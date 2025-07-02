-- =============================================
-- PostgreSQL Schema for Enterprise Risk Management with 11 Modules 
-- Version: 2.0
-- Copyright 2025 All rights reserved β ORI Inc.
-- Created: 2025-05-29
-- Last Updated: 2025-06-15
--Author: Awase Khirni Syed
-- Description: Comprehensive schema for Enterprise Risk Management 
--              with advanced features for data governance, analytics, and compliance
-- =============================================

-- Core PostgreSQL Schema for Enterprise Risk Management Platform


-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to update 'updated_at' columns automatically
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create core schema
CREATE SCHEMA IF NOT EXISTS core;

-- Set search path for core schema
SET search_path TO core, public;

-- Table: core.users
-- Description: Stores user information for authentication and authorization.
CREATE TABLE core.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE core.users IS 'Stores user information for authentication and authorization.';
COMMENT ON COLUMN core.users.user_id IS 'Unique identifier for the user.';
COMMENT ON COLUMN core.users.username IS 'Unique username for login.';
COMMENT ON COLUMN core.users.password_hash IS 'Hashed password for security.';
COMMENT ON COLUMN core.users.email IS 'Unique email address of the user.';
COMMENT ON COLUMN core.users.first_name IS 'First name of the user.';
COMMENT ON COLUMN core.users.last_name IS 'Last name of the user.';
COMMENT ON COLUMN core.users.is_active IS 'Indicates if the user account is active.';
COMMENT ON COLUMN core.users.last_login IS 'Timestamp of the user''s last login.';
COMMENT ON COLUMN core.users.created_at IS 'Timestamp when the user account was created.';
COMMENT ON COLUMN core.users.updated_at IS 'Timestamp when the user account was last updated.';

-- Trigger for core.users table
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON core.users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: core.roles
-- Description: Defines user roles within the system (e.g., Admin, Risk Manager, Auditor).
CREATE TABLE core.roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE core.roles IS 'Defines user roles within the system.';
COMMENT ON COLUMN core.roles.role_id IS 'Unique identifier for the role.';
COMMENT ON COLUMN core.roles.role_name IS 'Name of the role.';
COMMENT ON COLUMN core.roles.description IS 'Description of the role.';
COMMENT ON COLUMN core.roles.created_at IS 'Timestamp when the role was created.';
COMMENT ON COLUMN core.roles.updated_at IS 'Timestamp when the role was last updated.';

-- Trigger for core.roles table
CREATE TRIGGER update_roles_updated_at
BEFORE UPDATE ON core.roles
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: core.permissions
-- Description: Defines granular permissions for system actions and resources.
CREATE TABLE core.permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name VARCHAR(255) UNIQUE NOT NULL,
    module VARCHAR(255) NOT NULL, -- e.g., 'Risk Management', 'User Management'
    action VARCHAR(255) NOT NULL, -- e.g., 'read', 'write', 'delete', 'approve'
    resource VARCHAR(255) NOT NULL, -- e.g., 'risk_record', 'user_profile', 'policy'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (module, action, resource)
);

COMMENT ON TABLE core.permissions IS 'Defines granular permissions for system actions and resources.';
COMMENT ON COLUMN core.permissions.permission_id IS 'Unique identifier for the permission.';
COMMENT ON COLUMN core.permissions.permission_name IS 'Name of the permission.';
COMMENT ON COLUMN core.permissions.module IS 'The module the permission belongs to.';
COMMENT ON COLUMN core.permissions.action IS 'The action allowed by the permission.';
COMMENT ON COLUMN core.permissions.resource IS 'The resource the permission applies to.';
COMMENT ON COLUMN core.permissions.description IS 'Description of the permission.';
COMMENT ON COLUMN core.permissions.created_at IS 'Timestamp when the permission was created.';
COMMENT ON COLUMN core.permissions.updated_at IS 'Timestamp when the permission was last updated.';

