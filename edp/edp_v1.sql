--
--   ENTERPRISE DATA DICTIONARY PLATFORM
-- Version: 1.0
-- Date: 2025-05-15
-- Author: Awase Khirni Syed
-- Copyright: 2025 β ORI Inc.Canada. All Rights Reserved.
-- Description: Comprehensive schema for Data Dictionary
-- =============================================

-- Business Case: Manages databases data for the application.
-- Table Name: databases
-- Purpose: Stores detailed information about databases.
-- Additional Information: This table is central to the databases module.

-- Enable the UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create the table
CREATE TABLE databases (
    database_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    database_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_databases_updated_at
BEFORE UPDATE ON databases
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Business Case: Manages schemas data for the application.
-- Table Name: schemas
-- Purpose: Stores detailed information about schemas.
-- Additional Information: This table is central to the schemas module.

-- Create the schemas table
CREATE TABLE schemas (
    schema_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    schema_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    database_id UUID REFERENCES databases(database_id)
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_schemas_updated_at
BEFORE UPDATE ON schemas
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
-- Business Case: Manages tables data for the application.
-- Table Name: tables
-- Purpose: Stores detailed information about tables.
-- Additional Information: This table is central to the tables module.


-- Create the tables table
CREATE TABLE tables (
    table_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    row_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    schema_id UUID REFERENCES schemas(schema_id)
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_tables_updated_at
BEFORE UPDATE ON tables
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_tables_schema_id ON tables(schema_id);



-- Business Case: Manages columns data for the application.
-- Table Name: columns
-- Purpose: Stores detailed information about columns.
-- Additional Information: This table is central to the columns module.


-- Create the columns table
CREATE TABLE columns (
    column_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_name VARCHAR(255) NOT NULL,
    ordinal_position INTEGER NOT NULL,
    data_type VARCHAR(255) NOT NULL,
    character_maximum_length INTEGER,
    numeric_precision INTEGER,
    numeric_scale INTEGER,
    is_nullable BOOLEAN DEFAULT TRUE,
    default_value TEXT,
    is_primary_key BOOLEAN DEFAULT FALSE,
    is_auto_increment BOOLEAN DEFAULT FALSE,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    table_id UUID REFERENCES tables(table_id)
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_columns_updated_at
BEFORE UPDATE ON columns
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_columns_table_id ON columns(table_id);

-- Business Case: Manages foreign_keys data for the application.
-- Table Name: foreign_keys
-- Purpose: Stores detailed information about foreign_keys.
-- Additional Information: This table is central to the foreign_keys module.


-- -- Create the foreign_keys table
-- CREATE TABLE foreign_keys (
--     foreign_key_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
--     is_active BOOLEAN DEFAULT TRUE,
--     column_id UUID REFERENCES columns(column_id),
--     referenced_table_id UUID REFERENCES tables(table_id),
--     referenced_column_id UUID REFERENCES columns(column_id)
-- );

-- -- Function to update updated_at
-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = NOW();
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Trigger to call the function before update
-- CREATE TRIGGER update_foreign_keys_updated_at
-- BEFORE UPDATE ON foreign_keys
-- FOR EACH ROW
-- EXECUTE FUNCTION update_updated_at_column();

-- CREATE INDEX idx_foreign_keys_column_id ON foreign_keys(column_id);
-- CREATE INDEX idx_foreign_keys_referenced_table_id ON foreign_keys(referenced_table_id);
-- CREATE INDEX idx_foreign_keys_referenced_column_id ON foreign_keys(referenced_column_id);


-- alternative design strategy 
CREATE TABLE foreign_key_constraints (
    constraint_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    constraint_name VARCHAR(255) NOT NULL,
    table_id UUID NOT NULL REFERENCES tables(table_id),
    referenced_table_id UUID NOT NULL REFERENCES tables(table_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE foreign_key_columns (
    constraint_id UUID NOT NULL REFERENCES foreign_key_constraints(constraint_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    referenced_column_id UUID NOT NULL REFERENCES columns(column_id),
    ordinal_position INTEGER NOT NULL,
    PRIMARY KEY (constraint_id, column_id, referenced_column_id)
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for foreign_key_constraints
CREATE TRIGGER update_foreign_key_constraints_updated_at
BEFORE UPDATE ON foreign_key_constraints
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Indexes for foreign_key_constraints
CREATE INDEX idx_fk_constraints_table_id ON foreign_key_constraints(table_id);
CREATE INDEX idx_fk_constraints_referenced_table_id ON foreign_key_constraints(referenced_table_id);

-- Indexes for foreign_key_columns
CREATE INDEX idx_fk_columns_constraint_id ON foreign_key_columns(constraint_id);
CREATE INDEX idx_fk_columns_column_id ON foreign_key_columns(column_id);
CREATE INDEX idx_fk_columns_referenced_column_id ON foreign_key_columns(referenced_column_id);



-- Business Case: Manages users data for the application.
-- Table Name: users
-- Purpose: Stores detailed information about users.
-- Additional Information: This table is central to the users module.


-- Create the users table
CREATE TABLE users (
    user_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    password_hash TEXT NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(255) DEFAULT 'UTC'
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
	
	
	
-- Business Case: Manages roles data for the application.
-- Table Name: roles
-- Purpose: Stores detailed information about roles.
-- Additional Information: This table is central to the roles module.


-- Create the roles table
CREATE TABLE roles (
    role_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    role_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_system_role BOOLEAN DEFAULT FALSE
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Index for system roles
CREATE INDEX idx_roles_is_system_role ON roles(is_system_role);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index on user activity
CREATE INDEX idx_users_is_active ON users(is_active);

-- Index on last_login for login tracking/reporting
CREATE INDEX idx_users_last_login ON users(last_login);


-- Business Case: Manages user_roles data for the application.
-- Table Name: user_roles
-- Purpose: Stores detailed information about user_roles.
-- Additional Information: This table is central to the user_roles module.


-- Create the user_roles table
CREATE TABLE user_roles (
    user_role_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure a user can't be assigned the same role more than once
    UNIQUE (user_id, role_id)
);

-- Index for user-based lookups
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

-- Index for role-based lookups
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);


-- Business Case: Manages permissions data for the application.
-- Table Name: permissions
-- Purpose: Stores detailed information about permissions.
-- Additional Information: This table is central to the permissions module.


-- Create the permissions table
CREATE TABLE permissions (
    permission_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    permission_name VARCHAR(255) NOT NULL UNIQUE, -- e.g., 'read:project', 'delete:database'
    description TEXT NOT NULL,
    resource_type VARCHAR(255) NOT NULL, -- e.g., 'project', 'database'
    action VARCHAR(255) NOT NULL, -- e.g., 'read', 'write', 'delete'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_permissions_updated_at
BEFORE UPDATE ON permissions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Index for permission lookups
CREATE INDEX idx_permissions_resource_action ON permissions(resource_type, action);


-- Business Case: Manages role_permissions data for the application.
-- Table Name: role_permissions
-- Purpose: Stores detailed information about role_permissions.
-- Additional Information: This table is central to the role_permissions module.

-- Create the role_permissions table
CREATE TABLE role_permissions (
    role_permission_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(role_id),
    permission_id UUID NOT NULL REFERENCES permissions(permission_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate permission assignments for the same role
    UNIQUE (role_id, permission_id)
);

-- Index for role-based lookups
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);

-- Index for permission-based lookups
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);


-- Business Case: User Permissions Lookup
-- View Name: user_permissions
-- Purpose: Aggregate all permissions assigned to users through their roles
-- Why It Matters:
--   - Enables fast permission checks in applications
--   - Supports role-based access control (RBAC)
--   - Simplifies security audits and user access reviews

CREATE OR REPLACE VIEW user_permissions AS
SELECT
    u.user_id,
    u.first_name || ' ' || u.last_name AS full_name,
    r.role_id,
    r.role_name,
    p.permission_id,
    p.permission_name,
    p.description AS permission_description,
    p.resource_type,
    p.action,
    ur.assigned_at AS user_role_assigned_at,
    rp.assigned_at AS role_permission_assigned_at
FROM
    users u
JOIN
    user_roles ur ON u.user_id = ur.user_id
JOIN
    roles r ON ur.role_id = r.role_id
JOIN
    role_permissions rp ON r.role_id = rp.role_id
JOIN
    permissions p ON rp.permission_id = p.permission_id;


--view select 
-- SELECT * FROM user_permissions
-- WHERE user_id = 'some-uuid' AND action = 'read' AND resource_type = 'project';
SELECT * FROM user_permissions;


  -- Business Case: Manages column_security_tags data for the application.
    -- Table Name: column_security_tags
    -- Purpose: Stores detailed information about column_security_tags.
    -- Additional Information: This table is central to the column_security_tags module.

    CREATE TABLE column_security_tags (
        security_tag_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        column_id UUID NOT NULL REFERENCES columns(column_id),
        is_sensitive BOOLEAN DEFAULT FALSE,
        encryption_algorithm VARCHAR(255),
        masking_type VARCHAR(255),
        masking_rule TEXT,
        access_control_policy TEXT,
        data_sovereignty_country VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );


    -- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_column_security_tags_updated_at
BEFORE UPDATE ON column_security_tags
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for column-based lookups
CREATE INDEX idx_column_security_tags_column_id ON column_security_tags(column_id);

-- Index for filtering by sensitivity flag
CREATE INDEX idx_column_security_tags_is_sensitive ON column_security_tags(is_sensitive);

-- Index for data sovereignty compliance
CREATE INDEX idx_column_security_tags_data_sovereignty ON column_security_tags(data_sovereignty_country);



-- Business Case: Manages compliance tags for regulatory standards
-- Table Name: compliance_tags
-- Purpose: Stores detailed information about compliance tags
-- Additional Information: Used to associate data objects with compliance standards like GDPR, HIPAA, SOC2

CREATE TABLE compliance_tags (
    compliance_tag_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tag_name VARCHAR(255) NOT NULL UNIQUE, -- e.g., 'GDPR', 'HIPAA', 'SOC2'
    description TEXT NOT NULL,
    regulation_standard VARCHAR(255), -- e.g., 'GDPR Article 5', 'HIPAA Title II'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_compliance_tags_updated_at
BEFORE UPDATE ON compliance_tags
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for compliance tag lookups
CREATE INDEX idx_compliance_tags_tag_name ON compliance_tags(tag_name);

-- Index for filtering by regulation standard
CREATE INDEX idx_compliance_tags_regulation_standard ON compliance_tags(regulation_standard);


-- Business Case: Manages column_compliance_mapping data for the application.
-- Table Name: column_compliance_mapping
-- Purpose: Stores detailed information about column_compliance_mapping.
-- Additional Information: This table is central to the column_compliance_mapping module.

CREATE TABLE column_compliance_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    compliance_tag_id UUID NOT NULL REFERENCES compliance_tags(compliance_tag_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate mappings
    UNIQUE (column_id, compliance_tag_id)
);

-- Index for column-based lookups
CREATE INDEX idx_column_compliance_mapping_column_id ON column_compliance_mapping(column_id);

-- Index for compliance tag-based lookups
CREATE INDEX idx_column_compliance_mapping_tag_id ON column_compliance_mapping(compliance_tag_id);


--- view: to list all compliance tags associated with each column for easy querying and reporting 
CREATE OR REPLACE VIEW column_compliance_tags AS
SELECT
    c.column_id,
    c.column_name,
    t.table_id,
    t.table_name,
    s.schema_id,
    s.schema_name,
    d.database_id,
    d.database_name,
    ct.compliance_tag_id,
    ct.tag_name,
    ct.description AS tag_description,
    ct.regulation_standard,
    cc.created_at AS mapped_at
FROM
    column_compliance_mapping cc
JOIN
    columns c ON cc.column_id = c.column_id
JOIN
    tables t ON c.table_id = t.table_id
JOIN
    schemas s ON t.schema_id = s.schema_id
JOIN
    databases d ON s.database_id = d.database_id
JOIN
    compliance_tags ct ON cc.compliance_tag_id = ct.compliance_tag_id;
	
-- function: to check if a specific column has a specific compliance tag assigned 
CREATE OR REPLACE FUNCTION has_compliance_tag(
    target_column_id UUID,
    target_tag_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    tag_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO tag_count
    FROM column_compliance_mapping
    WHERE column_id = target_column_id
      AND compliance_tag_id = target_tag_id;

    RETURN tag_count > 0;
END;
$$ LANGUAGE plpgsql;


--- Table: to log changes (inserts, updates, deletes) to the column compliance mapping for audit and compliance reporting 
CREATE TABLE column_compliance_mapping_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mapping_id UUID,
    column_id UUID,
    compliance_tag_id UUID,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);


CREATE OR REPLACE FUNCTION log_column_compliance_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_compliance_mapping_history (
            mapping_id, column_id, compliance_tag_id, action_type
        )
        VALUES (
            NEW.mapping_id, NEW.column_id, NEW.compliance_tag_id, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_compliance_mapping_history (
            mapping_id, column_id, compliance_tag_id, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.compliance_tag_id, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_compliance_mapping_history (
            mapping_id, column_id, compliance_tag_id, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.compliance_tag_id, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_column_compliance_mapping_audit
AFTER INSERT OR UPDATE OR DELETE ON column_compliance_mapping
FOR EACH ROW EXECUTE FUNCTION log_column_compliance_changes();


-- Business Case: Manages data_owners data for the application.
-- Table Name: data_owners
-- Purpose: Stores detailed information about data_owners.
-- Additional Information: This table is central to the data_owners module.

-- Table: data_owners
CREATE TABLE data_owners (
    owner_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department VARCHAR(255),
    role VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Optional: Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_data_owners_updated_at
BEFORE UPDATE ON data_owners
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Table: column_data_owners
CREATE TABLE column_data_owners (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    owner_id UUID NOT NULL REFERENCES data_owners(owner_id),
    assigned_by UUID REFERENCES data_owners(owner_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (column_id, owner_id)
);

-- Optional: Indexes
CREATE INDEX idx_column_data_owners_column_id ON column_data_owners(column_id);
CREATE INDEX idx_column_data_owners_owner_id ON column_data_owners(owner_id);

-- View: column_owners
-- Purpose: Show column ownership with full context
CREATE OR REPLACE VIEW column_owners AS
SELECT
    cdo.mapping_id,
    cdo.assigned_at,
    owner.owner_id,
    owner.name AS owner_name,
    owner.email AS owner_email,
    owner.department,
    owner.role,
    c.column_id,
    c.column_name,
    t.table_id,
    t.table_name,
    s.schema_id,
    s.schema_name,
    d.database_id,
    d.database_name
FROM
    column_data_owners cdo
JOIN
    data_owners owner ON cdo.owner_id = owner.owner_id
JOIN
    columns c ON cdo.column_id = c.column_id
JOIN
    tables t ON c.table_id = t.table_id
JOIN
    schemas s ON t.schema_id = s.schema_id
JOIN
    databases d ON s.database_id = d.database_id;


  -- Business Case: Manages column_ownership data for the application.
    -- Table Name: column_ownership
    -- Purpose: Stores detailed information about column_ownership.
    -- Additional Information: This table is central to the column_ownership module.

    CREATE TABLE column_ownership (
        ownership_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
        column_id UUID NOT NULL REFERENCES columns(column_id),
        data_owner_id UUID REFERENCES data_owners(owner_id),
        data_steward_id UUID REFERENCES data_owners(owner_id),
        business_owner_id UUID REFERENCES data_owners(owner_id),
        technical_owner_id UUID REFERENCES data_owners(owner_id),
        replacement_column_id UUID REFERENCES columns(column_id),
        is_deprecated BOOLEAN DEFAULT FALSE,
        deprecation_date TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );


    -- Function to update updated_at
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    -- Trigger to call the function before update
    CREATE TRIGGER update_column_ownership_updated_at
    BEFORE UPDATE ON column_ownership
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

    -- Index for column-based lookups
CREATE INDEX idx_column_ownership_column_id ON column_ownership(column_id);

-- Indexes for owner-based lookups
CREATE INDEX idx_column_ownership_data_owner_id ON column_ownership(data_owner_id);
CREATE INDEX idx_column_ownership_data_steward_id ON column_ownership(data_steward_id);
CREATE INDEX idx_column_ownership_business_owner_id ON column_ownership(business_owner_id);
CREATE INDEX idx_column_ownership_technical_owner_id ON column_ownership(technical_owner_id);

-- Index for replacement column lookups
CREATE INDEX idx_column_ownership_replacement_column_id ON column_ownership(replacement_column_id);


--View: to show ownership details per column 
CREATE OR REPLACE VIEW column_ownership_details AS
SELECT
    co.ownership_id,
    co.column_id,
    c.column_name,
    t.table_id,
    t.table_name,
    s.schema_id,
    s.schema_name,
    d.database_id,
    d.database_name,
    co.is_deprecated,
    co.deprecation_date,
    co.replacement_column_id,
    data_owner.name AS data_owner_name,
    data_owner.email AS data_owner_email,
    data_steward.name AS data_steward_name,
    data_steward.email AS data_steward_email,
    business_owner.name AS business_owner_name,
    business_owner.email AS business_owner_email,
    technical_owner.name AS technical_owner_name,
    technical_owner.email AS technical_owner_email,
    co.created_at,
    co.updated_at
FROM
    column_ownership co
LEFT JOIN columns c ON co.column_id = c.column_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_owners data_owner ON co.data_owner_id = data_owner.owner_id
LEFT JOIN data_owners data_steward ON co.data_steward_id = data_steward.owner_id
LEFT JOIN data_owners business_owner ON co.business_owner_id = business_owner.owner_id
LEFT JOIN data_owners technical_owner ON co.technical_owner_id = technical_owner.owner_id;


---table: to log changes to column ownerships (inserts, updates, deletes) for auditing and compliance reporting 
CREATE TABLE column_ownership_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    ownership_id UUID,
    column_id UUID,
    data_owner_id UUID,
    data_steward_id UUID,
    business_owner_id UUID,
    technical_owner_id UUID,
    replacement_column_id UUID,
    is_deprecated BOOLEAN,
    deprecation_date TIMESTAMP WITH TIME ZONE,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user,
    action_type VARCHAR(10) NOT NULL -- 'INSERT', 'UPDATE', 'DELETE'
);


-- Trigger Funcition
CREATE OR REPLACE FUNCTION log_column_ownership_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_ownership_history (
            ownership_id, column_id, data_owner_id, data_steward_id,
            business_owner_id, technical_owner_id, replacement_column_id,
            is_deprecated, deprecation_date, action_type
        )
        VALUES (
            NEW.ownership_id, NEW.column_id, NEW.data_owner_id, NEW.data_steward_id,
            NEW.business_owner_id, NEW.technical_owner_id, NEW.replacement_column_id,
            NEW.is_deprecated, NEW.deprecation_date, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_ownership_history (
            ownership_id, column_id, data_owner_id, data_steward_id,
            business_owner_id, technical_owner_id, replacement_column_id,
            is_deprecated, deprecation_date, action_type
        )
        VALUES (
            OLD.ownership_id, OLD.column_id, OLD.data_owner_id, OLD.data_steward_id,
            OLD.business_owner_id, OLD.technical_owner_id, OLD.replacement_column_id,
            OLD.is_deprecated, OLD.deprecation_date, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_ownership_history (
            ownership_id, column_id, data_owner_id, data_steward_id,
            business_owner_id, technical_owner_id, replacement_column_id,
            is_deprecated, deprecation_date, action_type
        )
        VALUES (
            OLD.ownership_id, OLD.column_id, OLD.data_owner_id, OLD.data_steward_id,
            OLD.business_owner_id, OLD.technical_owner_id, OLD.replacement_column_id,
            OLD.is_deprecated, OLD.deprecation_date, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_column_ownership_audit
AFTER INSERT OR UPDATE OR DELETE ON column_ownership
FOR EACH ROW EXECUTE FUNCTION log_column_ownership_changes();


-- to get current ownership information for a specific column
CREATE OR REPLACE FUNCTION get_column_ownership(target_column_id UUID)
RETURNS TABLE (
    ownership_id UUID,
    column_name VARCHAR,
    data_owner_name VARCHAR,
    data_steward_name VARCHAR,
    business_owner_name VARCHAR,
    technical_owner_name VARCHAR,
    is_deprecated BOOLEAN,
    deprecation_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        co.ownership_id,
        c.column_name,
        data_owner.name AS data_owner_name,
        data_steward.name AS data_steward_name,
        business_owner.name AS business_owner_name,
        technical_owner.name AS technical_owner_name,
        co.is_deprecated,
        co.deprecation_date
    FROM
        column_ownership co
    JOIN columns c ON co.column_id = c.column_id
    LEFT JOIN data_owners data_owner ON co.data_owner_id = data_owner.owner_id
    LEFT JOIN data_owners data_steward ON co.data_steward_id = data_steward.owner_id
    LEFT JOIN data_owners business_owner ON co.business_owner_id = business_owner.owner_id
    LEFT JOIN data_owners technical_owner ON co.technical_owner_id = technical_owner.owner_id
    WHERE
        co.column_id = target_column_id;
END;
$$ LANGUAGE plpgsql;


-- View: To help us track who changed ownership, see when and what changed, view before and after values 
--- similar to react time travel using redux design pattern
-- this would also support compliance and governance reviews 
CREATE OR REPLACE VIEW column_ownership_audit AS
SELECT
    h.changed_at,
    h.changed_by,
    h.action_type,
    
    -- Column Info
    h.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    
    -- Old values (for UPDATE)
    old_owners.name AS old_data_owner_name,
    old_stewards.name AS old_data_steward_name,
    old_business_owners.name AS old_business_owner_name,
    old_technical_owners.name AS old_technical_owner_name,
    h.is_deprecated AS old_is_deprecated,
    h.deprecation_date AS old_deprecation_date,
    
    -- New values (for INSERT / UPDATE)
    new_owners.name AS new_data_owner_name,
    new_stewards.name AS new_data_steward_name,
    new_business_owners.name AS new_business_owner_name,
    new_technical_owners.name AS new_technical_owner_name,
    co.is_deprecated AS new_is_deprecated,
    co.deprecation_date AS new_deprecation_date
FROM
    column_ownership_history h
LEFT JOIN column_ownership co ON h.ownership_id = co.ownership_id
LEFT JOIN columns c ON h.column_id = c.column_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN databases d ON s.database_id = d.database_id

-- Join for new values
LEFT JOIN data_owners new_owners ON co.data_owner_id = new_owners.owner_id
LEFT JOIN data_owners new_stewards ON co.data_steward_id = new_stewards.owner_id
LEFT JOIN data_owners new_business_owners ON co.business_owner_id = new_business_owners.owner_id
LEFT JOIN data_owners new_technical_owners ON co.technical_owner_id = new_technical_owners.owner_id

-- Join for old values (from history)
LEFT JOIN data_owners old_owners ON h.data_owner_id = old_owners.owner_id
LEFT JOIN data_owners old_stewards ON h.data_steward_id = old_stewards.owner_id
LEFT JOIN data_owners old_business_owners ON h.business_owner_id = old_business_owners.owner_id
LEFT JOIN data_owners old_technical_owners ON h.technical_owner_id = old_technical_owners.owner_id;


-- compact view - a summary dashboard view 
CREATE OR REPLACE VIEW column_ownership_audit_summary AS
SELECT
    changed_at,
    changed_by,
    action_type,
    column_name,
    table_name,
    schema_name,
    database_name,
    old_data_owner_name,
    new_data_owner_name,
    old_data_steward_name,
    new_data_steward_name,
    old_business_owner_name,
    new_business_owner_name,
    old_technical_owner_name,
    new_technical_owner_name,
    old_is_deprecated,
    new_is_deprecated
FROM
    column_ownership_audit;
	
-- function: create a function to get audit hisstory for a specific column	
	CREATE OR REPLACE FUNCTION get_column_ownership_audit(column_id UUID)
RETURNS TABLE (
    changed_at TIMESTAMP WITH TIME ZONE,
    changed_by TEXT,
    action_type VARCHAR,
    column_name VARCHAR,
    old_data_owner_name VARCHAR,
    new_data_owner_name VARCHAR,
    old_data_steward_name VARCHAR,
    new_data_steward_name VARCHAR,
    old_business_owner_name VARCHAR,
    new_business_owner_name VARCHAR,
    old_technical_owner_name VARCHAR,
    new_technical_owner_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.changed_at,
        a.changed_by,
        a.action_type,
        a.column_name,
        a.old_data_owner_name,
        a.new_data_owner_name,
        a.old_data_steward_name,
        a.new_data_steward_name,
        a.old_business_owner_name,
        a.new_business_owner_name,
        a.old_technical_owner_name,
        a.new_technical_owner_name
    FROM
        column_ownership_audit a
    WHERE
        a.column_id = column_id;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Manages retention_policies data for the application.
-- Table Name: retention_policies
-- Purpose: Stores detailed information about retention_policies.
-- Additional Information: This table is central to the retention_policies module.

CREATE TABLE retention_policies (
    policy_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    retention_period_days INTEGER,
    archive_period_days INTEGER,
    purge_after_days INTEGER,
    legal_hold_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_retention_policies_updated_at
BEFORE UPDATE ON retention_policies
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for policy name lookups
CREATE INDEX idx_retention_policies_name ON retention_policies(policy_name);

-- Index for legal hold filtering
CREATE INDEX idx_retention_policies_legal_hold ON retention_policies(legal_hold_required);


-- Table: column_retention_policies
-- Purpose: Associate retention policies with specific columns
CREATE TABLE column_retention_policies (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    policy_id UUID NOT NULL REFERENCES retention_policies(policy_id),
    assigned_by UUID REFERENCES data_owners(owner_id), -- optional
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate policy assignments to the same column
    UNIQUE (column_id, policy_id)
);


-- Index for column-based lookups
CREATE INDEX idx_column_retention_column_id ON column_retention_policies(column_id);

-- Index for policy-based lookups
CREATE INDEX idx_column_retention_policy_id ON column_retention_policies(policy_id);

-- Index for assigned_by field
CREATE INDEX idx_column_retention_assigned_by ON column_retention_policies(assigned_by);

-- View: to show retention rules per column, with full metadata
CREATE OR REPLACE VIEW column_retention_rules AS
SELECT
    crp.mapping_id,
    crp.assigned_at,
    p.policy_id,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required,
    c.column_id,
    c.column_name,
    t.table_id,
    t.table_name,
    s.schema_id,
    s.schema_name,
    d.database_id,
    d.database_name,
    owner.name AS assigned_by_name,
    owner.email AS assigned_by_email
FROM
    column_retention_policies crp
JOIN
    retention_policies p ON crp.policy_id = p.policy_id
JOIN
    columns c ON crp.column_id = c.column_id
JOIN
    tables t ON c.table_id = t.table_id
JOIN
    schemas s ON t.schema_id = s.schema_id
JOIN
    databases d ON s.database_id = d.database_id
LEFT JOIN
    data_owners owner ON crp.assigned_by = owner.owner_id;
	
-- Table: column retention policies history 
CREATE TABLE column_retention_policies_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mapping_id UUID,
    column_id UUID,
    policy_id UUID,
    assigned_by UUID,
    assigned_at TIMESTAMP WITH TIME ZONE,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);


CREATE OR REPLACE FUNCTION log_column_retention_policy_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_retention_policies_history (
            mapping_id, column_id, policy_id, assigned_by, assigned_at, action_type
        )
        VALUES (
            NEW.mapping_id, NEW.column_id, NEW.policy_id, NEW.assigned_by, NEW.assigned_at, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_retention_policies_history (
            mapping_id, column_id, policy_id, assigned_by, assigned_at, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.policy_id, OLD.assigned_by, OLD.assigned_at, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_retention_policies_history (
            mapping_id, column_id, policy_id, assigned_by, assigned_at, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.policy_id, OLD.assigned_by, OLD.assigned_at, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_column_retention_policies_audit
AFTER INSERT OR UPDATE OR DELETE ON column_retention_policies
FOR EACH ROW EXECUTE FUNCTION log_column_retention_policy_changes();


-- Business Case: Retention Coverage Dashboard
-- Purpose: Provide a centralized view to show retention policy coverage across columns
-- Why It Matters:
--   - Helps assess how many columns have retention rules applied
--   - Identifies gaps in data lifecycle management
--   - Supports compliance and audit reporting

CREATE OR REPLACE VIEW retention_coverage_dashboard AS
SELECT
    d.database_name,
    s.schema_name,
    t.table_name,
    c.column_name,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required,
    crp.assigned_at,
    owner.name AS assigned_by_name
FROM
    columns c
LEFT JOIN column_retention_policies crp ON c.column_id = crp.column_id
LEFT JOIN retention_policies p ON crp.policy_id = p.policy_id
LEFT JOIN data_owners owner ON crp.assigned_by = owner.owner_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id;

-- Business Case: Retention Policy Checker
-- Purpose: Determine whether a specific column has a retention policy assigned
-- Why It Matters:
--   - Used in application logic to enforce policy compliance
--   - Helps with automated audits
--   - Useful in UI to show policy status

CREATE OR REPLACE FUNCTION has_retention_policy(target_column_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM column_retention_policies
    WHERE column_id = target_column_id;

    RETURN policy_count > 0;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Retention Coverage Summary (by Schema)
-- Purpose: Show retention policy coverage aggregated at the schema level
-- Why It Matters:
--   - Helps identify schemas with low retention policy coverage
--   - Supports compliance and audit reporting
--   - Useful for high-level dashboards

CREATE OR REPLACE VIEW retention_coverage_summary_by_schema AS
SELECT
    d.database_name,
    s.schema_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT p.policy_id) AS columns_with_policy,
    ROUND(
        (COUNT(DISTINCT p.policy_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
GROUP BY
    d.database_name,
    s.schema_name;
	
	
	-- Business Case: Retention Coverage Summary (by Database)
-- Purpose: Show retention policy coverage aggregated at the database level
-- Why It Matters:
--   - Helps identify databases with low retention policy coverage
--   - Useful for executive dashboards and compliance reporting

CREATE OR REPLACE VIEW retention_coverage_summary_by_database AS
SELECT
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT p.policy_id) AS columns_with_policy,
    ROUND(
        (COUNT(DISTINCT p.policy_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
GROUP BY
    d.database_name;
	
	
-- Business Case: Policy Compliance Scorecard
-- Purpose: Provide a centralized scorecard to measure retention policy compliance
-- Why It Matters:
--   - Helps track compliance with internal/external data lifecycle policies
--   - Supports audit and regulatory reporting
--   - Enables governance teams to identify and close gaps

CREATE OR REPLACE VIEW policy_compliance_scorecard AS
SELECT
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT p.column_id) AS columns_with_retention_policy,
    ROUND(
        (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS compliance_status
FROM
    columns c
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id;


-- Business Case: Schema-Level Policy Compliance Scorecard
-- Purpose: Show compliance status per schema for governance and reporting
-- Why It Matters:
--   - Helps identify low-compliance schemas
--   - Useful for governance teams and auditors

CREATE OR REPLACE VIEW policy_compliance_scorecard_by_schema AS
SELECT
    d.database_name,
    s.schema_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT p.column_id) AS columns_with_retention_policy,
    ROUND(
        (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
GROUP BY
    d.database_name,
    s.schema_name;
	
	
-- Business Case: Database-Level Policy Compliance Scorecard
-- Purpose: Show compliance status per database for executive reporting
-- Why It Matters:
--   - Helps prioritize databases for policy coverage improvement
--   - Useful for executive dashboards

CREATE OR REPLACE VIEW policy_compliance_scorecard_by_database AS
SELECT
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT p.column_id) AS columns_with_retention_policy,
    ROUND(
        (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT p.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
GROUP BY
    d.database_name;
	
	
-- Business Case: Policy Compliance History
-- Purpose: Store daily snapshots of retention policy coverage for historical analysis
-- Why It Matters:
--   - Enables time-series analysis of compliance trends
--   - Supports audits and regulatory reporting
--   - Helps track progress toward compliance goals

CREATE TABLE policy_compliance_history (
    snapshot_date DATE DEFAULT CURRENT_DATE PRIMARY KEY,
    total_columns INTEGER NOT NULL,
    columns_with_retention_policy INTEGER NOT NULL,
    coverage_percentage NUMERIC(5, 2) NOT NULL,
    compliance_status VARCHAR(10) NOT NULL
);


-- Business Case: Capture Policy Compliance Snapshot
-- Purpose: Take a daily snapshot of retention policy coverage
-- Why It Matters:
--   - Provides historical data for dashboards and audits
--   - Ensures consistent and automated compliance tracking

CREATE OR REPLACE FUNCTION capture_policy_compliance_snapshot()
RETURNS VOID AS $$
DECLARE
    total_cols INTEGER;
    policy_cols INTEGER;
    coverage NUMERIC;
    status VARCHAR;
BEGIN
    -- Count total and compliant columns
    SELECT COUNT(DISTINCT c.column_id) INTO total_cols FROM columns c;
    SELECT COUNT(DISTINCT p.column_id) INTO policy_cols FROM column_retention_policies p;

    -- Calculate coverage
    coverage := ROUND((policy_cols::NUMERIC / total_cols::NUMERIC) * 100, 2);

    -- Determine compliance status
    status := CASE
        WHEN coverage >= 90 THEN 'Pass'
        WHEN coverage >= 70 THEN 'Warning'
        ELSE 'Fail'
    END;

    -- Insert snapshot
    INSERT INTO policy_compliance_history (
        snapshot_date,
        total_columns,
        columns_with_retention_policy,
        coverage_percentage,
        compliance_status
    ) VALUES (
        CURRENT_DATE,
        total_cols,
        policy_cols,
        coverage,
        status
    )
    ON CONFLICT (snapshot_date) DO UPDATE SET
        total_columns = EXCLUDED.total_columns,
        columns_with_retention_policy = EXCLUDED.columns_with_retention_policy,
        coverage_percentage = EXCLUDED.coverage_percentage,
        compliance_status = EXCLUDED.compliance_status;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Policy Compliance History View
-- Purpose: Show historical compliance coverage for reporting and dashboards
-- Why It Matters:
--   - Enables time-series analysis of compliance trends
--   - Supports audit and regulatory reporting
--   - Helps identify improvement or regression in policy coverage

CREATE OR REPLACE VIEW policy_compliance_history_view AS
SELECT
    snapshot_date,
    total_columns,
    columns_with_retention_policy,
    coverage_percentage,
    compliance_status
FROM
    policy_compliance_history
ORDER BY
    snapshot_date DESC;
	
-- Business Case: Retention Policy Gap Report
-- Purpose: Identify columns that do not have a retention policy assigned
-- Why It Matters:
--   - Helps governance teams close compliance gaps
--   - Prioritizes policy assignment for sensitive or regulated data
--   - Supports audit and regulatory reporting

CREATE OR REPLACE VIEW retention_policy_gap_report AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    'Missing Retention Policy' AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
WHERE
    p.mapping_id IS NULL;
	
	
CREATE OR REPLACE VIEW retention_policy_gap_report_with_metadata AS
SELECT
    c.column_id,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.description,
    COALESCE(cs.is_sensitive, FALSE) AS is_sensitive,
    COALESCE(cs.masking_type, 'none') AS masking_type,
    t.table_name,
    s.schema_name,
    d.database_name,
    'Missing Retention Policy' AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
LEFT JOIN column_security_tags cs ON c.column_id = cs.column_id
WHERE
    p.mapping_id IS NULL;
	
	-- Business Case: Retention Policy Gap Summary (by Schema)
-- Purpose: Show how many columns are missing retention policies per schema
-- Why It Matters:
--   - Helps identify high-risk schemas
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW retention_policy_gap_summary_by_schema AS
SELECT
    d.database_name,
    s.schema_name,
    COUNT(c.column_id) AS total_columns,
    COUNT(p.mapping_id) FILTER (WHERE p.mapping_id IS NULL) AS missing_policy_count,
    ROUND(
        (COUNT(p.mapping_id) FILTER (WHERE p.mapping_id IS NULL)::NUMERIC / COUNT(c.column_id)::NUMERIC) * 100,
        2
    ) AS gap_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
GROUP BY
    d.database_name,
    s.schema_name
HAVING
    COUNT(p.mapping_id) FILTER (WHERE p.mapping_id IS NULL) > 0
ORDER BY
    gap_percentage DESC;
	
	
-- Business Case: Policy Recommendation Basis
-- Purpose: Identify candidate columns and their metadata for policy recommendation
-- Why It Matters:
--   - Provides the foundation for smart policy assignment
--   - Helps ensure consistency in governance
--   - Enables automation and prioritization

CREATE OR REPLACE VIEW policy_recommendation_basis AS
SELECT
    c.column_id,
    c.column_name,
    c.data_type,
    c.description,
    cs.is_sensitive,
    cs.masking_type,
    cs.data_sovereignty_country,
    cc.tag_name AS compliance_tag,
    t.table_name,
    s.schema_name,
    d.database_name
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_security_tags cs ON c.column_id = cs.column_id
LEFT JOIN column_compliance_mapping cm ON c.column_id = cm.column_id
LEFT JOIN compliance_tags cc ON cm.compliance_tag_id = cc.compliance_tag_id
LEFT JOIN column_retention_policies p ON c.column_id = p.column_id
WHERE
    p.mapping_id IS NULL; -- Columns without a policy
	
-- Business Case: Policy Recommendation Engine
-- Purpose: Recommend a retention policy based on column metadata
-- Why It Matters:
--   - Helps governance teams assign policies consistently
--   - Enables automation and prioritization
--   - Supports compliance and audit readiness

CREATE OR REPLACE VIEW policy_recommendation_engine AS
SELECT
    basis.*,
    CASE
        WHEN basis.is_sensitive IS TRUE THEN 'sensitive_data_policy'
        WHEN basis.compliance_tag = 'GDPR' THEN 'gdpr_data_policy'
        WHEN basis.compliance_tag = 'HIPAA' THEN 'hipaa_data_policy'
        WHEN basis.data_type ILIKE '%date%' OR basis.data_type ILIKE '%timestamp%' THEN 'time_series_policy'
        WHEN basis.masking_type IS NOT NULL THEN 'masked_data_policy'
        ELSE 'default_data_policy'
    END AS recommended_policy_name,
    CASE
        WHEN basis.is_sensitive IS TRUE THEN 'Policy for sensitive data fields'
        WHEN basis.compliance_tag = 'GDPR' THEN 'Policy for GDPR-regulated data'
        WHEN basis.compliance_tag = 'HIPAA' THEN 'Policy for HIPAA-regulated data'
        WHEN basis.data_type ILIKE '%date%' OR basis.data_type ILIKE '%timestamp%' THEN 'Policy for time-based data'
        WHEN basis.masking_type IS NOT NULL THEN 'Policy for masked or redacted data'
        ELSE 'Default policy for general data'
    END AS recommendation_reason
FROM
    policy_recommendation_basis basis;
	

-- Business Case: Get Policy Recommendation for a Column
-- Purpose: Return a recommended policy for a specific column
-- Why It Matters:
--   - Enables API or UI integration
--   - Supports automation and governance workflows

CREATE OR REPLACE FUNCTION get_policy_recommendation_for_column(target_column_id UUID)
RETURNS TABLE (
    column_id UUID,
    column_name VARCHAR,
    database_name VARCHAR,
    schema_name VARCHAR,
    table_name VARCHAR,
    is_sensitive BOOLEAN,
    compliance_tag VARCHAR,
    data_type VARCHAR,
    recommended_policy_name VARCHAR,
    recommendation_reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        basis.column_id,
        basis.column_name,
        basis.database_name,
        basis.schema_name,
        basis.table_name,
        basis.is_sensitive,
        basis.compliance_tag,
        basis.data_type,
        basis.recommended_policy_name,
        basis.recommendation_reason
    FROM
        policy_recommendation_engine basis
    WHERE
        basis.column_id = target_column_id;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Policy Templates
-- Purpose: Store reusable policy templates that can be applied to columns based on metadata
-- Why It Matters:
--   - Reduces manual effort in policy creation
--   - Ensures consistency in data lifecycle rules
--   - Enables automation of policy assignment

CREATE TABLE policy_templates (
    template_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    template_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    retention_period_days INTEGER NOT NULL,
    archive_period_days INTEGER,
    purge_after_days INTEGER,
    legal_hold_required BOOLEAN DEFAULT FALSE,
    applies_to VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_policy_templates_updated_at
BEFORE UPDATE ON policy_templates
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- INSERT INTO policy_templates (
--     template_name,
--     description,
--     retention_period_days,
--     archive_period_days,
--     purge_after_days,
--     legal_hold_required,
--     applies_to
-- ) VALUES
-- (
--     'sensitive_data_policy',
--     'Default policy for sensitive data fields',
--     730, -- 2 years
--     365, -- Archive after 1 year
--     1095, -- Purge after 3 years
--     TRUE,
--     'sensitive'
-- ),
-- (
--     'gdpr_data_policy',
--     'Policy for GDPR-regulated data',
--     1095, -- 3 years
--     730, -- Archive after 2 years
--     1825, -- Purge after 5 years
--     TRUE,
--     'GDPR'
-- ),
-- (
--     'hipaa_data_policy',
--     'Policy for HIPAA-regulated data',
--     2190, -- 6 years
--     1825, -- Archive after 5 years
--     2555, -- Purge after 7 years
--     TRUE,
--     'HIPAA'
-- ),
-- (
--     'time_series_policy',
--     'Policy for time-based data like logs or events',
--     365, -- 1 year
--     180, -- Archive after 6 months
--     730, -- Purge after 2 years
--     FALSE,
--     'time-series'
-- ),
-- (
--     'masked_data_policy',
--     'Policy for masked or redacted data',
--     1095, -- 3 years
--     730, -- Archive after 2 years
--     1825, -- Purge after 5 years
--     FALSE,
--     'masked'
-- ),
-- (
--     'default_data_policy',
--     'Default policy for general data',
--     365, -- 1 year
--     180, -- Archive after 6 months
--     730, -- Purge after 2 years
--     FALSE,
--     'general'
-- );

-- Business Case: Policy Recommendation with Template
-- Purpose: Show recommended policy with template values for quick assignment
-- Why It Matters:
--   - Helps governance teams apply policies faster
--   - Supports automation and consistency
--   - Enables policy preview before assignment

CREATE OR REPLACE VIEW policy_recommendation_with_template AS
SELECT
    r.column_id,
    r.column_name,
    r.database_name,
    r.schema_name,
    r.table_name,
    r.is_sensitive,
    r.compliance_tag,
    r.data_type,
    r.recommended_policy_name,
    r.recommendation_reason,
    t.template_id,
    t.description AS template_description,
    t.retention_period_days,
    t.archive_period_days,
    t.purge_after_days,
    t.legal_hold_required
FROM
    policy_recommendation_engine r
JOIN
    policy_templates t
    ON r.recommended_policy_name = t.template_name;
	
-- Business Case: Apply Policy Template to Column
-- Purpose: Apply a policy template to a specific column
-- Why It Matters:
--   - Enables automation of policy assignment
--   - Speeds up governance workflows
--   - Ensures consistency across data lifecycle rules

CREATE OR REPLACE FUNCTION apply_policy_template_to_column(
    template_id UUID,
    column_id UUID,
    assigner_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    new_policy_id UUID;
BEGIN
    -- Create a new retention policy from the template
    INSERT INTO retention_policies (
        policy_name,
        description,
        retention_period_days,
        archive_period_days,
        purge_after_days,
        legal_hold_required
    )
    SELECT
        CONCAT(template_name, '-auto-', NOW()::DATE),
        description,
        retention_period_days,
        archive_period_days,
        purge_after_days,
        legal_hold_required
    FROM policy_templates
    WHERE policy_templates.template_id = apply_policy_template_to_column.template_id
    RETURNING policy_id INTO new_policy_id;

    -- Assign the new policy to the column
    INSERT INTO column_retention_policies (
        column_id,
        policy_id,
        assigned_by,
        assigned_at
    )
    VALUES (
        column_id,
        new_policy_id,
        assigner_id,
        NOW()
    );
END;
$$ LANGUAGE plpgsql;


-- Business Case: Apply Policy to All Columns in Schema
-- Purpose: Apply a policy template to all columns in a schema
-- Why It Matters:
--   - Speeds up governance at scale
--   - Ensures consistent policy coverage

CREATE OR REPLACE FUNCTION apply_policy_template_to_schema(
    template_id UUID,
    schema_id UUID,
    assigner_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    col RECORD;
BEGIN
    FOR col IN
        SELECT column_id FROM columns
        WHERE table_id IN (
            SELECT table_id FROM tables
            WHERE schema_id = apply_policy_template_to_schema.schema_id
        )
    LOOP
        PERFORM apply_policy_template_to_column(template_id, col.column_id, assigner_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Policy Assignment Report
-- Purpose: Provide a centralized view of retention policy assignments
-- Why It Matters:
--   - Helps track policy coverage across your data estate
--   - Supports compliance and audit reporting
--   - Identifies areas needing improvement

CREATE OR REPLACE VIEW policy_assignment_report AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    p.policy_id,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required,
    crp.assigned_at,
    owner.name AS assigned_by_name,
    owner.email AS assigned_by_email
FROM
    column_retention_policies crp
JOIN retention_policies p ON crp.policy_id = p.policy_id
JOIN columns c ON crp.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_owners owner ON crp.assigned_by = owner.owner_id;

-- Business Case: Policy Assignment Summary (by Schema)
-- Purpose: Show retention policy coverage aggregated at the schema level
-- Why It Matters:
--   - Helps identify schemas with low policy coverage
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW policy_assignment_summary_by_schema AS
SELECT
    s.schema_name,
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT crp.column_id) AS columns_with_policy,
    ROUND(
        (COUNT(DISTINCT crp.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies crp ON c.column_id = crp.column_id
GROUP BY
    s.schema_name,
    d.database_name
ORDER BY
    coverage_percentage DESC;
	

-- Business Case: Policy Assignment with Gap Info
-- Purpose: Show which columns have policies and which don't
-- Why It Matters:
--   - Helps governance teams prioritize policy assignments
--   - Enables audit and compliance reporting

CREATE OR REPLACE VIEW policy_assignment_with_gap_info AS
SELECT
    basis.column_id,
    basis.column_name,
    basis.table_name,
    basis.schema_name,
    basis.database_name,
    basis.is_sensitive,
    basis.compliance_tag,
    basis.data_type,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required,
    crp.assigned_at,
    owner.name AS assigned_by_name,
    CASE WHEN p.policy_id IS NOT NULL THEN 'Assigned' ELSE 'Missing' END AS policy_status
FROM
    policy_recommendation_basis basis
LEFT JOIN column_retention_policies crp ON basis.column_id = crp.column_id
LEFT JOIN retention_policies p ON crp.policy_id = p.policy_id
LEFT JOIN data_owners owner ON crp.assigned_by = owner.owner_id;

-- Business Case: Policy Assignment Summary (by Database)
-- Purpose: Show retention policy coverage aggregated at the database level
-- Why It Matters:
--   - Helps identify databases with low policy coverage
--   - Useful for executive dashboards

CREATE OR REPLACE VIEW policy_assignment_summary_by_database AS
SELECT
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT crp.column_id) AS columns_with_policy,
    ROUND(
        (COUNT(DISTINCT crp.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies crp ON c.column_id = crp.column_id
GROUP BY
    d.database_name
ORDER BY
    coverage_percentage DESC;
	
	
	-- Business Case: Policy Assignment History
-- Purpose: Track all changes to retention policy assignments
-- Why It Matters:
--   - Enables historical analysis of policy coverage
--   - Supports compliance and regulatory reporting
--   - Helps identify policy changes over time

CREATE OR REPLACE VIEW policy_assignment_history AS
SELECT
    h.history_id,
    h.changed_at,
    h.changed_by,
    h.action_type,
    h.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    h.policy_id,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required
FROM
    column_retention_policies_history h
LEFT JOIN retention_policies p ON h.policy_id = p.policy_id
LEFT JOIN columns c ON h.column_id = c.column_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN databases d ON s.database_id = d.database_id
ORDER BY
    h.changed_at DESC;
	
	
-- Business Case: Policy Assignment Timeline Summary
-- Purpose: Show daily summary of policy assignment changes
-- Why It Matters:
--   - Helps identify trends in policy coverage
--   - Useful for dashboards and executive reporting

CREATE OR REPLACE VIEW policy_assignment_timeline_summary AS
SELECT
    DATE(changed_at) AS change_date,
    COUNT(*) AS total_changes,
    COUNT(*) FILTER (WHERE action_type = 'INSERT') AS policies_added,
    COUNT(*) FILTER (WHERE action_type = 'DELETE') AS policies_removed,
    COUNT(*) FILTER (WHERE action_type = 'UPDATE') AS policies_updated
FROM
    column_retention_policies_history
GROUP BY
    DATE(changed_at)
ORDER BY
    change_date DESC;
	
-- Business Case: Policy Gap History Report
-- Purpose: Show which columns were missing policies on a given date
-- Why It Matters:
--   - Helps track policy coverage over time
--   - Useful for compliance audits

CREATE OR REPLACE FUNCTION policy_gap_history_report(report_date DATE)
RETURNS TABLE (
    column_id UUID,
    column_name VARCHAR,
    table_name VARCHAR,
    schema_name VARCHAR,
    database_name VARCHAR,
    policy_assigned BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.column_id,
        c.column_name,
        t.table_name,
        s.schema_name,
        d.database_name,
        CASE WHEN p.policy_id IS NOT NULL THEN TRUE ELSE FALSE END AS policy_assigned
    FROM
        columns c
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    LEFT JOIN (
        SELECT DISTINCT column_id, policy_id
        FROM column_retention_policies_history
        WHERE changed_at <= report_date
    ) p ON c.column_id = p.column_id;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Policy Coverage History
-- Purpose: Show historical coverage metrics (total, covered, percentage)
-- Why It Matters:
--   - Helps track progress toward full policy coverage
--   - Supports compliance and audit reporting

CREATE OR REPLACE VIEW policy_coverage_history AS
SELECT
    change_date,
    SUM(total_columns) AS total_columns,
    SUM(columns_with_policy) AS columns_with_policy,
    ROUND(
        (SUM(columns_with_policy)::NUMERIC / SUM(total_columns)::NUMERIC) * 100,
        2
    ) AS coverage_percentage
FROM (
    SELECT
        DATE(changed_at) AS change_date,
        COUNT(DISTINCT c.column_id) AS total_columns,
        COUNT(DISTINCT CASE WHEN h.policy_id IS NOT NULL THEN c.column_id ELSE NULL END) AS columns_with_policy
    FROM
        column_retention_policies_history h
    RIGHT JOIN columns c ON h.column_id = c.column_id
    GROUP BY DATE(changed_at), c.column_id
) sub
GROUP BY change_date
ORDER BY change_date DESC;
-- todo : add alerts when coverage drops below threshold. 
-- todo : i need to think of intergration with grafana/ power bi 
-- todo: add ML or rule-based logic for smarter recommendations
-- todo:Adding ML-based template matching  (e.g., based on column name or description)

-- Business Case: Manages column_retention_mapping data for the application.
-- Table Name: column_retention_mapping
-- Purpose: Stores detailed information about column_retention_mapping.
-- Additional Information: This table is central to the column_retention_mapping module.

CREATE TABLE column_retention_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    policy_id UUID NOT NULL REFERENCES retention_policies(policy_id),
    retention_start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_under_legal_hold BOOLEAN DEFAULT FALSE,
    legal_hold_start_date TIMESTAMP WITH TIME ZONE,
    legal_hold_end_date TIMESTAMP WITH TIME ZONE,
    legal_hold_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_column_retention_mapping_updated_at
BEFORE UPDATE ON column_retention_mapping
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for column-based lookups
CREATE INDEX idx_column_retention_mapping_column_id ON column_retention_mapping(column_id);

-- Index for policy-based lookups
CREATE INDEX idx_column_retention_mapping_policy_id ON column_retention_mapping(policy_id);

-- Index for legal hold filtering
CREATE INDEX idx_column_retention_mapping_legal_hold ON column_retention_mapping(is_under_legal_hold);


-- Business Case: Column Retention and Legal Hold Info
-- Purpose: Show retention policy and legal hold details for each column
-- Why It Matters:
--   - Helps governance teams understand policy coverage
--   - Identifies columns under legal hold
--   - Supports compliance and audit reporting

CREATE OR REPLACE VIEW column_retention_and_hold_info AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    p.policy_id,
    p.policy_name,
    p.description AS policy_description,
    p.retention_period_days,
    p.archive_period_days,
    p.purge_after_days,
    p.legal_hold_required,
    m.retention_start_date,
    m.is_under_legal_hold,
    m.legal_hold_start_date,
    m.legal_hold_end_date,
    m.legal_hold_reason,
    m.created_at,
    m.updated_at
FROM
    column_retention_mapping m
JOIN retention_policies p ON m.policy_id = p.policy_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id;
-- Business Case: Retention and Legal Hold History
-- Purpose: Track changes to retention and legal hold assignments for audit
-- Why It Matters:
--   - Enables historical analysis of policy and hold changes
--   - Supports compliance and regulatory reporting
--   - Helps identify who made changes and when

CREATE TABLE column_retention_mapping_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mapping_id UUID,
    column_id UUID,
    policy_id UUID,
    retention_start_date TIMESTAMP WITH TIME ZONE,
    is_under_legal_hold BOOLEAN,
    legal_hold_start_date TIMESTAMP WITH TIME ZONE,
    legal_hold_end_date TIMESTAMP WITH TIME ZONE,
    legal_hold_reason TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user,
    action_type VARCHAR(10) NOT NULL -- 'INSERT', 'UPDATE', 'DELETE'
);

CREATE OR REPLACE FUNCTION log_column_retention_and_hold_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_retention_mapping_history (
            mapping_id, column_id, policy_id, retention_start_date,
            is_under_legal_hold, legal_hold_start_date, legal_hold_end_date, legal_hold_reason, action_type
        )
        VALUES (
            NEW.mapping_id, NEW.column_id, NEW.policy_id, NEW.retention_start_date,
            NEW.is_under_legal_hold, NEW.legal_hold_start_date, NEW.legal_hold_end_date, NEW.legal_hold_reason, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_retention_mapping_history (
            mapping_id, column_id, policy_id, retention_start_date,
            is_under_legal_hold, legal_hold_start_date, legal_hold_end_date, legal_hold_reason, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.policy_id, OLD.retention_start_date,
            OLD.is_under_legal_hold, OLD.legal_hold_start_date, OLD.legal_hold_end_date, OLD.legal_hold_reason, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_retention_mapping_history (
            mapping_id, column_id, policy_id, retention_start_date,
            is_under_legal_hold, legal_hold_start_date, legal_hold_end_date, legal_hold_reason, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.policy_id, OLD.retention_start_date,
            OLD.is_under_legal_hold, OLD.legal_hold_start_date, OLD.legal_hold_end_date, OLD.legal_hold_reason, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_column_retention_and_hold_audit
AFTER INSERT OR UPDATE OR DELETE ON column_retention_mapping
FOR EACH ROW EXECUTE FUNCTION log_column_retention_and_hold_changes();

-- Business Case: Legal Hold Checker
-- Purpose: Check whether a specific column is currently under legal hold
-- Why It Matters:
--   - Used in application logic to prevent data deletion
--   - Helps with compliance workflows
--   - Useful in UI to show legal hold status

CREATE OR REPLACE FUNCTION is_column_under_legal_hold(target_column_id UUID)
RETURNS TABLE (
    column_id UUID,
    column_name VARCHAR,
    is_under_legal_hold BOOLEAN,
    legal_hold_start_date TIMESTAMP WITH TIME ZONE,
    legal_hold_end_date TIMESTAMP WITH TIME ZONE,
    legal_hold_reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.column_id,
        c.column_name,
        m.is_under_legal_hold,
        m.legal_hold_start_date,
        m.legal_hold_end_date,
        m.legal_hold_reason
    FROM
        column_retention_mapping m
    JOIN columns c ON m.column_id = c.column_id
    WHERE
        c.column_id = target_column_id
        AND m.is_under_legal_hold = TRUE;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Retention Compliance Scorecard
-- Purpose: Measure and track retention policy coverage across the organization
-- Why It Matters:
--   - Helps track progress toward full policy coverage
--   - Supports compliance and audit reporting
--   - Enables governance teams to identify and close gaps

CREATE OR REPLACE VIEW retention_compliance_scorecard AS
SELECT
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT m.column_id) AS columns_with_retention_policy,
    ROUND(
        (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS compliance_status
FROM
    columns c
LEFT JOIN column_retention_mapping m ON c.column_id = m.column_id;


-- Business Case: Schema-Level Retention Compliance
-- Purpose: Show retention compliance coverage per schema
-- Why It Matters:
--   - Helps identify schemas with low coverage
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW retention_compliance_scorecard_by_schema AS
SELECT
    s.schema_name,
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT m.column_id) AS columns_with_retention_policy,
    ROUND(
        (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_mapping m ON c.column_id = m.column_id
GROUP BY
    s.schema_name,
    d.database_name;
	
	
-- Business Case: Legal Hold Dashboard
-- Purpose: Provide a centralized view of all columns currently under legal hold
-- Why It Matters:
--   - Helps legal and governance teams track data that cannot be deleted
--   - Supports compliance and audit reporting
--   - Enables data protection and policy enforcement

CREATE OR REPLACE VIEW legal_hold_dashboard AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    m.policy_id,
    p.policy_name,
    m.legal_hold_start_date,
    m.legal_hold_end_date,
    m.legal_hold_reason,
    m.retention_start_date,
    m.updated_at
FROM
    column_retention_mapping m
JOIN retention_policies p ON m.policy_id = p.policy_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE
    m.is_under_legal_hold = TRUE;
	
	
-- Business Case: Legal Hold Summary
-- Purpose: Show legal hold coverage per schema/database
-- Why It Matters:
--   - Helps identify areas with high legal hold coverage
--   - Useful for legal and compliance teams

CREATE OR REPLACE VIEW legal_hold_summary_by_schema AS
SELECT
    s.schema_name,
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT m.column_id) AS columns_under_legal_hold,
    ROUND(
        (COUNT(DISTINCT m.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS legal_hold_coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_mapping m ON c.column_id = m.column_id AND m.is_under_legal_hold = TRUE
GROUP BY
    s.schema_name,
    d.database_name
HAVING
    COUNT(DISTINCT m.column_id) > 0
ORDER BY
    legal_hold_coverage_percentage DESC;
	
	
-- todo -- add alerts or notifications when legal hold status changes 
-- todo -- building a policy expiration or legal hold end date alert system



-- Business Case: Manages data_quality_rules data for the application.
-- Table Name: data_quality_rules
-- Purpose: Stores detailed information about data_quality_rules.
-- Additional Information: This table is central to the data_quality_rules module.

CREATE TABLE data_quality_rules (
                rule_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
                rule_name VARCHAR(255) NOT NULL UNIQUE,
                description TEXT NOT NULL,
                rule_expression TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_data_quality_rules_updated_at
BEFORE UPDATE ON data_quality_rules
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Index for rule name lookups
CREATE INDEX idx_data_quality_rules_name ON data_quality_rules(rule_name);
SELECT * FROM data_quality_rules WHERE rule_expression LIKE 'some_pattern%';

-- Index for rule expression (if used in WHERE clauses)
CREATE INDEX idx_data_quality_rules_expression ON data_quality_rules (rule_expression text_pattern_ops);




-- Business Case: Column Data Quality Rules Mapping
-- Purpose: Associate data quality rules with specific columns
-- Why It Matters:
--   - Enables governance and monitoring of data quality at the column level
--   - Supports automated data validation and alerting

CREATE TABLE column_data_quality_rules (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    rule_id UUID NOT NULL REFERENCES data_quality_rules(rule_id),
    is_active BOOLEAN DEFAULT TRUE,
    assigned_by UUID REFERENCES data_owners(owner_id), -- optional
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for column-based lookups
CREATE INDEX idx_column_data_quality_column_id ON column_data_quality_rules(column_id);

-- Index for rule-based lookups
CREATE INDEX idx_column_data_quality_rule_id ON column_data_quality_rules(rule_id);


-- Business Case: Column Data Quality Rules View
-- Purpose: Show data quality rules applied to each column
-- Why It Matters:
--   - Helps governance teams understand quality coverage
--   - Supports audit and reporting
--   - Enables integration with data quality dashboards

CREATE OR REPLACE VIEW column_data_quality_rules_view AS
SELECT
    cdr.mapping_id,
    cdr.assigned_at,
    cdr.is_active,
    r.rule_id,
    r.rule_name,
    r.description AS rule_description,
    r.rule_expression,
    c.column_id,
    c.column_name,
    t.table_id,
    t.table_name,
    s.schema_id,
    s.schema_name,
    d.database_id,
    d.database_name,
    owner.name AS assigned_by_name,
    owner.email AS assigned_by_email
FROM
    column_data_quality_rules cdr
JOIN data_quality_rules r ON cdr.rule_id = r.rule_id
JOIN columns c ON cdr.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_owners owner ON cdr.assigned_by = owner.owner_id;


-- Business Case: Column Data Quality Rules History
-- Purpose: Log changes to data quality rule assignments
-- Why It Matters:
--   - Enables historical analysis of quality rule changes
--   - Supports compliance and audit reporting
--   - Helps identify who made changes and when

CREATE TABLE column_data_quality_rules_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mapping_id UUID,
    column_id UUID,
    rule_id UUID,
    is_active BOOLEAN,
    assigned_by UUID,
    assigned_at TIMESTAMP WITH TIME ZONE,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);



CREATE OR REPLACE FUNCTION log_column_data_quality_rule_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_data_quality_rules_history (
            mapping_id, column_id, rule_id, is_active, assigned_by, assigned_at, action_type
        )
        VALUES (
            NEW.mapping_id, NEW.column_id, NEW.rule_id, NEW.is_active, NEW.assigned_by, NEW.assigned_at, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_data_quality_rules_history (
            mapping_id, column_id, rule_id, is_active, assigned_by, assigned_at, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.rule_id, OLD.is_active, OLD.assigned_by, OLD.assigned_at, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_data_quality_rules_history (
            mapping_id, column_id, rule_id, is_active, assigned_by, assigned_at, action_type
        )
        VALUES (
            OLD.mapping_id, OLD.column_id, OLD.rule_id, OLD.is_active, OLD.assigned_by, OLD.assigned_at, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_column_data_quality_rules_audit
AFTER INSERT OR UPDATE OR DELETE ON column_data_quality_rules
FOR EACH ROW EXECUTE FUNCTION log_column_data_quality_rule_changes();


-- Business Case: Data Quality Dashboard
-- Purpose: Provide a centralized view of data quality rule coverage
-- Why It Matters:
--   - Helps identify areas with high or low quality coverage
--   - Supports governance and compliance
--   - Enables prioritization of data quality improvements

CREATE OR REPLACE VIEW data_quality_dashboard AS
SELECT
    d.database_name,
    s.schema_name,
    t.table_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT r.rule_id) AS columns_with_quality_rules,
    ROUND(
        (COUNT(DISTINCT r.rule_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS quality_coverage_percentage
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_data_quality_rules r ON c.column_id = r.column_id AND r.is_active = TRUE
GROUP BY
    d.database_name,
    s.schema_name,
    t.table_name
ORDER BY
    quality_coverage_percentage DESC;
	
	
-- Business Case: Data Quality Scorecard
-- Purpose: Show overall data quality rule coverage across the organization
-- Why It Matters:
--   - Provides a high-level view for executives and governance teams
--   - Helps track progress toward full coverage
--   - Supports audit and compliance reporting

CREATE OR REPLACE VIEW data_quality_scorecard AS
SELECT
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT r.column_id) AS columns_with_quality_rules,
    ROUND(
        (COUNT(DISTINCT r.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) * 100,
        2
    ) AS overall_quality_coverage_percentage,
    CASE
        WHEN (COUNT(DISTINCT r.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.9 THEN 'Pass'
        WHEN (COUNT(DISTINCT r.column_id)::NUMERIC / COUNT(DISTINCT c.column_id)::NUMERIC) >= 0.7 THEN 'Warning'
        ELSE 'Fail'
    END AS coverage_status
FROM
    columns c
LEFT JOIN column_data_quality_rules r ON c.column_id = r.column_id AND r.is_active = TRUE;

-- Business Case: Data Quality Rule Details
-- Purpose: Show all active data quality rules per column
-- Why It Matters:
--   - Helps governance teams understand what rules are applied
--   - Supports audit and reporting
--   - Enables integration with data quality monitoring systems

CREATE OR REPLACE VIEW data_quality_rule_details AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    r.rule_id,
    r.rule_name,
    r.description AS rule_description,
    r.rule_expression,
    cdr.is_active,
    cdr.assigned_at,
    owner.name AS assigned_by_name
FROM
    column_data_quality_rules cdr
JOIN data_quality_rules r ON cdr.rule_id = r.rule_id
JOIN columns c ON cdr.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_owners owner ON cdr.assigned_by = owner.owner_id
WHERE
    cdr.is_active = TRUE;
	
-- Business Case: Data Quality Gap Report
-- Purpose: Identify columns without active data quality rules
-- Why It Matters:
--   - Helps governance teams prioritize rule assignments
--   - Supports compliance and audit readiness

CREATE OR REPLACE VIEW data_quality_gap_report AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    'Missing Data Quality Rule' AS compliance_status
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_data_quality_rules r ON c.column_id = r.column_id AND r.is_active = TRUE
WHERE
    r.mapping_id IS NULL;
	

-- Business Case: Column Quality Rule Checker
-- Purpose: Check whether a specific column has any active data quality rules
-- Why It Matters:
--   - Used in application logic to enforce quality checks
--   - Helps with UI validation
--   - Useful for automation workflows

CREATE OR REPLACE FUNCTION has_active_quality_rules(target_column_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    rule_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO rule_count
    FROM column_data_quality_rules
    WHERE column_id = target_column_id
      AND is_active = TRUE;

    RETURN rule_count > 0;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Data Quality Rule Assignment History
-- Purpose: Show historical changes to data quality rule assignments
-- Why It Matters:
--   - Enables audit and compliance reporting
--   - Helps identify who made changes and when
--   - Supports governance and policy reviews

CREATE OR REPLACE VIEW data_quality_rule_assignment_history AS
SELECT
    h.history_id,
    h.changed_at,
    h.changed_by,
    h.action_type,
    h.column_id,
    h.rule_id,
    h.is_active,
    c.column_name,
    r.rule_name,
    r.description AS rule_description,
    t.table_name,
    s.schema_name,
    d.database_name
FROM
    column_data_quality_rules_history h
LEFT JOIN columns c ON h.column_id = c.column_id
LEFT JOIN data_quality_rules r ON h.rule_id = r.rule_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN databases d ON s.database_id = d.database_id
ORDER BY
    h.changed_at DESC;
	
-- Business Case: Data Quality Rule Execution Results
-- Purpose: Store results of data quality rule evaluations
-- Why It Matters:
--   - Enables validation history and trend analysis
--   - Supports audit and reporting
--   - Tracks quality trends over time

CREATE TABLE data_quality_rule_results (
    result_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mapping_id UUID NOT NULL REFERENCES column_data_quality_rules(mapping_id),
    execution_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    passed BOOLEAN NOT NULL,
    error_count INTEGER,
    error_rate NUMERIC(5, 2), -- percentage of failed rows
    total_rows_checked BIGINT,
    execution_duration INTERVAL,
    validator TEXT,
    notes TEXT
);

-- Index for column-based lookups
CREATE INDEX idx_data_quality_results_column_id ON data_quality_rule_results(mapping_id);

-- Index for time-based filtering
CREATE INDEX idx_data_quality_results_execution_at ON data_quality_rule_results(execution_at);


-- Business Case: Data Quality Validation History
-- Purpose: Show historical validation results for a column or rule
-- Why It Matters:
--   - Helps identify quality trends
--   - Supports audit and compliance reporting
--   - Enables alerting on quality degradation

CREATE OR REPLACE VIEW data_quality_validation_history AS
SELECT
    r.result_id,
    r.execution_at,
    r.passed,
    r.error_count,
    r.error_rate,
    r.total_rows_checked,
    r.validator,
    r.notes,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_id,
    q.rule_name,
    q.description AS rule_description
FROM
    data_quality_rule_results r
JOIN column_data_quality_rules m ON r.mapping_id = m.mapping_id
JOIN data_quality_rules q ON m.rule_id = q.rule_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id;

-- Business Case: Data Quality Trend Report (by Column)
-- Purpose: Show data quality trends over time for each column
-- Why It Matters:
--   - Helps identify improvement or degradation in quality
--   - Supports governance and audit reporting

CREATE OR REPLACE VIEW data_quality_trend_by_column AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    DATE(r.execution_at) AS execution_date,
    AVG(r.error_rate) AS avg_error_rate,
    COUNT(*) AS total_executions,
    ROUND(
        (COUNT(*) FILTER (WHERE r.passed = TRUE)::NUMERIC / COUNT(*)::NUMERIC) * 100,
        2
    ) AS pass_rate
FROM
    data_quality_rule_results r
JOIN column_data_quality_rules m ON r.mapping_id = m.mapping_id
JOIN data_quality_rules q ON m.rule_id = q.rule_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    DATE(r.execution_at)
ORDER BY
    c.column_id,
    execution_date DESC;
	

-- Business Case: Data Quality Failures Dashboard
-- Purpose: Show recent data quality rule failures for monitoring and action
-- Why It Matters:
--   - Helps identify problematic columns and rules
--   - Supports data observability and governance
--   - Enables prioritization of data quality fixes
CREATE OR REPLACE VIEW data_quality_failures_dashboard AS
SELECT
    v.result_id,
    v.execution_at,
    v.passed,
    v.error_count,
    v.error_rate,
    v.total_rows_checked,
    v.validator,
    v.column_id,
    v.column_name,
    v.table_name,
    v.schema_name,
    v.database_name,
    v.rule_name,
    v.rule_description
FROM
    data_quality_validation_history v
WHERE
    NOT v.passed
ORDER BY
    v.execution_at DESC;
	

SELECT * FROM data_quality_validation_history LIMIT 0;

-- Business Case: Data Quality Alerts
-- Purpose: Show recent data quality rule failures that may require action
-- Why It Matters:
--   - Helps identify new or recurring quality issues
--   - Can be used to trigger automated alerts
--   - Supports real-time governance and observability
-- Business Case: Data Quality Alerts
-- Purpose: Show recent data quality rule failures that may require action
-- Why It Matters:
--   - Helps identify new or recurring quality issues
--   - Can be used to trigger automated alerts
--   - Supports real-time governance and observability

-- Business Case: Data Quality Alerts
-- Purpose: Show recent data quality rule failures that may require action
-- Why It Matters:
--   - Helps identify new or recurring quality issues
--   - Can be used to trigger automated alerts
--   - Supports real-time governance and observability

CREATE OR REPLACE VIEW data_quality_alerts AS
SELECT
    r.result_id,
    r.execution_at,
    r.error_count,
    r.error_rate,
    r.validator,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    q.description AS rule_description,
    ROUND(r.error_rate, 2) AS error_rate_percent
FROM
    data_quality_rule_results r
JOIN column_data_quality_rules m ON r.mapping_id = m.mapping_id
JOIN data_quality_rules q ON m.rule_id = q.rule_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE
    NOT r.passed
    AND r.execution_at >= NOW() - INTERVAL '7 days'
ORDER BY
    r.error_rate DESC;
	
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'data_quality_rules';
	
-- Business Case: Data Quality Alert Trigger
-- Purpose: Function to trigger alerts on quality failures
-- Why It Matters:
--   - Enables integration with alerting tools (e.g., Slack, PagerDuty)
--   - Automates data quality monitoring

CREATE OR REPLACE FUNCTION send_data_quality_alert()
RETURNS TRIGGER AS $$
DECLARE
    msg JSON;
BEGIN
    -- Build alert message
    msg := json_build_object(
        'result_id', NEW.result_id,
        'execution_at', NEW.execution_at,
        'column_name', NEW.column_name,
        'table_name', NEW.table_name,
        'schema_name', NEW.schema_name,
        'database_name', NEW.database_name,
        'rule_name', NEW.rule_name,
        'error_count', NEW.error_count,
        'error_rate', NEW.error_rate,
        'validator', NEW.validator
    );

    -- Use LISTEN/NOTIFY to send alert
    PERFORM pg_notify('data_quality_alert', msg::TEXT);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Business Case: Manages data_quality_results data for the application.
-- Table Name: data_quality_results
-- Purpose: Stores detailed information about data_quality_results.
-- Additional Information: This table is central to the data_quality_results module.

CREATE TABLE data_quality_results (
    result_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    rule_id UUID NOT NULL REFERENCES data_quality_rules(rule_id),
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actual_value NUMERIC,
    expected_value NUMERIC,
    threshold_value NUMERIC,
    records_failed INTEGER,
    error_message TEXT,
    validation_tool VARCHAR(255),
    job_id VARCHAR(255) NOT NULL,
    is_notified BOOLEAN DEFAULT FALSE
);


-- Index for column-based lookups
CREATE INDEX idx_data_quality_results_column_id ON data_quality_results(column_id);

-- Index for rule-based lookups
CREATE INDEX idx_data_quality_results_rule_id ON data_quality_results(rule_id);

-- Index for job_id (useful for tracking batch executions)
CREATE INDEX idx_data_quality_results_job_id ON data_quality_results(job_id);

-- Index for time-based filtering
CREATE INDEX idx_data_quality_results_time ON data_quality_results(execution_timestamp);


-- Business Case: Rule Failures Per Column
-- Purpose: Show all failed quality rules grouped by column
-- Why It Matters:
--   - Helps identify problematic columns
--   - Supports governance and prioritization
--   - Enables integration with dashboards and alerting systems

CREATE OR REPLACE VIEW data_quality_failures_per_column AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    COUNT(r.result_id) AS total_failures,
    MAX(r.execution_timestamp) AS last_failure_at,
    STRING_AGG(DISTINCT r.rule_id::TEXT, ', ') AS failed_rule_ids,
    STRING_AGG(DISTINCT q.rule_name, ', ') AS failed_rule_names
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE
    r.records_failed > 0  -- Only failed validations
GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name
ORDER BY
    total_failures DESC;
	
-- Business Case: Data Quality Trend by Column
-- Purpose: Show historical data quality failures over time per column
-- Why It Matters:
--   - Helps identify recurring or worsening data issues
--   - Supports audit and compliance reporting
--   - Enables proactive data quality management
-- Drop the existing view
DROP VIEW IF EXISTS data_quality_trend_by_column;

-- Recreate it with the correct column names
CREATE OR REPLACE VIEW data_quality_trend_by_column AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    DATE(r.execution_timestamp) AS failure_date,
    COUNT(r.result_id) AS total_failures,
    SUM(r.records_failed) AS total_records_failed,
    STRING_AGG(DISTINCT q.rule_name, ', ') AS failed_rule_names
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE
    r.records_failed > 0
GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    DATE(r.execution_timestamp)
ORDER BY
    failure_date DESC,
    total_failures DESC;
	
	
-- Business Case: Data Quality Failures with Severity
-- Purpose: Show rule failures with severity level assigned based on error rate or failed records
-- Why It Matters:
--   - Helps prioritize data issues
--   - Supports governance and alerting
--   - Enables escalation workflows

CREATE OR REPLACE VIEW data_quality_failures_with_severity AS
SELECT
    r.result_id,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    r.rule_id,
    r.actual_value,
    r.expected_value,
    r.threshold_value,
    r.records_failed,
    r.execution_timestamp,
    r.error_message,
    r.validation_tool,
    r.job_id,
    r.is_notified,
    -- Severity based on records failed
    CASE
        WHEN r.records_failed > 100 THEN 'High'
        WHEN r.records_failed > 10 THEN 'Medium'
        WHEN r.records_failed > 0 THEN 'Low'
        ELSE 'Unknown'
    END AS severity,
    -- Status based on actual vs expected
    CASE
        WHEN r.records_failed > 0 THEN 'Failed'
        ELSE 'Passed'
    END AS status
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE
    r.records_failed > 0;
	
	
-- Business Case: Get Data Quality Failures by Severity
-- Purpose: Filter data quality failures by severity level
-- Why It Matters:
--   - Helps governance teams prioritize issues
--   - Enables integration with alerting and dashboards

CREATE OR REPLACE FUNCTION get_failures_by_severity(severity_level VARCHAR DEFAULT 'High')
RETURNS TABLE (
    result_id UUID,
    column_name VARCHAR,
    table_name VARCHAR,
    schema_name VARCHAR,
    database_name VARCHAR,
    rule_name VARCHAR,
    records_failed INTEGER,
    execution_timestamp TIMESTAMP WITH TIME ZONE,
    severity VARCHAR  --Changed from TEXT to VARCHAR to match return type
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.result_id,
        c.column_name,
        t.table_name,
        s.schema_name,
        d.database_name,
        q.rule_name,
        r.records_failed,
        r.execution_timestamp,
        r.severity::VARCHAR  -- Cast severity from TEXT to VARCHAR
    FROM
        data_quality_failures_with_severity r
    JOIN data_quality_rules q ON r.rule_id = q.rule_id
    JOIN columns c ON r.column_id = c.column_id
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    WHERE
        r.severity = severity_level
    ORDER BY
        r.execution_timestamp DESC;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_failures_by_severity('High');

-- Business Case: Data Quality Trend with Severity
-- Purpose: Show historical data quality failures with severity levels
-- Why It Matters:
--   - Helps identify recurring or critical quality issues
--   - Supports governance and audit reporting

CREATE OR REPLACE VIEW data_quality_trend_with_severity AS
SELECT
    DATE(r.execution_timestamp) AS failure_date,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    COUNT(r.result_id) AS total_failures,
    SUM(r.records_failed) AS total_records_failed,
    MAX(r.severity) AS highest_severity
FROM
    data_quality_failures_with_severity r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
GROUP BY
    DATE(r.execution_timestamp),
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name
ORDER BY
    failure_date DESC;
	
	
-- Business Case: Custom Severity Rules
-- Purpose: Define severity levels based on dynamic thresholds
-- Why It Matters:
--   - Enables flexible, configurable severity rules
--   - Supports different rule types and thresholds
--   - Allows governance teams to adjust rules without code changes

CREATE TABLE severity_rules (
    severity_rule_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    severity_level VARCHAR(50) NOT NULL, -- e.g., 'High', 'Medium', 'Low'
    rule_name VARCHAR(255) NOT NULL, -- e.g., 'records_failed', 'error_rate'
    threshold_type VARCHAR(50) NOT NULL CHECK (threshold_type IN ('GREATER_THAN', 'LESS_THAN', 'EQUAL_TO', 'BETWEEN')),
    threshold_value_min NUMERIC,  -- For BETWEEN or min value
    threshold_value_max NUMERIC,  -- For BETWEEN or max value
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_severity_rules_updated_at
BEFORE UPDATE ON severity_rules
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


INSERT INTO severity_rules (
    severity_level,
    rule_name,
    threshold_type,
    threshold_value_min,
    threshold_value_max,
    description
) VALUES
('High', 'records_failed', 'GREATER_THAN', 100, NULL, 'More than 100 failed records'),
('Medium', 'records_failed', 'BETWEEN', 10, 100, 'Between 10 and 100 failed records'),
('Low', 'records_failed', 'BETWEEN', 1, 10, 'Between 1 and 10 failed records'),
('High', 'error_rate', 'GREATER_THAN', 5, NULL, 'Error rate above 5%'),
('Medium', 'error_rate', 'BETWEEN', 1, 5, 'Error rate between 1% and 5%'),
('Low', 'error_rate', 'BETWEEN', 0.1, 1, 'Error rate between 0.1% and 1%');


-- Business Case: Data Quality Failures with Configurable Severity
-- Purpose: Assign severity based on dynamic rules from severity_rules
-- Why It Matters:
--   - Ensures consistent severity assignment
--   - Uses centralized severity definitions
--   - Supports governance and audit reporting


CREATE OR REPLACE VIEW data_quality_failures_with_config_severity AS
SELECT
    r.result_id,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    r.actual_value,
    r.expected_value,
    r.records_failed,
    r.execution_timestamp,
    r.error_message,
    r.validation_tool,
    r.job_id,
    r.is_notified,
    COALESCE(sr.severity_level, 'Unknown') AS severity_level,
    COALESCE(sr.description, 'No matching severity rule') AS severity_rule_description
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN severity_rules sr
    ON q.rule_name = sr.rule_name
    AND sr.is_active = TRUE
    AND (
        (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
        OR
        (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
        OR
        (sr.threshold_type = 'EQUAL_TO' AND r.records_failed = sr.threshold_value_min)
        OR
        (sr.threshold_type = 'BETWEEN' AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
    )
WHERE
    r.records_failed > 0;
	
	
-- Business Case: Evaluate Severity Based on Rule
-- Purpose: Dynamically determine severity based on rule name and value
-- Why It Matters:
--   - Reusable in multiple views and functions
--   - Supports dynamic severity evaluation

CREATE OR REPLACE FUNCTION evaluate_severity(rule_name VARCHAR, value NUMERIC)
RETURNS TABLE(severity_level VARCHAR, rule_description TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sr.severity_level,
        sr.description
    FROM
        severity_rules sr
    WHERE
        sr.rule_name = evaluate_severity.rule_name
        AND sr.is_active = TRUE
        AND (
            (sr.threshold_type = 'GREATER_THAN' AND value > sr.threshold_value_min)
            OR
            (sr.threshold_type = 'LESS_THAN' AND value < sr.threshold_value_min)
            OR
            (sr.threshold_type = 'EQUAL_TO' AND value = sr.threshold_value_min)
            OR
            (sr.threshold_type = 'BETWEEN' AND value BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
        )
    ORDER BY
        sr.threshold_value_min DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


-- Get severity for 45 failed records on 'records_failed' rule
SELECT * FROM evaluate_severity('records_failed', 45);

-- Get severity for 2.5 error rate on 'error_rate' rule
SELECT * FROM evaluate_severity('error_rate', 2.5);



-- Business Case: Data Quality Dashboard with Severity
-- Purpose: Provide a centralized view of all failed data quality rules with severity levels
-- Why It Matters:
--   - Helps identify critical data issues at a glance
--   - Enables governance teams to prioritize fixes


CREATE OR REPLACE VIEW data_quality_dashboard_with_severity AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    r.rule_id,
    r.actual_value,
    r.expected_value,
    r.records_failed,
    r.execution_timestamp,
    r.error_message,
    sr.severity_level,
    sr.description AS severity_rule_description  -- Fixed: Use 'description', not 'severity_rule_description'
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN severity_rules sr
    ON q.rule_name = sr.rule_name
    AND sr.is_active = TRUE
    AND (
        (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
        OR
        (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
        OR
        (sr.threshold_type = 'EQUAL_TO' AND r.records_failed = sr.threshold_value_min)
        OR
        (sr.threshold_type = 'BETWEEN' AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
    )
WHERE
    r.records_failed > 0;
	
	

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'severity_rules';

--todo -- alert for high severity rules


-- Business Case: Data Quality Severity History
-- Purpose: Track severity changes over time for each rule execution
-- Why It Matters:
--   - Helps identify worsening or improving data quality trends
--   - Enables audit and compliance reporting
--   - Supports alerting on severity escalation

CREATE OR REPLACE VIEW data_quality_severity_history AS
SELECT
    r.result_id,
    r.column_id,
    c.column_name,
    r.rule_id,
    q.rule_name,
    r.execution_timestamp,
    r.records_failed,
    r.actual_value,
    r.expected_value,
    sr.severity_level,
    sr.description AS severity_rule_description,
    LAG(sr.severity_level, 1) OVER (
        PARTITION BY r.column_id, r.rule_id
        ORDER BY r.execution_timestamp
    ) AS severity_level_prev
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
LEFT JOIN severity_rules sr
    ON q.rule_name = sr.rule_name
    AND sr.is_active = TRUE
    AND (
        (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
        OR
        (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
        OR
        (sr.threshold_type = 'EQUAL_TO' AND r.records_failed = sr.threshold_value_min)
        OR
        (sr.threshold_type = 'BETWEEN' AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
    )
WHERE
    r.records_failed > 0;
	
	

-- Business Case: Data Quality Severity History (Standalone)
-- Purpose: Track severity changes over time without relying on other views
-- Why It Matters:
--   - Helps identify trends and anomalies
--   - Useful for audit and reporting
--   - Enables historical analysis of data quality
-- Step 1: Drop the existing view
DROP VIEW IF EXISTS data_quality_severity_history;

-- Step 2: Recreate it with correct column names
CREATE OR REPLACE VIEW data_quality_severity_history AS
SELECT
    r.result_id,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    r.rule_id,
    r.execution_timestamp,
    sr.severity_level,
    sr.description AS severity_rule_description,
    r.records_failed,
    r.actual_value,
    r.expected_value
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN severity_rules sr
    ON q.rule_name = sr.rule_name
    AND sr.is_active = TRUE
    AND (
        (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
        OR
        (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
        OR
        (sr.threshold_type = 'EQUAL_TO' AND r.records_failed = sr.threshold_value_min)
        OR
        (sr.threshold_type = 'BETWEEN' AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
    )
WHERE
    r.records_failed > 0
ORDER BY
    r.execution_timestamp DESC;
	
	
-- Business Case: Data Quality Severity Trend by Column
-- Purpose: Show how severity has changed per column and rule over time
-- Why It Matters:
--   - Helps identify improving or worsening data quality
--   - Supports governance and audit reporting

CREATE OR REPLACE VIEW data_quality_severity_trend_by_column AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    DATE(r.execution_timestamp) AS execution_date,
    sr.severity_level,
    COUNT(*) AS failure_count,
    SUM(r.records_failed) AS total_records_failed
FROM
    data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN severity_rules sr
    ON q.rule_name = sr.rule_name
    AND sr.is_active = TRUE
    AND (
        (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
        OR
        (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
        OR
        (sr.threshold_type = 'EQUAL_TO' AND r.records_failed = sr.threshold_value_min)
        OR
        (sr.threshold_type = 'BETWEEN' AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
    )
WHERE
    r.records_failed > 0
GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    DATE(r.execution_timestamp),
    sr.severity_level
ORDER BY
    execution_date DESC,
    total_records_failed DESC;
	
	
-- Business Case: Severity Change Alert View
-- Purpose: Show severity changes between rule executions
-- Why It Matters:
--   - Helps identify worsening data quality
--   - Supports alerting and governance workflows

CREATE OR REPLACE VIEW data_quality_severity_changes AS
SELECT
    current_exec.column_id,
    current_exec.column_name,
    current_exec.rule_id,
    current_exec.rule_name,
    current_exec.execution_timestamp AS current_execution,
    current_exec.severity_level AS current_severity,
    prev_exec.execution_timestamp AS previous_execution,
    prev_exec.severity_level AS previous_severity
FROM
    data_quality_severity_history current_exec
LEFT JOIN LATERAL (
    SELECT *
    FROM data_quality_severity_history prev
    WHERE
        prev.column_id = current_exec.column_id
        AND prev.rule_id = current_exec.rule_id
        AND prev.execution_timestamp < current_exec.execution_timestamp
    ORDER BY prev.execution_timestamp DESC
    LIMIT 1
) prev_exec ON TRUE
WHERE
    prev_exec.severity_level IS DISTINCT FROM current_exec.severity_level;
	
	


-- Business Case: Manages data_quality_metrics data for the application.
-- Table Name: data_quality_metrics
-- Purpose: Stores detailed information about data_quality_metrics.
-- Additional Information: This table is central to the data_quality_metrics module.

CREATE TABLE data_quality_metrics (
    metric_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    last_validation_run TIMESTAMP WITH TIME ZONE,
    freshness_threshold_hours INTEGER,
    completeness_threshold NUMERIC,
    accuracy_threshold NUMERIC,
    consistency_threshold NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_data_quality_metrics_updated_at
BEFORE UPDATE ON data_quality_metrics
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Index for column-based lookups
CREATE INDEX idx_data_quality_metrics_column_id ON data_quality_metrics(column_id);

-- Index for freshness threshold
CREATE INDEX idx_data_quality_metrics_freshness ON data_quality_metrics(freshness_threshold_hours);

-- Index for time-based filtering
CREATE INDEX idx_data_quality_metrics_last_run ON data_quality_metrics(last_validation_run);

-- Business Case: Column Data Quality Metrics
-- Purpose: Show data quality metrics per column with full metadata
-- Why It Matters:
--   - Helps governance teams understand quality at a column level
--   - Supports dashboarding and alerting
--   - Enables integration with monitoring systems

CREATE OR REPLACE VIEW column_data_quality_metrics AS
SELECT
    m.metric_id,
    m.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    m.last_validation_run,
    m.freshness_threshold_hours,
    m.completeness_threshold,
    m.accuracy_threshold,
    m.consistency_threshold,
    m.created_at,
    m.updated_at
FROM
    data_quality_metrics m
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id;


-- Business Case: Column Quality Threshold Checker
-- Purpose: Check whether a column meets all defined quality thresholds
-- Why It Matters:
--   - Used in alerting and governance workflows
--   - Helps automate quality validation
--   - Useful in UI to show pass/fail status

CREATE OR REPLACE FUNCTION is_column_quality_met(target_column_id UUID)
RETURNS TABLE (
    column_id UUID,
    column_name VARCHAR,
    meets_threshold BOOLEAN,
    last_validation_run TIMESTAMP WITH TIME ZONE,
    failed_metrics TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.column_id,
        m.column_name,
        CASE
            WHEN m.freshness_threshold_hours IS NULL OR (NOW() - m.last_validation_run) <= (m.freshness_threshold_hours || ' hours')::INTERVAL THEN TRUE
            ELSE FALSE
        END AS freshness_met,
        CASE
            WHEN m.completeness_threshold IS NULL OR r.records_failed <= m.completeness_threshold THEN TRUE
            ELSE FALSE
        END AS completeness_met,
        CASE
            WHEN m.accuracy_threshold IS NULL OR r.actual_value = m.accuracy_threshold THEN TRUE
            ELSE FALSE
        END AS accuracy_met,
        CASE
            WHEN m.consistency_threshold IS NULL OR r.expected_value = m.consistency_threshold THEN TRUE
            ELSE FALSE
        END AS consistency_met
    FROM
        column_data_quality_metrics m
    LEFT JOIN data_quality_results r ON m.column_id = r.column_id
    WHERE
        m.column_id = target_column_id;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Data Quality Scorecard
-- Purpose: Provide a high-level view of data quality status across the organization
-- Why It Matters:
--   - Shows which columns are failing or passing quality checks
--   - Supports executive dashboards and governance

DROP VIEW IF EXISTS data_quality_scorecard;

CREATE OR REPLACE VIEW data_quality_scorecard AS
SELECT
    m.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    m.last_validation_run,
    -- Freshness check
    CASE
        WHEN m.freshness_threshold_hours IS NULL THEN TRUE
        WHEN (NOW() - m.last_validation_run) <= (m.freshness_threshold_hours || ' hours')::INTERVAL THEN TRUE
        ELSE FALSE
    END AS meets_freshness,
    -- Completeness check
    CASE
        WHEN m.completeness_threshold IS NULL THEN TRUE
        WHEN r.records_failed <= m.completeness_threshold THEN TRUE
        ELSE FALSE
    END AS meets_completeness,
    -- Accuracy check
    CASE
        WHEN m.accuracy_threshold IS NULL THEN TRUE
        WHEN r.actual_value = m.accuracy_threshold THEN TRUE
        ELSE FALSE
    END AS meets_accuracy,
    -- Consistency check
    CASE
        WHEN m.consistency_threshold IS NULL THEN TRUE
        WHEN r.expected_value = m.consistency_threshold THEN TRUE
        ELSE FALSE
    END AS meets_consistency,
    -- Overall status
    CASE
        WHEN
            (NOW() - m.last_validation_run) <= (m.freshness_threshold_hours || ' hours')::INTERVAL
            AND (r.records_failed <= m.completeness_threshold OR m.completeness_threshold IS NULL)
            AND (r.actual_value = m.accuracy_threshold OR m.accuracy_threshold IS NULL)
            AND (r.expected_value = m.consistency_threshold OR m.consistency_threshold IS NULL)
        THEN 'Pass'
        WHEN
            (NOW() - m.last_validation_run) > (m.freshness_threshold_hours || ' hours')::INTERVAL
            OR r.records_failed > m.completeness_threshold
            OR r.actual_value <> m.accuracy_threshold
            OR r.expected_value <> m.consistency_threshold
        THEN 'Fail'
        ELSE 'Unknown'
    END AS overall_status
FROM
    data_quality_metrics m
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_quality_results r ON m.column_id = r.column_id;

-- Business Case: Data Quality Scorecard by Schema
-- Purpose: Show quality pass/fail status per schema
-- Why It Matters:
--   - Helps identify schemas with low data quality
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW data_quality_scorecard_by_schema AS
SELECT
    s.schema_name,
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END) AS passing_columns,
    COUNT(DISTINCT CASE WHEN q.overall_status = 'Fail' THEN c.column_id END) AS failing_columns,
    ROUND(
        (
            COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END)::NUMERIC
            / NULLIF(COUNT(DISTINCT c.column_id), 0)::NUMERIC
        ) * 100,
        2
    ) AS quality_score
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_quality_scorecard q ON c.column_id = q.column_id
GROUP BY
    s.schema_name,
    d.database_name
ORDER BY
    quality_score DESC NULLS LAST;
	
	
SELECT * FROM data_quality_scorecard LIMIT 0;


SELECT column_name
FROM information_schema.columns
WHERE table_name = 'data_quality_scorecard';

-- Business Case: Database-Level Data Quality Scorecard
-- Purpose: Show data quality coverage and score per database
-- Why It Matters:
--   - Helps identify databases with low quality coverage
--   - Supports executive dashboards and governance
--   - Enables prioritization of remediation efforts

CREATE OR REPLACE VIEW data_quality_scorecard_by_database AS
SELECT
    d.database_name,
    COUNT(DISTINCT c.column_id) AS total_columns,
    COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END) AS passing_columns,
    COUNT(DISTINCT CASE WHEN q.overall_status = 'Fail' THEN c.column_id END) AS failing_columns,
    ROUND(
        (
            COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END)::NUMERIC
            / NULLIF(COUNT(DISTINCT c.column_id), 0)::NUMERIC
        ) * 100,
        2
    ) AS quality_score
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN data_quality_scorecard q ON c.column_id = q.column_id
GROUP BY
    d.database_name
ORDER BY
    quality_score DESC NULLS LAST;
	
	
-- Business Case: Schema-Level Data Quality Status
-- Purpose: Get the quality status and score for a specific schema
-- Why It Matters:
--   - Used in governance workflows and dashboards
--   - Helps users drill down into schema-level quality
--   - Enables automation and alerting

CREATE OR REPLACE FUNCTION get_quality_status_by_schema(schema_name TEXT, database_name TEXT)
RETURNS TABLE (
    schema_name_out TEXT,        -- Changed to TEXT to match cast
    total_columns BIGINT,
    passing_columns BIGINT,
    failing_columns BIGINT,
    quality_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.schema_name::TEXT,    -- Cast to TEXT to match function definition
        COUNT(DISTINCT c.column_id) AS total_columns,
        COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END) AS passing_columns,
        COUNT(DISTINCT CASE WHEN q.overall_status = 'Fail' THEN c.column_id END) AS failing_columns,
        ROUND(
            (
                COUNT(DISTINCT CASE WHEN q.overall_status = 'Pass' THEN c.column_id END)::NUMERIC
                / NULLIF(COUNT(DISTINCT c.column_id), 0)::NUMERIC
            ) * 100,
            2
        ) AS quality_score
    FROM
        columns c
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    LEFT JOIN data_quality_scorecard q ON c.column_id = q.column_id
    WHERE
        s.schema_name = get_quality_status_by_schema.schema_name
        AND d.database_name = get_quality_status_by_schema.database_name
    GROUP BY
        s.schema_name,
        d.database_name;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_quality_status_by_schema('public', 'analytics_db');

-- Business Case: Data Quality Score History
-- Purpose: Store historical snapshots of quality scores
-- Why It Matters:
--   - Enables trend analysis and reporting
--   - Supports audit and governance workflows
--   - Tracks progress toward data quality goals

CREATE TABLE data_quality_score_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    schema_name TEXT NOT NULL,
    database_name TEXT NOT NULL,
    total_columns BIGINT,
    passing_columns BIGINT,
    failing_columns BIGINT,
    quality_score NUMERIC(5, 2),
    captured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- Business Case: Capture Quality Score Snapshot
-- Purpose: Take a snapshot of current quality scores for history
-- Why It Matters:
--   - Enables time-series analysis of quality trends
--   - Supports audit and compliance reporting

CREATE OR REPLACE FUNCTION capture_data_quality_snapshot()
RETURNS VOID AS $$
BEGIN
    INSERT INTO data_quality_score_history (
        schema_name,
        database_name,
        total_columns,
        passing_columns,
        failing_columns,
        quality_score
    )
    SELECT
        schema_name,
        database_name,
        total_columns,
        passing_columns,
        failing_columns,
        quality_score
    FROM data_quality_scorecard_by_schema;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Data Quality History View
-- Purpose: Show historical quality scores for schemas
-- Why It Matters:
--   - Helps identify improvements or degradation in data quality
--   - Supports governance and audit reporting

CREATE OR REPLACE VIEW data_quality_score_history_view AS
SELECT
    database_name,
    schema_name,
    DATE(captured_at) AS capture_date,
    quality_score,
    passing_columns,
    failing_columns,
    total_columns
FROM
    data_quality_score_history
ORDER BY
    database_name,
    schema_name,
    captured_at DESC;
	
	
-- Business Case: Data Quality Score Trend by Schema
-- Purpose: Show historical changes in data quality scores for each schema
-- Why It Matters:
--   - Helps identify improving or worsening data quality
--   - Supports audit and compliance reporting
--   - Enables proactive governance and alerting

CREATE OR REPLACE VIEW data_quality_score_trend_by_schema AS
SELECT
    DATE(captured_at) AS capture_date,
    database_name,
    schema_name,
    total_columns,
    passing_columns,
    failing_columns,
    quality_score
FROM
    data_quality_score_history
ORDER BY
    database_name,
    schema_name,
    captured_at DESC;
	
	
-- Business Case: Weekly Data Quality Trend by Schema
-- Purpose: Aggregate quality scores by week for smoother trend analysis
-- Why It Matters:
--   - Helps identify weekly patterns
--   - Useful for governance and executive reporting

CREATE OR REPLACE VIEW data_quality_score_weekly_trend_by_schema AS
SELECT
    DATE_TRUNC('week', captured_at) AS week,
    database_name,
    schema_name,
    ROUND(AVG(quality_score), 2) AS avg_quality_score,
    SUM(passing_columns) AS total_passing_columns,
    SUM(failing_columns) AS total_failing_columns,
    SUM(total_columns) AS total_columns
FROM
    data_quality_score_history
GROUP BY
    DATE_TRUNC('week', captured_at),
    database_name,
    schema_name
ORDER BY
    week DESC,
    AVG(quality_score) DESC;
	
	
-- Business Case: Data Quality Dashboard View
-- Purpose: Show top improving/worsening schemas in the last 7 days
-- Why It Matters:
--   - Helps governance teams prioritize action
--   - Useful for dashboards and alerting

CREATE OR REPLACE VIEW data_quality_dashboard_trend_summary AS
WITH latest AS (
    SELECT
        DATE(captured_at) AS capture_date,
        database_name,
        schema_name,
        quality_score
    FROM
        data_quality_score_history
    WHERE
        captured_at >= NOW() - INTERVAL '7 days'
),
    daily_quality AS (
        SELECT
            database_name,
            schema_name,
            MAX(CASE WHEN capture_date = CURRENT_DATE THEN quality_score END) AS today_score,
        MAX(CASE WHEN capture_date = CURRENT_DATE - INTERVAL '7 days' THEN quality_score END) AS score_7_days_ago
    FROM
        latest
    GROUP BY
        database_name,
        schema_name
)
SELECT
    database_name,
    schema_name,
    score_7_days_ago,
    today_score,
    ROUND(today_score - score_7_days_ago, 2) AS score_change,
    CASE
        WHEN today_score > score_7_days_ago THEN 'Improving'
        WHEN today_score < score_7_days_ago THEN 'Worsening'
        ELSE 'Stable'
    END AS trend_status
FROM
    daily_quality
WHERE
    score_7_days_ago IS NOT NULL
    AND today_score IS NOT NULL
ORDER BY
    score_change DESC
LIMIT 5;

--todo add alerts for large drops in average quality score 
--building a daily vs weekly comparison view 

-- Business Case: Data Quality Daily vs Weekly Trend
-- Purpose: Compare daily data quality scores with weekly averages
-- Why It Matters:
--   - Helps identify quality anomalies
--   - Supports trend analysis
--   - Enables governance and alerting

CREATE OR REPLACE VIEW data_quality_daily_vs_weekly AS
SELECT
    DATE(d.captured_at) AS capture_date,  -- Fixed: derived from captured_at
    DATE_TRUNC('week', d.captured_at) AS week,
    d.database_name,
    d.schema_name,
    d.quality_score AS daily_quality_score,
    ROUND(AVG(d.quality_score) OVER (
        PARTITION BY d.database_name, d.schema_name
        ORDER BY d.captured_at
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7_day_avg,
    ROUND(AVG(d.quality_score) OVER (
        PARTITION BY d.database_name, d.schema_name, DATE_TRUNC('week', d.captured_at)
    ), 2) AS weekly_avg_quality_score,
    ROUND(d.quality_score - AVG(d.quality_score) OVER (
        PARTITION BY d.database_name, d.schema_name, DATE_TRUNC('week', d.captured_at)
    ), 2) AS score_deviation
FROM
    data_quality_score_history d
ORDER BY
    d.database_name,
    d.schema_name,
    d.captured_at DESC;
	
-- Business Case: Weekly Quality with Deviation
-- Purpose: Show weekly quality scores with deviation from the previous week
-- Why It Matters:
--   - Helps identify trends and anomalies
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW data_quality_weekly_with_deviation AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    LAG(weekly_avg_quality_score, 1) OVER (
        PARTITION BY database_name, schema_name
        ORDER BY week
    ) AS previous_week_score,
    ROUND(
        weekly_avg_quality_score - LAG(weekly_avg_quality_score, 1) OVER (
            PARTITION BY database_name, schema_name
            ORDER BY week
        ),
        2
    ) AS week_over_week_change
FROM (
    SELECT
        DATE_TRUNC('week', captured_at) AS week,
        database_name,
        schema_name,
        ROUND(AVG(quality_score), 2) AS weekly_avg_quality_score
    FROM
        data_quality_score_history
    GROUP BY
        DATE_TRUNC('week', captured_at),
        database_name,
        schema_name
) AS weekly_data
ORDER BY
    week DESC,
    database_name,
    schema_name;
	
-- Business Case: Quality Deviation Alert View
-- Purpose: Show schemas with large quality changes week-over-week
-- Why It Matters:
--   - Helps identify worsening or improving data quality
--   - Enables alerting and governance workflows

CREATE OR REPLACE VIEW data_quality_score_deviation_alerts AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    previous_week_score,
    week_over_week_change,
    CASE
        WHEN week_over_week_change > 5 THEN 'Improvement'
        WHEN week_over_week_change < -5 THEN 'Degradation'
        ELSE 'Stable'
    END AS trend_status
FROM
    data_quality_weekly_with_deviation
WHERE
    week_over_week_change IS NOT NULL
    AND week_over_week_change NOT BETWEEN -5 AND 5
ORDER BY
    week DESC,
    week_over_week_change DESC;
	
-- Business Case: Dynamic Alert Thresholds
-- Purpose: Define custom thresholds for data quality deviation alerts
-- Why It Matters:
--   - Enables flexible, configurable alerting without code changes
--   - Supports different rules per database or schema
--   - Allows governance teams to manage sensitivity of alerts

CREATE TABLE alert_thresholds (
    threshold_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    database_name VARCHAR(255),
    schema_name VARCHAR(255),
    alert_type VARCHAR(50) NOT NULL DEFAULT 'DEVIATION', -- e.g., DEVIATION, FRESHNESS, COMPLETENESS
    severity_level VARCHAR(50) NOT NULL, -- e.g., Low, Medium, High
    min_deviation NUMERIC(5,2), -- Minimum change to trigger (e.g., 5.00 = 5%)
    max_deviation NUMERIC(5,2), -- Maximum allowed deviation before alert
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO alert_thresholds (database_name, schema_name, severity_level, min_deviation, max_deviation, description)
VALUES ('analytics_db', 'public', 'High', 5.00, NULL, 'Alert on any drop > 5%');


CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_alert_thresholds_updated_at
BEFORE UPDATE ON alert_thresholds
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Business Case: Get Quality Alerts by Scope
-- Purpose: Retrieve data quality deviation alerts filtered by database and/or schema
-- Why It Matters:
--   - Used in dashboards and governance workflows
--   - Helps users drill down into specific areas
--   - Enables integration with APIs and UIs

CREATE OR REPLACE FUNCTION get_quality_alerts_by_scope(
    database_filter TEXT DEFAULT NULL,
    schema_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    week DATE,
    database_name TEXT,
    schema_name TEXT,
    weekly_avg_quality_score NUMERIC,
    previous_week_score NUMERIC,
    week_over_week_change NUMERIC,
    trend_status TEXT,
    matched_threshold_id UUID,
    severity_level TEXT  -- ✅ Cast to TEXT to match expected return type
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.week::DATE,
        a.database_name,
        a.schema_name,
        a.weekly_avg_quality_score,
        a.previous_week_score,
        a.week_over_week_change,
        a.trend_status,
        t.threshold_id,
        t.severity_level::TEXT  -- ✅ Cast from VARCHAR(50) to TEXT
    FROM
        data_quality_score_deviation_alerts a
    LEFT JOIN alert_thresholds t
        ON (t.database_name IS NULL OR t.database_name = a.database_name)
        AND (t.schema_name IS NULL OR t.schema_name = a.schema_name)
        AND t.is_active = TRUE
        AND (
            (a.week_over_week_change < -COALESCE(t.max_deviation, 999))
            OR
            (a.week_over_week_change > COALESCE(t.min_deviation, 0))
        )
    WHERE
        (database_filter IS NULL OR a.database_name ILIKE database_filter)
        AND (schema_filter IS NULL OR a.schema_name ILIKE schema_filter)
    ORDER BY
        a.week DESC,
        ABS(a.week_over_week_change) DESC;
END;
$$ LANGUAGE plpgsql;


-- All alerts
SELECT * FROM get_quality_alerts_by_scope();

-- Only for analytics_db
SELECT * FROM get_quality_alerts_by_scope('analytics_db');

-- For public schema in analytics_db
SELECT * FROM get_quality_alerts_by_scope('analytics_db', 'public');

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'alert_thresholds';


-- Business Case: Daily Data Quality Alert Digest
-- Purpose: Generate a daily summary of data quality alerts
-- Why It Matters:
--   - Helps governance teams stay informed
--   - Enables integration with email, Slack, or dashboard UIs
--   - Supports audit and compliance workflows

CREATE OR REPLACE FUNCTION generate_daily_quality_alert_digest(
    database_filter TEXT DEFAULT NULL,
    schema_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    alert_date DATE,
    database_name TEXT,
    schema_name TEXT,
    weekly_avg_quality_score NUMERIC(5,2),
    previous_week_score NUMERIC(5,2),
    week_over_week_change NUMERIC(5,2),
    trend_status TEXT,
    severity_level TEXT,
    alert_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(a.week) AS alert_date,
        a.database_name,
        a.schema_name,
        a.weekly_avg_quality_score,
        a.previous_week_score,
        a.week_over_week_change,
        a.trend_status,
        COALESCE(a.severity_level, 'Medium') AS severity_level,
        COUNT(*) AS alert_count
    FROM (
        SELECT *
        FROM get_quality_alerts_by_scope(database_filter, schema_filter)
    ) a
    WHERE
        a.week >= CURRENT_DATE - INTERVAL '1 day'
    GROUP BY
        DATE(a.week),
        a.database_name,
        a.schema_name,
        a.weekly_avg_quality_score,
        a.previous_week_score,
        a.week_over_week_change,
        a.trend_status,
        a.severity_level
    ORDER BY
        alert_date DESC,
        alert_count DESC;
END;
$$ LANGUAGE plpgsql;


-- Get daily digest for all databases
SELECT * FROM generate_daily_quality_alert_digest();

-- Get daily digest for analytics_db
SELECT * FROM generate_daily_quality_alert_digest('analytics_db');

-- Get daily digest for public schema in analytics_db
SELECT * FROM generate_daily_quality_alert_digest('analytics_db', 'public');


-- Business Case: Quality Deviation Alert View
-- Purpose: Show schemas with large quality changes week-over-week
-- Why It Matters:
--   - Helps identify worsening or improving data quality
--   - Enables alerting and governance workflows

CREATE OR REPLACE VIEW data_quality_score_deviation_alerts AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    previous_week_score,
    week_over_week_change,
    CASE
        WHEN week_over_week_change > 5 THEN 'Improvement'
        WHEN week_over_week_change < -5 THEN 'Degradation'
        ELSE 'Stable'
    END AS trend_status
FROM
    data_quality_weekly_with_deviation
WHERE
    week_over_week_change IS NOT NULL
    AND week_over_week_change NOT BETWEEN -5 AND 5
ORDER BY
    week DESC;
	
	
SELECT * FROM get_quality_alerts_by_scope(NULL, NULL);

SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public';

--checking all the relations
SELECT relname
FROM pg_class
WHERE relkind IN ('v', 'm');


-- Business Case: Weekly Quality with Deviation
-- Purpose: Show weekly quality scores with deviation from previous week
-- Why It Matters:
--   - Helps identify trends and anomalies
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW data_quality_weekly_with_deviation AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    LAG(weekly_avg_quality_score, 1) OVER (
        PARTITION BY database_name, schema_name
        ORDER BY week
    ) AS previous_week_score,
    ROUND(
        weekly_avg_quality_score - LAG(weekly_avg_quality_score, 1) OVER (
            PARTITION BY database_name, schema_name
            ORDER BY week
        ),
        2
    ) AS week_over_week_change
FROM (
    SELECT
        DATE_TRUNC('week', captured_at) AS week,
        database_name,
        schema_name,
        ROUND(AVG(quality_score), 2) AS weekly_avg_quality_score
    FROM
        data_quality_score_history
    GROUP BY
        DATE_TRUNC('week', captured_at),
        database_name,
        schema_name
) AS weekly_data
ORDER BY
    week DESC,
    weekly_avg_quality_score DESC;
	
-- Business Case: Quality Deviation Alert View
-- Purpose: Show schemas with large quality changes week-over-week
-- Why It Matters:
--   - Helps identify worsening or improving data quality
--   - Enables alerting and governance workflows

CREATE OR REPLACE VIEW data_quality_score_deviation_alerts AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    previous_week_score,
    week_over_week_change,
    CASE
        WHEN week_over_week_change > 5 THEN 'Improvement'
        WHEN week_over_week_change < -5 THEN 'Degradation'
        ELSE 'Stable'
    END AS trend_status
FROM
    data_quality_weekly_with_deviation
WHERE
    week_over_week_change IS NOT NULL
    AND week_over_week_change NOT BETWEEN -5 AND 5
ORDER BY
    week DESC;

-- DROP FUNCTION IF EXISTS get_quality_alerts_by_scope(text, text);
-- Business Case: Get Quality Alerts by Scope
-- Purpose: Retrieve data quality deviation alerts filtered by database and/or schema
-- Why It Matters:
--   - Used in dashboards and governance workflows
--   - Helps users drill down into specific areas
--   - Enables integration with APIs and UIs

CREATE OR REPLACE FUNCTION get_quality_alerts_by_scope(
    database_filter TEXT DEFAULT NULL,
    schema_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    alert_date DATE,
    database_name TEXT,
    schema_name TEXT,
    weekly_avg_quality_score NUMERIC,
    previous_week_score NUMERIC,
    week_over_week_change NUMERIC,
    trend_status TEXT,
    matched_threshold_id UUID,
    severity_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.week::DATE,
        a.database_name,
        a.schema_name,
        a.weekly_avg_quality_score,
        a.previous_week_score,
        a.week_over_week_change,
        a.trend_status,
        t.threshold_id,
        t.severity_level::TEXT
    FROM
        data_quality_score_deviation_alerts a
    LEFT JOIN alert_thresholds t
        ON (t.database_name IS NULL OR t.database_name = a.database_name)
        AND (t.schema_name IS NULL OR t.schema_name = a.schema_name)
        AND t.is_active = TRUE
        AND (
            (a.week_over_week_change < -COALESCE(t.max_deviation, 999))
            OR
            (a.week_over_week_change > COALESCE(t.min_deviation, 0))
        )
    WHERE
        (database_filter IS NULL OR a.database_name ILIKE database_filter)
        AND (schema_filter IS NULL OR a.schema_name ILIKE schema_filter)
    ORDER BY
        a.week DESC,
        ABS(a.week_over_week_change) DESC;
END;
$$ LANGUAGE plpgsql;

-- Optional: Recreate if needed
-- CREATE TABLE IF NOT EXISTS data_quality_score_history (
--     history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
--     schema_name TEXT NOT NULL,
--     database_name TEXT NOT NULL,
--     total_columns BIGINT,
--     passing_columns BIGINT,
--     failing_columns BIGINT,
--     quality_score NUMERIC(5,2),
--     captured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );
-- Business Case: Weekly Quality with Deviation
-- Purpose: Show weekly quality scores with deviation from previous week
-- Why It Matters:
--   - Helps identify trends and anomalies
--   - Useful for governance and audit reporting

CREATE OR REPLACE VIEW data_quality_weekly_with_deviation AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    LAG(weekly_avg_quality_score, 1) OVER (
        PARTITION BY database_name, schema_name
        ORDER BY week
    ) AS previous_week_score,
    ROUND(
        weekly_avg_quality_score - LAG(weekly_avg_quality_score, 1) OVER (
            PARTITION BY database_name, schema_name
            ORDER BY week
        ),
        2
    ) AS week_over_week_change
FROM (
    SELECT
        DATE_TRUNC('week', captured_at) AS week,
        database_name,
        schema_name,
        ROUND(AVG(quality_score), 2) AS weekly_avg_quality_score
    FROM
        data_quality_score_history
    GROUP BY
        DATE_TRUNC('week', captured_at),
        database_name,
        schema_name
) AS weekly_data
ORDER BY
    week DESC;
	
	
-- Business Case: Quality Deviation Alert View
-- Purpose: Show schemas with large quality changes week-over-week
-- Why It Matters:
--   - Helps identify worsening or improving data quality
--   - Enables alerting and governance workflows

CREATE OR REPLACE VIEW data_quality_score_deviation_alerts AS
SELECT
    week,
    database_name,
    schema_name,
    weekly_avg_quality_score,
    previous_week_score,
    week_over_week_change,
    CASE
        WHEN week_over_week_change > 5 THEN 'Improvement'
        WHEN week_over_week_change < -5 THEN 'Degradation'
        ELSE 'Stable'
    END AS trend_status
FROM
    data_quality_weekly_with_deviation
WHERE
    week_over_week_change IS NOT NULL
    AND week_over_week_change NOT BETWEEN -5 AND 5
ORDER BY
    week DESC;
-- Business Case: Get Quality Alerts by Scope
-- Purpose: Retrieve data quality deviation alerts filtered by database and/or schema
-- Why It Matters:
--   - Used in dashboards and governance workflows
--   - Helps users drill down into specific areas
--   - Enables integration with APIs and UIs

CREATE OR REPLACE FUNCTION get_quality_alerts_by_scope(
    database_filter TEXT DEFAULT NULL,
    schema_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    alert_date DATE,
    database_name TEXT,
    schema_name TEXT,
    weekly_avg_quality_score NUMERIC,
    previous_week_score NUMERIC,
    week_over_week_change NUMERIC,
    trend_status TEXT,
    matched_threshold_id UUID,
    severity_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.week::DATE,
        a.database_name,
        a.schema_name,
        a.weekly_avg_quality_score,
        a.previous_week_score,
        a.week_over_week_change,
        a.trend_status,
        t.threshold_id,
        t.severity_level::TEXT
    FROM
        data_quality_score_deviation_alerts a
    LEFT JOIN alert_thresholds t
        ON (t.database_name IS NULL OR t.database_name = a.database_name)
        AND (t.schema_name IS NULL OR t.schema_name = a.schema_name)
        AND t.is_active = TRUE
        AND (
            (a.week_over_week_change < -COALESCE(t.max_deviation, 999))
            OR
            (a.week_over_week_change > COALESCE(t.min_deviation, 0))
        )
    WHERE
        (database_filter IS NULL OR a.database_name ILIKE database_filter)
        AND (schema_filter IS NULL OR a.schema_name ILIKE schema_filter)
    ORDER BY
        a.week DESC,
        ABS(a.week_over_week_change) DESC;
END;
$$ LANGUAGE plpgsql;

-- display quality alerts by scope
SELECT * FROM get_quality_alerts_by_scope(NULL, NULL);


-- Business Case: Manages data_lineage data for the application.
-- Table Name: data_lineage
-- Purpose: Stores detailed information about data_lineage.
-- Additional Information: This table is central to the data_lineage module.

CREATE TABLE data_lineage (
    lineage_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source_column_id UUID REFERENCES columns(column_id),
    target_column_id UUID REFERENCES columns(column_id),
    transformation_logic TEXT,
    pipeline_name VARCHAR(255),
    data_flow_id VARCHAR(255) NOT NULL,
    lineage_tool_id VARCHAR(255) NOT NULL,
    lineage_tool_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_data_lineage_updated_at
BEFORE UPDATE ON data_lineage
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for source-based lookups
CREATE INDEX idx_data_lineage_source_column ON data_lineage(source_column_id);

-- Index for target-based lookups
CREATE INDEX idx_data_lineage_target_column ON data_lineage(target_column_id);

-- Index for data flow ID
CREATE INDEX idx_data_lineage_data_flow_id ON data_lineage(data_flow_id);

-- Index for pipeline name
CREATE INDEX idx_data_lineage_pipeline_name ON data_lineage(pipeline_name);


-- Business Case: Full Data Lineage Path
-- Purpose: Show the complete mapping from source column to target column with full context
-- Why It Matters:
--   - Enables impact analysis and debugging
--   - Supports compliance and audit reporting
--   - Helps users understand how data flows through pipelines

CREATE OR REPLACE VIEW data_lineage_full_path AS
SELECT
    l.lineage_id,
    l.data_flow_id,
    l.pipeline_name,
    l.transformation_logic,
    l.lineage_tool_id,
    l.lineage_tool_name,
    -- Source Column Info
    src_col.column_name AS source_column_name,
    src_tbl.table_name AS source_table_name,
    src_sch.schema_name AS source_schema_name,
    src_db.database_name AS source_database_name,
    -- Target Column Info
    tgt_col.column_name AS target_column_name,
    tgt_tbl.table_name AS target_table_name,
    tgt_sch.schema_name AS target_schema_name,
    tgt_db.database_name AS target_database_name,
    -- Timestamps
    l.created_at,
    l.updated_at
FROM
    data_lineage l
JOIN columns src_col ON l.source_column_id = src_col.column_id
JOIN tables src_tbl ON src_col.table_id = src_tbl.table_id
JOIN schemas src_sch ON src_tbl.schema_id = src_sch.schema_id
JOIN databases src_db ON src_sch.database_id = src_db.database_id
JOIN columns tgt_col ON l.target_column_id = tgt_col.column_id
JOIN tables tgt_tbl ON tgt_col.table_id = tgt_tbl.table_id
JOIN schemas tgt_sch ON tgt_tbl.schema_id = tgt_sch.schema_id
JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id;



-- Business Case: Upstream Dependency Tracer
-- Purpose: Trace all upstream sources feeding into a given column
-- Why It Matters:
--   - Used in impact analysis ("What feeds this?")
--   - Helps debug incorrect values
--   - Supports governance and compliance audits

CREATE OR REPLACE FUNCTION trace_upstream_dependencies(target_col_id UUID)
RETURNS TABLE (
    level INTEGER,
    source_database_name TEXT,
    source_schema_name TEXT,
    source_table_name TEXT,
    source_column_name TEXT,
    target_database_name TEXT,
    target_schema_name TEXT,
    target_table_name TEXT,
    target_column_name TEXT,
    transformation_logic TEXT,
    pipeline_name TEXT,
    data_flow_id TEXT
) AS $$
BEGIN
    RETURN QUERY WITH RECURSIVE upstream AS (
        -- Base case: start from target column
        SELECT
            1 AS level,
            l.*
        FROM
            data_lineage l
        WHERE
            l.target_column_id = trace_upstream_dependencies.target_col_id

        UNION ALL

        -- Recursive case: follow the chain upstream
        SELECT
            u.level + 1,
            l.*
        FROM
            data_lineage l
        JOIN upstream u ON l.target_column_id = u.source_column_id
        WHERE
            u.level < 10  -- Prevent infinite recursion
    )
    SELECT
        u.level,
        src_db.database_name::TEXT,
        src_sch.schema_name::TEXT,
        src_tbl.table_name::TEXT,
        src_col.column_name::TEXT,
        tgt_db.database_name::TEXT,
        tgt_sch.schema_name::TEXT,
        tgt_tbl.table_name::TEXT,
        tgt_col.column_name::TEXT,
        u.transformation_logic,
        u.pipeline_name,
        u.data_flow_id
    FROM
        upstream u
    JOIN columns src_col ON u.source_column_id = src_col.column_id
    JOIN tables src_tbl ON src_col.table_id = src_tbl.table_id
    JOIN schemas src_sch ON src_tbl.schema_id = src_sch.schema_id
    JOIN databases src_db ON src_sch.database_id = src_db.database_id
    JOIN columns tgt_col ON u.target_column_id = tgt_col.column_id
    JOIN tables tgt_tbl ON tgt_col.table_id = tgt_tbl.table_id
    JOIN schemas tgt_sch ON tgt_tbl.schema_id = tgt_sch.schema_id
    JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
    ORDER BY
        u.level, u.created_at;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Downstream Dependency Tracer
-- Purpose: Trace all downstream targets derived from a given column
-- Why It Matters:
--   - Used in impact analysis ("Where is this used?")
--   - Helps assess risk before schema changes
--   - Supports data deprecation workflows

CREATE OR REPLACE FUNCTION trace_downstream_dependencies(src_col_id UUID)
RETURNS TABLE (
    level INTEGER,
    source_database_name TEXT,
    source_schema_name TEXT,
    source_table_name TEXT,
    source_column_name TEXT,
    target_database_name TEXT,
    target_schema_name TEXT,
    target_table_name TEXT,
    target_column_name TEXT,
    transformation_logic TEXT,
    pipeline_name TEXT,
    data_flow_id TEXT
) AS $$
BEGIN
    RETURN QUERY WITH RECURSIVE downstream AS (
        -- Base case: start from source column
        SELECT
            1 AS level,
            l.*
        FROM
            data_lineage l
        WHERE
            l.source_column_id = trace_downstream_dependencies.src_col_id

        UNION ALL

        -- Recursive case: follow the chain downstream
        SELECT
            d.level + 1,
            l.*
        FROM
            data_lineage l
        JOIN downstream d ON l.source_column_id = d.target_column_id
        WHERE
            d.level < 10  -- Prevent infinite recursion
    )
    SELECT
        d.level,
        src_db.database_name::TEXT,
        src_sch.schema_name::TEXT,
        src_tbl.table_name::TEXT,
        src_col.column_name::TEXT,
        tgt_db.database_name::TEXT,
        tgt_sch.schema_name::TEXT,
        tgt_tbl.table_name::TEXT,
        tgt_col.column_name::TEXT,
        d.transformation_logic,
        d.pipeline_name,
        d.data_flow_id
    FROM
        downstream d
    JOIN columns src_col ON d.source_column_id = src_col.column_id
    JOIN tables src_tbl ON src_col.table_id = src_tbl.table_id
    JOIN schemas src_sch ON src_tbl.schema_id = src_sch.schema_id
    JOIN databases src_db ON src_sch.database_id = src_db.database_id
    JOIN columns tgt_col ON d.target_column_id = tgt_col.column_id
    JOIN tables tgt_tbl ON tgt_col.table_id = tgt_tbl.table_id
    JOIN schemas tgt_sch ON tgt_tbl.schema_id = tgt_sch.schema_id
    JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
    ORDER BY
        d.level, d.created_at;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Data Lineage History
-- Purpose: Track changes to lineage records for audit and compliance
-- Why It Matters:
--   - Enables historical analysis of data flow changes
--   - Supports regulatory reporting
--   - Helps identify who changed what and when

CREATE TABLE data_lineage_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    lineage_id UUID,
    source_column_id UUID,
    target_column_id UUID,
    transformation_logic TEXT,
    pipeline_name VARCHAR(255),
    data_flow_id VARCHAR(255),
    lineage_tool_id VARCHAR(255),
    lineage_tool_name VARCHAR(255),
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);



-- Function to log lineage changes
CREATE OR REPLACE FUNCTION log_data_lineage_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO data_lineage_history (
            lineage_id, source_column_id, target_column_id,
            transformation_logic, pipeline_name, data_flow_id,
            lineage_tool_id, lineage_tool_name, action_type
        ) VALUES (
            NEW.lineage_id, NEW.source_column_id, NEW.target_column_id,
            NEW.transformation_logic, NEW.pipeline_name, NEW.data_flow_id,
            NEW.lineage_tool_id, NEW.lineage_tool_name, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO data_lineage_history (
            lineage_id, source_column_id, target_column_id,
            transformation_logic, pipeline_name, data_flow_id,
            lineage_tool_id, lineage_tool_name, action_type
        ) VALUES (
            OLD.lineage_id, OLD.source_column_id, OLD.target_column_id,
            OLD.transformation_logic, OLD.pipeline_name, OLD.data_flow_id,
            OLD.lineage_tool_id, OLD.lineage_tool_name, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO data_lineage_history (
            lineage_id, source_column_id, target_column_id,
            transformation_logic, pipeline_name, data_flow_id,
            lineage_tool_id, lineage_tool_name, action_type
        ) VALUES (
            OLD.lineage_id, OLD.source_column_id, OLD.target_column_id,
            OLD.transformation_logic, OLD.pipeline_name, OLD.data_flow_id,
            OLD.lineage_tool_id, OLD.lineage_tool_name, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_data_lineage_audit
AFTER INSERT OR UPDATE OR DELETE ON data_lineage
FOR EACH ROW EXECUTE FUNCTION log_data_lineage_changes();


-- Business Case: Export Lineage to OpenLineage Format
-- Purpose: Generate OpenLineage-compliant JSON for integration with Marquez, Amundsen, or other tools
-- Why It Matters:
--   - Enables interoperability with open-source metadata systems
--   - Supports automated metadata ingestion
--   - Future-proofs your governance system

CREATE OR REPLACE FUNCTION export_lineage_to_openlineage(target_lineage_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT INTO result
        json_build_object(
            'eventType', 'COMPLETE',
            'eventTime', NOW()::TEXT,
            'run', json_build_object(
                'runId', l.data_flow_id,
                'facets', json_build_object(
                    'nominalTime', json_build_object(
                        '_producer', 'your-data-platform/v1',
                        '_schemaURL', 'https://github.com/OpenLineage/OpenLineage/blob/main/spec/facets/NominalTimeRunFacet.json#/',
                        'nominalStartTime', l.created_at AT TIME ZONE 'UTC'
                    )
                )
            ),
            'job', json_build_object(
                'namespace', src_db.database_name || '.' || src_sch.schema_name,
                'name', COALESCE(l.pipeline_name, 'unknown_pipeline'),
                'facets', json_build_object(
                    'sourceCode', json_build_object(
                        '_producer', 'your-data-platform/v1',
                        '_schemaURL', ' https://github.com/OpenLineage/OpenLineage/blob/main/spec/facets/SourceCodeJobFacet.json#/',
                        'language', 'sql',
                        'sourceCode', l.transformation_logic
                    )
                )
            ),
            'inputs', json_agg(
                json_build_object(
                    'namespace', src_db.database_name || '.' || src_sch.schema_name,
                    'name', src_tbl.table_name,
                    'facets', json_build_object(
                        'schema', json_build_object(
                            '_producer', 'your-data-platform/v1',
                            '_schemaURL', ' https://github.com/OpenLineage/OpenLineage/blob/main/spec/facets/SchemaDatasetFacet.json#/',
                            'fields', json_build_array(
                                json_build_object(
                                    'name', src_col.column_name,
                                    'type', 'string' -- Optional: add actual data type from columns table
                                )
                            )
                        )
                    )
                )
            ),
            'outputs', json_agg(
                json_build_object(
                    'namespace', tgt_db.database_name || '.' || tgt_sch.schema_name,
                    'name', tgt_tbl.table_name,
                    'facets', json_build_object(
                        'schema', json_build_object(
                            '_producer', 'your-data-platform/v1',
                            '_schemaURL', ' https://github.com/OpenLineage/OpenLineage/blob/main/spec/facets/SchemaDatasetFacet.json#/',
                            'fields', json_build_array(
                                json_build_object(
                                    'name', tgt_col.column_name,
                                    'type', 'string' -- Optional: add actual data type
                                )
                            )
                        )
                    )
                )
            ),
            'producer', 'http://your-org/data-lineage-service/v1',
            '_schemaURL', ' https://openlineage.io/spec/1-0-2/OpenLineage.json#/'
        )
    FROM
        data_lineage l
    JOIN columns src_col ON l.source_column_id = src_col.column_id
    JOIN tables src_tbl ON src_col.table_id = src_tbl.table_id
    JOIN schemas src_sch ON src_tbl.schema_id = src_sch.schema_id
    JOIN databases src_db ON src_sch.database_id = src_db.database_id
    JOIN columns tgt_col ON l.target_column_id = tgt_col.column_id
    JOIN tables tgt_tbl ON tgt_col.table_id = tgt_tbl.table_id
    JOIN schemas tgt_sch ON tgt_tbl.schema_id = tgt_sch.schema_id
    JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
    WHERE
        l.lineage_id = target_lineage_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


-- batch export function 
-- to export all recent lineage records 
CREATE OR REPLACE FUNCTION export_all_lineage_to_openlineage()
RETURNS SETOF JSON AS $$
BEGIN
    RETURN QUERY
    SELECT export_lineage_to_openlineage(l.lineage_id)
    FROM data_lineage l
    WHERE l.updated_at >= NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Awase todo 
-- integrate with airflow with open lineage integration 
-- kafka with open lineage adapter 
-- plain python script can also be used to visualize and genearte mermaid.js or D3.js. we can also do neo4j export
-- we can also build a kafka producer for real-time lineage streaming 
-- or create a python script to push events to Marquez (https://marquezproject.ai/)
-- Amundsen + Dbt 

-- Business Case: Manages upstream_dependencies data for the application.
-- Table Name: upstream_dependencies
-- Purpose: Stores detailed information about upstream_dependencies.
-- Additional Information: This table is central to the upstream_dependencies module.

CREATE TABLE upstream_dependencies (
    dependency_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    upstream_column_id UUID NOT NULL REFERENCES columns(column_id),
    relationship_type VARCHAR(255), -- e.g., 'direct', 'derived', 'copy', 'aggregated'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate dependencies
    UNIQUE (column_id, upstream_column_id)
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_upstream_dependencies_updated_at
BEFORE UPDATE ON upstream_dependencies
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for downstream lookups (what depends on this column?)
CREATE INDEX idx_upstream_dependencies_column_id ON upstream_dependencies(column_id);

-- Index for upstream lookups (what feeds into this column?)
CREATE INDEX idx_upstream_dependencies_upstream_column_id ON upstream_dependencies(upstream_column_id);

-- Index for relationship type filtering
CREATE INDEX idx_upstream_dependencies_relationship_type ON upstream_dependencies(relationship_type);



-- Business Case: Manages downstream_dependencies data for the application.
-- Table Name: downstream_dependencies
-- Purpose: Stores detailed information about downstream_dependencies.
-- Additional Information: This table is central to the downstream_dependencies module.

CREATE TABLE downstream_dependencies (
    dependency_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    downstream_column_id UUID NOT NULL REFERENCES columns(column_id),
    relationship_type VARCHAR(255), -- e.g., 'direct', 'aggregated', 'transformed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate dependencies
    UNIQUE (column_id, downstream_column_id)
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_downstream_dependencies_updated_at
BEFORE UPDATE ON downstream_dependencies
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Business Case: Full Dependency Path View
-- Purpose: Show bi-directional column-level dependencies with full metadata
-- Why It Matters:
--   - Enables fast impact analysis
--   - Supports governance dashboards
--   - Avoids recursive CTE performance issues

CREATE OR REPLACE VIEW dependency_full_path AS
SELECT
    'upstream' AS direction,
    u.dependency_id,
    c.column_name AS target_column_name,
    t.table_name AS target_table_name,
    s.schema_name AS target_schema_name,
    d.database_name AS target_database_name,
    up_col.column_name AS source_column_name,
    up_tbl.table_name AS source_table_name,
    up_sch.schema_name AS source_schema_name,
    up_db.database_name AS source_database_name,
    u.relationship_type,
    u.created_at,
    u.updated_at
FROM
    upstream_dependencies u
JOIN columns c ON u.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
JOIN columns up_col ON u.upstream_column_id = up_col.column_id
JOIN tables up_tbl ON up_col.table_id = up_tbl.table_id
JOIN schemas up_sch ON up_tbl.schema_id = up_sch.schema_id
JOIN databases up_db ON up_sch.database_id = up_db.database_id

UNION ALL

SELECT
    'downstream' AS direction,
    d.dependency_id,
    c.column_name AS source_column_name,
    t.table_name AS source_table_name,
    s.schema_name AS source_schema_name,
    d_db.database_name AS source_database_name,
    down_col.column_name AS target_column_name,
    down_tbl.table_name AS target_table_name,
    down_sch.schema_name AS target_schema_name,
    down_db.database_name AS target_database_name,
    d.relationship_type,
    d.created_at,
    d.updated_at
FROM
    downstream_dependencies d
JOIN columns c ON d.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d_db ON s.database_id = d_db.database_id
JOIN columns down_col ON d.downstream_column_id = down_col.column_id
JOIN tables down_tbl ON down_col.table_id = down_tbl.table_id
JOIN schemas down_sch ON down_tbl.schema_id = down_sch.schema_id
JOIN databases down_db ON down_sch.database_id = down_db.database_id;



-- Business Case: Auto-Populate Dependencies
-- Purpose: Populate dependency tables from data_lineage
-- Why It Matters:
--   - Keeps dependency tables in sync with lineage
--   - Improves query performance for impact analysis
--   - Enables hybrid manual/auto governance

CREATE OR REPLACE FUNCTION sync_dependencies_from_data_lineage()
RETURNS VOID AS $$
BEGIN
    -- Insert into upstream_dependencies (target <- source)
    INSERT INTO upstream_dependencies (column_id, upstream_column_id, relationship_type)
    SELECT
        l.target_column_id,
        l.source_column_id,
        COALESCE(l.pipeline_name, 'derived') AS relationship_type
    FROM
        data_lineage l
    ON CONFLICT (column_id, upstream_column_id) DO NOTHING;

    -- Insert into downstream_dependencies (source -> target)
    INSERT INTO downstream_dependencies (column_id, downstream_column_id, relationship_type)
    SELECT
        l.source_column_id,
        l.target_column_id,
        COALESCE(l.pipeline_name, 'derived') AS relationship_type
    FROM
        data_lineage l
    ON CONFLICT (column_id, downstream_column_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;


SELECT sync_dependencies_from_data_lineage();

-- Business Case: Export to Neo4j Cypher
-- Purpose: Generate Cypher queries to import into Neo4j
-- Why It Matters:
--   - Enables visual graph exploration
--   - Integrates with modern graph databases

CREATE OR REPLACE FUNCTION export_to_neo4j_cypher()
RETURNS SETOF TEXT AS $$
BEGIN
    RETURN QUERY
    SELECT
        FORMAT(
            'MERGE (c1:Column {name: %L}) MERGE (c2:Column {name: %L}) MERGE (c1)-[:%s]->(c2);',
            src_col.column_name,
            tgt_col.column_name,
            COALESCE(REPLACE(u.relationship_type, ' ', '_'), 'DEPENDS_ON')
        )
    FROM
        upstream_dependencies u
    JOIN columns src_col ON u.upstream_column_id = src_col.column_id
    JOIN columns tgt_col ON u.column_id = tgt_col.column_id;
END;
$$ LANGUAGE plpgsql;



-- Business Case: Export to D3.js Graph Format
-- Purpose: Generate JSON for force-directed graphs
-- Why It Matters:
--   - Enables web-based visualization
--   - Integrates with React, Vue, etc.

CREATE OR REPLACE FUNCTION export_to_d3_graph()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    WITH nodes AS (
        SELECT DISTINCT
            col.column_id AS id,
            col.column_name AS label,
            tbl.table_name AS table_name,
            sch.schema_name AS schema_name,
            db.database_name AS database_name
        FROM (
            SELECT source_column_id AS column_id FROM data_lineage
            UNION
            SELECT target_column_id AS column_id FROM data_lineage
        ) rel
        JOIN columns col ON rel.column_id = col.column_id
        JOIN tables tbl ON col.table_id = tbl.table_id
        JOIN schemas sch ON tbl.schema_id = sch.schema_id
        JOIN databases db ON sch.database_id = db.database_id
    ),
    links AS (
        SELECT
            l.source_column_id AS source,
            l.target_column_id AS target,
            COALESCE(l.pipeline_name, 'transform') AS type
        FROM data_lineage l
    )
    SELECT INTO result
        json_build_object(
            'nodes', COALESCE(json_agg(DISTINCT n), '[]'),
            'links', COALESCE((
                SELECT json_agg(
                    json_build_object('source', l.source, 'target', l.target, 'type', l.type)
                ) FROM links l
            ), '[]')
        )
    FROM nodes n;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

SELECT export_to_d3_graph();


-- Business Case: Export to Mermaid.js
-- Purpose: Generate Mermaid flowcharts for documentation
-- Why It Matters:
--   - Great for Confluence, Markdown, docs
--   - Easy to visualize

CREATE OR REPLACE FUNCTION export_to_mermaid_flowchart()
RETURNS TEXT AS $$
DECLARE
    diagram TEXT := 'graph TD\n';
    r RECORD;
BEGIN
    FOR r IN
        SELECT
            src_col.column_name AS src,
            tgt_col.column_name AS tgt,
            COALESCE(dl.pipeline_name, 'Process') AS label
        FROM data_lineage dl
        JOIN columns src_col ON dl.source_column_id = src_col.column_id
        JOIN columns tgt_col ON dl.target_column_id = tgt_col.column_id
    LOOP
        diagram := diagram || FORMAT('    %I -->|%I| %I\n', r.src, r.label, r.tgt);
    END LOOP;

    RETURN diagram;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Manages business_glossary data for the application.
-- Table Name: business_glossary
-- Purpose: Stores detailed information about business_glossary.
-- Additional Information: This table is central to the business_glossary module.

CREATE TABLE business_glossary (
    term_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    term_name VARCHAR(255) NOT NULL UNIQUE,
    definition TEXT NOT NULL,
    business_rules TEXT,
    example_values TEXT,
    domain VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before update
CREATE TRIGGER update_business_glossary_updated_at
BEFORE UPDATE ON business_glossary
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- Index for term name lookups
CREATE INDEX idx_business_glossary_term_name ON business_glossary(term_name);

-- Index for domain filtering
CREATE INDEX idx_business_glossary_domain ON business_glossary(domain);



-- Business Case: Manages column_glossary_mapping data for the application.
-- Table Name: column_glossary_mapping
-- Purpose: Stores detailed information about column_glossary_mapping.
-- Additional Information: This table is central to the column_glossary_mapping module.

CREATE TABLE column_glossary_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    term_id UUID NOT NULL REFERENCES business_glossary(term_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate mappings
    UNIQUE (column_id, term_id)
);


-- Add updated_at column
ALTER TABLE column_glossary_mapping
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Add trigger
CREATE TRIGGER update_column_glossary_mapping_updated_at
BEFORE UPDATE ON column_glossary_mapping
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Index for column-based lookups
CREATE INDEX idx_column_glossary_column_id ON column_glossary_mapping(column_id);

-- Index for term-based lookups
CREATE INDEX idx_column_glossary_term_id ON column_glossary_mapping(term_id);


-- Business Case: Glossary Terms Per Column
-- Purpose: Show all business glossary terms mapped to each column
-- Why It Matters:
--   - Helps users understand the meaning of data
--   - Supports data discovery and governance
--   - Enables integration with BI tools and catalogs

CREATE OR REPLACE VIEW column_glossary_terms AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    g.term_id,
    g.term_name,
    g.definition,
    g.business_rules,
    g.example_values,
    g.domain,
    m.created_at AS mapped_at
FROM
    column_glossary_mapping m
JOIN business_glossary g ON m.term_id = g.term_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id;



-- Business Case: Search Glossary by Keyword or Domain
-- Purpose: Allow users to search business terms by keyword or domain
-- Why It Matters:
--   - Improves self-service data discovery
--   - Helps analysts find relevant definitions
--   - Supports compliance and reporting

CREATE OR REPLACE FUNCTION search_glossary(
    search_text TEXT DEFAULT NULL,
    domain_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    term_id UUID,
    term_name TEXT,
    definition TEXT,
    business_rules TEXT,
    example_values TEXT,
    domain TEXT,
    matched_field TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        g.term_id,
        g.term_name::TEXT,                    --  Cast
        g.definition,
        g.business_rules,
        g.example_values,
        g.domain::TEXT,                       -- Cast domain to TEXT
        CASE
            WHEN g.term_name ILIKE ('%' || search_text || '%') THEN 'term_name'
            WHEN g.definition ILIKE ('%' || search_text || '%') THEN 'definition'
            WHEN g.business_rules ILIKE ('%' || search_text || '%') THEN 'business_rules'
            WHEN g.example_values ILIKE ('%' || search_text || '%') THEN 'example_values'
            ELSE 'domain'
        END::TEXT AS matched_field
    FROM
        business_glossary g
    WHERE
        (search_text IS NULL
         OR g.term_name ILIKE ('%' || search_text || '%')
         OR g.definition ILIKE ('%' || search_text || '%')
         OR g.business_rules ILIKE ('%' || search_text || '%')
         OR g.example_values ILIKE ('%' || search_text || '%'))
        AND (domain_filter IS NULL OR g.domain ILIKE ('%' || domain_filter || '%'))
    ORDER BY
        g.term_name::TEXT;  --  Now matches selected expression exactly
END;
$$ LANGUAGE plpgsql;


-- Search for terms related to "email"
SELECT * FROM search_glossary();

-- Search for terms in "PII" domain
SELECT * FROM search_glossary(NULL, 'PII');

-- Search for "customer" in "Sales" domain
SELECT * FROM search_glossary('customer', 'Sales');

-- Business Case: Business Glossary History
-- Purpose: Log changes to business glossary entries for audit and compliance
-- Why It Matters:
--   - Enables historical analysis of term changes
--   - Supports regulatory reporting
--   - Helps identify who made changes

CREATE TABLE business_glossary_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    term_id UUID NOT NULL,
    term_name VARCHAR(255) NOT NULL,
    definition TEXT NOT NULL,
    business_rules TEXT,
    example_values TEXT,
    domain VARCHAR(255),
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);


CREATE OR REPLACE FUNCTION log_business_glossary_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO business_glossary_history (
            term_id, term_name, definition, business_rules,
            example_values, domain, action_type
        )
        VALUES (
            NEW.term_id, NEW.term_name, NEW.definition, NEW.business_rules,
            NEW.example_values, NEW.domain, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO business_glossary_history (
            term_id, term_name, definition, business_rules,
            example_values, domain, action_type
        )
        VALUES (
            OLD.term_id, OLD.term_name, OLD.definition, OLD.business_rules,
            OLD.example_values, OLD.domain, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO business_glossary_history (
            term_id, term_name, definition, business_rules,
            example_values, domain, action_type
        )
        VALUES (
            OLD.term_id, OLD.term_name, OLD.definition, OLD.business_rules,
            OLD.example_values, OLD.domain, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_business_glossary_audit
AFTER INSERT OR UPDATE OR DELETE ON business_glossary
FOR EACH ROW EXECUTE FUNCTION log_business_glossary_changes();


-- Business Case: Business Glossary Dashboard
-- Purpose: Provide a centralized view of all business glossary terms with technical context
-- Why It Matters:
--   - Enables self-service data discovery
--   - Shows which terms are linked to physical columns
--   - Supports governance, compliance, and onboarding

CREATE OR REPLACE VIEW business_glossary_dashboard AS
SELECT
    g.term_id,
    g.term_name,
    g.definition,
    g.domain,
    g.business_rules,
    g.example_values,
    -- Count how many columns this term is mapped to
    COALESCE(m.column_count, 0) AS mapped_column_count,
    -- List sample columns it's linked to (for quick reference)
    STRING_AGG(DISTINCT c.column_name, ', ') FILTER (WHERE c.column_name IS NOT NULL) AS sample_mapped_columns,
    -- List tables where it's used
    STRING_AGG(DISTINCT t.table_name, ', ') FILTER (WHERE t.table_name IS NOT NULL) AS usage_in_tables,
    -- List databases/schemas
    STRING_AGG(DISTINCT d.database_name || '.' || s.schema_name, ', ') 
        FILTER (WHERE d.database_name IS NOT NULL AND s.schema_name IS NOT NULL) AS usage_in_schemas,
    -- Timestamps
    g.created_at,
    g.updated_at
FROM
    business_glossary g
LEFT JOIN (
    SELECT
        term_id,
        COUNT(column_id) AS column_count
    FROM
        column_glossary_mapping
    GROUP BY
        term_id
) m ON g.term_id = m.term_id
LEFT JOIN column_glossary_mapping map ON g.term_id = map.term_id
LEFT JOIN columns c ON map.column_id = c.column_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN databases d ON s.database_id = d.database_id
GROUP BY
    g.term_id,
    g.term_name,
    g.definition,
    g.domain,
    g.business_rules,
    g.example_values,
    m.column_count,
    g.created_at,
    g.updated_at
ORDER BY
    g.term_name;
	
	
	
-- Business Case: Manages search_tags data for the application.
-- Table Name: search_tags
-- Purpose: Stores detailed information about search_tags.
-- Additional Information: This table is central to the search_tags module.

CREATE TABLE search_tags (
    tag_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    tag_name VARCHAR(255) NOT NULL UNIQUE,
    tag_category VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_tag_mapping data for the application.
-- Table Name: column_tag_mapping
-- Purpose: Stores detailed information about column_tag_mapping.
-- Additional Information: This table is central to the column_tag_mapping module.

CREATE TABLE column_tag_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    tag_id UUID NOT NULL REFERENCES search_tags(tag_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicates
    UNIQUE (column_id, tag_id)
);


-- Business Case: Manages column_usage_metrics data for the application.
-- Table Name: column_usage_metrics
-- Purpose: Stores detailed information about column_usage_metrics.
-- Additional Information: This table is central to the column_usage_metrics module.

CREATE TABLE column_usage_metrics (
    metric_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    query_count INTEGER DEFAULT 0,
    last_queried_at TIMESTAMP WITH TIME ZONE,
    usage_context TEXT,
    data_product VARCHAR(255),
    data_catalog_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_documentation data for the application.
-- Table Name: column_documentation
-- Purpose: Stores detailed information about column_documentation.
-- Additional Information: This table is central to the column_documentation module.

CREATE TABLE column_documentation (
    documentation_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    created_by UUID REFERENCES users(user_id),
    documentation_link TEXT,
    business_term_mapping TEXT,
    technical_specification TEXT,
    sample_queries TEXT,
    known_issues TEXT,
    troubleshooting_guide TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_search_tags_updated_at
    BEFORE UPDATE ON search_tags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_column_tag_mapping_updated_at
    BEFORE UPDATE ON column_tag_mapping
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_column_usage_metrics_updated_at
    BEFORE UPDATE ON column_usage_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_column_documentation_updated_at
    BEFORE UPDATE ON column_documentation
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
	
	
-- search_tags
CREATE INDEX idx_search_tags_name ON search_tags(tag_name);
CREATE INDEX idx_search_tags_category ON search_tags(tag_category);

-- column_tag_mapping
CREATE INDEX idx_column_tag_column_id ON column_tag_mapping(column_id);
CREATE INDEX idx_column_tag_tag_id ON column_tag_mapping(tag_id);

-- column_usage_metrics
CREATE INDEX idx_usage_column_id ON column_usage_metrics(column_id);
CREATE INDEX idx_usage_last_queried ON column_usage_metrics(last_queried_at);
CREATE INDEX idx_usage_data_product ON column_usage_metrics(data_product);

-- column_documentation
CREATE INDEX idx_doc_column_id ON column_documentation(column_id);
CREATE INDEX idx_doc_created_by ON column_documentation(created_by);

-- Business Case: Search Columns by Tag or Keyword
-- Purpose: Allow users to search columns by name, glossary term, tag, or description
-- Why It Matters:
--   - Powers data discovery in UIs and catalogs
--   - Helps analysts find relevant data fast
--   - Supports compliance and impact analysis

CREATE OR REPLACE FUNCTION search_columns(
    search_text TEXT DEFAULT NULL,
    tag_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    column_id UUID,
    column_name TEXT,
    table_name TEXT,
    schema_name TEXT,
    database_name TEXT,
    glossary_terms TEXT,
    tags TEXT,
    query_count INTEGER,
    last_queried_at TIMESTAMP WITH TIME ZONE,
    documentation_link TEXT,
    matched_field TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        ctx.column_id,
        ctx.column_name::TEXT,
        ctx.table_name::TEXT,
        ctx.schema_name::TEXT,
        ctx.database_name::TEXT,
        ctx.glossary_terms,
        ctx.tags,
        ctx.query_count,
        ctx.last_queried_at,
        ctx.documentation_link,
        CASE
            WHEN ctx.column_name ILIKE ('%' || search_text || '%') THEN 'column_name'
            WHEN ctx.table_name ILIKE ('%' || search_text || '%') THEN 'table_name'
            WHEN ctx.glossary_terms ILIKE ('%' || search_text || '%') THEN 'glossary_term'
            WHEN ctx.tags ILIKE ('%' || search_text || '%') THEN 'tag'
            WHEN ctx.technical_specification ILIKE ('%' || search_text || '%') THEN 'technical_spec'
            WHEN ctx.sample_queries ILIKE ('%' || search_text || '%') THEN 'sample_query'
            ELSE 'other'
        END::TEXT AS matched_field
    FROM
        column_full_context ctx
    WHERE
        (search_text IS NULL
         OR ctx.column_name ILIKE ('%' || search_text || '%')
         OR ctx.table_name ILIKE ('%' || search_text || '%')
         OR ctx.glossary_terms ILIKE ('%' || search_text || '%')
         OR ctx.tags ILIKE ('%' || search_text || '%')
         OR ctx.technical_specification ILIKE ('%' || search_text || '%')
         OR ctx.sample_queries ILIKE ('%' || search_text || '%')
         OR ctx.known_issues ILIKE ('%' || search_text || '%'))
        AND (tag_filter IS NULL OR ctx.tags ILIKE ('%' || tag_filter || '%'))
    ORDER BY
        ctx.query_count DESC NULLS LAST,
        ctx.column_name;
END;
$$ LANGUAGE plpgsql;

-- Search for "email"
SELECT * FROM search_columns('email');

-- Search for columns tagged with "PII"
SELECT * FROM search_columns(NULL, 'PII');

-- Search for "join" in tables tagged "Sales"
SELECT * FROM search_columns('join', 'Sales');



-- Business Case: Full Column Context
-- Purpose: Provide a unified view of all metadata for each column
-- Why It Matters:
--   - Enables self-service data discovery
--   - Combines business, technical, usage, and tagging info
--   - Supports governance, onboarding, and troubleshooting

CREATE OR REPLACE VIEW column_full_context AS
SELECT
    -- Column Identity
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Business Glossary
    STRING_AGG(DISTINCT g.term_name, ', ') FILTER (WHERE g.term_name IS NOT NULL) AS glossary_terms,
    STRING_AGG(DISTINCT g.domain, ', ') FILTER (WHERE g.domain IS NOT NULL) AS term_domains,

    -- Tags
    STRING_AGG(DISTINCT st.tag_name, ', ') FILTER (WHERE st.tag_name IS NOT NULL) AS tags,
    STRING_AGG(DISTINCT st.tag_category, ', ') FILTER (WHERE st.tag_category IS NOT NULL) AS tag_categories,

    -- Usage Metrics
    um.query_count,
    um.last_queried_at,
    um.data_product,
    um.usage_context,

    -- Documentation
    doc.documentation_link,
    doc.business_term_mapping,
    doc.technical_specification,
    doc.sample_queries,
    doc.known_issues,
    doc.troubleshooting_guide,
    -- Safe fallback: only use user_id (we know it exists)
    COALESCE(u.user_id::TEXT, 'Unknown') AS documented_by_name,
    doc.created_at AS documentation_created_at,
    doc.updated_at AS documentation_updated_at,

    -- Last Updated
    GREATEST(doc.updated_at, um.updated_at) AS last_enriched_at
FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

-- Glossary
LEFT JOIN column_glossary_mapping cgm ON c.column_id = cgm.column_id
LEFT JOIN business_glossary g ON cgm.term_id = g.term_id

-- Tags
LEFT JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
LEFT JOIN search_tags st ON ctm.tag_id = st.tag_id

-- Usage
LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id

-- Documentation
LEFT JOIN column_documentation doc ON c.column_id = doc.column_id
LEFT JOIN users u ON doc.created_by = u.user_id  -- This join is safe as long as user_id exists

GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    um.query_count,
    um.last_queried_at,
    um.data_product,
    um.usage_context,
    doc.documentation_link,
    doc.business_term_mapping,
    doc.technical_specification,
    doc.sample_queries,
    doc.known_issues,
    doc.troubleshooting_guide,
    u.user_id,
    doc.created_at,
    doc.updated_at,
    um.updated_at;
	
	
-- Business Case: Column Documentation History
-- Purpose: Log changes to column documentation for audit and compliance
-- Why It Matters:
--   - Enables historical analysis of doc changes
--   - Supports regulatory reporting
--   - Helps identify who made updates

CREATE TABLE column_documentation_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    documentation_id UUID NOT NULL,
    column_id UUID NOT NULL,
    created_by UUID,
    documentation_link TEXT,
    business_term_mapping TEXT,
    technical_specification TEXT,
    sample_queries TEXT,
    known_issues TEXT,
    troubleshooting_guide TEXT,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);


CREATE OR REPLACE FUNCTION log_column_documentation_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO column_documentation_history (
            documentation_id, column_id, created_by,
            documentation_link, business_term_mapping,
            technical_specification, sample_queries,
            known_issues, troubleshooting_guide, action_type
        )
        VALUES (
            NEW.documentation_id, NEW.column_id, NEW.created_by,
            NEW.documentation_link, NEW.business_term_mapping,
            NEW.technical_specification, NEW.sample_queries,
            NEW.known_issues, NEW.troubleshooting_guide, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO column_documentation_history (
            documentation_id, column_id, created_by,
            documentation_link, business_term_mapping,
            technical_specification, sample_queries,
            known_issues, troubleshooting_guide, action_type
        )
        VALUES (
            OLD.documentation_id, OLD.column_id, OLD.created_by,
            OLD.documentation_link, OLD.business_term_mapping,
            OLD.technical_specification, OLD.sample_queries,
            OLD.known_issues, OLD.troubleshooting_guide, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO column_documentation_history (
            documentation_id, column_id, created_by,
            documentation_link, business_term_mapping,
            technical_specification, sample_queries,
            known_issues, troubleshooting_guide, action_type
        )
        VALUES (
            OLD.documentation_id, OLD.column_id, OLD.created_by,
            OLD.documentation_link, OLD.business_term_mapping,
            OLD.technical_specification, OLD.sample_queries,
            OLD.known_issues, OLD.troubleshooting_guide, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Data Discovery Scorecard
-- Purpose: Show overall coverage of metadata across the data estate
-- Why It Matters:
--   - Measures progress toward full documentation and tagging
--   - Supports executive reporting and governance goals
--   - Highlights gaps in discoverability

CREATE OR REPLACE VIEW data_discovery_scorecard AS
SELECT
    COUNT(DISTINCT c.column_id) AS total_columns,

    -- Glossary Coverage
    COUNT(DISTINCT g.term_id) AS columns_with_glossary,
    ROUND(
        (COUNT(DISTINCT g.term_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS glossary_coverage_percent,

    -- Tagging Coverage
    COUNT(DISTINCT st.tag_id) AS columns_with_tags,
    ROUND(
        (COUNT(DISTINCT st.tag_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS tags_coverage_percent,

    -- Documentation Coverage
    COUNT(DISTINCT doc.documentation_id) AS columns_with_documentation,
    ROUND(
        (COUNT(DISTINCT doc.documentation_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS documentation_coverage_percent,

    -- Usage Coverage
    COUNT(DISTINCT um.metric_id) AS columns_with_usage_metrics,
    ROUND(
        (COUNT(DISTINCT um.metric_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS usage_tracking_percent,

    -- Overall "Well-Described" Columns (has at least one of each)
    COUNT(DISTINCT CASE
        WHEN g.term_id IS NOT NULL
             AND st.tag_id IS NOT NULL
             AND doc.documentation_id IS NOT NULL
             AND um.metric_id IS NOT NULL
        THEN c.column_id
    END) AS fully_described_columns,
    ROUND(
        (
            COUNT(DISTINCT CASE
                WHEN g.term_id IS NOT NULL
                     AND st.tag_id IS NOT NULL
                     AND doc.documentation_id IS NOT NULL
                     AND um.metric_id IS NOT NULL
                THEN c.column_id
            END)::NUMERIC
            / COUNT(DISTINCT c.column_id)
        ) * 100,
        2
    ) AS completeness_score
FROM
    columns c
LEFT JOIN column_glossary_mapping cgm ON c.column_id = cgm.column_id
LEFT JOIN business_glossary g ON cgm.term_id = g.term_id
LEFT JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
LEFT JOIN search_tags st ON ctm.tag_id = st.tag_id
LEFT JOIN column_documentation doc ON c.column_id = doc.column_id
LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id;


-- Business Case: Data Discovery Dashboard by Schema
-- Purpose: Show metadata coverage broken down by schema and database
-- Why It Matters:
--   - Helps identify low-coverage areas
--   - Enables prioritization of stewardship efforts
--   - Supports schema-level governance

CREATE OR REPLACE VIEW data_discovery_dashboard_by_schema AS
SELECT
    d.database_name,
    s.schema_name,
    COUNT(DISTINCT c.column_id) AS total_columns,

    -- Glossary
    COUNT(DISTINCT g.term_id) AS with_glossary,
    ROUND(
        (COUNT(DISTINCT g.term_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS glossary_coverage,

    -- Tags
    COUNT(DISTINCT st.tag_id) AS with_tags,
    ROUND(
        (COUNT(DISTINCT st.tag_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS tags_coverage,

    -- Documentation
    COUNT(DISTINCT doc.documentation_id) AS with_docs,
    ROUND(
        (COUNT(DISTINCT doc.documentation_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS docs_coverage,

    -- Usage Tracking
    COUNT(DISTINCT um.metric_id) AS with_usage,
    ROUND(
        (COUNT(DISTINCT um.metric_id)::NUMERIC / COUNT(DISTINCT c.column_id)) * 100,
        2
    ) AS usage_coverage,

    -- Completeness: All four present
    COUNT(DISTINCT CASE
        WHEN g.term_id IS NOT NULL
             AND st.tag_id IS NOT NULL
             AND doc.documentation_id IS NOT NULL
             AND um.metric_id IS NOT NULL
        THEN c.column_id
    END) AS fully_enriched_columns,
    ROUND(
        (
            COUNT(DISTINCT CASE
                WHEN g.term_id IS NOT NULL
                     AND st.tag_id IS NOT NULL
                     AND doc.documentation_id IS NOT NULL
                     AND um.metric_id IS NOT NULL
                THEN c.column_id
            END)::NUMERIC
            / COUNT(DISTINCT c.column_id)
        ) * 100,
        2
    ) AS completeness_score
FROM
    schemas s
JOIN databases d ON s.database_id = d.database_id
JOIN tables t ON s.schema_id = t.schema_id
JOIN columns c ON t.table_id = c.table_id
LEFT JOIN column_glossary_mapping cgm ON c.column_id = cgm.column_id
LEFT JOIN business_glossary g ON cgm.term_id = g.term_id
LEFT JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
LEFT JOIN search_tags st ON ctm.tag_id = st.tag_id
LEFT JOIN column_documentation doc ON c.column_id = doc.column_id
LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id
GROUP BY
    d.database_name,
    s.schema_name
HAVING
    COUNT(DISTINCT c.column_id) > 0
ORDER BY
    completeness_score DESC,
    total_columns DESC;
	
	
-- Business Case: Low Coverage Schema Alerts
-- Purpose: Identify schemas with poor metadata coverage for governance action
-- Why It Matters:
--   - Helps data stewards focus on high-impact areas
--   - Supports continuous improvement of data discovery
--   - Enables automated reporting

CREATE OR REPLACE VIEW data_discovery_low_coverage_alerts AS
SELECT
    database_name,
    schema_name,
    total_columns,
    glossary_coverage,
    tags_coverage,
    docs_coverage,
    usage_coverage,
    completeness_score,
    CASE
        WHEN completeness_score < 30 THEN 'Critical'
        WHEN completeness_score < 60 THEN 'Warning'
        ELSE 'Good'
    END AS coverage_status
FROM
    data_discovery_dashboard_by_schema
WHERE
    completeness_score < 60  -- Only show schemas below 60% full enrichment
ORDER BY
    completeness_score ASC,
    total_columns DESC;
	
-- Business Case: Daily Governance Digest
-- Purpose: Generate a formatted summary of low-coverage schemas
-- Why It Matters:
--   - Automates communication with data stewards
--   - Encourages accountability and action
--   - Integrates with alerting systems

CREATE OR REPLACE FUNCTION generate_daily_digest()
RETURNS TABLE (
    subject TEXT,
    body TEXT
) AS $$
DECLARE
    total_low_schemas INTEGER;
    top_critical_schema TEXT;
BEGIN
    -- Get count of low-coverage schemas
    SELECT COUNT(*) INTO total_low_schemas
    FROM data_discovery_low_coverage_alerts;

    -- Get the worst-performing schema
    SELECT database_name || '.' || schema_name INTO top_critical_schema
    FROM data_discovery_low_coverage_alerts
    WHERE coverage_status = 'Critical'
    ORDER BY completeness_score ASC
    LIMIT 1;

    -- Return subject and body
    RETURN QUERY
    SELECT
        '[Daily Digest] ' || total_low_schemas || ' Schemas Need Metadata Attention' AS subject,
        'Hello Data Steward,' || E'\n\n' ||
        'We found ' || total_low_schemas || ' schema(s) with low metadata coverage today.' || E'\n' ||
        'These schemas are missing key information like business terms, tags, or documentation.' || E'\n\n' ||
        '🚨 Top Priority: ' || COALESCE(top_critical_schema, 'N/A') || E'\n\n' ||
        'Please log in to the Data Catalog to review and improve:' || E'\n' ||
        '👉 http://your-data-catalog.example.com/dashboards/governance' || E'\n\n' ||
        'Thank you for improving data discoverability!' AS body;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM generate_daily_digest();

-- python script to run dialy via airflow
-- import psycopg2
-- import smtplib
-- from email.mime.text import MIMEText
-- from config import DB_CONFIG, SMTP_CONFIG  # Your secrets

-- def send_daily_digest():
--     conn = psycopg2.connect(**DB_CONFIG)
--     cur = conn.cursor()

--     cur.execute("SELECT subject, body FROM generate_daily_digest();")
--     row = cur.fetchone()
--     subject, body = row

--     cur.close()
--     conn.close()

--     # Email setup
--     msg = MIMEText(body)
--     msg['Subject'] = subject
--     msg['From'] = SMTP_CONFIG['from']
--     msg['To'] = 'data-stewards@yourcompany.com'

--     # Send via SMTP
--     with smtplib.SMTP(SMTP_CONFIG['host'], SMTP_CONFIG['port']) as server:
--         server.starttls()
--         server.login(SMTP_CONFIG['user'], SMTP_CONFIG['password'])
--         server.send_message(msg)

--     print("Daily digest sent!")

-- if __name__ == "__main__":
--     send_daily_digest()

-- Business Case: Manages data_products data for the application.
-- Table Name: data_products
-- Purpose: Stores detailed information about data_products.
-- Additional Information: This table is central to the data_products module.

CREATE TABLE data_products (
    product_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    domain VARCHAR(255),
    data_contract JSONB,
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    version VARCHAR(255) DEFAULT '1.0.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    owner_id UUID REFERENCES data_owners(owner_id),
    steward_id UUID REFERENCES data_owners(owner_id)
);


-- Business Case: Manages data_product_components data for the application.
-- Table Name: data_product_components
-- Purpose: Stores detailed information about data_product_components.
-- Additional Information: This table is central to the data_product_components module.

CREATE TABLE data_product_components (
    component_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    is_required BOOLEAN DEFAULT TRUE,
    usage_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate mappings
    UNIQUE (product_id, column_id)
);


-- Business Case: Manages data_product_consumers data for the application.
-- Table Name: data_product_consumers
-- Purpose: Stores detailed information about data_product_consumers.
-- Additional Information: This table is central to the data_product_consumers module.

CREATE TABLE data_product_consumers (
    consumer_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    consumer_org VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_data_products_updated_at
    BEFORE UPDATE ON data_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_product_components_updated_at
    BEFORE UPDATE ON data_product_components
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_product_consumers_updated_at
    BEFORE UPDATE ON data_product_consumers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
	
	
-- data_products
CREATE INDEX idx_data_products_domain ON data_products(domain);
CREATE INDEX idx_data_products_owner ON data_products(owner_id);
CREATE INDEX idx_data_products_steward ON data_products(steward_id);
CREATE INDEX idx_data_products_published ON data_products(is_published);

-- data_product_components
CREATE INDEX idx_data_product_components_product ON data_product_components(product_id);
CREATE INDEX idx_data_product_components_column ON data_product_components(column_id);

-- data_product_consumers
CREATE INDEX idx_data_product_consumers_product ON data_product_consumers(product_id);
CREATE INDEX idx_data_product_consumers_org ON data_product_consumers(consumer_org);
CREATE INDEX idx_data_product_consumers_contact ON data_product_consumers(contact_email);


-- Business Case: Full Data Product Context
-- Purpose: Show complete information about each data product, including its components and consumers
-- Why It Matters:
--   - Enables self-service discovery of data products
--   - Shows who owns it, what it contains, and who uses it
--   - Supports governance, SLA tracking, and impact analysis

CREATE OR REPLACE VIEW data_product_full_context AS
SELECT
    -- Product Identity
    p.product_id,
    p.product_name,
    p.description,
    p.domain,
    p.version,
    p.is_published,
    p.published_at,

    -- Ownership
    owner.name AS owner_name,
    owner.email AS owner_email,
    steward.name AS steward_name,
    steward.email AS steward_email,

    -- Components (Columns)
    COUNT(pc.component_id) AS total_components,
    STRING_AGG(DISTINCT c.column_name, ', ') FILTER (WHERE c.column_name IS NOT NULL) AS sample_columns,
    STRING_AGG(DISTINCT t.table_name || '.' || s.schema_name, ', ') 
        FILTER (WHERE t.table_name IS NOT NULL AND s.schema_name IS NOT NULL) AS tables_used,

    -- Required vs Optional
    COUNT(pc.component_id) FILTER (WHERE pc.is_required) AS required_components,
    COUNT(pc.component_id) FILTER (WHERE NOT pc.is_required) AS optional_components,

    -- Usage Description Summary
    STRING_AGG(DISTINCT SUBSTRING(pc.usage_description FOR 100), ' | ') 
        FILTER (WHERE pc.usage_description IS NOT NULL) AS usage_overview,

    -- Consumers
    COUNT(con.consumer_id) AS total_consumers,
    STRING_AGG(DISTINCT con.consumer_org, ', ') FILTER (WHERE con.consumer_org IS NOT NULL) AS consumer_organizations,
    MAX(con.last_accessed) AS last_consumer_access,

    -- Metadata
    p.created_at,
    p.updated_at,
    p.data_contract

FROM
    data_products p
LEFT JOIN data_owners owner ON p.owner_id = owner.owner_id
LEFT JOIN data_owners steward ON p.steward_id = steward.owner_id
LEFT JOIN data_product_components pc ON p.product_id = pc.product_id
LEFT JOIN columns c ON pc.column_id = c.column_id
LEFT JOIN tables t ON c.table_id = t.table_id
LEFT JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN data_product_consumers con ON p.product_id = con.product_id

GROUP BY
    p.product_id,
    p.product_name,
    p.description,
    p.domain,
    p.version,
    p.is_published,
    p.published_at,
    owner.name,
    owner.email,
    steward.name,
    steward.email,
    p.created_at,
    p.updated_at,
    p.data_contract;
	
	
	
	
-- Business Case: Data Contract Compliance Checker
-- Purpose: Validate that all required columns in the data product exist
-- Why It Matters:
--   - Ensures backward compatibility
--   - Prevents breaking changes
--   - Supports automated CI/CD pipelines

CREATE OR REPLACE FUNCTION check_data_contract_compliance(target_product_id UUID)
RETURNS TABLE (
    product_name TEXT,
    total_required_components INT,
    missing_components INT,
    compliant BOOLEAN,
    non_compliant_columns TEXT[],
    checked_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    missing_cols TEXT[];
BEGIN
    -- Get list of missing required components
    SELECT
        ARRAY_AGG(c.column_name ORDER BY c.column_name),
        COUNT(*)
    INTO
        missing_cols,
        missing_components
    FROM
        data_product_components pc
    JOIN columns c ON pc.column_id = c.column_id
    WHERE
        pc.product_id = target_product_id
        AND pc.is_required = TRUE
        AND NOT EXISTS (
            SELECT 1 FROM columns c2 WHERE c2.column_id = pc.column_id
        );

    -- If no missing components, set to empty array
    IF missing_cols IS NULL THEN
        missing_cols := '{}';
        missing_components := 0;
    END IF;

    RETURN QUERY
    SELECT
        p.product_name::TEXT,
        COALESCE(req.total_required, 0)::INT AS total_required_components,
        COALESCE(missing_components, 0)::INT AS missing_components,
        (COALESCE(missing_components, 0) = 0) AS compliant,
        missing_cols AS non_compliant_columns,
        NOW() AS checked_at
    FROM
        data_products p
    LEFT JOIN (
        SELECT product_id, COUNT(*) AS total_required
        FROM data_product_components
        WHERE is_required = TRUE
        GROUP BY product_id
    ) req ON p.product_id = req.product_id
    WHERE
        p.product_id = target_product_id;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Data Product Change History
-- Purpose: Log changes to data products for audit and compliance
-- Why It Matters:
--   - Enables historical analysis of product changes
--   - Supports regulatory reporting
--   - Helps identify who made updates

CREATE TABLE data_products_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    domain VARCHAR(255),
    data_contract JSONB,
    is_published BOOLEAN,
    published_at TIMESTAMP WITH TIME ZONE,
    version VARCHAR(255),
    owner_id UUID,
    steward_id UUID,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);


CREATE OR REPLACE FUNCTION log_data_product_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO data_products_history (
            product_id, product_name, description, domain,
            data_contract, is_published, published_at,
            version, owner_id, steward_id, action_type
        )
        VALUES (
            NEW.product_id, NEW.product_name, NEW.description, NEW.domain,
            NEW.data_contract, NEW.is_published, NEW.published_at,
            NEW.version, NEW.owner_id, NEW.steward_id, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO data_products_history (
            product_id, product_name, description, domain,
            data_contract, is_published, published_at,
            version, owner_id, steward_id, action_type
        )
        VALUES (
            OLD.product_id, OLD.product_name, OLD.description, OLD.domain,
            OLD.data_contract, OLD.is_published, OLD.published_at,
            OLD.version, OLD.owner_id, OLD.steward_id, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO data_products_history (
            product_id, product_name, description, domain,
            data_contract, is_published, published_at,
            version, owner_id, steward_id, action_type
        )
        VALUES (
            OLD.product_id, OLD.product_name, OLD.description, OLD.domain,
            OLD.data_contract, OLD.is_published, OLD.published_at,
            OLD.version, OLD.owner_id, OLD.steward_id, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_data_products_audit
AFTER INSERT OR UPDATE OR DELETE ON data_products
FOR EACH ROW EXECUTE FUNCTION log_data_product_changes();
-- Business Case: Data Product Scorecard
-- Purpose: Provide a high-level summary of all data products and their maturity
-- Why It Matters:
--   - Measures progress toward full productization
--   - Supports executive reporting
--   - Highlights gaps in publishing, ownership, or usage

CREATE OR REPLACE VIEW data_product_scorecard AS
SELECT
    COUNT(p.product_id) AS total_products,

    -- Publishing Status
    COUNT(p.product_id) FILTER (WHERE p.is_published) AS published_products,
    ROUND(
        (COUNT(p.product_id) FILTER (WHERE p.is_published)::NUMERIC / COUNT(p.product_id)) * 100,
        2
    ) AS publish_rate_percent,

    -- Ownership & Stewardship
    COUNT(p.product_id) FILTER (WHERE p.owner_id IS NOT NULL) AS products_with_owner,
    COUNT(p.product_id) FILTER (WHERE p.steward_id IS NOT NULL) AS products_with_steward,
    ROUND(
        (COUNT(p.product_id) FILTER (WHERE p.owner_id IS NOT NULL AND p.steward_id IS NOT NULL)::NUMERIC / COUNT(p.product_id)) * 100,
        2
    ) AS fully_owned_products_percent,

    -- Component Coverage
    COALESCE(AVG(comp.component_count), 0) AS avg_components_per_product,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY comp.component_count) AS median_components,

    -- Consumer Adoption
    COUNT(p.product_id) FILTER (WHERE cons.consumer_count > 0) AS adopted_products,
    ROUND(
        (COUNT(p.product_id) FILTER (WHERE cons.consumer_count > 0)::NUMERIC / COUNT(p.product_id)) * 100,
        2
    ) AS adoption_rate_percent,
    COALESCE(SUM(cons.consumer_count), 0) AS total_consumer_subscriptions,

    -- Data Contract Usage
    COUNT(p.product_id) FILTER (WHERE p.data_contract IS NOT NULL) AS products_with_contract,
    ROUND(
        (COUNT(p.product_id) FILTER (WHERE p.data_contract IS NOT NULL)::NUMERIC / COUNT(p.product_id)) * 100,
        2
    ) AS contract_coverage_percent,

    -- Overall Maturity Score (weighted)
    ROUND(
        (
            (COUNT(p.product_id) FILTER (WHERE p.is_published)::NUMERIC / COUNT(p.product_id)) * 30 +
            (COUNT(p.product_id) FILTER (WHERE p.owner_id IS NOT NULL AND p.steward_id IS NOT NULL)::NUMERIC / COUNT(p.product_id)) * 20 +
            (COUNT(p.product_id) FILTER (WHERE cons.consumer_count > 0)::NUMERIC / COUNT(p.product_id)) * 30 +
            (COUNT(p.product_id) FILTER (WHERE p.data_contract IS NOT NULL)::NUMERIC / COUNT(p.product_id)) * 20
        ), 2
    ) AS overall_maturity_score

FROM
    data_products p
LEFT JOIN (
    SELECT product_id, COUNT(component_id) AS component_count
    FROM data_product_components
    GROUP BY product_id
) comp ON p.product_id = comp.product_id
LEFT JOIN (
    SELECT product_id, COUNT(consumer_id) AS consumer_count
    FROM data_product_consumers
    GROUP BY product_id
) cons ON p.product_id = cons.product_id;

-- Business Case: Manages metadata_enrichment data for the application.
-- Table Name: metadata_enrichment
-- Purpose: Stores detailed information about metadata_enrichment.
-- Additional Information: This table is central to the metadata_enrichment module.

CREATE TABLE metadata_enrichment (
    enrichment_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    approved_by UUID REFERENCES users(user_id),
    original_value TEXT,
    enriched_value TEXT,
    confidence_score NUMERIC,
    model_version VARCHAR(255),
    last_refreshed TIMESTAMP WITH TIME ZONE,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_insights data for the application.
-- Table Name: column_insights
-- Purpose: Stores detailed information about column_insights.
-- Additional Information: This table is central to the column_insights module.

CREATE TABLE column_insights (
    insight_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    predictive_relevance_score NUMERIC,
    recommended_index BOOLEAN DEFAULT FALSE,
    recommended_index_type VARCHAR(255),
    schema_drift_detected BOOLEAN DEFAULT FALSE,
    schema_drift_alert BOOLEAN DEFAULT FALSE,
    schema_drift_details TEXT,
    anomaly_detected BOOLEAN DEFAULT FALSE,
    anomaly_details TEXT,
    ai_generated_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages anomaly_detection_results data for the application.
-- Table Name: anomaly_detection_results
-- Purpose: Stores detailed information about anomaly_detection_results.
-- Additional Information: This table is central to the anomaly_detection_results module.

CREATE TABLE anomaly_detection_results (
    result_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    anomaly_score NUMERIC,
    anomaly_details JSONB,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT
);

-- Business Case: Manages database_connections data for the application.
-- Table Name: database_connections
-- Purpose: Stores detailed information about database_connections.
-- Additional Information: This table is central to the database_connections module.

CREATE TABLE database_connections (
    connection_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    database_id UUID REFERENCES databases(database_id),
    connection_name VARCHAR(255) NOT NULL,
    connection_string TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_harvested TIMESTAMP WITH TIME ZONE,
    harvest_frequency INTEGER DEFAULT 1440, -- Default: 1440 minutes = 1 day
    connection_properties JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_metadata_enrichment_updated_at
    BEFORE UPDATE ON metadata_enrichment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_column_insights_updated_at
    BEFORE UPDATE ON column_insights
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_database_connections_updated_at
    BEFORE UPDATE ON database_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
	
	
	
-- metadata_enrichment
CREATE INDEX idx_metadata_enrichment_column ON metadata_enrichment(column_id);
CREATE INDEX idx_metadata_enrichment_approved ON metadata_enrichment(approved_by);

-- column_insights
CREATE INDEX idx_column_insights_column ON column_insights(column_id);
CREATE INDEX idx_column_insights_drift ON column_insights(schema_drift_detected, anomaly_detected);

-- anomaly_detection_results
CREATE INDEX idx_anomaly_results_column ON anomaly_detection_results(column_id);
CREATE INDEX idx_anomaly_results_detected ON anomaly_detection_results(detected_at);
CREATE INDEX idx_anomaly_results_resolved ON anomaly_detection_results(is_resolved);

-- database_connections
CREATE INDEX idx_db_connections_database ON database_connections(database_id);
CREATE INDEX idx_db_connections_active ON database_connections(is_active);


-- Business Case: Full Column Observability
-- Purpose: Show unified view of AI/ML-generated insights, anomalies, and metadata enrichment per column
-- Why It Matters:
--   - Enables holistic monitoring of column health
--   - Supports data stewards in prioritizing actions
--   - Integrates with dashboards and alerting systems

CREATE OR REPLACE VIEW column_observability_full_view AS
SELECT
    -- Column Identity
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Insights
    ci.predictive_relevance_score,
    ci.recommended_index,
    ci.recommended_index_type,
    ci.schema_drift_detected,
    ci.schema_drift_details,
    ci.anomaly_detected,
    ci.anomaly_details,
    ci.ai_generated_description,
    ci.created_at AS insight_created_at,
    ci.updated_at AS insight_updated_at,

    -- Latest Anomaly (if any)
    adr.result_id AS latest_anomaly_id,
    adr.detected_at AS last_anomaly_detected_at,
    adr.anomaly_score,
    adr.is_resolved AS anomaly_resolved,
    adr.resolution_notes,

    -- Metadata Enrichment
    me.original_value,
    me.enriched_value,
    me.confidence_score,
    me.model_version,
    me.last_refreshed AS enrichment_last_refreshed,
    me.is_approved AS enrichment_approved,
    me.approved_at AS enrichment_approved_at,

    -- Summary Flags
    CASE
        WHEN ci.schema_drift_detected THEN 'High'
        WHEN ci.anomaly_detected AND adr.is_resolved = FALSE THEN 'Medium'
        WHEN me.confidence_score < 0.7 THEN 'Low'
        ELSE 'None'
    END AS overall_risk_level,

    -- Last Updated
    GREATEST(
        ci.updated_at,
        adr.detected_at,
        me.last_refreshed,
        ci.created_at,
        adr.detected_at,
        me.created_at
    ) AS last_observed_change

FROM
    columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

-- Insights
LEFT JOIN column_insights ci ON c.column_id = ci.column_id

-- Latest Anomaly (per column)
LEFT JOIN LATERAL (
    SELECT *
    FROM anomaly_detection_results adr2
    WHERE adr2.column_id = c.column_id
    ORDER BY adr2.detected_at DESC
    LIMIT 1
) adr ON TRUE

-- Metadata Enrichment
LEFT JOIN metadata_enrichment me ON c.column_id = me.column_id

ORDER BY
    last_observed_change DESC NULLS LAST;
	
	
	
-- Business Case: Schema Drift Trend Detector
-- Purpose: Identify columns with repeated or worsening schema drift over time
-- Why It Matters:
--   - Helps catch unstable pipelines early
--   - Supports root cause analysis
--   - Enables automated alerts

CREATE OR REPLACE FUNCTION detect_schema_drift_trends(days INTEGER DEFAULT 7)
RETURNS TABLE (
    column_id UUID,
    column_name TEXT,
    table_name TEXT,
    schema_name TEXT,
    database_name TEXT,
    drift_event_count BIGINT,
    first_detected TIMESTAMP WITH TIME ZONE,
    last_detected TIMESTAMP WITH TIME ZONE,
    trend_status TEXT,
    recent_details TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.column_id,
        c.column_name::TEXT,
        t.table_name::TEXT,
        s.schema_name::TEXT,
        d.database_name::TEXT,
        COUNT(*) AS drift_event_count,
        MIN(ci.created_at) AS first_detected,
        MAX(ci.created_at) AS last_detected,
        CASE
            WHEN COUNT(*) >= 3 THEN 'Recurring'
            WHEN MAX(ci.created_at) > NOW() - INTERVAL '1 day' THEN 'Recent'
            ELSE 'Historical'
        END AS trend_status,
        STRING_AGG(DISTINCT SUBSTRING(ci.schema_drift_details FOR 100), '; ') AS recent_details
    FROM
        column_insights ci
    JOIN columns c ON ci.column_id = c.column_id
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    WHERE
        ci.schema_drift_detected = TRUE
        AND ci.created_at >= NOW() - (days || ' days')::INTERVAL
    GROUP BY
        c.column_id,
        c.column_name,
        t.table_name,
        s.schema_name,
        d.database_name
    HAVING
        COUNT(*) >= 1
    ORDER BY
        drift_event_count DESC,
        last_detected DESC;
END;
$$ LANGUAGE plpgsql;

-- Drift in last 7 days
SELECT * FROM detect_schema_drift_trends(7);

-- Last 30 days
SELECT * FROM detect_schema_drift_trends(30);


-- Business Case: Metadata Enrichment Change History
-- Purpose: Log changes to metadata enrichment records
-- Why It Matters:
--   - Enables audit and compliance
--   - Tracks approval history
--   - Supports versioning

CREATE TABLE metadata_enrichment_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    enrichment_id UUID NOT NULL,
    column_id UUID,
    approved_by UUID,
    original_value TEXT,
    enriched_value TEXT,
    confidence_score NUMERIC,
    model_version VARCHAR(255),
    last_refreshed TIMESTAMP WITH TIME ZONE,
    is_approved BOOLEAN,
    approved_at TIMESTAMP WITH TIME ZONE,
    action_type VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    changed_by TEXT DEFAULT session_user
);



-- Function
CREATE OR REPLACE FUNCTION log_metadata_enrichment_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO metadata_enrichment_history (
            enrichment_id, column_id, approved_by, original_value, enriched_value,
            confidence_score, model_version, last_refreshed, is_approved, approved_at, action_type
        )
        VALUES (
            NEW.enrichment_id, NEW.column_id, NEW.approved_by, NEW.original_value, NEW.enriched_value,
            NEW.confidence_score, NEW.model_version, NEW.last_refreshed, NEW.is_approved, NEW.approved_at, 'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO metadata_enrichment_history (
            enrichment_id, column_id, approved_by, original_value, enriched_value,
            confidence_score, model_version, last_refreshed, is_approved, approved_at, action_type
        )
        VALUES (
            OLD.enrichment_id, OLD.column_id, OLD.approved_by, OLD.original_value, OLD.enriched_value,
            OLD.confidence_score, OLD.model_version, OLD.last_refreshed, OLD.is_approved, OLD.approved_at, 'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO metadata_enrichment_history (
            enrichment_id, column_id, approved_by, original_value, enriched_value,
            confidence_score, model_version, last_refreshed, is_approved, approved_at, action_type
        )
        VALUES (
            OLD.enrichment_id, OLD.column_id, OLD.approved_by, OLD.original_value, OLD.enriched_value,
            OLD.confidence_score, OLD.model_version, OLD.last_refreshed, OLD.is_approved, OLD.approved_at, 'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trigger_metadata_enrichment_audit
AFTER INSERT OR UPDATE OR DELETE ON metadata_enrichment
FOR EACH ROW EXECUTE FUNCTION log_metadata_enrichment_changes();



-- Business Case: Manages table_dependencies data for the application.
-- Table Name: table_dependencies
-- Purpose: Stores detailed information about table_dependencies.
-- Additional Information: This table is central to the table_dependencies module.

CREATE TABLE table_dependencies (
    dependency_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source_table_id UUID NOT NULL REFERENCES tables(table_id),
    target_table_id UUID NOT NULL REFERENCES tables(table_id),
    description TEXT NOT NULL,
    confidence_score NUMERIC DEFAULT 0.8,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate dependencies
    UNIQUE (source_table_id, target_table_id)
);


-- Business Case: Manages column_statistics data for the application.
-- Table Name: column_statistics
-- Purpose: Stores detailed information about column_statistics.
-- Additional Information: This table is central to the column_statistics module.

CREATE TABLE column_statistics (
    stats_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    null_count INTEGER,
    distinct_count INTEGER,
    min_value TEXT,
    max_value TEXT,
    avg_value TEXT,        -- Can store formatted number or 'N/A' for non-numeric
    median_value TEXT,
    value_distribution JSONB,
    pattern_distribution JSONB,
    data_freshness INTEGER, -- e.g., days since last update
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages access_logs data for the application.
-- Table Name: access_logs
-- Purpose: Stores detailed information about access_logs.
-- Additional Information: This table is central to the access_logs module.

CREATE TABLE access_logs (
    log_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    access_method VARCHAR(255) NOT NULL, -- e.g., 'UI', 'API', 'SQL'
    query_parameters TEXT,
    client_ip VARCHAR(45), -- IPv6-compatible
    was_approved BOOLEAN NOT NULL,
    approval_mechanism VARCHAR(255) -- e.g., 'RBAC', 'Manual Approval', 'Policy Engine'
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for table_dependencies
CREATE TRIGGER update_table_dependencies_updated_at
    BEFORE UPDATE ON table_dependencies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
	
	
-- table_dependencies
CREATE INDEX idx_table_dependencies_source ON table_dependencies(source_table_id);
CREATE INDEX idx_table_dependencies_target ON table_dependencies(target_table_id);
CREATE INDEX idx_table_dependencies_active ON table_dependencies(is_active);

-- column_statistics
CREATE INDEX idx_column_stats_column ON column_statistics(column_id);
CREATE INDEX idx_column_stats_calculated ON column_statistics(calculated_at);
CREATE INDEX idx_column_stats_distinct ON column_statistics(distinct_count);
CREATE INDEX idx_column_stats_freshness ON column_statistics(data_freshness);

-- access_logs
CREATE INDEX idx_access_logs_user ON access_logs(user_id);
CREATE INDEX idx_access_logs_column ON access_logs(column_id);
CREATE INDEX idx_access_logs_accessed ON access_logs(accessed_at);
CREATE INDEX idx_access_logs_approved ON access_logs(was_approved);
CREATE INDEX idx_access_logs_ip ON access_logs(client_ip);


-- Business Case: Full Table Lineage Path
-- Purpose: Show complete source-to-target data flow between tables
-- Why It Matters:
--   - Enables impact analysis ("What feeds this table?")
--   - Supports data migration and deprecation workflows
--   - Helps debug pipeline failures and data issues

CREATE OR REPLACE VIEW table_lineage_full_path AS
WITH RECURSIVE lineage_tree AS (
    -- Base case: direct dependencies (level 1)
    SELECT
        td.dependency_id,
        td.source_table_id,
        src.table_name AS source_table_name,
        src_sch.schema_name AS source_schema_name,
        src_db.database_name AS source_database_name,
        td.target_table_id,
        tgt.table_name AS target_table_name,
        tgt_sch.schema_name AS target_schema_name,
        tgt_db.database_name AS target_database_name,
        td.description,
        td.confidence_score,
        td.is_active,
        1 AS level,
        ARRAY[src.table_name]::TEXT[] AS path  -- ✅ Cast to TEXT[]
    FROM
        table_dependencies td
    JOIN tables src ON td.source_table_id = src.table_id
    JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
    JOIN databases src_db ON src_sch.database_id = src_db.database_id
    JOIN tables tgt ON td.target_table_id = tgt.table_id
    JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
    JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
    WHERE
        td.is_active = TRUE

    UNION ALL

    -- Recursive case: chain dependencies forward
    SELECT
        td.dependency_id,
        td.source_table_id,
        src.table_name AS source_table_name,
        src_sch.schema_name AS source_schema_name,
        src_db.database_name AS source_database_name,
        td.target_table_id,
        tgt.table_name AS target_table_name,
        tgt_sch.schema_name AS target_schema_name,
        tgt_db.database_name AS target_database_name,
        td.description,
        td.confidence_score,
        td.is_active,
        lt.level + 1 AS level,
        lt.path || src.table_name AS path  -- Now matches TEXT[] type
    FROM
        table_dependencies td
    JOIN tables src ON td.source_table_id = src.table_id
    JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
    JOIN databases src_db ON src_sch.database_id = src_db.database_id
    JOIN tables tgt ON td.target_table_id = tgt.table_id
    JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
    JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
    JOIN lineage_tree lt ON td.source_table_id = lt.target_table_id
    WHERE
        td.is_active = TRUE
        AND src.table_name <> ALL(lt.path) -- Prevent cycles
        AND lt.level < 10 -- Limit depth
)
SELECT
    dependency_id,
    source_database_name,
    source_schema_name,
    source_table_name,
    target_database_name,
    target_schema_name,
    target_table_name,
    description,
    confidence_score,
    is_active,
    level,
    path AS lineage_path
FROM
    lineage_tree
ORDER BY
    level,
    source_database_name,
    source_schema_name,
    source_table_name,
    target_table_name;


CREATE OR REPLACE FUNCTION trace_table_upstream(
    target_table_name TEXT,
    max_depth INTEGER DEFAULT 10
)
RETURNS TABLE (
    level INTEGER,
    source_database TEXT,
    source_schema TEXT,
    source_table TEXT,
    target_database TEXT,
    target_schema TEXT,
    target_table TEXT,
    description TEXT,
    confidence_score NUMERIC,
    path TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE upstream AS (
        -- Base: find direct sources
        SELECT
            1 AS level,
            src_db.database_name::TEXT,
            src_sch.schema_name::TEXT,
            src.table_name::TEXT AS source_table,
            tgt_db.database_name::TEXT,
            tgt_sch.schema_name::TEXT,
            tgt.table_name::TEXT AS target_table,
            td.description,
            td.confidence_score,
            ARRAY[src.table_name]::TEXT[] AS path
        FROM
            table_dependencies td
        JOIN tables src ON td.source_table_id = src.table_id
        JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
        JOIN databases src_db ON src_sch.database_id = src_db.database_id
        JOIN tables tgt ON td.target_table_id = tgt.table_id
        JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
        JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
        WHERE
            tgt.table_name ILIKE target_table_name
            AND td.is_active = TRUE

        UNION ALL

        -- Recurse up
        SELECT
            u.level + 1,
            src_db.database_name,
            src_sch.schema_name,
            src.table_name,
            tgt_db.database_name,
            tgt_sch.schema_name,
            tgt.table_name,
            td.description,
            td.confidence_score,
            u.path || src.table_name
        FROM
            table_dependencies td
        JOIN tables src ON td.source_table_id = src.table_id
        JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
        JOIN databases src_db ON src_sch.database_id = src_db.database_id
        JOIN tables tgt ON td.target_table_id = tgt.table_id
        JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
        JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
        JOIN upstream u ON src.table_name = u.source_table
        WHERE
            td.is_active = TRUE
            AND u.level < max_depth
            AND NOT (src.table_name = ANY(u.path)) -- No cycles
    )
    SELECT * FROM upstream ORDER BY level, source_table;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trace_table_downstream(
    source_table_name TEXT,
    max_depth INTEGER DEFAULT 10
)
RETURNS TABLE (
    level INTEGER,
    source_database TEXT,
    source_schema TEXT,
    source_table TEXT,
    target_database TEXT,
    target_schema TEXT,
    target_table TEXT,
    description TEXT,
    confidence_score NUMERIC,
    path TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE downstream AS (
        SELECT
            1 AS level,
            src_db.database_name::TEXT,
            src_sch.schema_name::TEXT,
            src.table_name::TEXT,
            tgt_db.database_name::TEXT,
            tgt_sch.schema_name::TEXT,
            tgt.table_name::TEXT,
            td.description,
            td.confidence_score,
            ARRAY[tgt.table_name]::TEXT[] AS path
        FROM
            table_dependencies td
        JOIN tables src ON td.source_table_id = src.table_id
        JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
        JOIN databases src_db ON src_sch.database_id = src_db.database_id
        JOIN tables tgt ON td.target_table_id = tgt.table_id
        JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
        JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
        WHERE
            src.table_name ILIKE source_table_name
            AND td.is_active = TRUE

        UNION ALL

        SELECT
            d.level + 1,
            src_db.database_name,
            src_sch.schema_name,
            src.table_name,
            tgt_db.database_name,
            tgt_sch.schema_name,
            tgt.table_name,
            td.description,
            td.confidence_score,
            d.path || tgt.table_name
        FROM
            table_dependencies td
        JOIN tables src ON td.source_table_id = src.table_id
        JOIN schemas src_sch ON src.schema_id = src_sch.schema_id
        JOIN databases src_db ON src_sch.database_id = src_db.database_id
        JOIN tables tgt ON td.target_table_id = tgt.table_id
        JOIN schemas tgt_sch ON tgt.schema_id = tgt_sch.schema_id
        JOIN databases tgt_db ON tgt_sch.database_id = tgt_db.database_id
        JOIN downstream d ON tgt.table_name = d.target_table
        WHERE
            td.is_active = TRUE
            AND d.level < max_depth
            AND NOT (tgt.table_name = ANY(d.path))
    )
    SELECT * FROM downstream ORDER BY level, target_table;
END;
$$ LANGUAGE plpgsql;


-- audit logging for critical metadata changes 
CREATE TABLE table_dependencies_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dependency_id UUID,
    source_table_id UUID,
    target_table_id UUID,
    description TEXT,
    confidence_score NUMERIC,
    is_active BOOLEAN,
    action_type VARCHAR(10),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    changed_by TEXT DEFAULT session_user
);

CREATE OR REPLACE FUNCTION log_table_dependencies_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO table_dependencies_history VALUES (DEFAULT, NEW.*, 'INSERT', NOW(), session_user);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO table_dependencies_history VALUES (DEFAULT, OLD.*, 'UPDATE', NOW(), session_user);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO table_dependencies_history VALUES (DEFAULT, OLD.*, 'DELETE', NOW(), session_user);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_table_dependencies_audit
AFTER INSERT OR UPDATE OR DELETE ON table_dependencies
FOR EACH ROW EXECUTE FUNCTION log_table_dependencies_changes();



CREATE OR REPLACE VIEW top_accessed_columns AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    COUNT(*) AS total_accesses,
    COUNT(*) FILTER (WHERE a.was_approved) AS approved_accesses,
    ROUND(
        (COUNT(*) FILTER (WHERE a.was_approved)::NUMERIC / COUNT(*)) * 100,
        2
    ) AS approval_rate_percent,
    MAX(a.accessed_at) AS last_accessed
FROM
    access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
GROUP BY
    c.column_id, c.column_name, t.table_name, s.schema_name, d.database_name
ORDER BY
    total_accesses DESC
LIMIT 100;


-- Business Case: Top Accessed Columns
-- Purpose: Show the most frequently accessed columns across the data platform
-- Why It Matters:
--   - Helps prioritize governance and documentation efforts
--   - Supports capacity planning and indexing decisions
--   - Enables monitoring of sensitive data access

CREATE OR REPLACE VIEW top_accessed_columns AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Access Metrics
    COUNT(*) AS total_access_count,
    COUNT(*) FILTER (WHERE a.was_approved) AS approved_access_count,
    COUNT(*) FILTER (WHERE NOT a.was_approved) AS denied_or_unapproved_count,
    
    ROUND(
        (COUNT(*) FILTER (WHERE a.was_approved)::NUMERIC / NULLIF(COUNT(*), 0)) * 100,
        2
    ) AS approval_rate_percent,

    -- Temporal Insights
    MIN(a.accessed_at) AS first_accessed,
    MAX(a.accessed_at) AS last_accessed,
    EXTRACT(EPOCH FROM (MAX(a.accessed_at) - MIN(a.accessed_at))) / 3600 AS hours_since_first_access,

    -- User Diversity
    COUNT(DISTINCT a.user_id) AS unique_users,

    -- Common Access Methods
    STRING_AGG(DISTINCT a.access_method, ', ') AS access_methods_used

FROM
    access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name

HAVING
    COUNT(*) >= 1  -- At least one access

ORDER BY
    total_access_count DESC,
    last_accessed DESC;


-- Business Case: Top Accessed Columns
-- Purpose: Show the most frequently accessed columns across the data platform
-- Why It Matters:
--   - Helps prioritize governance and documentation efforts
--   - Supports capacity planning and indexing decisions
--   - Enables monitoring of sensitive data access


-- Recreate with correct column names
CREATE OR REPLACE VIEW top_accessed_columns AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Access Metrics
    COUNT(*) AS total_access_count,
    COUNT(*) FILTER (WHERE a.was_approved) AS approved_access_count,
    COUNT(*) FILTER (WHERE NOT a.was_approved) AS denied_or_unapproved_count,
    
    ROUND(
        (COUNT(*) FILTER (WHERE a.was_approved)::NUMERIC / NULLIF(COUNT(*), 0)) * 100,
        2
    ) AS approval_rate_percent,

    -- Temporal Insights
    MIN(a.accessed_at) AS first_accessed,
    MAX(a.accessed_at) AS last_accessed,
    EXTRACT(EPOCH FROM (MAX(a.accessed_at) - MIN(a.accessed_at))) / 3600 AS hours_since_first_access,

    -- User Diversity
    COUNT(DISTINCT a.user_id) AS unique_users,

    -- Common Access Methods
    STRING_AGG(DISTINCT a.access_method, ', ') AS access_methods_used

FROM
    access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name

HAVING
    COUNT(*) >= 1

ORDER BY
    total_access_count DESC,
    last_accessed DESC;


-- Business Case: Daily Access Log Summary
-- Purpose: Get aggregated access trends over the last N days
-- Why It Matters:
--   - Tracks usage growth or decline
--   - Supports security audits and reporting
--   - Powers dashboards and alerts

-- Business Case: Daily Access Log Summary
-- Purpose: Get aggregated access trends over the last N days
-- Why It Matters:
--   - Tracks usage growth or decline
--   - Supports security audits and reporting
--   - Powers dashboards and alerts

CREATE OR REPLACE FUNCTION get_access_log_summary(days INTEGER DEFAULT 7)
RETURNS TABLE (
    report_date DATE,
    total_accesses BIGINT,
    approved_accesses BIGINT,
    unapproved_attempts BIGINT,
    unique_users BIGINT,
    top_column TEXT,
    top_table TEXT,
    peak_hour TIME,
    avg_hourly_accesses NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_access AS (
        SELECT
            DATE(a.accessed_at) AS access_date,
            EXTRACT(HOUR FROM a.accessed_at)::INTEGER AS hour,
            a.column_id,
            a.user_id,
            a.was_approved
        FROM
            access_logs a
        WHERE
            a.accessed_at >= NOW() - (days || ' days')::INTERVAL
    ),
    summary AS (
        SELECT
            access_date,
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE was_approved) AS approved,
            COUNT(*) FILTER (WHERE NOT was_approved) AS unapproved,
            COUNT(DISTINCT user_id) AS users,
            MODE() WITHIN GROUP (ORDER BY column_id) AS most_accessed_column_id
        FROM
            daily_access
        GROUP BY
            access_date
    ),
    hourly_stats AS (
        SELECT
            access_date,
            hour,
            COUNT(*) AS hourly_count
        FROM
            daily_access
        GROUP BY
            access_date, hour
    ),
    top_hour AS (
        SELECT DISTINCT ON (access_date)
            access_date,
            MAKE_TIME(hour, 0, 0) AS peak_hour
        FROM
            hourly_stats
        ORDER BY
            access_date, hourly_count DESC
    )
    SELECT
        s.access_date AS report_date,
        s.total::BIGINT,
        s.approved::BIGINT,
        s.unapproved::BIGINT,
        s.users::BIGINT,
        c.column_name::TEXT AS top_column,     -- Cast to TEXT
        t.table_name::TEXT AS top_table,       -- Cast to TEXT
        th.peak_hour,
        AVG(hs.hourly_count)::NUMERIC AS avg_hourly_accesses
    FROM
        summary s
    LEFT JOIN columns c ON s.most_accessed_column_id = c.column_id
    LEFT JOIN tables t ON c.table_id = t.table_id
    LEFT JOIN top_hour th ON s.access_date = th.access_date
    LEFT JOIN hourly_stats hs ON s.access_date = hs.access_date
    GROUP BY
        s.access_date,
        s.total,
        s.approved,
        s.unapproved,
        s.users,
        c.column_name,
        t.table_name,
        th.peak_hour
    ORDER BY
        s.access_date DESC;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_access_log_summary(7);  -- Last week
SELECT * FROM get_access_log_summary(30); -- Last month

-- Business Case: Sensitive Access Audit Log
-- Purpose: Track all access attempts to sensitive columns
-- Why It Matters:
--   - Supports compliance (GDPR, HIPAA, CCPA)
--   - Enables forensic analysis
--   - Powers alerting systems

CREATE TABLE sensitive_column_access_audit (
    audit_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    log_id UUID REFERENCES access_logs(log_id),
    column_id UUID,
    column_name TEXT,
    table_name TEXT,
    schema_name TEXT,
    database_name TEXT,
    user_id UUID,
    user_email TEXT,
    accessed_at TIMESTAMP WITH TIME ZONE,
    was_approved BOOLEAN,
    client_ip VARCHAR(45),
    is_unapproved_sensitive_access BOOLEAN,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_sensitive_access()
RETURNS TRIGGER AS $$
DECLARE
    is_sensitive BOOLEAN := FALSE;
BEGIN
    -- Check if column is tagged as sensitive
    SELECT TRUE INTO is_sensitive
    FROM column_tag_mapping ctm
    JOIN search_tags st ON ctm.tag_id = st.tag_id
    WHERE
        ctm.column_id = NEW.column_id
        AND st.tag_name ILIKE ANY(ARRAY['PII', 'SSN', 'Password', 'Email', 'Phone', 'DOB', 'Credit Card']);

    IF is_sensitive THEN
        INSERT INTO sensitive_column_access_audit (
            log_id,
            column_id,
            column_name,
            table_name,
            schema_name,
            database_name,
            user_id,
            user_email,
            accessed_at,
            was_approved,
            client_ip,
            is_unapproved_sensitive_access
        )
        SELECT
            NEW.log_id,
            c.column_id,
            c.column_name,
            t.table_name,
            s.schema_name,
            d.database_name,
            NEW.user_id,
            u.email,
            NEW.accessed_at,
            NEW.was_approved,
            NEW.client_ip,
            NOT NEW.was_approved
        FROM
            columns c
            JOIN tables t ON c.table_id = t.table_id
            JOIN schemas s ON t.schema_id = s.schema_id
            JOIN databases d ON s.database_id = d.database_id
            LEFT JOIN users u ON NEW.user_id = u.user_id
        WHERE
            c.column_id = NEW.column_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_sensitive_column_access
AFTER INSERT ON access_logs
FOR EACH ROW EXECUTE FUNCTION log_sensitive_access();


-- Business Case: Unapproved Sensitive Access Alerts
-- Purpose: Find unapproved access attempts to sensitive columns
-- Why It Matters:
--   - Enables real-time security response
--   - Supports incident investigation

CREATE OR REPLACE FUNCTION get_unapproved_sensitive_access_alerts(since INTERVAL DEFAULT INTERVAL '1 day')
RETURNS TABLE (
    column_name TEXT,
    table_name TEXT,
    user_email TEXT,
    accessed_at TIMESTAMP WITH TIME ZONE,
    client_ip VARCHAR(45),
    days_ago NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sca.column_name,
        sca.table_name,
        sca.user_email,
        sca.accessed_at,
        sca.client_ip,
        EXTRACT(EPOCH FROM (NOW() - sca.accessed_at)) / 86400 AS days_ago
    FROM
        sensitive_column_access_audit sca
    WHERE
        sca.is_unapproved_sensitive_access = TRUE
        AND sca.accessed_at >= NOW() - since
    ORDER BY
        sca.accessed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Last 24 hours
SELECT * FROM get_unapproved_sensitive_access_alerts();

-- Last 7 days
SELECT * FROM get_unapproved_sensitive_access_alerts('7 days');


-- Business Case: Manages masking_profiles data for the application.
-- Table Name: masking_profiles
-- Purpose: Stores detailed information about masking_profiles.
-- Additional Information: This table is central to the masking_profiles module.

CREATE TABLE masking_profiles (
    profile_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    description TEXT NOT NULL,
    masking_function VARCHAR(255) NOT NULL,
    masking_parameters JSONB NOT NULL,
    is_reversible BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_masking_profiles_updated_at
    BEFORE UPDATE ON masking_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
	-- Index on commonly filtered fields
CREATE INDEX idx_masking_profiles_function ON masking_profiles(masking_function);
CREATE INDEX idx_masking_profiles_reversible ON masking_profiles(is_reversible);

-- If you query by creation time
CREATE INDEX idx_masking_profiles_created_at ON masking_profiles(created_at);

CREATE TABLE column_masking_rules (
    rule_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    profile_id UUID NOT NULL REFERENCES masking_profiles(profile_id),
    environment VARCHAR(50) NOT NULL, -- 'dev', 'staging', 'prod'
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Optional: For vector embeddings (if using pgvector)
-- CREATE EXTENSION IF NOT EXISTS "vector";

-- Business Case: Manages masking_profiles data for the application.
-- Table Name: masking_profiles
-- Purpose: Stores detailed information about masking_profiles.
-- Additional Information: This table is central to the masking_profiles module.

CREATE TABLE masking_profiles (
    profile_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    description TEXT NOT NULL,
    masking_function VARCHAR(255) NOT NULL,
    masking_parameters JSONB NOT NULL,
    is_reversible BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages column_masking data for the application.
-- Table Name: column_masking
-- Purpose: Stores detailed information about column_masking.
-- Additional Information: This table is central to the column_masking module.

CREATE TABLE column_masking ( masking_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
							 column_id UUID NOT NULL REFERENCES columns(column_id), 
							 profile_id UUID NOT NULL REFERENCES masking_profiles(profile_id),
							 is_active BOOLEAN DEFAULT TRUE, 
							 created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
							 updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
							 
-- Business Case: Manages data_contracts data for the application.
-- Table Name: data_contracts
-- Purpose: Stores detailed information about data_contracts.
-- Additional Information: This table is central to the data_contracts module.							 
CREATE TABLE data_contracts (
    contract_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    consumer_org VARCHAR(255) NOT NULL,
    consumer_contact VARCHAR(255) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    usage_limits JSONB,
    sla_terms JSONB,
    pricing_model JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages contract_assignments data for the application.
-- Table Name: contract_assignments
-- Purpose: Stores detailed information about contract_assignments.
-- Additional Information: This table is central to the contract_assignments module.
CREATE TABLE contract_assignments (
    assignment_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    contract_id UUID NOT NULL REFERENCES data_contracts(contract_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    last_validated TIMESTAMP WITH TIME ZONE,
    validation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages contract_columns data for the application.
-- Table Name: contract_columns
-- Purpose: Stores detailed information about contract_columns.
-- Additional Information: This table is central to the contract_columns module.
CREATE TABLE contract_columns (
    contract_column_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    contract_id UUID NOT NULL REFERENCES data_contracts(contract_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    transformation_rules JSONB,
    masking_policy VARCHAR(255),
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages contract_usage data for the application.
-- Table Name: contract_usage
-- Purpose: Stores detailed information about contract_usage.
-- Additional Information: This table is central to the contract_usage module.
CREATE TABLE contract_usage (
    usage_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    contract_id UUID NOT NULL REFERENCES data_contracts(contract_id),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    rows_accessed INTEGER,
    queries_executed INTEGER,
    api_calls INTEGER,
    computed_cost NUMERIC,
    details JSONB
);


-- Business Case: Manages data_quality_dimensions data for the application.
-- Table Name: data_quality_dimensions
-- Purpose: Stores detailed information about data_quality_dimensions.
-- Additional Information: This table is central to the data_quality_dimensions module.

CREATE TABLE data_quality_dimensions (
    dimension_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    description TEXT NOT NULL,
    measurement_method TEXT NOT NULL,
    weighting_factor NUMERIC DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages dimension_scores data for the application.
-- Table Name: dimension_scores
-- Purpose: Stores detailed information about dimension_scores.
-- Additional Information: This table is central to the dimension_scores module.
CREATE TABLE dimension_scores (
    score_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    dimension_id UUID NOT NULL REFERENCES data_quality_dimensions(dimension_id),
    score_value NUMERIC NOT NULL,
    measurement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    measurement_window INTEGER NOT NULL,
    is_baseline BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages health_indicators data for the application.
-- Table Name: health_indicators
-- Purpose: Stores detailed information about health_indicators.
-- Additional Information: This table is central to the health_indicators module.
CREATE TABLE health_indicators (
    indicator_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    description TEXT NOT NULL,
    measurement_query TEXT NOT NULL,
    threshold_warning NUMERIC,
    threshold_critical NUMERIC,
    evaluation_frequency INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages process_flows data for the application.
-- Table Name: process_flows
-- Purpose: Stores detailed information about process_flows.
-- Additional Information: This table is central to the process_flows module.

CREATE TABLE process_flows (
    flow_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    flow_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    business_process VARCHAR(255) NOT NULL,
    owning_team VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages flow_steps data for the application.
-- Table Name: flow_steps
-- Purpose: Stores detailed information about flow_steps.
-- Additional Information: This table is central to the flow_steps module.
CREATE TABLE flow_steps (
    step_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    flow_id UUID NOT NULL REFERENCES process_flows(flow_id),
    step_name VARCHAR(255) NOT NULL,
    step_sequence INTEGER NOT NULL,
    description TEXT NOT NULL,
    responsible_team VARCHAR(255),
    tooling_used VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages domain_hierarchy data for the application.
-- Table Name: domain_hierarchy
-- Purpose: Stores detailed information about domain_hierarchy.
-- Additional Information: This table is central to the domain_hierarchy module.

CREATE TABLE domain_hierarchy (
    domain_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    parent_domain_id UUID REFERENCES domain_hierarchy(domain_id),
    domain_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    owning_team VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages term_relationships data for the application.
-- Table Name: term_relationships
-- Purpose: Stores detailed information about term_relationships.
-- Additional Information: This table is central to the term_relationships module.

CREATE TABLE term_relationships (
    relationship_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    source_term_id UUID NOT NULL REFERENCES business_glossary(term_id),
    target_term_id UUID NOT NULL REFERENCES business_glossary(term_id),
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages product_versions data for the application.
-- Table Name: product_versions
-- Purpose: Stores detailed information about product_versions.
-- Additional Information: This table is central to the product_versions module.
CREATE TABLE product_versions (
    version_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    version_number VARCHAR(255) NOT NULL,
    release_notes TEXT,
    is_current BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    deprecated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages product_subscriptions data for the application.
-- Table Name: product_subscriptions
-- Purpose: Stores detailed information about product_subscriptions.
-- Additional Information: This table is central to the product_subscriptions module.
CREATE TABLE product_subscriptions (
    subscription_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    consumer_org VARCHAR(255) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages ml_models data for the application.
-- Table Name: ml_models
-- Purpose: Stores detailed information about ml_models.
-- Additional Information: This table is central to the ml_models module.

CREATE TABLE ml_models (
    model_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(255) NOT NULL,
    version VARCHAR(255) NOT NULL,
    purpose TEXT NOT NULL,
    training_data_range TSRANGE,
    performance_metrics JSONB,
    deployed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages model_applications data for the application.
-- Table Name: model_applications
-- Purpose: Stores detailed information about model_applications.
-- Additional Information: This table is central to the model_applications module.
CREATE TABLE model_applications (
    application_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    model_id UUID NOT NULL REFERENCES ml_models(model_id),
    column_id UUID REFERENCES columns(column_id),
    table_id UUID REFERENCES tables(table_id),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    confidence_score NUMERIC,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages recommendation_models data for the application.
-- Table Name: recommendation_models
-- Purpose: Stores detailed information about recommendation_models.
-- Additional Information: This table is central to the recommendation_models module.
CREATE TABLE recommendation_models (
    model_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_parameters JSONB NOT NULL,
    training_date TIMESTAMP WITH TIME ZONE,
    evaluation_metrics JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_recommendations data for the application.
-- Table Name: column_recommendations
-- Purpose: Stores detailed information about column_recommendations.
-- Additional Information: This table is central to the column_recommendations module.
CREATE TABLE column_recommendations (
    recommendation_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    model_id UUID NOT NULL REFERENCES recommendation_models(model_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    recommended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    relevance_score NUMERIC,
    context JSONB,
    was_consumed BOOLEAN DEFAULT FALSE,
    consumed_at TIMESTAMP WITH TIME ZONE
);


-- Business Case: Manages etl_jobs data for the application.
-- Table Name: etl_jobs
-- Purpose: Stores detailed information about etl_jobs.
-- Additional Information: This table is central to the etl_jobs module.
CREATE TABLE etl_jobs (
    job_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    job_description TEXT,
    source_system VARCHAR(255),
    target_system VARCHAR(255),
    schedule_cron VARCHAR(255),
    error_threshold NUMERIC,
    retry_policy TEXT,
    alerts_enabled BOOLEAN DEFAULT TRUE,
    alert_channels TEXT,
    orchestration_tool VARCHAR(255),
    pipeline_trigger VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_etl_mapping data for the application.
-- Table Name: column_etl_mapping
-- Purpose: Stores detailed information about column_etl_mapping.
-- Additional Information: This table is central to the column_etl_mapping module.
CREATE TABLE column_etl_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES etl_jobs(job_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    source_column_name VARCHAR(255),
    source_column_path TEXT,
    target_column_name VARCHAR(255),
    transformation_logic TEXT,
    test_code TEXT,
    generated_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages workspaces data for the application.
-- Table Name: workspaces
-- Purpose: Stores detailed information about workspaces.
-- Additional Information: This table is central to the workspaces module.

CREATE TABLE workspaces (
    workspace_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    owner_id UUID REFERENCES users(user_id),
    workspace_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages workspace_members data for the application.
-- Table Name: workspace_members
-- Purpose: Stores detailed information about workspace_members.
-- Additional Information: This table is central to the workspace_members module.
CREATE TABLE workspace_members (
    member_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(workspace_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



-- Business Case: Manages privacy_assessments data for the application.
-- Table Name: privacy_assessments
-- Purpose: Stores detailed information about privacy_assessments.
-- Additional Information: This table is central to the privacy_assessments module.
CREATE TABLE privacy_assessments (
    assessment_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    approved_by UUID REFERENCES users(user_id),
    assessment_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    legal_basis VARCHAR(255),
    data_subject_categories TEXT,
    data_categories TEXT,
    retention_period_days INTEGER,
    international_transfer BOOLEAN,
    risk_score NUMERIC,
    mitigation_measures TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages assessment_column_mapping data for the application.
-- Table Name: assessment_column_mapping
-- Purpose: Stores detailed information about assessment_column_mapping.
-- Additional Information: This table is central to the assessment_column_mapping module.
CREATE TABLE assessment_column_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    assessment_id UUID NOT NULL REFERENCES privacy_assessments(assessment_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    processing_purpose TEXT,
    is_identified BOOLEAN,
    is_identifiable BOOLEAN,
    sensitivity_level VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages storage_metrics data for the application.
-- Table Name: storage_metrics
-- Purpose: Stores detailed information about storage_metrics.
-- Additional Information: This table is central to the storage_metrics module.
CREATE TABLE storage_metrics (
    metric_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    table_id UUID REFERENCES tables(table_id),
    database_id UUID REFERENCES databases(database_id),
    metric_date DATE NOT NULL,
    size_bytes BIGINT NOT NULL,
    growth_bytes BIGINT,
    compression_ratio NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages query_metrics data for the application.
-- Table Name: query_metrics
-- Purpose: Stores detailed information about query_metrics.
-- Additional Information: This table is central to the query_metrics module.

CREATE TABLE query_metrics (
    metric_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    table_id UUID REFERENCES tables(table_id),
    query_pattern TEXT NOT NULL,
    execution_count INTEGER NOT NULL,
    avg_duration_ms NUMERIC NOT NULL,
    max_duration_ms NUMERIC NOT NULL,
    last_executed TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);




CREATE OR REPLACE VIEW data_product_compliance_dashboard AS
SELECT
    dp.product_name,
    COUNT(cc.contract_column_id) AS contracted_columns,
    COUNT(cm.masking_id) FILTER (WHERE cm.is_active) AS masked_columns,
    AVG(ds.score_value) AS avg_quality_score,
    MAX(cu.computed_cost) AS monthly_cost
FROM data_products dp
LEFT JOIN contract_columns cc ON dp.product_id = cc.contract_id
LEFT JOIN column_masking cm ON cc.column_id = cm.column_id
LEFT JOIN dimension_scores ds ON cc.column_id = ds.column_id
LEFT JOIN contract_usage cu ON dp.product_id = cu.contract_id
GROUP BY dp.product_id, dp.product_name;



-- Business Case: Top Sensitive Columns by Access Frequency
-- Table Name: top_sensitive_columns_by_access
-- Purpose: Identify high-risk PII or sensitive columns that are frequently accessed
-- Additional Information: Used for audit logging and alert prioritization
CREATE OR REPLACE VIEW top_sensitive_columns_by_access AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    STRING_AGG(st.tag_name, ', ') AS sensitivity_tags,
    COUNT(al.log_id) AS total_accesses,
    COUNT(*) FILTER (WHERE NOT al.was_approved) AS unapproved_attempts,

    MAX(al.accessed_at) AS last_accessed

FROM columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id AND st.tag_category = 'PII'
JOIN access_logs al ON c.column_id = al.column_id

GROUP BY c.column_id, c.column_name, t.table_name, s.schema_name, d.database_name
HAVING COUNT(al.log_id) >= 1

ORDER BY unapproved_attempts DESC, total_accesses DESC;




-- Business Case: Get Column Lineage Summary
-- Function Name: get_column_lineage_summary
-- Purpose: Return upstream and downstream lineage paths for a given column
-- Additional Information: Used in column detail pages and impact analysis tools
CREATE OR REPLACE FUNCTION get_column_lineage_summary(target_column_id UUID)
RETURNS TABLE (
    direction TEXT,
    source_table TEXT,
    source_column TEXT,
    target_table TEXT,
    target_column TEXT,
    pipeline_name TEXT,
    transformation_logic TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Upstream
    SELECT
        'upstream'::TEXT AS direction,
        src_t.table_name,
        src_c.column_name,
        tgt_t.table_name,
        tgt_c.column_name,
        dl.pipeline_name,
        dl.transformation_logic
    FROM data_lineage dl
    JOIN columns src_c ON dl.source_column_id = src_c.column_id
    JOIN tables src_t ON src_c.table_id = src_t.table_id
    JOIN columns tgt_c ON dl.target_column_id = tgt_c.column_id
    JOIN tables tgt_t ON tgt_c.table_id = tgt_t.table_id
    WHERE dl.target_column_id = target_column_id

    UNION ALL

    -- Downstream
    SELECT
        'downstream'::TEXT,
        src_t.table_name,
        src_c.column_name,
        tgt_t.table_name,
        tgt_c.column_name,
        dl.pipeline_name,
        dl.transformation_logic
    FROM data_lineage dl
    JOIN columns src_c ON dl.source_column_id = src_c.column_id
    JOIN tables src_t ON src_c.table_id = src_t.table_id
    JOIN columns tgt_c ON dl.target_column_id = tgt_c.column_id
    JOIN tables tgt_t ON tgt_c.table_id = tgt_t.table_id
    WHERE dl.source_column_id = target_column_id;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Assess Column Risk Score
-- Function Name: assess_column_risk_score
-- Purpose: Calculate a composite risk score based on sensitivity, access, and quality
-- Additional Information: Score ranges from 0 (low) to 100 (critical); used in dashboards
CREATE OR REPLACE FUNCTION assess_column_risk_score(target_column_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    risk_score NUMERIC := 0;
    is_pii BOOLEAN := FALSE;
    access_count BIGINT := 0;
    unapproved_count BIGINT := 0;
    quality_score NUMERIC := 100;
BEGIN
    -- Check if PII
    SELECT TRUE INTO is_pii
    FROM column_tag_mapping ctm
    JOIN search_tags st ON ctm.tag_id = st.tag_id
    WHERE ctm.column_id = target_column_id
      AND st.tag_category = 'PII';

    -- Access volume
    SELECT COUNT(*), COUNT(*) FILTER (WHERE NOT was_approved)
    INTO access_count, unapproved_count
    FROM access_logs WHERE column_id = target_column_id;

    -- Quality baseline
    SELECT COALESCE(AVG(score_value), 100)
    INTO quality_score
    FROM dimension_scores WHERE column_id = target_column_id;

    -- Weighted risk calculation
    risk_score := 0;
    IF is_pii THEN risk_score := risk_score + 40; END IF;
    risk_score := risk_score + LEAST(access_count * 0.1, 30);
    risk_score := risk_score + LEAST(unapproved_count * 2, 20);
    risk_score := risk_score + GREATEST(100 - quality_score, 0);

    RETURN LEAST(risk_score, 100);
END;
$$ LANGUAGE plpgsql;


-- Business Case: Trace Impact of Column Change
-- Function Name: trace_impact_of_column_change
-- Purpose: List all downstream data products, reports, and consumers affected by a column change
-- Additional Information: Critical for change management and deprecation workflows
CREATE OR REPLACE FUNCTION trace_impact_of_column_change(target_column_id UUID)
RETURNS TABLE (
    impact_type TEXT,
    dependent_name TEXT,
    dependency_details TEXT,
    owner_email TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Impacted Data Products
    SELECT
        'data_product'::TEXT,
        dp.product_name,
        'Used in contract'::TEXT,
        u.email
    FROM contract_columns cc
    JOIN data_products dp ON cc.contract_id = dp.product_id
    LEFT JOIN users u ON dp.owner_id = u.user_id
    WHERE cc.column_id = target_column_id

    UNION ALL

    -- Impacted Consumers
    SELECT
        'consumer'::TEXT,
        psc.consumer_org,
        'Subscribed to product using this column'::TEXT,
        NULL
    FROM product_subscriptions psc
    JOIN contract_columns cc ON psc.product_id = cc.contract_id
    WHERE cc.column_id = target_column_id

    UNION ALL

    -- Impacted Discussions
    SELECT
        'discussion'::TEXT,
        dd.title,
        'Open discussion about this column'::TEXT,
        u.email
    FROM data_discussions dd
    LEFT JOIN users u ON dd.started_by = u.user_id
    WHERE dd.column_id = target_column_id AND dd.is_resolved = FALSE;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Generate Data Contract Report
-- Function Name: generate_data_contract_report
-- Purpose: Create a detailed compliance and usage report for a specific data contract
-- Additional Information: Exportable to PDF or email; used in quarterly audits
CREATE OR REPLACE FUNCTION generate_data_contract_report(target_contract_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT INTO result
        json_build_object(
            'contract_id', dc.contract_id,
            'consumer_org', dc.consumer_org,
            'start_date', dc.start_date,
            'end_date', dc.end_date,
            'is_active', dc.is_active,
            'sla_terms', dc.sla_terms,
            'pricing_model', dc.pricing_model,
            'columns_covered', (
                SELECT json_agg(json_build_object(
                    'column_name', c.column_name,
                    'table', t.table_name,
                    'masking_policy', cc.masking_policy
                ))
                FROM contract_columns cc
                JOIN columns c ON cc.column_id = c.column_id
                JOIN tables t ON c.table_id = t.table_id
                WHERE cc.contract_id = target_contract_id
            ),
            'usage_summary', (
                SELECT json_build_object(
                    'total_rows_accessed', SUM(rows_accessed),
                    'query_volume', SUM(queries_executed),
                    'api_calls', SUM(api_calls),
                    'computed_cost', SUM(computed_cost)
                )
                FROM contract_usage
                WHERE contract_id = target_contract_id
            )
        )
    FROM data_contracts dc
    WHERE dc.contract_id = target_contract_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql;



-- Business Case: Get Recent Anomalies
-- Function Name: get_recent_anomalies
-- Purpose: Retrieve all anomalies detected in the last N days
-- Additional Information: Used in daily digest emails and Slack alerts
CREATE OR REPLACE FUNCTION get_recent_anomalies(days INTEGER DEFAULT 7)
RETURNS TABLE (
    anomaly_id UUID,
    detected_at TIMESTAMP WITH TIME ZONE,
    anomaly_score NUMERIC,
    expected_value JSONB,
    actual_value JSONB,
    details JSONB,
    column_id UUID,
    column_name TEXT,
    table_name TEXT,
    schema_name TEXT,
    assigned_to_name TEXT,
    is_open BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.anomaly_id,
        a.detected_at,
        a.anomaly_score,
        a.expected_value,
        a.actual_value,
        a.details,
        ad.column_id,
        c.column_name,
        t.table_name,
        s.schema_name,
        u.user_name AS assigned_to_name,
        (a.resolved_at IS NULL) AS is_open
    FROM anomalies a
    JOIN anomaly_detectors ad ON a.detector_id = ad.detector_id
    JOIN columns c ON ad.column_id = c.column_id
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    LEFT JOIN users u ON a.assigned_to = u.user_id
    WHERE a.detected_at >= NOW() - (days || ' days')::INTERVAL
      AND (a.resolved_at IS NULL OR a.resolved_at > NOW() - (days || ' days')::INTERVAL)
    ORDER BY a.anomaly_score DESC;
END;
$$ LANGUAGE plpgsql;

-- Business Case: Manages anomaly_detectors data for the application.
-- Table Name: anomaly_detectors
-- Purpose: Stores detailed information about anomaly_detectors.
-- Additional Information: This table is central to the anomaly_detectors module.
CREATE TABLE anomaly_detectors (
    detector_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    parameters JSONB NOT NULL,
    training_data_range TSRANGE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages anomalies data for the application.
-- Table Name: anomalies
-- Purpose: Stores detailed information about anomalies.
-- Additional Information: This table is central to the anomalies module.
CREATE TABLE anomalies (
    anomaly_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    detector_id UUID NOT NULL REFERENCES anomaly_detectors(detector_id),
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    anomaly_score NUMERIC NOT NULL,
    expected_value JSONB,
    actual_value JSONB,
    details JSONB,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    assigned_to UUID REFERENCES users(user_id)
);


-- Make sure function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to both tables
CREATE TRIGGER update_anomaly_detectors_updated_at
    BEFORE UPDATE ON anomaly_detectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_anomalies_updated_at
    BEFORE UPDATE ON anomalies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
	
	
	
CREATE OR REPLACE VIEW anomaly_detection_monitor AS
SELECT
    a.anomaly_id,
    a.detected_at,
    a.anomaly_score,
    ad.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    CASE
        WHEN u.user_id IS NOT NULL THEN 'User ' || u.user_id::TEXT
        ELSE 'Unassigned'
    END AS assigned_to_name,
    (a.resolved_at IS NULL) AS is_open
FROM anomalies a
JOIN anomaly_detectors ad ON a.detector_id = ad.detector_id
JOIN columns c ON ad.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN users u ON a.assigned_to = u.user_id;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Business Case: Anomaly Detection Monitor
-- Table Name: anomaly_detection_monitor
-- Purpose: Real-time view of unresolved anomalies across the data estate
-- Additional Information: Integrated into observability dashboards and alert systems
CREATE OR REPLACE VIEW anomaly_detection_monitor AS
SELECT
    a.anomaly_id,
    a.detected_at,
    a.anomaly_score,
    a.expected_value,
    a.actual_value,
    a.details,
    ad.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    u.user_name AS assigned_to_name,
    (a.resolved_at IS NULL) AS is_open
FROM anomalies a
JOIN anomaly_detectors ad ON a.detector_id = ad.detector_id
JOIN columns c ON ad.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN users u ON a.assigned_to = u.user_id
WHERE a.resolved_at IS NULL OR a.resolved_at > NOW() - INTERVAL '7 days'
ORDER BY a.anomaly_score DESC;

-- Business Case: Manages health_scores data for the application.
-- Table Name: health_scores
-- Purpose: Stores detailed information about health_scores.
-- Additional Information: This table is central to the health_scores module.
CREATE TABLE health_scores (
    score_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    table_id UUID REFERENCES tables(table_id),
    indicator_id UUID NOT NULL REFERENCES health_indicators(indicator_id),
    score_value NUMERIC NOT NULL,
    evaluation_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_baseline BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Manages data_discussions data for the application.
-- Table Name: data_discussions
-- Purpose: Stores detailed information about data_discussions.
-- Additional Information: This table is central to the data_discussions module.

CREATE TABLE data_discussions (
    discussion_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID REFERENCES columns(column_id),
    table_id UUID REFERENCES tables(table_id),
    title VARCHAR(255) NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_by UUID REFERENCES users(user_id),
    resolved_by UUID REFERENCES users(user_id)
);

-- Business Case: Manages discussion_comments data for the application.
-- Table Name: discussion_comments
-- Purpose: Stores detailed information about discussion_comments.
-- Additional Information: This table is central to the discussion_comments module.
CREATE TABLE discussion_comments (
    comment_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    discussion_id UUID NOT NULL REFERENCES data_discussions(discussion_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    parent_comment_id UUID REFERENCES discussion_comments(comment_id)
);


-- Business Case: Manages user_deletion_requests data for the application.
-- Table Name: user_deletion_requests
-- Purpose: Stores detailed information about user_deletion_requests.
-- Additional Information: This table is central to the user_deletion_requests module.
CREATE TABLE user_deletion_requests (
    request_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);


-- Business Case: Manages column_test_coverage data for the application.
-- Table Name: column_test_coverage
-- Purpose: Stores detailed information about column_test_coverage.
-- Additional Information: This table is central to the column_test_coverage module.

CREATE TABLE column_test_coverage (
    test_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    test_name VARCHAR(255) NOT NULL,
    test_description TEXT,
    last_run_at TIMESTAMP WITH TIME ZONE,
    test_script TEXT,
    test_framework VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Create trigger function if not already defined
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to column_test_coverage
CREATE TRIGGER update_column_test_coverage_updated_at
    BEFORE UPDATE ON column_test_coverage
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- For joining on column
CREATE INDEX idx_column_test_coverage_column ON column_test_coverage(column_id);

-- For filtering by test framework or recent runs
CREATE INDEX idx_column_test_coverage_last_run ON column_test_coverage(last_run_at DESC);
CREATE INDEX idx_column_test_coverage_framework ON column_test_coverage(test_framework);


-- Business Case: Column Test Coverage Dashboard
-- Table Name: column_test_coverage_dashboard
-- Purpose: Provide visibility into which columns are tested, how recently, and with what framework
-- Additional Information: Used in data quality dashboards and governance reports
CREATE OR REPLACE VIEW column_test_coverage_dashboard AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Test Status
    COUNT(tc.test_id) AS total_tests,
    BOOL_OR(tc.last_run_at IS NOT NULL) AS has_been_tested,
    MAX(tc.last_run_at) AS last_test_run_at,
    STRING_AGG(DISTINCT tc.test_framework, ', ') AS test_frameworks,
    STRING_AGG(DISTINCT tc.test_name, '; ') AS sample_test_names,

    -- Sensitive Flag
    CASE
        WHEN EXISTS (
            SELECT 1 FROM column_tag_mapping ctm
            JOIN search_tags st ON ctm.tag_id = st.tag_id
            WHERE ctm.column_id = c.column_id
              AND st.tag_category = 'PII'
        ) THEN TRUE
        ELSE FALSE
    END AS is_sensitive,

    -- Recency Bucket
    CASE
        WHEN MAX(tc.last_run_at) >= NOW() - INTERVAL '7 days' THEN 'Recent'
        WHEN MAX(tc.last_run_at) >= NOW() - INTERVAL '30 days' THEN 'Stale'
        WHEN MAX(tc.last_run_at) IS NULL THEN 'Untested'
        ELSE 'Very Stale'
    END AS test_status_bucket,

    -- Last Updated
    GREATEST(MAX(tc.updated_at), MAX(tc.created_at)) AS last_updated

FROM columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

LEFT JOIN column_test_coverage tc ON c.column_id = tc.column_id

GROUP BY
    c.column_id, c.column_name, t.table_name, s.schema_name, d.database_name

ORDER BY
    is_sensitive DESC,
    total_tests ASC,
    last_test_run_at ASC NULLS FIRST;
	
	
	
-- Business Case: Untested Sensitive Columns Detector
-- Function Name: get_untested_sensitive_columns
-- Purpose: Identify PII or regulated columns that lack any test coverage
-- Additional Information: Used in daily digest emails and pipeline gates
CREATE OR REPLACE FUNCTION get_untested_sensitive_columns()
RETURNS TABLE (
    column_id UUID,
    column_name TEXT,
    table_name TEXT,
    schema_name TEXT,
    database_name TEXT,
    sensitivity_tags TEXT,
    last_test_run_at TIMESTAMP WITH TIME ZONE,
    days_since_last_test BIGINT,
    test_frameworks TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cov.column_id::UUID,
        cov.column_name::TEXT,
        cov.table_name::TEXT,
        cov.schema_name::TEXT,
        cov.database_name::TEXT,
        STRING_AGG(st.tag_name, ', ')::TEXT AS sensitivity_tags,
        cov.last_test_run_at,
        EXTRACT(EPOCH FROM (NOW() - COALESCE(cov.last_test_run_at, NOW())))::BIGINT / 86400 AS days_since_last_test,
        cov.test_frameworks::TEXT
    FROM column_test_coverage_dashboard cov
    JOIN column_tag_mapping ctm ON cov.column_id = ctm.column_id
    JOIN search_tags st ON ctm.tag_id = st.tag_id
    WHERE
        st.tag_category = 'PII' OR st.tag_name ILIKE '%sensitive%'
        AND (cov.total_tests = 0 OR cov.last_test_run_at IS NULL)
    GROUP BY
        cov.column_id, cov.column_name, cov.table_name, cov.schema_name, cov.database_name,
        cov.last_test_run_at, cov.test_frameworks
    ORDER BY
        days_since_last_test DESC NULLS FIRST;
END;
$$ LANGUAGE plpgsql;


-- Get all untested sensitive columns
SELECT * FROM get_untested_sensitive_columns();

-- Use in alerting scripts
SELECT COUNT(*) FROM get_untested_sensitive_columns(); -- If > 0, trigger alert

-- Business Case: Prevent duplicate test entries for the same column and test name
-- Purpose: Enable safe upserts using ON CONFLICT
-- Additional Information: Required for ON CONFLICT to work
ALTER TABLE column_test_coverage
ADD CONSTRAINT uk_column_test_coverage_unique_test_per_column
UNIQUE (column_id, test_name);

-- Add semantic uniqueness
ALTER TABLE column_test_coverage
ADD CONSTRAINT uk_column_test_coverage UNIQUE (column_id, test_name);

-- Insert test for the 'email' column in 'users' table
INSERT INTO column_test_coverage (column_id, test_name, last_run_at, test_script)
SELECT
    c.column_id,
    'not_null_check',
    NOW(),
    'IS NOT NULL'
FROM columns c
JOIN tables t ON c.table_id = t.table_id
WHERE t.table_name = 'users'
  AND c.column_name = 'email';


-- Business Case: Manages graphql_schema data for the application.
-- Table Name: graphql_schema
-- Purpose: Stores detailed information about graphql_schema.
-- Additional Information: This table is central to the graphql_schema module.

CREATE TABLE graphql_schema (
    schema_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    schema_name VARCHAR(255) NOT NULL,
    schema_definition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE TRIGGER update_graphql_schema_updated_at
    BEFORE UPDATE ON graphql_schema
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Business Case: Manages graphql_field_mapping data for the application.
-- Table Name: graphql_field_mapping
-- Purpose: Stores detailed information about graphql_field_mapping.
-- Additional Information: This table is central to the graphql_field_mapping module.

CREATE TABLE graphql_field_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    schema_id UUID NOT NULL REFERENCES graphql_schema(schema_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    field_name VARCHAR(255) NOT NULL,
    field_type VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    is_deprecated BOOLEAN DEFAULT FALSE,
    deprecation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages graphql_field_mapping data for the application.
-- Table Name: graphql_field_mapping
-- Purpose: Stores detailed information about graphql_field_mapping.
-- Additional Information: This table is central to the graphql_field_mapping module.

CREATE TABLE graphql_field_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    schema_id UUID NOT NULL REFERENCES graphql_schema(schema_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    field_name VARCHAR(255) NOT NULL,
    field_type VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    is_deprecated BOOLEAN DEFAULT FALSE,
    deprecation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_description_generation data for the application.
-- Table Name: column_description_generation
-- Purpose: Stores detailed information about column_description_generation.
-- Additional Information: This table is central to the column_description_generation module.

CREATE TABLE column_description_generation (
    generation_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    reviewed_by UUID REFERENCES users(user_id),
    generated_description TEXT,
    generation_model VARCHAR(255),
    generation_parameters JSONB,
    confidence_score NUMERIC,
    human_reviewed BOOLEAN DEFAULT FALSE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE TRIGGER update_column_description_generation_updated_at
    BEFORE UPDATE ON column_description_generation
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- graphql_schema
CREATE INDEX idx_graphql_schema_active ON graphql_schema(is_active);

-- graphql_field_mapping
CREATE INDEX idx_graphql_field_mapping_schema ON graphql_field_mapping(schema_id);
CREATE INDEX idx_graphql_field_mapping_column ON graphql_field_mapping(column_id);
CREATE INDEX idx_graphql_field_mapping_deprecated ON graphql_field_mapping(is_deprecated);

-- column_description_generation
CREATE INDEX idx_col_desc_gen_column ON column_description_generation(column_id);
CREATE INDEX idx_col_desc_gen_model ON column_description_generation(generation_model);
CREATE INDEX idx_col_desc_gen_confidence ON column_description_generation(confidence_score);
CREATE INDEX idx_col_desc_gen_reviewed ON column_description_generation(human_reviewed);


CREATE OR REPLACE VIEW column_ai_description_dashboard AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    cdg.generated_description,
    cdg.confidence_score,
    cdg.human_reviewed,
    u.user_id::TEXT AS reviewed_by_user,
    cdg.created_at,
    cdg.updated_at
FROM columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_description_generation cdg ON c.column_id = cdg.column_id
LEFT JOIN users u ON cdg.reviewed_by = u.user_id;


-- Business Case: Get Unreviewed AI Descriptions
-- Function Name: get_unreviewed_ai_descriptions
-- Purpose: Find AI-generated column descriptions that haven't been reviewed
-- Additional Information: Used in daily digest emails and steward dashboards
CREATE OR REPLACE FUNCTION get_unreviewed_ai_descriptions()
RETURNS SETOF column_ai_description_dashboard AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM column_ai_description_dashboard
    WHERE human_reviewed = FALSE AND generated_description IS NOT NULL
    ORDER BY confidence_score DESC;
END;
$$ LANGUAGE plpgsql;


-- Business Case: Manages anomaly_detection_rules data for the application.
-- Table Name: anomaly_detection_rules
-- Purpose: Stores detailed information about anomaly_detection_rules.
-- Additional Information: This table is central to the anomaly_detection_rules module.

CREATE TABLE anomaly_detection_rules (
    rule_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    rule_name VARCHAR(255) NOT NULL,
    rule_parameters JSONB NOT NULL,
    sensitivity NUMERIC DEFAULT 0.8,
    is_active BOOLEAN DEFAULT TRUE,
    last_executed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Create trigger function if not already defined
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to anomaly_detection_rules
CREATE TRIGGER update_anomaly_detection_rules_updated_at
    BEFORE UPDATE ON anomaly_detection_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
-- For filtering by column and active rules
CREATE INDEX idx_anomaly_detection_rules_column ON anomaly_detection_rules(column_id);
CREATE INDEX idx_anomaly_detection_rules_active ON anomaly_detection_rules(is_active);
CREATE INDEX idx_anomaly_detection_rules_last_executed ON anomaly_detection_rules(last_executed DESC);

-- Business Case: Active Anomaly Rules Dashboard
-- Table Name: active_anomaly_rules_dashboard
-- Purpose: Show all active anomaly detection rules with context about their target columns and recent execution status
-- Additional Information: Used in data observability dashboards and monitoring tools

CREATE OR REPLACE VIEW active_anomaly_rules_dashboard AS
SELECT
    adr.rule_id,
    adr.rule_name,
    adr.sensitivity,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    adr.rule_parameters,
    adr.is_active,
    adr.last_executed,
    GREATEST(adr.updated_at, adr.created_at) AS last_updated,
    
    -- Time since last executed (in hours)
    EXTRACT(EPOCH FROM (NOW() - COALESCE(adr.last_executed, '1970-01-01'::TIMESTAMP WITH TIME ZONE))) / 3600 AS hours_since_last_execution,

    -- Execution status summary
    CASE
        WHEN adr.last_executed IS NULL THEN 'Never Run'
        WHEN adr.last_executed < NOW() - INTERVAL '24 hours' THEN 'Stale'
        ELSE 'Recent'
    END AS execution_status,

    -- Risk level based on sensitivity and column importance
    CASE
        WHEN adr.sensitivity > 0.8 THEN 'High'
        WHEN adr.sensitivity > 0.5 THEN 'Medium'
        ELSE 'Low'
    END AS rule_criticality

FROM anomaly_detection_rules adr
JOIN columns c ON adr.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

WHERE
    adr.is_active = TRUE  -- Only show active rules

ORDER BY
    adr.sensitivity DESC,
    adr.last_executed ASC NULLS FIRST,
    t.table_name,
    c.column_name;


SELECT * FROM active_anomaly_rules_dashboard
WHERE execution_status = 'Stale';


SELECT * FROM active_anomaly_rules_dashboard
WHERE rule_criticality = 'High';


SELECT table_name, COUNT(*) AS rule_count
FROM active_anomaly_rules_dashboard
GROUP BY table_name
ORDER BY rule_count DESC;


-- Business Case: Manages data_product_usage data for the application.
-- Table Name: data_product_usage
-- Purpose: Stores detailed information about data_product_usage.
-- Additional Information: This table is central to the data_product_usage module.

CREATE TABLE data_product_usage (
    usage_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    access_method VARCHAR(255),
    query_parameters TEXT,
    rows_accessed INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Most common query patterns
CREATE INDEX idx_data_product_usage_product ON data_product_usage(product_id);
CREATE INDEX idx_data_product_usage_user ON data_product_usage(user_id);
CREATE INDEX idx_data_product_usage_accessed ON data_product_usage(accessed_at DESC);
CREATE INDEX idx_data_product_usage_method ON data_product_usage(access_method);


-- Business Case: Data Product Usage Dashboard
-- Table Name: data_product_usage_dashboard
-- Purpose: Show top data products by access frequency, user count, and rows accessed
-- Additional Information: Used in product analytics, cost attribution, and adoption reporting

CREATE OR REPLACE VIEW data_product_usage_dashboard AS
SELECT
    dp.product_id,
    dp.product_name,
    dp.domain,
    dp.owner_id,
    dp.steward_id,
    dp.is_published,
    dp.published_at,

    -- Access Volume
    COUNT(usage.usage_id) AS total_access_events,
    COUNT(DISTINCT usage.user_id) AS unique_users,
    SUM(usage.rows_accessed) AS total_rows_accessed,
    ROUND(AVG(usage.rows_accessed), 2) AS avg_rows_per_access,

    -- Temporal Insights
    MIN(usage.accessed_at) AS first_accessed,
    MAX(usage.accessed_at) AS last_accessed,
    EXTRACT(EPOCH FROM (MAX(usage.accessed_at) - MIN(usage.accessed_at))) / 86400 AS days_active,

    -- Access Patterns
    STRING_AGG(DISTINCT usage.access_method, ', ') AS access_methods_used,

    -- Engagement Score (weighted)
    (
        LOG(COUNT(*)) +  -- Log scale for fairness
        LOG(1 + COUNT(DISTINCT usage.user_id)) +
        LOG(1 + COALESCE(SUM(usage.rows_accessed), 0) / 1000.0)
    ) AS engagement_score

FROM data_products dp
JOIN data_product_usage usage ON dp.product_id = usage.product_id

GROUP BY
    dp.product_id,
    dp.product_name,
    dp.domain,
    dp.owner_id,
    dp.steward_id,
    dp.is_published,
    dp.published_at

HAVING
    COUNT(usage.usage_id) > 0  -- Only show products with usage

ORDER BY
    engagement_score DESC,
    total_access_events DESC;
	
	
	SELECT product_name, total_access_events, unique_users
FROM data_product_usage_dashboard
ORDER BY total_access_events DESC
LIMIT 10;


SELECT product_name, last_accessed
FROM data_product_usage_dashboard
WHERE last_accessed < NOW() - INTERVAL '30 days';


SELECT product_name, total_rows_accessed
FROM data_product_usage_dashboard
ORDER BY total_rows_accessed DESC;


-- Business Case: Monthly Data Product Usage Summary
-- Function Name: get_monthly_usage_summary
-- Purpose: Aggregate monthly access, row volume, and user engagement for a given data product
-- Additional Information: Used in product dashboards and executive reports

CREATE OR REPLACE FUNCTION get_monthly_usage_summary(target_product_id UUID)
RETURNS TABLE (
    month DATE,
    total_accesses BIGINT,
    unique_users BIGINT,
    total_rows_accessed BIGINT,
    avg_rows_per_access NUMERIC,
    days_active_in_month BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE_TRUNC('month', usage.accessed_at)::DATE AS month,
        COUNT(*) AS total_accesses,
        COUNT(DISTINCT usage.user_id) AS unique_users,
        COALESCE(SUM(usage.rows_accessed), 0) AS total_rows_accessed,
        ROUND(AVG(usage.rows_accessed::NUMERIC), 2) AS avg_rows_per_access,
        COUNT(DISTINCT DATE(usage.accessed_at)) AS days_active_in_month
    FROM data_product_usage usage
    WHERE usage.product_id = target_product_id
      AND usage.accessed_at >= DATE_TRUNC('month', NOW()) - INTERVAL '12 months'
    GROUP BY month
    ORDER BY month DESC;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_monthly_usage_summary('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');





-- Add foreign keys to link data product to actual tables/columns
ALTER TABLE data_products 
ADD COLUMN IF NOT EXISTS root_table_id UUID REFERENCES tables(table_id),
ADD COLUMN IF NOT EXISTS database_id UUID REFERENCES databases(database_id);


-- Business Case: Manages cost_models data for the application.
-- Table Name: cost_models
-- Purpose: Stores detailed information about cost_models.
-- Additional Information: This table is central to the cost_models module.
CREATE TABLE cost_models (
    model_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    cost_per_gb_storage NUMERIC,
    cost_per_million_rows_scanned NUMERIC,
    cost_per_query NUMERIC,
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages cost_attribution data for the application.
-- Table Name: cost_attribution
-- Purpose: Stores detailed information about cost_attribution.
-- Additional Information: This table is central to the cost_attribution module.
CREATE TABLE cost_attribution (
    attribution_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    model_id UUID NOT NULL REFERENCES cost_models(model_id),
    storage_bytes INTEGER,
    monthly_rows_scanned INTEGER,
    monthly_query_count INTEGER,
    calculated_cost NUMERIC,
    calculation_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cost_attribution_column ON cost_attribution(column_id);
CREATE INDEX idx_cost_attribution_model ON cost_attribution(model_id);
CREATE INDEX idx_cost_attribution_date ON cost_attribution(calculation_date DESC);


-- Business Case: Manages data_product_usage data for the application.
-- Table Name: data_product_usage
-- Purpose: Stores detailed information about data_product_usage.
-- Additional Information: This table is central to the data_product_usage module.
CREATE TABLE data_product_usage (
    usage_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES data_products(product_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    access_method VARCHAR(255),
    query_parameters TEXT,
    rows_accessed INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Business Case: Manages column_embeddings data for the application.
-- Table Name: column_embeddings
-- Purpose: Stores detailed information about column_embeddings.
-- Additional Information: This table is central to the column_embeddings module.
CREATE TABLE column_embeddings (
    embedding_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    embedding_vector VECTOR(384),
    model_version VARCHAR(255) NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business Case: Cost-per-Product Report
-- Table Name: data_product_cost_report
-- Purpose: Show estimated storage, compute, and total cost per data product
-- Additional Information: Integrated with finance systems and FinOps dashboards
CREATE OR REPLACE VIEW data_product_cost_report AS
SELECT
    dp.product_id,
    dp.product_name,
    dp.domain,
    dp.owner_id,
    dp.steward_id,

    -- Storage Cost
    SUM(sm.size_bytes) AS total_storage_bytes,
    ROUND(SUM(sm.size_bytes) / 1024.0^3, 2) AS storage_gb,
    cm.cost_per_gb_storage,
    ROUND((SUM(sm.size_bytes) / 1024.0^3) * cm.cost_per_gb_storage, 2) AS storage_cost_usd,

    -- Query Cost (based on rows scanned)
    SUM(ca.monthly_rows_scanned) AS total_rows_scanned,
    cm.cost_per_million_rows_scanned,
    ROUND(
        (SUM(ca.monthly_rows_scanned) / 1e6) * cm.cost_per_million_rows_scanned,
        2
    ) AS query_cost_usd,

    -- Total Cost
    ROUND(
        ((SUM(sm.size_bytes) / 1024.0^3) * cm.cost_per_gb_storage) +
        ((SUM(ca.monthly_rows_scanned) / 1e6) * cm.cost_per_million_rows_scanned),
        2
    ) AS total_cost_usd,

    -- Engagement
    MAX(COALESCE(dpu.total_access_events, 0)) AS monthly_access_count,
    MAX(COALESCE(dpu.unique_users, 0)) AS monthly_unique_users

FROM data_products dp
JOIN contract_columns cc ON dp.product_id = cc.contract_id
JOIN columns c ON cc.column_id = c.column_id

LEFT JOIN storage_metrics sm ON c.column_id = sm.column_id
    AND sm.metric_date >= CURRENT_DATE - INTERVAL '30 days'

LEFT JOIN cost_attribution ca ON c.column_id = ca.column_id
LEFT JOIN cost_models cm ON ca.model_id = cm.model_id AND cm.is_active = TRUE

LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS total_access_events,
        COUNT(DISTINCT user_id) AS unique_users
    FROM data_product_usage
    WHERE product_id = dp.product_id
      AND accessed_at >= CURRENT_DATE - INTERVAL '30 days'
) dpu ON TRUE

GROUP BY
    dp.product_id, dp.product_name, dp.domain, dp.owner_id, dp.steward_id,
    cm.cost_per_gb_storage, cm.cost_per_million_rows_scanned

HAVING
    SUM(sm.size_bytes) > 0 OR COALESCE(SUM(ca.monthly_rows_scanned), 0) > 0

ORDER BY
    total_cost_usd DESC NULLS LAST;
	
--display
SELECT * FROM data_product_cost_report LIMIT 10;


-- Business Case: High-Cost / Low-Use Products Alert
-- Table Name: daily_digest_high_cost_low_use_products
-- Purpose: Identify data products with high storage/query costs but low user engagement
-- Additional Information: Source for daily digest emails, Slack alerts, and steward dashboards
CREATE OR REPLACE VIEW daily_digest_high_cost_low_use_products AS
SELECT
    dp.product_id,
    dp.product_name,
    dp.domain,
    dp.owner_id,
    dp.steward_id,

    -- Cost Metrics
    cpr.total_cost_usd,
    cpr.storage_cost_usd,
    cpr.query_cost_usd,
    cpr.storage_gb,
    cpr.total_rows_scanned,

    -- Usage & Engagement
    cpr.monthly_access_count,
    cpr.monthly_unique_users,
    ROUND(
        CASE
            WHEN cpr.total_cost_usd > 0
            THEN (cpr.monthly_access_count::NUMERIC / cpr.total_cost_usd)
            ELSE 0
        END,
        2
    ) AS accesses_per_dollar,

    -- Risk Classification
    CASE
        WHEN cpr.monthly_access_count = 0 AND cpr.total_cost_usd >= 100
            THEN 'High Risk: Unused & Expensive'
        WHEN cpr.monthly_access_count < 5 AND cpr.total_cost_usd >= 50
            THEN 'Medium Risk: Underused & Costly'
        WHEN cpr.total_cost_usd >= 200
            THEN 'High Cost: Monitor Usage'
        ELSE 'Watchlist'
    END AS risk_category

FROM data_products dp
JOIN data_product_cost_report cpr ON dp.product_id = cpr.product_id

WHERE
    -- Only show costly products
    cpr.total_cost_usd >= 50

    -- And low engagement
    AND (
        cpr.monthly_access_count = 0
        OR cpr.monthly_access_count < 10
    )

ORDER BY
    cpr.total_cost_usd DESC,
    cpr.monthly_access_count ASC;
	
	

SELECT * FROM daily_digest_high_cost_low_use_products;

SELECT product_name, total_cost_usd
FROM daily_digest_high_cost_low_use_products
WHERE monthly_access_count = 0;

-- Business Case: Privacy Assessment Summary Dashboard
-- Table Name: privacy_assessment_summary_dashboard
-- Purpose: Show all privacy assessments with PII coverage and expiration status
-- Additional Information: Used in compliance dashboards and audit reports
CREATE OR REPLACE VIEW privacy_assessment_summary_dashboard AS
SELECT
    pa.assessment_id,
    pa.assessment_name,
    pa.description,
    pa.legal_basis,
    pa.data_subject_categories,
    pa.data_categories,
    pa.retention_period_days,
    pa.international_transfer,
    pa.risk_score,
    pa.mitigation_measures,
    pa.approved_at,
    pa.valid_until,
    u.user_id::TEXT AS approved_by_user,

    -- Coverage
    COUNT(acm.mapping_id) AS columns_mapped,
    STRING_AGG(DISTINCT st.tag_name, ', ') FILTER (WHERE st.tag_name IS NOT NULL) AS pii_tags_covered,

    -- Expiration Status
    CASE
        WHEN pa.valid_until IS NULL THEN 'No Expiry'
        WHEN pa.valid_until < NOW() THEN 'Expired'
        WHEN pa.valid_until < NOW() + INTERVAL '30 days' THEN 'Expiring Soon'
        ELSE 'Valid'
    END AS validity_status,

    -- Days until expiry (negative if expired)
    EXTRACT(EPOCH FROM (pa.valid_until - NOW())) / 86400 AS days_until_expiry,

    -- Last Updated
    GREATEST(pa.updated_at, pa.created_at) AS last_updated

FROM privacy_assessments pa
LEFT JOIN users u ON pa.approved_by = u.user_id
LEFT JOIN assessment_column_mapping acm ON pa.assessment_id = acm.assessment_id
LEFT JOIN columns c ON acm.column_id = c.column_id
LEFT JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
LEFT JOIN search_tags st ON ctm.tag_id = st.tag_id AND st.tag_category = 'PII'

GROUP BY
    pa.assessment_id,
    pa.assessment_name,
    pa.description,
    pa.legal_basis,
    pa.data_subject_categories,
    pa.data_categories,
    pa.retention_period_days,
    pa.international_transfer,
    pa.risk_score,
    pa.mitigation_measures,
    pa.approved_at,
    pa.valid_until,
    u.user_id

ORDER BY
    pa.valid_until ASC NULLS LAST,
    pa.risk_score DESC NULLS LAST;
	
	
-- Business Case: Get Expired or Expiring Assessments
-- Function Name: get_expired_or_expiring_assessments
-- Purpose: Return all privacy assessments that are expired or will expire within N days
-- Additional Information: Used in daily digest emails and compliance alerts
CREATE OR REPLACE FUNCTION get_expired_or_expiring_assessments(days_ahead INT DEFAULT 30)
RETURNS SETOF privacy_assessment_summary_dashboard AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM privacy_assessment_summary_dashboard
    WHERE
        validity_status = 'Expired'
        OR (validity_status = 'Expiring Soon' AND days_until_expiry <= days_ahead)
    ORDER BY
        validity_status,
        valid_until ASC;
END;
$$ LANGUAGE plpgsql;


-- Get all expired or expiring within 30 days
SELECT * FROM get_expired_or_expiring_assessments(30);

-- Get those expiring within 7 days
SELECT * FROM get_expired_or_expiring_assessments(7);

-- Business Case: Unassessed PII Columns Report
-- Purpose: Find PII-tagged columns that are not mapped to any privacy assessment
-- Additional Information: Critical for GDPR/CCPA compliance gap analysis
CREATE OR REPLACE VIEW pii_columns_without_assessment AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    st.tag_name AS pii_type,
    STRING_AGG(DISTINCT bg.term_name, ', ') FILTER (WHERE bg.term_name IS NOT NULL) AS related_terms

FROM columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id
LEFT JOIN business_glossary bg ON c.column_name ILIKE ('%' || bg.term_name || '%')

-- Only PII tags
WHERE st.tag_category = 'PII' OR st.tag_name ILIKE '%sensitive%'

-- Not in any assessment
AND NOT EXISTS (
    SELECT 1 FROM assessment_column_mapping acm
    WHERE acm.column_id = c.column_id
)

GROUP BY
    c.column_id, c.column_name, t.table_name, s.schema_name, d.database_name, st.tag_name
ORDER BY
    st.tag_name, t.table_name, c.column_name;
	
	
-- Business Case: Privacy Assessments Change History
-- Table Name: privacy_assessments_history
-- Purpose: Log all changes to privacy assessments for audit and compliance
-- Additional Information: Supports versioning, forensics, and regulatory reporting

CREATE TABLE privacy_assessments_history (
    history_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    assessment_id UUID NOT NULL,
    approved_by UUID,
    assessment_name VARCHAR(255),
    description TEXT,
    legal_basis VARCHAR(255),
    data_subject_categories TEXT,
    data_categories TEXT,
    retention_period_days INTEGER,
    international_transfer BOOLEAN,
    risk_score NUMERIC,
    mitigation_measures TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    action_type VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT DEFAULT session_user
);

-- Business Case: Log Changes to Privacy Assessments
-- Function Name: log_privacy_assessment_changes
-- Purpose: Automatically record insert/update/delete operations on privacy_assessments
-- Additional Information: Used by trigger to populate privacy_assessments_history
CREATE OR REPLACE FUNCTION log_privacy_assessment_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO privacy_assessments_history (
            assessment_id,
            approved_by,
            assessment_name,
            description,
            legal_basis,
            data_subject_categories,
            data_categories,
            retention_period_days,
            international_transfer,
            risk_score,
            mitigation_measures,
            approved_at,
            valid_until,
            action_type
        )
        VALUES (
            NEW.assessment_id,
            NEW.approved_by,
            NEW.assessment_name,
            NEW.description,
            NEW.legal_basis,
            NEW.data_subject_categories,
            NEW.data_categories,
            NEW.retention_period_days,
            NEW.international_transfer,
            NEW.risk_score,
            NEW.mitigation_measures,
            NEW.approved_at,
            NEW.valid_until,
            'INSERT'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO privacy_assessments_history (
            assessment_id,
            approved_by,
            assessment_name,
            description,
            legal_basis,
            data_subject_categories,
            data_categories,
            retention_period_days,
            international_transfer,
            risk_score,
            mitigation_measures,
            approved_at,
            valid_until,
            action_type
        )
        VALUES (
            OLD.assessment_id,
            OLD.approved_by,
            OLD.assessment_name,
            OLD.description,
            OLD.legal_basis,
            OLD.data_subject_categories,
            OLD.data_categories,
            OLD.retention_period_days,
            OLD.international_transfer,
            OLD.risk_score,
            OLD.mitigation_measures,
            OLD.approved_at,
            OLD.valid_until,
            'UPDATE'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO privacy_assessments_history (
            assessment_id,
            approved_by,
            assessment_name,
            description,
            legal_basis,
            data_subject_categories,
            data_categories,
            retention_period_days,
            international_transfer,
            risk_score,
            mitigation_measures,
            approved_at,
            valid_until,
            action_type
        )
        VALUES (
            OLD.assessment_id,
            OLD.approved_by,
            OLD.assessment_name,
            OLD.description,
            OLD.legal_basis,
            OLD.data_subject_categories,
            OLD.data_categories,
            OLD.retention_period_days,
            OLD.international_transfer,
            OLD.risk_score,
            OLD.mitigation_measures,
            OLD.approved_at,
            OLD.valid_until,
            'DELETE'
        );
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Apply audit trigger to privacy_assessments
CREATE TRIGGER trigger_privacy_assessments_audit
AFTER INSERT OR UPDATE OR DELETE ON privacy_assessments
FOR EACH ROW EXECUTE FUNCTION log_privacy_assessment_changes();

ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;

-- Add new rule_type column temporarily allowing NULLs
ALTER TABLE severity_rules ADD COLUMN IF NOT EXISTS rule_type VARCHAR(50);

-- Backfill rule_type based on rule_name patterns
UPDATE severity_rules
SET rule_type = 
    CASE 
        WHEN rule_name ILIKE '%error_rate%' OR rule_name ILIKE '%rate%' THEN 'ERROR_RATE'
        WHEN rule_name ILIKE '%failed%' OR rule_name ILIKE '%missing%' OR rule_name ILIKE '%invalid%' THEN 'RECORDS_FAILED'
        ELSE 'CUSTOM'
    END
WHERE rule_type IS NULL;

-- Make rule_type required now that it's populated
ALTER TABLE severity_rules ALTER COLUMN rule_type SET NOT NULL;

-- Optional: Create index for performance
CREATE INDEX IF NOT EXISTS idx_severity_rules_rule_type ON severity_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_severity_rules_active ON severity_rules(is_active);


-- Ensure update_updated_at_column() function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger if not already present
DROP TRIGGER IF EXISTS update_severity_rules_updated_at ON severity_rules;
CREATE TRIGGER update_severity_rules_updated_at
    BEFORE UPDATE ON severity_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Add total_rows_checked to support error rate-based severity rules
-- Add missing columns if they don't exist
ALTER TABLE data_quality_results 
ADD COLUMN IF NOT EXISTS total_rows_checked BIGINT;

ALTER TABLE data_quality_results 
ADD COLUMN IF NOT EXISTS severity TEXT; -- Optional: if used directly

-- Optional: Backfill if possible (if you can infer from logs or jobs)
-- UPDATE data_quality_results SET total_rows_checked = ... WHERE total_rows_checked IS NULL;





-- Business Case: Data Quality Trend with Severity
-- Purpose: Show historical failure trends grouped by date, column, table, and severity
-- Why It Matters:
-- - Reveals recurring or worsening quality issues
-- - Enables time-series analysis for root cause investigation
-- - Supports compliance audits and executive reporting
CREATE OR REPLACE VIEW data_quality_trend_with_severity AS
SELECT
    DATE(r.execution_timestamp) AS failure_date,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name,
    COUNT(r.result_id) AS total_failures,
    SUM(r.records_failed) AS total_records_failed,
    MAX(COALESCE(sr.severity_level, 'Unknown')) AS highest_severity,
    AVG(
        CASE 
            WHEN r.total_rows_checked > 0 
            THEN (r.records_failed::NUMERIC / r.total_rows_checked) * 100 
            ELSE NULL 
        END
    ) AS avg_error_rate_percent
FROM data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN severity_rules sr ON (
    sr.is_active = TRUE
    AND (
        (sr.rule_type = 'RECORDS_FAILED' AND r.records_failed > 0
            AND (
                (sr.threshold_type = 'GREATER_THAN' AND r.records_failed > sr.threshold_value_min)
                OR (sr.threshold_type = 'LESS_THAN' AND r.records_failed < sr.threshold_value_min)
                OR (sr.threshold_type = 'BETWEEN' 
                    AND r.records_failed BETWEEN sr.threshold_value_min AND sr.threshold_value_max)
            )
        )
        OR
        (sr.rule_type = 'ERROR_RATE'
            AND r.total_rows_checked IS NOT NULL AND r.total_rows_checked > 0
            AND (r.records_failed::NUMERIC / r.total_rows_checked) * 100 BETWEEN
                COALESCE(sr.threshold_value_min, 0) AND COALESCE(sr.threshold_value_max, 100)
        )
    )
)
WHERE r.records_failed > 0
GROUP BY
    DATE(r.execution_timestamp),
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    q.rule_name
ORDER BY failure_date DESC, total_records_failed DESC;


-- Test base view
SELECT * FROM data_quality_failures_with_severity LIMIT 5;

-- Test derived trend view
SELECT * FROM data_quality_trend_with_severity LIMIT 5;



-- Business Case: Usage Policies
-- Table Name: usage_policies
-- Purpose: Defines rules governing how sensitive columns may be accessed or used (e.g., export, download, masking)
-- Why It Matters:
-- - Enables fine-grained control over data access beyond basic permissions
-- - Supports dynamic policy enforcement (block/warn/log) based on context
-- - Critical for compliance, auditing, and data governance
CREATE TABLE usage_policies (
    policy_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    allowed_roles TEXT[], -- e.g., '{analyst,admin}'
    allowed_operations TEXT[] DEFAULT ARRAY['SELECT']::TEXT[], -- e.g., SELECT, EXPORT, DOWNLOAD
    required_context JSONB, -- e.g., {"require_mfa": true, "allowed_networks": ["10.0.0.0/8"]}
    enforcement_action VARCHAR(20) NOT NULL DEFAULT 'LOG' 
        CHECK (enforcement_action IN ('LOG', 'WARN', 'BLOCK')),
    is_active BOOLEAN DEFAULT TRUE,
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_usage_policies_column_id ON usage_policies(column_id);
CREATE INDEX IF NOT EXISTS idx_usage_policies_is_active ON usage_policies(is_active);
CREATE INDEX IF NOT EXISTS idx_usage_policies_enforcement_action ON usage_policies(enforcement_action);

-- Trigger to auto-update updated_at
CREATE TRIGGER update_usage_policies_updated_at
    BEFORE UPDATE ON usage_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
-- Business Case: Policy Violations
-- Table Name: policy_violations
-- Purpose: Stores detailed information about violations of usage policies (e.g., unauthorized exports, blocked access)
-- Why It Matters:
-- - Central to audit trails and incident response
-- - Enables review workflow (PENDING → REVIEWED → RESOLVED)
-- - Integrates with alerting and compliance reporting
CREATE TABLE policy_violations (
    violation_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    policy_id UUID NOT NULL REFERENCES usage_policies(policy_id),
    column_id UUID NOT NULL REFERENCES columns(column_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    operation VARCHAR(255) NOT NULL, -- e.g., 'EXPORT_TO_CSV', 'FULL_TABLE_SELECT'
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    was_blocked BOOLEAN NOT NULL DEFAULT TRUE,
    violation_details JSONB, -- Context: IP, query snippet, role, etc.
    reviewed_by UUID REFERENCES users(user_id),
    review_status VARCHAR(50) DEFAULT 'PENDING' 
        CHECK (review_status IN ('PENDING', 'REVIEWED', 'RESOLVED', 'ESCALATED')),
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_policy_violations_policy_id ON policy_violations(policy_id);
CREATE INDEX IF NOT EXISTS idx_policy_violations_column_id ON policy_violations(column_id);
CREATE INDEX IF NOT EXISTS idx_policy_violations_user_id ON policy_violations(user_id);
CREATE INDEX IF NOT EXISTS idx_policy_violations_reviewed_by ON policy_violations(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_policy_violations_attempted_at ON policy_violations(attempted_at);
CREATE INDEX IF NOT EXISTS idx_policy_violations_review_status ON policy_violations(review_status);

-- Trigger
CREATE TRIGGER update_policy_violations_updated_at
    BEFORE UPDATE ON policy_violations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	

SELECT
    a.anomaly_id,
    a.detected_at,
    c.column_name,
    t.table_name,
    s.schema_name,
    COALESCE(u.first_name || ' ' || u.last_name, u.email, 'Unknown') AS assigned_to_name
FROM anomalies a
JOIN anomaly_detectors ad ON a.detector_id = ad.detector_id
JOIN columns c ON ad.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
LEFT JOIN users u ON a.assigned_to = u.user_id;


-- create a view for user display names 
CREATE OR REPLACE VIEW user_display_names AS
SELECT
    user_id,
    COALESCE(first_name || ' ' || last_name, email, 'Unknown') AS user_name,
    first_name,
    last_name,
    email,
    is_active,
    last_login
FROM users;
	
-- Business Case: Recent Policy Violations Dashboard
-- Purpose: Show recent policy violations with full context for audit and review
-- Why It Matters:
-- - Enables quick identification of unauthorized or risky access attempts
-- - Supports incident response and compliance reporting
-- - Integrates with alerting and governance workflows
CREATE OR REPLACE VIEW recent_policy_violations AS
SELECT
    pv.violation_id,
    pv.operation,
    pv.attempted_at,
    COALESCE(u.first_name || ' ' || u.last_name, u.email, 'Unknown') AS user_name,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    up.policy_name,
    pv.was_blocked,
    pv.review_status,
    COALESCE(reviewer.first_name || ' ' || reviewer.last_name, reviewer.email, 'Not Reviewed') AS reviewed_by_name,
    pv.review_notes
FROM policy_violations pv
JOIN users u ON pv.user_id = u.user_id
JOIN usage_policies up ON pv.policy_id = up.policy_id
JOIN columns c ON pv.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN users reviewer ON pv.reviewed_by = reviewer.user_id
ORDER BY pv.attempted_at DESC;


-- Business Case: Manages data_consents data for the application.
-- Table Name: data_consents
-- Purpose: Stores detailed information about data processing consents (e.g., GDPR, CCPA).
-- Why It Matters:
-- - Central to compliance with privacy regulations
-- - Tracks legal basis, purpose, and validity period of data usage
-- - Enables auditability and revocation workflows
CREATE TABLE data_consents (
    consent_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    purpose VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    legal_basis VARCHAR(255) NOT NULL CHECK (legal_basis IN ('CONSENT', 'LEGAL_OBLIGATION', 'LEGITIMATE_INTEREST', 'VITAL_INTEREST', 'PUBLIC_TASK', 'CONTRACT')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_data_consents_is_active ON data_consents(is_active);
CREATE INDEX IF NOT EXISTS idx_data_consents_start_end_date ON data_consents(start_date, end_date);

-- Trigger to auto-update updated_at
CREATE TRIGGER update_data_consents_updated_at
    BEFORE UPDATE ON data_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Business Case: Manages consent_column_mapping data for the application.
-- Table Name: consent_column_mapping
-- Purpose: Links data consent policies to specific sensitive columns.
-- Why It Matters:
-- - Ensures only properly consented data is processed
-- - Supports field-level governance and masking logic
-- - Critical for data minimization and audit reporting
CREATE TABLE consent_column_mapping (
    mapping_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    consent_id UUID NOT NULL REFERENCES data_consents(consent_id) ON DELETE CASCADE,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance and joins
CREATE INDEX IF NOT EXISTS idx_consent_column_mapping_consent_id ON consent_column_mapping(consent_id);
CREATE INDEX IF NOT EXISTS idx_consent_column_mapping_column_id ON consent_column_mapping(column_id);
CREATE INDEX IF NOT EXISTS idx_consent_column_mapping_is_required ON consent_column_mapping(is_required);

-- Prevent duplicate mappings
ALTER TABLE consent_column_mapping ADD CONSTRAINT uk_consent_column UNIQUE (consent_id, column_id);


-- Business Case: Manages user_consents data for the application.
-- Table Name: user_consents
-- Purpose: Records individual user grants or revocations of consent.
-- Why It Matters:
-- - Tracks actual user actions (opt-in/opt-out)
-- - Supports right-to-withdraw and data deletion workflows
-- - Required for regulatory proof of consent management
CREATE TABLE user_consents (
    user_consent_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    consent_id UUID NOT NULL REFERENCES data_consents(consent_id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    is_revoked BOOLEAN GENERATED ALWAYS AS (revoked_at IS NOT NULL) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_consents_user_id ON user_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_consent_id ON user_consents(consent_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_granted_at ON user_consents(granted_at);
CREATE INDEX IF NOT EXISTS idx_user_consents_is_revoked ON user_consents(is_revoked);

-- Trigger
CREATE TRIGGER update_user_consents_updated_at
    BEFORE UPDATE ON user_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Business Case: Active User Consents Dashboard
-- Purpose: Show which users have active consent for sensitive columns
CREATE OR REPLACE VIEW active_user_consents_by_column AS
SELECT
    uc.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    dc.purpose,
    c.column_name,
    t.table_name,
    s.schema_name,
    uc.granted_at,
    uc.revoked_at
FROM user_consents uc
JOIN users u ON uc.user_id = u.user_id
JOIN data_consents dc ON uc.consent_id = dc.consent_id
JOIN consent_column_mapping ccm ON dc.consent_id = ccm.consent_id
JOIN columns c ON ccm.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
WHERE uc.is_revoked = FALSE
  AND dc.is_active = TRUE
  AND (dc.end_date IS NULL OR dc.end_date > NOW())
ORDER BY uc.granted_at DESC;


-- Business Case: Manages impact_simulations data for the application.
-- Table Name: impact_simulations
-- Purpose: Stores metadata about data change impact simulations (e.g., "What if this column is deprecated?")
-- Why It Matters:
-- - Enables safe evolution of schemas and pipelines
-- - Supports governance workflows for breaking changes
-- - Provides audit trail of what was analyzed and by whom
CREATE TABLE impact_simulations (
    simulation_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    simulation_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES users(user_id),
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT' 
        CHECK (status IN ('DRAFT', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_impact_simulations_created_by ON impact_simulations(created_by);
CREATE INDEX IF NOT EXISTS idx_impact_simulations_status ON impact_simulations(status);
CREATE INDEX IF NOT EXISTS idx_impact_simulations_created_at ON impact_simulations(created_at);

-- Trigger
CREATE TRIGGER update_impact_simulations_updated_at
    BEFORE UPDATE ON impact_simulations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Business Case: Manages simulation_parameters data for the application.
-- Table Name: simulation_parameters
-- Purpose: Stores input parameters used in an impact simulation run
-- Why It Matters:
-- - Allows reproducibility of simulation results
-- - Supports versioning and comparison across runs
-- - Critical for debugging and validation
CREATE TABLE simulation_parameters (
    parameter_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    simulation_id UUID NOT NULL REFERENCES impact_simulations(simulation_id) ON DELETE CASCADE,
    parameter_name VARCHAR(255) NOT NULL,
    parameter_value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX IF NOT EXISTS idx_simulation_parameters_simulation_id ON simulation_parameters(simulation_id);
-- Prevent redundant parameters
ALTER TABLE simulation_parameters ADD CONSTRAINT uk_simulation_parameter 
    UNIQUE (simulation_id, parameter_name);
	
	
	
-- Business Case: Manages simulation_results data for the application.
-- Table Name: simulation_results
-- Purpose: Stores output from impact simulations including downstream effects and cost estimates
-- Why It Matters:
-- - Quantifies risk and effort of proposed changes
-- - Helps prioritize remediation work
-- - Integrates with reporting and alerting systems
CREATE TABLE simulation_results (
    result_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    simulation_id UUID NOT NULL REFERENCES impact_simulations(simulation_id) ON DELETE CASCADE,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    impact_description TEXT,
    affected_downstream_components INTEGER DEFAULT 0,
    estimated_remediation_cost NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_simulation_results_simulation_id ON simulation_results(simulation_id);
CREATE INDEX IF NOT EXISTS idx_simulation_results_column_id ON simulation_results(column_id);
CREATE INDEX IF NOT EXISTS idx_simulation_results_created_at ON simulation_results(created_at);

-- Trigger
CREATE TRIGGER update_simulation_results_updated_at
    BEFORE UPDATE ON simulation_results
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
	
	
-- Business Case: Manages column_health_metrics data for the application.
-- Table Name: column_health_metrics
-- Purpose: Tracks time-series health indicators such as freshness, volume, null rate, and schema stability
-- Why It Matters:
-- - Enables proactive detection of data quality issues
-- - Supports SLA monitoring and observability
-- - Feeds into automated alerts and dashboards
CREATE TABLE column_health_metrics (
    metric_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    column_id UUID NOT NULL REFERENCES columns(column_id),
    metric_date DATE NOT NULL DEFAULT CURRENT_DATE,
    freshness_seconds INTEGER, -- Time since last update (in seconds)
    volume_count INTEGER,      -- Row count or message count
    null_percentage NUMERIC CHECK (null_percentage BETWEEN 0 AND 100),
    distinct_percentage NUMERIC CHECK (distinct_percentage BETWEEN 0 AND 100),
    value_distribution JSONB,  -- Histogram or top values
    schema_stable BOOLEAN DEFAULT TRUE, -- Whether schema changed recently
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Composite index and constraint
CREATE INDEX IF NOT EXISTS idx_column_health_metrics_column_date ON column_health_metrics(column_id, metric_date);
ALTER TABLE column_health_metrics ADD CONSTRAINT uk_column_metric_per_day 
    UNIQUE (column_id, metric_date);

-- Optional: Partial index for unstable schemas
CREATE INDEX IF NOT EXISTS idx_column_health_unstable ON column_health_metrics(column_id) 
WHERE schema_stable = FALSE;


-- Business Case: Column Health Dashboard
-- Purpose: Show recent health trends for monitoring and alerting
-- Why It Matters:
-- - Centralized view for data stewards and engineers
-- - Enables quick triage of unhealthy columns
-- - Integrates with UIs and alerting systems
CREATE OR REPLACE VIEW column_health_dashboard AS
SELECT
    m.metric_id,
    m.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    m.metric_date,
    m.freshness_seconds,
    m.volume_count,
    m.null_percentage,
    m.distinct_percentage,
    m.schema_stable,
    m.created_at,
    CASE
        WHEN NOT m.schema_stable THEN 'SCHEMA_DRIFT'
        WHEN m.freshness_seconds > 86400 THEN 'STALE_DATA'
        WHEN m.null_percentage > 50 THEN 'HIGH_NULLS'
        WHEN m.distinct_percentage < 1 THEN 'LOW_CARDINALITY'
        ELSE 'HEALTHY'
    END AS health_status,
    ROUND(m.null_percentage, 2) AS null_pct_display
FROM column_health_metrics m
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE m.metric_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY m.metric_date DESC, m.null_percentage DESC;

-- Business Case: Provides a comprehensive view of all column metadata, including details from parent tables, schemas, and databases.
-- View Name: vw_full_column_metadata
-- Purpose: Simplifies access to complete column information for reporting and analysis.
-- Additional Information: Useful for data catalog, governance, and lineage tools.
CREATE OR REPLACE VIEW vw_full_column_metadata AS
SELECT
    d.database_name,
    s.schema_name,
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.is_primary_key,
    c.description AS column_description,
    c.created_at AS column_created_at,
    c.updated_at AS column_updated_at
FROM
    databases d
JOIN
    schemas s ON d.database_id = s.database_id
JOIN
    tables t ON s.schema_id = t.schema_id
JOIN
    columns c ON t.table_id = c.table_id;
	
	

-- Business Case: Consolidates user, role, and permission information for access control auditing.
-- View Name: vw_user_permissions
-- Purpose: Provides an easy way to see which users have what permissions through their assigned roles.
-- Additional Information: Essential for security audits and compliance checks.
CREATE OR REPLACE VIEW vw_user_permissions AS
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.is_active AS user_active,
    r.role_name,
    p.resource_type,
    p.action,
    p.description AS permission_description
FROM
    users u
JOIN
    user_roles ur ON u.user_id = ur.user_id
JOIN
    roles r ON ur.role_id = r.role_id
JOIN
    role_permissions rp ON r.role_id = rp.role_id
JOIN
    permissions p ON rp.permission_id = p.permission_id;
	
	
-- Business Case: Provides a daily summary of data quality results for quick monitoring and dashboarding.
-- Materialized View Name: mv_daily_data_quality_summary
-- Purpose: Aggregates daily data quality metrics to improve query performance for frequently accessed reports.
-- Additional Information: Should be refreshed periodically (e.g., daily) to ensure up-to-date data.
CREATE MATERIALIZED VIEW mv_daily_data_quality_summary AS
SELECT
    c.column_name,
    dq.rule_name,
    DATE_TRUNC('day', dqr.execution_timestamp) AS execution_date,
    COUNT(dqr.result_id) AS total_checks,
    SUM(CASE WHEN dqr.records_failed > 0 THEN 1 ELSE 0 END) AS failed_checks,
    SUM(dqr.records_failed) AS total_records_failed,
    AVG(dqr.actual_value) AS avg_actual_value
FROM
    data_quality_results dqr
JOIN
    columns c ON dqr.column_id = c.column_id
JOIN
    data_quality_rules dq ON dqr.rule_id = dq.rule_id
GROUP BY
    c.column_name, dq.rule_name, DATE_TRUNC('day', dqr.execution_timestamp)
ORDER BY
    execution_date DESC;
	

-- Business Case: Traces the flow of data from source to target columns, providing end-to-end lineage.
-- View Name: vw_column_lineage
-- Purpose: Helps in understanding data origins, transformations, and impacts of changes.
-- Additional Information: Useful for impact analysis, root cause analysis, and compliance.
CREATE OR REPLACE VIEW vw_column_lineage AS
SELECT
    dl.lineage_id,
    sc.column_name AS source_column_name,
    st.table_name AS source_table_name,
    ss.schema_name AS source_schema_name,
    sd.database_name AS source_database_name,
    tc.column_name AS target_column_name,
    tt.table_name AS target_table_name,
    ts.schema_name AS target_schema_name,
    td.database_name AS target_database_name,
    dl.transformation_logic,
    dl.pipeline_name,
    dl.created_at
FROM
    data_lineage dl
JOIN
    columns sc ON dl.source_column_id = sc.column_id
JOIN
    tables st ON sc.table_id = st.table_id
JOIN
    schemas ss ON st.schema_id = ss.schema_id
JOIN
    databases sd ON ss.database_id = sd.database_id
JOIN
    columns tc ON dl.target_column_id = tc.column_id
JOIN
    tables tt ON tc.table_id = tt.table_id
JOIN
    schemas ts ON tt.schema_id = ts.schema_id
JOIN
    databases td ON ts.database_id = td.database_id;
	


-- Business Case: Combines column usage metrics with query performance data to identify frequently used and slow columns.
-- View Name: vw_column_usage_and_performance
-- Purpose: Helps in optimizing database performance and identifying areas for data archiving or indexing.
-- Additional Information: Provides insights for data lifecycle management and performance tuning.
CREATE OR REPLACE VIEW vw_column_usage_and_performance AS
SELECT
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    cum.query_count,
    cum.last_queried_at,
    qm.avg_duration_ms AS avg_query_duration_ms,
    qm.max_duration_ms AS max_query_duration_ms,
    qm.execution_count AS query_execution_count
FROM
    columns c
JOIN
    tables t ON c.table_id = t.table_id
JOIN
    schemas s ON t.schema_id = s.schema_id
JOIN
    databases d ON s.database_id = d.database_id
LEFT JOIN
    column_usage_metrics cum ON c.column_id = cum.column_id
LEFT JOIN
    query_metrics qm ON c.column_id = qm.column_id;
	
	
-- Business Case: Automates the process of adding a new user to the system and assigning them a default role.
-- Stored Procedure Name: add_new_user
-- Purpose: Ensures consistency and simplifies user onboarding by encapsulating the logic for user creation and role assignment.
-- Why It Matters:
-- - Reduces risk of incomplete user setup
-- - Enforces governance policies during provisioning
-- - Improves auditability and security posture
-- Additional Information:
-- - Requires the 'uuid-ossp' extension for UUID generation
-- - Assumes a 'default_user' role exists in the roles table
-- - Uses standard audit fields (created_at, updated_at)
CREATE OR REPLACE PROCEDURE add_new_user(
    p_username VARCHAR(255),
    p_password_hash TEXT,
    p_email VARCHAR(255),
    p_first_name VARCHAR(255) DEFAULT NULL,
    p_last_name VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_default_role_id UUID;
BEGIN
    -- Validate required inputs
    IF p_username IS NULL OR p_password_hash IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'Username, password hash, and email are required.';
    END IF;

    -- Get the ID of the 'default_user' role
    SELECT role_id INTO v_default_role_id 
    FROM roles 
    WHERE role_name = 'default_user';

    IF v_default_role_id IS NULL THEN
        RAISE EXCEPTION 'Default role "default_user" not found. Please ensure the role exists.';
    END IF;

    -- Insert the new user
    INSERT INTO users (
        user_id, 
        username, 
        password_hash, 
        first_name, 
        last_name, 
        email,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        uuid_generate_v4(),
        p_username,
        p_password_hash,
        p_first_name,
        p_last_name,
        p_email,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING user_id INTO v_user_id;

    -- Assign the default role to the new user
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_at)
    VALUES (uuid_generate_v4(), v_user_id, v_default_role_id, CURRENT_TIMESTAMP);

    -- Log success
    RAISE NOTICE 'User % (ID: %) created successfully and assigned to default role.', p_username, v_user_id;
    
EXCEPTION
    WHEN UNIQUE_VIOLATION THEN
        RAISE EXCEPTION 'A user with username or email % already exists.', COALESCE(p_username, p_email);
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create user %: %', p_username, SQLERRM;
END;
$$;


-- Business Case: Automates the process of adding a new user to the system and assigning them a default role.
-- Stored Procedure Name: add_new_user
-- Purpose: Ensures consistency and simplifies user onboarding by encapsulating the logic for user creation and role assignment.
-- Why It Matters:
-- - Reduces risk of incomplete setup (e.g., missing roles)
-- - Enforces security policies during provisioning
-- - Improves auditability and compliance
-- Additional Information:
-- - Requires 'uuid-ossp' extension (assumed enabled)
-- - Assumes a role named 'default_user' exists
-- - Adds user with email as login identifier if no username field
CREATE OR REPLACE PROCEDURE add_new_user(
    p_email VARCHAR(255),
    p_password_hash TEXT,
    p_first_name VARCHAR(255) DEFAULT NULL,
    p_last_name VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_default_role_id UUID;
BEGIN
    -- Validate required inputs
    IF p_email IS NULL OR p_password_hash IS NULL THEN
        RAISE EXCEPTION 'Email and password hash are required.';
    END IF;

    -- Check if user already exists
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RAISE EXCEPTION 'User with email % already exists.', p_email;
    END IF;

    -- Get the ID of the 'default_user' role
    SELECT role_id INTO v_default_role_id FROM roles WHERE role_name = 'default_user';

    IF v_default_role_id IS NULL THEN
        RAISE EXCEPTION 'Default role "default_user" not found. Please create it first.';
    END IF;

    -- Insert the new user
    INSERT INTO users (
        user_id,
        password_hash,
        first_name,
        last_name,
        email,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        uuid_generate_v4(),
        p_password_hash,
        p_first_name,
        p_last_name,
        p_email,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING user_id INTO v_user_id;

    -- Assign the default role
    INSERT INTO user_roles (user_role_id, user_id, role_id, assigned_at)
    VALUES (uuid_generate_v4(), v_user_id, v_default_role_id, CURRENT_TIMESTAMP);

    -- Log success
    RAISE NOTICE 'User % (ID: %) created and assigned to role "default_user".', p_email, v_user_id;

EXCEPTION
    WHEN UNIQUE_VIOLATION THEN
        RAISE EXCEPTION 'A unique constraint was violated. User may already exist.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create user %: %', p_email, SQLERRM;
END;
$$;


-- Business Case: Allows updating a column's description and automatically logs the change in the audit trail.
-- Stored Procedure Name: update_column_description
-- Purpose: Centralizes column description updates and ensures data governance and traceability.
-- Why It Matters:
-- - Prevents untracked metadata changes
-- - Builds trust in data catalog accuracy
-- - Integrates with stewardship workflows and reporting
-- Additional Information:
-- - Depends on `column_audit_trail` table for logging
-- - Requires valid user_id for attribution
CREATE OR REPLACE PROCEDURE update_column_description(
    p_column_id UUID,
    p_new_description TEXT,
    p_changed_by_user_id UUID,
    p_change_reason TEXT DEFAULT 'Description updated via stored procedure'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_description TEXT;
BEGIN
    -- Validate input
    IF p_column_id IS NULL THEN
        RAISE EXCEPTION 'Column ID is required.';
    END IF;

    -- Ensure user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_changed_by_user_id) THEN
        RAISE EXCEPTION 'Invalid user_id: user does not exist.';
    END IF;

    -- Ensure column exists
    IF NOT EXISTS (SELECT 1 FROM columns WHERE column_id = p_column_id) THEN
        RAISE EXCEPTION 'Invalid column_id: column not found.';
    END IF;

    -- Get current description
    SELECT description INTO v_old_description FROM columns WHERE column_id = p_column_id;

    -- Avoid unnecessary updates
    IF v_old_description IS NOT DISTINCT FROM p_new_description THEN
        RAISE NOTICE 'No change detected for column ID %. Description unchanged.', p_column_id;
        RETURN;
    END IF;

    -- Update the column
    UPDATE columns
    SET description = p_new_description,
        updated_at = CURRENT_TIMESTAMP
    WHERE column_id = p_column_id;

    -- Log the change
    INSERT INTO column_audit_trail (
        audit_id,
        column_id,
        changed_by,
        changed_at,
        old_value,
        new_value,
        change_reason,
        changed_field
    )
    VALUES (
        uuid_generate_v4(),
        p_column_id,
        p_changed_by_user_id,
        CURRENT_TIMESTAMP,
        jsonb_build_object('description', v_old_description),
        jsonb_build_object('description', p_new_description),
        COALESCE(p_change_reason, 'Description updated'),
        'description'
    );

    -- Confirmation log
    RAISE NOTICE 'Column description updated: ID=%, From="%", To="%", By User=%',
                 p_column_id,
                 COALESCE(v_old_description, '[NULL]'),
                 p_new_description,
                 p_changed_by_user_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to update column description for column ID %: %', p_column_id, SQLERRM;
END;
$$;


-- Business Case: Records usage events for data products, enabling usage analytics and billing.
-- Stored Procedure Name: log_data_product_usage
-- Purpose: Provides a standardized way to log interactions with data products, capturing key metrics.
-- Why It Matters:
-- - Enables accurate measurement of adoption and engagement
-- - Supports FinOps and cost attribution workflows
-- - Powers dashboards like data_product_usage_dashboard
-- Additional Information:
-- - Uses UUIDs for traceability
-- - Compatible with batch and real-time logging
-- - Aligns with audit patterns across the platform
CREATE OR REPLACE PROCEDURE log_data_product_usage(
    p_product_id UUID,
    p_user_id UUID,
    p_access_method VARCHAR(255) DEFAULT NULL,
    p_query_parameters TEXT DEFAULT NULL,
    p_rows_accessed INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_accessed_at TIMESTAMP WITH TIME ZONE := CURRENT_TIMESTAMP;
BEGIN
    -- Validate required inputs
    IF p_product_id IS NULL THEN
        RAISE EXCEPTION 'Parameter p_product_id cannot be NULL.';
    END IF;

    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'Parameter p_user_id cannot be NULL.';
    END IF;

    -- Ensure product exists
    IF NOT EXISTS (SELECT 1 FROM data_products WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'Invalid product_id: % does not exist.', p_product_id;
    END IF;

    -- Ensure user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user_id: % does not exist.', p_user_id;
    END IF;

    -- Insert usage record
    INSERT INTO data_product_usage (
        usage_id,
        product_id,
        user_id,
        accessed_at,
        access_method,
        query_parameters,
        rows_accessed,
        created_at,
        updated_at
    )
    VALUES (
        uuid_generate_v4(),
        p_product_id,
        p_user_id,
        v_accessed_at,
        p_access_method,
        p_query_parameters,
        p_rows_accessed,
        v_accessed_at,
        v_accessed_at
    );

    -- Optional: Log success (useful in debug mode)
    RAISE NOTICE 'Usage logged for data product ID % by user % at %.', p_product_id, p_user_id, v_accessed_at;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to log data product usage: %', SQLERRM;
END;
$$;



-- Business Case: Refreshes the materialized view for daily data quality summary.
-- Stored Procedure Name: refresh_daily_quality_summary
-- Purpose: Ensures that the materialized view 'mv_daily_data_quality_summary' is up-to-date with the latest data quality results.
-- Additional Information: Should be scheduled to run periodically, e.g., daily, to maintain data freshness.
CREATE OR REPLACE PROCEDURE refresh_daily_quality_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_daily_data_quality_summary;
    RAISE NOTICE 'Materialized view mv_daily_data_quality_summary refreshed successfully.';
END;
$$;



-- Business Case: Data Quality Heatmap
-- Purpose: Visualize data quality health across schemas and time using a heatmap
-- Why It Matters:
-- - Quickly identify schemas with recurring or worsening failures
-- - Supports executive dashboards and governance triage
-- - Enables proactive remediation before downstream impact
CREATE OR REPLACE VIEW data_quality_heatmap AS
SELECT
    database_name,
    schema_name,
    DATE_TRUNC('week', captured_at)::DATE AS week_start,
    ROUND(AVG(quality_score), 2) AS avg_quality_score,
    SUM(failing_columns) AS failing_column_count
FROM data_quality_score_history
GROUP BY
    database_name,
    schema_name,
    week_start
ORDER BY
    database_name,
    schema_name,
    week_start DESC;
	
	
-- Business Case: Column Access Pattern Heatmap
-- Purpose: Identify temporal access patterns to detect anomalies or peak usage times
-- Why It Matters:
-- - Helps spot off-hours access (potential security issue)
-- - Informs indexing, caching, and scaling strategies
-- - Enhances monitoring of PII columns
CREATE OR REPLACE VIEW column_access_frequency_heatmap AS
SELECT
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    EXTRACT(DOW FROM a.accessed_at) AS day_of_week, -- 0=Sun, 6=Sat
    EXTRACT(HOUR FROM a.accessed_at) AS hour_of_day,
    COUNT(*) AS access_count
FROM access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE a.accessed_at >= NOW() - INTERVAL '7 days'
GROUP BY
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    day_of_week,
    hour_of_day
HAVING COUNT(*) > 0
ORDER BY access_count DESC;


-- Business Case: Sensitive Data Exposure Heatmap
-- Purpose: Map user access to sensitive (PII/regulated) columns
-- Why It Matters:
-- - Identifies excessive or unexpected access rights
-- - Supports least-privilege audits and SOX/GDPR compliance
-- - Highlights need for masking or approval workflows
CREATE OR REPLACE VIEW sensitive_column_exposure_heatmap AS
SELECT
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    st.tag_category,
    st.tag_name,
    COUNT(a.log_id) AS total_accesses,
    COUNT(*) FILTER (WHERE NOT a.was_approved) AS unapproved_attempts,
    MAX(a.accessed_at) AS last_accessed
FROM access_logs a
JOIN users u ON a.user_id = u.user_id
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id
WHERE st.tag_category IN ('PII', 'PHI', 'PCI', 'SECRET', 'CONFIDENTIAL')
GROUP BY
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    c.column_id,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    st.tag_category,
    st.tag_name
HAVING COUNT(a.log_id) > 0
ORDER BY total_accesses DESC;



ALTER TABLE column_usage_metrics 
RENAME COLUMN last_queried_at TO last_accessed_at;

-- Business Case: Metadata Completeness Heatmap
-- Purpose: Visualize completeness of metadata attributes per schema
-- Why It Matters:
-- - Guides stewardship efforts toward under-documented areas
-- - Measures progress on data discovery initiatives
-- - Aligns with data mesh domain ownership goals
-- Additional Information:
-- - Aggregates coverage across five key metadata dimensions
-- - Outputs percentage scores for easy dashboarding
-- - Used in data governance scorecards and low-coverage alerts
CREATE OR REPLACE VIEW metadata_completeness_heatmap AS
WITH coverage AS (
    SELECT
        d.database_name,
        s.schema_name,
        COUNT(c.column_id) AS total_columns,

        -- Description completeness
        AVG(CASE WHEN c.description IS NOT NULL THEN 1 ELSE 0 END) AS pct_with_description,

        -- Tagging completeness
        AVG(CASE WHEN EXISTS (
            SELECT 1 
            FROM column_tag_mapping ctm 
            JOIN search_tags st ON ctm.tag_id = st.tag_id 
            WHERE ctm.column_id = c.column_id
        ) THEN 1 ELSE 0 END) AS pct_with_tags,

        -- Glossary linkage completeness
        AVG(CASE WHEN g.term_id IS NOT NULL THEN 1 ELSE 0 END) AS pct_with_glossary,

        -- Usage tracking completeness (fixed column name)
        AVG(CASE WHEN um.last_accessed_at IS NOT NULL THEN 1 ELSE 0 END) AS pct_with_usage,

        -- AI/ML insights completeness
        AVG(CASE WHEN ci.predictive_relevance_score IS NOT NULL THEN 1 ELSE 0 END) AS pct_with_ai_insights

    FROM columns c
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id

    -- Optional: metadata components
    LEFT JOIN column_glossary_mapping g ON c.column_id = g.column_id
    LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id
    LEFT JOIN column_insights ci ON c.column_id = ci.column_id

    GROUP BY
        d.database_name,
        s.schema_name
)
SELECT
    database_name,
    schema_name,
    ROUND(pct_with_description * 100, 1) AS description_coverage_pct,
    ROUND(pct_with_tags * 100, 1) AS tags_coverage_pct,
    ROUND(pct_with_glossary * 100, 1) AS glossary_coverage_pct,
    ROUND(pct_with_usage * 100, 1) AS usage_coverage_pct,
    ROUND(pct_with_ai_insights * 100, 1) AS ai_insights_coverage_pct,
    ROUND(
        (pct_with_description + pct_with_tags + pct_with_glossary + pct_with_usage + pct_with_ai_insights) / 5 * 100, 1
    ) AS overall_metadata_score
FROM coverage
ORDER BY overall_metadata_score ASC;


-- Business Case: Retention Policy Gap Heatmap
-- Purpose: Show retention policy coverage intensity across databases and schemas
-- Why It Matters:
-- - Identifies non-compliant areas for GDPR/CCPA readiness
-- - Focuses governance team attention on high-risk zones
-- - Tracks improvement over time
CREATE OR REPLACE VIEW retention_policy_gap_heatmap AS
SELECT
    d.database_name,
    s.schema_name,
    COUNT(c.column_id) AS total_columns,
    COUNT(m.column_id) AS covered_columns,
    ROUND(
        (COUNT(m.column_id)::NUMERIC / NULLIF(COUNT(c.column_id), 0)) * 100, 2
    ) AS retention_coverage_pct,
    CASE
        WHEN (COUNT(m.column_id)::NUMERIC / NULLIF(COUNT(c.column_id), 0)) * 100 < 30 THEN 'Critical'
        WHEN (COUNT(m.column_id)::NUMERIC / NULLIF(COUNT(c.column_id), 0)) * 100 < 70 THEN 'Warning'
        ELSE 'Good'
    END AS risk_level
FROM columns c
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_retention_policies m ON c.column_id = m.column_id
GROUP BY
    d.database_name,
    s.schema_name
HAVING COUNT(c.column_id) > 0
ORDER BY
    retention_coverage_pct ASC,
    total_columns DESC;

-- Business Case: User Activity Intensity Heatmap
-- Purpose: Map user engagement intensity across time-of-day and day-of-week
-- Why It Matters:
-- - Detects off-hours access (potential security concern)
-- - Informs staffing, support, and scaling decisions
-- - Powers anomaly detection models
CREATE OR REPLACE VIEW user_activity_intensity_heatmap AS
SELECT
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    EXTRACT(DOW FROM a.accessed_at) AS day_of_week, -- 0=Sun, 6=Sat
    EXTRACT(HOUR FROM a.accessed_at) AS hour_of_day,
    COUNT(*) AS access_count
FROM access_logs a
JOIN users u ON a.user_id = u.user_id
WHERE a.accessed_at >= NOW() - INTERVAL '14 days'
GROUP BY
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    day_of_week,
    hour_of_day
HAVING COUNT(*) > 0
ORDER BY access_count DESC;


-- Business Case: Sensitivity vs Access Frequency Heatmap
-- Purpose: Highlight columns that are both sensitive and highly accessed
-- Why It Matters:
-- - Prioritizes masking, approval workflows, or deprecation efforts
-- - Balances usability with risk management
-- - Feeds into data protection impact assessments (DPIA)
CREATE OR REPLACE VIEW sensitivity_access_heatmap AS
SELECT
    st.tag_name AS sensitivity_level,
    CASE
        WHEN freq.access_count < 10 THEN 'Low'
        WHEN freq.access_count < 100 THEN 'Medium'
        WHEN freq.access_count < 1000 THEN 'High'
        ELSE 'Very High'
    END AS access_frequency_band,
    COUNT(*) AS column_count,
    STRING_AGG(c.column_name, ', ') AS sample_columns
FROM (
    SELECT
        c.column_id,
        c.column_name,
        COUNT(*) AS access_count
    FROM access_logs a
    JOIN columns c ON a.column_id = c.column_id
    WHERE a.accessed_at >= NOW() - INTERVAL '7 days'
    GROUP BY c.column_id, c.column_name
) freq
JOIN columns c ON freq.column_id = c.column_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id
WHERE st.tag_category IN ('PII', 'PCI', 'PHI', 'SECRET')
GROUP BY
    st.tag_name,
    access_frequency_band
ORDER BY
    CASE st.tag_name
        WHEN 'SSN' THEN 1
        WHEN 'Credit Card' THEN 2
        WHEN 'Password' THEN 3
        WHEN 'Email' THEN 4
        ELSE 5
    END,
    access_frequency_band;


-- Business Case: Retention Duration Distribution Heatmap
-- Purpose: Visualize how long data is kept across systems
-- Why It Matters:
-- - Ensures alignment with regulatory requirements
-- - Highlights outliers (e.g., 10-year logs in dev DB)
-- - Supports cost optimization and purge planning
CREATE OR REPLACE VIEW retention_duration_heatmap AS
SELECT
    d.database_name,
    s.schema_name,
    p.retention_period_days,
    COUNT(m.column_id) AS column_count
FROM column_retention_policies m
JOIN retention_policies p ON m.policy_id = p.policy_id
JOIN columns c ON m.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
GROUP BY
    d.database_name,
    s.schema_name,
    p.retention_period_days
ORDER BY
    d.database_name,
    p.retention_period_days;
	
	
-- Business Case: AI Insight Completeness Heatmap
-- Purpose: Monitor progress of AI-generated metadata across schemas
-- Why It Matters:
-- - Measures ROI of AI investments
-- - Guides manual review priorities
-- - Supports auto-tagging model training feedback loop
CREATE OR REPLACE VIEW ai_insight_completeness_heatmap AS
WITH insight_types AS (
    SELECT column_id, 'description' AS insight_type FROM column_description_generation WHERE human_reviewed = TRUE
    UNION ALL
    SELECT column_id, 'recommendation' FROM column_recommendations WHERE was_consumed
    UNION ALL
    SELECT column_id, 'embedding' FROM column_embeddings
    UNION ALL
    SELECT column_id, 'insight' FROM column_insights WHERE predictive_relevance_score IS NOT NULL
),
schema_insights AS (
    SELECT
        s.schema_name,
        d.database_name,
        it.insight_type,
        COUNT(*) AS generated_count
    FROM insight_types it
    JOIN columns c ON it.column_id = c.column_id
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    GROUP BY s.schema_name, d.database_name, it.insight_type
),
schema_totals AS (
    SELECT
        s.schema_name,
        d.database_name,
        COUNT(c.column_id) AS total_columns
    FROM schemas s
    JOIN databases d ON s.database_id = d.database_id
    JOIN tables t ON t.schema_id = s.schema_id
    JOIN columns c ON c.table_id = t.table_id
    GROUP BY s.schema_name, d.database_name
)
SELECT
    si.database_name,
    si.schema_name,
    si.insight_type,
    si.generated_count,
    st.total_columns,
    ROUND((si.generated_count::NUMERIC / st.total_columns) * 100, 1) AS completion_pct
FROM schema_insights si
JOIN schema_totals st 
    ON si.schema_name = st.schema_name 
   AND si.database_name = st.database_name
ORDER BY
    si.database_name,
    si.schema_name,
    si.insight_type;


--rule name with pattern matching 
SELECT
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    r.records_failed,
    r.execution_timestamp,
    CASE 
        WHEN q.rule_name ILIKE '%null%' THEN 'NOT_NULL'
        WHEN q.rule_name ILIKE '%unique%' THEN 'UNIQUENESS'
        WHEN q.rule_name ILIKE '%regex%' THEN 'REGEX_MATCH'
        WHEN q.rule_name ILIKE '%range%' THEN 'VALUE_RANGE'
        ELSE 'CUSTOM'
    END AS rule_type,
    COUNT(*) AS failure_count
FROM data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE r.records_failed > 0
GROUP BY
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    r.records_failed,
    r.execution_timestamp,
    rule_type
ORDER BY failure_count DESC;

-- Example: DQ Failure Type Heatmap
SELECT
    s.schema_name,
    CASE 
        WHEN q.rule_name ILIKE '%null%' THEN 'NOT_NULL'
        WHEN q.rule_name ILIKE '%unique%' THEN 'UNIQUENESS'
        ELSE 'OTHER'
    END AS rule_type,
    COUNT(r.result_id) AS failure_count
FROM data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
WHERE r.records_failed > 0
GROUP BY s.schema_name, rule_type;

-- Business Case: Schema Weekly Activity Heatmap
-- Purpose: Visualize access intensity per schema by day of week
-- Why It Matters:
-- - Reveals usage patterns (batch jobs, reporting cycles)
-- - Helps detect anomalies (e.g., weekend ETL spikes)
-- - Supports capacity planning
CREATE OR REPLACE VIEW schema_activity_heatmap AS
SELECT
    s.schema_name,
    d.database_name,
    EXTRACT(DOW FROM a.accessed_at) AS day_of_week, -- 0=Sun, 6=Sat
    TO_CHAR(a.accessed_at, 'Day') AS day_name,
    COUNT(*) AS access_count
FROM access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE a.accessed_at >= NOW() - INTERVAL '14 days'
GROUP BY
    s.schema_name,
    d.database_name,
    day_of_week,
    day_name
HAVING COUNT(*) > 0
ORDER BY
    d.database_name,
    s.schema_name,
    day_of_week;
	
	
-- Business Case: User-Schema Engagement Heatmap
-- Purpose: Map user interaction intensity across schemas
-- Why It Matters:
-- - Identifies domain experts vs outliers
-- - Supports role-based access review
-- - Powers stewardship assignment logic
CREATE OR REPLACE VIEW user_schema_engagement_heatmap AS
SELECT
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    s.schema_name,
    d.database_name,
    COUNT(*) AS total_accesses,
    COUNT(*) FILTER (WHERE NOT a.was_approved) AS unapproved_attempts,
    MAX(a.accessed_at) AS last_accessed
FROM access_logs a
JOIN users u ON a.user_id = u.user_id
JOIN columns c ON a.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE a.accessed_at >= NOW() - INTERVAL '30 days'
GROUP BY
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    s.schema_name,
    d.database_name
HAVING COUNT(*) > 0
ORDER BY total_accesses DESC;


-- Business Case: PII Hourly Exposure Heatmap
-- Purpose: Identify high-risk access windows for PII-tagged columns
-- Why It Matters:
-- - Flags potential insider threats
-- - Supports zero-trust monitoring
-- - Integrates with SIEM/SOAR tools
CREATE OR REPLACE VIEW pii_hourly_exposure_heatmap AS
SELECT
    s.schema_name,
    EXTRACT(DOW FROM a.accessed_at) AS day_of_week,
    EXTRACT(HOUR FROM a.accessed_at) AS hour_of_day,
    st.tag_name AS sensitivity_level,
    COUNT(*) AS access_count,
    COUNT(*) FILTER (WHERE NOT a.was_approved) AS denied_count
FROM access_logs a
JOIN columns c ON a.column_id = c.column_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
WHERE st.tag_category = 'PII'
  AND a.accessed_at >= NOW() - INTERVAL '7 days'
GROUP BY
    s.schema_name,
    day_of_week,
    hour_of_day,
    sensitivity_level
HAVING COUNT(*) > 0
ORDER BY access_count DESC;


-- Business Case: DQ Rule Execution Frequency Heatmap
-- Purpose: Show rule execution coverage across schemas and time
-- Why It Matters:
-- - Ensures consistent monitoring cadence
-- - Highlights neglected areas
-- - Supports SLA compliance
CREATE OR REPLACE VIEW dq_rule_execution_frequency_heatmap AS
SELECT
    s.schema_name,
    d.database_name,
    DATE_TRUNC('day', r.execution_timestamp) AS execution_date,
    q.rule_name,
    COUNT(r.result_id) AS execution_count
FROM data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE r.execution_timestamp >= NOW() - INTERVAL '14 days'
GROUP BY
    s.schema_name,
    d.database_name,
    execution_date,
    q.rule_name
HAVING COUNT(r.result_id) > 0
ORDER BY execution_date DESC, execution_count DESC;


-- Business Case: Metadata Enrichment Completeness Heatmap
-- Purpose: Measure progress on metadata completeness across schemas
-- Why It Matters:
-- - Tracks stewardship KPIs
-- - Guides AI/ML auto-tagging efforts
-- - Supports data product certification
CREATE OR REPLACE VIEW metadata_enrichment_heatmap AS
WITH schema_summary AS (
    SELECT
        s.schema_name,
        d.database_name,
        COUNT(c.column_id) AS total_columns,

        COUNT(CASE WHEN c.description IS NOT NULL THEN 1 END) AS has_description,
        ROUND(COUNT(CASE WHEN c.description IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id), 2) AS description_pct,

        COUNT(CASE WHEN EXISTS (
            SELECT 1 FROM column_tag_mapping ctm WHERE ctm.column_id = c.column_id
        ) THEN 1 END) AS has_tags,
        ROUND(COUNT(CASE WHEN EXISTS (
            SELECT 1 FROM column_tag_mapping ctm WHERE ctm.column_id = c.column_id
        ) THEN 1 END)::NUMERIC / COUNT(c.column_id), 2) AS tags_pct,

        COUNT(CASE WHEN um.last_accessed_at IS NOT NULL THEN 1 END) AS has_usage,
        ROUND(COUNT(CASE WHEN um.last_accessed_at IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id), 2) AS usage_pct
    FROM columns c
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    JOIN databases d ON s.database_id = d.database_id
    LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id
    GROUP BY s.schema_name, d.database_name
)
SELECT
    database_name,
    schema_name,
    ROUND(description_pct * 100) AS description_completeness,
    ROUND(tags_pct * 100) AS tagging_completeness,
    ROUND(usage_pct * 100) AS usage_tracking_completeness,
    ROUND(
        (description_pct + tags_pct + usage_pct) / 3 * 100
    ) AS overall_metadata_score
FROM schema_summary
ORDER BY overall_metadata_score ASC;



-- Business Case: Column Popularity Trend Heatmap
-- Purpose: Monitor shifting access patterns across key columns
-- Why It Matters:
-- - Reveals emerging data products
-- - Detects deprecated usage
-- - Informs caching/indexing strategies
CREATE OR REPLACE VIEW column_popularity_weekly_heatmap AS
WITH weekly_access AS (
    SELECT
        DATE_TRUNC('week', a.accessed_at) AS week_start,
        c.column_id,
        c.column_name,
        t.table_name,
        s.schema_name,
        COUNT(*) AS access_count,
        RANK() OVER (PARTITION BY DATE_TRUNC('week', a.accessed_at) ORDER BY COUNT(*) DESC) AS rank_in_week
    FROM access_logs a
    JOIN columns c ON a.column_id = c.column_id
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    WHERE a.accessed_at >= NOW() - INTERVAL '8 weeks'
    GROUP BY week_start, c.column_id, c.column_name, t.table_name, s.schema_name
)
SELECT
    week_start,
    schema_name,
    table_name,
    column_name,
    access_count,
    rank_in_week
FROM weekly_access
WHERE rank_in_week <= 10  -- Top 10 per week
ORDER BY week_start DESC, rank_in_week;


-- Business Case: Sensitive Data Hotspot Heatmap
-- Purpose: Identify high-exposure PII/PHI/PCI columns based on access frequency
-- Why It Matters:
-- - Flags high-risk data assets requiring stronger controls
-- - Supports zero-trust architecture and least-privilege reviews
-- - Powers automated alerts when new "hot" cells appear
CREATE OR REPLACE VIEW sensitive_column_access_heatmap AS
SELECT
    st.tag_name AS sensitivity_tag,
    s.schema_name,
    COUNT(al.log_id) AS total_accesses,
    COUNT(*) FILTER (WHERE NOT al.was_approved) AS unapproved_attempts,
    ROUND(
        (COUNT(*) FILTER (WHERE NOT al.was_approved)::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 2
    ) AS rejection_rate_percent,
    MAX(al.accessed_at) AS last_accessed
FROM access_logs al
JOIN columns c ON al.column_id = c.column_id
JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
JOIN search_tags st ON ctm.tag_id = st.tag_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
WHERE st.tag_category IN ('PII', 'PHI', 'PCI')
GROUP BY
    st.tag_name,
    s.schema_name
HAVING COUNT(al.log_id) > 0
ORDER BY total_accesses DESC;


-- Business Case: Schema Documentation Coverage Heatmap
-- Purpose: Visualize metadata completeness per schema across description, tagging, glossary, and usage
-- Why It Matters:
-- - Measures progress of data cataloging initiatives
-- - Identifies stewardship gaps
-- - Enables domain-level accountability in data mesh
CREATE OR REPLACE VIEW schema_metadata_coverage_heatmap AS
SELECT
    d.database_name,
    s.schema_name,
    
    -- Description completeness
    ROUND(
        (COUNT(CASE WHEN c.description IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id)) * 100, 1
    ) AS description_pct,

    -- Tagging completeness
    ROUND(
        (COUNT(CASE WHEN EXISTS (
            SELECT 1 FROM column_tag_mapping ctm WHERE ctm.column_id = c.column_id
        ) THEN 1 END)::NUMERIC / COUNT(c.column_id)) * 100, 1
    ) AS tags_pct,

    -- Glossary linkage
    ROUND(
        (COUNT(CASE WHEN g.term_id IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id)) * 100, 1
    ) AS glossary_pct,

    -- Usage tracking
    ROUND(
        (COUNT(CASE WHEN um.last_accessed_at IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id)) * 100, 1
    ) AS usage_pct,

    -- Overall score
    ROUND(
        (
            (COUNT(CASE WHEN c.description IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id)) +
            (COUNT(CASE WHEN EXISTS (SELECT 1 FROM column_tag_mapping ctm WHERE ctm.column_id = c.column_id) THEN 1 END)::NUMERIC / COUNT(c.column_id)) +
            (COUNT(CASE WHEN g.term_id IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id)) +
            (COUNT(CASE WHEN um.last_accessed_at IS NOT NULL THEN 1 END)::NUMERIC / COUNT(c.column_id))
        ) / 4 * 100, 1
    ) AS overall_score
FROM schemas s
JOIN databases d ON s.database_id = d.database_id
JOIN tables t ON s.schema_id = t.schema_id
JOIN columns c ON t.table_id = c.table_id
LEFT JOIN column_glossary_mapping g ON c.column_id = g.column_id
LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id
GROUP BY
    d.database_name,
    s.schema_name
HAVING COUNT(c.column_id) > 0
ORDER BY overall_score ASC;

-- Business Case: DQ Rule Failure Intensity Heatmap
-- Purpose: Highlight recurring quality issues by rule type and schema
-- Why It Matters:
-- - Helps prioritize root cause analysis
-- - Reveals systemic problems (e.g., all regex rules failing in one schema)
-- - Guides test coverage improvements
CREATE OR REPLACE VIEW dq_failure_intensity_heatmap AS
SELECT
    s.schema_name,
    d.database_name,
    q.rule_name,
    COUNT(r.result_id) AS failure_count,
    SUM(r.records_failed) AS total_records_affected,
    ROUND(AVG(r.records_failed::NUMERIC), 2) AS avg_records_per_failure,
    MAX(r.execution_timestamp) AS last_failure_time
FROM data_quality_results r
JOIN data_quality_rules q ON r.rule_id = q.rule_id
JOIN columns c ON r.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
WHERE r.records_failed > 0
  AND r.execution_timestamp >= NOW() - INTERVAL '14 days'
GROUP BY
    s.schema_name,
    d.database_name,
    q.rule_name
HAVING COUNT(r.result_id) > 0
ORDER BY failure_count DESC;


-- Business Case: Get All Tables Used by a Data Product
-- Purpose: Identify physical tables underlying a data product for lineage and impact analysis
-- Why It Matters:
-- - Supports deprecation planning
-- - Enables cost attribution at the table level
-- - Helps build accurate data catalogs
CREATE OR REPLACE VIEW data_product_tables_context AS
SELECT DISTINCT
    dp.product_id,
    dp.product_name,
    dp.domain,
    t.table_id,
    t.table_name,
    s.schema_name,
    d.database_name,
    COUNT(c.column_id) AS column_count_in_product
FROM data_products dp
JOIN data_product_components pc ON dp.product_id = pc.product_id
JOIN columns c ON pc.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
GROUP BY
    dp.product_id,
    dp.product_name,
    dp.domain,
    t.table_id,
    t.table_name,
    s.schema_name,
    d.database_name
ORDER BY
    dp.product_name,
    d.database_name,
    s.schema_name,
    t.table_name;

-- Business Case: Full Data Product Physical Context
-- Purpose: Show complete mapping from logical data product to physical tables, with metrics
-- Why It Matters:
-- - Bridges semantic and storage layers
-- - Powers FinOps and optimization initiatives
-- - Critical for migration and modernization projects
CREATE OR REPLACE VIEW data_product_physical_context AS
SELECT
    dp.product_id,
    dp.product_name,
    dp.domain,
    d.database_name,
    s.schema_name,
    t.table_name,
    COUNT(DISTINCT c.column_id) AS column_count,
    SUM(um.query_count) AS total_queries_on_columns,
    MAX(um.last_accessed_at) AS last_accessed,  -- Fixed: Use new column name
    SUM(COALESCE(ca.calculated_cost, 0)) AS estimated_monthly_cost
FROM data_products dp
JOIN data_product_components pc ON dp.product_id = pc.product_id
JOIN columns c ON pc.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id
LEFT JOIN column_usage_metrics um ON c.column_id = um.column_id
LEFT JOIN cost_attribution ca ON c.column_id = ca.column_id 
    AND ca.calculation_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    dp.product_id,
    dp.product_name,
    dp.domain,
    d.database_name,
    s.schema_name,
    t.table_name
ORDER BY
    dp.product_name,
    total_queries_on_columns DESC NULLS LAST;

-- Business Case: Test Coverage Freshness Heatmap
-- Purpose: Track recency and scope of testing at the column level
-- Why It Matters:
-- - Prevents undetected regressions
-- - Ensures compliance with testing SLAs
-- - Integrates with DevOps pipelines
CREATE OR REPLACE VIEW test_coverage_freshness_heatmap AS
WITH column_test_status AS (
    SELECT
        s.schema_name,
        c.column_id,
        c.column_name,
        tc.last_run_at
    FROM columns c
    JOIN tables t ON c.table_id = t.table_id
    JOIN schemas s ON t.schema_id = s.schema_id
    LEFT JOIN column_test_coverage tc ON c.column_id = tc.column_id
),
schema_summary AS (
    SELECT
        schema_name,
        CASE
            WHEN MAX(last_run_at) >= NOW() - INTERVAL '1 day' THEN 'Last 24h'
            WHEN MAX(last_run_at) >= NOW() - INTERVAL '7 days' THEN 'Last Week'
            WHEN MAX(last_run_at) IS NOT NULL THEN 'Stale (>7d)'
            ELSE 'Never Tested'
        END AS test_recency_bucket,
        COUNT(*) AS column_count,
        STRING_AGG(CASE WHEN last_run_at IS NULL THEN column_name END, ', ') AS untested_columns
    FROM column_test_status
    GROUP BY
        schema_name
)
SELECT
    schema_name,
    test_recency_bucket,
    column_count,
    untested_columns
FROM schema_summary
ORDER BY
    schema_name,
    CASE test_recency_bucket
        WHEN 'Last 24h' THEN 1
        WHEN 'Last Week' THEN 2
        WHEN 'Stale (>7d)' THEN 3
        ELSE 4
    END;

-- Business Case: Role-Based Data Domain Access Heatmap
-- Purpose: Understand cross-role engagement with business domains
-- Why It Matters:
-- - Detects over-permissioned users
-- - Validates role design assumptions
-- - Supports RBAC refinement and policy automation
CREATE OR REPLACE VIEW role_domain_engagement_heatmap AS
WITH user_role_names AS (
    SELECT
        ur.user_id,
        r.role_name
    FROM user_roles ur
    JOIN roles r ON ur.role_id = r.role_id
)
SELECT
    urn.role_name,
    dp.domain,
    COUNT(*) AS access_count,
    COUNT(DISTINCT al.user_id) AS unique_users,
    CASE
        WHEN COUNT(*) > 1000 THEN 'Very High'
        WHEN COUNT(*) > 100 THEN 'High'
        WHEN COUNT(*) > 10 THEN 'Medium'
        ELSE 'Low'
    END AS engagement_level
FROM access_logs al
JOIN user_role_names urn ON al.user_id = urn.user_id
JOIN columns c ON al.column_id = c.column_id
-- Correct path: go through data_product_components
JOIN data_product_components dpc ON c.column_id = dpc.column_id
JOIN data_products dp ON dpc.product_id = dp.product_id
GROUP BY
    urn.role_name,
    dp.domain
HAVING COUNT(*) > 0
ORDER BY
    urn.role_name,
    access_count DESC;

-- to detect over permissioned roles 

SELECT *
FROM role_domain_engagement_heatmap
WHERE role_name IN ('analyst', 'engineer')
  AND domain = 'Finance'
  AND engagement_level = 'Very High';
  
  
-- Business Case: Over-Permissioned Roles & Users
-- Purpose: Identify users assigned to roles with broad or risky access patterns, especially to sensitive data
-- Why It Matters:
-- - Supports least-privilege security model
-- - Enables quarterly access reviews and SOX/GDPR compliance
-- - Highlights candidates for role refinement or deprovisioning
CREATE OR REPLACE VIEW over_permissioned_roles_and_users AS
WITH sensitive_columns AS (
    -- Get all columns tagged as PII, PHI, PCI, SECRET, etc.
    SELECT DISTINCT c.column_id
    FROM columns c
    JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
    JOIN search_tags st ON ctm.tag_id = st.tag_id
    WHERE st.tag_category IN ('PII', 'PHI', 'PCI', 'SECRET', 'CONFIDENTIAL')
),
role_sensitive_access_stats AS (
    -- For each role, calculate how many sensitive columns its users accessed
    SELECT
        r.role_id,
        r.role_name,
        COUNT(DISTINCT al.column_id) AS unique_sensitive_columns_accessed,
        COUNT(al.log_id) AS total_sensitive_access_events,
        COUNT(DISTINCT al.user_id) AS user_count_in_role,
        ROUND(
            AVG(EXTRACT(EPOCH FROM (al.accessed_at - '2000-01-01')))::NUMERIC,
            0
        ) AS avg_access_timestamp_epoch -- proxy for recency/frequency
    FROM roles r
    JOIN user_roles ur ON r.role_id = ur.role_id
    JOIN access_logs al ON ur.user_id = al.user_id
    JOIN sensitive_columns sc ON al.column_id = sc.column_id
    GROUP BY r.role_id, r.role_name
    HAVING COUNT(al.log_id) > 50 -- Only roles with significant access
       AND COUNT(DISTINCT al.column_id) > 5 -- Accessed more than 5 sensitive columns
),
over_permissive_roles AS (
    -- Flag roles with unusually high access volume
    SELECT *,
           PERCENT_RANK() OVER (ORDER BY unique_sensitive_columns_accessed DESC) AS exposure_rank
    FROM role_sensitive_access_stats
    WHERE unique_sensitive_columns_accessed > (
        SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY unique_sensitive_columns_accessed)
        FROM role_sensitive_access_stats
    )
)
SELECT
    opr.role_id,
    opr.role_name,
    opr.unique_sensitive_columns_accessed,
    opr.total_sensitive_access_events,
    opr.user_count_in_role,
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    u.email,
    ur.assigned_at AS user_assigned_to_role_at,
    CASE
        WHEN opr.exposure_rank > 0.9 THEN 'Critical'
        WHEN opr.exposure_rank > 0.7 THEN 'High'
        ELSE 'Moderate'
    END AS risk_level
FROM over_permissive_roles opr
JOIN user_roles ur ON opr.role_id = ur.role_id
JOIN users u ON ur.user_id = u.user_id
ORDER BY
    opr.exposure_rank DESC,
    opr.total_sensitive_access_events DESC,
    u.last_name,
    u.first_name;
	
	
-- Business Case: Recently Over-Permissioned Roles & Users
-- Purpose: Identify users in roles with excessive access to sensitive data over a recent time window
-- Why It Matters:
-- - Focuses review efforts on current risks
-- - Supports monthly/quarterly access certifications
-- - Reduces noise from stale or historical access
-- Additional Information:
-- - Filters access_logs to last 30 days
-- - Flags roles with high volume and breadth of sensitive access
CREATE OR REPLACE VIEW over_permissioned_roles_and_users_recent AS
WITH recent_sensitive_access AS (
    -- Find accesses to PII/PHI/PCI columns in the last 30 days
    SELECT DISTINCT
        al.user_id,
        al.column_id
    FROM access_logs al
    JOIN columns c ON al.column_id = c.column_id
    JOIN column_tag_mapping ctm ON c.column_id = ctm.column_id
    JOIN search_tags st ON ctm.tag_id = st.tag_id
    WHERE st.tag_category IN ('PII', 'PHI', 'PCI', 'SECRET', 'CONFIDENTIAL')
      AND al.accessed_at >= NOW() - INTERVAL '30 days'
),
role_sensitive_stats AS (
    -- Aggregate per-role risk metrics
    SELECT
        r.role_id,
        r.role_name,
        COUNT(DISTINCT rsa.column_id) AS unique_sensitive_columns_accessed,
        COUNT(rsa.user_id) AS total_access_events,
        COUNT(DISTINCT rsa.user_id) AS user_count
    FROM roles r
    JOIN user_roles ur ON r.role_id = ur.role_id
    JOIN recent_sensitive_access rsa ON ur.user_id = rsa.user_id
    GROUP BY r.role_id, r.role_name
    HAVING COUNT(DISTINCT rsa.column_id) > 5  -- Accessed many sensitive fields
       AND COUNT(rsa.user_id) > 10           -- High frequency
),
high_risk_roles AS (
    -- Rank roles by exposure
    SELECT *,
           PERCENT_RANK() OVER (ORDER BY unique_sensitive_columns_accessed DESC) AS exposure_rank
    FROM role_sensitive_stats
    WHERE unique_sensitive_columns_accessed > (
        SELECT COALESCE(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY unique_sensitive_columns_accessed), 0)
        FROM role_sensitive_stats
    )
)
SELECT
    hrr.role_id,
    hrr.role_name,
    hrr.unique_sensitive_columns_accessed,
    hrr.total_access_events,
    hrr.user_count,
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    u.email,
    ur.assigned_at AS assigned_to_role_at,
    CASE
        WHEN hrr.exposure_rank > 0.9 THEN 'Critical'
        WHEN hrr.exposure_rank > 0.7 THEN 'High'
        ELSE 'Moderate'
    END AS risk_level
FROM high_risk_roles hrr
JOIN user_roles ur ON hrr.role_id = ur.role_id
JOIN users u ON ur.user_id = u.user_id
ORDER BY
    hrr.exposure_rank DESC,
    hrr.total_access_events DESC,
    u.last_name,
    u.first_name;
	

-- Business Case: Users with Policy Violations
-- Purpose: List all users who violated data usage policies, including context and assigned roles
-- Why It Matters:
-- - Enables incident response and remediation workflows
-- - Supports audit trails and compliance reporting (GDPR, SOX, HIPAA)
-- - Helps identify repeat offenders or systemic access issues
-- Additional Information:
-- - Joins violations with user roles, ownership, and sensitivity tags
-- - Aggregates user roles for complete risk assessment
-- - Safe against missing reviewed_by or full names
CREATE OR REPLACE VIEW users_with_policy_violations AS
SELECT
    pv.violation_id,
    pv.operation,
    pv.attempted_at,
    pv.was_blocked,
    pv.review_status,
    pv.review_notes,

    -- User Identity
    u.user_id,
    COALESCE(u.first_name || ' ' || u.last_name, u.email) AS user_name,
    u.email,

    -- Roles Assigned to User
    STRING_AGG(DISTINCT r.role_name, ', ') FILTER (WHERE r.role_name IS NOT NULL) AS user_roles,

    -- Target Column & Table Context
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,

    -- Policy Details
    up.policy_name,
    up.description AS policy_description,
    up.enforcement_action,
    up.allowed_operations,

    -- Violation Details
    pv.violation_details,

    -- Reviewer Info (if any)
    COALESCE(
        reviewer.first_name || ' ' || reviewer.last_name,
        reviewer.email
    ) AS reviewed_by_name,

    -- Timestamps
    pv.created_at,
    pv.updated_at

FROM policy_violations pv

-- Join to get user info
JOIN users u ON pv.user_id = u.user_id

-- Join to get policy details
JOIN usage_policies up ON pv.policy_id = up.policy_id

-- Join to get column/table/database context
JOIN columns c ON pv.column_id = c.column_id
JOIN tables t ON c.table_id = t.table_id
JOIN schemas s ON t.schema_id = s.schema_id
JOIN databases d ON s.database_id = d.database_id

-- Optional: Get reviewer name if reviewed
LEFT JOIN users reviewer ON pv.reviewed_by = reviewer.user_id

-- Optional: Get all roles for the violating user
LEFT JOIN user_roles ur ON u.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id

-- Group so we can aggregate roles per violation
GROUP BY
    pv.violation_id,
    pv.operation,
    pv.attempted_at,
    pv.was_blocked,
    pv.review_status,
    pv.review_notes,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    c.column_name,
    t.table_name,
    s.schema_name,
    d.database_name,
    up.policy_name,
    up.description,
    up.enforcement_action,
    up.allowed_operations,
    pv.violation_details,
    reviewer.first_name,
    reviewer.last_name,
    reviewer.email,
    pv.created_at,
    pv.updated_at

-- Order by most recent violations first
ORDER BY
    pv.attempted_at DESC,
    pv.review_status,
    s.schema_name,
    t.table_name;
