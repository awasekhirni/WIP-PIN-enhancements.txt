-- =============================================
-- β Pulse Platform Database Schema
-- Version: 1.0
-- Created: 2025-04-23
-- Last Updated: 2025-06-19
-- Description: PostgreSQL implementation of the β Pulse operations performance/observability platform.
-- Author: Awase Khirni Syed
-- Copyright: 2025 β ORI Inc. Canada. All Rights Reserved.
--  'β Pulse Platform Database: Stores operational telemetry data (traces, logs, metrics), incident records,
--  and supports data governance and analytics';
-- =============================================

--Awase 
-- I have been very conservative on allocating mem for varchar data types. 
-- we could add more for varchar data types from varchar(20) to varchar(100)
-- More Enhancements and Metrics to Come, to capture application/browser performance metrics to this schema
-- =============================================
-- SECTION 1: DATABASE SETUP AND CONFIGURATION
-- =============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "ltree";

-- Create schema for core platform tables
CREATE SCHEMA IF NOT EXISTS btrace_core;
COMMENT ON SCHEMA btrace_core IS 'Core tables for β Trace platform functionality';

-- Create schema for data governance
CREATE SCHEMA IF NOT EXISTS btrace_gov;
COMMENT ON SCHEMA btrace_gov IS 'Data governance and compliance tables';

-- Create schema for analytics
CREATE SCHEMA IF NOT EXISTS btrace_analytics;
COMMENT ON SCHEMA btrace_analytics IS 'Analytics and reporting tables';

-- Create schema for RBAC
CREATE SCHEMA IF NOT EXISTS btrace_rbac;
COMMENT ON SCHEMA btrace_rbac IS 'Role-based access control tables';

-- Create schema for audit logging
CREATE SCHEMA IF NOT EXISTS btrace_audit;
COMMENT ON SCHEMA btrace_audit IS 'Audit logging and change tracking';

-- =============================================
-- SECTION 2: ROLE-BASED ACCESS CONTROL (RBAC)
-- =============================================
--
-- BUSINESS CASE:
-- The `roles` table defines the set of access roles available in the observability platform.
-- It enables fine-grained access control, ensuring users only see data and perform actions appropriate to their responsibilities.
-- This is essential for security, compliance (e.g., GDPR, SOC2), and operational safety.
--
-- PURPOSE:
-- - Centralize role definitions (e.g., Administrator, SRE, Viewer)
-- - Distinguish between modifiable custom roles and immutable system roles
-- - Support auditability and governance of access policies
-- - Enable integration with permission and user-role assignment systems
-- - Prevent unauthorized modification of critical roles
--

CREATE TABLE btrace_rbac.roles (
    role_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name      VARCHAR(100) NOT NULL,
    description    TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    created_by     UUID,
    updated_by     UUID,

    -- Enforce unique role names
    CONSTRAINT uq_role_name 
        UNIQUE (role_name),

    -- Prevent deactivation of system roles
    CONSTRAINT chk_system_role_active 
        CHECK (NOT (is_system_role AND is_active = FALSE)),

    -- System roles should not have user attribution
    CONSTRAINT chk_system_role_modifiable 
        CHECK (NOT (is_system_role AND (created_by IS NOT NULL OR updated_by IS NOT NULL)))

    -- ⚠️ WARNING: Uncomment the FKs below ONLY if btrace_core.users exists
    -- If the users table does not exist, these will cause syntax or reference errors
    -- 
    -- ,CONSTRAINT fk_roles_created_by 
    --     FOREIGN KEY (created_by) 
    --     REFERENCES btrace_core.users (user_id) 
    --     ON DELETE SET NULL,
    --
    -- CONSTRAINT fk_roles_updated_by 
    --     FOREIGN KEY (updated_by) 
    --     REFERENCES btrace_core.users (user_id) 
    --     ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_roles_role_name ON btrace_rbac.roles (role_name);
CREATE INDEX idx_roles_active ON btrace_rbac.roles (is_active);
CREATE INDEX idx_roles_system ON btrace_rbac.roles (is_system_role);
CREATE INDEX idx_roles_status_type ON btrace_rbac.roles (is_active, is_system_role);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION btrace_rbac.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_roles_updated_at
    BEFORE UPDATE ON btrace_rbac.roles
    FOR EACH ROW
    EXECUTE FUNCTION btrace_rbac.update_updated_at_column();


-- RBAC: Users table
--
-- BUSINESS CASE:
-- The `users` table stores system users who access the observability platform.
-- It enables secure authentication, personalized experiences, and audit accountability.
-- This table is central to identity management, access control, and compliance.
--
-- PURPOSE:
-- - Store user identities with secure credentials
-- - Support authentication (password + MFA)
-- - Enable personalization (timezone, locale)
-- - Provide audit trail for actions performed by users
-- - Serve as a reference for role assignments, permission grants, and activity logs
--

CREATE TABLE btrace_rbac.users (
    user_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username      VARCHAR(100) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    last_login    TIMESTAMP WITH TIME ZONE,
    mfa_enabled   BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret    TEXT,
    timezone      VARCHAR(50) NOT NULL DEFAULT 'UTC',
    locale        VARCHAR(10) NOT NULL DEFAULT 'en-US',
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- === Constraints ===

    -- Enforce unique usernames and emails
    CONSTRAINT uq_username UNIQUE (username),
    CONSTRAINT uq_email UNIQUE (email),

    -- Prevent invalid time values
    CONSTRAINT chk_last_login_not_future 
        CHECK (last_login IS NULL OR last_login <= CURRENT_TIMESTAMP),

    -- Validate timezone and locale formats (basic)
    -- Consider using a lookup table for strict validation
    CONSTRAINT chk_timezone_format 
        CHECK (timezone ~ '^[A-Za-z0-9/_+\-]+$'),

    CONSTRAINT chk_locale_format 
        CHECK (locale ~ '^[a-z]{2}(-[A-Z]{2})?$')
);

-- Fast lookup by username (login)
CREATE INDEX idx_users_username ON btrace_rbac.users (username);

-- Fast lookup by email (password reset, SSO)
CREATE INDEX idx_users_email ON btrace_rbac.users (email);

-- Filter active users only (common in UIs and auth)
CREATE INDEX idx_users_is_active ON btrace_rbac.users (is_active);

-- Find recently active users
CREATE INDEX idx_users_last_login ON btrace_rbac.users (last_login DESC)
WHERE last_login IS NOT NULL;

-- Support audit queries (who did what?)
CREATE INDEX idx_users_updated_at ON btrace_rbac.users (updated_at DESC);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION btrace_rbac.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on users
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON btrace_rbac.users
    FOR EACH ROW
    EXECUTE FUNCTION btrace_rbac.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_rbac.users IS 
'Stores user identities for the observability platform. Includes credentials, profile info, and security settings. Used for authentication, personalization, and audit logging.';

COMMENT ON COLUMN btrace_rbac.users.user_id IS 
'Globally unique identifier for the user. Used in foreign keys across roles, permissions, and audit trails.';

COMMENT ON COLUMN btrace_rbac.users.username IS 
'Unique login identifier (e.g., "jsmith"). Must be unique across the system.';

COMMENT ON COLUMN btrace_rbac.users.email IS 
'User''s email address. Used for notifications, SSO, and password recovery. Must be unique.';

COMMENT ON COLUMN btrace_rbac.users.password_hash IS 
'Securely hashed password using bcrypt or similar. Never stored in plaintext.';

COMMENT ON COLUMN btrace_rbac.users.first_name IS 
'User''s first name. Optional, used for display in UIs.';

COMMENT ON COLUMN btrace_rbac.users.last_name IS 
'User''s last name. Optional, used for display in UIs.';

COMMENT ON COLUMN btrace_rbac.users.is_active IS 
'Indicates whether the user can log in. Set to FALSE to deactivate without deleting (preserves audit history).';

COMMENT ON COLUMN btrace_rbac.users.last_login IS 
'Timestamp of the user''s most recent successful login. Used for account review and security monitoring.';

COMMENT ON COLUMN btrace_rbac.users.mfa_enabled IS 
'Indicates whether multi-factor authentication is enabled for this user. Recommended for all production accounts.';

COMMENT ON COLUMN btrace_rbac.users.mfa_secret IS 
'Secret key used for TOTP-based MFA (e.g., Google Authenticator). Encrypted at rest if possible.';

COMMENT ON COLUMN btrace_rbac.users.timezone IS 
'Preferred timezone for displaying timestamps (e.g., "America/New_York"). Default is UTC.';

COMMENT ON COLUMN btrace_rbac.users.locale IS 
'Preferred language/locale for UI (e.g., "en-US", "fr-FR"). Used for localization.';

COMMENT ON COLUMN btrace_rbac.users.created_at IS 
'Timestamp when the user account was created.';

COMMENT ON COLUMN btrace_rbac.users.updated_at IS 
'Automatically updated when the user record is modified. Useful for audit and change tracking.';


-- Check if the users table exists
SELECT 1
FROM information_schema.tables
WHERE table_schema = 'btrace_core'
  AND table_name = 'users';
  
-- Check if user_id column exists and is UUID
SELECT 1
FROM information_schema.columns
WHERE table_schema = 'btrace_core'
  AND table_name = 'users'
  AND column_name = 'user_id'
  AND data_type = 'USER-DEFINED' OR udt_name = 'uuid';
  
 
-- Now safely add the foreign keys
ALTER TABLE btrace_rbac.roles
    ADD CONSTRAINT fk_roles_created_by
        FOREIGN KEY (created_by)
        REFERENCES btrace_rbac.users (user_id)
        ON DELETE SET NULL;

ALTER TABLE btrace_rbac.roles
    ADD CONSTRAINT fk_roles_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES btrace_rbac.users (user_id)
        ON DELETE SET NULL;
	
	
-- RBAC: Permissions table
--
-- BUSINESS CASE:
-- The `permissions` table defines all possible permissions in the observability platform.
-- It serves as the source of truth for what actions can be performed on which resources.
-- This enables fine-grained, auditable, and maintainable access control policies.
--
-- PURPOSE:
-- - Centralize all permission definitions (e.g., "trace:read", "dashboard:write")
-- - Support role-permission assignment and policy evaluation
-- - Enable UIs to dynamically show/hide features based on user permissions
-- - Prevent magic strings in code by using a canonical permission registry
-- - Support audit logs and compliance reporting
--

CREATE TABLE btrace_rbac.permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(150) NOT NULL,
    description TEXT,
    resource_type VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Enforce unique permission names (canonical identifier)
    CONSTRAINT uq_permission_name 
        UNIQUE (permission_name),

    -- Optional: enforce semantic uniqueness (only one perm per resource+action)
    -- Remove if you allow multiple permissions with same resource/action but different scope
    CONSTRAINT uq_resource_action 
        UNIQUE (resource_type, action),

    -- Validate action values to prevent typos
    CONSTRAINT chk_action_value 
        CHECK (action IN ('read', 'create', 'update', 'delete', 'execute', 'share', 'manage')),

    -- Validate resource_type to ensure consistency
    CONSTRAINT chk_resource_type_value 
        CHECK (resource_type IN (
            'trace', 'span', 'log', 'metric', 'dashboard', 
            'alert', 'incident', 'service', 'environment', 
            'data_source', 'user', 'role', 'permission'
        ))
);

-- === Indexes for Performance ===

-- Fast lookup by permission_name (used in auth checks)
CREATE INDEX idx_permissions_name ON btrace_rbac.permissions (permission_name);

-- Filter by resource type (e.g., all dashboard perms)
CREATE INDEX idx_permissions_resource_type ON btrace_rbac.permissions (resource_type);

-- Filter by action
CREATE INDEX idx_permissions_action ON btrace_rbac.permissions (action);

-- Composite index for common queries (e.g., "what can be deleted?")
CREATE INDEX idx_permissions_resource_action ON btrace_rbac.permissions (resource_type, action);

COMMENT ON TABLE btrace_rbac.permissions IS 
'Defines all possible permissions in the system. Each permission grants the right to perform an action on a type of resource (e.g., "trace:read"). Used to build roles and evaluate access control.';

COMMENT ON COLUMN btrace_rbac.permissions.permission_name IS 
'Canonical, unique identifier for the permission (e.g., "traces:read", "dashboards:delete"). Used in code, APIs, and policies. Should follow format: "{resource}:{action}".';

COMMENT ON COLUMN btrace_rbac.permissions.description IS 
'Description of what the permission allows and when it should be granted. Used for UI tooltips and audit documentation.';

COMMENT ON COLUMN btrace_rbac.permissions.resource_type IS 
'The category of resource this permission applies to (e.g., trace, dashboard, alert). Used for grouping and scoping.';

COMMENT ON COLUMN btrace_rbac.permissions.action IS 
'The operation allowed: read, create, update, delete, execute, share, manage. Aligns with CRUD/REST conventions.';


--example permissions 
INSERT INTO btrace_rbac.permissions 
(permission_name, description, resource_type, action)
VALUES 
('trace:read', 'View distributed traces', 'trace', 'read'),
('trace:write', 'Record new traces', 'trace', 'create'),
('log:read', 'View application logs', 'log', 'read'),
('metric:read', 'View time-series metrics', 'metric', 'read'),
('dashboard:create', 'Create new dashboards', 'dashboard', 'create'),
('dashboard:delete', 'Delete dashboards', 'dashboard', 'delete'),
('alert:manage', 'Manage alert rules', 'alert', 'manage'),
('user:read', 'View user list', 'user', 'read'),
('role:update', 'Modify roles', 'role', 'update'),
('permission:read', 'View permissions', 'permission', 'read');

SELECT * FROM btrace_rbac.permissions ;
--RBAC: Role-Permissions Mapping 
--
-- BUSINESS CASE:
-- The `role_permissions` table links roles to their assigned permissions, forming the core of the RBAC (Role-Based Access Control) system.
-- It enables fine-grained access control by defining exactly what actions each role can perform on which resources.
-- This table is essential for secure, auditable, and maintainable authorization logic.
--
-- PURPOSE:
-- - Define which permissions are granted to each role
-- - Support fast permission checks during authentication/authorization
-- - Maintain an audit trail of who granted which permissions
-- - Enable dynamic UI rendering (e.g., show/hide "Delete" button)
-- - Facilitate compliance reporting and access reviews
--

CREATE TABLE btrace_rbac.role_permissions (
    role_id       UUID NOT NULL,
    permission_id UUID NOT NULL,
    granted_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by    UUID,  -- Optional: user who granted this permission (for audit)

    -- === Constraints ===

    -- Composite primary key ensures no duplicate role-permission assignments
    CONSTRAINT pk_role_permissions 
        PRIMARY KEY (role_id, permission_id),

    -- Foreign key to roles (cascade delete if role is removed)
    CONSTRAINT fk_role_permissions_role_id 
        FOREIGN KEY (role_id) 
        REFERENCES btrace_rbac.roles (role_id) 
        ON DELETE CASCADE,

    -- Foreign key to permissions (cascade delete if perm is removed)
    CONSTRAINT fk_role_permissions_permission_id 
        FOREIGN KEY (permission_id) 
        REFERENCES btrace_rbac.permissions (permission_id) 
        ON DELETE CASCADE,

    -- Optional: link to user who granted the permission
    -- Only enable if btrace_rbac.users table exists
    CONSTRAINT fk_role_permissions_granted_by 
        FOREIGN KEY (granted_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- === Indexes ===

-- Index for: "What permissions does this role have?"
-- Used in auth checks when loading a user's role permissions
CREATE INDEX idx_role_permissions_by_role 
ON btrace_rbac.role_permissions (role_id);

-- Index for: "Which roles have this permission?"
-- Useful for audit, compliance, and impact analysis (e.g., "who can delete dashboards?")
CREATE INDEX idx_role_permissions_by_permission 
ON btrace_rbac.role_permissions (permission_id);

-- Index for: "Who has been granting permissions?"
-- Useful for security audits and detecting privilege escalation
CREATE INDEX idx_role_permissions_granted_by 
ON btrace_rbac.role_permissions (granted_by)
WHERE granted_by IS NOT NULL;

-- Optional: covering index for common queries with granted_at
CREATE INDEX idx_role_permissions_covering 
ON btrace_rbac.role_permissions (role_id, permission_id)
INCLUDE (granted_at, granted_by);

COMMENT ON TABLE btrace_rbac.role_permissions IS 
'Junction table that assigns permissions to roles. Forms the backbone of the RBAC system. Each row grants a specific permission to a role, optionally recording who granted it and when.';

COMMENT ON COLUMN btrace_rbac.role_permissions.role_id IS 
'References the role being granted a permission. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.role_permissions.permission_id IS 
'References the permission being granted to the role. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.role_permissions.granted_at IS 
'Timestamp when the permission was assigned to the role. Used for audit and change tracking.';

COMMENT ON COLUMN btrace_rbac.role_permissions.granted_by IS 
'Optional: user who granted this permission. NULL if automated or untracked. Used for security audits and accountability.';




-- RBAC: User-Role mapping
--
-- BUSINESS CASE:
-- The `user_roles` table links users to their assigned roles, completing the RBAC (Role-Based Access Control) model.
-- It enables personalized access control by defining exactly what each user is authorized to do in the system.
-- This table is essential for secure authentication, dynamic UI rendering, and compliance auditing.
--
-- PURPOSE:
-- - Assign roles to users (e.g., "Alice has the SRE role")
-- - Support fast permission resolution during login and API requests
-- - Maintain an audit trail of role assignments
-- - Enable access reviews and least-privilege enforcement
-- - Facilitate deprovisioning via is_active flags or role removal
--

CREATE TABLE btrace_rbac.user_roles (
    user_id      UUID NOT NULL,
    role_id      UUID NOT NULL,
    assigned_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by  UUID,  -- Optional: user who granted this role (for audit)

    -- Composite Primary Key: one role per user (no duplicates)
    CONSTRAINT pk_user_roles 
        PRIMARY KEY (user_id, role_id),

    -- Foreign Keys
    CONSTRAINT fk_user_roles_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_user_roles_role_id 
        FOREIGN KEY (role_id) 
        REFERENCES btrace_rbac.roles (role_id) 
        ON DELETE CASCADE,

    -- Optional: track who assigned the role
    -- Remove or adjust schema if btrace_rbac.users doesn't exist
    CONSTRAINT fk_user_roles_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Index: "What roles does this user have?" ← Critical for auth
CREATE INDEX idx_user_roles_by_user 
ON btrace_rbac.user_roles (user_id);

-- Index: "Which users have this role?" ← Critical for audits
CREATE INDEX idx_user_roles_by_role 
ON btrace_rbac.user_roles (role_id);

-- Index: "Who has been assigning roles?" ← Security forensics
CREATE INDEX idx_user_roles_assigned_by 
ON btrace_rbac.user_roles (assigned_by)
WHERE assigned_by IS NOT NULL;

-- Covering index for audit/export queries
CREATE INDEX idx_user_roles_covering 
ON btrace_rbac.user_roles (user_id, role_id)
INCLUDE (assigned_at, assigned_by);

COMMENT ON TABLE btrace_rbac.user_roles IS 
'Junction table that assigns roles to users. Each row represents a role granted to a user. Supports auditability via assigned_at and assigned_by. Used during authentication to resolve user permissions.';

COMMENT ON COLUMN btrace_rbac.user_roles.user_id IS 
'References the user being granted a role. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_roles.role_id IS 
'References the role being assigned to the user. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_roles.assigned_at IS 
'Timestamp when the role was assigned. Used for access reviews and compliance reporting.';

COMMENT ON COLUMN btrace_rbac.user_roles.assigned_by IS 
'Optional: user who assigned this role. NULL if assigned via automation, seed data, or self-registration. Used for accountability and audit trails.';

-- -- SELECT to get all the permissions for a user
-- SELECT DISTINCT p.permission_name, p.description
-- FROM btrace_rbac.users u
-- JOIN btrace_rbac.user_roles ur ON u.user_id = ur.user_id
-- JOIN btrace_rbac.role_permissions rp ON ur.role_id = rp.role_id
-- JOIN btrace_rbac.permissions p ON rp.permission_id = p.permission_id
-- WHERE u.user_id = :user_id 
--   AND u.is_active = TRUE;

-- SELECT DISTINCT p.permission_name, p.description
-- FROM btrace_rbac.users u
-- JOIN btrace_rbac.user_roles ur ON u.user_id = ur.user_id
-- JOIN btrace_rbac.role_permissions rp ON ur.role_id = rp.role_id
-- JOIN btrace_rbac.permissions p ON rp.permission_id = p.permission_id
-- WHERE u.username = 'jsmith' 
--   AND u.is_active = TRUE;

SELECT DISTINCT p.permission_name, p.description
FROM btrace_rbac.users u
JOIN btrace_rbac.user_roles ur ON u.user_id = ur.user_id
JOIN btrace_rbac.role_permissions rp ON ur.role_id = rp.role_id
JOIN btrace_rbac.permissions p ON rp.permission_id = p.permission_id
WHERE u.user_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678' 
  AND u.is_active = TRUE;

-- RBAC: Teams table
--
-- BUSINESS CASE:
-- The `teams` table models organizational teams (e.g., "Backend", "SRE", "Payments") within the company.
-- It enables team-based access control, ownership assignment, and collaboration in the observability platform.
-- Teams are essential for scaling permissions, routing alerts, and managing service ownership.
--
-- PURPOSE:
-- - Represent organizational structure in the system
-- - Support team-based permissions and resource ownership
-- - Enable hierarchical organization (e.g., "Platform" → "SRE")
-- - Facilitate audit, reporting, and access reviews
-- - Serve as a foundation for team-scoped dashboards and alerts
--

CREATE TABLE btrace_rbac.teams (
    team_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_name      VARCHAR(100) NOT NULL,
    description    TEXT,
    parent_team_id UUID,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    created_by     UUID,
    updated_by     UUID,

    -- Enforce unique team names
    CONSTRAINT uq_team_name 
        UNIQUE (team_name),

    -- Prevent self-referencing or invalid parent
    CONSTRAINT chk_not_self_parent 
        CHECK (team_id != parent_team_id),

    -- Foreign keys
    CONSTRAINT fk_teams_parent_team_id 
        FOREIGN KEY (parent_team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_teams_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_teams_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast lookup by team name
CREATE INDEX idx_teams_team_name ON btrace_rbac.teams (team_name);

-- Filter by parent (e.g., "show subteams of Platform")
CREATE INDEX idx_teams_parent_team_id ON btrace_rbac.teams (parent_team_id);

-- Audit: who created/updated teams?
CREATE INDEX idx_teams_created_by ON btrace_rbac.teams (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_teams_updated_by ON btrace_rbac.teams (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for team listings
CREATE INDEX idx_teams_covering 
ON btrace_rbac.teams (team_name, parent_team_id)
INCLUDE (description, created_at);


-- Function (reuse from earlier if already created)
-- Only create if not exists
CREATE OR REPLACE FUNCTION btrace_rbac.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_teams_updated_at
    BEFORE UPDATE ON btrace_rbac.teams
    FOR EACH ROW
    EXECUTE FUNCTION btrace_rbac.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_rbac.teams IS 
'Represents organizational teams (e.g., "SRE", "Payments") that users can belong to. Supports hierarchical structure via parent_team_id. Used for access control, ownership, and alert routing.';

COMMENT ON COLUMN btrace_rbac.teams.team_id IS 
'Unique identifier for the team. Used in foreign keys and APIs.';

COMMENT ON COLUMN btrace_rbac.teams.team_name IS 
'Human-readable name of the team. Must be unique across the system.';

COMMENT ON COLUMN btrace_rbac.teams.description IS 
'Description of the team''s responsibilities, scope, and members.';

COMMENT ON COLUMN btrace_rbac.teams.parent_team_id IS 
'References the parent team to support hierarchy (e.g., "SRE" under "Platform"). NULL for top-level teams.';

COMMENT ON COLUMN btrace_rbac.teams.created_at IS 
'Timestamp when the team was created.';

COMMENT ON COLUMN btrace_rbac.teams.updated_at IS 
'Automatically updated when the team is modified. Useful for audit and change tracking.';

COMMENT ON COLUMN btrace_rbac.teams.created_by IS 
'Optional: user who created the team. NULL if created via automation or seed data.';

COMMENT ON COLUMN btrace_rbac.teams.updated_by IS 
'Optional: last user to update the team. NULL if untracked.';
	
	
	
-- RBAC: User-Team mapping
--
-- BUSINESS CASE:
-- The `user_teams` table links users to the teams they belong to, enabling team-based access control, ownership, and collaboration.
-- It supports organizational hierarchy, role assignment (e.g., team lead), and routing of alerts and responsibilities.
-- This table is essential for scaling observability and incident response across large organizations.
--
-- PURPOSE:
-- - Define team membership for users
-- - Identify team leads or administrators
-- - Support service ownership (e.g., "this team owns service X")
-- - Enable team-scoped dashboards, alerts, and permissions
-- - Facilitate access reviews and compliance reporting
--

CREATE TABLE btrace_rbac.user_teams (
    user_id        UUID NOT NULL,
    team_id        UUID NOT NULL,
    is_team_lead   BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by       UUID,  -- Optional: who added the user to the team

    -- Composite Primary Key: one membership per user-team
    CONSTRAINT pk_user_teams 
        PRIMARY KEY (user_id, team_id),

    -- Foreign Keys
    CONSTRAINT fk_user_teams_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_user_teams_team_id 
        FOREIGN KEY (team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE CASCADE,

    -- Optional: track who added the user
    CONSTRAINT fk_user_teams_added_by 
        FOREIGN KEY (added_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Index: "What teams does this user belong to?" ← Critical for auth/UI
CREATE INDEX idx_user_teams_by_user 
ON btrace_rbac.user_teams (user_id);

-- Index: "Who is in this team?" ← Critical for collaboration and alerts
CREATE INDEX idx_user_teams_by_team 
ON btrace_rbac.user_teams (team_id);

-- Index: "Find team leads" (e.g., for on-call, approvals)
CREATE INDEX idx_user_teams_team_lead 
ON btrace_rbac.user_teams (team_id, user_id)
WHERE is_team_lead = TRUE;

-- Index: Audit — who has been adding members?
CREATE INDEX idx_user_teams_added_by 
ON btrace_rbac.user_teams (added_by)
WHERE added_by IS NOT NULL;

-- Covering index for team membership listing
CREATE INDEX idx_user_teams_covering 
ON btrace_rbac.user_teams (team_id, joined_at DESC)
INCLUDE (user_id, is_team_lead, added_by);


COMMENT ON TABLE btrace_rbac.user_teams IS 
'Junction table that defines team membership. Each row indicates that a user belongs to a team, optionally marking them as a team lead. Used for ownership, access control, and collaboration features.';

COMMENT ON COLUMN btrace_rbac.user_teams.user_id IS 
'References the user who is a member of the team. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_teams.team_id IS 
'References the team the user belongs to. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_teams.is_team_lead IS 
'Indicates whether the user is a lead or administrator of the team. Used for escalation, approvals, and ownership.';

COMMENT ON COLUMN btrace_rbac.user_teams.joined_at IS 
'Timestamp when the user joined the team. Used for onboarding and historical reporting.';

COMMENT ON COLUMN btrace_rbac.user_teams.added_by IS 
'Optional: user who added this member to the team. NULL if self-joined or seeded. Used for audit and accountability.';


SELECT u.username, u.email, ut.is_team_lead, ut.joined_at
FROM btrace_rbac.user_teams ut
JOIN btrace_rbac.users u ON ut.user_id = u.user_id
WHERE ut.team_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY ut.is_team_lead DESC, ut.joined_at;


SELECT t.team_name, u.username AS lead_user
FROM btrace_rbac.user_teams ut
JOIN btrace_rbac.teams t ON ut.team_id = t.team_id
JOIN btrace_rbac.users u ON ut.user_id = u.user_id
WHERE ut.is_team_lead = TRUE
  AND u.is_active = TRUE;

-- RBAC: Service Accounts
--
-- BUSINESS CASE:
-- The `service_accounts` table manages non-human identities (bots, CI/CD jobs, exporters) that interact with the observability platform via APIs.
-- It enables secure, auditable, and revocable access without using human credentials.
-- This is essential for automation, integration safety, and compliance (e.g., SOC2, ISO27001).
--
-- PURPOSE:
-- - Issue API keys to machines and services
-- - Track who created which service account
-- - Support key expiration and rotation
-- - Enable revocation (`is_active`)
-- - Audit access and enforce least privilege
--

CREATE TABLE btrace_rbac.service_accounts (
    account_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_name       VARCHAR(100) NOT NULL,
    description        TEXT,
    api_key_hash       TEXT NOT NULL,  -- Store hash, not raw key
    api_key_expires_at TIMESTAMP WITH TIME ZONE,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP WITH TIME ZONE,
    created_by         UUID,  -- Human or system that created it
    updated_by         UUID,  -- Last modifier

    -- Enforce unique account names
    CONSTRAINT uq_account_name 
        UNIQUE (account_name),

    -- Prevent expired or invalid timestamps
    CONSTRAINT chk_api_key_future_expiration 
        CHECK (api_key_expires_at IS NULL OR api_key_expires_at > created_at),

    -- Ensure created_by references valid users (if used)
    CONSTRAINT fk_service_accounts_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_service_accounts_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by account name (admin UI, audit)
CREATE INDEX idx_service_accounts_name ON btrace_rbac.service_accounts (account_name);

-- Filter active accounts only (auth checks)
CREATE INDEX idx_service_accounts_is_active ON btrace_rbac.service_accounts (is_active);

-- Find expiring API keys (for rotation alerts)
CREATE INDEX idx_service_accounts_expires_at 
ON btrace_rbac.service_accounts (api_key_expires_at)
WHERE api_key_expires_at IS NOT NULL AND is_active = TRUE;

-- Audit: who created/updated accounts?
CREATE INDEX idx_service_accounts_created_by ON btrace_rbac.service_accounts (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_service_accounts_updated_by ON btrace_rbac.service_accounts (updated_by) WHERE updated_by IS NOT NULL;

-- Critical: fast lookup by API key hash during auth
-- (Used in authentication: "find account with this api_key_hash")
CREATE INDEX idx_service_accounts_api_key_hash ON btrace_rbac.service_accounts (api_key_hash);


-- Reuse the existing function (if not created, see below)
-- Only create if it doesn't exist
CREATE OR REPLACE FUNCTION btrace_rbac.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on service_accounts
CREATE TRIGGER update_service_accounts_updated_at
    BEFORE UPDATE ON btrace_rbac.service_accounts
    FOR EACH ROW
    EXECUTE FUNCTION btrace_rbac.update_updated_at_column();
	
COMMENT ON TABLE btrace_rbac.service_accounts IS 
'Non-human identities (e.g., CI/CD jobs, exporters, bots) that access the system via API keys. Each service account can be assigned roles and permissions. Designed for automation and integration safety.';

COMMENT ON COLUMN btrace_rbac.service_accounts.account_id IS 
'Unique identifier for the service account. Used in foreign keys and APIs.';

COMMENT ON COLUMN btrace_rbac.service_accounts.account_name IS 
'Human-readable name (e.g., "grafana-agent", "ci-deploy-bot"). Must be unique. Used for identification and auditing.';

COMMENT ON COLUMN btrace_rbac.service_accounts.description IS 
'Description of the service account''s purpose, owner, and usage. Critical for access reviews.';

COMMENT ON COLUMN btrace_rbac.service_accounts.api_key_hash IS 
'Cryptographic hash (e.g., bcrypt, SHA-256) of the API key. Never store raw keys. Used to authenticate incoming requests.';

COMMENT ON COLUMN btrace_rbac.service_accounts.api_key_expires_at IS 
'Optional expiration timestamp for the API key. Encourages rotation and reduces risk of long-lived secrets. NULL = no expiration.';

COMMENT ON COLUMN btrace_rbac.service_accounts.is_active IS 
'Indicates whether the service account is allowed to authenticate. Set to FALSE to revoke access without deleting.';

COMMENT ON COLUMN btrace_rbac.service_accounts.created_at IS 
'Timestamp when the service account was registered.';

COMMENT ON COLUMN btrace_rbac.service_accounts.updated_at IS 
'Automatically updated when the account is modified. Useful for change tracking.';

COMMENT ON COLUMN btrace_rbac.service_accounts.created_by IS 
'Optional: user who created this service account. NULL for automated provisioning.';

COMMENT ON COLUMN btrace_rbac.service_accounts.updated_by IS 
'Optional: last user to modify the account (e.g., rotated key, updated description).';

-- RBAC: Service Account-Role mapping
--
-- BUSINESS CASE:
-- The `service_account_roles` table assigns roles to service accounts, enabling non-human identities to perform authorized actions (e.g., ingest traces, read dashboards).
-- It extends the RBAC model to machines, ensuring automated systems follow the same least-privilege security principles as human users.
-- This is essential for compliance, auditability, and secure automation.
--
-- PURPOSE:
-- - Grant permissions to service accounts via role assignment
-- - Support least-privilege access for CI/CD, agents, and integrations
-- - Maintain an audit trail of who granted which roles
-- - Enable access reviews and revocation
-- - Facilitate secure, scoped API access
--

CREATE TABLE btrace_rbac.service_account_roles (
    account_id   UUID NOT NULL,
    role_id      UUID NOT NULL,
    assigned_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by  UUID,  -- Optional: user or system that granted the role

    -- Composite Primary Key: one role per service account
    CONSTRAINT pk_service_account_roles 
        PRIMARY KEY (account_id, role_id),

    -- Foreign Keys
    CONSTRAINT fk_sar_account_id 
        FOREIGN KEY (account_id) 
        REFERENCES btrace_rbac.service_accounts (account_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_sar_role_id 
        FOREIGN KEY (role_id) 
        REFERENCES btrace_rbac.roles (role_id) 
        ON DELETE CASCADE,

    -- Optional: track who assigned the role (audit)
    -- Remove or adjust schema if btrace_rbac.users doesn't exist
    CONSTRAINT fk_sar_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Index: "What roles does this service account have?" ← Critical for auth
CREATE INDEX idx_sar_by_account 
ON btrace_rbac.service_account_roles (account_id);

-- Index: "Which service accounts have this role?" ← Critical for audits
CREATE INDEX idx_sar_by_role 
ON btrace_rbac.service_account_roles (role_id);

-- Index: "Who has been assigning roles to service accounts?" ← Security forensics
CREATE INDEX idx_sar_assigned_by 
ON btrace_rbac.service_account_roles (assigned_by)
WHERE assigned_by IS NOT NULL;

-- Covering index for audit/export queries (avoid table fetch)
CREATE INDEX idx_sar_covering 
ON btrace_rbac.service_account_roles (account_id, role_id)
INCLUDE (assigned_at, assigned_by);

COMMENT ON TABLE btrace_rbac.service_account_roles IS 
'Junction table that assigns roles to service accounts. Each row grants a role (and its permissions) to a non-human identity. Supports auditability via assigned_at and assigned_by. Used during API authentication to resolve machine permissions.';

COMMENT ON COLUMN btrace_rbac.service_account_roles.account_id IS 
'References the service account receiving the role. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.service_account_roles.role_id IS 
'References the role being assigned. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.service_account_roles.assigned_at IS 
'Timestamp when the role was assigned to the service account. Used for compliance and access reviews.';

COMMENT ON COLUMN btrace_rbac.service_account_roles.assigned_by IS 
'Optional: user who granted this role. NULL if assigned via automation or infrastructure-as-code. Used for accountability and audit trails.';


SELECT DISTINCT p.permission_name, p.description
FROM btrace_rbac.service_accounts sa
JOIN btrace_rbac.service_account_roles sar ON sa.account_id = sar.account_id
JOIN btrace_rbac.role_permissions rp ON sar.role_id = rp.role_id
JOIN btrace_rbac.permissions p ON rp.permission_id = p.permission_id
WHERE sa.account_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND sa.is_active = TRUE;
-- =============================================
-- SECTION 3: DATA GOVERNANCE AND COMPLIANCE
-- =============================================

-- Governance Committee
--
-- BUSINESS CASE:
-- The `governance_committees` table defines formal data governance bodies responsible for policies, standards, and oversight of observability data.
-- These committees ensure data quality, privacy compliance (e.g., PII handling), and alignment across teams.
-- This table supports accountability, meeting cadence tracking, and leadership assignment.
--
-- PURPOSE:
-- - Document governance structure and ownership
-- - Assign leadership roles (chair, secretary)
-- - Track meeting frequency and responsibilities
-- - Support compliance reporting (e.g., GDPR, HIPAA, SOC2)
-- - Enable integration with meeting scheduling and action tracking
--

CREATE TABLE btrace_gov.governance_committees (
    committee_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    committee_name      VARCHAR(100) NOT NULL,
    purpose             TEXT NOT NULL,
    chair_person_id     UUID,
    secretary_person_id UUID,
    meeting_frequency   VARCHAR(50),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE,
    created_by          UUID,
    updated_by          UUID,

    -- Enforce unique committee names
    CONSTRAINT uq_committee_name 
        UNIQUE (committee_name),

    -- Validate meeting frequency
    CONSTRAINT chk_meeting_frequency 
        CHECK (meeting_frequency IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'ad_hoc')),

    -- Chair and secretary must be valid users
    CONSTRAINT fk_committee_chair 
        FOREIGN KEY (chair_person_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_committee_secretary 
        FOREIGN KEY (secretary_person_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    -- Track who created/updated the record
    CONSTRAINT fk_committee_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_committee_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by name
CREATE INDEX idx_gov_committees_name ON btrace_gov.governance_committees (committee_name);

-- Find committees by chair or secretary
CREATE INDEX idx_gov_committees_chair ON btrace_gov.governance_committees (chair_person_id) 
WHERE chair_person_id IS NOT NULL;

CREATE INDEX idx_gov_committees_secretary ON btrace_gov.governance_committees (secretary_person_id) 
WHERE secretary_person_id IS NOT NULL;

-- Filter by meeting frequency
CREATE INDEX idx_gov_committees_frequency ON btrace_gov.governance_committees (meeting_frequency);

-- Audit: who created/updated committees?
CREATE INDEX idx_gov_committees_created_by ON btrace_gov.governance_committees (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_gov_committees_updated_by ON btrace_gov.governance_committees (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for listing committees
CREATE INDEX idx_gov_committees_covering 
ON btrace_gov.governance_committees (committee_name, meeting_frequency)
INCLUDE (purpose, chair_person_id, secretary_person_id, created_at);

-- Reuse existing function (ensure it's created in btrace_gov or shared schema)
-- If not exists, create it
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_governance_committees_updated_at
    BEFORE UPDATE ON btrace_gov.governance_committees
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_gov.governance_committees IS 
'Represents formal data governance committees responsible for oversight of observability data practices. Includes leadership roles, meeting cadence, and purpose. Used for compliance, accountability, and organizational transparency.';

COMMENT ON COLUMN btrace_gov.governance_committees.committee_id IS 
'Unique identifier for the governance committee. Used in foreign keys and APIs.';

COMMENT ON COLUMN btrace_gov.governance_committees.committee_name IS 
'Human-readable name of the committee (e.g., "Observability Governance Board"). Must be unique.';

COMMENT ON COLUMN btrace_gov.governance_committees.purpose IS 
'Description of the committee''s mission, scope, and responsibilities (e.g., "Oversee PII handling in logs").';

COMMENT ON COLUMN btrace_gov.governance_committees.chair_person_id IS 
'References the user serving as chair of the committee. Leads meetings and drives decisions. NULL if vacant.';

COMMENT ON COLUMN btrace_gov.governance_committees.secretary_person_id IS 
'References the user responsible for recording minutes and action items. NULL if unassigned.';

COMMENT ON COLUMN btrace_gov.governance_committees.meeting_frequency IS 
'How often the committee meets: daily, weekly, biweekly, monthly, quarterly, or ad_hoc. Used for planning and compliance tracking.';

COMMENT ON COLUMN btrace_gov.governance_committees.created_at IS 
'Timestamp when the committee was established.';

COMMENT ON COLUMN btrace_gov.governance_committees.updated_at IS 
'Automatically updated when the committee record is modified. Useful for audit and change tracking.';

COMMENT ON COLUMN btrace_gov.governance_committees.created_by IS 
'Optional: user who registered this committee. NULL if created via automation or seed data.';

COMMENT ON COLUMN btrace_gov.governance_committees.updated_by IS 
'Optional: last user to update the committee details. NULL if untracked.';

-- Committee Members
--
-- BUSINESS CASE:
-- The `committee_members` table tracks which users belong to data governance committees, their roles, and tenure.
-- It enables formal oversight, accountability, and compliance reporting by documenting who participated in governance decisions.
-- This is essential for audits, access reviews, and organizational transparency.
--
-- PURPOSE:
-- - Record membership in governance committees
-- - Track roles (e.g., member, advisor, co-chair)
-- - Support time-bound appointments (e.g., 6-month term)
-- - Enable historical reporting ("who was on the committee in Q1?")
-- - Facilitate communication and meeting planning
--

CREATE TABLE btrace_gov.committee_members (
    committee_id UUID NOT NULL,
    user_id      UUID NOT NULL,
    role         VARCHAR(50) NOT NULL,
    start_date   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date     TIMESTAMP WITH TIME ZONE,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   UUID,
    updated_at   TIMESTAMP WITH TIME ZONE,

    -- Composite Primary Key
    CONSTRAINT pk_committee_members 
        PRIMARY KEY (committee_id, user_id),

    -- Enforce valid date range
    CONSTRAINT chk_valid_term 
        CHECK (end_date IS NULL OR end_date >= start_date),

    -- Ensure role is meaningful
    CONSTRAINT chk_role_value 
        CHECK (role IN (
            'member', 'chair', 'co-chair', 'secretary', 
            'deputy', 'advisor', 'observer', 'guest'
        )),

    -- Foreign Keys
    CONSTRAINT fk_cm_committee_id 
        FOREIGN KEY (committee_id) 
        REFERENCES btrace_gov.governance_committees (committee_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_cm_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_cm_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Who are the current members of this committee?"
CREATE INDEX idx_cm_by_committee 
ON btrace_gov.committee_members (committee_id, is_active)
WHERE is_active = TRUE;

-- Fast: "Which committees is this user on?"
CREATE INDEX idx_cm_by_user 
ON btrace_gov.committee_members (user_id, is_active)
WHERE is_active = TRUE;

-- Find expiring/ended memberships (for renewal alerts)
CREATE INDEX idx_cm_end_date 
ON btrace_gov.committee_members (end_date)
WHERE end_date IS NOT NULL AND is_active = TRUE;

-- Filter by role (e.g., "find all chairs")
CREATE INDEX idx_cm_role 
ON btrace_gov.committee_members (role);

-- Audit: who added members?
CREATE INDEX idx_cm_created_by 
ON btrace_gov.committee_members (created_by)
WHERE created_by IS NOT NULL;

-- Covering index for committee roster display
CREATE INDEX idx_cm_covering 
ON btrace_gov.committee_members (committee_id, is_active, start_date DESC)
INCLUDE (user_id, role, end_date, created_by);

-- Reuse or create the standard updated_at trigger
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_committee_members_updated_at
    BEFORE UPDATE ON btrace_gov.committee_members
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
-- Reuse or create the standard updated_at trigger
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_committee_members_updated_at
    BEFORE UPDATE ON btrace_gov.committee_members
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
	COMMENT ON TABLE btrace_gov.committee_members IS 
'Junction table that defines membership in data governance committees. Tracks role, tenure (start/end date), and activity status. Used for compliance, historical reporting, and meeting coordination.';

COMMENT ON COLUMN btrace_gov.committee_members.committee_id IS 
'References the governance committee. Part of composite primary key.';

COMMENT ON COLUMN btrace_gov.committee_members.user_id IS 
'References the user who is a member. Part of composite primary key.';

COMMENT ON COLUMN btrace_gov.committee_members.role IS 
'Role of the member: e.g., member, chair, co-chair, secretary, advisor, observer. Defines responsibilities within the committee.';

COMMENT ON COLUMN btrace_gov.committee_members.start_date IS 
'Timestamp when the membership began. Typically the date of appointment or first meeting.';

COMMENT ON COLUMN btrace_gov.committee_members.end_date IS 
'Optional: timestamp when the membership ends (e.g., term expiration). NULL if ongoing.';

COMMENT ON COLUMN btrace_gov.committee_members.is_active IS 
'Computed flag indicating current membership status. TRUE if active (end_date is NULL or in the future). Used for filtering active rosters.';

COMMENT ON COLUMN btrace_gov.committee_members.created_at IS 
'Timestamp when the membership record was created.';

COMMENT ON COLUMN btrace_gov.committee_members.created_by IS 
'Optional: user who added this member to the committee. NULL if self-registered or seeded.';

COMMENT ON COLUMN btrace_gov.committee_members.updated_at IS 
'Automatically updated when the membership is modified (e.g., role change). Useful for audit.';


-- get current members of a committee 
SELECT u.username, cm.role, cm.start_date, cm.end_date
FROM btrace_gov.committee_members cm
JOIN btrace_rbac.users u ON cm.user_id = u.user_id
WHERE cm.committee_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND cm.is_active = TRUE
ORDER BY 
  CASE WHEN cm.role = 'chair' THEN 1
       WHEN cm.role = 'co-chair' THEN 2
       ELSE 3 END,
  cm.start_date;
  
  
SELECT c.committee_name, u.username, cm.role, cm.end_date
FROM btrace_gov.committee_members cm
JOIN btrace_gov.governance_committees c ON cm.committee_id = c.committee_id
JOIN btrace_rbac.users u ON cm.user_id = u.user_id
WHERE cm.is_active = TRUE
  AND cm.end_date IS NOT NULL
  AND cm.end_date BETWEEN NOW() AND NOW() + INTERVAL '30 days';

-- Governance Policies
--
-- BUSINESS CASE:
-- The `policies` table stores formal data governance policies (e.g., data retention, PII handling, quality standards) 
-- established by governance committees. It ensures consistency, compliance, and transparency across the organization.
-- This table is critical for audits (e.g., SOC2, GDPR), onboarding, and enforcing best practices in observability.
--
-- PURPOSE:
-- - Centralize governance policies in a versioned, searchable registry
-- - Assign ownership to governance committees
-- - Track policy lifecycle (effective, review, active/inactive)
-- - Support compliance reporting and access reviews
-- - Enable integration with training and alerting systems
--

CREATE TABLE btrace_gov.policies (
    policy_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name     VARCHAR(100) NOT NULL,
    description     TEXT,
    policy_type     VARCHAR(50) NOT NULL,
    policy_text     TEXT NOT NULL,
    version         VARCHAR(20) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date  TIMESTAMP WITH TIME ZONE NOT NULL,
    review_date     TIMESTAMP WITH TIME ZONE,
    committee_id    UUID,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,
    created_by      UUID,
    updated_by      UUID,

    -- Enforce unique policy name + version
    CONSTRAINT uq_policy_name_version 
        UNIQUE (policy_name, version),

    -- Validate policy_type
    CONSTRAINT chk_policy_type 
        CHECK (policy_type IN (
            'data_quality', 'data_security', 'data_retention', 
            'pii_handling', 'access_control', 'metadata_management',
            'compliance', 'classification', 'lineage'
        )),

    -- Prevent invalid dates
    CONSTRAINT chk_effective_date_not_future 
        CHECK (effective_date <= CURRENT_TIMESTAMP + INTERVAL '1 day'),

    CONSTRAINT chk_review_after_effective 
        CHECK (review_date IS NULL OR review_date >= effective_date),

    -- Foreign keys
    CONSTRAINT fk_policies_committee_id 
        FOREIGN KEY (committee_id) 
        REFERENCES btrace_gov.governance_committees (committee_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_policies_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_policies_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by policy name
CREATE INDEX idx_policies_name ON btrace_gov.policies (policy_name);

-- Filter by type (e.g., "show all data_retention policies")
CREATE INDEX idx_policies_type ON btrace_gov.policies (policy_type);

-- Find active policies only
CREATE INDEX idx_policies_is_active ON btrace_gov.policies (is_active);

-- Policies due for review (critical for compliance)
CREATE INDEX idx_policies_review_date 
ON btrace_gov.policies (review_date)
WHERE review_date IS NOT NULL AND is_active = TRUE;

-- Policies by committee (ownership)
CREATE INDEX idx_policies_committee_id ON btrace_gov.policies (committee_id) WHERE committee_id IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_policies_created_by ON btrace_gov.policies (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_policies_updated_by ON btrace_gov.policies (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for policy listings
CREATE INDEX idx_policies_covering 
ON btrace_gov.policies (policy_name, version, is_active)
INCLUDE (policy_type, effective_date, review_date, description);

-- Reuse or create the updated_at function in btrace_gov schema
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_policies_updated_at
    BEFORE UPDATE ON btrace_gov.policies
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.policies IS 
'Central registry of formal data governance policies. Each policy defines rules for data handling, quality, security, or compliance. Versioned and owned by a governance committee. Used for audits, training, and enforcement.';

COMMENT ON COLUMN btrace_gov.policies.policy_id IS 
'Unique identifier for the policy. Used in references and APIs.';

COMMENT ON COLUMN btrace_gov.policies.policy_name IS 
'Human-readable name of the policy (e.g., "Log Data Retention Policy"). Should be clear and consistent.';

COMMENT ON COLUMN btrace_gov.policies.description IS 
'Summary of the policy''s purpose and scope. Used in UIs and documentation.';

COMMENT ON COLUMN btrace_gov.policies.policy_type IS 
'Category of the policy: e.g., data_quality, data_security, data_retention, pii_handling. Used for filtering and compliance reporting.';

COMMENT ON COLUMN btrace_gov.policies.policy_text IS 
'Full text of the policy. May include legal language, requirements, and procedures. Stored as plain text or Markdown.';

COMMENT ON COLUMN btrace_gov.policies.version IS 
'Version identifier (e.g., "1.0", "2.1"). Used with policy_name for uniqueness. Supports version history.';

COMMENT ON COLUMN btrace_gov.policies.is_active IS 
'Indicates whether the policy is currently enforced. Set to FALSE when deprecated (preserves history).';

COMMENT ON COLUMN btrace_gov.policies.effective_date IS 
'Date when the policy became active. Used for compliance and historical tracking.';

COMMENT ON COLUMN btrace_gov.policies.review_date IS 
'Scheduled date for next policy review. Encourages regular updates and compliance alignment.';

COMMENT ON COLUMN btrace_gov.policies.committee_id IS 
'References the governance committee responsible for this policy. NULL if unassigned or system-defined.';

COMMENT ON COLUMN btrace_gov.policies.created_at IS 
'Timestamp when the policy was registered.';

COMMENT ON COLUMN btrace_gov.policies.updated_at IS 
'Automatically updated when the policy is modified. Used for audit and change tracking.';

COMMENT ON COLUMN btrace_gov.policies.created_by IS 
'User who created the policy. NULL if seeded or automated.';

COMMENT ON COLUMN btrace_gov.policies.updated_by IS 
'Last user to update the policy. NULL if untracked.';

-- get current active policies 
SELECT policy_name, version, policy_type, effective_date, review_date
FROM btrace_gov.policies
WHERE is_active = TRUE
ORDER BY policy_type, policy_name;

SELECT policy_name, version, review_date, committee_id
FROM btrace_gov.policies
WHERE is_active = TRUE
  AND review_date IS NOT NULL
  AND review_date <= NOW() + INTERVAL '7 days'
ORDER BY review_date;

SELECT c.committee_name, p.policy_name, p.version, p.effective_date
FROM btrace_gov.policies p
JOIN btrace_gov.governance_committees c ON p.committee_id = c.committee_id
WHERE p.is_active = TRUE
ORDER BY c.committee_name, p.policy_name;

--- check compliance for SOC2, ISO27001, GDPR Compliance 


-- Policy Approvals
--
-- BUSINESS CASE:
-- The `policy_approvals` table records formal approvals of data governance policies by stakeholders or committee members.
-- It ensures accountability, supports compliance audits (e.g., SOX, GDPR), and provides a clear chain of authorization.
-- This table is essential for proving that policies were reviewed and accepted by responsible parties.
--
-- PURPOSE:
-- - Track who approved a policy and when
-- - Support multi-stakeholder approval workflows
-- - Enable audit trails for regulatory compliance
-- - Facilitate policy activation (e.g., "effective after 2 approvals")
-- - Integrate with notification and review systems
--

CREATE TABLE btrace_gov.policy_approvals (
    approval_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_id      UUID NOT NULL,
    approved_by    UUID NOT NULL,
    approval_date  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status         VARCHAR(20) NOT NULL DEFAULT 'approved',
    comments       TEXT,

    -- Enforce valid status
    CONSTRAINT chk_approval_status 
        CHECK (status IN ('approved', 'rejected', 'pending')),

    -- Foreign Keys
    CONSTRAINT fk_policy_approvals_policy_id 
        FOREIGN KEY (policy_id) 
        REFERENCES btrace_gov.policies (policy_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_policy_approvals_approved_by 
        FOREIGN KEY (approved_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE
);

-- Fast: "What policies has this user approved?"
CREATE INDEX idx_policy_approvals_by_user 
ON btrace_gov.policy_approvals (approved_by);

-- Fast: "Show all approvals for this policy"
CREATE INDEX idx_policy_approvals_by_policy 
ON btrace_gov.policy_approvals (policy_id);

-- Find recent approvals (dashboard, audit)
CREATE INDEX idx_policy_approvals_date 
ON btrace_gov.policy_approvals (approval_date DESC);

-- Filter by status (if using multi-state workflow)
CREATE INDEX idx_policy_approvals_status 
ON btrace_gov.policy_approvals (status);

-- Covering index for audit reports
CREATE INDEX idx_policy_approvals_covering 
ON btrace_gov.policy_approvals (policy_id, approval_date DESC)
INCLUDE (approved_by, status, comments);

COMMENT ON TABLE btrace_gov.policy_approvals IS 
'Records formal approvals (or rejections) of governance policies. Each entry represents a stakeholder''s sign-off, enabling audit trails and compliance reporting. Used to enforce policy activation workflows and demonstrate organizational accountability.';

COMMENT ON COLUMN btrace_gov.policy_approvals.approval_id IS 
'Unique identifier for the approval record. Used in audit logs and APIs.';

COMMENT ON COLUMN btrace_gov.policy_approvals.policy_id IS 
'References the policy being approved. Cascades delete if policy is removed.';

COMMENT ON COLUMN btrace_gov.policy_approvals.approved_by IS 
'References the user who provided the approval. Must be a valid system user.';

COMMENT ON COLUMN btrace_gov.policy_approvals.approval_date IS 
'Timestamp when the approval was recorded. Typically the time of submission or review completion.';

COMMENT ON COLUMN btrace_gov.policy_approvals.status IS 
'Status of the approval: approved, rejected, or pending. Enables formal review workflows and escalation.';

COMMENT ON COLUMN btrace_gov.policy_approvals.comments IS 
'Optional feedback or rationale from the approver (e.g., "Meets security standards with minor edits").';


-- get all approvals for a policy 
SELECT u.username, pa.status, pa.approval_date, pa.comments
FROM btrace_gov.policy_approvals pa
JOIN btrace_rbac.users u ON pa.approved_by = u.user_id
WHERE pa.policy_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY pa.approval_date DESC;

-- get the count approvals classified by status
SELECT 
    status,
    COUNT(*) as count,
    MIN(approval_date) as first,
    MAX(approval_date) as last
FROM btrace_gov.policy_approvals
WHERE policy_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
GROUP BY status;

-- we should also get unapproved policies or pending policies 
SELECT p.policy_name, p.version
FROM btrace_gov.policies p
LEFT JOIN btrace_gov.policy_approvals pa 
    ON p.policy_id = pa.policy_id AND pa.status = 'approved'
WHERE pa.policy_id IS NULL
  AND p.is_active = TRUE;

-- Data Domains
--
-- BUSINESS CASE:
-- The `data_domains` table defines logical business areas of data ownership (e.g., "Observability", "User Management", "Billing").
-- It enables structured data governance by assigning clear ownership and stewardship responsibilities.
-- This is essential for compliance, impact analysis, and ensuring accountability across teams.
--
-- PURPOSE:
-- - Organize data assets by business function
-- - Assign data owners and stewards
-- - Support classification, lineage, and access control
-- - Enable domain-based policies and dashboards
-- - Facilitate compliance reporting (e.g., "Who owns PII in the Billing domain?")
--

CREATE TABLE btrace_gov.data_domains (
    domain_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    domain_name      VARCHAR(100) NOT NULL,
    description      TEXT,
    data_owner_id    UUID,
    data_steward_id  UUID,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE,
    created_by       UUID,
    updated_by       UUID,

    -- Enforce unique domain names
    CONSTRAINT uq_domain_name 
        UNIQUE (domain_name),

    -- Prevent owner/steward from being the same unless intentional
    -- Optional: remove if allowed
    CONSTRAINT chk_owner_steward_different 
        CHECK (data_owner_id IS NULL OR data_steward_id IS NULL OR data_owner_id != data_steward_id),

    -- Foreign Keys
    CONSTRAINT fk_data_domains_owner 
        FOREIGN KEY (data_owner_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_data_domains_steward 
        FOREIGN KEY (data_steward_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_data_domains_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_data_domains_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by domain name
CREATE INDEX idx_data_domains_name ON btrace_gov.data_domains (domain_name);

-- Find domains by owner or steward
CREATE INDEX idx_data_domains_owner ON btrace_gov.data_domains (data_owner_id) 
WHERE data_owner_id IS NOT NULL;

CREATE INDEX idx_data_domains_steward ON btrace_gov.data_domains (data_steward_id) 
WHERE data_steward_id IS NOT NULL;

-- Audit: who created/updated domains?
CREATE INDEX idx_data_domains_created_by ON btrace_gov.data_domains (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_data_domains_updated_by ON btrace_gov.data_domains (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for domain listing (UI, API)
CREATE INDEX idx_data_domains_covering 
ON btrace_gov.data_domains (domain_name)
INCLUDE (description, data_owner_id, data_steward_id, created_at);


-- Reuse or create the updated_at function in btrace_gov schema
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_data_domains_updated_at
    BEFORE UPDATE ON btrace_gov.data_domains
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_gov.data_domains IS 
'Logical business areas of data ownership (e.g., "Billing", "User Management", "Observability"). Used to assign data owners and stewards, enforce policies, and organize governance efforts by functional domain.';

COMMENT ON COLUMN btrace_gov.data_domains.domain_id IS 
'Unique identifier for the data domain. Used in foreign keys and APIs.';

COMMENT ON COLUMN btrace_gov.data_domains.domain_name IS 
'Human-readable name of the domain (e.g., "Telemetry", "Payments"). Must be unique. Used for classification and policy assignment.';

COMMENT ON COLUMN btrace_gov.data_domains.description IS 
'Description of the domain''s scope, data types, and business purpose (e.g., "Contains all user session and trace data").';

COMMENT ON COLUMN btrace_gov.data_domains.data_owner_id IS 
'References the business or technical leader accountable for the data (e.g., VP of Engineering). Responsible for high-level decisions and compliance. NULL if unassigned.';

COMMENT ON COLUMN btrace_gov.data_domains.data_steward_id IS 
'References the operational owner responsible for data quality, metadata, and day-to-day governance (e.g., SRE Lead). Works under the data owner. NULL if unassigned.';

COMMENT ON COLUMN btrace_gov.data_domains.created_at IS 
'Timestamp when the domain was registered.';

COMMENT ON COLUMN btrace_gov.data_domains.updated_at IS 
'Automatically updated when the domain is modified. Used for audit and change tracking.';

COMMENT ON COLUMN btrace_gov.data_domains.created_by IS 
'Optional: user who created the domain. NULL if seeded or automated.';

COMMENT ON COLUMN btrace_gov.data_domains.updated_by IS 
'Optional: last user to update the domain. NULL if untracked.';

-- GDPR Compliance: Data Subjects
CREATE TABLE btrace_gov.data_subjects (
    subject_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_type VARCHAR(50) NOT NULL,
    identifier_key VARCHAR(100) NOT NULL,
    identifier_value VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_subject_identifier UNIQUE (subject_type, identifier_key, identifier_value)
);
COMMENT ON TABLE btrace_gov.data_subjects IS 'Individuals whose data is processed (for GDPR compliance)';
COMMENT ON COLUMN btrace_gov.data_subjects.subject_type IS 'Type of subject (e.g., customer, employee)';
COMMENT ON COLUMN btrace_gov.data_subjects.identifier_key IS 'Field used to identify the subject (e.g., email, user_id)';
COMMENT ON COLUMN btrace_gov.data_subjects.identifier_value IS 'Value of the identifier field';

---find domains by owner 
SELECT d.domain_name, d.description
FROM btrace_gov.data_domains d
WHERE d.data_owner_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678';

-- list all domains with owners and stewards
SELECT 
    d.domain_name,
    u1.username AS owner,
    u2.username AS steward,
    d.description
FROM btrace_gov.data_domains d
LEFT JOIN btrace_rbac.users u1 ON d.data_owner_id = u1.user_id
LEFT JOIN btrace_rbac.users u2 ON d.data_steward_id = u2.user_id
ORDER BY d.domain_name;


-- GDPR Compliance: Data Subjects 
--
-- BUSINESS CASE:
-- The `data_subjects` table identifies individuals (e.g., users, customers) whose personal data is collected and processed.
-- It supports privacy rights management (e.g., GDPR, CCPA), consent tracking, and data subject access requests (DSARs).
-- This table is essential for compliance and accountability.
--
-- PURPOSE:
-- - Uniquely identify data subjects in the system
-- - Support consent, data access, and deletion workflows
-- - Enable auditability of personal data processing
-- - Serve as anchor for consent, classification, and retention policies
--

CREATE TABLE btrace_gov.data_subjects (
    subject_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_identifier VARCHAR(255) NOT NULL,
    identifier_type    VARCHAR(50) NOT NULL DEFAULT 'user_id',
    first_name         VARCHAR(100),
    last_name          VARCHAR(100),
    email              VARCHAR(255),
    phone              VARCHAR(50),
    country            VARCHAR(100),
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP WITH TIME ZONE,

    -- Enforce uniqueness of subject identifiers
    CONSTRAINT uq_subject_identifier_type 
        UNIQUE (subject_identifier, identifier_type),

    -- Validate identifier type
    CONSTRAINT chk_identifier_type 
        CHECK (identifier_type IN ('user_id', 'email', 'phone', 'external_id', 'anonymous_id'))
);

-- Fast lookup by identifier (e.g., email)
CREATE INDEX idx_data_subjects_identifier 
ON btrace_gov.data_subjects (subject_identifier, identifier_type);

-- Filter by email (common in DSARs)
CREATE INDEX idx_data_subjects_email 
ON btrace_gov.data_subjects (email) 
WHERE email IS NOT NULL;

-- Filter by country (for GDPR localization)
CREATE INDEX idx_data_subjects_country 
ON btrace_gov.data_subjects (country) 
WHERE country IS NOT NULL;

-- Covering index for consent and DSAR queries
CREATE INDEX idx_data_subjects_covering 
ON btrace_gov.data_subjects (subject_id)
INCLUDE (subject_identifier, identifier_type, email, first_name, last_name);

-- Ensure the function exists
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
CREATE TRIGGER update_data_subjects_updated_at
    BEFORE UPDATE ON btrace_gov.data_subjects
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.data_subjects IS 
'Represents individuals (e.g., users, customers) whose personal data is collected. Used for consent management, DSARs, and compliance with privacy regulations (e.g., GDPR, CCPA).';

COMMENT ON COLUMN btrace_gov.data_subjects.subject_id IS 
'Internal unique identifier for the data subject. Used in foreign keys and APIs.';

COMMENT ON COLUMN btrace_gov.data_subjects.subject_identifier IS 
'The actual identifier (e.g., "user_123", "john@example.com") used to reference the subject in systems.';

COMMENT ON COLUMN btrace_gov.data_subjects.identifier_type IS 
'Type of identifier: user_id, email, phone, external_id, anonymous_id. Helps distinguish identity sources.';

COMMENT ON COLUMN btrace_gov.data_subjects.first_name IS 
'First name of the individual. Optional, may be redacted for privacy.';

COMMENT ON COLUMN btrace_gov.data_subjects.last_name IS 
'Last name of the individual. Optional.';

COMMENT ON COLUMN btrace_gov.data_subjects.email IS 
'Email address. Used for communication and DSAR fulfillment.';

COMMENT ON COLUMN btrace_gov.data_subjects.phone IS 
'Phone number. Optional.';

COMMENT ON COLUMN btrace_gov.data_subjects.country IS 
'Country of residence. Used for regional compliance (e.g., GDPR applies to EU residents).';

COMMENT ON COLUMN btrace_gov.data_subjects.created_at IS 
'Timestamp when the subject was first recorded in the system.';

COMMENT ON COLUMN btrace_gov.data_subjects.updated_at IS 
'Automatically updated when subject details are modified.';


-- GDPR Compliance: Consent Records
--
-- BUSINESS CASE:
-- The `consent_records` table stores formal records of consent given by data subjects (e.g., users, customers) 
-- for the collection, use, or sharing of their personal data. It is essential for regulatory compliance (e.g., GDPR, CCPA),
-- auditability, and user trust. This table enables organizations to prove lawful processing and support data subject rights.
--
-- PURPOSE:
-- - Track when, how, and why consent was obtained
-- - Support consent withdrawal and audit trails
-- - Enable compliance reporting and data subject access requests (DSARs)
-- - Facilitate data minimization and purpose limitation
-- - Integrate with privacy dashboards and consent banners
--

CREATE TABLE btrace_gov.consent_records (
    consent_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id         UUID NOT NULL,
    purpose            VARCHAR(100) NOT NULL,
    consent_type       VARCHAR(50) NOT NULL,
    consent_given      BOOLEAN NOT NULL,
    consent_date       TIMESTAMP WITH TIME ZONE NOT NULL,
    expiration_date    TIMESTAMP WITH TIME ZONE,
    collection_method  VARCHAR(50) NOT NULL,
    version            VARCHAR(20) NOT NULL,
    evidence           TEXT,  -- Optional: JSON, URL, or description of proof
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP WITH TIME ZONE,
    created_by         UUID,  -- Who recorded the consent (e.g., system, admin)
    updated_by         UUID,  -- Who last updated it (e.g., on withdrawal)

    -- Enforce valid consent types
    CONSTRAINT chk_consent_type 
        CHECK (consent_type IN ('marketing', 'analytics', 'personalization', 'third_party_sharing', 'essential', 'security')),

    -- Enforce valid collection methods
    CONSTRAINT chk_collection_method 
        CHECK (collection_method IN ('web_form', 'api', 'mobile_app', 'checkbox', 'implicit', 'admin_granted')),

    -- Prevent invalid date logic
    CONSTRAINT chk_consent_date_not_future 
        CHECK (consent_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute'),

    CONSTRAINT chk_expiration_after_consent 
        CHECK (expiration_date IS NULL OR expiration_date > consent_date),

    -- Foreign Keys
    CONSTRAINT fk_consent_subject_id 
        FOREIGN KEY (subject_id) 
        REFERENCES btrace_gov.data_subjects (subject_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_consent_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_consent_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- GDPR Compliance: Data Processing Activities
--
-- BUSINESS CASE:
-- The `data_processing_activities` table documents all data processing operations conducted by the organization,
-- in compliance with GDPR Article 30. It records the purpose, legal basis, controllers, processors, and retention policies.
-- This table is essential for regulatory audits, transparency, and accountability.
--
-- PURPOSE:
-- - Maintain a formal Record of Processing Activities (RoPA)
-- - Demonstrate lawful basis for data processing
-- - Support Data Protection Impact Assessments (DPIAs)
-- - Enable oversight by Data Protection Officers (DPOs)
-- - Facilitate responses to regulatory inquiries
--

CREATE TABLE btrace_gov.data_processing_activities (
    activity_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_name     VARCHAR(100) NOT NULL,
    description       TEXT,
    legal_basis       VARCHAR(100) NOT NULL,
    data_controller   VARCHAR(255),
    data_processor    VARCHAR(255),
    retention_period  VARCHAR(50) NOT NULL,
    domain_id         UUID,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE,
    created_by        UUID,
    updated_by        UUID,

    -- Enforce valid legal bases (GDPR-compliant)
    CONSTRAINT chk_legal_basis 
        CHECK (legal_basis IN (
            'consent', 
            'contract', 
            'legal_obligation', 
            'vital_interests', 
            'public_task', 
            'legitimate_interests'
        )),

    -- Enforce valid retention periods
    CONSTRAINT chk_retention_period 
        CHECK (retention_period IN (
            '24_hours', '7_days', '30_days', '90_days', '180_days', '1_year', 
            '2_years', 'indefinite', 'erased_on_request'
        )),

    -- Foreign Keys
    CONSTRAINT fk_dpa_domain_id 
        FOREIGN KEY (domain_id) 
        REFERENCES btrace_gov.data_domains (domain_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_dpa_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_dpa_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by name
CREATE INDEX idx_dpa_name ON btrace_gov.data_processing_activities (activity_name);

-- Filter by legal basis (audit requirement)
CREATE INDEX idx_dpa_legal_basis ON btrace_gov.data_processing_activities (legal_basis);

-- Filter by retention period
CREATE INDEX idx_dpa_retention ON btrace_gov.data_processing_activities (retention_period);

-- Find all activities in a data domain
CREATE INDEX idx_dpa_domain_id ON btrace_gov.data_processing_activities (domain_id) WHERE domain_id IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_dpa_created_by ON btrace_gov.data_processing_activities (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_dpa_updated_by ON btrace_gov.data_processing_activities (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for RoPA reports and exports
CREATE INDEX idx_dpa_covering 
ON btrace_gov.data_processing_activities (activity_name, legal_basis)
INCLUDE (description, data_controller, data_processor, retention_period, domain_id, created_at);

-- Reuse or create the updated_at function (if not already created)
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_data_processing_activities_updated_at
    BEFORE UPDATE ON btrace_gov.data_processing_activities
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.data_processing_activities IS 
'Record of Processing Activities (RoPA) as required by GDPR Article 30. Documents each data processing operation, including purpose, legal basis, controllers, processors, and retention. Used for compliance audits, DPO reviews, and regulatory reporting.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.activity_id IS 
'Unique identifier for the processing activity. Used in APIs and audit logs.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.activity_name IS 
'Human-readable name of the processing activity (e.g., "User Login Monitoring", "Billing Data Processing"). Should be clear and consistent.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.description IS 
'Detailed explanation of what data is processed, how, and why. Includes systems involved and data categories.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.legal_basis IS 
'Lawful basis for processing under GDPR: consent, contract, legal obligation, vital interests, public task, or legitimate interests. Required for compliance.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.data_controller IS 
'Organization or role responsible for determining the purposes of processing (e.g., "Acme Inc.", "Chief Privacy Officer"). May be internal or external.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.data_processor IS 
'Organization or service that processes data on behalf of the controller (e.g., "AWS", "Datadog", "Internal Observability Team").';

COMMENT ON COLUMN btrace_gov.data_processing_activities.retention_period IS 
'How long personal data is retained before deletion or anonymization. Supports data minimization principle.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.domain_id IS 
'References the data domain this activity belongs to (e.g., "User Management", "Telemetry"). Helps organize RoPA by business area.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.created_at IS 
'Timestamp when the activity was registered in the system.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.updated_at IS 
'Automatically updated when the record is modified. Used for audit and change tracking.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.created_by IS 
'Optional: user who documented this processing activity. NULL if seeded or automated.';

COMMENT ON COLUMN btrace_gov.data_processing_activities.updated_by IS 
'Optional: last user to update the activity details. NULL if untracked.';

--GDPR: Record of Processing Activity (RoPA)Report
SELECT 
    activity_name,
    d.description,
    legal_basis,
    data_controller,
    data_processor,
    retention_period,
    d.domain_name AS data_domain
FROM btrace_gov.data_processing_activities a
LEFT JOIN btrace_gov.data_domains d ON a.domain_id = d.domain_id
ORDER BY a.activity_name;
-- find all activites based on "legitimate interests"
SELECT activity_name, description
FROM btrace_gov.data_processing_activities
WHERE legal_basis = 'legitimate_interests';
-- list activities by retention policy 
SELECT retention_period, COUNT(*) AS count
FROM btrace_gov.data_processing_activities
GROUP BY retention_period
ORDER BY count DESC;
	
-- GDPR Compliance: Subject Access Requests
--
-- BUSINESS CASE:
-- The `subject_access_requests` table manages Data Subject Access Requests (DSARs) — formal inquiries from individuals
-- exercising their privacy rights (e.g., access, deletion, correction of their personal data).
-- This table is essential for compliance with GDPR, CCPA, and other privacy laws, ensuring timely, auditable, and accountable responses.
--
-- PURPOSE:
-- - Track the lifecycle of DSARs from submission to completion
-- - Assign ownership and enforce SLAs (e.g., 30-day response window)
-- - Support audit and regulatory reporting
-- - Enable integration with privacy portals and ticketing systems
-- - Facilitate proof of compliance
--

CREATE TABLE btrace_gov.subject_access_requests (
    request_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id      UUID NOT NULL,
    request_type    VARCHAR(50) NOT NULL,
    request_date    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) NOT NULL,
    due_date        TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_date  TIMESTAMP WITH TIME ZONE,
    notes           TEXT,
    assigned_to     UUID,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,
    created_by      UUID,  -- Who submitted or created the request
    updated_by      UUID,  -- Who last updated it (e.g., case worker)

    -- Enforce valid request types (aligned with privacy rights)
    CONSTRAINT chk_request_type 
        CHECK (request_type IN (
            'access',           -- Right to access
            'rectification',    -- Right to correct
            'erasure',          -- Right to be forgotten
            'restriction',      -- Right to restrict processing
            'portability',      -- Right to data portability
            'objection'         -- Right to object
        )),

    -- Enforce valid status values
    CONSTRAINT chk_status 
        CHECK (status IN (
            'submitted', 
            'in_progress', 
            'on_hold', 
            'completed', 
            'rejected', 
            'cancelled'
        )),

    -- Ensure due_date >= request_date
    CONSTRAINT chk_due_date_after_request 
        CHECK (due_date >= request_date),

    -- Ensure completed_date is not before request_date
    CONSTRAINT chk_completed_date_valid 
        CHECK (completed_date IS NULL OR completed_date >= request_date),

    -- Foreign Keys
    CONSTRAINT fk_dsar_subject_id 
        FOREIGN KEY (subject_id) 
        REFERENCES btrace_gov.data_subjects (subject_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_dsar_assigned_to 
        FOREIGN KEY (assigned_to) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_dsar_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_dsar_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all requests for this data subject"
CREATE INDEX idx_dsar_subject_id ON btrace_gov.subject_access_requests (subject_id);

-- Filter by status (e.g., "show all in_progress")
CREATE INDEX idx_dsar_status ON btrace_gov.subject_access_requests (status);

-- Find overdue requests (critical for SLA compliance)
CREATE INDEX idx_dsar_due_date 
ON btrace_gov.subject_access_requests (due_date)
WHERE status NOT IN ('completed', 'rejected', 'cancelled');

-- Find completed requests (audit)
CREATE INDEX idx_dsar_completed_date 
ON btrace_gov.subject_access_requests (completed_date)
WHERE completed_date IS NOT NULL;

-- Filter by request type
CREATE INDEX idx_dsar_request_type ON btrace_gov.subject_access_requests (request_type);

-- Who is handling what?
CREATE INDEX idx_dsar_assigned_to ON btrace_gov.subject_access_requests (assigned_to) WHERE assigned_to IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_dsar_created_by ON btrace_gov.subject_access_requests (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_dsar_updated_by ON btrace_gov.subject_access_requests (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for DSAR dashboard
CREATE INDEX idx_dsar_covering 
ON btrace_gov.subject_access_requests (status, request_date DESC)
INCLUDE (request_type, subject_id, due_date, completed_date, assigned_to, notes);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_subject_access_requests_updated_at
    BEFORE UPDATE ON btrace_gov.subject_access_requests
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.subject_access_requests IS 
'Tracks Data Subject Access Requests (DSARs) submitted under privacy regulations (e.g., GDPR, CCPA). Each record represents a formal request from an individual to access, correct, delete, or transfer their personal data. Used for compliance, SLA tracking, and audit reporting.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.request_id IS 
'Unique identifier for the DSAR. Used in case management and communication.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.subject_id IS 
'References the individual (data subject) making the request. Cascades delete if subject is removed.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.request_type IS 
'Type of privacy right being exercised: access, rectification, erasure, restriction, portability, objection. Must align with applicable law.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.request_date IS 
'Date when the request was received. Start of the compliance clock (e.g., 30-day response window).';

COMMENT ON COLUMN btrace_gov.subject_access_requests.status IS 
'Current lifecycle stage: submitted, in_progress, on_hold, completed, rejected, cancelled. Used for workflow tracking.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.due_date IS 
'Deadline for responding to the request (e.g., 30 days from request_date). Critical for SLA and regulatory compliance.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.completed_date IS 
'Date when the request was fully resolved. NULL if not yet completed.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.notes IS 
'Internal notes, actions taken, or correspondence related to the request. Not shared with the subject unless required.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.assigned_to IS 
'References the team member or DPO responsible for handling the request. NULL if unassigned.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.created_at IS 
'Timestamp when the request was created in the system.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.updated_at IS 
'Automatically updated when the request is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.created_by IS 
'Optional: user who created the request (e.g., via portal, admin entry). NULL if submitted by subject directly.';

COMMENT ON COLUMN btrace_gov.subject_access_requests.updated_by IS 
'Optional: last user to update the request status or notes. NULL if untracked.';


-- find overdue DSARs
SELECT r.request_id, d.subject_identifier, r.request_type, r.due_date
FROM btrace_gov.subject_access_requests r
JOIN btrace_gov.data_subjects d ON r.subject_id = d.subject_id
WHERE r.status NOT IN ('completed', 'rejected', 'cancelled')
  AND r.due_date < NOW()
ORDER BY r.due_date;

--Generate DSAR Report 
SELECT 
    r.request_type,
    r.status,
    r.request_date,
    r.due_date,
    r.completed_date,
    u.username AS assigned_to,
    d.email AS subject_email
FROM btrace_gov.subject_access_requests r
LEFT JOIN btrace_rbac.users u ON r.assigned_to = u.user_id
LEFT JOIN btrace_gov.data_subjects d ON r.subject_id = d.subject_id
ORDER BY r.request_date DESC;

--
-- BUSINESS CASE:
-- The `dsar_evidence` table stores proof that actions were taken in response to a Data Subject Access Request (DSAR).
-- This includes exported data files, deletion logs, anonymization records, or system snapshots.
-- It is essential for audit trails, regulatory compliance, and dispute resolution.
--
-- PURPOSE:
-- - Maintain verifiable proof of DSAR fulfillment
-- - Support internal and external audits
-- - Demonstrate compliance with GDPR/CCPA
-- - Enable traceability of data handling
--

CREATE TABLE btrace_gov.dsar_evidence (
    evidence_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id      UUID NOT NULL,
    evidence_type   VARCHAR(50) NOT NULL,
    description     TEXT,
    file_name       VARCHAR(255),  -- Original filename
    file_path       TEXT,          -- Secure path or URL (e.g., S3, encrypted blob)
    file_size       BIGINT,        -- In bytes
    media_type      VARCHAR(100),  -- MIME type (e.g., application/pdf, text/csv)
    uploaded_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by     UUID,          -- Who uploaded the evidence
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,

    -- Enforce valid evidence types
    CONSTRAINT chk_evidence_type 
        CHECK (evidence_type IN (
            'data_export',         -- JSON/CSV of user data
            'deletion_log',        -- System log showing deletion
            'anonymization_proof', -- Before/after comparison
            'consent_snapshot',    -- Consent state at time of request
            'system_audit_log',    -- Access logs
            'redaction_proof',     -- Edited documents
            'other'
        )),

    -- Foreign Keys
    CONSTRAINT fk_evidence_request_id 
        FOREIGN KEY (request_id) 
        REFERENCES btrace_gov.subject_access_requests (request_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_evidence_uploaded_by 
        FOREIGN KEY (uploaded_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all evidence for this DSAR"
CREATE INDEX idx_dsar_evidence_request_id ON btrace_gov.dsar_evidence (request_id);

-- Filter by type (e.g., show all data exports)
CREATE INDEX idx_dsar_evidence_type ON btrace_gov.dsar_evidence (evidence_type);

-- Find recently uploaded evidence
CREATE INDEX idx_dsar_evidence_uploaded_at 
ON btrace_gov.dsar_evidence (uploaded_at DESC);

-- Audit: who uploaded what?
CREATE INDEX idx_dsar_evidence_uploaded_by 
ON btrace_gov.dsar_evidence (uploaded_by) 
WHERE uploaded_by IS NOT NULL;

-- Covering index for audit export
CREATE INDEX idx_dsar_evidence_covering 
ON btrace_gov.dsar_evidence (request_id, evidence_type)
INCLUDE (file_name, file_size, media_type, uploaded_at, uploaded_by);

CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_dsar_evidence_updated_at
    BEFORE UPDATE ON btrace_gov.dsar_evidence
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.dsar_evidence IS 
'Proof of actions taken during a DSAR (e.g., data exports, deletion logs). Used for audits, compliance, and legal defense.';

COMMENT ON COLUMN btrace_gov.dsar_evidence.evidence_id IS 'Unique ID for the evidence item.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.request_id IS 'Links to the DSAR being supported.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.evidence_type IS 'Category of evidence: data_export, deletion_log, etc.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.description IS 'Details about what this evidence shows.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.file_name IS 'Original name of the uploaded file.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.file_path IS 'Secure location (e.g., S3 key, encrypted blob ID). Never expose publicly.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.file_size IS 'Size in bytes for validation.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.media_type IS 'MIME type (e.g., application/json).';
COMMENT ON COLUMN btrace_gov.dsar_evidence.uploaded_at IS 'When the evidence was added.';
COMMENT ON COLUMN btrace_gov.dsar_evidence.uploaded_by IS 'User who uploaded the proof (e.g., DPO, admin).';

--
-- BUSINESS CASE:
-- The `dsar_communications` table records all messages sent and received during a Data Subject Access Request (DSAR).
-- This includes emails to the subject, internal team discussions, and status updates.
-- It ensures transparency, accountability, and compliance with response timelines.
--
-- PURPOSE:
-- - Maintain a full communication history for each DSAR
-- - Support audit and dispute resolution
-- - Prevent miscommunication or missed responses
-- - Enable collaboration between privacy, legal, and support teams
--

CREATE TABLE btrace_gov.dsar_communications (
    communication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id       UUID NOT NULL,
    direction        VARCHAR(10) NOT NULL,  -- 'inbound' or 'outbound'
    channel          VARCHAR(20) NOT NULL,  -- 'email', 'portal', 'phone', 'internal'
    sender           VARCHAR(255),          -- Email or name
    recipient        VARCHAR(255),          -- Email or name
    subject          VARCHAR(255),          -- For emails
    body             TEXT NOT NULL,
    sent_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at     TIMESTAMP WITH TIME ZONE,
    read_at          TIMESTAMP WITH TIME ZONE,
    is_internal      BOOLEAN NOT NULL DEFAULT FALSE,  -- Internal note vs. sent message
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by       UUID,  -- Who sent or recorded the message

    -- Enforce direction
    CONSTRAINT chk_direction 
        CHECK (direction IN ('inbound', 'outbound')),

    -- Enforce channel
    CONSTRAINT chk_channel 
        CHECK (channel IN ('email', 'portal', 'phone', 'internal', 'letter', 'api')),

    -- Foreign Keys
    CONSTRAINT fk_comm_request_id 
        FOREIGN KEY (request_id) 
        REFERENCES btrace_gov.subject_access_requests (request_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_comm_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast: "Show all comms for this DSAR"
CREATE INDEX idx_dsar_comm_request_id ON btrace_gov.dsar_communications (request_id);

-- Filter by direction
CREATE INDEX idx_dsar_comm_direction ON btrace_gov.dsar_communications (direction);

-- Filter by channel
CREATE INDEX idx_dsar_comm_channel ON btrace_gov.dsar_communications (channel);

-- Find unread or undelivered messages
CREATE INDEX idx_dsar_comm_status 
ON btrace_gov.dsar_communications (delivered_at, read_at)
WHERE delivered_at IS NULL OR read_at IS NULL;

-- Internal notes only
CREATE INDEX idx_dsar_comm_internal 
ON btrace_gov.dsar_communications (is_internal) 
WHERE is_internal = TRUE;

-- Covering index for message timeline
CREATE INDEX idx_dsar_comm_covering 
ON btrace_gov.dsar_communications (request_id, sent_at DESC)
INCLUDE (direction, sender, recipient, subject, is_internal, created_by);

COMMENT ON TABLE btrace_gov.dsar_communications IS 
'All messages related to a DSAR — emails, portal messages, internal notes. Used for audit, collaboration, and compliance.';

COMMENT ON COLUMN btrace_gov.dsar_communications.communication_id IS 'Unique ID for the message.';
COMMENT ON COLUMN btrace_gov.dsar_communications.request_id IS 'Links to the DSAR.';
COMMENT ON COLUMN btrace_gov.dsar_communications.direction IS 'Was the message sent (outbound) or received (inbound)?';
COMMENT ON COLUMN btrace_gov.dsar_communications.channel IS 'How was it sent? email, portal, phone, etc.';
COMMENT ON COLUMN btrace_gov.dsar_communications.sender IS 'Email or name of sender.';
COMMENT ON COLUMN btrace_gov.dsar_communications.recipient IS 'Email or name of recipient.';
COMMENT ON COLUMN btrace_gov.dsar_communications.subject IS 'Email subject line.';
COMMENT ON COLUMN btrace_gov.dsar_communications.body IS 'Full message content (plain text or HTML).';
COMMENT ON COLUMN btrace_gov.dsar_communications.sent_at IS 'When the message was sent.';
COMMENT ON COLUMN btrace_gov.dsar_communications.delivered_at IS 'When delivery was confirmed (e.g., read receipt).';
COMMENT ON COLUMN btrace_gov.dsar_communications.read_at IS 'When the message was read.';
COMMENT ON COLUMN btrace_gov.dsar_communications.is_internal IS 'If TRUE, this is a private note (not sent to the subject).';
COMMENT ON COLUMN btrace_gov.dsar_communications.created_by IS 'User who sent or logged the message.';

-- Need to think of integration with OneTrust, Cookiebot or inhouse SAAS Tols (Awase)

--
-- BUSINESS CASE:
-- The `notification_templates` table stores reusable message templates for common governance events
-- (e.g., DSAR confirmation, consent expiration, policy review).
-- Ensures consistent, compliant, and localized communication.
--
-- PURPOSE:
-- - Standardize messaging across the platform
-- - Support multilingual content
-- - Enable quick deployment of new alerts
-- - Reduce errors in manual messaging
--

CREATE TABLE btrace_gov.notification_templates (
    template_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_key    VARCHAR(100) NOT NULL,
    channel         VARCHAR(20) NOT NULL,
    language        VARCHAR(10) NOT NULL DEFAULT 'en-US',
    subject         VARCHAR(255),
    body            TEXT NOT NULL,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,

    -- Enforce valid channels
    CONSTRAINT chk_template_channel 
        CHECK (channel IN ('email', 'slack', 'sms', 'webhook')),

    -- Enforce valid language format
    CONSTRAINT chk_language_format 
        CHECK (language ~ '^[a-z]{2}(-[A-Z]{2})?$'),

    -- Unique key + channel + language
    CONSTRAINT uq_template_key_channel_lang 
        UNIQUE (template_key, channel, language)
);

CREATE INDEX idx_templates_key ON btrace_gov.notification_templates (template_key);
CREATE INDEX idx_templates_channel ON btrace_gov.notification_templates (channel);
CREATE INDEX idx_templates_active ON btrace_gov.notification_templates (is_active);
COMMENT ON TABLE btrace_gov.notification_templates IS 
'Reusable message templates for automated notifications (e.g., DSAR confirmation, consent expiry). Ensures consistency and compliance.';

COMMENT ON COLUMN btrace_gov.notification_templates.template_key IS 'Logical key (e.g., "dsar_submitted", "consent_expiring") used in code.';
COMMENT ON COLUMN btrace_gov.notification_templates.channel IS 'Delivery method: email, slack, etc.';
COMMENT ON COLUMN btrace_gov.notification_templates.language IS 'Locale (e.g., en-US, fr-FR).';
COMMENT ON COLUMN btrace_gov.notification_templates.subject IS 'Email subject or Slack title.';
COMMENT ON COLUMN btrace_gov.notification_templates.body IS 'Message content with placeholders (e.g., {{user_name}}, {{due_date}}).';
COMMENT ON COLUMN btrace_gov.notification_templates.is_active IS 'If FALSE, template is disabled (not used in sends).';


--outbound notifications 

--
-- BUSINESS CASE:
-- The `notifications` table tracks all outbound messages sent to users, teams, or systems
-- as part of governance workflows (e.g., DSAR updates, policy reviews).
-- It enables delivery tracking, retries, and auditability.
--
-- PURPOSE:
-- - Send timely alerts for time-sensitive events
-- - Track delivery status (sent, delivered, failed)
-- - Support multi-channel delivery
-- - Maintain audit trail for compliance
--

CREATE TABLE btrace_gov.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id     UUID NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    channel         VARCHAR(20) NOT NULL,
    recipient_type  VARCHAR(20) NOT NULL,  -- 'user', 'team', 'email', 'slack_channel'
    recipient_id    UUID,                  -- For users/teams
    recipient_value VARCHAR(255),          -- For email, Slack channel, phone
    subject         VARCHAR(255),
    body            TEXT NOT NULL,
    context_data    JSONB,                 -- { "request_id": "x", "due_date": "..." }
    scheduled_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at         TIMESTAMP WITH TIME ZONE,
    delivered_at    TIMESTAMP WITH TIME ZONE,
    read_at         TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    failure_reason  TEXT,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,

    -- Constraints
    CONSTRAINT chk_channel 
        CHECK (channel IN ('email', 'slack', 'sms', 'webhook')),

    CONSTRAINT chk_recipient_type 
        CHECK (recipient_type IN ('user', 'team', 'email', 'slack_channel', 'phone')),

    CONSTRAINT chk_status 
        CHECK (status IN ('pending', 'sending', 'sent', 'delivered', 'read', 'failed', 'cancelled')),

    -- Foreign Keys
    CONSTRAINT fk_notifications_template 
        FOREIGN KEY (template_id) 
        REFERENCES btrace_gov.notification_templates (template_id),

    CONSTRAINT fk_notifications_recipient_user 
        FOREIGN KEY (recipient_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Find all pending/scheduled notifications
CREATE INDEX idx_notifications_status_scheduled 
ON btrace_gov.notifications (status, scheduled_at)
WHERE status IN ('pending', 'sending');

-- Find failed notifications (for retry)
CREATE INDEX idx_notifications_failed 
ON btrace_gov.notifications (status) 
WHERE status = 'failed';

-- By event type (e.g., DSAR, consent)
CREATE INDEX idx_notifications_event_type ON btrace_gov.notifications (event_type);

-- By recipient (user or email)
CREATE INDEX idx_notifications_recipient_id ON btrace_gov.notifications (recipient_id) WHERE recipient_id IS NOT NULL;
CREATE INDEX idx_notifications_recipient_value ON btrace_gov.notifications (recipient_value);

-- Covering index for dashboard
CREATE INDEX idx_notifications_covering 
ON btrace_gov.notifications (status, event_type, scheduled_at DESC)
INCLUDE (channel, recipient_value, sent_at, delivered_at);


COMMENT ON TABLE btrace_gov.notifications IS 
'Outbound messages sent to users or systems. Tracks delivery status and context. Used for DSAR alerts, policy reviews, consent expirations.';

COMMENT ON COLUMN btrace_gov.notifications.template_id IS 'Source template used to generate this message.';
COMMENT ON COLUMN btrace_gov.notifications.event_type IS 'Triggering event (e.g., dsar.created, consent.expiring).';
COMMENT ON COLUMN btrace_gov.notifications.channel IS 'Delivery method.';
COMMENT ON COLUMN btrace_gov.notifications.recipient_type IS 'Type of recipient: user, team, email, etc.';
COMMENT ON COLUMN btrace_gov.notifications.recipient_id IS 'Reference to internal user/team (if applicable).';
COMMENT ON COLUMN btrace_gov.notifications.recipient_value IS 'External address (e.g., john@example.com, #privacy-alerts).';
COMMENT ON COLUMN btrace_gov.notifications.context_data IS 'JSON payload used to render template (e.g., due_date, request_id).';
COMMENT ON COLUMN btrace_gov.notifications.scheduled_at IS 'When the notification should be sent.';
COMMENT ON COLUMN btrace_gov.notifications.sent_at IS 'When the message was dispatched.';
COMMENT ON COLUMN btrace_gov.notifications.delivered_at IS 'When delivery was confirmed (e.g., email bounce check).';
COMMENT ON COLUMN btrace_gov.notifications.read_at IS 'When opened (if tracked).';
COMMENT ON COLUMN btrace_gov.notifications.status IS 'Current delivery status.';
COMMENT ON COLUMN btrace_gov.notifications.failure_reason IS 'Error message if send failed.';

--
-- BUSINESS CASE:
-- The `notification_events` table logs every lifecycle event of a notification
-- (e.g., "sent", "failed", "read") for audit and debugging.
-- It enables root-cause analysis and compliance reporting.
--

CREATE TABLE btrace_gov.notification_events (
    event_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL,
    event_type      VARCHAR(50) NOT NULL,  -- 'sent', 'failed', 'delivered', 'read'
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details         JSONB,
    created_by      UUID,  -- System or user who triggered event

    -- Constraints
    CONSTRAINT chk_event_type 
        CHECK (event_type IN ('sent', 'failed', 'delivered', 'read', 'retried', 'cancelled')),

    -- Foreign Keys
    CONSTRAINT fk_event_notification_id 
        FOREIGN KEY (notification_id) 
        REFERENCES btrace_gov.notifications (notification_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_event_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


CREATE INDEX idx_notification_events ON btrace_gov.notification_events (notification_id, event_timestamp DESC);

CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON btrace_gov.notifications
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();

CREATE TRIGGER update_templates_updated_at
    BEFORE UPDATE ON btrace_gov.notification_templates
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();


ALTER TABLE btrace_gov.notifications
ADD CONSTRAINT chk_recipient_integrity
CHECK (
    (recipient_type = 'user' AND recipient_id IS NOT NULL) OR
    (recipient_type IN ('email', 'slack_channel', 'phone') AND recipient_value IS NOT NULL AND recipient_id IS NULL) OR
    (recipient_type = 'team' AND recipient_id IS NOT NULL)
);
-- Sample insertions 
-- 1. Template
-- Step 1: Insert the template
INSERT INTO btrace_gov.notification_templates 
(template_key, channel, language, subject, body, is_active)
VALUES (
    'dsar_submitted',
    'email',
    'en-US',
    'Your Data Request Has Been Received',
    'Dear {{first_name}}, your DSAR (ID: {{request_id}}) has been received and is due by {{due_date}}.',
    TRUE
)
RETURNING template_id;  -- This will give you the real UUID

-- 2. Send Notification
UPDATE btrace_gov.notification_templates
SET 
    subject = 'Your DSAR Request Has Been Received',
    body = 'Hello {{first_name}}, your DSAR (ID: {{request_id}}) is in progress and due by {{due_date}}.',
    is_active = TRUE,
    updated_at = NOW()
WHERE 
    template_key = 'dsar_submitted'
    AND channel = 'email'
    AND language = 'en-US';
	
SELECT 1 FROM btrace_gov.notification_templates
WHERE 
    template_key = 'dsar_submitted'
    AND channel = 'email'
    AND language = 'en-US';
	
-- Seed notification templates
INSERT INTO btrace_gov.notification_templates 
(template_key, channel, language, subject, body, is_active)
VALUES 
('dsar_submitted', 'email', 'en-US', 
 'Your DSAR Has Been Received', 
 'Hi {{first_name}}, we''ve received your request (ID: {{request_id}}). Due: {{due_date}}.', 
 TRUE),
('dsar_completed', 'email', 'en-US', 
 'Your DSAR Has Been Completed', 
 'Your data request (ID: {{request_id}}) is complete. Attached is your data package.', 
 TRUE),
('consent_expiring', 'email', 'en-US', 
 'Your Consent Is Expiring Soon', 
 'Your consent for {{purpose}} will expire on {{expiration_date}}. Renew now.', 
 TRUE)
ON CONFLICT (template_key, channel, language) 
DO UPDATE SET
    subject = EXCLUDED.subject,
    body = EXCLUDED.body,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- helper function that validates the template first 
CREATE OR REPLACE FUNCTION btrace_gov.send_notification(
    p_template_key TEXT,
    p_channel TEXT,
    p_recipient_type TEXT,
    p_recipient_id UUID DEFAULT NULL,
    p_recipient_value TEXT DEFAULT NULL,
    p_context_data JSONB DEFAULT '{}'::jsonb  -- Fixed: now has default
)
RETURNS UUID AS $$
DECLARE
    v_template_id UUID;
    v_notification_id UUID;
    v_body TEXT;
    v_subject TEXT;
BEGIN
    -- Look up the active template
    SELECT template_id, body, subject
    INTO v_template_id, v_body, v_subject
    FROM btrace_gov.notification_templates
    WHERE template_key = p_template_key
      AND channel = p_channel
      AND is_active = TRUE
    LIMIT 1;

    IF v_template_id IS NULL THEN
        RAISE EXCEPTION 'Notification template not found: % for channel %', p_template_key, p_channel;
    END IF;

    -- Insert notification
    INSERT INTO btrace_gov.notifications (
        template_id, event_type, channel, recipient_type,
        recipient_id, recipient_value, subject, body,
        context_data, scheduled_at, status
    )
    VALUES (
        v_template_id,
        p_template_key,
        p_channel,
        p_recipient_type,
        p_recipient_id,
        p_recipient_value,
        v_subject,
        v_body,
        p_context_data,
        NOW(),
        'pending'
    )
    RETURNING notification_id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

SELECT btrace_gov.send_notification(
    'dsar_submitted',
    'email',
    'email',
    NULL,
    'alice@example.com',
    '{"first_name": "Alice", "request_id": "xyz"}'::jsonb
);



-- Data Catalog: Business Glossary
--
-- BUSINESS CASE:
-- The `business_glossary` table defines standardized business terms and their meanings (e.g., "Customer", "Session Duration").
-- It ensures consistent interpretation of data across departments and systems.
-- This is essential for data literacy, compliance, and effective communication between technical and non-technical stakeholders.
--
-- PURPOSE:
-- - Establish a single source of truth for business terminology
-- - Link terms to data domains and stewards
-- - Support data catalog integration
-- - Improve data discovery and reporting accuracy
-- - Facilitate onboarding and training
--

CREATE TABLE btrace_gov.business_glossary (
    term_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    term          VARCHAR(100) NOT NULL,
    definition    TEXT NOT NULL,
    synonyms      TEXT[],  -- Array of synonyms (better than comma-separated string)
    related_terms UUID[],  -- Optional: array of related term_ids (or use junction table)
    domain_id     UUID,
    steward_id    UUID,
    status        VARCHAR(20) NOT NULL DEFAULT 'Draft',
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,
    updated_by    UUID,

    -- Enforce unique terms (case-insensitive)
    CONSTRAINT uq_term 
        UNIQUE (term),

    -- Validate status
    CONSTRAINT chk_status 
        CHECK (status IN ('Draft', 'Under Review', 'Approved', 'Deprecated', 'Retired')),

    -- Foreign Keys
    CONSTRAINT fk_glossary_domain_id 
        FOREIGN KEY (domain_id) 
        REFERENCES btrace_gov.data_domains (domain_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_glossary_steward_id 
        FOREIGN KEY (steward_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_glossary_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_glossary_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by term (case-insensitive)
CREATE INDEX idx_business_glossary_term 
ON btrace_gov.business_glossary (term);

-- Filter by status (e.g., show only Approved terms)
CREATE INDEX idx_business_glossary_status 
ON btrace_gov.business_glossary (status);

-- Find terms in a domain
CREATE INDEX idx_business_glossary_domain_id 
ON btrace_gov.business_glossary (domain_id) 
WHERE domain_id IS NOT NULL;

-- Find terms by steward
CREATE INDEX idx_business_glossary_steward_id 
ON btrace_gov.business_glossary (steward_id) 
WHERE steward_id IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_business_glossary_created_by 
ON btrace_gov.business_glossary (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_business_glossary_updated_by 
ON btrace_gov.business_glossary (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for glossary listing
CREATE INDEX idx_business_glossary_covering 
ON btrace_gov.business_glossary (term, status)
INCLUDE (definition, domain_id, steward_id, created_at);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_gov.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_business_glossary_updated_at
    BEFORE UPDATE ON btrace_gov.business_glossary
    FOR EACH ROW
    EXECUTE FUNCTION btrace_gov.update_updated_at_column();
	
COMMENT ON TABLE btrace_gov.business_glossary IS 
'Central repository of business terms and definitions (e.g., "Customer", "Active User"). Ensures consistent understanding of data across teams. Used in data catalogs, reports, and dashboards.';

COMMENT ON COLUMN btrace_gov.business_glossary.term_id IS 
'Unique identifier for the glossary term. Used in APIs and references.';

COMMENT ON COLUMN btrace_gov.business_glossary.term IS 
'Canonical name of the business concept (e.g., "Session", "Conversion"). Must be unique.';

COMMENT ON COLUMN btrace_gov.business_glossary.definition IS 
'Clear, unambiguous explanation of the term''s meaning and usage. Should include examples if helpful.';

COMMENT ON COLUMN btrace_gov.business_glossary.synonyms IS 
'Alternative names or spellings for the term (e.g., "User" → "Customer", "Client"). Helps with search and discovery.';

COMMENT ON COLUMN btrace_gov.business_glossary.related_terms IS 
'Optional: array of term_ids that are related (e.g., "Session" → "Page View", "Bounce Rate"). Consider using a junction table for complex relationships.';

COMMENT ON COLUMN btrace_gov.business_glossary.domain_id IS 
'References the data domain this term belongs to (e.g., "Marketing", "Billing"). Helps organize the glossary.';

COMMENT ON COLUMN btrace_gov.business_glossary.steward_id IS 
'References the data steward responsible for maintaining this term''s accuracy and relevance.';

COMMENT ON COLUMN btrace_gov.business_glossary.status IS 
'Lifecycle status: Draft, Under Review, Approved, Deprecated, Retired. Controls visibility in catalogs.';

COMMENT ON COLUMN btrace_gov.business_glossary.created_at IS 
'Timestamp when the term was proposed.';

COMMENT ON COLUMN btrace_gov.business_glossary.updated_at IS 
'Automatically updated when the term is modified. Used for audit.';

COMMENT ON COLUMN btrace_gov.business_glossary.created_by IS 
'Optional: user who proposed the term. NULL if seeded or automated.';

COMMENT ON COLUMN btrace_gov.business_glossary.updated_by IS 
'Optional: last user to edit the term. NULL if untracked.';

-- Data Catalog: Data Assets
CREATE TABLE btrace_gov.data_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_name VARCHAR(100) NOT NULL,
    description TEXT,
    asset_type VARCHAR(50) NOT NULL,
    domain_id UUID,
    owner_id UUID,
    steward_id UUID,
    classification VARCHAR(20) NOT NULL,
    retention_policy VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_asset_name UNIQUE (asset_name),
    FOREIGN KEY (domain_id) REFERENCES btrace_gov.data_domains(domain_id) ON DELETE SET NULL,
    FOREIGN KEY (owner_id) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (steward_id) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL
);
COMMENT ON TABLE btrace_gov.data_assets IS 'Inventory of data assets in the organization';
COMMENT ON COLUMN btrace_gov.data_assets.asset_type IS 'Type of asset (e.g., database, file, API)';
COMMENT ON COLUMN btrace_gov.data_assets.classification IS 'Data classification level (e.g., public, internal, confidential)';

-- Data Catalog: Data Elements
CREATE TABLE btrace_gov.data_elements (
    element_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    element_name VARCHAR(100) NOT NULL,
    description TEXT,
    data_type VARCHAR(50) NOT NULL,
    format VARCHAR(100),
    allowed_values TEXT,
    is_pii BOOLEAN NOT NULL DEFAULT FALSE,
    pii_type VARCHAR(50),
    asset_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_element_asset UNIQUE (element_name, asset_id),
    FOREIGN KEY (asset_id) REFERENCES btrace_gov.data_assets(asset_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_gov.data_elements IS 'Detailed metadata about specific data elements/fields';
COMMENT ON COLUMN btrace_gov.data_elements.is_pii IS 'Flag indicating if this element contains personally identifiable information';
COMMENT ON COLUMN btrace_gov.data_elements.pii_type IS 'Type of PII if applicable (e.g., name, email, SSN)';

-- Data Lineage: Lineage Records
CREATE TABLE btrace_gov.data_lineage (
    lineage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_asset_id UUID NOT NULL,
    source_element_id UUID,
    target_asset_id UUID NOT NULL,
    target_element_id UUID,
    transformation_description TEXT,
    lineage_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    FOREIGN KEY (source_asset_id) REFERENCES btrace_gov.data_assets(asset_id) ON DELETE CASCADE,
    FOREIGN KEY (source_element_id) REFERENCES btrace_gov.data_elements(element_id) ON DELETE CASCADE,
    FOREIGN KEY (target_asset_id) REFERENCES btrace_gov.data_assets(asset_id) ON DELETE CASCADE,
    FOREIGN KEY (target_element_id) REFERENCES btrace_gov.data_elements(element_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_gov.data_lineage IS 'Records of how data flows between systems and transformations';
COMMENT ON COLUMN btrace_gov.data_lineage.lineage_type IS 'Type of lineage (e.g., system, business, transformation)';

-- Data Quality: Quality Rules
CREATE TABLE btrace_gov.data_quality_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(100) NOT NULL,
    description TEXT,
    rule_type VARCHAR(50) NOT NULL,
    rule_definition TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    asset_id UUID,
    element_id UUID,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    FOREIGN KEY (asset_id) REFERENCES btrace_gov.data_assets(asset_id) ON DELETE CASCADE,
    FOREIGN KEY (element_id) REFERENCES btrace_gov.data_elements(element_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_gov.data_quality_rules IS 'Rules for assessing data quality';
COMMENT ON COLUMN btrace_gov.data_quality_rules.rule_type IS 'Type of quality rule (e.g., completeness, validity, consistency)';

-- Data Quality: Quality Metrics
CREATE TABLE btrace_gov.data_quality_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL,
    measurement_time TIMESTAMP WITH TIME ZONE NOT NULL,
    measured_value DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    records_analyzed INTEGER,
    error_count INTEGER,
    sample_errors TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rule_id) REFERENCES btrace_gov.data_quality_rules(rule_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_gov.data_quality_metrics IS 'Measurements of data quality over time';
COMMENT ON COLUMN btrace_gov.data_quality_metrics.status IS 'Status of the measurement (e.g., pass, fail, warning)';

-- =============================================
-- SECTION 4: CORE PLATFORM TABLES
-- =============================================

-- Services: Definition of monitored services
CREATE TABLE btrace_core.services (
    service_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    service_type VARCHAR(50) NOT NULL,
    domain_id UUID,
    owner_team_id UUID,
    criticality VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_service_name UNIQUE (service_name),
    FOREIGN KEY (domain_id) REFERENCES btrace_gov.data_domains(domain_id) ON DELETE SET NULL,
    FOREIGN KEY (owner_team_id) REFERENCES btrace_rbac.teams(team_id) ON DELETE SET NULL
);
COMMENT ON TABLE btrace_core.services IS 'Services being monitored by the platform';
COMMENT ON COLUMN btrace_core.services.service_type IS 'Type of service (e.g., microservice, database, API)';
COMMENT ON COLUMN btrace_core.services.criticality IS 'Business criticality (e.g., critical, high, medium, low)';

-- Environments: Deployment environments
CREATE TABLE btrace_core.environments (
    environment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    environment_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_production BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_environment_name UNIQUE (environment_name)
);
COMMENT ON TABLE btrace_core.environments IS 'Deployment environments (e.g., production, staging, development)';

-- Service Versions: Versions of services deployed
CREATE TABLE btrace_core.service_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL,
    version_name VARCHAR(50) NOT NULL,
    git_commit_hash VARCHAR(100),
    git_branch VARCHAR(100),
    build_timestamp TIMESTAMP WITH TIME ZONE,
    deployed_at TIMESTAMP WITH TIME ZONE,
    environment_id UUID NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (service_id) REFERENCES btrace_core.services(service_id) ON DELETE CASCADE,
    FOREIGN KEY (environment_id) REFERENCES btrace_core.environments(environment_id) ON DELETE CASCADE,
    CONSTRAINT uq_service_version_env UNIQUE (service_id, version_name, environment_id)
);
COMMENT ON TABLE btrace_core.service_versions IS 'Versions of services deployed to environments';

-- Service Dependencies: Relationships between services
CREATE TABLE btrace_core.service_dependencies (
    dependency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_service_id UUID NOT NULL,
    target_service_id UUID NOT NULL,
    dependency_type VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    FOREIGN KEY (source_service_id) REFERENCES btrace_core.services(service_id) ON DELETE CASCADE,
    FOREIGN KEY (target_service_id) REFERENCES btrace_core.services(service_id) ON DELETE CASCADE,
    CONSTRAINT uq_service_dependency UNIQUE (source_service_id, target_service_id, dependency_type)
);
COMMENT ON TABLE btrace_core.service_dependencies IS 'Relationships and dependencies between services';

-- Data Sources: Sources of telemetry data
CREATE TABLE btrace_core.data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL,
    description TEXT,
    source_type VARCHAR(50) NOT NULL,
    connection_details JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_harvested_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_source_name UNIQUE (source_name)
);
COMMENT ON TABLE btrace_core.data_sources IS 'Sources of telemetry data (logs, metrics, traces)';
COMMENT ON COLUMN btrace_core.data_sources.source_type IS 'Type of source (e.g., application, infrastructure, database)';

-- Service Data Sources: Mapping services to data sources
CREATE TABLE btrace_core.service_data_sources (
    service_id UUID NOT NULL,
    source_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (service_id, source_id),
    FOREIGN KEY (service_id) REFERENCES btrace_core.services(service_id) ON DELETE CASCADE,
    FOREIGN KEY (source_id) REFERENCES btrace_core.data_sources(source_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_core.service_data_sources IS 'Mapping between services and their data sources';


-- todo -- self-service analytics, integration with data catalog
-- todo -- think about integration with Apache Atlas or DataHub 
--
-- BUSINESS CASE:
-- The `glossary_relations` table defines semantic relationships between business glossary terms
-- (e.g., "Session" → "has child" → "Page View", or "User" → "synonym" → "Customer").
-- It enables a rich, interconnected knowledge graph of business concepts.
-- This is essential for data discovery, impact analysis, and ontology modeling.
--
-- PURPOSE:
-- - Model hierarchical and associative term relationships
-- - Support term navigation (e.g., "Show all children of 'Revenue'")
-- - Enable data lineage and impact analysis
-- - Facilitate advanced search and recommendations
-- - Integrate with data catalog and semantic layer tools
--

CREATE TABLE btrace_gov.glossary_relations (
    term_id           UUID NOT NULL,
    related_term_id   UUID NOT NULL,
    relation_type     VARCHAR(20) NOT NULL DEFAULT 'related',
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by        UUID,

    -- Prevent self-referencing
    CONSTRAINT chk_not_self_reference 
        CHECK (term_id != related_term_id),

    -- Enforce valid relationship types
    CONSTRAINT chk_relation_type 
        CHECK (relation_type IN (
            'related',      -- General association
            'synonym',      -- Equivalent meaning
            'antonym',      -- Opposite meaning
            'parent',       -- Hierarchical parent (e.g., "Metric" → "Revenue")
            'child',        -- Hierarchical child
            'broader',      -- Broader concept (SKOS-style)
            'narrower',     -- Narrower concept
            'see_also'      -- Suggestive link
        )),

    -- Composite Primary Key
    CONSTRAINT pk_glossary_relations 
        PRIMARY KEY (term_id, related_term_id),

    -- Foreign Keys
    CONSTRAINT fk_glossary_relations_term_id 
        FOREIGN KEY (term_id) 
        REFERENCES btrace_gov.business_glossary (term_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_glossary_relations_related_term_id 
        FOREIGN KEY (related_term_id) 
        REFERENCES btrace_gov.business_glossary (term_id) 
        ON DELETE CASCADE,

    -- Optional: track who created the relationship
    CONSTRAINT fk_glossary_relations_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Forward: "What is related to this term?"
-- (Covered by PK: idx on term_id)

-- Reverse: "Which terms point TO this term?" (e.g., parents, synonyms)
CREATE INDEX idx_glossary_relations_reverse 
ON btrace_gov.glossary_relations (related_term_id, term_id);

-- Filter by relation type (e.g., only 'parent' links)
CREATE INDEX idx_glossary_relations_type 
ON btrace_gov.glossary_relations (relation_type);

-- Find all incoming 'parent' relationships (i.e., children)
CREATE INDEX idx_glossary_relations_parent 
ON btrace_gov.glossary_relations (related_term_id, term_id)
WHERE relation_type = 'parent';

-- Audit: who created relationships?
CREATE INDEX idx_glossary_relations_created_by 
ON btrace_gov.glossary_relations (created_by)
WHERE created_by IS NOT NULL;

-- Covering index for term detail page
CREATE INDEX idx_glossary_relations_covering 
ON btrace_gov.glossary_relations (term_id)
INCLUDE (related_term_id, relation_type, created_at, created_by);

COMMENT ON TABLE btrace_gov.glossary_relations IS 
'Defines semantic relationships between business glossary terms. Enables navigation, hierarchy, and discovery (e.g., "Revenue" has child "Subscription Revenue"). Supports data ontology modeling.';

COMMENT ON COLUMN btrace_gov.glossary_relations.term_id IS 
'The source term in the relationship (e.g., "Revenue").';

COMMENT ON COLUMN btrace_gov.glossary_relations.related_term_id IS 
'The target term in the relationship (e.g., "Subscription Revenue").';

COMMENT ON COLUMN btrace_gov.glossary_relations.relation_type IS 
'Type of relationship: related, synonym, antonym, parent, child, broader, narrower, see_also. Enables intelligent navigation and reasoning.';

COMMENT ON COLUMN btrace_gov.glossary_relations.created_at IS 
'Timestamp when the relationship was recorded.';

COMMENT ON COLUMN btrace_gov.glossary_relations.created_by IS 
'Optional: user who proposed or approved this relationship. NULL if automated or seeded.';

-- find the uid of the term 
SELECT term_id, term
FROM btrace_gov.business_glossary
WHERE term ILIKE 'Revenue';

-- fetch all children of a specific terms 
SELECT bg.term, bg.definition
FROM btrace_gov.glossary_relations gr
JOIN btrace_gov.business_glossary bg ON gr.related_term_id = bg.term_id
WHERE gr.term_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND gr.relation_type = 'parent';
 
-- search by term name 
SELECT child.term, child.definition
FROM btrace_gov.glossary_relations gr
JOIN btrace_gov.business_glossary parent ON gr.term_id = parent.term_id
JOIN btrace_gov.business_glossary child ON gr.related_term_id = child.term_id
WHERE parent.term = 'Revenue'
  AND gr.relation_type = 'parent';
  
--reverse query 
SELECT parent.term, parent.definition
FROM btrace_gov.glossary_relations gr
JOIN btrace_gov.business_glossary parent ON gr.term_id = parent.term_id
JOIN btrace_gov.business_glossary child ON gr.related_term_id = child.term_id
WHERE child.term = 'Subscription Revenue'
  AND gr.relation_type = 'parent';
  
-- Show all "children" of the term "Revenue"
SELECT child.term, child.definition
FROM btrace_gov.glossary_relations gr
JOIN btrace_gov.business_glossary parent ON gr.term_id = parent.term_id
JOIN btrace_gov.business_glossary child ON gr.related_term_id = child.term_id
WHERE parent.term = 'Revenue'
  AND gr.relation_type = 'parent';
  
-- adding index for text search 
CREATE INDEX idx_business_glossary_term_lower 
ON btrace_gov.business_glossary (LOWER(term));

-- =============================================
-- SECTION 5: TELEMETRY DATA TABLES
-- =============================================

--
-- BUSINESS CASE:
-- The `traces` table stores high-level metadata for distributed traces collected across microservices.
-- It enables observability into system behavior, performance analysis, error tracking, and root cause analysis.
-- This table is critical for monitoring service health, identifying latency bottlenecks, and supporting SRE/DevOps teams.
--
-- PURPOSE:
-- Centralize aggregated trace summaries for fast querying and dashboarding. Designed to support:
-- - Trace search by service, time range, status
-- - Performance monitoring (latency, error rates)
-- - Multi-environment visibility (dev, staging, prod)
-- - Integration with observability platforms (e.g., Grafana, Jaeger UI)
-- - Efficient partitioning and retention policies
--

CREATE TABLE btrace_core.traces (
    trace_id         UUID NOT NULL,
    trace_name       VARCHAR(255) NOT NULL,
    start_time       TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time         TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_ms      BIGINT NOT NULL CHECK (duration_ms >= 0),
    status_code      VARCHAR(20) NOT NULL 
        CHECK (status_code IN ('OK', 'ERROR', 'UNAVAILABLE', 'DEADLINE_EXCEEDED', 'CANCELLED', 'UNKNOWN')),
    status_message   TEXT,
    service_count    INTEGER NOT NULL CHECK (service_count >= 1),
    span_count       INTEGER NOT NULL CHECK (span_count >= 1),
    is_sampled       BOOLEAN NOT NULL DEFAULT TRUE,
    environment_id   UUID NOT NULL,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    root_service     VARCHAR(100),        -- Optional: top-level service initiating the trace
    trace_flags      SMALLINT DEFAULT 1,  -- e.g., sampling bit from W3C traceflags
    tags             JSONB,               -- Custom key-value metadata (version, user_id, etc.)

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_traces 
        PRIMARY KEY (trace_id, start_time),

    -- Foreign key constraint
    CONSTRAINT fk_environment 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments(environment_id) 
        ON DELETE CASCADE,

    -- Ensure valid time range
    CONSTRAINT valid_time_range 
        CHECK (end_time >= start_time)
)
PARTITION BY RANGE (start_time);

-- === Indexes (will be propagated to each partition) ===

-- Index on environment + time for common filtering
CREATE INDEX idx_traces_environment_start_time 
ON btrace_core.traces (environment_id, start_time DESC)
WHERE is_sampled = TRUE;

-- Index on status for error monitoring
CREATE INDEX idx_traces_status_start_time 
ON btrace_core.traces (status_code, start_time DESC);

-- Index on duration for performance analysis
CREATE INDEX idx_traces_duration_ms 
ON btrace_core.traces (duration_ms) 
WHERE status_code = 'OK' AND is_sampled = TRUE;

-- GIN index on tags for flexible filtering
CREATE INDEX idx_traces_tags_gin 
ON btrace_core.traces USING GIN (tags);

-- Optional: if you query by root_service frequently
CREATE INDEX idx_traces_root_service 
ON btrace_core.traces (root_service, start_time DESC);

-- Spans: Individual operations within traces
--
-- BUSINESS CASE:
-- The `spans` table stores individual operations (spans) within distributed traces, representing units of work 
-- performed by services (e.g., HTTP requests, DB calls, message processing). This data enables deep-dive 
-- latency analysis, error tracing, and service dependency mapping.
--
-- PURPOSE:
-- - Support high-cardinality, high-volume span ingestion from microservices
-- - Enable fast querying by trace_id, service, operation, or time range
-- - Facilitate root-cause analysis and performance debugging
-- - Integrate with observability tools (e.g., UIs, alerting, service maps)
-- - Allow efficient retention via time-based partitioning
--

CREATE TABLE btrace_core.spans (
    span_id          UUID NOT NULL,
    trace_id         UUID NOT NULL,
    parent_span_id   UUID,
    span_name        VARCHAR(255) NOT NULL,
    start_time       TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time         TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_ms      BIGINT NOT NULL CHECK (duration_ms >= 0),
    service_id       UUID NOT NULL,
    service_name     VARCHAR(100) NOT NULL,
    operation_name   VARCHAR(255) NOT NULL,
    kind             VARCHAR(20) NOT NULL 
        CHECK (kind IN ('INTERNAL', 'SERVER', 'CLIENT', 'PRODUCER', 'CONSUMER')),
    status_code      VARCHAR(20) NOT NULL 
        CHECK (status_code IN ('OK', 'ERROR', 'UNAVAILABLE', 'DEADLINE_EXCEEDED', 'CANCELLED', 'UNKNOWN')),
    status_message   TEXT,
    attributes       JSONB,
    events           JSONB,
    links            JSONB,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_spans 
        PRIMARY KEY (trace_id, span_id, start_time),

    -- Foreign keys
    CONSTRAINT fk_spans_trace_id 
        FOREIGN KEY (trace_id, start_time) 
        REFERENCES btrace_core.traces (trace_id, start_time) 
        ON DELETE CASCADE,

    CONSTRAINT fk_spans_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    -- Time integrity
    CONSTRAINT valid_time_range 
        CHECK (end_time >= start_time)
)
PARTITION BY RANGE (start_time);

-- === Indexes for Performance ===

-- Index for retrieving all spans of a trace (common lookup)
CREATE INDEX idx_spans_trace_id_start_time 
ON btrace_core.spans (trace_id, start_time DESC);

-- Index for filtering by service and time (e.g., "show slow DB calls in auth-service")
CREATE INDEX idx_spans_service_name_start_time 
ON btrace_core.spans (service_name, start_time DESC);

-- Index for operation-level analysis
CREATE INDEX idx_spans_operation_name 
ON btrace_core.spans (operation_name, start_time DESC);

-- Index for status-based error analysis
CREATE INDEX idx_spans_status_code 
ON btrace_core.spans (status_code, start_time DESC) 
WHERE status_code != 'OK';

-- GIN indexes for JSONB filtering
CREATE INDEX idx_spans_attributes_gin 
ON btrace_core.spans USING GIN (attributes) 
WHERE attributes IS NOT NULL;

CREATE INDEX idx_spans_events_gin 
ON btrace_core.spans USING GIN (events) 
WHERE events IS NOT NULL;

-- Optional: for distributed tracing context propagation
CREATE INDEX idx_spans_parent_span_id 
ON btrace_core.spans (parent_span_id) 
WHERE parent_span_id IS NOT NULL;

-- === Comments ===

COMMENT ON TABLE btrace_core.spans IS 
'Individual spans representing operations within distributed traces. Each span corresponds to a unit of work (e.g., an RPC, DB query). Partitioned by start_time for scalability and retention.';

COMMENT ON COLUMN btrace_core.spans.span_id IS 
'Unique identifier for this span within the trace (OpenTelemetry-compliant).';

COMMENT ON COLUMN btrace_core.spans.trace_id IS 
'References the parent trace. Combined with start_time in FK due to partitioning.';

COMMENT ON COLUMN btrace_core.spans.parent_span_id IS 
'Optional: span_id of the parent span in the trace tree. NULL for root spans.';

COMMENT ON COLUMN btrace_core.spans.span_name IS 
'User-defined name of the span (e.g., "GET /api/users"). Should be low cardinality.';

COMMENT ON COLUMN btrace_core.spans.operation_name IS 
'Logical operation or method name (e.g., "UserService.GetUser"). May be same as span_name or more specific.';

COMMENT ON COLUMN btrace_core.spans.kind IS 
'Role of the span in a workflow. Values: INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER. Aligns with OpenTelemetry semantic conventions.';

COMMENT ON COLUMN btrace_core.spans.service_name IS 
'Name of the service that generated this span (e.g., "user-service"). Useful for filtering and service maps.';

COMMENT ON COLUMN btrace_core.spans.duration_ms IS 
'Duration of the span in milliseconds. Precomputed for fast latency analysis.';

COMMENT ON COLUMN btrace_core.spans.status_code IS 
'Final status of the span (OK, ERROR, etc.). Used for error rate calculations.';

COMMENT ON COLUMN btrace_core.spans.attributes IS 
'Key-value metadata about the span (e.g., http.method, db.statement). Stored as JSONB for flexible querying.';

COMMENT ON COLUMN btrace_core.spans.events IS 
'Timestamped events within the span (e.g., "retry", "timeout"). Limited to ~10-50 per span.';

COMMENT ON COLUMN btrace_core.spans.links IS 
'Links to other spans (potentially in different traces), used for causal relationships (e.g., queue messaging).';

--
-- BUSINESS CASE:
-- The `logs` table stores structured application and system logs from services, containers, and infrastructure.
-- It enables debugging, auditing, security monitoring, and correlation with traces and metrics.
-- Logs are critical for post-incident analysis and compliance.
--
-- PURPOSE:
-- - Centralize logs from distributed systems in a queryable format
-- - Support fast filtering by service, environment, log level, and time
-- - Correlate logs with traces and spans for contextual debugging
-- - Enable retention policies via time-based partitioning
-- - Facilitate integration with observability dashboards and alerting
--

CREATE TABLE btrace_core.logs (
    log_id         UUID NOT NULL DEFAULT uuid_generate_v4(),
    timestamp      TIMESTAMP WITH TIME ZONE NOT NULL,
    service_id     UUID NOT NULL,
    service_name   VARCHAR(100) NOT NULL,
    host_name      VARCHAR(255),
    log_level      VARCHAR(20) NOT NULL 
        CHECK (log_level IN ('TRACE', 'DEBUG', 'INFO', 'WARN', 'WARNING', 'ERROR', 'FATAL', 'CRITICAL')),
    message        TEXT NOT NULL,
    trace_id       UUID,
    span_id        UUID,
    attributes     JSONB,
    environment_id UUID NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_logs 
        PRIMARY KEY (log_id, timestamp),

    -- Foreign keys
    CONSTRAINT fk_logs_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_logs_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    -- Note: Cannot directly reference spans(trace_id, span_id, start_time) due to complexity
    -- Instead, we use a soft reference (no FK) or rely on trace_id alone
    -- See comment below for explanation

    -- Time constraint
    CONSTRAINT valid_timestamp 
        CHECK (timestamp <= CURRENT_TIMESTAMP + INTERVAL '1 day') -- Prevent future timestamps
)
PARTITION BY RANGE (timestamp);

-- === Indexes for Performance ===

-- Index for time-based queries (most common)
CREATE INDEX idx_logs_timestamp 
ON btrace_core.logs (timestamp DESC);

-- Index for filtering by service and time
CREATE INDEX idx_logs_service_name_timestamp 
ON btrace_core.logs (service_name, timestamp DESC);

-- Index for error/warn level logs
CREATE INDEX idx_logs_log_level_timestamp 
ON btrace_core.logs (log_level, timestamp DESC)
WHERE log_level IN ('WARN', 'WARNING', 'ERROR', 'FATAL', 'CRITICAL');

-- Index for trace correlation
CREATE INDEX idx_logs_trace_id 
ON btrace_core.logs (trace_id, timestamp DESC)
WHERE trace_id IS NOT NULL;

-- GIN index for structured attributes
CREATE INDEX idx_logs_attributes_gin 
ON btrace_core.logs USING GIN (attributes)
WHERE attributes IS NOT NULL;

-- Optional: if span_id is frequently used
CREATE INDEX idx_logs_span_id 
ON btrace_core.logs (span_id, timestamp DESC)
WHERE span_id IS NOT NULL;

-- === Comments ===

COMMENT ON TABLE btrace_core.logs IS 
'Structured application and system logs ingested from services and infrastructure. Partitioned by timestamp for scalability and retention. Supports correlation with traces and spans for contextual debugging.';

COMMENT ON COLUMN btrace_core.logs.log_id IS 
'Unique identifier for the log record. Generated via uuid_generate_v4() unless provided.';

COMMENT ON COLUMN btrace_core.logs.timestamp IS 
'When the log event occurred (not when it was ingested). Used for partitioning and time-based queries.';

COMMENT ON COLUMN btrace_core.logs.service_name IS 
'Name of the service that emitted the log (e.g., "order-service"). Useful for filtering and dashboards.';

COMMENT ON COLUMN btrace_core.logs.host_name IS 
'Optional: hostname or pod name where the log originated. Useful for infrastructure-level debugging.';

COMMENT ON COLUMN btrace_core.logs.log_level IS 
'Severity level of the log. Standard values: TRACE, DEBUG, INFO, WARN, WARNING, ERROR, FATAL, CRITICAL.';

COMMENT ON COLUMN btrace_core.logs.message IS 
'The main log message (e.g., "User login failed"). Should be human-readable and avoid high cardinality.';

COMMENT ON COLUMN btrace_core.logs.trace_id IS 
'Optional: links this log to a distributed trace for correlation. Enables "show logs for this trace" in UIs.';

COMMENT ON COLUMN btrace_core.logs.span_id IS 
'Optional: links this log to a specific span. Enables precise context within a trace.';

COMMENT ON COLUMN btrace_core.logs.attributes IS 
'Structured key-value fields (e.g., user_id, request_id, http.status_code). Stored as JSONB for flexible filtering and analysis.';

COMMENT ON COLUMN btrace_core.logs.environment_id IS 
'Foreign key to the deployment environment (e.g., production, staging). Enables environment-specific filtering.';

--
-- BUSINESS CASE:
-- The `metrics` table stores time-series data emitted by services, containers, and infrastructure (e.g., CPU, request rate, latency).
-- It enables real-time monitoring, alerting, capacity planning, and performance analysis.
-- Metrics are essential for SLOs, dashboards, and proactive system health management.
--
-- PURPOSE:
-- - Store high-volume, time-series telemetry data at scale
-- - Support fast aggregation and querying by service, environment, and dimensions (attributes)
-- - Enable integration with monitoring tools (e.g., Grafana, Prometheus via adapter)
-- - Allow efficient retention via time-based partitioning
-- - Support multi-dimensional metrics (similar to Prometheus labels or OTel resource attributes)
--

CREATE TABLE btrace_core.metrics (
    metric_id      UUID NOT NULL DEFAULT uuid_generate_v4(),
    metric_name    VARCHAR(255) NOT NULL,
    metric_type    VARCHAR(50) NOT NULL 
        CHECK (metric_type IN ('gauge', 'counter', 'histogram', 'summary', 'sum', 'avg')),
    timestamp      TIMESTAMP WITH TIME ZONE NOT NULL,
    service_id     UUID,
    service_name   VARCHAR(100),
    value          DOUBLE PRECISION NOT NULL,
    unit           VARCHAR(50),  -- e.g., 's', 'ms', 'bytes', 'requests', '%'
    attributes     JSONB,
    environment_id UUID NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_metrics 
        PRIMARY KEY (metric_id, timestamp),

    -- Foreign keys
    CONSTRAINT fk_metrics_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_metrics_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    -- Prevent future timestamps (within reason)
    CONSTRAINT valid_timestamp 
        CHECK (timestamp <= CURRENT_TIMESTAMP + INTERVAL '1 hour')
)
PARTITION BY RANGE (timestamp);

-- === Indexes for Performance ===

-- Most common: query by name + time
CREATE INDEX idx_metrics_metric_name_timestamp 
ON btrace_core.metrics (metric_name, timestamp DESC);

-- Filter by service and time
CREATE INDEX idx_metrics_service_name_timestamp 
ON btrace_core.metrics (service_name, timestamp DESC);

-- Filter by environment + time (e.g., prod vs staging)
CREATE INDEX idx_metrics_environment_id_timestamp 
ON btrace_core.metrics (environment_id, timestamp DESC);

-- For attribute-based filtering (e.g., "region=us-west", "job=backend")
CREATE INDEX idx_metrics_attributes_gin 
ON btrace_core.metrics USING GIN (attributes)
WHERE attributes IS NOT NULL;

-- Optional: if querying by metric type (e.g., all histograms)
CREATE INDEX idx_metrics_type 
ON btrace_core.metrics (metric_type, timestamp DESC);

-- Covering index for common dashboard queries (avoid table fetch)
CREATE INDEX idx_metrics_covering 
ON btrace_core.metrics (metric_name, timestamp DESC, service_name, value)
INCLUDE (unit, attributes)
WHERE service_name IS NOT NULL;

-- === Comments ===

COMMENT ON TABLE btrace_core.metrics IS 
'Time-series metrics from services, containers, and infrastructure. Designed for high-throughput ingestion and fast querying. Partitioned by timestamp for scalability and retention. Supports multi-dimensional attributes (labels).';

COMMENT ON COLUMN btrace_core.metrics.metric_id IS 
'Unique identifier for the metric record. Useful for internal tracking, but queries typically use metric_name + attributes.';

COMMENT ON COLUMN btrace_core.metrics.metric_name IS 
'Name of the metric (e.g., "http.request.duration", "cpu.utilization"). Should be consistent and low-cardinality.';

COMMENT ON COLUMN btrace_core.metrics.metric_type IS 
'Type of metric: gauge (current value), counter (cumulative), histogram (distribution), summary, sum, avg. Aligns with Prometheus/OTel conventions.';

COMMENT ON COLUMN btrace_core.metrics.timestamp IS 
'When the metric was recorded (not ingested). Used for partitioning and time-series analysis.';

COMMENT ON COLUMN btrace_core.metrics.service_name IS 
'Optional: name of the service emitting the metric. Useful for filtering and dashboards.';

COMMENT ON COLUMN btrace_core.metrics.value IS 
'Numeric value of the metric point. For histograms, this may represent sum/count, with buckets in attributes or separate rows.';

COMMENT ON COLUMN btrace_core.metrics.unit IS 
'Unit of measurement (e.g., "s", "ms", "bytes", "count", "percent"). Helps with visualization and conversion.';

COMMENT ON COLUMN btrace_core.metrics.attributes IS 
'Dimensions or labels for the metric (e.g., method="GET", status="200", region="us-west"). Stored as JSONB for flexible filtering and grouping. Equivalent to Prometheus labels or OTel metric attributes.';

COMMENT ON COLUMN btrace_core.metrics.environment_id IS 
'Foreign key to the deployment environment (e.g., production, staging). Enables environment-specific monitoring and alerting.';

--
-- BUSINESS CASE:
-- The `metric_definitions` table serves as a centralized catalog of all metrics collected across services.
-- It enables discoverability, standardization, and documentation of metrics for engineers, SREs, and platform teams.
-- Without this, teams face "metric sprawl" — unclear, inconsistent, or duplicated metrics.
--
-- PURPOSE:
-- - Provide self-service discovery of available metrics
-- - Enforce naming and semantic consistency (e.g., via standard types/units)
-- - Document meaning, usage, and ownership of metrics
-- - Support UIs (e.g., metric explorer), documentation generators, and onboarding
-- - Distinguish standard vs. custom metrics for governance
-- - Enable integration with SLO/SLI tooling
--

CREATE TABLE btrace_core.metric_definitions (
    definition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name   VARCHAR(255) NOT NULL,
    description   TEXT,
    metric_type   VARCHAR(50) NOT NULL 
        CHECK (metric_type IN ('gauge', 'counter', 'histogram', 'summary', 'sum', 'avg')),
    unit          VARCHAR(50),  -- e.g., 'seconds', 'bytes', 'requests', 'percent'
    service_id    UUID,
    data_source   VARCHAR(50) DEFAULT 'application' 
        CHECK (data_source IN ('application', 'infrastructure', 'kubernetes', 'database', 'network')),
    is_standard   BOOLEAN NOT NULL DEFAULT TRUE,
    is_custom     BOOLEAN NOT NULL DEFAULT FALSE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    tags          JSONB,  -- e.g., {"team": "payments", "slo": "true", "pii": "false"}
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,   -- Reference to users (if available)
    updated_by    UUID,   -- Reference to users (if available)

    -- Enforce unique metric name per service (NULL service = global/system metric)
    CONSTRAINT uq_metric_name_service 
        UNIQUE (metric_name, service_id),

    -- Ensure is_standard and is_custom are consistent
    CONSTRAINT chk_standard_custom 
        CHECK ((is_standard AND NOT is_custom) OR (NOT is_standard AND is_custom) OR (is_standard AND is_custom = FALSE)),

    -- Foreign keys
    CONSTRAINT fk_metric_def_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    -- Optional: link to user (assume btrace_core.users exists)
    -- Remove if no user table
    CONSTRAINT fk_metric_def_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_core.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_metric_def_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_core.users (user_id) 
        ON DELETE SET NULL
);

-- === Indexes for Performance ===

-- For fast lookup by name (common in UI/search)
CREATE INDEX idx_metric_def_name ON btrace_core.metric_definitions (metric_name);

-- For filtering by service and type
CREATE INDEX idx_metric_def_service_type 
ON btrace_core.metric_definitions (service_id, metric_type);

-- For searching by tags (e.g., "slo=true", "team=auth")
CREATE INDEX idx_metric_def_tags_gin 
ON btrace_core.metric_definitions USING GIN (tags);

-- For listing active metrics by source
CREATE INDEX idx_metric_def_data_source 
ON btrace_core.metric_definitions (data_source, is_active);

-- Full-text search on description (if enabled)
CREATE INDEX idx_metric_def_description_gin 
ON btrace_core.metric_definitions USING GIN (to_tsvector('english', description))
WHERE description IS NOT NULL;

-- === Comments ===

COMMENT ON TABLE btrace_core.metric_definitions IS 
'Master catalog of all metrics, providing metadata, documentation, and governance. Used by developers, SREs, and dashboards to discover and understand available metrics.';

COMMENT ON COLUMN btrace_core.metric_definitions.metric_name IS 
'Canonical name of the metric (e.g., "http.server.request.duration"). Should follow consistent naming conventions.';

COMMENT ON COLUMN btrace_core.metric_definitions.description IS 
'Human-readable explanation of what the metric measures, how it is used, and any caveats.';

COMMENT ON COLUMN btrace_core.metric_definitions.metric_type IS 
'The semantic type of the metric: gauge, counter, histogram, etc. Aligns with OpenTelemetry and Prometheus conventions.';

COMMENT ON COLUMN btrace_core.metric_definitions.unit IS 
'Standardized unit of measurement (e.g., "s", "ms", "bytes", "count", "percent"). Critical for correct visualization and alerting.';

COMMENT ON COLUMN btrace_core.metric_definitions.service_id IS 
'Optional: service that owns or emits this metric. NULL if global (e.g., infrastructure).';

COMMENT ON COLUMN btrace_core.metric_definitions.data_source IS 
'Where the metric originates: application, infrastructure, Kubernetes, etc. Helps with filtering and ownership.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_standard IS 
'True if this is a well-known, standardized metric (e.g., HTTP request count). Used for governance and best practices.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_custom IS 
'True if this is a team-specific or ad-hoc metric. Helps identify potential sprawl or technical debt.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_active IS 
'Flag to deprecate or archive metrics no longer in use. Avoids deletion while preserving history.';

COMMENT ON COLUMN btrace_core.metric_definitions.tags IS 
'Flexible key-value metadata for classification: team, SLO relevance, PII, environment scope, etc.';

COMMENT ON COLUMN btrace_core.metric_definitions.created_by IS 
'Optional: user who registered this metric (if identity tracking is enabled).';

COMMENT ON COLUMN btrace_core.metric_definitions.updated_by IS 
'Optional: last user to update the metric metadata.';

-- need to think about workflow automation and incorporate them here (Awase)
-- integration with OpenTelemetry Collector? or we should create our own as we have our control and no license to worry about 
-- need to think of migrating to TimeScaleDB for enhanced time-series performance 
-- need to add row-level seucirty (RLS) using roles 

-- =============================================
-- SECTION 6: INCIDENT MANAGEMENT
-- =============================================

--
-- BUSINESS CASE:
-- The `services` table stores metadata about microservices, containers, or functions in the system.
-- It enables service-level filtering, ownership tracking, and dependency mapping in observability tools.
-- This table is essential for organizing telemetry data and assigning accountability.
--
-- PURPOSE:
-- - Define logical services in the platform
-- - Support service-level dashboards and alerts
-- - Enable ownership and team assignment
-- - Facilitate service dependency and topology mapping
-- - Serve as a reference for traces, logs, metrics, and incidents
--

CREATE TABLE btrace_core.services (
    service_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name     VARCHAR(100) NOT NULL,
    display_name     VARCHAR(100),  -- Human-friendly name (e.g., "User API")
    description      TEXT,
    owner_team_id    UUID,          -- References btrace_rbac.teams
    owner_user_id    UUID,          -- Optional: individual owner
    lifecycle_stage  VARCHAR(20) NOT NULL DEFAULT 'production',
    repository_url   VARCHAR(255),  -- Code repo (e.g., GitHub)
    documentation_url VARCHAR(255), -- Runbook, Confluence, etc.
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE,

    -- Enforce unique service names
    CONSTRAINT uq_service_name 
        UNIQUE (service_name),

    -- Validate lifecycle stage
    CONSTRAINT chk_lifecycle_stage 
        CHECK (lifecycle_stage IN ('development', 'staging', 'production', 'deprecated', 'retired')),

    -- Foreign Keys
    CONSTRAINT fk_services_owner_team 
        FOREIGN KEY (owner_team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_services_owner_user 
        FOREIGN KEY (owner_user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by name
CREATE INDEX idx_services_name ON btrace_core.services (service_name);

-- Filter by lifecycle stage
CREATE INDEX idx_services_stage ON btrace_core.services (lifecycle_stage);

-- Find services by team
CREATE INDEX idx_services_owner_team ON btrace_core.services (owner_team_id) WHERE owner_team_id IS NOT NULL;

-- Covering index for service catalog
CREATE INDEX idx_services_covering 
ON btrace_core.services (service_name, lifecycle_stage)
INCLUDE (display_name, description, repository_url, documentation_url);

-- Create function if not exists
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_services_updated_at
    BEFORE UPDATE ON btrace_core.services
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.services IS 
'Represents a logical service (microservice, function, container) in the system. Used to organize traces, logs, metrics, and incidents. Supports ownership and documentation linking.';

COMMENT ON COLUMN btrace_core.services.service_id IS 
'Globally unique identifier for the service. Used in foreign keys and APIs.';
COMMENT ON COLUMN btrace_core.services.service_name IS 
'Canonical name (e.g., "user-service"). Used in instrumentation and queries. Must be unique.';
COMMENT ON COLUMN btrace_core.services.display_name IS 
'Human-readable name (e.g., "User API"). Used in dashboards and UIs.';
COMMENT ON COLUMN btrace_core.services.description IS 
'Short summary of the service''s purpose and responsibilities.';
COMMENT ON COLUMN btrace_core.services.owner_team_id IS 
'Team responsible for the service (e.g., "SRE", "Auth Team"). Used for alert routing and ownership.';
COMMENT ON COLUMN btrace_core.services.owner_user_id IS 
'Optional: individual owner or point of contact. NULL if team-owned.';
COMMENT ON COLUMN btrace_core.services.lifecycle_stage IS 
'Current environment or maturity: development, staging, production, deprecated, retired.';
COMMENT ON COLUMN btrace_core.services.repository_url IS 
'Link to source code (e.g., GitHub, GitLab).';
COMMENT ON COLUMN btrace_core.services.documentation_url IS 
'Link to runbook, architecture doc, or on-call guide.';
COMMENT ON COLUMN btrace_core.services.created_at IS 
'When the service was registered in the catalog.';
COMMENT ON COLUMN btrace_core.services.updated_at IS 
'Automatically updated when service metadata changes.';

-- need to look at integration with service mesh (e.g. Istio, linkerd)

--
-- BUSINESS CASE:
-- The `environments` table defines deployment environments (e.g., production, staging, development).
-- It enables environment-specific filtering, access control, and compliance in observability and governance systems.
-- This table is essential for managing multi-environment deployments and preventing cross-environment incidents.
--
-- PURPOSE:
-- - Represent logical deployment environments
-- - Enable environment-based dashboards and alerts
-- - Support access control (e.g., "read-only in production")
-- - Facilitate release tracking and impact analysis
-- - Serve as a reference for traces, logs, metrics, and incidents
--

CREATE TABLE btrace_core.environments (
    environment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    environment_name VARCHAR(50) NOT NULL,
    display_name VARCHAR(100),  -- Human-friendly name (e.g., "Production - US East")
    description TEXT,
    environment_type VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,

    -- Enforce unique environment names
    CONSTRAINT uq_environment_name 
        UNIQUE (environment_name),

    -- Validate environment type
    CONSTRAINT chk_environment_type 
        CHECK (environment_type IN ('development', 'staging', 'production', 'testing', 'sandbox', 'disaster_recovery')),

    -- Prevent inactive environments from being used in active systems
    -- (enforced at app level or via triggers if needed)
    CONSTRAINT chk_active_if_used 
        CHECK (is_active = TRUE)  -- Optional: remove if you want to allow inactive entries
);

-- Fast lookup by name
CREATE INDEX idx_environments_name ON btrace_core.environments (environment_name);

-- Filter by type (e.g., only production)
CREATE INDEX idx_environments_type ON btrace_core.environments (environment_type);

-- Filter by active status
CREATE INDEX idx_environments_is_active ON btrace_core.environments (is_active);

-- Covering index for UI dropdowns
CREATE INDEX idx_environments_covering 
ON btrace_core.environments (environment_name, environment_type)
INCLUDE (display_name, description, is_active);

-- Create function if not exists
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_environments_updated_at
    BEFORE UPDATE ON btrace_core.environments
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.environments IS 
'Represents a deployment environment (e.g., production, staging). Used to separate telemetry, access, and policies across lifecycle stages.';

COMMENT ON COLUMN btrace_core.environments.environment_id IS 
'Globally unique identifier for the environment. Used in foreign keys and APIs.';
COMMENT ON COLUMN btrace_core.environments.environment_name IS 
'Canonical name (e.g., "prod", "staging"). Used in instrumentation and queries. Must be unique.';
COMMENT ON COLUMN btrace_core.environments.display_name IS 
'Human-readable label (e.g., "Production - US East"). Used in dashboards and UIs.';
COMMENT ON COLUMN btrace_core.environments.description IS 
'Description of the environment''s purpose, scope, and data sensitivity.';
COMMENT ON COLUMN btrace_core.environments.environment_type IS 
'Category: development, staging, production, etc. Used for filtering and access control.';
COMMENT ON COLUMN btrace_core.environments.is_active IS 
'Indicates whether the environment is currently active. Set to FALSE to deprecate without deletion.';
COMMENT ON COLUMN btrace_core.environments.created_at IS 
'When the environment was registered in the system.';
COMMENT ON COLUMN btrace_core.environments.updated_at IS 
'Automatically updated when environment metadata changes.';

--
-- BUSINESS CASE:
-- The `traces` table stores high-level metadata for distributed traces collected across microservices.
-- It enables observability into system behavior, performance analysis, error tracking, and root cause analysis.
-- This table is critical for monitoring service health, identifying latency bottlenecks, and supporting SRE/DevOps teams.
--
-- PURPOSE:
-- Centralize aggregated trace summaries for fast querying and dashboarding. Designed to support:
-- - Trace search by service, time range, status
-- - Performance monitoring (latency, error rates)
-- - Multi-environment visibility (dev, staging, prod)
-- - Integration with observability platforms (e.g., Grafana, Jaeger UI)
-- - Efficient partitioning and retention policies
--
CREATE TABLE btrace_core.traces (
    trace_id         UUID NOT NULL,
    trace_name       VARCHAR(255) NOT NULL,
    start_time       TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time         TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_ms      BIGINT NOT NULL CHECK (duration_ms >= 0),
    status_code      VARCHAR(20) NOT NULL 
        CHECK (status_code IN ('OK', 'ERROR', 'UNAVAILABLE', 'DEADLINE_EXCEEDED', 'CANCELLED', 'UNKNOWN')),
    status_message   TEXT,
    service_count    INTEGER NOT NULL CHECK (service_count >= 1),
    span_count       INTEGER NOT NULL CHECK (span_count >= 1),
    is_sampled       BOOLEAN NOT NULL DEFAULT TRUE,
    environment_id   UUID NOT NULL,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    root_service     VARCHAR(100),        -- Optional: top-level service initiating the trace
    trace_flags      SMALLINT DEFAULT 1,  -- e.g., sampling bit from W3C traceflags
    tags             JSONB,               -- Custom key-value metadata (version, user_id, etc.)
    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_traces 
        PRIMARY KEY (trace_id, start_time),
    -- Foreign key constraint
    CONSTRAINT fk_environment 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments(environment_id) 
        ON DELETE CASCADE,
    -- Ensure valid time range
    CONSTRAINT valid_time_range 
        CHECK (end_time >= start_time)
)
PARTITION BY RANGE (start_time);

-- === Indexes (will be propagated to each partition) ===
-- Index on environment + time for common filtering
CREATE INDEX idx_traces_environment_start_time 
ON btrace_core.traces (environment_id, start_time DESC)
WHERE is_sampled = TRUE;

-- Index on status for error monitoring
CREATE INDEX idx_traces_status_start_time 
ON btrace_core.traces (status_code, start_time DESC);

-- Index on duration for performance analysis
CREATE INDEX idx_traces_duration_ms 
ON btrace_core.traces (duration_ms) 
WHERE status_code = 'OK' AND is_sampled = TRUE;

-- GIN index on tags for flexible filtering
CREATE INDEX idx_traces_tags_gin 
ON btrace_core.traces USING GIN (tags);

-- Optional: if you query by root_service frequently
CREATE INDEX idx_traces_root_service 
ON btrace_core.traces (root_service, start_time DESC);


--
-- BUSINESS CASE:
-- The `logs` table stores structured application and system logs from services, containers, and infrastructure.
-- It enables debugging, auditing, security monitoring, and correlation with traces and metrics.
-- Logs are critical for post-incident analysis and compliance.
--
-- PURPOSE:
-- - Centralize logs from distributed systems in a queryable format
-- - Support fast filtering by service, environment, log level, and time
-- - Correlate logs with traces and spans for contextual debugging
-- - Enable retention policies via time-based partitioning
-- - Facilitate integration with observability dashboards and alerting
--
CREATE TABLE btrace_core.logs (
    log_id         UUID NOT NULL DEFAULT uuid_generate_v4(),
    timestamp      TIMESTAMP WITH TIME ZONE NOT NULL,
    service_id     UUID NOT NULL,
    service_name   VARCHAR(100) NOT NULL,
    host_name      VARCHAR(255),
    log_level      VARCHAR(20) NOT NULL 
        CHECK (log_level IN ('TRACE', 'DEBUG', 'INFO', 'WARN', 'WARNING', 'ERROR', 'FATAL', 'CRITICAL')),
    message        TEXT NOT NULL,
    trace_id       UUID,
    span_id        UUID,
    attributes     JSONB,
    environment_id UUID NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_logs 
        PRIMARY KEY (log_id, timestamp),
    -- Foreign keys
    CONSTRAINT fk_logs_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_logs_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,
    -- Time constraint
    CONSTRAINT valid_timestamp 
        CHECK (timestamp <= CURRENT_TIMESTAMP + INTERVAL '1 day') -- Prevent future timestamps
)
PARTITION BY RANGE (timestamp);

-- === Indexes for Performance ===
-- Index for time-based queries (most common)
CREATE INDEX idx_logs_timestamp 
ON btrace_core.logs (timestamp DESC);

-- Index for filtering by service and time
CREATE INDEX idx_logs_service_name_timestamp 
ON btrace_core.logs (service_name, timestamp DESC);

-- Index for error/warn level logs
CREATE INDEX idx_logs_log_level_timestamp 
ON btrace_core.logs (log_level, timestamp DESC)
WHERE log_level IN ('WARN', 'WARNING', 'ERROR', 'FATAL', 'CRITICAL');

-- Index for trace correlation
CREATE INDEX idx_logs_trace_id 
ON btrace_core.logs (trace_id, timestamp DESC)
WHERE trace_id IS NOT NULL;

-- GIN index for structured attributes
CREATE INDEX idx_logs_attributes_gin 
ON btrace_core.logs USING GIN (attributes)
WHERE attributes IS NOT NULL;

-- Optional: if span_id is frequently used
CREATE INDEX idx_logs_span_id 
ON btrace_core.logs (span_id, timestamp DESC)
WHERE span_id IS NOT NULL;


--
-- BUSINESS CASE:
-- The `metrics` table stores time-series data emitted by services, containers, and infrastructure (e.g., CPU, request rate, latency).
-- It enables real-time monitoring, alerting, capacity planning, and performance analysis.
-- Metrics are essential for SLOs, dashboards, and proactive system health management.
--
-- PURPOSE:
-- - Store high-volume, time-series telemetry data at scale
-- - Support fast aggregation and querying by service, environment, and dimensions (attributes)
-- - Enable integration with monitoring tools (e.g., Grafana, Prometheus via adapter)
-- - Allow efficient retention via time-based partitioning
-- - Support multi-dimensional metrics (similar to Prometheus labels or OTel resource attributes)
--
CREATE TABLE btrace_core.metrics (
    metric_id      UUID NOT NULL DEFAULT uuid_generate_v4(),
    metric_name    VARCHAR(255) NOT NULL,
    metric_type    VARCHAR(50) NOT NULL 
        CHECK (metric_type IN ('gauge', 'counter', 'histogram', 'summary', 'sum', 'avg')),
    timestamp      TIMESTAMP WITH TIME ZONE NOT NULL,
    service_id     UUID,
    service_name   VARCHAR(100),
    value          DOUBLE PRECISION NOT NULL,
    unit           VARCHAR(50),  -- e.g., 's', 'ms', 'bytes', 'requests', '%'
    attributes     JSONB,
    environment_id UUID NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_metrics 
        PRIMARY KEY (metric_id, timestamp),
    -- Foreign keys
    CONSTRAINT fk_metrics_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_metrics_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,
    -- Prevent future timestamps (within reason)
    CONSTRAINT valid_timestamp 
        CHECK (timestamp <= CURRENT_TIMESTAMP + INTERVAL '1 hour')
)
PARTITION BY RANGE (timestamp);

-- === Indexes for Performance ===
-- Most common: query by name + time
CREATE INDEX idx_metrics_metric_name_timestamp 
ON btrace_core.metrics (metric_name, timestamp DESC);

-- Filter by service and time
CREATE INDEX idx_metrics_service_name_timestamp 
ON btrace_core.metrics (service_name, timestamp DESC);

-- Filter by environment + time (e.g., prod vs staging)
CREATE INDEX idx_metrics_environment_id_timestamp 
ON btrace_core.metrics (environment_id, timestamp DESC);

-- For attribute-based filtering (e.g., "region=us-west", "job=backend")
CREATE INDEX idx_metrics_attributes_gin 
ON btrace_core.metrics USING GIN (attributes)
WHERE attributes IS NOT NULL;

-- Optional: if querying by metric type (e.g., all histograms)
CREATE INDEX idx_metrics_type 
ON btrace_core.metrics (metric_type, timestamp DESC);

-- Covering index for common dashboard queries (avoid table fetch)
CREATE INDEX idx_metrics_covering 
ON btrace_core.metrics (metric_name, timestamp DESC, service_name, value)
INCLUDE (unit, attributes)
WHERE service_name IS NOT NULL;

-- Incidents: Records of operational incidents
--
-- BUSINESS CASE:
-- The `incidents` table records operational incidents (outages, degradations, alerts) affecting system reliability.
-- It enables incident response coordination, post-mortem analysis, SLA tracking, and customer communication.
-- This table is essential for SRE teams, NOC operations, and service reliability reporting.
--
-- PURPOSE:
-- - Centralize incident lifecycle tracking (detected → resolved)
-- - Support severity-based alerting and escalation
-- - Enable post-incident reviews (PIRs) and root cause analysis
-- - Measure MTTR (Mean Time to Resolve) and uptime
-- - Facilitate customer impact reporting and transparency
--

CREATE TABLE btrace_core.incidents (
    incident_id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title                     VARCHAR(255) NOT NULL,
    description               TEXT,
    status                    VARCHAR(20) NOT NULL,
    severity                  VARCHAR(10) NOT NULL,
    impact                    VARCHAR(20) NOT NULL,
    start_time                TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time                  TIMESTAMP WITH TIME ZONE,
    detected_at               TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at               TIMESTAMP WITH TIME ZONE,
    service_id                UUID,
    environment_id            UUID NOT NULL,
    is_customer_impacting     BOOLEAN NOT NULL DEFAULT FALSE,
    customer_impact_description TEXT,
    created_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                TIMESTAMP WITH TIME ZONE,
    created_by                UUID,
    updated_by                UUID,

    -- Validate status
    CONSTRAINT chk_incident_status 
        CHECK (status IN ('detected', 'acknowledged', 'investigating', 'mitigated', 'resolved', 'closed')),

    -- Validate severity (P1-P5)
    CONSTRAINT chk_incident_severity 
        CHECK (severity IN ('P1', 'P2', 'P3', 'P4', 'P5')),

    -- Validate impact
    CONSTRAINT chk_incident_impact 
        CHECK (impact IN ('critical', 'major', 'moderate', 'minor', 'none')),

    -- Ensure detected_at <= start_time <= resolved_at (if present)
    CONSTRAINT chk_detected_before_start 
        CHECK (detected_at <= start_time),

    CONSTRAINT chk_start_before_end 
        CHECK (end_time IS NULL OR start_time <= end_time),

    CONSTRAINT chk_resolved_after_start 
        CHECK (resolved_at IS NULL OR resolved_at >= start_time),

    -- Foreign Keys
    CONSTRAINT fk_incidents_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_incidents_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_incidents_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_incidents_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast: "Show active incidents"
CREATE INDEX idx_incidents_status ON btrace_core.incidents (status)
WHERE status NOT IN ('resolved', 'closed');

-- Filter by severity (P1/P2 alerts)
CREATE INDEX idx_incidents_severity ON btrace_core.incidents (severity)
WHERE severity IN ('P1', 'P2');

-- Find recent incidents
CREATE INDEX idx_incidents_detected_at ON btrace_core.incidents (detected_at DESC);

-- Incidents by service (impact analysis)
CREATE INDEX idx_incidents_service_id ON btrace_core.incidents (service_id) WHERE service_id IS NOT NULL;

-- Incidents by environment
CREATE INDEX idx_incidents_environment_id ON btrace_core.incidents (environment_id);

-- Customer-impacting incidents
CREATE INDEX idx_incidents_customer_impact ON btrace_core.incidents (is_customer_impacting)
WHERE is_customer_impacting = TRUE;

-- Resolved incidents (for post-mortems)
CREATE INDEX idx_incidents_resolved_at ON btrace_core.incidents (resolved_at DESC)
WHERE resolved_at IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_incidents_created_by ON btrace_core.incidents (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX idx_incidents_updated_by ON btrace_core.incidents (updated_by) WHERE updated_by IS NOT NULL;

-- Covering index for incident dashboard
CREATE INDEX idx_incidents_covering 
ON btrace_core.incidents (status, severity, detected_at DESC)
INCLUDE (title, service_id, environment_id, is_customer_impacting, resolved_at);


-- Incident Timeline: Events during an incident
--
-- BUSINESS CASE:
-- The `incident_timeline` table records a chronological sequence of key events during an operational incident.
-- It provides a clear, auditable record of actions taken, decisions made, and milestones reached.
-- This is essential for post-mortems, regulatory compliance, training, and transparency.
--
-- PURPOSE:
-- - Maintain a real-time timeline of incident response activities
-- - Support post-incident reviews (PIRs) and root cause analysis
-- - Enable automated status updates and customer communications
-- - Facilitate collaboration and accountability among responders
-- - Integrate with chatops, monitoring alerts, and runbooks
--

CREATE TABLE btrace_core.incident_timeline (
    event_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id   UUID NOT NULL,
    event_type    VARCHAR(50) NOT NULL,
    event_time    TIMESTAMP WITH TIME ZONE NOT NULL,
    description   TEXT NOT NULL,
    created_by    UUID,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Enforce valid event types
    CONSTRAINT chk_event_type 
        CHECK (event_type IN (
            'detection',           -- When the incident was first detected
            'alert_fired',         -- Specific alert that triggered
            'acknowledged',        -- Team acknowledged
            'investigation_started',
            'mitigation_applied',  -- Workaround deployed
            'service_restored',    -- Users can access again
            'root_cause_identified',
            'fix_deployed',        -- Permanent fix in prod
            'postmortem_started',
            'postmortem_published',
            'incident_closed',
            'customer_update',     -- Public status update
            'external_communication',
            'escalation',          -- To manager, C-suite
            'oncall_paged',
            'manual_update'        -- Free-form entry
        )),

    -- Ensure event_time is not in the distant future
    CONSTRAINT chk_event_time_not_future 
        CHECK (event_time <= CURRENT_TIMESTAMP + INTERVAL '1 hour'),

    -- Foreign Keys
    CONSTRAINT fk_timeline_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_timeline_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all events for this incident"
CREATE INDEX idx_incident_timeline_incident_id 
ON btrace_core.incident_timeline (incident_id, event_time DESC);

-- Filter by event type (e.g., show all customer updates)
CREATE INDEX idx_incident_timeline_type 
ON btrace_core.incident_timeline (event_type);

-- Find recent events (for live dashboards)
CREATE INDEX idx_incident_timeline_time 
ON btrace_core.incident_timeline (event_time DESC);

-- Who created the events?
CREATE INDEX idx_incident_timeline_created_by 
ON btrace_core.incident_timeline (created_by) 
WHERE created_by IS NOT NULL;

-- Covering index for timeline UI
CREATE INDEX idx_incident_timeline_covering 
ON btrace_core.incident_timeline (incident_id, event_time DESC)
INCLUDE (event_type, description, created_by, created_at);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_incident_timeline_updated_at
    BEFORE UPDATE ON btrace_core.incident_timeline
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
	COMMENT ON TABLE btrace_core.incident_timeline IS 
'Chronological record of significant events during an incident (e.g., detection, mitigation, communication). Used for post-mortems, audits, and transparency.';

COMMENT ON COLUMN btrace_core.incident_timeline.event_id IS 
'Unique identifier for the timeline event. Used in APIs and UIs.';

COMMENT ON COLUMN btrace_core.incident_timeline.incident_id IS 
'References the parent incident. Cascades delete if incident is archived.';

COMMENT ON COLUMN btrace_core.incident_timeline.event_type IS 
'Category of event: detection, mitigation, customer_update, etc. Enables filtering and automation.';

COMMENT ON COLUMN btrace_core.incident_timeline.event_time IS 
'Timestamp when the event occurred (e.g., when service was restored). May differ from when it was recorded.';

COMMENT ON COLUMN btrace_core.incident_timeline.description IS 
'Detailed description of what happened at this moment (e.g., "Rollback completed, API latency back to normal").';

COMMENT ON COLUMN btrace_core.incident_timeline.created_by IS 
'User who added this event (e.g., responder, SRE). NULL if auto-generated by system.';

COMMENT ON COLUMN btrace_core.incident_timeline.created_at IS 
'When the event was recorded in the system.';

COMMENT ON COLUMN btrace_core.incident_timeline.updated_at IS 
'Automatically updated if the event description is edited. Used for audit trail.';


-- extract the full timeline for an incident
SELECT 
    event_time,
    event_type,
    description,
    u.username AS recorded_by
FROM btrace_core.incident_timeline t
LEFT JOIN btrace_rbac.users u ON t.created_by = u.user_id
WHERE t.incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY event_time ASC;


-- show customer facing updates only 
SELECT event_time, description
FROM btrace_core.incident_timeline
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND event_type IN ('customer_update', 'external_communication')
ORDER BY event_time;

--Timetaken to fix (TTTF)- measures the time between detection and fix 
WITH timeline AS (
    SELECT 
        event_type,
        event_time,
        LEAD(event_time) OVER (ORDER BY event_time) AS next_time
    FROM btrace_core.incident_timeline
    WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
)
SELECT 
    event_type,
    event_time,
    EXTRACT(EPOCH FROM (next_time - event_time)) AS duration_seconds
FROM timeline
WHERE event_type = 'mitigation_applied';  -- Or 'service_restored'


-- Incident Assignments: Who is working on an incident
--
-- BUSINESS CASE:
-- The `incident_assignments` table tracks who is responsible for resolving an incident — whether an individual (user) or a team.
-- It enables dynamic reassignment, on-call rotations, and accountability during incident response.
-- This is essential for SRE teams, NOC operations, and post-incident reviews.
--
-- PURPOSE:
-- - Assign ownership of incidents to users or teams
-- - Support role-based response (e.g., "SRE Team" owns P1s)
-- - Enable audit trail of who was assigned and when
-- - Facilitate handoffs and escalation
-- - Integrate with chatops, alerting, and status pages
--
--
-- BUSINESS CASE:
-- The `incident_user_assignments` table tracks when individual users are assigned to incidents.
-- It enables accountability, SLA tracking, and on-call management by recording who responded and when.
-- This is essential for post-mortems, performance reviews, and ensuring no incident is left unattended.
--
-- PURPOSE:
-- - Assign ownership of incidents to specific users
-- - Support dynamic reassignment and handoffs
-- - Enable audit trail of user involvement
-- - Facilitate integration with chatops, alerting, and status pages
-- - Support querying "Which incidents has Alice handled?"
--

CREATE TABLE btrace_core.incident_user_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id   UUID NOT NULL,
    user_id       UUID NOT NULL,
    assigned_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at TIMESTAMP WITH TIME ZONE,
    assigned_by   UUID,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Prevent invalid time logic
    CONSTRAINT chk_unassigned_after_assigned 
        CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at),

    -- Foreign Keys
    CONSTRAINT fk_iua_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_iua_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_iua_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

--
-- BUSINESS CASE:
-- The `incident_team_assignments` table tracks when teams are assigned responsibility for an incident.
-- It supports team-based response models (e.g., "SRE Team" owns P1s) and enables load balancing across members.
-- This is essential for large organizations where incidents are owned by functional groups, not just individuals.
--
-- PURPOSE:
-- - Assign incident ownership to organizational teams
-- - Enable team-level dashboards and reporting
-- - Support on-call rotations within teams
-- - Facilitate collaboration and internal handoffs
-- - Integrate with team calendars and status pages
--

CREATE TABLE btrace_core.incident_team_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id   UUID NOT NULL,
    team_id       UUID NOT NULL,
    assigned_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at TIMESTAMP WITH TIME ZONE,
    assigned_by   UUID,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Prevent invalid time logic
    CONSTRAINT chk_unassigned_after_assigned 
        CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at),

    -- Foreign Keys
    CONSTRAINT fk_ita_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_ita_team_id 
        FOREIGN KEY (team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_ita_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- User Assignments: Find all active assignments for a user
CREATE INDEX idx_iua_user_active 
ON btrace_core.incident_user_assignments (user_id)
WHERE unassigned_at IS NULL;

-- User Assignments: Find all assignments for an incident
CREATE INDEX idx_iua_incident 
ON btrace_core.incident_user_assignments (incident_id, assigned_at DESC);

-- User Assignments: Who is assigning?
CREATE INDEX idx_iua_assigned_by 
ON btrace_core.incident_user_assignments (assigned_by) 
WHERE assigned_by IS NOT NULL;

-- Team Assignments: Find all active assignments for a team
CREATE INDEX idx_ita_team_active 
ON btrace_core.incident_team_assignments (team_id)
WHERE unassigned_at IS NULL;

-- Team Assignments: Find all assignments for an incident
CREATE INDEX idx_ita_incident 
ON btrace_core.incident_team_assignments (incident_id, assigned_at DESC);

-- Team Assignments: Who is assigning?
CREATE INDEX idx_ita_assigned_by 
ON btrace_core.incident_team_assignments (assigned_by) 
WHERE assigned_by IS NOT NULL;

-- Covering index for user assignment dashboard
CREATE INDEX idx_iua_covering 
ON btrace_core.incident_user_assignments (user_id, assigned_at DESC)
INCLUDE (incident_id, unassigned_at, assigned_by);

-- Covering index for team assignment dashboard
CREATE INDEX idx_ita_covering 
ON btrace_core.incident_team_assignments (team_id, assigned_at DESC)
INCLUDE (incident_id, unassigned_at, assigned_by);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user assignments
CREATE TRIGGER update_incident_user_assignments_updated_at
    BEFORE UPDATE ON btrace_core.incident_user_assignments
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();

-- Trigger for team assignments
CREATE TRIGGER update_incident_team_assignments_updated_at
    BEFORE UPDATE ON btrace_core.incident_team_assignments
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.incident_user_assignments IS 
'Records when a specific user is assigned to an incident. Supports individual accountability, on-call tracking, and handoffs.';

COMMENT ON COLUMN btrace_core.incident_user_assignments.assignment_id IS 'Unique identifier for the assignment.';
COMMENT ON COLUMN btrace_core.incident_user_assignments.incident_id IS 'References the incident being managed.';
COMMENT ON COLUMN btrace_core.incident_user_assignments.user_id IS 'The user responsible for resolving the incident.';
COMMENT ON COLUMN btrace_core.incident_user_assignments.assigned_at IS 'When the assignment was made.';
COMMENT ON COLUMN btrace_core.incident_user_assignments.unassigned_at IS 'When the assignment ended (e.g., resolved, handed off). NULL if active.';
COMMENT ON COLUMN btrace_core.incident_user_assignments.assigned_by IS 'User who made the assignment (e.g., incident commander). NULL if automated.';


COMMENT ON TABLE btrace_core.incident_team_assignments IS 
'Records when a team is assigned ownership of an incident. Enables team-based response models and load balancing.';

COMMENT ON COLUMN btrace_core.incident_team_assignments.assignment_id IS 'Unique identifier for the team assignment.';
COMMENT ON COLUMN btrace_core.incident_team_assignments.incident_id IS 'References the incident.';
COMMENT ON COLUMN btrace_core.incident_team_assignments.team_id IS 'The team responsible for managing the incident.';
COMMENT ON COLUMN btrace_core.incident_team_assignments.assigned_at IS 'When the team was assigned.';
COMMENT ON COLUMN btrace_core.incident_team_assignments.unassigned_at IS 'When the team''s responsibility ended.';
COMMENT ON COLUMN btrace_core.incident_team_assignments.assigned_by IS 'User who assigned the team (e.g., NOC lead). NULL if automated.';

-- find all active user assignemnts
SELECT i.title, u.username, iua.assigned_at
FROM btrace_core.incident_user_assignments iua
JOIN btrace_core.incidents i ON iua.incident_id = i.incident_id
JOIN btrace_rbac.users u ON iua.user_id = u.user_id
WHERE iua.unassigned_at IS NULL;

-- find all active team assignments 
SELECT i.title, t.team_name, ita.assigned_at
FROM btrace_core.incident_team_assignments ita
JOIN btrace_core.incidents i ON ita.incident_id = i.incident_id
JOIN btrace_rbac.teams t ON ita.team_id = t.team_id
WHERE ita.unassigned_at IS NULL;

--fetch full assignement history for an incident 
SELECT 'user' AS assignee_type, u.username AS assignee, assigned_at, unassigned_at
FROM btrace_core.incident_user_assignments iua
JOIN btrace_rbac.users u ON iua.user_id = u.user_id
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
UNION ALL
SELECT 'team', t.team_name, assigned_at, unassigned_at
FROM btrace_core.incident_team_assignments ita
JOIN btrace_rbac.teams t ON ita.team_id = t.team_id
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY assigned_at;




-- Incident Related Data: Links between incidents and telemetry data
--
-- BUSINESS CASE:
-- The `incident_related_data` table links incidents to relevant telemetry data (e.g., a trace, a log, a metric alert).
-- It enables contextual debugging by allowing responders to jump directly from an incident to the root cause evidence.
-- This is essential for reducing MTTR (Mean Time to Resolve) and improving incident investigation efficiency.
--
-- PURPOSE:
-- - Correlate incidents with distributed traces, logs, spans, and metrics
-- - Support "drill-down" workflows in observability UIs
-- - Enable automated linking (e.g., "this P1 incident is linked to 12 ERROR logs")
-- - Facilitate post-mortem evidence collection
-- - Build a knowledge graph of incident context
--

CREATE TABLE btrace_core.incident_related_data (
    relation_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id   UUID NOT NULL,
    data_type     VARCHAR(20) NOT NULL,
    data_id       TEXT NOT NULL,
    relation_type VARCHAR(50) NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by    UUID,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Validate data_type
    CONSTRAINT chk_data_type 
        CHECK (data_type IN ('trace', 'span', 'log', 'metric')),

    -- Validate relation_type
    CONSTRAINT chk_relation_type 
        CHECK (relation_type IN (
            'root_cause_trace',      -- This trace shows the root cause
            'evidence_log',          -- This log confirms the error
            'triggering_metric',     -- This metric alert fired
            'related_span',          -- A span in the critical path
            'performance_baseline',  -- Baseline metric
            'configuration_change',  -- Link to a config event
            'manual_link'            -- User-added context
        )),

    -- Foreign Keys
    CONSTRAINT fk_related_data_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_related_data_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast: "Show all related data for this incident"
CREATE INDEX idx_incident_related_data_incident 
ON btrace_core.incident_related_data (incident_id, created_at DESC);

-- Filter by data type (e.g., show all traces)
CREATE INDEX idx_incident_related_data_type 
ON btrace_core.incident_related_data (data_type);

-- Find all links to a specific trace/log/metric
CREATE INDEX idx_incident_related_data_id 
ON btrace_core.incident_related_data (data_type, data_id);

-- Filter by relation type (e.g., only root causes)
CREATE INDEX idx_incident_related_relation_type 
ON btrace_core.incident_related_data (relation_type);

-- Who created the links?
CREATE INDEX idx_incident_related_created_by 
ON btrace_core.incident_related_data (created_by) 
WHERE created_by IS NOT NULL;

-- Covering index for incident context panel
CREATE INDEX idx_incident_related_covering 
ON btrace_core.incident_related_data (incident_id, data_type)
INCLUDE (data_id, relation_type, created_at, created_by);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_incident_related_data_updated_at
    BEFORE UPDATE ON btrace_core.incident_related_data
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	

COMMENT ON TABLE btrace_core.incident_related_data IS 
'Links an incident to relevant telemetry records (traces, logs, metrics, spans) for contextual debugging. Enables responders to quickly navigate to evidence and root cause.';

COMMENT ON COLUMN btrace_core.incident_related_data.relation_id IS 
'Unique identifier for this relationship. Used in APIs and audit logs.';

COMMENT ON COLUMN btrace_core.incident_related_data.incident_id IS 
'References the parent incident. Cascades delete if incident is archived.';

COMMENT ON COLUMN btrace_core.incident_related_data.data_type IS 
'Type of telemetry being linked: trace, span, log, or metric. Used to determine how to render or navigate to it.';

COMMENT ON COLUMN btrace_core.incident_related_data.data_id IS 
'Identifier of the linked data record (e.g., trace_id, log_id, metric_id). Stored as TEXT to support heterogeneous IDs.';

COMMENT ON COLUMN btrace_core.incident_related_data.relation_type IS 
'Semantic role of the linked data: root_cause_trace, evidence_log, triggering_metric, etc. Enables intelligent grouping and UI rendering.';

COMMENT ON COLUMN btrace_core.incident_related_data.created_at IS 
'When the link was created (automatically or manually).';

COMMENT ON COLUMN btrace_core.incident_related_data.created_by IS 
'User who added the link (e.g., responder, SRE). NULL if auto-generated by correlation engine.';

COMMENT ON COLUMN btrace_core.incident_related_data.updated_at IS 
'Automatically updated if the link is edited. Used for audit trail.';

--fetch all releated data for an incident 
SELECT 
    rd.data_type, 
    rd.data_id, 
    rd.relation_type, 
    rd.created_at, 
    u.username
FROM btrace_core.incident_related_data rd
LEFT JOIN btrace_rbac.users u ON rd.created_by = u.user_id
WHERE rd.incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY rd.created_at DESC;



--find all incidents linked to a trace 
SELECT i.title, rd.relation_type, rd.created_at
FROM btrace_core.incident_related_data rd
JOIN btrace_core.incidents i ON rd.incident_id = i.incident_id
WHERE rd.data_type = 'trace' AND rd.data_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY rd.created_at DESC;

--show only root casue evidence 
SELECT data_type, data_id
FROM btrace_core.incident_related_data
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND relation_type = 'root_cause_trace';
  
  

-- Incident Communications: Internal and external communications
--
-- BUSINESS CASE:
-- The `incident_communications` table stores all messages sent during an incident,
-- including internal updates, customer notifications, and resolution announcements.
-- It ensures transparency, supports post-mortem reviews, and provides a clear audit trail of stakeholder communication.
-- This is essential for SRE teams, customer trust, compliance, and effective incident command.
--
-- PURPOSE:
-- - Record all internal and external communications tied to an incident
-- - Support status page updates, Slack messages, and email alerts
-- - Enable collaboration and context sharing among responders
-- - Facilitate post-incident reporting and regulatory audits
-- - Integrate with chatops, notification systems, and dashboards
--

CREATE TABLE btrace_core.incident_communications (
    communication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id      UUID NOT NULL,
    communication_type VARCHAR(20) NOT NULL,
    content          TEXT NOT NULL,
    is_internal      BOOLEAN NOT NULL DEFAULT TRUE,
    sent_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_by          UUID,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE,

    -- Enforce valid communication types
    CONSTRAINT chk_communication_type 
        CHECK (communication_type IN ('update', 'resolution', 'notification', 'alert', 'summary', 'customer_update')),

    -- Foreign Keys
    CONSTRAINT fk_comm_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_comm_sent_by 
        FOREIGN KEY (sent_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all comms for this incident"
CREATE INDEX idx_incident_communications_incident 
ON btrace_core.incident_communications (incident_id, sent_at DESC);

-- Filter by type (e.g., only customer updates)
CREATE INDEX idx_incident_communications_type 
ON btrace_core.incident_communications (communication_type);

-- Filter by audience (internal vs external)
CREATE INDEX idx_incident_communications_internal 
ON btrace_core.incident_communications (is_internal);

-- Who sent the messages?
CREATE INDEX idx_incident_communications_sent_by 
ON btrace_core.incident_communications (sent_by) 
WHERE sent_by IS NOT NULL;

-- Covering index for incident comms panel
CREATE INDEX idx_incident_communications_covering 
ON btrace_core.incident_communications (incident_id, sent_at DESC)
INCLUDE (communication_type, is_internal, content, sent_by);


-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_incident_communications_updated_at
    BEFORE UPDATE ON btrace_core.incident_communications
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
	
	COMMENT ON TABLE btrace_core.incident_communications IS 
'Records all messages sent during an incident, including internal status updates and external customer notifications. Used for transparency, collaboration, and post-mortem documentation.';

COMMENT ON COLUMN btrace_core.incident_communications.communication_id IS 
'Unique identifier for the communication. Used in APIs and audit logs.';

COMMENT ON COLUMN btrace_core.incident_communications.incident_id IS 
'References the parent incident. Cascades delete if incident is archived.';

COMMENT ON COLUMN btrace_core.incident_communications.communication_type IS 
'Category of the message: update (progress), resolution (fixed), notification (alert), customer_update, summary (post-mortem). Enables filtering and automation.';

COMMENT ON COLUMN btrace_core.incident_communications.content IS 
'Full text of the message sent to stakeholders (e.g., Slack, email, status page). Should include context and next steps.';

COMMENT ON COLUMN btrace_core.incident_communications.is_internal IS 
'Indicates whether the message was for internal teams only. Set to FALSE for customer-facing communications.';

COMMENT ON COLUMN btrace_core.incident_communications.sent_at IS 
'When the message was sent or published. May differ from creation time due to approvals.';

COMMENT ON COLUMN btrace_core.incident_communications.sent_by IS 
'User who authored or approved the message (e.g., incident commander). NULL if automated.';

COMMENT ON COLUMN btrace_core.incident_communications.created_at IS 
'When the record was created in the system.';

COMMENT ON COLUMN btrace_core.incident_communications.updated_at IS 
'Automatically updated when the message is edited. Used for audit trail.';


--custmer facing 
SELECT content, sent_at, u.username AS sent_by
FROM btrace_core.incident_communications c
LEFT JOIN btrace_rbac.users u ON c.sent_by = u.user_id
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND is_internal = FALSE
  AND communication_type IN ('update', 'resolution', 'customer_update')
ORDER BY sent_at;
-- Incident Post-Mortems: Analysis of incidents after resolution
--
-- BUSINESS CASE:
-- The `incident_post_mortems` table stores detailed analyses of resolved incidents, documenting root causes,
-- impacts, timelines, and follow-up actions. It enables organizational learning, process improvement, and
-- compliance with SRE best practices. This is essential for reducing recurrence and improving system resilience.
--
-- PURPOSE:
-- - Capture knowledge from incidents in a structured format
-- - Track action items and their owners
-- - Support audit and compliance requirements (e.g., SOX, ISO27001)
-- - Facilitate sharing of lessons learned across teams
-- - Integrate with dashboards, status pages, and review workflows
--

CREATE TABLE btrace_core.incident_post_mortems (
    post_mortem_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id    UUID NOT NULL,
    title          VARCHAR(255) NOT NULL,
    summary        TEXT NOT NULL,
    root_cause     TEXT NOT NULL,
    impact_analysis TEXT NOT NULL,
    timeline_events JSONB NOT NULL,  -- Array of { timestamp, description, type }
    action_items   JSONB NOT NULL,  -- Array of { description, owner, due_date, status }
    status         VARCHAR(20) NOT NULL,
    published_at   TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    created_by     UUID,
    updated_by     UUID,

    -- Enforce valid post-mortem status
    CONSTRAINT chk_post_mortem_status 
        CHECK (status IN ('draft', 'review', 'approved', 'published', 'archived')),

    -- Ensure published_at is not before created_at
    CONSTRAINT chk_published_after_created 
        CHECK (published_at IS NULL OR published_at >= created_at),

    -- Foreign Keys
    CONSTRAINT fk_postmortem_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_postmortem_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_postmortem_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show post-mortem for this incident"
CREATE INDEX idx_post_mortems_incident_id 
ON btrace_core.incident_post_mortems (incident_id);

-- Filter by status (e.g., show all drafts)
CREATE INDEX idx_post_mortems_status 
ON btrace_core.incident_post_mortems (status);

-- Find recently published post-mortems
CREATE INDEX idx_post_mortems_published_at 
ON btrace_core.incident_post_mortems (published_at DESC)
WHERE published_at IS NOT NULL;

-- Who created/updated?
CREATE INDEX idx_post_mortems_created_by 
ON btrace_core.incident_post_mortems (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_post_mortems_updated_by 
ON btrace_core.incident_post_mortems (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for post-mortem dashboard
CREATE INDEX idx_post_mortems_covering 
ON btrace_core.incident_post_mortems (status, created_at DESC)
INCLUDE (title, incident_id, published_at, created_by);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_incident_post_mortems_updated_at
    BEFORE UPDATE ON btrace_core.incident_post_mortems
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_core.incident_post_mortems IS 
'Detailed analysis of an incident after resolution. Documents root cause, impact, timeline, and action items. Used for organizational learning, compliance, and preventing recurrence.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.post_mortem_id IS 
'Unique identifier for the post-mortem document. Used in APIs and references.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.incident_id IS 
'References the parent incident. Cascades delete if incident is archived.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.title IS 
'Clear, concise title summarizing the incident (e.g., "Payment Processing Outage - June 2025"). Used in reports and dashboards.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.summary IS 
'High-level overview of what happened, when, and how it was resolved. Intended for executives and cross-functional teams.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.root_cause IS 
'Detailed technical explanation of the underlying cause (e.g., "Race condition in inventory service"). Should include evidence and analysis.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.impact_analysis IS 
'Business and customer impact: duration, affected users, revenue loss, SLA breaches. Critical for prioritization and communication.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.timeline_events IS 
'Chronological list of key events during the incident (e.g., detection, mitigation, resolution). Stored as JSONB for flexibility.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.action_items IS 
'List of follow-up tasks with owners and due dates to prevent recurrence (e.g., "Add retry logic", "Improve alerting").';

COMMENT ON COLUMN btrace_core.incident_post_mortems.status IS 
'Current lifecycle stage: draft, review, approved, published, archived. Controls visibility and workflow.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.published_at IS 
'When the post-mortem was finalized and shared with stakeholders. NULL if not yet published.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.created_at IS 
'When the post-mortem was first created (usually after incident resolution).';

COMMENT ON COLUMN btrace_core.incident_post_mortems.updated_at IS 
'Automatically updated when the post-mortem is edited. Used for audit trail.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.created_by IS 
'User who initiated the post-mortem (e.g., incident commander, SRE lead). NULL if auto-created.';

COMMENT ON COLUMN btrace_core.incident_post_mortems.updated_by IS 
'Last user to edit the post-mortem. NULL if untracked.';

SELECT title, summary, root_cause, published_at
FROM btrace_core.incident_post_mortems
WHERE incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678';

SELECT p.title, i.title AS incident_title, p.published_at, u.username AS created_by
FROM btrace_core.incident_post_mortems p
JOIN btrace_core.incidents i ON p.incident_id = i.incident_id
LEFT JOIN btrace_rbac.users u ON p.created_by = u.user_id
WHERE p.status = 'published'
ORDER BY p.published_at DESC;

SELECT 
    p.title AS post_mortem,
    jsonb_array_elements(p.action_items) AS action_item
FROM btrace_core.incident_post_mortems p
WHERE p.status = 'published';

-- Alert Rules: Definitions of alert conditions
--
-- BUSINESS CASE:
-- The `alert_rules` table defines the conditions under which system alerts are triggered (e.g., high error rate, latency spike).
-- It enables proactive monitoring, incident prevention, and SLO enforcement.
-- This table is essential for SRE teams, DevOps engineers, and platform reliability.
--
-- PURPOSE:
-- - Centralize alert rule definitions for auditability and consistency
-- - Support rule inheritance by service and environment
-- - Enable UI-based rule management and discovery
-- - Facilitate integration with alerting engines and notification systems
-- - Track ownership and lifecycle of alerting logic
--

CREATE TABLE btrace_core.alert_rules (
    rule_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name       VARCHAR(100) NOT NULL,
    description     TEXT,
    rule_type       VARCHAR(50) NOT NULL,
    rule_condition  TEXT NOT NULL,
    severity        VARCHAR(10) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    service_id      UUID,
    environment_id  UUID,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,
    created_by      UUID,
    updated_by      UUID,

    -- Enforce unique rule names
    CONSTRAINT uq_rule_name 
        UNIQUE (rule_name),

    -- Validate rule_type
    CONSTRAINT chk_rule_type 
        CHECK (rule_type IN ('metric', 'log', 'trace', 'anomaly', 'slo_burn_rate')),

    -- Validate severity
    CONSTRAINT chk_severity 
        CHECK (severity IN ('P1', 'P2', 'P3', 'P4', 'P5')),

    -- Foreign Keys
    CONSTRAINT fk_alert_rules_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_alert_rules_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_alert_rules_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_alert_rules_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast lookup by name
CREATE INDEX idx_alert_rules_name ON btrace_core.alert_rules (rule_name);

-- Filter by active status
CREATE INDEX idx_alert_rules_is_active ON btrace_core.alert_rules (is_active);

-- Filter by type and severity (e.g., active P1 metric alerts)
CREATE INDEX idx_alert_rules_type_severity 
ON btrace_core.alert_rules (rule_type, severity) 
WHERE is_active = TRUE;

-- Find rules for a specific service
CREATE INDEX idx_alert_rules_service_id 
ON btrace_core.alert_rules (service_id) 
WHERE service_id IS NOT NULL;

-- Find rules for a specific environment
CREATE INDEX idx_alert_rules_environment_id 
ON btrace_core.alert_rules (environment_id) 
WHERE environment_id IS NOT NULL;

-- Audit: who created/updated?
CREATE INDEX idx_alert_rules_created_by 
ON btrace_core.alert_rules (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_alert_rules_updated_by 
ON btrace_core.alert_rules (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for alert rules dashboard
CREATE INDEX idx_alert_rules_covering 
ON btrace_core.alert_rules (is_active, severity, rule_type)
INCLUDE (rule_name, description, service_id, environment_id, created_at, updated_at);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_alert_rules_updated_at
    BEFORE UPDATE ON btrace_core.alert_rules
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.alert_rules IS 
'Defines the conditions under which alerts are triggered (e.g., metric thresholds, log patterns). Used by the alerting engine to detect system issues and notify responders.';

COMMENT ON COLUMN btrace_core.alert_rules.rule_id IS 
'Unique identifier for the alert rule. Used in APIs, dashboards, and audit logs.';

COMMENT ON COLUMN btrace_core.alert_rules.rule_name IS 
'Human-readable name of the rule (e.g., "High HTTP 5xx Rate"). Must be unique across the system.';

COMMENT ON COLUMN btrace_core.alert_rules.description IS 
'Description of what the rule monitors, why it exists, and its expected behavior. Used for onboarding and troubleshooting.';

COMMENT ON COLUMN btrace_core.alert_rules.rule_type IS 
'Category of telemetry that triggers the alert: metric, log, trace, anomaly, or SLO burn rate. Determines evaluation engine.';

COMMENT ON COLUMN btrace_core.alert_rules.rule_condition IS 
'Expression or query that defines the alert trigger (e.g., "rate(errors[5m]) > 0.1"). Stored as text for flexibility.';

COMMENT ON COLUMN btrace_core.alert_rules.severity IS 
'Urgency level (P1-P5): P1 = critical outage, P2 = major degradation, etc. Drives escalation and response SLAs.';

COMMENT ON COLUMN btrace_core.alert_rules.is_active IS 
'Indicates whether the rule is currently being evaluated. Set to FALSE to disable without deletion.';

COMMENT ON COLUMN btrace_core.alert_rules.service_id IS 
'Optional: service this rule applies to. NULL if global (e.g., infrastructure-wide CPU alert).';

COMMENT ON COLUMN btrace_core.alert_rules.environment_id IS 
'Optional: environment this rule applies to (e.g., production). NULL if cross-environment.';

COMMENT ON COLUMN btrace_core.alert_rules.created_at IS 
'When the rule was created.';

COMMENT ON COLUMN btrace_core.alert_rules.updated_at IS 
'Automatically updated when the rule is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_core.alert_rules.created_by IS 
'Optional: user who created the rule. NULL if seeded or automated.';

COMMENT ON COLUMN btrace_core.alert_rules.updated_by IS 
'Optional: last user to update the rule. NULL if untracked.';


-- get all active P1 alerts 
SELECT rule_name, description, rule_type, service_id, environment_id
FROM btrace_core.alert_rules
WHERE is_active = TRUE AND severity = 'P1'
ORDER BY rule_name;


SELECT rule_name, rule_condition, severity
FROM btrace_core.alert_rules
WHERE service_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678';

SELECT 
    rule_name,
    severity,
    rule_type,
    description
FROM btrace_core.alert_rules
WHERE is_active = TRUE
ORDER BY severity, rule_name;


-- Alerts: Triggered alert instances
--
-- BUSINESS CASE:
-- The `alerts` table records individual instances when an alert rule is triggered (e.g., "CPU > 90%").
-- It enables real-time monitoring, response tracking, and integration with incident management.
-- This is essential for SRE teams, NOC operations, and ensuring no alert is missed.
--
-- PURPOSE:
-- - Track the lifecycle of alert instances (open → acknowledged → resolved)
-- - Support alert deduplication, grouping, and routing
-- - Enable integration with incident creation and notification systems
-- - Facilitate alert history analysis and MTTA (Mean Time to Acknowledge)
-- - Provide audit trail for compliance and post-incident reviews
--

CREATE TABLE btrace_core.alerts (
    alert_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id        UUID NOT NULL,
    title          VARCHAR(255) NOT NULL,
    description    TEXT,
    status         VARCHAR(20) NOT NULL,
    severity       VARCHAR(10) NOT NULL,
    triggered_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at    TIMESTAMP WITH TIME ZONE,
    incident_id    UUID,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Enforce valid alert status
    CONSTRAINT chk_alert_status 
        CHECK (status IN ('open', 'acknowledged', 'suppressed', 'resolved')),

    -- Enforce valid severity (must match rule)
    CONSTRAINT chk_alert_severity 
        CHECK (severity IN ('P1', 'P2', 'P3', 'P4', 'P5')),

    -- Ensure resolved_at >= triggered_at
    CONSTRAINT chk_resolved_after_triggered 
        CHECK (resolved_at IS NULL OR resolved_at >= triggered_at),

    -- Foreign Keys
    CONSTRAINT fk_alerts_rule_id 
        FOREIGN KEY (rule_id) 
        REFERENCES btrace_core.alert_rules (rule_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_alerts_incident_id 
        FOREIGN KEY (incident_id) 
        REFERENCES btrace_core.incidents (incident_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all open alerts"
CREATE INDEX idx_alerts_status 
ON btrace_core.alerts (status)
WHERE status IN ('open', 'acknowledged');

-- Filter by severity (P1/P2)
CREATE INDEX idx_alerts_severity 
ON btrace_core.alerts (severity)
WHERE status IN ('open', 'acknowledged');

-- Find recent alerts
CREATE INDEX idx_alerts_triggered_at 
ON btrace_core.alerts (triggered_at DESC);

-- Find alerts by rule (e.g., "how often does this fire?")
CREATE INDEX idx_alerts_rule_id 
ON btrace_core.alerts (rule_id, triggered_at DESC);

-- Find alerts linked to incidents
CREATE INDEX idx_alerts_incident_id 
ON btrace_core.alerts (incident_id) 
WHERE incident_id IS NOT NULL;

-- Covering index for alert dashboard
CREATE INDEX idx_alerts_covering 
ON btrace_core.alerts (status, severity, triggered_at DESC)
INCLUDE (title, rule_id, resolved_at, incident_id);


-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_alerts_updated_at
    BEFORE UPDATE ON btrace_core.alerts
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_core.alerts IS 
'Records individual instances of triggered alert rules. Each row represents an active or resolved alert, used for real-time monitoring, response tracking, and incident correlation.';

COMMENT ON COLUMN btrace_core.alerts.alert_id IS 
'Unique identifier for the alert instance. Used in APIs, notifications, and UIs.';

COMMENT ON COLUMN btrace_core.alerts.rule_id IS 
'References the rule that triggered this alert. Cascades delete if rule is removed.';

COMMENT ON COLUMN btrace_core.alerts.title IS 
'Summary of the alert (e.g., "High Error Rate in Payment Service"). Used in notifications and dashboards.';

COMMENT ON COLUMN btrace_core.alerts.description IS 
'Detailed explanation of the condition that triggered the alert, including context and suggested actions.';

COMMENT ON COLUMN btrace_core.alerts.status IS 
'Current lifecycle stage: open, acknowledged, suppressed, resolved. Drives notification and escalation logic.';

COMMENT ON COLUMN btrace_core.alerts.severity IS 
'Urgency level inherited from the alert rule (P1-P5). P1 = critical, P2 = major, etc.';

COMMENT ON COLUMN btrace_core.alerts.triggered_at IS 
'When the alert condition was first met and the alert was created.';

COMMENT ON COLUMN btrace_core.alerts.resolved_at IS 
'When the alert was manually or automatically resolved. NULL if still active.';

COMMENT ON COLUMN btrace_core.alerts.incident_id IS 
'Optional: links this alert to an incident if one was created. NULL if no incident or not yet linked.';

COMMENT ON COLUMN btrace_core.alerts.created_at IS 
'When the alert record was created in the system (same as triggered_at unless delayed).';

COMMENT ON COLUMN btrace_core.alerts.updated_at IS 
'Automatically updated when the alert status changes. Used for audit trail.';

--list all active p1/p2 alerts
SELECT title, triggered_at, severity, rule_id
FROM btrace_core.alerts
WHERE status IN ('open', 'acknowledged')
  AND severity IN ('P1', 'P2')
ORDER BY triggered_at DESC;

-- link alert to incident 
UPDATE btrace_core.alerts
SET incident_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678',
    status = 'acknowledged',
    updated_at = NOW()
WHERE alert_id = 'e1f2g3h4-5678-90ab-cdef-1234567890ab';

-- computer MTTA(Mean Time to Acknowledge)
SELECT 
    AVG(acknowledged_at - triggered_at) AS avg_mtta
FROM (
    SELECT 
        triggered_at,
        updated_at AS acknowledged_at
    FROM btrace_core.alerts
    WHERE status = 'resolved'
      AND updated_at > triggered_at
) t;



-- Alert Notifications: Notifications sent for alerts
--
-- BUSINESS CASE:
-- The `alert_notifications` table records every delivery attempt made when an alert is triggered.
-- It enables delivery auditing, failure analysis, and compliance with incident response SLAs.
-- This is essential for ensuring alerts are not missed and for diagnosing notification system issues.
--
-- PURPOSE:
-- - Track which alerts were sent, to whom, and through which channel
-- - Monitor delivery success/failure rates
-- - Support root cause analysis when alerts are not received
-- - Enable integration with audit logs and SRE reviews
-- - Facilitate retry logic and escalation workflows
--

CREATE TABLE btrace_core.alert_notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id        UUID NOT NULL,
    channel         VARCHAR(50) NOT NULL,
    recipient       TEXT NOT NULL,
    content         TEXT NOT NULL,
    sent_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) NOT NULL,
    error_message   TEXT,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,

    -- Validate notification channel
    CONSTRAINT chk_notification_channel 
        CHECK (channel IN ('email', 'slack', 'webhook', 'sms')),

    -- Validate delivery status
    CONSTRAINT chk_notification_status 
        CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'retrying')),

    -- Foreign Key
    CONSTRAINT fk_alert_notifications_alert_id 
        FOREIGN KEY (alert_id) 
        REFERENCES btrace_core.alerts (alert_id) 
        ON DELETE CASCADE
);

-- Fast: "Show all notifications for this alert"
CREATE INDEX idx_alert_notifications_alert_id 
ON btrace_core.alert_notifications (alert_id, sent_at DESC);

-- Filter by delivery status (e.g., show all failed)
CREATE INDEX idx_alert_notifications_status 
ON btrace_core.alert_notifications (status)
WHERE status = 'failed';

-- Find recent notifications (for real-time dashboards)
CREATE INDEX idx_alert_notifications_sent_at 
ON btrace_core.alert_notifications (sent_at DESC);

-- Filter by channel (e.g., all Slack alerts)
CREATE INDEX idx_alert_notifications_channel 
ON btrace_core.alert_notifications (channel);

-- Covering index for alert history panel
CREATE INDEX idx_alert_notifications_covering 
ON btrace_core.alert_notifications (alert_id, sent_at DESC)
INCLUDE (channel, recipient, status, error_message);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_alert_notifications_updated_at
    BEFORE UPDATE ON btrace_core.alert_notifications
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.alert_notifications IS 
'Records every delivery attempt for an alert (e.g., email, Slack). Used to audit notification reliability, diagnose failures, and ensure critical alerts are not missed.';

COMMENT ON COLUMN btrace_core.alert_notifications.notification_id IS 
'Unique identifier for the notification attempt. Used in logs, dashboards, and debugging.';

COMMENT ON COLUMN btrace_core.alert_notifications.alert_id IS 
'References the alert that triggered this notification. Cascades delete if alert is archived.';

COMMENT ON COLUMN btrace_core.alert_notifications.channel IS 
'Communication method used: email, slack, pagerduty, webhook, etc. Enables channel-specific routing and policies.';

COMMENT ON COLUMN btrace_core.alert_notifications.recipient IS 
'Destination address or identifier (e.g., "sre-team@company.com", "#alerts", "PAGERDUTY_SERVICE_KEY").';

COMMENT ON COLUMN btrace_core.alert_notifications.content IS 
'Full message content sent via the channel (e.g., alert title, description, severity). May include links to UI.';

COMMENT ON COLUMN btrace_core.alert_notifications.sent_at IS 
'When the notification was dispatched by the system. May differ from delivery time.';

COMMENT ON COLUMN btrace_core.alert_notifications.status IS 
'Current delivery state: pending, sent, delivered, failed, retrying. Critical for monitoring and escalation.';

COMMENT ON COLUMN btrace_core.alert_notifications.error_message IS 
'Error details if delivery failed (e.g., "SMTP timeout", "Slack rate limit"). Used for debugging and retries.';

COMMENT ON COLUMN btrace_core.alert_notifications.created_at IS 
'When the notification record was created (typically at dispatch time).';

COMMENT ON COLUMN btrace_core.alert_notifications.updated_at IS 
'Automatically updated if the status changes (e.g., retry). Used for audit trail.';

-- list all failed notifications in the last 24 hours
SELECT 
    a.title AS alert_title,
    channel, 
    recipient, 
    error_message, 
    sent_at
FROM btrace_core.alert_notifications n
JOIN btrace_core.alerts a ON n.alert_id = a.alert_id
WHERE n.status = 'failed'
  AND n.sent_at >= NOW() - INTERVAL '24 hours'
ORDER BY n.sent_at DESC;


--delivery success rate 
SELECT 
    channel,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE status = 'sent' OR status = 'delivered') AS success,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'sent' OR status = 'delivered') / COUNT(*), 
        2
    ) AS success_rate_pct
FROM btrace_core.alert_notifications
GROUP BY channel
ORDER BY success_rate_pct;

--find notifications for a specific alert 
SELECT channel, recipient, status, sent_at
FROM btrace_core.alert_notifications
WHERE alert_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY sent_at;


-- enhancement iteration 1
-- Add a rounded duration in seconds for fast grouping
ALTER TABLE btrace_core.traces 
ADD COLUMN duration_sec SMALLINT GENERATED ALWAYS AS (FLOOR(duration_ms / 1000.0)) STORED;

-- Index for latency tiers
CREATE INDEX idx_traces_duration_sec ON btrace_core.traces (duration_sec) WHERE is_sampled = TRUE;


-- automation: partition management 
-- to create future partitions, drop old ones, ability to attach and detach effectively 
CREATE OR REPLACE FUNCTION btrace_core.create_time_partitions()
RETURNS void AS $$
DECLARE
    trace_start DATE := DATE_TRUNC('month', NOW());
    log_start   DATE := DATE_TRUNC('day', NOW());
    metric_start DATE := DATE_TRUNC('day', NOW());
    trace_end   DATE := trace_start + INTERVAL '12 months';
    daily_end   DATE := log_start + INTERVAL '30 days';
    p_name      TEXT;
    p_start     TIMESTAMP;
    p_end       TIMESTAMP;
BEGIN
    -- Traces: Monthly partitions
    FOR p_start IN SELECT generate_series(trace_start, trace_end, '1 month') LOOP
        p_end := p_start + INTERVAL '1 month';
        p_name := 'traces_' || TO_CHAR(p_start, 'YYYY_MM');
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS btrace_core.%I PARTITION OF btrace_core.traces
            FOR VALUES FROM (%L) TO (%L)',
            p_name, p_start, p_end);
    END LOOP;

    -- Logs & Metrics: Daily partitions
    FOR p_start IN SELECT generate_series(log_start, daily_end, '1 day') LOOP
        p_end := p_start + INTERVAL '1 day';
        -- Logs
        p_name := 'logs_' || TO_CHAR(p_start, 'YYYY_MM_DD');
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS btrace_core.%I PARTITION OF btrace_core.logs
            FOR VALUES FROM (%L) TO (%L)',
            p_name, p_start, p_end);

        -- Metrics
        p_name := 'metrics_' || TO_CHAR(p_start, 'YYYY_MM_DD');
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS btrace_core.%I PARTITION OF btrace_core.metrics
            FOR VALUES FROM (%L) TO (%L)',
            p_name, p_start, p_end);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- think of add a scheduler to this using pgcron extension 


-- to show top 10 slowest traces per day 
-- "Show top 10 slowest traces per day"
CREATE MATERIALIZED VIEW btrace_core.mv_daily_slow_traces AS
SELECT
    DATE(start_time) AS day,
    root_service,
    AVG(duration_ms) AS avg_duration,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms) AS p95_duration,
    COUNT(*) AS trace_count
FROM btrace_core.traces
WHERE is_sampled = TRUE
  AND start_time > NOW() - INTERVAL '30 days'
GROUP BY day, root_service;

-- Refresh nightly
CREATE INDEX idx_mv_slow_traces ON btrace_core.mv_daily_slow_traces (day DESC, p95_duration DESC);


--enable RLS(row-level security features) for multi-tenant or environment isolation
ALTER TABLE btrace_core.traces ENABLE ROW LEVEL SECURITY;

-- todo - explore the possibility of integritation with open policy Agent (OPA)

--Missing piece, user_environments table -- this defines who can access the environments
--btrace_core.environments (lookup table for environments)-- defines what environments exist. 
-- an authorization table that controls who can see what 
-- defines which users have access to which environment and this should be in RBAC module 

--
-- BUSINESS CASE:
-- The `user_environments` table defines which environments a user is authorized to access.
-- It enables environment-based access control (e.g., "only SREs can view production").
-- This is essential for security, compliance, and preventing accidental changes in critical environments.
--
-- PURPOSE:
-- - Assign environment-level permissions to users
-- - Support multi-tenancy or environment isolation
-- - Enable Row-Level Security (RLS) policies
-- - Facilitate audit of who has access to which environments
-- - Integrate with RBAC and team-based access
--
-- btrace_core.environments
--          ↑
--          │ environment_id (FK)
--          │ many-to-many via junction
--          ↓
-- btrace_rbac.user_environments
--          ↑
--          │ user_id (FK)
--          ↓
-- btrace_rbac.users

CREATE TABLE btrace_rbac.user_environments (
    user_id        UUID NOT NULL,
    environment_id UUID NOT NULL,
    role_in_env    VARCHAR(50) NOT NULL DEFAULT 'viewer',  -- e.g., viewer, editor, admin
    assigned_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by    UUID,  -- Who granted access

    -- Composite Primary Key
    CONSTRAINT pk_user_environments 
        PRIMARY KEY (user_id, environment_id),

    -- Foreign Keys
    CONSTRAINT fk_ue_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_ue_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_ue_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    -- Validate role_in_env
    CONSTRAINT chk_ue_role 
        CHECK (role_in_env IN ('viewer', 'editor', 'admin', 'observer', 'oncall'))
);

-- Fast: "What environments can this user access?"
CREATE INDEX idx_user_environments_by_user 
ON btrace_rbac.user_environments (user_id);

-- Fast: "Who can access this environment?"
CREATE INDEX idx_user_environments_by_env 
ON btrace_rbac.user_environments (environment_id);

-- Audit: Who granted access?
CREATE INDEX idx_user_environments_assigned_by 
ON btrace_rbac.user_environments (assigned_by) 
WHERE assigned_by IS NOT NULL;

-- Covering index for access checks
CREATE INDEX idx_user_environments_covering 
ON btrace_rbac.user_environments (user_id, environment_id)
INCLUDE (role_in_env, assigned_at);


COMMENT ON TABLE btrace_rbac.user_environments IS 
'Maps users to the environments they are authorized to view or manage. Used for access control, audit, and RLS policies.';

COMMENT ON COLUMN btrace_rbac.user_environments.user_id IS 
'References the user with access. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_environments.environment_id IS 
'References the environment the user can access. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.user_environments.role_in_env IS 
'Level of access: viewer (read-only), editor (modify), admin (manage access). Used for UI and API permissions.';

COMMENT ON COLUMN btrace_rbac.user_environments.assigned_at IS 
'When the access was granted. Used for audit and access reviews.';

COMMENT ON COLUMN btrace_rbac.user_environments.assigned_by IS 
'Optional: user who granted the access (e.g., team lead). NULL if auto-provisioned.';


-- Enable RLS
ALTER TABLE btrace_core.traces ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see traces in environments they're assigned to
CREATE POLICY traces_env_policy ON btrace_core.traces
FOR SELECT USING (
    environment_id IN (
        SELECT environment_id 
        FROM btrace_rbac.user_environments 
        WHERE user_id = current_setting('app.current_user')::UUID
    )
);

-- what if teams based environment access is required?
-- maintainable than assigning access at the individual user level.
--
-- BUSINESS CASE:
-- The `team_environments` table defines which environments a team is authorized to access and at what privilege level.
-- It enables team-based access control (e.g., "SRE Team" has 'admin' access to production, "Dev Team" has 'read' access to staging).
-- This is essential for scalable permission management, reducing individual assignments, and supporting least-privilege security.
--
-- PURPOSE:
-- - Assign environment access at the team level instead of per-user
-- - Support role-based workflows (e.g., on-call rotations, CI/CD pipelines)
-- - Enable Row-Level Security (RLS) policies based on team membership
-- - Facilitate audit and access reviews ("Which teams can modify production?")
-- - Integrate with team-based alerting and ownership models
--


CREATE TABLE btrace_rbac.team_environments (
    team_id        UUID NOT NULL,
    environment_id UUID NOT NULL,
    access_level   VARCHAR(20) NOT NULL DEFAULT 'read',
    assigned_by    UUID,
    assigned_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Composite Primary Key
    CONSTRAINT pk_team_environments 
        PRIMARY KEY (team_id, environment_id),

    -- Validate access_level
    CONSTRAINT chk_access_level 
        CHECK (access_level IN ('read', 'write', 'admin', 'observer', 'oncall')),

    -- Foreign Keys
    CONSTRAINT fk_team_env_team_id 
        FOREIGN KEY (team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_team_env_environment_id 
        FOREIGN KEY (environment_id) 
        REFERENCES btrace_core.environments (environment_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_team_env_assigned_by 
        FOREIGN KEY (assigned_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast: "Which teams can access this environment?"
CREATE INDEX idx_team_environments_by_env 
ON btrace_rbac.team_environments (environment_id);

-- Fast: "What environments can this team access?"
CREATE INDEX idx_team_environments_by_team 
ON btrace_rbac.team_environments (team_id);

-- Filter by access level (e.g., show all admin teams)
CREATE INDEX idx_team_environments_access_level 
ON btrace_rbac.team_environments (access_level);

-- Audit: Who granted access?
CREATE INDEX idx_team_environments_assigned_by 
ON btrace_rbac.team_environments (assigned_by) 
WHERE assigned_by IS NOT NULL;

-- Covering index for access control checks
CREATE INDEX idx_team_environments_covering 
ON btrace_rbac.team_environments (team_id, environment_id)
INCLUDE (access_level, assigned_at, assigned_by);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_rbac.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_team_environments_updated_at
    BEFORE UPDATE ON btrace_rbac.team_environments
    FOR EACH ROW
    EXECUTE FUNCTION btrace_rbac.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_rbac.team_environments IS 
'Defines environment access permissions for teams. Enables scalable, auditable, and consistent access control (e.g., ''SRE Team'' has admin access to production). Used for UI filtering, RLS policies, and compliance reviews.';

COMMENT ON COLUMN btrace_rbac.team_environments.team_id IS 
'References the team granted access. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.team_environments.environment_id IS 
'References the environment being accessed. Part of composite primary key.';

COMMENT ON COLUMN btrace_rbac.team_environments.access_level IS 
'Privilege level: read (view), write (modify), admin (manage access), observer, oncall. Drives UI and API behavior.';

COMMENT ON COLUMN btrace_rbac.team_environments.assigned_by IS 
'Optional: user who granted this access (e.g., platform lead). NULL if auto-provisioned via IaC.';

COMMENT ON COLUMN btrace_rbac.team_environments.assigned_at IS 
'When the access was granted. Used for audit and access certification.';

COMMENT ON COLUMN btrace_rbac.team_environments.updated_at IS 
'Automatically updated when access is modified (e.g., level changed). Used for audit trail.';

--to find all teams with access to production 
SELECT t.team_name, te.access_level, u.username AS assigned_by
FROM btrace_rbac.team_environments te
JOIN btrace_rbac.teams t ON te.team_id = t.team_id
JOIN btrace_core.environments e ON te.environment_id = e.environment_id
LEFT JOIN btrace_rbac.users u ON te.assigned_by = u.user_id
WHERE e.environment_name = 'production'
ORDER BY te.access_level, t.team_name;

-- to find all environments a team can access
SELECT e.environment_name, te.access_level
FROM btrace_rbac.team_environments te
JOIN btrace_core.environments e ON te.environment_id = e.environment_id
WHERE te.team_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY e.environment_name;

--policy Row level Security (RLS) using team membership
-- Policy: Users can see traces only in environments their team can access
CREATE POLICY traces_team_env_policy ON btrace_core.traces
FOR SELECT USING (
    environment_id IN (
        SELECT te.environment_id
        FROM btrace_rbac.user_teams ut
        JOIN btrace_rbac.team_environments te ON ut.team_id = te.team_id
        WHERE ut.user_id = current_setting('app.current_user')::UUID
    )
);


--data masking for PII in logs 
ALTER TABLE btrace_core.logs ADD COLUMN contains_pii BOOLEAN DEFAULT FALSE;
CREATE INDEX idx_logs_contains_pii ON btrace_core.logs (contains_pii) WHERE contains_pii = TRUE;

-- Secure view for non-privileged users
CREATE OR REPLACE VIEW btrace_core.logs_secure AS
SELECT
    log_id,
    timestamp,
    service_name,
    host_name,
    log_level,
    CASE 
        WHEN contains_pii THEN '[REDACTED]' 
        ELSE message 
    END AS message,
    trace_id,
    CASE 
        WHEN contains_pii THEN attributes - 'user_id' - 'email'
        ELSE attributes
    END AS attributes
FROM btrace_core.logs;


-- CREATE INDEX idx_logs_contains_pii ON btrace_core.logs (contains_pii) WHERE contains_pii = TRUE;

--
-- BUSINESS CASE:
-- The `metric_definitions` table serves as a centralized catalog of all metrics collected across services.
-- It enables discoverability, standardization, and documentation of metrics for engineers, SREs, and platform teams.
-- Without this, teams face "metric sprawl" — unclear, inconsistent, or duplicated metrics.
--
-- PURPOSE:
-- - Provide self-service discovery of available metrics
-- - Enforce naming and semantic consistency (e.g., via standard types/units)
-- - Document meaning, usage, and ownership of metrics
-- - Support UIs (e.g., metric explorer), documentation generators, and onboarding
-- - Distinguish standard vs. custom metrics for governance
-- - Enable integration with SLO/SLI tooling
--

CREATE TABLE btrace_core.metric_definitions (
    definition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name   VARCHAR(255) NOT NULL,
    description   TEXT,
    metric_type   VARCHAR(50) NOT NULL 
        CHECK (metric_type IN ('gauge', 'counter', 'histogram', 'summary', 'sum', 'avg')),
    unit          VARCHAR(50),
    service_id    UUID,
    data_source   VARCHAR(50) DEFAULT 'application' 
        CHECK (data_source IN ('application', 'infrastructure', 'kubernetes', 'database', 'network')),
    is_standard   BOOLEAN NOT NULL DEFAULT TRUE,
    is_custom     BOOLEAN NOT NULL DEFAULT FALSE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    tags          JSONB,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,
    updated_by    UUID,

    -- Enforce unique metric name per service
    CONSTRAINT uq_metric_name_service 
        UNIQUE (metric_name, service_id),

    -- Ensure is_standard and is_custom are consistent
    CONSTRAINT chk_standard_custom 
        CHECK (
            (is_standard AND NOT is_custom) OR 
            (NOT is_standard AND is_custom) OR 
            (is_standard AND is_custom = FALSE)
        ),

    -- Foreign Keys
    CONSTRAINT fk_metric_def_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_metric_def_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_metric_def_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- For fast lookup by name (common in UI/search)
CREATE INDEX idx_metric_def_name ON btrace_core.metric_definitions (metric_name);

-- For filtering by service and type
CREATE INDEX idx_metric_def_service_type 
ON btrace_core.metric_definitions (service_id, metric_type);

-- For searching by tags (e.g., "slo=true", "team=auth")
CREATE INDEX idx_metric_def_tags_gin 
ON btrace_core.metric_definitions USING GIN (tags);

-- For listing active metrics by source
CREATE INDEX idx_metric_def_data_source 
ON btrace_core.metric_definitions (data_source, is_active);

-- ✅ Fixed full-text search on description (no WHERE clause)
-- Resolves: "functions in index predicate must be marked IMMUTABLE"
CREATE INDEX idx_metric_def_description_gin 
ON btrace_core.metric_definitions 
USING GIN (to_tsvector('english', COALESCE(description, '')));
COMMENT ON TABLE btrace_core.metric_definitions IS 
'Master catalog of all metrics, providing metadata, documentation, and governance. Used by developers, SREs, and dashboards to discover and understand available metrics.';

COMMENT ON COLUMN btrace_core.metric_definitions.definition_id IS 
'Unique identifier for the metric definition. Used in APIs and references.';

COMMENT ON COLUMN btrace_core.metric_definitions.metric_name IS 
'Canonical name of the metric (e.g., "http.server.request.duration"). Should follow consistent naming conventions and be low-cardinality.';

COMMENT ON COLUMN btrace_core.metric_definitions.description IS 
'Human-readable explanation of what the metric measures, how it is used, and any caveats. Critical for onboarding and compliance.';

COMMENT ON COLUMN btrace_core.metric_definitions.metric_type IS 
'The semantic type of the metric: gauge, counter, histogram, etc. Aligns with OpenTelemetry and Prometheus conventions.';

COMMENT ON COLUMN btrace_core.metric_definitions.unit IS 
'Standardized unit of measurement (e.g., "s", "ms", "bytes", "count", "percent"). Critical for correct visualization and alerting.';

COMMENT ON COLUMN btrace_core.metric_definitions.service_id IS 
'Optional: service that owns or emits this metric. NULL if global (e.g., infrastructure, platform). Used for ownership and filtering.';

COMMENT ON COLUMN btrace_core.metric_definitions.data_source IS 
'Where the metric originates: application, infrastructure, Kubernetes, etc. Helps with filtering and ownership.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_standard IS 
'True if this is a well-known, standardized metric (e.g., HTTP request count). Used for governance and best practices.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_custom IS 
'True if this is a team-specific or ad-hoc metric. Helps identify potential sprawl or technical debt.';

COMMENT ON COLUMN btrace_core.metric_definitions.is_active IS 
'Flag to deprecate or archive metrics no longer in use. Avoids deletion while preserving history.';

COMMENT ON COLUMN btrace_core.metric_definitions.tags IS 
'Flexible key-value metadata for classification: team, SLO relevance, PII, environment scope, etc. Enables powerful filtering.';

COMMENT ON COLUMN btrace_core.metric_definitions.created_at IS 
'When the metric was registered in the catalog.';

COMMENT ON COLUMN btrace_core.metric_definitions.updated_at IS 
'Automatically updated when the definition is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_core.metric_definitions.created_by IS 
'Optional: user who registered this metric. NULL if auto-discovered or seeded.';

COMMENT ON COLUMN btrace_core.metric_definitions.updated_by IS 
'Optional: last user to update the metric metadata. NULL if untracked.';


-- Discovering metrics 
SELECT 
    metric_name,
    description,
    unit,
    data_source,
    is_standard
FROM btrace_core.metric_definitions
WHERE to_tsvector('english', COALESCE(description, '')) @@ to_tsquery('english', 'error & latency')
  AND is_active = TRUE
ORDER BY is_standard DESC, metric_name;

--
-- BUSINESS CASE:
-- The `service_dependencies` table captures runtime relationships between services (e.g., "auth-service calls user-service").
-- It enables automatic service map visualization, impact analysis, and root cause identification during incidents.
-- This is essential for understanding complex microservice architectures and improving system observability.
--
-- PURPOSE:
-- - Discover and store service-to-service communication patterns
-- - Support dynamic service topology views (e.g., dependency graphs)
-- - Enable impact analysis ("What depends on this service?")
-- - Power alert correlation and root cause suggestions
-- - Facilitate architecture reviews and documentation
--

CREATE TABLE btrace_core.service_dependencies (
    source_service_id UUID NOT NULL,
    target_service_id UUID NOT NULL,
    dependency_type   VARCHAR(20) NOT NULL,
    call_count        BIGINT DEFAULT 1,
    error_rate        DOUBLE PRECISION DEFAULT 0.0,
    avg_latency_ms    DOUBLE PRECISION,
    min_latency_ms    DOUBLE PRECISION,
    max_latency_ms    DOUBLE PRECISION,
    last_seen         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE,

    -- Composite Primary Key
    CONSTRAINT pk_service_dependencies 
        PRIMARY KEY (source_service_id, target_service_id, dependency_type),

    -- Validate dependency_type
    CONSTRAINT chk_dependency_type 
        CHECK (dependency_type IN ('http', 'grpc', 'kafka', 'rabbitmq', 'db', 'redis', 'sqs', 's3', 'eventbridge')),

    -- Ensure valid metrics
    CONSTRAINT chk_error_rate_range 
        CHECK (error_rate >= 0.0 AND error_rate <= 1.0),
    CONSTRAINT chk_latency_non_negative 
        CHECK (avg_latency_ms IS NULL OR avg_latency_ms >= 0),
    CONSTRAINT chk_min_le_avg_le_max 
        CHECK (
            (min_latency_ms IS NULL OR avg_latency_ms IS NULL OR min_latency_ms <= avg_latency_ms) AND
            (avg_latency_ms IS NULL OR max_latency_ms IS NULL OR avg_latency_ms <= max_latency_ms)
        ),

    -- Prevent self-dependency
    CONSTRAINT chk_no_self_dependency 
        CHECK (source_service_id != target_service_id),

    -- Foreign Keys
    CONSTRAINT fk_dep_source_service 
        FOREIGN KEY (source_service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_dep_target_service 
        FOREIGN KEY (target_service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE
);

-- === Indexes for Performance ===
-- For fast lookup by name (common in UI/search)
CREATE INDEX idx_metric_def_name ON btrace_core.metric_definitions (metric_name);

-- For filtering by service and type
CREATE INDEX idx_metric_def_service_type 
ON btrace_core.metric_definitions (service_id, metric_type);

-- For searching by tags (e.g., "slo=true", "team=auth")
CREATE INDEX idx_metric_def_tags_gin 
ON btrace_core.metric_definitions USING GIN (tags);

-- For listing active metrics by source
CREATE INDEX idx_metric_def_data_source 
ON btrace_core.metric_definitions (data_source, is_active);

-- Fixed full-text search on description
CREATE INDEX idx_metric_def_description_gin 
ON btrace_core.metric_definitions 
USING GIN (to_tsvector('english', COALESCE(description, '')));

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_service_dependencies_updated_at
    BEFORE UPDATE ON btrace_core.service_dependencies
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.service_dependencies IS 
'Records runtime dependencies between services (e.g., ''auth-service → user-service via HTTP''). Used to generate service maps, analyze impact, and support root cause analysis. Updated continuously from span data.';

COMMENT ON COLUMN btrace_core.service_dependencies.source_service_id IS 
'The service initiating the call (e.g., frontend, auth-service). Part of composite primary key.';

COMMENT ON COLUMN btrace_core.service_dependencies.target_service_id IS 
'The service being called (e.g., user-service, payment-db). Part of composite primary key.';

COMMENT ON COLUMN btrace_core.service_dependencies.dependency_type IS 
'Protocol or system used for communication: http, grpc, kafka, db, etc. Enables filtering and protocol-specific analysis.';

COMMENT ON COLUMN btrace_core.service_dependencies.call_count IS 
'Number of observed calls over the aggregation window. Used to gauge dependency strength.';

COMMENT ON COLUMN btrace_core.service_dependencies.error_rate IS 
'Proportion of failed calls (0.0 to 1.0). High values indicate potential instability or integration issues.';

COMMENT ON COLUMN btrace_core.service_dependencies.avg_latency_ms IS 
'Average round-trip latency in milliseconds. Key indicator of performance health.';

COMMENT ON COLUMN btrace_core.service_dependencies.min_latency_ms IS 
'Minimum observed latency in the aggregation period.';

COMMENT ON COLUMN btrace_core.service_dependencies.max_latency_ms IS 
'Maximum observed latency in the aggregation period.';

COMMENT ON COLUMN btrace_core.service_dependencies.last_seen IS 
'Timestamp of the most recent observed call. Used to determine if a dependency is still active.';

COMMENT ON COLUMN btrace_core.service_dependencies.created_at IS 
'When the dependency was first observed.';

COMMENT ON COLUMN btrace_core.service_dependencies.updated_at IS 
'Automatically updated when metrics (call_count, error_rate, etc.) are refreshed. Used for staleness detection.';


-- get all dependencies for a service 
SELECT 
    src.service_name AS source,
    tgt.service_name AS target,
    dependency_type,
    call_count,
    error_rate,
    avg_latency_ms,
    last_seen
FROM btrace_core.service_dependencies d
JOIN btrace_core.services src ON d.source_service_id = src.service_id
JOIN btrace_core.services tgt ON d.target_service_id = tgt.service_id
WHERE src.service_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY call_count DESC;

--find high-error dependencies 
SELECT 
    src.service_name, 
    tgt.service_name, 
    dependency_type, 
    error_rate
FROM btrace_core.service_dependencies d
JOIN btrace_core.services src ON d.source_service_id = src.service_id
JOIN btrace_core.services tgt ON d.target_service_id = tgt.service_id
WHERE error_rate > 0.1
  AND last_seen > NOW() - INTERVAL '1 hour'
ORDER BY error_rate DESC;

-- -- to delete stale dependencies 
-- DELETE FROM btrace_core.service_dependencies
-- WHERE last_seen < NOW() - INTERVAL '30 days';


-- service level objectives
--
-- BUSINESS CASE:
-- The `slos` table defines measurable Service Level Objectives (SLOs) for services, specifying reliability targets
-- (e.g., "99.95% availability over 28 days"). It enables data-driven reliability management, error budget tracking,
-- and objective decision-making during incidents. This is essential for SRE teams and executive reporting.
--
-- PURPOSE:
-- - Define and track reliability goals for services
-- - Enable error budget consumption monitoring
-- - Support alerting when SLOs are at risk
-- - Facilitate post-incident reviews ("Did we burn through the budget?")
-- - Integrate with dashboards, status pages, and governance reports
--

CREATE TABLE btrace_core.slos (
    slo_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id    UUID NOT NULL,
    metric_name   VARCHAR(255) NOT NULL,
    target        DOUBLE PRECISION NOT NULL,
    time_window       INTERVAL NOT NULL,
    description   TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Enforce valid SLO target (0.0 to 1.0)
    CONSTRAINT chk_slo_target_range 
        CHECK (target >= 0.0 AND target <= 1.0),

    -- Ensure window is positive
    CONSTRAINT chk_slo_positive_window 
        CHECK (time_window > INTERVAL '0 seconds'),

    -- Foreign Key
    CONSTRAINT fk_slo_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE
);

-- Fast: "Show all SLOs for this service"
CREATE INDEX idx_slos_service_id 
ON btrace_core.slos (service_id);

-- Filter by active status (most common)
CREATE INDEX idx_slos_is_active 
ON btrace_core.slos (is_active);

-- Find all SLOs with a specific metric (e.g., error rate)
CREATE INDEX idx_slos_metric_name 
ON btrace_core.slos (metric_name);

-- Covering index for SLO dashboard
CREATE INDEX idx_slos_covering 
ON btrace_core.slos (service_id, is_active)
INCLUDE (metric_name, target, time_window, description, created_at);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_slos_updated_at
    BEFORE UPDATE ON btrace_core.slos
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	

COMMENT ON TABLE btrace_core.slos IS 
'Defines Service Level Objectives (SLOs) for services, specifying reliability targets (e.g., 99.95% uptime over 28 days). Used for error budget tracking, alerting, and reliability reporting.';

COMMENT ON COLUMN btrace_core.slos.slo_id IS 
'Unique identifier for the SLO. Used in APIs, dashboards, and references.';

COMMENT ON COLUMN btrace_core.slos.service_id IS 
'References the service this SLO applies to (e.g., "payment-service"). Enables service-level reliability reporting and filtering in dashboards. Cascades delete if service is retired.';

COMMENT ON COLUMN btrace_core.slos.metric_name IS 
'Name of the metric used to evaluate the SLO (e.g., "http.success_rate"). Must exist in metric_definitions. Defines the signal used for compliance calculation.';

COMMENT ON COLUMN btrace_core.slos.target IS 
'The reliability target as a fraction (e.g., 0.9995 = 99.95%). Defines the minimum acceptable success rate over the evaluation window.';

COMMENT ON COLUMN btrace_core.slos."time_window" IS 
'Length of time over which the SLO is evaluated (e.g., ''7 days'', ''28 days''). Aligns with industry best practices (e.g., Google''s error budgeting).';

COMMENT ON COLUMN btrace_core.slos.description IS 
'Description of the SLO''s purpose, scope, and business impact. Should include examples of compliant vs. non-compliant behavior.';

COMMENT ON COLUMN btrace_core.slos.is_active IS 
'Indicates whether the SLO is currently being enforced. Set to FALSE to deprecate without deletion. Used for lifecycle management.';

COMMENT ON COLUMN btrace_core.slos.created_at IS 
'When the SLO was created. Used for audit and change tracking.';

COMMENT ON COLUMN btrace_core.slos.updated_at IS 
'Automatically updated when the SLO is modified. Used for audit trail and change detection.';

--
-- BUSINESS CASE:
-- The `incident_action_items` table tracks follow-up tasks generated during post-mortems to prevent incident recurrence.
-- It ensures accountability by assigning owners and due dates, and enables progress tracking.
-- This is essential for organizational learning, compliance, and improving system resilience.
--
-- PURPOSE:
-- - Convert post-mortem insights into actionable tasks
-- - Assign ownership and deadlines for remediation work
-- - Monitor completion status and overdue items
-- - Support SRE reviews and leadership reporting
-- - Integrate with dashboards and notification systems
--

CREATE TABLE btrace_core.incident_action_items (
    item_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_mortem_id UUID NOT NULL,
    description   TEXT NOT NULL,
    owner_id      UUID NOT NULL,
    due_date      DATE NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'open',
    completed_at  TIMESTAMP WITH TIME ZONE,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,

    -- Enforce valid status
    CONSTRAINT chk_action_item_status 
        CHECK (status IN ('open', 'in_progress', 'blocked', 'review', 'completed')),

    -- Ensure completed_at >= due_date (if completed)
    CONSTRAINT chk_completed_after_due 
        CHECK (completed_at IS NULL OR completed_at >= due_date::TIMESTAMP WITH TIME ZONE),

    -- Ensure due_date is not in the distant past (optional)
    CONSTRAINT chk_due_date_reasonable 
        CHECK (due_date >= '2000-01-01'::DATE),

    -- Foreign Keys
    CONSTRAINT fk_action_item_post_mortem_id 
        FOREIGN KEY (post_mortem_id) 
        REFERENCES btrace_core.incident_post_mortems (post_mortem_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_action_item_owner_id 
        FOREIGN KEY (owner_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE
);

-- Fast: "Show all action items for this post-mortem"
CREATE INDEX idx_incident_action_items_post_mortem 
ON btrace_core.incident_action_items (post_mortem_id);

-- Filter by owner (e.g., "show my tasks")
CREATE INDEX idx_incident_action_items_owner 
ON btrace_core.incident_action_items (owner_id);

-- Find overdue items (critical for SRE hygiene)
-- Recommended: Create a sargable, reliable index
CREATE INDEX idx_incident_action_items_overdue 
ON btrace_core.incident_action_items (status, due_date)
WHERE status != 'completed';

-- Filter by status (e.g., only open/in_progress)
CREATE INDEX idx_incident_action_items_status 
ON btrace_core.incident_action_items (status)
WHERE status NOT IN ('completed', 'review');

-- Covering index for action item dashboard
CREATE INDEX idx_incident_action_items_covering 
ON btrace_core.incident_action_items (status, due_date)
INCLUDE (description, owner_id, post_mortem_id, created_at, completed_at);

--show items overdue 
SELECT *
FROM btrace_core.incident_action_items
WHERE status != 'completed'
  AND due_date < CURRENT_DATE;

--show all open items 
SELECT 
    item_id,
    description,
    owner_id,
    due_date,
    status,
    created_at,
    updated_at,
    post_mortem_id
FROM btrace_core.incident_action_items
WHERE status = 'open'
ORDER BY created_at DESC;

SELECT 
    a.item_id,
    a.description,
    u.username AS owner,
    a.due_date,
    a.status,
    a.created_at,
    a.updated_at,
    a.post_mortem_id
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
WHERE a.status = 'open'
ORDER BY a.due_date ASC, a.created_at DESC;


SELECT 
    a.item_id,
    a.description,
    u.username AS owner,
    a.due_date,
    a.status,
    p.title AS post_mortem_title,
    a.created_at
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
JOIN btrace_core.incident_post_mortems p ON a.post_mortem_id = p.post_mortem_id
WHERE a.status = 'open'
ORDER BY a.due_date ASC, a.created_at DESC;

-- show actionitems due soon 

SELECT 
    item_id,
    description,
    owner_id,
    due_date,
    status,
    created_at,
    updated_at,
    post_mortem_id
FROM btrace_core.incident_action_items
WHERE 
    status != 'completed'  -- Exclude completed items
    AND due_date >= CURRENT_DATE
    AND due_date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY due_date ASC, created_at DESC;

SELECT 
    a.item_id,
    a.description,
    u.username AS owner,
    a.due_date,
    a.status,
    a.post_mortem_id
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
WHERE 
    a.status != 'completed'
    AND a.due_date >= CURRENT_DATE
    AND a.due_date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY a.due_date ASC, a.created_at DESC;

--inlcude post-mortem title 
SELECT 
    a.item_id,
    a.description,
    u.username AS owner,
    a.due_date,
    a.status,
    p.title AS post_mortem_title
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
JOIN btrace_core.incident_post_mortems p ON a.post_mortem_id = p.post_mortem_id
WHERE 
    a.status != 'completed'
    AND a.due_date >= CURRENT_DATE
    AND a.due_date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY a.due_date ASC;
--show all items due soon

--view showing all action items with status - open or status in progress joined with owner details and post-mortem context 
CREATE OR REPLACE VIEW btrace_core.open_action_items AS
SELECT 
    a.item_id,
    a.description,
    a.status,
    a.due_date,
    a.created_at,
    a.updated_at,
    u.user_id AS owner_id,
    u.username AS owner_username,
    u.email AS owner_email,
    p.post_mortem_id,
    p.title AS post_mortem_title,
    i.title AS incident_title,
    i.severity AS incident_severity,
    i.start_time AS incident_start_time
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
JOIN btrace_core.incident_post_mortems p ON a.post_mortem_id = p.post_mortem_id
JOIN btrace_core.incidents i ON p.incident_id = i.incident_id
WHERE a.status IN ('open', 'in_progress');


-- view showing non-completed action items due in the next 7 days for proactive reminders 
CREATE OR REPLACE VIEW btrace_core.upcoming_action_items AS
SELECT 
    a.item_id,
    a.description,
    a.status,
    a.due_date,
    a.created_at,
    a.updated_at,
    u.user_id AS owner_id,
    u.username AS owner_username,
    u.email AS owner_email,
    p.post_mortem_id,
    p.title AS post_mortem_title,
    i.title AS incident_title,
    i.severity AS incident_severity,
    i.start_time AS incident_start_time,
    (a.due_date - CURRENT_DATE) AS days_until_due
FROM btrace_core.incident_action_items a
JOIN btrace_rbac.users u ON a.owner_id = u.user_id
JOIN btrace_core.incident_post_mortems p ON a.post_mortem_id = p.post_mortem_id
JOIN btrace_core.incidents i ON p.incident_id = i.incident_id
WHERE 
    a.status NOT IN ('completed', 'review')  -- Exclude completed and under-review
    AND a.due_date >= CURRENT_DATE
    AND a.due_date <= CURRENT_DATE + INTERVAL '7 days'  -- Due within a week
ORDER BY a.due_date ASC, a.created_at DESC;

-- Materialized version (refresh nightly)
CREATE MATERIALIZED VIEW btrace_core.mv_upcoming_action_items AS
SELECT * FROM btrace_core.upcoming_action_items;

-- Index for fast lookup by owner
CREATE INDEX idx_mv_upcoming_owner ON btrace_core.mv_upcoming_action_items (owner_id);
CREATE INDEX idx_mv_upcoming_due_date ON btrace_core.mv_upcoming_action_items (due_date);

SELECT owner_username, description, due_date, incident_title
FROM btrace_core.open_action_items
ORDER BY due_date ASC;

SELECT *
FROM btrace_core.upcoming_action_items
WHERE days_until_due <= 3;

SELECT 
    owner_username,
    COUNT(*) AS open_items
FROM btrace_core.open_action_items
GROUP BY owner_username
ORDER BY open_items DESC;

--
-- BUSINESS CASE:
-- The `oncall_schedules` table defines which users are on call for a team during specific time periods.
-- It enables automated incident assignment, escalation policies, and auditability of on-call rotations.
-- This is essential for SRE teams, NOC operations, and ensuring no incident goes unattended.
--
-- PURPOSE:
-- - Track on-call rotations (primary, secondary) for teams
-- - Support auto-assignment of incidents and alerts
-- - Enable escalation if no response
-- - Facilitate on-call compensation and workload analysis
-- - Integrate with calendar systems and notification tools
--

CREATE TABLE btrace_core.oncall_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id     UUID NOT NULL,
    user_id     UUID NOT NULL,
    start_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time    TIMESTAMP WITH TIME ZONE NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'primary',
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE,

    -- Enforce valid role
    CONSTRAINT chk_oncall_role 
        CHECK (role IN ('primary', 'secondary', 'manager', 'observer')),

    -- Ensure end_time > start_time
    CONSTRAINT chk_valid_duration 
        CHECK (end_time > start_time),

    -- Prevent overlapping shifts for the same user/team/role (complex, use application logic or exclusion constraint)
    -- Note: Full overlap prevention requires an exclusion constraint with &&, which needs btree_gist

    -- Foreign Keys
    CONSTRAINT fk_oncall_team_id 
        FOREIGN KEY (team_id) 
        REFERENCES btrace_rbac.teams (team_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_oncall_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE CASCADE
);

-- Fast: "Who is on call right now for this team?"
-- Index by team and time range (supports overlap queries)
CREATE INDEX idx_oncall_active_by_team 
ON btrace_core.oncall_schedules (team_id, start_time, end_time);

-- Fast: "When is this user on call?"
-- Index by user and time for chronological lookup
CREATE INDEX idx_oncall_by_user 
ON btrace_core.oncall_schedules (user_id, start_time DESC);

-- Find upcoming shifts
CREATE INDEX idx_oncall_start_time 
ON btrace_core.oncall_schedules (start_time DESC);

-- Find current on-call by role (e.g., primary vs secondary)
-- Remove WHERE, but keep role + time in index
CREATE INDEX idx_oncall_role_time 
ON btrace_core.oncall_schedules (role, start_time, end_time);

SELECT 
    t.team_name,
    u.username,
    s.role,
    s.start_time,
    s.end_time
FROM btrace_core.oncall_schedules s
JOIN btrace_rbac.teams t ON s.team_id = t.team_id
JOIN btrace_rbac.users u ON s.user_id = u.user_id
WHERE 
    s.start_time <= NOW()
    AND s.end_time > NOW()
ORDER BY t.team_name, s.role;


-- Add a time range column
ALTER TABLE btrace_core.oncall_schedules 
ADD COLUMN active_period tstzrange GENERATED ALWAYS AS (tstzrange(start_time, end_time, '[)')) STORED;

-- Index it
CREATE INDEX idx_oncall_active_period 
ON btrace_core.oncall_schedules USING GIST (active_period);

-- Query: Who is on call now?
SELECT 
    t.team_name,
    u.username,
    s.role
FROM btrace_core.oncall_schedules s
JOIN btrace_rbac.teams t ON s.team_id = t.team_id
JOIN btrace_rbac.users u ON s.user_id = u.user_id
WHERE s.active_period @> NOW();

-- Covering index for on-call dashboard
-- Remove WHERE, but include all needed columns
CREATE INDEX idx_oncall_covering 
ON btrace_core.oncall_schedules (team_id, start_time, end_time)
INCLUDE (user_id, role, created_at);
  


--extensibility and ecosystems, links to docs, runbooks, jira and confluence 
--
-- BUSINESS CASE:
-- The `external_links` table stores references from internal platform entities (incidents, services, alert rules)
-- to external documentation and tracking systems (e.g., runbooks, Jira, Confluence).
-- It enables seamless navigation between observability data and operational context, improving response efficiency and knowledge sharing.
-- This is essential for SRE teams, incident commanders, and onboarding.
--
-- PURPOSE:
-- - Connect telemetry and incidents to supporting documentation
-- - Reduce context switching during incident response
-- - Support audit and compliance by preserving references
-- - Facilitate knowledge transfer and reduce tribal knowledge
-- - Integrate with service catalogs, post-mortems, and alerting
--

CREATE TABLE btrace_core.external_links (
    link_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type   VARCHAR(20) NOT NULL,
    entity_id     UUID NOT NULL,
    link_type     VARCHAR(20) NOT NULL,
    url           TEXT NOT NULL,
    description   TEXT,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,

    -- Enforce valid entity types
    CONSTRAINT chk_external_link_entity_type 
        CHECK (entity_type IN ('incident', 'service', 'alert_rule', 'post_mortem', 'slo', 'trace', 'metric')),

    -- Enforce valid link types
    CONSTRAINT chk_external_link_link_type 
        CHECK (link_type IN ('runbook', 'jira', 'confluence', 'status_page', 'design_doc', 'video', 'slack', 'email', 'dashboard')),

    -- Foreign Key
    CONSTRAINT fk_external_links_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show all links for this entity"
CREATE INDEX idx_external_links_entity 
ON btrace_core.external_links (entity_type, entity_id);

-- Filter by link type (e.g., all runbooks)
CREATE INDEX idx_external_links_type 
ON btrace_core.external_links (link_type);

-- Who created the links?
CREATE INDEX idx_external_links_created_by 
ON btrace_core.external_links (created_by) 
WHERE created_by IS NOT NULL;

-- Covering index for detail page sidebar
CREATE INDEX idx_external_links_covering 
ON btrace_core.external_links (entity_type, entity_id)
INCLUDE (link_type, url, description, created_at, created_by);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_external_links_updated_at
    BEFORE UPDATE ON btrace_core.external_links
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
COMMENT ON TABLE btrace_core.external_links IS 
'Links internal platform entities (e.g., incidents, services) to external resources (runbooks, Jira, Confluence). Enables contextual navigation and reduces incident response time. Critical for knowledge management and onboarding.';

COMMENT ON COLUMN btrace_core.external_links.link_id IS 
'Unique identifier for the link. Used in APIs and UIs.';

COMMENT ON COLUMN btrace_core.external_links.entity_type IS 
'Type of internal entity being linked: incident, service, alert_rule, etc. Enables polymorphic association.';

COMMENT ON COLUMN btrace_core.external_links.entity_id IS 
'ID of the internal entity (e.g., incident_id, service_id). Used with entity_type to resolve the target.';

COMMENT ON COLUMN btrace_core.external_links.link_type IS 
'Purpose of the link: runbook, jira, confluence, dashboard, etc. Drives icon and grouping in UI.';

COMMENT ON COLUMN btrace_core.external_links.url IS 
'Full URL to the external resource. Must be valid and accessible to authorized users.';

COMMENT ON COLUMN btrace_core.external_links.description IS 
'Optional: summary of what the link contains (e.g., "Post-mortem for P1 outage"). Helps users decide whether to click.';

COMMENT ON COLUMN btrace_core.external_links.created_at IS 
'When the link was added to the system.';

COMMENT ON COLUMN btrace_core.external_links.updated_at IS 
'Automatically updated if the URL or description is edited. Used for audit trail.';

COMMENT ON COLUMN btrace_core.external_links.created_by IS 
'Optional: user who added the link. NULL if auto-imported or seeded.';


--get all links for an incident 
SELECT link_type, url, description, u.username AS created_by
FROM btrace_core.external_links l
LEFT JOIN btrace_rbac.users u ON l.created_by = u.user_id
WHERE l.entity_type = 'incident'
  AND l.entity_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY l.link_type;

--show all runbooks
SELECT entity_type, entity_id, url, description
FROM btrace_core.external_links
WHERE link_type = 'runbook';

--generate post-mortem resource list
SELECT 
    el.link_type, 
    el.url
FROM btrace_core.external_links el
JOIN btrace_core.incident_post_mortems p ON el.entity_id = p.post_mortem_id
WHERE el.entity_type = 'post_mortem'
  AND p.title = 'P1 Payment Service Outage - Post-Mortem';
  
  
SELECT 
    el.link_type, 
    el.url
FROM btrace_core.external_links el
JOIN btrace_core.incident_post_mortems p ON el.entity_id = p.post_mortem_id
JOIN btrace_core.incidents i ON p.incident_id = i.incident_id
WHERE el.entity_type = 'post_mortem'
  AND i.title = 'Payment Service Degradation';
  
  
SELECT post_mortem_id, title
FROM btrace_core.incident_post_mortems
WHERE title ILIKE '%payment%' OR title ILIKE '%P1%';

-- Step 1: Find the post-mortem
SELECT post_mortem_id, title FROM btrace_core.incident_post_mortems;

-- Step 2: Use real UUID
SELECT link_type, url
FROM btrace_core.external_links
WHERE entity_type = 'post_mortem'
  AND entity_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678';  -- Real UUID
-------- done until here 
-- for high cardinality debugging
-- to show me 10 traces that triggered this alert 
--
-- BUSINESS CASE:
-- The `trace_samples` table captures references to distributed traces that matched specific alerting or sampling rules
-- (e.g., "high latency", "error burst"). It enables engineers to quickly access exemplar traces for debugging,
-- performance analysis, and validating alert conditions. This is essential for reducing MTTR and improving signal quality.
--
-- PURPOSE:
-- - Preserve traces that triggered alerts or met sampling criteria
-- - Support "top N slow traces" dashboards
-- - Enable post-incident root cause analysis with real data
-- - Facilitate alert validation ("Did this alert fire on real issues?")
-- - Integrate with alerting and profiling workflows
--

CREATE TABLE btrace_core.trace_samples (
    sample_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id     UUID,  -- Optional: if triggered by an alert rule
    trace_id    UUID NOT NULL,
    start_time  TIMESTAMP WITH TIME ZONE NOT NULL,  -- Required to reference partitioned `traces` table
    matched_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sample_type VARCHAR(20) NOT NULL DEFAULT 'alert_trigger',  -- 'latency_outlier', 'error', 'manual', 'profiling'
    metadata    JSONB,  -- Additional context (e.g., P99 value, error rate)
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE,

    -- Enforce valid sample type
    CONSTRAINT chk_trace_sample_type 
        CHECK (sample_type IN ('alert_trigger', 'latency_outlier', 'error', 'manual', 'profiling', 'anomaly')),

    -- Foreign Keys
    CONSTRAINT fk_trace_samples_rule_id 
        FOREIGN KEY (rule_id) 
        REFERENCES btrace_core.alert_rules (rule_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_trace_samples_trace_id 
        FOREIGN KEY (trace_id, start_time) 
        REFERENCES btrace_core.traces (trace_id, start_time) 
        ON DELETE CASCADE
);


-- Fast: "Show all samples for this rule"
CREATE INDEX idx_trace_samples_rule_id 
ON btrace_core.trace_samples (rule_id, matched_at DESC);

-- Fast: "Find recent high-value traces"
CREATE INDEX idx_trace_samples_matched_at 
ON btrace_core.trace_samples (matched_at DESC);

-- Fast: "Get the trace details" (supports JOIN with traces)
CREATE INDEX idx_trace_samples_trace_id_start_time 
ON btrace_core.trace_samples (trace_id, start_time);

-- Filter by type (e.g., only latency outliers)
CREATE INDEX idx_trace_samples_type 
ON btrace_core.trace_samples (sample_type);

-- Covering index for sampling dashboard
CREATE INDEX idx_trace_samples_covering 
ON btrace_core.trace_samples (matched_at DESC, sample_type)
INCLUDE (trace_id, rule_id, metadata);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_trace_samples_updated_at
    BEFORE UPDATE ON btrace_core.trace_samples
    FOR EACH ROW
    EXECUTE FUNCTION btrace_core.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_core.trace_samples IS 
'Records references to high-value traces that matched alert rules, latency thresholds, or manual sampling criteria. Used for debugging, alert validation, and performance analysis. Preserves context even after trace retention expires.';

COMMENT ON COLUMN btrace_core.trace_samples.sample_id IS 
'Unique identifier for the sample record. Used in APIs and UIs.';

COMMENT ON COLUMN btrace_core.trace_samples.rule_id IS 
'Optional: references the alert rule that triggered this sample (e.g., "high_latency_api_checkout"). NULL if manually sampled.';

COMMENT ON COLUMN btrace_core.trace_samples.trace_id IS 
'References the captured trace. Must be paired with start_time to resolve partition.';

COMMENT ON COLUMN btrace_core.trace_samples.start_time IS 
'The start_time of the referenced trace. Required due to partitioning on btrace_core.traces. Enables correct foreign key reference.';

COMMENT ON COLUMN btrace_core.trace_samples.matched_at IS 
'When the trace was identified as interesting (e.g., when the alert fired or outlier was detected).';

COMMENT ON COLUMN btrace_core.trace_samples.sample_type IS 
'Category of sampling event: alert_trigger, latency_outlier, error, manual, profiling. Helps filter and group in UIs.';

COMMENT ON COLUMN btrace_core.trace_samples.metadata IS 
'Additional context about why the trace was sampled (e.g., "latency=1.8s", "error_count=5"). Useful for analysis.';

COMMENT ON COLUMN btrace_core.trace_samples.created_at IS 
'When the sample record was created.';

COMMENT ON COLUMN btrace_core.trace_samples.updated_at IS 
'Automatically updated when the sample is modified. Used for audit trail.';

--show all traces smapled by a rule
SELECT s.matched_at, s.sample_type, t.trace_name, t.duration_ms
FROM btrace_core.trace_samples s
JOIN btrace_core.traces t ON s.trace_id = t.trace_id AND s.start_time = t.start_time
WHERE s.rule_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY s.matched_at DESC;


-- top 10 slowest sampled traces
SELECT t.trace_name, t.duration_ms, s.sample_type, s.matched_at
FROM btrace_core.trace_samples s
JOIN btrace_core.traces t ON s.trace_id = t.trace_id AND s.start_time = t.start_time
ORDER BY t.duration_ms DESC
LIMIT 10;


-- generate alert validation report 
SELECT 
    ar.rule_name,
    COUNT(*) AS trace_count,
    AVG(t.duration_ms) AS avg_duration,
    COUNT(*) FILTER (WHERE t.status_code = 'ERROR') AS error_count
FROM btrace_core.trace_samples s
JOIN btrace_core.alert_rules ar ON s.rule_id = ar.rule_id
JOIN btrace_core.traces t ON s.trace_id = t.trace_id AND s.start_time = t.start_time
WHERE s.matched_at > NOW() - INTERVAL '7 days'
GROUP BY ar.rule_name;

--
-- BUSINESS CASE:
-- The `spans` table stores individual operations (spans) within distributed traces, representing units of work 
-- performed by services (e.g., HTTP requests, DB calls, message processing). This data enables deep-dive 
-- latency analysis, error tracing, and service dependency mapping.
--
-- PURPOSE:
-- - Support high-cardinality, high-volume span ingestion from microservices
-- - Enable fast querying by trace_id, service, operation, or time range
-- - Facilitate root-cause analysis and performance debugging
-- - Integrate with observability tools (e.g., UIs, alerting, service maps)
-- - Allow efficient retention via time-based partitioning
--

CREATE TABLE btrace_core.spans (
    span_id          UUID NOT NULL,
    trace_id         UUID NOT NULL,
    parent_span_id   UUID,
    span_name        VARCHAR(255) NOT NULL,
    start_time       TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time         TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_ms      BIGINT NOT NULL CHECK (duration_ms >= 0),
    service_id       UUID NOT NULL,
    service_name     VARCHAR(100) NOT NULL,
    operation_name   VARCHAR(255) NOT NULL,
    kind             VARCHAR(20) NOT NULL 
        CHECK (kind IN ('INTERNAL', 'SERVER', 'CLIENT', 'PRODUCER', 'CONSUMER')),
    status_code      VARCHAR(20) NOT NULL 
        CHECK (status_code IN ('OK', 'ERROR', 'UNAVAILABLE', 'DEADLINE_EXCEEDED', 'CANCELLED', 'UNKNOWN')),
    status_message   TEXT,
    attributes       JSONB,
    events           JSONB,
    links            JSONB,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_spans 
        PRIMARY KEY (trace_id, span_id, start_time),

    -- Foreign keys
    CONSTRAINT fk_spans_trace_id 
        FOREIGN KEY (trace_id, start_time) 
        REFERENCES btrace_core.traces (trace_id, start_time) 
        ON DELETE CASCADE,

    CONSTRAINT fk_spans_service_id 
        FOREIGN KEY (service_id) 
        REFERENCES btrace_core.services (service_id) 
        ON DELETE CASCADE,

    -- Time integrity
    CONSTRAINT valid_time_range 
        CHECK (end_time >= start_time)
)
PARTITION BY RANGE (start_time);

-- Index for retrieving all spans of a trace (common lookup)
CREATE INDEX idx_spans_trace_id_start_time 
ON btrace_core.spans (trace_id, start_time DESC);

-- Index for filtering by service and time
CREATE INDEX idx_spans_service_name_start_time 
ON btrace_core.spans (service_name, start_time DESC);

-- Index for operation-level analysis
CREATE INDEX idx_spans_operation_name 
ON btrace_core.spans (operation_name, start_time DESC);

-- Index for status-based error analysis
CREATE INDEX idx_spans_status_code 
ON btrace_core.spans (status_code, start_time DESC) 
WHERE status_code != 'OK';

-- GIN indexes for JSONB filtering
CREATE INDEX idx_spans_attributes_gin 
ON btrace_core.spans USING GIN (attributes) 
WHERE attributes IS NOT NULL;

CREATE INDEX idx_spans_events_gin 
ON btrace_core.spans USING GIN (events) 
WHERE events IS NOT NULL;

-- Optional: for distributed tracing context propagation
CREATE INDEX idx_spans_parent_span_id 
ON btrace_core.spans (parent_span_id) 
WHERE parent_span_id IS NOT NULL;


COMMENT ON TABLE btrace_core.spans IS 
'Individual spans representing operations within distributed traces. Each span corresponds to a unit of work (e.g., an RPC, DB query). Partitioned by start_time for scalability and retention.';

COMMENT ON COLUMN btrace_core.spans.span_id IS 
'Unique identifier for this span within the trace (OpenTelemetry-compliant).';

COMMENT ON COLUMN btrace_core.spans.trace_id IS 
'References the parent trace. Combined with start_time in FK due to partitioning.';

COMMENT ON COLUMN btrace_core.spans.parent_span_id IS 
'Optional: span_id of the parent span in the trace tree. NULL for root spans.';

COMMENT ON COLUMN btrace_core.spans.span_name IS 
'User-defined name of the span (e.g., "GET /api/users"). Should be low cardinality.';

COMMENT ON COLUMN btrace_core.spans.operation_name IS 
'Logical operation or method name (e.g., "UserService.GetUser"). May be same as span_name or more specific.';

COMMENT ON COLUMN btrace_core.spans.kind IS 
'Role of the span in a workflow. Values: INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER. Aligns with OpenTelemetry semantic conventions.';

COMMENT ON COLUMN btrace_core.spans.service_name IS 
'Name of the service that generated this span (e.g., "user-service"). Useful for filtering and service maps.';

COMMENT ON COLUMN btrace_core.spans.duration_ms IS 
'Duration of the span in milliseconds. Precomputed for fast latency analysis.';

COMMENT ON COLUMN btrace_core.spans.status_code IS 
'Final status of the span (OK, ERROR, etc.). Used for error rate calculations.';

COMMENT ON COLUMN btrace_core.spans.attributes IS 
'Key-value metadata about the span (e.g., http.method, db.statement). Stored as JSONB for flexible querying.';

COMMENT ON COLUMN btrace_core.spans.events IS 
'Timestamped events within the span (e.g., "retry", "timeout"). Limited to ~10-50 per span.';

COMMENT ON COLUMN btrace_core.spans.links IS 
'Links to other spans (potentially in different traces), used for causal relationships (e.g., queue messaging).';

--
-- BUSINESS CASE:
-- The `create_monthly_partitions` function automates the creation of time-based partitions
-- for large tables (e.g., traces, logs, metrics). It prevents ingestion failures due to missing partitions
-- and reduces operational overhead. This is essential for scalable, self-managing observability systems.
--
-- PURPOSE:
-- - Prevent "no partition for value" errors during data ingestion
-- - Automate schema maintenance for time-partitioned tables
-- - Support long retention policies and high-volume ingestion
-- - Integrate with cron or startup scripts for zero-touch operations
--

CREATE OR REPLACE FUNCTION btrace_core.create_monthly_partitions(
    start_table REGCLASS,
    months_ahead INT DEFAULT 6
)
RETURNS void AS $$
DECLARE
    part_name TEXT;
    part_start DATE;
    part_end DATE;
    query TEXT;
    schema_name TEXT;
    table_name TEXT;
BEGIN
    -- Extract schema and table name
    schema_name := SPLIT_PART(start_table::TEXT, '.', 1);
    table_name := SPLIT_PART(start_table::TEXT, '.', 2);

    -- Loop over the next N months
    FOR i IN 0..months_ahead LOOP
        part_start := DATE_TRUNC('month', CURRENT_DATE + (i || ' months')::INTERVAL);
        part_end := part_start + INTERVAL '1 month';

        -- Format partition name: {table}_YYYY_MM
        part_name := table_name || '_' || TO_CHAR(part_start, 'YYYY_MM');

        -- Build and execute CREATE TABLE ... PARTITION OF
        query := FORMAT(
            'CREATE TABLE IF NOT EXISTS %I.%I PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
            schema_name, part_name,
            start_table,
            part_start, part_end
        );

        EXECUTE query;

        -- Optional: RAISE NOTICE 'Created partition: %', part_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = btrace_core, pg_temp;


-- SELECT btrace_core.create_monthly_partitions('btrace_core.traces', 12);
-- SELECT btrace_core.create_monthly_partitions('btrace_core.spans', 12);
-- SELECT btrace_core.create_monthly_partitions('btrace_core.logs', 12);
-- SELECT btrace_core.create_monthly_partitions('btrace_core.metrics', 12);

-- =============================================
-- SECTION 7: ANALYTICS AND REPORTING
-- =============================================
--
-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS btrace_analytics;
-- BUSINESS CASE:
-- The `dashboards` table stores user-defined collections of visualizations (charts, tables, traces, logs) 
-- for monitoring, debugging, and reporting. It enables self-service analytics and knowledge sharing across teams.
-- This is essential for SREs, developers, and product teams to gain insights from telemetry data.
--
-- PURPOSE:
-- - Centralize dashboard definitions for discoverability and reuse
-- - Support layout customization and personalization
-- - Enable sharing and collaboration
-- - Track ownership and modification history
-- - Integrate with UIs, embeddable views, and scheduled reports
--

CREATE TABLE btrace_analytics.dashboards (
    dashboard_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_name VARCHAR(100) NOT NULL,
    description    TEXT,
    is_shared      BOOLEAN NOT NULL DEFAULT FALSE,
    layout_config  JSONB,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,
    created_by     UUID,
    updated_by     UUID,

    -- Enforce unique dashboard name (case-insensitive)
    CONSTRAINT uq_dashboard_name 
        UNIQUE (dashboard_name),

    -- Validate layout_config is a valid JSON object (not array or scalar)
    CONSTRAINT chk_layout_config_type 
        CHECK (jsonb_typeof(layout_config) = 'object' OR layout_config IS NULL),

    -- Foreign Keys
    CONSTRAINT fk_dashboards_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_dashboards_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Find dashboards by name"
CREATE INDEX idx_dashboards_name ON btrace_analytics.dashboards (dashboard_name);

-- Filter by shared status (e.g., "show all public dashboards")
CREATE INDEX idx_dashboards_is_shared ON btrace_analytics.dashboards (is_shared);

-- Find dashboards by creator
CREATE INDEX idx_dashboards_created_by ON btrace_analytics.dashboards (created_by) WHERE created_by IS NOT NULL;

-- Covering index for dashboard listing UI
CREATE INDEX idx_dashboards_covering 
ON btrace_analytics.dashboards (dashboard_name)
INCLUDE (description, is_shared, created_at, updated_at, created_by);



-- Reuse or create the updated_at function in btrace_analytics
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_dashboards_updated_at
    BEFORE UPDATE ON btrace_analytics.dashboards
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_analytics.dashboards IS 
'User-defined collections of visualizations (charts, traces, logs) for monitoring, debugging, and reporting. Enables self-service analytics and knowledge sharing. Stored as JSON configuration for flexibility and portability.';

COMMENT ON COLUMN btrace_analytics.dashboards.dashboard_id IS 
'Globally unique identifier for the dashboard. Used in APIs, sharing links, and references.';

COMMENT ON COLUMN btrace_analytics.dashboards.dashboard_name IS 
'Human-readable name (e.g., "Payment Service Health"). Must be unique. Used in search and navigation.';

COMMENT ON COLUMN btrace_analytics.dashboards.description IS 
'Short summary of the dashboard''s purpose, scope, and key metrics. Helps users decide if it''s relevant.';

COMMENT ON COLUMN btrace_analytics.dashboards.is_shared IS 
'Indicates whether the dashboard is visible to other users. If FALSE, only the owner can access it.';

COMMENT ON COLUMN btrace_analytics.dashboards.layout_config IS 
'JSON structure defining the arrangement, size, and configuration of panels (visualizations). Includes query definitions, chart types, and filters.';

COMMENT ON COLUMN btrace_analytics.dashboards.created_at IS 
'When the dashboard was created.';

COMMENT ON COLUMN btrace_analytics.dashboards.updated_at IS 
'Automatically updated when the dashboard is modified. Used for freshness indication and audit trail.';

COMMENT ON COLUMN btrace_analytics.dashboards.created_by IS 
'Optional: user who created the dashboard. NULL if seeded or imported.';

COMMENT ON COLUMN btrace_analytics.dashboards.updated_by IS 
'Optional: last user to edit the dashboard. NULL if untracked.';




-- Dashboard Widgets: Individual visualizations on dashboards
--
-- BUSINESS CASE:
-- The `dashboard_widgets` table defines individual visualizations (widgets) within a dashboard,
-- such as line charts, tables, trace viewers, or metric summaries. It enables flexible, customizable dashboards
-- tailored to specific teams, services, or use cases. This is essential for self-service observability and SRE workflows.
--
-- PURPOSE:
-- - Store configuration of each widget (type, query, layout)
-- - Support drag-and-drop dashboard editing
-- - Enable reuse of common visualizations
-- - Facilitate collaboration and sharing
-- - Integrate with UIs, embeddable views, and scheduled reports
--

CREATE TABLE btrace_analytics.dashboard_widgets (
    widget_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id  UUID NOT NULL,
    widget_name   VARCHAR(100) NOT NULL,
    widget_type   VARCHAR(50) NOT NULL,
    widget_config JSONB NOT NULL,
    position      INTEGER NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,
    updated_by    UUID,

    -- Enforce valid widget types
    CONSTRAINT chk_widget_type 
        CHECK (widget_type IN (
            'line_chart', 'bar_chart', 'gauge', 'table', 'trace_view', 'log_view',
            'metric_summary', 'alert_list', 'markdown', 'text', 'heatmap', 'map'
        )),

    -- Prevent invalid position
    CONSTRAINT chk_position_non_negative 
        CHECK (position >= 0),

    -- Foreign Keys
    CONSTRAINT fk_widget_dashboard_id 
        FOREIGN KEY (dashboard_id) 
        REFERENCES btrace_analytics.dashboards (dashboard_id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_widget_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_widget_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);


-- Fast: "Show all widgets for this dashboard"
CREATE INDEX idx_dashboard_widgets_dashboard 
ON btrace_analytics.dashboard_widgets (dashboard_id, position);

-- Filter by widget type (e.g., all charts)
CREATE INDEX idx_dashboard_widgets_type 
ON btrace_analytics.dashboard_widgets (widget_type);

-- Who created/updated widgets?
CREATE INDEX idx_dashboard_widgets_created_by 
ON btrace_analytics.dashboard_widgets (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_dashboard_widgets_updated_by 
ON btrace_analytics.dashboard_widgets (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for dashboard rendering
CREATE INDEX idx_dashboard_widgets_covering 
ON btrace_analytics.dashboard_widgets (dashboard_id, position)
INCLUDE (widget_name, widget_type, widget_config, created_at);

-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_dashboard_widgets_updated_at
    BEFORE UPDATE ON btrace_analytics.dashboard_widgets
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.dashboard_widgets IS 
'Individual visualizations (widgets) that make up a dashboard. Each widget has a type (e.g., line_chart), configuration, and position. Enables flexible, user-defined observability views.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.widget_id IS 
'Unique identifier for the widget. Used in APIs, layout references, and state management.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.dashboard_id IS 
'References the parent dashboard. Cascades delete if dashboard is removed.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.widget_name IS 
'User-defined label for the widget (e.g., "API Latency (P99)"). Used in UI tabs and navigation.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.widget_type IS 
'Visualization type: line_chart, bar_chart, table, trace_view, etc. Determines rendering and configuration schema.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.widget_config IS 
'JSON structure defining the data source, query, filters, time range, and display options for the widget. Flexible to support multiple visualization types.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.position IS 
'Order of the widget within the dashboard layout (e.g., for vertical stacking). Used to preserve user-defined arrangement.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.created_at IS 
'When the widget was added to the dashboard.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.updated_at IS 
'Automatically updated when the widget configuration is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.created_by IS 
'Optional: user who added the widget. NULL if auto-generated or seeded.';

COMMENT ON COLUMN btrace_analytics.dashboard_widgets.updated_by IS 
'Optional: last user to edit the widget. NULL if untracked.';



-- display all widget for a dashboard 
SELECT widget_name, widget_type, position, widget_config
FROM btrace_analytics.dashboard_widgets
WHERE dashboard_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY position;

--Show all line charts 
SELECT widget_name, dashboard_id
FROM btrace_analytics.dashboard_widgets
WHERE widget_type = 'line_chart';


--- find widgets using a specific metric 
SELECT w.widget_name, d.dashboard_name
FROM btrace_analytics.dashboard_widgets w
JOIN btrace_analytics.dashboards d ON w.dashboard_id = d.dashboard_id
WHERE w.widget_config @> '{"metric": "http.request.duration"}';

-- Saved Queries: Frequently used queries for analysis
--
-- BUSINESS CASE:
-- The `saved_queries` table stores reusable SQL or domain-specific language (DSL) queries used for observability analysis.
-- It enables knowledge sharing, reduces repetitive work, and standardizes debugging patterns across teams.
-- This is essential for onboarding, SRE playbooks, and reducing MTTR.
--
-- PURPOSE:
-- - Preserve high-value queries for reuse (e.g., "P99 latency by region")
-- - Support sharing and collaboration across teams
-- - Enable integration with UIs (query library, autocomplete)
-- - Track ownership and modification history
-- - Facilitate audit and governance of analysis patterns
--

CREATE TABLE btrace_analytics.saved_queries (
    query_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_name    VARCHAR(100) NOT NULL,
    description   TEXT,
    query_text    TEXT NOT NULL,
    query_type    VARCHAR(50) NOT NULL,
    parameters    JSONB,
    is_shared     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE,
    created_by    UUID,
    updated_by    UUID,

    -- Enforce unique query name (case-insensitive)
    CONSTRAINT uq_query_name 
        UNIQUE (query_name),

    -- Validate query_type
    CONSTRAINT chk_saved_query_type 
        CHECK (query_type IN ('trace', 'span', 'log', 'metric', 'alert', 'dashboard', 'custom')),

    -- Ensure parameters is a JSON object (if present)
    CONSTRAINT chk_parameters_type 
        CHECK (jsonb_typeof(parameters) = 'object' OR parameters IS NULL),

    -- Foreign Keys
    CONSTRAINT fk_saved_queries_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_saved_queries_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Find queries by name"
CREATE INDEX idx_saved_queries_name ON btrace_analytics.saved_queries (query_name);

-- Filter by query type (e.g., all trace queries)
CREATE INDEX idx_saved_queries_type ON btrace_analytics.saved_queries (query_type);

-- Filter by shared status (e.g., show all public queries)
CREATE INDEX idx_saved_queries_is_shared ON btrace_analytics.saved_queries (is_shared);

-- Find queries by creator
CREATE INDEX idx_saved_queries_created_by ON btrace_analytics.saved_queries (created_by) WHERE created_by IS NOT NULL;

-- Covering index for query explorer UI
CREATE INDEX idx_saved_queries_covering 
ON btrace_analytics.saved_queries (query_name)
INCLUDE (query_type, is_shared, description, created_at, updated_at, created_by);


-- Reuse or create the updated_at function (if not already exists)
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_saved_queries_updated_at
    BEFORE UPDATE ON btrace_analytics.saved_queries
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.saved_queries IS 
'Stores frequently used queries for observability analysis (e.g., trace, log, metric). Enables reuse, sharing, and standardization of debugging patterns. Critical for onboarding and SRE efficiency.';

COMMENT ON COLUMN btrace_analytics.saved_queries.query_id IS 
'Unique identifier for the saved query. Used in APIs, sharing links, and references.';

COMMENT ON COLUMN btrace_analytics.saved_queries.query_name IS 
'Human-readable name (e.g., "High Latency Traces - Payment Service"). Must be unique. Used in search and navigation.';

COMMENT ON COLUMN btrace_analytics.saved_queries.description IS 
'Short summary of what the query does, when to use it, and expected output. Helps users understand its purpose.';

COMMENT ON COLUMN btrace_analytics.saved_queries.query_text IS 
'The actual query text (e.g., SQL, PromQL, OTel DSL). Stored verbatim for execution or rendering in UIs.';

COMMENT ON COLUMN btrace_analytics.saved_queries.query_type IS 
'Category of data the query targets: trace, span, log, metric, alert, dashboard, or custom. Drives icon and grouping in UI.';

COMMENT ON COLUMN btrace_analytics.saved_queries.parameters IS 
'Optional: JSON structure defining input parameters (e.g., time_range, service_name). Enables dynamic query templates.';

COMMENT ON COLUMN btrace_analytics.saved_queries.is_shared IS 
'Indicates whether the query is visible to other users. If FALSE, only the owner can access it.';

COMMENT ON COLUMN btrace_analytics.saved_queries.created_at IS 
'When the query was saved.';

COMMENT ON COLUMN btrace_analytics.saved_queries.updated_at IS 
'Automatically updated when the query is modified. Used for freshness indication and audit trail.';

COMMENT ON COLUMN btrace_analytics.saved_queries.created_by IS 
'Optional: user who saved the query. NULL if seeded or imported.';

COMMENT ON COLUMN btrace_analytics.saved_queries.updated_by IS 
'Optional: last user to edit the query. NULL if untracked.';


-- insert queries 

INSERT INTO btrace_analytics.saved_queries (
    query_name,
    description,
    query_text,
    query_type,
    parameters,
    is_shared,
    created_by
)
VALUES

-- ===== TRACE QUERIES =====
('High Latency Traces (P99) - Last 1 Hour', 'Find traces in the top 1% of latency', 
 'SELECT trace_id, trace_name, duration_ms, root_service, environment_id 
  FROM btrace_core.traces 
  WHERE start_time >= NOW() - INTERVAL ''1 hour'' 
    AND duration_ms > (SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms) FROM btrace_core.traces WHERE start_time >= NOW() - INTERVAL ''1 hour'')
    AND is_sampled = TRUE 
  ORDER BY duration_ms DESC 
  LIMIT 100', 
 'trace', 
 '{"time_range": "1h", "percentile": 99}', 
 TRUE, NULL),

('Error Traces - Last 6 Hours', 'Show all traces with ERROR status', 
 'SELECT trace_id, trace_name, duration_ms, status_message, root_service 
  FROM btrace_core.traces 
  WHERE start_time >= NOW() - INTERVAL ''6 hours'' 
    AND status_code = ''ERROR'' 
  ORDER BY start_time DESC', 
 'trace', 
 '{"time_range": "6h"}', 
 TRUE, NULL),

('Traces by Root Service', 'Filter traces by top-level service', 
 'SELECT trace_id, duration_ms, status_code, start_time 
  FROM btrace_core.traces 
  WHERE root_service = {{service_name}} 
    AND start_time >= NOW() - INTERVAL ''{{hours}} hours'' 
  ORDER BY start_time DESC', 
 'trace', 
 '{"service_name": "payment-service", "hours": 24}', 
 TRUE, NULL),

('Traces with PII Tag', 'Find traces potentially containing PII for compliance', 
 'SELECT trace_id, trace_name, duration_ms 
  FROM btrace_core.traces 
  WHERE tags ? ''pii'' AND start_time >= NOW() - INTERVAL ''7 days''', 
 'trace', 
 '{"tag": "pii"}', 
 TRUE, NULL),

('Recent Sampled Traces - Production', 'Quick view of active production traffic', 
 'SELECT trace_id, trace_name, duration_ms, root_service 
  FROM btrace_core.traces 
  WHERE environment_id = (SELECT environment_id FROM btrace_core.environments WHERE environment_name = ''production'') 
    AND is_sampled = TRUE 
    AND start_time >= NOW() - INTERVAL ''30 minutes'' 
  ORDER BY start_time DESC 
  LIMIT 50', 
 'trace', 
 '{"env": "production", "limit": 50}', 
 TRUE, NULL),

-- ===== SPAN QUERIES =====
('Slow DB Spans > 500ms', 'Find database calls exceeding 500ms', 
 'SELECT span_name, service_name, duration_ms, attributes->>''db.statement'' as statement 
  FROM btrace_core.spans 
  WHERE operation_name ILIKE ''%database%'' 
    AND duration_ms > 500 
    AND start_time >= NOW() - INTERVAL ''1 hour'' 
  ORDER BY duration_ms DESC', 
 'span', 
 '{"threshold_ms": 500}', 
 TRUE, NULL),

('Error Spans - Last 24 Hours', 'All spans with ERROR status', 
 'SELECT span_name, service_name, status_message, duration_ms 
  FROM btrace_core.spans 
  WHERE status_code = ''ERROR'' 
    AND start_time >= NOW() - INTERVAL ''24 hours'' 
  ORDER BY start_time DESC', 
 'span', 
 '{"time_range": "24h"}', 
 TRUE, NULL),

('Spans by Service and Operation', 'Filter spans by service and method', 
 'SELECT span_id, duration_ms, attributes 
  FROM btrace_core.spans 
  WHERE service_name = {{service_name}} 
    AND operation_name = {{operation}} 
    AND start_time >= NOW() - INTERVAL ''{{hours}} hours''', 
 'span', 
 '{"service_name": "auth-service", "operation": "User.Login", "hours": 12}', 
 TRUE, NULL),

('HTTP 5xx Spans', 'Spans where HTTP status is 5xx', 
 'SELECT span_name, service_name, attributes->>''http.status_code'' as status 
  FROM btrace_core.spans 
  WHERE attributes @> ''{"http.status_code": "5"}'' 
    AND start_time >= NOW() - INTERVAL ''6 hours''', 
 'span', 
 '{"error_class": "5xx"}', 
 TRUE, NULL),

('Spans with Retry Events', 'Find spans that had retry logic triggered', 
 'SELECT span_name, service_name, events 
  FROM btrace_core.spans 
  WHERE events @> ''[{"name": "retry"}]'' 
    AND start_time >= NOW() - INTERVAL ''1 day''', 
 'span', 
 '{"event": "retry"}', 
 TRUE, NULL),

-- ===== LOG QUERIES =====
('ERROR Logs - Last 1 Hour', 'All ERROR-level logs in the past hour', 
 'SELECT timestamp, service_name, host_name, message 
  FROM btrace_core.logs 
  WHERE log_level IN (''ERROR'', ''FATAL'', ''CRITICAL'') 
    AND timestamp >= NOW() - INTERVAL ''1 hour'' 
  ORDER BY timestamp DESC', 
 'log', 
 '{"level": "ERROR", "time_range": "1h"}', 
 TRUE, NULL),

('Logs by Service', 'Filter logs by service name', 
 'SELECT timestamp, log_level, message 
  FROM btrace_core.logs 
  WHERE service_name = {{service_name}} 
    AND timestamp >= NOW() - INTERVAL ''{{hours}} hours'' 
  ORDER BY timestamp DESC', 
 'log', 
 '{"service_name": "order-service", "hours": 6}', 
 TRUE, NULL),

('Logs with Exception Stack Trace', 'Find logs containing stack traces', 
 'SELECT message, service_name, timestamp 
  FROM btrace_core.logs 
  WHERE message ILIKE ''%exception%'' 
     OR message ILIKE ''%trace%'' 
     OR message ILIKE ''%at %.%('' 
  ORDER BY timestamp DESC 
  LIMIT 100', 
 'log', 
 '{"pattern": "exception|trace"}', 
 TRUE, NULL),

('Logs Correlated to Trace', 'Show logs for a specific trace', 
 'SELECT message, log_level, timestamp 
  FROM btrace_core.logs 
  WHERE trace_id = {{trace_id}} 
  ORDER BY timestamp', 
 'log', 
 '{"trace_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Slow Query Logs (DB)', 'Logs indicating slow database queries', 
 'SELECT message, service_name, timestamp 
  FROM btrace_core.logs 
  WHERE (message ILIKE ''%slow query%'' OR message ILIKE ''%execution time%ms%'') 
    AND timestamp >= NOW() - INTERVAL ''1 day''', 
 'log', 
 '{"source": "database"}', 
 TRUE, NULL),

-- ===== METRIC QUERIES =====
('P95 HTTP Request Duration - Last 1 Hour', 'Top 5% slowest HTTP requests', 
 'SELECT service_name, PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) AS p95_latency 
  FROM btrace_core.metrics 
  WHERE metric_name = ''http.request.duration'' 
    AND attributes @> ''{"http.status_code": "200"}'' 
    AND timestamp >= NOW() - INTERVAL ''1 hour'' 
  GROUP BY service_name 
  ORDER BY p95_latency DESC', 
 'metric', 
 '{"metric": "http.request.duration", "percentile": 0.95}', 
 TRUE, NULL),

('Error Rate by Service - 5 Minute Rate', 'Calculate error rate per service', 
 'SELECT 
    service_name,
    SUM(CASE WHEN attributes @> ''{"http.status_code": "5"}'' THEN value ELSE 0 END) / NULLIF(SUM(value), 0) AS error_rate
  FROM btrace_core.metrics 
  WHERE metric_name = ''http.requests.count'' 
    AND timestamp >= NOW() - INTERVAL ''5 minutes''
  GROUP BY service_name 
  HAVING error_rate > 0.01 
  ORDER BY error_rate DESC', 
 'metric', 
 '{"threshold": 0.01}', 
 TRUE, NULL),

('CPU Utilization - Top 10 Hosts', 'Hosts with highest CPU usage', 
 'SELECT attributes->>''host.name'' as host, MAX(value) as max_cpu 
  FROM btrace_core.metrics 
  WHERE metric_name = ''system.cpu.utilization'' 
    AND timestamp >= NOW() - INTERVAL ''15 minutes'' 
  GROUP BY host 
  ORDER BY max_cpu DESC 
  LIMIT 10', 
 'metric', 
 '{"metric": "system.cpu.utilization", "limit": 10}', 
 TRUE, NULL),

('Request Rate per Service', 'Total requests per service over last 5m', 
 'SELECT service_name, SUM(value) as total_requests 
  FROM btrace_core.metrics 
  WHERE metric_name = ''http.requests.count'' 
    AND timestamp >= NOW() - INTERVAL ''5 minutes'' 
  GROUP BY service_name 
  ORDER BY total_requests DESC', 
 'metric', 
 '{"time_window": "5m"}', 
 TRUE, NULL),

('Memory Usage Trend - Last 24h', 'Average memory usage per service', 
 'SELECT service_name, AVG(value) as avg_memory_mb 
  FROM btrace_core.metrics 
  WHERE metric_name = ''process.memory.usage'' 
    AND unit = ''MB'' 
    AND timestamp >= NOW() - INTERVAL ''24 hours'' 
  GROUP BY service_name 
  ORDER BY avg_memory_mb DESC', 
 'metric', 
 '{"unit": "MB"}', 
 TRUE, NULL),

-- ===== INCIDENT & POST-MORTEM =====
('Recent Incidents - Last 7 Days', 'Show all incidents from the past week', 
 'SELECT title, severity, start_time, end_time, is_customer_impacting 
  FROM btrace_core.incidents 
  WHERE start_time >= NOW() - INTERVAL ''7 days'' 
  ORDER BY start_time DESC', 
 'custom', 
 '{"time_range": "7d"}', 
 TRUE, NULL),

('Open Action Items by Owner', 'All unresolved post-mortem tasks', 
 'SELECT description, due_date, status 
  FROM btrace_core.incident_action_items 
  WHERE status NOT IN (''completed'', ''review'') 
  ORDER BY due_date ASC', 
 'custom', 
 '{"status": "open"}', 
 TRUE, NULL),

('P1 Incidents - Last 30 Days', 'Critical incidents for executive review', 
 'SELECT title, start_time, resolved_at, impact 
  FROM btrace_core.incidents 
  WHERE severity = ''P1'' 
    AND start_time >= NOW() - INTERVAL ''30 days''', 
 'custom', 
 '{"severity": "P1"}', 
 TRUE, NULL),

-- ===== SERVICE DEPENDENCIES =====
('Service Calls - HTTP', 'Show all HTTP-based service dependencies', 
 'SELECT DISTINCT source.service_name AS caller, target.service_name AS callee 
  FROM btrace_core.spans source 
  JOIN btrace_core.spans target ON source.span_id = target.parent_span_id 
  WHERE source.kind = ''CLIENT'' AND target.kind = ''SERVER'' 
    AND source.attributes @> ''{"http.method": "GET"}'' 
  LIMIT 100', 
 'span', 
 '{"protocol": "http"}', 
 TRUE, NULL),

('Kafka Producers to Consumers', 'Map Kafka message flow between services', 
 'SELECT producer.service_name AS producer, consumer.service_name AS consumer, 
         attributes->>''messaging.destination'' as topic 
  FROM btrace_core.spans producer 
  JOIN btrace_core.spans consumer ON producer.links @> jsonb_build_array(jsonb_build_object(''trace_id'', consumer.trace_id, ''span_id'', consumer.span_id))
  WHERE producer.kind = ''PRODUCER'' AND consumer.kind = ''CONSUMER''', 
 'span', 
 '{"messaging": "kafka"}', 
 TRUE, NULL),

-- ===== SECURITY & COMPLIANCE =====
('Failed Login Attempts', 'Logs indicating authentication failures', 
 'SELECT message, attributes->>''user_id'' as user, timestamp 
  FROM btrace_core.logs 
  WHERE message ILIKE ''%failed login%'' 
     OR message ILIKE ''%authentication failed%'' 
  ORDER BY timestamp DESC', 
 'log', 
 '{"event": "auth_failure"}', 
 TRUE, NULL),

('Access to PII-Tagged Traces', 'Audit access to sensitive traces', 
 'SELECT trace_id, start_time, root_service 
  FROM btrace_core.traces 
  WHERE tags ? ''pii'' 
    AND start_time >= NOW() - INTERVAL ''30 days''', 
 'trace', 
 '{"tag": "pii", "scope": "audit"}', 
 TRUE, NULL),

-- ===== DEBUGGING & TESTING =====
('Traces with Test Headers', 'Find traces from synthetic or load tests', 
 'SELECT trace_id, trace_name, attributes 
  FROM btrace_core.traces 
  WHERE tags ? ''test'' OR attributes @> ''{"user-agent": "load-test"}''', 
 'trace', 
 '{"tag": "test"}', 
 TRUE, NULL),

('Spans with High Retry Count', 'Spans that retried more than 3 times', 
 'SELECT span_name, service_name, events 
  FROM btrace_core.spans 
  WHERE (SELECT COUNT(*) FROM jsonb_array_elements(events) e WHERE e->>''name'' = ''retry'') > 3', 
 'span', 
 '{"min_retries": 3}', 
 TRUE, NULL),

-- ===== SYSTEM HEALTH =====
('Host Uptime from Logs', 'Infer host availability from heartbeat logs', 
 'SELECT attributes->>''host.name'' as host, MIN(timestamp) as first_seen 
  FROM btrace_core.logs 
  WHERE message ILIKE ''%service started%'' 
  GROUP BY host 
  ORDER BY first_seen ASC', 
 'log', 
 '{"event": "startup"}', 
 TRUE, NULL),

('Disk Usage > 80%', 'Alert on high disk utilization', 
 'SELECT attributes->>''host.name'' as host, MAX(value) as usage_pct 
  FROM btrace_core.metrics 
  WHERE metric_name = ''system.disk.usage'' 
    AND value > 80 
  GROUP BY host', 
 'metric', 
 '{"threshold": 80}', 
 TRUE, NULL),

-- ===== CUSTOM & ADVANCED =====
('Trace-to-Metric Gap Analysis', 'Find traces without corresponding metrics', 
 'SELECT t.trace_id 
  FROM btrace_core.traces t 
  LEFT JOIN btrace_core.metrics m ON m.attributes @> jsonb_build_object(''trace_id'', t.trace_id::text)
  WHERE m.metric_id IS NULL 
    AND t.start_time >= NOW() - INTERVAL ''1 hour'' 
  LIMIT 50', 
 'custom', 
 '{"gap": "trace-metric"}', 
 TRUE, NULL),

('Orphaned Spans (No Trace)', 'Find spans not linked to a trace', 
 'SELECT span_id, span_name 
  FROM btrace_core.spans s 
  WHERE NOT EXISTS (
    SELECT 1 FROM btrace_core.traces t 
    WHERE t.trace_id = s.trace_id AND t.start_time <= s.start_time AND t.end_time >= s.start_time
  )', 
 'span', 
 '{"issue": "orphaned"}', 
 TRUE, NULL),

('High Cardinality Attributes', 'Find attributes causing high cardinality', 
 'SELECT key, COUNT(*) as usage 
  FROM btrace_core.spans, jsonb_object_keys(attributes) as key 
  GROUP BY key 
  ORDER BY usage DESC 
  LIMIT 20', 
 'span', 
 '{"analysis": "cardinality"}', 
 TRUE, NULL);

--- adding tags to the table will help 
ALTER TABLE btrace_analytics.saved_queries ADD COLUMN tags TEXT[];

-- adding index for full-text search 
CREATE INDEX ON btrace_analytics.saved_queries USING GIN(to_tsvector('english', description));


INSERT INTO btrace_analytics.saved_queries (
    query_name,
    description,
    query_text,
    query_type,
    parameters,
    is_shared,
    created_by
)
VALUES

-- ===== CROSS-DOMAIN CORRELATION =====
('Trace + Log + Metric: Full Context for Trace ID', 'Correlate all telemetry for a single trace', 
 'WITH trace_data AS (
    SELECT trace_id, trace_name, duration_ms, root_service 
    FROM btrace_core.traces 
    WHERE trace_id = {{trace_id}}
 ),
 log_data AS (
    SELECT message, log_level, timestamp 
    FROM btrace_core.logs 
    WHERE trace_id = {{trace_id}} 
      AND timestamp BETWEEN (SELECT start_time FROM btrace_core.traces WHERE trace_id = {{trace_id}}) 
                        AND (SELECT end_time FROM btrace_core.traces WHERE trace_id = {{trace_id}})
 ),
 metric_data AS (
    SELECT metric_name, value, timestamp 
    FROM btrace_core.metrics 
    WHERE attributes @> jsonb_build_object(''trace_id'', {{trace_id}}::text)
      AND timestamp BETWEEN (SELECT start_time FROM btrace_core.traces WHERE trace_id = {{trace_id}}) 
                        AND (SELECT end_time FROM btrace_core.traces WHERE trace_id = {{trace_id}})
 )
 SELECT ''trace'' as source, trace_name as detail, duration_ms::text as value, ''info'' as level FROM trace_data
 UNION ALL
 SELECT ''log'' as source, message as detail, log_level as value, log_level as level FROM log_data
 UNION ALL
 SELECT ''metric'' as source, metric_name as detail, value::text, ''metric'' as level FROM metric_data
 ORDER BY timestamp', 
 'custom', 
 '{"trace_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Spans with Errors AND High Latency', 'Find spans that are both slow and errored', 
 'SELECT span_name, service_name, duration_ms, status_message 
  FROM btrace_core.spans 
  WHERE status_code != ''OK'' 
    AND duration_ms > 1000 
    AND start_time >= NOW() - INTERVAL ''1 hour'' 
  ORDER BY duration_ms DESC', 
 'span', 
 '{"latency_threshold_ms": 1000, "time_range": "1h"}', 
 TRUE, NULL),

('Logs Preceding an Error Trace', 'Show logs in the 30 seconds before an error trace started', 
 'SELECT l.timestamp, l.message, l.service_name 
  FROM btrace_core.logs l
  JOIN btrace_core.traces t ON l.trace_id = t.trace_id
  WHERE t.status_code = ''ERROR''
    AND l.timestamp < t.start_time
    AND l.timestamp >= t.start_time - INTERVAL ''30 seconds''
  ORDER BY l.timestamp DESC', 
 'log', 
 '{"lookback": "30 seconds"}', 
 TRUE, NULL),

('Traces with No Logs (Orphaned)', 'Find traces that have no associated logs — potential instrumentation gap', 
 'SELECT t.trace_id, t.trace_name, t.duration_ms 
  FROM btrace_core.traces t
  WHERE NOT EXISTS (
    SELECT 1 FROM btrace_core.logs l WHERE l.trace_id = t.trace_id
  )
    AND t.start_time >= NOW() - INTERVAL ''1 hour''', 
 'trace', 
 '{"gap": "trace-log"}', 
 TRUE, NULL),

('High Metric Variance Spans', 'Spans during periods of high CPU or memory variance', 
 'WITH high_variance_metrics AS (
    SELECT service_name, 
           AVG(value) as avg_val, 
           STDDEV(value) as std_dev
    FROM btrace_core.metrics 
    WHERE metric_name = ''system.cpu.utilization'' 
      AND timestamp >= NOW() - INTERVAL ''5 minutes''
    GROUP BY service_name
    HAVING STDDEV(value) > 0.15
 )
 SELECT s.span_name, s.service_name, s.duration_ms
 FROM btrace_core.spans s
 JOIN high_variance_metrics hvm ON s.service_name = hvm.service_name
 WHERE s.start_time >= NOW() - INTERVAL ''5 minutes''', 
 'span', 
 '{"metric": "system.cpu.utilization", "stddev_threshold": 0.15}', 
 TRUE, NULL),

-- ===== INCIDENT INVESTIGATION =====
('Incident Timeline: Traces, Logs, Alerts', 'Full telemetry context around an incident', 
 'SELECT ''trace'' as type, t.duration_ms as value, t.trace_name as detail, t.start_time as event_time
  FROM btrace_core.traces t
  JOIN btrace_core.incidents i ON t.start_time BETWEEN i.start_time - INTERVAL ''5 minutes'' AND i.end_time + INTERVAL ''5 minutes''
  WHERE i.incident_id = {{incident_id}}
    AND t.status_code = ''ERROR''
 UNION ALL
 SELECT ''log'' as type, NULL as value, l.message as detail, l.timestamp as event_time
  FROM btrace_core.logs l
  JOIN btrace_core.incidents i ON l.timestamp BETWEEN i.start_time - INTERVAL ''5 minutes'' AND i.end_time + INTERVAL ''5 minutes''
  WHERE i.incident_id = {{incident_id}}
    AND l.log_level IN (''ERROR'', ''WARN'')
 UNION ALL
 SELECT ''alert'' as type, NULL as value, ar.rule_name as detail, a.triggered_at as event_time
  FROM btrace_core.alerts a
  JOIN btrace_core.alert_rules ar ON a.rule_id = ar.rule_id
  JOIN btrace_core.incidents i ON a.incident_id = i.incident_id
  WHERE i.incident_id = {{incident_id}}
 ORDER BY event_time', 
 'custom', 
 '{"incident_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Post-Mortem: Top 10 Slowest Traces During Incident', 
 'Identify the slowest traces that occurred during an incident window', 
 'SELECT trace_id, trace_name, duration_ms, root_service
  FROM btrace_core.traces
  WHERE start_time >= (SELECT start_time FROM btrace_core.incidents WHERE incident_id = {{incident_id}})
    AND end_time <= (SELECT COALESCE(end_time, NOW()) FROM btrace_core.incidents WHERE incident_id = {{incident_id}})
    AND is_sampled = TRUE
  ORDER BY duration_ms DESC
  LIMIT 10', 
 'trace', 
 '{"incident_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Incident-Related Spans by Service', 'Breakdown of error spans during an incident by service', 
 'SELECT s.service_name, COUNT(*) as error_span_count
  FROM btrace_core.spans s
  JOIN btrace_core.incidents i ON s.start_time BETWEEN i.start_time AND COALESCE(i.end_time, NOW())
  WHERE i.incident_id = {{incident_id}}
    AND s.status_code != ''OK''
  GROUP BY s.service_name
  ORDER BY error_span_count DESC', 
 'span', 
 '{"incident_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Logs During Incident with PII Tags', 'Audit for sensitive data exposure during outages', 
 'SELECT message, service_name, attributes->>''user_id'' as user_id
  FROM btrace_core.logs
  JOIN btrace_core.incidents i ON timestamp BETWEEN i.start_time AND COALESCE(i.end_time, NOW())
  WHERE i.incident_id = {{incident_id}}
    AND (attributes ? ''pii'' OR message ILIKE ''%ssn%'' OR message ILIKE ''%password%'')
  ORDER BY timestamp', 
 'log', 
 '{"incident_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

-- ===== ANOMALY & OUTLIER DETECTION =====
('Traces with Duration > 3σ from Mean', 'Statistical outlier detection for latency', 
 'WITH trace_stats AS (
    SELECT AVG(duration_ms) as mean, STDDEV(duration_ms) as stddev
    FROM btrace_core.traces
    WHERE start_time >= NOW() - INTERVAL ''1 hour''
      AND is_sampled = TRUE
 )
 SELECT t.trace_id, t.trace_name, t.duration_ms, t.root_service
 FROM btrace_core.traces t, trace_stats s
 WHERE t.duration_ms > (s.mean + 3 * s.stddev)
   AND t.start_time >= NOW() - INTERVAL ''1 hour''
 ORDER BY t.duration_ms DESC', 
 'trace', 
 '{"stddev_multiplier": 3, "time_window": "1h"}', 
 TRUE, NULL),

('Sudden Spike in 5xx Error Rate', 'Detect abrupt increases in error rate', 
 'WITH error_rates AS (
    SELECT 
        time_bucket(''5 minutes'', m.timestamp) as bucket,
        SUM(CASE WHEN m.attributes @> ''{"http.status_code": "5"}'' THEN m.value ELSE 0 END) / NULLIF(SUM(m.value), 0) as error_rate
    FROM btrace_core.metrics m
    WHERE m.metric_name = ''http.requests.count''
      AND m.timestamp >= NOW() - INTERVAL ''1 hour''
    GROUP BY bucket
 ),
 rate_changes AS (
    SELECT bucket, error_rate,
           LAG(error_rate) OVER (ORDER BY bucket) as prev_rate
    FROM error_rates
 )
 SELECT bucket, error_rate, prev_rate, (error_rate - prev_rate) as delta
 FROM rate_changes
 WHERE prev_rate IS NOT NULL AND (error_rate - prev_rate) > 0.1
 ORDER BY delta DESC', 
 'metric', 
 '{"threshold_increase": 0.1, "window": "5m"}', 
 TRUE, NULL),

('Spans with Missing Parent', 'Detect broken trace context propagation', 
 'SELECT span_name, service_name, start_time
  FROM btrace_core.spans
  WHERE parent_span_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM btrace_core.spans parent
      WHERE parent.span_id = parent_span_id
        AND parent.trace_id = spans.trace_id
    )
    AND start_time >= NOW() - INTERVAL ''1 hour''', 
 'span', 
 '{"issue": "orphaned_child"}', 
 TRUE, NULL),

-- ===== SERVICE DEPENDENCY & TOPOLOGY =====
('Service Call Graph (Last 5 Min)', 'Dynamic service dependency map', 
 'SELECT DISTINCT
    caller.service_name AS source,
    callee.service_name AS target,
    COUNT(*) as call_count
  FROM btrace_core.spans caller
  JOIN btrace_core.spans callee ON caller.span_id = callee.parent_span_id
  WHERE caller.kind = ''CLIENT'' AND callee.kind = ''SERVER''
    AND caller.start_time >= NOW() - INTERVAL ''5 minutes''
  GROUP BY source, target
  ORDER BY call_count DESC', 
 'span', 
 '{"time_window": "5m"}', 
 TRUE, NULL),

('Downstream Services of a Given Service', 'Find all services called by a specific service', 
 'SELECT DISTINCT callee.service_name
  FROM btrace_core.spans caller
  JOIN btrace_core.spans callee ON caller.span_id = callee.parent_span_id
  WHERE caller.service_name = {{service_name}}
    AND caller.kind = ''CLIENT''
    AND callee.kind = ''SERVER''
    AND caller.start_time >= NOW() - INTERVAL ''1 hour''', 
 'span', 
 '{"service_name": "auth-service"}', 
 TRUE, NULL),

('Services That Call a Database', 'Map application services to databases', 
 'SELECT DISTINCT s.service_name, 
         a.attributes->>''db.name'' as database_name,
         a.attributes->>''db.system'' as db_type
  FROM btrace_core.spans s
  WHERE s.operation_name ILIKE ''%database%'' 
     OR s.attributes ? ''db.name''
  ORDER BY database_name, service_name', 
 'span', 
 '{"category": "database"}', 
 TRUE, NULL),

-- ===== SECURITY & COMPLIANCE =====
('Failed Login Attempts by IP', 'Brute force attack detection', 
 'SELECT 
    attributes->>''http.client_ip'' as client_ip,
    COUNT(*) as attempt_count
  FROM btrace_core.logs
  WHERE message ILIKE ''%failed login%''
    AND timestamp >= NOW() - INTERVAL ''15 minutes''
  GROUP BY client_ip
  HAVING COUNT(*) > 10
  ORDER BY attempt_count DESC', 
 'log', 
 '{"threshold": 10, "window": "15m"}', 
 TRUE, NULL),

('PII Access Logs', 'Audit access to PII-tagged data', 
 'SELECT message, attributes->>''user_id'' as user, timestamp
  FROM btrace_core.logs
  WHERE tags ? ''pii'' OR message ILIKE ''%ssn%'' OR message ILIKE ''%credit_card%''
  ORDER BY timestamp DESC
  LIMIT 100', 
 'log', 
 '{"sensitivity": "high"}', 
 TRUE, NULL),

('Unusual Admin Access Times', 'Detect admin logins outside business hours', 
 'SELECT message, attributes->>''user_id'' as user, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%admin%login%'' OR attributes @> ''{"role": "admin"}'')
    AND EXTRACT(HOUR FROM timestamp) NOT BETWEEN 9 AND 17
  ORDER BY timestamp DESC', 
 'log', 
 '{"role": "admin", "hours": "non-business"}', 
 TRUE, NULL),

-- ===== SLO & PERFORMANCE =====
('Error Budget Burn Rate - Last 7 Days', 'Calculate daily error budget consumption', 
 'WITH daily_error_rate AS (
    SELECT
        time_bucket(''1 day'', m.timestamp) as day,
        SUM(CASE WHEN m.attributes @> ''{"http.status_code": "5"}'' THEN m.value ELSE 0 END) / NULLIF(SUM(m.value), 0) as error_rate
    FROM btrace_core.metrics m
    WHERE m.metric_name = ''http.requests.count''
      AND m.timestamp >= NOW() - INTERVAL ''7 days''
    GROUP BY day
 )
 SELECT 
    day,
    error_rate,
    1 - error_rate as availability,
    (1 - 0.9995) / (1 - error_rate) as burn_rate
 FROM daily_error_rate
 ORDER BY day', 
 'metric', 
 '{"slo_target": 0.9995}', 
 TRUE, NULL),

('P99 Latency vs Request Rate', 'Correlate throughput and latency', 
 'WITH latency AS (
    SELECT
        time_bucket(''5 minutes'', t.start_time) as bucket,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY t.duration_ms) as p99_latency
    FROM btrace_core.traces t
    WHERE t.trace_name = {{trace_name}}
      AND t.start_time >= NOW() - INTERVAL ''1 hour''
    GROUP BY bucket
 ),
 rate AS (
    SELECT
        time_bucket(''5 minutes'', m.timestamp) as bucket,
        SUM(m.value) as request_rate
    FROM btrace_core.metrics m
    WHERE m.metric_name = ''http.requests.count''
      AND m.attributes->>''http.route'' = {{route}}
      AND m.timestamp >= NOW() - INTERVAL ''1 hour''
    GROUP BY bucket
 )
 SELECT l.bucket, l.p99_latency, r.request_rate
 FROM latency l
 JOIN rate r ON l.bucket = r.bucket
 ORDER BY l.bucket', 
 'custom', 
 '{"trace_name": "HTTP GET /api/users", "route": "/api/users"}', 
 TRUE, NULL),

-- ===== ADVANCED DEBUGGING =====
('Traces with Retry Loops', 'Find traces with repeated retry patterns', 
 'SELECT t.trace_id, t.trace_name, COUNT(*) as retry_count
  FROM btrace_core.traces t
  JOIN btrace_core.spans s ON t.trace_id = s.trace_id
  WHERE s.events @> ''[{"name": "retry"}]''
    AND s.start_time >= NOW() - INTERVAL ''1 hour''
  GROUP BY t.trace_id, t.trace_name
  HAVING COUNT(*) > 3
  ORDER BY retry_count DESC', 
 'trace', 
 '{"min_retries": 3}', 
 TRUE, NULL),

('Spans with Large Payloads', 'Detect spans processing large data (potential DoS)', 
 'SELECT span_name, service_name, 
         (attributes->>''message.size.bytes'')::BIGINT as size_bytes
  FROM btrace_core.spans
  WHERE (attributes->>''message.size.bytes'')::BIGINT > 1000000
    AND start_time >= NOW() - INTERVAL ''1 hour''
  ORDER BY size_bytes DESC', 
 'span', 
 '{"size_threshold_bytes": 1000000}', 
 TRUE, NULL),

('Missing Heartbeat Logs', 'Detect services that stopped sending logs (crash/dead)', 
 'SELECT DISTINCT service_name
  FROM btrace_core.logs
  WHERE service_name IN (SELECT service_name FROM btrace_core.logs GROUP BY service_name)
    AND service_name NOT IN (
      SELECT service_name
      FROM btrace_core.logs
      WHERE timestamp >= NOW() - INTERVAL ''5 minutes''
    )', 
 'log', 
 '{"timeout": "5m"}', 
 TRUE, NULL);
-- tack changes to query_text over time --versioning the query

-- add security audit queries 
INSERT INTO btrace_analytics.saved_queries (
    query_name,
    description,
    query_text,
    query_type,
    parameters,
    is_shared,
    created_by
)
VALUES

-- ===== PII & DATA EXPOSURE =====
('Traces with PII Tags - Last 30 Days', 'Find traces tagged as containing PII for compliance audits', 
 'SELECT trace_id, trace_name, duration_ms, root_service, start_time
  FROM btrace_core.traces
  WHERE tags ? ''pii'' 
    AND start_time >= NOW() - INTERVAL ''30 days''
  ORDER BY start_time DESC', 
 'trace', 
 '{"tag": "pii", "retention_days": 30}', 
 TRUE, NULL),

('Logs Containing PII Patterns', 'Detect logs with potential PII (SSN, email, credit card)', 
 'SELECT message, service_name, timestamp, attributes->>''user_id'' as user_id
  FROM btrace_core.logs
  WHERE (message ~* ''\d{3}-\d{2}-\d{4}'' OR -- SSN
         message ~* ''\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'' OR -- Email
         message ~* ''\b(?:\d[ -]*?){13,16}\b'' -- Credit Card
        )
    AND timestamp >= NOW() - INTERVAL ''7 days''
  ORDER BY timestamp DESC
  LIMIT 100', 
 'log', 
 '{"patterns": ["ssn", "email", "credit_card"]}', 
 TRUE, NULL),

('Spans Accessing PII-Tagged Data', 'Spans that read or write sensitive user data', 
 'SELECT span_name, service_name, attributes->>''db.statement'' as statement, start_time
  FROM btrace_core.spans
  WHERE attributes @> ''{"data.sensitivity": "high"}'' 
     OR operation_name ILIKE ''%user%profile%''
  ORDER BY start_time DESC', 
 'span', 
 '{"sensitivity": "high"}', 
 TRUE, NULL),

('Metrics with PII Tags', 'Identify metrics that may expose sensitive data', 
 'SELECT metric_name, unit, tags
  FROM btrace_core.metric_definitions
  WHERE tags ? ''pii'' OR tags->>''pii'' = ''true''
  ORDER BY metric_name', 
 'metric', 
 '{"tag": "pii"}', 
 TRUE, NULL),

-- ===== AUTHENTICATION & ACCESS =====
('Failed Login Attempts by User', 'Audit failed logins per user (brute force detection)', 
 'SELECT attributes->>''user_id'' as user_id, COUNT(*) as fail_count, MIN(timestamp) as first_attempt, MAX(timestamp) as last_attempt
  FROM btrace_core.logs
  WHERE message ILIKE ''%failed login%''
     OR message ILIKE ''%authentication failed%''
     OR (log_level = ''WARN'' AND message ILIKE ''%invalid credentials%'')
    AND timestamp >= NOW() - INTERVAL ''15 minutes''
  GROUP BY user_id
  HAVING COUNT(*) > 5
  ORDER BY fail_count DESC', 
 'log', 
 '{"threshold": 5, "window": "15m"}', 
 TRUE, NULL),

('Successful Logins Outside Business Hours', 'Detect admin or user logins during off-hours', 
 'SELECT message, attributes->>''user_id'' as user_id, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%login%success%'')
    AND EXTRACT(HOUR FROM timestamp) NOT BETWEEN 8 AND 18
    AND timestamp >= NOW() - INTERVAL ''7 days''
  ORDER BY timestamp DESC', 
 'log', 
 '{"role": "user", "hours": "non-business"}', 
 TRUE, NULL),

('Admin Role Changes', 'Audit when a user was granted admin privileges', 
 'SELECT message, attributes->>''target_user'' as target, attributes->>''granted_by'' as granted_by, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%role updated%admin%''
     OR message ILIKE ''%privilege escalation%'')
    AND timestamp >= NOW() - INTERVAL ''30 days''
  ORDER BY timestamp DESC', 
 'log', 
 '{"action": "role_change"}', 
 TRUE, NULL),

('Service Account Usage in Production', 'Monitor non-human identity access to prod', 
 'SELECT message, attributes->>''service_account'' as service, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%service account%''
     OR attributes ? ''service_account'')
    AND environment_id = (SELECT environment_id FROM btrace_core.environments WHERE environment_name = ''production'')
    AND timestamp >= NOW() - INTERVAL ''24 hours''
  ORDER BY timestamp DESC', 
 'log', 
 '{"env": "production", "identity": "service_account"}', 
 TRUE, NULL),

-- ===== ANOMALY & THREAT DETECTION =====
('Unusual Spike in Error Rate (Potential DDoS)', 'Detect sudden increase in 5xx errors', 
 'WITH error_rate AS (
    SELECT 
        time_bucket(''1 minute'', m.timestamp) as bucket,
        SUM(CASE WHEN m.attributes @> ''{"http.status_code": "5"}'' THEN m.value ELSE 0 END) / NULLIF(SUM(m.value), 0) as error_ratio
    FROM btrace_core.metrics m
    WHERE m.metric_name = ''http.requests.count''
      AND m.timestamp >= NOW() - INTERVAL ''10 minutes''
    GROUP BY bucket
 ),
 lagged AS (
    SELECT bucket, error_ratio,
           LAG(error_ratio, 1) OVER (ORDER BY bucket) as prev_ratio
    FROM error_rate
 )
 SELECT bucket, error_ratio, prev_ratio, (error_ratio - prev_ratio) as delta
 FROM lagged
 WHERE prev_ratio IS NOT NULL AND (error_ratio - prev_ratio) > 0.2
 ORDER BY delta DESC', 
 'metric', 
 '{"threshold": 0.2, "window": "1m"}', 
 TRUE, NULL),

('Traces from Unknown IPs', 'Find traces initiated from unexpected client IPs', 
 'SELECT t.trace_id, t.trace_name, l.attributes->>''http.client_ip'' as client_ip, t.start_time
  FROM btrace_core.traces t
  JOIN btrace_core.logs l ON t.trace_id = l.trace_id
  WHERE l.attributes ? ''http.client_ip''
    AND l.attributes->>''http.client_ip'' NOT IN (''192.168.%'', ''10.%'', ''172.16.%'', ''172.31.%'', ''203.0.113.%'')
    AND t.start_time >= NOW() - INTERVAL ''1 hour''
  ORDER BY t.start_time DESC', 
 'trace', 
 '{"trusted_ranges": ["192.168.0.0/16", "10.0.0.0/8"]}', 
 TRUE, NULL),

('Spans with Elevated Privileges', 'Spans where operations were performed with admin rights', 
 'SELECT span_name, service_name, attributes->>''auth.role'' as role, start_time
  FROM btrace_core.spans
  WHERE attributes @> ''{"auth.elevated": "true"}''
     OR attributes->>''auth.role'' = ''admin''
  ORDER BY start_time DESC', 
 'span', 
 '{"privilege": "elevated"}', 
 TRUE, NULL),

('Logs from Suspicious User Agents', 'Detect potential bots, scrapers, or attack tools', 
 'SELECT message, attributes->>''http.user_agent'' as user_agent, timestamp
  FROM btrace_core.logs
  WHERE (attributes->>''http.user_agent'') ILIKE ''%sqlmap%''
     OR (attributes->>''http.user_agent'') ILIKE ''%nmap%''
     OR (attributes->>''http.user_agent'') ILIKE ''%burp%''
     OR (attributes->>''http.user_agent'') ILIKE ''%curl'' AND message ILIKE ''%admin%''
  ORDER BY timestamp DESC', 
 'log', 
 '{"tools": ["sqlmap", "nmap", "burp"]}', 
 TRUE, NULL),

-- ===== COMPLIANCE & FORENSICS =====
('GDPR Right to Access: User Data Traces', 'Find all traces involving a specific user (DSAR support)', 
 'SELECT t.trace_id, t.trace_name, t.duration_ms, t.start_time, t.root_service
  FROM btrace_core.traces t
  WHERE t.tags @> jsonb_build_object(''user_id'', {{user_id}})
     OR t.tags ? {{user_id}}
  ORDER BY t.start_time DESC', 
 'trace', 
 '{"user_id": "usr-12345"}', 
 TRUE, NULL),

('HIPAA Audit: PHI Access Logs', 'Audit access to protected health information', 
 'SELECT message, attributes->>''patient_id'' as patient_id, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%patient%''
     OR message ILIKE ''%medical%''
     OR attributes ? ''patient_id'')
    AND (log_level = ''INFO'' OR log_level = ''WARN'')
  ORDER BY timestamp DESC
  LIMIT 200', 
 'log', 
 '{"data_type": "phi"}', 
 TRUE, NULL),

('Incident-Related Security Logs', 'Security-relevant logs during a known incident', 
 'SELECT l.message, l.log_level, l.timestamp
  FROM btrace_core.logs l
  JOIN btrace_core.incidents i ON l.timestamp BETWEEN i.start_time AND COALESCE(i.end_time, NOW())
  WHERE i.incident_id = {{incident_id}}
    AND (l.message ILIKE ''%unauthorized%''
      OR l.message ILIKE ''%denied%''
      OR l.message ILIKE ''%blocked%'')
  ORDER BY l.timestamp', 
 'log', 
 '{"incident_id": "a1b2c3d4-..."}', 
 TRUE, NULL),

('Service Account with Long-Lived Tokens', 'Detect service accounts using old credentials', 
 'SELECT attributes->>''service_account'' as service, MAX(timestamp) as last_used
  FROM btrace_core.logs
  WHERE attributes ? ''service_account''
  GROUP BY service
  HAVING MAX(timestamp) < NOW() - INTERVAL ''90 days''
  ORDER BY last_used ASC', 
 'log', 
 '{"rotation_policy_days": 90}', 
 TRUE, NULL),

('Privileged Operation Audit Trail', 'Log all admin-level operations', 
 'SELECT operation_name, service_name, attributes->>''user_id'' as user, start_time
  FROM btrace_core.spans
  WHERE span_name ILIKE ''%delete%''
     OR span_name ILIKE ''%disable%''
     OR span_name ILIKE ''%grant%''
     OR attributes @> ''{"auth.level": "admin"}''
  ORDER BY start_time DESC
  LIMIT 100', 
 'span', 
 '{"operation": "privileged"}', 
 TRUE, NULL),

('Configuration Changes in Production', 'Audit config updates that could impact security', 
 'SELECT message, attributes->>''changed_by'' as user, timestamp
  FROM btrace_core.logs
  WHERE (message ILIKE ''%config updated%''
     OR message ILIKE ''%feature flag%'')
    AND environment_id = (SELECT environment_id FROM btrace_core.environments WHERE environment_name = ''production'')
  ORDER BY timestamp DESC', 
 'log', 
 '{"env": "production", "change_type": "config"}', 
 TRUE, NULL);

-- todo -- build a searchable library with filtering by query-type, tags -- query explorer UI 
-- 

--list all shared queries 
SELECT 
    q.query_name, 
    q.description, 
    u.username AS owner, 
    q.updated_at
FROM btrace_analytics.saved_queries q
LEFT JOIN btrace_rbac.users u ON q.created_by = u.user_id
WHERE q.is_shared = TRUE
ORDER BY q.updated_at DESC;

--search queries by type 
SELECT query_name, query_text
FROM btrace_analytics.saved_queries
WHERE query_type = 'trace'
  AND (query_name ILIKE '%latency%' OR description ILIKE '%slow%');
  
  
-- show my queries 
SELECT query_name, is_shared, updated_at
FROM btrace_analytics.saved_queries
WHERE created_by = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY updated_at DESC;


--automated partition creation 
CREATE OR REPLACE FUNCTION create_traces_partitions()
RETURNS void AS $$
DECLARE
    start_date DATE := DATE_TRUNC('month', NOW());
    end_date   DATE := start_date + INTERVAL '12 months';
    part_name  TEXT;
    part_start TIMESTAMP;
    part_end   TIMESTAMP;
BEGIN
    FOR part_start IN SELECT generate_series(start_date, end_date, '1 month') LOOP
        part_end := part_start + INTERVAL '1 month';
        part_name := 'traces_' || TO_CHAR(part_start, 'YYYY_MM');
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS btrace_core.%I PARTITION OF btrace_core.traces FOR VALUES FROM (%L) TO (%L)',
            part_name, part_start, part_end
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- SOC/SIEM style dashboards with compliance reporting (GDPR, HIPAA, SOC2)
-- materilaized view for security events 
--
-- BUSINESS CASE:
-- The `security_events` materialized view consolidates high-risk security signals from traces, logs, spans, and incidents
-- into a unified event stream. It enables centralized monitoring, faster threat detection, and simplified compliance reporting.
-- This is essential for security teams, incident commanders, and auditors.
--
-- PURPOSE:
-- - Normalize security-relevant events from heterogeneous sources
-- - Support real-time dashboards and alerting
-- - Enable historical analysis and forensics
-- - Reduce query complexity for security use cases
-- - Facilitate integration with external SIEMs or alerting systems
--
--
-- BUSINESS CASE:
-- The `security_events` materialized view consolidates high-risk security signals from logs, incidents, and traces
-- into a unified event stream. This spans-free version avoids dependency on the `spans` table for early deployment.
-- It enables centralized monitoring, faster threat detection, and simplified compliance reporting.
--
-- PURPOSE:
-- - Normalize security-relevant events from heterogeneous sources
-- - Support real-time dashboards and alerting
-- - Enable historical analysis and forensics
-- - Reduce query complexity for security use cases
-- - Facilitate integration with external SIEMs or alerting systems
--

CREATE MATERIALIZED VIEW btrace_analytics.security_events AS

-- Failed Login Attempts
SELECT
    'failed_login'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    COALESCE(l.attributes->> 'user_id', '<unknown>') AS user_id,
    'Failed login attempt'::TEXT AS description,
    'WARN'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'client_ip', l.attributes->>'http.client_ip',
        'user_agent', l.attributes->>'http.user_agent',
        'service', l.service_name
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
WHERE (l.message ILIKE '%failed login%'
   OR l.message ILIKE '%invalid credentials%'
   OR l.message ILIKE '%authentication failed%')
  AND l.log_level IN ('WARN', 'ERROR')

UNION ALL

-- PII Exposure in Logs
SELECT
    'pii_exposure'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'user_id' AS user_id,
    'Potential PII exposure in log message'::TEXT AS description,
    'CRITICAL'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'pattern_found', 
        CASE 
            WHEN l.message ~* '\d{3}-\d{2}-\d{4}' THEN 'SSN'
            WHEN l.message ~* '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' THEN 'Email'
            WHEN l.message ~* '\b(?:\d[ -]*?){13,16}\b' THEN 'Credit Card'
            ELSE 'Unknown'
        END,
        'message_snippet', left(l.message, 200)
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
WHERE (l.message ~* '\d{3}-\d{2}-\d{4}'          -- SSN
    OR l.message ~* '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'  -- Email
    OR l.message ~* '\b(?:\d[ -]*?){13,16}\b')   -- Credit Card
  AND l.timestamp >= NOW() - INTERVAL '30 days'

UNION ALL

-- High Severity Incidents (P1/P2)
SELECT
    'incident_p1_p2'::VARCHAR(50) AS event_type,
    'incident'::VARCHAR(20) AS source_type,
    NULL::UUID AS trace_id,
    i.incident_id AS source_id,
    i.start_time AS event_time,
    s.service_name,
    NULL::VARCHAR AS host_name,
    NULL::TEXT AS user_id,
    i.title AS description,
    i.severity AS severity,
    jsonb_build_object(
        'impact', i.impact,
        'is_customer_impacting', i.is_customer_impacting,
        'detected_at', i.detected_at,
        'status', i.status
    ) AS metadata,
    i.environment_id,
    i.created_at

FROM btrace_core.incidents i
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
WHERE i.severity IN ('P1', 'P2')

UNION ALL

-- Suspicious User Agents (e.g., sqlmap, burp)
SELECT
    'suspicious_ua'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'user_id' AS user_id,
    'Request from suspicious tool (e.g., sqlmap, burp)'::TEXT AS description,
    'ALERT'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'user_agent', l.attributes->>'http.user_agent',
        'url', l.attributes->>'http.url',
        'method', l.attributes->>'http.method'
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
WHERE (l.attributes->>'http.user_agent') ILIKE '%sqlmap%'
   OR (l.attributes->>'http.user_agent') ILIKE '%nmap%'
   OR (l.attributes->>'http.user_agent') ILIKE '%burp%'
   OR (l.attributes->>'http.user_agent') ILIKE '%hydra%'
   OR (l.attributes->>'http.user_agent') ILIKE '%metasploit%'

UNION ALL

-- Admin Privilege Escalation
SELECT
    'privilege_escalation'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'user_id' AS user_id,
    'User granted admin privileges'::TEXT AS description,
    'CRITICAL'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'target_user', l.attributes->>'target_user',
        'granted_by', l.attributes->>'granted_by',
        'role', l.attributes->>'role'
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
WHERE (l.message ILIKE '%role updated%admin%'
   OR l.message ILIKE '%privilege escalation%'
   OR l.message ILIKE '%grant admin%')

UNION ALL

-- Unauthorized Access Attempts (from logs)
SELECT
    'unauthorized_access'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'user_id' AS user_id,
    COALESCE(l.message, 'Unauthorized access attempt') AS description,
    'ALERT'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'path', l.attributes->>'http.url',
        'method', l.attributes->>'http.method',
        'status_code', l.attributes->>'http.status_code'
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
WHERE (l.message ILIKE '%unauthorized%'
   OR l.message ILIKE '%forbidden%'
   OR l.message ILIKE '%access denied%')
  AND l.log_level IN ('WARN', 'ERROR')

UNION ALL

-- Service Account Usage in Production
SELECT
    'service_account_prod'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'service_account' AS user_id,
    'Service account activity in production'::TEXT AS description,
    'INFO'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'service_account', l.attributes->>'service_account',
        'action', l.attributes->>'action',
        'client_ip', l.attributes->>'http.client_ip'
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
JOIN btrace_core.environments e ON l.environment_id = e.environment_id
WHERE (l.message ILIKE '%service account%'
   OR l.attributes ? 'service_account')
  AND e.environment_name = 'production'

UNION ALL

-- Configuration Changes in Production
SELECT
    'config_change'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    l.trace_id,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    l.attributes->> 'user_id' AS user_id,
    'Production configuration updated'::TEXT AS description,
    'INFO'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'change', left(l.message, 200),
        'changed_by', l.attributes->>'user_id'
    ) AS metadata,
    l.environment_id,
    l.created_at

FROM btrace_core.logs l
JOIN btrace_core.environments e ON l.environment_id = e.environment_id
WHERE (l.message ILIKE '%config updated%'
   OR l.message ILIKE '%feature flag%'
   OR l.message ILIKE '%toggle enabled%')
  AND e.environment_name = 'production'

UNION ALL

-- Brute Force Attack Detection (by IP)
SELECT
    'brute_force_attack'::VARCHAR(50) AS event_type,
    'log'::VARCHAR(20) AS source_type,
    NULL::UUID AS trace_id,
    NULL::UUID AS source_id,
    MIN(l.timestamp) AS event_time,
    l.service_name,
    NULL::VARCHAR AS host_name,
    NULL::TEXT AS user_id,
    format('Brute force attack from %s (%s attempts)', l.attributes->>'http.client_ip', COUNT(*)) AS description,
    'CRITICAL'::VARCHAR(20) AS severity,
    jsonb_build_object(
        'client_ip', l.attributes->>'http.client_ip',
        'attempt_count', COUNT(*),
        'service', l.service_name
    ) AS metadata,
    l.environment_id,
    NOW() AS created_at

FROM btrace_core.logs l
WHERE (l.message ILIKE '%failed login%' OR l.message ILIKE '%invalid credentials%')
  AND l.timestamp >= NOW() - INTERVAL '15 minutes'
GROUP BY l.service_name, l.attributes->>'http.client_ip', l.environment_id
HAVING COUNT(*) > 10;

-- Fast: "Show recent security events"
CREATE INDEX idx_security_events_time 
ON btrace_analytics.security_events (event_time DESC);

-- Filter by event_type
CREATE INDEX idx_security_events_type 
ON btrace_analytics.security_events (event_type);

-- Filter by severity
CREATE INDEX idx_security_events_severity 
ON btrace_analytics.security_events (severity);

-- Filter by user_id
CREATE INDEX idx_security_events_user_id 
ON btrace_analytics.security_events (user_id) 
WHERE user_id IS NOT NULL AND user_id != '<unknown>';

-- Filter by environment
CREATE INDEX idx_security_events_environment 
ON btrace_analytics.security_events (environment_id);

-- Covering index for dashboards
CREATE INDEX idx_security_events_covering 
ON btrace_analytics.security_events (event_time DESC, severity)
INCLUDE (event_type, description, service_name, metadata);

-- Manual refresh
REFRESH MATERIALIZED VIEW btrace_analytics.security_events;

-- -- Schedule with pg_cron (run hourly)
-- SELECT cron.schedule(
--     'refresh-security-events', 
--     '0 * * * *', 
--     'REFRESH MATERIALIZED VIEW btrace_analytics.security_events'
-- );

SELECT 
    event_type, 
    description, 
    user_id, 
    service_name, 
    event_time, 
    severity 
FROM btrace_analytics.security_events
ORDER BY event_time DESC
LIMIT 100;
------================
--
-- BUSINESS CASE:
-- The `privileged_access_monitor` view consolidates all signals of elevated or administrative access
-- from logs and incidents into a single real-time stream. This spans-free version avoids dependency on 
-- the `spans` table for early deployment and schema safety.
-- It enables monitoring, alerting, and auditing of high-risk operations.
--
-- PURPOSE:
-- - Centralize detection of admin, root, and elevated privilege usage
-- - Support real-time dashboards and alerting
-- - Enable forensic investigation of privilege misuse
-- - Facilitate compliance with access control policies
-- - Integrate with SIEMs or notification systems
--

CREATE OR REPLACE VIEW btrace_analytics.privileged_access_monitor AS

-- Privileged Access from Logs
SELECT
    'log'::VARCHAR(20) AS source_type,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    COALESCE(l.attributes->>'user_id', l.attributes->>'username', '<unknown>') AS user_id,
    CASE
        WHEN l.message ILIKE '%admin%' THEN 'admin_access'
        WHEN l.message ILIKE '%root%' THEN 'root_access'
        WHEN l.message ILIKE '%sudo%' THEN 'sudo_usage'
        WHEN l.message ILIKE '%elevated%' THEN 'privilege_elevation'
        WHEN l.message ILIKE '%grant role%' THEN 'role_grant'
        WHEN l.message ILIKE '%disable user%' THEN 'user_disable'
        WHEN l.message ILIKE '%delete user%' THEN 'user_deletion'
        ELSE 'privileged_operation'
    END AS access_type,
    l.log_level,
    l.message AS description,
    jsonb_build_object(
        'client_ip', l.attributes->>'http.client_ip',
        'user_agent', l.attributes->>'http.user_agent',
        'service', l.service_name,
        'environment', e.environment_name,
        'trace_id', l.trace_id
    ) AS metadata,
    e.environment_name AS environment,
    l.trace_id,
    NULL::UUID AS span_id  -- Placeholder for future spans integration

FROM btrace_core.logs l
JOIN btrace_core.environments e ON l.environment_id = e.environment_id
WHERE (
    -- Admin/root/sudo keywords
    l.message ILIKE '%admin%'
    OR l.message ILIKE '%root%'
    OR l.message ILIKE '%sudo%'
    OR l.message ILIKE '%elevated privileges%'
    OR l.message ILIKE '%privilege escalation%'
    -- Role and access management
    OR l.message ILIKE '%grant role%'
    OR l.message ILIKE '%revoke role%'
    OR l.message ILIKE '%disable user%'
    OR l.message ILIKE '%delete user%'
    OR l.message ILIKE '%change password for%'
    -- Sensitive operations
    OR l.message ILIKE '%bypass auth%'
    OR l.message ILIKE '%override permission%'
    -- Attribute-based detection
    OR l.attributes @> '{"auth.level": "admin"}'
    OR l.attributes @> '{"role": "admin"}'
    OR l.attributes @> '{"privilege": "elevated"}'
    OR l.attributes ? 'is_superuser'
)
  AND l.timestamp >= NOW() - INTERVAL '7 days'

UNION ALL

-- Privileged Actions from Incidents
SELECT
    'incident'::VARCHAR(20) AS source_type,
    i.incident_id AS source_id,
    i.start_time AS event_time,
    s.service_name,
    NULL::VARCHAR AS host_name,
    COALESCE(i.created_by::TEXT, '<unknown>') AS user_id,
    'incident_involving_privileged_service'::VARCHAR(50) AS access_type,
    i.severity AS log_level,
    i.title AS description,
    jsonb_build_object(
        'impact', i.impact,
        'is_customer_impacting', i.is_customer_impacting,
        'status', i.status,
        'severity', i.severity,
        'detected_at', i.detected_at,
        'environment', e.environment_name
    ) AS metadata,
    e.environment_name AS environment,
    NULL::UUID AS trace_id,
    NULL::UUID AS span_id

FROM btrace_core.incidents i
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
JOIN btrace_core.environments e ON i.environment_id = e.environment_id
WHERE 
    -- High severity incidents in critical services
    i.severity IN ('P1', 'P2')
    AND i.start_time >= NOW() - INTERVAL '7 days'
    AND (
        s.service_name ILIKE '%admin%'
        OR s.service_name ILIKE '%auth%'
        OR s.service_name ILIKE '%user%'
        OR s.service_name ILIKE '%identity%'
        OR s.lifecycle_stage = 'production'
    );


--show all recent priveleged access 
SELECT 
    event_time, 
    user_id, 
    service_name, 
    access_type, 
    description, 
    environment 
FROM btrace_analytics.privileged_access_monitor
ORDER BY event_time DESC
LIMIT 100;



SELECT 
    description, 
    user_id, 
    event_time, 
    metadata->>'severity' AS severity, 
    environment 
FROM btrace_analytics.privileged_access_monitor
WHERE source_type = 'incident'
  AND metadata ? 'severity'  -- Ensures key exists
ORDER BY event_time DESC;


--  Privileged Actions from Incidents
SELECT
    'incident'::VARCHAR(20) AS source_type,
    i.incident_id AS source_id,
    i.start_time AS event_time,
    s.service_name,
    NULL::VARCHAR AS host_name,
    COALESCE(i.created_by::TEXT, '<unknown>') AS user_id,
    'incident_involving_privileged_service'::VARCHAR(50) AS access_type,
    i.severity AS log_level,
    i.title AS description,
    jsonb_build_object(
        'impact', i.impact,
        'is_customer_impacting', i.is_customer_impacting,
        'status', i.status,
        'detected_at', i.detected_at,
        'environment', e.environment_name
    ) AS metadata,
    e.environment_name AS environment,
    NULL::UUID AS trace_id,
    NULL::UUID AS span_id,
    i.severity  -- Add as top-level column

FROM btrace_core.incidents i
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
JOIN btrace_core.environments e ON i.environment_id = e.environment_id
WHERE 
    i.severity IN ('P1', 'P2')
    AND i.start_time >= NOW() - INTERVAL '7 days'
    AND (
        s.service_name ILIKE '%admin%'
        OR s.service_name ILIKE '%auth%'
        OR s.service_name ILIKE '%user%'
        OR s.service_name ILIKE '%identity%'
        OR s.lifecycle_stage = 'production'
    );


-- find all admin-related log events 
SELECT user_id, service_name, description, event_time
FROM btrace_analytics.privileged_access_monitor
WHERE access_type = 'admin_access'
ORDER BY event_time DESC;


--
-- BUSINESS CASE:
-- The `privileged_access_monitor_v2` view consolidates all signals of elevated or administrative access
-- from logs and incidents into a single real-time stream. This spans-free version avoids dependency on 
-- the `spans` table for early deployment and schema safety.
-- It enables monitoring, alerting, and auditing of high-risk operations.
--
-- PURPOSE:
-- - Centralize detection of admin, root, and elevated privilege usage
-- - Support real-time dashboards and alerting
-- - Enable forensic investigation of privilege misuse
-- - Facilitate compliance with access control policies
-- - Integrate with SIEMs or notification systems
--

CREATE OR REPLACE VIEW btrace_analytics.privileged_access_monitor_v2 AS

-- Privileged Access from Logs
SELECT
    'log'::VARCHAR(20) AS source_type,
    l.log_id AS source_id,
    l.timestamp AS event_time,
    l.service_name,
    l.host_name,
    COALESCE(l.attributes->>'user_id', l.attributes->>'username', '<unknown>') AS user_id,
    CASE
        WHEN l.message ILIKE '%admin%' THEN 'admin_access'
        WHEN l.message ILIKE '%root%' THEN 'root_access'
        WHEN l.message ILIKE '%sudo%' THEN 'sudo_usage'
        WHEN l.message ILIKE '%elevated%' THEN 'privilege_elevation'
        WHEN l.message ILIKE '%grant role%' THEN 'role_grant'
        WHEN l.message ILIKE '%disable user%' THEN 'user_disable'
        WHEN l.message ILIKE '%delete user%' THEN 'user_deletion'
        WHEN l.message ILIKE '%bypass auth%' THEN 'auth_bypass'
        WHEN l.message ILIKE '%override permission%' THEN 'permission_override'
        ELSE 'privileged_operation'
    END AS access_type,
    l.log_level,
    l.message AS description,
    jsonb_build_object(
        'client_ip', l.attributes->>'http.client_ip',
        'user_agent', l.attributes->>'http.user_agent',
        'service', l.service_name,
        'environment', e.environment_name,
        'trace_id', l.trace_id
    ) AS metadata,
    e.environment_name AS environment,
    l.trace_id,
    NULL::UUID AS span_id,
    NULL::VARCHAR AS severity  -- Not applicable for logs

FROM btrace_core.logs l
JOIN btrace_core.environments e ON l.environment_id = e.environment_id
WHERE (
    -- Admin/root/sudo keywords
    l.message ILIKE '%admin%'
    OR l.message ILIKE '%root%'
    OR l.message ILIKE '%sudo%'
    OR l.message ILIKE '%elevated privileges%'
    OR l.message ILIKE '%privilege escalation%'
    -- Role and access management
    OR l.message ILIKE '%grant role%'
    OR l.message ILIKE '%revoke role%'
    OR l.message ILIKE '%disable user%'
    OR l.message ILIKE '%delete user%'
    OR l.message ILIKE '%change password for%'
    OR l.message ILIKE '%reset password%'
    -- Sensitive operations
    OR l.message ILIKE '%bypass auth%'
    OR l.message ILIKE '%override permission%'
    OR l.message ILIKE '%access as%'
    -- Attribute-based detection
    OR l.attributes @> '{"auth.level": "admin"}'
    OR l.attributes @> '{"role": "admin"}'
    OR l.attributes @> '{"privilege": "elevated"}'
    OR l.attributes ? 'is_superuser'
)
  AND l.timestamp >= NOW() - INTERVAL '7 days'

UNION ALL

-- Privileged Actions from Incidents
SELECT
    'incident'::VARCHAR(20) AS source_type,
    i.incident_id AS source_id,
    i.start_time AS event_time,
    s.service_name,
    NULL::VARCHAR AS host_name,
    COALESCE(i.created_by::TEXT, '<unknown>') AS user_id,
    'incident_involving_privileged_service'::VARCHAR(50) AS access_type,
    i.severity AS log_level,
    i.title AS description,
    jsonb_build_object(
        'impact', i.impact,
        'is_customer_impacting', i.is_customer_impacting,
        'status', i.status,
        'detected_at', i.detected_at,
        'environment', e.environment_name
    ) AS metadata,
    e.environment_name AS environment,
    NULL::UUID AS trace_id,
    NULL::UUID AS span_id,
    i.severity  -- Top-level column for easy querying

FROM btrace_core.incidents i
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
JOIN btrace_core.environments e ON i.environment_id = e.environment_id
WHERE 
    i.severity IN ('P1', 'P2')
    AND i.start_time >= NOW() - INTERVAL '7 days'
    AND (
        s.service_name ILIKE '%admin%'
        OR s.service_name ILIKE '%auth%'
        OR s.service_name ILIKE '%user%'
        OR s.service_name ILIKE '%identity%'
        OR s.service_name ILIKE '%iam%'
        OR s.lifecycle_stage = 'production'
    );


--show all P1/P2 incidents with severity 
SELECT event_time, description, user_id, severity, environment
FROM btrace_analytics.privileged_access_monitor_v2
WHERE source_type = 'incident'
  AND severity IN ('P1', 'P2')
ORDER BY event_time DESC;

--show all admin-related log events 
SELECT event_time, user_id, service_name, description
FROM btrace_analytics.privileged_access_monitor_v2
WHERE access_type = 'admin_access'
ORDER BY event_time DESC;

--count privileged access by user
SELECT user_id, COUNT(*) AS event_count
FROM btrace_analytics.privileged_access_monitor_v2
WHERE user_id != '<unknown>'
GROUP BY user_id
ORDER BY event_count DESC;


-- For logs with privileged keywords
CREATE INDEX IF NOT EXISTS idx_logs_privileged_v2 
ON btrace_core.logs (timestamp DESC) 
WHERE message ILIKE '%admin%' OR message ILIKE '%sudo%' OR attributes ? 'is_superuser';

-- For high-severity incidents
CREATE INDEX IF NOT EXISTS idx_incidents_severity_v2 
ON btrace_core.incidents (severity, start_time DESC)
WHERE severity IN ('P1', 'P2');
------================
-- Reports: Scheduled or ad-hoc reports
--
-- BUSINESS CASE:
-- The `reports` table defines scheduled or on-demand reports that summarize key observability data
-- (e.g., incident trends, performance metrics, compliance status). It enables automated delivery to stakeholders,
-- supports executive reviews, and ensures consistent communication of system health.
-- This is essential for SRE teams, leadership, and auditors.
--
-- PURPOSE:
-- - Define and manage recurring or ad-hoc reports
-- - Support delivery via email, Slack, or export
-- - Track execution history and scheduling
-- - Enable self-service report creation
-- - Integrate with dashboards, compliance workflows, and governance
--

CREATE TABLE btrace_analytics.reports (
    report_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name     VARCHAR(100) NOT NULL,
    description     TEXT,
    report_type     VARCHAR(50) NOT NULL,
    report_config   JSONB NOT NULL,
    schedule        VARCHAR(100),  -- e.g., 'daily', 'weekly', '0 0 * * 1', NULL for ad-hoc
    last_run_at     TIMESTAMP WITH TIME ZONE,
    next_run_at     TIMESTAMP WITH TIME ZONE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    recipients      TEXT,  -- Comma-separated emails or user IDs
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE,
    created_by      UUID,
    updated_by      UUID,

    -- Enforce unique report name
    CONSTRAINT uq_report_name 
        UNIQUE (report_name),

    -- Validate report_type
    CONSTRAINT chk_report_type 
        CHECK (report_type IN (
            'incident_summary', 'performance_trends', 'slo_burn_rate', 'compliance_audit',
            'oncall_summary', 'error_budget', 'service_health', 'security_events',
            'custom', 'executive_dashboard'
        )),

    -- Ensure next_run_at >= last_run_at (if both set)
    CONSTRAINT chk_next_after_last 
        CHECK (next_run_at IS NULL OR last_run_at IS NULL OR next_run_at >= last_run_at),

    -- Foreign Keys
    CONSTRAINT fk_reports_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_reports_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Find reports by name"
CREATE INDEX idx_reports_name ON btrace_analytics.reports (report_name);

-- Filter by active status and schedule
CREATE INDEX idx_reports_is_active_schedule 
ON btrace_analytics.reports (is_active, schedule) 
WHERE is_active = TRUE AND schedule IS NOT NULL;

-- Find reports due to run
CREATE INDEX idx_reports_next_run_at 
ON btrace_analytics.reports (next_run_at) 
WHERE is_active = TRUE AND schedule IS NOT NULL;

-- Who created/updated?
CREATE INDEX idx_reports_created_by 
ON btrace_analytics.reports (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_reports_updated_by 
ON btrace_analytics.reports (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for report dashboard
CREATE INDEX idx_reports_covering 
ON btrace_analytics.reports (is_active, next_run_at)
INCLUDE (report_name, report_type, last_run_at, recipients, created_at);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_reports_updated_at
    BEFORE UPDATE ON btrace_analytics.reports
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
	
COMMENT ON TABLE btrace_analytics.reports IS 
'Defines scheduled or on-demand reports that summarize observability data (incidents, performance, SLOs, etc.). Used for automated delivery to teams, leadership, and auditors. Supports compliance, reviews, and operational transparency.';

COMMENT ON COLUMN btrace_analytics.reports.report_id IS 
'Unique identifier for the report. Used in APIs, scheduling, and audit logs.';

COMMENT ON COLUMN btrace_analytics.reports.report_name IS 
'Human-readable name (e.g., "Weekly SRE Summary"). Must be unique. Used in UI and notifications.';

COMMENT ON COLUMN btrace_analytics.reports.description IS 
'Short summary of the report''s purpose, audience, and key metrics. Helps users understand its value.';

COMMENT ON COLUMN btrace_analytics.reports.report_type IS 
'Category of report: incident_summary, performance_trends, slo_burn_rate, compliance_audit, etc. Drives template and delivery logic.';

COMMENT ON COLUMN btrace_analytics.reports.report_config IS 
'JSON structure defining the content: included dashboards, query filters, time range, visualizations. Flexible to support multiple report types.';

COMMENT ON COLUMN btrace_analytics.reports.schedule IS 
'Frequency of execution: ''daily'', ''weekly'', or cron expression (e.g., ''0 0 * * 1''). NULL for ad-hoc reports.';

COMMENT ON COLUMN btrace_analytics.reports.last_run_at IS 
'When the report was last executed. NULL if never run.';

COMMENT ON COLUMN btrace_analytics.reports.next_run_at IS 
'When the report is scheduled to run next. NULL for ad-hoc or inactive reports.';

COMMENT ON COLUMN btrace_analytics.reports.is_active IS 
'Indicates whether the report should be automatically executed. Set to FALSE to pause without deletion.';

COMMENT ON COLUMN btrace_analytics.reports.recipients IS 
'Comma-separated list of email addresses or user IDs who should receive the report. Supports both individuals and groups.';

COMMENT ON COLUMN btrace_analytics.reports.created_at IS 
'When the report was created.';

COMMENT ON COLUMN btrace_analytics.reports.updated_at IS 
'Automatically updated when the report is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_analytics.reports.created_by IS 
'Optional: user who created the report. NULL if auto-generated or imported.';

COMMENT ON COLUMN btrace_analytics.reports.updated_by IS 
'Optional: last user to edit the report. NULL if untracked.';


--list all active scheduled reports
SELECT report_name, report_type, schedule, next_run_at, recipients
FROM btrace_analytics.reports
WHERE is_active = TRUE AND schedule IS NOT NULL
ORDER BY next_run_at;


-- find reports due to run now 
SELECT report_name, report_config, recipients
FROM btrace_analytics.reports
WHERE is_active = TRUE
  AND schedule IS NOT NULL
  AND next_run_at <= NOW();
  
--generate compliance report 
SELECT report_config
FROM btrace_analytics.reports
WHERE report_type = 'compliance_audit'
  AND report_name = 'Monthly SOC2 Readiness Report';

---=========
-- KPI Definitions: Key performance indicators
--
-- BUSINESS CASE:
-- The `kpi_definitions` table defines Key Performance Indicators (KPIs) that measure business, operational, and reliability performance.
-- It enables objective tracking of goals (e.g., "MTTR < 30min", "SLO Compliance > 99.9%") and supports executive reporting, SRE reviews, and team accountability.
-- This is essential for aligning engineering work with business outcomes.
--
-- PURPOSE:
-- - Define and standardize KPIs across teams and systems
-- - Support automated calculation and dashboarding
-- - Enable goal-setting and performance reviews
-- - Facilitate compliance and audit of operational health
-- - Integrate with alerting and reporting workflows
--

CREATE TABLE btrace_analytics.kpi_definitions (
    kpi_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_name          VARCHAR(100) NOT NULL,
    description       TEXT,
    calculation       TEXT NOT NULL,
    unit              VARCHAR(20),
    target_value      DOUBLE PRECISION,
    target_direction  VARCHAR(10) NOT NULL,
    is_system_kpi     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE,
    created_by        UUID,
    updated_by        UUID,

    -- Enforce unique KPI name
    CONSTRAINT uq_kpi_name 
        UNIQUE (kpi_name),

    -- Validate target_direction
    CONSTRAINT chk_target_direction 
        CHECK (target_direction IN ('higher', 'lower')),

    -- Optional: restrict common units
    CONSTRAINT chk_unit 
        CHECK (unit IN ('seconds', 'ms', '%', 'count', 'requests/sec', 'errors/hour', 'dollar', 'pt', 'unit')),

    -- Ensure target_value is non-negative if applicable
    CONSTRAINT chk_target_value_non_negative 
        CHECK (target_value IS NULL OR target_value >= 0),

    -- Foreign Keys
    CONSTRAINT fk_kpi_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_kpi_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Find KPIs by name"
CREATE INDEX idx_kpi_definitions_name ON btrace_analytics.kpi_definitions (kpi_name);

-- Filter by system vs. custom KPIs
CREATE INDEX idx_kpi_definitions_system 
ON btrace_analytics.kpi_definitions (is_system_kpi);

-- Find all KPIs where higher is better
CREATE INDEX idx_kpi_definitions_direction 
ON btrace_analytics.kpi_definitions (target_direction);

-- Who created/updated?
CREATE INDEX idx_kpi_definitions_created_by 
ON btrace_analytics.kpi_definitions (created_by) 
WHERE created_by IS NOT NULL;

CREATE INDEX idx_kpi_definitions_updated_by 
ON btrace_analytics.kpi_definitions (updated_by) 
WHERE updated_by IS NOT NULL;

-- Covering index for KPI dashboard
CREATE INDEX idx_kpi_definitions_covering 
ON btrace_analytics.kpi_definitions (kpi_name)
INCLUDE (description, unit, target_value, target_direction, is_system_kpi, created_at);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_kpi_definitions_updated_at
    BEFORE UPDATE ON btrace_analytics.kpi_definitions
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.kpi_definitions IS 
'Defines Key Performance Indicators (KPIs) that measure operational, reliability, and business performance (e.g., MTTR, error rate, SLO compliance). Used for dashboards, executive reporting, and team accountability.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.kpi_id IS 
'Unique identifier for the KPI. Used in APIs, references, and integrations.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.kpi_name IS 
'Human-readable name (e.g., "Mean Time to Resolve", "P95 Latency"). Must be unique. Used in UIs and reports.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.description IS 
'Description of what the KPI measures, why it matters, and how it is calculated. Critical for onboarding and alignment.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.calculation IS 
'The logic or SQL-like expression used to compute the KPI (e.g., "SUM(errors) / SUM(requests)"). Should be executable or interpretable by the analytics engine.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.unit IS 
'Standardized unit of measurement (e.g., "seconds", "ms", "%", "count"). Ensures consistent visualization and comparison.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.target_value IS 
'The desired value or threshold for the KPI (e.g., 30 for "MTTR < 30min"). NULL if no numeric target.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.target_direction IS 
'Indicates whether higher or lower values are better: ''higher'' (e.g., uptime) or ''lower'' (e.g., latency, error count). Drives visualization and alerting logic.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.is_system_kpi IS 
'Indicates whether this KPI is defined by the platform (e.g., SLO compliance) or by a team/user. System KPIs are immutable and standardized.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.created_at IS 
'When the KPI was defined.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.updated_at IS 
'Automatically updated when the KPI definition is modified. Used for audit trail.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.created_by IS 
'Optional: user who defined the KPI. NULL if seeded or system-defined.';

COMMENT ON COLUMN btrace_analytics.kpi_definitions.updated_by IS 
'Optional: last user to edit the KPI. NULL if untracked.';


-- -- Apply to all relevant tables
-- ALTER TABLE btrace_core.alerts 
-- ALTER COLUMN status TYPE VARCHAR(50);

-- DROP MATERIALIZED VIEW btrace_analytics.security_events;
-- DROP VIEW IF EXISTS btrace_analytics.privileged_access_monitor;

-- ALTER TABLE btrace_core.traces 
-- ALTER COLUMN status_code TYPE VARCHAR(50);

-- -- Example: Increase `status` from VARCHAR(20) to VARCHAR(50)
-- ALTER TABLE btrace_core.incidents 
-- ALTER COLUMN status TYPE VARCHAR(100);


-- Drop the old constraint
ALTER TABLE btrace_analytics.kpi_definitions 
DROP CONSTRAINT chk_unit;

-- Add the improved constraint with common abbreviations
ALTER TABLE btrace_analytics.kpi_definitions 
ADD CONSTRAINT chk_unit 
    CHECK (unit IN (
        'seconds', 'secs', 's',
        'minutes', 'mins', 'min',
        'hours', 'hrs', 'h',
        'days', 'd',
        'ms', 'milliseconds',
        '%', 'percent',
        'count', 'number', 'n',
        'req/sec', 'req/s', 'requests/sec',
        'req/min', 'req/m',
        'errors/hour', 'errors/hr',
        'dollars', '$', 'usd',
        'users', 'customers', 'clients',
        'tickets', 'incidents', 'alerts',
        'ratio', 'score', 'points', 'pt',
        'boolean', 'bool',
        'unit'
    ));
	
ALTER TABLE btrace_analytics.kpi_definitions 
DROP CONSTRAINT chk_unit;

ALTER TABLE btrace_analytics.kpi_definitions 
ADD CONSTRAINT chk_unit 
    CHECK (unit IS NOT NULL AND TRIM(unit) != '' AND LENGTH(unit) <= 20);

INSERT INTO btrace_analytics.kpi_definitions (
    kpi_name,
    description,
    calculation,
    unit,
    target_value,
    target_direction,
    is_system_kpi,
    created_by
)
VALUES
-- ===== SRE & RELIABILITY =====
('MTTR', 'Mean Time to Resolve incidents', 'SUM(downtime_duration) / COUNT(incidents)', 'mins', 30.0, 'lower', TRUE, NULL),
('MTBF', 'Mean Time Between Failures', 'SUM(time_between_incidents) / COUNT(incidents)', 'hrs', 168.0, 'higher', TRUE, NULL),
('MTTD', 'Mean Time to Detect incidents', 'AVG(EXTRACT(EPOCH FROM (start_time - detected_at)) / 60)', 'mins', 15.0, 'lower', TRUE, NULL),
('MTTA', 'Mean Time to Acknowledge', 'AVG(EXTRACT(EPOCH FROM (acknowledged_at - start_time)) / 60)', 'mins', 10.0, 'lower', TRUE, NULL),
('Incident Rate', 'Number of incidents per day', 'COUNT(incidents) / 7', 'inc/wk', 2.0, 'lower', TRUE, NULL),
('P1/P2 Incident Rate', 'Critical and major incidents per week', 'COUNT(incidents WHERE severity IN (''P1'', ''P2'')) / 1', 'inc/wk', 1.0, 'lower', TRUE, NULL),
('Error Budget Remaining', 'Percentage of error budget left in current window', '1 - (error_minutes_consumed / allowed_error_minutes)', '%', 95.0, 'higher', TRUE, NULL),
('SLO Compliance Rate', 'Percentage of services meeting their SLOs', 'COUNT(services WHERE error_rate <= target) / COUNT(services)', '%', 99.0, 'higher', TRUE, NULL),
('Service Uptime', 'Uptime percentage over 28 days', 'AVG(CASE WHEN status = ''UP'' THEN 1 ELSE 0 END) * 100', '%', 99.95, 'higher', TRUE, NULL),
('Availability', 'System availability over 7 days', 'SUM(successful_requests) / SUM(total_requests) * 100', '%', 99.9, 'higher', TRUE, NULL),

-- ===== PERFORMANCE =====
('P95 Latency', '95th percentile request latency', 'PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms)', 'ms', 200.0, 'lower', TRUE, NULL),
('P99 Latency', '99th percentile request latency', 'PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms)', 'ms', 500.0, 'lower', TRUE, NULL),
('P999 Latency', '99.9th percentile request latency', 'PERCENTILE_CONT(0.999) WITHIN GROUP (ORDER BY duration_ms)', 'ms', 1000.0, 'lower', TRUE, NULL),
('Average Latency', 'Mean request latency', 'AVG(duration_ms)', 'ms', 100.0, 'lower', TRUE, NULL),
('Throughput', 'Requests per second', 'COUNT(requests) / time_window_seconds', 'req/s', 1000.0, 'higher', TRUE, NULL),
('Request Rate', 'Number of requests per minute', 'COUNT(*) FILTER (WHERE timestamp > NOW() - INTERVAL ''1 minute'')', 'req/m', 500.0, 'higher', TRUE, NULL),
('Error Rate', 'Percentage of failed requests', 'COUNT(errors) / COUNT(total) * 100', '%', 0.5, 'lower', TRUE, NULL),
('Retry Rate', 'Percentage of requests that required retry', 'COUNT(retries) / COUNT(total_requests) * 100', '%', 2.0, 'lower', TRUE, NULL),
('Timeout Rate', 'Percentage of requests ending in timeout', 'COUNT(timeouts) / COUNT(total) * 100', '%', 1.0, 'lower', TRUE, NULL),
('Cache Hit Ratio', 'Percentage of cache hits', 'GETS - MISSES / GETS * 100', '%', 90.0, 'higher', TRUE, NULL),

-- ===== INCIDENT MANAGEMENT =====
('Incident Response Time', 'Time from detection to assignment', 'AVG(EXTRACT(EPOCH FROM (assigned_at - detected_at)) / 60)', 'mins', 5.0, 'lower', TRUE, NULL),
('Incident Resolution Time', 'Time from start to resolution', 'AVG(EXTRACT(EPOCH FROM (resolved_at - start_time)) / 60)', 'mins', 30.0, 'lower', TRUE, NULL),
('On-Call Load', 'Number of incidents per on-call shift', 'COUNT(incidents) / COUNT(shifts)', 'inc/shift', 3.0, 'lower', TRUE, NULL),
('Auto-Resolved Incidents', 'Percentage of incidents resolved without human intervention', 'COUNT(auto_resolved) / COUNT(incidents) * 100', '%', 20.0, 'higher', TRUE, NULL),
('Incident Follow-Up Completion', 'Percentage of post-mortems with all action items completed', 'COUNT(completed) / COUNT(total) * 100', '%', 95.0, 'higher', TRUE, NULL),
('Post-Mortem Completion Rate', 'Percentage of incidents with a post-mortem', 'COUNT(with_postmortem) / COUNT(incidents) * 100', '%', 100.0, 'higher', TRUE, NULL),
('Action Item Completion Rate', 'Percentage of post-mortem action items completed on time', 'COUNT(completed_on_time) / COUNT(total_items) * 100', '%', 90.0, 'higher', TRUE, NULL),
('Incident Downtime', 'Total minutes of service unavailability', 'SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 60)', 'mins', 15.0, 'lower', TRUE, NULL),
('Customer-Impacting Incidents', 'Number of incidents affecting external users', 'COUNT(incidents WHERE is_customer_impacting = TRUE)', 'count', 0.0, 'lower', TRUE, NULL),
('Internal Incidents', 'Number of internal-only incidents', 'COUNT(incidents WHERE is_customer_impacting = FALSE)', 'count', 10.0, 'lower', TRUE, NULL),

-- ===== SECURITY & COMPLIANCE =====
('Security Incident Rate', 'Number of security-related incidents per month', 'COUNT(incidents WHERE tags @> ''{"category": "security"}'')', 'inc/mo', 0.0, 'lower', TRUE, NULL),
('PII Exposure Incidents', 'Number of incidents involving PII exposure', 'COUNT(incidents WHERE tags @> ''{"data": "pii"}'')', 'inc/mo', 0.0, 'lower', TRUE, NULL),
('Failed Login Attempts', 'Number of failed logins per hour', 'COUNT(logs WHERE message ILIKE ''%failed login%'')', 'cnt/hr', 10.0, 'lower', TRUE, NULL),
('Privileged Access Events', 'Number of admin/root/sudo actions per day', 'COUNT(logs WHERE message ILIKE ''%admin%'' OR message ILIKE ''%sudo%'')', 'cnt/d', 50.0, 'lower', TRUE, NULL),
('Compliance Audit Pass Rate', 'Percentage of compliance checks passed', 'COUNT(passed) / COUNT(total) * 100', '%', 100.0, 'higher', TRUE, NULL),
('Patch Compliance', 'Percentage of systems up to date with security patches', 'COUNT(patched) / COUNT(systems) * 100', '%', 95.0, 'higher', TRUE, NULL),
('Vulnerability Remediation Time', 'Mean time to fix critical vulnerabilities', 'AVG(EXTRACT(EPOCH FROM (fixed_at - reported_at)) / 86400)', 'days', 7.0, 'lower', TRUE, NULL),
('Unauthorized Access Attempts', 'Number of 403/401 errors per hour', 'COUNT(spans WHERE status_code = ''ERROR'' AND status_message ILIKE ''%forbidden%'')', 'cnt/hr', 5.0, 'lower', TRUE, NULL),
('Data Retention Compliance', 'Percentage of data deleted per retention policy', 'COUNT(deleted) / COUNT(expired) * 100', '%', 100.0, 'higher', TRUE, NULL),
('Audit Log Coverage', 'Percentage of services emitting audit logs', 'COUNT(with_audit_logs) / COUNT(services) * 100', '%', 100.0, 'higher', TRUE, NULL),

-- ===== BUSINESS & CUSTOMER IMPACT =====
('Customer Satisfaction (CSAT)', 'Post-incident customer satisfaction score', 'AVG(survey_score)', '/10', 8.5, 'higher', TRUE, NULL),
('Revenue Impact', 'Estimated revenue lost due to downtime', 'SUM(downtime_minutes * avg_revenue_per_minute)', '$', 0.0, 'lower', TRUE, NULL),
('User Impact', 'Number of users affected by incidents', 'SUM(affected_users)', 'users', 0.0, 'lower', TRUE, NULL),
('Feature Adoption Rate', 'Percentage of users using a new feature', 'COUNT(users_with_feature) / COUNT(total_users) * 100', '%', 70.0, 'higher', TRUE, NULL),
('Conversion Rate', 'Percentage of users completing key actions', 'COUNT(completed) / COUNT(started) * 100', '%', 85.0, 'higher', TRUE, NULL),
('Churn Rate', 'Percentage of users leaving due to reliability issues', 'COUNT(churned) / COUNT(active) * 100', '%', 1.0, 'lower', TRUE, NULL),
('NPS', 'Net Promoter Score from customer feedback', 'AVG(score)', '/10', 50.0, 'higher', TRUE, NULL),
('Support Ticket Volume', 'Number of support tickets per week', 'COUNT(tickets)', 'tix/wk', 10.0, 'lower', TRUE, NULL),
('Mean Time to Feedback', 'Time from incident to customer feedback', 'AVG(EXTRACT(EPOCH FROM (feedback_at - resolved_at)) / 3600)', 'hrs', 24.0, 'lower', TRUE, NULL),
('Service Level Indicator (SLI)', 'Technical measure of service health (e.g., success rate)', 'SUM(successful) / SUM(total) * 100', '%', 99.95, 'higher', TRUE, NULL),

-- ===== OBSERVABILITY HEALTH =====
('Trace Sampling Rate', 'Percentage of traces sampled', 'COUNT(sampled) / COUNT(total) * 100', '%', 100.0, 'higher', TRUE, NULL),
('Log Ingestion Rate', 'Number of logs ingested per second', 'COUNT(logs) / time_window_seconds', 'logs/s', 10000.0, 'higher', TRUE, NULL),
('Metric Emission Rate', 'Number of metrics emitted per minute', 'COUNT(metrics) / 60', 'metrics/m', 50000.0, 'higher', TRUE, NULL),
('Span Coverage', 'Percentage of services emitting spans', 'COUNT(with_spans) / COUNT(services) * 100', '%', 95.0, 'higher', TRUE, NULL),
('Alert Noise Ratio', 'Ratio of alerts to incidents', 'COUNT(alerts) / COUNT(incidents)', 'ratio', 5.0, 'lower', TRUE, NULL),
('Mean Time to Correlate', 'Time to link logs, traces, and metrics for an incident', 'AVG(EXTRACT(EPOCH FROM (correlated_at - start_time)) / 60)', 'mins', 2.0, 'lower', TRUE, NULL),
('Dashboard Usage', 'Number of unique users viewing dashboards per day', 'COUNT(DISTINCT user_id)', 'users/d', 50.0, 'higher', TRUE, NULL),
('Saved Query Usage', 'Number of saved queries executed per day', 'COUNT(*)', 'queries/d', 100.0, 'higher', TRUE, NULL),
('Alert False Positive Rate', 'Percentage of alerts not leading to incidents', 'COUNT(false_positives) / COUNT(alerts) * 100', '%', 10.0, 'lower', TRUE, NULL),
('System Resource Utilization', 'Average CPU, memory, disk usage', 'AVG(cpu), AVG(memory), AVG(disk)', '%', 75.0, 'lower', TRUE, NULL),

-- ===== TEAM & OPERATIONAL EFFICIENCY =====
('On-Call Satisfaction', 'Average on-call experience rating', 'AVG(rating)', '/10', 7.0, 'higher', TRUE, NULL),
('Incident Fatigue', 'Number of incidents per engineer per month', 'COUNT(incidents) / COUNT(engineers)', 'inc/eng/mo', 2.0, 'lower', TRUE, NULL),
('Change Failure Rate', 'Percentage of deployments causing incidents', 'COUNT(bad_deployments) / COUNT(total_deployments) * 100', '%', 5.0, 'lower', TRUE, NULL),
('Deployment Frequency', 'Number of deployments per day', 'COUNT(deployments)', 'deploys/d', 10.0, 'higher', TRUE, NULL),
('Lead Time for Changes', 'Time from commit to production', 'AVG(EXTRACT(EPOCH FROM (deployed_at - committed_at)) / 3600)', 'hrs', 2.0, 'lower', TRUE, NULL),
('Mean Time to Restore Service', 'Average time to restore after a failure', 'AVG(EXTRACT(EPOCH FROM (restored_at - failed_at)) / 60)', 'mins', 15.0, 'lower', TRUE, NULL),
('Automation Coverage', 'Percentage of operational tasks automated', 'COUNT(automated) / COUNT(tasks) * 100', '%', 80.0, 'higher', TRUE, NULL),
('Runbook Usage Rate', 'Number of runbooks consulted per incident', 'COUNT(runbook_accesses) / COUNT(incidents)', 'runbooks/inc', 1.0, 'higher', TRUE, NULL),
('Knowledge Base Articles Created', 'Number of new KB articles per month', 'COUNT(articles)', 'articles/mo', 5.0, 'higher', TRUE, NULL),
('Cross-Team Collaboration Rate', 'Number of incidents involving multiple teams', 'COUNT(cross_team) / COUNT(incidents) * 100', '%', 30.0, 'higher', TRUE, NULL),

-- ===== CUSTOM (Example) =====
('Custom KPI: API Latency Budget', 'Custom business rule for API performance', 'P99(duration_ms) < 300', 'bool', 1.0, 'higher', FALSE, NULL),
('Custom KPI: Checkout Success Rate', 'E-commerce specific: successful checkouts', 'COUNT(success) / COUNT(attempts) * 100', '%', 98.0, 'higher', FALSE, NULL);

--list all KPIs
SELECT kpi_name, description, unit, target_value, target_direction
FROM btrace_analytics.kpi_definitions
ORDER BY kpi_name;

---show KPIs where lower is better 
SELECT kpi_name, calculation, target_value
FROM btrace_analytics.kpi_definitions
WHERE target_direction = 'lower'
ORDER BY target_value;

--system defined KPIs
SELECT kpi_name, description
FROM btrace_analytics.kpi_definitions
WHERE is_system_kpi = TRUE;

--todo -- KPI values table, add KPI_Values to store time-series KPI measurements 
-- KPI dashboard view showing current vs target 
-- KPI alert notifications when KPIs deviate from target 
-- auto-generate monthly and biweekly, weekly KPI report for senior management for tracking 
-- ability to export to any BI 



-- KPI Measurements: Values of KPIs over time
--
-- BUSINESS CASE:
-- The `kpi_measurements` table stores time-series values of Key Performance Indicators (KPIs) 
-- (e.g., "MTTR = 28min on 2025-07-20"). It enables trend analysis, dashboards, alerting, 
-- and historical reporting. This is essential for tracking performance over time and proving progress.
--
-- PURPOSE:
-- - Store actual KPI values at regular intervals (minute, hour, day, week)
-- - Support dashboards showing current vs. target
-- - Enable alerting when KPIs deviate from targets
-- - Facilitate compliance and executive reporting
-- - Integrate with BI tools and data lakes
--

CREATE TABLE btrace_analytics.kpi_measurements (
    measurement_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id           UUID NOT NULL,
    measured_value   DOUBLE PRECISION NOT NULL,
    measurement_time TIMESTAMP WITH TIME ZONE NOT NULL,
    time_granularity VARCHAR(20) NOT NULL,
    context          JSONB,  -- Optional: metadata (e.g., "source: incidents_2025_07", "sample_size": 12)
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE,

    -- Enforce valid granularity
    CONSTRAINT chk_time_granularity 
        CHECK (time_granularity IN ('minute', 'hour', 'day', 'week', 'month', 'quarter', 'year')),

    -- Ensure measured_value is non-negative (if applicable)
    CONSTRAINT chk_measured_value_non_negative 
        CHECK (measured_value IS NULL OR measured_value >= 0),

    -- Prevent future measurement times (within reason)
    CONSTRAINT chk_measurement_time_not_future 
        CHECK (measurement_time <= NOW() + INTERVAL '1 hour'),

    -- Foreign Key
    CONSTRAINT fk_kpi_measurements_kpi_id 
        FOREIGN KEY (kpi_id) 
        REFERENCES btrace_analytics.kpi_definitions (kpi_id) 
        ON DELETE CASCADE
);

-- Fast: "Show all measurements for this KPI"
CREATE INDEX idx_kpi_measurements_kpi_id 
ON btrace_analytics.kpi_measurements (kpi_id, measurement_time DESC);

-- Filter by time (e.g., "show last 30 days")
CREATE INDEX idx_kpi_measurements_time 
ON btrace_analytics.kpi_measurements (measurement_time DESC);

-- Filter by granularity (e.g., only daily measurements)
CREATE INDEX idx_kpi_measurements_granularity 
ON btrace_analytics.kpi_measurements (time_granularity);

-- Covering index for KPI dashboard
CREATE INDEX idx_kpi_measurements_covering 
ON btrace_analytics.kpi_measurements (kpi_id, measurement_time DESC)
INCLUDE (measured_value, time_granularity, created_at);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_kpi_measurements_updated_at
    BEFORE UPDATE ON btrace_analytics.kpi_measurements
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.kpi_measurements IS 
'Time-series measurements of Key Performance Indicators (KPIs). Each row represents a recorded value of a KPI at a specific point in time. Enables trend analysis, dashboards, and historical reporting.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.measurement_id IS 
'Unique identifier for the measurement record. Used in APIs and audit logs.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.kpi_id IS 
'References the KPI being measured. Cascades delete if KPI is retired.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.measured_value IS 
'The numeric value of the KPI at the measurement time (e.g., 28.0 for MTTR in minutes).';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.measurement_time IS 
'When the KPI was measured (e.g., end of day, end of week). Used for time-series analysis and charting.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.time_granularity IS 
'The time interval over which the KPI was calculated: minute, hour, day, week, month, etc. Drives aggregation and visualization.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.context IS 
'Optional metadata about how the measurement was computed (e.g., sample size, data source, filters applied). Useful for audit and debugging.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.created_at IS 
'When the measurement was recorded in the system.';

COMMENT ON COLUMN btrace_analytics.kpi_measurements.updated_at IS 
'Automatically updated when the measurement is modified. Used for audit trail.';


--
-- BUSINESS CASE:
-- The `kpi_dashboard` view provides a real-time summary of all KPIs with their current value, target, and status.
-- It powers executive dashboards, SRE reviews, and automated reporting.
-- This is essential for visibility and accountability.
--
CREATE OR REPLACE VIEW btrace_analytics.kpi_dashboard AS
SELECT
    k.kpi_name,
    k.description,
    k.unit,
    k.target_value,
    k.target_direction,
    m.measured_value AS current_value,
    m.measurement_time,
    m.context,
    CASE
        WHEN k.target_direction = 'lower' AND (m.measured_value IS NULL OR m.measured_value <= k.target_value) THEN 'on_track'
        WHEN k.target_direction = 'higher' AND (m.measured_value IS NOT NULL AND m.measured_value >= k.target_value) THEN 'on_track'
        ELSE 'off_track'
    END AS status,
    ROUND(
        CASE
            WHEN k.target_direction = 'lower' THEN (k.target_value - COALESCE(m.measured_value, 0))
            WHEN k.target_direction = 'higher' THEN (COALESCE(m.measured_value, 0) - k.target_value)
            ELSE 0
        END :: NUMERIC, 2
    ) AS delta_from_target,
    k.is_system_kpi

FROM btrace_analytics.kpi_definitions k
LEFT JOIN LATERAL (
    SELECT measured_value, measurement_time, context
    FROM btrace_analytics.kpi_measurements
    WHERE kpi_id = k.kpi_id
    ORDER BY measurement_time DESC
    LIMIT 1
) m ON TRUE;
  

SELECT kpi_name, current_value, target_value, unit, status, delta_from_target
FROM btrace_analytics.kpi_dashboard
ORDER BY status, kpi_name;


--
-- BUSINESS CASE:
-- The `check_kpi_alerts` function identifies KPIs that are deviating from their targets.
-- It enables automated alerting via email, Slack, or ticket creation.
-- This is essential for proactive performance management.
--

CREATE OR REPLACE FUNCTION btrace_analytics.check_kpi_alerts()
RETURNS TABLE (
    kpi_name TEXT,
    current_value DOUBLE PRECISION,
    target_value DOUBLE PRECISION,
    unit VARCHAR(20),
    measurement_time TIMESTAMP WITH TIME ZONE,
    status TEXT,
    severity VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.kpi_name,
        m.measured_value AS current_value,
        d.target_value,
        d.unit,
        m.measurement_time,
        CASE
            WHEN d.target_direction = 'lower' AND (m.measured_value > d.target_value) THEN 'below_target'
            WHEN d.target_direction = 'higher' AND (m.measured_value < d.target_value) THEN 'below_target'
            ELSE 'on_target'
        END AS status,
        CASE
            WHEN (d.target_direction = 'lower' AND m.measured_value > d.target_value * 1.5)
              OR (d.target_direction = 'higher' AND m.measured_value < d.target_value * 0.5)
                THEN 'CRITICAL'
            WHEN (d.target_direction = 'lower' AND m.measured_value > d.target_value * 1.2)
              OR (d.target_direction = 'higher' AND m.measured_value < d.target_value * 0.8)
                THEN 'WARN'
            ELSE 'INFO'
        END AS severity
    FROM btrace_analytics.kpi_definitions d
    JOIN btrace_analytics.kpi_measurements m ON m.kpi_id = d.kpi_id
    WHERE m.measurement_time >= NOW() - INTERVAL '24 hours'
      AND d.is_active = TRUE
      AND d.target_value IS NOT NULL
    ORDER BY severity DESC, d.kpi_name;
END;
$$ LANGUAGE plpgsql;
  
  
CREATE OR REPLACE FUNCTION btrace_analytics.generate_weekly_kpi_report()
RETURNS TABLE (
    report_date DATE,
    kpi_name TEXT,
    avg_value DOUBLE PRECISION,
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    on_track_percentage DOUBLE PRECISION,
    target_value DOUBLE PRECISION,
    unit VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CURRENT_DATE AS report_date,
        k.kpi_name,
        AVG(m.measured_value) AS avg_value,
        MIN(m.measured_value) AS min_value,
        MAX(m.measured_value) AS max_value,
        AVG(CASE
            WHEN (k.target_direction = 'lower' AND m.measured_value <= k.target_value)
              OR (k.target_direction = 'higher' AND m.measured_value >= k.target_value)
                THEN 100.0 ELSE 0.0
        END) AS on_track_percentage,
        k.target_value,
        k.unit
    FROM btrace_analytics.kpi_definitions k
    JOIN btrace_analytics.kpi_measurements m ON m.kpi_id = k.kpi_id
    WHERE m.measurement_time >= DATE_TRUNC('week', NOW() - INTERVAL '1 week')
      AND m.measurement_time < DATE_TRUNC('week', NOW())
      AND k.is_active = TRUE
    GROUP BY k.kpi_name, k.target_value, k.target_direction, k.unit
    ORDER BY on_track_percentage ASC;
END;
$$ LANGUAGE plpgsql;
-- =============================================
-- SECTION 8: AUDIT LOGGING
-- =============================================
-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS btrace_audit;
-- Audit Logs: Records of significant system events
--
--
-- BUSINESS CASE:
-- The `audit_logs` table records significant system events (e.g., login, role change, SLO update) for security, compliance, and forensic analysis.
-- It enables tracking of user actions, detecting suspicious behavior, and proving compliance with regulations (e.g., SOC2, HIPAA).
-- This is essential for security teams, auditors, and SREs.
--
-- PURPOSE:
-- - Log all security-relevant actions (create, update, delete, login, permission change)
-- - Support forensic investigations and incident response
-- - Enable compliance reporting and audit trails
-- - Detect anomalous behavior (e.g., off-hours access, bulk deletions)
-- - Integrate with SIEMs, dashboards, and alerting systems
--

CREATE TABLE btrace_audit.audit_logs (
    log_id         UUID NOT NULL DEFAULT uuid_generate_v4(),
    event_time     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type     VARCHAR(100) NOT NULL,
    event_subtype  VARCHAR(100),
    user_id        UUID,
    user_name      VARCHAR(255),
    user_ip        INET,
    user_agent     TEXT,
    resource_type  VARCHAR(100),
    resource_id    VARCHAR(100),
    resource_name  VARCHAR(255),
    action         VARCHAR(50) NOT NULL,
    action_status  VARCHAR(20) NOT NULL,
    details        JSONB,

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_audit_logs 
        PRIMARY KEY (log_id, event_time),

    -- Enforce valid action
    CONSTRAINT chk_audit_action 
        CHECK (action IN ('create', 'read', 'update', 'delete', 'login', 'logout', 'grant', 'revoke', 'enable', 'disable')),

    -- Enforce valid action_status
    CONSTRAINT chk_audit_action_status 
        CHECK (action_status IN ('success', 'failure', 'pending')),

    -- Enforce valid event_type
    CONSTRAINT chk_audit_event_type 
        CHECK (event_type IN (
            'authentication', 'authorization', 'resource_change', 'configuration', 'access', 'compliance',
            'incident', 'post_mortem', 'oncall', 'slo', 'metric', 'dashboard', 'alert', 'data_access'
        )),

    -- Prevent future event_time
    CONSTRAINT chk_audit_event_time_not_future 
        CHECK (event_time <= NOW() + INTERVAL '1 minute'),

    -- Foreign Key
    CONSTRAINT fk_audit_logs_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
)
PARTITION BY RANGE (event_time);
-- Index on event_time for time-based queries
CREATE INDEX idx_audit_logs_event_time 
ON btrace_audit.audit_logs (event_time DESC);

-- Index on user for filtering by actor
CREATE INDEX idx_audit_logs_user_id 
ON btrace_audit.audit_logs (user_id, event_time DESC)
WHERE user_id IS NOT NULL;

-- Index on action + status
CREATE INDEX idx_audit_logs_action_status 
ON btrace_audit.audit_logs (action, action_status, event_time DESC);

-- Index on resource
CREATE INDEX idx_audit_logs_resource 
ON btrace_audit.audit_logs (resource_type, resource_id, event_time DESC);

-- GIN index on details
CREATE INDEX idx_audit_logs_details_gin 
ON btrace_audit.audit_logs USING GIN (details)
WHERE details IS NOT NULL;

-- Covering index for audit dashboard
CREATE INDEX idx_audit_logs_covering 
ON btrace_audit.audit_logs (event_time DESC, event_type)
INCLUDE (action, action_status, user_name, resource_type, resource_name, user_ip);



-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_audit.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at column
ALTER TABLE btrace_audit.audit_logs ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE;

-- Trigger
CREATE TRIGGER update_audit_logs_updated_at
    BEFORE UPDATE ON btrace_audit.audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION btrace_audit.update_updated_at_column();
	
	
--automate the creation of partitions
CREATE OR REPLACE FUNCTION create_audit_partitions()
RETURNS void AS $$
DECLARE
    start_date DATE := DATE_TRUNC('month', NOW());
    end_date   DATE := start_date + INTERVAL '12 months';
    part_name  TEXT;
    part_start TIMESTAMP;
    part_end   TIMESTAMP;
BEGIN
    FOR part_start IN SELECT generate_series(start_date, end_date, '1 month') LOOP
        part_end := part_start + INTERVAL '1 month';
        part_name := 'audit_logs_' || TO_CHAR(part_start, 'YYYY_MM');
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS btrace_audit.%I PARTITION OF btrace_audit.audit_logs FOR VALUES FROM (%L) TO (%L)',
            part_name, part_start, part_end
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Run it
SELECT create_audit_partitions();

INSERT INTO btrace_audit.audit_logs (
    event_type,
    event_subtype,
    user_name,
    user_ip,
    user_agent,
    resource_type,
    resource_id,
    action,
    action_status,
    details
) VALUES (
    'authentication',
    'password_reset',
    'malicious@attacker.com',
    '45.34.23.12',
    'Mozilla/5.0 ...',
    'user',
    'usr-99999',
    'login',
    'failure',
    '{"attempt": 12, "blocked": true}'
);
-- user_id omitted → NULL, FK constraint satisfied

-- Data Access Logs: Records of data access
--
-- BUSINESS CASE:
-- The `data_access_logs` table records all access to sensitive or regulated data (e.g., traces, logs, incidents).
-- It enables compliance with data governance policies (e.g., GDPR, HIPAA), detects unauthorized access,
-- and supports forensic investigations. This is essential for security teams, auditors, and data stewards.
--
-- PURPOSE:
-- - Log all data access events (read, export, query) for audit and compliance
-- - Support user activity monitoring and anomaly detection
-- - Enable data subject access request (DSAR) fulfillment
-- - Detect excessive or suspicious data access (e.g., data exfiltration)
-- - Integrate with SIEMs, dashboards, and alerting systems
--

CREATE TABLE btrace_audit.data_access_logs (
    access_id      UUID NOT NULL DEFAULT uuid_generate_v4(),
    access_time    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id        UUID,
    user_name      VARCHAR(255),
    user_ip        INET,
    data_type      VARCHAR(50) NOT NULL,
    data_id        VARCHAR(100) NOT NULL,
    access_type    VARCHAR(50) NOT NULL,
    query_parameters TEXT,
    result_count   INTEGER,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Enforce valid data_type
    CONSTRAINT chk_data_access_data_type 
        CHECK (data_type IN (
            'trace', 'span', 'log', 'metric', 'incident', 'post_mortem', 
            'alert', 'dashboard', 'report', 'kpi', 'slo', 'config'
        )),

    -- Enforce valid access_type
    CONSTRAINT chk_data_access_access_type 
        CHECK (access_type IN ('read', 'export', 'query', 'download', 'view', 'print')),

    -- Prevent future access_time
    CONSTRAINT chk_data_access_time_not_future 
        CHECK (access_time <= NOW() + INTERVAL '1 minute'),

    -- Ensure result_count is non-negative
    CONSTRAINT chk_data_access_result_count 
        CHECK (result_count IS NULL OR result_count >= 0),

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_data_access_logs 
        PRIMARY KEY (access_id, access_time),

    -- Foreign Key
    CONSTRAINT fk_data_access_logs_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
)
PARTITION BY RANGE (access_time);


-- Fast: "Show recent data access by user"
CREATE INDEX idx_data_access_logs_user_id 
ON btrace_audit.data_access_logs (user_id, access_time DESC)
WHERE user_id IS NOT NULL;

-- Filter by time (most common)
CREATE INDEX idx_data_access_logs_access_time 
ON btrace_audit.data_access_logs (access_time DESC);

-- Filter by data_type + access_type (e.g., all exports of incidents)
CREATE INDEX idx_data_access_logs_data_type_access_type 
ON btrace_audit.data_access_logs (data_type, access_type, access_time DESC);

-- Filter by data_id (e.g., access to a specific trace)
CREATE INDEX idx_data_access_logs_data_id 
ON btrace_audit.data_access_logs (data_type, data_id, access_time DESC);

-- Covering index for audit dashboard
CREATE INDEX idx_data_access_logs_covering 
ON btrace_audit.data_access_logs (access_time DESC, data_type)
INCLUDE (access_type, user_name, user_ip, result_count, query_parameters);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_audit.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_data_access_logs_updated_at
    BEFORE UPDATE ON btrace_audit.data_access_logs
    FOR EACH ROW
    EXECUTE FUNCTION btrace_audit.update_updated_at_column();
	
COMMENT ON TABLE btrace_audit.data_access_logs IS 
'Records all access to sensitive or regulated data (e.g., traces, logs, incidents) for compliance, security, and forensic analysis. Immutable and append-only. Partitioned by access_time for scalability and retention.';

COMMENT ON COLUMN btrace_audit.data_access_logs.access_id IS 
'Globally unique identifier for the data access event. Used in APIs and references.';

COMMENT ON COLUMN btrace_audit.data_access_logs.access_time IS 
'When the data was accessed. Used for partitioning and time-based queries.';

COMMENT ON COLUMN btrace_audit.data_access_logs.user_id IS 
'Optional: user who accessed the data. NULL if anonymous or system-generated.';

COMMENT ON COLUMN btrace_audit.data_access_logs.user_name IS 
'Optional: display name of the user (e.g., "Alice Johnson"). Useful if user is deleted but log persists.';

COMMENT ON COLUMN btrace_audit.data_access_logs.user_ip IS 
'IP address from which the data was accessed. Critical for detecting suspicious access.';

COMMENT ON COLUMN btrace_audit.data_access_logs.data_type IS 
'Type of data accessed: trace, log, incident, dashboard, etc. Enables broad filtering and classification.';

COMMENT ON COLUMN btrace_audit.data_access_logs.data_id IS 
'Identifier of the specific data item accessed (e.g., trace_id, incident_id). Used with data_type for precise identification.';

COMMENT ON COLUMN btrace_audit.data_access_logs.access_type IS 
'Operation performed: read, export, query, download, view, print. Drives audit logic and compliance checks.';

COMMENT ON COLUMN btrace_audit.data_access_logs.query_parameters IS 
'Optional: full query or filter parameters used to access the data (e.g., time range, filters). Useful for forensic analysis.';

COMMENT ON COLUMN btrace_audit.data_access_logs.result_count IS 
'Optional: number of records returned by the query or access operation. Helps detect bulk access or data exfiltration.';

COMMENT ON COLUMN btrace_audit.data_access_logs.created_at IS 
'When the access log was recorded in the system.';

COMMENT ON COLUMN btrace_audit.data_access_logs.updated_at IS 
'Automatically updated if the log is modified (rare). Used for audit trail.';


--show all access to a specific trace 
SELECT access_time, user_name, user_ip, access_type, result_count
FROM btrace_audit.data_access_logs
WHERE data_type = 'trace'
  AND data_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY access_time DESC;

--detect bulk data exports 
SELECT user_name, data_type, result_count, access_time
FROM btrace_audit.data_access_logs
WHERE access_type = 'export'
  AND result_count > 1000
  AND access_time > NOW() - INTERVAL '1 hour'
ORDER BY result_count DESC;

--show user's data access history
SELECT data_type, data_id, access_type, access_time
FROM btrace_audit.data_access_logs
WHERE user_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
ORDER BY access_time DESC
LIMIT 100;

-- Configuration Changes: Records of system configuration changes
--
-- BUSINESS CASE:
-- The `configuration_changes` table records all modifications to system configuration (e.g., alert rules, SLOs, dashboards, RBAC).
-- It enables change auditing, compliance (e.g., SOC2, ISO27001), forensic analysis, and rollback planning.
-- This is essential for security teams, platform engineers, and auditors.
--
-- PURPOSE:
-- - Log all configuration changes (create, update, delete) for accountability
-- - Support forensic investigations and incident response
-- - Enable compliance reporting and audit trails
-- - Detect unauthorized or risky changes
-- - Integrate with CI/CD, dashboards, and alerting systems
--
CREATE TABLE btrace_audit.configuration_changes (
    change_id      UUID NOT NULL DEFAULT uuid_generate_v4(),
    change_time    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id        UUID,
    user_name      VARCHAR(255),
    config_type    VARCHAR(100) NOT NULL,
    config_id      VARCHAR(100) NOT NULL,
    change_type    VARCHAR(20) NOT NULL,
    old_value      JSONB,
    new_value      JSONB,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Enforce valid change_type
    CONSTRAINT chk_config_change_type 
        CHECK (change_type IN ('create', 'update', 'delete')),

    -- Enforce valid config_type
    CONSTRAINT chk_config_config_type 
        CHECK (config_type IN (
            'alert_rule', 'slo', 'dashboard', 'metric_definition', 'service', 
            'environment', 'team', 'user', 'oncall_schedule', 'kpi', 'trace_sampling_rule'
        )),

    -- Prevent future change_time
    CONSTRAINT chk_config_change_time_not_future 
        CHECK (change_time <= NOW() + INTERVAL '1 minute'),

    -- Ensure old_value and new_value are not both NULL
    CONSTRAINT chk_config_value_change 
        CHECK (old_value IS NOT NULL OR new_value IS NOT NULL),

    -- Composite Primary Key
    CONSTRAINT pk_configuration_changes 
        PRIMARY KEY (change_id),

    -- Foreign Key
    CONSTRAINT fk_config_changes_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- =============================================
-- SECTION 9: VISITOR ANALYTICS
-- =============================================

-- Platform Usage: Tracking user interactions with the platform
--
-- BUSINESS CASE:
-- The `platform_usage` table records user interactions with the platform UI (e.g., page views, clicks, form submissions).
-- It enables product analytics, UX optimization, adoption tracking, and feature usage analysis.
-- This is essential for product managers, UX designers, and platform engineers.
--
-- PURPOSE:
-- - Track user engagement and feature adoption
-- - Support A/B testing and UX improvements
-- - Identify underused or confusing features
-- - Enable user journey analysis and funnel tracking
-- - Integrate with dashboards, alerts, and reporting systems
--

CREATE TABLE btrace_analytics.platform_usage (
    usage_id       UUID NOT NULL DEFAULT uuid_generate_v4(),
    user_id        UUID,
    session_id     VARCHAR(100) NOT NULL,
    event_time     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_type     VARCHAR(100) NOT NULL,
    event_name     VARCHAR(100) NOT NULL,
    page_url       TEXT,
    element_id     VARCHAR(100),
    metadata       JSONB,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Enforce valid event_type
    CONSTRAINT chk_platform_usage_event_type 
        CHECK (event_type IN (
            'pageview', 'click', 'form_submit', 'navigation', 'hover', 
            'search', 'filter_change', 'dashboard_view', 'export', 'error'
        )),

    -- Prevent future event_time
    CONSTRAINT chk_platform_usage_event_time_not_future 
        CHECK (event_time <= NOW() + INTERVAL '1 minute'),

    -- Composite Primary Key including partitioning column
    CONSTRAINT pk_platform_usage 
        PRIMARY KEY (usage_id, event_time),

    -- Foreign Key
    CONSTRAINT fk_platform_usage_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
)
PARTITION BY RANGE (event_time);

-- Fast: "Show recent activity by user"
CREATE INDEX idx_platform_usage_user_id 
ON btrace_analytics.platform_usage (user_id, event_time DESC)
WHERE user_id IS NOT NULL;

-- Filter by time (most common)
CREATE INDEX idx_platform_usage_event_time 
ON btrace_analytics.platform_usage (event_time DESC);

-- Filter by session (e.g., full user journey)
CREATE INDEX idx_platform_usage_session_id 
ON btrace_analytics.platform_usage (session_id, event_time DESC);

-- Filter by event_type + event_name (e.g., all dashboard views)
CREATE INDEX idx_platform_usage_event_type_name 
ON btrace_analytics.platform_usage (event_type, event_name, event_time DESC);

-- Filter by page URL (e.g., adoption of a new feature page)
CREATE INDEX idx_platform_usage_page_url 
ON btrace_analytics.platform_usage (page_url, event_time DESC)
WHERE page_url IS NOT NULL;

-- GIN index on metadata for structured filtering
CREATE INDEX idx_platform_usage_metadata_gin 
ON btrace_analytics.platform_usage USING GIN (metadata)
WHERE metadata IS NOT NULL;

-- Covering index for product dashboard
CREATE INDEX idx_platform_usage_covering 
ON btrace_analytics.platform_usage (event_time DESC, event_type)
INCLUDE (event_name, user_id, session_id, page_url, element_id);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_platform_usage_updated_at
    BEFORE UPDATE ON btrace_analytics.platform_usage
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.platform_usage IS 
'Records user interactions with the platform UI (e.g., page views, clicks, form submissions). Used for product analytics, UX optimization, and feature adoption tracking. Immutable and append-only. Partitioned by event_time for scalability and retention.';

COMMENT ON COLUMN btrace_analytics.platform_usage.usage_id IS 
'Globally unique identifier for the usage event. Used in APIs and references.';

COMMENT ON COLUMN btrace_analytics.platform_usage.user_id IS 
'Optional: user who performed the action. NULL if anonymous or not logged in.';

COMMENT ON COLUMN btrace_analytics.platform_usage.session_id IS 
'Identifier for the user session (e.g., from browser cookie). Enables journey analysis and funnel tracking.';

COMMENT ON COLUMN btrace_analytics.platform_usage.event_time IS 
'When the interaction occurred. Used for partitioning and time-based queries.';

COMMENT ON COLUMN btrace_analytics.platform_usage.event_type IS 
'High-level category of the interaction: pageview, click, form_submit, navigation, search, error, etc. Drives analytics and filtering.';

COMMENT ON COLUMN btrace_analytics.platform_usage.event_name IS 
'Name of the specific event (e.g., "Dashboard Export Clicked", "SLO Created"). Should be consistent and low-cardinality.';

COMMENT ON COLUMN btrace_analytics.platform_usage.page_url IS 
'Full URL of the page where the event occurred (e.g., "/dashboards/123"). Enables page-level adoption analysis.';

COMMENT ON COLUMN btrace_analytics.platform_usage.element_id IS 
'Optional: ID of the clicked element (e.g., "export-btn", "create-slo-modal"). Useful for A/B testing and UX debugging.';

COMMENT ON COLUMN btrace_analytics.platform_usage.metadata IS 
'Additional structured context about the event (e.g., "dashboard_id", "slo_name", "filters_applied"). Stored as JSONB for flexibility.';

COMMENT ON COLUMN btrace_analytics.platform_usage.created_at IS 
'When the usage event was recorded in the system.';

COMMENT ON COLUMN btrace_analytics.platform_usage.updated_at IS 
'Automatically updated if the log is modified (rare). Used for audit trail.';

--select user's recent activity
SELECT event_time, event_type, event_name, page_url
FROM btrace_analytics.platform_usage
WHERE user_id = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
  AND event_time > NOW() - INTERVAL '7 days'
ORDER BY event_time DESC;

--track adoption of a new feature 

SELECT COUNT(*) AS feature_uses
FROM btrace_analytics.platform_usage
WHERE page_url LIKE '/features/new-trace-explorer%'
  AND event_type = 'pageview'
  AND event_time > '2025-07-01';
  
--detect UI errors
SELECT user_id, page_url, metadata, event_time
FROM btrace_analytics.platform_usage
WHERE event_type = 'error'
  AND event_time > NOW() - INTERVAL '1 hour'
ORDER BY event_time DESC;

--funnnel analysis 
WITH funnel AS (
    SELECT 
        session_id,
        BOOL_OR(event_name = 'SLO Page Viewed') AS viewed,
        BOOL_OR(event_name = 'SLO Form Submitted') AS submitted,
        BOOL_OR(event_name = 'SLO Created') AS created
    FROM btrace_analytics.platform_usage
    WHERE event_name IN ('SLO Page Viewed', 'SLO Form Submitted', 'SLO Created')
      AND event_time > NOW() - INTERVAL '30 days'
    GROUP BY session_id
)
SELECT 
    COUNT(*) AS sessions,
    COUNT(*) FILTER (WHERE viewed) AS viewed_page,
    COUNT(*) FILTER (WHERE submitted) AS submitted_form,
    COUNT(*) FILTER (WHERE created) AS created_slo,
    ROUND(100.0 * COUNT(*) FILTER (WHERE created) / NULLIF(COUNT(*) FILTER (WHERE viewed), 0), 2) AS conversion_rate
FROM funnel;

-- Feature Adoption: Tracking usage of platform features
CREATE TABLE btrace_analytics.feature_adoption (
    adoption_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    first_used_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE NOT NULL,
    usage_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (user_id) REFERENCES btrace_rbac.users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_user_feature UNIQUE (user_id, feature_name)
);
COMMENT ON TABLE btrace_analytics.feature_adoption IS 'Tracking of feature usage by users';
COMMENT ON COLUMN btrace_analytics.feature_adoption.feature_name IS 'Name of the platform feature';

-- User Feedback: Feedback from platform users
--
-- BUSINESS CASE:
-- The `user_feedback` table captures feedback from platform users (e.g., bug reports, feature requests, general comments).
-- It enables product teams to prioritize improvements, respond to users, and close the loop on issues.
-- This is essential for user satisfaction, product iteration, and platform governance.
--
-- PURPOSE:
-- - Centralize all user feedback in a structured, queryable format
-- - Support triage, assignment, and response workflows
-- - Enable reporting on feedback volume, resolution time, and satisfaction
-- - Integrate with dashboards, alerts, and support systems
-- - Facilitate user engagement and retention
--

CREATE TABLE btrace_analytics.user_feedback (
    feedback_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID,
    feedback_type  VARCHAR(50) NOT NULL,
    subject        VARCHAR(255) NOT NULL,
    message        TEXT NOT NULL,
    rating         INTEGER,
    status         VARCHAR(20) NOT NULL DEFAULT 'open',
    response       TEXT,
    responded_by   UUID,
    responded_at   TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE,

    -- Enforce valid feedback_type
    CONSTRAINT chk_user_feedback_type 
        CHECK (feedback_type IN ('bug', 'feature_request', 'general', 'performance', 'ui/ux', 'security', 'documentation')),

    -- Enforce valid status
    CONSTRAINT chk_user_feedback_status 
        CHECK (status IN ('open', 'triaged', 'in_progress', 'resolved', 'closed', 'duplicate', 'won''t_fix')),

    -- Enforce valid rating (if provided)
    CONSTRAINT chk_user_feedback_rating 
        CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),

    -- Ensure responded_at implies responded_by
    CONSTRAINT chk_user_feedback_response_integrity 
        CHECK (responded_at IS NULL OR responded_by IS NOT NULL),

    -- Prevent future timestamps
    CONSTRAINT chk_user_feedback_created_at_not_future 
        CHECK (created_at <= NOW() + INTERVAL '1 minute'),

    -- Foreign Keys
    CONSTRAINT fk_user_feedback_user_id 
        FOREIGN KEY (user_id) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL,

    CONSTRAINT fk_user_feedback_responded_by 
        FOREIGN KEY (responded_by) 
        REFERENCES btrace_rbac.users (user_id) 
        ON DELETE SET NULL
);

-- Fast: "Show recent feedback from this user"
CREATE INDEX idx_user_feedback_user_id 
ON btrace_analytics.user_feedback (user_id, created_at DESC)
WHERE user_id IS NOT NULL;

-- Filter by status (e.g., "show all open feedback")
CREATE INDEX idx_user_feedback_status 
ON btrace_analytics.user_feedback (status, created_at DESC);

-- Filter by feedback_type (e.g., all bug reports)
CREATE INDEX idx_user_feedback_type 
ON btrace_analytics.user_feedback (feedback_type, created_at DESC);

-- Filter by rating (e.g., low-rated feedback)
CREATE INDEX idx_user_feedback_rating 
ON btrace_analytics.user_feedback (rating) 
WHERE rating IS NOT NULL;

-- Covering index for feedback dashboard
CREATE INDEX idx_user_feedback_covering 
ON btrace_analytics.user_feedback (created_at DESC, status)
INCLUDE (feedback_type, subject, user_id, rating, responded_at);

-- Reuse or create the updated_at function
CREATE OR REPLACE FUNCTION btrace_analytics.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_user_feedback_updated_at
    BEFORE UPDATE ON btrace_analytics.user_feedback
    FOR EACH ROW
    EXECUTE FUNCTION btrace_analytics.update_updated_at_column();
	
COMMENT ON TABLE btrace_analytics.user_feedback IS 
'Feedback submitted by platform users (e.g., bug reports, feature requests, general comments). Enables product improvement, user engagement, and closed-loop communication. Critical for customer satisfaction and platform evolution.';

COMMENT ON COLUMN btrace_analytics.user_feedback.feedback_id IS 
'Unique identifier for the feedback entry. Used in APIs, references, and notifications.';

COMMENT ON COLUMN btrace_analytics.user_feedback.user_id IS 
'Optional: user who submitted the feedback. NULL if anonymous.';

COMMENT ON COLUMN btrace_analytics.user_feedback.feedback_type IS 
'Category of feedback: bug, feature_request, general, performance, ui/ux, security, documentation. Drives triage and routing.';

COMMENT ON COLUMN btrace_analytics.user_feedback.subject IS 
'Short summary of the feedback (e.g., "Dashboard Export Fails"). Used in lists and notifications.';

COMMENT ON COLUMN btrace_analytics.user_feedback.message IS 
'Detailed description of the issue, request, or comment. Should include steps to reproduce (for bugs) or use case (for features).';

COMMENT ON COLUMN btrace_analytics.user_feedback.rating IS 
'Optional: numeric rating (1-5) provided by the user (e.g., satisfaction, severity). NULL if not rated.';

COMMENT ON COLUMN btrace_analytics.user_feedback.status IS 
'Current state of the feedback: open, triaged, in_progress, resolved, closed, duplicate, won''t_fix. Used for workflow management.';

COMMENT ON COLUMN btrace_analytics.user_feedback.response IS 
'Optional: response from the product or support team. Used to close the loop with the user.';

COMMENT ON COLUMN btrace_analytics.user_feedback.responded_by IS 
'Optional: user who responded to the feedback. NULL if unassigned or auto-closed.';

COMMENT ON COLUMN btrace_analytics.user_feedback.responded_at IS 
'Optional: when the feedback was responded to. NULL if not yet addressed.';

COMMENT ON COLUMN btrace_analytics.user_feedback.created_at IS 
'When the feedback was submitted.';

COMMENT ON COLUMN btrace_analytics.user_feedback.updated_at IS 
'Automatically updated when the feedback is modified. Used for audit trail.';



--show all open feedback 
SELECT subject, feedback_type, message, rating, created_at
FROM btrace_analytics.user_feedback
WHERE status = 'open'
ORDER BY created_at DESC;

--find all bug reports 
SELECT feedback_id, subject, message, user_id
FROM btrace_analytics.user_feedback
WHERE feedback_type = 'bug'
  AND status != 'resolved'
ORDER BY created_at DESC;

SELECT 
    AVG(EXTRACT(EPOCH FROM (responded_at - created_at)) / 3600) AS avg_hours_to_respond
FROM btrace_analytics.user_feedback
WHERE responded_at IS NOT NULL;


SELECT subject, message, rating, created_at
FROM btrace_analytics.user_feedback
WHERE rating IN (1, 2)
ORDER BY created_at DESC;

-- =============================================
-- SECTION 10: PARTITION MANAGEMENT
-- =============================================

-- Function to create monthly partitions for time-series tables
CREATE OR REPLACE FUNCTION btrace_core.create_monthly_partitions()
RETURNS VOID AS $$
DECLARE
    current_month DATE := DATE_TRUNC('month', CURRENT_DATE);
    next_month DATE := current_month + INTERVAL '1 month';
    partition_suffix TEXT := TO_CHAR(current_month, 'YYYY_MM');
    next_partition_suffix TEXT := TO_CHAR(next_month, 'YYYY_MM');
BEGIN
    -- Create partitions for traces table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.traces_%s PARTITION OF btrace_core.traces FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for spans table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.spans_%s PARTITION OF btrace_core.spans FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for logs table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.logs_%s PARTITION OF btrace_core.logs FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for metrics table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.metrics_%s PARTITION OF btrace_core.metrics FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for audit logs table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_audit.audit_logs_%s PARTITION OF btrace_audit.audit_logs FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for data access logs table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_audit.data_access_logs_%s PARTITION OF btrace_audit.data_access_logs FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create partitions for platform usage table
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_analytics.platform_usage_%s PARTITION OF btrace_analytics.platform_usage FOR VALUES FROM (%L) TO (%L)', 
                  partition_suffix, current_month, next_month);
    
    -- Create next month's partitions as well
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.traces_%s PARTITION OF btrace_core.traces FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.spans_%s PARTITION OF btrace_core.spans FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.logs_%s PARTITION OF btrace_core.logs FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_core.metrics_%s PARTITION OF btrace_core.metrics FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_audit.audit_logs_%s PARTITION OF btrace_audit.audit_logs FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_audit.data_access_logs_%s PARTITION OF btrace_audit.data_access_logs FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS btrace_analytics.platform_usage_%s PARTITION OF btrace_analytics.platform_usage FOR VALUES FROM (%L) TO (%L)', 
                  next_partition_suffix, next_month, next_month + INTERVAL '1 month');
END;
$$ LANGUAGE plpgsql;

-- Function to drop old partitions
CREATE OR REPLACE FUNCTION btrace_core.drop_old_partitions(retention_months INTEGER DEFAULT 12)
RETURNS VOID AS $$
DECLARE
    cutoff_date DATE := DATE_TRUNC('month', CURRENT_DATE - (retention_months * INTERVAL '1 month'));
    partition_record RECORD;
    partition_date DATE;
    partition_schema TEXT;
    partition_table TEXT;
    drop_command TEXT;
BEGIN
    FOR partition_record IN 
        SELECT nmsp_parent.nspname AS parent_schema,
               parent.relname AS parent_table,
               nmsp_child.nspname AS child_schema,
               child.relname AS child_table
        FROM pg_inherits
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
        JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
        WHERE parent.relname IN ('traces', 'spans', 'logs', 'metrics', 'audit_logs', 'data_access_logs', 'platform_usage')
    LOOP
        -- Extract date from partition table name (format: tablename_YYYY_MM)
        BEGIN
            partition_date := TO_DATE(SUBSTRING(partition_record.child_table FROM '([0-9]{4}_[0-9]{2})$'), 'YYYY_MM');
            
            IF partition_date < cutoff_date THEN
                partition_schema := partition_record.child_schema;
                partition_table := partition_record.child_table;
                drop_command := format('DROP TABLE IF EXISTS %I.%I', partition_schema, partition_table);
                
                RAISE NOTICE 'Dropping partition: %', drop_command;
                EXECUTE drop_command;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not parse date from partition %: %', partition_record.child_table, SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- SECTION 11: INDEXES FOR PERFORMANCE
-- =============================================

-- Indexes for traces table
CREATE INDEX IF NOT EXISTS idx_traces_start_time ON btrace_core.traces (start_time);
CREATE INDEX IF NOT EXISTS idx_traces_duration ON btrace_core.traces (duration_ms);
CREATE INDEX IF NOT EXISTS idx_traces_status_code ON btrace_core.traces (status_code);
CREATE INDEX IF NOT EXISTS idx_traces_environment ON btrace_core.traces (environment_id);

-- Indexes for spans table
CREATE INDEX IF NOT EXISTS idx_spans_trace_id ON btrace_core.spans (trace_id);
CREATE INDEX IF NOT EXISTS idx_spans_start_time ON btrace_core.spans (start_time);
CREATE INDEX IF NOT EXISTS idx_spans_service ON btrace_core.spans (service_id);
CREATE INDEX IF NOT EXISTS idx_spans_operation ON btrace_core.spans (operation_name);
CREATE INDEX IF NOT EXISTS idx_spans_status_code ON btrace_core.spans (status_code);

-- Indexes for logs table
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON btrace_core.logs (timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_service ON btrace_core.logs (service_id);
CREATE INDEX IF NOT EXISTS idx_logs_level ON btrace_core.logs (log_level);
CREATE INDEX IF NOT EXISTS idx_logs_trace ON btrace_core.logs (trace_id) WHERE trace_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_logs_environment ON btrace_core.logs (environment_id);

-- Indexes for metrics table
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON btrace_core.metrics (timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_name ON btrace_core.metrics (metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_service ON btrace_core.metrics (service_id) WHERE service_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_metrics_environment ON btrace_core.metrics (environment_id);

-- Indexes for incidents table
CREATE INDEX IF NOT EXISTS idx_incidents_start_time ON btrace_core.incidents (start_time);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON btrace_core.incidents (status);
CREATE INDEX IF NOT EXISTS idx_incidents_severity ON btrace_core.incidents (severity);
CREATE INDEX IF NOT EXISTS idx_incidents_service ON btrace_core.incidents (service_id) WHERE service_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_incidents_environment ON btrace_core.incidents (environment_id);

-- Indexes for alerts table
CREATE INDEX IF NOT EXISTS idx_alerts_triggered_at ON btrace_core.alerts (triggered_at);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON btrace_core.alerts (status);
CREATE INDEX IF NOT EXISTS idx_alerts_rule ON btrace_core.alerts (rule_id);
CREATE INDEX IF NOT EXISTS idx_alerts_incident ON btrace_core.alerts (incident_id) WHERE incident_id IS NOT NULL;

-- Indexes for audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_time ON btrace_audit.audit_logs (event_time);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON btrace_audit.audit_logs (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON btrace_audit.audit_logs (resource_type, resource_id) WHERE resource_type IS NOT NULL AND resource_id IS NOT NULL;

-- Indexes for platform usage
CREATE INDEX IF NOT EXISTS idx_platform_usage_event_time ON btrace_analytics.platform_usage (event_time);
CREATE INDEX IF NOT EXISTS idx_platform_usage_user ON btrace_analytics.platform_usage (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_platform_usage_event_type ON btrace_analytics.platform_usage (event_type);

-- =============================================
-- SECTION 12: VIEWS FOR COMMON QUERIES
-- =============================================

-- View: Service Health Overview
--
-- BUSINESS CASE:
-- The `service_health_overview` view provides a real-time summary of each service's health,
-- including open incidents, recent incident history, resolution times, and current performance metrics.
-- It enables SREs, platform engineers, and leadership to quickly identify at-risk services and prioritize work.
-- This is essential for operational excellence and proactive incident prevention.
--
-- PURPOSE:
-- - Provide a single pane of glass for service health
-- - Support on-call triage and daily standups
-- - Enable service-level reporting and accountability
-- - Integrate with dashboards, alerts, and executive reviews
-- - Facilitate SLO/SLI tracking and incident management
CREATE OR REPLACE VIEW btrace_analytics.service_health_overview AS
SELECT 
    s.service_id,
    s.service_name,
    s.lifecycle_stage AS criticality,  -- Use lifecycle_stage as proxy for importance
    t.team_name AS owner_team,
    NULL::TEXT AS data_domain,
    COUNT(DISTINCT i.incident_id) FILTER (WHERE i.status = 'open') AS open_incidents,
    COUNT(DISTINCT i.incident_id) FILTER (
        WHERE i.status = 'resolved' 
          AND i.start_time >= CURRENT_DATE - INTERVAL '30 days'
    ) AS recent_incidents,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time)) / 60.0) FILTER (
            WHERE i.status = 'resolved' 
              AND i.start_time >= CURRENT_DATE - INTERVAL '30 days'
        ), 2
    ) AS avg_resolution_time_minutes,
    AVG(m.value) FILTER (
        WHERE m.metric_name = 'http.server.request.duration'
          AND m.attributes @> '{"le": "0.95"}'
          AND m.timestamp >= NOW() - INTERVAL '5 minutes'
    ) AS current_p95_response_time_ms,
    AVG(m.value) FILTER (
        WHERE m.metric_name = 'http.server.error.rate'
          AND m.timestamp >= NOW() - INTERVAL '5 minutes'
    ) AS current_error_rate_percent

FROM 
    btrace_core.services s
LEFT JOIN btrace_rbac.teams t ON s.owner_team_id = t.team_id
LEFT JOIN btrace_core.incidents i ON s.service_id = i.service_id
LEFT JOIN btrace_core.metrics m ON s.service_id = m.service_id
GROUP BY 
    s.service_id, s.service_name, s.lifecycle_stage, t.team_name;
	
	
--
-- BUSINESS CASE:
-- The `incident_summary` view provides a daily rollup of incident volume and resolution times by environment.
-- It enables SRE teams, leadership, and operations to track system stability, identify trends, and measure improvement.
-- This is essential for incident retrospectives, executive reporting, and reliability planning.
--
-- PURPOSE:
-- - Monitor daily incident volume and severity distribution
-- - Track resolution times (MTTR) by environment
-- - Identify spikes in P1/P2 incidents or customer-impacting outages
-- - Support SLO reporting and reliability dashboards
-- - Enable trend analysis and capacity planning
--

CREATE OR REPLACE VIEW btrace_analytics.incident_summary AS
SELECT 
    DATE_TRUNC('day', i.start_time) AS day,
    i.environment_id,
    e.environment_name,
    COUNT(*) AS total_incidents,
    COUNT(*) FILTER (WHERE i.severity = 'P1') AS p1_incidents,
    COUNT(*) FILTER (WHERE i.severity = 'P2') AS p2_incidents,
    COUNT(*) FILTER (WHERE i.severity = 'P3') AS p3_incidents,
    COUNT(*) FILTER (WHERE i.severity = 'P4') AS p4_incidents,
    COUNT(*) FILTER (WHERE i.is_customer_impacting) AS customer_impacting_incidents,
    -- Only include resolved incidents in resolution time calculations
    ROUND(
        AVG(EXTRACT(EPOCH FROM (i.end_time - i.start_time))) FILTER (
            WHERE i.status = 'resolved' AND i.end_time IS NOT NULL
        ), 2
    ) AS avg_resolution_seconds,
    ROUND(
        MAX(EXTRACT(EPOCH FROM (i.end_time - i.start_time))) FILTER (
            WHERE i.status = 'resolved' AND i.end_time IS NOT NULL
        ), 2
    ) AS max_resolution_seconds
FROM 
    btrace_core.incidents i
JOIN 
    btrace_core.environments e ON i.environment_id = e.environment_id
GROUP BY 
    DATE_TRUNC('day', i.start_time), i.environment_id, e.environment_name
ORDER BY 
    day DESC;
	
	COMMENT ON VIEW btrace_analytics.incident_summary IS 
'Daily summary of incidents by environment and severity. Includes counts by P1-P4, customer-impacting incidents, and average/max resolution times for resolved incidents. Used by SRE teams and leadership to monitor system stability and track reliability trends.';

--
-- BUSINESS CASE:
-- The `trace_error_analysis` view identifies services and operations with high error rates and poor performance.
-- It enables developers and SREs to pinpoint problematic endpoints, debug root causes, and prioritize fixes.
-- This is essential for reducing error budgets, improving user experience, and meeting SLOs.
--
-- PURPOSE:
-- - Identify high-error services and operations
-- - Compare latency between successful and failed traces
-- - Support root-cause analysis and performance tuning
-- - Integrate with dashboards and alerting systems
-- - Enable service-level reporting and accountability
--

CREATE OR REPLACE VIEW btrace_analytics.trace_error_analysis AS
SELECT 
    s.service_id,
    s.service_name,
    sp.operation_name,
    COUNT(*) AS total_traces,
    COUNT(*) FILTER (WHERE t.status_code = 'ERROR') AS error_traces,
    ROUND(
        COUNT(*) FILTER (WHERE t.status_code = 'ERROR') * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS error_rate_percent,
    ROUND(
        AVG(t.duration_ms) FILTER (WHERE t.status_code = 'OK'), 2
    ) AS avg_success_duration_ms,
    ROUND(
        AVG(t.duration_ms) FILTER (WHERE t.status_code = 'ERROR'), 2
    ) AS avg_error_duration_ms,
    MAX(t.duration_ms) FILTER (WHERE t.status_code = 'OK') AS max_success_duration_ms,
    MAX(t.duration_ms) FILTER (WHERE t.status_code = 'ERROR') AS max_error_duration_ms
FROM 
    btrace_core.traces t
-- Join on root span (span with no parent) to get initiating operation
JOIN 
    btrace_core.spans sp ON t.trace_id = sp.trace_id AND sp.parent_span_id IS NULL
JOIN 
    btrace_core.services s ON sp.service_id = s.service_id
WHERE 
    t.start_time >= NOW() - INTERVAL '7 days'
    AND t.is_sampled = TRUE  -- Focus on sampled traces for performance
GROUP BY 
    s.service_id, s.service_name, sp.operation_name
HAVING 
    COUNT(*) FILTER (WHERE t.status_code = 'ERROR') > 0
ORDER BY 
    error_rate_percent DESC, total_traces DESC;
	
	
COMMENT ON VIEW btrace_analytics.trace_error_analysis IS 
'Analysis of error rates and performance by service and operation. Shows error rate, average and max latency for successful and failed traces. Focused on sampled traces from the last 7 days. Used by developers and SREs to identify and debug high-impact issues.';

-- For incident_summary
CREATE INDEX IF NOT EXISTS idx_incidents_start_time_env_severity 
ON btrace_core.incidents (start_time DESC, environment_id, severity, is_customer_impacting);

-- For trace_error_analysis
CREATE INDEX IF NOT EXISTS idx_traces_time_sampled_status 
ON btrace_core.traces (start_time DESC, is_sampled, status_code, duration_ms)
WHERE is_sampled = TRUE;

--daily incident trends 
SELECT 
    day, 
    environment_name, 
    total_incidents, 
    p1_incidents, 
    customer_impacting_incidents,
    avg_resolution_seconds / 60.0 AS avg_resolution_minutes
FROM btrace_analytics.incident_summary
WHERE day >= CURRENT_DATE - INTERVAL '14 days'
ORDER BY day DESC;

-- list top high-error operations 
SELECT 
    service_name, 
    operation_name, 
    total_traces, 
    error_traces, 
    error_rate_percent,
    avg_error_duration_ms
FROM btrace_analytics.trace_error_analysis
ORDER BY error_rate_percent DESC
LIMIT 10;

--
-- BUSINESS CASE:
-- The `top_slow_operations` view identifies the slowest server-side operations across the system
-- based on P95 and P99 latency. It enables SREs and developers to prioritize performance optimization
-- efforts on the most impactful endpoints. This is essential for meeting SLOs and improving user experience.
--
-- PURPOSE:
-- - Identify high-latency operations (e.g., API endpoints, DB queries)
-- - Prioritize performance tuning and code optimization
-- - Support SLO/SLI tracking and incident prevention
-- - Enable capacity planning and load testing
-- - Integrate with dashboards and alerting systems
--

CREATE OR REPLACE VIEW btrace_analytics.top_slow_operations AS
SELECT 
    s.service_id,
    s.service_name,
    sp.operation_name,
    COUNT(*) AS call_count,
    ROUND(
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sp.duration_ms)::NUMERIC,
        2
    ) AS p95_duration_ms,
    ROUND(
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY sp.duration_ms)::NUMERIC,
        2
    ) AS p99_duration_ms,
    MAX(sp.duration_ms) AS max_duration_ms,
    ROUND(AVG(sp.duration_ms), 2) AS avg_duration_ms
FROM 
    btrace_core.spans sp
JOIN 
    btrace_core.services s ON sp.service_id = s.service_id
WHERE 
    sp.start_time >= NOW() - INTERVAL '7 days'
    AND sp.kind = 'SERVER'
    AND sp.duration_ms <= 3600000  -- Exclude outliers (>1 hour)
    AND sp.duration_ms > 0
GROUP BY 
    s.service_id, s.service_name, sp.operation_name
HAVING 
    COUNT(*) > 100
ORDER BY 
    p95_duration_ms DESC
LIMIT 50;

--show top 10 slowest operations
SELECT 
    service_name, 
    operation_name, 
    call_count, 
    p95_duration_ms, 
    p99_duration_ms
FROM btrace_analytics.top_slow_operations
ORDER BY p95_duration_ms DESC
LIMIT 10;

--find high-p99, high volume endpoints
SELECT 
    service_name, 
    operation_name, 
    call_count, 
    p99_duration_ms
FROM btrace_analytics.top_slow_operations
WHERE p99_duration_ms > 2000  -- >2s P99
ORDER BY p99_duration_ms DESC;

--compare avg vs p95 latency 
SELECT 
    service_name, 
    operation_name, 
    avg_duration_ms, 
    p95_duration_ms,
    ROUND(p95_duration_ms - avg_duration_ms, 2) AS tail_latency_gap_ms
FROM btrace_analytics.top_slow_operations
ORDER BY tail_latency_gap_ms DESC
LIMIT 20;

-- View: Alert Effectiveness
--
-- BUSINESS CASE:
-- The `alert_effectiveness` view measures the quality and impact of alert rules by analyzing
-- how often they trigger, how many lead to incidents, and whether they resolve quickly or become stale.
-- It enables SRE teams to reduce alert noise, improve signal-to-noise ratio, and refine alerting policies.
-- This is essential for on-call health, incident response efficiency, and system reliability.
--
-- PURPOSE:
-- - Identify noisy, ineffective, or stale alerts
-- - Measure alert-to-incident conversion rate
-- - Support alert rule tuning and deprecation
-- - Enable on-call satisfaction and fatigue reduction
-- - Integrate with dashboards, reporting, and SLO reviews
--

CREATE OR REPLACE VIEW btrace_analytics.alert_effectiveness AS
SELECT 
    r.rule_id,
    r.rule_name,
    r.severity,
    s.service_name,
    COUNT(a.alert_id) AS total_alerts,
    COUNT(a.alert_id) FILTER (WHERE a.incident_id IS NOT NULL) AS linked_to_incident,
    COUNT(a.alert_id) FILTER (
        WHERE a.status = 'resolved' AND a.incident_id IS NULL
    ) AS resolved_without_incident,
    COUNT(a.alert_id) FILTER (
        WHERE a.status = 'open' 
          AND a.triggered_at < NOW() - INTERVAL '1 hour'
    ) AS stale_alerts,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (a.resolved_at - a.triggered_at))) FILTER (
            WHERE a.status = 'resolved'
        ), 2
    ) AS avg_resolution_seconds,
    -- Additional insight: false positive rate
    ROUND(
        COUNT(a.alert_id) FILTER (WHERE a.incident_id IS NULL) * 100.0 / 
        NULLIF(COUNT(a.alert_id), 0), 2
    ) AS false_positive_rate_percent
FROM 
    btrace_core.alert_rules r
LEFT JOIN 
    btrace_core.alerts a ON r.rule_id = a.rule_id 
                       AND a.triggered_at >= NOW() - INTERVAL '30 days'
LEFT JOIN 
    btrace_core.services s ON r.service_id = s.service_id
GROUP BY 
    r.rule_id, r.rule_name, r.severity, s.service_name
ORDER BY 
    total_alerts DESC;
	
COMMENT ON VIEW btrace_analytics.alert_effectiveness IS 
'Analyzes the effectiveness of alert rules over the last 30 days. Metrics include total alerts, linkage to incidents, stale/open alerts, average resolution time, and false positive rate. Used by SRE teams to reduce alert noise, improve signal quality, and optimize alerting policies.';

-- For alert_rules + alerts join
CREATE INDEX IF NOT EXISTS idx_alerts_rule_id_triggered_at 
ON btrace_core.alerts (rule_id, triggered_at DESC)
INCLUDE (incident_id, status, resolved_at);

-- For alert_rules service filtering
CREATE INDEX IF NOT EXISTS idx_alert_rules_service_id 
ON btrace_core.alert_rules (service_id);

-- Covering index for view (optional)
CREATE INDEX IF NOT EXISTS idx_alert_rules_covering 
ON btrace_core.alert_rules (rule_id, rule_name, severity, service_id);

--show all alert rules with high false positive rate 
SELECT 
    rule_name, 
    service_name, 
    severity, 
    total_alerts, 
    false_positive_rate_percent
FROM btrace_analytics.alert_effectiveness
WHERE false_positive_rate_percent > 50
  AND total_alerts > 10
ORDER BY false_positive_rate_percent DESC;


---alert to incident conversion rate 
SELECT 
    rule_name,
    total_alerts,
    linked_to_incident,
    ROUND(
        linked_to_incident * 100.0 / NULLIF(total_alerts, 0), 2
    ) AS incident_conversion_rate_percent
FROM btrace_analytics.alert_effectiveness
WHERE total_alerts > 5
ORDER BY incident_conversion_rate_percent ASC;

-- find stale alerts 
SELECT 
    rule_name, 
    service_name, 
    severity, 
    stale_alerts
FROM btrace_analytics.alert_effectiveness
WHERE stale_alerts > 0
ORDER BY stale_alerts DESC;

-- View: Data Quality Metrics Overview
--
-- BUSINESS CASE:
-- The `observability_data_quality_overview` view assesses the health and completeness of observability data (traces, logs, metrics)
-- ingested from services. It enables SREs and platform engineers to identify instrumentation gaps, sampling issues, or data loss.
-- This is essential for ensuring trust in observability tools and meeting SLOs.
--
-- PURPOSE:
-- - Monitor delivery of traces, logs, and metrics per service
-- - Detect instrumentation gaps or misconfigurations
-- - Support onboarding and compliance with observability standards
-- - Enable root-cause analysis when data is missing
-- - Integrate with dashboards and alerting systems
--

CREATE OR REPLACE VIEW btrace_analytics.observability_data_quality_overview AS
WITH service_data AS (
    SELECT 
        s.service_id,
        s.service_name,
        s.lifecycle_stage,
        e.environment_name,
        -- Traces
        COUNT(DISTINCT t.trace_id) FILTER (WHERE t.start_time >= NOW() - INTERVAL '1 hour') AS traces_last_hour,
        AVG(t.duration_ms) FILTER (WHERE t.start_time >= NOW() - INTERVAL '1 hour') AS avg_trace_duration_ms,
        -- Logs
        COUNT(l.log_id) FILTER (WHERE l.timestamp >= NOW() - INTERVAL '1 hour') AS logs_last_hour,
        COUNT(l.log_id) FILTER (
            WHERE l.timestamp >= NOW() - INTERVAL '1 hour' 
              AND l.log_level IN ('ERROR', 'FATAL', 'CRITICAL')
        ) AS error_logs_last_hour,
        -- Metrics
        COUNT(m.metric_id) FILTER (WHERE m.timestamp >= NOW() - INTERVAL '1 hour') AS metrics_last_hour,
        COUNT(m.metric_id) FILTER (
            WHERE m.timestamp >= NOW() - INTERVAL '1 hour' 
              AND m.metric_name ILIKE '%latency%'
        ) AS latency_metrics_last_hour
    FROM 
        btrace_core.services s
    CROSS JOIN 
        btrace_core.environments e
    LEFT JOIN 
        btrace_core.traces t ON s.service_id = t.root_service::UUID -- Best-effort join
                             AND t.environment_id = e.environment_id
                             AND t.start_time >= NOW() - INTERVAL '1 hour'
    LEFT JOIN 
        btrace_core.logs l ON s.service_id = l.service_id
                          AND l.environment_id = e.environment_id
                          AND l.timestamp >= NOW() - INTERVAL '1 hour'
    LEFT JOIN 
        btrace_core.metrics m ON s.service_id = m.service_id
                            AND m.environment_id = e.environment_id
                            AND m.timestamp >= NOW() - INTERVAL '1 hour'
    GROUP BY 
        s.service_id, s.service_name, s.lifecycle_stage, e.environment_name
)
SELECT 
    service_name,
    environment_name,
    lifecycle_stage,
    traces_last_hour,
    logs_last_hour,
    metrics_last_hour,
    error_logs_last_hour,
    latency_metrics_last_hour,
    -- Data Quality Indicators
    CASE WHEN traces_last_hour = 0 THEN 0 ELSE 1 END +
    CASE WHEN logs_last_hour = 0 THEN 0 ELSE 1 END +
    CASE WHEN metrics_last_hour = 0 THEN 0 ELSE 1 END AS data_coverage_score, -- 0-3
    ROUND(
        (CASE WHEN traces_last_hour > 0 THEN 1 ELSE 0 END +
         CASE WHEN logs_last_hour > 0 THEN 1 ELSE 0 END +
         CASE WHEN metrics_last_hour > 0 THEN 1 ELSE 0 END) * 100.0 / 3.0, 2
    ) AS data_completeness_percent,
    CASE
        WHEN traces_last_hour = 0 OR logs_last_hour = 0 OR metrics_last_hour = 0
            THEN 'missing_data'
        WHEN error_logs_last_hour > 10
            THEN 'high_errors'
        ELSE 'healthy'
    END AS data_health_status
FROM 
    service_data
ORDER BY 
    data_completeness_percent ASC, environment_name, service_name;
	
COMMENT ON VIEW btrace_analytics.observability_data_quality_overview IS 
'Assesses the completeness and health of observability data (traces, logs, metrics) per service and environment. Measures ingestion over the last hour and flags services with missing data or high error logs. Used by SREs and platform teams to ensure instrumentation coverage and data reliability.';

--show services with incomplete data 
SELECT 
    service_name, 
    environment_name, 
    data_completeness_percent, 
    data_health_status
FROM btrace_analytics.observability_data_quality_overview
WHERE data_completeness_percent < 100
ORDER BY data_completeness_percent ASC;

--show services with high error logs 
SELECT 
    service_name, 
    environment_name, 
    error_logs_last_hour
FROM btrace_analytics.observability_data_quality_overview
WHERE error_logs_last_hour > 50
ORDER BY error_logs_last_hour DESC;

-- Future: Data Quality Rules
CREATE TABLE btrace_gov.data_quality_rules (
    rule_id UUID PRIMARY KEY,
    asset_name VARCHAR(255) NOT NULL,
    rule_type VARCHAR(50) CHECK (rule_type IN ('not_null', 'unique', 'format', 'range', 'referential_integrity')),
    threshold_pct INT NOT NULL DEFAULT 95,
    is_active BOOLEAN DEFAULT TRUE
);

-- Future: Data Quality Metrics
CREATE TABLE btrace_gov.data_quality_metrics (
    metric_id UUID PRIMARY KEY,
    rule_id UUID,
    measured_value DOUBLE PRECISION,
    status VARCHAR(10) CHECK (status IN ('pass', 'fail', 'warning')),
    measurement_time TIMESTAMP WITH TIME ZONE,
    details JSONB
);



-- =============================================
-- SECTION 13: STORED PROCEDURES
-- =============================================

-- BUSINESS CASE:
-- Automate the creation of an operational incident record directly from a triggered alert.
-- This streamlines the incident response workflow by reducing manual steps for responders,
-- ensuring faster acknowledgment and investigation of critical issues.
-- It also maintains data integrity by automatically linking the alert to the newly created incident.
--
-- PURPOSE:
-- - Create a new record in the `btrace_core.incidents` table based on alert data.
-- - Update the source `btrace_core.alerts` record to link it to the new incident.
-- - Log the creation event in the `btrace_core.incident_timeline`.
-- - Optionally assign the incident to the owning team based on the associated service.
-- - Provide a consistent, auditable way to initiate incident response from an alert.

CREATE OR REPLACE PROCEDURE btrace_core.create_incident_from_alert(
    p_alert_id UUID,
    p_created_by UUID -- User initiating the incident creation (e.g., automation, responder)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_alert_record RECORD;
    v_incident_id UUID;
    v_service_owner_team_id UUID; -- Use the correct column name from services table
BEGIN
    -- Get alert details and associated rule information
    SELECT
        a.alert_id,
        a.title AS alert_title,
        a.description AS alert_description,
        a.severity AS alert_severity,
        a.triggered_at,
        r.service_id,
        r.environment_id
    INTO v_alert_record
    FROM btrace_core.alerts a
    JOIN btrace_core.alert_rules r ON a.rule_id = r.rule_id
    WHERE a.alert_id = p_alert_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Alert with ID % not found', p_alert_id;
    END IF;

    -- Validate that the alert is not already linked to an incident
    IF v_alert_record.incident_id IS NOT NULL THEN
        RAISE EXCEPTION 'Alert % is already linked to incident %', p_alert_id, v_alert_record.incident_id;
    END IF;

    -- Create the incident record
    INSERT INTO btrace_core.incidents (
        title,
        description,
        status,
        severity,
        impact, -- Impact logic can be refined based on severity or other factors
        start_time,
        detected_at,
        service_id,
        environment_id,
        is_customer_impacting,
        created_by
    ) VALUES (
        LEFT('Incident from Alert: ' || v_alert_record.alert_title, 255), -- Ensure title fits within limit
        v_alert_record.alert_description,
        'investigating', -- Initial status
        v_alert_record.alert_severity,
        CASE
            WHEN v_alert_record.alert_severity IN ('P1', 'P2') THEN 'high'
            WHEN v_alert_record.alert_severity = 'P3' THEN 'medium'
            ELSE 'low'
        END, -- Map alert severity to impact if needed, or use a default/generic value
        v_alert_record.triggered_at, -- Incident start time aligns with alert trigger
        v_alert_record.triggered_at, -- Detected time aligns with alert trigger
        v_alert_record.service_id,
        v_alert_record.environment_id,
        FALSE, -- Default value, can be updated later based on investigation
        p_created_by
    )
    RETURNING incident_id INTO v_incident_id;


    -- Link the original alert to the newly created incident
    UPDATE btrace_core.alerts
    SET incident_id = v_incident_id,
        updated_at = CURRENT_TIMESTAMP -- Update timestamp for audit trail
    WHERE alert_id = p_alert_id;


    -- Record the incident creation in the timeline
    INSERT INTO btrace_core.incident_timeline (
        incident_id,
        event_type,
        event_time,
        description,
        created_by
    ) VALUES (
        v_incident_id,
        'incident_created',
        CURRENT_TIMESTAMP,
        'Incident automatically created from alert ID: ' || p_alert_id || ' (Title: ' || v_alert_record.alert_title || ').',
        p_created_by
    );


    -- Attempt to assign the incident to the service's owning team
    IF v_alert_record.service_id IS NOT NULL THEN
        -- Retrieve the owner team ID from the services table
        SELECT owner_team_id -- Correct column name based on schema
        INTO v_service_owner_team_id
        FROM btrace_core.services
        WHERE service_id = v_alert_record.service_id;

        IF FOUND AND v_service_owner_team_id IS NOT NULL THEN
            -- Insert the team assignment record using the correct table name and columns
            INSERT INTO btrace_core.incident_team_assignments ( -- Correct table name
                incident_id,
                team_id, -- Assign to the team, not user
                assigned_by
            ) VALUES (
                v_incident_id,
                v_service_owner_team_id,
                p_created_by
            );

            -- Log the team assignment in the timeline
            INSERT INTO btrace_core.incident_timeline (
                incident_id,
                event_type,
                event_time,
                description,
                created_by
            ) VALUES (
                v_incident_id,
                'team_assigned',
                CURRENT_TIMESTAMP,
                'Incident automatically assigned to owning team (ID: ' || v_service_owner_team_id || ') based on service.',
                p_created_by
            );
        ELSE
            -- Optional: Log if no team is assigned to the service
            INSERT INTO btrace_core.incident_timeline (
                incident_id,
                event_type,
                event_time,
                description,
                created_by
            ) VALUES (
                v_incident_id,
                'note',
                CURRENT_TIMESTAMP,
                'No owning team found for the associated service (ID: ' || v_alert_record.service_id || '). Manual assignment required.',
                p_created_by
            );
        END IF;
    END IF;

    -- Consider adding a user assignment if p_created_by is meant to be the initial assignee
    -- This depends on the specific workflow requirements.
    -- Example:
    -- INSERT INTO btrace_core.incident_user_assignments (incident_id, user_id, assigned_by)
    -- VALUES (v_incident_id, p_created_by, p_created_by);

    -- RAISE NOTICE 'Incident % created successfully from alert %', v_incident_id, p_alert_id;

END;
$$;

COMMENT ON PROCEDURE btrace_core.create_incident_from_alert IS
'Creates a new incident in btrace_core.incidents based on the details of a specific alert. It links the alert to the incident, logs the creation event in the timeline, and optionally assigns the incident to the service''s owning team.';

CREATE OR REPLACE VIEW btrace_core.active_incidents_with_alerts AS
SELECT
    i.incident_id,
    i.title AS incident_title,
    i.status AS incident_status,
    i.severity,
    i.service_id,
    s.service_name,
    i.environment_id,
    e.environment_name,
    i.start_time,
    COUNT(a.alert_id) AS alert_count,
    -- Array of recent alert titles/descriptions if needed
    jsonb_agg(
        jsonb_build_object(
            'alert_id', a.alert_id,
            'alert_title', a.title,
            'triggered_at', a.triggered_at,
            'alert_status', a.status
        )
    ) FILTER (WHERE a.alert_id IS NOT NULL) AS alerts
FROM btrace_core.incidents i
LEFT JOIN btrace_core.alerts a ON i.incident_id = a.incident_id
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
LEFT JOIN btrace_core.environments e ON i.environment_id = e.environment_id
WHERE i.status IN ('investigating', 'identified') -- Define "active" statuses
GROUP BY i.incident_id, i.title, i.status, i.severity, i.service_id, s.service_name, i.environment_id, e.environment_name, i.start_time;
COMMENT ON VIEW btrace_core.active_incidents_with_alerts IS 'Provides a consolidated view of active incidents and their associated alerts for operational monitoring.';

-- Find unlinked, open alerts quickly (e.g., for batch processing or UI display)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alerts_unlinked_open
ON btrace_core.alerts (triggered_at DESC)
INCLUDE (alert_id, rule_id, status, severity, title) -- Covering for common lookups
WHERE incident_id IS NULL AND status IN ('open', 'triggered'); -- Adjust status list as needed
COMMENT ON INDEX btrace_core.idx_alerts_unlinked_open IS 'Index for quickly finding recent, unacknowledged/unlinked alerts that might need incident creation.';

--note:Ensure btrace_core.incident_timeline.event_type has a value like 'incident_created' and 'team_assigned' defined if it's an ENUM or has a check constraint listing valid types. Also, ensure btrace_core.incidents.status includes 'investigating'. The schema implies these values are used, so they should be seeded if necessary.


-- Procedure: Resolve Incident
-- BUSINESS CASE:
-- Formally close an operational incident once the underlying issue has been resolved and the system is stable.
-- This procedure standardizes the resolution process, ensuring critical fields like `end_time`, `resolved_at`, and `status` are updated correctly.
-- It also provides an audit trail by logging the resolution in the incident timeline and automatically resolves any alerts that were linked to this incident,
-- preventing lingering open alerts and maintaining data consistency.
--
-- PURPOSE:
-- - Update the status of a specific incident to 'resolved'.
-- - Set the `end_time` and `resolved_at` timestamps for the incident.
-- - Record the resolution event and notes in the `btrace_core.incident_timeline`.
-- - Automatically update the status of all linked alerts (that are not already resolved) to 'resolved'.
-- - Ensure the `updated_at` and `updated_by` fields on the incident are correctly maintained.

CREATE OR REPLACE PROCEDURE btrace_core.resolve_incident(
    p_incident_id UUID,
    p_resolution_notes TEXT, -- Optional detailed notes about the resolution
    p_resolved_by UUID       -- User ID of the person resolving the incident
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_incident_status TEXT;
    v_affected_rows INTEGER; -- To capture the number of alerts updated
BEGIN
    -- Check current status of the incident
    SELECT status INTO v_incident_status
    FROM btrace_core.incidents
    WHERE incident_id = p_incident_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Incident with ID % not found', p_incident_id;
    END IF;

    -- Check if the incident is already resolved or closed
    -- Using 'closed' as well, as it's another common final status in the schema
    IF v_incident_status IN ('resolved', 'closed') THEN
        RAISE NOTICE 'Incident % is already in a final state (%). No action taken.', p_incident_id, v_incident_status;
        RETURN;
    END IF;

    -- Update the incident record to mark it as resolved
    -- Note: end_time is often set when the incident is truly over, which might be slightly after resolution starts.
    -- However, setting it on resolution is common. Alternatively, it could be set on 'closed' status if that's a later step.
    UPDATE btrace_core.incidents
    SET
        status = 'resolved',
        resolved_at = CURRENT_TIMESTAMP, -- Standardize on resolved_at for when resolution process completes
        end_time = CURRENT_TIMESTAMP,    -- Set end_time here as per procedure logic
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_resolved_by
    WHERE incident_id = p_incident_id;


    -- Add a timeline event to record the resolution
    INSERT INTO btrace_core.incident_timeline (
        incident_id,
        event_type, -- Should be 'incident_resolved' for clarity based on schema examples
        event_time,
        description,
        created_by
    ) VALUES (
        p_incident_id,
        'incident_resolved', -- Use a clear, specific event type
        CURRENT_TIMESTAMP,
        COALESCE(LEFT(p_resolution_notes, 2000), 'Incident marked as resolved.'), -- Truncate notes if extremely long and provide default
        p_resolved_by
    );


    -- Resolve all linked alerts that are not already resolved
    -- This ensures alert dashboards and workflows reflect the correct state.
    UPDATE btrace_core.alerts
    SET
        status = 'resolved',
        resolved_at = CURRENT_TIMESTAMP, -- Set resolved timestamp for the alert
        updated_at = CURRENT_TIMESTAMP   -- Update the alert's timestamp
    WHERE incident_id = p_incident_id
      AND status != 'resolved'; -- Only update alerts that are not already resolved

    GET DIAGNOSTICS v_affected_rows = ROW_COUNT; -- Get number of alerts updated

    -- Optionally, log the number of alerts resolved in the timeline
    IF v_affected_rows > 0 THEN
        INSERT INTO btrace_core.incident_timeline (
            incident_id,
            event_type,
            event_time,
            description,
            created_by
        ) VALUES (
            p_incident_id,
            'note', -- Using 'note' for informational messages
            CURRENT_TIMESTAMP,
            format('Automatically resolved %s linked alert(s) as part of incident resolution.', v_affected_rows),
            p_resolved_by
        );
    END IF;

    -- Consider if a 'closed' status is a separate step in your workflow.
    -- If so, this procedure only handles 'resolved'. A separate 'close_incident'
    -- procedure might be needed for the final 'closed' state.

    -- RAISE NOTICE 'Incident % resolved successfully. % alert(s) were also resolved.', p_incident_id, v_affected_rows;

END;
$$;

COMMENT ON PROCEDURE btrace_core.resolve_incident IS
'Updates an incident''s status to ''resolved'', sets resolution timestamps, logs the event in the timeline, and automatically resolves all associated alerts.';


-- BUSINESS CASE:
-- Transition an incident to its final 'closed' state after resolution and any required post-mortem activities are complete.
-- This signifies the end of the active incident management process and prepares the incident for long-term archiving or review.
--
-- PURPOSE:
-- - Update the incident status to 'closed'.
-- - Record the closure event and notes in the `btrace_core.incident_timeline`.
-- - Ensure the `updated_at` and `updated_by` fields on the incident are correctly maintained.
-- - Enforce workflow by only allowing closure of 'resolved' incidents.

CREATE OR REPLACE PROCEDURE btrace_core.close_incident(
    p_incident_id UUID,
    p_closure_notes TEXT, -- Optional detailed notes on closure (e.g., PM completed, verified fix)
    p_closed_by UUID       -- User ID of the person closing the incident
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_incident_status TEXT;
BEGIN
    -- Check current status of the incident
    SELECT status INTO v_incident_status
    FROM btrace_core.incidents
    WHERE incident_id = p_incident_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Incident with ID % not found', p_incident_id;
    END IF;

    -- Check if the incident is already closed
    IF v_incident_status = 'closed' THEN
        RAISE NOTICE 'Incident % is already closed.', p_incident_id;
        RETURN;
    END IF;

    -- Enforce workflow: Incident must be resolved before it can be closed
    IF v_incident_status != 'resolved' THEN
         RAISE EXCEPTION 'Incident % must be in ''resolved'' status before it can be closed. Current status: ''%''', p_incident_id, v_incident_status;
    END IF;

    -- Update the incident record to mark it as closed
    -- The end_time should ideally have been set during resolution.
    -- If it wasn't, or if you want the 'closed' timestamp as the absolute end, you can set it here.
    -- Based on the schema's `idx_incidents_resolved_at` and common practice, end_time is often set on resolution.
    -- We will update updated_at/updated_by for audit purposes.
    UPDATE btrace_core.incidents
    SET
        status = 'closed',
        -- end_time = COALESCE(end_time, CURRENT_TIMESTAMP), -- Optional: Uncomment if end_time should be finalized on close
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_closed_by
    WHERE incident_id = p_incident_id;


    -- Add a timeline event to record the closure
    INSERT INTO btrace_core.incident_timeline (
        incident_id,
        event_type, -- Use a clear, specific event type
        event_time,
        description,
        created_by
    ) VALUES (
        p_incident_id,
        'incident_closed', -- Specific event type for clarity
        CURRENT_TIMESTAMP,
        COALESCE(LEFT(p_closure_notes, 2000), 'Incident formally closed.'), -- Truncate long notes and provide default
        p_closed_by
    );


    -- RAISE NOTICE 'Incident % closed successfully.', p_incident_id;

END;
$$;

COMMENT ON PROCEDURE btrace_core.close_incident IS
'Transitions a resolved incident to the final ''closed'' state, logs the event in the timeline, and updates audit fields. Enforces that only ''resolved'' incidents can be closed.';


--view to list incidents that are in the resolved state but not yet closed.
-- potentially past a certain age. this helps in identifying incidents that need to be formally closed 
---Business case: Ensures that incidents dont remain in a resolved limbo state indefinitely, prompting completion of the full incident lifecycle, including post-mortems
CREATE OR REPLACE VIEW btrace_core.resolved_incidents_pending_closure AS
SELECT
    i.incident_id,
    i.title,
    i.service_id,
    s.service_name,
    i.environment_id,
    e.environment_name,
    i.severity,
    i.resolved_at,
    EXTRACT(EPOCH FROM (NOW() - i.resolved_at)) / 3600.0 AS hours_since_resolution
FROM btrace_core.incidents i
LEFT JOIN btrace_core.services s ON i.service_id = s.service_id
LEFT JOIN btrace_core.environments e ON i.environment_id = e.environment_id
WHERE i.status = 'resolved'
  AND i.resolved_at < NOW() - INTERVAL '24 hours'; -- Or configurable threshold
COMMENT ON VIEW btrace_core.resolved_incidents_pending_closure IS 'Lists incidents resolved more than 24 hours ago that are awaiting formal closure. Used for follow-up and ensuring incident lifecycle completion.';



-- Procedure: Calculate Service Level Objectives
-- BUSINESS CASE:
-- Systematically evaluate and report on the compliance of defined Service Level Objectives (SLOs) for one or more services over a specified time period.
-- This procedure provides data-driven insights into service reliability, enabling Site Reliability Engineers (SREs) and service owners to make informed decisions
-- about system health, identify reliability risks, track error budget consumption, and validate if services are meeting their contractual or internal reliability targets.
-- Accurate SLO calculation is fundamental for proactive reliability management and effective incident response prioritization.
--
-- PURPOSE:
-- - Calculate compliance for SLOs stored in the `btrace_core.slos` table.
-- - Support calculating SLOs for a specific service or for all services.
-- - Allow specifying a custom time window for the calculation.
-- - Compute actual values based on relevant metric data from `btrace_core.metrics`.
-- - Determine compliance status (e.g., 'meets', 'fails') based on the defined target.
-- - Return the results in a structured format for reporting and dashboarding.
-- - Note: This example focuses on SLOs based on metric-based SLIs like error rates or latency. Incident-based SLOs would require a different calculation approach.

CREATE OR REPLACE PROCEDURE btrace_analytics.calculate_slos(
    p_service_id UUID DEFAULT NULL,      
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_DATE - INTERVAL '30 days'), 
    p_end_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_DATE                           
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_slo_record RECORD; 
    v_actual_value DOUBLE PRECISION;
    v_compliance_status VARCHAR(20);
    v_records_analyzed INTEGER;
BEGIN
    -- Validate input parameters
    IF p_start_date >= p_end_date THEN
        RAISE EXCEPTION 'Start date (%) must be before end date (%).', p_start_date, p_end_date;
    END IF;

    -- Create a temporary table to store the calculation results
    -- Using ON COMMIT DROP to automatically clean up at the end of the session/transaction
    CREATE TEMP TABLE IF NOT EXISTS temp_slo_results (
        slo_id UUID,
        service_id UUID,
        service_name VARCHAR(100),
        slo_description TEXT,
        metric_name VARCHAR(255), 
        target_value DOUBLE PRECISION, 
        actual_value DOUBLE PRECISION, 
        compliance_status VARCHAR(20), 
        measurement_period_start TIMESTAMP WITH TIME ZONE,
        measurement_period_end TIMESTAMP WITH TIME ZONE,
        records_analyzed INTEGER 
    ) ON COMMIT DROP;

    -- Clear any existing results in the temp table for this session
    TRUNCATE temp_slo_results;


    -- Loop through defined SLOs
    FOR v_slo_record IN
        SELECT
            s.slo_id,
            s.service_id,
            svc.service_name, 
            s.description AS slo_description,
            s.metric_name, 
            s.target 
        FROM btrace_core.slos s
        JOIN btrace_core.services svc ON s.service_id = svc.service_id
        WHERE s.is_active = TRUE 
          AND (p_service_id IS NULL OR s.service_id = p_service_id) 
    LOOP

        v_actual_value := NULL; 
        v_compliance_status := 'no_data'; 
        v_records_analyzed := 0; 

        -- Calculate the average value of the metric over the period for this service
        SELECT
            AVG(m.value), 
            COUNT(m.metric_id) 
        INTO
            v_actual_value,
            v_records_analyzed
        FROM btrace_core.metrics m
        WHERE m.service_id = v_slo_record.service_id
          AND m.metric_name = v_slo_record.metric_name 
          AND m.timestamp >= p_start_date
          AND m.timestamp < p_end_date; 


        -- Determine compliance based on the calculated value and the SLO target
        -- This logic assumes a "higher is better" SLO (e.g., success rate).
        -- For "lower is better" SLOs (e.g., error rate, latency), the comparison would flip.
        IF v_actual_value IS NOT NULL THEN
            -- Example: Assuming the SLO target is for a rate/metric where higher is better (e.g., success rate)
            IF v_actual_value >= v_slo_record.target THEN
                v_compliance_status := 'meets';
            ELSE
                v_compliance_status := 'fails';
            END IF;
        ELSE
            v_compliance_status := 'no_data';
            v_actual_value := 0; 
        END IF;


        -- Insert the calculated result for this SLO into the temporary table
        INSERT INTO temp_slo_results (
            slo_id,
            service_id,
            service_name,
            slo_description,
            metric_name,
            target_value,
            actual_value,
            compliance_status,
            measurement_period_start,
            measurement_period_end,
            records_analyzed
        ) VALUES (
            v_slo_record.slo_id,
            v_slo_record.service_id,
            v_slo_record.service_name,
            v_slo_record.slo_description,
            v_slo_record.metric_name,
            v_slo_record.target,
            COALESCE(v_actual_value, 0), 
            v_compliance_status,
            p_start_date,
            p_end_date,
            v_records_analyzed
        );

    END LOOP; 


    -- The procedure ends here. The calling session can then run:
    -- CALL btrace_analytics.calculate_slos(...);
    -- SELECT * FROM temp_slo_results;

END;
$$;

COMMENT ON PROCEDURE btrace_analytics.calculate_slos IS
'Calculates compliance for defined Service Level Objectives (SLOs) stored in btrace_core.slos. Supports filtering by service and custom time windows. Results are stored in a temporary table `temp_slo_results` for the session.';

-- BUSINESS CASE:
-- Provide a direct, programmatic interface to calculate the compliance of a single, specific SLO.
-- This is ideal for API endpoints, detailed dashboards, or automated checks that need the result for one SLO.
--
-- PURPOSE:
-- - Calculate the compliance for one SLO identified by slo_id.
-- - Return the result (target, actual value, status) directly as a record.
-- - Support custom time windows for the calculation.

CREATE OR REPLACE FUNCTION btrace_analytics.calculate_specific_slo(
    p_slo_id UUID,
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_DATE - INTERVAL '30 days'),
    p_end_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    slo_id UUID,
    service_id UUID,
    service_name VARCHAR(100),
    slo_description TEXT,
    metric_name VARCHAR(255),
    target_value DOUBLE PRECISION,
    actual_value DOUBLE PRECISION,
    compliance_status VARCHAR(20),
    measurement_period_start TIMESTAMP WITH TIME ZONE,
    measurement_period_end TIMESTAMP WITH TIME ZONE,
    records_analyzed INTEGER
)
AS $$
DECLARE
    v_slo_record RECORD;
    v_actual_value DOUBLE PRECISION;
    v_compliance_status VARCHAR(20);
    v_records_analyzed INTEGER;
BEGIN
    -- Input validation
    IF p_start_date >= p_end_date THEN
        RAISE EXCEPTION 'Start date must be before end date.';
    END IF;

    -- Fetch the SLO definition
    SELECT s.*, svc.service_name
    INTO v_slo_record
    FROM btrace_core.slos s
    JOIN btrace_core.services svc ON s.service_id = svc.service_id
    WHERE s.slo_id = p_slo_id AND s.is_active = TRUE;

    IF NOT FOUND THEN
       RAISE EXCEPTION 'Active SLO with ID % not found.', p_slo_id;
    END IF;

    -- Perform calculation (same logic as in the main procedure loop)
    -- Example: Simple average of the metric value over the period.
    SELECT AVG(m.value), COUNT(m.metric_id)
    INTO v_actual_value, v_records_analyzed
    FROM btrace_core.metrics m
    WHERE m.service_id = v_slo_record.service_id
      AND m.metric_name = v_slo_record.metric_name
      AND m.timestamp >= p_start_date
      AND m.timestamp < p_end_date;

    IF v_actual_value IS NOT NULL THEN
        -- Example: Assuming the SLO target is for a rate/metric where higher is better (e.g., success rate)
        IF v_actual_value >= v_slo_record.target THEN
            v_compliance_status := 'meets';
        ELSE
            v_compliance_status := 'fails';
        END IF;
    ELSE
        v_compliance_status := 'no_data';
        v_actual_value := 0;
    END IF;

    -- Return the single result row
    RETURN QUERY SELECT
        v_slo_record.slo_id,
        v_slo_record.service_id,
        v_slo_record.service_name,
        v_slo_record.description,
        v_slo_record.metric_name,
        v_slo_record.target,
        COALESCE(v_actual_value, 0),
        v_compliance_status,
        p_start_date,
        p_end_date,
        v_records_analyzed;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION btrace_analytics.calculate_specific_slo IS 'Calculates compliance for a single, specified SLO and returns the result directly.';


-- BUSINESS CASE:
-- Provide a quick, at-a-glance overview of the current compliance status for all active SLOs.
-- This view simplifies monitoring and is ideal for dashboards showing overall service health.
--
-- PURPOSE:
-- - Display key details and the latest compliance status for every active SLO.
-- - Join relevant tables to provide context (service name, SLO description).
-- - *Note: This view shows SLO definitions. For *calculated* current status,
--          a Materialized View based on historical calculations is recommended.*

CREATE OR REPLACE VIEW btrace_analytics.current_slo_status AS
SELECT
    s.slo_id,
    s.service_id,
    svc.service_name,
    s.description AS slo_description,
    s.metric_name,
    s.target AS target_value,
    -- Placeholder for calculated status. In a full implementation,
    -- this would join with a table of recent calculation results.
    'requires_calculation'::VARCHAR(20) AS compliance_status,
    s.is_active
FROM btrace_core.slos s
JOIN btrace_core.services svc ON s.service_id = svc.service_id
WHERE s.is_active = TRUE;

COMMENT ON VIEW btrace_analytics.current_slo_status IS 'Shows the definitions and a placeholder for the current compliance status of all active SLOs. Requires integration with calculation logic or results table for actual status.';

-- BUSINESS CASE:
-- Maintain a permanent, time-series log of SLO compliance calculations.
-- This historical data is crucial for trend analysis, burn rate calculations, long-term reporting,
-- and understanding the reliability journey of services over time.
--
-- PURPOSE:
-- - Store the outcome of SLO calculations (actual value, status) with a timestamp.
-- - Enable querying SLO performance over weeks, months, or years.
-- - Facilitate the calculation of error budget burn rates.
-- - Support historical SLO dashboards and executive reporting.

CREATE TABLE IF NOT EXISTS btrace_analytics.slo_historical_results (
    result_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    slo_id UUID NOT NULL,
    calculation_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    measurement_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    measurement_period_end TIMESTAMP WITH TIME ZONE NOT NULL, -- <<< PARTITION KEY COLUMN
    actual_value DOUBLE PRECISION,
    compliance_status VARCHAR(20) NOT NULL CHECK (compliance_status IN ('meets', 'fails', 'no_data')),
    records_analyzed INTEGER,
    calculated_by UUID,
    metadata JSONB,
    -- PRIMARY KEY must include the partition key column
    CONSTRAINT pk_slo_historical_results PRIMARY KEY (result_id, measurement_period_end),
    -- Foreign Key
    CONSTRAINT fk_slo_hist_res_slo_id FOREIGN KEY (slo_id) REFERENCES btrace_core.slos(slo_id) ON DELETE CASCADE
) PARTITION BY RANGE (measurement_period_end);

-- Index for looking up results for a specific SLO
CREATE INDEX IF NOT EXISTS idx_slo_hist_results_slo_id ON btrace_analytics.slo_historical_results (slo_id, measurement_period_end DESC);
-- Index for looking up results by time window
CREATE INDEX IF NOT EXISTS idx_slo_hist_results_period ON btrace_analytics.slo_historical_results (measurement_period_start, measurement_period_end);
-- Index for filtering by status
CREATE INDEX IF NOT EXISTS idx_slo_hist_results_status ON btrace_analytics.slo_historical_results (compliance_status);

COMMENT ON TABLE btrace_analytics.slo_historical_results IS 'Stores historical results of SLO compliance calculations for trend analysis and reporting.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.result_id IS 'Unique identifier for this specific calculation result.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.slo_id IS 'References the SLO definition this result is for.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.calculation_timestamp IS 'When this specific calculation was performed.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.measurement_period_start IS 'Start time of the period over which the SLO was evaluated.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.measurement_period_end IS 'End time of the period over which the SLO was evaluated. Used for partitioning.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.actual_value IS 'The calculated value of the SLI for the period.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.compliance_status IS 'Whether the SLO target was met, failed, or no data was available.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.records_analyzed IS 'Number of data points used in the calculation.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.calculated_by IS 'Optional: User or process ID that triggered the calculation.';
COMMENT ON COLUMN btrace_analytics.slo_historical_results.metadata IS 'Optional: JSONB for storing extra context (parameters, version).';

-- Example of creating an initial partition (recommended to automate this)
-- You need to create at least one partition for it to work.
-- CREATE TABLE btrace_analytics.slo_historical_results_y2025_m04 PARTITION OF btrace_analytics.slo_historical_results
--     FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

-- BUSINESS CASE:
-- Provide a high-performance, at-a-glance overview of the current compliance status for all active SLOs.
-- This materialized view simplifies monitoring, is ideal for dashboards, and avoids expensive real-time calculations.
--
-- PURPOSE:
-- - Store the results of a recent SLO compliance calculation (e.g., last 7 days) for all active SLOs.
-- - Enable fast querying for SLO dashboards and health overviews.
-- - Must be refreshed periodically (e.g., hourly, daily) to show current status.
-- - *Note: Requires the `btrace_analytics.slo_historical_results` table to be populated.*

-- This view gets the *most recent* calculation result for each active SLO.
CREATE MATERIALIZED VIEW IF NOT EXISTS btrace_analytics.current_slo_status_mv AS
WITH latest_calculation_per_slo AS (
    SELECT DISTINCT ON (shr.slo_id)
        shr.slo_id,
        shr.actual_value,
        shr.compliance_status,
        shr.measurement_period_end,
        shr.records_analyzed
    FROM btrace_analytics.slo_historical_results shr
    ORDER BY shr.slo_id, shr.measurement_period_end DESC
)
SELECT
    s.slo_id,
    s.service_id,
    svc.service_name,
    s.description AS slo_description,
    s.metric_name,
    s.target AS target_value,
    COALESCE(lc.actual_value, 0) AS actual_value,
    COALESCE(lc.compliance_status, 'no_data') AS compliance_status,
    lc.measurement_period_end,
    lc.records_analyzed
FROM btrace_core.slos s
JOIN btrace_core.services svc ON s.service_id = svc.service_id
LEFT JOIN latest_calculation_per_slo lc ON s.slo_id = lc.slo_id
WHERE s.is_active = TRUE;

COMMENT ON MATERIALIZED VIEW btrace_analytics.current_slo_status_mv IS 'Stores the most recent calculated compliance status for all active SLOs. Requires periodic refresh.';

-- Indexes for the Materialized View
CREATE UNIQUE INDEX IF NOT EXISTS idx_current_slo_status_mv_slo_id ON btrace_analytics.current_slo_status_mv (slo_id);
CREATE INDEX IF NOT EXISTS idx_current_slo_status_mv_service_id ON btrace_analytics.current_slo_status_mv (service_id);
CREATE INDEX IF NOT EXISTS idx_current_slo_status_mv_status ON btrace_analytics.current_slo_status_mv (compliance_status);

-- Remember to refresh the materialized view after populating slo_historical_results
-- REFRESH MATERIALIZED VIEW btrace_analytics.current_slo_status_mv;

-- Index for fast lookup by service
CREATE UNIQUE INDEX idx_current_slo_status_mv_slo_id ON btrace_analytics.current_slo_status_mv (slo_id);
CREATE INDEX idx_current_slo_status_mv_service_id ON btrace_analytics.current_slo_status_mv (service_id);
CREATE INDEX idx_current_slo_status_mv_status ON btrace_analytics.current_slo_status_mv (compliance_status);

-- Example refresh command (can be scheduled with pg_cron)
-- REFRESH MATERIALIZED VIEW btrace_analytics.current_slo_status_mv;


-- Procedure: Anonymize Data Subject
CREATE OR REPLACE PROCEDURE btrace_gov.anonymize_data_subject(
    p_subject_id UUID,
    p_requested_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subject_type TEXT;
    v_identifier_key TEXT;
    v_identifier_value TEXT;
BEGIN
    -- Get subject details
    SELECT subject_type, identifier_key, identifier_value
    INTO v_subject_type, v_identifier_key, v_identifier_value
    FROM btrace_gov.data_subjects
    WHERE subject_id = p_subject_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Data subject with ID % not found', p_subject_id;
    END IF;
    
    -- Log the anonymization request
    INSERT INTO btrace_gov.subject_access_requests (
        subject_id,
        request_type,
        request_date,
        status,
        due_date,
        notes,
        assigned_to
    ) VALUES (
        p_subject_id,
        'erasure',
        CURRENT_TIMESTAMP,
        'completed',
        CURRENT_TIMESTAMP,
        'Data anonymization requested through procedure',
        p_requested_by
    );
    
    -- Anonymize traces
    UPDATE btrace_core.spans
    SET attributes = jsonb_set(attributes, ARRAY[v_identifier_key], '"ANONYMIZED"')
    WHERE attributes ? v_identifier_key
    AND attributes->>v_identifier_key = v_identifier_value;
    
    -- Anonymize logs
    UPDATE btrace_core.logs
    SET attributes = jsonb_set(attributes, ARRAY[v_identifier_key], '"ANONYMIZED"')
    WHERE attributes ? v_identifier_key
    AND attributes->>v_identifier_key = v_identifier_value;
    
    -- Anonymize metrics
    UPDATE btrace_core.metrics
    SET attributes = jsonb_set(attributes, ARRAY[v_identifier_key], '"ANONYMIZED"')
    WHERE attributes ? v_identifier_key
    AND attributes->>v_identifier_key = v_identifier_value;
    
    -- Mark the subject as anonymized
    UPDATE btrace_gov.data_subjects
    SET identifier_value = 'ANONYMIZED-' || uuid_generate_v4()
    WHERE subject_id = p_subject_id;
    
    COMMIT;
END;
$$;
COMMENT ON PROCEDURE btrace_gov.anonymize_data_subject IS 'Anonymizes all data for a specific data subject to comply with GDPR right to erasure';


-- BUSINESS CASE:
-- Execute the "Right to Erasure" (also known as "Right to be Forgotten") as mandated by privacy regulations like GDPR.
-- This procedure systematically anonymizes or removes personal data associated with a specific data subject across core telemetry data stores (traces, logs, metrics).
-- It ensures compliance when a data subject requests the deletion of their personal information.
-- The procedure also logs the action as a completed 'erasure' request in the DSAR tracking system for audit purposes.
--
-- PURPOSE:
-- - Permanently anonymize identifiable information linked to a specific data subject within trace spans, logs, and metrics.
-- - Update the core `btrace_gov.data_subjects` record to indicate the data has been anonymized.
-- - Log the anonymization event as a completed 'erasure' Subject Access Request (DSAR) for compliance auditing.
-- - Handle cases where the specific identifier key might not exist in the attributes JSONB by using jsonb_set safely.

CREATE OR REPLACE PROCEDURE btrace_gov.anonymize_data_subject(
    p_subject_id UUID,
    p_requested_by UUID -- User ID initiating the anonymization (e.g., DPO, admin)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subject_record RECORD; -- Use RECORD to fetch multiple fields
    v_anonymized_identifier TEXT;
    v_updated_spans INTEGER := 0;
    v_updated_logs INTEGER := 0;
    v_updated_metrics INTEGER := 0;
BEGIN
    -- Get subject details for the identifier key and value
    SELECT subject_id, subject_type, identifier_key, identifier_value
    INTO v_subject_record -- Assign to the record variable
    FROM btrace_gov.data_subjects
    WHERE subject_id = p_subject_id;

    -- Check if the data subject exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Data subject with ID % not found', p_subject_id;
    END IF;

    -- Optional: Check if the subject is already anonymized
    IF v_subject_record.identifier_value LIKE 'ANONYMIZED-%' THEN
        RAISE NOTICE 'Data subject % is already anonymized.', p_subject_id;
        RETURN;
    END IF;

    -- Generate a unique anonymized identifier
    v_anonymized_identifier := 'ANONYMIZED-' || gen_random_uuid(); -- Use gen_random_uuid() if uuid_generate_v4() is problematic


    -- Log the anonymization action as a completed 'erasure' DSAR
    -- This provides an audit trail for compliance.
    INSERT INTO btrace_gov.subject_access_requests (
        subject_id,
        request_type,
        request_date,
        status,
        due_date,
        notes,
        assigned_to,
        created_by -- Log who initiated the request internally
        -- completed_date is often set for 'completed' requests, but CURRENT_TIMESTAMP is fine here
    ) VALUES (
        p_subject_id,
        'erasure', -- Correct request type for Right to Erasure
        CURRENT_TIMESTAMP,
        'completed', -- Mark as completed immediately
        CURRENT_TIMESTAMP, -- Set due date to now as it's completed
        format('Data anonymization executed via procedure btrace_gov.anonymize_data_subject by user %L.', p_requested_by),
        p_requested_by, -- Assign the requester
        p_requested_by -- Record who created this log entry
    );


    -- Anonymize data in btrace_core.spans
    -- Use jsonb_set to replace the value, even if the key doesn't exist, it won't error.
    -- We filter first to only update rows that actually contain the identifier.
    UPDATE btrace_core.spans
    SET attributes = jsonb_set(attributes, ARRAY[v_subject_record.identifier_key], to_jsonb(v_anonymized_identifier))
    WHERE attributes ? v_subject_record.identifier_key -- Check if key exists
      AND attributes->>v_subject_record.identifier_key = v_subject_record.identifier_value; -- Check if value matches

    -- Capture the number of affected rows
    GET DIAGNOSTICS v_updated_spans = ROW_COUNT;


    -- Anonymize data in btrace_core.logs
    UPDATE btrace_core.logs
    SET attributes = jsonb_set(attributes, ARRAY[v_subject_record.identifier_key], to_jsonb(v_anonymized_identifier))
    WHERE attributes ? v_subject_record.identifier_key
      AND attributes->>v_subject_record.identifier_key = v_subject_record.identifier_value;

    GET DIAGNOSTICS v_updated_logs = ROW_COUNT;


    -- Anonymize data in btrace_core.metrics
    UPDATE btrace_core.metrics
    SET attributes = jsonb_set(attributes, ARRAY[v_subject_record.identifier_key], to_jsonb(v_anonymized_identifier))
    WHERE attributes ? v_subject_record.identifier_key
      AND attributes->>v_subject_record.identifier_key = v_subject_record.identifier_value;

    GET DIAGNOSTICS v_updated_metrics = ROW_COUNT;


    -- Mark the subject record itself as anonymized in btrace_gov.data_subjects
    -- We only update the identifier_value. Other PII fields should ideally be cleared or set to NULL if they existed.
    -- Based on the schema, fields like first_name, last_name, email, phone might need clearing.
    -- Let's assume for now, the identifier_value is the main link, and others are cleared separately or were part of the span/log/metric data.
    UPDATE btrace_gov.data_subjects
    SET
        identifier_value = v_anonymized_identifier,
        -- Clear other PII fields if they exist and were populated
        first_name = NULL,
        last_name = NULL,
        email = NULL,
        phone = NULL,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_requested_by
    WHERE subject_id = p_subject_id;


    -- Optional: Log a summary of changes to a dedicated audit log or notice
    RAISE NOTICE 'Data subject % anonymized. Updated Spans: %, Logs: %, Metrics: %.',
                 p_subject_id, v_updated_spans, v_updated_logs, v_updated_metrics;

    -- COMMIT is generally not needed in a procedure unless specific transaction control is required.
    -- The calling transaction context handles this.

END;
$$;

COMMENT ON PROCEDURE btrace_gov.anonymize_data_subject IS
'Anonymizes personal data for a specific data subject across traces (spans), logs, and metrics to fulfill the "Right to Erasure" (GDPR). Logs the action as a completed DSAR.';

-- BUSINESS CASE:
-- Permanently remove the record of a data subject from the `btrace_gov.data_subjects` registry.
-- This is typically done after data has been anonymized and a retention period has expired,
-- or as part of a final, manual data cleansing process, in accordance with data retention policies.
-- Note: This procedure does NOT delete the underlying anonymized or raw telemetry data (spans, logs, metrics)
-- as that is often impractical due to volume and structure. Anonymization is the primary method for erasure.
--
-- PURPOSE:
-- - Delete the row corresponding to `p_subject_id` from the `btrace_gov.data_subjects` table.
-- - Log the deletion attempt (success or failure) for audit purposes, potentially in `btrace_audit.data_access_logs`
--   or a dedicated deletion log (conceptual, as no specific table was defined for this in the schema).
-- - Handle cases where the subject might not exist gracefully.
-- - Optionally, prevent deletion if the subject record indicates data has not been anonymized yet.

CREATE OR REPLACE PROCEDURE btrace_gov.delete_data_subject(
    p_subject_id UUID,
    p_deleted_by UUID -- User ID initiating the deletion (e.g., DPO, Admin)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subject_exists BOOLEAN;
    v_is_anonymized BOOLEAN;
    v_subject_identifier TEXT; -- For audit log message
BEGIN
    -- Check if the data subject record exists
    SELECT
        TRUE,
        -- Check if the identifier_value indicates anonymization has occurred
        (identifier_value LIKE 'ANONYMIZED-%'),
        identifier_value -- Get the identifier for logging
    INTO
        v_subject_exists,
        v_is_anonymized,
        v_subject_identifier
    FROM btrace_gov.data_subjects
    WHERE subject_id = p_subject_id;

    -- If the subject record doesn't exist, log and exit
    IF NOT v_subject_exists THEN
        -- Optionally log this attempt in an audit table
        -- INSERT INTO btrace_audit.data_access_logs (...) VALUES (...);
        RAISE NOTICE 'Data subject record with ID % does not exist. Nothing to delete.', p_subject_id;
        RETURN;
    END IF;

    -- Optional: Enforce a check that anonymization happened before allowing deletion
    -- IF NOT v_is_anonymized THEN
    --     RAISE EXCEPTION 'Data subject % must be anonymized before the record can be deleted.', p_subject_id;
    -- END IF;

    -- Log the deletion attempt/action (conceptual - assumes an audit log table or mechanism)
    -- Example conceptual log entry (adjust table/column names as needed if an audit log table exists):
    -- INSERT INTO btrace_audit.data_access_logs (user_id, action, resource_type, resource_id, details, action_timestamp)
    -- VALUES (p_deleted_by, 'DELETE_SUBJECT_RECORD', 'data_subject', p_subject_id,
    --         format('Deleted data subject record (Identifier: %L). Anonymized: %L.', v_subject_identifier, v_is_anonymized),
    --         CURRENT_TIMESTAMP);

    -- Perform the deletion of the data subject record from the registry
    DELETE FROM btrace_gov.data_subjects
    WHERE subject_id = p_subject_id;


    -- Log successful completion
    RAISE NOTICE 'Data subject record % (Identifier: %) deleted by user %.', p_subject_id, v_subject_identifier, p_deleted_by;

END;
$$;

COMMENT ON PROCEDURE btrace_gov.delete_data_subject IS
'Permanently deletes a data subject record from the btrace_gov.data_subjects registry. This should typically be done after anonymization and according to data retention policies. Does not affect underlying telemetry data.';


-- BUSINESS CASE:
-- Provide a simple and efficient way to look up the internal `subject_id` using the common external identifier (key + value).
-- This simplifies workflows where the internal UUID is not readily available, such as when handling a DSAR request
-- or initiating an anonymization process based on user-provided information like an email address.
--
-- PURPOSE:
-- - Find the `subject_id` (UUID) for a data subject based on their `identifier_key` (e.g., 'email', 'user_id') and `identifier_value` (e.g., 'user@example.com', 'usr_abc123').
-- - Return the UUID if a matching record is found.
-- - Return NULL if no matching record is found.
-- - Be efficient by leveraging appropriate indexes (implicitly or explicitly).

CREATE OR REPLACE FUNCTION btrace_gov.find_data_subject_by_identifier(
    p_identifier_key TEXT,
    p_identifier_value TEXT
)
RETURNS UUID -- Returns the subject_id UUID or NULL
AS $$
DECLARE
    v_subject_id UUID;
BEGIN
    -- Query the data_subjects table to find the matching record
    SELECT subject_id
    INTO v_subject_id
    FROM btrace_gov.data_subjects
    WHERE identifier_key = p_identifier_key
      AND identifier_value = p_identifier_value;

    -- Return the found subject_id, or NULL if not found
    RETURN v_subject_id;
END;
$$ LANGUAGE plpgsql STABLE; -- STABLE because it doesn't modify data and return value depends only on input

COMMENT ON FUNCTION btrace_gov.find_data_subject_by_identifier IS
'Finds the internal subject_id UUID for a data subject based on their identifier key (e.g., ''email'') and identifier value (e.g., ''user@example.com''). Returns NULL if not found.';


-- Procedure: Check Data Quality
-- BUSINESS CASE:
-- Automate the execution of predefined data quality rules to continuously assess the health, accuracy, and completeness of core observability data assets (e.g., traces, logs, metrics).
-- This procedure is essential for maintaining trust in the data used for monitoring, alerting, SLOs, and incident response.
-- By identifying data quality issues early, it enables platform teams and SREs to address instrumentation problems, pipeline errors, or schema inconsistencies proactively,
-- preventing downstream failures in observability and reliability efforts.
--
-- PURPOSE:
-- - Execute one or more data quality checks defined in `btrace_gov.data_quality_rules`.
-- - Support running a check for a specific rule (`p_rule_id`), all rules for a specific asset (`p_asset_id`), or all active rules.
-- - Perform the actual data validation logic based on the rule's definition.
-- - Record the results (measured value, status, error count, sample errors) in `btrace_gov.data_quality_metrics`.
-- - Provide a structured way to programmatically trigger data quality assessments.

CREATE OR REPLACE PROCEDURE btrace_gov.check_data_quality(
    p_asset_id UUID DEFAULT NULL, -- Optional: Check all rules for this asset
    p_rule_id UUID DEFAULT NULL   -- Optional: Check only this specific rule
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rule RECORD;
    v_error_count INTEGER;
    v_total_count INTEGER;
    v_measured_value DOUBLE PRECISION; -- Use DOUBLE PRECISION as per schema
    v_status VARCHAR(20);             -- Use VARCHAR(20) as per schema
    v_sample_errors TEXT;             -- Use TEXT, aggregate sample errors into a single string
    v_query TEXT;                     -- To hold dynamic query text
    v_target_table TEXT;              -- To hold the name of the table to query
    v_target_column TEXT;             -- To hold the name of the column to check
BEGIN
    -- Input validation: Cannot specify both asset_id and rule_id
    IF p_asset_id IS NOT NULL AND p_rule_id IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot specify both p_asset_id and p_rule_id. Please provide only one.';
    END IF;

    -- Process specific rule if provided
    IF p_rule_id IS NOT NULL THEN
        -- Fetch the specific rule details
        SELECT * INTO v_rule
        FROM btrace_gov.data_quality_rules
        WHERE rule_id = p_rule_id AND is_active = TRUE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Active data quality rule with ID % not found', p_rule_id;
        END IF;

        -- Determine the target table based on the associated asset
        -- This requires joining with data_assets to get the asset_type or name
        SELECT da.asset_name -- Assuming asset_name maps to table name (e.g., 'traces', 'logs')
        INTO v_target_table
        FROM btrace_gov.data_quality_rules dqr
        JOIN btrace_gov.data_assets da ON dqr.asset_id = da.asset_id
        WHERE dqr.rule_id = p_rule_id;

        IF NOT FOUND THEN
            RAISE NOTICE 'Could not determine target table for rule %. Skipping.', p_rule_id;
            RETURN;
        END IF;

        -- Initialize variables for this rule execution
        v_error_count := 0;
        v_total_count := 0;
        v_measured_value := 0;
        v_status := 'fail'; -- Default status
        v_sample_errors := NULL;

        -- Execute rule-specific check based on rule_type
        -- Note: This is a simplified example for 'not_null' checks.
        -- More complex rule types (e.g., 'unique', 'format', 'range') would require more sophisticated logic.
        IF v_rule.rule_type = 'not_null' THEN
            -- Example: Check for NOT NULL constraint on a column
            -- Assume rule_definition contains the column name, e.g., 'trace_id'
            v_target_column := v_rule.rule_definition; -- Or parse from JSON if rule_definition is JSONB

            -- Validate column name to prevent SQL injection (basic check)
            -- A more robust system would use a whitelist or information_schema lookup
            IF v_target_column IS NULL OR LENGTH(TRIM(v_target_column)) = 0 THEN
                RAISE EXCEPTION 'Invalid column name specified in rule_definition for rule %', p_rule_id;
            END IF;

            -- Construct dynamic query based on the target table
            -- This example assumes a common timestamp column for filtering (e.g., start_time, timestamp)
            -- You might need different logic for different tables (metrics, logs).
            v_query := format('
                SELECT
                    COUNT(*) FILTER (WHERE %I IS NULL) AS error_count,
                    COUNT(*) AS total_count,
                    -- Aggregate a sample of IDs with errors (limit to 5 for brevity)
                    STRING_AGG(%I::TEXT, '', '' ORDER BY %I LIMIT 5) AS sample_errors
                FROM btrace_core.%I
                WHERE
                    CASE
                        WHEN ''%I'' = ''traces'' THEN start_time >= CURRENT_DATE - INTERVAL ''1 day''
                        WHEN ''%I'' = ''logs'' THEN timestamp >= CURRENT_DATE - INTERVAL ''1 day''
                        WHEN ''%I'' = ''metrics'' THEN timestamp >= CURRENT_DATE - INTERVAL ''1 day''
                        ELSE TRUE -- Check all if no specific time column is known
                    END
            ', v_target_column, -- For error count filter
               'trace_id',      -- Example ID column for sample errors (needs dynamic logic)
               'trace_id',      -- Order by for sample errors (needs dynamic logic)
               v_target_table,  -- FROM table
               v_target_table, v_target_table, v_target_table -- For CASE condition
            );

            -- For logs/metrics, you'd change 'trace_id' to 'log_id'/'metric_id' respectively.
            -- This is a simplification. A robust system would determine the correct ID column.

            -- Execute the dynamic query
            -- RAISE NOTICE 'Executing Query: %', v_query; -- For debugging
            BEGIN
                EXECUTE v_query INTO v_error_count, v_total_count, v_sample_errors;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Error executing data quality check for rule %: %', p_rule_id, SQLERRM;
                    -- Log the error in metrics with a specific status or note?
                    v_status := 'error';
                    v_sample_errors := LEFT(SQLERRM, 1000); -- Truncate error message
                    -- Insert an error metric record?
                    INSERT INTO btrace_gov.data_quality_metrics (
                        rule_id, measurement_time, measured_value, status,
                        records_analyzed, error_count, sample_errors
                    ) VALUES (
                        p_rule_id, CURRENT_TIMESTAMP, 0, 'error',
                        0, 0, v_sample_errors
                    );
                    RETURN; -- Exit if the query itself fails
            END;

            -- Calculate measured value (e.g., % of non-null records)
            IF v_total_count > 0 THEN
                v_measured_value := ((v_total_count - v_error_count) * 100.0) / v_total_count;
            ELSE
                v_measured_value := 100; -- If no records, consider it 100% compliant
            END IF;

            -- Determine status based on error count or a threshold (rule might have one)
            IF v_error_count = 0 THEN
                v_status := 'pass';
            ELSE
                v_status := 'fail';
            END IF;

            -- Insert the calculated metric result into the history table
            INSERT INTO btrace_gov.data_quality_metrics (
                rule_id,
                measurement_time,
                measured_value, -- DOUBLE PRECISION
                status,         -- VARCHAR(20)
                records_analyzed,
                error_count,
                sample_errors   -- TEXT
            ) VALUES (
                p_rule_id,
                CURRENT_TIMESTAMP,
                v_measured_value,
                v_status,
                v_total_count,
                v_error_count,
                v_sample_errors -- Already aggregated string
            );

        -- Add ELSIF blocks for other rule types like 'unique', 'format', 'range'
        -- ELSIF v_rule.rule_type = 'unique' THEN
        --    ...
        -- ELSIF v_rule.rule_type = 'format' THEN
        --    ...
        ELSE
            RAISE WARNING 'Rule type ''%'' for rule % is not yet implemented in this procedure.', v_rule.rule_type, p_rule_id;
            -- Optionally log this as a 'not_implemented' status in metrics
            INSERT INTO btrace_gov.data_quality_metrics (
                rule_id, measurement_time, measured_value, status,
                records_analyzed, error_count, sample_errors
            ) VALUES (
                p_rule_id, CURRENT_TIMESTAMP, 0, 'not_implemented',
                0, 0, format('Rule type ''%s'' not supported by check_data_quality procedure.', v_rule.rule_type)
            );
        END IF;

    -- Process all rules for an asset if provided
    ELSIF p_asset_id IS NOT NULL THEN
        -- Loop through all active rules for the given asset and call this procedure recursively
        FOR v_rule IN
            SELECT * FROM btrace_gov.data_quality_rules
            WHERE asset_id = p_asset_id AND is_active = TRUE
        LOOP
            -- Call the procedure for each rule ID
            CALL btrace_gov.check_data_quality(p_rule_id := v_rule.rule_id);
            -- Note: Using named parameter syntax for clarity
        END LOOP;

    -- Process all active rules if no parameters provided
    ELSE
        -- Loop through all active rules in the system and call this procedure recursively
        FOR v_rule IN
            SELECT * FROM btrace_gov.data_quality_rules
            WHERE is_active = TRUE
        LOOP
            CALL btrace_gov.check_data_quality(p_rule_id := v_rule.rule_id);
        END LOOP;
    END IF;

    -- COMMIT is generally not needed in a procedure unless specific transaction control is required.
    -- The calling transaction context handles this.

END;
$$;

COMMENT ON PROCEDURE btrace_gov.check_data_quality IS
'Executes data quality checks defined in btrace_gov.data_quality_rules for a specific rule, all rules of an asset, or all active rules. Records results in btrace_gov.data_quality_metrics.';


--Example 
CREATE OR REPLACE FUNCTION btrace_gov.get_asset_table_name(p_asset_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_table_name TEXT;
BEGIN
    SELECT LOWER(REPLACE(da.asset_name, ' ', '_')) -- Basic sanitization
    INTO v_table_name
    FROM btrace_gov.data_assets da
    WHERE da.asset_id = p_asset_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Optional: Validate against known core tables
    IF v_table_name NOT IN ('traces', 'logs', 'metrics', 'spans') THEN
        RAISE WARNING 'Asset name % maps to unknown or unsupported core table %', p_asset_id, v_table_name;
        RETURN NULL;
    END IF;

    RETURN v_table_name;
END;
$$ LANGUAGE plpgsql STABLE;


-- Data Catalog: Data Assets
CREATE TABLE btrace_gov.data_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_name VARCHAR(100) NOT NULL,
    description TEXT,
    asset_type VARCHAR(50) NOT NULL, -- e.g., 'table', 'stream', 'api'
    domain_id UUID,
    owner_id UUID,
    steward_id UUID,
    classification VARCHAR(20) NOT NULL, -- e.g., 'public', 'internal', 'confidential'
    retention_policy VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_asset_name UNIQUE (asset_name),
    FOREIGN KEY (domain_id) REFERENCES btrace_gov.data_domains(domain_id) ON DELETE SET NULL,
    FOREIGN KEY (owner_id) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (steward_id) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL
);

COMMENT ON TABLE btrace_gov.data_assets IS 'Inventory of data assets in the organization';
COMMENT ON COLUMN btrace_gov.data_assets.asset_type IS 'Type of asset (e.g., database, file, API)';
COMMENT ON COLUMN btrace_gov.data_assets.classification IS 'Data classification level (e.g., public, internal, confidential)';

-- Example Indexes (add if not already present in the full schema script)
CREATE INDEX idx_data_assets_domain_id ON btrace_gov.data_assets (domain_id);
CREATE INDEX idx_data_assets_owner_id ON btrace_gov.data_assets (owner_id);
CREATE INDEX idx_data_assets_steward_id ON btrace_gov.data_assets (steward_id);
CREATE INDEX idx_data_assets_type ON btrace_gov.data_assets (asset_type);
CREATE INDEX idx_data_assets_classification ON btrace_gov.data_assets (classification);

-- constraint (adjust list as needed)
ALTER TABLE btrace_gov.data_assets
ADD CONSTRAINT chk_asset_type
CHECK (asset_type IN ('table', 'view', 'stream', 'api', 'file', 'dashboard'));

-- constraint (adjust list as needed)
ALTER TABLE btrace_gov.data_assets
ADD CONSTRAINT chk_classification
CHECK (classification IN ('public', 'internal', 'confidential', 'restricted'));

-- BUSINESS CASE:
-- Provide a clear, structured view of how data flows through the organization's systems by generating lineage reports.
-- This is crucial for impact analysis (e.g., "What downstream systems are affected if this source changes?"),
-- root cause analysis of data issues, compliance audits (e.g., tracing the path of sensitive data),
-- and understanding the dependencies between data assets. It empowers data stewards, engineers, and analysts
-- to make informed decisions about data changes and migrations.
--
-- PURPOSE:
-- - Generate a data lineage report for either a specific data asset or the entire data ecosystem.
-- - Store the generated report content in the `btrace_analytics.reports` table for later retrieval.
-- - Support configurable report depth to limit complexity.
-- - Provide both upstream (source) and downstream (dependent) lineage views for a specific asset.
-- - Use a recursive CTE to traverse the lineage graph up to the specified depth.

CREATE OR REPLACE PROCEDURE btrace_gov.generate_data_lineage_report(
    p_asset_id UUID DEFAULT NULL, -- Optional: Generate report for this specific asset. If NULL, generates for all.
    p_depth INTEGER DEFAULT 3     -- Optional: Maximum depth of lineage to traverse (to prevent infinite loops).
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_report_id UUID;
    v_report_name TEXT;
    v_report_content TEXT := ''; -- Use TEXT for potentially large content
    v_lineage_record RECORD;
    v_asset_name TEXT; -- To store the name of the specific asset being reported on
BEGIN
    -- Validate input parameter
    IF p_depth < 0 THEN
        RAISE EXCEPTION 'p_depth must be a non-negative integer. Provided value: %', p_depth;
    END IF;

    -- Determine the report name
    IF p_asset_id IS NOT NULL THEN
        -- Fetch the asset name for the specific report title
        SELECT asset_name INTO v_asset_name
        FROM btrace_gov.data_assets
        WHERE asset_id = p_asset_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Data asset with ID % not found.', p_asset_id;
        END IF;
        v_report_name := format('Data Lineage Report - %I (Depth: %s)', v_asset_name, p_depth);
    ELSE
        v_report_name := format('Data Lineage Report - All Assets (Depth: %s)', p_depth);
    END IF;

    -- Create the initial report record in btrace_analytics.reports
    INSERT INTO btrace_analytics.reports (
        report_name,
        report_type, -- Should match the report type defined in the schema
        report_config, -- Store parameters used for generation
        created_by -- Use a more robust method to identify the creator if possible
    ) VALUES (
        v_report_name,
        'data_lineage', -- Use a consistent, descriptive report type
        jsonb_build_object(
            'generated_for_asset_id', p_asset_id,
            'requested_depth', p_depth,
            'generated_at', CURRENT_TIMESTAMP
        ),
        -- current_user returns the database role name, which might not be a UUID.
        -- If you have a way to get the actual user UUID (e.g., from application context),
        -- use that. Otherwise, storing the role name as TEXT might be necessary.
        -- For now, assuming created_by is UUID, we use NULL or a system user UUID.
        -- Let's assume a system user or leave it NULL if allowed.
        NULL -- Or a specific system user UUID if applicable
    ) RETURNING report_id INTO v_report_id;


    -- Generate the lineage content based on the parameters
    IF p_asset_id IS NULL THEN
        -- === Full Lineage Report for All Assets ===
        v_report_content := format('DATA LINEAGE REPORT - ALL ASSETS (Max Depth: %s)' || E'\n', p_depth);
        v_report_content := v_report_content || repeat('=', 50) || E'\n\n';

        -- Note: The original logic for "all assets without parents" is flawed for a full graph view.
        -- A better approach for a full report is to find root nodes (no incoming edges)
        -- and then traverse downstream from each, or use a more complex graph traversal.
        -- For simplicity here, we'll adapt the logic to show a hierarchical view starting from roots.

        FOR v_lineage_record IN
            WITH RECURSIVE lineage_tree AS (
                -- Base case: Root assets (assets that are not targets of any lineage record)
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    0 AS level,
                    ARRAY[a.asset_name] AS path -- Use name for path to avoid issues with cycles on ID
                FROM
                    btrace_gov.data_assets a
                WHERE NOT EXISTS (
                    SELECT 1 FROM btrace_gov.data_lineage l WHERE l.target_asset_id = a.asset_id
                )

                UNION ALL

                -- Recursive case: Find direct downstream dependents
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    lt.level + 1,
                    lt.path || a.asset_name -- Append name to path
                FROM
                    btrace_gov.data_assets a
                JOIN
                    btrace_gov.data_lineage l ON a.asset_id = l.target_asset_id -- a is the target (dependent)
                JOIN
                    lineage_tree lt ON l.source_asset_id = lt.asset_id -- lt is the source
                WHERE
                    lt.level < p_depth
                    AND NOT a.asset_name = ANY(lt.path) -- Prevent simple cycles based on name path
            )
            SELECT
                asset_id,
                asset_name,
                asset_type,
                level,
                REPEAT('    ', level) || asset_name || ' (' || asset_type || ')' AS display_line
            FROM
                lineage_tree
            ORDER BY path -- Order by the constructed path for a tree-like structure
        LOOP
            v_report_content := v_report_content || v_lineage_record.display_line || E'\n';
        END LOOP;

    ELSE
        -- === Focused Lineage Report for Specific Asset ===
        v_report_content := format('DATA LINEAGE REPORT - %I (Max Depth: %s)' || E'\n', v_asset_name, p_depth);
        v_report_content := v_report_content || repeat('=', LENGTH(v_report_content) - 1) || E'\n\n';

        -- --- Upstream Lineage (Sources) ---
        v_report_content := v_report_content || 'UPSTREAM LINEAGE (Sources):' || E'\n';
        v_report_content := v_report_content || repeat('-', 30) || E'\n';

        FOR v_lineage_record IN
            WITH RECURSIVE upstream_lineage AS (
                -- Base case: the selected asset itself
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    0 AS level,
                    ARRAY[a.asset_name] AS path -- Use name for path
                FROM
                    btrace_gov.data_assets a
                WHERE
                    a.asset_id = p_asset_id

                UNION ALL

                -- Recursive case: Find direct upstream sources
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    ul.level + 1,
                    ul.path || a.asset_name -- Prepend name to path for upstream? Or just append for cycle check.
                     -- Let's append for consistency and cycle check.
                FROM
                    btrace_gov.data_assets a
                JOIN
                    btrace_gov.data_lineage l ON a.asset_id = l.source_asset_id -- a is the source
                JOIN
                    upstream_lineage ul ON l.target_asset_id = ul.asset_id -- ul is the target
                WHERE
                    ul.level < p_depth
                    AND NOT a.asset_name = ANY(ul.path) -- Prevent cycles
            )
            SELECT
                asset_id,
                asset_name,
                asset_type,
                level,
                 -- Indent based on level, but show level 0 (the asset itself) clearly
                CASE
                    WHEN level = 0 THEN '--> ' || asset_name || ' (' || asset_type || ') <-- (REPORTED ASSET)'
                    ELSE REPEAT('    ', level) || asset_name || ' (' || asset_type || ')'
                END AS display_line
            FROM
                upstream_lineage
            ORDER BY level -- Show closest sources first (level 1), then their sources (level 2)...
        LOOP
            v_report_content := v_report_content || v_lineage_record.display_line || E'\n';
        END LOOP;

        -- --- Downstream Lineage (Dependents) ---
        v_report_content := v_report_content || E'\nDOWNSTREAM LINEAGE (Dependents):' || E'\n';
        v_report_content := v_report_content || repeat('-', 32) || E'\n';

        FOR v_lineage_record IN
            WITH RECURSIVE downstream_lineage AS (
                -- Base case: the selected asset itself
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    0 AS level,
                    ARRAY[a.asset_name] AS path -- Use name for path
                FROM
                    btrace_gov.data_assets a
                WHERE
                    a.asset_id = p_asset_id

                UNION ALL

                -- Recursive case: Find direct downstream dependents
                SELECT
                    a.asset_id,
                    a.asset_name,
                    a.asset_type,
                    dl.level + 1,
                    dl.path || a.asset_name -- Append name to path
                FROM
                    btrace_gov.data_assets a
                JOIN
                    btrace_gov.data_lineage l ON a.asset_id = l.target_asset_id -- a is the target (dependent)
                JOIN
                    downstream_lineage dl ON l.source_asset_id = dl.asset_id -- dl is the source
                WHERE
                    dl.level < p_depth
                    AND NOT a.asset_name = ANY(dl.path) -- Prevent cycles
            )
            SELECT
                asset_id,
                asset_name,
                asset_type,
                level,
                 -- Indent based on level, but show level 0 (the asset itself) clearly
                CASE
                    WHEN level = 0 THEN '--> ' || asset_name || ' (' || asset_type || ') <-- (REPORTED ASSET)'
                    ELSE REPEAT('    ', level) || asset_name || ' (' || asset_type || ')'
                END AS display_line
            FROM
                downstream_lineage
            ORDER BY level -- Show closest dependents first (level 1), then their dependents (level 2)...
        LOOP
            v_report_content := v_report_content || v_lineage_record.display_line || E'\n';
        END LOOP;

    END IF; -- End IF p_asset_id IS NULL


    -- Update the report record with the generated content
    -- Note: Storing large text directly in report_config JSONB might not be ideal for performance.
    -- A separate `report_content TEXT` column in `reports` table is often better for large outputs.
    -- However, based on the current schema, we'll store it in report_config.
    -- If a TEXT column existed, we would do: UPDATE ... SET report_content = v_report_content ...
    UPDATE btrace_analytics.reports
    SET
        report_config = report_config || jsonb_build_object('generated_content', v_report_content),
        last_run_at = CURRENT_TIMESTAMP -- Indicate when it was generated
        -- Consider setting next_run_at if it's a scheduled report, but this seems ad-hoc.
    WHERE report_id = v_report_id;


    -- COMMIT is generally not needed in a procedure unless specific transaction control is required.
    -- The calling transaction context handles this.

    -- Note: Procedures in PL/pgSQL do not "return" query results directly like functions.
    -- The standard way is to have the caller query the results table.
    -- If returning the ID is crucial as a direct output, an INOUT or OUT parameter is needed.
    -- For now, we rely on the report being created and identifiable by v_report_id.
    -- The last SELECT statement in the original code is incorrect for a procedure's return mechanism.
    -- RAISE NOTICE 'Lineage report generated successfully with ID: %', v_report_id;

END;
$$;

COMMENT ON PROCEDURE btrace_gov.generate_data_lineage_report IS
'Generates a data lineage report for a specific data asset or all assets, showing upstream sources and downstream dependents up to a specified depth. Stores the report content in btrace_analytics.reports.';


-- BUSINESS CASE:
-- Provide programmatic access to data lineage information for a specific asset.
-- This enables dynamic UIs, integration with graph visualization tools, and automated lineage analysis.
-- It allows applications and analysts to query the relationships and flow of data directly,
-- supporting tasks like impact analysis, root cause investigation, and compliance reporting.
--
-- PURPOSE:
-- - Return a structured set of records representing the lineage graph for a given data asset.
-- - Support querying upstream ('up'), downstream ('down'), or bidirectional ('both') lineage.
-- - Limit the depth of the traversal to prevent overly complex or infinite results.
-- - Include relevant identifiers and details for both the source and target assets in each lineage link.
-- - Be efficient and suitable for consumption by other database queries, application code, or APIs.

CREATE OR REPLACE FUNCTION btrace_gov.get_asset_lineage_graph(
    p_asset_id UUID,
    p_direction TEXT DEFAULT 'both', -- 'up' for upstream/sources, 'down' for downstream/dependents, 'both' for all
    p_max_depth INTEGER DEFAULT 3    -- Maximum number of hops to traverse
)
RETURNS TABLE (
    source_asset_id UUID,
    source_asset_name TEXT,
    target_asset_id UUID,
    target_asset_name TEXT,
    depth INTEGER, -- The number of hops from the original p_asset_id
    lineage_type TEXT -- The type of relationship from the data_lineage table (e.g., 'system', 'business')
)
AS $$
BEGIN
    -- Validate input parameters
    IF p_max_depth < 0 THEN
        RAISE EXCEPTION 'p_max_depth must be a non-negative integer. Provided value: %', p_max_depth;
    END IF;

    IF p_direction NOT IN ('up', 'down', 'both') THEN
        RAISE EXCEPTION 'Invalid p_direction: %. Must be ''up'', ''down'', or ''both''.', p_direction;
    END IF;

    -- Check if the specified asset exists
    IF NOT EXISTS (SELECT 1 FROM btrace_gov.data_assets WHERE asset_id = p_asset_id) THEN
        RAISE EXCEPTION 'Data asset with ID % not found.', p_asset_id;
    END IF;


    -- Return the appropriate lineage data based on the requested direction
    IF p_direction = 'up' THEN
        -- === UPSTREAM LINEAGE (Sources) ===
        RETURN QUERY
        WITH RECURSIVE upstream_cte AS (
            -- Base case: Start with the specified asset at depth 0
            SELECT
                a.asset_id AS source_asset_id,
                a.asset_name AS source_asset_name,
                a.asset_id AS target_asset_id,
                a.asset_name AS target_asset_name,
                0 AS current_depth,
                CAST('' AS TEXT) AS lineage_type -- No lineage link at depth 0
            FROM btrace_gov.data_assets a
            WHERE a.asset_id = p_asset_id

            UNION ALL

            -- Recursive step: Find immediate upstream sources
            SELECT
                da_source.asset_id AS source_asset_id,
                da_source.asset_name AS source_asset_name,
                ul.source_asset_id AS target_asset_id, -- The "target" in the previous step becomes the new source
                ul.source_asset_name AS target_asset_name, -- The name of that new source
                ul.current_depth + 1 AS current_depth,
                dl.lineage_type AS lineage_type
            FROM upstream_cte ul
            JOIN btrace_gov.data_lineage dl ON dl.target_asset_id = ul.source_asset_id -- Find records where the asset is the target
            JOIN btrace_gov.data_assets da_source ON dl.source_asset_id = da_source.asset_id -- Get the source asset details
            WHERE ul.current_depth < p_max_depth
              -- Prevent simple cycles (though complex ones might still occur in bad data)
              AND dl.source_asset_id <> ALL( -- Check if source ID is not already in the upstream path
                  -- This requires tracking the path. A simpler check for immediate parent is:
                  -- AND dl.source_asset_id <> ul.target_asset_id
                  -- For a full path check, the CTE would need to carry an array of visited IDs.
                  -- Let's use the simpler check for now.
                  SELECT source_asset_id FROM upstream_cte WHERE source_asset_id = dl.source_asset_id
                  -- This check prevents immediate parent cycles but not longer loops.
                  -- A full path array is more complex but more robust.
              )
        )
        -- Select final results, excluding the initial depth 0 row which is just the seed
        SELECT
            u.source_asset_id,
            u.source_asset_name,
            u.target_asset_id,
            u.target_asset_name,
            u.current_depth AS depth,
            u.lineage_type
        FROM upstream_cte u
        WHERE u.current_depth > 0 -- Exclude the initial seed row
        ORDER BY u.current_depth;


    ELSIF p_direction = 'down' THEN
        -- === DOWNSTREAM LINEAGE (Dependents) ===
        RETURN QUERY
        WITH RECURSIVE downstream_cte AS (
            -- Base case: Start with the specified asset at depth 0
            SELECT
                a.asset_id AS source_asset_id,
                a.asset_name AS source_asset_name,
                a.asset_id AS target_asset_id,
                a.asset_name AS target_asset_name,
                0 AS current_depth,
                CAST('' AS TEXT) AS lineage_type -- No lineage link at depth 0
            FROM btrace_gov.data_assets a
            WHERE a.asset_id = p_asset_id

            UNION ALL

            -- Recursive step: Find immediate downstream dependents
            SELECT
                dl.source_asset_id AS source_asset_id, -- The "source" in the lineage record
                dd_source.asset_name AS source_asset_name, -- Name of that source
                dd_target.asset_id AS target_asset_id, -- The dependent asset found
                dd_target.asset_name AS target_asset_name, -- Name of the dependent
                dl_cte.current_depth + 1 AS current_depth,
                dl.lineage_type AS lineage_type
            FROM downstream_cte dl_cte
            JOIN btrace_gov.data_lineage dl ON dl.source_asset_id = dl_cte.target_asset_id -- Find records where the asset is the source
            JOIN btrace_gov.data_assets dd_target ON dl.target_asset_id = dd_target.asset_id -- Get the target (dependent) asset details
            JOIN btrace_gov.data_assets dd_source ON dl.source_asset_id = dd_source.asset_id -- Get the source asset details (for name)
            WHERE dl_cte.current_depth < p_max_depth
              -- Prevent simple cycles
              AND dl.target_asset_id <> ALL(
                  SELECT target_asset_id FROM downstream_cte WHERE target_asset_id = dl.target_asset_id
                  -- Simpler check: AND dl.target_asset_id <> dl_cte.source_asset_id
              )
        )
        -- Select final results, excluding the initial depth 0 row
        SELECT
            d.source_asset_id,
            d.source_asset_name,
            d.target_asset_id,
            d.target_asset_name,
            d.current_depth AS depth,
            d.lineage_type
        FROM downstream_cte d
        WHERE d.current_depth > 0 -- Exclude the initial seed row
        ORDER BY d.current_depth;


    ELSIF p_direction = 'both' THEN
        -- === COMBINED UPSTREAM AND DOWNSTREAM LINEAGE ===
        -- Combine the results of the 'up' and 'down' queries.
        -- Note: This combines two separate traversals and might show the central node's relationships twice
        -- if it has a self-loop (unlikely but possible in bad data). The individual queries prevent simple cycles.
        RETURN QUERY
            -- Get upstream lineage
            SELECT * FROM btrace_gov.get_asset_lineage_graph(p_asset_id, 'up', p_max_depth)
            UNION ALL
            -- Get downstream lineage
            SELECT * FROM btrace_gov.get_asset_lineage_graph(p_asset_id, 'down', p_max_depth);


    END IF;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION btrace_gov.get_asset_lineage_graph IS
'Returns a table of lineage relationships for a given data asset, showing upstream sources, downstream dependents, or both, up to a specified depth.';


--
SELECT asset_id, asset_name
FROM btrace_gov.data_assets
LIMIT 5; -- See the first 5 assets
---===== Get upstream lineage(sources) for a specific asset 
SELECT
    source_asset_id,
    source_asset_name,
    target_asset_id,
    target_asset_name,
    depth,
    lineage_type
FROM
    btrace_gov.get_asset_lineage_graph(
        p_asset_id => 'VALID-ASSET-ID-FROM-ABOVE-QUERY', -- <-- Replace this
        p_direction => 'both', -- or 'up' or 'down'
        p_max_depth => 3
    )
ORDER BY
    depth, source_asset_name, target_asset_name;
	
	
SELECT
    source_asset_id,
    source_asset_name,
    target_asset_id,
    target_asset_name,
    depth,
    lineage_type
FROM
    btrace_gov.get_asset_lineage_graph(
        p_asset_id => 'abcd1234-ef56-7890-abcd-1234567890ab', -- Replace with actual UUID
        p_direction => 'down',
        p_max_depth => 3 -- Default depth is 3, so this could be omitted
    );
	
	
SELECT
    source_asset_id,
    source_asset_name,
    target_asset_id,
    target_asset_name,
    depth,
    lineage_type
FROM
    btrace_gov.get_asset_lineage_graph(
        p_asset_id => 'abcd1234-ef56-7890-abcd-1234567890ab', -- Replace with actual UUID
        p_direction => 'up',
        p_max_depth => 2
    );
	
	



-- =============================================
-- SECTION 15: INITIAL DATA SETUP
-- =============================================

-- Insert system roles
INSERT INTO btrace_rbac.roles (role_id, role_name, description, is_system_role) VALUES
('00000000-0000-0000-0000-000000000001', 'Administrator', 'Full access to all platform features and configuration', TRUE),
('00000000-0000-0000-0000-000000000002', 'Operations Lead', 'Can view all dashboards, manage incidents, configure alerts, and access all data', TRUE),
('00000000-0000-0000-0000-000000000003', 'SRE/DevOps Engineer', 'Can investigate traces, search logs, and monitor metrics for assigned services', TRUE),
('00000000-0000-0000-0000-000000000004', 'Customer Support Agent', 'Can view incident status and customer-impacting information', TRUE),
('00000000-0000-0000-0000-000000000005', 'Viewer/Analyst', 'Can view dashboards and reports but cannot make changes', TRUE),
('00000000-0000-0000-0000-000000000006', 'Data Steward', 'Responsible for data governance and quality for specific domains', TRUE),
('00000000-0000-0000-0000-000000000007', 'Security Analyst', 'Can access security-related data and perform investigations', TRUE);

-- Insert system permissions

-- INSERT INTO btrace_rbac.permissions (permission_id, permission_name, description, resource_type, action) VALUES
-- -- Administrative permissions
-- ('00000000-0000-0000-0001-000000000001', 'admin.access', 'Access admin features', 'system', 'access'),
-- ('00000000-0000-0000-0001-000000000002', 'user.manage', 'Manage users and roles', 'user', 'manage'),
-- ('00000000-0000-0000-0001-000000000003', 'system.configure', 'Configure system settings', 'system', 'configure'),
-- -- Additional permissions (examples)
-- ('00000000-0000-0000-0001-000000000004', 'policy.manage', 'Manage data governance policies', 'policy', 'manage'),
-- ('00000000-0000-0000-0001-000000000005', 'audit.view', 'View audit logs', 'audit', 'read');

-- -- Data permissions
-- ('00000000-0000-0000-0002-000000000001', 'trace.view', 'View trace data', 'trace', 'view'),
-- ('00000000-0000-0000-0002-000000000002', 'trace.export', 'Export trace data', 'trace', 'export'),
-- ('00000000-0000-0000-0002-000000000003', 'log.view', 'View log data', 'log', 'view'),
-- ('00000000-0000-0000-0002-000000000004', 'log.export', 'Export log data', 'log', 'export'),
-- ('00000000-0000-0000-0002-000000000005', 'metric.view', 'View metric data', 'metric', 'view'),
-- ('00000000-0000-0000-0002-000000000006', 'metric.export', 'Export metric data', 'metric', 'export'),
-- ('00000000-0000-0000-0002-000000000007', 'data.pii.view', 'View PII data', 'data', 'pii_view'),

-- -- Incident management permissions
-- ('00000000-0000-0000-0003-000000000001', 'incident.view', 'View incidents', 'incident', 'view'),
-- ('00000000-0000-0000-0003-000000000002', 'incident.create', 'Create incidents', 'incident', 'create'),
-- ('00000000-0000-0000-0003-000000000003', 'incident.update', 'Update incidents', 'incident', 'update'),
-- ('00000000-0000-0000-0003-000000000004', 'incident.resolve', 'Resolve incidents', 'incident', 'resolve'),
-- ('00000000-0000-0000-0003-000000000005', 'incident.assign', 'Assign incidents', 'incident', 'assign'),
-- ('00000000-0000-0000-0003-000000000006', 'incident.communicate', 'Send incident communications', 'incident', 'communicate'),

-- -- Alerting permissions
-- ('00000000-0000-0000-0004-000000000001', 'alert.view', 'View alerts', 'alert', 'view'),
-- ('00000000-0000-0000-0004-000000000002', 'alert.create', 'Create alert rules', 'alert', 'create'),
-- ('00000000-0000-0000-0004-000000000003', 'alert.update', 'Update alert rules', 'alert', 'update'),
-- ('00000000-0000-0000-0004-000000000004', 'alert.delete', 'Delete alert rules', 'alert', 'delete'),
-- ('00000000-0000-0000-0004-000000000005', 'alert.acknowledge', 'Acknowledge alerts', 'alert', 'acknowledge'),

-- -- Dashboard and reporting permissions
-- ('00000000-0000-0000-0005-000000000001', 'dashboard.view', 'View dashboards', 'dashboard', 'view'),
-- ('00000000-0000-0000-0005-000000000002', 'dashboard.create', 'Create dashboards', 'dashboard', 'create'),
-- ('00000000-0000-0000-0005-000000000003', 'dashboard.update', 'Update dashboards', 'dashboard', 'update'),
-- ('00000000-0000-0000-0005-000000000004', 'dashboard.delete', 'Delete dashboards', 'dashboard', 'delete'),
-- ('00000000-0000-0000-0005-000000000005', 'dashboard.share', 'Share dashboards', 'dashboard', 'share'),
-- ('00000000-0000-0000-0005-000000000006', 'report.view', 'View reports', 'report', 'view'),
-- ('00000000-0000-0000-0005-000000000007', 'report.create', 'Create reports', 'report', 'create'),
-- ('00000000-0000-0000-0005-000000000008', 'report.update', 'Update reports', 'report', 'update'),
-- ('00000000-0000-0000-0005-000000000009', 'report.delete', 'Delete reports', 'report', 'delete'),

-- -- Data governance permissions
-- ('00000000-0000-0000-0006-000000000001', 'governance.view', 'View governance data', 'governance', 'view'),
-- ('00000000-0000-0000-0006-000000000002', 'governance.manage', 'Manage governance policies', 'governance', 'manage'),
-- ('00000000-0000-0000-0006-000000000003', 'data.quality.view', 'View data quality metrics', 'data_quality', 'view'),
-- ('00000000-0000-0000-0006-000000000004', 'data.quality.manage', 'Manage data quality rules', 'data_quality', 'manage'),
-- ('00000000-0000-0000-0006-000000000005', 'data.lineage.view', 'View data lineage', 'data_lineage', 'view'),
-- ('00000000-0000-0000-0006-000000000006', 'data.lineage.manage', 'Manage data lineage', 'data_lineage', 'manage'),
-- ('00000000-0000-0000-0006-000000000007', 'data.catalog.view', 'View data catalog', 'data_catalog', 'view'),
-- ('00000000-0000-0000-0006-000000000008', 'data.catalog.manage', 'Manage data catalog', 'data_catalog', 'manage'),
-- ('00000000-0000-0000-0006-000000000009', 'gdpr.manage', 'Manage GDPR compliance', 'gdpr', 'manage');

-- -- Assign permissions to roles
-- -- Administrator gets all permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id)
-- SELECT '00000000-0000-0000-0000-000000000001', permission_id FROM btrace_rbac.permissions;

-- -- Operations Lead permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0002-000000000001'), -- trace.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0002-000000000003'), -- log.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0002-000000000005'), -- metric.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000001'), -- incident.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000002'), -- incident.create
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000003'), -- incident.update
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000004'), -- incident.resolve
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000005'), -- incident.assign
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000006'), -- incident.communicate
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0004-000000000001'), -- alert.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0004-000000000002'), -- alert.create
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0004-000000000003'), -- alert.update
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000001'), -- dashboard.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000002'), -- dashboard.create
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000006'), -- report.view
-- ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0006-000000000001'); -- governance.view

-- -- SRE/DevOps Engineer permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0002-000000000001'), -- trace.view
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0002-000000000003'), -- log.view
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0002-000000000005'), -- metric.view
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0003-000000000001'), -- incident.view
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0003-000000000003'), -- incident.update
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0003-000000000004'), -- incident.resolve
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0004-000000000001'), -- alert.view
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0004-000000000005'), -- alert.acknowledge
-- ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000001'); -- dashboard.view

-- -- Customer Support Agent permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0003-000000000001'), -- incident.view
-- ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0003-000000000006'); -- incident.communicate

-- -- Viewer/Analyst permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0002-000000000001'), -- trace.view
-- ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0002-000000000003'), -- log.view
-- ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0002-000000000005'), -- metric.view
-- ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0005-000000000001'), -- dashboard.view
-- ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0005-000000000006'); -- report.view

-- -- Data Steward permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000001'), -- governance.view
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000003'), -- data.quality.view
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000004'), -- data.quality.manage
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000005'), -- data.lineage.view
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000007'), -- data.catalog.view
-- ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0006-000000000008'); -- data.catalog.manage

-- -- Security Analyst permissions
-- INSERT INTO btrace_rbac.role_permissions (role_id, permission_id) VALUES
-- ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0002-000000000001'), -- trace.view
-- ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0002-000000000003'), -- log.view
-- ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0002-000000000007'), -- data.pii.view
-- ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0006-000000000001'), -- governance.view
-- ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0006-000000000009'); -- gdpr.manage

-- -- Insert initial environments
-- INSERT INTO btrace_core.environments (environment_id, environment_name, description, is_production) VALUES
-- ('00000000-0000-0000-0000-000000000101', 'production', 'Production environment', TRUE),
-- ('00000000-0000-0000-0000-000000000102', 'staging', 'Staging environment', FALSE),
-- ('00000000-0000-0000-0000-000000000103', 'development', 'Development environment', FALSE),
-- ('00000000-0000-0000-0000-000000000104', 'testing', 'Testing environment', FALSE);

-- -- Insert initial data domains
-- INSERT INTO btrace_gov.data_domains (domain_id, domain_name, description) VALUES
-- ('00000000-0000-0000-0000-000000000201', 'Infrastructure', 'Infrastructure and platform services'),
-- ('00000000-0000-0000-0000-000000000202', 'Application', 'Application services and business logic'),
-- ('00000000-0000-0000-0000-000000000203', 'Data', 'Data storage and processing services'),
-- ('00000000-0000-0000-0000-000000000204', 'Security', 'Security and compliance services');

-- -- Insert initial governance policies
-- INSERT INTO btrace_gov.policies (
--     policy_id, 
--     policy_name, 
--     description, 
--     policy_type, 
--     policy_text, 
--     version, 
--     is_active, 
--     effective_date, 
--     committee_id
-- ) VALUES (
--     '00000000-0000-0000-0000-000000000301',
--     'Data Retention Policy',
--     'Policy governing how long different types of data should be retained',
--     'retention',
--     'All operational telemetry data (traces, logs, metrics) should be retained for 30 days in hot storage, 90 days in warm storage, and 1 year in cold storage. Incident data should be retained indefinitely for historical analysis.',
--     '1.0',
--     TRUE,
--     CURRENT_DATE,
--     '00000000-0000-0000-0000-000000000204'  -- Security domain
-- ), (
--     '00000000-0000-0000-0000-000000000302',
--     'Incident Management Policy',
--     'Policy for handling operational incidents',
--     'incident',
--     'All incidents must be documented with a timeline of events. P1 and P2 incidents require a post-mortem analysis within 5 business days of resolution. Incident communications must be timely and accurate.',
--     '1.0',
--     TRUE,
--     CURRENT_DATE,
--     '00000000-0000-0000-0000-000000000201'  -- Infrastructure domain
-- ), (
--     '00000000-0000-0000-0000-000000000303',
--     'GDPR Compliance Policy',
--     'Policy for handling personal data in compliance with GDPR',
--     'gdpr',
--     'All personal data must be properly classified and protected. Data subjects must be able to exercise their rights under GDPR, including access, rectification, and erasure. Data processing activities must be documented.',
--     '1.0',
--     TRUE,
--     CURRENT_DATE,
--     '00000000-0000-0000-0000-000000000204'  -- Security domain
-- );

-- -- Create initial partitions
-- CALL btrace_core.create_monthly_partitions();

-- =============================================
-- SECTION 16:  SETUP
-- =============================================

-- Create read-only role for reporting
-- Create read-only role for reporting
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'btrace_readonly') THEN
        CREATE ROLE btrace_readonly;
        -- Replace 'your_actual_database_name' with the name of your database
        GRANT CONNECT ON DATABASE btracedb TO btrace_readonly;
        GRANT USAGE ON SCHEMA btrace_core, btrace_analytics, btrace_gov TO btrace_readonly;
        GRANT SELECT ON ALL TABLES IN SCHEMA btrace_core, btrace_analytics, btrace_gov TO btrace_readonly;
        ALTER DEFAULT PRIVILEGES IN SCHEMA btrace_core, btrace_analytics, btrace_gov
        GRANT SELECT ON TABLES TO btrace_readonly;
    END IF;
END
$$;

-- Create application role with necessary permissions
-- Create application role with necessary permissions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'btrace_app') THEN
        CREATE ROLE btrace_app;
        -- *** REPLACE 'your_actual_database_name' BELOW *** --
        GRANT CONNECT ON DATABASE btracedb TO btrace_app;
        -- *** END REPLACE *** --
        GRANT USAGE ON SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit TO btrace_app;
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit TO btrace_app;
        GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit TO btrace_app;
        GRANT USAGE ON ALL SEQUENCES IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit TO btrace_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO btrace_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit
        GRANT USAGE ON SEQUENCES TO btrace_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA btrace_core, btrace_analytics, btrace_gov, btrace_rbac, btrace_audit
        GRANT EXECUTE ON FUNCTIONS TO btrace_app;
    END IF;
END
$$;

-- Create admin user
-- Ensure pgcrypto is available (run this first if unsure)
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure the Administrator role exists (example, run this first if unsure)
-- INSERT INTO btrace_rbac.roles (role_id, role_name, description, is_active, is_system_role)
-- VALUES ('00000000-0000-0000-0000-000000000001', 'Administrator', 'Full system access role', TRUE, TRUE)
-- ON CONFLICT (role_id) DO NOTHING; -- Prevents error if role already exists

DO $$
DECLARE
    v_admin_user_id UUID := gen_random_uuid(); -- Generate a proper UUID
    v_admin_role_id UUID := '00000000-0000-0000-0000-000000000001'; -- Use the known Admin role ID
BEGIN
    IF NOT EXISTS (SELECT 1 FROM btrace_rbac.users WHERE username = 'admin') THEN
        INSERT INTO btrace_rbac.users (
            user_id, -- Use the generated ID
            username,
            email,
            password_hash,
            first_name,
            last_name,
            is_active
        ) VALUES (
            v_admin_user_id, -- Use the variable
            'admin',
            'admin@btrace.example.com',
            -- Ensure pgcrypto extension is installed for crypt/gen_salt
            crypt('admin123', gen_salt('bf')), 
            'System',
            'Administrator',
            TRUE
        );

        -- Assign admin role
        INSERT INTO btrace_rbac.user_roles (
            user_id,
            role_id,
            assigned_by
        ) VALUES (
            v_admin_user_id, -- Use the variable
            v_admin_role_id, -- Use the known role ID
            v_admin_user_id  -- Self-assigned
        );
    END IF;
END
$$;

-- Create initial dashboard
DO $$
DECLARE
    v_dashboard_id UUID := gen_random_uuid();
    -- *** USE THE CORRECT, EXISTING user_id BELOW *** --
    v_admin_user_id UUID := 'abcd1234-ef56-7890-abcd-1234567890ab'; 
    -- *** END CORRECT user_id *** --
BEGIN
    IF NOT EXISTS (SELECT 1 FROM btrace_analytics.dashboards WHERE dashboard_name = 'Operations Overview') THEN
        INSERT INTO btrace_analytics.dashboards (
            dashboard_id,
            dashboard_name,
            description,
            is_shared,
            created_by
        ) VALUES (
            v_dashboard_id,
            'Operations Overview',
            'High-level overview of operational metrics and incidents',
            TRUE,
            v_admin_user_id -- Use the verified existing user ID
        );
    END IF;
END
$$;

-- =============================================
-- SECTION 17: Notifications Module
-- =============================================
-- =============================================
-- ENHANCEMENT 1: NOTIFICATIONS SYSTEM
-- =============================================

-- BUSINESS CASE:
-- The `notifications` table tracks all outbound messages sent to users, teams, or systems
-- as part of operational workflows (incident alerts, policy updates, DSAR completions).
-- It enables delivery tracking, retries, and auditability across multiple channels.
--
-- PURPOSE:
-- - Centralize all platform notifications
-- - Track delivery status (queued, sent, delivered, failed)
-- - Support multi-channel delivery (email, SMS, webhooks, etc.)
-- - Maintain audit trail for compliance requirements
-- - Enable notification templates for consistent messaging

CREATE TABLE btrace_core.notification_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) NOT NULL,
    description TEXT,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    is_html BOOLEAN NOT NULL DEFAULT FALSE,
    channels VARCHAR(50)[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_template_name UNIQUE (template_name),
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL
);
COMMENT ON TABLE btrace_core.notification_templates IS 'Templates for standardized notifications';

CREATE TABLE btrace_core.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID,
    notification_type VARCHAR(50) NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    channel VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'queued',
    priority INTEGER NOT NULL DEFAULT 3,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER NOT NULL DEFAULT 3,
    recipient_type VARCHAR(10) NOT NULL,
    recipient_id UUID,
    recipient_address TEXT,
    context JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (template_id) REFERENCES btrace_core.notification_templates(template_id) ON DELETE SET NULL,
    CONSTRAINT chk_status CHECK (status IN ('queued', 'processing', 'sent', 'delivered', 'failed')),
    CONSTRAINT chk_recipient_type CHECK (recipient_type IN ('user', 'team', 'external'))
);
COMMENT ON TABLE btrace_core.notifications IS 'Outbound notifications with delivery tracking';
CREATE INDEX idx_notifications_status ON btrace_core.notifications (status);
CREATE INDEX idx_notifications_recipient ON btrace_core.notifications (recipient_type, recipient_id);

-- =============================================
-- ENHANCEMENT 2: SERVICE LEVEL OBJECTIVES (SLOs)
-- =============================================

-- BUSINESS CASE:
-- The `service_level_objectives` table defines measurable reliability targets
-- for services, enabling teams to track and report on compliance with
-- operational expectations.
--
-- PURPOSE:
-- - Define reliability targets (e.g., 99.9% availability)
-- - Track compliance over time
-- - Calculate error budgets
-- - Support incident severity classification

CREATE TABLE btrace_core.service_level_objectives (
    slo_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL,
    slo_name VARCHAR(100) NOT NULL,
    description TEXT,
    slo_type VARCHAR(50) NOT NULL,
    target_value DECIMAL(5,2) NOT NULL,
    time_window VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    FOREIGN KEY (service_id) REFERENCES btrace_core.services(service_id) ON DELETE CASCADE,
    CONSTRAINT chk_slo_type CHECK (slo_type IN ('availability', 'latency', 'throughput', 'correctness')),
    CONSTRAINT chk_time_window CHECK (time_window IN ('7d', '30d', '90d', '28d'))
);
COMMENT ON TABLE btrace_core.service_level_objectives IS 'Service Level Objective definitions';

CREATE TABLE btrace_core.slo_measurements (
    measurement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slo_id UUID NOT NULL,
    measurement_time TIMESTAMP WITH TIME ZONE NOT NULL,
    measured_value DECIMAL(5,2) NOT NULL,
    compliance_status BOOLEAN NOT NULL,
    error_budget_consumed DECIMAL(5,2) NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (slo_id) REFERENCES btrace_core.service_level_objectives(slo_id) ON DELETE CASCADE
);
COMMENT ON TABLE btrace_core.slo_measurements IS 'Historical SLO compliance measurements';
CREATE INDEX idx_slo_measurements ON btrace_core.slo_measurements (slo_id, measurement_time);

-- =============================================
-- ENHANCEMENT 3: KNOWLEDGE BASE
-- =============================================

-- BUSINESS CASE:
-- The `knowledge_base` tables store organizational knowledge including
-- incident post-mortems, runbooks, and troubleshooting guides to enable
-- faster incident resolution and prevent repeat issues.
--
-- PURPOSE:
-- - Centralize operational knowledge
-- - Link to related incidents and services
-- - Support search and discovery
-- - Maintain version history

CREATE TABLE btrace_core.knowledge_articles (
    article_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    article_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    published_at TIMESTAMP WITH TIME ZONE,
    published_by UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    FOREIGN KEY (published_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_article_type CHECK (article_type IN ('runbook', 'post_mortem', 'troubleshooting', 'how_to', 'reference')),
    CONSTRAINT chk_status CHECK (status IN ('draft', 'review', 'published', 'archived'))
);
COMMENT ON TABLE btrace_core.knowledge_articles IS 'Knowledge base articles';

CREATE TABLE btrace_core.article_relations (
    relation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL,
    related_type VARCHAR(50) NOT NULL,
    related_id UUID NOT NULL,
    relation_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    FOREIGN KEY (article_id) REFERENCES btrace_core.knowledge_articles(article_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_related_type CHECK (related_type IN ('service', 'incident', 'alert_rule', 'slo'))
);
COMMENT ON TABLE btrace_core.article_relations IS 'Relations between knowledge articles and other entities';

-- =============================================
-- ENHANCEMENT 4: ENHANCED VIEWS
-- =============================================

-- BUSINESS CASE:
-- The `service_slo_compliance` view provides a comprehensive overview
-- of service reliability against defined objectives, enabling teams to
-- quickly assess operational health.
--
-- PURPOSE:
-- - Visualize SLO compliance trends
-- - Identify services at risk of breaching objectives
-- - Support capacity planning decisions
-- - Provide operational metrics to stakeholders

CREATE OR REPLACE VIEW btrace_analytics.service_slo_compliance AS
SELECT 
    s.service_id,
    s.service_name,
    slo.slo_id,
    slo.slo_name,
    slo.slo_type,
    slo.target_value,
    slo.time_window,
    m.measured_value AS current_value,
    m.compliance_status AS is_compliant,
    m.measurement_time AS last_measured,
    m.error_budget_consumed,
    CASE 
        WHEN slo.slo_type = 'availability' THEN 
            ROUND((m.measured_value - slo.target_value) * 
            EXTRACT(EPOCH FROM 
                CASE 
                    WHEN slo.time_window = '7d' THEN INTERVAL '7 days'
                    WHEN slo.time_window = '28d' THEN INTERVAL '28 days'
                    WHEN slo.time_window = '30d' THEN INTERVAL '30 days'
                    WHEN slo.time_window = '90d' THEN INTERVAL '90 days'
                END
            ) / 86400, 2)
        ELSE NULL
    END AS error_budget_remaining_days
FROM 
    btrace_core.services s
JOIN 
    btrace_core.service_level_objectives slo ON s.service_id = slo.service_id
JOIN (
    SELECT 
        slo_id,
        measured_value,
        compliance_status,
        measurement_time,
        error_budget_consumed,
        ROW_NUMBER() OVER (PARTITION BY slo_id ORDER BY measurement_time DESC) AS rn
    FROM 
        btrace_core.slo_measurements
) m ON slo.slo_id = m.slo_id AND m.rn = 1
WHERE 
    slo.is_active = TRUE;
COMMENT ON VIEW btrace_analytics.service_slo_compliance IS 'Current SLO compliance status for all services';

-- =============================================
-- ENHANCEMENT 5: STORED PROCEDURES
-- =============================================

-- BUSINESS CASE:
-- The `process_dsar_request` procedure handles Data Subject Access Requests
-- by coordinating data retrieval, redaction, and notification workflows
-- to ensure GDPR compliance.
--
-- PURPOSE:
-- - Standardize DSAR processing
-- - Ensure proper audit logging
-- - Automate notification to requesters
-- - Maintain compliance timelines

CREATE OR REPLACE PROCEDURE btrace_gov.process_dsar_request(
    p_request_id UUID,
    p_processed_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_request RECORD;
    v_subject RECORD;
    v_template_id UUID;
    v_notification_id UUID;
BEGIN
    -- Get request details
    SELECT * INTO v_request
    FROM btrace_gov.subject_access_requests
    WHERE request_id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'DSAR request with ID % not found', p_request_id;
    END IF;
    
    -- Get subject details
    SELECT * INTO v_subject
    FROM btrace_gov.data_subjects
    WHERE subject_id = v_request.subject_id;
    
    -- Update request status
    UPDATE btrace_gov.subject_access_requests
    SET 
        status = 'completed',
        completed_date = CURRENT_TIMESTAMP,
        processed_by = p_processed_by
    WHERE request_id = p_request_id;
    
    -- Audit log
    INSERT INTO btrace_audit.audit_logs (
        event_type,
        event_subtype,
        user_id,
        resource_type,
        resource_id,
        action,
        action_status,
        details
    ) VALUES (
        'gdpr',
        'dsar_processed',
        p_processed_by,
        'subject_access_request',
        p_request_id::TEXT,
        'update',
        'success',
        jsonb_build_object('subject_id', v_request.subject_id, 'request_type', v_request.request_type)
    );
    
    -- Get notification template
    SELECT template_id INTO v_template_id
    FROM btrace_core.notification_templates
    WHERE template_name = 'dsar_completion_notification';
    
    -- Send notification
    IF FOUND THEN
        INSERT INTO btrace_core.notifications (
            template_id,
            notification_type,
            subject,
            body,
            channel,
            status,
            recipient_type,
            recipient_address,
            context
        ) VALUES (
            v_template_id,
            'dsar_completion',
            'Your data access request has been processed',
            'Your ' || v_request.request_type || ' request regarding ' || v_subject.subject_type || 
            ' data has been completed. Reference: ' || p_request_id,
            'email',
            'queued',
            'external',
            v_subject.identifier_value,
            jsonb_build_object('request_id', p_request_id, 'request_type', v_request.request_type)
        ) RETURNING notification_id INTO v_notification_id;
    END IF;
    
    COMMIT;
END;
$$;
COMMENT ON PROCEDURE btrace_gov.process_dsar_request IS 'Processes a Data Subject Access Request including data retrieval and requester notification';

-- BUSINESS CASE:
-- The `check_slo_compliance` procedure evaluates service level objectives
-- against recent operational data, updating compliance status and triggering
-- alerts when objectives are at risk.
--
-- PURPOSE:
-- - Automate SLO compliance monitoring
-- - Calculate error budget consumption
-- - Trigger proactive alerts
-- - Support reliability engineering practices

CREATE OR REPLACE PROCEDURE btrace_core.check_slo_compliance(
    p_service_id UUID DEFAULT NULL,
    p_slo_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_slo RECORD;
    v_measurement RECORD;
    v_alert_rule_id UUID;
BEGIN
    -- Process specific SLO if provided
    IF p_slo_id IS NOT NULL THEN
        SELECT * INTO v_slo
        FROM btrace_core.service_level_objectives
        WHERE slo_id = p_slo_id AND is_active = TRUE;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Active SLO with ID % not found', p_slo_id;
        END IF;
        
        -- Calculate compliance based on SLO type
        IF v_slo.slo_type = 'availability' THEN
            -- Calculate availability over the SLO time window
            INSERT INTO btrace_core.slo_measurements (
                slo_id,
                measurement_time,
                measured_value,
                compliance_status,
                error_budget_consumed,
                details
            )
            SELECT 
                v_slo.slo_id,
                CURRENT_TIMESTAMP,
                CASE 
                    WHEN v_slo.time_window = '7d' THEN 
                        (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 7) * 100
                    WHEN v_slo.time_window = '30d' THEN 
                        (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 30) * 100
                    ELSE 100
                END AS measured_value,
                CASE 
                    WHEN v_slo.time_window = '7d' THEN 
                        (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 7) * 100 >= v_slo.target_value
                    WHEN v_slo.time_window = '30d' THEN 
                        (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 30) * 100 >= v_slo.target_value
                    ELSE TRUE
                END AS compliance_status,
                CASE 
                    WHEN v_slo.time_window = '7d' THEN 
                        GREATEST(0, (v_slo.target_value - (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 7) * 100) / 
                        (100 - v_slo.target_value)) * 100
                    WHEN v_slo.time_window = '30d' THEN 
                        GREATEST(0, (v_slo.target_value - (1 - COUNT(DISTINCT i.incident_id) * 1.0 / 30) * 100) / 
                        (100 - v_slo.target_value)) * 100
                    ELSE 0
                END AS error_budget_consumed,
                jsonb_build_object(
                    'incident_count', COUNT(DISTINCT i.incident_id),
                    'calculation_window', v_slo.time_window
                ) AS details
            FROM 
                btrace_core.services s
            LEFT JOIN 
                btrace_core.incidents i ON s.service_id = i.service_id
                AND i.is_customer_impacting = TRUE
                AND i.start_time >= CASE 
                    WHEN v_slo.time_window = '7d' THEN CURRENT_DATE - INTERVAL '7 days'
                    WHEN v_slo.time_window = '30d' THEN CURRENT_DATE - INTERVAL '30 days'
                    ELSE CURRENT_DATE - INTERVAL '1 day'
                END
            WHERE 
                s.service_id = v_slo.service_id
            GROUP BY 
                s.service_id
            RETURNING * INTO v_measurement;
            
            -- Check if we need to trigger an alert (error budget > 50% consumed)
            IF v_measurement.error_budget_consumed > 50 THEN
                -- Find the appropriate alert rule
                SELECT rule_id INTO v_alert_rule_id
                FROM btrace_core.alert_rules
                WHERE rule_name = 'slo_error_budget_consumed_' || v_slo.slo_type
                AND service_id = v_slo.service_id;
                
                IF FOUND THEN
                    INSERT INTO btrace_core.alerts (
                        rule_id,
                        title,
                        description,
                        status,
                        severity,
                        triggered_at
                    ) VALUES (
                        v_alert_rule_id,
                        'SLO Error Budget Warning: ' || v_slo.slo_name,
                        'Error budget for ' || v_slo.slo_name || ' is ' || 
                        ROUND(v_measurement.error_budget_consumed, 1) || '% consumed. ' ||
                        'Current compliance: ' || ROUND(v_measurement.measured_value, 1) || '% vs target ' || 
                        v_slo.target_value || '%',
                        'open',
                        'P3',
                        CURRENT_TIMESTAMP
                    );
                END IF;
            END IF;
        END IF;
        
    -- Process all SLOs for a service if provided
    ELSIF p_service_id IS NOT NULL THEN
        FOR v_slo IN 
            SELECT * FROM btrace_core.service_level_objectives 
            WHERE service_id = p_service_id AND is_active = TRUE
        LOOP
            CALL btrace_core.check_slo_compliance(p_slo_id := v_slo.slo_id);
        END LOOP;
        
    -- Process all active SLOs if no parameters provided
    ELSE
        FOR v_slo IN 
            SELECT * FROM btrace_core.service_level_objectives 
            WHERE is_active = TRUE
        LOOP
            CALL btrace_core.check_slo_compliance(p_slo_id := v_slo.slo_id);
        END LOOP;
    END IF;
    
    COMMIT;
END;
$$;
COMMENT ON PROCEDURE btrace_core.check_slo_compliance IS 'Evaluates service level objectives against recent operational data and updates compliance status';

-- =============================================
-- ENHANCEMENT 6: ADDITIONAL INDEXES
-- =============================================

-- BUSINESS CASE:
-- The following indexes optimize query performance for the enhanced
-- notification and SLO tracking features, particularly for time-based
-- queries and status checks.
--
-- PURPOSE:
-- - Accelerate notification processing
-- - Improve SLO compliance reporting
-- - Support high-volume operations
-- - Maintain performance as data grows

CREATE INDEX IF NOT EXISTS idx_notifications_template ON btrace_core.notifications (template_id) WHERE template_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON btrace_core.notifications (created_at) WHERE status IN ('queued', 'processing');
CREATE INDEX IF NOT EXISTS idx_slo_service ON btrace_core.service_level_objectives (service_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_knowledge_article_type ON btrace_core.knowledge_articles (article_type, status);
CREATE INDEX IF NOT EXISTS idx_article_relations ON btrace_core.article_relations (related_type, related_id);

-- =============================================
-- ENHANCEMENT 7: INITIAL DATA FOR NEW TABLES
-- =============================================

-- BUSINESS CASE:
-- Initial data setup ensures the system has essential templates and
-- configurations available immediately after deployment, reducing
-- setup time and ensuring consistency.
--
-- PURPOSE:
-- - Provide default notification templates
-- - Establish common SLO definitions
-- - Create knowledge base structure
-- - Enable immediate platform usability

-- Notification templates
-- Note:ensure  that a user record with user_id = '00000000-0000-0000-0000-000000000501' exists in the btrace_rbac.users table.
-- Corrected Initial Data Setup for Notification Templates
-- Ensure the user '00000000-0000-0000-0000-000000000501' exists in btrace_rbac.users first!
-- this is sample testing code used by me
INSERT INTO btrace_core.notification_templates (
    template_id,
    template_name,
    description,
    subject_template,
    body_template,
    is_html,
    channels,
    created_by,
    created_at,        -- Explicitly set
    updated_at,        -- Explicitly set (can be NULL or same as created_at initially)
    updated_by         -- Explicitly set (can be NULL or same as created_by initially)
) VALUES 
(
    '00000000-0000-0000-0000-000000000701', -- template_id
    'incident_alert',                       -- template_name
    'Notification for new incident creation', -- description
    'New Incident: {{incident.title}}',     -- subject_template
    'A new incident has been detected:' || E'\n\n' || -- body_template (using E'' for newline)
    'Title: {{incident.title}}' || E'\n' ||
    'Severity: {{incident.severity}}' || E'\n' ||
    'Service: {{service.name}}' || E'\n' ||
    'Start Time: {{incident.start_time}}' || E'\n\n' ||
    'View in β Trace: {{app_url}}/incidents/{{incident.id}}',
    FALSE,                                  -- is_html
    ARRAY['email', 'slack'],                -- channels
    '00000000-0000-0000-0000-000000000501', -- created_by (ensure this user exists)
    CURRENT_TIMESTAMP,                      -- created_at
    CURRENT_TIMESTAMP,                      -- updated_at (set to current time or NULL)
    '00000000-0000-0000-0000-000000000501'  -- updated_by (ensure this user exists, or NULL)
),
(
    '00000000-0000-0000-0000-000000000702', -- template_id
    'dsar_completion_notification',         -- template_name
    'Notification for completed DSAR requests', -- description
    'Your Data Request is Complete',        -- subject_template
    'Dear {{subject.type}},' || E'\n\n' || -- body_template (using E'' for newline)
    'Your {{request.type}} request has been completed.' || E'\n' ||
    'Reference Number: {{request.id}}' || E'\n' ||
    'Completion Date: {{completed.date}}' || E'\n\n' ||
    'Thank you,' || E'\n' ||
    'The Data Protection Team',
    TRUE,                                   -- is_html
    ARRAY['email'],                         -- channels
    '00000000-0000-0000-0000-000000000501', -- created_by (ensure this user exists)
    CURRENT_TIMESTAMP,                      -- created_at
    CURRENT_TIMESTAMP,                      -- updated_at (set to current time or NULL)
    '00000000-0000-0000-0000-000000000501'  -- updated_by (ensure this user exists, or NULL)
);


-- Sample SLO definitions
-- Initial SLO data setup
-- Creates a default 'Production Availability' SLO for critical/high services
-- Requires:
-- - Services with criticality 'critical' or 'high' to exist in btrace_core.services
-- - Admin user '00000000-0000-0000-0000-000000000501' to exist in btrace_rbac.users
INSERT INTO btrace_core.service_level_objectives (
    slo_id,
    service_id,
    slo_name,
    slo_type,
    target_value,
    time_window,
    created_by
    -- description, created_at, updated_at, updated_by, is_active are omitted (using defaults or allowing NULL)
)
SELECT
    uuid_generate_v4(),                          -- Generate new UUID for each SLO
    service_id,                                  -- Link to existing service
    'Production Availability',                   -- SLO Name
    'availability',                              -- SLO Type
    99.9,                                        -- Target Value (%)
    '30d',                                       -- Time Window
    '00000000-0000-0000-0000-000000000501'       -- created_by (ensure this admin user exists)
FROM
    btrace_core.services
WHERE
    criticality IN ('critical', 'high'); -- Apply to critical/high services


-- Initial knowledge base structure
-- Sets up a foundational runbook article
-- Requires:
-- - Admin user '00000000-0000-0000-0000-000000000501' to exist in btrace_rbac.users
INSERT INTO btrace_core.knowledge_articles (
    article_id,
    title,
    content,
    article_type,
    status,
    published_at,
    published_by,
    created_by
    -- updated_at, updated_by are omitted (allowing NULL for initial state)
)
VALUES (
    '00000000-0000-0000-0000-000000000801',  -- article_id (using specific UUID)
    'Incident Management Process',           -- title
    'Standard operating procedures for incident management...', -- content (placeholder)
    'runbook',                               -- article_type
    'published',                             -- status
    CURRENT_TIMESTAMP,                       -- published_at (set to now)
    '00000000-0000-0000-0000-000000000501',  -- published_by (ensure this admin user exists)
    '00000000-0000-0000-0000-000000000501'   -- created_by (ensure this admin user exists)
);

-- =============================================
-- ENHANCEMENT 8: Change Management System 
-- =============================================


-- BUSINESS CASE:
-- The `change_management` tables track planned changes to systems and services,
-- enabling coordination between teams and providing context for incident analysis.
--
-- PURPOSE:
-- - Track planned infrastructure and application changes
-- - Support change approval workflows
-- - Correlate changes with incidents
-- - Maintain audit history of all modifications

CREATE TABLE btrace_core.change_requests (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    change_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    planned_start TIMESTAMP WITH TIME ZONE NOT NULL,
    planned_end TIMESTAMP WITH TIME ZONE NOT NULL,
    service_id UUID,
    environment_id UUID NOT NULL,
    risk_assessment TEXT,
    rollback_plan TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    approved_by UUID,
    FOREIGN KEY (service_id) REFERENCES btrace_core.services(service_id) ON DELETE SET NULL,
    FOREIGN KEY (environment_id) REFERENCES btrace_core.environments(environment_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_change_type CHECK (change_type IN ('deployment', 'config', 'maintenance', 'emergency')),
    CONSTRAINT chk_status CHECK (status IN ('draft', 'submitted', 'approved', 'rejected', 'implemented', 'rolledback', 'verified'))
);
COMMENT ON TABLE btrace_core.change_requests IS 'Track planned changes to systems and services';

CREATE TABLE btrace_core.change_approvals (
    approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    change_id UUID NOT NULL,
    approver_id UUID NOT NULL,
    decision VARCHAR(10) NOT NULL,
    comments TEXT,
    approved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (change_id) REFERENCES btrace_core.change_requests(change_id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES btrace_rbac.users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_decision CHECK (decision IN ('approved', 'rejected'))
);
COMMENT ON TABLE btrace_core.change_approvals IS 'Approval history for change requests';

CREATE TABLE btrace_core.change_implementations (
    implementation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    change_id UUID NOT NULL,
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL,
    output TEXT,
    implemented_by UUID,
    verified_by UUID,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (change_id) REFERENCES btrace_core.change_requests(change_id) ON DELETE CASCADE,
    FOREIGN KEY (implemented_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (verified_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_status CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'rolledback'))
);
COMMENT ON TABLE btrace_core.change_implementations IS 'Implementation details for executed changes';

CREATE INDEX idx_change_requests_service ON btrace_core.change_requests (service_id);
CREATE INDEX idx_change_requests_dates ON btrace_core.change_requests (planned_start, planned_end);
CREATE INDEX idx_change_requests_status ON btrace_core.change_requests (status);


-- =============================================
-- ENHANCEMENT 9: Enhanced Dependency Mapping
-- =============================================
-- BUSINESS CASE:
-- The `dependency_mapping` tables provide detailed relationship tracking
-- between services, infrastructure components, and external dependencies,
-- enabling better impact analysis and incident correlation.
--
-- PURPOSE:
-- - Model complex service dependencies
-- - Support topology visualization
-- - Enable impact analysis for changes/incidents
-- - Track third-party service dependencies

CREATE TABLE btrace_core.dependency_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_bidirectional BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_type_name UNIQUE (type_name)
);
COMMENT ON TABLE btrace_core.dependency_types IS 'Types of dependencies between system components';

CREATE TABLE btrace_core.dependency_mappings (
    dependency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_type VARCHAR(50) NOT NULL,
    source_id UUID NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    type_id UUID NOT NULL,
    description TEXT,
    criticality VARCHAR(20) NOT NULL DEFAULT 'medium',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    FOREIGN KEY (type_id) REFERENCES btrace_core.dependency_types(type_id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_source_type CHECK (source_type IN ('service', 'host', 'database', 'api', 'queue', 'external_service')),
    CONSTRAINT chk_target_type CHECK (target_type IN ('service', 'host', 'database', 'api', 'queue', 'external_service'))
);
COMMENT ON TABLE btrace_core.dependency_mappings IS 'Mappings between system components and their dependencies';

CREATE TABLE btrace_core.dependency_health (
    health_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dependency_id UUID NOT NULL,
    health_status VARCHAR(20) NOT NULL,
    check_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_time_ms INTEGER,
    error_rate DECIMAL(5,2),
    details JSONB,
    FOREIGN KEY (dependency_id) REFERENCES btrace_core.dependency_mappings(dependency_id) ON DELETE CASCADE,
    CONSTRAINT chk_health_status CHECK (health_status IN ('healthy', 'degraded', 'unavailable', 'unknown'))
);
COMMENT ON TABLE btrace_core.dependency_health IS 'Health status of tracked dependencies';
CREATE INDEX idx_dependency_health_time ON btrace_core.dependency_health (dependency_id, check_time DESC);


-- =============================================
-- ENHANCEMENT 10: Advanced Anomaly Detection
-- =============================================


-- BUSINESS CASE:
-- The `anomaly_detection` tables support machine learning-based anomaly
-- detection by storing model configurations, training data, and detection results.
--
-- PURPOSE:
-- - Store ML model configurations
-- - Track anomaly detection results
-- - Support model retraining
-- - Correlate anomalies with incidents

CREATE TABLE btrace_analytics.anomaly_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(100) NOT NULL,
    description TEXT,
    model_type VARCHAR(50) NOT NULL,
    target_metric VARCHAR(255) NOT NULL,
    training_data_range VARCHAR(50) NOT NULL,
    sensitivity DECIMAL(3,2) NOT NULL DEFAULT 0.95,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_trained_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_model_type CHECK (model_type IN ('statistical', 'machine_learning', 'deep_learning'))
);
COMMENT ON TABLE btrace_analytics.anomaly_models IS 'Configuration of anomaly detection models';

CREATE TABLE btrace_analytics.anomaly_detections (
    detection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metric_value DOUBLE PRECISION NOT NULL,
    expected_range JSONB NOT NULL,
    deviation_score DECIMAL(5,2) NOT NULL,
    confidence_score DECIMAL(5,2),
    service_id UUID,
    incident_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    reviewed_by UUID,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES btrace_analytics.anomaly_models(model_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES btrace_core.services(service_id) ON DELETE SET NULL,
    FOREIGN KEY (incident_id) REFERENCES btrace_core.incidents(incident_id) ON DELETE SET NULL,
    FOREIGN KEY (reviewed_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_status CHECK (status IN ('open', 'investigating', 'false_positive', 'confirmed', 'resolved'))
);
COMMENT ON TABLE btrace_analytics.anomaly_detections IS 'Detected anomalies from monitoring models';
CREATE INDEX idx_anomaly_detections_service ON btrace_analytics.anomaly_detections (service_id, detected_at DESC);
CREATE INDEX idx_anomaly_detections_status ON btrace_analytics.anomaly_detections (status) WHERE status = 'open';




----===============================================================================================================================================================================================
--- Views 
---==========
-- =============================================
-- ENHANCEMENT 15: Change Impact Analysis View (Fixed)
-- =============================================
-- BUSINESS CASE:
-- The `change_impact_analysis` view correlates upcoming changes with
-- service dependencies to assess potential impact before implementation.
--
-- PURPOSE:
-- - Predict impact of planned changes
-- - Identify risk areas
-- - Support change approval decisions
-- - Provide visibility across teams

-- Fix: Use the correct table name `service_dependencies` and its relevant columns.
-- The original query referenced non-existent tables (`dependency_mappings`, `dependency_types`)
-- and columns (`source_type`, `source_id`, `target_type`, `target_id`, `is_active`).
-- The join logic needs to identify services that the changed service depends *on* (target services)
-- or services that depend *on* the changed service (source services), based on the `service_dependencies` table.

-- =============================================
-- ENHANCEMENT 15: Change Impact Analysis View (Fixed)
-- =============================================
-- BUSINESS CASE:
-- The `change_impact_analysis` view correlates upcoming changes with
-- service dependencies to assess potential impact before implementation.
--
-- PURPOSE:
-- - Predict impact of planned changes
-- - Identify risk areas
-- - Support change approval decisions
-- - Provide visibility across teams

-- Fix: Use the correct column name `lifecycle_stage` instead of `criticality` for the service's importance level.
-- Also, ensure all referenced tables and columns exist based on the provided schema.

CREATE OR REPLACE VIEW btrace_analytics.change_impact_analysis AS
SELECT
    cr.change_id,
    cr.title AS change_title,
    cr.planned_start,
    cr.planned_end,
    s.service_name AS impacted_service_name, -- Clarify that this is the service being changed
    s.lifecycle_stage AS impacted_service_criticality, -- Fix: Use lifecycle_stage as the proxy for criticality/importance
    -- Count distinct services that the changed service depends on (outbound dependencies)
    COUNT(DISTINCT sd.target_service_id) AS direct_outbound_dependent_services_count,
    -- Count distinct services that depend on the changed service (inbound dependencies)
    COUNT(DISTINCT sd_inbound.source_service_id) AS direct_inbound_dependent_services_count,
    -- Aggregate distinct dependency types for outbound dependencies
    STRING_AGG(DISTINCT sd.dependency_type, ', ') AS outbound_dependency_types,
    -- Check if any outbound dependency targets a critical service
    -- Using lifecycle_stage = 'production' or similar logic as a proxy for high criticality
    MAX(CASE
        WHEN tgt_s.lifecycle_stage = 'production' THEN 1 -- Assume 'production' services are high criticality
        ELSE 0
    END) AS has_high_criticality_outbound_deps,
    -- Count related incidents for the *changed* service in the last 30 days
    COUNT(DISTINCT CASE
        WHEN i.start_time >= CURRENT_DATE - INTERVAL '30 days' THEN i.incident_id
        ELSE NULL
    END) AS related_incidents_last_30d_on_changed_service
FROM
    btrace_core.change_requests cr
JOIN
    btrace_core.services s ON cr.service_id = s.service_id
-- Join to find outbound dependencies (services THIS service calls)
LEFT JOIN
    btrace_core.service_dependencies sd ON sd.source_service_id = s.service_id
    AND sd.last_seen >= NOW() - INTERVAL '1 hour' -- Consider only recent dependencies
-- Join to get details of the target services of outbound dependencies
LEFT JOIN
    btrace_core.services tgt_s ON sd.target_service_id = tgt_s.service_id
-- Join to find inbound dependencies (services that call THIS service)
LEFT JOIN
    btrace_core.service_dependencies sd_inbound ON sd_inbound.target_service_id = s.service_id
    AND sd_inbound.last_seen >= NOW() - INTERVAL '1 hour' -- Consider only recent dependencies
-- Join to count incidents related to the *changed* service
LEFT JOIN
    btrace_core.incidents i ON i.service_id = s.service_id
WHERE
    cr.status IN ('approved', 'scheduled', 'in_progress') -- Include relevant statuses for upcoming/potential impact
    AND cr.planned_start >= CURRENT_DATE -- Focus on future or current changes
GROUP BY
    cr.change_id, cr.title, cr.planned_start, cr.planned_end, s.service_id, s.service_name, s.lifecycle_stage -- Fix: Group by lifecycle_stage
ORDER BY
    cr.planned_start ASC, has_high_criticality_outbound_deps DESC NULLS LAST, direct_outbound_dependent_services_count DESC NULLS LAST;

COMMENT ON VIEW btrace_analytics.change_impact_analysis IS 'Analysis of potential impact from planned changes based on service dependencies. Shows the service being changed, its outbound and inbound dependencies, and recent incident history for risk assessment.';
-- BUSINESS CASE:
-- The `anomaly_correlation` view identifies patterns between detected
-- anomalies and subsequent incidents, helping improve detection models.
--
-- PURPOSE:
-- - Measure anomaly detection effectiveness
-- - Identify false positives/negatives
-- - Support model tuning
-- - Improve incident prevention

CREATE OR REPLACE VIEW btrace_analytics.anomaly_correlation AS
SELECT 
    am.model_id,
    am.model_name,
    am.model_type,
    COUNT(DISTINCT ad.detection_id) AS total_detections,
    COUNT(DISTINCT ad.detection_id) FILTER (WHERE ad.status = 'false_positive') AS false_positives,
    COUNT(DISTINCT ad.detection_id) FILTER (WHERE ad.status = 'confirmed') AS confirmed_anomalies,
    COUNT(DISTINCT i.incident_id) FILTER (
        WHERE i.start_time BETWEEN ad.detected_at - INTERVAL '1 hour' AND ad.detected_at + INTERVAL '4 hours'
    ) AS correlated_incidents,
    ROUND(COUNT(DISTINCT i.incident_id) FILTER (
        WHERE i.start_time BETWEEN ad.detected_at - INTERVAL '1 hour' AND ad.detected_at + INTERVAL '4 hours'
    ) * 100.0 / NULLIF(COUNT(DISTINCT ad.detection_id), 0), 2) AS incident_correlation_rate,
    AVG(EXTRACT(EPOCH FROM (i.detected_at - ad.detected_at))) FILTER (
        WHERE i.start_time BETWEEN ad.detected_at - INTERVAL '1 hour' AND ad.detected_at + INTERVAL '4 hours'
    ) AS avg_lead_time_seconds
FROM 
    btrace_analytics.anomaly_models am
LEFT JOIN 
    btrace_analytics.anomaly_detections ad ON am.model_id = ad.model_id
    AND ad.detected_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN 
    btrace_core.incidents i ON ad.service_id = i.service_id
    AND i.start_time >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    am.model_id, am.model_name, am.model_type
ORDER BY 
    incident_correlation_rate DESC;
COMMENT ON VIEW btrace_analytics.anomaly_correlation IS 'Correlation analysis between detected anomalies and subsequent incidents';


--=====
--Change Risk Evaluation 
--====
-- =============================================
-- ENHANCEMENT 16: Evaluate Change Risk Procedure (Fixed)
-- =============================================
-- BUSINESS CASE:
-- The `evaluate_change_risk` procedure analyzes a change request against
-- historical data to predict risk levels and suggest mitigation strategies.
--
-- PURPOSE:
-- - Automate risk assessment
-- - Suggest optimal change windows
-- - Identify required approvals
-- - Recommend verification steps

-- Fix: Use the correct table name `service_dependencies` and its relevant columns.
-- The original query referenced the non-existent table `dependency_mappings`
-- and columns (`source_type`, `source_id`, `target_type`, `target_id`, `criticality`).
-- Also, use `lifecycle_stage` from the `services` table as the proxy for criticality.

CREATE OR REPLACE PROCEDURE btrace_core.evaluate_change_risk(
    p_change_id UUID,
    OUT p_risk_score DECIMAL(3,2),
    OUT p_risk_level VARCHAR(20),
    OUT p_recommendations TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_change RECORD;
    v_service RECORD;
    v_incident_count INTEGER;
    v_failure_rate DECIMAL(5,2);
    v_dependency_count INTEGER;
    v_high_crit_deps INTEGER;
BEGIN
    -- Get change details
    SELECT * INTO v_change
    FROM btrace_core.change_requests
    WHERE change_id = p_change_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Change request with ID % not found', p_change_id;
    END IF;

    -- Get service details
    SELECT * INTO v_service
    FROM btrace_core.services
    WHERE service_id = v_change.service_id;

    -- Calculate historical failure rate for similar changes
    SELECT
        COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / NULLIF(COUNT(*), 0)
    INTO v_failure_rate
    FROM btrace_core.change_implementations
    WHERE change_id IN (
        SELECT change_id
        FROM btrace_core.change_requests
        WHERE change_type = v_change.change_type
        AND service_id = v_change.service_id
    );

    -- Count related incidents in similar time windows (last 90 days)
    SELECT COUNT(*) INTO v_incident_count
    FROM btrace_core.incidents
    WHERE service_id = v_change.service_id
    AND EXTRACT(HOUR FROM start_time) BETWEEN EXTRACT(HOUR FROM v_change.planned_start) AND EXTRACT(HOUR FROM v_change.planned_end)
    AND start_time >= CURRENT_DATE - INTERVAL '90 days';

    -- Count dependencies using the correct table and columns
    -- Count outbound dependencies (services THIS service calls)
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE tgt_s.lifecycle_stage = 'production') -- Assume 'production' services are high criticality
    INTO v_dependency_count, v_high_crit_deps
    FROM btrace_core.service_dependencies sd
    JOIN btrace_core.services tgt_s ON sd.target_service_id = tgt_s.service_id -- Join to get target service details
    WHERE sd.source_service_id = v_change.service_id
    AND sd.last_seen >= NOW() - INTERVAL '1 hour'; -- Consider only recent dependencies

    -- Calculate risk score (simplified example)
    -- Normalize components to be between 0 and 1 before weighting
    p_risk_score := LEAST(1.0,
        (COALESCE(v_failure_rate, 0) * 0.3 / 100) + -- Normalize failure rate (assuming max 100%)
        LEAST(1.0, (v_incident_count * 0.2) / 10) + -- Normalize incident count (assuming max 10 incidents is high risk)
        LEAST(1.0, (v_high_crit_deps * 0.3) / 5) + -- Normalize high crit dep count (assuming max 5 is high risk)
        CASE WHEN v_service.lifecycle_stage = 'production' THEN 0.2 ELSE 0.1 END -- Use lifecycle_stage instead of criticality
    );

    -- Determine risk level
    IF p_risk_score >= 0.7 THEN
        p_risk_level := 'high';
        p_recommendations := ARRAY[
            'Schedule during low-traffic window',
            'Require director approval',
            'Prepare full rollback plan',
            'Notify all dependent service owners',
            'Conduct pre-change review meeting'
        ];
    ELSIF p_risk_score >= 0.4 THEN
        p_risk_level := 'medium';
        p_recommendations := ARRAY[
            'Schedule during business hours',
            'Require manager approval',
            'Prepare partial rollback plan',
            'Notify critical dependency owners',
            'Conduct pre-change checklist review'
        ];
    ELSE
        p_risk_level := 'low';
        p_recommendations := ARRAY[
            'Standard approval process',
            'Basic rollback plan',
            'Monitor during implementation'
        ];
    END IF;

    -- Add service-specific recommendations
    IF v_service.lifecycle_stage = 'production' THEN -- Use lifecycle_stage instead of criticality
        p_recommendations := p_recommendations || ARRAY['Include SRE in implementation'];
    END IF;

    IF v_change.change_type = 'deployment' THEN
        p_recommendations := p_recommendations || ARRAY['Perform canary deployment'];
    END IF;
END;
$$;

COMMENT ON PROCEDURE btrace_core.evaluate_change_risk IS 'Evaluates risk level for a change request based on historical data and service dependencies';



-- BUSINESS CASE:
-- The `train_anomaly_model` procedure manages the retraining process for
-- anomaly detection models based on recent operational data.
--
-- PURPOSE:
-- - Automate model retraining
-- - Incorporate new data patterns
-- - Adjust sensitivity thresholds
-- - Maintain model performance

CREATE OR REPLACE PROCEDURE btrace_analytics.train_anomaly_model(
    p_model_id UUID,
    p_training_window VARCHAR(20) DEFAULT '30d',
    p_retrain_if_exists BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_model RECORD;
    v_training_data_start TIMESTAMP;
    v_training_data_end TIMESTAMP;
    v_training_count INTEGER;
    v_incident_count INTEGER;
BEGIN
    -- Get model details
    SELECT * INTO v_model
    FROM btrace_analytics.anomaly_models
    WHERE model_id = p_model_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Anomaly model with ID % not found', p_model_id;
    END IF;
    
    -- Check if model already trained recently
    IF NOT p_retrain_if_exists AND v_model.last_trained_at >= CURRENT_TIMESTAMP - INTERVAL '7 days' THEN
        RAISE NOTICE 'Model % was trained recently, skipping retrain', p_model_id;
        RETURN;
    END IF;
    
    -- Determine training window
    v_training_data_end := CURRENT_TIMESTAMP;
    CASE p_training_window
        WHEN '7d' THEN v_training_data_start := v_training_data_end - INTERVAL '7 days';
        WHEN '30d' THEN v_training_data_start := v_training_data_end - INTERVAL '30 days';
        WHEN '90d' THEN v_training_data_start := v_training_data_end - INTERVAL '90 days';
        ELSE RAISE EXCEPTION 'Invalid training window: %', p_training_window;
    END CASE;
    
    -- Log training start (in a real implementation, this would call ML service)
    INSERT INTO btrace_audit.audit_logs (
        event_type,
        event_subtype,
        resource_type,
        resource_id,
        action,
        action_status,
        details
    ) VALUES (
        'ml',
        'model_training',
        'anomaly_model',
        p_model_id::TEXT,
        'update',
        'started',
        jsonb_build_object(
            'training_window', p_training_window,
            'data_start', v_training_data_start,
            'data_end', v_training_data_end
        )
    );
    
    -- Get training data stats (simplified example)
    -- In practice, this would extract and prepare the actual training data
    IF v_model.target_metric LIKE 'service.%' THEN
        -- Service-level metric
        SELECT COUNT(*) INTO v_training_count
        FROM btrace_core.metrics
        WHERE metric_name = v_model.target_metric
        AND timestamp BETWEEN v_training_data_start AND v_training_data_end;
        
        SELECT COUNT(*) INTO v_incident_count
        FROM btrace_core.incidents i
        JOIN btrace_core.services s ON i.service_id = s.service_id
        WHERE i.start_time BETWEEN v_training_data_start AND v_training_data_end;
    ELSE
        -- System-level metric
        SELECT COUNT(*) INTO v_training_count
        FROM btrace_core.metrics
        WHERE metric_name = v_model.target_metric
        AND timestamp BETWEEN v_training_data_start AND v_training_data_end;
        
        SELECT COUNT(*) INTO v_incident_count
        FROM btrace_core.incidents
        WHERE start_time BETWEEN v_training_data_start AND v_training_data_end;
    END IF;
    
    -- Simulate model training (in practice, this would call an ML service)
    PERFORM pg_sleep(1); -- Simulate processing time
    
    -- Update model with new training timestamp
    UPDATE btrace_analytics.anomaly_models
    SET 
        last_trained_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE model_id = p_model_id;
    
    -- Log training completion
    INSERT INTO btrace_audit.audit_logs (
        event_type,
        event_subtype,
        resource_type,
        resource_id,
        action,
        action_status,
        details
    ) VALUES (
        'ml',
        'model_training',
        'anomaly_model',
        p_model_id::TEXT,
        'update',
        'completed',
        jsonb_build_object(
            'training_samples', v_training_count,
            'incident_samples', v_incident_count,
            'training_duration', '1s' -- simulated
        )
    );
    
    COMMIT;
END;
$$;
COMMENT ON PROCEDURE btrace_analytics.train_anomaly_model IS 'Manages the retraining process for anomaly detection models';


-- BUSINESS CASE:
-- These additional indexes optimize query performance for the new change
-- management and dependency tracking features, particularly for temporal
-- queries and relationship traversals.
--
-- PURPOSE:
-- - Accelerate change timeline queries
-- - Improve dependency graph traversal
-- - Support impact analysis
-- - Maintain performance at scale

CREATE INDEX IF NOT EXISTS idx_change_requests_timeline ON btrace_core.change_requests (planned_start, planned_end, status);
CREATE INDEX IF NOT EXISTS idx_change_implementations_status ON btrace_core.change_implementations (change_id, status);
CREATE INDEX IF NOT EXISTS idx_dependency_mappings_source ON btrace_core.dependency_mappings (source_type, source_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_dependency_mappings_target ON btrace_core.dependency_mappings (target_type, target_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_anomaly_detections_model ON btrace_analytics.anomaly_detections (model_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_anomaly_detections_metric ON btrace_analytics.anomaly_detections ((details->>'metric_name'), detected_at DESC);

--todo initial data for new enhancements 

--==========
-- New Enhancements -- Networking Module Schema 
--======
-- =============================================
-- NETWORKING MODULE SCHEMA
-- =============================================
-- to add the following features 
--- complete network device and topology inventory as i beleive they are part of the environment 
-- interface level monitoring and metrics 
-- VLAN and network service tracking -- this would help on monitoring network services, page profile and application performance 
-- network-specific incident management 
-- automated anomaly detection 
-- integration with core platform features 
-- ready to use monitoring rules and dashboards. 
--- network metrics and KPIs that can be helpful for application performance at different situations 
--- During SycliQ IOT Platform development, the network performance varied at different sites. it was quicker for hubs, rather than for nodes.


-- Create schema for networking tables
CREATE SCHEMA IF NOT EXISTS btrace_network;
COMMENT ON SCHEMA btrace_network IS 'Networking monitoring and management tables';

-- BUSINESS CASE:
-- The `network_devices` table inventories all network infrastructure components
-- being monitored by the platform, enabling correlation between network health
-- and service performance.
--
-- PURPOSE:
-- - Track network device inventory
-- - Store critical configuration details
-- - Support topology mapping
-- - Enable device-specific monitoring

CREATE TABLE btrace_network.network_devices (
    device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hostname VARCHAR(255) NOT NULL,
    ip_address INET NOT NULL,
    mac_address MACADDR,
    device_type VARCHAR(50) NOT NULL,
    vendor VARCHAR(100),
    model VARCHAR(100),
    os_version VARCHAR(100),
    role VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    environment_id UUID NOT NULL,
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    snmp_community TEXT,
    ssh_credentials_ref TEXT,
    last_discovered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_network_device UNIQUE (hostname, ip_address),
    FOREIGN KEY (environment_id) REFERENCES btrace_core.environments(environment_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_device_type CHECK (device_type IN ('router', 'switch', 'firewall', 'load_balancer', 'wifi_ap', 'server', 'other')),
    CONSTRAINT chk_role CHECK (role IN ('core', 'distribution', 'access', 'edge', 'management', 'storage'))
);
COMMENT ON TABLE btrace_network.network_devices IS 'Inventory of network infrastructure devices';

-- BUSINESS CASE:
-- The `network_interfaces` table tracks all physical and logical network
-- interfaces, enabling granular monitoring of network connectivity and
-- performance at the interface level.
--
-- PURPOSE:
-- - Track interface configurations
-- - Support capacity planning
-- - Enable interface-level metrics collection
-- - Correlate interface status with service issues

CREATE TABLE btrace_network.network_interfaces (
    interface_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL,
    name VARCHAR(50) NOT NULL,
    alias VARCHAR(100),
    mac_address MACADDR,
    ip_address INET,
    subnet_mask CIDR,
    speed_mbps INTEGER,
    duplex VARCHAR(10),
    mtu INTEGER,
    is_up BOOLEAN NOT NULL DEFAULT TRUE,
    is_physical BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    CONSTRAINT chk_duplex CHECK (duplex IN ('half', 'full', 'auto', NULL))
);
COMMENT ON TABLE btrace_network.network_interfaces IS 'Network interfaces associated with devices';

-- BUSINESS CASE:
-- The `network_links` table defines connections between network devices,
-- enabling topology visualization and impact analysis for network changes
-- or failures.
--
-- PURPOSE:
-- - Document physical network topology
-- - Support path analysis
-- - Enable impact assessment
-- - Facilitate troubleshooting

CREATE TABLE btrace_network.network_links (
    link_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_device_id UUID NOT NULL,
    source_interface_id UUID,
    target_device_id UUID NOT NULL,
    target_interface_id UUID,
    link_type VARCHAR(50) NOT NULL,
    speed_mbps INTEGER,
    is_lag BOOLEAN NOT NULL DEFAULT FALSE,
    lag_group VARCHAR(50),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    FOREIGN KEY (source_device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (source_interface_id) REFERENCES btrace_network.network_interfaces(interface_id) ON DELETE SET NULL,
    FOREIGN KEY (target_device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (target_interface_id) REFERENCES btrace_network.network_interfaces(interface_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_link_type CHECK (link_type IN ('fiber', 'copper', 'wan', 'wireless', 'virtual'))
);
COMMENT ON TABLE btrace_network.network_links IS 'Physical and logical connections between network devices';

-- BUSINESS CASE:
-- The `network_metrics` table stores time-series network performance data
-- collected from monitoring tools, enabling historical analysis and
-- capacity planning.
--
-- PURPOSE:
-- - Store interface utilization metrics
-- - Track network performance trends
-- - Support capacity planning
-- - Enable threshold-based alerting
CREATE TABLE btrace_network.network_metrics (
    metric_id UUID NOT NULL DEFAULT uuid_generate_v4(), -- Remove PRIMARY KEY from here
    device_id UUID,
    interface_id UUID,
    metric_type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(10),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Composite Primary Key including the partition key column
    PRIMARY KEY (metric_id, timestamp), 
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (interface_id) REFERENCES btrace_network.network_interfaces(interface_id) ON DELETE CASCADE,
    CONSTRAINT chk_metric_type CHECK (metric_type IN (
        'bandwidth_in', 'bandwidth_out', 'errors_in', 'errors_out', 
        'discards_in', 'discards_out', 'packets_in', 'packets_out',
        'cpu_utilization', 'memory_utilization', 'temperature',
        'latency', 'jitter', 'packet_loss'
    ))
) PARTITION BY RANGE (timestamp);

COMMENT ON TABLE btrace_network.network_metrics IS 'Time-series network performance metrics';


-- BUSINESS CASE:
-- The `network_services` table maps network services (DNS, DHCP, NTP, etc.)
-- to the devices that host them, enabling service-level monitoring of
-- network infrastructure.
--
-- PURPOSE:
-- - Track network service dependencies
-- - Support service-level monitoring
-- - Enable impact analysis
-- - Facilitate troubleshooting

CREATE TABLE btrace_network.network_services (
    service_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    port INTEGER,
    protocol VARCHAR(10),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    monitoring_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_service_type CHECK (service_type IN (
        'dns', 'dhcp', 'ntp', 'snmp', 'syslog', 'radius', 'tacacs',
        'ldap', 'ipam', 'vpn', 'proxy', 'ftp', 'http', 'https'
    )),
    CONSTRAINT chk_protocol CHECK (protocol IN ('tcp', 'udp', 'icmp', NULL))
);
COMMENT ON TABLE btrace_network.network_services IS 'Network services hosted on infrastructure devices';

-- BUSINESS CASE:
-- The `network_vlans` table tracks VLAN configurations across the network,
-- enabling proper segmentation monitoring and troubleshooting.
--
-- PURPOSE:
-- - Document VLAN architecture
-- - Track VLAN assignments
-- - Support security audits
-- - Enable VLAN-specific monitoring

CREATE TABLE btrace_network.network_vlans (
    vlan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vlan_number INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    subnet CIDR,
    gateway INET,
    purpose VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    CONSTRAINT uq_vlan_number UNIQUE (vlan_number),
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL
);
COMMENT ON TABLE btrace_network.network_vlans IS 'VLAN configurations for network segmentation';

-- BUSINESS CASE:
-- The `vlan_assignments` table maps VLANs to interfaces and devices,
-- providing complete visibility into network segmentation.
--
-- PURPOSE:
-- - Track VLAN port assignments
-- - Support change management
-- - Enable security monitoring
-- - Facilitate troubleshooting

CREATE TABLE btrace_network.vlan_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vlan_id UUID NOT NULL,
    device_id UUID NOT NULL,
    interface_id UUID,
    assignment_type VARCHAR(50) NOT NULL,
    is_tagged BOOLEAN NOT NULL DEFAULT FALSE,
    native_vlan BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    FOREIGN KEY (vlan_id) REFERENCES btrace_network.network_vlans(vlan_id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (interface_id) REFERENCES btrace_network.network_interfaces(interface_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_assignment_type CHECK (assignment_type IN ('access', 'trunk', 'voice', 'management'))
);
COMMENT ON TABLE btrace_network.vlan_assignments IS 'Assignments of VLANs to network interfaces';

-- BUSINESS CASE:
-- The `network_issues` table tracks network-specific incidents and
-- anomalies, enabling specialized workflows for network operations.
--
-- PURPOSE:
-- - Track network-specific incidents
-- - Support network troubleshooting
-- - Enable network change management
-- - Facilitate root cause analysis

CREATE TABLE btrace_network.network_issues (
    issue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    device_id UUID,
    interface_id UUID,
    vlan_id UUID,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    incident_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    resolved_by UUID,
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE SET NULL,
    FOREIGN KEY (interface_id) REFERENCES btrace_network.network_interfaces(interface_id) ON DELETE SET NULL,
    FOREIGN KEY (vlan_id) REFERENCES btrace_network.network_vlans(vlan_id) ON DELETE SET NULL,
    FOREIGN KEY (incident_id) REFERENCES btrace_core.incidents(incident_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (resolved_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_severity CHECK (severity IN ('critical', 'major', 'minor', 'warning')),
    CONSTRAINT chk_status CHECK (status IN ('open', 'investigating', 'resolved', 'closed'))
);
COMMENT ON TABLE btrace_network.network_issues IS 'Network-specific incidents and problems';

-- BUSINESS CASE:
-- The `network_config_history` table tracks configuration changes to
-- network devices, enabling change tracking and rollback capabilities.
--
-- PURPOSE:
-- - Maintain configuration history
-- - Support change audits
-- - Enable configuration diffs
-- - Facilitate troubleshooting

CREATE TABLE btrace_network.network_config_history (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL,
    config_type VARCHAR(50) NOT NULL,
    previous_config TEXT,
    new_config TEXT NOT NULL,
    change_reason TEXT,
    change_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by UUID,
    backup_successful BOOLEAN NOT NULL DEFAULT FALSE,
    validation_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES btrace_network.network_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_config_type CHECK (config_type IN ('running', 'startup', 'partial')),
    CONSTRAINT chk_validation_status CHECK (validation_status IN ('pending', 'success', 'failure', 'warning'))
);
COMMENT ON TABLE btrace_network.network_config_history IS 'History of network device configuration changes';

-- BUSINESS CASE:
-- The `network_monitoring_rules` table defines monitoring rules and
-- thresholds for network infrastructure, enabling proactive alerting.
--
-- PURPOSE:
-- - Define network monitoring thresholds
-- - Support multi-vendor monitoring
-- - Enable customized alerting
-- - Standardize network monitoring

CREATE TABLE btrace_network.network_monitoring_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(100) NOT NULL,
    description TEXT,
    metric_type VARCHAR(50) NOT NULL,
    threshold_value DOUBLE PRECISION NOT NULL,
    threshold_type VARCHAR(20) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    device_type VARCHAR(50),
    vendor VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID,
    updated_by UUID,
    CONSTRAINT uq_rule_name UNIQUE (rule_name),
    FOREIGN KEY (created_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES btrace_rbac.users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_threshold_type CHECK (threshold_type IN ('upper', 'lower', 'equal', 'not_equal')),
    CONSTRAINT chk_severity CHECK (severity IN ('critical', 'major', 'minor', 'warning'))
);
COMMENT ON TABLE btrace_network.network_monitoring_rules IS 'Rules for monitoring network infrastructure';


---===Views----
-- BUSINESS CASE:
-- The `network_device_status` view provides a comprehensive overview of
-- all network devices and their current operational status based on the
-- most recent metrics.
--
-- PURPOSE:
-- - Single pane view of network health
-- - Quickly identify problem devices
-- - Monitor resource utilization
-- - Support capacity planning

CREATE OR REPLACE VIEW btrace_network.network_device_status AS
WITH latest_metrics AS (
    -- Get the most recent metric for each device and metric type
    SELECT DISTINCT ON (device_id, metric_type)
        device_id,
        metric_type,
        value,
        unit,
        timestamp
    FROM btrace_network.network_metrics
    ORDER BY device_id, metric_type, timestamp DESC
),
device_utilization AS (
    -- Aggregate key metrics per device
    SELECT 
        device_id,
        -- CPU Utilization
        MAX(CASE WHEN metric_type = 'cpu_utilization' THEN value END) AS cpu_utilization_percent,
        -- Memory Utilization
        MAX(CASE WHEN metric_type = 'memory_utilization' THEN value END) AS memory_utilization_percent,
        -- Temperature
        MAX(CASE WHEN metric_type = 'temperature' THEN value END) AS temperature_celsius,
        -- Latency (average if multiple interfaces)
        AVG(CASE WHEN metric_type = 'latency' THEN value END) AS avg_latency_ms,
        -- Packet Loss (average if multiple interfaces)
        AVG(CASE WHEN metric_type = 'packet_loss' THEN value END) AS avg_packet_loss_percent,
        -- Most recent metric timestamp for this device
        MAX(timestamp) AS last_metric_timestamp
    FROM latest_metrics
    GROUP BY device_id
)
SELECT 
    nd.device_id,
    nd.hostname,
    nd.ip_address,
    nd.device_type,
    nd.vendor,
    nd.model,
    nd.role,
    nd.location,
    nd.is_critical,
    nd.last_discovered_at,
    -- Utilization and Status Metrics
    du.cpu_utilization_percent,
    du.memory_utilization_percent,
    du.temperature_celsius,
    du.avg_latency_ms,
    du.avg_packet_loss_percent,
    du.last_metric_timestamp,
    -- Derived Status Field (simplified logic - can be enhanced)
    CASE 
        WHEN du.temperature_celsius > 80 THEN 'CRITICAL' -- High temperature
        WHEN du.cpu_utilization_percent > 90 THEN 'CRITICAL' -- High CPU
        WHEN du.memory_utilization_percent > 90 THEN 'MAJOR' -- High Memory
        WHEN du.avg_packet_loss_percent > 5 THEN 'MAJOR' -- Significant packet loss
        WHEN du.avg_latency_ms > 100 THEN 'MINOR' -- High latency
        WHEN du.last_metric_timestamp < NOW() - INTERVAL '15 minutes' THEN 'WARNING' -- Stale metrics
        WHEN du.cpu_utilization_percent > 75 THEN 'MINOR' -- Moderate CPU
        WHEN du.memory_utilization_percent > 75 THEN 'MINOR' -- Moderate Memory
        ELSE 'OK'
    END AS operational_status,
    -- Days since last discovery
    EXTRACT(EPOCH FROM (NOW() - nd.last_discovered_at)) / 86400 AS days_since_last_discovery
FROM btrace_network.network_devices nd
LEFT JOIN device_utilization du ON nd.device_id = du.device_id;

COMMENT ON VIEW btrace_network.network_device_status IS 'Comprehensive overview of network device health and current operational status';


-- BUSINESS CASE:
-- The `network_bandwidth_utilization` view analyzes interface bandwidth
-- usage to identify potential bottlenecks and overutilized links.
--
-- PURPOSE:
-- - Identify congested links
-- - Support capacity planning
-- - Monitor traffic trends
-- - Highlight underutilized resources

CREATE OR REPLACE VIEW btrace_network.network_bandwidth_utilization AS
WITH latest_bandwidth_metrics AS (
    -- Get the most recent bandwidth metrics for each interface
    SELECT DISTINCT ON (interface_id, metric_type)
        nm.interface_id,
        nm.metric_type,
        nm.value,
        nm.unit,
        nm.timestamp
    FROM btrace_network.network_metrics nm
    WHERE nm.metric_type IN ('bandwidth_in', 'bandwidth_out')
    ORDER BY interface_id, metric_type, timestamp DESC
),
interface_bandwidth_data AS (
    -- Pivot the data to get in/out bandwidth on the same row per interface
    SELECT 
        i.interface_id,
        i.device_id,
        i.name AS interface_name,
        i.alias AS interface_alias,
        i.speed_mbps AS configured_speed_mbps,
        -- Inbound bandwidth (last recorded value)
        MAX(CASE WHEN lbm.metric_type = 'bandwidth_in' THEN lbm.value END) AS current_bandwidth_in_bps,
        -- Outbound bandwidth (last recorded value)
        MAX(CASE WHEN lbm.metric_type = 'bandwidth_out' THEN lbm.value END) AS current_bandwidth_out_bps,
        -- Timestamp of the latest metric for this interface
        MAX(lbm.timestamp) AS last_metric_timestamp
    FROM btrace_network.network_interfaces i
    LEFT JOIN latest_bandwidth_metrics lbm ON i.interface_id = lbm.interface_id
    GROUP BY i.interface_id, i.device_id, i.name, i.alias, i.speed_mbps
)
SELECT 
    ibd.interface_id,
    ibd.device_id,
    nd.hostname AS device_hostname,
    nd.device_type,
    nd.role AS device_role,
    ibd.interface_name,
    ibd.interface_alias,
    ibd.configured_speed_mbps,
    -- Convert bps to Mbps for easier readability (with proper casting for ROUND)
    ROUND(COALESCE(ibd.current_bandwidth_in_bps, 0)::NUMERIC / 1000000.0, 2) AS current_bandwidth_in_mbps,
    ROUND(COALESCE(ibd.current_bandwidth_out_bps, 0)::NUMERIC / 1000000.0, 2) AS current_bandwidth_out_mbps,
    ibd.last_metric_timestamp,
    -- Calculate utilization percentages (if speed is configured)
    CASE 
        WHEN ibd.configured_speed_mbps IS NOT NULL AND ibd.configured_speed_mbps > 0 THEN
            ROUND((COALESCE(ibd.current_bandwidth_in_bps, 0)::NUMERIC / (ibd.configured_speed_mbps * 1000000.0)) * 100, 2)
        ELSE NULL 
    END AS bandwidth_in_utilization_percent,
    CASE 
        WHEN ibd.configured_speed_mbps IS NOT NULL AND ibd.configured_speed_mbps > 0 THEN
            ROUND((COALESCE(ibd.current_bandwidth_out_bps, 0)::NUMERIC / (ibd.configured_speed_mbps * 1000000.0)) * 100, 2)
        ELSE NULL 
    END AS bandwidth_out_utilization_percent,
    -- Identify potential issues based on utilization
    CASE 
        WHEN ibd.configured_speed_mbps IS NOT NULL AND ibd.configured_speed_mbps > 0 THEN
            CASE 
                WHEN GREATEST(
                    COALESCE(ibd.current_bandwidth_in_bps, 0) / (ibd.configured_speed_mbps * 1000000.0),
                    COALESCE(ibd.current_bandwidth_out_bps, 0) / (ibd.configured_speed_mbps * 1000000.0)
                ) > 0.8 THEN 'HIGH_UTILIZATION'
                WHEN GREATEST(
                    COALESCE(ibd.current_bandwidth_in_bps, 0) / (ibd.configured_speed_mbps * 1000000.0),
                    COALESCE(ibd.current_bandwidth_out_bps, 0) / (ibd.configured_speed_mbps * 1000000.0)
                ) < 0.1 THEN 'LOW_UTILIZATION'
                ELSE 'NORMAL'
            END
        ELSE 'SPEED_NOT_CONFIGURED'
    END AS utilization_status,
    -- Days since last metric update
    CASE 
        WHEN ibd.last_metric_timestamp IS NOT NULL THEN
            EXTRACT(EPOCH FROM (NOW() - ibd.last_metric_timestamp)) / 86400
        ELSE NULL 
    END AS days_since_last_metric
FROM interface_bandwidth_data ibd
JOIN btrace_network.network_devices nd ON ibd.device_id = nd.device_id
-- Filter out interfaces without any bandwidth data or inactive interfaces if needed
WHERE ibd.current_bandwidth_in_bps IS NOT NULL OR ibd.current_bandwidth_out_bps IS NOT NULL;

COMMENT ON VIEW btrace_network.network_bandwidth_utilization IS 'Analysis of network interface bandwidth usage for capacity planning and bottleneck identification';


-- BUSINESS CASE:
-- The `network_service_dependencies` view maps application services to
-- their underlying network dependencies, enabling impact analysis for
-- network changes or outages.
--
-- PURPOSE:
-- - Understand service network requirements
-- - Assess impact of network changes
-- - Troubleshoot connectivity issues
-- - Plan network upgrades

CREATE OR REPLACE VIEW btrace_network.network_service_dependencies AS
SELECT 
    ns.service_id,
    ns.service_name,
    ns.service_type,
    ns.port,
    ns.protocol,
    ns.is_active AS service_is_active,
    nd.device_id,
    nd.hostname AS device_hostname,
    nd.ip_address AS device_ip,
    nd.device_type,
    nd.vendor,
    nd.model,
    nd.role AS device_role,
    nd.is_critical AS device_is_critical,
    ni.interface_id,
    ni.name AS interface_name,
    ni.alias AS interface_alias,
    ni.ip_address AS interface_ip,
    ni.is_up AS interface_is_up,
    nv.vlan_id,
    nv.vlan_number,
    nv.name AS vlan_name,
    nv.subnet AS vlan_subnet,
    nv.gateway AS vlan_gateway,
    nl.link_id,
    nl.link_type,
    nl.speed_mbps AS link_speed_mbps,
    target_nd.device_id AS target_device_id,
    target_nd.hostname AS target_device_hostname,
    target_nd.ip_address AS target_device_ip,
    target_nd.device_type AS target_device_type,
    target_nd.role AS target_device_role
FROM btrace_network.network_services ns
JOIN btrace_network.network_devices nd ON ns.device_id = nd.device_id
LEFT JOIN btrace_network.network_interfaces ni ON nd.device_id = ni.device_id
LEFT JOIN btrace_network.vlan_assignments nva ON ni.interface_id = nva.interface_id
LEFT JOIN btrace_network.network_vlans nv ON nva.vlan_id = nv.vlan_id
LEFT JOIN btrace_network.network_links nl ON (
    (nl.source_device_id = nd.device_id AND nl.source_interface_id = ni.interface_id) OR
    (nl.target_device_id = nd.device_id AND nl.target_interface_id = ni.interface_id)
)
LEFT JOIN btrace_network.network_devices target_nd ON (
    (nl.source_device_id = nd.device_id AND nl.target_device_id = target_nd.device_id) OR
    (nl.target_device_id = nd.device_id AND nl.source_device_id = target_nd.device_id)
)
WHERE ns.is_active = TRUE;

COMMENT ON VIEW btrace_network.network_service_dependencies IS 'Mapping of application services to their underlying network dependencies for impact analysis';

-- BUSINESS CASE:
-- The `detect_network_anomalies` procedure analyzes recent network metrics
-- against defined thresholds to identify potential issues before they
-- impact services.
--
-- PURPOSE:
-- - Automate network health monitoring
-- - Detect performance anomalies
-- - Identify configuration issues
-- - Proactively alert network teams

CREATE OR REPLACE PROCEDURE btrace_network.detect_network_anomalies()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rule RECORD;
    v_issue_count INTEGER := 0;
    v_issue_title TEXT;
    v_issue_description TEXT;
    v_severity TEXT;
    v_existing_issue UUID;
BEGIN
    -- Loop through all active monitoring rules
    FOR v_rule IN
        SELECT 
            rule_id,
            rule_name,
            description,
            metric_type,
            threshold_value,
            threshold_type,
            severity
        FROM btrace_network.network_monitoring_rules
        WHERE is_active = TRUE
    LOOP
        -- Check for metrics that violate the current rule
        -- We'll look for metrics in the last 15 minutes
        INSERT INTO btrace_network.network_issues (
            title,
            description,
            severity,
            status,
            device_id,
            interface_id,
            start_time,
            created_at
        )
        SELECT DISTINCT
            -- Title
            LEFT('Anomaly: ' || v_rule.rule_name || ' on ' || 
                 COALESCE(nd.hostname, 'Unknown Device') || 
                 CASE 
                     WHEN ni.name IS NOT NULL THEN ' (' || ni.name || ')' 
                     ELSE '' 
                 END, 255),
            -- Description
            'Metric "' || v_rule.metric_type || '" value ' || nm.value || 
            ' ' || CASE 
                      WHEN v_rule.threshold_type = 'upper' THEN 'exceeds upper threshold of ' || v_rule.threshold_value
                      WHEN v_rule.threshold_type = 'lower' THEN 'falls below lower threshold of ' || v_rule.threshold_value
                      WHEN v_rule.threshold_type = 'equal' THEN 'equals threshold value of ' || v_rule.threshold_value
                      WHEN v_rule.threshold_type = 'not_equal' THEN 'differs from expected value of ' || v_rule.threshold_value
                      ELSE 'violates threshold'
                  END || '. Rule: ' || COALESCE(v_rule.description, v_rule.rule_name),
            -- Severity (map rule severity to issue severity)
            v_rule.severity,
            -- Status
            'open',
            -- Device and Interface
            nm.device_id,
            nm.interface_id,
            -- Start time (time of the metric)
            nm.timestamp,
            -- Created at
            NOW()
        FROM btrace_network.network_metrics nm
        JOIN btrace_network.network_devices nd ON nm.device_id = nd.device_id
        LEFT JOIN btrace_network.network_interfaces ni ON nm.interface_id = ni.interface_id
        WHERE 
            -- Match the metric type
            nm.metric_type = v_rule.metric_type
            -- Look at recent metrics (last 15 minutes)
            AND nm.timestamp >= NOW() - INTERVAL '15 minutes'
            -- Apply threshold condition
            AND (
                (v_rule.threshold_type = 'upper' AND nm.value > v_rule.threshold_value) OR
                (v_rule.threshold_type = 'lower' AND nm.value < v_rule.threshold_value) OR
                (v_rule.threshold_type = 'equal' AND nm.value = v_rule.threshold_value) OR
                (v_rule.threshold_type = 'not_equal' AND nm.value != v_rule.threshold_value)
            )
            -- Avoid creating duplicate issues for the same device/interface/metric in a short time window
            AND NOT EXISTS (
                SELECT 1 
                FROM btrace_network.network_issues ni2
                WHERE ni2.device_id = nm.device_id
                  AND (ni2.interface_id = nm.interface_id OR (ni2.interface_id IS NULL AND nm.interface_id IS NULL))
                  AND ni2.title LIKE ('Anomaly: ' || v_rule.rule_name || '%')
                  AND ni2.start_time >= nm.timestamp - INTERVAL '30 minutes' -- Deduplication window
                  AND ni2.status IN ('open', 'investigating')
            );
            
        -- Get count of newly inserted issues
        GET DIAGNOSTICS v_issue_count = ROW_COUNT;
        
        -- Optional: Log or report on the number of issues found for this rule
        -- RAISE NOTICE 'Rule % detected % new anomalies', v_rule.rule_name, v_issue_count;
        
    END LOOP;
    
    -- Optional: Clean up old resolved issues (older than 30 days and resolved)
    -- This helps keep the issues table manageable
    DELETE FROM btrace_network.network_issues
    WHERE status IN ('resolved', 'closed')
      AND end_time < NOW() - INTERVAL '30 days';
      
    -- Optional: Log procedure completion
    -- RAISE NOTICE 'Network anomaly detection completed at %', NOW();

EXCEPTION
    WHEN OTHERS THEN
        -- Log error information
        RAISE NOTICE 'Error in detect_network_anomalies: %', SQLERRM;
        -- Re-raise the exception so it's not silently ignored
        RAISE;
END;
$$;

COMMENT ON PROCEDURE btrace_network.detect_network_anomalies() IS 'Analyzes recent network metrics against defined thresholds to identify potential issues';


-- BUSINESS CASE:
-- The `sync_network_inventory` procedure discovers and updates network
-- device inventory using configured discovery methods (SNMP, API, etc.),
-- maintaining an accurate network device database.
--
-- PURPOSE:
-- - Automate network discovery
-- - Maintain accurate inventory
-- - Detect unauthorized devices
-- - Support asset management

CREATE OR REPLACE PROCEDURE btrace_network.sync_network_inventory(
    p_discovery_method VARCHAR(20) DEFAULT 'snmp',
    p_scan_ranges TEXT[] DEFAULT ARRAY['192.168.1.0/24', '10.0.0.0/8'],
    p_environment_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_device RECORD;
    v_new_device_id UUID;
    v_interface_count INTEGER;
    v_updated_devices INTEGER := 0;
    v_new_devices INTEGER := 0;
BEGIN
    -- Log discovery start
    INSERT INTO btrace_audit.audit_logs (
        event_type,
        event_subtype,
        resource_type,
        action,
        action_status,
        details
    ) VALUES (
        'network',
        'discovery',
        'network_device',
        'scan',
        'started',
        jsonb_build_object(
            'method', p_discovery_method,
            'ranges', p_scan_ranges,
            'environment_id', p_environment_id
        )
    );
    
    -- In a real implementation, this would call external discovery tools
    -- For this example, we'll simulate discovering 2 devices
    
    -- Simulate discovering a Cisco switch
    SELECT device_id INTO v_device
    FROM btrace_network.network_devices
    WHERE ip_address = '192.168.1.1'::INET;
    
    IF NOT FOUND THEN
        -- New device
        INSERT INTO btrace_network.network_devices (
            hostname,
            ip_address,
            device_type,
            vendor,
            model,
            os_version,
            role,
            environment_id,
            is_critical,
            last_discovered_at,
            created_at
        ) VALUES (
            'switch1',
            '192.168.1.1',
            'switch',
            'Cisco',
            'Catalyst 9300',
            'IOS-XE 17.6.1',
            'access',
            COALESCE(p_environment_id, '00000000-0000-0000-0000-000000000101'), -- production
            TRUE,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        ) RETURNING device_id INTO v_new_device_id;
        
        -- Add interfaces
        INSERT INTO btrace_network.network_interfaces (
            device_id,
            name,
            speed_mbps,
            is_up,
            is_physical,
            created_at
        ) VALUES 
        (v_new_device_id, 'GigabitEthernet1/0/1', 1000, TRUE, TRUE, CURRENT_TIMESTAMP),
        (v_new_device_id, 'GigabitEthernet1/0/2', 1000, TRUE, TRUE, CURRENT_TIMESTAMP);
        
        v_new_devices := v_new_devices + 1;
    ELSE
        -- Update existing device
        UPDATE btrace_network.network_devices
        SET 
            last_discovered_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE device_id = v_device.device_id;
        
        v_updated_devices := v_updated_devices + 1;
    END IF;
    
    -- Simulate discovering a firewall
    SELECT device_id INTO v_device
    FROM btrace_network.network_devices
    WHERE ip_address = '192.168.1.254'::INET;
    
    IF NOT FOUND THEN
        -- New device
        INSERT INTO btrace_network.network_devices (
            hostname,
            ip_address,
            device_type,
            vendor,
            model,
            os_version,
            role,
            environment_id,
            is_critical,
            last_discovered_at,
            created_at
        ) VALUES (
            'firewall1',
            '192.168.1.254',
            'firewall',
            'Palo Alto',
            'PA-3220',
            'PAN-OS 10.1',
            'edge',
            COALESCE(p_environment_id, '00000000-0000-0000-0000-000000000101'), -- production
            TRUE,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        ) RETURNING device_id INTO v_new_device_id;
        
        -- Add interfaces
        INSERT INTO btrace_network.network_interfaces (
            device_id,
            name,
            speed_mbps,
            is_up,
            is_physical,
            created_at
        ) VALUES 
        (v_new_device_id, 'ethernet1/1', 10000, TRUE, TRUE, CURRENT_TIMESTAMP),
        (v_new_device_id, 'ethernet1/2', 10000, TRUE, TRUE, CURRENT_TIMESTAMP);
        
        v_new_devices := v_new_devices + 1;
    ELSE
        -- Update existing device
        UPDATE btrace_network.network_devices
        SET 
            last_discovered_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE device_id = v_device.device_id;
        
        v_updated_devices := v_updated_devices + 1;
    END IF;
    
    -- Log discovery completion
    INSERT INTO btrace_audit.audit_logs (
        event_type,
        event_subtype,
        resource_type,
        action,
        action_status,
        details
    ) VALUES (
        'network',
        'discovery',
        'network_device',
        'scan',
        'completed',
        jsonb_build_object(
            'new_devices', v_new_devices,
            'updated_devices', v_updated_devices,
            'total_devices', v_new_devices + v_updated_devices
        )
    );
    
    COMMIT;
END;
$$;
COMMENT ON PROCEDURE btrace_network.sync_network_inventory IS 'Discovers and updates network device inventory using configured methods';

-- BUSINESS CASE:
-- The `generate_network_topology` procedure analyzes network links and
-- devices to generate a comprehensive topology map, supporting
-- visualization and path analysis.
--
-- PURPOSE:
-- - Automate topology documentation
-- - Support network diagrams
-- - Enable path tracing
-- - Identify single points of failure

CREATE OR REPLACE PROCEDURE btrace_network.generate_network_topology(
    OUT p_topology_json JSONB,
    IN p_environment_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_device_count INTEGER;
    v_link_count INTEGER;
BEGIN
    -- Generate a JSON representation of the network topology
    SELECT jsonb_build_object(
        'version', '1.0',
        'generated_at', CURRENT_TIMESTAMP,
        'environment_id', p_environment_id,
        'environment_name', (SELECT environment_name FROM btrace_core.environments WHERE environment_id = p_environment_id),
        'devices', (
            SELECT jsonb_agg(jsonb_build_object(
                'device_id', d.device_id,
                'hostname', d.hostname,
                'ip_address', d.ip_address,
                'device_type', d.device_type,
                'role', d.role,
                'is_critical', d.is_critical,
                'interfaces', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'interface_id', i.interface_id,
                        'name', i.name,
                        'ip_address', i.ip_address,
                        'speed_mbps', i.speed_mbps,
                        'is_up', i.is_up
                    ))
                    FROM btrace_network.network_interfaces i
                    WHERE i.device_id = d.device_id
                )
            ))
            FROM btrace_network.network_devices d
            WHERE p_environment_id IS NULL OR d.environment_id = p_environment_id
        ),
        'links', (
            SELECT jsonb_agg(jsonb_build_object(
                'link_id', l.link_id,
                'source_device_id', l.source_device_id,
                'source_device', (SELECT hostname FROM btrace_network.network_devices WHERE device_id = l.source_device_id),
                'source_interface_id', l.source_interface_id,
                'source_interface', (SELECT name FROM btrace_network.network_interfaces WHERE interface_id = l.source_interface_id),
                'target_device_id', l.target_device_id,
                'target_device', (SELECT hostname FROM btrace_network.network_devices WHERE device_id = l.target_device_id),
                'target_interface_id', l.target_interface_id,
                'target_interface', (SELECT name FROM btrace_network.network_interfaces WHERE interface_id = l.target_interface_id),
                'link_type', l.link_type,
                'speed_mbps', l.speed_mbps,
                'is_primary', l.is_primary
            ))
            FROM btrace_network.network_links l
            WHERE p_environment_id IS NULL OR 
                  EXISTS (
                      SELECT 1 FROM btrace_network.network_devices d 
                      WHERE d.device_id IN (l.source_device_id, l.target_device_id)
                      AND d.environment_id = p_environment_id
                  )
        )
    ) INTO p_topology_json;
    
    -- Count devices and links for audit logging
    SELECT COUNT(*) INTO v_device_count
    FROM jsonb_array_elements(COALESCE(p_topology_json->'devices', '[]'::jsonb));
    
    SELECT COUNT(*) INTO v_link_count
    FROM jsonb_array_elements(COALESCE(p_topology_json->'links', '[]'::jsonb));
    
    -- Store the generated topology (in a real implementation, this might go to a visualization service)
    -- Note: Using btrace_core.audit_log based on schema references in other procedures
    INSERT INTO btrace_core.audit_log (
        event_type,
        event_subtype,
        resource_type,
        action,
        action_status,
        details,
        created_at
    ) VALUES (
        'network',
        'topology',
        'network',
        'generate',
        'completed',
        jsonb_build_object(
            'environment_id', p_environment_id,
            'device_count', v_device_count,
            'link_count', v_link_count
        ),
        NOW()
    );
    
    -- COMMIT is not needed as stored procedures in PostgreSQL don't control transactions implicitly
    -- The calling context manages the transaction
END;
$$;

COMMENT ON PROCEDURE btrace_network.generate_network_topology IS 'Generates a JSON representation of the network topology for visualization';