-- Trigger for core.permissions table
CREATE TRIGGER update_permissions_updated_at
BEFORE UPDATE ON core.permissions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: core.user_roles
-- Description: Junction table for many-to-many relationship between users and roles.
CREATE TABLE core.user_roles (
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES core.roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

COMMENT ON TABLE core.user_roles IS 'Junction table for many-to-many relationship between users and roles.';
COMMENT ON COLUMN core.user_roles.user_id IS 'Foreign key referencing the user.';
COMMENT ON COLUMN core.user_roles.role_id IS 'Foreign key referencing the role.';
COMMENT ON COLUMN core.user_roles.assigned_at IS 'Timestamp when the role was assigned to the user.';

-- Table: core.role_permissions
-- Description: Junction table for many-to-many relationship between roles and permissions.
CREATE TABLE core.role_permissions (
    role_id UUID NOT NULL REFERENCES core.roles(role_id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES core.permissions(permission_id) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

COMMENT ON TABLE core.role_permissions IS 'Junction table for many-to-many relationship between roles and permissions.';
COMMENT ON COLUMN core.role_permissions.role_id IS 'Foreign key referencing the role.';
COMMENT ON COLUMN core.role_permissions.permission_id IS 'Foreign key referencing the permission.';
COMMENT ON COLUMN core.role_permissions.granted_at IS 'Timestamp when the permission was granted to the role.';

-- Table: core.audit_logs
-- Description: Comprehensive audit trail of all significant system activities and data changes (SOX2 compliant).
CREATE TABLE core.audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_type VARCHAR(255) NOT NULL, -- e.g., 'LOGIN', 'DATA_UPDATE', 'CONFIGURATION_CHANGE', 'ACCESS_DENIED'
    module VARCHAR(255), -- e.g., 'User Management', 'Risk Register', 'Policy Management'
    action VARCHAR(255) NOT NULL, -- e.g., 'create', 'read', 'update', 'delete', 'approve', 'reject'
    resource_type VARCHAR(255), -- e.g., 'user', 'risk_record', 'policy', 'report'
    resource_id UUID, -- ID of the affected resource
    old_value JSONB, -- Old state of the data (for updates/deletes)
    new_value JSONB, -- New state of the data (for creates/updates)
    ip_address INET,
    user_agent TEXT,
    details JSONB, -- Additional contextual details in JSON format
    is_sensitive BOOLEAN DEFAULT FALSE NOT NULL, -- Indicates if the log contains sensitive information
    CONSTRAINT chk_event_type_action_resource CHECK (event_type IS NOT NULL AND action IS NOT NULL)
);

COMMENT ON TABLE core.audit_logs IS 'Comprehensive audit trail of all significant system activities and data changes (SOX2 compliant).';
COMMENT ON COLUMN core.audit_logs.log_id IS 'Unique identifier for the audit log entry.';
COMMENT ON COLUMN core.audit_logs.user_id IS 'Foreign key referencing the user who performed the action.';
COMMENT ON COLUMN core.audit_logs.event_time IS 'Timestamp of the event.';
COMMENT ON COLUMN core.audit_logs.event_type IS 'High-level category of the event.';
COMMENT ON COLUMN core.audit_logs.module IS 'The system module where the event occurred.';
COMMENT ON COLUMN core.audit_logs.action IS 'The specific action performed.';
COMMENT ON COLUMN core.audit_logs.resource_type IS 'The type of resource affected by the action.';
COMMENT ON COLUMN core.audit_logs.resource_id IS 'The UUID of the resource affected.';
COMMENT ON COLUMN core.audit_logs.old_value IS 'JSON representation of the data before the change.';
COMMENT ON COLUMN core.audit_logs.new_value IS 'JSON representation of the data after the change.';
COMMENT ON COLUMN core.audit_logs.ip_address IS 'IP address from which the action originated.';
COMMENT ON COLUMN core.audit_logs.user_agent IS 'User agent string of the client.';
COMMENT ON COLUMN core.audit_logs.details IS 'Additional details about the event.';
COMMENT ON COLUMN core.audit_logs.is_sensitive IS 'Indicates if the log entry contains sensitive data.';

-- Stored Procedure: core.sp_create_user_with_role
-- Description: Creates a new user and assigns a specified role.
CREATE OR REPLACE PROCEDURE core.sp_create_user_with_role(
    p_username VARCHAR,
    p_password_hash VARCHAR,
    p_email VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_role_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
BEGIN
    -- Create the user
    INSERT INTO core.users (username, password_hash, email, first_name, last_name)
    VALUES (p_username, p_password_hash, p_email, p_first_name, p_last_name)
    RETURNING user_id INTO v_user_id;

    -- Get the role_id
    SELECT role_id INTO v_role_id FROM core.roles WHERE role_name = p_role_name;

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Role % not found.', p_role_name;
    END IF;

    -- Assign the role to the user
    INSERT INTO core.user_roles (user_id, role_id)
    VALUES (v_user_id, v_role_id);

    -- Log the action
    INSERT INTO core.audit_logs (user_id, event_type, module, action, resource_type, resource_id, details)
    VALUES (v_user_id, 'USER_MANAGEMENT', 'User Management', 'create_user_with_role', 'user', v_user_id, jsonb_build_object('username', p_username, 'role_name', p_role_name));

END;
$$;

COMMENT ON PROCEDURE core.sp_create_user_with_role(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) IS 'Creates a new user and assigns a specified role.';

-- Stored Procedure: core.sp_log_audit_event
-- Description: Inserts a new entry into the audit_logs table.
CREATE OR REPLACE PROCEDURE core.sp_log_audit_event(
    p_user_id UUID,
    p_event_type VARCHAR,
    p_module VARCHAR,
    p_action VARCHAR,
    p_resource_type VARCHAR,
    p_resource_id UUID DEFAULT NULL,
    p_old_value JSONB DEFAULT NULL,
    p_new_value JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_details JSONB DEFAULT NULL,
    p_is_sensitive BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO core.audit_logs (
        user_id, event_type, module, action, resource_type, resource_id,
        old_value, new_value, ip_address, user_agent, details, is_sensitive
    )
    VALUES (
        p_user_id, p_event_type, p_module, p_action, p_resource_type, p_resource_id,
        p_old_value, p_new_value, p_ip_address, p_user_agent, p_details, p_is_sensitive
    );
END;
$$;

COMMENT ON PROCEDURE core.sp_log_audit_event(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID, JSONB, JSONB, INET, TEXT, JSONB, BOOLEAN) IS 'Inserts a new entry into the audit_logs table.';

-- View: core.vw_active_users
-- Description: Provides a list of all active users in the system.
CREATE OR REPLACE VIEW core.vw_active_users AS
SELECT
    user_id,
    username,
    email,
    first_name,
    last_name,
    last_login,
    created_at
FROM
    core.users
WHERE
    is_active = TRUE;

COMMENT ON VIEW core.vw_active_users IS 'Provides a list of all active users in the system.';

-- View: core.vw_user_roles_permissions
-- Description: Shows a consolidated view of users, their assigned roles, and corresponding permissions.
CREATE OR REPLACE VIEW core.vw_user_roles_permissions AS
SELECT
    u.user_id,
    u.username,
    u.email,
    r.role_name,
    p.permission_name,
    p.module AS permission_module,
    p.action AS permission_action,
    p.resource AS permission_resource
FROM
    core.users u
JOIN
    core.user_roles ur ON u.user_id = ur.user_id
JOIN
    core.roles r ON ur.role_id = r.role_id
JOIN
    core.role_permissions rp ON r.role_id = rp.role_id
JOIN
    core.permissions p ON rp.permission_id = p.permission_id;

COMMENT ON VIEW core.vw_user_roles_permissions IS 'Shows a consolidated view of users, their assigned roles, and corresponding permissions.';

-- Materialized View: core.mv_daily_audit_summary
-- Description: Summarizes daily audit log activity for quick reporting.
CREATE MATERIALIZED VIEW core.mv_daily_audit_summary AS
SELECT
    DATE_TRUNC('day', event_time) AS audit_date,
    event_type,
    module,
    action,
    COUNT(*) AS event_count
FROM
    core.audit_logs
GROUP BY
    1, 2, 3, 4
ORDER BY
    audit_date DESC;

COMMENT ON MATERIALIZED VIEW core.mv_daily_audit_summary IS 'Summarizes daily audit log activity for quick reporting.';

-- SOX2 Compliance Note:
-- The `core.audit_logs` table and the `core.sp_log_audit_event` stored procedure are designed to capture comprehensive,
-- immutable records of all significant system activities, data modifications, and user actions.
-- This functionality is crucial for meeting SOX2 compliance requirements by providing a detailed audit trail
-- for financial reporting controls and internal control over financial reporting (ICFR).
-- All critical data manipulation and system configuration changes are intended to be logged via `core.sp_log_audit_event`.




-- ENHANCEMENTS FOR CORE SCHEMA

-- Table: core.notifications
-- Description: Stores system-wide notifications for users.
CREATE TABLE core.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES core.users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- e.g., info, warning, alert, task
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE core.notifications IS 'Stores system-wide notifications for users.';
COMMENT ON COLUMN core.notifications.notification_id IS 'Unique identifier for the notification.';
COMMENT ON COLUMN core.notifications.user_id IS 'Foreign key referencing the user to whom the notification is addressed. NULL for system-wide notifications.';
COMMENT ON COLUMN core.notifications.message IS 'The content of the notification.';
COMMENT ON COLUMN core.notifications.notification_type IS 'Type of notification (e.g., info, warning, alert, task).';
COMMENT ON COLUMN core.notifications.is_read IS 'Indicates if the notification has been read by the user.';
COMMENT ON COLUMN core.notifications.created_at IS 'Timestamp when the notification was created.';

-- View: core.vw_active_users
-- Description: Lists all currently active users.
CREATE OR REPLACE VIEW core.vw_active_users AS
SELECT
    user_id,
    username,
    email,
    first_name,
    last_name,
    last_login
FROM
    core.users
WHERE
    is_active = TRUE;

COMMENT ON VIEW core.vw_active_users IS 'Lists all currently active users.';

-- Stored Procedure: core.sp_log_user_activity
-- Description: Logs user login and logout activities.
CREATE OR REPLACE PROCEDURE core.sp_log_user_activity(
    p_user_id UUID,
    p_activity_type VARCHAR(50) -- e.g., LOGIN, LOGOUT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO core.audit_logs (
        user_id, event_type, module, action, resource_type, resource_id, ip_address, user_agent, details
    )
    VALUES (
        p_user_id,
        p_activity_type,
        'User Management',
        p_activity_type,
        'user',
        p_user_id,
        NULL, -- IP address can be captured from application layer
        NULL, -- User agent can be captured from application layer
        jsonb_build_object('activity_type', p_activity_type)
    );

    IF p_activity_type = 'LOGIN' THEN
        UPDATE core.users SET last_login = CURRENT_TIMESTAMP WHERE user_id = p_user_id;
    END IF;
END;
$$;

COMMENT ON PROCEDURE core.sp_log_user_activity(UUID, VARCHAR) IS 'Logs user login and logout activities.';




-- Business Continuity Management (BCM) Schema



-- Business Continuity Management (BCM) Schema



-- Create BCM schema
CREATE SCHEMA IF NOT EXISTS bcm;

-- Set search path for BCM schema
SET search_path TO bcm, public;

-- Table: bcm.bcm_plans
-- Description: Stores Business Continuity Plans.
CREATE TABLE bcm.bcm_plans (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Draft, Approved, Under Review, Active, Archived
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_due_at DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bcm_plans IS 'Stores Business Continuity Plans.';
COMMENT ON COLUMN bcm.bcm_plans.plan_id IS 'Unique identifier for the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.plan_name IS 'Name of the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.description IS 'Description of the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.version IS 'Version of the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.status IS 'Current status of the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.last_reviewed_at IS 'Timestamp of the last review of the plan.';
COMMENT ON COLUMN bcm.bcm_plans.next_review_due_at IS 'Date when the next review of the plan is due.';
COMMENT ON COLUMN bcm.bcm_plans.owner_user_id IS 'User responsible for the BCM plan.';
COMMENT ON COLUMN bcm.bcm_plans.created_at IS 'Timestamp when the BCM plan was created.';
COMMENT ON COLUMN bcm.bcm_plans.updated_at IS 'Timestamp when the BCM plan was last updated.';

-- Trigger for bcm.bcm_plans table
CREATE TRIGGER update_bcm_plans_updated_at
BEFORE UPDATE ON bcm.bcm_plans
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: bcm.bcm_exercises
-- Description: Records details of BCM exercises conducted.
CREATE TABLE bcm.bcm_exercises (
    exercise_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    exercise_type VARCHAR(100) NOT NULL, -- e.g., Tabletop, Simulation, Full-Scale
    exercise_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Planned, In Progress, Completed, Canceled
    results TEXT,
    lessons_learned TEXT,
    conducted_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bcm_exercises IS 'Records details of BCM exercises conducted.';
COMMENT ON COLUMN bcm.bcm_exercises.exercise_id IS 'Unique identifier for the BCM exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.plan_id IS 'Foreign key referencing the BCM plan tested.';
COMMENT ON COLUMN bcm.bcm_exercises.exercise_name IS 'Name of the BCM exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.exercise_type IS 'Type of BCM exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.exercise_date IS 'Date the exercise was conducted.';
COMMENT ON COLUMN bcm.bcm_exercises.status IS 'Current status of the exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.results IS 'Results and outcomes of the exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.lessons_learned IS 'Lessons learned from the exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.conducted_by IS 'User who conducted the exercise.';
COMMENT ON COLUMN bcm.bcm_exercises.created_at IS 'Timestamp when the exercise record was created.';
COMMENT ON COLUMN bcm.bcm_exercises.updated_at IS 'Timestamp when the exercise record was last updated.';

-- Trigger for bcm.bcm_exercises table
CREATE TRIGGER update_bcm_exercises_updated_at
BEFORE UPDATE ON bcm.bcm_exercises
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: bcm.bcm_incidents
-- Description: Records actual business disruption incidents.
CREATE TABLE bcm.bcm_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_name VARCHAR(255) NOT NULL,
    description TEXT,
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    impact_level VARCHAR(50), -- e.g., Minor, Moderate, Major, Catastrophic
    status VARCHAR(50) NOT NULL, -- e.g., Active, Resolved, Closed
    recovery_actions TEXT,
    lessons_learned TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bcm_incidents IS 'Records actual business disruption incidents.';
COMMENT ON COLUMN bcm.bcm_incidents.incident_id IS 'Unique identifier for the BCM incident.';
COMMENT ON COLUMN bcm.bcm_incidents.incident_name IS 'Name or title of the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.description IS 'Description of the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.incident_date IS 'Date and time the incident occurred.';
COMMENT ON COLUMN bcm.bcm_incidents.discovery_date IS 'Date and time the incident was discovered.';
COMMENT ON COLUMN bcm.bcm_incidents.impact_level IS 'Level of impact caused by the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.status IS 'Current status of the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.recovery_actions IS 'Actions taken to recover from the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.lessons_learned IS 'Lessons learned from the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.reported_by IS 'User who reported the incident.';
COMMENT ON COLUMN bcm.bcm_incidents.created_at IS 'Timestamp when the incident record was created.';
COMMENT ON COLUMN bcm.bcm_incidents.updated_at IS 'Timestamp when the incident record was last updated.';

-- Trigger for bcm.bcm_incidents table
CREATE TRIGGER update_bcm_incidents_updated_at
BEFORE UPDATE ON bcm.bcm_incidents
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: bcm.vw_bcm_plan_status
-- Description: Provides an overview of BCM plans and their current status.
CREATE OR REPLACE VIEW bcm.vw_bcm_plan_status AS
SELECT
    plan_id,
    plan_name,
    version,
    status,
    last_reviewed_at,
    next_review_due_at,
    u.username AS owner_username
FROM
    bcm.bcm_plans bp
LEFT JOIN
    core.users u ON bp.owner_user_id = u.user_id;

COMMENT ON VIEW bcm.vw_bcm_plan_status IS 'Provides an overview of BCM plans and their current status.';

-- View: bcm.vw_bcm_exercise_summary
-- Description: Summarizes BCM exercise results and lessons learned.
CREATE OR REPLACE VIEW bcm.vw_bcm_exercise_summary AS
SELECT
    be.exercise_id,
    be.exercise_name,
    be.exercise_type,
    be.exercise_date,
    be.status,
    bp.plan_name AS bcm_plan_name,
    be.results,
    be.lessons_learned,
    u.username AS conducted_by_username
FROM
    bcm.bcm_exercises be
JOIN
    bcm.bcm_plans bp ON be.plan_id = bp.plan_id
LEFT JOIN
    core.users u ON be.conducted_by = u.user_id;

COMMENT ON VIEW bcm.vw_bcm_exercise_summary IS 'Summarizes BCM exercise results and lessons learned.';

-- Stored Procedure: bcm.sp_update_bcm_plan_status
-- Description: Updates the status of a BCM plan.
CREATE OR REPLACE PROCEDURE bcm.sp_update_bcm_plan_status(
    p_plan_id UUID,
    p_new_status VARCHAR,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM bcm.bcm_plans WHERE plan_id = p_plan_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'BCM Plan ID % not found.', p_plan_id;
    END IF;

    UPDATE bcm.bcm_plans
    SET
        status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        plan_id = p_plan_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'BCM_MANAGEMENT',
        'Business Continuity Management',
        'update_plan_status',
        'bcm_plan',
        p_plan_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE bcm.sp_update_bcm_plan_status(UUID, VARCHAR, UUID) IS 'Updates the status of a BCM plan.';




-- ENHANCEMENTS FOR BUSINESS CONTINUITY MANAGEMENT SCHEMA

-- Table: bcm.recovery_strategies
-- Description: Details specific recovery strategies for business functions or systems.
CREATE TABLE bcm.recovery_strategies (
    strategy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    strategy_name VARCHAR(255) NOT NULL,
    description TEXT,
    recovery_time_objective INTERVAL, -- e.g., INTERVAL '4 hours'
    recovery_point_objective INTERVAL, -- e.g., INTERVAL '1 hour'
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.recovery_strategies IS 'Details specific recovery strategies for business functions or systems.';
COMMENT ON COLUMN bcm.recovery_strategies.strategy_id IS 'Unique identifier for the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.plan_id IS 'Foreign key referencing the associated BCM plan.';
COMMENT ON COLUMN bcm.recovery_strategies.strategy_name IS 'Name of the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.description IS 'Description of the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.recovery_time_objective IS 'Recovery Time Objective (RTO) for the strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.recovery_point_objective IS 'Recovery Point Objective (RPO) for the strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.owner_user_id IS 'User responsible for this recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.created_at IS 'Timestamp when the strategy record was created.';
COMMENT ON COLUMN bcm.recovery_strategies.updated_at IS 'Timestamp when the strategy record was last updated.';

-- Trigger for bcm.recovery_strategies table
CREATE TRIGGER update_recovery_strategies_updated_at
BEFORE UPDATE ON bcm.recovery_strategies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: bcm.vw_bcm_plan_status_overview
-- Description: Provides an overview of BCM plans and their current status, including last exercise date.
CREATE OR REPLACE VIEW bcm.vw_bcm_plan_status_overview AS
SELECT
    bp.plan_id,
    bp.plan_name,
    bp.description,
    bp.status,
    bp.last_exercise_date,
    bp.next_exercise_due_date,
    u.username AS owner_username,
    COUNT(rs.strategy_id) AS number_of_strategies
FROM
    bcm.bcm_plans bp
LEFT JOIN
    core.users u ON bp.owner_user_id = u.user_id
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.plan_id
GROUP BY
    bp.plan_id, bp.plan_name, bp.description, bp.status, bp.last_exercise_date, bp.next_exercise_due_date, u.username;

COMMENT ON VIEW bcm.vw_bcm_plan_status_overview IS 'Provides an overview of BCM plans and their current status, including last exercise date.';

-- Stored Procedure: bcm.sp_update_bcm_plan_status
-- Description: Updates the status and exercise dates of a BCM plan.
CREATE OR REPLACE PROCEDURE bcm.sp_update_bcm_plan_status(
    p_plan_id UUID,
    p_new_status VARCHAR,
    p_last_exercise_date DATE DEFAULT NULL,
    p_next_exercise_due_date DATE DEFAULT NULL,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM bcm.bcm_plans WHERE plan_id = p_plan_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'BCM Plan ID % not found.', p_plan_id;
    END IF;

    UPDATE bcm.bcm_plans
    SET
        status = p_new_status,
        last_exercise_date = COALESCE(p_last_exercise_date, last_exercise_date),
        next_exercise_due_date = COALESCE(p_next_exercise_due_date, next_exercise_due_date),
        updated_at = CURRENT_TIMESTAMP
    WHERE
        plan_id = p_plan_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'BUSINESS_CONTINUITY_MANAGEMENT',
        'Business Continuity Management',
        'update_bcm_plan_status',
        'bcm_plan',
        p_plan_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'last_exercise_date', p_last_exercise_date, 'next_exercise_due_date', p_next_exercise_due_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_update_bcm_plan_status(UUID, VARCHAR, DATE, DATE, UUID) IS 'Updates the status and exercise dates of a BCM plan.';

-- Materialized View: bcm.mv_critical_bcm_metrics
-- Description: Provides aggregated critical BCM metrics for quick reporting.
CREATE MATERIALIZED VIEW bcm.mv_critical_bcm_metrics AS
SELECT
    bp.status,
    COUNT(bp.plan_id) AS total_plans,
    COUNT(CASE WHEN bp.status = 'Active' THEN 1 END) AS active_plans,
    COUNT(CASE WHEN bp.next_exercise_due_date < CURRENT_DATE AND bp.status = 'Active' THEN 1 END) AS overdue_exercises,
    AVG(EXTRACT(EPOCH FROM rs.recovery_time_objective) / 3600) AS avg_rto_hours, -- Average RTO in hours
    AVG(EXTRACT(EPOCH FROM rs.recovery_point_objective) / 3600) AS avg_rpo_hours -- Average RPO in hours
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.plan_id
GROUP BY
    bp.status;

COMMENT ON MATERIALIZED VIEW bcm.mv_critical_bcm_metrics IS 'Provides aggregated critical BCM metrics for quick reporting.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE bcm.sp_refresh_mv_critical_bcm_metrics()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW bcm.mv_critical_bcm_metrics;
END;
$$;

COMMENT ON PROCEDURE bcm.sp_refresh_mv_critical_bcm_metrics() IS 'Refreshes the materialized view for critical BCM metrics.';


---to store structured BCPs including objectives, risk assessmetns, BIA, communication plan and IT continutity strategies
CREATE TABLE IF NOT EXISTS bcm.business_continuity_plans (
    bcp_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    objective TEXT NOT NULL,
    risk_assessment_summary TEXT,
    business_impact_analysis TEXT,
    communication_plan TEXT,
    it_systems_continuity TEXT,
    data_backup_strategy TEXT,
    cybersecurity_measures TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.business_continuity_plans IS 'Structured Business Continuity Plans (BCPs) outlining objectives, risk assessment, BIA, communication plan, IT systems continuity, data backup, and cybersecurity measures.';

--to define personnel involved in emergency response plannign and execution
CREATE TABLE IF NOT EXISTS bcm.recovery_teams (
    team_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_name VARCHAR(255) NOT NULL,
    description TEXT,
    department VARCHAR(100), -- e.g., IT, Operations, Legal, HR
    is_critical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.recovery_teams IS 'Personnel teams responsible for planning and executing emergency response activities.';


-- associates users with recovery teams
CREATE TABLE IF NOT EXISTS bcm.team_members (
    team_member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES bcm.recovery_teams(team_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    role_in_team VARCHAR(100), -- e.g., Lead, Member, Alternate
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.team_members IS 'Links users to specific recovery teams with defined roles.';

--records formal risk assesment tied to a BCP or plan
CREATE TABLE IF NOT EXISTS bcm.risk_assessments (
    risk_assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    threat_description TEXT NOT NULL,
    vulnerability_description TEXT,
    likelihood VARCHAR(50), -- e.g., Low, Medium, High, Critical
    impact_level VARCHAR(50), -- e.g., Minor, Moderate, Major, Catastrophic
    mitigation_strategy TEXT,
    assessed_by UUID REFERENCES core.users(user_id),
    assessment_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.risk_assessments IS 'Identifies vulnerabilities and potential threats, guiding planning and management.';


--captures impact analysis results used to prioritize recovery efforts
CREATE TABLE IF NOT EXISTS bcm.business_impact_analyses (
    bia_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    process_or_function VARCHAR(255) NOT NULL,
    rto INTERVAL, -- Recovery Time Objective
    rpo INTERVAL, -- Recovery Point Objective
    financial_impact DECIMAL(18,2),
    regulatory_impact TEXT,
    customer_impact TEXT,
    recovery_priority INT CHECK (recovery_priority BETWEEN 1 AND 5),
    analyzed_by UUID REFERENCES core.users(user_id),
    analysis_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.business_impact_analyses IS 'Calculates potential disaster impact on business functions, prioritizes recovery planning.';


--defines steps for handling different types of disasters
CREATE TABLE IF NOT EXISTS bcm.disaster_response_procedures (
    procedure_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    disaster_type VARCHAR(100) NOT NULL, -- e.g., Cyberattack, Natural Disaster, System Failure
    title VARCHAR(255) NOT NULL,
    description TEXT,
    steps TEXT[],
    required_teams UUID[], -- References team_ids
    it_recovery_steps TEXT,
    employee_evacuation BOOLEAN DEFAULT FALSE,
    alternate_site_activation BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.disaster_response_procedures IS 'Defines steps for specific disaster types to maintain continuity and eliminate confusion.';


--view to provide summary of BCPs linked to their associated BCM plans
CREATE OR REPLACE VIEW bcm.vw_bcp_overview AS
SELECT
    bcp.bcp_id,
    bp.plan_name,
    bcp.objective,
    COUNT(DISTINCT ra.risk_assessment_id) AS total_risk_assessments,
    COUNT(DISTINCT bia.bia_id) AS total_bia_entries,
    bcp.created_at,
    bcp.updated_at
FROM
    bcm.business_continuity_plans bcp
JOIN
    bcm.bcm_plans bp ON bcp.plan_id = bp.plan_id
LEFT JOIN
    bcm.risk_assessments ra ON bcp.bcp_id = ra.bcp_id
LEFT JOIN
    bcm.business_impact_analyses bia ON bcp.bcp_id = bia.bcp_id
GROUP BY
    bcp.bcp_id, bp.plan_name, bcp.objective, bcp.created_at, bcp.updated_at;

COMMENT ON VIEW bcm.vw_bcp_overview IS 'Provides an overview of Business Continuity Plans (BCPs) including associated risk assessments and impact analyses.';


--view lists detailed disaster response procedures with associated teams
CREATE OR REPLACE VIEW bcm.vw_disaster_procedure_details AS
SELECT
    dp.procedure_id,
    dp.disaster_type,
    dp.title,
    dp.description,
    dp.steps,
    array_agg(t.team_name) AS affected_teams,
    dp.it_recovery_steps,
    dp.employee_evacuation,
    dp.alternate_site_activation,
    u.username AS created_by_username
FROM
    bcm.disaster_response_procedures dp
LEFT JOIN
    unnest(dp.required_teams) AS team_id
    LEFT JOIN bcm.recovery_teams t ON t.team_id = team_id
LEFT JOIN
    core.users u ON dp.created_by = u.user_id
GROUP BY
    dp.procedure_id, dp.disaster_type, dp.title, dp.description, dp.steps, dp.it_recovery_steps,
    dp.employee_evacuation, dp.alternate_site_activation, u.username;

COMMENT ON VIEW bcm.vw_disaster_procedure_details IS 'Details disaster response procedures along with required teams and actions.';


--stored procedure to create a new business continuity plan (BCP)
CREATE OR REPLACE PROCEDURE bcm.sp_create_bcp(
    p_plan_id UUID,
    p_objective TEXT,
    p_risk_assessment_summary TEXT,
    p_business_impact_analysis TEXT,
    p_communication_plan TEXT,
    p_it_systems_continuity TEXT,
    p_data_backup_strategy TEXT,
    p_cybersecurity_measures TEXT,
    p_created_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_bcp_id UUID;
BEGIN
    INSERT INTO bcm.business_continuity_plans (
        plan_id, objective, risk_assessment_summary, business_impact_analysis,
        communication_plan, it_systems_continuity, data_backup_strategy,
        cybersecurity_measures
    ) VALUES (
        p_plan_id, p_objective, p_risk_assessment_summary, p_business_impact_analysis,
        p_communication_plan, p_it_systems_continuity, p_data_backup_strategy,
        p_cybersecurity_measures
    ) RETURNING bcp_id INTO v_bcp_id;

    CALL core.sp_log_audit_event(
        p_created_by_user_id,
        'BCM_MANAGEMENT',
        'Business Continuity',
        'create_bcp',
        'business_continuity_plan',
        v_bcp_id,
        NULL,
        jsonb_build_object('objective', p_objective),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_create_bcp(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID) IS 'Creates a new Business Continuity Plan (BCP).';


--stored procedure to add a new disaster response procedure
CREATE OR REPLACE PROCEDURE bcm.sp_record_disaster_response(
    p_disaster_type VARCHAR,
    p_title VARCHAR,
    p_description TEXT,
    p_steps TEXT[],
    p_required_teams UUID[],
    p_it_recovery_steps TEXT,
    p_employee_evacuation BOOLEAN,
    p_alternate_site_activation BOOLEAN,
    p_created_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_proc_id UUID;
BEGIN
    INSERT INTO bcm.disaster_response_procedures (
        disaster_type, title, description, steps, required_teams,
        it_recovery_steps, employee_evacuation, alternate_site_activation,
        created_by
    ) VALUES (
        p_disaster_type, p_title, p_description, p_steps, p_required_teams,
        p_it_recovery_steps, p_employee_evacuation, p_alternate_site_activation,
        p_created_by
    ) RETURNING procedure_id INTO v_proc_id;

    CALL core.sp_log_audit_event(
        p_created_by,
        'BCM_MANAGEMENT',
        'Disaster Response',
        'record_disaster_procedure',
        'disaster_response_procedure',
        v_proc_id,
        NULL,
        jsonb_build_object('title', p_title, 'disaster_type', p_disaster_type),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_record_disaster_response(VARCHAR, VARCHAR, TEXT, TEXT[], UUID[], TEXT, BOOLEAN, BOOLEAN, UUID) IS 'Records a new disaster response procedure.';


--Triggers for Automatic Timestamp updates
-- Trigger function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_bcp_updated_at
BEFORE UPDATE ON bcm.business_continuity_plans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_risk_assessments_updated_at
BEFORE UPDATE ON bcm.risk_assessments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_bia_updated_at
BEFORE UPDATE ON bcm.business_impact_analyses
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_disaster_procedures_updated_at
BEFORE UPDATE ON bcm.disaster_response_procedures
FOR EACH ROW EXECUTE FUNCTION update_timestamp();


-- BCM commmunication plan
CREATE TABLE IF NOT EXISTS bcm.communication_plans (
    comm_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    internal_communication TEXT,
    external_communication TEXT,
    escalation_procedures TEXT[],
    contact_list JSONB, -- { "executive": "john@example.com", "it": ["jane@...", ...] }
    media_response_template TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.communication_plans IS 'Ensures timely and effective communication during a crisis.';


--view -- bcm communication overview
CREATE OR REPLACE VIEW bcm.vw_bcm_communication_overview AS
SELECT
    cp.comm_plan_id,
    bcp.bcp_id,
    bp.plan_name,
    array_length(cp.contact_list->'internal', 1) AS internal_contacts_count,
    array_length(cp.contact_list->'external', 1) AS external_contacts_count,
    CASE WHEN cp.media_response_template IS NOT NULL THEN TRUE ELSE FALSE END AS has_media_template
FROM bcm.communication_plans cp
JOIN bcm.business_continuity_plans bcp ON cp.bcp_id = bcp.bcp_id
JOIN bcm.bcm_plans bp ON bcp.plan_id = bp.plan_id;

COMMENT ON VIEW bcm.vw_bcm_communication_overview IS 'Provides an overview of BCM communication plans linked to BCPs.';

--testing and exercises
CREATE TABLE IF NOT EXISTS bcm.exercise_types (
    exercise_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

INSERT INTO bcm.exercise_types (type_name, description)
VALUES
('Tabletop Exercise', 'Discussion-based review of response procedures'),
('Simulation', 'IT system or process simulation under stress'),
('Full-Scale Drill', 'Real-time activation of BCM plan'),
('Functional Test', 'Test of specific BCM components');

COMMENT ON TABLE bcm.exercise_types IS 'Enumerates types of BCM exercises for structured testing.';


ALTER TABLE bcm.bcm_exercises ADD COLUMN exercise_type_id INT REFERENCES bcm.exercise_types(exercise_type_id);
ALTER TABLE bcm.bcm_exercises ADD COLUMN effectiveness_rating VARCHAR(50); -- e.g., Effective, Partially Effective, Ineffective
ALTER TABLE bcm.bcm_exercises ADD COLUMN participants JSONB;

--BCM training programs for training and awareness
CREATE TABLE IF NOT EXISTS bcm.training_programs (
    training_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration INTERVAL,
    delivery_method VARCHAR(100), -- e.g., Online, Classroom, Workshop
    mandatory BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.training_programs IS 'Educates personnel on BCM plans and procedures.';


---bcm user training records
CREATE TABLE IF NOT EXISTS bcm.user_training_records (
    record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    training_id UUID NOT NULL REFERENCES bcm.training_programs(training_id) ON DELETE CASCADE,
    completion_date DATE,
    score NUMERIC(5,2),
    status VARCHAR(50) DEFAULT 'Pending', -- Pending, Completed, Failed
    certificate_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.user_training_records IS 'Tracks individual BCM training completions.';

--bcm improvement actions
CREATE TABLE IF NOT EXISTS bcm.improvement_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    owner_user_id UUID REFERENCES core.users(user_id),
    due_date DATE,
    status VARCHAR(50) DEFAULT 'Open', -- Open, In Progress, Closed
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.improvement_actions IS 'Regular review and updates of BCM plans.';

--for operational resillience metrics
CREATE TABLE IF NOT EXISTS bcm.resilience_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    metric_name VARCHAR(255) NOT NULL,
    target_value TEXT,
    actual_value TEXT,
    last_assessed DATE,
    assessment_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.resilience_metrics IS 'Focuses on mitigating risk and impact of disruptions to support ongoing operations.';

-- structured framework to company-wide practices
CREATE TABLE IF NOT EXISTS bcm.framework_elements (
    element_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    applies_to VARCHAR(100), -- e.g., Policy, Practice, Process
    required BOOLEAN DEFAULT FALSE
);

INSERT INTO bcm.framework_elements (name, description, applies_to, required)
VALUES
('BCM Policy', 'Formal policy supporting BCM framework', 'Policy', TRUE),
('BCM Committee', 'Governance committee overseeing BCM', 'Practice', TRUE),
('BCM Lifecycle', 'Integrated into company-wide planning', 'Process', TRUE),
('Recovery Time Objective (RTO)', 'Time within which systems must recover', 'Metric', TRUE),
('Recovery Point Objective (RPO)', 'Data loss tolerance level', 'Metric', TRUE);

COMMENT ON TABLE bcm.framework_elements IS 'Supports BCM with defined policies, practices, and systems.';

--recovery strategy
ALTER TABLE bcm.recovery_strategies ADD COLUMN lifecycle_stage VARCHAR(50); -- Preparation, Planning, Implementation, Adaptation



--stored procedures
CREATE OR REPLACE PROCEDURE bcm.sp_record_bcm_exercise_result(
    p_exercise_id UUID,
    p_effectiveness_rating VARCHAR,
    p_participants JSONB,
    p_lessons_learned TEXT,
    p_updated_by UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bcm.bcm_exercises
    SET
        effectiveness_rating = p_effectiveness_rating,
        participants = p_participants,
        lessons_learned = p_lessons_learned
    WHERE exercise_id = p_exercise_id;

    CALL core.sp_log_audit_event(
        p_updated_by,
        'BCM_MANAGEMENT',
        'Exercise Evaluation',
        'record_exercise_result',
        'bcm_exercise',
        p_exercise_id,
        NULL,
        jsonb_build_object('effectiveness_rating', p_effectiveness_rating),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_record_bcm_exercise_result(UUID, VARCHAR, JSONB, TEXT, UUID) IS 'Records results of BCM exercises and evaluates effectiveness.';


--stored procedure to assign training to a user
CREATE OR REPLACE PROCEDURE bcm.sp_assign_training_to_user(
    p_user_id UUID,
    p_training_id UUID,
    p_assigned_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE v_status VARCHAR;
BEGIN
    INSERT INTO bcm.user_training_records (user_id, training_id)
    VALUES (p_user_id, p_training_id)
    RETURNING status INTO v_status;

    CALL core.sp_log_audit_event(
        p_assigned_by,
        'BCM_TRAINING',
        'User Training Assignment',
        'assign_training',
        'user_training_record',
        gen_random_uuid(),
        NULL,
        jsonb_build_object('user_id', p_user_id, 'training_id', p_training_id),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_assign_training_to_user(UUID, UUID, UUID) IS 'Assigns BCM training to users.';


--triggers for timestamp updates
CREATE TRIGGER update_communication_plans_updated_at
BEFORE UPDATE ON bcm.communication_plans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_improvement_actions_updated_at
BEFORE UPDATE ON bcm.improvement_actions
FOR EACH ROW EXECUTE FUNCTION update_timestamp();


-- executive support commitments
CREATE TABLE IF NOT EXISTS bcm.executive_commitments (
    commitment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    executive_user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    statement TEXT NOT NULL,
    signed_date DATE NOT NULL,
    review_due_date DATE,
    status VARCHAR(50) DEFAULT 'Active', -- Active, Expired, Renewed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.executive_commitments IS 'Secures leadership commitment and resources.';

--Risk identification
CREATE TABLE IF NOT EXISTS bcm.risk_mapping (
    risk_map_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    internal_risks TEXT[],
    external_risks TEXT[],
    mapped_by UUID REFERENCES core.users(user_id),
    mapping_date DATE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.risk_mapping IS 'Maps internal and external risks associated with BCM plans.';

--resource allocaiton
CREATE TABLE IF NOT EXISTS bcm.resource_requirements (
    requirement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    resource_type VARCHAR(100), -- e.g., Personnel, Equipment, Facility
    description TEXT,
    quantity INT,
    priority_level INT CHECK (priority_level BETWEEN 1 AND 5),
    allocated BOOLEAN DEFAULT FALSE,
    allocated_to_team UUID REFERENCES bcm.recovery_teams(team_id),
    requested_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.resource_requirements IS 'Ensures necessary resources are available for BCM initiatives.';

--funding
CREATE TABLE IF NOT EXISTS bcm.funding_sources (
    funding_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    source_name VARCHAR(255) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    approved_by UUID REFERENCES core.users(user_id),
    approval_date DATE,
    validity_period DATERANGE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.funding_sources IS 'Secures financial support for BCM initiatives.';


--authority  and autorization levels
CREATE TABLE IF NOT EXISTS bcm.authorization_levels (
    auth_level_id SERIAL PRIMARY KEY,
    level_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB -- Example: { "can_activate_plan": true, "can_assign_teams": true }
);

INSERT INTO bcm.authorization_levels (level_name, description)
VALUES
('Plan Owner', 'Full control over BCM plan lifecycle'),
('Team Lead', 'Can execute recovery procedures'),
('Reviewer', 'Can view and comment on plans');

COMMENT ON TABLE bcm.authorization_levels IS 'Grants necessary authority for BCM implementation.';


--bcm user authorizations
CREATE TABLE IF NOT EXISTS bcm.user_authorizations (
    user_auth_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    auth_level_id INT NOT NULL REFERENCES bcm.authorization_levels(auth_level_id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    granted_by UUID REFERENCES core.users(user_id),
    grant_date DATE NOT NULL,
    expires_at DATE,
    status VARCHAR(50) DEFAULT 'Active' -- Active, Expired, Revoked
);

COMMENT ON TABLE bcm.user_authorizations IS 'Tracks assigned authority levels for users in BCM plans.';

--holistic management process
-- to present a  view summarizing all BCM components
CREATE OR REPLACE VIEW bcm.vw_bcm_holistic_summary AS
SELECT
    bp.plan_id,
    bp.plan_name,
    COUNT(DISTINCT rs.strategy_id) AS recovery_strategies_count,
    COUNT(DISTINCT rmp.team_id) AS teams_involved_count,
    COUNT(DISTINCT fr.resource_requirement_id) AS resource_requirements_count,
    SUM(fr.quantity) AS total_resources_required,
    COUNT(DISTINCT fu.funding_id) AS funding_sources_count,
    SUM(fu.amount) AS total_funding_secured,
    COUNT(DISTINCT ec.commitment_id) AS executive_commitments_count
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.plan_id
LEFT JOIN
    bcm.recovery_team_memberships rmp ON bp.plan_id = rmp.plan_id
LEFT JOIN
    bcm.resource_requirements fr ON bp.plan_id = fr.bcp_id
LEFT JOIN
    bcm.funding_sources fu ON bp.plan_id = fu.plan_id
LEFT JOIN
    bcm.executive_commitments ec ON bp.plan_id = ec.plan_id
GROUP BY
    bp.plan_id, bp.plan_name;

COMMENT ON VIEW bcm.vw_bcm_holistic_summary IS 'Provides a holistic overview of BCM processes and integration points.';

---organizational reilience framework to capture through strucutured elements across multiple tables.

CREATE TABLE IF NOT EXISTS bcm.resilience_framework_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    framework_name VARCHAR(255) NOT NULL,
    version VARCHAR(50),
    standard VARCHAR(100), -- e.g., ISO 22301, NIST
    scope TEXT,
    key_components JSONB, -- List of required BCM elements
    active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.resilience_framework_config IS 'Provides a structure for building organizational resilience.';

--effective response capability
ALTER TABLE bcm.bcm_exercises ADD COLUMN effectiveness_rating VARCHAR(50); -- e.g., Effective, Partially Effective, Ineffective

--stakeholder reputation, brand protection - to consolidate these into a stakeholder protection table
CREATE TABLE IF NOT EXISTS bcm.stakeholder_protection (
    stakeholder_protection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    stakeholder_group VARCHAR(255), -- e.g., Customers, Employees, Regulators
    protection_strategy TEXT,
    communication_plan TEXT,
    impact_mitigation TEXT,
    brand_impact_avoidance TEXT,
    value_creation_preservation TEXT,
    reviewed_by UUID REFERENCES core.users(user_id),
    review_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.stakeholder_protection IS 'Safeguards interests of stakeholders, protects reputation and brand value, and ensures value-creating activities continue.';


--value creating activirews protection
CREATE TABLE IF NOT EXISTS bcm.value_creating_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    activity_name VARCHAR(255) NOT NULL,
    description TEXT,
    criticality_level INT CHECK (criticality_level BETWEEN 1 AND 5),
    recovery_priority INT CHECK (recovery_priority BETWEEN 1 AND 5),
    rto INTERVAL,
    rpo INTERVAL,
    owner_user_id UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.value_creating_activities IS 'Ensures continuity of activities that generate value.';

--integration of emergency response, crisis management, disaster recovery and bsuiness continutity
-- a consolidated view and possibly integrate with an external system later
CREATE OR REPLACE VIEW bcm.vw_bcm_discipline_integration AS
SELECT
    bp.plan_id,
    bp.plan_name,
    COUNT(DISTINCT dp.procedure_id) AS disaster_procedures_count,
    COUNT(DISTINCT cr.crisis_response_id) AS crisis_responses_count,
    COUNT(DISTINCT rs.strategy_id) AS recovery_strategies_count,
    COUNT(DISTINCT cp.comm_plan_id) AS communication_plans_count
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.disaster_response_procedures dp ON bp.plan_id = dp.plan_id
LEFT JOIN
    bcm.crisis_management cr ON bp.plan_id = cr.plan_id
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.plan_id
LEFT JOIN
    bcm.communication_plans cp ON bp.plan_id = cp.bcp_id
GROUP BY
    bp.plan_id, bp.plan_name;

COMMENT ON VIEW bcm.vw_bcm_discipline_integration IS 'Integrates emergency response, crisis management, disaster recovery, and business continuity.';

--stored procedures for granting user authorization
CREATE OR REPLACE PROCEDURE bcm.sp_grant_user_authorization(
    p_user_id UUID,
    p_auth_level_id INT,
    p_plan_id UUID,
    p_granted_by UUID,
    p_expires_at DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO bcm.user_authorizations (
        user_id, auth_level_id, plan_id, granted_by, grant_date, expires_at
    ) VALUES (
        p_user_id, p_auth_level_id, p_plan_id, p_granted_by, CURRENT_DATE, p_expires_at
    );

    CALL core.sp_log_audit_event(
        p_granted_by,
        'BCM_AUTHORIZATION',
        'User Authorization',
        'grant_authorization',
        'user_authorization',
        gen_random_uuid(),
        NULL,
        jsonb_build_object('user_id', p_user_id, 'auth_level_id', p_auth_level_id),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_grant_user_authorization(UUID, INT, UUID, UUID, DATE) IS 'Grants user authorization for BCM plan execution.';

---triggers for timestamp updates
CREATE TRIGGER update_executive_commitments_updated_at
BEFORE UPDATE ON bcm.executive_commitments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_resource_requirements_updated_at
BEFORE UPDATE ON bcm.resource_requirements
FOR EACH ROW EXECUTE FUNCTION update_timestamp();


--BCM software types
CREATE TABLE IF NOT EXISTS bcm.bcm_software_types (
    software_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_core BOOLEAN DEFAULT FALSE -- Whether it's part of core BCM suite
);

INSERT INTO bcm.bcm_software_types (type_name, description, is_core)
VALUES
('BCM Core Platform', 'Centralized system for all BCM activities', TRUE),
('Risk Assessment Module', 'Tools for identifying and managing risks', TRUE),
('Recovery Planning Module', 'Supports creation and execution of recovery strategies', TRUE),
('Crisis Management Module', 'Manages crisis events and communication', TRUE),
('IT Disaster Recovery Module', 'Focuses on IT-specific disaster recovery plans', TRUE),
('Vendor Risk Module', 'Tracks and manages third-party vendor risks', TRUE),
('Integrated Risk Management Module', 'Unified view of all risk-related activities', TRUE),
('Action Management Module', 'Tracks and manages recovery actions', TRUE),
('Analytics Dashboard Module', 'Provides performance insights and metrics', TRUE),
('Mobile Access Module', 'Mobile application for BCM plan access', TRUE);


CREATE TABLE IF NOT EXISTS bcm.bcm_software_instances (
    software_instance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    software_type_id INT NOT NULL REFERENCES bcm.bcm_software_types(software_type_id),
    instance_name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'Active', -- Active, Inactive, Under Maintenance
    configured_for_plan UUID REFERENCES bcm.bcm_plans(plan_id),
    installed_by UUID REFERENCES core.users(user_id),
    install_date DATE DEFAULT CURRENT_DATE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bcm_software_instances IS 'Represents instances of BCM software deployed in the organization.';


--BCM action management software system to manage tasks
CREATE TABLE IF NOT EXISTS bcm.action_management_tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES core.users(user_id),
    assigned_by UUID REFERENCES core.users(user_id),
    due_date DATE,
    priority_level INT CHECK (priority_level BETWEEN 1 AND 5),
    status VARCHAR(50) DEFAULT 'Pending', -- Pending, In Progress, Completed, Overdue
    related_plan_id UUID REFERENCES bcm.bcm_plans(plan_id),
    related_incident_id UUID REFERENCES bcm.bcm_incidents(incident_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.action_management_tasks IS 'Tracks and manages recovery and improvement actions.';

--to catpure real-time status updates
CREATE TABLE IF NOT EXISTS bcm.real_time_status_updates (
    update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id),
    message TEXT NOT NULL,
    sent_by UUID REFERENCES core.users(user_id),
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_broadcast BOOLEAN DEFAULT FALSE,
    recipients JSONB -- { "users": [uuid1, uuid2], "teams": [uuid3] }
);

COMMENT ON TABLE bcm.real_time_status_updates IS 'Provides live updates on BCM status during incidents.';

--business continutity emergency alerts
CREATE TABLE IF NOT EXISTS bcm.emergency_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    triggered_by UUID REFERENCES core.users(user_id),
    trigger_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    alert_type VARCHAR(100), -- e.g., System Failure, Cyberattack, Natural Disaster
    affected_plans UUID[], -- List of affected plan IDs
    escalation_level INT DEFAULT 1,
    acknowledged_by UUID[],
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE bcm.emergency_alerts IS 'Automated alerts triggered during emergencies.';


--analytics and dashboards
-- materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS bcm.mv_bcm_dashboard_summary AS
SELECT
    bp.status AS plan_status,
    COUNT(bp.plan_id) AS total_plans,
    COUNT(CASE WHEN be.exercise_date > CURRENT_DATE - INTERVAL '1 year' THEN 1 END) AS tested_last_year,
    COUNT(DISTINCT bi.incident_id) AS total_incidents,
    AVG(EXTRACT(EPOCH FROM rs.recovery_time_objective)/3600) AS avg_rto_hours,
    AVG(EXTRACT(EPOCH FROM rs.recovery_point_objective)/3600) AS avg_rpo_hours
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.bcm_exercises be ON bp.plan_id = be.plan_id
LEFT JOIN
    bcm.bcm_incidents bi ON bp.plan_id = bi.plan_id
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.plan_id
GROUP BY
    bp.status;

COMMENT ON MATERIALIZED VIEW bcm.mv_bcm_dashboard_summary IS 'Provides key BCM metrics for dashboards.';

--refresh dashboard
CREATE OR REPLACE PROCEDURE bcm.sp_refresh_bcm_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW bcm.mv_bcm_dashboard_summary;
END;
$$;

COMMENT ON PROCEDURE bcm.sp_refresh_bcm_dashboard() IS 'Refreshes BCM dashboard materialized view.';

--mobile app acess
CREATE TABLE IF NOT EXISTS bcm.mobile_app_access_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(user_id),
    device_id VARCHAR(255) NOT NULL,
    token_value TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.mobile_app_access_tokens IS 'Stores tokens for mobile app authentication and access.';


-- custom BCM plan templates
CREATE TABLE IF NOT EXISTS bcm.plan_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- e.g., IT, HR, Finance
    content JSONB NOT NULL,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.plan_templates IS 'Provides customizable templates for various BCM scenarios.';


---internal audit management
CREATE TABLE IF NOT EXISTS bcm.bcm_audit_records (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id),
    auditor_user_id UUID NOT NULL REFERENCES core.users(user_id),
    audit_date DATE NOT NULL,
    findings TEXT,
    recommendations TEXT,
    compliance_status VARCHAR(50), -- Compliant, Non-Compliant, Partially Compliant
    reviewed_by UUID REFERENCES core.users(user_id),
    review_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bcm_audit_records IS 'Records internal audits related to BCM plans.';


--regulatory compliance tracking
CREATE TABLE IF NOT EXISTS bcm.regulatory_compliance (
    compliance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    standard_name VARCHAR(100) NOT NULL, -- e.g., ISO 22301, NIST SP 800-34
    requirement TEXT NOT NULL,
    plan_id UUID REFERENCES bcm.bcm_plans(plan_id),
    implementation_status VARCHAR(50) DEFAULT 'Not Started', -- Not Started, In Progress, Completed
    evidence TEXT,
    last_reviewed DATE,
    next_review_due DATE,
    responsible_user_id UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.regulatory_compliance IS 'Tracks compliance with regulatory requirements such as ISO 22301.';


--automated workflows definitions
CREATE TABLE IF NOT EXISTS bcm.workflow_definitions (
    workflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    trigger_event VARCHAR(100), -- e.g., Incident Reported, Exercise Due
    steps JSONB NOT NULL, -- Contains ordered list of steps with roles and conditions
    enabled BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.workflow_definitions IS 'Defines automated workflows for BCM processes.';

--incident trackign
ALTER TABLE bcm.bcm_incidents ADD COLUMN severity_level INT CHECK (severity_level BETWEEN 1 AND 5);


--reporting capabiities
CREATE OR REPLACE VIEW bcm.vw_bcm_incident_report AS
SELECT
    i.incident_id,
    i.incident_name,
    i.description,
    i.incident_date,
    i.discovery_date,
    i.severity_level,
    i.status,
    p.plan_name,
    u.username AS reported_by,
    i.created_at
FROM
    bcm.bcm_incidents i
LEFT JOIN
    bcm.bcm_plans p ON i.plan_id = p.plan_id
LEFT JOIN
    core.users u ON i.reported_by = u.user_id;

COMMENT ON VIEW bcm.vw_bcm_incident_report IS 'Provides structured reporting data for BCM incidents.';

--critical operation identification
CREATE TABLE IF NOT EXISTS bcm.critical_operations (
    operation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id),
    operation_name VARCHAR(255) NOT NULL,
    description TEXT,
    rto INTERVAL,
    rpo INTERVAL,
    owner_user_id UUID REFERENCES core.users(user_id),
    criticality_level INT CHECK (criticality_level BETWEEN 1 AND 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.critical_operations IS 'Identifies essential business operations for continuity.';

--triggers for automatic updates
CREATE TRIGGER update_action_management_tasks_updated_at
BEFORE UPDATE ON bcm.action_management_tasks
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_real_time_status_updates_updated_at
BEFORE UPDATE ON bcm.real_time_status_updates
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Repeat for other new tables as needed

--altering risk assessments to add risk category
ALTER TABLE bcm.risk_assessments ADD COLUMN risk_category VARCHAR(100); -- e.g., Cyber, Operational, Legal


-- adding bcm risk assessment matrix
CREATE TABLE IF NOT EXISTS bcm.risk_matrix (
    matrix_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_id UUID NOT NULL REFERENCES operational_risk.operational_risks(risk_id),
    likelihood_level INT CHECK (likelihood_level BETWEEN 1 AND 5),
    impact_level INT CHECK (impact_level BETWEEN 1 AND 5),
    calculated_priority TEXT, -- e.g., High, Medium, Low
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.risk_matrix IS 'Tool to visualize and prioritize risks based on likelihood and impact.';

-- business impact analysis (BIA) for assessing the financial impact
CREATE TABLE IF NOT EXISTS bcm.bia_financial_impact (
    bia_finance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    revenue_loss_per_hour DECIMAL(18,2),
    estimated_downtime_hours INT,
    total_revenue_loss DECIMAL(18,2),
    mitigation_cost DECIMAL(18,2),
    updated_by UUID REFERENCES core.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bia_financial_impact IS 'Quantifies revenue loss during downtime.';

-- business impact analysis (BIA) for assessing operational impact
CREATE TABLE IF NOT EXISTS bcm.bia_operational_impact (
    bia_ops_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    employee_impact TEXT,
    production_impact TEXT,
    service_level_impact TEXT,
    updated_by UUID REFERENCES core.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bia_operational_impact IS 'Assesses effects on employees, production, and service levels.';

-- BIA for legal and compliance risks
CREATE TABLE IF NOT EXISTS bcm.bia_compliance_impact (
    bia_compliance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcp_id UUID NOT NULL REFERENCES bcm.business_continuity_plans(bcp_id) ON DELETE CASCADE,
    regulation_name VARCHAR(255),
    potential_penalties TEXT,
    reporting_obligations TEXT,
    updated_by UUID REFERENCES core.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.bia_compliance_impact IS 'Identifies regulatory consequences of operational stops.';


-- view for summarizing business impact analysis results
CREATE OR REPLACE VIEW bcm.vw_bcm_bia_summary AS
SELECT
    bcp.bcp_id,
    bp.plan_name,
    COALESCE(finance.total_revenue_loss, 0) AS estimated_revenue_loss,
    ops.employee_impact,
    comp.penalties AS potential_penalties,
    CASE WHEN finance.total_revenue_loss > 100000 THEN 'High' ELSE 'Medium' END AS financial_impact_rating
FROM
    bcm.business_continuity_plans bcp
JOIN
    bcm.bcm_plans bp ON bcp.plan_id = bp.plan_id
LEFT JOIN
    bcm.bia_financial_impact finance ON bcp.bcp_id = finance.bcp_id
LEFT JOIN
    bcm.bia_operational_impact ops ON bcp.bcp_id = ops.bcp_id
LEFT JOIN
    bcm.bia_compliance_impact comp ON bcp.bcp_id = comp.bcp_id;

COMMENT ON VIEW bcm.vw_bcm_bia_summary IS 'Analyzes the potential impact of threats on day-to-day operations.';

-- to minimize recovery down time
ALTER TABLE bcm.recovery_strategies ADD COLUMN minimize_downtime BOOLEAN DEFAULT TRUE;

-- to assess and record financial impact revenue
ALTER TABLE bcm.bia_financial_impact ADD COLUMN revenue_protection_strategy TEXT;

-- to maintain customer trust
ALTER TABLE bcm.communication_plans ADD COLUMN customer_communication_strategy TEXT;


-- to define contingency plans
CREATE TABLE IF NOT EXISTS bcm.contingency_plans (
    contingency_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    scenario VARCHAR(255) NOT NULL,
    alternative_supplier TEXT,
    flexible_work_setup TEXT,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.contingency_plans IS 'Alternative strategies for various scenarios like backup suppliers and flexible work setups.';

-- for workforce shortage plannign
CREATE TABLE IF NOT EXISTS bcm.workforce_shortage_plans (
    shortage_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    staffing_gap_description TEXT,
    cross_training_available BOOLEAN DEFAULT FALSE,
    remote_work_capacity TEXT,
    temporary_staffing_options TEXT,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.workforce_shortage_plans IS 'Addresses potential lack of personnel during crises.';

--supply chain disruption planning
CREATE TABLE IF NOT EXISTS bcm.supply_chain_disruption_plans (
    disruption_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    risk_description TEXT,
    alternate_suppliers JSONB,
    inventory_buffer_days INT,
    logistics_contingency TEXT,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.supply_chain_disruption_plans IS 'Strategies for managing interruptions in the supply chain.';

--alternative access methods
ALTER TABLE bcm.recovery_strategies ADD COLUMN alternative_access_methods TEXT[];


-- workarounds for key digital processes
ALTER TABLE bcm.recovery_strategies ADD COLUMN digital_process_workarounds TEXT[];

--disaster recovery planning
ALTER TABLE bcm.recovery_strategies ADD COLUMN digital_process_workarounds TEXT[];

--economic downturn plans
CREATE TABLE IF NOT EXISTS bcm.economic_downturn_plans (
    downturn_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    strategy_description TEXT,
    cost_reduction_actions TEXT[],
    revenue_preservation_methods TEXT[],
    stakeholder_communication_plan TEXT,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.economic_downturn_plans IS 'Strategies for managing financial crises and industry changes.';


-- best or good practice guidleiens (GPG adeherence)
ALTER TABLE bcm.business_continuity_plans ADD COLUMN gpg_adherence_notes TEXT;


-- to create a view for bcm governance summary
CREATE OR REPLACE VIEW bcm.vw_bcm_governance_summary AS
SELECT
    p.plan_id,
    p.plan_name,
    COUNT(DISTINCT r.risk_id) AS total_risks_mapped,
    COUNT(DISTINCT c.compliance_id) AS compliance_items_tracked,
    COUNT(DISTINCT a.audit_id) AS audits_conducted,
    MAX(a.review_date) AS last_audit_date
FROM
    bcm.bcm_plans p
LEFT JOIN
    operational_risk.operational_risks r ON p.plan_id = r.bcm_plan_id
LEFT JOIN
    regulatory_compliance.regulatory_compliance c ON p.plan_id = c.plan_id
LEFT JOIN
    internal_audit.audit_engagements a ON p.plan_id = a.bcm_plan_id
GROUP BY
    p.plan_id, p.plan_name;

COMMENT ON VIEW bcm.vw_bcm_governance_summary IS 'Summarizes BCM program effectiveness from a governance perspective.';

--stored procedure for contingency plan
CREATE OR REPLACE PROCEDURE bcm.sp_create_contingency_plan(
    p_plan_id UUID,
    p_scenario VARCHAR,
    p_alternative_supplier TEXT,
    p_flexible_work_setup TEXT,
    p_created_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE v_plan_id UUID;
BEGIN
    INSERT INTO bcm.contingency_plans (
        plan_id, scenario, alternative_supplier, flexible_work_setup, created_by
    ) VALUES (
        p_plan_id, p_scenario, p_alternative_supplier, p_flexible_work_setup, p_created_by
    ) RETURNING contingency_plan_id INTO v_plan_id;

    CALL core.sp_log_audit_event(
        p_created_by,
        'BCM_CONTINGENCY',
        'Contingency Planning',
        'create_contingency_plan',
        'contingency_plan',
        v_plan_id,
        NULL,
        jsonb_build_object('scenario', p_scenario),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_create_contingency_plan(UUID, VARCHAR, TEXT, TEXT, UUID) IS 'Records a new contingency plan.';

--triggers for ensuring automatic timestamp updates
CREATE TRIGGER update_bia_financial_impact_updated_at
BEFORE UPDATE ON bcm.bia_financial_impact
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_contingency_plans_updated_at
BEFORE UPDATE ON bcm.contingency_plans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();



----- alter table for regulatory compliance tables
ALTER TABLE bcm.bcm_plans ADD COLUMN financial_institution_specific BOOLEAN DEFAULT FALSE;


-- create a view to organize and access information via centralized schema structure
CREATE OR REPLACE VIEW bcm.vw_bcm_central_repository AS
SELECT
    bp.plan_id,
    bp.plan_name,
    bp.status,
    rs.strategy_count,
    cp.contact_list,
    dp.procedure_count,
    ia.total_incidents,
    fu.total_funding_secured
FROM
    bcm.bcm_plans bp
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS strategy_count FROM bcm.recovery_strategies WHERE plan_id = bp.plan_id
) rs ON TRUE
LEFT JOIN LATERAL (
    SELECT contact_list FROM bcm.communication_plans WHERE bcp_id IN (
        SELECT bcp_id FROM bcm.business_continuity_plans WHERE plan_id = bp.plan_id
    )
) cp ON TRUE
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS procedure_count FROM bcm.disaster_response_procedures WHERE plan_id = bp.plan_id
) dp ON TRUE
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS total_incidents FROM operational_risk.risk_events WHERE category = 'Disruption'
) ia ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(amount) AS total_funding_secured FROM bcm.funding_sources WHERE plan_id = bp.plan_id
) fu ON TRUE;

COMMENT ON VIEW bcm.vw_bcm_central_repository IS 'Centralized, secure, and readily available location for all BCM plans and data.';



--expose third party business continuity risks
ALTER TABLE third_party_risk.third_parties ADD COLUMN has_bcm_plan BOOLEAN DEFAULT FALSE;


-- view for bcm exposure
CREATE OR REPLACE VIEW bcm.vw_third_party_bcm_exposure AS
SELECT
    tp.company_name,
    tp.service_provided,
    tp.risk_rating,
    CASE WHEN tp.has_bcm_plan THEN 'Yes' ELSE 'No' END AS has_bcm_contingency,
    ra.findings
FROM
    third_party_risk.third_parties tp
LEFT JOIN LATERAL (
    SELECT findings FROM third_party_risk.risk_assessments WHERE third_party_id = tp.third_party_id ORDER BY assessment_date DESC LIMIT 1
) ra ON TRUE;

COMMENT ON VIEW bcm.vw_third_party_bcm_exposure IS 'Identifies and assesses risks posed by third-party vendors.';


--emergency communication capabiltieis
ALTER TABLE bcm.communication_plans ADD COLUMN enable_two_way_communication BOOLEAN DEFAULT FALSE;

----bcm for pandemic planning
CREATE TABLE IF NOT EXISTS bcm.pandemic_plans (
    pandemic_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    remote_work_capacity TEXT,
    employee_health_monitoring TEXT,
    supply_chain_disruption_strategy TEXT,
    customer_service_continuity TEXT,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.pandemic_plans IS 'Specific tools and guidance for managing pandemic situations.';


-- exam readiness
CREATE OR REPLACE VIEW bcm.vw_bcm_exam_ready_status AS
SELECT
    bp.plan_id,
    bp.plan_name,
    bp.status,
    CASE WHEN bp.next_review_due_at < CURRENT_DATE THEN 'Overdue' ELSE 'Current' END AS review_status,
    COUNT(DISTINCT be.exercise_id) AS exercise_count,
    COUNT(DISTINCT ac.action_id) AS open_actions_count
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.bcm_exercises be ON bp.plan_id = be.plan_id
LEFT JOIN
    bcm.improvement_actions ac ON bp.plan_id = ac.bcp_id AND ac.status = 'Open'
GROUP BY
    bp.plan_id, bp.plan_name, bp.status, bp.next_review_due_at;

COMMENT ON VIEW bcm.vw_bcm_exam_ready_status IS 'Provides reporting and dashboards for demonstrating compliance and preparedness to examiners.';


--bcm mitigation framework
ALTER TABLE bcm.business_continuity_plans ADD COLUMN mitigation_framework TEXT;

-- for automated data updates
ALTER TABLE bcm.data_backup_strategy ADD COLUMN automated_cloud_backup BOOLEAN DEFAULT FALSE;

--geographic diversificaiton plans
ALTER TABLE bcm.bcm_plans ADD COLUMN geographic_diversification_notes TEXT;

--cloud based BCM solutons
ALTER TABLE bcm.bcm_software_instances ADD COLUMN hosted_in_cloud BOOLEAN DEFAULT FALSE;

--AI/machine learning intellgience integrations with BCM
CREATE TABLE IF NOT EXISTS bcm.ai_model_integrations (
    ai_integration_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES model_risk.models(model_id),
    integration_description TEXT,
    use_case VARCHAR(255), -- e.g., Predictive Risk Analysis
    enabled BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.ai_model_integrations IS 'Uses AI for predictive risk analysis and automated response.';

--block chain integration for supply chain transparency
ALTER TABLE bcm.supply_chain_disruption_plans ADD COLUMN uses_blockchain BOOLEAN DEFAULT FALSE;

--IOT for real-time monitoring
CREATE TABLE IF NOT EXISTS bcm.iot_asset_monitoring (
    iot_monitoring_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL,
    asset_type VARCHAR(100), -- e.g., Server, Generator, HVAC
    status_last_checked TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status_details JSONB,
    alert_thresholds JSONB,
    created_by UUID REFERENCES core.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.iot_asset_monitoring IS 'Uses IoT devices for continuous monitoring of critical assets.';


--gamified training
ALTER TABLE bcm.training_programs ADD COLUMN gamified BOOLEAN DEFAULT FALSE;

--cross-organizational collaboration platforms
ALTER TABLE bcm.bcm_plans ADD COLUMN collaboration_platform_url TEXT;

-- stored procedure for pandemic plans
CREATE OR REPLACE PROCEDURE bcm.sp_create_pandemic_plan(
    p_plan_id UUID,
    p_remote_work_capacity TEXT,
    p_employee_health_monitoring TEXT,
    p_supply_chain_disruption_strategy TEXT,
    p_customer_service_continuity TEXT,
    p_created_by UUID
)
LANGUAGE plpgsql
AS $$
DECLARE v_plan_id UUID;
BEGIN
    INSERT INTO bcm.pandemic_plans (
        plan_id, remote_work_capacity, employee_health_monitoring,
        supply_chain_disruption_strategy, customer_service_continuity, created_by
    ) VALUES (
        p_plan_id, p_remote_work_capacity, p_employee_health_monitoring,
        p_supply_chain_disruption_strategy, p_customer_service_continuity, p_created_by
    ) RETURNING pandemic_plan_id INTO v_plan_id;

    CALL core.sp_log_audit_event(
        p_created_by,
        'BCM_PANDEMIC',
        'Pandemic Planning',
        'create_pandemic_plan',
        'pandemic_plan',
        v_plan_id,
        NULL,
        jsonb_build_object('plan_id', p_plan_id),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_create_pandemic_plan(UUID, TEXT, TEXT, TEXT, TEXT, UUID) IS 'Records a new pandemic plan.';

-- ensure autoamtic timestamp updates
CREATE TRIGGER update_pandemic_plans_updated_at
BEFORE UPDATE ON bcm.pandemic_plans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_iot_asset_monitoring_updated_at
BEFORE UPDATE ON bcm.iot_asset_monitoring
FOR EACH ROW EXECUTE FUNCTION update_timestamp();



-----------------
-- Data Privacy Management Schema
--------------------


-- Data Privacy Management Schema (GDPR, FIPPA Compliance)


-- Create data_privacy schema
CREATE SCHEMA IF NOT EXISTS data_privacy;

-- Set search path for data_privacy schema
SET search_path TO data_privacy, public;

-- Table: data_privacy.data_subjects
-- Description: Stores information about data subjects whose personal data is processed.
CREATE TABLE data_privacy.data_subjects (
    subject_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    date_of_birth DATE,
    country_of_residence VARCHAR(100),
    consent_status BOOLEAN DEFAULT FALSE NOT NULL, -- GDPR: Indicates if consent is given
    consent_last_updated TIMESTAMP WITH TIME ZONE,
    data_source TEXT, -- Where the data was collected from
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_subjects IS 'Stores information about data subjects whose personal data is processed.';
COMMENT ON COLUMN data_privacy.data_subjects.subject_id IS 'Unique identifier for the data subject.';
COMMENT ON COLUMN data_privacy.data_subjects.first_name IS 'First name of the data subject.';
COMMENT ON COLUMN data_privacy.data_subjects.last_name IS 'Last name of the data subject.';
COMMENT ON COLUMN data_privacy.data_subjects.email IS 'Email address of the data subject.';
COMMENT ON COLUMN data_privacy.data_subjects.date_of_birth IS 'Date of birth of the data subject.';
COMMENT ON COLUMN data_privacy.data_subjects.country_of_residence IS 'Country of residence for compliance purposes (e.g., GDPR, FIPPA).';
COMMENT ON COLUMN data_privacy.data_subjects.consent_status IS 'Current consent status for data processing.';
COMMENT ON COLUMN data_privacy.data_subjects.consent_last_updated IS 'Timestamp when consent status was last updated.';
COMMENT ON COLUMN data_privacy.data_subjects.data_source IS 'Source from which the data was collected.';
COMMENT ON COLUMN data_privacy.data_subjects.created_at IS 'Timestamp when the data subject record was created.';
COMMENT ON COLUMN data_privacy.data_subjects.updated_at IS 'Timestamp when the data subject record was last updated.';

-- Trigger for data_privacy.data_subjects table
CREATE TRIGGER update_data_subjects_updated_at
BEFORE UPDATE ON data_privacy.data_subjects
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: data_privacy.data_retention_policies
-- Description: Defines data retention policies for different data categories.
CREATE TABLE data_privacy.data_retention_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    retention_period_days INT NOT NULL, -- Retention period in days
    legal_basis TEXT, -- Legal or regulatory basis for retention (e.g., GDPR Article 6)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_retention_policies IS 'Defines data retention policies for different data categories.';
COMMENT ON COLUMN data_privacy.data_retention_policies.policy_id IS 'Unique identifier for the retention policy.';
COMMENT ON COLUMN data_privacy.data_retention_policies.policy_name IS 'Name of the retention policy.';
COMMENT ON COLUMN data_privacy.data_retention_policies.description IS 'Description of the retention policy.';
COMMENT ON COLUMN data_privacy.data_retention_policies.retention_period_days IS 'Number of days data should be retained.';
COMMENT ON COLUMN data_privacy.data_retention_policies.legal_basis IS 'Legal basis for data retention.';
COMMENT ON COLUMN data_privacy.data_retention_policies.created_at IS 'Timestamp when the policy was created.';
COMMENT ON COLUMN data_privacy.data_retention_policies.updated_at IS 'Timestamp when the policy was last updated.';

-- Trigger for data_privacy.data_retention_policies table
CREATE TRIGGER update_data_retention_policies_updated_at
BEFORE UPDATE ON data_privacy.data_retention_policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: data_privacy.data_processing_activities
-- Description: Records data processing activities (GDPR Article 30).
CREATE TABLE data_privacy.data_processing_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    data_category VARCHAR(255) NOT NULL, -- e.g., 'Personal Data', 'Sensitive Personal Data'
    purpose_of_processing TEXT NOT NULL,
    legal_basis TEXT, -- e.g., 'Consent', 'Contract', 'Legal Obligation'
    data_retention_policy_id UUID REFERENCES data_privacy.data_retention_policies(policy_id) ON DELETE SET NULL,
    involved_systems TEXT, -- Comma-separated list of systems involved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_processing_activities IS 'Records data processing activities (GDPR Article 30).';
COMMENT ON COLUMN data_privacy.data_processing_activities.activity_id IS 'Unique identifier for the processing activity.';
COMMENT ON COLUMN data_privacy.data_processing_activities.activity_name IS 'Name of the processing activity.';
COMMENT ON COLUMN data_privacy.data_processing_activities.description IS 'Description of the processing activity.';
COMMENT ON COLUMN data_privacy.data_processing_activities.data_category IS 'Category of data being processed.';
COMMENT ON COLUMN data_privacy.data_processing_activities.purpose_of_processing IS 'Purpose for which data is processed.';
COMMENT ON COLUMN data_privacy.data_processing_activities.legal_basis IS 'Legal basis for processing.';
COMMENT ON COLUMN data_privacy.data_processing_activities.data_retention_policy_id IS 'Foreign key referencing the applicable data retention policy.';
COMMENT ON COLUMN data_privacy.data_processing_activities.involved_systems IS 'Systems involved in the processing activity.';
COMMENT ON COLUMN data_privacy.data_processing_activities.created_at IS 'Timestamp when the activity record was created.';
COMMENT ON COLUMN data_privacy.data_processing_activities.updated_at IS 'Timestamp when the activity record was last updated.';

-- Trigger for data_privacy.data_processing_activities table
CREATE TRIGGER update_data_processing_activities_updated_at
BEFORE UPDATE ON data_privacy.data_processing_activities
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: data_privacy.data_subject_requests
-- Description: Tracks Data Subject Access Requests (DSARs) (GDPR Articles 15-22).
CREATE TABLE data_privacy.data_subject_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID NOT NULL REFERENCES data_privacy.data_subjects(subject_id) ON DELETE CASCADE,
    request_type VARCHAR(100) NOT NULL, -- e.g., 'Access', 'Rectification', 'Erasure', 'Restriction', 'Portability'
    request_details TEXT,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL, -- e.g., 'Received', 'In Progress', 'Completed', 'Rejected'
    resolution_details TEXT,
    resolved_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_subject_requests IS 'Tracks Data Subject Access Requests (DSARs).';
COMMENT ON COLUMN data_privacy.data_subject_requests.request_id IS 'Unique identifier for the DSAR.';
COMMENT ON COLUMN data_privacy.data_subject_requests.subject_id IS 'Foreign key referencing the data subject.';
COMMENT ON COLUMN data_privacy.data_subject_requests.request_type IS 'Type of request (e.g., Access, Erasure).';
COMMENT ON COLUMN data_privacy.data_subject_requests.request_details IS 'Details provided by the data subject in their request.';
COMMENT ON COLUMN data_privacy.data_subject_requests.request_date IS 'Timestamp when the request was received.';
COMMENT ON COLUMN data_privacy.data_subject_requests.status IS 'Current status of the request.';
COMMENT ON COLUMN data_privacy.data_subject_requests.resolution_details IS 'Details of how the request was resolved.';
COMMENT ON COLUMN data_privacy.data_subject_requests.resolved_by IS 'User who resolved the request.';
COMMENT ON COLUMN data_privacy.data_subject_requests.resolved_at IS 'Timestamp when the request was resolved.';
COMMENT ON COLUMN data_privacy.data_subject_requests.created_at IS 'Timestamp when the request record was created.';
COMMENT ON COLUMN data_privacy.data_subject_requests.updated_at IS 'Timestamp when the request record was last updated.';

-- Trigger for data_privacy.data_subject_requests table
CREATE TRIGGER update_data_subject_requests_updated_at
BEFORE UPDATE ON data_privacy.data_subject_requests
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: data_privacy.vw_data_subject_consent_status
-- Description: Shows the consent status for all data subjects.
CREATE OR REPLACE VIEW data_privacy.vw_data_subject_consent_status AS
SELECT
    subject_id,
    first_name,
    last_name,
    email,
    country_of_residence,
    consent_status,
    consent_last_updated
FROM
    data_privacy.data_subjects;

COMMENT ON VIEW data_privacy.vw_data_subject_consent_status IS 'Shows the consent status for all data subjects.';

-- View: data_privacy.vw_data_processing_activities_with_policy
-- Description: Provides details of data processing activities linked to their retention policies.
CREATE OR REPLACE VIEW data_privacy.vw_data_processing_activities_with_policy AS
SELECT
    dpa.activity_id,
    dpa.activity_name,
    dpa.description,
    dpa.data_category,
    dpa.purpose_of_processing,
    dpa.legal_basis,
    drp.policy_name AS retention_policy_name,
    drp.retention_period_days,
    drp.legal_basis AS retention_legal_basis
FROM
    data_privacy.data_processing_activities dpa
LEFT JOIN
    data_privacy.data_retention_policies drp ON dpa.data_retention_policy_id = drp.policy_id;

COMMENT ON VIEW data_privacy.vw_data_processing_activities_with_policy IS 'Provides details of data processing activities linked to their retention policies.';

-- Stored Procedure: data_privacy.sp_process_dsar_erasure
-- Description: Simulates the process of handling a Data Subject Access Request (DSAR) for erasure.
-- In a real system, this would involve actual data deletion/anonymization across various systems.
CREATE OR REPLACE PROCEDURE data_privacy.sp_process_dsar_erasure(
    p_request_id UUID,
    p_resolved_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subject_id UUID;
    v_request_type VARCHAR;
BEGIN
    -- Get request details
    SELECT subject_id, request_type INTO v_subject_id, v_request_type
    FROM data_privacy.data_subject_requests
    WHERE request_id = p_request_id;

    IF v_subject_id IS NULL THEN
        RAISE EXCEPTION 'DSAR Request ID % not found.', p_request_id;
    END IF;

    IF v_request_type <> 'Erasure' THEN
        RAISE EXCEPTION 'Request ID % is not an Erasure request.', p_request_id;
    END IF;

    -- Simulate data erasure (in a real system, this would trigger complex data deletion processes)
    -- For demonstration, we will anonymize the data subject record and log the action.
    UPDATE data_privacy.data_subjects
    SET
        first_name = 'ANONYMIZED',
        last_name = 'ANONYMIZED',
        email = 'anonymized_'||subject_id||'@example.com',
        date_of_birth = NULL,
        country_of_residence = NULL,
        consent_status = FALSE,
        consent_last_updated = CURRENT_TIMESTAMP
    WHERE
        subject_id = v_subject_id;

    -- Update the DSAR request status
    UPDATE data_privacy.data_subject_requests
    SET
        status = 'Completed',
        resolution_details = 'Data subject record anonymized as per erasure request.',
        resolved_by = p_resolved_by_user_id,
        resolved_at = CURRENT_TIMESTAMP
    WHERE
        request_id = p_request_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_resolved_by_user_id,
        'DATA_PRIVACY',
        'Data Privacy Management',
        'process_dsar_erasure',
        'data_subject',
        v_subject_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('status', 'anonymized'),
        NULL, NULL, jsonb_build_object('request_id', p_request_id),
        TRUE -- Sensitive operation
    );

END;
$$;

COMMENT ON PROCEDURE data_privacy.sp_process_dsar_erasure(UUID, UUID) IS 'Simulates the process of handling a Data Subject Access Request (DSAR) for erasure.';




-- ENHANCEMENTS FOR DATA PRIVACY MANAGEMENT SCHEMA

-- Table: data_privacy.data_breaches
-- Description: Records details of data breaches and security incidents.
CREATE TABLE data_privacy.data_breaches (
    breach_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    breach_name VARCHAR(255) NOT NULL,
    description TEXT,
    breach_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    impact_description TEXT,
    affected_records_count INT,
    status VARCHAR(50) NOT NULL, -- e.g., Reported, Under Investigation, Contained, Resolved
    remediation_actions TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_breaches IS 'Records details of data breaches and security incidents.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_id IS 'Unique identifier for the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_name IS 'Name or title of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.description IS 'Description of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_date IS 'Date and time the breach occurred.';
COMMENT ON COLUMN data_privacy.data_breaches.discovery_date IS 'Date and time the breach was discovered.';
COMMENT ON COLUMN data_privacy.data_breaches.impact_description IS 'Description of the impact of the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.affected_records_count IS 'Number of records affected by the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.status IS 'Current status of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.remediation_actions IS 'Actions taken to remediate the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.reported_by IS 'User who reported the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.created_at IS 'Timestamp when the breach record was created.';
COMMENT ON COLUMN data_privacy.data_breaches.updated_at IS 'Timestamp when the breach record was last updated.';

-- Trigger for data_privacy.data_breaches table
CREATE TRIGGER update_data_breaches_updated_at
BEFORE UPDATE ON data_privacy.data_breaches
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: data_privacy.vw_data_subject_consent_summary
-- Description: Provides a summary of data subject consent status.
CREATE OR REPLACE VIEW data_privacy.vw_data_subject_consent_summary AS
SELECT
    consent_status,
    COUNT(subject_id) AS total_subjects,
    ROUND((COUNT(subject_id) * 100.0) / (SELECT COUNT(*) FROM data_privacy.data_subjects), 2) AS percentage
FROM
    data_privacy.data_subjects
GROUP BY
    consent_status;

COMMENT ON VIEW data_privacy.vw_data_subject_consent_summary IS 'Provides a summary of data subject consent status.';

-- Stored Procedure: data_privacy.sp_record_data_breach
-- Description: Records a new data breach incident.
CREATE OR REPLACE PROCEDURE data_privacy.sp_record_data_breach(
    p_breach_name VARCHAR,
    p_description TEXT,
    p_breach_date TIMESTAMP WITH TIME ZONE,
    p_discovery_date TIMESTAMP WITH TIME ZONE,
    p_impact_description TEXT,
    p_affected_records_count INT,
    p_status VARCHAR,
    p_remediation_actions TEXT,
    p_reported_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO data_privacy.data_breaches (
        breach_name, description, breach_date, discovery_date,
        impact_description, affected_records_count, status, remediation_actions, reported_by
    )
    VALUES (
        p_breach_name, p_description, p_breach_date, p_discovery_date,
        p_impact_description, p_affected_records_count, p_status, p_remediation_actions, p_reported_by_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_reported_by_user_id,
        'DATA_PRIVACY_MANAGEMENT',
        'Data Privacy Management',
        'record_data_breach',
        'data_breach',
        (SELECT breach_id FROM data_privacy.data_breaches WHERE breach_name = p_breach_name AND breach_date = p_breach_date ORDER BY created_at DESC LIMIT 1),
        NULL, jsonb_build_object('breach_name', p_breach_name, 'status', p_status, 'affected_records_count', p_affected_records_count),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE data_privacy.sp_record_data_breach(VARCHAR, TEXT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, TEXT, INT, VARCHAR, TEXT, UUID) IS 'Records a new data breach incident.';

-- Materialized View: data_privacy.mv_data_privacy_compliance_summary
-- Description: Aggregates key data privacy compliance metrics.
CREATE MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_summary AS
SELECT
    (SELECT COUNT(*) FROM data_privacy.data_subjects WHERE consent_status = TRUE) AS consented_subjects_count,
    (SELECT COUNT(*) FROM data_privacy.data_subjects WHERE consent_status = FALSE) AS non_consented_subjects_count,
    (SELECT COUNT(*) FROM data_privacy.data_processing_activities) AS total_processing_activities,
    (SELECT COUNT(*) FROM data_privacy.data_subject_requests WHERE status = 'Open') AS open_dsar_requests,
    (SELECT COUNT(*) FROM data_privacy.data_breaches WHERE status IN ('Reported', 'Under Investigation')) AS active_data_breaches;

COMMENT ON MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_summary IS 'Aggregates key data privacy compliance metrics.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE data_privacy.sp_refresh_mv_data_privacy_compliance_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_summary;
END;
$$;

COMMENT ON PROCEDURE data_privacy.sp_refresh_mv_data_privacy_compliance_summary() IS 'Refreshes the materialized view for data privacy compliance summary.';




-- ESG and Financial Controls Management Schema



-- Environmental, Social & Governance (ESG) and Financial Controls Management Schema



-- Create ESG schema
CREATE SCHEMA IF NOT EXISTS esg;

-- Set search path for ESG schema
SET search_path TO esg, public;

-- Table: esg.esg_policies
-- Description: Stores ESG-related policies and commitments.
CREATE TABLE esg.esg_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL, -- e.g., Environmental, Social, Governance
    status VARCHAR(50) NOT NULL, -- e.g., Draft, Approved, Under Review
    effective_date DATE,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE esg.esg_policies IS 'Stores ESG-related policies and commitments.';
COMMENT ON COLUMN esg.esg_policies.policy_id IS 'Unique identifier for the ESG policy.';
COMMENT ON COLUMN esg.esg_policies.policy_name IS 'Name of the ESG policy.';
COMMENT ON COLUMN esg.esg_policies.description IS 'Description of the ESG policy.';
COMMENT ON COLUMN esg.esg_policies.category IS 'Category of the ESG policy (Environmental, Social, or Governance).';
COMMENT ON COLUMN esg.esg_policies.status IS 'Current status of the ESG policy.';
COMMENT ON COLUMN esg.esg_policies.effective_date IS 'Date when the policy became effective.';
COMMENT ON COLUMN esg.esg_policies.last_reviewed_at IS 'Timestamp of the last review of the policy.';
COMMENT ON COLUMN esg.esg_policies.owner_user_id IS 'User responsible for the ESG policy.';
COMMENT ON COLUMN esg.esg_policies.created_at IS 'Timestamp when the ESG policy was created.';
COMMENT ON COLUMN esg.esg_policies.updated_at IS 'Timestamp when the ESG policy was last updated.';

-- Trigger for esg.esg_policies table
CREATE TRIGGER update_esg_policies_updated_at
BEFORE UPDATE ON esg.esg_policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: esg.esg_metrics
-- Description: Stores definitions for ESG metrics and their targets.
CREATE TABLE esg.esg_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL, -- e.g., Emissions, Water Usage, Diversity, Board Independence
    unit VARCHAR(50), -- e.g., tonnes CO2e, m3, %
    target_value DECIMAL(18, 4),
    reporting_frequency VARCHAR(50), -- e.g., Annually, Quarterly
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE esg.esg_metrics IS 'Stores definitions for ESG metrics and their targets.';
COMMENT ON COLUMN esg.esg_metrics.metric_id IS 'Unique identifier for the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.metric_name IS 'Name of the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.description IS 'Description of the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.category IS 'Category of the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.unit IS 'Unit of measurement for the metric.';
COMMENT ON COLUMN esg.esg_metrics.target_value IS 'Target value for the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.reporting_frequency IS 'Frequency of reporting for the metric.';
COMMENT ON COLUMN esg.esg_metrics.owner_user_id IS 'User responsible for the ESG metric.';
COMMENT ON COLUMN esg.esg_metrics.created_at IS 'Timestamp when the ESG metric was defined.';
COMMENT ON COLUMN esg.esg_metrics.updated_at IS 'Timestamp when the ESG metric was last updated.';

-- Trigger for esg.esg_metrics table
CREATE TRIGGER update_esg_metrics_updated_at
BEFORE UPDATE ON esg.esg_metrics
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: esg.esg_actuals
-- Description: Stores actual reported values for ESG metrics.
CREATE TABLE esg.esg_actuals (
    actual_id BIGSERIAL PRIMARY KEY,
    metric_id UUID NOT NULL REFERENCES esg.esg_metrics(metric_id) ON DELETE CASCADE,
    reporting_period DATE NOT NULL, -- Date representing the end of the reporting period
    actual_value DECIMAL(18, 4) NOT NULL,
    source_of_data TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (metric_id, reporting_period)
);

COMMENT ON TABLE esg.esg_actuals IS 'Stores actual reported values for ESG metrics.';
COMMENT ON COLUMN esg.esg_actuals.actual_id IS 'Unique identifier for the ESG actual value.';
COMMENT ON COLUMN esg.esg_actuals.metric_id IS 'Foreign key referencing the ESG metric definition.';
COMMENT ON COLUMN esg.esg_actuals.reporting_period IS 'End date of the reporting period for the actual value.';
COMMENT ON COLUMN esg.esg_actuals.actual_value IS 'Actual measured value of the ESG metric.';
COMMENT ON COLUMN esg.esg_actuals.source_of_data IS 'Source from which the data was obtained.';
COMMENT ON COLUMN esg.esg_actuals.reported_by IS 'User who reported the actual value.';
COMMENT ON COLUMN esg.esg_actuals.created_at IS 'Timestamp when the actual value was recorded.';

-- View: esg.vw_esg_policy_overview
-- Description: Provides an overview of ESG policies and their review status.
CREATE OR REPLACE VIEW esg.vw_esg_policy_overview AS
SELECT
    policy_id,
    policy_name,
    category,
    status,
    effective_date,
    last_reviewed_at,
    u.username AS owner_username
FROM
    esg.esg_policies ep
LEFT JOIN
    core.users u ON ep.owner_user_id = u.user_id;

COMMENT ON VIEW esg.vw_esg_policy_overview IS 'Provides an overview of ESG policies and their review status.';

-- View: esg.vw_esg_metric_performance
-- Description: Shows the latest actual values for each ESG metric compared to their targets.
CREATE OR REPLACE VIEW esg.vw_esg_metric_performance AS
SELECT
    em.metric_name,
    em.description,
    em.category,
    em.unit,
    em.target_value,
    ea.reporting_period,
    ea.actual_value,
    (ea.actual_value - em.target_value) AS variance,
    CASE
        WHEN em.target_value = 0 THEN NULL
        ELSE ((ea.actual_value - em.target_value) / em.target_value) * 100
    END AS variance_percentage
FROM
    esg.esg_metrics em
JOIN
    esg.esg_actuals ea ON em.metric_id = ea.metric_id
WHERE
    ea.reporting_period = (SELECT MAX(reporting_period) FROM esg.esg_actuals WHERE metric_id = em.metric_id);

COMMENT ON VIEW esg.vw_esg_metric_performance IS 'Shows the latest actual values for each ESG metric compared to their targets.';

-- Stored Procedure: esg.sp_record_esg_actual
-- Description: Records a new actual value for a specified ESG metric.
CREATE OR REPLACE PROCEDURE esg.sp_record_esg_actual(
    p_metric_name VARCHAR,
    p_reporting_period DATE,
    p_actual_value DECIMAL,
    p_source_of_data TEXT,
    p_reported_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_metric_id UUID;
BEGIN
    SELECT metric_id INTO v_metric_id FROM esg.esg_metrics WHERE metric_name = p_metric_name;

    IF v_metric_id IS NULL THEN
        RAISE EXCEPTION 'ESG Metric % not found.', p_metric_name;
    END IF;

    INSERT INTO esg.esg_actuals (metric_id, reporting_period, actual_value, source_of_data, reported_by)
    VALUES (v_metric_id, p_reporting_period, p_actual_value, p_source_of_data, p_reported_by_user_id)
    ON CONFLICT (metric_id, reporting_period) DO UPDATE SET
        actual_value = EXCLUDED.actual_value,
        source_of_data = EXCLUDED.source_of_data,
        reported_by = EXCLUDED.reported_by,
        created_at = CURRENT_TIMESTAMP;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_reported_by_user_id,
        'ESG_MANAGEMENT',
        'ESG',
        'record_esg_actual',
        'esg_metric_actual',
        v_metric_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('metric_name', p_metric_name, 'reporting_period', p_reporting_period, 'actual_value', p_actual_value),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE esg.sp_record_esg_actual(VARCHAR, DATE, DECIMAL, TEXT, UUID) IS 'Records a new actual value for a specified ESG metric.';

-- Create financial_controls schema
CREATE SCHEMA IF NOT EXISTS financial_controls;

-- Set search path for financial_controls schema
SET search_path TO financial_controls, public;

-- Table: financial_controls.financial_controls
-- Description: Stores definitions of financial controls.
CREATE TABLE financial_controls.financial_controls (
    control_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    control_type VARCHAR(100) NOT NULL, -- e.g., Preventative, Detective
    frequency VARCHAR(50), -- e.g., Daily, Weekly, Monthly, Quarterly, Annually
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    related_sox_section TEXT, -- e.g., SOX 302, SOX 404
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE financial_controls.financial_controls IS 'Stores definitions of financial controls.';
COMMENT ON COLUMN financial_controls.financial_controls.control_id IS 'Unique identifier for the financial control.';
COMMENT ON COLUMN financial_controls.financial_controls.control_name IS 'Name of the financial control.';
COMMENT ON COLUMN financial_controls.financial_controls.description IS 'Description of the financial control.';
COMMENT ON COLUMN financial_controls.financial_controls.control_type IS 'Type of control (Preventative or Detective).';
COMMENT ON COLUMN financial_controls.financial_controls.frequency IS 'Frequency of control execution.';
COMMENT ON COLUMN financial_controls.financial_controls.owner_user_id IS 'User responsible for the financial control.';
COMMENT ON COLUMN financial_controls.financial_controls.related_sox_section IS 'Relevant SOX section for the control.';
COMMENT ON COLUMN financial_controls.financial_controls.created_at IS 'Timestamp when the financial control was created.';
COMMENT ON COLUMN financial_controls.financial_controls.updated_at IS 'Timestamp when the financial control was last updated.';

-- Trigger for financial_controls.financial_controls table
CREATE TRIGGER update_financial_controls_updated_at
BEFORE UPDATE ON financial_controls.financial_controls
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: financial_controls.financial_control_tests
-- Description: Records results of financial control tests.
CREATE TABLE financial_controls.financial_control_tests (
    test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES financial_controls.financial_controls(control_id) ON DELETE CASCADE,
    test_date DATE NOT NULL,
    result VARCHAR(50) NOT NULL, -- e.g., Pass, Fail, Partial Pass
    findings TEXT,
    remediation_plan TEXT,
    tested_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    reviewed_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE financial_controls.financial_control_tests IS 'Records results of financial control tests.';
COMMENT ON COLUMN financial_controls.financial_control_tests.test_id IS 'Unique identifier for the control test.';
COMMENT ON COLUMN financial_controls.financial_control_tests.control_id IS 'Foreign key referencing the financial control tested.';
COMMENT ON COLUMN financial_controls.financial_control_tests.test_date IS 'Date the control test was performed.';
COMMENT ON COLUMN financial_controls.financial_control_tests.result IS 'Result of the control test.';
COMMENT ON COLUMN financial_controls.financial_control_tests.findings IS 'Findings from the control test.';
COMMENT ON COLUMN financial_controls.financial_control_tests.remediation_plan IS 'Plan for remediating any control deficiencies.';
COMMENT ON COLUMN financial_controls.financial_control_tests.tested_by IS 'User who performed the test.';
COMMENT ON COLUMN financial_controls.financial_control_tests.reviewed_by IS 'User who reviewed the test results.';
COMMENT ON COLUMN financial_controls.financial_control_tests.created_at IS 'Timestamp when the test record was created.';
COMMENT ON COLUMN financial_controls.financial_control_tests.updated_at IS 'Timestamp when the test record was last updated.';

-- Trigger for financial_controls.financial_control_tests table
CREATE TRIGGER update_financial_control_tests_updated_at
BEFORE UPDATE ON financial_controls.financial_control_tests
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: financial_controls.financial_incidents
-- Description: Records financial incidents or anomalies.
CREATE TABLE financial_controls.financial_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_name VARCHAR(255) NOT NULL,
    description TEXT,
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Reported, Under Investigation, Resolved, Closed
    financial_impact DECIMAL(18, 2), -- Monetary impact of the incident
    root_cause TEXT,
    remediation_actions TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE financial_controls.financial_incidents IS 'Records financial incidents or anomalies.';
COMMENT ON COLUMN financial_controls.financial_incidents.incident_id IS 'Unique identifier for the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.incident_name IS 'Name or title of the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.description IS 'Description of the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.incident_date IS 'Date the incident occurred.';
COMMENT ON COLUMN financial_controls.financial_incidents.discovery_date IS 'Date the incident was discovered.';
COMMENT ON COLUMN financial_controls.financial_incidents.status IS 'Current status of the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.financial_impact IS 'Monetary impact of the incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.root_cause IS 'Root cause of the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.remediation_actions IS 'Actions taken to remediate the incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.reported_by IS 'User who reported the financial incident.';
COMMENT ON COLUMN financial_controls.financial_incidents.created_at IS 'Timestamp when the incident record was created.';
COMMENT ON COLUMN financial_controls.financial_incidents.updated_at IS 'Timestamp when the incident record was last updated.';

-- Trigger for financial_controls.financial_incidents table
CREATE TRIGGER update_financial_incidents_updated_at
BEFORE UPDATE ON financial_controls.financial_incidents
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: financial_controls.vw_financial_control_status
-- Description: Provides an overview of financial controls and their latest test results.
CREATE OR REPLACE VIEW financial_controls.vw_financial_control_status AS
SELECT
    fc.control_id,
    fc.control_name,
    fc.description,
    fc.control_type,
    fc.frequency,
    u.username AS owner_username,
    fct.test_date AS last_test_date,
    fct.result AS last_test_result,
    fct.findings AS last_test_findings
FROM
    financial_controls.financial_controls fc
LEFT JOIN
    core.users u ON fc.owner_user_id = u.user_id
LEFT JOIN LATERAL (
    SELECT *
    FROM financial_controls.financial_control_tests
    WHERE control_id = fc.control_id
    ORDER BY test_date DESC
    LIMIT 1
) fct ON TRUE;

COMMENT ON VIEW financial_controls.vw_financial_control_status IS 'Provides an overview of financial controls and their latest test results.';

-- View: financial_controls.vw_financial_incident_summary
-- Description: Summarizes financial incidents by status and impact.
CREATE OR REPLACE VIEW financial_controls.vw_financial_incident_summary AS
SELECT
    status,
    COUNT(incident_id) AS total_incidents,
    SUM(financial_impact) AS total_financial_impact
FROM
    financial_controls.financial_incidents
GROUP BY
    status;

COMMENT ON VIEW financial_controls.vw_financial_incident_summary IS 'Summarizes financial incidents by status and impact.';

-- Stored Procedure: financial_controls.sp_record_control_test_result
-- Description: Records the result of a financial control test.
CREATE OR REPLACE PROCEDURE financial_controls.sp_record_control_test_result(
    p_control_id UUID,
    p_test_date DATE,
    p_result VARCHAR,
    p_findings TEXT,
    p_remediation_plan TEXT,
    p_tested_by_user_id UUID,
    p_reviewed_by_user_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO financial_controls.financial_control_tests (
        control_id, test_date, result, findings, remediation_plan, tested_by, reviewed_by
    )
    VALUES (
        p_control_id, p_test_date, p_result, p_findings, p_remediation_plan, p_tested_by_user_id, p_reviewed_by_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_tested_by_user_id,
        'FINANCIAL_CONTROLS_MANAGEMENT',
        'Financial Controls Management',
        'record_control_test_result',
        'financial_control_test',
        p_control_id,
        NULL, jsonb_build_object('test_date', p_test_date, 'result', p_result),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE financial_controls.sp_record_control_test_result(UUID, DATE, VARCHAR, TEXT, TEXT, UUID, UUID) IS 'Records the result of a financial control test.';



-- ENHANCEMENTS FOR ESG AND FINANCIAL CONTROLS MANAGEMENT SCHEMA

-- Table: esg.carbon_emissions_data
-- Description: Stores detailed carbon emissions data.
CREATE TABLE esg.carbon_emissions_data (
    emission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_id UUID NOT NULL REFERENCES esg.esg_metrics(metric_id) ON DELETE CASCADE,
    reporting_period DATE NOT NULL,
    scope1_emissions DECIMAL(18, 4), -- Direct emissions
    scope2_emissions DECIMAL(18, 4), -- Indirect emissions from purchased energy
    scope3_emissions DECIMAL(18, 4), -- Other indirect emissions
    total_emissions DECIMAL(18, 4) GENERATED ALWAYS AS (scope1_emissions + scope2_emissions + scope3_emissions) STORED,
    emission_source TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE esg.carbon_emissions_data IS 'Stores detailed carbon emissions data.';
COMMENT ON COLUMN esg.carbon_emissions_data.emission_id IS 'Unique identifier for the emission record.';
COMMENT ON COLUMN esg.carbon_emissions_data.metric_id IS 'Foreign key referencing the associated ESG metric (e.g., Total Carbon Emissions).';
COMMENT ON COLUMN esg.carbon_emissions_data.reporting_period IS 'End date of the reporting period.';
COMMENT ON COLUMN esg.carbon_emissions_data.scope1_emissions IS 'Direct emissions from owned or controlled sources.';
COMMENT ON COLUMN esg.carbon_emissions_data.scope2_emissions IS 'Indirect emissions from the generation of purchased electricity, steam, heating, and cooling consumed by the reporting company.';
COMMENT ON COLUMN esg.carbon_emissions_data.scope3_emissions IS 'All other indirect emissions that occur in a company’s value chain.';
COMMENT ON COLUMN esg.carbon_emissions_data.total_emissions IS 'Calculated total emissions.';
COMMENT ON COLUMN esg.carbon_emissions_data.emission_source IS 'Description of the source of these emissions.';
COMMENT ON COLUMN esg.carbon_emissions_data.reported_by IS 'User who reported the emissions data.';
COMMENT ON COLUMN esg.carbon_emissions_data.created_at IS 'Timestamp when the record was created.';
COMMENT ON COLUMN esg.carbon_emissions_data.updated_at IS 'Timestamp when the record was last updated.';

-- Trigger for esg.carbon_emissions_data table
CREATE TRIGGER update_carbon_emissions_data_updated_at
BEFORE UPDATE ON esg.carbon_emissions_data
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: esg.vw_esg_performance_dashboard
-- Description: Aggregates key ESG performance indicators for a dashboard view.
CREATE OR REPLACE VIEW esg.vw_esg_performance_dashboard AS
SELECT
    em.metric_name,
    em.category,
    em.unit,
    em.target_value,
    ea.actual_value AS latest_actual_value,
    ea.reporting_period AS latest_reporting_period,
    (ea.actual_value - em.target_value) AS variance_from_target,
    CASE
        WHEN em.target_value = 0 THEN NULL
        ELSE ROUND(((ea.actual_value - em.target_value) / em.target_value) * 100, 2)
    END AS variance_percentage_from_target,
    CASE
        WHEN ea.actual_value <= em.target_value THEN 'On Track'
        ELSE 'Off Track'
    END AS performance_status
FROM
    esg.esg_metrics em
LEFT JOIN LATERAL (
    SELECT actual_value, reporting_period
    FROM esg.esg_actuals
    WHERE metric_id = em.metric_id
    ORDER BY reporting_period DESC
    LIMIT 1
) ea ON TRUE;

COMMENT ON VIEW esg.vw_esg_performance_dashboard IS 'Aggregates key ESG performance indicators for a dashboard view.';

-- Stored Procedure: esg.sp_analyze_esg_trends
-- Description: Analyzes historical ESG data to identify trends for a given metric.
CREATE OR REPLACE PROCEDURE esg.sp_analyze_esg_trends(
    p_metric_name VARCHAR,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_metric_id UUID;
BEGIN
    SELECT metric_id INTO v_metric_id FROM esg.esg_metrics WHERE metric_name = p_metric_name;

    IF v_metric_id IS NULL THEN
        RAISE EXCEPTION 'ESG Metric % not found.', p_metric_name;
    END IF;

    RAISE NOTICE 'Analyzing trends for metric: % from % to %',
        p_metric_name, p_start_date, p_end_date;

    -- This is a simplified example. In a real application, this procedure would
    -- perform complex statistical analysis, potentially using temporary tables
    -- or returning a CURSOR for detailed results.
    -- For now, it just selects data and logs the action.
    PERFORM
        reporting_period,
        actual_value
    FROM
        esg.esg_actuals
    WHERE
        metric_id = v_metric_id AND reporting_period BETWEEN p_start_date AND p_end_date
    ORDER BY
        reporting_period;

    CALL core.sp_log_audit_event(
        NULL, -- Assuming this can be called by system or a specific user
        'ESG_MANAGEMENT',
        'ESG',
        'analyze_esg_trends',
        'esg_metric',
        v_metric_id,
        NULL, NULL,
        NULL, NULL, jsonb_build_object('metric_name', p_metric_name, 'start_date', p_start_date, 'end_date', p_end_date),
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE esg.sp_analyze_esg_trends(VARCHAR, DATE, DATE) IS 'Analyzes historical ESG data to identify trends for a given metric.';

-- Materialized View: esg.mv_esg_compliance_summary
-- Description: Provides a summary of ESG policy compliance and metric performance.
CREATE MATERIALIZED VIEW esg.mv_esg_compliance_summary AS
SELECT
    (SELECT COUNT(*) FROM esg.esg_policies WHERE status = 'Approved') AS approved_policies_count,
    (SELECT COUNT(*) FROM esg.esg_policies WHERE next_review_due_at < CURRENT_DATE) AS overdue_policy_reviews_count,
    (SELECT COUNT(*) FROM esg.esg_metrics) AS total_esg_metrics,
    (SELECT COUNT(*) FROM esg.vw_esg_metric_performance WHERE performance_status = 'Off Track') AS off_track_metrics_count;

COMMENT ON MATERIALIZED VIEW esg.mv_esg_compliance_summary IS 'Provides a summary of ESG policy compliance and metric performance.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE esg.sp_refresh_mv_esg_compliance_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW esg.mv_esg_compliance_summary;
END;
$$;

COMMENT ON PROCEDURE esg.sp_refresh_mv_esg_compliance_summary() IS 'Refreshes the materialized view for ESG compliance summary.';


-- ENHANCEMENTS FOR FINANCIAL CONTROLS MANAGEMENT SCHEMA

-- Table: financial_controls.control_deficiencies
-- Description: Tracks identified control deficiencies and their remediation.
CREATE TABLE financial_controls.control_deficiencies (
    deficiency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES financial_controls.financial_controls(control_id) ON DELETE CASCADE,
    test_id UUID REFERENCES financial_controls.financial_control_tests(test_id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL, -- e.g., Low, Medium, High, Critical
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Closed, Verified
    remediation_plan TEXT,
    due_date DATE,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    closed_date DATE,
    closed_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE financial_controls.control_deficiencies IS 'Tracks identified control deficiencies and their remediation.';
COMMENT ON COLUMN financial_controls.control_deficiencies.deficiency_id IS 'Unique identifier for the control deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.control_id IS 'Foreign key referencing the control with the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.test_id IS 'Foreign key referencing the test that identified the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.description IS 'Description of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.severity IS 'Severity of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.status IS 'Current status of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.remediation_plan IS 'Plan for remediating the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.due_date IS 'Due date for remediation.';
COMMENT ON COLUMN financial_controls.control_deficiencies.responsible_user_id IS 'User responsible for remediating the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.closed_date IS 'Date the deficiency was closed.';
COMMENT ON COLUMN financial_controls.control_deficiencies.closed_by IS 'User who closed the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.created_at IS 'Timestamp when the deficiency was recorded.';
COMMENT ON COLUMN financial_controls.control_deficiencies.updated_at IS 'Timestamp when the deficiency was last updated.';

-- Trigger for financial_controls.control_deficiencies table
CREATE TRIGGER update_control_deficiencies_updated_at
BEFORE UPDATE ON financial_controls.control_deficiencies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: financial_controls.vw_control_deficiency_summary
-- Description: Provides a summary of control deficiencies by status and severity.
CREATE OR REPLACE VIEW financial_controls.vw_control_deficiency_summary AS
SELECT
    status,
    severity,
    COUNT(deficiency_id) AS total_deficiencies,
    COUNT(CASE WHEN due_date < CURRENT_DATE AND status IN ('Open', 'In Progress') THEN 1 END) AS overdue_deficiencies
FROM
    financial_controls.control_deficiencies
GROUP BY
    status, severity;

COMMENT ON VIEW financial_controls.vw_control_deficiency_summary IS 'Provides a summary of control deficiencies by status and severity.';

-- Stored Procedure: financial_controls.sp_update_deficiency_status
-- Description: Updates the status and remediation details of a control deficiency.
CREATE OR REPLACE PROCEDURE financial_controls.sp_update_deficiency_status(
    p_deficiency_id UUID,
    p_new_status VARCHAR,
    p_remediation_plan TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_responsible_user_id UUID DEFAULT NULL,
    p_closed_by_user_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM financial_controls.control_deficiencies WHERE deficiency_id = p_deficiency_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'Control Deficiency ID % not found.', p_deficiency_id;
    END IF;

    UPDATE financial_controls.control_deficiencies
    SET
        status = p_new_status,
        remediation_plan = COALESCE(p_remediation_plan, remediation_plan),
        due_date = COALESCE(p_due_date, due_date),
        responsible_user_id = COALESCE(p_responsible_user_id, responsible_user_id),
        closed_date = CASE WHEN p_new_status = 'Closed' THEN CURRENT_DATE ELSE closed_date END,
        closed_by = CASE WHEN p_new_status = 'Closed' THEN p_closed_by_user_id ELSE closed_by END,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        deficiency_id = p_deficiency_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        COALESCE(p_closed_by_user_id, p_responsible_user_id), -- Logged by whoever is closing or responsible
        'FINANCIAL_CONTROLS_MANAGEMENT',
        'Financial Controls Management',
        'update_deficiency_status',
        'control_deficiency',
        p_deficiency_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'remediation_plan', p_remediation_plan, 'due_date', p_due_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE financial_controls.sp_update_deficiency_status(UUID, VARCHAR, TEXT, DATE, UUID, UUID) IS 'Updates the status and remediation details of a control deficiency.';

-- Materialized View: financial_controls.mv_sox_compliance_dashboard
-- Description: Aggregates key metrics for SOX compliance reporting.
CREATE MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard AS
SELECT
    (SELECT COUNT(*) FROM financial_controls.financial_controls) AS total_controls,
    (SELECT COUNT(*) FROM financial_controls.financial_control_tests WHERE result = 'Fail') AS failed_tests_count,
    (SELECT COUNT(*) FROM financial_controls.control_deficiencies WHERE status IN ('Open', 'In Progress')) AS open_deficiencies_count,
    (SELECT COUNT(*) FROM financial_controls.financial_incidents WHERE status IN ('Reported', 'Under Investigation')) AS active_financial_incidents;

COMMENT ON MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard IS 'Aggregates key metrics for SOX compliance reporting.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE financial_controls.sp_refresh_mv_sox_compliance_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard;
END;
$$;

COMMENT ON PROCEDURE financial_controls.sp_refresh_mv_sox_compliance_dashboard() IS 'Refreshes the materialized view for SOX compliance dashboard.';




-- Internal Audit Management and IT Governance Schema



-- Internal Audit Management and IT Governance Schema



-- Create internal_audit schema
CREATE SCHEMA IF NOT EXISTS internal_audit;

-- Set search path for internal_audit schema
SET search_path TO internal_audit, public;

-- Table: internal_audit.audit_engagements
-- Description: Stores details of internal audit engagements.
CREATE TABLE internal_audit.audit_engagements (
    engagement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    engagement_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(50) NOT NULL, -- e.g., Planned, In Progress, Completed, Canceled
    lead_auditor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_engagements IS 'Stores details of internal audit engagements.';
COMMENT ON COLUMN internal_audit.audit_engagements.engagement_id IS 'Unique identifier for the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.engagement_name IS 'Name of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.description IS 'Description of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.start_date IS 'Start date of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.end_date IS 'End date of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.status IS 'Current status of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.lead_auditor_user_id IS 'User ID of the lead auditor for the engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.created_at IS 'Timestamp when the engagement record was created.';
COMMENT ON COLUMN internal_audit.audit_engagements.updated_at IS 'Timestamp when the engagement record was last updated.';

-- Trigger for internal_audit.audit_engagements table
CREATE TRIGGER update_audit_engagements_updated_at
BEFORE UPDATE ON internal_audit.audit_engagements
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: internal_audit.audit_findings
-- Description: Records findings from internal audit engagements.
CREATE TABLE internal_audit.audit_findings (
    finding_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    engagement_id UUID NOT NULL REFERENCES internal_audit.audit_engagements(engagement_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    recommendation TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Closed, Verified
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    due_date DATE,
    closed_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_findings IS 'Records findings from internal audit engagements.';
COMMENT ON COLUMN internal_audit.audit_findings.finding_id IS 'Unique identifier for the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.engagement_id IS 'Foreign key referencing the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_findings.title IS 'Title of the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.description IS 'Description of the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.severity IS 'Severity level of the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.recommendation IS 'Recommended action to address the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.status IS 'Current status of the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.responsible_user_id IS 'User responsible for addressing the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.due_date IS 'Due date for remediation.';
COMMENT ON COLUMN internal_audit.audit_findings.closed_date IS 'Date the finding was closed.';
COMMENT ON COLUMN internal_audit.audit_findings.created_at IS 'Timestamp when the finding record was created.';
COMMENT ON COLUMN internal_audit.audit_findings.updated_at IS 'Timestamp when the finding record was last updated.';

-- Trigger for internal_audit.audit_findings table
CREATE TRIGGER update_audit_findings_updated_at
BEFORE UPDATE ON internal_audit.audit_findings
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: internal_audit.vw_open_audit_findings
-- Description: Lists all open audit findings with their details and responsible parties.
CREATE OR REPLACE VIEW internal_audit.vw_open_audit_findings AS
SELECT
    af.finding_id,
    ae.engagement_name,
    af.title,
    af.description,
    af.severity,
    af.recommendation,
    af.status,
    u.username AS responsible_username,
    af.due_date
FROM
    internal_audit.audit_findings af
JOIN
    internal_audit.audit_engagements ae ON af.engagement_id = ae.engagement_id
LEFT JOIN
    core.users u ON af.responsible_user_id = u.user_id
WHERE
    af.status IN (
        'Open',
        'In Progress'
    );

COMMENT ON VIEW internal_audit.vw_open_audit_findings IS 'Lists all open audit findings with their details and responsible parties.';

-- Stored Procedure: internal_audit.sp_update_finding_status
-- Description: Updates the status of an audit finding.
CREATE OR REPLACE PROCEDURE internal_audit.sp_update_finding_status(
    p_finding_id UUID,
    p_new_status VARCHAR,
    p_closed_date DATE DEFAULT NULL,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM internal_audit.audit_findings WHERE finding_id = p_finding_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'Audit Finding ID % not found.', p_finding_id;
    END IF;

    UPDATE internal_audit.audit_findings
    SET
        status = p_new_status,
        closed_date = p_closed_date,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        finding_id = p_finding_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'INTERNAL_AUDIT',
        'Internal Audit Management',
        'update_finding_status',
        'audit_finding',
        p_finding_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'closed_date', p_closed_date),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_update_finding_status(UUID, VARCHAR, DATE, UUID) IS 'Updates the status of an audit finding.';

-- Create it_governance schema
CREATE SCHEMA IF NOT EXISTS it_governance;

-- Set search path for it_governance schema
SET search_path TO it_governance, public;

-- Table: it_governance.it_policies
-- Description: Stores IT policies and standards.
CREATE TABLE it_governance.it_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    category VARCHAR(100), -- e.g., Security, Data Management, Acceptable Use
    effective_date DATE,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_due_at DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_policies IS 'Stores IT policies and standards.';
COMMENT ON COLUMN it_governance.it_policies.policy_id IS 'Unique identifier for the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.policy_name IS 'Name of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.description IS 'Description of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.version IS 'Version of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.category IS 'Category of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.effective_date IS 'Date when the policy became effective.';
COMMENT ON COLUMN it_governance.it_policies.last_reviewed_at IS 'Timestamp of the last review of the policy.';
COMMENT ON COLUMN it_governance.it_policies.next_review_due_at IS 'Date when the next review of the policy is due.';
COMMENT ON COLUMN it_governance.it_policies.owner_user_id IS 'User responsible for the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.created_at IS 'Timestamp when the IT policy was created.';
COMMENT ON COLUMN it_governance.it_policies.updated_at IS 'Timestamp when the IT policy was last updated.';

-- Trigger for it_governance.it_policies table
CREATE TRIGGER update_it_policies_updated_at
BEFORE UPDATE ON it_governance.it_policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: it_governance.it_risks
-- Description: Records IT-related risks.
CREATE TABLE it_governance.it_risks (
    risk_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    likelihood VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    impact VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    mitigation_plan TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, Mitigated, Closed
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_risks IS 'Records IT-related risks.';
COMMENT ON COLUMN it_governance.it_risks.risk_id IS 'Unique identifier for the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.risk_name IS 'Name of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.description IS 'Description of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.severity IS 'Severity of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.likelihood IS 'Likelihood of the IT risk occurring.';
COMMENT ON COLUMN it_governance.it_risks.impact IS 'Impact of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.mitigation_plan IS 'Plan to mitigate the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.status IS 'Current status of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.owner_user_id IS 'User responsible for the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.created_at IS 'Timestamp when the IT risk was created.';
COMMENT ON COLUMN it_governance.it_risks.updated_at IS 'Timestamp when the IT risk was last updated.';

-- Trigger for it_governance.it_risks table
CREATE TRIGGER update_it_risks_updated_at
BEFORE UPDATE ON it_governance.it_risks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: it_governance.vw_it_policy_compliance
-- Description: Provides an overview of IT policies and their review status.
CREATE OR REPLACE VIEW it_governance.vw_it_policy_compliance AS
SELECT
    policy_id,
    policy_name,
    category,
    version,
    effective_date,
    last_reviewed_at,
    next_review_due_at,
    u.username AS owner_username
FROM
    it_governance.it_policies ip
LEFT JOIN
    core.users u ON ip.owner_user_id = u.user_id;

COMMENT ON VIEW it_governance.vw_it_policy_compliance IS 'Provides an overview of IT policies and their review status.';

-- View: it_governance.vw_it_risk_register
-- Description: Displays the current IT risk register.
CREATE OR REPLACE VIEW it_governance.vw_it_risk_register AS
SELECT
    risk_id,
    risk_name,
    description,
    severity,
    likelihood,
    impact,
    mitigation_plan,
    status,
    u.username AS owner_username
FROM
    it_governance.it_risks ir
LEFT JOIN
    core.users u ON ir.owner_user_id = u.user_id;

COMMENT ON VIEW it_governance.vw_it_risk_register IS 'Displays the current IT risk register.';

-- Stored Procedure: it_governance.sp_update_it_risk_status
-- Description: Updates the status of an IT risk.
CREATE OR REPLACE PROCEDURE it_governance.sp_update_it_risk_status(
    p_risk_id UUID,
    p_new_status VARCHAR,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM it_governance.it_risks WHERE risk_id = p_risk_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'IT Risk ID % not found.', p_risk_id;
    END IF;

    UPDATE it_governance.it_risks
    SET
        status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        risk_id = p_risk_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'IT_GOVERNANCE',
        'IT Governance',
        'update_risk_status',
        'it_risk',
        p_risk_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE it_governance.sp_update_it_risk_status(UUID, VARCHAR, UUID) IS 'Updates the status of an IT risk.';






-- Model Risk Governance and Operational Risk Management Schema



-- Model Risk Governance and Operational Risk Management Schema



-- Create model_risk schema
CREATE SCHEMA IF NOT EXISTS model_risk;

-- Set search path for model_risk schema
SET search_path TO model_risk, public;

-- Table: model_risk.models
-- Description: Stores details of models used within the organization.
CREATE TABLE model_risk.models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    model_type VARCHAR(100), -- e.g., Credit Risk, Market Risk, Operational Risk, AML
    development_date DATE,
    last_validation_date DATE,
    next_validation_due_date DATE,
    status VARCHAR(50) NOT NULL, -- e.g., In Development, Approved, Under Review, Retired
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE model_risk.models IS 'Stores details of models used within the organization.';
COMMENT ON COLUMN model_risk.models.model_id IS 'Unique identifier for the model.';
COMMENT ON COLUMN model_risk.models.model_name IS 'Name of the model.';
COMMENT ON COLUMN model_risk.models.description IS 'Description of the model.';
COMMENT ON COLUMN model_risk.models.model_type IS 'Type of the model.';
COMMENT ON COLUMN model_risk.models.development_date IS 'Date when the model was developed.';
COMMENT ON COLUMN model_risk.models.last_validation_date IS 'Date of the last model validation.';
COMMENT ON COLUMN model_risk.models.next_validation_due_date IS 'Date when the next model validation is due.';
COMMENT ON COLUMN model_risk.models.status IS 'Current status of the model.';
COMMENT ON COLUMN model_risk.models.owner_user_id IS 'User responsible for the model.';
COMMENT ON COLUMN model_risk.models.created_at IS 'Timestamp when the model record was created.';
COMMENT ON COLUMN model_risk.models.updated_at IS 'Timestamp when the model record was last updated.';

-- Trigger for model_risk.models table
CREATE TRIGGER update_models_updated_at
BEFORE UPDATE ON model_risk.models
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: model_risk.model_validations
-- Description: Records results of model validation activities.
CREATE TABLE model_risk.model_validations (
    validation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES model_risk.models(model_id) ON DELETE CASCADE,
    validation_date DATE NOT NULL,
    validator_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    validation_result VARCHAR(50) NOT NULL, -- e.g., Pass, Fail, Conditional Pass
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE model_risk.model_validations IS 'Records results of model validation activities.';
COMMENT ON COLUMN model_risk.model_validations.validation_id IS 'Unique identifier for the model validation.';
COMMENT ON COLUMN model_risk.model_validations.model_id IS 'Foreign key referencing the validated model.';
COMMENT ON COLUMN model_risk.model_validations.validation_date IS 'Date of the model validation.';
COMMENT ON COLUMN model_risk.model_validations.validator_user_id IS 'User who performed the validation.';
COMMENT ON COLUMN model_risk.model_validations.validation_result IS 'Result of the validation.';
COMMENT ON COLUMN model_risk.model_validations.findings IS 'Findings from the validation.';
COMMENT ON COLUMN model_risk.model_validations.recommendations IS 'Recommendations from the validation.';
COMMENT ON COLUMN model_risk.model_validations.created_at IS 'Timestamp when the validation record was created.';
COMMENT ON COLUMN model_risk.model_validations.updated_at IS 'Timestamp when the validation record was last updated.';

-- Trigger for model_risk.model_validations table
CREATE TRIGGER update_model_validations_updated_at
BEFORE UPDATE ON model_risk.model_validations
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: model_risk.vw_model_validation_status
-- Description: Provides an overview of models and their latest validation status.
CREATE OR REPLACE VIEW model_risk.vw_model_validation_status AS
SELECT
    m.model_id,
    m.model_name,
    m.model_type,
    m.status,
    m.last_validation_date,
    m.next_validation_due_date,
    mv.validation_result AS latest_validation_result,
    u.username AS owner_username
FROM
    model_risk.models m
LEFT JOIN LATERAL (
    SELECT *
    FROM model_risk.model_validations
    WHERE model_id = m.model_id
    ORDER BY validation_date DESC
    LIMIT 1
) mv ON TRUE
LEFT JOIN
    core.users u ON m.owner_user_id = u.user_id;

COMMENT ON VIEW model_risk.vw_model_validation_status IS 'Provides an overview of models and their latest validation status.';

-- Stored Procedure: model_risk.sp_record_model_validation
-- Description: Records a new model validation result.
CREATE OR REPLACE PROCEDURE model_risk.sp_record_model_validation(
    p_model_id UUID,
    p_validation_date DATE,
    p_validator_user_id UUID,
    p_validation_result VARCHAR,
    p_findings TEXT,
    p_recommendations TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO model_risk.model_validations (model_id, validation_date, validator_user_id, validation_result, findings, recommendations)
    VALUES (p_model_id, p_validation_date, p_validator_user_id, p_validation_result, p_findings, p_recommendations);

    -- Update the model\'s last validation date and status
    UPDATE model_risk.models
    SET
        last_validation_date = p_validation_date,
        status = CASE WHEN p_validation_result = 'Pass' THEN 'Approved' ELSE 'Under Review' END,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        model_id = p_model_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_validator_user_id,
        'MODEL_RISK_GOVERNANCE',
        'Model Risk Governance',
        'record_model_validation',
        'model_validation',
        p_model_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('model_id', p_model_id, 'validation_result', p_validation_result),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE model_risk.sp_record_model_validation(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new model validation result.';

-- Create operational_risk schema
CREATE SCHEMA IF NOT EXISTS operational_risk;

-- Set search path for operational_risk schema
SET search_path TO operational_risk, public;

-- Table: operational_risk.operational_risks
-- Description: Stores identified operational risks.
CREATE TABLE operational_risk.operational_risks (
    risk_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100), -- e.g., Process, People, Systems, External Events
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    likelihood VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    impact VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    mitigation_plan TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, Mitigated, Closed
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.operational_risks IS 'Stores identified operational risks.';
COMMENT ON COLUMN operational_risk.operational_risks.risk_id IS 'Unique identifier for the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.risk_name IS 'Name of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.description IS 'Description of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.category IS 'Category of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.severity IS 'Severity of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.likelihood IS 'Likelihood of the operational risk occurring.';
COMMENT ON COLUMN operational_risk.operational_risks.impact IS 'Impact of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.mitigation_plan IS 'Plan to mitigate the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.status IS 'Current status of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.owner_user_id IS 'User responsible for the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.created_at IS 'Timestamp when the operational risk was created.';
COMMENT ON COLUMN operational_risk.operational_risks.updated_at IS 'Timestamp when the operational risk was last updated.';

-- Trigger for operational_risk.operational_risks table
CREATE TRIGGER update_operational_risks_updated_at
BEFORE UPDATE ON operational_risk.operational_risks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: operational_risk.risk_events
-- Description: Records actual operational risk events (incidents).
CREATE TABLE operational_risk.risk_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_id UUID REFERENCES operational_risk.operational_risks(risk_id) ON DELETE SET NULL,
    event_name VARCHAR(255) NOT NULL,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    impact_description TEXT,
    financial_impact DECIMAL(18, 2),
    status VARCHAR(50) NOT NULL, -- e.g., Reported, Under Investigation, Closed
    root_cause TEXT,
    lessons_learned TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.risk_events IS 'Records actual operational risk events (incidents).';
COMMENT ON COLUMN operational_risk.risk_events.event_id IS 'Unique identifier for the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.risk_id IS 'Foreign key referencing the related operational risk.';
COMMENT ON COLUMN operational_risk.risk_events.event_name IS 'Name or title of the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.description IS 'Description of the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.event_date IS 'Date and time the event occurred.';
COMMENT ON COLUMN operational_risk.risk_events.discovery_date IS 'Date and time the event was discovered.';
COMMENT ON COLUMN operational_risk.risk_events.impact_description IS 'Description of the impact of the event.';
COMMENT ON COLUMN operational_risk.risk_events.financial_impact IS 'Financial impact of the event.';
COMMENT ON COLUMN operational_risk.risk_events.status IS 'Current status of the event.';
COMMENT ON COLUMN operational_risk.risk_events.root_cause IS 'Root cause of the event.';
COMMENT ON COLUMN operational_risk.risk_events.lessons_learned IS 'Lessons learned from the event.';
COMMENT ON COLUMN operational_risk.risk_events.reported_by IS 'User who reported the event.';
COMMENT ON COLUMN operational_risk.risk_events.created_at IS 'Timestamp when the event record was created.';
COMMENT ON COLUMN operational_risk.risk_events.updated_at IS 'Timestamp when the event record was last updated.';

-- Trigger for operational_risk.risk_events table
CREATE TRIGGER update_risk_events_updated_at
BEFORE UPDATE ON operational_risk.risk_events
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: operational_risk.vw_operational_risk_register
-- Description: Displays the current operational risk register.
CREATE OR REPLACE VIEW operational_risk.vw_operational_risk_register AS
SELECT
    risk_id,
    risk_name,
    description,
    category,
    severity,
    likelihood,
    impact,
    mitigation_plan,
    status,
    u.username AS owner_username
FROM
    operational_risk.operational_risks ork
LEFT JOIN
    core.users u ON ork.owner_user_id = u.user_id;

COMMENT ON VIEW operational_risk.vw_operational_risk_register IS 'Displays the current operational risk register.';

-- View: operational_risk.vw_recent_risk_events
-- Description: Lists recent operational risk events.
CREATE OR REPLACE VIEW operational_risk.vw_recent_risk_events AS
SELECT
    re.event_id,
    re.event_name,
    re.event_date,
    re.status,
    re.financial_impact,
    ork.risk_name AS related_risk_name,
    u.username AS reported_by_username
FROM
    operational_risk.risk_events re
LEFT JOIN
    operational_risk.operational_risks ork ON re.risk_id = ork.risk_id
LEFT JOIN
    core.users u ON re.reported_by = u.user_id
ORDER BY
    re.event_date DESC
LIMIT 100;

COMMENT ON VIEW operational_risk.vw_recent_risk_events IS 'Lists recent operational risk events.';

-- Stored Procedure: operational_risk.sp_record_risk_event
-- Description: Records a new operational risk event.
CREATE OR REPLACE PROCEDURE operational_risk.sp_record_risk_event(
    p_risk_id UUID,
    p_event_name VARCHAR,
    p_description TEXT,
    p_event_date TIMESTAMP WITH TIME ZONE,
    p_discovery_date TIMESTAMP WITH TIME ZONE,
    p_impact_description TEXT,
    p_financial_impact DECIMAL,
    p_status VARCHAR,
    p_root_cause TEXT,
    p_lessons_learned TEXT,
    p_reported_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO operational_risk.risk_events (
        risk_id, event_name, description, event_date, discovery_date,
        impact_description, financial_impact, status, root_cause, lessons_learned, reported_by
    )
    VALUES (
        p_risk_id, p_event_name, p_description, p_event_date, p_discovery_date,
        p_impact_description, p_financial_impact, p_status, p_root_cause, p_lessons_learned, p_reported_by_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_reported_by_user_id,
        'OPERATIONAL_RISK_MANAGEMENT',
        'Operational Risk Management',
        'record_risk_event',
        'risk_event',
        p_risk_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('event_name', p_event_name, 'status', p_status, 'financial_impact', p_financial_impact),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_record_risk_event(UUID, VARCHAR, TEXT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, TEXT, DECIMAL, VARCHAR, TEXT, TEXT, UUID) IS 'Records a new operational risk event.';






-- Policy Management and Regulatory Compliance Management Schema



-- Policy Management and Regulatory Compliance Management Schema



-- Create policy_management schema
CREATE SCHEMA IF NOT EXISTS policy_management;

-- Set search path for policy_management schema
SET search_path TO policy_management, public;

-- Table: policy_management.policies
-- Description: Stores organizational policies.
CREATE TABLE policy_management.policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    category VARCHAR(100), -- e.g., HR, IT, Risk, Compliance
    effective_date DATE,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_due_at DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE policy_management.policies IS 'Stores organizational policies.';
COMMENT ON COLUMN policy_management.policies.policy_id IS 'Unique identifier for the policy.';
COMMENT ON COLUMN policy_management.policies.policy_name IS 'Name of the policy.';
COMMENT ON COLUMN policy_management.policies.description IS 'Description of the policy.';
COMMENT ON COLUMN policy_management.policies.version IS 'Version of the policy.';
COMMENT ON COLUMN policy_management.policies.category IS 'Category of the policy.';
COMMENT ON COLUMN policy_management.policies.effective_date IS 'Date when the policy became effective.';
COMMENT ON COLUMN policy_management.policies.last_reviewed_at IS 'Timestamp of the last review of the policy.';
COMMENT ON COLUMN policy_management.policies.next_review_due_at IS 'Date when the next review of the policy is due.';
COMMENT ON COLUMN policy_management.policies.owner_user_id IS 'User responsible for the policy.';
COMMENT ON COLUMN policy_management.policies.created_at IS 'Timestamp when the policy was created.';
COMMENT ON COLUMN policy_management.policies.updated_at IS 'Timestamp when the policy was last updated.';

-- Trigger for policy_management.policies table
CREATE TRIGGER update_policies_updated_at
BEFORE UPDATE ON policy_management.policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: policy_management.policy_acknowledgements
-- Description: Tracks user acknowledgements of policies.
CREATE TABLE policy_management.policy_acknowledgements (
    acknowledgement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID NOT NULL REFERENCES policy_management.policies(policy_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    acknowledgement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE policy_management.policy_acknowledgements IS 'Tracks user acknowledgements of policies.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.acknowledgement_id IS 'Unique identifier for the acknowledgement.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.policy_id IS 'Foreign key referencing the acknowledged policy.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.user_id IS 'Foreign key referencing the user who acknowledged the policy.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.acknowledgement_date IS 'Timestamp when the policy was acknowledged.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.created_at IS 'Timestamp when the acknowledgement record was created.';

-- View: policy_management.vw_policy_compliance_status
-- Description: Provides an overview of policies and their acknowledgement status by users.
CREATE OR REPLACE VIEW policy_management.vw_policy_compliance_status AS
SELECT
    p.policy_id,
    p.policy_name,
    p.version,
    p.effective_date,
    p.next_review_due_at,
    COUNT(DISTINCT pa.user_id) AS acknowledged_users_count,
    (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE) AS total_active_users,
    (COUNT(DISTINCT pa.user_id)::DECIMAL / (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE)) * 100 AS compliance_percentage
FROM
    policy_management.policies p
LEFT JOIN
    policy_management.policy_acknowledgements pa ON p.policy_id = pa.policy_id
GROUP BY
    p.policy_id, p.policy_name, p.version, p.effective_date, p.next_review_due_at;

COMMENT ON VIEW policy_management.vw_policy_compliance_status IS 'Provides an overview of policies and their acknowledgement status by users.';

-- Stored Procedure: policy_management.sp_acknowledge_policy
-- Description: Records a user acknowledging a policy.
CREATE OR REPLACE PROCEDURE policy_management.sp_acknowledge_policy(
    p_policy_id UUID,
    p_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO policy_management.policy_acknowledgements (policy_id, user_id)
    VALUES (p_policy_id, p_user_id)
    ON CONFLICT (policy_id, user_id) DO NOTHING; -- Prevent duplicate acknowledgements

    -- Log the action
    CALL core.sp_log_audit_event(
        p_user_id,
        'POLICY_MANAGEMENT',
        'Policy Management',
        'acknowledge_policy',
        'policy',
        p_policy_id,
        NULL, NULL, NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_acknowledge_policy(UUID, UUID) IS 'Records a user acknowledging a policy.';

-- Create regulatory_compliance schema
CREATE SCHEMA IF NOT EXISTS regulatory_compliance;

-- Set search path for regulatory_compliance schema
SET search_path TO regulatory_compliance, public;

-- Table: regulatory_compliance.regulations
-- Description: Stores details of applicable regulations (e.g., GDPR, FIPPA, SOX).
CREATE TABLE regulatory_compliance.regulations (
    regulation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    jurisdiction VARCHAR(100), -- e.g., EU, Canada, US
    effective_date DATE,
    last_updated_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.regulations IS 'Stores details of applicable regulations.';
COMMENT ON COLUMN regulatory_compliance.regulations.regulation_id IS 'Unique identifier for the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.regulation_name IS 'Name of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.description IS 'Description of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.jurisdiction IS 'Jurisdiction of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.effective_date IS 'Date when the regulation became effective.';
COMMENT ON COLUMN regulatory_compliance.regulations.last_updated_date IS 'Date when the regulation was last updated.';
COMMENT ON COLUMN regulatory_compliance.regulations.created_at IS 'Timestamp when the regulation record was created.';
COMMENT ON COLUMN regulatory_compliance.regulations.updated_at IS 'Timestamp when the regulation record was last updated.';

-- Trigger for regulatory_compliance.regulations table
CREATE TRIGGER update_regulations_updated_at
BEFORE UPDATE ON regulatory_compliance.regulations
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: regulatory_compliance.compliance_controls
-- Description: Maps internal controls to specific regulatory requirements.
CREATE TABLE regulatory_compliance.compliance_controls (
    control_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    control_name VARCHAR(255) NOT NULL,
    description TEXT,
    control_type VARCHAR(100), -- e.g., Technical, Administrative, Physical
    status VARCHAR(50) NOT NULL, -- e.g., Implemented, In Progress, Not Applicable
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (regulation_id, control_name)
);

COMMENT ON TABLE regulatory_compliance.compliance_controls IS 'Maps internal controls to specific regulatory requirements.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.control_id IS 'Unique identifier for the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.regulation_id IS 'Foreign key referencing the related regulation.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.control_name IS 'Name of the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.description IS 'Description of the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.control_type IS 'Type of control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.status IS 'Current status of the control implementation.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.owner_user_id IS 'User responsible for the control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.created_at IS 'Timestamp when the control record was created.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.updated_at IS 'Timestamp when the control record was last updated.';

-- Trigger for regulatory_compliance.compliance_controls table
CREATE TRIGGER update_compliance_controls_updated_at
BEFORE UPDATE ON regulatory_compliance.compliance_controls
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: regulatory_compliance.compliance_assessments
-- Description: Records results of compliance assessments against regulations.
CREATE TABLE regulatory_compliance.compliance_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    overall_result VARCHAR(50) NOT NULL, -- e.g., Compliant, Partially Compliant, Non-Compliant
    findings TEXT,
    remediation_plan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.compliance_assessments IS 'Records results of compliance assessments against regulations.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessment_id IS 'Unique identifier for the compliance assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.regulation_id IS 'Foreign key referencing the assessed regulation.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.overall_result IS 'Overall result of the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.remediation_plan IS 'Plan for remediating non-compliance.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for regulatory_compliance.compliance_assessments table
CREATE TRIGGER update_compliance_assessments_updated_at
BEFORE UPDATE ON regulatory_compliance.compliance_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: regulatory_compliance.vw_regulation_compliance_summary
-- Description: Provides a summary of compliance status for each regulation.
CREATE OR REPLACE VIEW regulatory_compliance.vw_regulation_compliance_summary AS
SELECT
    r.regulation_name,
    r.jurisdiction,
    r.effective_date,
    ca.assessment_date AS last_assessment_date,
    ca.overall_result AS last_assessment_result,
    COUNT(cc.control_id) AS total_controls,
    COUNT(CASE WHEN cc.status = 'Implemented' THEN 1 END) AS implemented_controls,
    (COUNT(CASE WHEN cc.status = 'Implemented' THEN 1 END)::DECIMAL / COUNT(cc.control_id)) * 100 AS implementation_percentage
FROM
    regulatory_compliance.regulations r
LEFT JOIN LATERAL (
    SELECT *
    FROM regulatory_compliance.compliance_assessments
    WHERE regulation_id = r.regulation_id
    ORDER BY assessment_date DESC
    LIMIT 1
) ca ON TRUE
LEFT JOIN
    regulatory_compliance.compliance_controls cc ON r.regulation_id = cc.regulation_id
GROUP BY
    r.regulation_id, r.regulation_name, r.jurisdiction, r.effective_date, ca.assessment_date, ca.overall_result;

COMMENT ON VIEW regulatory_compliance.vw_regulation_compliance_summary IS 'Provides a summary of compliance status for each regulation.';

-- Stored Procedure: regulatory_compliance.sp_record_compliance_assessment
-- Description: Records a new compliance assessment result.
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_record_compliance_assessment(
    p_regulation_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_overall_result VARCHAR,
    p_findings TEXT,
    p_remediation_plan TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO regulatory_compliance.compliance_assessments (regulation_id, assessment_date, assessor_user_id, overall_result, findings, remediation_plan)
    VALUES (p_regulation_id, p_assessment_date, p_assessor_user_id, p_overall_result, p_findings, p_remediation_plan);

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'REGULATORY_COMPLIANCE',
        'Regulatory Compliance Management',
        'record_compliance_assessment',
        'compliance_assessment',
        p_regulation_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('regulation_id', p_regulation_id, 'overall_result', p_overall_result),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_record_compliance_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new compliance assessment result.';






-- Third-Party Risk Management Schema



-- Third-Party Risk Management Schema



-- Create third_party_risk schema
CREATE SCHEMA IF NOT EXISTS third_party_risk;

-- Set search path for third_party_risk schema
SET search_path TO third_party_risk, public;

-- Table: third_party_risk.third_parties
-- Description: Stores details of third-party vendors or partners.
CREATE TABLE third_party_risk.third_parties (
    third_party_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) UNIQUE NOT NULL,
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    service_provided TEXT,
    risk_rating VARCHAR(50), -- e.g., High, Medium, Low
    status VARCHAR(50) NOT NULL, -- e.g., Active, Inactive, Under Review
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE third_party_risk.third_parties IS 'Stores details of third-party vendors or partners.';
COMMENT ON COLUMN third_party_risk.third_parties.third_party_id IS 'Unique identifier for the third party.';
COMMENT ON COLUMN third_party_risk.third_parties.company_name IS 'Name of the third-party company.';
COMMENT ON COLUMN third_party_risk.third_parties.contact_person IS 'Main contact person at the third party.';
COMMENT ON COLUMN third_party_risk.third_parties.contact_email IS 'Contact email for the third party.';
COMMENT ON COLUMN third_party_risk.third_parties.service_provided IS 'Description of the service provided by the third party.';
COMMENT ON COLUMN third_party_risk.third_parties.risk_rating IS 'Assessed risk rating of the third party.';
COMMENT ON COLUMN third_party_risk.third_parties.status IS 'Current status of the third-party relationship.';
COMMENT ON COLUMN third_party_risk.third_parties.created_at IS 'Timestamp when the third-party record was created.';
COMMENT ON COLUMN third_party_risk.third_parties.updated_at IS 'Timestamp when the third-party record was last updated.';

-- Trigger for third_party_risk.third_parties table
CREATE TRIGGER update_third_parties_updated_at
BEFORE UPDATE ON third_party_risk.third_parties
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: third_party_risk.risk_assessments
-- Description: Records risk assessments conducted for third parties.
CREATE TABLE third_party_risk.risk_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    third_party_id UUID NOT NULL REFERENCES third_party_risk.third_parties(third_party_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    overall_score DECIMAL(5, 2),
    findings TEXT,
    recommendations TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Completed, In Progress, Pending
    next_assessment_due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE third_party_risk.risk_assessments IS 'Records risk assessments conducted for third parties.';
COMMENT ON COLUMN third_party_risk.risk_assessments.assessment_id IS 'Unique identifier for the risk assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.third_party_id IS 'Foreign key referencing the assessed third party.';
COMMENT ON COLUMN third_party_risk.risk_assessments.assessment_date IS 'Date the assessment was conducted.';
COMMENT ON COLUMN third_party_risk.risk_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.overall_score IS 'Overall risk score from the assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.findings IS 'Findings from the risk assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.recommendations IS 'Recommendations from the risk assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.status IS 'Current status of the assessment.';
COMMENT ON COLUMN third_party_risk.risk_assessments.next_assessment_due_date IS 'Date when the next assessment is due.';
COMMENT ON COLUMN third_party_risk.risk_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN third_party_risk.risk_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for third_party_risk.risk_assessments table
CREATE TRIGGER update_risk_assessments_updated_at
BEFORE UPDATE ON third_party_risk.risk_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: third_party_risk.vw_third_party_risk_overview
-- Description: Provides an overview of third parties and their risk assessment status.
CREATE OR REPLACE VIEW third_party_risk.vw_third_party_risk_overview AS
SELECT
    tp.third_party_id,
    tp.company_name,
    tp.service_provided,
    tp.risk_rating,
    tp.status,
    ra.assessment_date AS last_assessment_date,
    ra.overall_score AS last_assessment_score,
    ra.status AS last_assessment_status,
    ra.next_assessment_due_date
FROM
    third_party_risk.third_parties tp
LEFT JOIN LATERAL (
    SELECT *
    FROM third_party_risk.risk_assessments
    WHERE third_party_id = tp.third_party_id
    ORDER BY assessment_date DESC
    LIMIT 1
) ra ON TRUE;

COMMENT ON VIEW third_party_risk.vw_third_party_risk_overview IS 'Provides an overview of third parties and their risk assessment status.';

-- Stored Procedure: third_party_risk.sp_record_risk_assessment
-- Description: Records a new risk assessment for a third party.
CREATE OR REPLACE PROCEDURE third_party_risk.sp_record_risk_assessment(
    p_third_party_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_overall_score DECIMAL,
    p_findings TEXT,
    p_recommendations TEXT,
    p_status VARCHAR,
    p_next_assessment_due_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO third_party_risk.risk_assessments (
        third_party_id, assessment_date, assessor_user_id, overall_score,
        findings, recommendations, status, next_assessment_due_date
    )
    VALUES (
        p_third_party_id, p_assessment_date, p_assessor_user_id, p_overall_score,
        p_findings, p_recommendations, p_status, p_next_assessment_due_date
    );

    -- Update the third party\'s risk rating based on the latest assessment
    UPDATE third_party_risk.third_parties
    SET
        risk_rating = CASE
            WHEN p_overall_score >= 80 THEN 'Low'
            WHEN p_overall_score >= 50 THEN 'Medium'
            ELSE 'High'
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        third_party_id = p_third_party_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'THIRD_PARTY_RISK_MANAGEMENT',
        'Third-Party Risk Management',
        'record_risk_assessment',
        'third_party_risk_assessment',
        p_third_party_id,
        NULL, -- Old value not captured for this example
        jsonb_build_object('assessment_id', (SELECT currval('third_party_risk.risk_assessments_assessment_id_seq')), 'overall_score', p_overall_score, 'status', p_status),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE third_party_risk.sp_record_risk_assessment(UUID, DATE, UUID, DECIMAL, TEXT, TEXT, VARCHAR, DATE) IS 'Records a new risk assessment for a third party.';






-- ActivityPub and SOX2 Compliance Elements



-- Internal Audit Management and IT Governance Schema



-- Create internal_audit schema
CREATE SCHEMA IF NOT EXISTS internal_audit;

-- Set search path for internal_audit schema
SET search_path TO internal_audit, public;

-- Table: internal_audit.audit_engagements
-- Description: Stores details of internal audit engagements.
CREATE TABLE internal_audit.audit_engagements (
    engagement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    engagement_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(50) NOT NULL, -- e.g., Planned, In Progress, Completed, Canceled
    lead_auditor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_engagements IS 'Stores details of internal audit engagements.';
COMMENT ON COLUMN internal_audit.audit_engagements.engagement_id IS 'Unique identifier for the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.engagement_name IS 'Name of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.description IS 'Description of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.start_date IS 'Start date of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.end_date IS 'End date of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.status IS 'Current status of the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.lead_auditor_user_id IS 'User ID of the lead auditor for the engagement.';
COMMENT ON COLUMN internal_audit.audit_engagements.created_at IS 'Timestamp when the engagement record was created.';
COMMENT ON COLUMN internal_audit.audit_engagements.updated_at IS 'Timestamp when the engagement record was last updated.';

-- Trigger for internal_audit.audit_engagements table
CREATE TRIGGER update_audit_engagements_updated_at
BEFORE UPDATE ON internal_audit.audit_engagements
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: internal_audit.audit_findings
-- Description: Records findings from internal audit engagements.
CREATE TABLE internal_audit.audit_findings (
    finding_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    engagement_id UUID NOT NULL REFERENCES internal_audit.audit_engagements(engagement_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    recommendation TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Closed, Verified
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    due_date DATE,
    closed_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_findings IS 'Records findings from internal audit engagements.';
COMMENT ON COLUMN internal_audit.audit_findings.finding_id IS 'Unique identifier for the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.engagement_id IS 'Foreign key referencing the audit engagement.';
COMMENT ON COLUMN internal_audit.audit_findings.title IS 'Title of the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.description IS 'Description of the audit finding.';
COMMENT ON COLUMN internal_audit.audit_findings.severity IS 'Severity level of the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.recommendation IS 'Recommended action to address the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.status IS 'Current status of the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.responsible_user_id IS 'User responsible for addressing the finding.';
COMMENT ON COLUMN internal_audit.audit_findings.due_date IS 'Due date for remediation.';
COMMENT ON COLUMN internal_audit.audit_findings.closed_date IS 'Date the finding was closed.';
COMMENT ON COLUMN internal_audit.audit_findings.created_at IS 'Timestamp when the finding record was created.';
COMMENT ON COLUMN internal_audit.audit_findings.updated_at IS 'Timestamp when the finding record was last updated.';

-- Trigger for internal_audit.audit_findings table
CREATE TRIGGER update_audit_findings_updated_at
BEFORE UPDATE ON internal_audit.audit_findings
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: internal_audit.vw_open_audit_findings
-- Description: Lists all open audit findings with their details and responsible parties.
CREATE OR REPLACE VIEW internal_audit.vw_open_audit_findings AS
SELECT
    af.finding_id,
    ae.engagement_name,
    af.title,
    af.description,
    af.severity,
    af.recommendation,
    af.status,
    u.username AS responsible_username,
    af.due_date
FROM
    internal_audit.audit_findings af
JOIN
    internal_audit.audit_engagements ae ON af.engagement_id = ae.engagement_id
LEFT JOIN
    core.users u ON af.responsible_user_id = u.user_id
WHERE
    af.status IN (
        'Open',
        'In Progress'
    );

COMMENT ON VIEW internal_audit.vw_open_audit_findings IS 'Lists all open audit findings with their details and responsible parties.';

-- Stored Procedure: internal_audit.sp_update_finding_status
-- Description: Updates the status of an audit finding.
CREATE OR REPLACE PROCEDURE internal_audit.sp_update_finding_status(
    p_finding_id UUID,
    p_new_status VARCHAR,
    p_closed_date DATE DEFAULT NULL,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM internal_audit.audit_findings WHERE finding_id = p_finding_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'Audit Finding ID % not found.', p_finding_id;
    END IF;

    UPDATE internal_audit.audit_findings
    SET
        status = p_new_status,
        closed_date = p_closed_date,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        finding_id = p_finding_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'INTERNAL_AUDIT',
        'Internal Audit Management',
        'update_finding_status',
        'audit_finding',
        p_finding_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'closed_date', p_closed_date),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_update_finding_status(UUID, VARCHAR, DATE, UUID) IS 'Updates the status of an audit finding.';

-- Create it_governance schema
CREATE SCHEMA IF NOT EXISTS it_governance;

-- Set search path for it_governance schema
SET search_path TO it_governance, public;

-- Table: it_governance.it_policies
-- Description: Stores IT policies and standards.
CREATE TABLE it_governance.it_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    category VARCHAR(100), -- e.g., Security, Data Management, Acceptable Use
    effective_date DATE,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_due_at DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_policies IS 'Stores IT policies and standards.';
COMMENT ON COLUMN it_governance.it_policies.policy_id IS 'Unique identifier for the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.policy_name IS 'Name of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.description IS 'Description of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.version IS 'Version of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.category IS 'Category of the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.effective_date IS 'Date when the policy became effective.';
COMMENT ON COLUMN it_governance.it_policies.last_reviewed_at IS 'Timestamp of the last review of the policy.';
COMMENT ON COLUMN it_governance.it_policies.next_review_due_at IS 'Date when the next review of the policy is due.';
COMMENT ON COLUMN it_governance.it_policies.owner_user_id IS 'User responsible for the IT policy.';
COMMENT ON COLUMN it_governance.it_policies.created_at IS 'Timestamp when the IT policy was created.';
COMMENT ON COLUMN it_governance.it_policies.updated_at IS 'Timestamp when the IT policy was last updated.';

-- Trigger for it_governance.it_policies table
CREATE TRIGGER update_it_policies_updated_at
BEFORE UPDATE ON it_governance.it_policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: it_governance.it_risks
-- Description: Records IT-related risks.
CREATE TABLE it_governance.it_risks (
    risk_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    likelihood VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    impact VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    mitigation_plan TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, Mitigated, Closed
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_risks IS 'Records IT-related risks.';
COMMENT ON COLUMN it_governance.it_risks.risk_id IS 'Unique identifier for the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.risk_name IS 'Name of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.description IS 'Description of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.severity IS 'Severity of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.likelihood IS 'Likelihood of the IT risk occurring.';
COMMENT ON COLUMN it_governance.it_risks.impact IS 'Impact of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.mitigation_plan IS 'Plan to mitigate the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.status IS 'Current status of the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.owner_user_id IS 'User responsible for the IT risk.';
COMMENT ON COLUMN it_governance.it_risks.created_at IS 'Timestamp when the IT risk was created.';
COMMENT ON COLUMN it_governance.it_risks.updated_at IS 'Timestamp when the IT risk was last updated.';

-- Trigger for it_governance.it_risks table
CREATE TRIGGER update_it_risks_updated_at
BEFORE UPDATE ON it_governance.it_risks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: it_governance.vw_it_policy_compliance
-- Description: Provides an overview of IT policies and their review status.
CREATE OR REPLACE VIEW it_governance.vw_it_policy_compliance AS
SELECT
    policy_id,
    policy_name,
    category,
    version,
    effective_date,
    last_reviewed_at,
    next_review_due_at,
    u.username AS owner_username
FROM
    it_governance.it_policies ip
LEFT JOIN
    core.users u ON ip.owner_user_id = u.user_id;

COMMENT ON VIEW it_governance.vw_it_policy_compliance IS 'Provides an overview of IT policies and their review status.';

-- View: it_governance.vw_it_risk_register
-- Description: Displays the current IT risk register.
CREATE OR REPLACE VIEW it_governance.vw_it_risk_register AS
SELECT
    risk_id,
    risk_name,
    description,
    severity,
    likelihood,
    impact,
    mitigation_plan,
    status,
    u.username AS owner_username
FROM
    it_governance.it_risks ir
LEFT JOIN
    core.users u ON ir.owner_user_id = u.user_id;

COMMENT ON VIEW it_governance.vw_it_risk_register IS 'Displays the current IT risk register.';

-- Stored Procedure: it_governance.sp_update_it_risk_status
-- Description: Updates the status of an IT risk.
CREATE OR REPLACE PROCEDURE it_governance.sp_update_it_risk_status(
    p_risk_id UUID,
    p_new_status VARCHAR,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM it_governance.it_risks WHERE risk_id = p_risk_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'IT Risk ID % not found.', p_risk_id;
    END IF;

    UPDATE it_governance.it_risks
    SET
        status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        risk_id = p_risk_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'IT_GOVERNANCE',
        'IT Governance',
        'update_risk_status',
        'it_risk',
        p_risk_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status),
        NULL, NULL, NULL,
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE it_governance.sp_update_it_risk_status(UUID, VARCHAR, UUID) IS 'Updates the status of an IT risk.';


-- ENHANCEMENTS FOR INTERNAL AUDIT MANAGEMENT AND IT GOVERNANCE SCHEMA

-- Table: internal_audit.audit_recommendation_tracking
-- Description: Tracks the implementation status of audit recommendations.
CREATE TABLE internal_audit.audit_recommendation_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    finding_id UUID NOT NULL REFERENCES internal_audit.audit_findings(finding_id) ON DELETE CASCADE,
    action_item TEXT NOT NULL,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    due_date DATE,
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Completed, Verified
    completion_date DATE,
    verified_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_recommendation_tracking IS 'Tracks the implementation status of audit recommendations.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.tracking_id IS 'Unique identifier for the recommendation tracking record.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.finding_id IS 'Foreign key referencing the audit finding.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.action_item IS 'Specific action item for remediation.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.responsible_user_id IS 'User responsible for implementing the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.due_date IS 'Due date for the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.status IS 'Current status of the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.completion_date IS 'Date the action item was completed.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.verified_by IS 'User who verified the completion of the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.created_at IS 'Timestamp when the tracking record was created.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.updated_at IS 'Timestamp when the tracking record was last updated.';

-- Trigger for internal_audit.audit_recommendation_tracking table
CREATE TRIGGER update_audit_recommendation_tracking_updated_at
BEFORE UPDATE ON internal_audit.audit_recommendation_tracking
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: internal_audit.vw_audit_recommendation_status
-- Description: Provides a consolidated view of audit findings and their recommendation tracking status.
CREATE OR REPLACE VIEW internal_audit.vw_audit_recommendation_status AS
SELECT
    af.finding_id,
    af.title AS finding_title,
    af.severity AS finding_severity,
    af.status AS finding_status,
    art.action_item,
    art.status AS recommendation_status,
    art.due_date AS recommendation_due_date,
    u.username AS responsible_for_recommendation
FROM
    internal_audit.audit_findings af
LEFT JOIN
    internal_audit.audit_recommendation_tracking art ON af.finding_id = art.finding_id
LEFT JOIN
    core.users u ON art.responsible_user_id = u.user_id;

COMMENT ON VIEW internal_audit.vw_audit_recommendation_status IS 'Provides a consolidated view of audit findings and their recommendation tracking status.';

-- Stored Procedure: internal_audit.sp_add_audit_recommendation
-- Description: Adds a new recommendation action item for an audit finding.
CREATE OR REPLACE PROCEDURE internal_audit.sp_add_audit_recommendation(
    p_finding_id UUID,
    p_action_item TEXT,
    p_responsible_user_id UUID,
    p_due_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO internal_audit.audit_recommendation_tracking (
        finding_id, action_item, responsible_user_id, due_date, status
    )
    VALUES (
        p_finding_id, p_action_item, p_responsible_user_id, p_due_date, 'Open'
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_responsible_user_id,
        'INTERNAL_AUDIT',
        'Internal Audit Management',
        'add_audit_recommendation',
        'audit_recommendation_tracking',
        p_finding_id,
        NULL, jsonb_build_object('action_item', p_action_item, 'due_date', p_due_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_add_audit_recommendation(UUID, TEXT, UUID, DATE) IS 'Adds a new recommendation action item for an audit finding.';

-- Materialized View: internal_audit.mv_audit_engagement_summary
-- Description: Summarizes audit engagement statuses and finding counts.
CREATE MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary AS
SELECT
    ae.engagement_id,
    ae.engagement_name,
    ae.status AS engagement_status,
    COUNT(af.finding_id) AS total_findings,
    COUNT(CASE WHEN af.status IN ('Open', 'In Progress') THEN 1 END) AS open_findings_count,
    COUNT(CASE WHEN af.status = 'Closed' THEN 1 END) AS closed_findings_count
FROM
    internal_audit.audit_engagements ae
LEFT JOIN
    internal_audit.audit_findings af ON ae.engagement_id = af.engagement_id
GROUP BY
    ae.engagement_id, ae.engagement_name, ae.status;

COMMENT ON MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary IS 'Summarizes audit engagement statuses and finding counts.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE internal_audit.sp_refresh_mv_audit_engagement_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary;
END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_refresh_mv_audit_engagement_summary() IS 'Refreshes the materialized view for audit engagement summary.';


-- ENHANCEMENTS FOR IT GOVERNANCE SCHEMA

-- Table: it_governance.it_control_assessments
-- Description: Records assessments of IT controls.
CREATE TABLE it_governance.it_control_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES it_governance.it_controls(control_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    result VARCHAR(50) NOT NULL, -- e.g., Compliant, Non-Compliant, Partially Compliant
    findings TEXT,
    remediation_plan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_control_assessments IS 'Records assessments of IT controls.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessment_id IS 'Unique identifier for the IT control assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.control_id IS 'Foreign key referencing the IT control assessed.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.result IS 'Result of the control assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.remediation_plan IS 'Plan for remediating any non-compliance.';
COMMENT ON COLUMN it_governance.it_control_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN it_governance.it_control_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for it_governance.it_control_assessments table
CREATE TRIGGER update_it_control_assessments_updated_at
BEFORE UPDATE ON it_governance.it_control_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: it_governance.vw_it_control_compliance_summary
-- Description: Summarizes the compliance status of IT controls.
CREATE OR REPLACE VIEW it_governance.vw_it_control_compliance_summary AS
SELECT
    ic.control_id,
    ic.control_name,
    ic.category,
    ica.assessment_date AS last_assessment_date,
    ica.result AS last_assessment_result,
    ica.findings AS last_assessment_findings
FROM
    it_governance.it_controls ic
LEFT JOIN LATERAL (
    SELECT *
    FROM it_governance.it_control_assessments
    WHERE control_id = ic.control_id
    ORDER BY assessment_date DESC
    LIMIT 1
) ica ON TRUE;

COMMENT ON VIEW it_governance.vw_it_control_compliance_summary IS 'Summarizes the compliance status of IT controls.';

-- Stored Procedure: it_governance.sp_record_it_control_assessment
-- Description: Records a new IT control assessment result.
CREATE OR REPLACE PROCEDURE it_governance.sp_record_it_control_assessment(
    p_control_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_result VARCHAR,
    p_findings TEXT,
    p_remediation_plan TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO it_governance.it_control_assessments (
        control_id, assessment_date, assessor_user_id, result, findings, remediation_plan
    )
    VALUES (
        p_control_id, p_assessment_date, p_assessor_user_id, p_result, p_findings, p_remediation_plan
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'IT_GOVERNANCE',
        'IT Governance',
        'record_it_control_assessment',
        'it_control_assessment',
        p_control_id,
        NULL, jsonb_build_object('result', p_result, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE it_governance.sp_record_it_control_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new IT control assessment result.';

-- Materialized View: it_governance.mv_it_risk_and_compliance_overview
-- Description: Provides a consolidated overview of IT risks and control compliance.
CREATE MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview AS
SELECT
    (SELECT COUNT(*) FROM it_governance.it_risks WHERE status = 'Open') AS open_it_risks_count,
    (SELECT COUNT(*) FROM it_governance.it_policies WHERE next_review_due_at < CURRENT_DATE) AS overdue_it_policy_reviews_count,
    (SELECT COUNT(*) FROM it_governance.it_controls) AS total_it_controls,
    (SELECT COUNT(*) FROM it_governance.it_control_assessments WHERE result = 'Non-Compliant') AS non_compliant_it_controls_count;

COMMENT ON MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview IS 'Provides a consolidated overview of IT risks and control compliance.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE it_governance.sp_refresh_mv_it_risk_and_compliance_overview()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview;
END;
$$;

COMMENT ON PROCEDURE it_governance.sp_refresh_mv_it_risk_and_compliance_overview() IS 'Refreshes the materialized view for IT risk and compliance overview.';


-- ENHANCEMENTS FOR MODEL RISK GOVERNANCE SCHEMA

-- Table: model_risk.model_performance_metrics
-- Description: Stores performance metrics for models over time.
CREATE TABLE model_risk.model_performance_metrics (
    metric_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES model_risk.models(model_id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    metric_name VARCHAR(255) NOT NULL, -- e.g., Accuracy, Precision, Recall, F1-Score, AUC
    metric_value DECIMAL(18, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (model_id, metric_date, metric_name)
);

COMMENT ON TABLE model_risk.model_performance_metrics IS 'Stores performance metrics for models over time.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_record_id IS 'Unique identifier for the metric record.';
COMMENT ON COLUMN model_risk.model_performance_metrics.model_id IS 'Foreign key referencing the model.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_date IS 'Date the metric was recorded.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_name IS 'Name of the performance metric.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_value IS 'Value of the performance metric.';
COMMENT ON COLUMN model_risk.model_performance_metrics.created_at IS 'Timestamp when the record was created.';
COMMENT ON COLUMN model_risk.model_performance_metrics.updated_at IS 'Timestamp when the record was last updated.';

-- Trigger for model_risk.model_performance_metrics table
CREATE TRIGGER update_model_performance_metrics_updated_at
BEFORE UPDATE ON model_risk.model_performance_metrics
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: model_risk.vw_model_performance_summary
-- Description: Provides a summary of the latest performance metrics for each model.
CREATE OR REPLACE VIEW model_risk.vw_model_performance_summary AS
SELECT
    m.model_id,
    m.model_name,
    m.model_type,
    m.status,
    mpm.metric_name,
    mpm.metric_value AS latest_metric_value,
    mpm.metric_date AS latest_metric_date
FROM
    model_risk.models m
LEFT JOIN LATERAL (
    SELECT *
    FROM model_risk.model_performance_metrics
    WHERE model_id = m.model_id
    ORDER BY metric_date DESC
    LIMIT 1
) mpm ON TRUE;

COMMENT ON VIEW model_risk.vw_model_performance_summary IS 'Provides a summary of the latest performance metrics for each model.';

-- Stored Procedure: model_risk.sp_record_model_performance
-- Description: Records a new performance metric for a model.
CREATE OR REPLACE PROCEDURE model_risk.sp_record_model_performance(
    p_model_id UUID,
    p_metric_date DATE,
    p_metric_name VARCHAR,
    p_metric_value DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO model_risk.model_performance_metrics (
        model_id, metric_date, metric_name, metric_value
    )
    VALUES (
        p_model_id, p_metric_date, p_metric_name, p_metric_value
    )
    ON CONFLICT (model_id, metric_date, metric_name) DO UPDATE SET
        metric_value = EXCLUDED.metric_value,
        updated_at = CURRENT_TIMESTAMP;

    -- Log the action
    CALL core.sp_log_audit_event(
        NULL, -- Assuming system or automated process
        'MODEL_RISK_GOVERNANCE',
        'Model Risk Governance',
        'record_model_performance',
        'model_performance_metric',
        p_model_id,
        NULL, jsonb_build_object('metric_name', p_metric_name, 'metric_value', p_metric_value),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE model_risk.sp_record_model_performance(UUID, DATE, VARCHAR, DECIMAL) IS 'Records a new performance metric for a model.';

-- Materialized View: model_risk.mv_model_risk_dashboard
-- Description: Aggregates key metrics for the model risk dashboard.
CREATE MATERIALIZED VIEW model_risk.mv_model_risk_dashboard AS
SELECT
    (SELECT COUNT(*) FROM model_risk.models WHERE status = 'Approved') AS approved_models_count,
    (SELECT COUNT(*) FROM model_risk.models WHERE status = 'Under Review') AS models_under_review_count,
    (SELECT COUNT(*) FROM model_risk.models WHERE next_validation_due_date < CURRENT_DATE) AS overdue_validations_count,
    (SELECT COUNT(*) FROM model_risk.model_validations WHERE validation_result = 'Fail') AS failed_validations_count;

COMMENT ON MATERIALIZED VIEW model_risk.mv_model_risk_dashboard IS 'Aggregates key metrics for the model risk dashboard.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE model_risk.sp_refresh_mv_model_risk_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW model_risk.mv_model_risk_dashboard;
END;
$$;

COMMENT ON PROCEDURE model_risk.sp_refresh_mv_model_risk_dashboard() IS 'Refreshes the materialized view for model risk dashboard.';


-- ENHANCEMENTS FOR OPERATIONAL RISK MANAGEMENT SCHEMA

-- Table: operational_risk.control_effectiveness_assessments
-- Description: Records assessments of operational control effectiveness.
CREATE TABLE operational_risk.control_effectiveness_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES operational_risk.operational_controls(control_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    effectiveness_rating VARCHAR(50) NOT NULL, -- e.g., Effective, Partially Effective, Ineffective
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.control_effectiveness_assessments IS 'Records assessments of operational control effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessment_id IS 'Unique identifier for the control effectiveness assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.control_id IS 'Foreign key referencing the operational control assessed.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.effectiveness_rating IS 'Rating of the control''s effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.recommendations IS 'Recommendations for improving control effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for operational_risk.control_effectiveness_assessments table
CREATE TRIGGER update_control_effectiveness_assessments_updated_at
BEFORE UPDATE ON operational_risk.control_effectiveness_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: operational_risk.vw_control_effectiveness_summary
-- Description: Provides a summary of operational control effectiveness.
CREATE OR REPLACE VIEW operational_risk.vw_control_effectiveness_summary AS
SELECT
    oc.control_id,
    oc.control_name,
    oc.category,
    cea.assessment_date AS last_assessment_date,
    cea.effectiveness_rating AS last_effectiveness_rating,
    cea.findings AS last_assessment_findings
FROM
    operational_risk.operational_controls oc
LEFT JOIN LATERAL (
    SELECT *
    FROM operational_risk.control_effectiveness_assessments
    WHERE control_id = oc.control_id
    ORDER BY assessment_date DESC
    LIMIT 1
) cea ON TRUE;

COMMENT ON VIEW operational_risk.vw_control_effectiveness_summary IS 'Provides a summary of operational control effectiveness.';

-- Stored Procedure: operational_risk.sp_record_control_effectiveness_assessment
-- Description: Records a new operational control effectiveness assessment.
CREATE OR REPLACE PROCEDURE operational_risk.sp_record_control_effectiveness_assessment(
    p_control_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_effectiveness_rating VARCHAR,
    p_findings TEXT,
    p_recommendations TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO operational_risk.control_effectiveness_assessments (
        control_id, assessment_date, assessor_user_id, effectiveness_rating, findings, recommendations
    )
    VALUES (
        p_control_id, p_assessment_date, p_assessor_user_id, p_effectiveness_rating, p_findings, p_recommendations
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'OPERATIONAL_RISK_MANAGEMENT',
        'Operational Risk Management',
        'record_control_effectiveness_assessment',
        'control_effectiveness_assessment',
        p_control_id,
        NULL, jsonb_build_object('effectiveness_rating', p_effectiveness_rating, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_record_control_effectiveness_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new operational control effectiveness assessment.';

-- Materialized View: operational_risk.mv_operational_risk_dashboard
-- Description: Aggregates key metrics for the operational risk dashboard.
CREATE MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard AS
SELECT
    (SELECT COUNT(*) FROM operational_risk.operational_risks WHERE status = 'Open') AS open_operational_risks_count,
    (SELECT COUNT(*) FROM operational_risk.risk_events WHERE status = 'Reported') AS active_risk_events_count,
    (SELECT SUM(financial_impact) FROM operational_risk.risk_events WHERE status != 'Closed') AS total_unresolved_financial_impact,
    (SELECT COUNT(*) FROM operational_risk.operational_controls WHERE status = 'Ineffective') AS ineffective_controls_count;

COMMENT ON MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard IS 'Aggregates key metrics for the operational risk dashboard.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE operational_risk.sp_refresh_mv_operational_risk_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard;
END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_refresh_mv_operational_risk_dashboard() IS 'Refreshes the materialized view for operational risk dashboard.';


-- ENHANCEMENTS FOR POLICY MANAGEMENT SCHEMA

-- Table: policy_management.policy_versions
-- Description: Stores historical versions of policies.
CREATE TABLE policy_management.policy_versions (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID NOT NULL REFERENCES policy_management.policies(policy_id) ON DELETE CASCADE,
    version_number VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    effective_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (policy_id, version_number)
);

COMMENT ON TABLE policy_management.policy_versions IS 'Stores historical versions of policies.';
COMMENT ON COLUMN policy_management.policy_versions.version_id IS 'Unique identifier for the policy version.';
COMMENT ON COLUMN policy_management.policy_versions.policy_id IS 'Foreign key referencing the policy.';
COMMENT ON COLUMN policy_management.policy_versions.version_number IS 'Version number of the policy.';
COMMENT ON COLUMN policy_management.policy_versions.content IS 'Full content of the policy version.';
COMMENT ON COLUMN policy_management.policy_versions.effective_date IS 'Date when this version became effective.';
COMMENT ON COLUMN policy_management.policy_versions.created_at IS 'Timestamp when the version record was created.';

-- View: policy_management.vw_policy_version_history
-- Description: Provides a history of all versions for a given policy.
CREATE OR REPLACE VIEW policy_management.vw_policy_version_history AS
SELECT
    p.policy_name,
    pv.version_number,
    pv.effective_date,
    pv.content,
    pv.created_at AS version_created_at
FROM
    policy_management.policies p
JOIN
    policy_management.policy_versions pv ON p.policy_id = pv.policy_id
ORDER BY
    p.policy_name, pv.effective_date DESC;

COMMENT ON VIEW policy_management.vw_policy_version_history IS 'Provides a history of all versions for a given policy.';

-- Stored Procedure: policy_management.sp_publish_new_policy_version
-- Description: Publishes a new version of a policy, archiving the old one.
CREATE OR REPLACE PROCEDURE policy_management.sp_publish_new_policy_version(
    p_policy_id UUID,
    p_new_version_number VARCHAR,
    p_new_content TEXT,
    p_effective_date DATE,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_version_number VARCHAR;
    v_old_content TEXT;
BEGIN
    -- Archive current version
    SELECT version, description INTO v_old_version_number, v_old_content
    FROM policy_management.policies
    WHERE policy_id = p_policy_id;

    IF v_old_version_number IS NOT NULL THEN
        INSERT INTO policy_management.policy_versions (policy_id, version_number, content, effective_date)
        VALUES (p_policy_id, v_old_version_number, v_old_content, (SELECT effective_date FROM policy_management.policies WHERE policy_id = p_policy_id));
    END IF;

    -- Update policy with new version
    UPDATE policy_management.policies
    SET
        version = p_new_version_number,
        description = p_new_content, -- Assuming description holds the main content for simplicity
        effective_date = p_effective_date,
        last_reviewed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        policy_id = p_policy_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'POLICY_MANAGEMENT',
        'Policy Management',
        'publish_new_policy_version',
        'policy',
        p_policy_id,
        jsonb_build_object('version', v_old_version_number),
        jsonb_build_object('version', p_new_version_number, 'effective_date', p_effective_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_publish_new_policy_version(UUID, VARCHAR, TEXT, DATE, UUID) IS 'Publishes a new version of a policy, archiving the old one.';

-- Materialized View: policy_management.mv_policy_acknowledgement_summary
-- Description: Summarizes policy acknowledgement status across all active users.
CREATE MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary AS
SELECT
    p.policy_id,
    p.policy_name,
    p.version,
    COUNT(DISTINCT pa.user_id) AS acknowledged_users_count,
    (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE) AS total_active_users,
    ROUND((COUNT(DISTINCT pa.user_id)::NUMERIC / (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE)) * 100, 2) AS compliance_percentage
FROM
    policy_management.policies p
LEFT JOIN
    policy_management.policy_acknowledgements pa ON p.policy_id = pa.policy_id
GROUP BY
    p.policy_id, p.policy_name, p.version;

COMMENT ON MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary IS 'Summarizes policy acknowledgement status across all active users.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE policy_management.sp_refresh_mv_policy_acknowledgement_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary;
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_refresh_mv_policy_acknowledgement_summary() IS 'Refreshes the materialized view for policy acknowledgement summary.';


-- ENHANCEMENTS FOR REGULATORY COMPLIANCE MANAGEMENT SCHEMA

-- Table: regulatory_compliance.regulatory_updates
-- Description: Tracks updates and changes to regulations.
CREATE TABLE regulatory_compliance.regulatory_updates (
    update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    update_date DATE NOT NULL,
    description TEXT NOT NULL,
    impact_assessment TEXT,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.regulatory_updates IS 'Tracks updates and changes to regulations.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.update_id IS 'Unique identifier for the regulatory update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.regulation_id IS 'Foreign key referencing the regulation being updated.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.update_date IS 'Date of the regulatory update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.description IS 'Description of the update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.impact_assessment IS 'Assessment of the impact of the update on the organization.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.responsible_user_id IS 'User responsible for managing this update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.created_at IS 'Timestamp when the update record was created.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.updated_at IS 'Timestamp when the update record was last updated.';

-- Trigger for regulatory_compliance.regulatory_updates table
CREATE TRIGGER update_regulatory_updates_updated_at
BEFORE UPDATE ON regulatory_compliance.regulatory_updates
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: regulatory_compliance.vw_regulatory_change_tracker
-- Description: Provides a view of recent regulatory changes and their impact assessments.
CREATE OR REPLACE VIEW regulatory_compliance.vw_regulatory_change_tracker AS
SELECT
    ru.update_id,
    r.regulation_name,
    r.jurisdiction,
    ru.update_date,
    ru.description AS update_description,
    ru.impact_assessment,
    u.username AS responsible_user
FROM
    regulatory_compliance.regulatory_updates ru
JOIN
    regulatory_compliance.regulations r ON ru.regulation_id = r.regulation_id
LEFT JOIN
    core.users u ON ru.responsible_user_id = u.user_id
ORDER BY
    ru.update_date DESC;

COMMENT ON VIEW regulatory_compliance.vw_regulatory_change_tracker IS 'Provides a view of recent regulatory changes and their impact assessments.';

-- Stored Procedure: regulatory_compliance.sp_add_regulatory_update
-- Description: Adds a new regulatory update record.
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_add_regulatory_update(
    p_regulation_id UUID,
    p_update_date DATE,
    p_description TEXT,
    p_impact_assessment TEXT,
    p_responsible_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO regulatory_compliance.regulatory_updates (
        regulation_id, update_date, description, impact_assessment, responsible_user_id
    )
    VALUES (
        p_regulation_id, p_update_date, p_description, p_impact_assessment, p_responsible_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_responsible_user_id,
        'REGULATORY_COMPLIANCE',
        'Regulatory Compliance Management',
        'add_regulatory_update',
        'regulatory_update',
        p_regulation_id,
        NULL, jsonb_build_object('update_date', p_update_date, 'description', p_description),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_add_regulatory_update(UUID, DATE, TEXT, TEXT, UUID) IS 'Adds a new regulatory update record.';

-- Materialized View: regulatory_compliance.mv_overall_compliance_status
-- Description: Provides an aggregated view of overall regulatory compliance status.
CREATE MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status AS
SELECT
    (SELECT COUNT(*) FROM regulatory_compliance.regulations) AS total_regulations,
    (SELECT COUNT(*) FROM regulatory_compliance.compliance_assessments WHERE overall_result = 'Non-Compliant') AS non_compliant_assessments_count,
    (SELECT COUNT(*) FROM regulatory_compliance.compliance_controls WHERE status != 'Implemented') AS controls_not_implemented_count,
    (SELECT COUNT(*) FROM regulatory_compliance.regulatory_updates WHERE update_date > CURRENT_DATE - INTERVAL '90 days') AS recent_regulatory_updates_count;

COMMENT ON MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status IS 'Provides an aggregated view of overall regulatory compliance status.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_refresh_mv_overall_compliance_status()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status;
END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_refresh_mv_overall_compliance_status() IS 'Refreshes the materialized view for overall regulatory compliance status.';


-- ENHANCEMENTS FOR THIRD-PARTY RISK MANAGEMENT SCHEMA

-- Table: third_party_risk.vendor_contracts
-- Description: Stores details of contracts with third-party vendors.
CREATE TABLE third_party_risk.vendor_contracts (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    third_party_id UUID NOT NULL REFERENCES third_party_risk.third_parties(third_party_id) ON DELETE CASCADE,
    contract_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    contract_value DECIMAL(18, 2),
    status VARCHAR(50) NOT NULL, -- e.g., Active, Expired, Terminated
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE third_party_risk.vendor_contracts IS 'Stores details of contracts with third-party vendors.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.contract_id IS 'Unique identifier for the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.third_party_id IS 'Foreign key referencing the third-party vendor.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.contract_name IS 'Name of the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.start_date IS 'Start date of the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.end_date IS 'End date of the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.contract_value IS 'Monetary value of the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.status IS 'Current status of the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.owner_user_id IS 'User responsible for managing the contract.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.created_at IS 'Timestamp when the contract record was created.';
COMMENT ON COLUMN third_party_risk.vendor_contracts.updated_at IS 'Timestamp when the contract record was last updated.';

-- Trigger for third_party_risk.vendor_contracts table
CREATE TRIGGER update_vendor_contracts_updated_at
BEFORE UPDATE ON third_party_risk.vendor_contracts
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: third_party_risk.vw_vendor_contract_overview
-- Description: Provides an overview of vendor contracts and their status.
CREATE OR REPLACE VIEW third_party_risk.vw_vendor_contract_overview AS
SELECT
    vc.contract_id,
    tp.company_name AS vendor_name,
    vc.contract_name,
    vc.start_date,
    vc.end_date,
    vc.status,
    vc.contract_value,
    u.username AS contract_owner
FROM
    third_party_risk.vendor_contracts vc
JOIN
    third_party_risk.third_parties tp ON vc.third_party_id = tp.third_party_id
LEFT JOIN
    core.users u ON vc.owner_user_id = u.user_id;

COMMENT ON VIEW third_party_risk.vw_vendor_contract_overview IS 'Provides an overview of vendor contracts and their status.';

-- Stored Procedure: third_party_risk.sp_update_contract_status
-- Description: Updates the status of a vendor contract.
CREATE OR REPLACE PROCEDURE third_party_risk.sp_update_contract_status(
    p_contract_id UUID,
    p_new_status VARCHAR,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM third_party_risk.vendor_contracts WHERE contract_id = p_contract_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'Contract ID % not found.', p_contract_id;
    END IF;

    UPDATE third_party_risk.vendor_contracts
    SET
        status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        contract_id = p_contract_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'THIRD_PARTY_RISK_MANAGEMENT',
        'Third-Party Risk Management',
        'update_contract_status',
        'vendor_contract',
        p_contract_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE third_party_risk.sp_update_contract_status(UUID, VARCHAR, UUID) IS 'Updates the status of a vendor contract.';

-- Materialized View: third_party_risk.mv_third_party_risk_dashboard
-- Description: Aggregates key metrics for the third-party risk dashboard.
CREATE MATERIALIZED VIEW third_party_risk.mv_third_party_risk_dashboard AS
SELECT
    (SELECT COUNT(*) FROM third_party_risk.third_parties WHERE status = 'Active') AS active_third_parties_count,
    (SELECT COUNT(*) FROM third_party_risk.third_parties WHERE risk_rating = 'High') AS high_risk_third_parties_count,
    (SELECT COUNT(*) FROM third_party_risk.risk_assessments WHERE next_assessment_due_date < CURRENT_DATE) AS overdue_assessments_count,
    (SELECT COUNT(*) FROM third_party_risk.vendor_contracts WHERE status = 'Expired') AS expired_contracts_count;

COMMENT ON MATERIALIZED VIEW third_party_risk.mv_third_party_risk_dashboard IS 'Aggregates key metrics for the third-party risk dashboard.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE third_party_risk.sp_refresh_mv_third_party_risk_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW third_party_risk.mv_third_party_risk_dashboard;
END;
$$;

COMMENT ON PROCEDURE third_party_risk.sp_refresh_mv_third_party_risk_dashboard() IS 'Refreshes the materialized view for third-party risk dashboard.';


-- ActivityPub Integration (Conceptual Tables)

-- Table: activitypub_actors
-- Description: Stores information about ActivityPub actors (users, applications, services).
CREATE TABLE activitypub_actors (
    actor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_type VARCHAR(50) NOT NULL, -- e.g., 'Person', 'Application', 'Service'
    preferred_username VARCHAR(255) UNIQUE NOT NULL,
    inbox_url TEXT NOT NULL,
    outbox_url TEXT NOT NULL,
    public_key TEXT, -- For signing and verification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE activitypub_actors IS 'Stores information about ActivityPub actors.';
COMMENT ON COLUMN activitypub_actors.actor_id IS 'Unique identifier for the ActivityPub actor.';
COMMENT ON COLUMN activitypub_actors.actor_type IS 'Type of the ActivityPub actor.';
COMMENT ON COLUMN activitypub_actors.preferred_username IS 'Preferred username for the actor.';
COMMENT ON COLUMN activitypub_actors.inbox_url IS 'URL of the actor''s inbox.';
COMMENT ON COLUMN activitypub_actors.outbox_url IS 'URL of the actor''s outbox.';
COMMENT ON COLUMN activitypub_actors.public_key IS 'Public key for cryptographic operations.';
COMMENT ON COLUMN activitypub_actors.created_at IS 'Timestamp when the actor record was created.';
COMMENT ON COLUMN activitypub_actors.updated_at IS 'Timestamp when the actor record was last updated.';

-- Trigger for activitypub_actors table
CREATE TRIGGER update_activitypub_actors_updated_at
BEFORE UPDATE ON activitypub_actors
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: activitypub_activities
-- Description: Stores ActivityPub activities (e.g., Create, Update, Delete, Announce).
CREATE TABLE activitypub_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- e.g., 'Create', 'Update', 'Delete', 'Announce'
    object_id TEXT, -- ID of the object being acted upon (e.g., URL of a risk record)
    object_type VARCHAR(255), -- Type of the object (e.g., 'RiskRecord', 'Policy')
    activity_json JSONB NOT NULL, -- Full JSON representation of the activity
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE activitypub_activities IS 'Stores ActivityPub activities.';
COMMENT ON COLUMN activitypub_activities.activity_id IS 'Unique identifier for the ActivityPub activity.';
COMMENT ON COLUMN activitypub_activities.actor_id IS 'Foreign key referencing the actor who performed the activity.';
COMMENT ON COLUMN activitypub_activities.activity_type IS 'Type of the ActivityPub activity.';
COMMENT ON COLUMN activitypub_activities.object_id IS 'ID of the object being acted upon.';
COMMENT ON COLUMN activitypub_activities.object_type IS 'Type of the object being acted upon.';
COMMENT ON COLUMN activitypub_activities.activity_json IS 'Full JSON representation of the activity.';
COMMENT ON COLUMN activitypub_activities.published_at IS 'Timestamp when the activity was published.';
COMMENT ON COLUMN activitypub_activities.created_at IS 'Timestamp when the activity record was created.';

-- Table: activitypub_followers
-- Description: Tracks followers for ActivityPub actors.
CREATE TABLE activitypub_followers (
    follower_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    follower_actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (actor_id, follower_actor_id)
);

COMMENT ON TABLE activitypub_followers IS 'Tracks followers for ActivityPub actors.';
COMMENT ON COLUMN activitypub_followers.follower_id IS 'Unique identifier for the follower relationship.';
COMMENT ON COLUMN activitypub_followers.actor_id IS 'Foreign key referencing the actor being followed.';
COMMENT ON COLUMN activitypub_followers.follower_actor_id IS 'Foreign key referencing the actor who is following.';
COMMENT ON COLUMN activitypub_followers.followed_at IS 'Timestamp when the actor started following.';

-- Stored Procedure: activitypub.sp_create_activity
-- Description: Creates a new ActivityPub activity and stores it.
CREATE OR REPLACE PROCEDURE activitypub.sp_create_activity(
    p_actor_id UUID,
    p_activity_type VARCHAR,
    p_object_id TEXT,
    p_object_type VARCHAR,
    p_activity_json JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO activitypub_activities (
        actor_id, activity_type, object_id, object_type, activity_json
    )
    VALUES (
        p_actor_id, p_activity_type, p_object_id, p_object_type, p_activity_json
    );

    -- In a real implementation, this would also trigger sending the activity
    -- to followers' inboxes.

    -- Log the action
    CALL core.sp_log_audit_event(
        p_actor_id,
        'ACTIVITYPUB',
        'ActivityPub Integration',
        'create_activity',
        'activitypub_activity',
        (SELECT currval('activitypub.activitypub_activities_activity_id_seq')), -- Get last inserted ID
        NULL, p_activity_json,
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE activitypub.sp_create_activity(UUID, VARCHAR, TEXT, VARCHAR, JSONB) IS 'Creates a new ActivityPub activity and stores it.';

-- SOX2 Compliance Note:
-- The audit_logs table (in the core schema) is designed to capture all significant system activities,
-- including data changes, access attempts, and configuration modifications. This provides a robust
-- and immutable audit trail necessary for SOX2 compliance. All DML operations on sensitive tables
-- should ideally be routed through stored procedures that explicitly log to audit_logs.
-- Furthermore, access to audit_logs should be restricted to authorized personnel only.
-- Data retention policies for audit logs should be strictly enforced to meet regulatory requirements.

-- Additional SOX2 considerations:
-- 1. Segregation of Duties: Implemented via RBAC (roles and permissions) in the core schema.
-- 2. Access Controls: Managed through user authentication and RBAC.
-- 3. Data Integrity: Ensured by proper data types, constraints, and transaction management.
-- 4. Change Management: All schema and code changes should follow a strict change management process,
--    with corresponding audit trails (e.g., version control systems).
-- 5. System Monitoring: External monitoring tools would complement the internal audit logs.

-- End of Consolidated Schema


-- ENHANCEMENTS FOR CORE SCHEMA

-- Table: core.notifications
-- Description: Stores system notifications for users.
CREATE TABLE core.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    notification_type VARCHAR(50), -- e.g., 'Alert', 'Info', 'Warning'
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE core.notifications IS 'Stores system notifications for users.';
COMMENT ON COLUMN core.notifications.notification_id IS 'Unique identifier for the notification.';
COMMENT ON COLUMN core.notifications.user_id IS 'Foreign key referencing the recipient user.';
COMMENT ON COLUMN core.notifications.message IS 'The notification message.';
COMMENT ON COLUMN core.notifications.notification_type IS 'Type of notification.';
COMMENT ON COLUMN core.notifications.is_read IS 'Indicates if the notification has been read.';
COMMENT ON COLUMN core.notifications.created_at IS 'Timestamp when the notification was created.';

-- View: core.vw_active_users
-- Description: Lists all currently active users.
CREATE OR REPLACE VIEW core.vw_active_users AS
SELECT
    user_id,
    username,
    email,
    first_name,
    last_name,
    last_login
FROM
    core.users
WHERE
    is_active = TRUE;

COMMENT ON VIEW core.vw_active_users IS 'Lists all currently active users.';

-- Stored Procedure: core.sp_send_notification
-- Description: Sends a new notification to a specified user.
CREATE OR REPLACE PROCEDURE core.sp_send_notification(
    p_user_id UUID,
    p_message TEXT,
    p_notification_type VARCHAR DEFAULT 'Info'
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO core.notifications (user_id, message, notification_type)
    VALUES (p_user_id, p_message, p_notification_type);

    -- Log the action
    CALL core.sp_log_audit_event(
        NULL, -- System action
        'CORE_SYSTEM',
        'Notification Management',
        'send_notification',
        'notification',
        (SELECT currval('core.notifications_notification_id_seq')), -- Get last inserted ID
        NULL, jsonb_build_object('user_id', p_user_id, 'message', p_message, 'type', p_notification_type),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE core.sp_send_notification(UUID, TEXT, VARCHAR) IS 'Sends a new notification to a specified user.';


-- ENHANCEMENTS FOR BUSINESS CONTINUITY MANAGEMENT (BCM) SCHEMA

-- Table: bcm.recovery_strategies
-- Description: Stores detailed recovery strategies for critical business functions.
CREATE TABLE bcm.recovery_strategies (
    strategy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bcm_plan_id UUID NOT NULL REFERENCES bcm.bcm_plans(plan_id) ON DELETE CASCADE,
    strategy_name VARCHAR(255) NOT NULL,
    description TEXT,
    recovery_time_objective INTERVAL, -- e.g., '4 hours'
    recovery_point_objective INTERVAL, -- e.g., '1 hour'
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE bcm.recovery_strategies IS 'Stores detailed recovery strategies for critical business functions.';
COMMENT ON COLUMN bcm.recovery_strategies.strategy_id IS 'Unique identifier for the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.bcm_plan_id IS 'Foreign key referencing the associated BCM plan.';
COMMENT ON COLUMN bcm.recovery_strategies.strategy_name IS 'Name of the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.description IS 'Description of the recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.recovery_time_objective IS 'Recovery Time Objective (RTO) for the strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.recovery_point_objective IS 'Recovery Point Objective (RPO) for the strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.owner_user_id IS 'User responsible for this recovery strategy.';
COMMENT ON COLUMN bcm.recovery_strategies.created_at IS 'Timestamp when the strategy record was created.';
COMMENT ON COLUMN bcm.recovery_strategies.updated_at IS 'Timestamp when the strategy record was last updated.';

-- Trigger for bcm.recovery_strategies table
CREATE TRIGGER update_recovery_strategies_updated_at
BEFORE UPDATE ON bcm.recovery_strategies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: bcm.vw_bcm_plan_status
-- Description: Provides a summary of BCM plans and their current status.
CREATE OR REPLACE VIEW bcm.vw_bcm_plan_status AS
SELECT
    bp.plan_id,
    bp.plan_name,
    bp.status,
    bp.last_tested_date,
    bp.next_test_due_date,
    u.username AS owner_username,
    COUNT(rs.strategy_id) AS total_recovery_strategies
FROM
    bcm.bcm_plans bp
LEFT JOIN
    bcm.recovery_strategies rs ON bp.plan_id = rs.bcm_plan_id
LEFT JOIN
    core.users u ON bp.owner_user_id = u.user_id
GROUP BY
    bp.plan_id, bp.plan_name, bp.status, bp.last_tested_date, bp.next_test_due_date, u.username;

COMMENT ON VIEW bcm.vw_bcm_plan_status IS 'Provides a summary of BCM plans and their current status.';

-- Stored Procedure: bcm.sp_update_bcm_plan_status
-- Description: Updates the status and test dates of a BCM plan.
CREATE OR REPLACE PROCEDURE bcm.sp_update_bcm_plan_status(
    p_plan_id UUID,
    p_new_status VARCHAR,
    p_last_tested_date DATE DEFAULT NULL,
    p_next_test_due_date DATE DEFAULT NULL,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM bcm.bcm_plans WHERE plan_id = p_plan_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'BCM Plan ID % not found.', p_plan_id;
    END IF;

    UPDATE bcm.bcm_plans
    SET
        status = p_new_status,
        last_tested_date = COALESCE(p_last_tested_date, last_tested_date),
        next_test_due_date = COALESCE(p_next_test_due_date, next_test_due_date),
        updated_at = CURRENT_TIMESTAMP
    WHERE
        plan_id = p_plan_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'BUSINESS_CONTINUITY_MANAGEMENT',
        'Business Continuity Management',
        'update_bcm_plan_status',
        'bcm_plan',
        p_plan_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'last_tested_date', p_last_tested_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE bcm.sp_update_bcm_plan_status(UUID, VARCHAR, DATE, DATE, UUID) IS 'Updates the status and test dates of a BCM plan.';

-- Materialized View: bcm.mv_bcm_readiness_summary
-- Description: Provides a summary of BCM readiness, including overdue tests and active incidents.
CREATE MATERIALIZED VIEW bcm.mv_bcm_readiness_summary AS
SELECT
    (SELECT COUNT(*) FROM bcm.bcm_plans WHERE status = 'Active') AS active_bcm_plans_count,
    (SELECT COUNT(*) FROM bcm.bcm_plans WHERE next_test_due_date < CURRENT_DATE) AS overdue_bcm_tests_count,
    (SELECT COUNT(*) FROM operational_risk.risk_events WHERE status != 'Closed' AND category = 'Disruption') AS active_disruption_incidents_count;

COMMENT ON MATERIALIZED VIEW bcm.mv_bcm_readiness_summary IS 'Provides a summary of BCM readiness, including overdue tests and active incidents.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE bcm.sp_refresh_mv_bcm_readiness_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW bcm.mv_bcm_readiness_summary;
END;
$$;

COMMENT ON PROCEDURE bcm.sp_refresh_mv_bcm_readiness_summary() IS 'Refreshes the materialized view for BCM readiness summary.';


-- ENHANCEMENTS FOR DATA PRIVACY MANAGEMENT SCHEMA

-- Table: data_privacy.data_breaches
-- Description: Records data breach incidents.
CREATE TABLE data_privacy.data_breaches (
    breach_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    breach_name VARCHAR(255) NOT NULL,
    description TEXT,
    breach_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE NOT NULL,
    impacted_records_count INT,
    status VARCHAR(50) NOT NULL, -- e.g., Reported, Under Investigation, Contained, Resolved
    notification_required BOOLEAN,
    notified_regulators TEXT, -- Comma-separated list of regulators notified
    remediation_actions TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE data_privacy.data_breaches IS 'Records data breach incidents.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_id IS 'Unique identifier for the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_name IS 'Name or title of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.description IS 'Description of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.breach_date IS 'Date and time the breach occurred.';
COMMENT ON COLUMN data_privacy.data_breaches.discovery_date IS 'Date and time the breach was discovered.';
COMMENT ON COLUMN data_privacy.data_breaches.impacted_records_count IS 'Number of records impacted by the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.status IS 'Current status of the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.notification_required IS 'Indicates if notification to authorities/individuals is required.';
COMMENT ON COLUMN data_privacy.data_breaches.notified_regulators IS 'List of regulators notified about the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.remediation_actions IS 'Actions taken to remediate the breach.';
COMMENT ON COLUMN data_privacy.data_breaches.reported_by IS 'User who reported the data breach.';
COMMENT ON COLUMN data_privacy.data_breaches.created_at IS 'Timestamp when the breach record was created.';
COMMENT ON COLUMN data_privacy.data_breaches.updated_at IS 'Timestamp when the breach record was last updated.';

-- Trigger for data_privacy.data_breaches table
CREATE TRIGGER update_data_breaches_updated_at
BEFORE UPDATE ON data_privacy.data_breaches
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: data_privacy.vw_data_subject_consent_summary
-- Description: Provides a summary of data subject consent status.
CREATE OR REPLACE VIEW data_privacy.vw_data_subject_consent_summary AS
SELECT
    ds.country_of_residence,
    COUNT(ds.subject_id) AS total_subjects,
    COUNT(CASE WHEN ds.consent_status = TRUE THEN 1 END) AS consented_subjects_count,
    ROUND((COUNT(CASE WHEN ds.consent_status = TRUE THEN 1 END)::NUMERIC / COUNT(ds.subject_id)) * 100, 2) AS consent_percentage
FROM
    data_privacy.data_subjects ds
GROUP BY
    ds.country_of_residence;

COMMENT ON VIEW data_privacy.vw_data_subject_consent_summary IS 'Provides a summary of data subject consent status.';

-- Stored Procedure: data_privacy.sp_record_data_breach
-- Description: Records a new data breach incident.
CREATE OR REPLACE PROCEDURE data_privacy.sp_record_data_breach(
    p_breach_name VARCHAR,
    p_description TEXT,
    p_breach_date TIMESTAMP WITH TIME ZONE,
    p_discovery_date TIMESTAMP WITH TIME ZONE,
    p_impacted_records_count INT,
    p_status VARCHAR,
    p_notification_required BOOLEAN,
    p_notified_regulators TEXT,
    p_remediation_actions TEXT,
    p_reported_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO data_privacy.data_breaches (
        breach_name, description, breach_date, discovery_date, impacted_records_count,
        status, notification_required, notified_regulators, remediation_actions, reported_by
    )
    VALUES (
        p_breach_name, p_description, p_breach_date, p_discovery_date, p_impacted_records_count,
        p_status, p_notification_required, p_notified_regulators, p_remediation_actions, p_reported_by_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_reported_by_user_id,
        'DATA_PRIVACY_MANAGEMENT',
        'Data Privacy Management',
        'record_data_breach',
        'data_breach',
        (SELECT currval('data_privacy.data_breaches_breach_id_seq')), -- Get last inserted ID
        NULL, jsonb_build_object('breach_name', p_breach_name, 'status', p_status, 'impacted_records', p_impacted_records_count),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE data_privacy.sp_record_data_breach(VARCHAR, TEXT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INT, VARCHAR, BOOLEAN, TEXT, TEXT, UUID) IS 'Records a new data breach incident.';

-- Materialized View: data_privacy.mv_data_privacy_compliance_overview
-- Description: Provides an aggregated overview of data privacy compliance metrics.
CREATE MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_overview AS
SELECT
    (SELECT COUNT(*) FROM data_privacy.data_subjects WHERE consent_status = FALSE) AS subjects_without_consent_count,
    (SELECT COUNT(*) FROM data_privacy.data_subject_requests WHERE status != 'Completed') AS open_dsar_count,
    (SELECT COUNT(*) FROM data_privacy.data_breaches WHERE status != 'Resolved') AS active_data_breaches_count,
    (SELECT COUNT(*) FROM data_privacy.data_processing_activities) AS total_processing_activities;

COMMENT ON MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_overview IS 'Provides an aggregated overview of data privacy compliance metrics.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE data_privacy.sp_refresh_mv_data_privacy_compliance_overview()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW data_privacy.mv_data_privacy_compliance_overview;
END;
$$;

COMMENT ON PROCEDURE data_privacy.sp_refresh_mv_data_privacy_compliance_overview() IS 'Refreshes the materialized view for data privacy compliance overview.';


-- ENHANCEMENTS FOR ESG AND FINANCIAL CONTROLS MANAGEMENT SCHEMA

-- Table: esg.carbon_emissions_data
-- Description: Stores detailed carbon emissions data.
CREATE TABLE esg.carbon_emissions_data (
    emission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_id UUID NOT NULL REFERENCES esg.esg_metrics(metric_id) ON DELETE CASCADE,
    reporting_period DATE NOT NULL,
    scope1_emissions DECIMAL(18, 4), -- Direct emissions
    scope2_emissions DECIMAL(18, 4), -- Indirect emissions from purchased energy
    scope3_emissions DECIMAL(18, 4), -- Other indirect emissions
    total_emissions DECIMAL(18, 4) GENERATED ALWAYS AS (scope1_emissions + scope2_emissions + scope3_emissions) STORED,
    emission_source TEXT,
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE esg.carbon_emissions_data IS 'Stores detailed carbon emissions data.';
COMMENT ON COLUMN esg.carbon_emissions_data.emission_id IS 'Unique identifier for the emission record.';
COMMENT ON COLUMN esg.carbon_emissions_data.metric_id IS 'Foreign key referencing the associated ESG metric (e.g., Total Carbon Emissions).';
COMMENT ON COLUMN esg.carbon_emissions_data.reporting_period IS 'End date of the reporting period.';
COMMENT ON COLUMN esg.carbon_emissions_data.scope1_emissions IS 'Direct emissions from owned or controlled sources.';
COMMENT ON COLUMN esg.carbon_emissions_data.scope2_emissions IS 'Indirect emissions from the generation of purchased electricity, steam, heating, and cooling consumed by the reporting company.';
COMMENT ON COLUMN esg.carbon_emissions.scope3_emissions IS 'All other indirect emissions that occur in a company’s value chain.';
COMMENT ON COLUMN esg.carbon_emissions_data.total_emissions IS 'Calculated total emissions.';
COMMENT ON COLUMN esg.carbon_emissions_data.emission_source IS 'Description of the source of these emissions.';
COMMENT ON COLUMN esg.carbon_emissions_data.reported_by IS 'User who reported the emissions data.';
COMMENT ON COLUMN esg.carbon_emissions_data.created_at IS 'Timestamp when the record was created.';
COMMENT ON COLUMN esg.carbon_emissions_data.updated_at IS 'Timestamp when the record was last updated.';

-- Trigger for esg.carbon_emissions_data table
CREATE TRIGGER update_carbon_emissions_data_updated_at
BEFORE UPDATE ON esg.carbon_emissions_data
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: esg.vw_esg_performance_dashboard
-- Description: Aggregates key ESG performance indicators for a dashboard view.
CREATE OR REPLACE VIEW esg.vw_esg_performance_dashboard AS
SELECT
    em.metric_name,
    em.category,
    em.unit,
    em.target_value,
    ea.actual_value AS latest_actual_value,
    ea.reporting_period AS latest_reporting_period,
    (ea.actual_value - em.target_value) AS variance_from_target,
    CASE
        WHEN em.target_value = 0 THEN NULL
        ELSE ROUND(((ea.actual_value - em.target_value) / em.target_value) * 100, 2)
    END AS variance_percentage_from_target,
    CASE
        WHEN ea.actual_value <= em.target_value THEN 'On Track'
        ELSE 'Off Track'
    END AS performance_status
FROM
    esg.esg_metrics em
LEFT JOIN LATERAL (
    SELECT actual_value, reporting_period
    FROM esg.esg_actuals
    WHERE metric_id = em.metric_id
    ORDER BY reporting_period DESC
    LIMIT 1
) ea ON TRUE;

COMMENT ON VIEW esg.vw_esg_performance_dashboard IS 'Aggregates key ESG performance indicators for a dashboard view.';

-- Stored Procedure: esg.sp_analyze_esg_trends
-- Description: Analyzes historical ESG data to identify trends for a given metric.
CREATE OR REPLACE PROCEDURE esg.sp_analyze_esg_trends(
    p_metric_name VARCHAR,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_metric_id UUID;
BEGIN
    SELECT metric_id INTO v_metric_id FROM esg.esg_metrics WHERE metric_name = p_metric_name;

    IF v_metric_id IS NULL THEN
        RAISE EXCEPTION 'ESG Metric % not found.', p_metric_name;
    END IF;

    RAISE NOTICE 'Analyzing trends for metric: % from % to %',
        p_metric_name, p_start_date, p_end_date;

    -- This is a simplified example. In a real application, this procedure would
    -- perform complex statistical analysis, potentially using temporary tables
    -- or returning a CURSOR for detailed results.
    -- For now, it just selects data and logs the action.
    PERFORM
        reporting_period,
        actual_value
    FROM
        esg.esg_actuals
    WHERE
        metric_id = v_metric_id AND reporting_period BETWEEN p_start_date AND p_end_date
    ORDER BY
        reporting_period;

    CALL core.sp_log_audit_event(
        NULL, -- Assuming this can be called by system or a specific user
        'ESG_MANAGEMENT',
        'ESG',
        'analyze_esg_trends',
        'esg_metric',
        v_metric_id,
        NULL, NULL,
        NULL, NULL, jsonb_build_object('metric_name', p_metric_name, 'start_date', p_start_date, 'end_date', p_end_date),
        FALSE
    );

END;
$$;

COMMENT ON PROCEDURE esg.sp_analyze_esg_trends(VARCHAR, DATE, DATE) IS 'Analyzes historical ESG data to identify trends for a given metric.';

-- Materialized View: esg.mv_esg_compliance_summary
-- Description: Provides a summary of ESG policy compliance and metric performance.
CREATE MATERIALIZED VIEW esg.mv_esg_compliance_summary AS
SELECT
    (SELECT COUNT(*) FROM esg.esg_policies WHERE status = 'Approved') AS approved_policies_count,
    (SELECT COUNT(*) FROM esg.esg_policies WHERE next_review_due_at < CURRENT_DATE) AS overdue_policy_reviews_count,
    (SELECT COUNT(*) FROM esg.esg_metrics) AS total_esg_metrics,
    (SELECT COUNT(*) FROM esg.vw_esg_metric_performance WHERE performance_status = 'Off Track') AS off_track_metrics_count;

COMMENT ON MATERIALIZED VIEW esg.mv_esg_compliance_summary IS 'Provides a summary of ESG policy compliance and metric performance.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE esg.sp_refresh_mv_esg_compliance_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW esg.mv_esg_compliance_summary;
END;
$$;

COMMENT ON PROCEDURE esg.sp_refresh_mv_esg_compliance_summary() IS 'Refreshes the materialized view for ESG compliance summary.';


-- ENHANCEMENTS FOR FINANCIAL CONTROLS MANAGEMENT SCHEMA

-- Table: financial_controls.control_deficiencies
-- Description: Tracks identified control deficiencies and their remediation.
CREATE TABLE financial_controls.control_deficiencies (
    deficiency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES financial_controls.financial_controls(control_id) ON DELETE CASCADE,
    test_id UUID REFERENCES financial_controls.financial_control_tests(test_id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL, -- e.g., Low, Medium, High, Critical
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Closed, Verified
    remediation_plan TEXT,
    due_date DATE,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    closed_date DATE,
    closed_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE financial_controls.control_deficiencies IS 'Tracks identified control deficiencies and their remediation.';
COMMENT ON COLUMN financial_controls.control_deficiencies.deficiency_id IS 'Unique identifier for the control deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.control_id IS 'Foreign key referencing the control with the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.test_id IS 'Foreign key referencing the test that identified the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.description IS 'Description of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.severity IS 'Severity of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.status IS 'Current status of the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.remediation_plan IS 'Plan for remediating the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.due_date IS 'Due date for remediation.';
COMMENT ON COLUMN financial_controls.control_deficiencies.responsible_user_id IS 'User responsible for remediating the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.closed_date IS 'Date the deficiency was closed.';
COMMENT ON COLUMN financial_controls.control_deficiencies.closed_by IS 'User who closed the deficiency.';
COMMENT ON COLUMN financial_controls.control_deficiencies.created_at IS 'Timestamp when the deficiency was recorded.';
COMMENT ON COLUMN financial_controls.control_deficiencies.updated_at IS 'Timestamp when the deficiency was last updated.';

-- Trigger for financial_controls.control_deficiencies table
CREATE TRIGGER update_control_deficiencies_updated_at
BEFORE UPDATE ON financial_controls.control_deficiencies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: financial_controls.vw_control_deficiency_summary
-- Description: Provides a summary of control deficiencies by status and severity.
CREATE OR REPLACE VIEW financial_controls.vw_control_deficiency_summary AS
SELECT
    status,
    severity,
    COUNT(deficiency_id) AS total_deficiencies,
    COUNT(CASE WHEN due_date < CURRENT_DATE AND status IN ('Open', 'In Progress') THEN 1 END) AS overdue_deficiencies
FROM
    financial_controls.control_deficiencies
GROUP BY
    status, severity;

COMMENT ON VIEW financial_controls.vw_control_deficiency_summary IS 'Provides a summary of control deficiencies by status and severity.';

-- Stored Procedure: financial_controls.sp_update_deficiency_status
-- Description: Updates the status and remediation details of a control deficiency.
CREATE OR REPLACE PROCEDURE financial_controls.sp_update_deficiency_status(
    p_deficiency_id UUID,
    p_new_status VARCHAR,
    p_remediation_plan TEXT DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_responsible_user_id UUID DEFAULT NULL,
    p_closed_by_user_id UUID DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status VARCHAR;
BEGIN
    SELECT status INTO v_old_status FROM financial_controls.control_deficiencies WHERE deficiency_id = p_deficiency_id;

    IF v_old_status IS NULL THEN
        RAISE EXCEPTION 'Control Deficiency ID % not found.', p_deficiency_id;
    END IF;

    UPDATE financial_controls.control_deficiencies
    SET
        status = p_new_status,
        remediation_plan = COALESCE(p_remediation_plan, remediation_plan),
        due_date = COALESCE(p_due_date, due_date),
        responsible_user_id = COALESCE(p_responsible_user_id, responsible_user_id),
        closed_date = CASE WHEN p_new_status = 'Closed' THEN CURRENT_DATE ELSE closed_date END,
        closed_by = CASE WHEN p_new_status = 'Closed' THEN p_closed_by_user_id ELSE closed_by END,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        deficiency_id = p_deficiency_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        COALESCE(p_closed_by_user_id, p_responsible_user_id), -- Logged by whoever is closing or responsible
        'FINANCIAL_CONTROLS_MANAGEMENT',
        'Financial Controls Management',
        'update_deficiency_status',
        'control_deficiency',
        p_deficiency_id,
        jsonb_build_object('status', v_old_status),
        jsonb_build_object('status', p_new_status, 'remediation_plan', p_remediation_plan, 'due_date', p_due_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE financial_controls.sp_update_deficiency_status(UUID, VARCHAR, TEXT, DATE, UUID, UUID) IS 'Updates the status and remediation details of a control deficiency.';

-- Materialized View: financial_controls.mv_sox_compliance_dashboard
-- Description: Aggregates key metrics for SOX compliance reporting.
CREATE MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard AS
SELECT
    (SELECT COUNT(*) FROM financial_controls.financial_controls) AS total_controls,
    (SELECT COUNT(*) FROM financial_controls.financial_control_tests WHERE result = 'Fail') AS failed_tests_count,
    (SELECT COUNT(*) FROM financial_controls.control_deficiencies WHERE status IN ('Open', 'In Progress')) AS open_deficiencies_count,
    (SELECT COUNT(*) FROM financial_controls.financial_incidents WHERE status IN ('Reported', 'Under Investigation')) AS active_financial_incidents;

COMMENT ON MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard IS 'Aggregates key metrics for SOX compliance reporting.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE financial_controls.sp_refresh_mv_sox_compliance_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW financial_controls.mv_sox_compliance_dashboard;
END;
$$;

COMMENT ON PROCEDURE financial_controls.sp_refresh_mv_sox_compliance_dashboard() IS 'Refreshes the materialized view for SOX compliance dashboard.';


-- ENHANCEMENTS FOR INTERNAL AUDIT MANAGEMENT AND IT GOVERNANCE SCHEMA

-- Table: internal_audit.audit_recommendation_tracking
-- Description: Tracks the implementation status of audit recommendations.
CREATE TABLE internal_audit.audit_recommendation_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    finding_id UUID NOT NULL REFERENCES internal_audit.audit_findings(finding_id) ON DELETE CASCADE,
    action_item TEXT NOT NULL,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    due_date DATE,
    status VARCHAR(50) NOT NULL, -- e.g., Open, In Progress, Completed, Verified
    completion_date DATE,
    verified_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE internal_audit.audit_recommendation_tracking IS 'Tracks the implementation status of audit recommendations.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.tracking_id IS 'Unique identifier for the recommendation tracking record.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.finding_id IS 'Foreign key referencing the audit finding.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.action_item IS 'Specific action item for remediation.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.responsible_user_id IS 'User responsible for implementing the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.due_date IS 'Due date for the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.status IS 'Current status of the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.completion_date IS 'Date the action item was completed.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.verified_by IS 'User who verified the completion of the action item.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.created_at IS 'Timestamp when the tracking record was created.';
COMMENT ON COLUMN internal_audit.audit_recommendation_tracking.updated_at IS 'Timestamp when the tracking record was last updated.';

-- Trigger for internal_audit.audit_recommendation_tracking table
CREATE TRIGGER update_audit_recommendation_tracking_updated_at
BEFORE UPDATE ON internal_audit.audit_recommendation_tracking
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: internal_audit.vw_audit_recommendation_status
-- Description: Provides a consolidated view of audit findings and their recommendation tracking status.
CREATE OR REPLACE VIEW internal_audit.vw_audit_recommendation_status AS
SELECT
    af.finding_id,
    af.title AS finding_title,
    af.severity AS finding_severity,
    af.status AS finding_status,
    art.action_item,
    art.status AS recommendation_status,
    art.due_date AS recommendation_due_date,
    u.username AS responsible_for_recommendation
FROM
    internal_audit.audit_findings af
LEFT JOIN
    internal_audit.audit_recommendation_tracking art ON af.finding_id = art.finding_id
LEFT JOIN
    core.users u ON art.responsible_user_id = u.user_id;

COMMENT ON VIEW internal_audit.vw_audit_recommendation_status IS 'Provides a consolidated view of audit findings and their recommendation tracking status.';

-- Stored Procedure: internal_audit.sp_add_audit_recommendation
-- Description: Adds a new recommendation action item for an audit finding.
CREATE OR REPLACE PROCEDURE internal_audit.sp_add_audit_recommendation(
    p_finding_id UUID,
    p_action_item TEXT,
    p_responsible_user_id UUID,
    p_due_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO internal_audit.audit_recommendation_tracking (
        finding_id, action_item, responsible_user_id, due_date, status
    )
    VALUES (
        p_finding_id, p_action_item, p_responsible_user_id, p_due_date, 'Open'
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_responsible_user_id,
        'INTERNAL_AUDIT',
        'Internal Audit Management',
        'add_audit_recommendation',
        'audit_recommendation_tracking',
        p_finding_id,
        NULL, jsonb_build_object('action_item', p_action_item, 'due_date', p_due_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_add_audit_recommendation(UUID, TEXT, UUID, DATE) IS 'Adds a new recommendation action item for an audit finding.';

-- Materialized View: internal_audit.mv_audit_engagement_summary
-- Description: Summarizes audit engagement statuses and finding counts.
CREATE MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary AS
SELECT
    ae.engagement_id,
    ae.engagement_name,
    ae.status AS engagement_status,
    COUNT(af.finding_id) AS total_findings,
    COUNT(CASE WHEN af.status IN ('Open', 'In Progress') THEN 1 END) AS open_findings_count,
    COUNT(CASE WHEN af.status = 'Closed' THEN 1 END) AS closed_findings_count
FROM
    internal_audit.audit_engagements ae
LEFT JOIN
    internal_audit.audit_findings af ON ae.engagement_id = af.engagement_id
GROUP BY
    ae.engagement_id, ae.engagement_name, ae.status;

COMMENT ON MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary IS 'Summarizes audit engagement statuses and finding counts.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE internal_audit.sp_refresh_mv_audit_engagement_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW internal_audit.mv_audit_engagement_summary;
END;
$$;

COMMENT ON PROCEDURE internal_audit.sp_refresh_mv_audit_engagement_summary() IS 'Refreshes the materialized view for audit engagement summary.';


-- ENHANCEMENTS FOR IT GOVERNANCE SCHEMA

-- Table: it_governance.it_control_assessments
-- Description: Records assessments of IT controls.
CREATE TABLE it_governance.it_control_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES it_governance.it_controls(control_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    result VARCHAR(50) NOT NULL, -- e.g., Compliant, Non-Compliant, Partially Compliant
    findings TEXT,
    remediation_plan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE it_governance.it_control_assessments IS 'Records assessments of IT controls.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessment_id IS 'Unique identifier for the IT control assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.control_id IS 'Foreign key referencing the IT control assessed.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.result IS 'Result of the control assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN it_governance.it_control_assessments.remediation_plan IS 'Plan for remediating any non-compliance.';
COMMENT ON COLUMN it_governance.it_control_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN it_governance.it_control_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for it_governance.it_control_assessments table
CREATE TRIGGER update_it_control_assessments_updated_at
BEFORE UPDATE ON it_governance.it_control_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: it_governance.vw_it_control_compliance_summary
-- Description: Summarizes the compliance status of IT controls.
CREATE OR REPLACE VIEW it_governance.vw_it_control_compliance_summary AS
SELECT
    ic.control_id,
    ic.control_name,
    ic.category,
    ica.assessment_date AS last_assessment_date,
    ica.result AS last_assessment_result,
    ica.findings AS last_assessment_findings
FROM
    it_governance.it_controls ic
LEFT JOIN LATERAL (
    SELECT *
    FROM it_governance.it_control_assessments
    WHERE control_id = ic.control_id
    ORDER BY assessment_date DESC
    LIMIT 1
) ica ON TRUE;

COMMENT ON VIEW it_governance.vw_it_control_compliance_summary IS 'Summarizes the compliance status of IT controls.';

-- Stored Procedure: it_governance.sp_record_it_control_assessment
-- Description: Records a new IT control assessment result.
CREATE OR REPLACE PROCEDURE it_governance.sp_record_it_control_assessment(
    p_control_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_result VARCHAR,
    p_findings TEXT,
    p_remediation_plan TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO it_governance.it_control_assessments (
        control_id, assessment_date, assessor_user_id, result, findings, remediation_plan
    )
    VALUES (
        p_control_id, p_assessment_date, p_assessor_user_id, p_result, p_findings, p_remediation_plan
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'IT_GOVERNANCE',
        'IT Governance',
        'record_it_control_assessment',
        'it_control_assessment',
        p_control_id,
        NULL, jsonb_build_object('result', p_result, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE it_governance.sp_record_it_control_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new IT control assessment result.';

-- Materialized View: it_governance.mv_it_risk_and_compliance_overview
-- Description: Provides a consolidated overview of IT risks and control compliance.
CREATE MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview AS
SELECT
    (SELECT COUNT(*) FROM it_governance.it_risks WHERE status = 'Open') AS open_it_risks_count,
    (SELECT COUNT(*) FROM it_governance.it_policies WHERE next_review_due_at < CURRENT_DATE) AS overdue_it_policy_reviews_count,
    (SELECT COUNT(*) FROM it_governance.it_controls) AS total_it_controls,
    (SELECT COUNT(*) FROM it_governance.it_control_assessments WHERE result = 'Non-Compliant') AS non_compliant_it_controls_count;

COMMENT ON MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview IS 'Provides a consolidated overview of IT risks and control compliance.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE it_governance.sp_refresh_mv_it_risk_and_compliance_overview()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW it_governance.mv_it_risk_and_compliance_overview;
END;
$$;

COMMENT ON PROCEDURE it_governance.sp_refresh_mv_it_risk_and_compliance_overview() IS 'Refreshes the materialized view for IT risk and compliance overview.';






-- ActivityPub Integration (Conceptual Tables)

-- Table: activitypub_actors
-- Description: Stores information about ActivityPub actors (users, applications, services).
CREATE TABLE activitypub_actors (
    actor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_type VARCHAR(50) NOT NULL, -- e.g., 'Person', 'Application', 'Service'
    preferred_username VARCHAR(255) UNIQUE NOT NULL,
    inbox_url TEXT NOT NULL,
    outbox_url TEXT NOT NULL,
    public_key TEXT, -- For signing and verification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE activitypub_actors IS 'Stores information about ActivityPub actors.';
COMMENT ON COLUMN activitypub_actors.actor_id IS 'Unique identifier for the ActivityPub actor.';
COMMENT ON COLUMN activitypub_actors.actor_type IS 'Type of the ActivityPub actor.';
COMMENT ON COLUMN activitypub_actors.preferred_username IS 'Preferred username for the actor.';
COMMENT ON COLUMN activitypub_actors.inbox_url IS 'URL of the actor''s inbox.';
COMMENT ON COLUMN activitypub_actors.outbox_url IS 'URL of the actor''s outbox.';
COMMENT ON COLUMN activitypub_actors.public_key IS 'Public key for cryptographic operations.';
COMMENT ON COLUMN activitypub_actors.created_at IS 'Timestamp when the actor record was created.';
COMMENT ON COLUMN activitypub_actors.updated_at IS 'Timestamp when the actor record was last updated.';

-- Trigger for activitypub_actors table
CREATE TRIGGER update_activitypub_actors_updated_at
BEFORE UPDATE ON activitypub_actors
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: activitypub_activities
-- Description: Stores ActivityPub activities (e.g., Create, Update, Delete, Announce).
CREATE TABLE activitypub_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- e.g., 'Create', 'Update', 'Delete', 'Announce'
    object_id TEXT, -- ID of the object being acted upon (e.g., URL of a risk record)
    object_type VARCHAR(255), -- Type of the object (e.g., 'RiskRecord', 'Policy')
    activity_json JSONB NOT NULL, -- Full JSON representation of the activity
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE activitypub_activities IS 'Stores ActivityPub activities.';
COMMENT ON COLUMN activitypub_activities.activity_id IS 'Unique identifier for the ActivityPub activity.';
COMMENT ON COLUMN activitypub_activities.actor_id IS 'Foreign key referencing the actor who performed the activity.';
COMMENT ON COLUMN activitypub_activities.activity_type IS 'Type of the ActivityPub activity.';
COMMENT ON COLUMN activitypub_activities.object_id IS 'ID of the object being acted upon.';
COMMENT ON COLUMN activitypub_activities.object_type IS 'Type of the object being acted upon.';
COMMENT ON COLUMN activitypub_activities.activity_json IS 'Full JSON representation of the activity.';
COMMENT ON COLUMN activitypub_activities.published_at IS 'Timestamp when the activity was published.';
COMMENT ON COLUMN activitypub_activities.created_at IS 'Timestamp when the activity record was created.';

-- Table: activitypub_followers
-- Description: Tracks followers for ActivityPub actors.
CREATE TABLE activitypub_followers (
    follower_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    follower_actor_id UUID NOT NULL REFERENCES activitypub_actors(actor_id) ON DELETE CASCADE,
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (actor_id, follower_actor_id)
);

COMMENT ON TABLE activitypub_followers IS 'Tracks followers for ActivityPub actors.';
COMMENT ON COLUMN activitypub_followers.follower_id IS 'Unique identifier for the follower relationship.';
COMMENT ON COLUMN activitypub_followers.actor_id IS 'Foreign key referencing the actor being followed.';
COMMENT ON COLUMN activitypub_followers.follower_actor_id IS 'Foreign key referencing the actor who is following.';
COMMENT ON COLUMN activitypub_followers.followed_at IS 'Timestamp when the actor started following.';

-- Stored Procedure: activitypub.sp_create_activity
-- Description: Creates a new ActivityPub activity and stores it.
CREATE OR REPLACE PROCEDURE activitypub.sp_create_activity(
    p_actor_id UUID,
    p_activity_type VARCHAR,
    p_object_id TEXT,
    p_object_type VARCHAR,
    p_activity_json JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO activitypub_activities (
        actor_id, activity_type, object_id, object_type, activity_json
    )
    VALUES (
        p_actor_id, p_activity_type, p_object_id, p_object_type, p_activity_json
    );

    -- In a real implementation, this would also trigger sending the activity
    -- to followers'' inboxes.

    -- Log the action
    CALL core.sp_log_audit_event(
        p_actor_id,
        ''ACTIVITYPUB'','
        ''ActivityPub Integration'','
        ''create_activity'','
        ''activitypub_activity'','
        (SELECT currval(''activitypub_activities_activity_id_seq'')), -- Get last inserted ID
        NULL, p_activity_json,
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE activitypub.sp_create_activity(UUID, VARCHAR, TEXT, VARCHAR, JSONB) IS 'Creates a new ActivityPub activity and stores it.';

-- SOX2 Compliance Note:
-- The audit_logs table (in the core schema) is designed to capture all significant system activities,
-- including data changes, access attempts, and configuration modifications. This provides a robust
-- and immutable audit trail necessary for SOX2 compliance. All DML operations on sensitive tables
-- should ideally be routed through stored procedures that explicitly log to audit_logs.
-- Furthermore, access to audit_logs should be restricted to authorized personnel only.
-- Data retention policies for audit logs should be strictly enforced to meet regulatory requirements.

-- Additional SOX2 considerations:
-- 1. Segregation of Duties: Implemented via RBAC (roles and permissions) in the core schema.
-- 2. Access Controls: Managed through user authentication and RBAC.
-- 3. Data Integrity: Ensured by proper data types, constraints, and transaction management.
-- 4. Change Management: All schema and code changes should follow a strict change management process,
--    with corresponding audit trails (e.g., version control systems).
-- 5. System Monitoring: External monitoring tools would complement the internal audit logs.

-- End of Consolidated Schema



-- Model Risk Governance and Operational Risk Management Schema



-- Create model_risk schema
CREATE SCHEMA IF NOT EXISTS model_risk;

-- Set search path for model_risk schema
SET search_path TO model_risk, public;

-- Table: model_risk.models
-- Description: Stores information about various models used within the organization.
CREATE TABLE model_risk.models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name VARCHAR(255) UNIQUE NOT NULL,
    model_type VARCHAR(100), -- e.g., Credit Scoring, Fraud Detection, Valuation
    description TEXT,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Development, Approved, Retired, Under Review
    last_validation_date DATE,
    next_validation_due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE model_risk.models IS 'Stores information about various models used within the organization.';
COMMENT ON COLUMN model_risk.models.model_id IS 'Unique identifier for the model.';
COMMENT ON COLUMN model_risk.models.model_name IS 'Name of the model.';
COMMENT ON COLUMN model_risk.models.model_type IS 'Type or category of the model.';
COMMENT ON COLUMN model_risk.models.description IS 'Description of the model.';
COMMENT ON COLUMN model_risk.models.owner_user_id IS 'User responsible for the model.';
COMMENT ON COLUMN model_risk.models.status IS 'Current status of the model.';
COMMENT ON COLUMN model_risk.models.last_validation_date IS 'Date of the last model validation.';
COMMENT ON COLUMN model_risk.models.next_validation_due_date IS 'Date when the next model validation is due.';
COMMENT ON COLUMN model_risk.models.created_at IS 'Timestamp when the model record was created.';
COMMENT ON COLUMN model_risk.models.updated_at IS 'Timestamp when the model record was last updated.';

-- Trigger for model_risk.models table
CREATE TRIGGER update_models_updated_at
BEFORE UPDATE ON model_risk.models
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: model_risk.model_validations
-- Description: Records details of model validation activities.
CREATE TABLE model_risk.model_validations (
    validation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES model_risk.models(model_id) ON DELETE CASCADE,
    validation_date DATE NOT NULL,
    validator_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    validation_result VARCHAR(50) NOT NULL, -- e.g., Pass, Fail, Conditional Pass
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE model_risk.model_validations IS 'Records details of model validation activities.';
COMMENT ON COLUMN model_risk.model_validations.validation_id IS 'Unique identifier for the model validation.';
COMMENT ON COLUMN model_risk.model_validations.model_id IS 'Foreign key referencing the validated model.';
COMMENT ON COLUMN model_risk.model_validations.validation_date IS 'Date the validation was performed.';
COMMENT ON COLUMN model_risk.model_validations.validator_user_id IS 'User who performed the validation.';
COMMENT ON COLUMN model_risk.model_validations.validation_result IS 'Result of the validation.';
COMMENT ON COLUMN model_risk.model_validations.findings IS 'Findings from the validation.';
COMMENT ON COLUMN model_risk.model_validations.recommendations IS 'Recommendations from the validation.';
COMMENT ON COLUMN model_risk.model_validations.created_at IS 'Timestamp when the validation record was created.';
COMMENT ON COLUMN model_risk.model_validations.updated_at IS 'Timestamp when the validation record was last updated.';

-- Trigger for model_risk.model_validations table
CREATE TRIGGER update_model_validations_updated_at
BEFORE UPDATE ON model_risk.model_validations
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: model_risk.vw_model_inventory
-- Description: Provides a comprehensive view of all models and their validation status.
CREATE OR REPLACE VIEW model_risk.vw_model_inventory AS
SELECT
    m.model_id,
    m.model_name,
    m.model_type,
    m.status,
    m.last_validation_date,
    m.next_validation_due_date,
    mv.validation_result AS latest_validation_result,
    u.username AS owner_username
FROM
    model_risk.models m
LEFT JOIN LATERAL (
    SELECT *
    FROM model_risk.model_validations
    WHERE model_id = m.model_id
    ORDER BY validation_date DESC
    LIMIT 1
) mv ON TRUE
LEFT JOIN
    core.users u ON m.owner_user_id = u.user_id;

COMMENT ON VIEW model_risk.vw_model_inventory IS 'Provides a comprehensive view of all models and their validation status.';

-- Stored Procedure: model_risk.sp_record_model_validation
-- Description: Records a new model validation result and updates the model''s validation dates.
CREATE OR REPLACE PROCEDURE model_risk.sp_record_model_validation(
    p_model_id UUID,
    p_validation_date DATE,
    p_validator_user_id UUID,
    p_validation_result VARCHAR,
    p_findings TEXT,
    p_recommendations TEXT,
    p_next_validation_due_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO model_risk.model_validations (
        model_id, validation_date, validator_user_id, validation_result, findings, recommendations
    )
    VALUES (
        p_model_id, p_validation_date, p_validator_user_id, p_validation_result, p_findings, p_recommendations
    );

    UPDATE model_risk.models
    SET
        last_validation_date = p_validation_date,
        next_validation_due_date = p_next_validation_due_date,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        model_id = p_model_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_validator_user_id,
        'MODEL_RISK_GOVERNANCE',
        'Model Risk Governance',
        'record_model_validation',
        'model_validation',
        p_model_id,
        NULL, jsonb_build_object('validation_result', p_validation_result, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE model_risk.sp_record_model_validation(UUID, DATE, UUID, VARCHAR, TEXT, TEXT, DATE) IS 'Records a new model validation result and updates the model''s validation dates.';

-- Create operational_risk schema
CREATE SCHEMA IF NOT EXISTS operational_risk;

-- Set search path for operational_risk schema
SET search_path TO operational_risk, public;

-- Table: operational_risk.operational_risks
-- Description: Stores identified operational risks.
CREATE TABLE operational_risk.operational_risks (
    risk_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100), -- e.g., Process, People, Systems, External Events
    severity VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    likelihood VARCHAR(50) NOT NULL, -- e.g., High, Medium, Low
    impact VARCHAR(50) NOT NULL, -- e.g., Financial, Reputational, Operational
    mitigation_plan TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Open, Mitigated, Closed
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.operational_risks IS 'Stores identified operational risks.';
COMMENT ON COLUMN operational_risk.operational_risks.risk_id IS 'Unique identifier for the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.risk_name IS 'Name of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.description IS 'Description of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.category IS 'Category of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.severity IS 'Severity of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.likelihood IS 'Likelihood of the operational risk occurring.';
COMMENT ON COLUMN operational_risk.operational_risks.impact IS 'Impact of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.mitigation_plan IS 'Plan to mitigate the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.status IS 'Current status of the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.owner_user_id IS 'User responsible for the operational risk.';
COMMENT ON COLUMN operational_risk.operational_risks.created_at IS 'Timestamp when the operational risk was created.';
COMMENT ON COLUMN operational_risk.operational_risks.updated_at IS 'Timestamp when the operational risk was last updated.';

-- Trigger for operational_risk.operational_risks table
CREATE TRIGGER update_operational_risks_updated_at
BEFORE UPDATE ON operational_risk.operational_risks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: operational_risk.risk_events
-- Description: Records actual operational risk events or incidents.
CREATE TABLE operational_risk.risk_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_id UUID REFERENCES operational_risk.operational_risks(risk_id) ON DELETE SET NULL,
    event_name VARCHAR(255) NOT NULL,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovery_date TIMESTAMP WITH TIME ZONE,
    category VARCHAR(100), -- e.g., System Failure, Human Error, External Fraud
    financial_impact DECIMAL(18, 2), -- Monetary impact of the event
    status VARCHAR(50) NOT NULL, -- e.g., Reported, Under Investigation, Resolved, Closed
    reported_by UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    resolution_details TEXT,
    closed_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.risk_events IS 'Records actual operational risk events or incidents.';
COMMENT ON COLUMN operational_risk.risk_events.event_id IS 'Unique identifier for the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.risk_id IS 'Foreign key referencing the associated operational risk.';
COMMENT ON COLUMN operational_risk.risk_events.event_name IS 'Name or title of the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.description IS 'Description of the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.event_date IS 'Date and time the event occurred.';
COMMENT ON COLUMN operational_risk.risk_events.discovery_date IS 'Date and time the event was discovered.';
COMMENT ON COLUMN operational_risk.risk_events.category IS 'Category of the risk event.';
COMMENT ON COLUMN operational_risk.risk_events.financial_impact IS 'Financial impact of the event.';
COMMENT ON COLUMN operational_risk.risk_events.status IS 'Current status of the event.';
COMMENT ON COLUMN operational_risk.risk_events.reported_by IS 'User who reported the event.';
COMMENT ON COLUMN operational_risk.risk_events.resolution_details IS 'Details of how the event was resolved.';
COMMENT ON COLUMN operational_risk.risk_events.closed_date IS 'Date and time the event was closed.';
COMMENT ON COLUMN operational_risk.risk_events.created_at IS 'Timestamp when the event record was created.';
COMMENT ON COLUMN operational_risk.risk_events.updated_at IS 'Timestamp when the event record was last updated.';

-- Trigger for operational_risk.risk_events table
CREATE TRIGGER update_risk_events_updated_at
BEFORE UPDATE ON operational_risk.risk_events
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: operational_risk.operational_controls
-- Description: Stores information about operational controls designed to mitigate risks.
CREATE TABLE operational_risk.operational_controls (
    control_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(100), -- e.g., Preventative, Detective, Corrective
    type VARCHAR(100), -- e.g., Manual, Automated
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Implemented, Under Review, Deficient
    last_tested_date DATE,
    next_test_due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.operational_controls IS 'Stores information about operational controls designed to mitigate risks.';
COMMENT ON COLUMN operational_risk.operational_controls.control_id IS 'Unique identifier for the operational control.';
COMMENT ON COLUMN operational_risk.operational_controls.control_name IS 'Name of the operational control.';
COMMENT ON COLUMN operational_risk.operational_controls.description IS 'Description of the operational control.';
COMMENT ON COLUMN operational_risk.operational_controls.category IS 'Category of the control (e.g., Preventative).';
COMMENT ON COLUMN operational_risk.operational_controls.type IS 'Type of the control (e.g., Manual, Automated).';
COMMENT ON COLUMN operational_risk.operational_controls.owner_user_id IS 'User responsible for the control.';
COMMENT ON COLUMN operational_risk.operational_controls.status IS 'Current status of the control.';
COMMENT ON COLUMN operational_risk.operational_controls.last_tested_date IS 'Date the control was last tested.';
COMMENT ON COLUMN operational_risk.operational_controls.next_test_due_date IS 'Date when the next control test is due.';
COMMENT ON COLUMN operational_risk.operational_controls.created_at IS 'Timestamp when the control record was created.';
COMMENT ON COLUMN operational_risk.operational_controls.updated_at IS 'Timestamp when the control record was last updated.';

-- Trigger for operational_risk.operational_controls table
CREATE TRIGGER update_operational_controls_updated_at
BEFORE UPDATE ON operational_risk.operational_controls
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: operational_risk.vw_risk_event_summary
-- Description: Provides a summary of operational risk events by category and status.
CREATE OR REPLACE VIEW operational_risk.vw_risk_event_summary AS
SELECT
    category,
    status,
    COUNT(event_id) AS total_events,
    SUM(financial_impact) AS total_financial_impact
FROM
    operational_risk.risk_events
GROUP BY
    category, status;

COMMENT ON VIEW operational_risk.vw_risk_event_summary IS 'Provides a summary of operational risk events by category and status.';

-- Stored Procedure: operational_risk.sp_report_risk_event
-- Description: Records a new operational risk event.
CREATE OR REPLACE PROCEDURE operational_risk.sp_report_risk_event(
    p_risk_id UUID,
    p_event_name VARCHAR,
    p_description TEXT,
    p_event_date TIMESTAMP WITH TIME ZONE,
    p_discovery_date TIMESTAMP WITH TIME ZONE,
    p_category VARCHAR,
    p_financial_impact DECIMAL,
    p_reported_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO operational_risk.risk_events (
        risk_id, event_name, description, event_date, discovery_date, category, financial_impact, status, reported_by
    )
    VALUES (
        p_risk_id, p_event_name, p_description, p_event_date, p_discovery_date, p_category, p_financial_impact, 'Reported', p_reported_by_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_reported_by_user_id,
        'OPERATIONAL_RISK_MANAGEMENT',
        'Operational Risk Management',
        'report_risk_event',
        'risk_event',
        (SELECT currval('operational_risk.risk_events_event_id_seq')), -- Get last inserted ID
        NULL, jsonb_build_object('event_name', p_event_name, 'category', p_category, 'financial_impact', p_financial_impact),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_report_risk_event(UUID, VARCHAR, TEXT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, VARCHAR, DECIMAL, UUID) IS 'Records a new operational risk event.';


-- ENHANCEMENTS FOR MODEL RISK GOVERNANCE SCHEMA

-- Table: model_risk.model_performance_metrics
-- Description: Stores performance metrics for models over time.
CREATE TABLE model_risk.model_performance_metrics (
    metric_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES model_risk.models(model_id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    metric_name VARCHAR(255) NOT NULL, -- e.g., Accuracy, Precision, Recall, F1-Score, AUC
    metric_value DECIMAL(18, 4) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (model_id, metric_date, metric_name)
);

COMMENT ON TABLE model_risk.model_performance_metrics IS 'Stores performance metrics for models over time.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_record_id IS 'Unique identifier for the metric record.';
COMMENT ON COLUMN model_risk.model_performance_metrics.model_id IS 'Foreign key referencing the model.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_date IS 'Date the metric was recorded.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_name IS 'Name of the performance metric.';
COMMENT ON COLUMN model_risk.model_performance_metrics.metric_value IS 'Value of the performance metric.';
COMMENT ON COLUMN model_risk.model_performance_metrics.created_at IS 'Timestamp when the record was created.';
COMMENT ON COLUMN model_risk.model_performance_metrics.updated_at IS 'Timestamp when the record was last updated.';

-- Trigger for model_risk.model_performance_metrics table
CREATE TRIGGER update_model_performance_metrics_updated_at
BEFORE UPDATE ON model_risk.model_performance_metrics
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: model_risk.vw_model_performance_summary
-- Description: Provides a summary of the latest performance metrics for each model.
CREATE OR REPLACE VIEW model_risk.vw_model_performance_summary AS
SELECT
    m.model_id,
    m.model_name,
    m.model_type,
    m.status,
    mpm.metric_name,
    mpm.metric_value AS latest_metric_value,
    mpm.metric_date AS latest_metric_date
FROM
    model_risk.models m
LEFT JOIN LATERAL (
    SELECT *
    FROM model_risk.model_performance_metrics
    WHERE model_id = m.model_id
    ORDER BY metric_date DESC
    LIMIT 1
) mpm ON TRUE;

COMMENT ON VIEW model_risk.vw_model_performance_summary IS 'Provides a summary of the latest performance metrics for each model.';

-- Stored Procedure: model_risk.sp_record_model_performance
-- Description: Records a new performance metric for a model.
CREATE OR REPLACE PROCEDURE model_risk.sp_record_model_performance(
    p_model_id UUID,
    p_metric_date DATE,
    p_metric_name VARCHAR,
    p_metric_value DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO model_risk.model_performance_metrics (
        model_id, metric_date, metric_name, metric_value
    )
    VALUES (
        p_model_id, p_metric_date, p_metric_name, p_metric_value
    )
    ON CONFLICT (model_id, metric_date, metric_name) DO UPDATE SET
        metric_value = EXCLUDED.metric_value,
        updated_at = CURRENT_TIMESTAMP;

    -- Log the action
    CALL core.sp_log_audit_event(
        NULL, -- Assuming system or automated process
        'MODEL_RISK_GOVERNANCE',
        'Model Risk Governance',
        'record_model_performance',
        'model_performance_metric',
        p_model_id,
        NULL, jsonb_build_object('metric_name', p_metric_name, 'metric_value', p_metric_value),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE model_risk.sp_record_model_performance(UUID, DATE, VARCHAR, DECIMAL) IS 'Records a new performance metric for a model.';

-- Materialized View: model_risk.mv_model_risk_dashboard
-- Description: Aggregates key metrics for the model risk dashboard.
CREATE MATERIALIZED VIEW model_risk.mv_model_risk_dashboard AS
SELECT
    (SELECT COUNT(*) FROM model_risk.models WHERE status = 'Approved') AS approved_models_count,
    (SELECT COUNT(*) FROM model_risk.models WHERE status = 'Under Review') AS models_under_review_count,
    (SELECT COUNT(*) FROM model_risk.models WHERE next_validation_due_date < CURRENT_DATE) AS overdue_validations_count,
    (SELECT COUNT(*) FROM model_risk.model_validations WHERE validation_result = 'Fail') AS failed_validations_count;

COMMENT ON MATERIALIZED VIEW model_risk.mv_model_risk_dashboard IS 'Aggregates key metrics for the model risk dashboard.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE model_risk.sp_refresh_mv_model_risk_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW model_risk.mv_model_risk_dashboard;
END;
$$;

COMMENT ON PROCEDURE model_risk.sp_refresh_mv_model_risk_dashboard() IS 'Refreshes the materialized view for model risk dashboard.';


-- ENHANCEMENTS FOR OPERATIONAL RISK MANAGEMENT SCHEMA

-- Table: operational_risk.control_effectiveness_assessments
-- Description: Records assessments of operational control effectiveness.
CREATE TABLE operational_risk.control_effectiveness_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES operational_risk.operational_controls(control_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    effectiveness_rating VARCHAR(50) NOT NULL, -- e.g., Effective, Partially Effective, Ineffective
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE operational_risk.control_effectiveness_assessments IS 'Records assessments of operational control effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessment_id IS 'Unique identifier for the control effectiveness assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.control_id IS 'Foreign key referencing the operational control assessed.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.effectiveness_rating IS 'Rating of the control''s effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.recommendations IS 'Recommendations for improving control effectiveness.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN operational_risk.control_effectiveness_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for operational_risk.control_effectiveness_assessments table
CREATE TRIGGER update_control_effectiveness_assessments_updated_at
BEFORE UPDATE ON operational_risk.control_effectiveness_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: operational_risk.vw_control_effectiveness_summary
-- Description: Provides a summary of operational control effectiveness.
CREATE OR REPLACE VIEW operational_risk.vw_control_effectiveness_summary AS
SELECT
    oc.control_id,
    oc.control_name,
    oc.category,
    cea.assessment_date AS last_assessment_date,
    cea.effectiveness_rating AS last_effectiveness_rating,
    cea.findings AS last_assessment_findings
FROM
    operational_risk.operational_controls oc
LEFT JOIN LATERAL (
    SELECT *
    FROM operational_risk.control_effectiveness_assessments
    WHERE control_id = oc.control_id
    ORDER BY assessment_date DESC
    LIMIT 1
) cea ON TRUE;

COMMENT ON VIEW operational_risk.vw_control_effectiveness_summary IS 'Provides a summary of operational control effectiveness.';

-- Stored Procedure: operational_risk.sp_record_control_effectiveness_assessment
-- Description: Records a new operational control effectiveness assessment.
CREATE OR REPLACE PROCEDURE operational_risk.sp_record_control_effectiveness_assessment(
    p_control_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_effectiveness_rating VARCHAR,
    p_findings TEXT,
    p_recommendations TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO operational_risk.control_effectiveness_assessments (
        control_id, assessment_date, assessor_user_id, effectiveness_rating, findings, recommendations
    )
    VALUES (
        p_control_id, p_assessment_date, p_assessor_user_id, p_effectiveness_rating, p_findings, p_recommendations
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'OPERATIONAL_RISK_MANAGEMENT',
        'Operational Risk Management',
        'record_control_effectiveness_assessment',
        'control_effectiveness_assessment',
        p_control_id,
        NULL, jsonb_build_object('effectiveness_rating', p_effectiveness_rating, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_record_control_effectiveness_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new operational control effectiveness assessment.';

-- Materialized View: operational_risk.mv_operational_risk_dashboard
-- Description: Aggregates key metrics for the operational risk dashboard.
CREATE MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard AS
SELECT
    (SELECT COUNT(*) FROM operational_risk.operational_risks WHERE status = 'Open') AS open_operational_risks_count,
    (SELECT COUNT(*) FROM operational_risk.risk_events WHERE status != 'Closed') AS active_risk_events_count,
    (SELECT SUM(financial_impact) FROM operational_risk.risk_events WHERE status != 'Closed') AS total_unresolved_financial_impact,
    (SELECT COUNT(*) FROM operational_risk.operational_controls WHERE status = 'Ineffective') AS ineffective_controls_count;

COMMENT ON MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard IS 'Aggregates key metrics for the operational risk dashboard.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE operational_risk.sp_refresh_mv_operational_risk_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW operational_risk.mv_operational_risk_dashboard;
END;
$$;

COMMENT ON PROCEDURE operational_risk.sp_refresh_mv_operational_risk_dashboard() IS 'Refreshes the materialized view for operational risk dashboard.';



-- Policy Management and Regulatory Compliance Management Schema



-- Create policy_management schema
CREATE SCHEMA IF NOT EXISTS policy_management;

-- Set search path for policy_management schema
SET search_path TO policy_management, public;

-- Table: policy_management.policies
-- Description: Stores organizational policies.
CREATE TABLE policy_management.policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    category VARCHAR(100), -- e.g., HR, IT, Finance, Risk
    effective_date DATE,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_due_at DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL, -- e.g., Draft, Approved, Under Review, Retired
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE policy_management.policies IS 'Stores organizational policies.';
COMMENT ON COLUMN policy_management.policies.policy_id IS 'Unique identifier for the policy.';
COMMENT ON COLUMN policy_management.policies.policy_name IS 'Name of the policy.';
COMMENT ON COLUMN policy_management.policies.description IS 'Description or content of the policy.';
COMMENT ON COLUMN policy_management.policies.version IS 'Version of the policy.';
COMMENT ON COLUMN policy_management.policies.category IS 'Category of the policy.';
COMMENT ON COLUMN policy_management.policies.effective_date IS 'Date when the policy became effective.';
COMMENT ON COLUMN policy_management.policies.last_reviewed_at IS 'Timestamp of the last review of the policy.';
COMMENT ON COLUMN policy_management.policies.next_review_due_at IS 'Date when the next review of the policy is due.';
COMMENT ON COLUMN policy_management.policies.owner_user_id IS 'User responsible for the policy.';
COMMENT ON COLUMN policy_management.policies.status IS 'Current status of the policy.';
COMMENT ON COLUMN policy_management.policies.created_at IS 'Timestamp when the policy was created.';
COMMENT ON COLUMN policy_management.policies.updated_at IS 'Timestamp when the policy was last updated.';

-- Trigger for policy_management.policies table
CREATE TRIGGER update_policies_updated_at
BEFORE UPDATE ON policy_management.policies
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: policy_management.policy_acknowledgements
-- Description: Tracks user acknowledgements of policies.
CREATE TABLE policy_management.policy_acknowledgements (
    acknowledgement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID NOT NULL REFERENCES policy_management.policies(policy_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES core.users(user_id) ON DELETE CASCADE,
    acknowledgement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (policy_id, user_id)
);

COMMENT ON TABLE policy_management.policy_acknowledgements IS 'Tracks user acknowledgements of policies.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.acknowledgement_id IS 'Unique identifier for the acknowledgement record.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.policy_id IS 'Foreign key referencing the acknowledged policy.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.user_id IS 'Foreign key referencing the user who acknowledged the policy.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.acknowledgement_date IS 'Timestamp when the policy was acknowledged.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.created_at IS 'Timestamp when the record was created.';
COMMENT ON COLUMN policy_management.policy_acknowledgements.updated_at IS 'Timestamp when the record was last updated.';

-- Trigger for policy_management.policy_acknowledgements table
CREATE TRIGGER update_policy_acknowledgements_updated_at
BEFORE UPDATE ON policy_management.policy_acknowledgements
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: policy_management.vw_policy_compliance_status
-- Description: Provides an overview of policy compliance status.
CREATE OR REPLACE VIEW policy_management.vw_policy_compliance_status AS
SELECT
    p.policy_id,
    p.policy_name,
    p.version,
    p.status,
    p.next_review_due_at,
    COUNT(pa.user_id) AS acknowledged_users_count,
    (SELECT COUNT(user_id) FROM core.users WHERE is_active = TRUE) AS total_active_users
FROM
    policy_management.policies p
LEFT JOIN
    policy_management.policy_acknowledgements pa ON p.policy_id = pa.policy_id
GROUP BY
    p.policy_id, p.policy_name, p.version, p.status, p.next_review_due_at;

COMMENT ON VIEW policy_management.vw_policy_compliance_status IS 'Provides an overview of policy compliance status.';

-- Stored Procedure: policy_management.sp_acknowledge_policy
-- Description: Records a user''s acknowledgement of a policy.
CREATE OR REPLACE PROCEDURE policy_management.sp_acknowledge_policy(
    p_policy_id UUID,
    p_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO policy_management.policy_acknowledgements (policy_id, user_id)
    VALUES (p_policy_id, p_user_id)
    ON CONFLICT (policy_id, user_id) DO UPDATE SET
        acknowledgement_date = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_user_id,
        'POLICY_MANAGEMENT',
        'Policy Management',
        'acknowledge_policy',
        'policy_acknowledgement',
        p_policy_id,
        NULL, jsonb_build_object('user_id', p_user_id, 'policy_id', p_policy_id),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_acknowledge_policy(UUID, UUID) IS 'Records a user''s acknowledgement of a policy.';

-- Create regulatory_compliance schema
CREATE SCHEMA IF NOT EXISTS regulatory_compliance;

-- Set search path for regulatory_compliance schema
SET search_path TO regulatory_compliance, public;

-- Table: regulatory_compliance.regulations
-- Description: Stores details of applicable regulations.
CREATE TABLE regulatory_compliance.regulations (
    regulation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_name VARCHAR(255) UNIQUE NOT NULL,
    jurisdiction VARCHAR(100), -- e.g., GDPR, CCPA, SOX, HIPAA
    description TEXT,
    effective_date DATE,
    last_updated_date DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.regulations IS 'Stores details of applicable regulations.';
COMMENT ON COLUMN regulatory_compliance.regulations.regulation_id IS 'Unique identifier for the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.regulation_name IS 'Name of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.jurisdiction IS 'Jurisdiction or type of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.description IS 'Description of the regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.effective_date IS 'Date when the regulation became effective.';
COMMENT ON COLUMN regulatory_compliance.regulations.last_updated_date IS 'Date when the regulation was last updated.';
COMMENT ON COLUMN regulatory_compliance.regulations.owner_user_id IS 'User responsible for tracking this regulation.';
COMMENT ON COLUMN regulatory_compliance.regulations.created_at IS 'Timestamp when the regulation record was created.';
COMMENT ON COLUMN regulatory_compliance.regulations.updated_at IS 'Timestamp when the regulation record was last updated.';

-- Trigger for regulatory_compliance.regulations table
CREATE TRIGGER update_regulations_updated_at
BEFORE UPDATE ON regulatory_compliance.regulations
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: regulatory_compliance.compliance_controls
-- Description: Maps internal controls to regulatory requirements.
CREATE TABLE regulatory_compliance.compliance_controls (
    control_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    control_name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL, -- e.g., Implemented, Partially Implemented, Not Implemented
    last_tested_date DATE,
    next_test_due_date DATE,
    owner_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.compliance_controls IS 'Maps internal controls to regulatory requirements.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.control_id IS 'Unique identifier for the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.regulation_id IS 'Foreign key referencing the regulation this control addresses.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.control_name IS 'Name of the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.description IS 'Description of the compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.status IS 'Current implementation status of the control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.last_tested_date IS 'Date the control was last tested for compliance.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.next_test_due_date IS 'Date when the next compliance test is due.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.owner_user_id IS 'User responsible for this compliance control.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.created_at IS 'Timestamp when the control record was created.';
COMMENT ON COLUMN regulatory_compliance.compliance_controls.updated_at IS 'Timestamp when the control record was last updated.';

-- Trigger for regulatory_compliance.compliance_controls table
CREATE TRIGGER update_compliance_controls_updated_at
BEFORE UPDATE ON regulatory_compliance.compliance_controls
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Table: regulatory_compliance.compliance_assessments
-- Description: Records assessments of compliance with regulations.
CREATE TABLE regulatory_compliance.compliance_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    assessment_date DATE NOT NULL,
    assessor_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    overall_result VARCHAR(50) NOT NULL, -- e.g., Compliant, Non-Compliant, Partially Compliant
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.compliance_assessments IS 'Records assessments of compliance with regulations.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessment_id IS 'Unique identifier for the compliance assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.regulation_id IS 'Foreign key referencing the regulation being assessed.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessment_date IS 'Date of the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.assessor_user_id IS 'User who performed the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.overall_result IS 'Overall result of the compliance assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.findings IS 'Findings from the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.recommendations IS 'Recommendations from the assessment.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.created_at IS 'Timestamp when the assessment record was created.';
COMMENT ON COLUMN regulatory_compliance.compliance_assessments.updated_at IS 'Timestamp when the assessment record was last updated.';

-- Trigger for regulatory_compliance.compliance_assessments table
CREATE TRIGGER update_compliance_assessments_updated_at
BEFORE UPDATE ON regulatory_compliance.compliance_assessments
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: regulatory_compliance.vw_regulation_compliance_summary
-- Description: Provides a summary of compliance status for each regulation.
CREATE OR REPLACE VIEW regulatory_compliance.vw_regulation_compliance_summary AS
SELECT
    r.regulation_id,
    r.regulation_name,
    r.jurisdiction,
    r.effective_date,
    r.last_updated_date,
    ca.overall_result AS latest_assessment_result,
    ca.assessment_date AS latest_assessment_date
FROM
    regulatory_compliance.regulations r
LEFT JOIN LATERAL (
    SELECT *
    FROM regulatory_compliance.compliance_assessments
    WHERE regulation_id = r.regulation_id
    ORDER BY assessment_date DESC
    LIMIT 1
) ca ON TRUE;

COMMENT ON VIEW regulatory_compliance.vw_regulation_compliance_summary IS 'Provides a summary of compliance status for each regulation.';

-- Stored Procedure: regulatory_compliance.sp_record_compliance_assessment
-- Description: Records a new compliance assessment result.
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_record_compliance_assessment(
    p_regulation_id UUID,
    p_assessment_date DATE,
    p_assessor_user_id UUID,
    p_overall_result VARCHAR,
    p_findings TEXT,
    p_recommendations TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO regulatory_compliance.compliance_assessments (
        regulation_id, assessment_date, assessor_user_id, overall_result, findings, recommendations
    )
    VALUES (
        p_regulation_id, p_assessment_date, p_assessor_user_id, p_overall_result, p_findings, p_recommendations
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_assessor_user_id,
        'REGULATORY_COMPLIANCE',
        'Regulatory Compliance Management',
        'record_compliance_assessment',
        'compliance_assessment',
        p_regulation_id,
        NULL, jsonb_build_object('overall_result', p_overall_result, 'findings', p_findings),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_record_compliance_assessment(UUID, DATE, UUID, VARCHAR, TEXT, TEXT) IS 'Records a new compliance assessment result.';


-- ENHANCEMENTS FOR POLICY MANAGEMENT SCHEMA

-- Table: policy_management.policy_versions
-- Description: Stores historical versions of policies.
CREATE TABLE policy_management.policy_versions (
    version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID NOT NULL REFERENCES policy_management.policies(policy_id) ON DELETE CASCADE,
    version_number VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    effective_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (policy_id, version_number)
);

COMMENT ON TABLE policy_management.policy_versions IS 'Stores historical versions of policies.';
COMMENT ON COLUMN policy_management.policy_versions.version_id IS 'Unique identifier for the policy version.';
COMMENT ON COLUMN policy_management.policy_versions.policy_id IS 'Foreign key referencing the policy.';
COMMENT ON COLUMN policy_management.policy_versions.version_number IS 'Version number of the policy.';
COMMENT ON COLUMN policy_management.policy_versions.content IS 'Full content of the policy version.';
COMMENT ON COLUMN policy_management.policy_versions.effective_date IS 'Date when this version became effective.';
COMMENT ON COLUMN policy_management.policy_versions.created_at IS 'Timestamp when the version record was created.';

-- View: policy_management.vw_policy_version_history
-- Description: Provides a history of all versions for a given policy.
CREATE OR REPLACE VIEW policy_management.vw_policy_version_history AS
SELECT
    p.policy_name,
    pv.version_number,
    pv.effective_date,
    pv.content,
    pv.created_at AS version_created_at
FROM
    policy_management.policies p
JOIN
    policy_management.policy_versions pv ON p.policy_id = pv.policy_id
ORDER BY
    p.policy_name, pv.effective_date DESC;

COMMENT ON VIEW policy_management.vw_policy_version_history IS 'Provides a history of all versions for a given policy.';

-- Stored Procedure: policy_management.sp_publish_new_policy_version
-- Description: Publishes a new version of a policy, archiving the old one.
CREATE OR REPLACE PROCEDURE policy_management.sp_publish_new_policy_version(
    p_policy_id UUID,
    p_new_version_number VARCHAR,
    p_new_content TEXT,
    p_effective_date DATE,
    p_updated_by_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_version_number VARCHAR;
    v_old_content TEXT;
BEGIN
    -- Archive current version
    SELECT version, description INTO v_old_version_number, v_old_content
    FROM policy_management.policies
    WHERE policy_id = p_policy_id;

    IF v_old_version_number IS NOT NULL THEN
        INSERT INTO policy_management.policy_versions (policy_id, version_number, content, effective_date)
        VALUES (p_policy_id, v_old_version_number, v_old_content, (SELECT effective_date FROM policy_management.policies WHERE policy_id = p_policy_id));
    END IF;

    -- Update policy with new version
    UPDATE policy_management.policies
    SET
        version = p_new_version_number,
        description = p_new_content, -- Assuming description holds the main content for simplicity
        effective_date = p_effective_date,
        last_reviewed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE
        policy_id = p_policy_id;

    -- Log the action
    CALL core.sp_log_audit_event(
        p_updated_by_user_id,
        'POLICY_MANAGEMENT',
        'Policy Management',
        'publish_new_policy_version',
        'policy',
        p_policy_id,
        jsonb_build_object('version', v_old_version_number),
        jsonb_build_object('version', p_new_version_number, 'effective_date', p_effective_date),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_publish_new_policy_version(UUID, VARCHAR, TEXT, DATE, UUID) IS 'Publishes a new version of a policy, archiving the old one.';

-- Materialized View: policy_management.mv_policy_acknowledgement_summary
-- Description: Summarizes policy acknowledgement status across all active users.
CREATE MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary AS
SELECT
    p.policy_id,
    p.policy_name,
    p.version,
    COUNT(DISTINCT pa.user_id) AS acknowledged_users_count,
    (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE) AS total_active_users,
    ROUND((COUNT(DISTINCT pa.user_id)::NUMERIC / (SELECT COUNT(DISTINCT user_id) FROM core.users WHERE is_active = TRUE)) * 100, 2) AS compliance_percentage
FROM
    policy_management.policies p
LEFT JOIN
    policy_management.policy_acknowledgements pa ON p.policy_id = pa.policy_id
GROUP BY
    p.policy_id, p.policy_name, p.version;

COMMENT ON MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary IS 'Summarizes policy acknowledgement status across all active users.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE policy_management.sp_refresh_mv_policy_acknowledgement_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW policy_management.mv_policy_acknowledgement_summary;
END;
$$;

COMMENT ON PROCEDURE policy_management.sp_refresh_mv_policy_acknowledgement_summary() IS 'Refreshes the materialized view for policy acknowledgement summary.';


-- ENHANCEMENTS FOR REGULATORY COMPLIANCE MANAGEMENT SCHEMA

-- Table: regulatory_compliance.regulatory_updates
-- Description: Tracks updates and changes to regulations.
CREATE TABLE regulatory_compliance.regulatory_updates (
    update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id UUID NOT NULL REFERENCES regulatory_compliance.regulations(regulation_id) ON DELETE CASCADE,
    update_date DATE NOT NULL,
    description TEXT NOT NULL,
    impact_assessment TEXT,
    responsible_user_id UUID REFERENCES core.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE regulatory_compliance.regulatory_updates IS 'Tracks updates and changes to regulations.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.update_id IS 'Unique identifier for the regulatory update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.regulation_id IS 'Foreign key referencing the regulation being updated.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.update_date IS 'Date of the regulatory update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.description IS 'Description of the update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.impact_assessment IS 'Assessment of the impact of the update on the organization.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.responsible_user_id IS 'User responsible for managing this update.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.created_at IS 'Timestamp when the update record was created.';
COMMENT ON COLUMN regulatory_compliance.regulatory_updates.updated_at IS 'Timestamp when the update record was last updated.';

-- Trigger for regulatory_compliance.regulatory_updates table
CREATE TRIGGER update_regulatory_updates_updated_at
BEFORE UPDATE ON regulatory_compliance.regulatory_updates
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- View: regulatory_compliance.vw_regulatory_change_tracker
-- Description: Provides a view of recent regulatory changes and their impact assessments.
CREATE OR REPLACE VIEW regulatory_compliance.vw_regulatory_change_tracker AS
SELECT
    ru.update_id,
    r.regulation_name,
    r.jurisdiction,
    ru.update_date,
    ru.description AS update_description,
    ru.impact_assessment,
    u.username AS responsible_user
FROM
    regulatory_compliance.regulatory_updates ru
JOIN
    regulatory_compliance.regulations r ON ru.regulation_id = r.regulation_id
LEFT JOIN
    core.users u ON ru.responsible_user_id = u.user_id
ORDER BY
    ru.update_date DESC;

COMMENT ON VIEW regulatory_compliance.vw_regulatory_change_tracker IS 'Provides a view of recent regulatory changes and their impact assessments.';

-- Stored Procedure: regulatory_compliance.sp_add_regulatory_update
-- Description: Adds a new regulatory update record.
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_add_regulatory_update(
    p_regulation_id UUID,
    p_update_date DATE,
    p_description TEXT,
    p_impact_assessment TEXT,
    p_responsible_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO regulatory_compliance.regulatory_updates (
        regulation_id, update_date, description, impact_assessment, responsible_user_id
    )
    VALUES (
        p_regulation_id, p_update_date, p_description, p_impact_assessment, p_responsible_user_id
    );

    -- Log the action
    CALL core.sp_log_audit_event(
        p_responsible_user_id,
        'REGULATORY_COMPLIANCE',
        'Regulatory Compliance Management',
        'add_regulatory_update',
        'regulatory_update',
        p_regulation_id,
        NULL, jsonb_build_object('update_date', p_update_date, 'description', p_description),
        NULL, NULL, NULL,
        FALSE
    );
END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_add_regulatory_update(UUID, DATE, TEXT, TEXT, UUID) IS 'Adds a new regulatory update record.';

-- Materialized View: regulatory_compliance.mv_overall_compliance_status
-- Description: Provides an aggregated view of overall regulatory compliance status.
CREATE MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status AS
SELECT
    (SELECT COUNT(*) FROM regulatory_compliance.regulations) AS total_regulations,
    (SELECT COUNT(*) FROM regulatory_compliance.compliance_assessments WHERE overall_result = 'Non-Compliant') AS non_compliant_assessments_count,
    (SELECT COUNT(*) FROM regulatory_compliance.compliance_controls WHERE status != 'Implemented') AS controls_not_implemented_count,
    (SELECT COUNT(*) FROM regulatory_compliance.regulatory_updates WHERE update_date > CURRENT_DATE - INTERVAL '90 days') AS recent_regulatory_updates_count;

COMMENT ON MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status IS 'Provides an aggregated view of overall regulatory compliance status.';

-- Stored Procedure to refresh materialized view
CREATE OR REPLACE PROCEDURE regulatory_compliance.sp_refresh_mv_overall_compliance_status()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW regulatory_compliance.mv_overall_compliance_status;
END;
$$;

COMMENT ON PROCEDURE regulatory_compliance.sp_refresh_mv_overall_compliance_status() IS 'Refreshes the materialized view for overall regulatory compliance status.';
