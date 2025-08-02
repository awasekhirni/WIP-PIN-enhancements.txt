--2025 β ORI Inc.Canada All Rights Reserved.
-- PostgreSQL Schema for All-in-One Marketing & CRM Operating System
-- Version: 1.0
-- Created: 2025-05-25
-- Author: Awase Khirni Syed, Simra Fathima Syed
-- this was built to support my daughter in her business accounting course inturn it would help my own company
-- extended the functionality to scale it to the enterprise thanks to a lot of CPA's for giving inputs


-- Create the main accounting schema
CREATE SCHEMA enterprise_cpa;

SET search_path TO enterprise_cpa;


-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "ltree";

-- ENUM types for various statuses and categories
CREATE TYPE user_role AS ENUM (
    'system_admin',
    'tenant_admin',
    'cfo',
    'controller',
    'finance_director',
    'auditor',
    'tax_advisor',
    'compliance_officer',
    'board_member',
    'executive',
    'analyst',
    'support_staff'
);

CREATE TYPE audit_status AS ENUM (
    'planned',
    'in_progress',
    'completed',
    'reported',
    'remediated'
);

CREATE TYPE tax_type AS ENUM (
    'vat',
    'gst',
    'corporate',
    'withholding',
    'sales',
    'property',
    'payroll',
    'customs',
    'excise',
    'other'
);

CREATE TYPE filing_status AS ENUM (
    'draft',
    'submitted',
    'approved',
    'rejected',
    'amended'
);

CREATE TYPE risk_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

CREATE TYPE document_type AS ENUM (
    'financial_statement',
    'tax_return',
    'audit_report',
    'invoice',
    'contract',
    'policy',
    'presentation',
    'other'
);

CREATE TYPE notification_type AS ENUM (
    'deadline',
    'alert',
    'message',
    'task',
    'approval',
    'system'
);

CREATE TYPE integration_type AS ENUM (
    'erp',
    'banking',
    'government',
    'document',
    'bi',
    'hr',
    'crm',
    'other'
);

CREATE TYPE subscription_tier AS ENUM (
    'standard',
    'professional',
    'enterprise'
);

-- Core tables
CREATE TABLE tenants (
    tenant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    tax_id VARCHAR(100),
    industry VARCHAR(100),
    revenue_band VARCHAR(50),
    employee_count_band VARCHAR(50),
    founded_date DATE,
    website VARCHAR(255),
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    default_currency CHAR(3) NOT NULL DEFAULT 'USD',
    subscription_tier subscription_tier NOT NULL DEFAULT 'standard',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    onboarding_date TIMESTAMP WITH TIME ZONE,
    logo_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL,
    department VARCHAR(100),
    job_title VARCHAR(100),
    phone VARCHAR(50),
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    profile_picture_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    token TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_id VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE legal_entities (
    entity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    parent_entity_id UUID REFERENCES legal_entities(entity_id),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(100),
    jurisdiction VARCHAR(100) NOT NULL,
    incorporation_date DATE,
    legal_form VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    accounting_standard VARCHAR(50) NOT NULL, -- IFRS, US GAAP, etc.
    functional_currency CHAR(3) NOT NULL,
    fiscal_year_start DATE NOT NULL,
    fiscal_year_end DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Financial Reporting & Compliance Module
CREATE TABLE chart_of_accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    parent_account_id UUID REFERENCES chart_of_accounts(account_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, account_code)
);

CREATE TABLE financial_periods (
    period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    close_date TIMESTAMP WITH TIME ZONE,
    closed_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_name)
);

CREATE TABLE financial_statements (
    statement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    statement_type VARCHAR(50) NOT NULL, -- Balance Sheet, Income Statement, Cash Flow, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    reporting_standard VARCHAR(50) NOT NULL, -- IFRS, GAAP, etc.
    currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(19, 6),
    prepared_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    approved_by UUID REFERENCES users(user_id),
    prepared_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE financial_statement_lines (
    line_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    statement_id UUID NOT NULL REFERENCES financial_statements(statement_id),
    account_id UUID NOT NULL REFERENCES chart_of_accounts(account_id),
    line_item VARCHAR(255) NOT NULL,
    amount DECIMAL(19, 4) NOT NULL,
    line_order INTEGER NOT NULL,
    is_calculated BOOLEAN NOT NULL DEFAULT FALSE,
    calculation_formula TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE regulatory_filings (
    filing_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    filing_type VARCHAR(100) NOT NULL, -- SEC, ESEF, XBRL, etc.
    jurisdiction VARCHAR(100) NOT NULL,
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    due_date DATE NOT NULL,
    submission_date DATE,
    status filing_status NOT NULL DEFAULT 'draft',
    filing_reference VARCHAR(255),
    document_id UUID, -- Reference to documents table
    prepared_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    submitted_by UUID REFERENCES users(user_id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE filing_deadlines (
    deadline_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id), -- NULL for tenant-wide deadlines
    filing_type VARCHAR(100) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    periodicity VARCHAR(50) NOT NULL, -- monthly, quarterly, annually, etc.
    days_before_due INTEGER NOT NULL DEFAULT 0, -- For recurring deadlines
    fixed_date DATE, -- For one-time deadlines
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tax Advisory & Compliance Module
CREATE TABLE tax_calculations (
    calculation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    tax_type tax_type NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    taxable_amount DECIMAL(19, 4) NOT NULL,
    tax_rate DECIMAL(7, 4) NOT NULL,
    tax_amount DECIMAL(19, 4) NOT NULL,
    calculation_date DATE NOT NULL,
    is_estimated BOOLEAN NOT NULL DEFAULT FALSE,
    is_final BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_filings (
    filing_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    tax_type tax_type NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    due_date DATE NOT NULL,
    submission_date DATE,
    status filing_status NOT NULL DEFAULT 'draft',
    filing_reference VARCHAR(255),
    tax_amount DECIMAL(19, 4),
    penalty_amount DECIMAL(19, 4),
    interest_amount DECIMAL(19, 4),
    payment_date DATE,
    document_id UUID, -- Reference to documents table
    prepared_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    submitted_by UUID REFERENCES users(user_id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_scenarios (
    scenario_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    scenario_name VARCHAR(255) NOT NULL,
    description TEXT,
    base_period_id UUID REFERENCES financial_periods(period_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_scenario_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_id UUID NOT NULL REFERENCES tax_scenarios(scenario_id),
    tax_type tax_type NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    taxable_amount DECIMAL(19, 4) NOT NULL,
    tax_rate DECIMAL(7, 4) NOT NULL,
    tax_amount DECIMAL(19, 4) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Internal Audit & Risk Management Module
CREATE TABLE risk_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id), -- NULL for tenant-wide assessments
    assessment_name VARCHAR(255) NOT NULL,
    assessment_date DATE NOT NULL,
    framework VARCHAR(100), -- ISO 31000, COSO, etc.
    next_assessment_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    conducted_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    approved_by UUID REFERENCES users(user_id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE risk_items (
    risk_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES risk_assessments(assessment_id),
    risk_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    inherent_risk risk_level NOT NULL,
    residual_risk risk_level,
    control_effectiveness VARCHAR(50),
    mitigation_plan TEXT,
    owner_id UUID REFERENCES users(user_id),
    target_date DATE,
    completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id), -- NULL for tenant-wide plans
    plan_name VARCHAR(255) NOT NULL,
    fiscal_year INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_engagements (
    engagement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES audit_plans(plan_id),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    engagement_name VARCHAR(255) NOT NULL,
    audit_type VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status audit_status NOT NULL DEFAULT 'planned',
    lead_auditor_id UUID REFERENCES users(user_id),
    scope TEXT NOT NULL,
    objectives TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_findings (
    finding_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    engagement_id UUID NOT NULL REFERENCES audit_engagements(engagement_id),
    finding_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    risk_level risk_level NOT NULL,
    category VARCHAR(100) NOT NULL,
    recommendation TEXT NOT NULL,
    action_plan TEXT,
    owner_id UUID REFERENCES users(user_id),
    target_date DATE,
    completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_evidence (
    evidence_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    finding_id UUID NOT NULL REFERENCES audit_findings(finding_id),
    document_id UUID, -- Reference to documents table
    evidence_type VARCHAR(100) NOT NULL,
    description TEXT,
    collected_by UUID REFERENCES users(user_id),
    collection_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Business Advisory Services Module
CREATE TABLE financial_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    plan_name VARCHAR(255) NOT NULL,
    plan_type VARCHAR(100) NOT NULL, -- Strategic, Operational, Budget, Forecast
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    base_currency CHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE financial_plan_lines (
    line_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES financial_plans(plan_id),
    account_id UUID REFERENCES chart_of_accounts(account_id),
    line_item VARCHAR(255) NOT NULL,
    period_date DATE NOT NULL,
    amount DECIMAL(19, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(19, 6),
    is_calculated BOOLEAN NOT NULL DEFAULT FALSE,
    calculation_formula TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_a_projects (
    project_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    project_name VARCHAR(255) NOT NULL,
    project_code VARCHAR(50),
    deal_type VARCHAR(100) NOT NULL, -- Merger, Acquisition, Divestiture, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'planning',
    target_name VARCHAR(255),
    target_industry VARCHAR(100),
    target_revenue DECIMAL(19, 4),
    target_employees INTEGER,
    deal_size DECIMAL(19, 4),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    expected_close_date DATE,
    actual_close_date DATE,
    lead_advisor_id UUID REFERENCES users(user_id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE m_a_due_diligence (
    diligence_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES m_a_projects(project_id),
    area VARCHAR(100) NOT NULL, -- Financial, Legal, Tax, Operational, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    lead_reviewer_id UUID REFERENCES users(user_id),
    start_date DATE,
    end_date DATE,
    findings_summary TEXT,
    risk_assessment risk_level,
    recommendation TEXT,
    document_id UUID, -- Reference to documents table
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_data (
    esg_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL, -- 2023, Q1 2023, etc.
    reporting_standard VARCHAR(100), -- GRI, SASB, TCFD, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    prepared_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    approved_by UUID REFERENCES users(user_id),
    prepared_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    esg_id UUID NOT NULL REFERENCES esg_data(esg_id),
    metric_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- Environmental, Social, Governance
    subcategory VARCHAR(100),
    value DECIMAL(19, 4),
    unit VARCHAR(50),
    data_source TEXT,
    verification_status VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Payroll & HR Advisory Module
CREATE TABLE payroll_runs (
    payroll_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    payroll_name VARCHAR(255) NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end DATE NOT NULL,
    payment_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    total_gross DECIMAL(19, 4) NOT NULL DEFAULT 0,
    total_net DECIMAL(19, 4) NOT NULL DEFAULT 0,
    total_tax DECIMAL(19, 4) NOT NULL DEFAULT 0,
    total_deductions DECIMAL(19, 4) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL,
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payroll_employees (
    payroll_employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll_runs(payroll_id),
    employee_id VARCHAR(100) NOT NULL, -- External ID from HR system
    employee_name VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    department VARCHAR(100),
    gross_pay DECIMAL(19, 4) NOT NULL,
    tax_amount DECIMAL(19, 4) NOT NULL,
    deductions DECIMAL(19, 4) NOT NULL DEFAULT 0,
    net_pay DECIMAL(19, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    bank_account VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payslip_document_id UUID, -- Reference to documents table
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compensation_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    plan_name VARCHAR(255) NOT NULL,
    plan_year INTEGER NOT NULL,
    plan_type VARCHAR(100) NOT NULL, -- Executive, Management, Staff, etc.
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compensation_structures (
    structure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES compensation_plans(plan_id),
    position_level VARCHAR(100) NOT NULL,
    base_salary_min DECIMAL(19, 4) NOT NULL,
    base_salary_max DECIMAL(19, 4) NOT NULL,
    bonus_target_pct DECIMAL(5, 2),
    equity_target_pct DECIMAL(5, 2),
    benefits_value DECIMAL(19, 4),
    currency CHAR(3) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Treasury & Cash Flow Management Module
CREATE TABLE bank_accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    account_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(100),
    bank_name VARCHAR(255) NOT NULL,
    bank_code VARCHAR(100),
    branch_code VARCHAR(100),
    currency CHAR(3) NOT NULL,
    account_type VARCHAR(100) NOT NULL, -- Checking, Savings, etc.
    opening_balance DECIMAL(19, 4) NOT NULL,
    opening_date DATE NOT NULL,
    current_balance DECIMAL(19, 4) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    online_access BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cashflow_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    forecast_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    base_currency CHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    scenario_type VARCHAR(100) NOT NULL DEFAULT 'base', -- base, optimistic, pessimistic
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cashflow_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_id UUID NOT NULL REFERENCES cashflow_forecasts(forecast_id),
    item_date DATE NOT NULL,
    item_type VARCHAR(50) NOT NULL, -- inflow, outflow
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(19, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(19, 6),
    bank_account_id UUID REFERENCES bank_accounts(account_id),
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fx_exposures (
    exposure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    exposure_date DATE NOT NULL,
    base_currency CHAR(3) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fx_exposure_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exposure_id UUID NOT NULL REFERENCES fx_exposures(exposure_id),
    foreign_currency CHAR(3) NOT NULL,
    amount DECIMAL(19, 4) NOT NULL,
    exchange_rate DECIMAL(19, 6) NOT NULL,
    equivalent_amount DECIMAL(19, 4) NOT NULL,
    exposure_type VARCHAR(100) NOT NULL, -- receivable, payable, etc.
    due_date DATE,
    hedge_status VARCHAR(50), -- hedged, unhedged, partially hedged
    hedge_instrument VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Digital Collaboration Hub
CREATE TABLE documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    document_name VARCHAR(255) NOT NULL,
    document_type document_type NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    version VARCHAR(50) NOT NULL DEFAULT '1.0',
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    previous_version_id UUID REFERENCES documents(document_id),
    uploaded_by UUID REFERENCES users(user_id),
    upload_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    encryption_key_id VARCHAR(255),
    expiry_date DATE,
    access_level VARCHAR(50) NOT NULL DEFAULT 'restricted',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE document_access (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(document_id),
    user_id UUID REFERENCES users(user_id),
    access_type VARCHAR(50) NOT NULL, -- view, edit, download, etc.
    granted_by UUID REFERENCES users(user_id),
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    priority VARCHAR(50) NOT NULL DEFAULT 'medium',
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    assigned_to UUID REFERENCES users(user_id),
    assigned_by UUID REFERENCES users(user_id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    related_entity_type VARCHAR(100), -- filing, audit, etc.
    related_entity_id UUID, -- ID of the related entity
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(task_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(task_id),
    document_id UUID NOT NULL REFERENCES documents(document_id),
    uploaded_by UUID REFERENCES users(user_id),
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    sender_id UUID NOT NULL REFERENCES users(user_id),
    subject VARCHAR(255) NOT NULL,
    message_text TEXT NOT NULL,
    is_urgent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE message_recipients (
    recipient_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(message_id),
    recipient_user_id UUID NOT NULL REFERENCES users(user_id),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE message_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(message_id),
    document_id UUID NOT NULL REFERENCES documents(document_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(100),
    related_entity_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE calendar_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    event_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_all_day BOOLEAN NOT NULL DEFAULT FALSE,
    location VARCHAR(255),
    organizer_id UUID REFERENCES users(user_id),
    related_entity_type VARCHAR(100),
    related_entity_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE event_attendees (
    attendee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES calendar_events(event_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    response_status VARCHAR(50) NOT NULL DEFAULT 'needs_action', -- accepted, declined, tentative
    response_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE client_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    layout_config JSONB NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES client_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL,
    widget_title VARCHAR(255) NOT NULL,
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER, -- in minutes
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dashboard_access (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES client_dashboards(dashboard_id),
    user_id UUID REFERENCES users(user_id),
    role_id UUID, -- Reference to roles if using role-based access
    access_level VARCHAR(50) NOT NULL, -- view, edit, manage
    granted_by UUID REFERENCES users(user_id),
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Expert Network Access
CREATE TABLE experts (
    expert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID REFERENCES users(user_id), -- NULL for external experts
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    expertise_area VARCHAR(100) NOT NULL,
    qualifications TEXT,
    experience_years INTEGER,
    hourly_rate DECIMAL(10, 2),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    profile_picture_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expert_availability (
    availability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expert_id UUID NOT NULL REFERENCES experts(expert_id),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expert_engagements (
    engagement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    expert_id UUID NOT NULL REFERENCES experts(expert_id),
    engagement_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    estimated_hours DECIMAL(5, 2),
    actual_hours DECIMAL(5, 2),
    rate DECIMAL(10, 2),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    total_cost DECIMAL(10, 2),
    related_entity_type VARCHAR(100),
    related_entity_id UUID,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expert_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    engagement_id UUID NOT NULL REFERENCES expert_engagements(engagement_id),
    session_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL,
    notes TEXT,
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE knowledge_base (
    article_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    tags TEXT[],
    author_id UUID REFERENCES users(user_id),
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    view_count INTEGER NOT NULL DEFAULT 0,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE knowledge_base_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES knowledge_base(article_id),
    document_id UUID NOT NULL REFERENCES documents(document_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_assistant_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID REFERENCES users(user_id),
    session_id VARCHAR(255) NOT NULL,
    query_text TEXT NOT NULL,
    response_text TEXT,
    intent VARCHAR(100),
    confidence_score DECIMAL(5, 4),
    response_time_ms INTEGER,
    is_successful BOOLEAN NOT NULL DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Analytics & Insights Engine
CREATE TABLE kpi_definitions (
    kpi_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    kpi_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    calculation_formula TEXT NOT NULL,
    preferred_visualization VARCHAR(100),
    target_value DECIMAL(19, 4),
    target_direction VARCHAR(50), -- higher, lower, neutral
    unit VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE kpi_values (
    value_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES kpi_definitions(kpi_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    actual_value DECIMAL(19, 4) NOT NULL,
    target_value DECIMAL(19, 4),
    benchmark_value DECIMAL(19, 4),
    variance_pct DECIMAL(7, 4),
    notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE benchmark_data (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES kpi_definitions(kpi_id),
    industry VARCHAR(100) NOT NULL,
    geography VARCHAR(100),
    company_size VARCHAR(50),
    benchmark_value DECIMAL(19, 4) NOT NULL,
    benchmark_year INTEGER NOT NULL,
    source VARCHAR(255) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE predictive_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    model_name VARCHAR(255) NOT NULL,
    description TEXT,
    model_type VARCHAR(100) NOT NULL,
    target_kpi_id UUID REFERENCES kpi_definitions(kpi_id),
    status VARCHAR(50) NOT NULL DEFAULT 'development',
    training_data_range_start DATE,
    training_data_range_end DATE,
    last_trained_at TIMESTAMP WITH TIME ZONE,
    accuracy_score DECIMAL(5, 4),
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE model_predictions (
    prediction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES predictive_models(model_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    prediction_date DATE NOT NULL,
    predicted_value DECIMAL(19, 4) NOT NULL,
    confidence_interval_lower DECIMAL(19, 4),
    confidence_interval_upper DECIMAL(19, 4),
    actual_value DECIMAL(19, 4),
    is_actual BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE anomaly_detections (
    anomaly_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    detection_date TIMESTAMP WITH TIME ZONE NOT NULL,
    anomaly_type VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(255),
    transaction_date DATE,
    amount DECIMAL(19, 4),
    currency CHAR(3),
    expected_range_lower DECIMAL(19, 4),
    expected_range_upper DECIMAL(19, 4),
    confidence_score DECIMAL(5, 4) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'new',
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Integration & API Management
CREATE TABLE integrations (
    integration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    integration_name VARCHAR(255) NOT NULL,
    integration_type integration_type NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    auth_type VARCHAR(100) NOT NULL,
    base_url TEXT,
    api_key_encrypted TEXT,
    client_id_encrypted TEXT,
    client_secret_encrypted TEXT,
    oauth_token_encrypted TEXT,
    oauth_refresh_token_encrypted TEXT,
    token_expiry TIMESTAMP WITH TIME ZONE,
    last_sync TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(50),
    config JSONB,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE integration_mappings (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID NOT NULL REFERENCES integrations(integration_id),
    source_field VARCHAR(255) NOT NULL,
    target_field VARCHAR(255) NOT NULL,
    transformation_rule TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE integration_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    integration_id UUID NOT NULL REFERENCES integrations(integration_id),
    log_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    operation VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    record_count INTEGER,
    duration_ms INTEGER,
    error_message TEXT,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE api_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    key_name VARCHAR(255) NOT NULL,
    api_key_encrypted TEXT NOT NULL,
    scopes TEXT[] NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Security & Access Control
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, role_name)
);

CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
    role_permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    permission_id UUID NOT NULL REFERENCES permissions(permission_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    assigned_by UUID REFERENCES users(user_id),
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, role_id)
);

CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_details JSONB,
    status VARCHAR(50) NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE data_encryption_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    key_name VARCHAR(255) NOT NULL,
    key_type VARCHAR(50) NOT NULL,
    key_encrypted TEXT NOT NULL,
    key_version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    rotation_policy VARCHAR(100) NOT NULL,
    last_rotated_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- System Configuration
CREATE TABLE system_settings (
    setting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    setting_name VARCHAR(255) NOT NULL,
    setting_value TEXT NOT NULL,
    data_type VARCHAR(50) NOT NULL, -- string, number, boolean, json
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, setting_name)
);

CREATE TABLE email_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    template_name VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    variables TEXT[],
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, template_name)
);

CREATE TABLE workflows (
    workflow_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    workflow_name VARCHAR(255) NOT NULL,
    description TEXT,
    trigger_event VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workflow_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES workflows(workflow_id),
    step_name VARCHAR(255) NOT NULL,
    step_type VARCHAR(100) NOT NULL,
    action_name VARCHAR(255) NOT NULL,
    action_config JSONB,
    step_order INTEGER NOT NULL,
    on_success_step_id UUID REFERENCES workflow_steps(step_id),
    on_failure_step_id UUID REFERENCES workflow_steps(step_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workflow_executions (
    execution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES workflows(workflow_id),
    trigger_event VARCHAR(255) NOT NULL,
    trigger_data JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'running',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workflow_execution_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES workflow_executions(execution_id),
    step_id UUID NOT NULL REFERENCES workflow_steps(step_id),
    status VARCHAR(50) NOT NULL,
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    duration_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- AI & Smart Features
CREATE TABLE ml_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(100) NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'development',
    training_data_query TEXT,
    features TEXT[] NOT NULL,
    target_variable VARCHAR(100) NOT NULL,
    performance_metrics JSONB,
    deployed_at TIMESTAMP WITH TIME ZONE,
    deployed_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE model_predictions_log (
    prediction_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES ml_models(model_id),
    input_data JSONB NOT NULL,
    prediction_output JSONB NOT NULL,
    confidence_score DECIMAL(5, 4),
    is_correct BOOLEAN,
    feedback TEXT,
    predicted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_classification_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    description TEXT,
    match_conditions JSONB NOT NULL,
    category VARCHAR(100) NOT NULL,
    gl_account_id UUID REFERENCES chart_of_accounts(account_id),
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_classification_log (
    classification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    transaction_id VARCHAR(255) NOT NULL,
    transaction_date DATE NOT NULL,
    original_description TEXT NOT NULL,
    amount DECIMAL(19, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    predicted_category VARCHAR(100) NOT NULL,
    predicted_gl_account_id UUID REFERENCES chart_of_accounts(account_id),
    confidence_score DECIMAL(5, 4) NOT NULL,
    applied_rule_id UUID REFERENCES transaction_classification_rules(rule_id),
    is_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_by UUID REFERENCES users(user_id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    final_category VARCHAR(100),
    final_gl_account_id UUID REFERENCES chart_of_accounts(account_id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--blockchain based audit trail
CREATE TABLE blockchain_audit_trail (
    block_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_hash VARCHAR(255) NOT NULL UNIQUE,
    previous_hash VARCHAR(255),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    action_type VARCHAR(100) NOT NULL,
    action_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    action_details JSONB NOT NULL,
    merkle_root VARCHAR(255),
    blockchain_network VARCHAR(100) NOT NULL,
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    confirmation_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_blockchain_audit_tenant_entity ON blockchain_audit_trail(tenant_id, entity_id);
CREATE INDEX idx_blockchain_audit_timestamp ON blockchain_audit_trail(action_timestamp);


--regulatory change management system
CREATE TABLE regulatory_authorities (
    authority_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    authority_name VARCHAR(255) NOT NULL,
    jurisdiction VARCHAR(100) NOT NULL,
    website_url VARCHAR(255),
    api_endpoint VARCHAR(255),
    contact_email VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE regulatory_changes (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    authority_id UUID NOT NULL REFERENCES regulatory_authorities(authority_id),
    reference_number VARCHAR(100) NOT NULL,
    change_title VARCHAR(255) NOT NULL,
    change_description TEXT NOT NULL,
    effective_date DATE NOT NULL,
    announcement_date DATE NOT NULL,
    compliance_deadline DATE,
    change_type VARCHAR(100) NOT NULL, -- tax, reporting, esg, etc.
    impact_level VARCHAR(50) NOT NULL, -- high, medium, low
    affected_industries VARCHAR(255)[],
    affected_countries VARCHAR(100)[],
    document_url VARCHAR(255),
    is_major_change BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE regulatory_change_impacts (
    impact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    change_id UUID NOT NULL REFERENCES regulatory_changes(change_id),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id), -- NULL for tenant-wide impact
    impact_assessment VARCHAR(50) NOT NULL, -- high, medium, low, none
    action_required BOOLEAN NOT NULL,
    action_deadline DATE,
    action_owner_id UUID REFERENCES users(user_id),
    action_status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    action_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_regulatory_changes_effective_date ON regulatory_changes(effective_date);
CREATE INDEX idx_regulatory_changes_jurisdiction ON regulatory_changes(affected_countries);



--enhanced ESG and sustainability tracking
CREATE TABLE esg_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_name VARCHAR(100) NOT NULL,
    framework_owner VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(50) NOT NULL,
    reporting_requirements JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_supply_chain (
    supply_chain_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    vendor_id VARCHAR(255) NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    tier INTEGER NOT NULL, -- 1 for direct suppliers, 2 for suppliers' suppliers, etc.
    industry VARCHAR(100),
    country VARCHAR(100),
    esg_risk_score DECIMAL(5,2),
    last_assessment_date DATE,
    assessment_document_id UUID REFERENCES documents(document_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE carbon_footprint (
    footprint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    scope_1_emissions DECIMAL(19,4), -- Direct emissions
    scope_2_emissions DECIMAL(19,4), -- Indirect emissions from purchased energy
    scope_3_emissions DECIMAL(19,4), -- Other indirect emissions
    total_emissions DECIMAL(19,4) GENERATED ALWAYS AS (COALESCE(scope_1_emissions,0) + COALESCE(scope_2_emissions,0) + COALESCE(scope_3_emissions,0)) STORED,
    revenue DECIMAL(19,4),
    intensity_ratio DECIMAL(19,4) GENERATED ALWAYS AS (CASE WHEN revenue > 0 THEN total_emissions/revenue ELSE NULL END) STORED,
    verification_status VARCHAR(100),
    verified_by VARCHAR(255),
    verification_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--advanced fraud detection system
CREATE TABLE fraud_detection_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(100) NOT NULL, -- anomaly, rules, hybrid
    version VARCHAR(50) NOT NULL,
    training_data_range_start DATE NOT NULL,
    training_data_range_end DATE NOT NULL,
    detection_metrics JSONB NOT NULL,
    precision DECIMAL(5,4) NOT NULL,
    recall DECIMAL(5,4) NOT NULL,
    f1_score DECIMAL(5,4) NOT NULL,
    threshold DECIMAL(5,4) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fraud_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    model_id UUID REFERENCES fraud_detection_models(model_id),
    alert_type VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(255),
    transaction_date DATE,
    transaction_amount DECIMAL(19,4),
    transaction_currency CHAR(3),
    parties_involved JSONB,
    risk_score DECIMAL(5,4) NOT NULL,
    indicators JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'new',
    assigned_to UUID REFERENCES users(user_id),
    investigation_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_code VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fraud_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    pattern_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    detection_rules JSONB NOT NULL,
    risk_level risk_level NOT NULL,
    common_in_industry VARCHAR(100),
    mitigation_strategy TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--multijurisdictional compliance engine
CREATE TABLE compliance_jurisdictions (
    jurisdiction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_code CHAR(2) NOT NULL,
    region VARCHAR(100),
    compliance_area VARCHAR(100) NOT NULL, -- tax, reporting, labor, etc.
    authority_name VARCHAR(255) NOT NULL,
    reporting_requirements JSONB NOT NULL,
    filing_frequency VARCHAR(50) NOT NULL,
    electronic_filing BOOLEAN NOT NULL,
    api_available BOOLEAN NOT NULL,
    standard_forms JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (country_code, region, compliance_area)
);

CREATE TABLE entity_compliance_mapping (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES compliance_jurisdictions(jurisdiction_id),
    compliance_lead_id UUID REFERENCES users(user_id),
    local_advisor_id UUID REFERENCES experts(expert_id),
    filing_currency CHAR(3) NOT NULL,
    fiscal_year_end DATE NOT NULL,
    last_review_date DATE,
    next_review_date DATE,
    compliance_status VARCHAR(50) NOT NULL DEFAULT 'compliant',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cross_border_tax_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_country CHAR(2) NOT NULL,
    destination_country CHAR(2) NOT NULL,
    tax_type VARCHAR(100) NOT NULL,
    treaty_name VARCHAR(255),
    treaty_article VARCHAR(100),
    withholding_rate DECIMAL(5,2),
    documentation_requirements TEXT,
    effective_date DATE NOT NULL,
    expiration_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--AI co-pilot for CFO --llm integration
CREATE TABLE llm_models (
    llm_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(255) NOT NULL,
    provider VARCHAR(100) NOT NULL, -- OpenAI, Anthropic, etc.
    version VARCHAR(100) NOT NULL,
    capabilities TEXT[] NOT NULL,
    input_token_cost DECIMAL(12,8),
    output_token_cost DECIMAL(12,8),
    context_window INTEGER NOT NULL,
    knowledge_cutoff_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE llm_financial_prompts (
    prompt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    prompt_name VARCHAR(255) NOT NULL,
    prompt_category VARCHAR(100) NOT NULL, -- analysis, reporting, compliance, etc.
    system_prompt TEXT NOT NULL,
    user_prompt_template TEXT NOT NULL,
    example_input TEXT,
    example_output TEXT,
    output_format JSONB,
    allowed_llms UUID[] NOT NULL REFERENCES llm_models(llm_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE llm_interactions (
    interaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    llm_id UUID NOT NULL REFERENCES llm_models(llm_id),
    prompt_id UUID REFERENCES llm_financial_prompts(prompt_id),
    session_id VARCHAR(255) NOT NULL,
    user_query TEXT NOT NULL,
    full_context TEXT,
    llm_response TEXT NOT NULL,
    input_tokens INTEGER NOT NULL,
    output_tokens INTEGER NOT NULL,
    cost_estimate DECIMAL(12,8),
    processing_time_ms INTEGER NOT NULL,
    feedback_score INTEGER,
    feedback_comment TEXT,
    referenced_entities UUID[],
    referenced_documents UUID[],
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_llm_interactions_user ON llm_interactions(user_id);
CREATE INDEX idx_llm_interactions_session ON llm_interactions(session_id);

--decentralized identity SSI integration
CREATE TABLE decentralized_identities (
    identity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    user_id UUID REFERENCES users(user_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    did_method VARCHAR(50) NOT NULL, -- did:ethr, did:key, etc.
    did_string VARCHAR(255) NOT NULL UNIQUE,
    blockchain_network VARCHAR(100),
    public_key_hex TEXT NOT NULL,
    key_type VARCHAR(100) NOT NULL,
    key_purpose VARCHAR(100) NOT NULL, -- auth, assertion, encryption
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE verifiable_credentials (
    credential_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issuer_did VARCHAR(255) NOT NULL REFERENCES decentralized_identities(did_string),
    holder_did VARCHAR(255) NOT NULL REFERENCES decentralized_identities(did_string),
    credential_type VARCHAR(255) NOT NULL,
    credential_data JSONB NOT NULL,
    issuance_date TIMESTAMP WITH TIME ZONE NOT NULL,
    expiration_date TIMESTAMP WITH TIME ZONE,
    revocation_status BOOLEAN NOT NULL DEFAULT FALSE,
    credential_proof JSONB NOT NULL,
    storage_location VARCHAR(255) NOT NULL, -- blockchain, ipfs, local
    reference_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE credential_schemas (
    schema_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schema_name VARCHAR(255) NOT NULL,
    schema_type VARCHAR(255) NOT NULL,
    schema_version VARCHAR(50) NOT NULL,
    schema_definition JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE identity_verification_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_did VARCHAR(255) NOT NULL REFERENCES decentralized_identities(did_string),
    subject_did VARCHAR(255) NOT NULL REFERENCES decentralized_identities(did_string),
    credential_type_required VARCHAR(255) NOT NULL,
    verification_purpose TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    presentation_request JSONB,
    presentation_response JSONB,
    verified_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--real-time financial data streaming
CREATE TABLE data_streams (
    stream_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    stream_name VARCHAR(255) NOT NULL,
    data_source VARCHAR(255) NOT NULL, -- erp, banking_api, market_data
    stream_type VARCHAR(100) NOT NULL, -- transactions, market_data, etc.
    refresh_frequency_ms INTEGER,
    is_real_time BOOLEAN NOT NULL DEFAULT FALSE,
    schema_definition JSONB NOT NULL,
    retention_period_days INTEGER NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stream_data_points (
    point_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stream_id UUID NOT NULL REFERENCES data_streams(stream_id),
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    ingestion_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    entity_id UUID REFERENCES legal_entities(entity_id),
    data_payload JSONB NOT NULL,
    raw_data_hash VARCHAR(255) NOT NULL,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (event_timestamp);

CREATE TABLE stream_processing_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stream_id UUID NOT NULL REFERENCES data_streams(stream_id),
    rule_name VARCHAR(255) NOT NULL,
    rule_condition TEXT NOT NULL,
    action_type VARCHAR(100) NOT NULL, -- alert, transform, enrich
    action_config JSONB NOT NULL,
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create monthly partitions for stream data
CREATE TABLE stream_data_points_y2023m01 PARTITION OF stream_data_points
    FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');

CREATE TABLE stream_data_points_y2023m02 PARTITION OF stream_data_points
    FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');

-- Create indexes on partitions
CREATE INDEX idx_stream_data_points_stream ON stream_data_points(stream_id);
CREATE INDEX idx_stream_data_points_timestamp ON stream_data_points(event_timestamp);


--advanced scenario modeling engine
CREATE TABLE scenario_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    framework_name VARCHAR(255) NOT NULL,
    description TEXT,
    base_period_id UUID REFERENCES financial_periods(period_id),
    currency CHAR(3) NOT NULL,
    time_horizon_months INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scenario_variables (
    variable_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_id UUID NOT NULL REFERENCES scenario_frameworks(framework_id),
    variable_name VARCHAR(255) NOT NULL,
    variable_type VARCHAR(100) NOT NULL, -- input, output, intermediate
    data_type VARCHAR(50) NOT NULL, -- numeric, percentage, boolean
    default_value DECIMAL(19,4),
    min_value DECIMAL(19,4),
    max_value DECIMAL(19,4),
    formula_expression TEXT,
    depends_on UUID[],
    description TEXT,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scenario_simulations (
    simulation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_id UUID NOT NULL REFERENCES scenario_frameworks(framework_id),
    scenario_name VARCHAR(255) NOT NULL,
    scenario_type VARCHAR(100) NOT NULL, -- base, stress, optimistic
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    run_by UUID REFERENCES users(user_id),
    run_at TIMESTAMP WITH TIME ZONE,
    completion_status VARCHAR(50),
    results_summary JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scenario_simulation_values (
    value_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID NOT NULL REFERENCES scenario_simulations(simulation_id),
    variable_id UUID NOT NULL REFERENCES scenario_variables(variable_id),
    time_period INTEGER NOT NULL, -- month number from start
    variable_value DECIMAL(19,4) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (simulation_id, variable_id, time_period)
);

CREATE TABLE scenario_comparisons (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    comparison_name VARCHAR(255) NOT NULL,
    base_scenario_id UUID NOT NULL REFERENCES scenario_simulations(simulation_id),
    alternate_scenario_id UUID NOT NULL REFERENCES scenario_simulations(simulation_id),
    comparison_metrics JSONB NOT NULL,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--hyperledger integration for audit trails
CREATE TABLE hyperledger_channels (
    channel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_name VARCHAR(255) NOT NULL UNIQUE,
    network_name VARCHAR(255) NOT NULL,
    consortium VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hyperledger_chaincodes (
    chaincode_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chaincode_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    channel_id UUID NOT NULL REFERENCES hyperledger_channels(channel_id),
    language VARCHAR(50) NOT NULL,
    init_parameters JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deployed_at TIMESTAMP WITH TIME ZONE,
    deployed_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (chaincode_name, version, channel_id)
);

CREATE TABLE hyperledger_transactions (
    tx_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES hyperledger_channels(channel_id),
    chaincode_id UUID NOT NULL REFERENCES hyperledger_chaincodes(chaincode_id),
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    transaction_type VARCHAR(100) NOT NULL,
    creator_msp VARCHAR(255) NOT NULL,
    creator_certificate TEXT,
    transaction_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(255) NOT NULL,
    transaction_input JSONB,
    transaction_output JSONB,
    response_status INTEGER NOT NULL,
    validation_code VARCHAR(50) NOT NULL,
    endorsing_peers TEXT[],
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hyperledger_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    ledger_key VARCHAR(255) NOT NULL,
    asset_type VARCHAR(100) NOT NULL,
    current_state JSONB NOT NULL,
    channel_id UUID NOT NULL REFERENCES hyperledger_channels(channel_id),
    chaincode_id UUID NOT NULL REFERENCES hyperledger_chaincodes(chaincode_id),
    created_tx_id UUID NOT NULL REFERENCES hyperledger_transactions(tx_id),
    last_updated_tx_id UUID NOT NULL REFERENCES hyperledger_transactions(tx_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ledger_key, channel_id)
);

CREATE INDEX idx_hyperledger_tx_channel ON hyperledger_transactions(channel_id);
CREATE INDEX idx_hyperledger_tx_chaincode ON hyperledger_transactions(chaincode_id);
CREATE INDEX idx_hyperledger_tx_timestamp ON hyperledger_transactions(transaction_timestamp);

--multiparty computation for secure data analysis
CREATE TABLE mpc_computation_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_name VARCHAR(255) NOT NULL,
    computation_purpose TEXT NOT NULL,
    mpc_protocol VARCHAR(100) NOT NULL,
    participant_count INTEGER NOT NULL,
    required_participants INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'initiating',
    initiation_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    completion_timestamp TIMESTAMP WITH TIME ZONE,
    result_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mpc_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES mpc_computation_sessions(session_id),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    participant_did VARCHAR(255) REFERENCES decentralized_identities(did_string),
    participant_role VARCHAR(100) NOT NULL,
    join_timestamp TIMESTAMP WITH TIME ZONE,
    leave_timestamp TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) NOT NULL DEFAULT 'invited',
    contribution_hash VARCHAR(255),
    verification_status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mpc_computation_parameters (
    parameter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES mpc_computation_sessions(session_id),
    parameter_name VARCHAR(255) NOT NULL,
    parameter_type VARCHAR(100) NOT NULL,
    parameter_source VARCHAR(100) NOT NULL, -- local, shared, derived
    data_reference JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mpc_computation_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES mpc_computation_sessions(session_id),
    result_type VARCHAR(100) NOT NULL,
    result_data JSONB,
    result_proof JSONB,
    is_aggregated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);




--enhanced user experience features
CREATE TABLE user_dashboard_preferences (
    preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    dashboard_id UUID REFERENCES client_dashboards(dashboard_id),
    layout_config JSONB NOT NULL,
    default_view BOOLEAN NOT NULL DEFAULT FALSE,
    refresh_rate INTEGER, -- in minutes
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_workspaces (
    workspace_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    workspace_name VARCHAR(255) NOT NULL,
    description TEXT,
    layout_config JSONB NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workspace_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES user_workspaces(workspace_id),
    widget_type VARCHAR(100) NOT NULL,
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER, -- in minutes
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contextual_help (
    help_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    context_path VARCHAR(255) NOT NULL, -- e.g., "tax/filing/vat/uk"
    help_title VARCHAR(255) NOT NULL,
    help_content TEXT NOT NULL,
    video_url VARCHAR(255),
    related_articles UUID[], -- References to knowledge_base
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--profitability metrics definition
CREATE TABLE profitability_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- margin, return, growth
    interpretation_guidance TEXT,
    optimal_range VARCHAR(100),
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard profitability metrics
INSERT INTO profitability_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_range)
VALUES
('Gross Profit Margin', 'GPM', '(Revenue - COGS) / Revenue', 'Measures core profitability before overheads', 'margin', 'Higher is better. Industry dependent but typically 30-60% for healthy businesses', '30-60%'),
('EBITDA Margin', 'EBITDA_M', 'EBITDA / Revenue', 'Evaluates operational efficiency excluding financing and tax effects', 'margin', 'Higher is better. Shows core operating profitability', '15-30%'),
('Net Profit Margin', 'NPM', 'Net Income / Revenue', 'Shows overall profitability after all expenses and taxes', 'margin', 'Higher is better. Final measure of profitability', '5-20%'),
('Return on Assets', 'ROA', 'Net Income / Total Assets', 'Assesses how efficiently assets are used to generate profit', 'return', 'Higher is better. Measures asset efficiency', '5-15%'),
('Return on Equity', 'ROE', 'Net Income / Shareholder Equity', 'Measures return generated for shareholders', 'return', 'Higher is better. Key metric for investors', '15-20%'),
('EBIT Margin', 'EBIT_M', 'EBIT / Revenue', 'Indicates operating performance excluding interest and taxes', 'margin', 'Higher is better. Pure operating performance measure', '10-25%');

CREATE TABLE metric_calculation_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    account_mappings JSONB NOT NULL, -- Maps formula components to GL accounts
    calculation_frequency VARCHAR(50) NOT NULL, -- monthly, quarterly, etc.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--profitabilty results tracking
CREATE TABLE profitability_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    benchmark_value DECIMAL(19,6),
    benchmark_source VARCHAR(255),
    trend_direction VARCHAR(50), -- improving, declining, stable
    trend_magnitude DECIMAL(10,4),
    is_audited BOOLEAN NOT NULL DEFAULT FALSE,
    audit_notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_id, metric_id)
);

CREATE TABLE profitability_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES profitability_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(account_id),
    calculation_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--benchmarking and peer analysis
CREATE TABLE profitability_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    geography VARCHAR(100),
    company_size VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE peer_group_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    peer_group_definition JSONB NOT NULL,
    analysis_date TIMESTAMP WITH TIME ZONE NOT NULL,
    summary_stats JSONB NOT NULL,
    percentile_rankings JSONB NOT NULL,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--profitability alerting system
CREATE TABLE profitability_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    alert_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    alert_condition TEXT NOT NULL,
    actual_value DECIMAL(19,6) NOT NULL,
    expected_value DECIMAL(19,6) NOT NULL,
    variance_pct DECIMAL(10,4) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profitability_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    rule_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    condition_config JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notification_template_id UUID REFERENCES email_templates(template_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--profitability KPI dashboards
CREATE TABLE profitability_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_time_range VARCHAR(50) NOT NULL, -- MTD, QTD, YTD, etc.
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profitability_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES profitability_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- trend, gauge, benchmark, etc.
    metric_id UUID REFERENCES profitability_metrics(metric_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--profitability improvement initiatives
CREATE TABLE profitability_initiatives (
    initiative_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    initiative_name VARCHAR(255) NOT NULL,
    description TEXT,
    target_metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    current_value DECIMAL(19,6) NOT NULL,
    target_value DECIMAL(19,6) NOT NULL,
    start_date DATE NOT NULL,
    target_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    owner_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE initiative_actions (
    action_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiative_id UUID NOT NULL REFERENCES profitability_initiatives(initiative_id),
    action_description TEXT NOT NULL,
    expected_impact_pct DECIMAL(10,4),
    priority VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    start_date DATE,
    end_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE initiative_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiative_id UUID NOT NULL REFERENCES profitability_initiatives(initiative_id),
    reporting_date DATE NOT NULL,
    metric_value DECIMAL(19,6) NOT NULL,
    progress_pct DECIMAL(10,4) NOT NULL,
    commentary TEXT,
    reported_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--profitability forecasting
CREATE TABLE profitability_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    forecast_name VARCHAR(255) NOT NULL,
    base_period_id UUID REFERENCES financial_periods(period_id),
    forecast_method VARCHAR(100) NOT NULL,
    forecast_date DATE NOT NULL,
    time_horizon_months INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE forecast_metric_projections (
    projection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_id UUID NOT NULL REFERENCES profitability_forecasts(forecast_id),
    metric_id UUID NOT NULL REFERENCES profitability_metrics(metric_id),
    period_offset INTEGER NOT NULL, -- months from base period
    projected_value DECIMAL(19,6) NOT NULL,
    confidence_interval_lower DECIMAL(19,6),
    confidence_interval_upper DECIMAL(19,6),
    assumption_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--liquidity metrics definition
CREATE TABLE liquidity_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- liquidity, efficiency, cash flow
    interpretation_guidance TEXT,
    optimal_range VARCHAR(100),
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard liquidity metrics
INSERT INTO liquidity_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_range)
VALUES
('Current Ratio', 'CR', 'Current Assets / Current Liabilities', 'Measures ability to meet short-term obligations', 'liquidity', 'Higher is better. Below 1 indicates potential liquidity issues', '1.5-3.0'),
('Quick Ratio', 'QR', '(Cash + Marketable Securities + Accounts Receivable) / Current Liabilities', 'More conservative liquidity measure', 'liquidity', 'Higher is better. Excludes inventory from liquid assets', '1.0-2.0'),
('Cash Conversion Cycle', 'CCC', 'DIO + DSO - DPO', 'Measures time from inventory investment to cash collection', 'efficiency', 'Lower is better. Negative CCC is optimal (paid after collecting)', 'Varies by industry'),
('Free Cash Flow', 'FCF', 'Operating Cash Flow - Capital Expenditures', 'Shows cash available for reinvestment or distribution', 'cash flow', 'Positive is essential for business health', 'Positive'),
('Days Sales Outstanding', 'DSO', '(Accounts Receivable / Total Credit Sales) × Days in Period', 'Tracks average time to collect receivables', 'efficiency', 'Lower is better. Indicates collection efficiency', '<45 days'),
('Days Payable Outstanding', 'DPO', '(Accounts Payable / COGS) × Days in Period', 'Measures average time to pay suppliers', 'efficiency', 'Higher can be better but may strain supplier relationships', '30-60 days'),
('Days Inventory Outstanding', 'DIO', '(Inventory / COGS) × Days in Period', 'Measures how long inventory is held before sale', 'efficiency', 'Lower is better but depends on industry norms', 'Varies by industry');


--liquidity calculation configuration
CREATE TABLE liquidity_metric_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES liquidity_metrics(metric_id),
    account_mappings JSONB NOT NULL, -- Maps formula components to GL accounts
    calculation_frequency VARCHAR(50) NOT NULL, -- daily, weekly, monthly
    alert_thresholds JSONB, -- Configurable thresholds for alerts
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--liquidity results tracking
CREATE TABLE liquidity_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES liquidity_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    days_value INTEGER, -- For DSO/DPO/DIO metrics
    benchmark_value DECIMAL(19,6),
    benchmark_source VARCHAR(255),
    trend_direction VARCHAR(50), -- improving, declining, stable
    trend_magnitude DECIMAL(10,4),
    is_audited BOOLEAN NOT NULL DEFAULT FALSE,
    audit_notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_id, metric_id)
);

CREATE TABLE liquidity_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES liquidity_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(account_id),
    calculation_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cash flow analysis extensions
CREATE TABLE cash_flow_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    operating_cash_flow DECIMAL(19,4) NOT NULL,
    investing_cash_flow DECIMAL(19,4) NOT NULL,
    financing_cash_flow DECIMAL(19,4) NOT NULL,
    free_cash_flow DECIMAL(19,4) NOT NULL,
    cash_conversion_cycle INTEGER NOT NULL,
    analysis_notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cash_flow_drivers (
    driver_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID NOT NULL REFERENCES cash_flow_analysis(analysis_id),
    driver_name VARCHAR(255) NOT NULL,
    driver_type VARCHAR(100) NOT NULL, -- working capital, capex, etc.
    impact_amount DECIMAL(19,4) NOT NULL,
    impact_direction VARCHAR(50) NOT NULL, -- positive, negative
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--working captial management
CREATE TABLE working_capital_snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    snapshot_date DATE NOT NULL,
    accounts_receivable DECIMAL(19,4) NOT NULL,
    accounts_payable DECIMAL(19,4) NOT NULL,
    inventory_value DECIMAL(19,4) NOT NULL,
    current_assets DECIMAL(19,4) NOT NULL,
    current_liabilities DECIMAL(19,4) NOT NULL,
    working_capital DECIMAL(19,4) GENERATED ALWAYS AS (current_assets - current_liabilities) STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE working_capital_trends (
    trend_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_code VARCHAR(50) NOT NULL, -- DSO, DPO, DIO, etc.
    period_type VARCHAR(50) NOT NULL, -- daily, weekly, monthly
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    average_value DECIMAL(19,6) NOT NULL,
    trend_value DECIMAL(10,4) NOT NULL, -- % change over period
    best_value DECIMAL(19,6),
    best_date DATE,
    worst_value DECIMAL(19,6),
    worst_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--liquidity alerting system
CREATE TABLE liquidity_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID NOT NULL REFERENCES liquidity_metrics(metric_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    alert_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    alert_condition TEXT NOT NULL,
    actual_value DECIMAL(19,6) NOT NULL,
    expected_value DECIMAL(19,6) NOT NULL,
    variance_pct DECIMAL(10,4) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE liquidity_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES liquidity_metrics(metric_id),
    rule_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    condition_config JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notification_template_id UUID REFERENCES email_templates(template_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cashflow forecasting
CREATE TABLE cash_flow_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    forecast_name VARCHAR(255) NOT NULL,
    forecast_date DATE NOT NULL,
    time_horizon_days INTEGER NOT NULL,
    base_cash_balance DECIMAL(19,4) NOT NULL,
    forecast_method VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    confidence_score DECIMAL(5,4),
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cash_flow_forecast_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_id UUID NOT NULL REFERENCES cash_flow_forecasts(forecast_id),
    item_date DATE NOT NULL,
    item_type VARCHAR(50) NOT NULL, -- inflow, outflow
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    certainty_level VARCHAR(50) NOT NULL, -- confirmed, probable, possible
    source_reference VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cash_flow_forecast_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    forecast_id UUID NOT NULL REFERENCES cash_flow_forecasts(forecast_id),
    days_ahead INTEGER NOT NULL,
    projected_cash_balance DECIMAL(19,4) NOT NULL,
    min_safe_balance DECIMAL(19,4),
    liquidity_risk_score DECIMAL(5,4),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--liquidity optimization Recommendations
CREATE TABLE liquidity_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    recommendation_type VARCHAR(100) NOT NULL, -- AR, AP, inventory, financing
    recommendation_text TEXT NOT NULL,
    impact_metric VARCHAR(50) NOT NULL, -- CCC, DSO, DPO, etc.
    expected_impact DECIMAL(10,4) NOT NULL, -- days or percentage
    implementation_complexity VARCHAR(50) NOT NULL, -- low, medium, high
    estimated_savings DECIMAL(19,4),
    priority VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'proposed',
    assigned_to UUID REFERENCES users(user_id),
    target_completion_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    result_achieved DECIMAL(10,4),
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--liquidity benchmarking
CREATE TABLE liquidity_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES liquidity_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    geography VARCHAR(100),
    company_size VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE peer_liquidity_comparison (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    peer_group_definition JSONB NOT NULL,
    comparison_date TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_comparisons JSONB NOT NULL,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--liquidity dashboard components
CREATE TABLE liquidity_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_time_range VARCHAR(50) NOT NULL, -- daily, weekly, monthly
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE liquidity_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES liquidity_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- trend, gauge, forecast, etc.
    metric_id UUID REFERENCES liquidity_metrics(metric_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--solvency metrics definition
CREATE TABLE solvency_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- leverage, coverage, capital structure
    interpretation_guidance TEXT,
    optimal_range VARCHAR(100),
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard solvency metrics
INSERT INTO solvency_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_range)
VALUES
('Debt-to-Equity Ratio', 'DER', 'Total Debt / Shareholder Equity', 'Assesses financial leverage and risk', 'leverage', 'Lower is generally better. Varies by industry', '0.5-2.0'),
('Debt-to-Asset Ratio', 'DAR', 'Total Debt / Total Assets', 'Measures percentage of assets financed by debt', 'leverage', 'Lower is generally better. Shows asset coverage', '<0.5'),
('Interest Coverage Ratio', 'ICR', 'EBIT / Interest Expense', 'Evaluates ability to service debt', 'coverage', 'Higher is better. Below 1.5 may signal distress', '>3.0'),
('Equity Ratio', 'ER', 'Total Equity / Total Assets', 'Shows proportion of assets funded by equity', 'capital structure', 'Higher is generally safer', '>0.3'),
('Debt Service Coverage Ratio', 'DSCR', 'Net Operating Income / Total Debt Service', 'Measures cash flow available for debt payments', 'coverage', 'Higher is better. Below 1 indicates negative cash flow', '>1.25'),
('Financial Leverage Ratio', 'FLR', 'Total Assets / Total Equity', 'Shows degree of financial leverage', 'leverage', 'Higher means more leverage and risk', '2-5'),
('Fixed Charge Coverage Ratio', 'FCCR', '(EBIT + Lease Payments) / (Interest + Lease Payments)', 'Expanded coverage ratio including leases', 'coverage', 'Higher is better. Accounts for all fixed charges', '>2.0');


--solvency calculation configuration
CREATE TABLE solvency_metric_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES solvency_metrics(metric_id),
    account_mappings JSONB NOT NULL, -- Maps formula components to GL accounts
    calculation_frequency VARCHAR(50) NOT NULL, -- monthly, quarterly
    debt_classification_rules JSONB, -- Rules for classifying debt types
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--solvency results tracking
CREATE TABLE solvency_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES solvency_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    benchmark_value DECIMAL(19,6),
    benchmark_source VARCHAR(255),
    covenant_threshold DECIMAL(19,6), -- For loan covenant compliance
    is_covenant_compliant BOOLEAN,
    trend_direction VARCHAR(50), -- improving, declining, stable
    trend_magnitude DECIMAL(10,4),
    is_audited BOOLEAN NOT NULL DEFAULT FALSE,
    audit_notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_id, metric_id)
);

CREATE TABLE solvency_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES solvency_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(account_id),
    calculation_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--debt structure analysis
CREATE TABLE debt_instruments (
    instrument_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    instrument_name VARCHAR(255) NOT NULL,
    instrument_type VARCHAR(100) NOT NULL, -- term loan, bond, lease, etc.
    principal_amount DECIMAL(19,4) NOT NULL,
    currency CHAR(3) NOT NULL,
    interest_rate DECIMAL(10,6) NOT NULL,
    rate_type VARCHAR(50) NOT NULL, -- fixed, variable
    start_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    payment_frequency VARCHAR(50) NOT NULL,
    collateral_description TEXT,
    covenant_details JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE debt_service_schedule (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instrument_id UUID NOT NULL REFERENCES debt_instruments(instrument_id),
    payment_date DATE NOT NULL,
    payment_number INTEGER NOT NULL,
    principal_payment DECIMAL(19,4) NOT NULL,
    interest_payment DECIMAL(19,4) NOT NULL,
    total_payment DECIMAL(19,4) GENERATED ALWAYS AS (principal_payment + interest_payment) STORED,
    remaining_balance DECIMAL(19,4) NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    paid_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--covenant compliance tracking
CREATE TABLE financial_covenants (
    covenant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    instrument_id UUID REFERENCES debt_instruments(instrument_id),
    covenant_name VARCHAR(255) NOT NULL,
    covenant_type VARCHAR(100) NOT NULL, -- ratio, minimum, maximum
    metric_id UUID REFERENCES solvency_metrics(metric_id),
    threshold_value DECIMAL(19,6) NOT NULL,
    test_frequency VARCHAR(50) NOT NULL, -- quarterly, semi-annually
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    grace_period_days INTEGER,
    consequences TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE covenant_test_results (
    test_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    covenant_id UUID NOT NULL REFERENCES financial_covenants(covenant_id),
    test_date DATE NOT NULL,
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    is_compliant BOOLEAN NOT NULL,
    variance_pct DECIMAL(10,4),
    notes TEXT,
    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--capital structure analysis

CREATE TABLE capital_structure_snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    snapshot_date DATE NOT NULL,
    total_debt DECIMAL(19,4) NOT NULL,
    short_term_debt DECIMAL(19,4) NOT NULL,
    long_term_debt DECIMAL(19,4) NOT NULL,
    total_equity DECIMAL(19,4) NOT NULL,
    preferred_equity DECIMAL(19,4),
    minority_interest DECIMAL(19,4),
    total_capital DECIMAL(19,4) GENERATED ALWAYS AS (total_debt + total_equity + COALESCE(preferred_equity,0) + COALESCE(minority_interest,0)) STORED,
    debt_to_capital DECIMAL(19,6) GENERATED ALWAYS AS (total_debt / total_capital) STORED,
    equity_to_capital DECIMAL(19,6) GENERATED ALWAYS AS ((total_equity + COALESCE(preferred_equity,0)) / total_capital) STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE capital_structure_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    debt_percentage DECIMAL(5,2) NOT NULL,
    equity_percentage DECIMAL(5,2) NOT NULL,
    weighted_avg_cost_capital DECIMAL(10,6),
    optimal_structure_analysis TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--solvency alerting system
CREATE TABLE solvency_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID NOT NULL REFERENCES solvency_metrics(metric_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    alert_type VARCHAR(100) NOT NULL, -- threshold, covenant, trend
    alert_condition TEXT NOT NULL,
    actual_value DECIMAL(19,6) NOT NULL,
    threshold_value DECIMAL(19,6) NOT NULL,
    variance_pct DECIMAL(10,4) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    covenant_id UUID REFERENCES financial_covenants(covenant_id),
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE solvency_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES solvency_metrics(metric_id),
    rule_type VARCHAR(100) NOT NULL, -- threshold, trend, covenant
    condition_config JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notification_template_id UUID REFERENCES email_templates(template_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--solvency benchmarking
CREATE TABLE solvency_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES solvency_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    geography VARCHAR(100),
    company_size VARCHAR(50),
    credit_rating VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE peer_solvency_comparison (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    peer_group_definition JSONB NOT NULL,
    comparison_date TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_comparisons JSONB NOT NULL,
    credit_rating_comparison JSONB,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--solvency optimization recommendations
CREATE TABLE capital_structure_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    analysis_date DATE NOT NULL,
    current_debt_ratio DECIMAL(5,4) NOT NULL,
    target_debt_ratio DECIMAL(5,4) NOT NULL,
    recommended_actions JSONB NOT NULL, -- refinance, equity raise, etc.
    expected_impact TEXT NOT NULL,
    implementation_complexity VARCHAR(50) NOT NULL, -- low, medium, high
    priority VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'proposed',
    assigned_to UUID REFERENCES users(user_id),
    target_completion_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    result_achieved DECIMAL(5,4),
    notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--solvency dashboard components
CREATE TABLE solvency_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_time_range VARCHAR(50) NOT NULL, -- quarterly, yearly
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE solvency_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES solvency_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- trend, gauge, covenant, etc.
    metric_id UUID REFERENCES solvency_metrics(metric_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--operational efficiency metrics
CREATE TABLE efficiency_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- asset, inventory, working capital
    interpretation_guidance TEXT,
    optimal_range VARCHAR(100),
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard efficiency metrics
INSERT INTO efficiency_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_range)
VALUES
('Asset Turnover Ratio', 'ATR', 'Revenue / Total Assets', 'Measures how effectively assets generate revenue', 'asset', 'Higher is better. Varies by capital intensity', '>1.0'),
('Inventory Turnover Ratio', 'ITR', 'COGS / Average Inventory', 'Indicates how many times inventory is sold and replaced', 'inventory', 'Higher is better but depends on industry', '5-10'),
('Fixed Asset Turnover', 'FAT', 'Revenue / Net Fixed Assets', 'Evaluates efficiency of fixed asset use', 'asset', 'Higher is better. Measures capital productivity', '>2.5'),
('Working Capital Turnover', 'WCT', 'Revenue / Working Capital', 'Measures efficiency in using working capital', 'working capital', 'Higher is better but may indicate under-capitalization', '5-15'),
('Receivables Turnover', 'RT', 'Net Credit Sales / Average Accounts Receivable', 'Measures how quickly receivables are collected', 'working capital', 'Higher is better. Shows collection efficiency', '8-12'),
('Payables Turnover', 'PT', 'COGS / Average Accounts Payable', 'Measures how quickly payables are paid', 'working capital', 'Lower may be better but depends on terms', '6-10'),
('Days Working Capital', 'DWC', 'Working Capital / (Revenue/365)', 'Shows days of revenue covered by working capital', 'working capital', 'Lower is generally better', '<90');


--efficiency calculation configuration
CREATE TABLE efficiency_metric_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    account_mappings JSONB NOT NULL, -- Maps formula components to GL accounts
    calculation_method VARCHAR(100) NOT NULL, -- average, period-end, etc.
    calculation_frequency VARCHAR(50) NOT NULL, -- monthly, quarterly
    seasonal_adjustment BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--efficiency results tracking
CREATE TABLE efficiency_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    days_value INTEGER, -- For days-based metrics
    benchmark_value DECIMAL(19,6),
    benchmark_source VARCHAR(255),
    trend_direction VARCHAR(50), -- improving, declining, stable
    trend_magnitude DECIMAL(10,4),
    is_audited BOOLEAN NOT NULL DEFAULT FALSE,
    audit_notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_id, metric_id)
);

CREATE TABLE efficiency_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES efficiency_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(account_id),
    calculation_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--asset efficiency analysis
CREATE TABLE asset_efficiency (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    total_asset_turnover DECIMAL(19,6) NOT NULL,
    fixed_asset_turnover DECIMAL(19,6) NOT NULL,
    current_asset_turnover DECIMAL(19,6) NOT NULL,
    industry_median_asset_turnover DECIMAL(19,6),
    asset_intensity_ratio DECIMAL(19,6) GENERATED ALWAYS AS (1 / total_asset_turnover) STORED,
    analysis_notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE asset_category_efficiency (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID NOT NULL REFERENCES asset_efficiency(analysis_id),
    asset_category VARCHAR(100) NOT NULL, -- PP&E, Inventory, Receivables
    asset_value DECIMAL(19,4) NOT NULL,
    revenue_contribution DECIMAL(19,4) NOT NULL,
    turnover_ratio DECIMAL(19,6) NOT NULL,
    benchmark_ratio DECIMAL(19,6),
    efficiency_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--inventory management metrics
CREATE TABLE inventory_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    inventory_turnover DECIMAL(19,6) NOT NULL,
    days_inventory_outstanding INTEGER NOT NULL,
    inventory_to_sales_ratio DECIMAL(19,6) NOT NULL,
    obsolete_inventory_pct DECIMAL(5,2),
    stockout_frequency DECIMAL(5,2),
    carrying_cost_pct DECIMAL(5,2),
    analysis_notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_category_turnover (
    turnover_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID NOT NULL REFERENCES inventory_analysis(analysis_id),
    product_category VARCHAR(255) NOT NULL,
    inventory_value DECIMAL(19,4) NOT NULL,
    cogs_contribution DECIMAL(19,4) NOT NULL,
    turnover_ratio DECIMAL(19,6) NOT NULL,
    days_outstanding INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--working captial efficiency
CREATE TABLE working_capital_efficiency (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    working_capital_turnover DECIMAL(19,6) NOT NULL,
    days_working_capital INTEGER NOT NULL,
    receivables_turnover DECIMAL(19,6) NOT NULL,
    payables_turnover DECIMAL(19,6) NOT NULL,
    cash_conversion_cycle INTEGER NOT NULL,
    working_capital_velocity DECIMAL(19,6) GENERATED ALWAYS AS (365 / working_capital_turnover) STORED,
    analysis_notes TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wc_component_efficiency (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID NOT NULL REFERENCES working_capital_efficiency(analysis_id),
    component_type VARCHAR(50) NOT NULL, -- AR, AP, Inventory
    component_value DECIMAL(19,4) NOT NULL,
    turnover_ratio DECIMAL(19,6) NOT NULL,
    days_outstanding INTEGER NOT NULL,
    benchmark_days INTEGER,
    efficiency_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--efficiency benchmarking
CREATE TABLE efficiency_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    company_size VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE efficiency_peer_comparison (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    peer_group_definition JSONB NOT NULL,
    comparison_date TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_comparisons JSONB NOT NULL,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--efficiency alerting system
CREATE TABLE efficiency_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    alert_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    alert_condition TEXT NOT NULL,
    actual_value DECIMAL(19,6) NOT NULL,
    expected_value DECIMAL(19,6) NOT NULL,
    variance_pct DECIMAL(10,4) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE efficiency_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    rule_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    condition_config JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notification_template_id UUID REFERENCES email_templates(template_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--operational improvement initiatives
CREATE TABLE efficiency_initiatives (
    initiative_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    initiative_name VARCHAR(255) NOT NULL,
    focus_area VARCHAR(100) NOT NULL, -- inventory, receivables, payables
    target_metric_id UUID NOT NULL REFERENCES efficiency_metrics(metric_id),
    current_value DECIMAL(19,6) NOT NULL,
    target_value DECIMAL(19,6) NOT NULL,
    expected_impact TEXT NOT NULL,
    implementation_plan TEXT NOT NULL,
    start_date DATE NOT NULL,
    target_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    owner_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE initiative_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiative_id UUID NOT NULL REFERENCES efficiency_initiatives(initiative_id),
    progress_date DATE NOT NULL,
    metric_value DECIMAL(19,6) NOT NULL,
    progress_pct DECIMAL(5,2) NOT NULL,
    completed_milestones TEXT,
    next_steps TEXT,
    reported_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--efficiency dashboard components
CREATE TABLE efficiency_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_time_range VARCHAR(50) NOT NULL, -- monthly, quarterly
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE efficiency_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES efficiency_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- trend, gauge, comparison
    metric_id UUID REFERENCES efficiency_metrics(metric_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost management metrics
CREATE TABLE cost_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- production, operational, innovation
    interpretation_guidance TEXT,
    optimal_range VARCHAR(100),
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard cost metrics
INSERT INTO cost_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_range)
VALUES
('Cost per Unit', 'CPU', 'Total Production Cost / Units Produced', 'Helps in pricing and cost control', 'production', 'Lower is better. Compare to selling price', 'Varies by industry'),
('SG&A Ratio', 'SG&A', 'SG&A Expenses / Revenue', 'Measures administrative and selling efficiency', 'operational', 'Lower is better. Benchmark against peers', '15-25%'),
('Operating Expense Ratio', 'OER', 'Operating Expenses / Revenue', 'Shows proportion of revenue consumed by operating costs', 'operational', 'Lower is better. Indicates operational efficiency', '<60%'),
('R&D to Revenue Ratio', 'RDR', 'R&D Expenses / Revenue', 'Assesses investment in innovation relative to revenue', 'innovation', 'Varies by industry and growth stage', '5-15% for tech'),
('Gross Margin Ratio', 'GMR', '(Revenue - COGS) / Revenue', 'Measures production efficiency after direct costs', 'production', 'Higher is better. Core profitability measure', '30-60%'),
('Contribution Margin Ratio', 'CMR', '(Revenue - Variable Costs) / Revenue', 'Shows profitability after variable costs', 'production', 'Higher is better. Important for pricing', '>40%'),
('Labor Cost Percentage', 'LCP', 'Total Labor Costs / Revenue', 'Measures workforce cost efficiency', 'operational', 'Varies by industry. Compare to benchmarks', '15-30%');


--cost calculation configuration
CREATE TABLE cost_metric_configs (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES cost_metrics(metric_id),
    account_mappings JSONB NOT NULL, -- Maps formula components to GL accounts
    cost_center_mappings JSONB, -- Optional cost center breakdowns
    calculation_frequency VARCHAR(50) NOT NULL, -- weekly, monthly
    unit_of_measure VARCHAR(50), -- For per-unit metrics
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--cost analysis framework
CREATE TABLE cost_structures (
    structure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    structure_name VARCHAR(255) NOT NULL,
    description TEXT,
    cost_hierarchy JSONB NOT NULL, -- Defines cost categories and relationships
    default_currency CHAR(3) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cost_allocations (
    allocation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    structure_id UUID NOT NULL REFERENCES cost_structures(structure_id),
    allocation_method VARCHAR(100) NOT NULL, -- direct, activity-based, etc.
    driver_account_id UUID REFERENCES chart_of_accounts(account_id),
    driver_description TEXT,
    allocation_rules JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost results tracking
CREATE TABLE cost_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES cost_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    benchmark_value DECIMAL(19,6),
    benchmark_source VARCHAR(255),
    trend_direction VARCHAR(50), -- improving, declining, stable
    trend_magnitude DECIMAL(10,4),
    variance_analysis TEXT,
    is_audited BOOLEAN NOT NULL DEFAULT FALSE,
    audit_notes TEXT,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (entity_id, period_id, metric_id)
);

CREATE TABLE cost_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES cost_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(account_id),
    cost_center_id UUID, -- References cost centers table
    calculation_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--product costing system
CREATE TABLE product_cost_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    product_id UUID NOT NULL, -- References products table
    model_name VARCHAR(255) NOT NULL,
    costing_method VARCHAR(100) NOT NULL, -- standard, actual, ABC
    currency CHAR(3) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_cost_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES product_cost_models(model_id),
    cost_type VARCHAR(100) NOT NULL, -- material, labor, overhead
    component_name VARCHAR(255) NOT NULL,
    unit_cost DECIMAL(19,4) NOT NULL,
    quantity DECIMAL(19,4) NOT NULL DEFAULT 1,
    total_cost DECIMAL(19,4) GENERATED ALWAYS AS (unit_cost * quantity) STORED,
    variance_account_id UUID REFERENCES chart_of_accounts(account_id),
    is_direct BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost variance analysis
CREATE TABLE cost_variances (
    variance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    cost_element VARCHAR(255) NOT NULL, -- material, labor, etc.
    account_id UUID REFERENCES chart_of_accounts(account_id),
    standard_cost DECIMAL(19,4) NOT NULL,
    actual_cost DECIMAL(19,4) NOT NULL,
    variance_amount DECIMAL(19,4) GENERATED ALWAYS AS (actual_cost - standard_cost) STORED,
    variance_pct DECIMAL(10,4) GENERATED ALWAYS AS
        (CASE WHEN standard_cost <> 0 THEN ((actual_cost - standard_cost) / standard_cost) * 100 ELSE NULL END) STORED,
    variance_type VARCHAR(50) NOT NULL, -- favorable, unfavorable
    root_cause_analysis TEXT,
    corrective_actions TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost bench marking
CREATE TABLE cost_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES cost_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    company_size VARCHAR(50),
    geography VARCHAR(100),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE peer_cost_comparison (
    comparison_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    peer_group_definition JSONB NOT NULL,
    comparison_date TIMESTAMP WITH TIME ZONE NOT NULL,
    metric_comparisons JSONB NOT NULL,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost reduction initiatives
CREATE TABLE cost_initiatives (
    initiative_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    initiative_name VARCHAR(255) NOT NULL,
    focus_area VARCHAR(100) NOT NULL, -- COGS, SG&A, R&D, etc.
    target_metric_id UUID REFERENCES cost_metrics(metric_id),
    current_value DECIMAL(19,6) NOT NULL,
    target_value DECIMAL(19,6) NOT NULL,
    expected_savings DECIMAL(19,4) NOT NULL,
    implementation_plan TEXT NOT NULL,
    start_date DATE NOT NULL,
    target_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    owner_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE initiative_savings (
    saving_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiative_id UUID NOT NULL REFERENCES cost_initiatives(initiative_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    actual_savings DECIMAL(19,4) NOT NULL,
    verified_by UUID REFERENCES users(user_id),
    verification_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost alerting system
CREATE TABLE cost_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID NOT NULL REFERENCES cost_metrics(metric_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    alert_type VARCHAR(100) NOT NULL, -- threshold, trend, variance
    alert_condition TEXT NOT NULL,
    actual_value DECIMAL(19,6) NOT NULL,
    expected_value DECIMAL(19,6) NOT NULL,
    variance_pct DECIMAL(10,4) NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    assigned_to UUID REFERENCES users(user_id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cost_alert_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES cost_metrics(metric_id),
    rule_type VARCHAR(100) NOT NULL, -- threshold, trend, benchmark
    condition_config JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notification_template_id UUID REFERENCES email_templates(template_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--cost management dashboards
CREATE TABLE cost_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_time_range VARCHAR(50) NOT NULL, -- monthly, quarterly
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cost_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES cost_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- trend, gauge, comparison
    metric_id UUID REFERENCES cost_metrics(metric_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--tax metrics definition
CREATE TABLE tax_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- compliance, planning, risk
    interpretation_guidance TEXT,
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard tax metrics
INSERT INTO tax_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance)
VALUES
('Effective Tax Rate', 'ETR', 'Total Tax Expense / Pre-Tax Income', 'Reflects actual tax burden considering deductions and credits', 'compliance', 'Compare to statutory rate to assess tax efficiency'),
('Deferred Tax Liability Growth', 'DTLG', 'Δ(Deferred Tax Liability)', 'Monitors impact of temporary differences on future taxes', 'planning', 'Rapid growth may indicate future cash flow impacts'),
('Tax Gap Analysis', 'TGA', 'Estimated Tax Owed vs. Actual Paid', 'Identifies underpayment risks or planning opportunities', 'risk', 'Positive gap indicates potential underpayment risk'),
('R&D Tax Credit Utilization Rate', 'RDCUR', 'Claimed Credits / Eligible Credits', 'Measures effectiveness of R&D incentive capture', 'planning', 'Higher is better. Below 1 indicates missed opportunities'),
('Cash Tax Rate', 'CTR', 'Cash Taxes Paid / Pre-Tax Income', 'Shows actual cash outflow for taxes', 'compliance', 'Compare to ETR to assess timing differences'),
('Permanent Difference Ratio', 'PDR', 'Permanent Differences / Pre-Tax Income', 'Measures non-recurring tax adjustments', 'planning', 'High ratios may indicate aggressive positions'),
('Tax Controversy Reserve Ratio', 'TCRR', 'Tax Reserves / Total Tax Expense', 'Assesses risk from uncertain tax positions', 'risk', 'Higher indicates greater tax uncertainty');

--jurisdictional tax tracking
CREATE TABLE tax_jurisdictions (
    jurisdiction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_code CHAR(2) NOT NULL,
    region VARCHAR(100),
    tax_type VARCHAR(100) NOT NULL, -- income, sales, property
    statutory_rate DECIMAL(5,4) NOT NULL,
    filing_frequency VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE entity_tax_profiles (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    filing_currency CHAR(3) NOT NULL,
    tax_identification_number VARCHAR(100),
    filing_method VARCHAR(100), -- electronic, paper
    primary_contact_id UUID REFERENCES users(user_id),
    local_advisor_id UUID REFERENCES experts(expert_id),
    compliance_status VARCHAR(50) NOT NULL DEFAULT 'compliant',
    last_review_date DATE,
    next_review_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--tax provision and compliance tracking
CREATE TABLE tax_provisions (
    provision_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    pre_tax_income DECIMAL(19,4) NOT NULL,
    current_tax_expense DECIMAL(19,4) NOT NULL,
    deferred_tax_expense DECIMAL(19,4) NOT NULL,
    total_tax_expense DECIMAL(19,4) GENERATED ALWAYS AS (current_tax_expense + deferred_tax_expense) STORED,
    effective_tax_rate DECIMAL(5,4) GENERATED ALWAYS AS
        (CASE WHEN pre_tax_income <> 0 THEN total_tax_expense / pre_tax_income ELSE NULL END) STORED,
    statutory_rate DECIMAL(5,4) NOT NULL,
    rate_reconciliation JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    prepared_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    approved_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_filings (
    filing_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provision_id UUID REFERENCES tax_provisions(provision_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    filing_period VARCHAR(50) NOT NULL,
    due_date DATE NOT NULL,
    filing_date DATE,
    payment_date DATE,
    tax_owed DECIMAL(19,4) NOT NULL,
    tax_paid DECIMAL(19,4),
    penalty_amount DECIMAL(19,4),
    interest_amount DECIMAL(19,4),
    filing_reference VARCHAR(255),
    document_id UUID REFERENCES documents(document_id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);



--deferred tax analysis
CREATE TABLE deferred_tax_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    item_name VARCHAR(255) NOT NULL,
    item_type VARCHAR(100) NOT NULL, -- liability, asset
    timing_difference_type VARCHAR(100) NOT NULL,
    book_basis DECIMAL(19,4) NOT NULL,
    tax_basis DECIMAL(19,4) NOT NULL,
    temporary_difference DECIMAL(19,4) GENERATED ALWAYS AS (book_basis - tax_basis) STORED,
    tax_rate DECIMAL(5,4) NOT NULL,
    deferred_tax_amount DECIMAL(19,4) GENERATED ALWAYS AS ((book_basis - tax_basis) * tax_rate) STORED,
    reversal_period VARCHAR(50),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deferred_tax_movements (
    movement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID NOT NULL REFERENCES deferred_tax_items(item_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    beginning_balance DECIMAL(19,4) NOT NULL,
    additions DECIMAL(19,4) NOT NULL,
    reversals DECIMAL(19,4) NOT NULL,
    ending_balance DECIMAL(19,4) GENERATED ALWAYS AS (beginning_balance + additions - reversals) STORED,
    movement_analysis TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--tax risk and controversy management
CREATE TABLE tax_risks (
    risk_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    risk_description TEXT NOT NULL,
    risk_category VARCHAR(100) NOT NULL, -- filing, transfer pricing, etc.
    exposure_amount DECIMAL(19,4),
    probability VARCHAR(50) NOT NULL, -- low, medium, high
    potential_penalty DECIMAL(19,4),
    detection_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    mitigation_plan TEXT,
    reserve_amount DECIMAL(19,4),
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_controversies (
    case_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    case_reference VARCHAR(255) NOT NULL,
    dispute_amount DECIMAL(19,4) NOT NULL,
    dispute_type VARCHAR(100) NOT NULL,
    filing_period VARCHAR(50) NOT NULL,
    notice_date DATE NOT NULL,
    response_deadline DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    assigned_counsel_id UUID REFERENCES experts(expert_id),
    reserve_amount DECIMAL(19,4),
    case_outcome VARCHAR(100),
    settlement_amount DECIMAL(19,4),
    closed_date DATE,
    lessons_learned TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--tax planning and incentives
CREATE TABLE tax_planning_opportunities (
    opportunity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID REFERENCES tax_jurisdictions(jurisdiction_id),
    opportunity_name VARCHAR(255) NOT NULL,
    opportunity_type VARCHAR(100) NOT NULL, -- credit, deduction, structure
    estimated_benefit DECIMAL(19,4) NOT NULL,
    implementation_complexity VARCHAR(50) NOT NULL, -- low, medium, high
    risk_level VARCHAR(50) NOT NULL, -- low, medium, high
    status VARCHAR(50) NOT NULL DEFAULT 'identified',
    owner_id UUID REFERENCES users(user_id),
    target_completion_date DATE,
    actual_completion_date DATE,
    realized_benefit DECIMAL(19,4),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE r_d_tax_credits (
    credit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    claim_period VARCHAR(50) NOT NULL,
    total_qualified_expenses DECIMAL(19,4) NOT NULL,
    credit_rate DECIMAL(5,4) NOT NULL,
    potential_credit DECIMAL(19,4) GENERATED ALWAYS AS (total_qualified_expenses * credit_rate) STORED,
    claimed_credit DECIMAL(19,4) NOT NULL,
    utilization_rate DECIMAL(5,4) GENERATED ALWAYS AS
        (CASE WHEN potential_credit <> 0 THEN claimed_credit / potential_credit ELSE NULL END) STORED,
    filing_reference VARCHAR(255),
    document_id UUID REFERENCES documents(document_id),
    status VARCHAR(50) NOT NULL DEFAULT 'filed',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--tax benchmarking and analytics
CREATE TABLE tax_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES tax_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    company_size VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_gap_analysis (
    gap_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    estimated_tax_owed DECIMAL(19,4) NOT NULL,
    actual_tax_paid DECIMAL(19,4) NOT NULL,
    tax_gap_amount DECIMAL(19,4) GENERATED ALWAYS AS (estimated_tax_owed - actual_tax_paid) STORED,
    gap_percentage DECIMAL(5,4) GENERATED ALWAYS AS
        (CASE WHEN estimated_tax_owed <> 0 THEN (estimated_tax_owed - actual_tax_paid) / estimated_tax_owed ELSE NULL END) STORED,
    gap_explanation TEXT,
    action_plan TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--tax alerting and monitoring
CREATE TABLE tax_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    metric_id UUID REFERENCES tax_metrics(metric_id),
    jurisdiction_id UUID REFERENCES tax_jurisdictions(jurisdiction_id),
    alert_type VARCHAR(100) NOT NULL, -- filing, rate, risk
    alert_description TEXT NOT NULL,
    trigger_value DECIMAL(19,6),
    threshold_value DECIMAL(19,6),
    severity VARCHAR(50) NOT NULL, -- critical, warning, informational
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    due_date DATE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_regulatory_changes (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_id UUID NOT NULL REFERENCES tax_jurisdictions(jurisdiction_id),
    change_description TEXT NOT NULL,
    change_type VARCHAR(100) NOT NULL, -- rate, filing, compliance
    effective_date DATE NOT NULL,
    impact_level VARCHAR(50) NOT NULL, -- high, medium, low
    affected_entities UUID[],
    action_required TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending_review',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--tax dashboard components
CREATE TABLE tax_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_view VARCHAR(100) NOT NULL, -- global, entity, jurisdiction
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tax_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES tax_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- metric, calendar, alert
    metric_id UUID REFERENCES tax_metrics(metric_id),
    jurisdiction_id UUID REFERENCES tax_jurisdictions(jurisdiction_id),
    widget_config JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--risk and internal control metrics
--risk and control metrics
CREATE TABLE risk_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- audit, compliance, operational
    interpretation_guidance TEXT,
    optimal_direction VARCHAR(50) NOT NULL, -- higher, lower, neutral
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard risk metrics
INSERT INTO risk_metrics
(metric_name, metric_code, formula, description, category, interpretation_guidance, optimal_direction)
VALUES
('Internal Audit Findings Closed on Time', 'IAFCT', '# Closed Issues / # Total Issues', 'Measures internal control responsiveness', 'audit', 'Higher is better. Shows timely remediation', 'higher'),
('Incident Response Time', 'IRT', 'Avg. Time to Resolve Risk Incidents', 'Tracks timeliness of addressing issues', 'operational', 'Lower is better. Faster response reduces impact', 'lower'),
('Compliance Breach Frequency', 'CBF', '# Breaches / Period', 'Monitors regulatory adherence', 'compliance', 'Lower is better. Zero is ideal', 'lower'),
('Segregation of Duties Violations', 'SODV', '# SoD Conflicts Detected', 'Highlights internal control weaknesses', 'audit', 'Lower is better. Zero is ideal', 'lower'),
('Control Effectiveness Score', 'CES', 'Effective Controls / Total Controls Tested', 'Measures control environment strength', 'audit', 'Higher is better. Target 95%+', 'higher'),
('Risk Appetite Coverage', 'RAC', 'Mitigated Risks / Identified Risks', 'Shows risk management completeness', 'operational', 'Higher is better. Target 100%', 'higher'),
('Third-Party Risk Index', 'TPRI', 'Weighted Risk Score of Vendors', 'Aggregates supply chain risk', 'compliance', 'Lower is better. Monitor trends', 'lower');


--risk framework configuration

CREATE TABLE risk_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    framework_name VARCHAR(255) NOT NULL,
    framework_type VARCHAR(100) NOT NULL, -- COSO, ISO, custom
    description TEXT,
    risk_categories JSONB NOT NULL,
    risk_tolerance_levels JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE risk_appetite_statements (
    statement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    risk_category VARCHAR(100) NOT NULL,
    appetite_level VARCHAR(50) NOT NULL, -- avoid, minimal, cautious, etc.
    quantitative_limits JSONB,
    qualitative_guidance TEXT,
    effective_date DATE NOT NULL,
    review_frequency VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--risk assessment and audit tracking
CREATE TABLE risk_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    assessment_name VARCHAR(255) NOT NULL,
    assessment_date DATE NOT NULL,
    framework_id UUID REFERENCES risk_frameworks(framework_id),
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    conducted_by UUID REFERENCES users(user_id),
    reviewed_by UUID REFERENCES users(user_id),
    approved_by UUID REFERENCES users(user_id),
    next_assessment_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE identified_risks (
    risk_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES risk_assessments(assessment_id),
    risk_name VARCHAR(255) NOT NULL,
    risk_category VARCHAR(100) NOT NULL,
    description TEXT,
    inherent_impact VARCHAR(50) NOT NULL,
    inherent_likelihood VARCHAR(50) NOT NULL,
    inherent_score INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN inherent_impact = 'low' AND inherent_likelihood = 'low' THEN 1
            WHEN inherent_impact = 'low' AND inherent_likelihood = 'medium' THEN 2
            WHEN inherent_impact = 'low' AND inherent_likelihood = 'high' THEN 3
            WHEN inherent_impact = 'medium' AND inherent_likelihood = 'low' THEN 2
            WHEN inherent_impact = 'medium' AND inherent_likelihood = 'medium' THEN 4
            WHEN inherent_impact = 'medium' AND inherent_likelihood = 'high' THEN 6
            WHEN inherent_impact = 'high' AND inherent_likelihood = 'low' THEN 3
            WHEN inherent_impact = 'high' AND inherent_likelihood = 'medium' THEN 6
            WHEN inherent_impact = 'high' AND inherent_likelihood = 'high' THEN 9
            ELSE 0
        END
    ) STORED,
    residual_impact VARCHAR(50),
    residual_likelihood VARCHAR(50),
    residual_score INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN residual_impact = 'low' AND residual_likelihood = 'low' THEN 1
            WHEN residual_impact = 'low' AND residual_likelihood = 'medium' THEN 2
            WHEN residual_impact = 'low' AND residual_likelihood = 'high' THEN 3
            WHEN residual_impact = 'medium' AND residual_likelihood = 'low' THEN 2
            WHEN residual_impact = 'medium' AND residual_likelihood = 'medium' THEN 4
            WHEN residual_impact = 'medium' AND residual_likelihood = 'high' THEN 6
            WHEN residual_impact = 'high' AND residual_likelihood = 'low' THEN 3
            WHEN residual_impact = 'high' AND residual_likelihood = 'medium' THEN 6
            WHEN residual_impact = 'high' AND residual_likelihood = 'high' THEN 9
            ELSE NULL
        END
    ) STORED,
    risk_owner_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_engagements (
    engagement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    engagement_name VARCHAR(255) NOT NULL,
    engagement_type VARCHAR(100) NOT NULL, -- internal, external, compliance
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    lead_auditor_id UUID REFERENCES users(user_id),
    objectives TEXT NOT NULL,
    scope TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--findings and Issues Management
CREATE TABLE audit_findings (
    finding_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    engagement_id UUID NOT NULL REFERENCES audit_engagements(engagement_id),
    finding_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    risk_level VARCHAR(50) NOT NULL, -- high, medium, low
    category VARCHAR(100) NOT NULL, -- financial, operational, compliance
    recommendation TEXT NOT NULL,
    root_cause_analysis TEXT,
    due_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    assigned_to UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE finding_remediations (
    remediation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    finding_id UUID NOT NULL REFERENCES audit_findings(finding_id),
    action_plan TEXT NOT NULL,
    implementation_details TEXT,
    target_completion_date DATE NOT NULL,
    actual_completion_date DATE,
    evidence_document_id UUID REFERENCES documents(document_id),
    verified_by UUID REFERENCES users(user_id),
    verification_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE control_issues (
    issue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    issue_name VARCHAR(255) NOT NULL,
    issue_type VARCHAR(100) NOT NULL, -- control failure, SOD violation, etc.
    description TEXT NOT NULL,
    detection_date DATE NOT NULL,
    impact_assessment VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    assigned_to UUID REFERENCES users(user_id),
    due_date DATE,
    resolved_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--Incident and Breach tracking
CREATE TABLE risk_incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    incident_name VARCHAR(255) NOT NULL,
    incident_type VARCHAR(100) NOT NULL, -- security, fraud, operational
    description TEXT NOT NULL,
    detection_date TIMESTAMP WITH TIME ZONE NOT NULL,
    severity VARCHAR(50) NOT NULL, -- critical, high, medium, low
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    root_cause TEXT,
    financial_impact DECIMAL(19,4),
    non_financial_impact TEXT,
    reported_by UUID REFERENCES users(user_id),
    assigned_to UUID REFERENCES users(user_id),
    resolved_date TIMESTAMP WITH TIME ZONE,
    resolution_time_minutes INTEGER GENERATED ALWAYS AS (
        CASE WHEN resolved_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (resolved_date - detection_date))/60
        ELSE NULL END
    ) STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compliance_breaches (
    breach_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    regulation_id UUID, -- References regulations table
    breach_description TEXT NOT NULL,
    breach_date DATE NOT NULL,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL,
    reporting_required BOOLEAN NOT NULL DEFAULT FALSE,
    reported_date DATE,
    regulatory_response TEXT,
    corrective_actions TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--controls testing and monitoring
CREATE TABLE internal_controls (
    control_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    control_name VARCHAR(255) NOT NULL,
    control_category VARCHAR(100) NOT NULL, -- preventive, detective, corrective
    control_type VARCHAR(100) NOT NULL, -- manual, automated, IT
    description TEXT NOT NULL,
    frequency VARCHAR(50) NOT NULL, -- daily, weekly, monthly
    owner_id UUID REFERENCES users(user_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE control_tests (
    test_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    control_id UUID NOT NULL REFERENCES internal_controls(control_id),
    test_date DATE NOT NULL,
    test_type VARCHAR(100) NOT NULL, -- sample, full population
    sample_size INTEGER,
    sample_method VARCHAR(100),
    performed_by UUID REFERENCES users(user_id),
    test_result VARCHAR(50) NOT NULL, -- pass, fail, exception
    findings TEXT,
    effectiveness_score INTEGER, -- 1-5 scale
    next_test_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE segregation_of_duties_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    rule_name VARCHAR(255) NOT NULL,
    risk_description TEXT NOT NULL,
    conflicting_roles JSONB NOT NULL,
    severity VARCHAR(50) NOT NULL,
    mitigation_controls TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sod_violations (
    violation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES segregation_of_duties_rules(rule_id),
    user_id UUID REFERENCES users(user_id),
    detection_date DATE NOT NULL,
    conflicting_roles_assigned JSONB NOT NULL,
    mitigation_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    mitigation_plan TEXT,
    resolved_date DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--risk metrics calculation and tracking
CREATE TABLE risk_metric_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID REFERENCES legal_entities(entity_id),
    period_id UUID NOT NULL REFERENCES financial_periods(period_id),
    metric_id UUID NOT NULL REFERENCES risk_metrics(metric_id),
    calculated_value DECIMAL(19,6) NOT NULL,
    benchmark_value DECIMAL(19,6),
    trend_direction VARCHAR(50), -- improving, declining, stable
    target_value DECIMAL(19,6),
    within_tolerance BOOLEAN GENERATED ALWAYS AS (
        CASE
            WHEN target_value IS NULL THEN NULL
            WHEN risk_metrics.optimal_direction = 'higher' AND calculated_value >= target_value THEN TRUE
            WHEN risk_metrics.optimal_direction = 'lower' AND calculated_value <= target_value THEN TRUE
            ELSE FALSE
        END
    ) STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (metric_id) REFERENCES risk_metrics(metric_id)
);

CREATE TABLE risk_metric_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    result_id UUID NOT NULL REFERENCES risk_metric_results(result_id),
    component_name VARCHAR(255) NOT NULL,
    component_value DECIMAL(19,4) NOT NULL,
    source_entity VARCHAR(255), -- For consolidated metrics
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--risk reporting and dashboard
CREATE TABLE risk_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(100) NOT NULL, -- executive, board, regulatory
    frequency VARCHAR(50) NOT NULL,
    delivery_method VARCHAR(100) NOT NULL,
    last_generated_date TIMESTAMP WITH TIME ZONE,
    next_due_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE risk_dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    dashboard_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_view VARCHAR(100) NOT NULL, -- enterprise, entity, risk-type
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE risk_dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES risk_dashboards(dashboard_id),
    widget_type VARCHAR(100) NOT NULL, -- metric, heatmap, trend
    metric_id UUID REFERENCES risk_metrics(metric_id),
    data_source JSONB NOT NULL,
    display_order INTEGER NOT NULL,
    refresh_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--ESG and Sustainability Metrics
--ESG Metrics Definition
CREATE TABLE esg_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL,
    metric_code VARCHAR(50) NOT NULL UNIQUE,
    formula TEXT NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL, -- environmental, social, governance
    reporting_standard VARCHAR(100) NOT NULL, -- GRI, SASB, TCFD
    unit_of_measure VARCHAR(50) NOT NULL,
    optimal_direction VARCHAR(50) NOT NULL, -- higher, lower, neutral
    is_standard BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with standard ESG metrics
INSERT INTO esg_metrics
(metric_name, metric_code, formula, description, category, reporting_standard, unit_of_measure, optimal_direction)
VALUES
('Carbon Intensity', 'CI', 'GHG Emissions / Revenue', 'Measures environmental impact per unit of output', 'environmental', 'GRI 305-3', 'tCO2e/$M revenue', 'lower'),
('Waste Diversion Rate', 'WDR', '(Recycled + Reused Waste) / Total Waste', 'Tracks sustainability efforts', 'environmental', 'GRI 306-2', 'percentage', 'higher'),
('Employee Voluntary Turnover Rate', 'EVTR', '# Employees Leaving Voluntarily / Avg. Workforce', 'Assesses employee satisfaction and HR health', 'social', 'SASB RT-CH-410a.1', 'percentage', 'lower'),
('Community Investment Ratio', 'CIR', 'Community Spending / Revenue', 'Measures social responsibility commitment', 'social', 'GRI 413-1', 'percentage', 'higher'),
('Board Gender Diversity', 'BGD', '# Female Directors / Total Directors', 'Measures gender balance in governance', 'governance', 'SASB CG-000.A', 'percentage', 'higher'),
('Energy Consumption Intensity', 'ECI', 'Total Energy Use / Revenue', 'Tracks energy efficiency', 'environmental', 'GRI 302-1', 'MWh/$M revenue', 'lower'),
('Pay Equity Ratio', 'PER', 'Minority Group Median Pay / Majority Group Median Pay', 'Measures compensation fairness', 'social', 'SASB HR-000.A', 'ratio', 'higher');

--ESG Framework Configuration
CREATE TABLE esg_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_name VARCHAR(100) NOT NULL,
    framework_owner VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    reporting_requirements JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_reporting_periods (
    period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    reporting_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    disclosure_deadline DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    framework_id UUID REFERENCES esg_frameworks(framework_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--Environmental Metrics Tracking
CREATE TABLE carbon_footprint (
    footprint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    scope_1_emissions DECIMAL(19,4), -- Direct emissions
    scope_2_emissions DECIMAL(19,4), -- Indirect emissions from purchased energy
    scope_3_emissions DECIMAL(19,4), -- Other indirect emissions
    total_emissions DECIMAL(19,4) GENERATED ALWAYS AS (COALESCE(scope_1_emissions,0) + COALESCE(scope_2_emissions,0) + COALESCE(scope_3_emissions,0)) STORED,
    revenue DECIMAL(19,4),
    carbon_intensity DECIMAL(19,6) GENERATED ALWAYS AS (CASE WHEN revenue > 0 THEN total_emissions/revenue ELSE NULL END) STORED,
    verification_status VARCHAR(100),
    verified_by VARCHAR(255),
    verification_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE waste_management (
    waste_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    total_waste DECIMAL(19,4) NOT NULL,
    recycled_waste DECIMAL(19,4) NOT NULL,
    reused_waste DECIMAL(19,4) NOT NULL,
    diverted_waste DECIMAL(19,4) GENERATED ALWAYS AS (recycled_waste + reused_waste) STORED,
    waste_diversion_rate DECIMAL(5,4) GENERATED ALWAYS AS (CASE WHEN total_waste > 0 THEN (recycled_waste + reused_waste)/total_waste ELSE NULL END) STORED,
    hazardous_waste DECIMAL(19,4),
    disposal_methods JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE energy_consumption (
    energy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    electricity_consumption DECIMAL(19,4) NOT NULL,
    fuel_consumption DECIMAL(19,4) NOT NULL,
    renewable_energy DECIMAL(19,4) NOT NULL,
    total_energy DECIMAL(19,4) GENERATED ALWAYS AS (electricity_consumption + fuel_consumption) STORED,
    renewable_percentage DECIMAL(5,4) GENERATED ALWAYS AS (CASE WHEN (electricity_consumption + fuel_consumption) > 0 THEN renewable_energy/(electricity_consumption + fuel_consumption) ELSE NULL END) STORED,
    energy_intensity DECIMAL(19,6),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--Social Metrics Tracking
CREATE TABLE workforce_metrics (
    workforce_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    avg_workforce INTEGER NOT NULL,
    voluntary_leavers INTEGER NOT NULL,
    voluntary_turnover_rate DECIMAL(5,4) GENERATED ALWAYS AS (CASE WHEN avg_workforce > 0 THEN voluntary_leavers::decimal/avg_workforce ELSE NULL END) STORED,
    total_turnover_rate DECIMAL(5,4),
    gender_distribution JSONB NOT NULL,
    diversity_index DECIMAL(5,4),
    training_hours_per_employee DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE community_investment (
    investment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    cash_donations DECIMAL(19,4) NOT NULL,
    in_kind_donations DECIMAL(19,4) NOT NULL,
    employee_volunteer_hours INTEGER NOT NULL,
    total_community_investment DECIMAL(19,4) GENERATED ALWAYS AS (cash_donations + in_kind_donations) STORED,
    revenue DECIMAL(19,4),
    community_investment_ratio DECIMAL(5,4) GENERATED ALWAYS AS (CASE WHEN revenue > 0 THEN total_community_investment/revenue ELSE NULL END) STORED,
    focus_areas JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE health_safety_metrics (
    safety_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    total_work_hours DECIMAL(19,4) NOT NULL,
    lost_time_injuries INTEGER NOT NULL,
    recordable_incidents INTEGER NOT NULL,
    trir DECIMAL(10,2) GENERATED ALWAYS AS (CASE WHEN total_work_hours > 0 THEN (recordable_incidents * 200000)/total_work_hours ELSE NULL END) STORED,
    ltir DECIMAL(10,2) GENERATED ALWAYS AS (CASE WHEN total_work_hours > 0 THEN (lost_time_injuries * 200000)/total_work_hours ELSE NULL END) STORED,
    training_completion_rate DECIMAL(5,4),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--Governance Metrics Tracking
CREATE TABLE board_composition (
    board_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    total_directors INTEGER NOT NULL,
    female_directors INTEGER NOT NULL,
    gender_diversity_ratio DECIMAL(5,4) GENERATED ALWAYS AS (CASE WHEN total_directors > 0 THEN female_directors::decimal/total_directors ELSE NULL END) STORED,
    independent_directors INTEGER NOT NULL,
    attendance_rate DECIMAL(5,4),
    committees JSONB NOT NULL,
    term_limits BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE business_ethics (
    ethics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    ethics_training_completion DECIMAL(5,4) NOT NULL,
    reported_incidents INTEGER NOT NULL,
    substantiated_incidents INTEGER NOT NULL,
    whistleblower_cases INTEGER NOT NULL,
    anti_corruption_training DECIMAL(5,4),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--ESG Data Collection and Validation
CREATE TABLE esg_data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    source_name VARCHAR(255) NOT NULL,
    source_type VARCHAR(100) NOT NULL, -- system, manual, third-party
    description TEXT,
    refresh_frequency VARCHAR(50) NOT NULL,
    owner_id UUID REFERENCES users(user_id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_data_points (
    data_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    metric_id UUID NOT NULL REFERENCES esg_metrics(metric_id),
    entity_id UUID NOT NULL REFERENCES legal_entities(entity_id),
    reporting_period VARCHAR(50) NOT NULL,
    raw_value DECIMAL(19,6) NOT NULL,
    adjusted_value DECIMAL(19,6),
    source_id UUID REFERENCES esg_data_sources(source_id),
    collection_date DATE NOT NULL,
    validation_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    validated_by UUID REFERENCES users(user_id),
    validation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_audit_trail (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_id UUID NOT NULL REFERENCES esg_data_points(data_id),
    changed_field VARCHAR(100) NOT NULL,
    previous_value TEXT,
    new_value TEXT NOT NULL,
    change_reason TEXT,
    changed_by UUID REFERENCES users(user_id),
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--ESG Benchmarking and Goals
CREATE TABLE esg_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_id UUID NOT NULL REFERENCES esg_metrics(metric_id),
    industry_code VARCHAR(50) NOT NULL,
    industry_name VARCHAR(255) NOT NULL,
    region VARCHAR(100),
    company_size VARCHAR(50),
    benchmark_year INTEGER NOT NULL,
    percentile_25 DECIMAL(19,6) NOT NULL,
    percentile_50 DECIMAL(19,6) NOT NULL,
    percentile_75 DECIMAL(19,6) NOT NULL,
    sample_size INTEGER,
    source VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_goals (
    goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    goal_name VARCHAR(255) NOT NULL,
    metric_id UUID NOT NULL REFERENCES esg_metrics(metric_id),
    target_value DECIMAL(19,6) NOT NULL,
    baseline_value DECIMAL(19,6) NOT NULL,
    baseline_year INTEGER NOT NULL,
    target_year INTEGER NOT NULL,
    progress DECIMAL(5,4),
    is_science_based BOOLEAN NOT NULL DEFAULT FALSE,
    commitment_public BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    owner_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--ESG reporting and disclosures
CREATE TABLE esg_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    report_name VARCHAR(255) NOT NULL,
    reporting_period VARCHAR(50) NOT NULL,
    framework_id UUID REFERENCES esg_frameworks(framework_id),
    publication_date DATE,
    publication_status VARCHAR(50) NOT NULL DEFAULT 'draft',
    document_id UUID REFERENCES documents(document_id),
    assurance_provider VARCHAR(255),
    assurance_level VARCHAR(100),
    stakeholder_feedback TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_disclosures (
    disclosure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES esg_reports(report_id),
    metric_id UUID NOT NULL REFERENCES esg_metrics(metric_id),
    reported_value DECIMAL(19,6) NOT NULL,
    methodology TEXT,
    limitations TEXT,
    comparative_data JSONB,
    narrative TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--ESG Dashboards and Visualization
CREATE TABLE esg_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    report_name VARCHAR(255) NOT NULL,
    reporting_period VARCHAR(50) NOT NULL,
    framework_id UUID REFERENCES esg_frameworks(framework_id),
    publication_date DATE,
    publication_status VARCHAR(50) NOT NULL DEFAULT 'draft',
    document_id UUID REFERENCES documents(document_id),
    assurance_provider VARCHAR(255),
    assurance_level VARCHAR(100),
    stakeholder_feedback TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE esg_disclosures (
    disclosure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES esg_reports(report_id),
    metric_id UUID NOT NULL REFERENCES esg_metrics(metric_id),
    reported_value DECIMAL(19,6) NOT NULL,
    methodology TEXT,
    limitations TEXT,
    comparative_data JSONB,
    narrative TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Core accounting tables (existing structure)
CREATE TABLE fiscal_periods (
    period_id SERIAL PRIMARY KEY,
    period_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    close_date TIMESTAMP
);

CREATE TABLE general_ledger (
    ledger_id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    normal_balance CHAR(1) CHECK (normal_balance IN ('D', 'C')),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(account_number)
);

-- New tables for Strategic Advisory Metrics

-- M&A Synergy Tracking
CREATE TABLE ma_transactions (
    transaction_id SERIAL PRIMARY KEY,
    deal_name VARCHAR(100) NOT NULL,
    announcement_date DATE,
    closing_date DATE,
    deal_value NUMERIC(15,2),
    expected_synergies NUMERIC(15,2),
    synergy_target_date DATE,
    status VARCHAR(50) CHECK (status IN ('Planning', 'Integration', 'Completed', 'Abandoned'))
);

CREATE TABLE synergy_metrics (
    metric_id SERIAL PRIMARY KEY,
    transaction_id INTEGER REFERENCES ma_transactions(transaction_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    synergy_type VARCHAR(50) CHECK (synergy_type IN ('Cost', 'Revenue', 'Capital')),
    target_value NUMERIC(15,2),
    actual_value NUMERIC(15,2),
    variance NUMERIC(15,2) GENERATED ALWAYS AS (actual_value - target_value) STORED,
    realization_rate NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE WHEN target_value = 0 THEN NULL
        ELSE (actual_value / target_value) * 100 END
    ) STORED,
    notes TEXT,
    UNIQUE(transaction_id, period_id, synergy_type)
);

-- Customer Lifetime Value Tracking
CREATE TABLE customer_segments (
    segment_id SERIAL PRIMARY KEY,
    segment_name VARCHAR(100) NOT NULL,
    definition TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE clv_metrics (
    clv_id SERIAL PRIMARY KEY,
    segment_id INTEGER REFERENCES customer_segments(segment_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    avg_revenue_per_customer NUMERIC(15,2),
    avg_customer_lifespan_months INTEGER,
    customer_lifetime_value NUMERIC(15,2) GENERATED ALWAYS AS
        (avg_revenue_per_customer * avg_customer_lifespan_months) STORED,
    acquisition_cost NUMERIC(15,2),
    retention_rate NUMERIC(5,2),
    UNIQUE(segment_id, period_id)
);

-- Strategic Initiatives Tracking
CREATE TABLE strategic_initiatives (
    initiative_id SERIAL PRIMARY KEY,
    initiative_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE,
    target_completion_date DATE,
    actual_completion_date DATE,
    status VARCHAR(50) CHECK (status IN ('Planning', 'In Progress', 'Completed', 'On Hold', 'Cancelled')),
    strategic_goal TEXT,
    responsible_party VARCHAR(100)
);

CREATE TABLE initiative_roi (
    roi_id SERIAL PRIMARY KEY,
    initiative_id INTEGER REFERENCES strategic_initiatives(initiative_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    total_cost NUMERIC(15,2),
    quantified_benefits NUMERIC(15,2),
    qualitative_benefits_score INTEGER CHECK (qualitative_benefits_score BETWEEN 1 AND 10),
    roi_percentage NUMERIC(10,2) GENERATED ALWAYS AS (
        CASE WHEN total_cost = 0 THEN NULL
        ELSE ((quantified_benefits - total_cost) / total_cost) * 100 END
    ) STORED,
    notes TEXT,
    UNIQUE(initiative_id, period_id)
);

-- Capital Allocation Tracking
CREATE TABLE capital_projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) CHECK (category IN ('Growth', 'Maintenance', 'Efficiency', 'Regulatory')),
    start_date DATE,
    completion_date DATE,
    total_budget NUMERIC(15,2),
    strategic_priority INTEGER CHECK (strategic_priority BETWEEN 1 AND 5)
);

CREATE TABLE capital_returns (
    return_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES capital_projects(project_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    capital_invested NUMERIC(15,2),
    return_generated NUMERIC(15,2),
    roi_percentage NUMERIC(10,2) GENERATED ALWAYS AS (
        CASE WHEN capital_invested = 0 THEN NULL
        ELSE (return_generated / capital_invested) * 100 END
    ) STORED,
    notes TEXT,
    UNIQUE(project_id, period_id)
);





-- Views for analytical reporting

-- M&A Synergy Realization Dashboard
CREATE VIEW ma_synergy_dashboard AS
SELECT
    t.deal_name,
    p.period_name,
    sm.synergy_type,
    sm.target_value,
    sm.actual_value,
    sm.variance,
    sm.realization_rate,
    t.expected_synergies,
    (SELECT SUM(actual_value) FROM synergy_metrics WHERE transaction_id = t.transaction_id) AS total_actual_synergies
FROM synergy_metrics sm
JOIN ma_transactions t ON sm.transaction_id = t.transaction_id
JOIN fiscal_periods p ON sm.period_id = p.period_id;

-- Customer Lifetime Value Analysis
CREATE VIEW customer_value_analysis AS
SELECT
    s.segment_name,
    p.period_name,
    cm.avg_revenue_per_customer,
    cm.avg_customer_lifespan_months,
    cm.customer_lifetime_value,
    cm.acquisition_cost,
    (cm.customer_lifetime_value - cm.acquisition_cost) AS net_customer_value,
    cm.retention_rate
FROM clv_metrics cm
JOIN customer_segments s ON cm.segment_id = s.segment_id
JOIN fiscal_periods p ON cm.period_id = p.period_id;

-- Strategic Initiative ROI Tracking
CREATE VIEW strategic_initiative_performance AS
SELECT
    si.initiative_name,
    p.period_name,
    ir.total_cost,
    ir.quantified_benefits,
    ir.roi_percentage,
    ir.qualitative_benefits_score,
    si.status,
    (ir.quantified_benefits - ir.total_cost) AS net_benefit
FROM initiative_roi ir
JOIN strategic_initiatives si ON ir.initiative_id = si.initiative_id
JOIN fiscal_periods p ON ir.period_id = p.period_id;

-- Capital Allocation Effectiveness
CREATE VIEW capital_allocation_roi AS
SELECT
    cp.project_name,
    cp.category,
    p.period_name,
    cr.capital_invested,
    cr.return_generated,
    cr.roi_percentage,
    cp.strategic_priority,
    (cr.return_generated - cr.capital_invested) AS net_return
FROM capital_returns cr
JOIN capital_projects cp ON cr.project_id = cp.project_id
JOIN fiscal_periods p ON cr.period_id = p.period_id;

--Technology and Automation Metrics
-- Add Technology & Automation tables to the enterprise_cpa schema

-- Automation Systems Catalog
CREATE TABLE automation_systems (
    system_id SERIAL PRIMARY KEY,
    system_name VARCHAR(100) NOT NULL,
    description TEXT,
    implementation_date DATE,
    vendor VARCHAR(100),
    system_type VARCHAR(50) CHECK (system_type IN ('RPA', 'AI/ML', 'Workflow', 'Data Processing', 'ERP Integration')),
    is_critical BOOLEAN DEFAULT FALSE,
    UNIQUE(system_name)
);

-- Automation Uptime Tracking
CREATE TABLE system_uptime_metrics (
    uptime_id SERIAL PRIMARY KEY,
    system_id INTEGER REFERENCES automation_systems(system_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    total_available_minutes INTEGER,
    downtime_minutes INTEGER,
    uptime_percentage NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE WHEN total_available_minutes = 0 THEN NULL
        ELSE ((total_available_minutes - downtime_minutes)::NUMERIC / total_available_minutes) * 100 END
    ) STORED,
    major_incidents INTEGER,
    root_cause_analysis TEXT,
    UNIQUE(system_id, period_id)
);

-- AI Productivity Gains
CREATE TABLE automation_productivity (
    productivity_id SERIAL PRIMARY KEY,
    system_id INTEGER REFERENCES automation_systems(system_id),
    process_name VARCHAR(100) NOT NULL,
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    manual_hours NUMERIC(10,2),
    automated_hours NUMERIC(10,2),
    hours_saved NUMERIC(10,2) GENERATED ALWAYS AS (manual_hours - automated_hours) STORED,
    fte_equivalent NUMERIC(10,2) GENERATED ALWAYS AS ((manual_hours - automated_hours) / 160) STORED, -- Assuming 160 working hours/month
    process_owner VARCHAR(100),
    UNIQUE(system_id, process_name, period_id)
);

-- Error Reduction Tracking
CREATE TABLE error_metrics (
    error_id SERIAL PRIMARY KEY,
    system_id INTEGER REFERENCES automation_systems(system_id),
    process_name VARCHAR(100) NOT NULL,
    pre_automation_period_id INTEGER REFERENCES fiscal_periods(period_id),
    post_automation_period_id INTEGER REFERENCES fiscal_periods(period_id),
    errors_before INTEGER,
    errors_after INTEGER,
    error_reduction_rate NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE WHEN errors_before = 0 THEN NULL
        ELSE ((errors_before - errors_after)::NUMERIC / errors_before) * 100 END
    ) STORED,
    error_severity VARCHAR(20) CHECK (error_severity IN ('Critical', 'High', 'Medium', 'Low')),
    UNIQUE(system_id, process_name, pre_automation_period_id)
);

-- System Integration Tracking
CREATE TABLE integration_projects (
    integration_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    target_system VARCHAR(100) NOT NULL,
    start_date DATE,
    completion_date DATE,
    project_owner VARCHAR(100),
    integration_type VARCHAR(50) CHECK (integration_type IN ('ERP', 'CRM', 'Database', 'API', 'ETL')),
    complexity_level INTEGER CHECK (complexity_level BETWEEN 1 AND 5)
);

CREATE TABLE integration_attempts (
    attempt_id SERIAL PRIMARY KEY,
    integration_id INTEGER REFERENCES integration_projects(integration_id),
    attempt_date TIMESTAMP,
    is_successful BOOLEAN,
    duration_minutes INTEGER,
    data_volume INTEGER, -- in records or MB
    error_message TEXT,
    resolution_notes TEXT
);

-- Views for Technology & Automation Analytics

-- Automation Reliability Dashboard
CREATE VIEW automation_reliability_view AS
SELECT
    a.system_name,
    a.system_type,
    p.period_name,
    um.uptime_percentage,
    um.downtime_minutes,
    um.major_incidents,
    CASE
        WHEN um.uptime_percentage >= 99.9 THEN 'Excellent'
        WHEN um.uptime_percentage >= 99.0 THEN 'Good'
        WHEN um.uptime_percentage >= 95.0 THEN 'Fair'
        ELSE 'Poor'
    END AS reliability_status
FROM system_uptime_metrics um
JOIN automation_systems a ON um.system_id = a.system_id
JOIN fiscal_periods p ON um.period_id = p.period_id;

-- Productivity Gains Analysis
CREATE VIEW productivity_gains_view AS
SELECT
    a.system_name,
    ap.process_name,
    p.period_name,
    ap.manual_hours,
    ap.automated_hours,
    ap.hours_saved,
    ap.fte_equivalent,
    (ap.hours_saved / NULLIF(ap.manual_hours, 0) * 100) AS efficiency_gain_percentage
FROM automation_productivity ap
JOIN automation_systems a ON ap.system_id = a.system_id
JOIN fiscal_periods p ON ap.period_id = p.period_id;

-- Error Reduction Analysis
CREATE VIEW error_reduction_view AS
SELECT
    a.system_name,
    em.process_name,
    pre_p.period_name AS pre_automation_period,
    post_p.period_name AS post_automation_period,
    em.errors_before,
    em.errors_after,
    em.error_reduction_rate,
    em.error_severity,
    CASE
        WHEN em.error_reduction_rate >= 90 THEN 'Exceptional Improvement'
        WHEN em.error_reduction_rate >= 70 THEN 'Significant Improvement'
        WHEN em.error_reduction_rate >= 50 THEN 'Moderate Improvement'
        ELSE 'Needs Review'
    END AS improvement_status
FROM error_metrics em
JOIN automation_systems a ON em.system_id = a.system_id
JOIN fiscal_periods pre_p ON em.pre_automation_period_id = pre_p.period_id
JOIN fiscal_periods post_p ON em.post_automation_period_id = post_p.period_id;

-- Integration Success Metrics
CREATE VIEW integration_success_view AS
SELECT
    ip.project_name,
    ip.source_system,
    ip.target_system,
    ip.integration_type,
    COUNT(ia.attempt_id) AS total_attempts,
    SUM(CASE WHEN ia.is_successful THEN 1 ELSE 0 END) AS successful_attempts,
    (SUM(CASE WHEN ia.is_successful THEN 1 ELSE 0 END)::NUMERIC /
        NULLIF(COUNT(ia.attempt_id), 0) * 100 AS success_rate,
    AVG(ia.duration_minutes) AS avg_duration_minutes,
    MAX(ia.attempt_date) AS last_attempt_date
FROM integration_attempts ia
JOIN integration_projects ip ON ia.integration_id = ip.integration_id
GROUP BY ip.project_name, ip.source_system, ip.target_system, ip.integration_type;

--real-time consolidation engines -- consolidation of subsidiaries

-- Add Real-Time Consolidation Engine tables to the enterprise_cpa schema

-- Subsidiary Master Table
CREATE TABLE subsidiaries (
    subsidiary_id SERIAL PRIMARY KEY,
    subsidiary_name VARCHAR(100) NOT NULL,
    legal_entity_id VARCHAR(50),
    country_code CHAR(2) NOT NULL,
    reporting_currency CHAR(3) NOT NULL,
    local_currency CHAR(3) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    consolidation_method VARCHAR(20) CHECK (consolidation_method IN ('Full', 'Proportional', 'Equity')),
    fiscal_year_end DATE,
    UNIQUE(subsidiary_name)
);

-- Consolidation Periods (extends fiscal_periods)
ALTER TABLE fiscal_periods ADD COLUMN is_consolidated BOOLEAN DEFAULT FALSE;
ALTER TABLE fiscal_periods ADD COLUMN consolidation_run_date TIMESTAMP;

-- Currency Exchange Rates
CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate_date DATE NOT NULL,
    rate_value NUMERIC(15,6) NOT NULL,
    rate_type VARCHAR(20) CHECK (rate_type IN ('Spot', 'Average', 'Closing')),
    source VARCHAR(50),
    UNIQUE(from_currency, to_currency, rate_date, rate_type)
);

-- Consolidated Financial Statements
CREATE TABLE consolidated_statements (
    statement_id SERIAL PRIMARY KEY,
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    statement_type VARCHAR(20) CHECK (statement_type IN ('BalanceSheet', 'IncomeStatement', 'CashFlow')),
    consolidation_version INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    approval_status VARCHAR(20) DEFAULT 'Draft' CHECK (approval_status IN ('Draft', 'Reviewed', 'Approved', 'Published'))
);

-- Consolidated Account Balances
CREATE TABLE consolidated_balances (
    balance_id SERIAL PRIMARY KEY,
    statement_id INTEGER REFERENCES consolidated_statements(statement_id),
    account_number VARCHAR(20) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    reporting_currency_amount NUMERIC(15,2) NOT NULL,
    local_currency_amount NUMERIC(15,2),
    consolidation_adjustments NUMERIC(15,2) DEFAULT 0,
    intercompany_eliminations NUMERIC(15,2) DEFAULT 0,
    tax_adjustments NUMERIC(15,2) DEFAULT 0,
    final_amount NUMERIC(15,2) GENERATED ALWAYS AS (
        reporting_currency_amount + consolidation_adjustments + intercompany_eliminations + tax_adjustments
    ) STORED,
    UNIQUE(statement_id, account_number)
);

-- Intercompany Transactions
CREATE TABLE intercompany_transactions (
    transaction_id SERIAL PRIMARY KEY,
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    transaction_date DATE NOT NULL,
    originating_subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    receiving_subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    transaction_type VARCHAR(50) CHECK (transaction_type IN ('Loan', 'Goods', 'Services', 'Royalty', 'Dividend')),
    original_amount NUMERIC(15,2) NOT NULL,
    original_currency CHAR(3) NOT NULL,
    description TEXT,
    is_eliminated BOOLEAN DEFAULT FALSE,
    elimination_entry_id INTEGER
);

-- Consolidation Mappings
CREATE TABLE consolidation_mappings (
    mapping_id SERIAL PRIMARY KEY,
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    local_account VARCHAR(20) NOT NULL,
    consolidation_account VARCHAR(20) NOT NULL,
    mapping_rules JSONB,
    UNIQUE(subsidiary_id, local_account)
);

-- Transaction Drill-Through View
CREATE TABLE consolidated_transaction_links (
    link_id SERIAL PRIMARY KEY,
    consolidated_balance_id INTEGER REFERENCES consolidated_balances(balance_id),
    source_subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    source_transaction_id VARCHAR(50) NOT NULL, -- References source system IDs
    source_system VARCHAR(50) NOT NULL,
    transaction_amount NUMERIC(15,2) NOT NULL,
    contribution_percentage NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE WHEN consolidated_balance_id IS NULL THEN NULL
        ELSE (transaction_amount / NULLIF(
            (SELECT reporting_currency_amount
             FROM consolidated_balances
             WHERE balance_id = consolidated_balance_id), 0)) * 100
        END
    ) STORED
);

-- Consolidation Audit Trail
CREATE TABLE consolidation_audit_log (
    log_id SERIAL PRIMARY KEY,
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('Run', 'Adjust', 'Approve', 'Publish', 'Rollback')),
    user_id VARCHAR(50) NOT NULL,
    action_details JSONB,
    system_version VARCHAR(50)
);

-- Views for Real-Time Consolidation

-- Consolidated Financial Statement View
CREATE VIEW consolidated_financial_view AS
SELECT
    cs.statement_id,
    fp.period_name,
    cs.statement_type,
    cs.consolidation_version,
    cs.approval_status,
    cb.account_number,
    cb.account_name,
    cb.reporting_currency_amount AS raw_amount,
    cb.consolidation_adjustments,
    cb.intercompany_eliminations,
    cb.tax_adjustments,
    cb.final_amount,
    COUNT(ctl.link_id) AS source_transaction_count
FROM consolidated_statements cs
JOIN fiscal_periods fp ON cs.period_id = fp.period_id
JOIN consolidated_balances cb ON cs.statement_id = cb.statement_id
LEFT JOIN consolidated_transaction_links ctl ON cb.balance_id = ctl.consolidated_balance_id
GROUP BY cs.statement_id, fp.period_name, cs.statement_type, cs.consolidation_version,
         cs.approval_status, cb.account_number, cb.account_name, cb.reporting_currency_amount,
         cb.consolidation_adjustments, cb.intercompany_eliminations, cb.tax_adjustments, cb.final_amount;

-- Intercompany Reconciliation View
CREATE VIEW intercompany_reconciliation_view AS
SELECT
    fp.period_name,
    s1.subsidiary_name AS originating_entity,
    s2.subsidiary_name AS receiving_entity,
    it.transaction_type,
    SUM(it.original_amount) AS gross_amount,
    COUNT(it.transaction_id) AS transaction_count,
    SUM(CASE WHEN it.is_eliminated THEN it.original_amount ELSE 0 END) AS eliminated_amount
FROM intercompany_transactions it
JOIN fiscal_periods fp ON it.period_id = fp.period_id
JOIN subsidiaries s1 ON it.originating_subsidiary_id = s1.subsidiary_id
JOIN subsidiaries s2 ON it.receiving_subsidiary_id = s2.subsidiary_id
GROUP BY fp.period_name, s1.subsidiary_name, s2.subsidiary_name, it.transaction_type;

-- Currency Exposure View
CREATE VIEW currency_exposure_view AS
SELECT
    fp.period_name,
    s.subsidiary_name,
    s.country_code,
    s.local_currency,
    SUM(cb.local_currency_amount) AS local_amount,
    SUM(cb.reporting_currency_amount) AS reporting_amount,
    (SUM(cb.reporting_currency_amount) / NULLIF(SUM(cb.local_currency_amount), 0)) AS effective_rate,
    er.rate_value AS period_end_rate
FROM consolidated_balances cb
JOIN consolidated_statements cs ON cb.statement_id = cs.statement_id
JOIN fiscal_periods fp ON cs.period_id = fp.period_id
JOIN subsidiaries s ON cb.account_number LIKE s.subsidiary_id || '-%'
LEFT JOIN exchange_rates er ON s.local_currency = er.from_currency
    AND er.to_currency = 'USD' -- Assuming USD is reporting currency
    AND er.rate_date = fp.end_date
    AND er.rate_type = 'Closing'
GROUP BY fp.period_name, s.subsidiary_name, s.country_code, s.local_currency, er.rate_value;

-- Stored Procedures for Real-Time Consolidation

-- Procedure for Running Consolidation
CREATE OR REPLACE FUNCTION run_consolidation(p_period_id INTEGER, p_user_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    v_statement_id INTEGER;
    v_version INTEGER;
BEGIN
    -- Get next version number
    SELECT COALESCE(MAX(consolidation_version), 0) + 1 INTO v_version
    FROM consolidated_statements
    WHERE period_id = p_period_id;

    -- Create new consolidation statement
    INSERT INTO consolidated_statements (period_id, statement_type, consolidation_version, created_by)
    VALUES (p_period_id, 'BalanceSheet', v_version, p_user_id)
    RETURNING statement_id INTO v_statement_id;

    INSERT INTO consolidated_statements (period_id, statement_type, consolidation_version, created_by)
    VALUES (p_period_id, 'IncomeStatement', v_version, p_user_id);

    INSERT INTO consolidated_statements (period_id, statement_type, consolidation_version, created_by)
    VALUES (p_period_id, 'CashFlow', v_version, p_user_id);

    -- Mark period as consolidated
    UPDATE fiscal_periods
    SET is_consolidated = TRUE,
        consolidation_run_date = CURRENT_TIMESTAMP
    WHERE period_id = p_period_id;

    -- Log the consolidation run
    INSERT INTO consolidation_audit_log (period_id, action_type, user_id, action_details)
    VALUES (p_period_id, 'Run', p_user_id,
            jsonb_build_object('version', v_version, 'statements_created', 3));

    RETURN v_version;
END;
$$ LANGUAGE plpgsql;

--allow teams to build financial planning models without using excel
--financial planning models
-- Add Dynamic FP&A Workbench tables to the enterprise_cpa schema

-- FP&A Models Master Table
CREATE TABLE fpa_models (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    description TEXT,
    model_type VARCHAR(50) CHECK (model_type IN ('Budget', 'Forecast', 'Scenario', 'Variance Analysis')),
    base_currency CHAR(3) NOT NULL,
    time_granularity VARCHAR(20) CHECK (time_granularity IN ('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Annual')),
    is_template BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    last_modified TIMESTAMP,
    UNIQUE(model_name)
);

-- Model Versions
CREATE TABLE fpa_model_versions (
    version_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    version_number INTEGER NOT NULL,
    version_label VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('Draft', 'Published', 'Archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    notes TEXT,
    parent_version_id INTEGER REFERENCES fpa_model_versions(version_id),
    UNIQUE(model_id, version_number)
);

-- Model Structure (Dimensions)
CREATE TABLE fpa_dimensions (
    dimension_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    dimension_name VARCHAR(50) NOT NULL,
    dimension_type VARCHAR(50) CHECK (dimension_type IN ('Time', 'Account', 'Entity', 'Product', 'Region', 'Custom')),
    hierarchy_level INTEGER DEFAULT 1,
    parent_dimension_id INTEGER REFERENCES fpa_dimensions(dimension_id),
    UNIQUE(model_id, dimension_name)
);

-- Dimension Members
CREATE TABLE fpa_dimension_members (
    member_id SERIAL PRIMARY KEY,
    dimension_id INTEGER REFERENCES fpa_dimensions(dimension_id),
    member_code VARCHAR(50) NOT NULL,
    member_name VARCHAR(100) NOT NULL,
    parent_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    properties JSONB,
    UNIQUE(dimension_id, member_code)
);

-- Model Data (Cells)
CREATE TABLE fpa_cell_data (
    cell_id SERIAL PRIMARY KEY,
    version_id INTEGER REFERENCES fpa_model_versions(version_id),
    time_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    account_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    entity_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    scenario_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    value NUMERIC(20,4),
    data_type VARCHAR(20) CHECK (data_type IN ('Actual', 'Budget', 'Forecast', 'Adjustment', 'Calculated')),
    source_system VARCHAR(50),
    source_reference VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(50),
    UNIQUE(version_id, time_member_id, account_member_id, entity_member_id, scenario_member_id)
);

-- Model Formulas
CREATE TABLE fpa_formulas (
    formula_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    formula_name VARCHAR(100) NOT NULL,
    formula_expression TEXT NOT NULL,
    output_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    calculation_order INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(model_id, formula_name)
);

-- What-If Scenarios
CREATE TABLE fpa_scenarios (
    scenario_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    scenario_name VARCHAR(100) NOT NULL,
    base_version_id INTEGER REFERENCES fpa_model_versions(version_id),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    status VARCHAR(20) DEFAULT 'Draft' CHECK (status IN ('Draft', 'Active', 'Approved', 'Rejected')),
    UNIQUE(model_id, scenario_name)
);

-- Scenario Assumptions
CREATE TABLE fpa_scenario_assumptions (
    assumption_id SERIAL PRIMARY KEY,
    scenario_id INTEGER REFERENCES fpa_scenarios(scenario_id),
    assumption_name VARCHAR(100) NOT NULL,
    target_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    adjustment_type VARCHAR(20) CHECK (adjustment_type IN ('Absolute', 'Percentage', 'Formula')),
    adjustment_value NUMERIC(20,4),
    adjustment_formula TEXT,
    UNIQUE(scenario_id, assumption_name, target_member_id)
);

-- ERP Integration Mappings
CREATE TABLE fpa_erp_mappings (
    mapping_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    erp_system VARCHAR(50) NOT NULL,
    erp_account_code VARCHAR(50) NOT NULL,
    model_member_id INTEGER REFERENCES fpa_dimension_members(member_id),
    mapping_rules JSONB,
    last_sync_date TIMESTAMP,
    UNIQUE(model_id, erp_system, erp_account_code)
);

-- Collaboration Features
CREATE TABLE fpa_comments (
    comment_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    version_id INTEGER REFERENCES fpa_model_versions(version_id),
    cell_id INTEGER REFERENCES fpa_cell_data(cell_id),
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(50)
);

CREATE TABLE fpa_change_log (
    change_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES fpa_models(model_id),
    version_id INTEGER REFERENCES fpa_model_versions(version_id),
    change_type VARCHAR(50) NOT NULL,
    change_details JSONB NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50)
);

-- Views for FP&A Workbench

-- Model Data Cube View
CREATE VIEW fpa_data_cube_view AS
SELECT
    m.model_name,
    mv.version_number,
    mv.version_label,
    t.member_name AS time_period,
    a.member_name AS account,
    e.member_name AS entity,
    s.member_name AS scenario,
    cd.value,
    cd.data_type,
    cd.last_updated
FROM fpa_cell_data cd
JOIN fpa_model_versions mv ON cd.version_id = mv.version_id
JOIN fpa_models m ON mv.model_id = m.model_id
JOIN fpa_dimension_members t ON cd.time_member_id = t.member_id
JOIN fpa_dimension_members a ON cd.account_member_id = a.member_id
JOIN fpa_dimension_members e ON cd.entity_member_id = e.member_id
LEFT JOIN fpa_dimension_members s ON cd.scenario_member_id = s.member_id;

-- Formula Dependencies View
CREATE VIEW fpa_formula_dependencies AS
WITH formula_outputs AS (
    SELECT
        f.formula_id,
        f.formula_name,
        dm.member_id,
        dm.member_name,
        d.dimension_name
    FROM fpa_formulas f
    JOIN fpa_dimension_members dm ON f.output_member_id = dm.member_id
    JOIN fpa_dimensions d ON dm.dimension_id = d.dimension_id
)
SELECT
    fo.formula_id,
    fo.formula_name,
    fo.member_name AS output_member,
    fo.dimension_name AS output_dimension,
    cd.cell_id,
    cd.value,
    cd.last_updated
FROM formula_outputs fo
JOIN fpa_cell_data cd ON fo.member_id = cd.account_member_id OR
                        fo.member_id = cd.entity_member_id OR
                        fo.member_id = cd.scenario_member_id;

-- Scenario Impact Analysis View
CREATE VIEW fpa_scenario_impact_view AS
SELECT
    s.scenario_name,
    m.model_name,
    base.member_name AS base_member,
    base_val.value AS base_value,
    scenario_val.value AS scenario_value,
    (scenario_val.value - base_val.value) AS absolute_change,
    CASE WHEN base_val.value = 0 THEN NULL
         ELSE ((scenario_val.value - base_val.value) / NULLIF(base_val.value, 0)) * 100
    END AS percentage_change,
    sa.assumption_name,
    sa.adjustment_type
FROM fpa_scenarios s
JOIN fpa_models m ON s.model_id = m.model_id
JOIN fpa_scenario_assumptions sa ON s.scenario_id = sa.scenario_id
JOIN fpa_dimension_members base ON sa.target_member_id = base.member_id
JOIN fpa_cell_data base_val ON base.member_id = base_val.account_member_id
    AND s.base_version_id = base_val.version_id
JOIN fpa_cell_data scenario_val ON base.member_id = scenario_val.account_member_id
    AND scenario_val.version_id IN (
        SELECT version_id FROM fpa_model_versions
        WHERE model_id = s.model_id AND version_label = s.scenario_name
    );

-- Stored Procedures for FP&A Workbench

-- Create New Model Version
CREATE OR REPLACE FUNCTION create_model_version(
    p_model_id INTEGER,
    p_user_id VARCHAR,
    p_version_label VARCHAR DEFAULT NULL,
    p_parent_version_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_version_number INTEGER;
    v_new_version_id INTEGER;
BEGIN
    -- Get next version number
    SELECT COALESCE(MAX(version_number), 0) + 1 INTO v_version_number
    FROM fpa_model_versions
    WHERE model_id = p_model_id;

    -- Create new version
    INSERT INTO fpa_model_versions (
        model_id, version_number, version_label, status,
        created_by, parent_version_id
    )
    VALUES (
        p_model_id, v_version_number, p_version_label, 'Draft',
        p_user_id, p_parent_version_id
    )
    RETURNING version_id INTO v_new_version_id;

    -- Copy data from parent version if specified
    IF p_parent_version_id IS NOT NULL THEN
        INSERT INTO fpa_cell_data (
            version_id, time_member_id, account_member_id,
            entity_member_id, scenario_member_id, value,
            data_type, source_system, source_reference
        )
        SELECT
            v_new_version_id, time_member_id, account_member_id,
            entity_member_id, scenario_member_id, value,
            data_type, source_system, source_reference
        FROM fpa_cell_data
        WHERE version_id = p_parent_version_id;
    END IF;

    -- Log the version creation
    INSERT INTO fpa_change_log (
        model_id, version_id, change_type, change_details, changed_by
    )
    VALUES (
        p_model_id, v_new_version_id, 'Version Created',
        jsonb_build_object('parent_version', p_parent_version_id, 'label', p_version_label),
        p_user_id
    );

    RETURN v_new_version_id;
END;
$$ LANGUAGE plpgsql;

-- Calculate Formula Values
CREATE OR REPLACE FUNCTION calculate_formula_values(
    p_version_id INTEGER,
    p_user_id VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_formula RECORD;
    v_result NUMERIC;
BEGIN
    -- Process all active formulas for the model
    FOR v_formula IN
        SELECT f.formula_id, f.formula_expression, f.output_member_id,
               m.model_id, dm.dimension_name
        FROM fpa_formulas f
        JOIN fpa_model_versions mv ON f.model_id = mv.model_id
        JOIN fpa_models m ON f.model_id = m.model_id
        JOIN fpa_dimension_members dm ON f.output_member_id = dm.member_id
        WHERE mv.version_id = p_version_id AND f.is_active = TRUE
        ORDER BY f.calculation_order NULLS LAST
    LOOP
        -- Execute the formula (simplified example - real implementation would need a proper expression evaluator)
        EXECUTE 'SELECT ' || v_formula.formula_expression || '::NUMERIC'
        INTO v_result
        USING p_version_id;

        -- Insert or update the calculated value
        INSERT INTO fpa_cell_data (
            version_id, time_member_id, account_member_id,
            entity_member_id, scenario_member_id, value,
            data_type, source_system, source_reference, updated_by
        )
        VALUES (
            p_version_id,
            CASE WHEN v_formula.dimension_name = 'Time' THEN v_formula.output_member_id ELSE NULL END,
            CASE WHEN v_formula.dimension_name = 'Account' THEN v_formula.output_member_id ELSE NULL END,
            CASE WHEN v_formula.dimension_name = 'Entity' THEN v_formula.output_member_id ELSE NULL END,
            CASE WHEN v_formula.dimension_name = 'Scenario' THEN v_formula.output_member_id ELSE NULL END,
            v_result, 'Calculated', 'FP&A Engine', 'Formula: ' || v_formula.formula_id, p_user_id
        )
        ON CONFLICT (version_id, time_member_id, account_member_id, entity_member_id, scenario_member_id)
        DO UPDATE SET
            value = EXCLUDED.value,
            data_type = EXCLUDED.data_type,
            source_system = EXCLUDED.source_system,
            source_reference = EXCLUDED.source_reference,
            last_updated = CURRENT_TIMESTAMP,
            updated_by = EXCLUDED.updated_by;

        -- Log the calculation
        INSERT INTO fpa_change_log (
            model_id, version_id, change_type, change_details, changed_by
        )
        VALUES (
            v_formula.model_id, p_version_id, 'Formula Calculated',
            jsonb_build_object('formula_id', v_formula.formula_id, 'result', v_result),
            p_user_id
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--predictive cash flow forecasting

-- Add Predictive Cash Flow Forecasting tables to the enterprise_cpa schema

-- Cash Flow Categories
CREATE TABLE cash_flow_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    direction CHAR(1) CHECK (direction IN ('I', 'O')), -- I=Inflow, O=Outflow
    is_operational BOOLEAN DEFAULT TRUE,
    volatility_rating INTEGER CHECK (volatility_rating BETWEEN 1 AND 5),
    UNIQUE(category_name, direction)
);

-- Historical Cash Flow Data
CREATE TABLE cash_flow_history (
    entry_id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES cash_flow_categories(category_id),
    entry_date DATE NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    entity_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    source_system VARCHAR(50),
    transaction_reference VARCHAR(100),
    is_recurring BOOLEAN DEFAULT FALSE,
    UNIQUE(category_id, entry_date, entity_id, transaction_reference)
);

-- External Economic Indicators
CREATE TABLE economic_indicators (
    indicator_id SERIAL PRIMARY KEY,
    indicator_name VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    frequency VARCHAR(20) CHECK (frequency IN ('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Annual')),
    unit VARCHAR(20),
    description TEXT,
    UNIQUE(indicator_name, source)
);

-- Economic Indicator Values
CREATE TABLE economic_indicator_values (
    value_id SERIAL PRIMARY KEY,
    indicator_id INTEGER REFERENCES economic_indicators(indicator_id),
    value_date DATE NOT NULL,
    value NUMERIC(15,4) NOT NULL,
    revision_number INTEGER DEFAULT 1,
    UNIQUE(indicator_id, value_date, revision_number)
);

-- Supply Chain Risk Factors
CREATE TABLE supply_chain_risk_factors (
    factor_id SERIAL PRIMARY KEY,
    factor_name VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    industry VARCHAR(100),
    severity_level INTEGER CHECK (severity_level BETWEEN 1 AND 5),
    start_date DATE,
    end_date DATE,
    description TEXT,
    UNIQUE(factor_name, region, industry)
);

-- Cash Flow Forecast Models
CREATE TABLE cash_flow_models (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) CHECK (model_type IN ('ARIMA', 'Prophet', 'LSTM', 'Regression', 'Ensemble')),
    entity_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    currency CHAR(3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_trained_at TIMESTAMP,
    training_period_start DATE,
    training_period_end DATE,
    model_metrics JSONB,
    model_parameters JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(model_name, entity_id)
);

-- Model Features (Input Variables)
CREATE TABLE model_features (
    feature_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES cash_flow_models(model_id),
    feature_type VARCHAR(50) CHECK (feature_type IN ('Historical', 'Economic', 'Risk', 'Calendar')),
    source_id INTEGER, -- References various tables depending on feature_type
    source_column VARCHAR(50),
    lag_period INTEGER DEFAULT 0,
    transformation VARCHAR(50),
    importance_score NUMERIC(5,2),
    UNIQUE(model_id, feature_type, source_id, source_column)
);

-- Cash Flow Forecasts
CREATE TABLE cash_flow_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES cash_flow_models(model_id),
    forecast_date DATE NOT NULL,
    forecast_run_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    horizon_days INTEGER NOT NULL,
    confidence_level NUMERIC(5,2) DEFAULT 0.95,
    UNIQUE(model_id, forecast_date, horizon_days)
);

-- Forecast Details
CREATE TABLE forecast_details (
    detail_id SERIAL PRIMARY KEY,
    forecast_id INTEGER REFERENCES cash_flow_forecasts(forecast_id),
    category_id INTEGER REFERENCES cash_flow_categories(category_id),
    forecast_day DATE NOT NULL,
    predicted_amount NUMERIC(15,2) NOT NULL,
    lower_bound NUMERIC(15,2),
    upper_bound NUMERIC(15,2),
    baseline_amount NUMERIC(15,2), -- For comparison with non-ML forecasts
    UNIQUE(forecast_id, category_id, forecast_day)
);

-- Liquidity Alerts
CREATE TABLE liquidity_alerts (
    alert_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    projected_date DATE NOT NULL,
    projected_balance NUMERIC(15,2) NOT NULL,
    threshold_amount NUMERIC(15,2) NOT NULL,
    alert_severity INTEGER CHECK (alert_severity BETWEEN 1 AND 3), -- 1=Warning, 2=Critical, 3=Emergency
    triggered_by_model INTEGER REFERENCES cash_flow_models(model_id),
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Acknowledged', 'Resolved')),
    resolution_notes TEXT
);

-- Alert Notification Rules
CREATE TABLE alert_rules (
    rule_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    rule_name VARCHAR(100) NOT NULL,
    time_horizon_days INTEGER NOT NULL,
    threshold_type VARCHAR(20) CHECK (threshold_type IN ('Absolute', 'Percentage', 'Statistical')),
    threshold_value NUMERIC(15,2) NOT NULL,
    minimum_balance_days INTEGER DEFAULT 1,
    severity_level INTEGER CHECK (severity_level BETWEEN 1 AND 3),
    notification_channels JSONB, -- Email, Slack, SMS, etc.
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(entity_id, rule_name)
);

-- Views for Predictive Cash Flow Analysis

-- Cash Flow Forecast View
CREATE VIEW cash_flow_forecast_view AS
SELECT
    cm.model_name,
    s.subsidiary_name,
    cf.forecast_date,
    cf.horizon_days,
    cfc.category_name,
    cfc.direction,
    fd.forecast_day,
    fd.predicted_amount,
    fd.lower_bound,
    fd.upper_bound,
    fd.baseline_amount,
    (fd.predicted_amount - fd.baseline_amount) AS ml_adjustment,
    CASE
        WHEN cfc.direction = 'I' THEN fd.predicted_amount
        WHEN cfc.direction = 'O' THEN -fd.predicted_amount
    END AS signed_amount
FROM forecast_details fd
JOIN cash_flow_forecasts cf ON fd.forecast_id = cf.forecast_id
JOIN cash_flow_models cm ON cf.model_id = cm.model_id
JOIN cash_flow_categories cfc ON fd.category_id = cfc.category_id
LEFT JOIN subsidiaries s ON cm.entity_id = s.subsidiary_id;

-- Liquidity Projection View
CREATE VIEW liquidity_projection_view AS
WITH daily_flows AS (
    SELECT
        forecast_day AS projection_date,
        entity_id,
        SUM(signed_amount) AS net_flow
    FROM cash_flow_forecast_view
    GROUP BY forecast_day, entity_id
),
running_balances AS (
    SELECT
        projection_date,
        entity_id,
        net_flow,
        SUM(net_flow) OVER (PARTITION BY entity_id ORDER BY projection_date) AS projected_balance
    FROM daily_flows
)
SELECT
    rb.projection_date,
    s.subsidiary_name,
    rb.net_flow,
    rb.projected_balance,
    ar.rule_name,
    ar.threshold_value,
    CASE
        WHEN rb.projected_balance < ar.threshold_value THEN 'Alert'
        ELSE 'Normal'
    END AS alert_status
FROM running_balances rb
JOIN subsidiaries s ON rb.entity_id = s.subsidiary_id
LEFT JOIN alert_rules ar ON rb.entity_id = ar.entity_id
WHERE ar.is_active = TRUE;

-- Model Feature Importance View
CREATE VIEW model_feature_importance AS
SELECT
    cm.model_name,
    s.subsidiary_name,
    CASE
        WHEN mf.feature_type = 'Historical' THEN 'Historical Cash Flow'
        WHEN mf.feature_type = 'Economic' THEN ei.indicator_name
        WHEN mf.feature_type = 'Risk' THEN scr.factor_name
        ELSE mf.feature_type
    END AS feature_name,
    mf.feature_type,
    mf.importance_score,
    mf.lag_period,
    mf.transformation
FROM model_features mf
JOIN cash_flow_models cm ON mf.model_id = cm.model_id
LEFT JOIN subsidiaries s ON cm.entity_id = s.subsidiary_id
LEFT JOIN economic_indicators ei ON mf.feature_type = 'Economic' AND mf.source_id = ei.indicator_id
LEFT JOIN supply_chain_risk_factors scr ON mf.feature_type = 'Risk' AND mf.source_id = scr.factor_id
ORDER BY cm.model_name, mf.importance_score DESC NULLS LAST;

-- Stored Procedures for Predictive Cash Flow

-- Generate Cash Flow Forecast
CREATE OR REPLACE FUNCTION generate_cash_flow_forecast(
    p_model_id INTEGER,
    p_forecast_date DATE DEFAULT CURRENT_DATE,
    p_horizon_days INTEGER DEFAULT 30,
    p_confidence_level NUMERIC DEFAULT 0.95
) RETURNS INTEGER AS $$
DECLARE
    v_forecast_id INTEGER;
    v_entity_id INTEGER;
    v_currency CHAR(3);
BEGIN
    -- Get model details
    SELECT entity_id, currency INTO v_entity_id, v_currency
    FROM cash_flow_models
    WHERE model_id = p_model_id;

    -- Create forecast record
    INSERT INTO cash_flow_forecasts (
        model_id, forecast_date, horizon_days, confidence_level
    )
    VALUES (
        p_model_id, p_forecast_date, p_horizon_days, p_confidence_level
    )
    RETURNING forecast_id INTO v_forecast_id;

    -- In a real implementation, this would call your ML service
    -- For this example, we'll simulate generating forecast details

    -- Simulate forecast for each category
    INSERT INTO forecast_details (
        forecast_id, category_id, forecast_day, predicted_amount,
        lower_bound, upper_bound, baseline_amount
    )
    SELECT
        v_forecast_id,
        cf.category_id,
        d.day_date,
        -- Simulated prediction (real implementation would use ML model)
        AVG(cfh.amount) * (1 + RANDOM() * 0.2 - 0.1) AS predicted_amount,
        AVG(cfh.amount) * 0.9 AS lower_bound,
        AVG(cfh.amount) * 1.1 AS upper_bound,
        AVG(cfh.amount) AS baseline_amount
    FROM
        GENERATE_SERIES(
            p_forecast_date,
            p_forecast_date + (p_horizon_days - 1) * INTERVAL '1 day',
            INTERVAL '1 day'
        ) AS d(day_date)
    CROSS JOIN cash_flow_categories cf
    LEFT JOIN cash_flow_history cfh ON cf.category_id = cfh.category_id
        AND cfh.entry_date BETWEEN d.day_date - INTERVAL '1 year' AND d.day_date
        AND cfh.entity_id = v_entity_id
        AND cfh.currency = v_currency
    WHERE cf.direction = 'O' -- Focus on outflows for this example
    GROUP BY cf.category_id, d.day_date;

    -- Check for liquidity alerts
    PERFORM check_liquidity_alerts(v_entity_id, p_forecast_date, p_horizon_days);

    RETURN v_forecast_id;
END;
$$ LANGUAGE plpgsql;

-- Check Liquidity Alerts
CREATE OR REPLACE FUNCTION check_liquidity_alerts(
    p_entity_id INTEGER,
    p_start_date DATE,
    p_horizon_days INTEGER
) RETURNS VOID AS $$
DECLARE
    v_alert_count INTEGER;
    v_min_balance NUMERIC;
    v_current_date DATE;
BEGIN
    -- Get the minimum projected balance for each day in horizon
    FOR v_current_date IN
        SELECT GENERATE_SERIES(
            p_start_date,
            p_start_date + (p_horizon_days - 1) * INTERVAL '1 day',
            INTERVAL '1 day'
        )::DATE
    LOOP
        -- Check each active alert rule
        FOR r IN
            SELECT * FROM alert_rules
            WHERE entity_id = p_entity_id AND is_active = TRUE
        LOOP
            -- Get the minimum projected balance for the rule's time horizon
            SELECT MIN(projected_balance) INTO v_min_balance
            FROM liquidity_projection_view
            WHERE entity_id = p_entity_id
            AND projection_date BETWEEN v_current_date AND v_current_date + r.time_horizon_days * INTERVAL '1 day';

            -- Check if balance falls below threshold
            IF v_min_balance < r.threshold_value THEN
                -- Check if alert already exists
                SELECT COUNT(*) INTO v_alert_count
                FROM liquidity_alerts
                WHERE entity_id = p_entity_id
                AND projected_date = v_current_date
                AND threshold_amount = r.threshold_value
                AND status = 'Active';

                -- Create new alert if none exists
                IF v_alert_count = 0 THEN
                    INSERT INTO liquidity_alerts (
                        entity_id, projected_date, projected_balance,
                        threshold_amount, alert_severity
                    )
                    VALUES (
                        p_entity_id, v_current_date, v_min_balance,
                        r.threshold_value, r.severity_level
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--Proactive regulatory watch and alert features to alert clients
-- Add Regulatory Watchtower tables to the enterprise_cpa schema

-- Regulatory Jurisdictions
CREATE TABLE regulatory_jurisdictions (
    jurisdiction_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region VARCHAR(100),
    regulatory_body VARCHAR(100) NOT NULL,
    oversight_area VARCHAR(100) NOT NULL, -- e.g., Banking, Securities, Tax, Data Privacy
    website_url VARCHAR(255),
    api_endpoint VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(country_code, regulatory_body, oversight_area)
);

-- Regulatory Source Documents
CREATE TABLE regulatory_documents (
    document_id SERIAL PRIMARY KEY,
    jurisdiction_id INTEGER REFERENCES regulatory_jurisdictions(jurisdiction_id),
    document_type VARCHAR(50) CHECK (document_type IN ('Law', 'Regulation', 'Guidance', 'Circular', 'Notice')),
    document_ref VARCHAR(100) NOT NULL,
    title TEXT NOT NULL,
    publication_date DATE NOT NULL,
    effective_date DATE,
    deadline_date DATE,
    document_url VARCHAR(255),
    full_text TEXT,
    summary TEXT,
    status VARCHAR(50) DEFAULT 'New' CHECK (status IN ('New', 'Processed', 'Archived')),
    raw_content_hash VARCHAR(64), -- For change detection
    UNIQUE(jurisdiction_id, document_ref)
);

-- Document NLP Analysis
CREATE TABLE document_analysis (
    analysis_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES regulatory_documents(document_id),
    analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_version VARCHAR(50) NOT NULL,
    key_topics JSONB, -- Extracted topics with confidence scores
    entities JSONB, -- Named entities (organizations, laws, dates)
    sentiment_score NUMERIC(3,2), -- -1 to 1 sentiment
    compliance_impact INTEGER CHECK (compliance_impact BETWEEN 1 AND 5),
    risk_level INTEGER CHECK (risk_level BETWEEN 1 AND 5),
    summary TEXT GENERATED ALWAYS AS (
        CASE
            WHEN key_topics IS NULL THEN 'Pending analysis'
            ELSE 'Impact: ' || compliance_impact || '/5. ' ||
                 COALESCE(jsonb_path_query_first(key_topics, '$[0].topic')::TEXT, 'No key topics')
        END
    ) STORED,
    UNIQUE(document_id, model_version)
);

-- Client Regulatory Profiles
CREATE TABLE client_profiles (
    profile_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL, -- References clients table in main system
    jurisdiction_ids INTEGER[] NOT NULL, -- Array of jurisdiction_ids
    industry_codes VARCHAR(10)[],
    compliance_contacts JSONB, -- {name, email, role, notification_preferences}
    monitoring_active BOOLEAN DEFAULT TRUE,
    last_review_date DATE,
    UNIQUE(client_id)
);

-- Regulatory Requirements
CREATE TABLE compliance_requirements (
    requirement_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES regulatory_documents(document_id),
    requirement_code VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    deadline DATE,
    grace_period_days INTEGER,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(50), -- e.g., 'Annual', 'Quarterly'
    UNIQUE(document_id, requirement_code)
);

-- Compliance Checklists
CREATE TABLE compliance_checklists (
    checklist_id SERIAL PRIMARY KEY,
    requirement_id INTEGER REFERENCES compliance_requirements(requirement_id),
    checklist_name VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    effective_date DATE NOT NULL,
    structure JSONB NOT NULL, -- Template structure with sections/items
    document_template TEXT, -- Liquid template or similar
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(requirement_id, version)
);

-- Client Compliance Tasks
CREATE TABLE client_compliance_tasks (
    task_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL, -- References clients table in main system
    requirement_id INTEGER REFERENCES compliance_requirements(requirement_id),
    checklist_id INTEGER REFERENCES compliance_checklists(checklist_id),
    original_deadline DATE NOT NULL,
    current_deadline DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Overdue', 'Waived')),
    assigned_to JSONB, -- {user_id, name, email}
    last_reminder_date DATE,
    completion_date DATE,
    notes TEXT,
    document_ids INTEGER[] -- References to submitted documents
);

-- Regulatory Change Notifications
CREATE TABLE regulatory_notifications (
    notification_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES regulatory_documents(document_id),
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notification_type VARCHAR(50) CHECK (notification_type IN ('New Regulation', 'Deadline', 'Update', 'Urgent')),
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority INTEGER CHECK (priority BETWEEN 1 AND 3),
    custom_fields JSONB
);

CREATE TABLE notification_recipients (
    recipient_id SERIAL PRIMARY KEY,
    notification_id INTEGER REFERENCES regulatory_notifications(notification_id),
    client_id INTEGER NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    sent_at TIMESTAMP,
    opened_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Sent', 'Delivered', 'Failed', 'Opened')),
    UNIQUE(notification_id, client_id, contact_email)
);

-- Views for Regulatory Watchtower

-- Pending Compliance Tasks View
CREATE VIEW pending_compliance_tasks AS
SELECT
    cp.client_id,
    cr.requirement_code,
    cr.description,
    cr.category,
    ccl.checklist_name,
    cct.current_deadline,
    (cct.current_deadline - CURRENT_DATE) AS days_remaining,
    cct.status,
    rd.title AS regulation_title,
    rj.regulatory_body,
    rj.country_code
FROM client_compliance_tasks cct
JOIN client_profiles cp ON cct.client_id = cp.client_id
JOIN compliance_requirements cr ON cct.requirement_id = cr.requirement_id
LEFT JOIN compliance_checklists ccl ON cct.checklist_id = ccl.checklist_id
JOIN regulatory_documents rd ON cr.document_id = rd.document_id
JOIN regulatory_jurisdictions rj ON rd.jurisdiction_id = rj.jurisdiction_id
WHERE cct.status IN ('Pending', 'In Progress', 'Overdue')
AND cp.monitoring_active = TRUE;

-- Regulatory Change Impact Analysis
CREATE VIEW regulatory_impact_view AS
SELECT
    rd.document_id,
    rd.document_ref,
    rd.title,
    rd.publication_date,
    rd.effective_date,
    rj.country_code,
    rj.regulatory_body,
    rj.oversight_area,
    da.compliance_impact,
    da.risk_level,
    da.sentiment_score,
    COUNT(DISTINCT cp.client_id) AS affected_clients,
    COUNT(DISTINCT cr.requirement_id) AS new_requirements,
    COUNT(DISTINCT cct.task_id) AS generated_tasks
FROM regulatory_documents rd
JOIN regulatory_jurisdictions rj ON rd.jurisdiction_id = rj.jurisdiction_id
LEFT JOIN document_analysis da ON rd.document_id = da.document_id
LEFT JOIN compliance_requirements cr ON rd.document_id = cr.document_id
LEFT JOIN client_profiles cp ON rj.jurisdiction_id = ANY(cp.jurisdiction_ids)
LEFT JOIN client_compliance_tasks cct ON cr.requirement_id = cct.requirement_id
WHERE rd.status = 'Processed'
GROUP BY rd.document_id, rd.document_ref, rd.title, rd.publication_date, rd.effective_date,
         rj.country_code, rj.regulatory_body, rj.oversight_area, da.compliance_impact,
         da.risk_level, da.sentiment_score;

-- Client Regulatory Exposure
CREATE VIEW client_regulatory_exposure AS
SELECT
    cp.client_id,
    COUNT(DISTINCT rj.jurisdiction_id) AS active_jurisdictions,
    COUNT(DISTINCT cct.task_id) FILTER (WHERE cct.status IN ('Pending', 'In Progress', 'Overdue')) AS pending_tasks,
    COUNT(DISTINCT cct.task_id) FILTER (WHERE cct.status = 'Overdue') AS overdue_tasks,
    MIN(cct.current_deadline) FILTER (WHERE cct.status IN ('Pending', 'In Progress')) AS next_deadline,
    AVG(da.risk_level)::NUMERIC(3,1) AS avg_risk_level
FROM client_profiles cp
LEFT JOIN regulatory_jurisdictions rj ON rj.jurisdiction_id = ANY(cp.jurisdiction_ids)
LEFT JOIN regulatory_documents rd ON rd.jurisdiction_id = rj.jurisdiction_id
LEFT JOIN document_analysis da ON rd.document_id = da.document_id
LEFT JOIN compliance_requirements cr ON rd.document_id = cr.document_id
LEFT JOIN client_compliance_tasks cct ON cr.requirement_id = cct.requirement_id AND cct.client_id = cp.client_id
WHERE cp.monitoring_active = TRUE
GROUP BY cp.client_id;

-- Stored Procedures for Regulatory Watchtower

-- Process New Regulatory Document
CREATE OR REPLACE FUNCTION process_regulatory_document(
    p_document_id INTEGER,
    p_model_version VARCHAR DEFAULT 'latest'
) RETURNS VOID AS $$
DECLARE
    v_text_content TEXT;
    v_analysis_result JSONB;
BEGIN
    -- Get document text (in real implementation would fetch from external source)
    SELECT full_text INTO v_text_content
    FROM regulatory_documents
    WHERE document_id = p_document_id;

    -- In production, this would call an NLP/AI service
    -- For this example, we simulate analysis results
    v_analysis_result := jsonb_build_object(
        'key_topics', jsonb_build_array(
            jsonb_build_object('topic', 'Data Privacy', 'score', 0.95),
            jsonb_build_object('topic', 'Reporting Requirements', 'score', 0.87)
        ),
        'entities', jsonb_build_array(
            jsonb_build_object('type', 'Law', 'text', 'GDPR', 'relevance', 0.98),
            jsonb_build_object('type', 'Organization', 'text', 'European Commission', 'relevance', 0.92)
        ),
        'sentiment', -0.3,
        'compliance_impact', 4,
        'risk_level', 3
    );

    -- Store analysis results
    INSERT INTO document_analysis (
        document_id, model_version, key_topics, entities,
        sentiment_score, compliance_impact, risk_level
    )
    VALUES (
        p_document_id, p_model_version,
        v_analysis_result->'key_topics',
        v_analysis_result->'entities',
        (v_analysis_result->>'sentiment')::NUMERIC,
        (v_analysis_result->>'compliance_impact')::INTEGER,
        (v_analysis_result->>'risk_level')::INTEGER
    );

    -- Update document status
    UPDATE regulatory_documents
    SET status = 'Processed'
    WHERE document_id = p_document_id;

    -- Generate requirements for high-impact documents
    IF (v_analysis_result->>'compliance_impact')::INTEGER >= 3 THEN
        PERFORM generate_compliance_requirements(p_document_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Generate Compliance Requirements
CREATE OR REPLACE FUNCTION generate_compliance_requirements(
    p_document_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_requirement_count INTEGER := 0;
    v_doc RECORD;
    v_analysis RECORD;
BEGIN
    -- Get document and analysis details
    SELECT * INTO v_doc FROM regulatory_documents WHERE document_id = p_document_id;
    SELECT * INTO v_analysis FROM document_analysis WHERE document_id = p_document_id ORDER BY analysis_date DESC LIMIT 1;

    -- In production, this would use AI to extract requirements
    -- For this example, we simulate requirement generation

    -- Simulate generating some standard requirements
    INSERT INTO compliance_requirements (
        document_id, requirement_code, description, category, deadline
    )
    VALUES (
        p_document_id,
        'REV-' || p_document_id || '-1',
        'Review new regulatory requirements with legal team',
        'General Compliance',
        v_doc.effective_date - 30
    )
    RETURNING requirement_id INTO v_requirement_count;

    INSERT INTO compliance_requirements (
        document_id, requirement_code, description, category, subcategory, deadline, is_recurring, recurrence_pattern
    )
    VALUES (
        p_document_id,
        'REP-' || p_document_id || '-1',
        'Submit annual compliance report',
        'Reporting',
        'Annual Filings',
        v_doc.effective_date + 365,
        TRUE,
        'Annual'
    );

    v_requirement_count := v_requirement_count + 1;

    -- Generate checklists for each requirement
    PERFORM generate_compliance_checklists(p_document_id);

    -- Assign tasks to affected clients
    PERFORM assign_client_compliance_tasks(p_document_id);

    RETURN v_requirement_count;
END;
$$ LANGUAGE plpgsql;

-- Assign Tasks to Clients
CREATE OR REPLACE FUNCTION assign_client_compliance_tasks(
    p_document_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_task_count INTEGER := 0;
    v_client RECORD;
    v_req RECORD;
    v_checklist_id INTEGER;
BEGIN
    -- For each affected client in the jurisdiction
    FOR v_client IN
        SELECT cp.client_id, cp.compliance_contacts
        FROM client_profiles cp
        JOIN regulatory_documents rd ON rd.jurisdiction_id = ANY(cp.jurisdiction_ids)
        WHERE rd.document_id = p_document_id
        AND cp.monitoring_active = TRUE
    LOOP
        -- For each requirement from this document
        FOR v_req IN
            SELECT * FROM compliance_requirements
            WHERE document_id = p_document_id
        LOOP
            -- Get the latest checklist for this requirement
            SELECT checklist_id INTO v_checklist_id
            FROM compliance_checklists
            WHERE requirement_id = v_req.requirement_id
            ORDER BY effective_date DESC
            LIMIT 1;

            -- Create client task
            INSERT INTO client_compliance_tasks (
                client_id, requirement_id, checklist_id,
                original_deadline, current_deadline,
                assigned_to
            )
            VALUES (
                v_client.client_id, v_req.requirement_id, v_checklist_id,
                v_req.deadline, v_req.deadline,
                jsonb_build_object(
                    'email', v_client.compliance_contacts->0->>'email',
                    'name', v_client.compliance_contacts->0->>'name'
                )
            );

            v_task_count := v_task_count + 1;
        END LOOP;
    END LOOP;

    RETURN v_task_count;
END;
$$ LANGUAGE plpgsql;

--smart document processing feature
-- Add Smart Document Processing tables to the enterprise_cpa schema

-- Document Types
CREATE TABLE sdp_document_types (
    doc_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) CHECK (category IN ('Financial', 'Legal', 'Tax', 'Operational')),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(type_name)
);

-- Document Sources
CREATE TABLE sdp_document_sources (
    source_id SERIAL PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL,
    source_type VARCHAR(50) CHECK (source_type IN ('Email', 'Upload', 'API', 'SFTP', 'Cloud Storage')),
    configuration JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(source_name)
);

-- Document Processing Jobs
CREATE TABLE sdp_processing_jobs (
    job_id SERIAL PRIMARY KEY,
    doc_type_id INTEGER REFERENCES sdp_document_types(doc_type_id),
    source_id INTEGER REFERENCES sdp_document_sources(source_id),
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(512) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    file_size INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'Received' CHECK (status IN ('Received', 'Processing', 'Processed', 'Failed', 'Manual Review')),
    status_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    processing_time_ms INTEGER,
    pages INTEGER,
    UNIQUE(file_hash)
);

-- Document Extraction Results
CREATE TABLE sdp_extraction_results (
    extraction_id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES sdp_processing_jobs(job_id),
    model_version VARCHAR(50) NOT NULL,
    confidence_score NUMERIC(5,2) CHECK (confidence_score BETWEEN 0 AND 1),
    extracted_data JSONB NOT NULL,
    validation_rules_applied JSONB,
    is_auto_validated BOOLEAN DEFAULT FALSE,
    validation_notes TEXT,
    UNIQUE(job_id)
);

-- Document Fields Configuration
CREATE TABLE sdp_field_configurations (
    field_id SERIAL PRIMARY KEY,
    doc_type_id INTEGER REFERENCES sdp_document_types(doc_type_id),
    field_name VARCHAR(100) NOT NULL,
    field_label VARCHAR(100) NOT NULL,
    data_type VARCHAR(20) CHECK (data_type IN ('Text', 'Number', 'Date', 'Boolean', 'Currency')),
    is_required BOOLEAN DEFAULT FALSE,
    validation_pattern VARCHAR(255),
    gl_mapping_rules JSONB, -- Rules for mapping to general ledger
    importance INTEGER CHECK (importance BETWEEN 1 AND 3), -- 1=Critical, 2=Important, 3=Optional
    UNIQUE(doc_type_id, field_name)
);

-- Document Posting Rules
CREATE TABLE sdp_posting_rules (
    rule_id SERIAL PRIMARY KEY,
    doc_type_id INTEGER REFERENCES sdp_document_types(doc_type_id),
    rule_name VARCHAR(100) NOT NULL,
    rule_condition JSONB NOT NULL, -- Condition for when this rule applies
    gl_account VARCHAR(20) REFERENCES general_ledger(account_number),
    debit_credit_indicator CHAR(1) CHECK (debit_credit_indicator IN ('D', 'C')),
    amount_field VARCHAR(100) NOT NULL, -- References field_name from field_configurations
    description_template TEXT, -- Template for journal entry description
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER NOT NULL, -- Processing order
    UNIQUE(doc_type_id, rule_name)
);

-- Processed Transactions
CREATE TABLE sdp_processed_transactions (
    transaction_id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES sdp_processing_jobs(job_id),
    gl_account VARCHAR(20) REFERENCES general_ledger(account_number),
    posting_date DATE NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    debit_credit CHAR(1) CHECK (debit_credit IN ('D', 'C')),
    description TEXT,
    reference_number VARCHAR(100),
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    fiscal_period_id INTEGER REFERENCES fiscal_periods(period_id),
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Posted', 'Rejected', 'Adjusted')),
    posted_at TIMESTAMP,
    posted_by VARCHAR(50),
    batch_id VARCHAR(50), -- For grouping related transactions
    UNIQUE(job_id, gl_account, amount, reference_number)
);

-- Exception Handling
CREATE TABLE sdp_exceptions (
    exception_id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES sdp_processing_jobs(job_id),
    exception_type VARCHAR(50) NOT NULL CHECK (exception_type IN ('Extraction', 'Validation', 'Posting', 'System')),
    field_name VARCHAR(100),
    expected_value TEXT,
    actual_value TEXT,
    resolution_notes TEXT,
    resolved_by VARCHAR(50),
    resolved_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'Resolved', 'Ignored'))
);

-- Document Processing Metrics
CREATE TABLE sdp_performance_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_date DATE NOT NULL,
    doc_type_id INTEGER REFERENCES sdp_document_types(doc_type_id),
    documents_processed INTEGER NOT NULL DEFAULT 0,
    documents_auto_posted INTEGER NOT NULL DEFAULT 0,
    documents_manual_review INTEGER NOT NULL DEFAULT 0,
    avg_processing_time_ms INTEGER,
    avg_confidence_score NUMERIC(5,2),
    error_rate NUMERIC(5,2),
    UNIQUE(metric_date, doc_type_id)
);

-- Views for Smart Document Processing

-- Document Processing Status View
CREATE VIEW sdp_processing_status AS
SELECT
    j.job_id,
    dt.type_name AS document_type,
    s.source_name,
    j.original_filename,
    j.status,
    j.created_at,
    j.processed_at,
    er.confidence_score,
    COUNT(pt.transaction_id) AS transactions_generated,
    COUNT(e.exception_id) FILTER (WHERE e.status = 'Open') AS open_exceptions
FROM sdp_processing_jobs j
JOIN sdp_document_types dt ON j.doc_type_id = dt.doc_type_id
JOIN sdp_document_sources s ON j.source_id = s.source_id
LEFT JOIN sdp_extraction_results er ON j.job_id = er.job_id
LEFT JOIN sdp_processed_transactions pt ON j.job_id = pt.job_id
LEFT JOIN sdp_exceptions e ON j.job_id = e.job_id
GROUP BY j.job_id, dt.type_name, s.source_name, j.original_filename,
         j.status, j.created_at, j.processed_at, er.confidence_score;

-- Auto-Posting Accuracy View
CREATE VIEW sdp_auto_posting_accuracy AS
SELECT
    dt.type_name AS document_type,
    COUNT(j.job_id) AS total_documents,
    COUNT(j.job_id) FILTER (WHERE j.status = 'Processed') AS successfully_processed,
    COUNT(j.job_id) FILTER (WHERE j.status = 'Manual Review') AS manual_review,
    COUNT(j.job_id) FILTER (WHERE j.status = 'Failed') AS failed,
    COUNT(pt.transaction_id) FILTER (WHERE pt.status = 'Posted') AS posted_transactions,
    AVG(er.confidence_score) AS avg_confidence,
    (COUNT(j.job_id) FILTER (WHERE j.status = 'Processed') * 100.0 /
        NULLIF(COUNT(j.job_id), 0))::NUMERIC(5,2) AS success_rate
FROM sdp_document_types dt
LEFT JOIN sdp_processing_jobs j ON dt.doc_type_id = j.doc_type_id
LEFT JOIN sdp_extraction_results er ON j.job_id = er.job_id
LEFT JOIN sdp_processed_transactions pt ON j.job_id = pt.job_id
GROUP BY dt.type_name;

-- Exception Analysis View
CREATE VIEW sdp_exception_analysis AS
SELECT
    dt.type_name AS document_type,
    e.exception_type,
    fc.field_label,
    COUNT(e.exception_id) AS exception_count,
    AVG(j.processing_time_ms) AS avg_processing_time,
    (COUNT(e.exception_id) * 100.0 /
        NULLIF(COUNT(DISTINCT j.job_id), 0))::NUMERIC(5,2) AS exception_rate
FROM sdp_exceptions e
JOIN sdp_processing_jobs j ON e.job_id = j.job_id
JOIN sdp_document_types dt ON j.doc_type_id = dt.doc_type_id
LEFT JOIN sdp_field_configurations fc ON j.doc_type_id = fc.doc_type_id AND e.field_name = fc.field_name
GROUP BY dt.type_name, e.exception_type, fc.field_label;

-- Stored Procedures for Smart Document Processing

-- Process New Document
CREATE OR REPLACE FUNCTION sdp_process_document(
    p_doc_type_id INTEGER,
    p_source_id INTEGER,
    p_filename VARCHAR,
    p_file_path VARCHAR,
    p_file_hash VARCHAR,
    p_file_size INTEGER,
    p_pages INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_job_id INTEGER;
BEGIN
    -- Create new processing job
    INSERT INTO sdp_processing_jobs (
        doc_type_id, source_id, original_filename,
        file_path, file_hash, file_size, pages
    )
    VALUES (
        p_doc_type_id, p_source_id, p_filename,
        p_file_path, p_file_hash, p_file_size, p_pages
    )
    RETURNING job_id INTO v_job_id;

    -- In production, this would trigger the actual processing pipeline
    -- For this example, we simulate the processing steps

    -- Simulate processing delay
    PERFORM pg_sleep(1);

    -- Update job status to processing
    UPDATE sdp_processing_jobs
    SET status = 'Processing',
        status_message = 'Document processing started'
    WHERE job_id = v_job_id;

    RETURN v_job_id;
END;
$$ LANGUAGE plpgsql;

-- Complete Document Processing
CREATE OR REPLACE FUNCTION sdp_complete_processing(
    p_job_id INTEGER,
    p_extracted_data JSONB,
    p_confidence_score NUMERIC,
    p_model_version VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_doc_type_id INTEGER;
    v_auto_validate BOOLEAN := FALSE;
BEGIN
    -- Get document type
    SELECT doc_type_id INTO v_doc_type_id
    FROM sdp_processing_jobs
    WHERE job_id = p_job_id;

    -- Check if we can auto-validate (confidence > 0.9)
    IF p_confidence_score >= 0.9 THEN
        v_auto_validate := TRUE;
    END IF;

    -- Store extraction results
    INSERT INTO sdp_extraction_results (
        job_id, model_version, confidence_score,
        extracted_data, is_auto_validated
    )
    VALUES (
        p_job_id, p_model_version, p_confidence_score,
        p_extracted_data, v_auto_validate
    );

    -- Update job status
    UPDATE sdp_processing_jobs
    SET status = CASE WHEN v_auto_validate THEN 'Processed' ELSE 'Manual Review' END,
        processed_at = CURRENT_TIMESTAMP,
        processing_time_ms = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) * 1000,
        status_message = CASE
            WHEN v_auto_validate THEN 'Automatically processed with high confidence'
            ELSE 'Needs manual review due to low confidence'
        END
    WHERE job_id = p_job_id;

    -- If auto-validated, generate transactions
    IF v_auto_validate THEN
        PERFORM sdp_generate_transactions(p_job_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Generate GL Transactions from Document
CREATE OR REPLACE FUNCTION sdp_generate_transactions(
    p_job_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_doc_type_id INTEGER;
    v_extracted_data JSONB;
    v_transaction_count INTEGER := 0;
    v_rule RECORD;
    v_amount NUMERIC;
    v_description TEXT;
    v_reference TEXT;
    v_subsidiary_id INTEGER;
    v_period_id INTEGER;
    v_batch_id VARCHAR := 'BATCH-' || p_job_id || '-' || FLOOR(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP));
BEGIN
    -- Get document type and extracted data
    SELECT j.doc_type_id, er.extracted_data
    INTO v_doc_type_id, v_extracted_data
    FROM sdp_processing_jobs j
    JOIN sdp_extraction_results er ON j.job_id = er.job_id
    WHERE j.job_id = p_job_id;

    -- Get fiscal period for posting date
    SELECT period_id INTO v_period_id
    FROM fiscal_periods
    WHERE CURRENT_DATE BETWEEN start_date AND end_date;

    -- Process each posting rule in priority order
    FOR v_rule IN
        SELECT * FROM sdp_posting_rules
        WHERE doc_type_id = v_doc_type_id
        AND is_active = TRUE
        ORDER BY priority
    LOOP
        -- Check if rule conditions are met (simplified example)
        -- In production, this would evaluate the rule_condition against extracted_data
        IF TRUE THEN -- Placeholder for condition evaluation
            -- Get amount from specified field
            v_amount := (v_extracted_data->>v_rule.amount_field)::NUMERIC;

            -- Build description from template
            v_description := REPLACE(v_rule.description_template, '{date}', CURRENT_DATE::TEXT);

            -- Get reference number if available
            v_reference := COALESCE(v_extracted_data->>'invoice_number',
                                  v_extracted_data->>'document_number',
                                  'DOC-' || p_job_id);

            -- Try to determine subsidiary from extracted data
            IF v_extracted_data ? 'subsidiary_code' THEN
                SELECT subsidiary_id INTO v_subsidiary_id
                FROM subsidiaries
                WHERE subsidiary_code = v_extracted_data->>'subsidiary_code';
            END IF;

            -- Create transaction
            INSERT INTO sdp_processed_transactions (
                job_id, gl_account, posting_date, amount,
                debit_credit, description, reference_number,
                subsidiary_id, fiscal_period_id, batch_id
            )
            VALUES (
                p_job_id, v_rule.gl_account, CURRENT_DATE, v_amount,
                v_rule.debit_credit_indicator, v_description, v_reference,
                v_subsidiary_id, v_period_id, v_batch_id
            );

            v_transaction_count := v_transaction_count + 1;
        END IF;
    END LOOP;

    -- Update metrics
    PERFORM sdp_update_metrics(v_doc_type_id);

    RETURN v_transaction_count;
END;
$$ LANGUAGE plpgsql;

-- Post Transactions to General Ledger
CREATE OR REPLACE FUNCTION sdp_post_transactions(
    p_batch_id VARCHAR,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_transaction RECORD;
    v_gl_entry_id INTEGER;
    v_count INTEGER := 0;
BEGIN
    -- Process each transaction in the batch
    FOR v_transaction IN
        SELECT * FROM sdp_processed_transactions
        WHERE batch_id = p_batch_id
        AND status = 'Pending'
    LOOP
        -- In production, this would create actual GL entries
        -- For this example, we just update the status

        UPDATE sdp_processed_transactions
        SET status = 'Posted',
            posted_at = CURRENT_TIMESTAMP,
            posted_by = p_user_id
        WHERE transaction_id = v_transaction.transaction_id;

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Update Processing Metrics
CREATE OR REPLACE FUNCTION sdp_update_metrics(
    p_doc_type_id INTEGER
) RETURNS VOID AS $$
BEGIN
    -- Update or insert metrics for today
    INSERT INTO sdp_performance_metrics (
        metric_date, doc_type_id, documents_processed,
        documents_auto_posted, documents_manual_review,
        avg_processing_time_ms, avg_confidence_score, error_rate
    )
    SELECT
        CURRENT_DATE,
        p_doc_type_id,
        COUNT(j.job_id),
        COUNT(j.job_id) FILTER (WHERE j.status = 'Processed'),
        COUNT(j.job_id) FILTER (WHERE j.status = 'Manual Review'),
        AVG(j.processing_time_ms),
        AVG(er.confidence_score),
        (COUNT(j.job_id) FILTER (WHERE j.status = 'Failed') * 100.0 /
            NULLIF(COUNT(j.job_id), 0))
    FROM sdp_processing_jobs j
    LEFT JOIN sdp_extraction_results er ON j.job_id = er.job_id
    WHERE j.doc_type_id = p_doc_type_id
    AND j.created_at::DATE = CURRENT_DATE
    ON CONFLICT (metric_date, doc_type_id)
    DO UPDATE SET
        documents_processed = EXCLUDED.documents_processed,
        documents_auto_posted = EXCLUDED.documents_auto_posted,
        documents_manual_review = EXCLUDED.documents_manual_review,
        avg_processing_time_ms = EXCLUDED.avg_processing_time_ms,
        avg_confidence_score = EXCLUDED.avg_confidence_score,
        error_rate = EXCLUDED.error_rate;
END;
$$ LANGUAGE plpgsql;

-- smart document processing features index
CREATE INDEX idx_sdp_jobs_status ON sdp_processing_jobs(status, doc_type_id);
CREATE INDEX idx_sdp_extraction_job ON sdp_extraction_results(job_id);
CREATE INDEX idx_sdp_transactions_job ON sdp_processed_transactions(job_id, status);
CREATE INDEX idx_sdp_transactions_batch ON sdp_processed_transactions(batch_id);
CREATE INDEX idx_sdp_exceptions_job ON sdp_exceptions(job_id, status);
CREATE INDEX idx_sdp_posting_rules_type ON sdp_posting_rules(doc_type_id, priority);

--compliance workflow builder
-- auditors aasked for visual workflow designer support, prebuilt templates for tax filing, audits and regulatory submissions
-- Add Embedded Compliance Workflow Builder tables to the enterprise_cpa schema

-- Workflow Templates
CREATE TABLE compliance_workflow_templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    description TEXT,
    workflow_type VARCHAR(50) NOT NULL CHECK (workflow_type IN ('Tax', 'Internal Control', 'Audit', 'Regulatory', 'Custom')),
    category VARCHAR(50),
    is_system_template BOOLEAN DEFAULT FALSE,
    version VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(template_name, version)
);

-- Workflow Nodes (Steps)
CREATE TABLE workflow_nodes (
    node_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES compliance_workflow_templates(template_id),
    node_name VARCHAR(100) NOT NULL,
    node_type VARCHAR(50) NOT NULL CHECK (node_type IN ('Task', 'Approval', 'Review', 'Notification', 'Gateway', 'Start', 'End')),
    description TEXT,
    instructions TEXT,
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    node_order INTEGER NOT NULL,
    UNIQUE(template_id, node_name)
);

-- Node Connections (Transitions)
CREATE TABLE workflow_connections (
    connection_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES compliance_workflow_templates(template_id),
    from_node_id INTEGER REFERENCES workflow_nodes(node_id),
    to_node_id INTEGER REFERENCES workflow_nodes(node_id),
    condition_expression TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    UNIQUE(template_id, from_node_id, to_node_id)
);

-- Workflow Roles
CREATE TABLE workflow_roles (
    role_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES compliance_workflow_templates(template_id),
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB, -- {can_edit: bool, can_approve: bool, etc.}
    UNIQUE(template_id, role_name)
);

-- Node Assignments
CREATE TABLE node_assignments (
    assignment_id SERIAL PRIMARY KEY,
    node_id INTEGER REFERENCES workflow_nodes(node_id),
    role_id INTEGER REFERENCES workflow_roles(role_id),
    assignment_type VARCHAR(20) CHECK (assignment_type IN ('Responsible', 'Accountable', 'Consulted', 'Informed')),
    UNIQUE(node_id, role_id, assignment_type)
);

-- SLA Definitions
CREATE TABLE workflow_slas (
    sla_id SERIAL PRIMARY KEY,
    node_id INTEGER REFERENCES workflow_nodes(node_id),
    sla_name VARCHAR(100) NOT NULL,
    duration_days INTEGER NOT NULL,
    duration_hours INTEGER DEFAULT 0,
    business_hours_only BOOLEAN DEFAULT TRUE,
    start_trigger VARCHAR(50) CHECK (start_trigger IN ('Node Entry', 'Previous Completion', 'Custom Event')),
    escalation_path JSONB, -- {levels: [{after_days: 2, notify: [role_ids]}]}
    UNIQUE(node_id, sla_name)
);

-- Workflow Instances
CREATE TABLE workflow_instances (
    instance_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES compliance_workflow_templates(template_id),
    instance_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'Draft' CHECK (status IN ('Draft', 'Active', 'Paused', 'Completed', 'Terminated')),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    due_date DATE,
    priority INTEGER CHECK (priority BETWEEN 1 AND 5), -- 1=Low, 5=Critical
    context_data JSONB, -- Workflow-specific data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL,
    UNIQUE(template_id, instance_name)
);

-- Instance Nodes (Active Steps)
CREATE TABLE instance_nodes (
    instance_node_id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES workflow_instances(instance_id),
    node_id INTEGER REFERENCES workflow_nodes(node_id),
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Rejected', 'Escalated')),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    assigned_to JSONB, -- {user_id: text, name: text, email: text}
    comments TEXT,
    outcome VARCHAR(50),
    sla_deadline TIMESTAMP,
    sla_status VARCHAR(20) CHECK (sla_status IN ('On Time', 'At Risk', 'Breached')),
    UNIQUE(instance_id, node_id)
);

-- Instance Transitions
CREATE TABLE instance_transitions (
    transition_id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES workflow_instances(instance_id),
    from_node_id INTEGER REFERENCES workflow_nodes(node_id),
    to_node_id INTEGER REFERENCES workflow_nodes(node_id),
    transitioned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transitioned_by VARCHAR(50) NOT NULL,
    comments TEXT
);

-- Workflow Documents
CREATE TABLE workflow_documents (
    document_id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES workflow_instances(instance_id),
    instance_node_id INTEGER REFERENCES instance_nodes(instance_node_id),
    document_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    storage_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(50) NOT NULL,
    version INTEGER DEFAULT 1,
    is_approved BOOLEAN DEFAULT FALSE,
    approval_notes TEXT
);

-- Escalation History
CREATE TABLE escalation_history (
    escalation_id SERIAL PRIMARY KEY,
    instance_node_id INTEGER REFERENCES instance_nodes(instance_node_id),
    escalation_level INTEGER NOT NULL,
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    escalated_to JSONB NOT NULL, -- {role_id: int, role_name: text, users: [user_ids]}
    reason TEXT,
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(50)
);

-- Workflow Notifications
CREATE TABLE workflow_notifications (
    notification_id SERIAL PRIMARY KEY,
    instance_id INTEGER REFERENCES workflow_instances(instance_id),
    instance_node_id INTEGER REFERENCES instance_nodes(instance_node_id),
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('Assignment', 'Reminder', 'Escalation', 'Completion')),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_to JSONB NOT NULL, -- {user_id: text, email: text, name: text}
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP
);

-- Views for Embedded Compliance Workflow Builder

-- Workflow Instance Status View
CREATE VIEW workflow_instance_status AS
SELECT
    wi.instance_id,
    wt.template_name,
    wi.instance_name,
    wi.status,
    wi.started_at,
    wi.due_date,
    wi.priority,
    COUNT(in_comp.instance_node_id) FILTER (WHERE in_comp.status = 'Completed') AS completed_steps,
    COUNT(in_all.instance_node_id) AS total_steps,
    (COUNT(in_comp.instance_node_id) FILTER (WHERE in_comp.status = 'Completed') * 100.0 /
        NULLIF(COUNT(in_all.instance_node_id), 0))::NUMERIC(5,2) AS completion_percentage,
    COUNT(es.escalation_id) FILTER (WHERE es.resolved_at IS NULL) AS active_escalations
FROM workflow_instances wi
JOIN compliance_workflow_templates wt ON wi.template_id = wt.template_id
LEFT JOIN instance_nodes in_all ON wi.instance_id = in_all.instance_id
LEFT JOIN instance_nodes in_comp ON wi.instance_id = in_comp.instance_id AND in_comp.status = 'Completed'
LEFT JOIN escalation_history es ON in_all.instance_node_id = es.instance_node_id AND es.resolved_at IS NULL
GROUP BY wi.instance_id, wt.template_name, wi.instance_name, wi.status, wi.started_at, wi.due_date, wi.priority;

-- SLA Compliance View
CREATE VIEW sla_compliance_view AS
SELECT
    wt.template_name,
    wn.node_name,
    wn.node_type,
    ws.sla_name,
    ws.duration_days,
    COUNT(in_ontime.instance_node_id) FILTER (WHERE in_ontime.sla_status = 'On Time') AS on_time_count,
    COUNT(in_risk.instance_node_id) FILTER (WHERE in_risk.sla_status = 'At Risk') AS at_risk_count,
    COUNT(in_breach.instance_node_id) FILTER (WHERE in_breach.sla_status = 'Breached') AS breached_count,
    (COUNT(in_ontime.instance_node_id) FILTER (WHERE in_ontime.sla_status = 'On Time') * 100.0 /
        NULLIF(COUNT(in_all.instance_node_id), 0))::NUMERIC(5,2) AS on_time_percentage
FROM workflow_slas ws
JOIN workflow_nodes wn ON ws.node_id = wn.node_id
JOIN compliance_workflow_templates wt ON wn.template_id = wt.template_id
LEFT JOIN instance_nodes in_all ON wn.node_id = in_all.node_id
LEFT JOIN instance_nodes in_ontime ON wn.node_id = in_ontime.node_id AND in_ontime.sla_status = 'On Time'
LEFT JOIN instance_nodes in_risk ON wn.node_id = in_risk.node_id AND in_risk.sla_status = 'At Risk'
LEFT JOIN instance_nodes in_breach ON wn.node_id = in_breach.node_id AND in_breach.sla_status = 'Breached'
GROUP BY wt.template_name, wn.node_name, wn.node_type, ws.sla_name, ws.duration_days;

-- Workflow Step Assignment View
CREATE VIEW workflow_step_assignments AS
SELECT
    wt.template_name,
    wn.node_name,
    wn.node_type,
    wr.role_name,
    na.assignment_type,
    COUNT(DISTINCT wi.instance_id) AS instance_count,
    COUNT(DISTINCT in_comp.instance_node_id) FILTER (WHERE in_comp.status = 'Completed') AS completed_count,
    AVG(EXTRACT(EPOCH FROM (in_comp.completed_at - in_comp.started_at))/3600)::NUMERIC(6,2) AS avg_hours_to_complete
FROM node_assignments na
JOIN workflow_roles wr ON na.role_id = wr.role_id
JOIN workflow_nodes wn ON na.node_id = wn.node_id
JOIN compliance_workflow_templates wt ON wn.template_id = wt.template_id
LEFT JOIN workflow_instances wi ON wt.template_id = wi.template_id
LEFT JOIN instance_nodes in_all ON wn.node_id = in_all.node_id AND wi.instance_id = in_all.instance_id
LEFT JOIN instance_nodes in_comp ON wn.node_id = in_comp.node_id AND wi.instance_id = in_comp.instance_id AND in_comp.status = 'Completed'
GROUP BY wt.template_name, wn.node_name, wn.node_type, wr.role_name, na.assignment_type;

-- Stored Procedures for Embedded Compliance Workflow Builder

-- Create Workflow Instance
CREATE OR REPLACE FUNCTION create_workflow_instance(
    p_template_id INTEGER,
    p_instance_name VARCHAR,
    p_created_by VARCHAR,
    p_due_date DATE DEFAULT NULL,
    p_priority INTEGER DEFAULT 3,
    p_context_data JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_instance_id INTEGER;
    v_node RECORD;
BEGIN
    -- Create the workflow instance
    INSERT INTO workflow_instances (
        template_id, instance_name, created_by,
        due_date, priority, context_data
    )
    VALUES (
        p_template_id, p_instance_name, p_created_by,
        p_due_date, p_priority, p_context_data
    )
    RETURNING instance_id INTO v_instance_id;

    -- Create all instance nodes from the template
    FOR v_node IN
        SELECT * FROM workflow_nodes
        WHERE template_id = p_template_id
        ORDER BY node_order
    LOOP
        INSERT INTO instance_nodes (
            instance_id, node_id
        )
        VALUES (
            v_instance_id, v_node.node_id
        );
    END LOOP;

    -- Activate the start node
    PERFORM start_workflow_instance(v_instance_id, p_created_by);

    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- Start Workflow Instance
CREATE OR REPLACE FUNCTION start_workflow_instance(
    p_instance_id INTEGER,
    p_started_by VARCHAR
) RETURNS VOID AS $$
DECLARE
    v_start_node_id INTEGER;
BEGIN
    -- Find the start node
    SELECT wn.node_id INTO v_start_node_id
    FROM workflow_nodes wn
    JOIN workflow_instances wi ON wn.template_id = wi.template_id
    WHERE wi.instance_id = p_instance_id
    AND wn.node_type = 'Start';

    -- Update instance status
    UPDATE workflow_instances
    SET status = 'Active',
        started_at = CURRENT_TIMESTAMP
    WHERE instance_id = p_instance_id;

    -- Activate the start node
    UPDATE instance_nodes
    SET status = 'In Progress',
        started_at = CURRENT_TIMESTAMP
    WHERE instance_id = p_instance_id
    AND node_id = v_start_node_id;

    -- Record the transition (from nowhere to start node)
    INSERT INTO instance_transitions (
        instance_id, from_node_id, to_node_id, transitioned_by
    )
    VALUES (
        p_instance_id, NULL, v_start_node_id, p_started_by
    );

    -- Process SLA for the start node
    PERFORM process_node_sla(p_instance_id, v_start_node_id);
END;
$$ LANGUAGE plpgsql;

-- Complete Workflow Node
CREATE OR REPLACE FUNCTION complete_workflow_node(
    p_instance_node_id INTEGER,
    p_completed_by VARCHAR,
    p_outcome VARCHAR DEFAULT NULL,
    p_comments TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_instance_id INTEGER;
    v_node_id INTEGER;
    v_template_id INTEGER;
    v_next_node_id INTEGER;
    v_connection RECORD;
    v_condition_met BOOLEAN;
    v_default_connection BOOLEAN;
    v_transition_count INTEGER := 0;
BEGIN
    -- Get node and instance details
    SELECT in_.instance_id, in_.node_id, wi.template_id
    INTO v_instance_id, v_node_id, v_template_id
    FROM instance_nodes in_
    JOIN workflow_instances wi ON in_.instance_id = wi.instance_id
    WHERE in_.instance_node_id = p_instance_node_id;

    -- Mark node as completed
    UPDATE instance_nodes
    SET status = 'Completed',
        completed_at = CURRENT_TIMESTAMP,
        outcome = p_outcome,
        comments = p_comments
    WHERE instance_node_id = p_instance_node_id;

    -- Find all outgoing connections from this node
    FOR v_connection IN
        SELECT * FROM workflow_connections
        WHERE template_id = v_template_id
        AND from_node_id = v_node_id
    LOOP
        -- Check if this is the default connection (when no conditions are met)
        v_default_connection := v_connection.is_default AND v_connection.condition_expression IS NULL;

        -- Evaluate connection condition if exists
        IF v_connection.condition_expression IS NOT NULL THEN
            -- In production, this would evaluate the condition against workflow context
            -- For this example, we'll simulate a simple condition check
            v_condition_met := (p_outcome = v_connection.condition_expression) OR
                              (v_connection.condition_expression = 'Always');
        ELSE
            v_condition_met := TRUE;
        END IF;

        -- If condition is met or this is the default connection, transition to next node
        IF v_condition_met OR v_default_connection THEN
            -- Activate the next node
            UPDATE instance_nodes
            SET status = 'In Progress',
                started_at = CURRENT_TIMESTAMP
            WHERE instance_id = v_instance_id
            AND node_id = v_connection.to_node_id;

            -- Record the transition
            INSERT INTO instance_transitions (
                instance_id, from_node_id, to_node_id, transitioned_by, comments
            )
            VALUES (
                v_instance_id, v_node_id, v_connection.to_node_id, p_completed_by,
                'Transitioned via ' || CASE
                    WHEN v_condition_met THEN 'condition: ' || v_connection.condition_expression
                    ELSE 'default connection'
                END
            );

            -- Process SLA for the new node
            PERFORM process_node_sla(v_instance_id, v_connection.to_node_id);

            v_transition_count := v_transition_count + 1;

            -- If this wasn't the default connection, exit the loop
            IF NOT v_default_connection THEN
                EXIT;
            END IF;
        END IF;
    END LOOP;

    -- Check if workflow is complete (no more active nodes)
    IF NOT EXISTS (
        SELECT 1 FROM instance_nodes
        WHERE instance_id = v_instance_id
        AND status IN ('Pending', 'In Progress')
    ) THEN
        UPDATE workflow_instances
        SET status = 'Completed',
            completed_at = CURRENT_TIMESTAMP
        WHERE instance_id = v_instance_id;
    END IF;

    RETURN v_transition_count;
END;
$$ LANGUAGE plpgsql;

-- Process Node SLA
CREATE OR REPLACE FUNCTION process_node_sla(
    p_instance_id INTEGER,
    p_node_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_sla RECORD;
    v_deadline TIMESTAMP;
    v_business_hours_start TIME := '09:00:00';
    v_business_hours_end TIME := '17:00:00';
    v_current_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_days_to_add INTEGER;
    v_hours_to_add INTEGER;
BEGIN
    -- Get SLA definition for this node
    SELECT * INTO v_sla
    FROM workflow_slas
    WHERE node_id = p_node_id
    LIMIT 1;

    IF FOUND THEN
        -- Calculate deadline based on SLA rules
        IF v_sla.business_hours_only THEN
            -- Business hours calculation (simplified example)
            v_days_to_add := v_sla.duration_days;
            v_hours_to_add := v_sla.duration_hours;

            -- Start with current time
            v_deadline := v_current_time;

            -- Add business days/hours
            WHILE v_days_to_add > 0 OR v_hours_to_add > 0 LOOP
                -- Move to next day if outside business hours
                IF v_deadline::TIME < v_business_hours_start THEN
                    v_deadline := v_deadline::DATE + v_business_hours_start;
                ELSIF v_deadline::TIME >= v_business_hours_end THEN
                    v_deadline := (v_deadline::DATE + 1) + v_business_hours_start;
                    v_days_to_add := v_days_to_add - 1;
                    CONTINUE;
                END IF;

                -- Add hours (within business day)
                IF v_hours_to_add > 0 THEN
                    IF EXTRACT(HOUR FROM v_deadline) + v_hours_to_add < EXTRACT(HOUR FROM v_business_hours_end) THEN
                        v_deadline := v_deadline + (v_hours_to_add * INTERVAL '1 hour');
                        v_hours_to_add := 0;
                    ELSE
                        DECLARE
                            v_remaining_hours INTEGER := EXTRACT(HOUR FROM v_business_hours_end) - EXTRACT(HOUR FROM v_deadline);
                        BEGIN
                            v_hours_to_add := v_hours_to_add - v_remaining_hours;
                            v_deadline := (v_deadline::DATE + 1) + v_business_hours_start;
                            v_days_to_add := v_days_to_add - 1;
                        END;
                    END IF;
                ELSE
                    -- Add full business day
                    v_deadline := v_deadline::DATE + 1 + v_business_hours_start;
                    v_days_to_add := v_days_to_add - 1;
                END IF;
            END LOOP;
        ELSE
            -- 24/7 calculation (simple)
            v_deadline := v_current_time +
                          (v_sla.duration_days * INTERVAL '1 day') +
                          (v_sla.duration_hours * INTERVAL '1 hour');
        END IF;

        -- Update instance node with SLA deadline
        UPDATE instance_nodes
        SET sla_deadline = v_deadline,
            sla_status = 'On Time'
        WHERE instance_id = p_instance_id
        AND node_id = p_node_id;

        -- Schedule SLA check (in production, this would use a job scheduler)
        -- For this example, we'll just record it
        INSERT INTO workflow_notifications (
            instance_id, instance_node_id, notification_type,
            sent_to, subject, message
        )
        VALUES (
            p_instance_id,
            (SELECT instance_node_id FROM instance_nodes
             WHERE instance_id = p_instance_id AND node_id = p_node_id),
            'Reminder',
            (SELECT assigned_to FROM instance_nodes
             WHERE instance_id = p_instance_id AND node_id = p_node_id),
            'New task assigned with deadline',
            'Your task has a deadline of ' || v_deadline
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Check SLA Compliance
CREATE OR REPLACE FUNCTION check_sla_compliance() RETURNS INTEGER AS $$
DECLARE
    v_breached_count INTEGER := 0;
    v_at_risk_count INTEGER := 0;
    v_node RECORD;
    v_time_remaining INTERVAL;
    v_time_remaining_pct NUMERIC;
    v_escalation_level INTEGER;
    v_escalation_path JSONB;
BEGIN
    -- Check all active nodes with SLAs
    FOR v_node IN
        SELECT in_.instance_node_id, in_.instance_id, in_.node_id, in_.sla_deadline,
               wn.node_name, wi.instance_name, wt.template_name, ws.escalation_path
        FROM instance_nodes in_
        JOIN workflow_nodes wn ON in_.node_id = wn.node_id
        JOIN workflow_instances wi ON in_.instance_id = wi.instance_id
        JOIN compliance_workflow_templates wt ON wn.template_id = wt.template_id
        LEFT JOIN workflow_slas ws ON wn.node_id = ws.node_id
        WHERE in_.status IN ('Pending', 'In Progress')
        AND in_.sla_deadline IS NOT NULL
    LOOP
        -- Calculate time remaining
        v_time_remaining := v_node.sla_deadline - CURRENT_TIMESTAMP;
        v_time_remaining_pct := EXTRACT(EPOCH FROM v_time_remaining) /
                              EXTRACT(EPOCH FROM (v_node.sla_deadline - in_.started_at)) * 100;

        -- Determine SLA status
        IF v_time_remaining <= INTERVAL '0' THEN
            -- SLA breached
            UPDATE instance_nodes
            SET sla_status = 'Breached'
            WHERE instance_node_id = v_node.instance_node_id;

            v_breached_count := v_breached_count + 1;

            -- Process escalations if not already escalated
            IF NOT EXISTS (
                SELECT 1 FROM escalation_history
                WHERE instance_node_id = v_node.instance_node_id
            ) AND v_node.escalation_path IS NOT NULL THEN
                v_escalation_path := v_node.escalation_path;

                -- Process each escalation level
                FOR v_escalation_level IN 1..jsonb_array_length(v_escalation_path->'levels')
                LOOP
                    DECLARE
                        v_level RECORD;
                        v_after_days INTEGER;
                        v_notify_roles JSONB;
                    BEGIN
                        -- Get escalation level details
                        SELECT
                            (v_escalation_path->'levels'->(v_escalation_level-1)->>'after_days')::INTEGER AS after_days,
                            v_escalation_path->'levels'->(v_escalation_level-1)->'notify' AS notify_roles
                        INTO v_level;

                        -- Check if we should escalate to this level
                        IF (v_node.sla_deadline - (v_level.after_days * INTERVAL '1 day')) <= CURRENT_TIMESTAMP THEN
                            -- Record escalation
                            INSERT INTO escalation_history (
                                instance_node_id, escalation_level, escalated_to
                            )
                            VALUES (
                                v_node.instance_node_id, v_escalation_level,
                                jsonb_build_object(
                                    'roles', v_level.notify_roles,
                                    'message', 'SLA breached by ' || abs(EXTRACT(EPOCH FROM v_time_remaining)/3600 || ' hours'
                                )
                            );

                            -- Notify escalated roles (in production, would actually send notifications)
                            INSERT INTO workflow_notifications (
                                instance_id, instance_node_id, notification_type,
                                sent_to, subject, message
                            )
                            VALUES (
                                v_node.instance_id, v_node.instance_node_id, 'Escalation',
                                jsonb_build_object('roles', v_level.notify_roles),
                                'SLA Escalation: ' || v_node.node_name,
                                'Task "' || v_node.node_name || '" in workflow "' ||
                                v_node.instance_name || '" has breached its SLA'
                            );
                        END IF;
                    END;
                END LOOP;
            END IF;
        ELSIF v_time_remaining_pct < 25 THEN
            -- At risk (less than 25% time remaining)
            UPDATE instance_nodes
            SET sla_status = 'At Risk'
            WHERE instance_node_id = v_node.instance_node_id;

            v_at_risk_count := v_at_risk_count + 1;
        ELSE
            -- On time
            UPDATE instance_nodes
            SET sla_status = 'On Time'
            WHERE instance_node_id = v_node.instance_node_id;
        END IF;
    END LOOP;

    -- Return count of breached SLAs
    RETURN v_breached_count;
END;
$$ LANGUAGE plpgsql;

--compliance workflow builder
CREATE INDEX idx_workflow_instances_template ON workflow_instances(template_id, status);
CREATE INDEX idx_instance_nodes_status ON instance_nodes(instance_id, status);
CREATE INDEX idx_instance_nodes_sla ON instance_nodes(sla_deadline, sla_status);
CREATE INDEX idx_workflow_notifications_instance ON workflow_notifications(instance_id, is_read);
CREATE INDEX idx_escalation_history_node ON escalation_history(instance_node_id, resolved_at);

--ESG sustainability Analytics feature
-- various frameworks exist -SASB,TCFD,GRI,ISSB,CSRD etc
-- Add ESG & Sustainability Analytics tables to the enterprise_cpa schema

-- ESG Frameworks
CREATE TABLE esg_frameworks (
    framework_id SERIAL PRIMARY KEY,
    framework_name VARCHAR(100) NOT NULL,
    framework_standard VARCHAR(50) CHECK (framework_standard IN ('SASB', 'TCFD', 'GRI', 'ISSB', 'CSRD', 'Custom')),
    version VARCHAR(20) NOT NULL,
    description TEXT,
    effective_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(framework_name, version)
);

-- ESG Categories
CREATE TABLE esg_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    dimension CHAR(1) CHECK (dimension IN ('E', 'S', 'G')), -- Environmental, Social, Governance
    description TEXT,
    UNIQUE(category_name, dimension)
);

-- Framework Mappings
CREATE TABLE framework_mappings (
    mapping_id SERIAL PRIMARY KEY,
    framework_id INTEGER REFERENCES esg_frameworks(framework_id),
    category_id INTEGER REFERENCES esg_categories(category_id),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_description TEXT NOT NULL,
    disclosure_requirements TEXT,
    reporting_frequency VARCHAR(20) CHECK (reporting_frequency IN ('Annual', 'Quarterly', 'Monthly', 'Continuous')),
    UNIQUE(framework_id, category_id, requirement_code)
);

-- ESG Metrics
CREATE TABLE esg_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_code VARCHAR(50) NOT NULL,
    category_id INTEGER REFERENCES esg_categories(category_id),
    unit_of_measure VARCHAR(50) NOT NULL,
    data_type VARCHAR(20) CHECK (data_type IN ('Integer', 'Decimal', 'Boolean', 'Percentage', 'Text')),
    is_kpi BOOLEAN DEFAULT FALSE,
    calculation_methodology TEXT,
    better_direction CHAR(1) CHECK (better_direction IN ('U', 'D')), -- Up is better, Down is better
    UNIQUE(metric_code)
);

-- ESG Data Collection
CREATE TABLE esg_data_points (
    data_point_id SERIAL PRIMARY KEY,
    metric_id INTEGER REFERENCES esg_metrics(metric_id),
    reporting_period_id INTEGER REFERENCES fiscal_periods(period_id),
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    value NUMERIC(20,6),
    text_value TEXT,
    measurement_date DATE NOT NULL,
    collection_method VARCHAR(50) CHECK (collection_method IN ('Manual', 'Sensor', 'ERP', 'Calculated', 'Estimated')),
    data_quality_score INTEGER CHECK (data_quality_score BETWEEN 1 AND 5),
    verified BOOLEAN DEFAULT FALSE,
    verified_by VARCHAR(50),
    verified_at TIMESTAMP,
    notes TEXT,
    UNIQUE(metric_id, reporting_period_id, subsidiary_id, measurement_date)
);

-- ESG Targets
CREATE TABLE esg_targets (
    target_id SERIAL PRIMARY KEY,
    metric_id INTEGER REFERENCES esg_metrics(metric_id),
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    target_value NUMERIC(20,6),
    target_year INTEGER NOT NULL,
    baseline_value NUMERIC(20,6),
    baseline_year INTEGER,
    is_science_based BOOLEAN DEFAULT FALSE,
    approval_status VARCHAR(20) DEFAULT 'Draft' CHECK (approval_status IN ('Draft', 'Approved', 'Rejected', 'Archived')),
    approved_by VARCHAR(50),
    approved_at TIMESTAMP,
    UNIQUE(metric_id, subsidiary_id, target_year)
);

-- Carbon Emissions Details
CREATE TABLE carbon_emissions (
    emission_id SERIAL PRIMARY KEY,
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    reporting_period_id INTEGER REFERENCES fiscal_periods(period_id),
    scope INTEGER CHECK (scope BETWEEN 1 AND 3),
    emission_source VARCHAR(100) NOT NULL,
    co2e_amount NUMERIC(20,2) NOT NULL, -- CO2 equivalent in metric tons
    emission_factor_id VARCHAR(50), -- Reference to emission factor database
    activity_amount NUMERIC(20,2),
    activity_unit VARCHAR(50),
    calculation_methodology VARCHAR(100),
    data_quality_score INTEGER CHECK (data_quality_score BETWEEN 1 AND 5),
    verified BOOLEAN DEFAULT FALSE,
    UNIQUE(subsidiary_id, reporting_period_id, scope, emission_source)
);

-- DEI (Diversity, Equity & Inclusion) Metrics
CREATE TABLE dei_metrics (
    dei_id SERIAL PRIMARY KEY,
    subsidiary_id INTEGER REFERENCES subsidiaries(subsidiary_id),
    reporting_period_id INTEGER REFERENCES fiscal_periods(period_id),
    metric_type VARCHAR(50) CHECK (metric_type IN ('Gender', 'Ethnicity', 'Age', 'Disability', 'Pay Equity')),
    category VARCHAR(100) NOT NULL,
    employee_count INTEGER,
    percentage NUMERIC(5,2),
    leadership_level VARCHAR(50), -- For breakdown by management level
    notes TEXT,
    UNIQUE(subsidiary_id, reporting_period_id, metric_type, category, leadership_level)
);

-- Sustainability Initiatives
CREATE TABLE sustainability_initiatives (
    initiative_id SERIAL PRIMARY KEY,
    initiative_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    target_completion_date DATE,
    category_id INTEGER REFERENCES esg_categories(category_id),
    budget NUMERIC(15,2),
    responsible_party VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Planning' CHECK (status IN ('Planning', 'In Progress', 'Completed', 'On Hold', 'Cancelled')),
    UNIQUE(initiative_name)
);

-- Initiative Outcomes
CREATE TABLE initiative_outcomes (
    outcome_id SERIAL PRIMARY KEY,
    initiative_id INTEGER REFERENCES sustainability_initiatives(initiative_id),
    metric_id INTEGER REFERENCES esg_metrics(metric_id),
    reporting_period_id INTEGER REFERENCES fiscal_periods(period_id),
    outcome_value NUMERIC(20,6),
    outcome_text TEXT,
    achieved_date DATE,
    verified BOOLEAN DEFAULT FALSE,
    notes TEXT,
    UNIQUE(initiative_id, metric_id, reporting_period_id)
);

-- ESG Report Templates
CREATE TABLE esg_report_templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    framework_id INTEGER REFERENCES esg_frameworks(framework_id),
    version VARCHAR(20) NOT NULL,
    template_schema JSONB NOT NULL, -- Structure of the report
    output_formats VARCHAR(50)[] DEFAULT ARRAY['PDF', 'HTML', 'CSV']::VARCHAR(50)[],
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(template_name, framework_id, version)
);

-- Generated ESG Reports
CREATE TABLE esg_reports (
    report_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES esg_report_templates(template_id),
    reporting_period_id INTEGER REFERENCES fiscal_periods(period_id),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(50) NOT NULL,
    report_data JSONB, -- Full report data in structured format
    publication_status VARCHAR(20) DEFAULT 'Draft' CHECK (publication_status IN ('Draft', 'Published', 'Archived')),
    published_at TIMESTAMP,
    published_to VARCHAR(100)[],
    UNIQUE(template_id, reporting_period_id)
);

-- ESG Audit Trail
CREATE TABLE esg_audit_log (
    audit_id SERIAL PRIMARY KEY,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('Data Entry', 'Data Update', 'Data Verification', 'Report Generation', 'Target Setting')),
    user_id VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    old_value JSONB,
    new_value JSONB,
    change_reason TEXT
);

-- Views for ESG & Sustainability Analytics

-- ESG Performance Dashboard
CREATE VIEW esg_performance_dashboard AS
SELECT
    ec.category_name,
    ec.dimension,
    em.metric_name,
    em.unit_of_measure,
    ed.subsidiary_id,
    s.subsidiary_name,
    fp.period_name,
    ed.value AS current_value,
    et.target_value,
    (ed.value - et.target_value) AS variance,
    CASE
        WHEN em.better_direction = 'U' THEN
            CASE WHEN ed.value >= et.target_value THEN 'Target Achieved' ELSE 'Below Target' END
        WHEN em.better_direction = 'D' THEN
            CASE WHEN ed.value <= et.target_value THEN 'Target Achieved' ELSE 'Above Target' END
        ELSE 'N/A'
    END AS target_status,
    ed.data_quality_score
FROM esg_data_points ed
JOIN esg_metrics em ON ed.metric_id = em.metric_id
JOIN esg_categories ec ON em.category_id = ec.category_id
JOIN fiscal_periods fp ON ed.reporting_period_id = fp.period_id
LEFT JOIN subsidiaries s ON ed.subsidiary_id = s.subsidiary_id
LEFT JOIN esg_targets et ON em.metric_id = et.metric_id
    AND ed.subsidiary_id = et.subsidiary_id
    AND EXTRACT(YEAR FROM fp.end_date) = et.target_year
WHERE em.is_kpi = TRUE;

-- Carbon Emissions Summary
CREATE VIEW carbon_emissions_summary AS
SELECT
    s.subsidiary_name,
    fp.period_name,
    ce.scope,
    SUM(ce.co2e_amount) AS total_co2e,
    COUNT(DISTINCT ce.emission_source) AS emission_sources_count,
    (SELECT SUM(co2e_amount) FROM carbon_emissions
     WHERE subsidiary_id = ce.subsidiary_id
     AND reporting_period_id = ce.reporting_period_id
     AND scope = 1) AS scope_1_total,
    (SELECT SUM(co2e_amount) FROM carbon_emissions
     WHERE subsidiary_id = ce.subsidiary_id
     AND reporting_period_id = ce.reporting_period_id
     AND scope = 2) AS scope_2_total,
    (SELECT SUM(co2e_amount) FROM carbon_emissions
     WHERE subsidiary_id = ce.subsidiary_id
     AND reporting_period_id = ce.reporting_period_id
     AND scope = 3) AS scope_3_total
FROM carbon_emissions ce
JOIN subsidiaries s ON ce.subsidiary_id = s.subsidiary_id
JOIN fiscal_periods fp ON ce.reporting_period_id = fp.period_id
GROUP BY s.subsidiary_name, fp.period_name, ce.scope, ce.subsidiary_id, ce.reporting_period_id;

-- DEI Progress View
CREATE VIEW dei_progress_view AS
SELECT
    s.subsidiary_name,
    fp.period_name,
    dm.metric_type,
    dm.category,
    dm.leadership_level,
    dm.employee_count,
    dm.percentage,
    LAG(dm.percentage) OVER (PARTITION BY dm.subsidiary_id, dm.metric_type, dm.category, dm.leadership_level
                            ORDER BY fp.end_date) AS prev_percentage,
    (dm.percentage - LAG(dm.percentage) OVER (PARTITION BY dm.subsidiary_id, dm.metric_type, dm.category, dm.leadership_level
                                            ORDER BY fp.end_date)) AS percentage_change
FROM dei_metrics dm
JOIN subsidiaries s ON dm.subsidiary_id = s.subsidiary_id
JOIN fiscal_periods fp ON dm.reporting_period_id = fp.period_id;

-- Framework Compliance Status
CREATE VIEW framework_compliance_status AS
SELECT
    ef.framework_name,
    ef.framework_standard,
    ec.category_name,
    ec.dimension,
    fm.requirement_code,
    COUNT(ed.data_point_id) AS data_points_collected,
    COUNT(DISTINCT ed.subsidiary_id) AS subsidiaries_covered,
    (COUNT(ed.data_point_id) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM subsidiaries WHERE is_active = TRUE), 0)) AS coverage_percentage
FROM framework_mappings fm
JOIN esg_frameworks ef ON fm.framework_id = ef.framework_id
JOIN esg_categories ec ON fm.category_id = ec.category_id
LEFT JOIN esg_metrics em ON ec.category_id = em.category_id
LEFT JOIN esg_data_points ed ON em.metric_id = ed.metric_id
WHERE ef.is_active = TRUE
GROUP BY ef.framework_name, ef.framework_standard, ec.category_name, ec.dimension, fm.requirement_code;

-- Stored Procedures for ESG & Sustainability Analytics

-- Calculate Carbon Footprint
CREATE OR REPLACE FUNCTION calculate_carbon_footprint(
    p_subsidiary_id INTEGER,
    p_period_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    v_total_co2e NUMERIC(20,2) := 0;
BEGIN
    -- Sum all emissions for the subsidiary and period
    SELECT SUM(co2e_amount) INTO v_total_co2e
    FROM carbon_emissions
    WHERE subsidiary_id = p_subsidiary_id
    AND reporting_period_id = p_period_id;

    -- Return the total (NULL becomes 0)
    RETURN COALESCE(v_total_co2e, 0);
END;
$$ LANGUAGE plpgsql;

-- Generate ESG Report
CREATE OR REPLACE FUNCTION generate_esg_report(
    p_template_id INTEGER,
    p_period_id INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_report_id INTEGER;
    v_framework_id INTEGER;
    v_report_data JSONB := '{}'::JSONB;
    v_metric RECORD;
    v_category RECORD;
    v_requirement RECORD;
BEGIN
    -- Get framework for this template
    SELECT framework_id INTO v_framework_id
    FROM esg_report_templates
    WHERE template_id = p_template_id;

    -- Create report record
    INSERT INTO esg_reports (
        template_id, reporting_period_id, generated_by
    )
    VALUES (
        p_template_id, p_period_id, p_user_id
    )
    RETURNING report_id INTO v_report_id;

    -- Build report data structure
    -- For each category in the framework
    FOR v_category IN
        SELECT DISTINCT ec.category_id, ec.category_name, ec.dimension
        FROM framework_mappings fm
        JOIN esg_categories ec ON fm.category_id = ec.category_id
        WHERE fm.framework_id = v_framework_id
    LOOP
        -- Initialize category section
        v_report_data := jsonb_set(v_report_data, ARRAY[v_category.dimension, v_category.category_name], '{}'::JSONB);

        -- For each requirement in this category
        FOR v_requirement IN
            SELECT requirement_code, requirement_description
            FROM framework_mappings
            WHERE framework_id = v_framework_id
            AND category_id = v_category.category_id
        LOOP
            -- Initialize requirement section
            v_report_data := jsonb_set(v_report_data,
                ARRAY[v_category.dimension, v_category.category_name, v_requirement.requirement_code],
                jsonb_build_object(
                    'description', v_requirement.requirement_description,
                    'metrics', '[]'::JSONB
                )
            );

            -- Add all metrics for this requirement
            FOR v_metric IN
                SELECT
                    em.metric_name,
                    em.unit_of_measure,
                    ed.value,
                    ed.measurement_date,
                    ed.data_quality_score,
                    s.subsidiary_name
                FROM esg_metrics em
                JOIN esg_data_points ed ON em.metric_id = ed.metric_id
                JOIN subsidiaries s ON ed.subsidiary_id = s.subsidiary_id
                JOIN framework_mappings fm ON em.category_id = fm.category_id
                WHERE ed.reporting_period_id = p_period_id
                AND fm.framework_id = v_framework_id
                AND fm.requirement_code = v_requirement.requirement_code
                AND em.category_id = v_category.category_id
            LOOP
                v_report_data := jsonb_set(v_report_data,
                    ARRAY[v_category.dimension, v_category.category_name, v_requirement.requirement_code, 'metrics', '-'],
                    jsonb_build_object(
                        'metric_name', v_metric.metric_name,
                        'unit_of_measure', v_metric.unit_of_measure,
                        'value', v_metric.value,
                        'measurement_date', v_metric.measurement_date,
                        'data_quality', v_metric.data_quality_score,
                        'subsidiary', v_metric.subsidiary_name
                    ),
                    true
                );
            END LOOP;
        END LOOP;
    END LOOP;

    -- Update report with collected data
    UPDATE esg_reports
    SET report_data = v_report_data
    WHERE report_id = v_report_id;

    -- Log report generation
    INSERT INTO esg_audit_log (
        action_type, user_id, entity_type, entity_id, new_value
    )
    VALUES (
        'Report Generation', p_user_id, 'ESG Report', v_report_id,
        jsonb_build_object('template_id', p_template_id, 'period_id', p_period_id)
    );

    RETURN v_report_id;
END;
$$ LANGUAGE plpgsql;

-- Set Science-Based Target
CREATE OR REPLACE FUNCTION set_science_based_target(
    p_metric_id INTEGER,
    p_subsidiary_id INTEGER,
    p_target_year INTEGER,
    p_target_value NUMERIC,
    p_user_id VARCHAR,
    p_baseline_year INTEGER DEFAULT NULL,
    p_baseline_value NUMERIC DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_target_id INTEGER;
BEGIN
    -- Insert or update target
    INSERT INTO esg_targets (
        metric_id, subsidiary_id, target_value, target_year,
        baseline_value, baseline_year, is_science_based,
        approval_status, approved_by, approved_at
    )
    VALUES (
        p_metric_id, p_subsidiary_id, p_target_value, p_target_year,
        p_baseline_value, p_baseline_year, TRUE,
        'Approved', p_user_id, CURRENT_TIMESTAMP
    )
    ON CONFLICT (metric_id, subsidiary_id, target_year)
    DO UPDATE SET
        target_value = EXCLUDED.target_value,
        baseline_value = EXCLUDED.baseline_value,
        baseline_year = EXCLUDED.baseline_year,
        is_science_based = EXCLUDED.is_science_based,
        approval_status = EXCLUDED.approval_status,
        approved_by = EXCLUDED.approved_by,
        approved_at = EXCLUDED.approved_at
    RETURNING target_id INTO v_target_id;

    -- Log target setting
    INSERT INTO esg_audit_log (
        action_type, user_id, entity_type, entity_id, new_value
    )
    VALUES (
        'Target Setting', p_user_id, 'ESG Target', v_target_id,
        jsonb_build_object(
            'metric_id', p_metric_id,
            'target_value', p_target_value,
            'target_year', p_target_year,
            'science_based', TRUE
        )
    );

    RETURN v_target_id;
END;
$$ LANGUAGE plpgsql;

-- ESG Analytics INdex
CREATE INDEX idx_esg_data_metric_period ON esg_data_points(metric_id, reporting_period_id);
CREATE INDEX idx_carbon_emissions_subsidiary ON carbon_emissions(subsidiary_id, scope, reporting_period_id);
CREATE INDEX idx_dei_metrics_type_period ON dei_metrics(metric_type, reporting_period_id);
CREATE INDEX idx_esg_targets_metric_year ON esg_targets(metric_id, target_year);
CREATE INDEX idx_esg_reports_template_period ON esg_reports(template_id, reporting_period_id);


-- Merger and Acquisition Due Deligence toolkit
-- Add M&A Due Diligence Toolkit tables to the enterprise_cpa schema

-- M&A Projects
CREATE TABLE ma_projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    target_company VARCHAR(100) NOT NULL,
    industry VARCHAR(100),
    deal_size NUMERIC(15,2),
    deal_stage VARCHAR(50) CHECK (deal_stage IN ('Prospecting', 'LOI', 'Due Diligence', 'Negotiation', 'Closed', 'Abandoned')),
    start_date DATE,
    target_close_date DATE,
    internal_sponsor VARCHAR(100),
    project_lead VARCHAR(100),
    confidentiality_level VARCHAR(20) CHECK (confidentiality_level IN ('Public', 'Internal', 'Secret', 'Top Secret')),
    UNIQUE(project_name)
);

-- Due Diligence Areas
CREATE TABLE diligence_areas (
    area_id SERIAL PRIMARY KEY,
    area_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Financial', 'Legal', 'Operational', 'Tax', 'HR', 'IT', 'Commercial', 'Environmental')),
    description TEXT,
    weight NUMERIC(5,2) CHECK (weight BETWEEN 0 AND 1),
    UNIQUE(area_name)
);

-- Due Diligence Checklists
CREATE TABLE diligence_checklists (
    checklist_id SERIAL PRIMARY KEY,
    area_id INTEGER REFERENCES diligence_areas(area_id),
    checklist_name VARCHAR(100) NOT NULL,
    checklist_description TEXT,
    version VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(area_id, checklist_name, version)
);

-- Checklist Items
CREATE TABLE checklist_items (
    item_id SERIAL PRIMARY KEY,
    checklist_id INTEGER REFERENCES diligence_checklists(checklist_id),
    item_text TEXT NOT NULL,
    item_guidance TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    item_order INTEGER NOT NULL,
    UNIQUE(checklist_id, item_text)
);

-- Project Checklists (Instance-specific)
CREATE TABLE project_checklists (
    project_item_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    item_id INTEGER REFERENCES checklist_items(item_id),
    status VARCHAR(20) DEFAULT 'Not Started' CHECK (status IN ('Not Started', 'In Progress', 'Completed', 'N/A', 'Issue Found')),
    assigned_to VARCHAR(100),
    due_date DATE,
    completed_date DATE,
    notes TEXT,
    risk_score INTEGER CHECK (risk_score BETWEEN 1 AND 5),
    supporting_docs INTEGER[], -- References to document_library
    UNIQUE(project_id, item_id)
);

-- Risk Scoring Framework
CREATE TABLE risk_factors (
    risk_id SERIAL PRIMARY KEY,
    risk_name VARCHAR(100) NOT NULL,
    risk_category VARCHAR(50) CHECK (risk_category IN ('Financial', 'Legal', 'Operational', 'Reputational', 'Compliance')),
    severity_weights JSONB NOT NULL, -- {low: 1, medium: 3, high: 5}
    probability_weights JSONB NOT NULL, -- {low: 1, medium: 2, high: 3}
    UNIQUE(risk_name)
);

-- Project Risks
CREATE TABLE project_risks (
    project_risk_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    risk_id INTEGER REFERENCES risk_factors(risk_id),
    severity VARCHAR(20) CHECK (severity IN ('Low', 'Medium', 'High')),
    probability VARCHAR(20) CHECK (probability IN ('Low', 'Medium', 'High')),
    calculated_score INTEGER GENERATED ALWAYS AS (
        (SELECT (severity_weights->>LOWER(severity))::INTEGER *
         (SELECT (probability_weights->>LOWER(probability))::INTEGER
        FROM risk_factors WHERE risk_id = project_risks.risk_id
    ) STORED,
    mitigation_plan TEXT,
    owner VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'Mitigated', 'Accepted', 'Transferred')),
    UNIQUE(project_id, risk_id)
);

-- Document Library
CREATE TABLE document_library (
    doc_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    document_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) CHECK (document_type IN ('Financial', 'Legal', 'Contract', 'Report', 'Presentation', 'Analysis')),
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(100) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    file_size INTEGER NOT NULL,
    confidentiality_level VARCHAR(20) CHECK (confidentiality_level IN ('Public', 'Internal', 'Confidential', 'Secret')),
    tags VARCHAR(100)[],
    version INTEGER DEFAULT 1,
    source VARCHAR(100), -- Original source of document
    UNIQUE(project_id, document_name, version)
);

-- External Data Connections
CREATE TABLE external_data_sources (
    source_id SERIAL PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL,
    source_type VARCHAR(50) CHECK (source_type IN ('Legal', 'Credit', 'Market', 'Regulatory')),
    api_endpoint VARCHAR(255),
    auth_type VARCHAR(50),
    refresh_frequency VARCHAR(20),
    last_refreshed TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(source_name)
);

-- External Data Snapshots
CREATE TABLE external_data_snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    source_id INTEGER REFERENCES external_data_sources(source_id),
    project_id INTEGER REFERENCES ma_projects(project_id),
    query_parameters JSONB,
    retrieved_data JSONB,
    retrieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    analyzed_by VARCHAR(100),
    analysis_notes TEXT,
    UNIQUE(source_id, project_id)
);

-- Integration Logs
CREATE TABLE integration_logs (
    log_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    source_id INTEGER REFERENCES external_data_sources(source_id),
    action_type VARCHAR(50) CHECK (action_type IN ('Search', 'Retrieve', 'Analyze', 'Error')),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('Success', 'Partial', 'Failed')),
    records_retrieved INTEGER,
    error_message TEXT
);

-- Valuation Models
CREATE TABLE valuation_models (
    model_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    model_type VARCHAR(50) CHECK (model_type IN ('DCF', 'Comparables', 'Precedent Transactions', 'LBO')),
    model_owner VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP,
    assumptions JSONB,
    valuation_range_low NUMERIC(15,2),
    valuation_range_high NUMERIC(15,2),
    primary_valuation NUMERIC(15,2),
    sensitivity_analysis JSONB,
    UNIQUE(project_id, model_type)
);

-- Synergy Analysis
CREATE TABLE synergy_analysis (
    synergy_id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES ma_projects(project_id),
    synergy_type VARCHAR(50) CHECK (synergy_type IN ('Cost', 'Revenue', 'Capital', 'Tax')),
    description TEXT,
    estimated_value NUMERIC(15,2),
    probability VARCHAR(20) CHECK (probability IN ('Low', 'Medium', 'High')),
    realization_timeline VARCHAR(50),
    owner VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Identified' CHECK (status IN ('Identified', 'Validated', 'Realized', 'Abandoned')),
    UNIQUE(project_id, synergy_type, description)
);

-- Views for M&A Due Diligence Toolkit

-- Project Due Diligence Status
CREATE VIEW project_diligence_status AS
SELECT
    p.project_id,
    p.project_name,
    p.target_company,
    p.deal_stage,
    da.area_name,
    dc.checklist_name,
    COUNT(pc.item_id) AS total_items,
    COUNT(pc.item_id) FILTER (WHERE pc.status = 'Completed') AS completed_items,
    (COUNT(pc.item_id) FILTER (WHERE pc.status = 'Completed') * 100.0 /
        NULLIF(COUNT(pc.item_id), 0))::NUMERIC(5,2) AS completion_percentage,
    COUNT(pc.item_id) FILTER (WHERE pc.risk_score >= 4) AS high_risk_items
FROM ma_projects p
JOIN project_checklists pc ON p.project_id = pc.project_id
JOIN checklist_items ci ON pc.item_id = ci.item_id
JOIN diligence_checklists dc ON ci.checklist_id = dc.checklist_id
JOIN diligence_areas da ON dc.area_id = da.area_id
GROUP BY p.project_id, p.project_name, p.target_company, p.deal_stage, da.area_name, dc.checklist_name;

-- Project Risk Dashboard
CREATE VIEW project_risk_dashboard AS
SELECT
    p.project_id,
    p.project_name,
    p.target_company,
    rf.risk_name,
    rf.risk_category,
    pr.severity,
    pr.probability,
    pr.calculated_score,
    pr.status,
    (SELECT COUNT(*) FROM project_checklists pc
     JOIN checklist_items ci ON pc.item_id = ci.item_id
     WHERE pc.project_id = p.project_id
     AND pc.risk_score >= 4
     AND ci.checklist_id IN (
         SELECT checklist_id FROM diligence_checklists
         WHERE area_id IN (
             SELECT area_id FROM diligence_areas
             WHERE category = rf.risk_category
         )
     )) AS related_high_risk_items
FROM ma_projects p
JOIN project_risks pr ON p.project_id = pr.project_id
JOIN risk_factors rf ON pr.risk_id = rf.risk_id;

-- Document Coverage View
CREATE VIEW document_coverage_view AS
SELECT
    p.project_id,
    p.project_name,
    da.area_name,
    COUNT(DISTINCT dl.doc_id) AS documents_available,
    COUNT(DISTINCT ci.item_id) AS checklist_items,
    (COUNT(DISTINCT dl.doc_id) * 100.0 /
        NULLIF(COUNT(DISTINCT ci.item_id), 0))::NUMERIC(5,2) AS coverage_percentage
FROM ma_projects p
JOIN diligence_areas da ON 1=1
LEFT JOIN diligence_checklists dc ON da.area_id = dc.area_id
LEFT JOIN checklist_items ci ON dc.checklist_id = ci.checklist_id
LEFT JOIN project_checklists pc ON p.project_id = pc.project_id AND ci.item_id = pc.item_id
LEFT JOIN document_library dl ON p.project_id = dl.project_id
    AND dl.document_type = da.category
GROUP BY p.project_id, p.project_name, da.area_name;

-- External Data Integration Status
CREATE VIEW external_data_status AS
SELECT
    p.project_id,
    p.project_name,
    eds.source_name,
    eds.source_type,
    MAX(edsn.retrieved_at) AS last_retrieved,
    COUNT(edsn.snapshot_id) AS snapshots_count,
    STRING_AGG(DISTINCT edsn.analyzed_by, ', ') AS analysts,
    MAX(il.action_timestamp) AS last_attempt,
    MAX(il.status) AS last_status
FROM ma_projects p
JOIN external_data_snapshots edsn ON p.project_id = edsn.project_id
JOIN external_data_sources eds ON edsn.source_id = eds.source_id
LEFT JOIN integration_logs il ON eds.source_id = il.source_id AND p.project_id = il.project_id
GROUP BY p.project_id, p.project_name, eds.source_name, eds.source_type;

-- Stored Procedures for M&A Due Diligence Toolkit

-- Initialize Project Due Diligence
CREATE OR REPLACE FUNCTION initialize_project_diligence(
    p_project_id INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_checklist_count INTEGER := 0;
    v_item_count INTEGER := 0;
    v_checklist RECORD;
    v_item RECORD;
BEGIN
    -- Create project checklists for all active checklists
    FOR v_checklist IN
        SELECT dc.checklist_id, dc.area_id
        FROM diligence_checklists dc
        WHERE dc.is_active = TRUE
    LOOP
        -- For each item in the checklist
        FOR v_item IN
            SELECT item_id FROM checklist_items
            WHERE checklist_id = v_checklist.checklist_id
        LOOP
            INSERT INTO project_checklists (
                project_id, item_id
            )
            VALUES (
                p_project_id, v_item.item_id
            );

            v_item_count := v_item_count + 1;
        END LOOP;

        v_checklist_count := v_checklist_count + 1;
    END LOOP;

    -- Log initialization
    INSERT INTO integration_logs (
        project_id, action_type, status, records_retrieved
    )
    VALUES (
        p_project_id, 'Initialize', 'Success', v_item_count
    );

    RETURN v_checklist_count;
END;
$$ LANGUAGE plpgsql;

-- Calculate Project Risk Score
CREATE OR REPLACE FUNCTION calculate_project_risk_score(
    p_project_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    v_total_weight NUMERIC := 0;
    v_weighted_score NUMERIC := 0;
    v_area RECORD;
    v_max_possible_score NUMERIC := 0;
    v_normalized_score NUMERIC;
BEGIN
    -- Calculate weighted risk score across all diligence areas
    FOR v_area IN
        SELECT
            da.area_id,
            da.weight,
            COALESCE(AVG(pc.risk_score), 0) AS avg_risk_score
        FROM diligence_areas da
        LEFT JOIN diligence_checklists dc ON da.area_id = dc.area_id
        LEFT JOIN checklist_items ci ON dc.checklist_id = ci.checklist_id
        LEFT JOIN project_checklists pc ON ci.item_id = pc.item_id AND pc.project_id = p_project_id
        GROUP BY da.area_id, da.weight
    LOOP
        IF v_area.weight > 0 THEN
            v_weighted_score := v_weighted_score + (v_area.avg_risk_score * v_area.weight);
            v_total_weight := v_total_weight + v_area.weight;
            v_max_possible_score := v_max_possible_score + (5 * v_area.weight); -- 5 is max risk score
        END IF;
    END LOOP;

    -- Normalize to 0-100 scale
    IF v_max_possible_score > 0 THEN
        v_normalized_score := (v_weighted_score / v_max_possible_score) * 100;
    ELSE
        v_normalized_score := 0;
    END IF;

    RETURN ROUND(v_normalized_score, 2);
END;
$$ LANGUAGE plpgsql;

-- Retrieve External Data
CREATE OR REPLACE FUNCTION retrieve_external_data(
    p_project_id INTEGER,
    p_source_id INTEGER,
    p_query_params JSONB,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_snapshot_id INTEGER;
    v_source_type VARCHAR;
    v_status VARCHAR := 'Success';
    v_records INTEGER := 0;
    v_error_msg TEXT;
BEGIN
    -- Get source type
    SELECT source_type INTO v_source_type
    FROM external_data_sources
    WHERE source_id = p_source_id;

    -- In production, this would call the actual API integration
    -- For this example, we'll simulate data retrieval
    BEGIN
        -- Simulate different data based on source type
        IF v_source_type = 'Legal' THEN
            INSERT INTO external_data_snapshots (
                source_id, project_id, query_parameters, retrieved_data
            )
            VALUES (
                p_source_id, p_project_id, p_query_params,
                jsonb_build_object(
                    'cases', jsonb_build_array(
                        jsonb_build_object(
                            'case_id', 'L-2023-1542',
                            'title', 'Intellectual Property Dispute',
                            'filing_date', '2023-05-15',
                            'status', 'Pending'
                        )
                    ),
                    'liens', jsonb_build_array(),
                    'judgments', jsonb_build_array()
                )
            )
            RETURNING snapshot_id INTO v_snapshot_id;

            v_records := 1;
        ELSIF v_source_type = 'Credit' THEN
            INSERT INTO external_data_snapshots (
                source_id, project_id, query_parameters, retrieved_data
            )
            VALUES (
                p_source_id, p_project_id, p_query_params,
                jsonb_build_object(
                    'credit_score', 720,
                    'rating', 'BB+',
                    'outstanding_debt', 2500000,
                    'payment_history', jsonb_build_object(
                        'delinquencies', 2,
                        'late_payments', 5
                    )
                )
            )
            RETURNING snapshot_id INTO v_snapshot_id;

            v_records := 1;
        ELSE
            -- Simulate empty result for other types
            INSERT INTO external_data_snapshots (
                source_id, project_id, query_parameters, retrieved_data
            )
            VALUES (
                p_source_id, p_project_id, p_query_params,
                jsonb_build_object('results', jsonb_build_array())
            )
            RETURNING snapshot_id INTO v_snapshot_id;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_status := 'Failed';
        v_error_msg := SQLERRM;
        v_records := 0;
    END;

    -- Log the retrieval
    INSERT INTO integration_logs (
        project_id, source_id, action_type, status,
        records_retrieved, error_message
    )
    VALUES (
        p_project_id, p_source_id, 'Retrieve', v_status,
        v_records, v_error_msg
    );

    -- Update source last refreshed time if successful
    IF v_status = 'Success' THEN
        UPDATE external_data_sources
        SET last_refreshed = CURRENT_TIMESTAMP
        WHERE source_id = p_source_id;
    END IF;

    RETURN v_snapshot_id;
END;
$$ LANGUAGE plpgsql;

-- M&A Due Dilligence Index
CREATE INDEX idx_project_checklists_project ON project_checklists(project_id, status);
CREATE INDEX idx_project_risks_score ON project_risks(project_id, calculated_score);
CREATE INDEX idx_document_library_project ON document_library(project_id, document_type);
CREATE INDEX idx_external_snapshots_project ON external_data_snapshots(project_id, source_id);
CREATE INDEX idx_valuation_models_project ON valuation_models(project_id, model_type);


--risk maangemetn with heat map -- metrics for risk
-- Add Risk Heatmap Dashboard tables to the enterprise_cpa schema

-- Risk Domains
CREATE TABLE risk_domains (
    domain_id SERIAL PRIMARY KEY,
    domain_name VARCHAR(50) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(domain_name)
);

-- Risk Categories
CREATE TABLE risk_categories (
    category_id SERIAL PRIMARY KEY,
    domain_id INTEGER REFERENCES risk_domains(domain_id),
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    weight NUMERIC(5,2) CHECK (weight BETWEEN 0 AND 1),
    UNIQUE(domain_id, category_name)
);

-- Risk Register
CREATE TABLE risk_register (
    risk_id SERIAL PRIMARY KEY,
    risk_name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES risk_categories(category_id),
    description TEXT,
    inherent_impact INTEGER CHECK (inherent_impact BETWEEN 1 AND 5),
    inherent_likelihood INTEGER CHECK (inherent_likelihood BETWEEN 1 AND 5),
    inherent_score INTEGER GENERATED ALWAYS AS (inherent_impact * inherent_likelihood) STORED,
    residual_impact INTEGER CHECK (residual_impact BETWEEN 1 AND 5),
    residual_likelihood INTEGER CHECK (residual_likelihood BETWEEN 1 AND 5),
    residual_score INTEGER GENERATED ALWAYS AS (residual_impact * residual_likelihood) STORED,
    risk_owner VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) NOT NULL,
    last_updated TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Mitigated', 'Retired', 'Transferred')),
    UNIQUE(risk_name, category_id)
);

-- Risk Controls
CREATE TABLE risk_controls (
    control_id SERIAL PRIMARY KEY,
    risk_id INTEGER REFERENCES risk_register(risk_id),
    control_name VARCHAR(100) NOT NULL,
    control_type VARCHAR(50) CHECK (control_type IN ('Preventive', 'Detective', 'Corrective', 'Deterrent')),
    control_frequency VARCHAR(50) CHECK (control_frequency IN ('Continuous', 'Daily', 'Weekly', 'Monthly', 'Quarterly', 'Annual')),
    control_owner VARCHAR(100),
    description TEXT,
    implementation_date DATE,
    last_test_date DATE,
    next_test_date DATE,
    effectiveness_score INTEGER CHECK (effectiveness_score BETWEEN 1 AND 5),
    UNIQUE(risk_id, control_name)
);

-- Risk Indicators (KRIs)
CREATE TABLE risk_indicators (
    indicator_id SERIAL PRIMARY KEY,
    risk_id INTEGER REFERENCES risk_register(risk_id),
    indicator_name VARCHAR(100) NOT NULL,
    measurement_unit VARCHAR(50) NOT NULL,
    current_value NUMERIC(20,6),
    threshold_green NUMERIC(20,6),
    threshold_amber NUMERIC(20,6),
    threshold_red NUMERIC(20,6),
    last_measured TIMESTAMP,
    data_source VARCHAR(100),
    refresh_frequency VARCHAR(50),
    trend_direction VARCHAR(20) CHECK (trend_direction IN ('Improving', 'Stable', 'Deteriorating')),
    UNIQUE(risk_id, indicator_name)
);

-- Mitigation Actions
CREATE TABLE mitigation_actions (
    action_id SERIAL PRIMARY KEY,
    risk_id INTEGER REFERENCES risk_register(risk_id),
    action_name VARCHAR(100) NOT NULL,
    action_description TEXT,
    due_date DATE,
    completion_date DATE,
    assigned_to VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Not Started' CHECK (status IN ('Not Started', 'In Progress', 'Completed', 'Delayed', 'Cancelled')),
    progress_percentage NUMERIC(5,2) CHECK (progress_percentage BETWEEN 0 AND 100),
    UNIQUE(risk_id, action_name)
);

-- GRC Integration Logs
CREATE TABLE grc_integration_logs (
    log_id SERIAL PRIMARY KEY,
    integration_type VARCHAR(50) CHECK (integration_type IN ('Risk', 'Control', 'Incident', 'Policy')),
    external_system VARCHAR(50) NOT NULL,
    action_type VARCHAR(50) CHECK (action_type IN ('Import', 'Export', 'Sync')),
    records_processed INTEGER,
    status VARCHAR(20) CHECK (status IN ('Success', 'Partial', 'Failed')),
    error_message TEXT,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(50)
);

-- Risk Snapshots (For historical tracking)
CREATE TABLE risk_snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    snapshot_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    snapshot_period VARCHAR(20) CHECK (snapshot_period IN ('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Adhoc')),
    created_by VARCHAR(50) NOT NULL,
    notes TEXT
);

-- Snapshot Risks
CREATE TABLE snapshot_risks (
    snapshot_risk_id SERIAL PRIMARY KEY,
    snapshot_id INTEGER REFERENCES risk_snapshots(snapshot_id),
    risk_id INTEGER REFERENCES risk_register(risk_id),
    current_impact INTEGER CHECK (current_impact BETWEEN 1 AND 5),
    current_likelihood INTEGER CHECK (current_likelihood BETWEEN 1 AND 5),
    current_score INTEGER GENERATED ALWAYS AS (current_impact * current_likelihood) STORED,
    status VARCHAR(20) CHECK (status IN ('New', 'Unchanged', 'Increased', 'Decreased')),
    UNIQUE(snapshot_id, risk_id)
);

-- Views for Risk Heatmap Dashboard

-- Current Risk Heatmap View
CREATE VIEW risk_heatmap_view AS
SELECT
    rd.domain_name,
    rc.category_name,
    rr.risk_id,
    rr.risk_name,
    rr.inherent_impact,
    rr.inherent_likelihood,
    rr.inherent_score,
    rr.residual_impact,
    rr.residual_likelihood,
    rr.residual_score,
    rr.status,
    rr.risk_owner,
    CASE
        WHEN rr.residual_score >= 16 THEN 'Extreme'
        WHEN rr.residual_score >= 9 THEN 'High'
        WHEN rr.residual_score >= 4 THEN 'Medium'
        ELSE 'Low'
    END AS risk_rating,
    COUNT(DISTINCT c.control_id) AS control_count,
    COUNT(DISTINCT ma.action_id) FILTER (WHERE ma.status != 'Completed') AS open_actions,
    MAX(ma.due_date) AS next_action_date
FROM risk_register rr
JOIN risk_categories rc ON rr.category_id = rc.category_id
JOIN risk_domains rd ON rc.domain_id = rd.domain_id
LEFT JOIN risk_controls c ON rr.risk_id = c.risk_id
LEFT JOIN mitigation_actions ma ON rr.risk_id = ma.risk_id
WHERE rr.status = 'Active'
GROUP BY rd.domain_name, rc.category_name, rr.risk_id, rr.risk_name,
         rr.inherent_impact, rr.inherent_likelihood, rr.inherent_score,
         rr.residual_impact, rr.residual_likelihood, rr.residual_score,
         rr.status, rr.risk_owner;

-- Risk Mitigation Progress View
CREATE VIEW risk_mitigation_progress AS
SELECT
    rr.risk_id,
    rr.risk_name,
    rc.category_name,
    rd.domain_name,
    COUNT(ma.action_id) AS total_actions,
    COUNT(ma.action_id) FILTER (WHERE ma.status = 'Completed') AS completed_actions,
    (COUNT(ma.action_id) FILTER (WHERE ma.status = 'Completed') * 100.0 /
        NULLIF(COUNT(ma.action_id), 0))::NUMERIC(5,2) AS completion_percentage,
    AVG(ma.progress_percentage) FILTER (WHERE ma.status != 'Completed') AS avg_in_progress,
    MIN(ma.due_date) FILTER (WHERE ma.status != 'Completed') AS next_due_date
FROM risk_register rr
JOIN risk_categories rc ON rr.category_id = rc.category_id
JOIN risk_domains rd ON rc.domain_id = rd.domain_id
LEFT JOIN mitigation_actions ma ON rr.risk_id = ma.risk_id
WHERE rr.status = 'Active'
GROUP BY rr.risk_id, rr.risk_name, rc.category_name, rd.domain_name;

-- KRI Status View
CREATE VIEW kri_status_view AS
SELECT
    rr.risk_id,
    rr.risk_name,
    ri.indicator_name,
    ri.current_value,
    ri.threshold_green,
    ri.threshold_amber,
    ri.threshold_red,
    CASE
        WHEN ri.current_value <= ri.threshold_green THEN 'Green'
        WHEN ri.current_value <= ri.threshold_amber THEN 'Amber'
        ELSE 'Red'
    END AS status,
    ri.trend_direction,
    ri.last_measured,
    ri.measurement_unit
FROM risk_indicators ri
JOIN risk_register rr ON ri.risk_id = rr.risk_id
WHERE rr.status = 'Active';

-- Risk Trend Analysis View
CREATE VIEW risk_trend_analysis AS
SELECT
    rr.risk_id,
    rr.risk_name,
    rc.category_name,
    rd.domain_name,
    ss.snapshot_date,
    sr.current_impact,
    sr.current_likelihood,
    sr.current_score,
    sr.status AS trend_status,
    LAG(sr.current_score) OVER (PARTITION BY rr.risk_id ORDER BY ss.snapshot_date) AS previous_score,
    (sr.current_score - LAG(sr.current_score) OVER (PARTITION BY rr.risk_id ORDER BY ss.snapshot_date)) AS score_change
FROM snapshot_risks sr
JOIN risk_snapshots ss ON sr.snapshot_id = ss.snapshot_id
JOIN risk_register rr ON sr.risk_id = rr.risk_id
JOIN risk_categories rc ON rr.category_id = rc.category_id
JOIN risk_domains rd ON rc.domain_id = rd.domain_id;

-- GRC Integration Status View
CREATE VIEW grc_integration_status AS
SELECT
    external_system,
    integration_type,
    action_type,
    COUNT(log_id) AS operation_count,
    COUNT(log_id) FILTER (WHERE status = 'Success') AS success_count,
    COUNT(log_id) FILTER (WHERE status = 'Failed') AS failure_count,
    MAX(performed_at) AS last_attempt,
    AVG(records_processed) FILTER (WHERE status = 'Success') AS avg_records_success
FROM grc_integration_logs
GROUP BY external_system, integration_type, action_type;

-- Stored Procedures for Risk Heatmap Dashboard

-- Create Risk Snapshot
CREATE OR REPLACE FUNCTION create_risk_snapshot(
    p_snapshot_period VARCHAR,
    p_user_id VARCHAR,
    p_notes TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_snapshot_id INTEGER;
    v_risk RECORD;
BEGIN
    -- Create snapshot record
    INSERT INTO risk_snapshots (
        snapshot_period, created_by, notes
    )
    VALUES (
        p_snapshot_period, p_user_id, p_notes
    )
    RETURNING snapshot_id INTO v_snapshot_id;

    -- Capture current state of all active risks
    FOR v_risk IN
        SELECT
            risk_id,
            residual_impact AS current_impact,
            residual_likelihood AS current_likelihood,
            CASE
                WHEN NOT EXISTS (
                    SELECT 1 FROM snapshot_risks sr
                    JOIN risk_snapshots ss ON sr.snapshot_id = ss.snapshot_id
                    WHERE sr.risk_id = rr.risk_id
                    ORDER BY ss.snapshot_date DESC
                    LIMIT 1
                ) THEN 'New'
                WHEN (residual_impact * residual_likelihood) > (
                    SELECT sr.current_score
                    FROM snapshot_risks sr
                    JOIN risk_snapshots ss ON sr.snapshot_id = ss.snapshot_id
                    WHERE sr.risk_id = rr.risk_id
                    ORDER BY ss.snapshot_date DESC
                    LIMIT 1
                ) THEN 'Increased'
                WHEN (residual_impact * residual_likelihood) < (
                    SELECT sr.current_score
                    FROM snapshot_risks sr
                    JOIN risk_snapshots ss ON sr.snapshot_id = ss.snapshot_id
                    WHERE sr.risk_id = rr.risk_id
                    ORDER BY ss.snapshot_date DESC
                    LIMIT 1
                ) THEN 'Decreased'
                ELSE 'Unchanged'
            END AS status
        FROM risk_register rr
        WHERE status = 'Active'
    LOOP
        INSERT INTO snapshot_risks (
            snapshot_id, risk_id, current_impact, current_likelihood, status
        )
        VALUES (
            v_snapshot_id, v_risk.risk_id, v_risk.current_impact, v_risk.current_likelihood, v_risk.status
        );
    END LOOP;

    RETURN v_snapshot_id;
END;
$$ LANGUAGE plpgsql;

-- Calculate Domain Risk Scores
CREATE OR REPLACE FUNCTION calculate_domain_risk_scores()
RETURNS TABLE (
    domain_id INTEGER,
    domain_name VARCHAR,
    inherent_score NUMERIC,
    residual_score NUMERIC,
    risk_count INTEGER,
    high_risk_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rd.domain_id,
        rd.domain_name,
        ROUND(AVG(rr.inherent_score)::NUMERIC, 2) AS inherent_score,
        ROUND(AVG(rr.residual_score)::NUMERIC, 2) AS residual_score,
        COUNT(rr.risk_id) AS risk_count,
        COUNT(rr.risk_id) FILTER (WHERE rr.residual_score >= 9) AS high_risk_count
    FROM risk_domains rd
    LEFT JOIN risk_categories rc ON rd.domain_id = rc.domain_id
    LEFT JOIN risk_register rr ON rc.category_id = rr.category_id
    WHERE rr.status = 'Active' OR rr.status IS NULL
    GROUP BY rd.domain_id, rd.domain_name
    ORDER BY residual_score DESC;
END;
$$ LANGUAGE plpgsql;

-- Sync Risks with GRC System
CREATE OR REPLACE FUNCTION sync_risks_with_grc(
    p_external_system VARCHAR,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_risk_count INTEGER := 0;
    v_success_count INTEGER := 0;
    v_failure_count INTEGER := 0;
    v_risk RECORD;
BEGIN
    -- In production, this would connect to the actual GRC system API
    -- For this example, we'll simulate the sync process

    -- Get all active risks that need to be synced
    FOR v_risk IN
        SELECT * FROM risk_register
        WHERE status = 'Active'
        AND (last_updated > COALESCE(
            (SELECT MAX(performed_at) FROM grc_integration_logs
             WHERE external_system = p_external_system
             AND integration_type = 'Risk'
             AND action_type = 'Export'),
            TIMESTAMP '1970-01-01')
        )
        OR NOT EXISTS (
            SELECT 1 FROM grc_integration_logs
            WHERE external_system = p_external_system
            AND integration_type = 'Risk'
            AND action_type = 'Export'
            AND records_processed > 0
        )
    LOOP
        BEGIN
            -- Simulate API call to GRC system
            -- In real implementation, this would be the actual integration code
            PERFORM pg_sleep(0.1); -- Simulate network delay

            -- Count as successful
            v_success_count := v_success_count + 1;
            v_risk_count := v_risk_count + 1;

            -- Update last_updated to prevent resync
            UPDATE risk_register
            SET last_updated = CURRENT_TIMESTAMP
            WHERE risk_id = v_risk.risk_id;
        EXCEPTION WHEN OTHERS THEN
            -- Count as failed
            v_failure_count := v_failure_count + 1;
            v_risk_count := v_risk_count + 1;
        END;
    END LOOP;

    -- Log the sync operation
    INSERT INTO grc_integration_logs (
        integration_type, external_system, action_type,
        records_processed, status, performed_by
    )
    VALUES (
        'Risk', p_external_system, 'Export',
        v_success_count,
        CASE WHEN v_failure_count = 0 THEN 'Success'
             WHEN v_success_count = 0 THEN 'Failed'
             ELSE 'Partial' END,
        p_user_id
    );

    RETURN v_success_count;
END;
$$ LANGUAGE plpgsql;

-- risk register index
CREATE INDEX idx_risk_register_category ON risk_register(category_id, status);
CREATE INDEX idx_risk_register_score ON risk_register(residual_score, inherent_score);
CREATE INDEX idx_risk_controls_risk ON risk_controls(risk_id);
CREATE INDEX idx_mitigation_actions_risk ON mitigation_actions(risk_id, status);
CREATE INDEX idx_snapshot_risks_snapshot ON snapshot_risks(snapshot_id);
CREATE INDEX idx_snapshot_risks_risk ON snapshot_risks(risk_id);
CREATE INDEX idx_grc_logs_system ON grc_integration_logs(external_system, integration_type);


--Benchamrking Engine -- comparative analysis against peers using anonymized industry data
-- comparative analysis on liquidity, profitability and efficiency
-- metrics for actionable insights for improvement

-- Add Benchmarking Engine tables to the enterprise_cpa schema

-- Industry Classification
CREATE TABLE industries (
    industry_id SERIAL PRIMARY KEY,
    industry_code VARCHAR(20) NOT NULL,
    industry_name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_industry_id INTEGER REFERENCES industries(industry_id),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(industry_code)
);

-- Company Peers
CREATE TABLE peer_groups (
    peer_group_id SERIAL PRIMARY KEY,
    group_name VARCHAR(100) NOT NULL,
    industry_id INTEGER REFERENCES industries(industry_id),
    company_size VARCHAR(20) CHECK (company_size IN ('Small', 'Medium', 'Large', 'Enterprise')),
    geography VARCHAR(100),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    UNIQUE(group_name, industry_id, company_size, geography)
);

-- Benchmark Metrics
CREATE TABLE benchmark_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_code VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Liquidity', 'Profitability', 'Efficiency', 'Growth', 'Leverage', 'Valuation')),
    formula TEXT,
    unit VARCHAR(20) NOT NULL,
    better_direction CHAR(1) CHECK (better_direction IN ('H', 'L', 'N')), -- Higher, Lower, Neutral
    description TEXT,
    UNIQUE(metric_code)
);

-- Benchmark Data (Anonymized)
CREATE TABLE benchmark_data (
    data_id SERIAL PRIMARY KEY,
    peer_group_id INTEGER REFERENCES peer_groups(peer_group_id),
    metric_id INTEGER REFERENCES benchmark_metrics(metric_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    percentile_10 NUMERIC(15,6),
    percentile_25 NUMERIC(15,6),
    median NUMERIC(15,6),
    percentile_75 NUMERIC(15,6),
    percentile_90 NUMERIC(15,6),
    average NUMERIC(15,6),
    std_dev NUMERIC(15,6),
    data_points INTEGER,
    refresh_date DATE,
    source VARCHAR(100),
    UNIQUE(peer_group_id, metric_id, period_id)
);

-- Company Benchmarking Results
CREATE TABLE company_benchmarks (
    benchmark_id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL, -- References internal company ID
    peer_group_id INTEGER REFERENCES peer_groups(peer_group_id),
    metric_id INTEGER REFERENCES benchmark_metrics(metric_id),
    period_id INTEGER REFERENCES fiscal_periods(period_id),
    company_value NUMERIC(15,6),
    peer_median NUMERIC(15,6),
    percentile_rank NUMERIC(5,2),
    z_score NUMERIC(10,6),
    variance_pct NUMERIC(10,2) GENERATED ALWAYS AS (
        CASE WHEN peer_median = 0 THEN NULL
        ELSE ((company_value - peer_median) / NULLIF(peer_median, 0)) * 100
        END
    ) STORED,
    performance_flag VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN percentile_rank >= 75 AND benchmark_metrics.better_direction = 'H' THEN 'Top Performer'
            WHEN percentile_rank >= 75 AND benchmark_metrics.better_direction = 'L' THEN 'Needs Improvement'
            WHEN percentile_rank <= 25 AND benchmark_metrics.better_direction = 'L' THEN 'Top Performer'
            WHEN percentile_rank <= 25 AND benchmark_metrics.better_direction = 'H' THEN 'Needs Improvement'
            ELSE 'In Line'
        END
    ) STORED,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (metric_id) REFERENCES benchmark_metrics(metric_id),
    UNIQUE(company_id, peer_group_id, metric_id, period_id)
);

-- Benchmark Insights
CREATE TABLE benchmark_insights (
    insight_id SERIAL PRIMARY KEY,
    benchmark_id INTEGER REFERENCES company_benchmarks(benchmark_id),
    insight_type VARCHAR(50) CHECK (insight_type IN ('Strength', 'Weakness', 'Opportunity', 'Threat')),
    insight_text TEXT NOT NULL,
    recommendation TEXT,
    priority INTEGER CHECK (priority BETWEEN 1 AND 3), -- 1=High, 3=Low
    relevant_departments VARCHAR(50)[],
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(50), -- System or user
    status VARCHAR(20) DEFAULT 'New' CHECK (status IN ('New', 'Reviewed', 'Actioned', 'Archived'))
);

-- Benchmarking Snapshots
CREATE TABLE benchmarking_snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL,
    peer_group_id INTEGER REFERENCES peer_groups(peer_group_id),
    snapshot_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metrics_compared INTEGER NOT NULL,
    strengths_count INTEGER,
    weaknesses_count INTEGER,
    created_by VARCHAR(50),
    notes TEXT
);

-- External Data Providers
CREATE TABLE benchmark_providers (
    provider_id SERIAL PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL,
    provider_type VARCHAR(50) CHECK (provider_type IN ('Commercial', 'Government', 'Industry', 'Research')),
    coverage VARCHAR(100),
    data_frequency VARCHAR(50),
    last_updated DATE,
    api_available BOOLEAN DEFAULT FALSE,
    UNIQUE(provider_name)
);

-- Views for Benchmarking Engine

-- Benchmark Comparison Dashboard
CREATE VIEW benchmark_comparison_view AS
SELECT
    c.company_id,
    pg.group_name AS peer_group,
    i.industry_name,
    bm.metric_name,
    bm.category,
    bm.unit,
    cb.company_value,
    cb.peer_median,
    cb.percentile_rank,
    cb.variance_pct,
    cb.performance_flag,
    bd.percentile_10,
    bd.percentile_25,
    bd.percentile_75,
    bd.percentile_90,
    bd.std_dev,
    bm.better_direction
FROM company_benchmarks cb
JOIN peer_groups pg ON cb.peer_group_id = pg.peer_group_id
JOIN industries i ON pg.industry_id = i.industry_id
JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
LEFT JOIN benchmark_data bd ON cb.peer_group_id = bd.peer_group_id
    AND cb.metric_id = bd.metric_id
    AND cb.period_id = bd.period_id;

-- Performance Outliers View
CREATE VIEW performance_outliers_view AS
SELECT
    cb.company_id,
    bm.metric_name,
    bm.category,
    cb.company_value,
    cb.peer_median,
    cb.variance_pct,
    cb.performance_flag,
    bi.insight_text,
    bi.recommendation,
    bi.priority
FROM company_benchmarks cb
JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
LEFT JOIN benchmark_insights bi ON cb.benchmark_id = bi.benchmark_id
WHERE cb.performance_flag IN ('Top Performer', 'Needs Improvement')
AND (bi.insight_id IS NULL OR bi.status != 'Archived')
ORDER BY
    CASE WHEN cb.performance_flag = 'Needs Improvement' THEN 0 ELSE 1 END,
    ABS(cb.variance_pct) DESC;

-- Trend Analysis View
CREATE VIEW benchmark_trend_view AS
SELECT
    cb.company_id,
    bm.metric_name,
    bm.category,
    fp.period_name,
    fp.end_date,
    cb.company_value,
    cb.peer_median,
    cb.percentile_rank,
    LAG(cb.company_value) OVER (PARTITION BY cb.company_id, cb.metric_id ORDER BY fp.end_date) AS prev_company_value,
    LAG(cb.percentile_rank) OVER (PARTITION BY cb.company_id, cb.metric_id ORDER BY fp.end_date) AS prev_percentile,
    (cb.percentile_rank - LAG(cb.percentile_rank) OVER (PARTITION BY cb.company_id, cb.metric_id ORDER BY fp.end_date)) AS percentile_change
FROM company_benchmarks cb
JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
JOIN fiscal_periods fp ON cb.period_id = fp.period_id;

-- Competitive Positioning View
CREATE VIEW competitive_positioning_view AS
SELECT
    cb.company_id,
    bm.category,
    COUNT(*) AS metric_count,
    COUNT(*) FILTER (WHERE cb.performance_flag = 'Top Performer') AS strength_count,
    COUNT(*) FILTER (WHERE cb.performance_flag = 'Needs Improvement') AS weakness_count,
    ROUND(AVG(cb.percentile_rank) FILTER (WHERE bm.better_direction = 'H') AS avg_rank_higher_better,
    ROUND(AVG(100 - cb.percentile_rank) FILTER (WHERE bm.better_direction = 'L')) AS avg_rank_lower_better
FROM company_benchmarks cb
JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
GROUP BY cb.company_id, bm.category;

-- Stored Procedures for Benchmarking Engine

-- Calculate Company Benchmarks
CREATE OR REPLACE FUNCTION calculate_company_benchmarks(
    p_company_id INTEGER,
    p_peer_group_id INTEGER,
    p_period_id INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_metric RECORD;
    v_benchmark_id INTEGER;
    v_count INTEGER := 0;
BEGIN
    -- Calculate benchmark for each metric in the peer group
    FOR v_metric IN
        SELECT
            bm.metric_id,
            bm.metric_code,
            bm.better_direction,
            (SELECT company_value FROM financial_metrics
             WHERE company_id = p_company_id
             AND metric_code = bm.metric_code
             AND period_id = p_period_id) AS company_value,
            bd.median AS peer_median,
            bd.percentile_25,
            bd.percentile_75,
            bd.std_dev
        FROM benchmark_metrics bm
        JOIN benchmark_data bd ON bm.metric_id = bd.metric_id
        WHERE bd.peer_group_id = p_peer_group_id
        AND bd.period_id = p_period_id
    LOOP
        -- Skip if no company value available
        CONTINUE WHEN v_metric.company_value IS NULL;

        -- Calculate percentile rank
        DECLARE
            v_percentile NUMERIC;
            v_z_score NUMERIC;
        BEGIN
            -- Simplified percentile calculation (in practice would use more precise method)
            IF v_metric.company_value <= v_metric.percentile_25 THEN
                v_percentile := 25 * (v_metric.company_value / NULLIF(v_metric.percentile_25, 0));
            ELSIF v_metric.company_value <= v_metric.median THEN
                v_percentile := 25 + 25 * ((v_metric.company_value - v_metric.percentile_25) /
                                   NULLIF((v_metric.median - v_metric.percentile_25), 0));
            ELSIF v_metric.company_value <= v_metric.percentile_75 THEN
                v_percentile := 50 + 25 * ((v_metric.company_value - v_metric.median) /
                                   NULLIF((v_metric.percentile_75 - v_metric.median), 0));
            ELSE
                v_percentile := 75 + 25 * ((v_metric.company_value - v_metric.percentile_75) /
                                   NULLIF((v_metric.percentile_75 * 1.2 - v_metric.percentile_75), 0));
            END IF;

            -- Calculate z-score
            v_z_score := (v_metric.company_value - v_metric.peer_median) / NULLIF(v_metric.std_dev, 0);

            -- Insert or update benchmark result
            INSERT INTO company_benchmarks (
                company_id, peer_group_id, metric_id, period_id,
                company_value, peer_median, percentile_rank, z_score
            )
            VALUES (
                p_company_id, p_peer_group_id, v_metric.metric_id, p_period_id,
                v_metric.company_value, v_metric.peer_median,
                LEAST(GREATEST(v_percentile, 0), 100), -- Ensure between 0-100
                v_z_score
            )
            ON CONFLICT (company_id, peer_group_id, metric_id, period_id)
            DO UPDATE SET
                company_value = EXCLUDED.company_value,
                peer_median = EXCLUDED.peer_median,
                percentile_rank = EXCLUDED.percentile_rank,
                z_score = EXCLUDED.z_score,
                calculated_at = CURRENT_TIMESTAMP
            RETURNING benchmark_id INTO v_benchmark_id;

            -- Generate insights for outliers
            IF (v_percentile >= 75 AND v_metric.better_direction = 'H') OR
               (v_percentile <= 25 AND v_metric.better_direction = 'L') THEN
                -- Strength
                INSERT INTO benchmark_insights (
                    benchmark_id, insight_type, insight_text, priority
                )
                VALUES (
                    v_benchmark_id, 'Strength',
                    'Top performer on ' || (SELECT metric_name FROM benchmark_metrics WHERE metric_id = v_metric.metric_id) ||
                    ' (better than ' || ROUND(v_percentile) || '% of peers)',
                    2
                );
            ELSIF (v_percentile >= 75 AND v_metric.better_direction = 'L') OR
                  (v_percentile <= 25 AND v_metric.better_direction = 'H') THEN
                -- Weakness
                INSERT INTO benchmark_insights (
                    benchmark_id, insight_type, insight_text, priority, recommendation
                )
                VALUES (
                    v_benchmark_id, 'Weakness',
                    'Lags peers on ' || (SELECT metric_name FROM benchmark_metrics WHERE metric_id = v_metric.metric_id) ||
                    ' (worse than ' || ROUND(100 - v_percentile) || '% of peers)',
                    1,
                    'Investigate root causes and develop improvement plan for ' ||
                    (SELECT metric_name FROM benchmark_metrics WHERE metric_id = v_metric.metric_id)
                );
            END IF;

            v_count := v_count + 1;
        END;
    END LOOP;

    -- Create snapshot record
    INSERT INTO benchmarking_snapshots (
        company_id, peer_group_id, metrics_compared,
        strengths_count, weaknesses_count, created_by
    )
    SELECT
        p_company_id, p_peer_group_id, v_count,
        COUNT(*) FILTER (WHERE bi.insight_type = 'Strength'),
        COUNT(*) FILTER (WHERE bi.insight_type = 'Weakness'),
        p_user_id
    FROM company_benchmarks cb
    LEFT JOIN benchmark_insights bi ON cb.benchmark_id = bi.benchmark_id
    WHERE cb.company_id = p_company_id
    AND cb.peer_group_id = p_peer_group_id
    AND cb.period_id = p_period_id
    AND (bi.insight_id IS NULL OR bi.status = 'New');

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Refresh Benchmark Data
CREATE OR REPLACE FUNCTION refresh_benchmark_data(
    p_peer_group_id INTEGER,
    p_period_id INTEGER,
    p_provider_id INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_metric RECORD;
    v_count INTEGER := 0;
BEGIN
    -- In production, this would fetch data from external provider API
    -- For this example, we'll simulate data refresh

    -- For each metric in the system
    FOR v_metric IN
        SELECT metric_id FROM benchmark_metrics
    LOOP
        -- Simulate fetching data (in real implementation, this would call the API)
        -- Generate random-ish data for demonstration
        DECLARE
            v_median NUMERIC := 100 + (RANDOM() * 200);
            v_std_dev NUMERIC := v_median * 0.3;
        BEGIN
            INSERT INTO benchmark_data (
                peer_group_id, metric_id, period_id,
                percentile_10, percentile_25, median,
                percentile_75, percentile_90, average,
                std_dev, data_points, refresh_date, source
            )
            VALUES (
                p_peer_group_id, v_metric.metric_id, p_period_id,
                v_median * 0.7, v_median * 0.85, v_median,
                v_median * 1.15, v_median * 1.3, v_median,
                v_std_dev, 100 + (RANDOM() * 400), CURRENT_DATE,
                (SELECT provider_name FROM benchmark_providers WHERE provider_id = p_provider_id)
            )
            ON CONFLICT (peer_group_id, metric_id, period_id)
            DO UPDATE SET
                percentile_10 = EXCLUDED.percentile_10,
                percentile_25 = EXCLUDED.percentile_25,
                median = EXCLUDED.median,
                percentile_75 = EXCLUDED.percentile_75,
                percentile_90 = EXCLUDED.percentile_90,
                average = EXCLUDED.average,
                std_dev = EXCLUDED.std_dev,
                data_points = EXCLUDED.data_points,
                refresh_date = EXCLUDED.refresh_date,
                source = EXCLUDED.source;

            v_count := v_count + 1;
        END;
    END LOOP;

    -- Update provider last_updated
    UPDATE benchmark_providers
    SET last_updated = CURRENT_DATE
    WHERE provider_id = p_provider_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Generate Benchmark Report
CREATE OR REPLACE FUNCTION generate_benchmark_report(
    p_company_id INTEGER,
    p_peer_group_id INTEGER,
    p_period_id INTEGER,
    p_user_id VARCHAR
) RETURNS JSONB AS $$
DECLARE
    v_report JSONB;
    v_strengths INTEGER;
    v_weaknesses INTEGER;
BEGIN
    -- Calculate benchmarks if not already done
    IF NOT EXISTS (
        SELECT 1 FROM company_benchmarks
        WHERE company_id = p_company_id
        AND peer_group_id = p_peer_group_id
        AND period_id = p_period_id
    ) THEN
        PERFORM calculate_company_benchmarks(p_company_id, p_peer_group_id, p_period_id, p_user_id);
    END IF;

    -- Get counts of strengths and weaknesses
    SELECT
        COUNT(*) FILTER (WHERE performance_flag = 'Top Performer'),
        COUNT(*) FILTER (WHERE performance_flag = 'Needs Improvement')
    INTO v_strengths, v_weaknesses
    FROM company_benchmarks
    WHERE company_id = p_company_id
    AND peer_group_id = p_peer_group_id
    AND period_id = p_period_id;

    -- Build report JSON structure
    v_report := jsonb_build_object(
        'metadata', jsonb_build_object(
            'generated_at', CURRENT_TIMESTAMP,
            'company_id', p_company_id,
            'peer_group', (SELECT group_name FROM peer_groups WHERE peer_group_id = p_peer_group_id),
            'period', (SELECT period_name FROM fiscal_periods WHERE period_id = p_period_id),
            'metrics_compared', (SELECT COUNT(*) FROM company_benchmarks
                                WHERE company_id = p_company_id
                                AND peer_group_id = p_peer_group_id
                                AND period_id = p_period_id)
        ),
        'summary', jsonb_build_object(
            'strengths_count', v_strengths,
            'weaknesses_count', v_weaknesses,
            'competitive_position', CASE
                WHEN v_strengths > 2 * v_weaknesses THEN 'Leading'
                WHEN v_strengths > v_weaknesses THEN 'Advantaged'
                WHEN v_strengths = v_weaknesses THEN 'Average'
                WHEN v_weaknesses > v_strengths THEN 'Challenged'
                ELSE 'Lagging'
            END
        ),
        'key_strengths', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric', bm.metric_name,
                'category', bm.category,
                'company_value', cb.company_value,
                'peer_median', cb.peer_median,
                'percentile', cb.percentile_rank,
                'insight', COALESCE(
                    (SELECT insight_text FROM benchmark_insights
                     WHERE benchmark_id = cb.benchmark_id
                     AND insight_type = 'Strength'
                     LIMIT 1),
                    'Strong performance relative to peers'
                )
            ))
            FROM company_benchmarks cb
            JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
            WHERE cb.company_id = p_company_id
            AND cb.peer_group_id = p_peer_group_id
            AND cb.period_id = p_period_id
            AND cb.performance_flag = 'Top Performer'
            ORDER BY cb.percentile_rank DESC
            LIMIT 5
        ),
        'key_weaknesses', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric', bm.metric_name,
                'category', bm.category,
                'company_value', cb.company_value,
                'peer_median', cb.peer_median,
                'percentile', cb.percentile_rank,
                'insight', COALESCE(
                    (SELECT insight_text FROM benchmark_insights
                     WHERE benchmark_id = cb.benchmark_id
                     AND insight_type = 'Weakness'
                     LIMIT 1),
                    'Needs improvement relative to peers'
                ),
                'recommendation', COALESCE(
                    (SELECT recommendation FROM benchmark_insights
                     WHERE benchmark_id = cb.benchmark_id
                     AND insight_type = 'Weakness'
                     LIMIT 1),
                    'Investigate root causes and develop improvement plan'
                )
            ))
            FROM company_benchmarks cb
            JOIN benchmark_metrics bm ON cb.metric_id = bm.metric_id
            WHERE cb.company_id = p_company_id
            AND cb.peer_group_id = p_peer_group_id
            AND cb.period_id = p_period_id
            AND cb.performance_flag = 'Needs Improvement'
            ORDER BY cb.percentile_rank ASC
            LIMIT 5
        )
    );

    RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- comparative benchmark index
CREATE INDEX idx_benchmark_data_group ON benchmark_data(peer_group_id, metric_id);
CREATE INDEX idx_company_benchmarks_composite ON company_benchmarks(company_id, peer_group_id, period_id);
CREATE INDEX idx_company_benchmarks_performance ON company_benchmarks(performance_flag, percentile_rank);
CREATE INDEX idx_benchmark_insights_benchmark ON benchmark_insights(benchmark_id, insight_type);
CREATE INDEX idx_benchmark_snapshots_company ON benchmarking_snapshots(company_id, snapshot_date);


--compliance calendar feature with smart alert features
-- a unified calendar showing all upcoming tax, audit and regulatory deadlines
-- Add Compliance Calendar tables to the enterprise_cpa schema

-- Compliance Event Types
CREATE TABLE compliance_event_types (
    event_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Tax', 'Audit', 'Regulatory', 'Legal', 'Corporate', 'Environmental')),
    default_priority INTEGER CHECK (default_priority BETWEEN 1 AND 3), -- 1=High, 3=Low
    default_reminder_days INTEGER[] DEFAULT ARRAY[30, 14, 7, 3, 1], -- Days before to remind
    color_hex VARCHAR(7) DEFAULT '#3B82F6', -- Default blue
    is_recurring BOOLEAN DEFAULT TRUE,
    UNIQUE(type_name)
);

-- Jurisdictions
CREATE TABLE jurisdictions (
    jurisdiction_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    region VARCHAR(100),
    authority_name VARCHAR(100) NOT NULL,
    authority_website VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(country_code, region, authority_name)
);

-- Compliance Events
CREATE TABLE compliance_events (
    event_id SERIAL PRIMARY KEY,
    event_type_id INTEGER REFERENCES compliance_event_types(event_type_id),
    jurisdiction_id INTEGER REFERENCES jurisdictions(jurisdiction_id),
    event_name VARCHAR(100) NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    start_date DATE,
    completion_date DATE,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled', 'Deferred')),
    priority INTEGER CHECK (priority BETWEEN 1 AND 3),
    recurrence_pattern VARCHAR(100), -- e.g., 'FREQ=YEARLY;INTERVAL=1'
    parent_event_id INTEGER REFERENCES compliance_events(event_id), -- For recurring series
    external_id VARCHAR(100), -- For sync with external calendars
    UNIQUE(event_type_id, jurisdiction_id, event_name, due_date)
);

-- Responsible Parties
CREATE TABLE event_responsible_parties (
    responsibility_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES compliance_events(event_id),
    user_id VARCHAR(50) NOT NULL, -- References user management system
    role VARCHAR(50) CHECK (role IN ('Owner', 'Reviewer', 'Contributor', 'Approver')),
    UNIQUE(event_id, user_id, role)
);

-- Compliance Documents
CREATE TABLE compliance_documents (
    doc_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES compliance_events(event_id),
    document_name VARCHAR(100) NOT NULL,
    document_type VARCHAR(50),
    storage_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'Draft' CHECK (status IN ('Draft', 'Submitted', 'Approved', 'Rejected')),
    UNIQUE(event_id, document_name)
);

-- Alert Rules
CREATE TABLE alert_rules (
    rule_id SERIAL PRIMARY KEY,
    event_type_id INTEGER REFERENCES compliance_event_types(event_type_id),
    rule_name VARCHAR(100) NOT NULL,
    notify_days_before INTEGER NOT NULL, -- Days before event to notify
    notification_channels VARCHAR(50)[] DEFAULT ARRAY['email', 'slack', 'in_app']::VARCHAR(50)[],
    message_template TEXT,
    escalation_path JSONB, -- {levels: [{after_hours: 24, notify: [user_ids]}]}
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(event_type_id, rule_name, notify_days_before)
);

-- Alert History
CREATE TABLE alert_history (
    alert_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES compliance_events(event_id),
    rule_id INTEGER REFERENCES alert_rules(rule_id),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_to JSONB NOT NULL, -- {user_id: text, email: text, name: text}
    channel VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'Sent' CHECK (status IN ('Sent', 'Delivered', 'Opened', 'Failed')),
    opened_at TIMESTAMP,
    UNIQUE(event_id, rule_id, sent_to->>'user_id')
);

-- Calendar Integrations
CREATE TABLE calendar_integrations (
    integration_id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    integration_type VARCHAR(50) CHECK (integration_type IN ('Outlook', 'Google', 'iCal', 'Slack')),
    external_calendar_id VARCHAR(100),
    last_sync TIMESTAMP,
    sync_status VARCHAR(20) CHECK (sync_status IN ('Active', 'Paused', 'Failed')),
    UNIQUE(user_id, integration_type)
);

-- Views for Compliance Calendar

-- Upcoming Compliance Events View
CREATE VIEW upcoming_compliance_events AS
SELECT
    ce.event_id,
    ce.event_name,
    cet.type_name,
    cet.category,
    j.country_code,
    j.region,
    j.authority_name,
    ce.due_date,
    (ce.due_date - CURRENT_DATE) AS days_remaining,
    ce.priority,
    ce.status,
    STRING_AGG(DISTINCT erp.user_id, ', ') AS responsible_parties,
    COUNT(DISTINCT cd.doc_id) FILTER (WHERE cd.is_required AND cd.status != 'Submitted') AS pending_docs,
    ARRAY(
        SELECT ar.notify_days_before
        FROM alert_rules ar
        WHERE ar.event_type_id = ce.event_type_id
        AND ar.is_active = TRUE
        AND (ce.due_date - CURRENT_DATE) <= ar.notify_days_before
        AND NOT EXISTS (
            SELECT 1 FROM alert_history ah
            WHERE ah.event_id = ce.event_id
            AND ah.rule_id = ar.rule_id
        )
    ) AS pending_alerts
FROM compliance_events ce
JOIN compliance_event_types cet ON ce.event_type_id = cet.event_type_id
JOIN jurisdictions j ON ce.jurisdiction_id = j.jurisdiction_id
LEFT JOIN event_responsible_parties erp ON ce.event_id = erp.event_id
LEFT JOIN compliance_documents cd ON ce.event_id = cd.event_id
WHERE ce.status IN ('Pending', 'In Progress')
AND ce.due_date >= CURRENT_DATE
GROUP BY ce.event_id, ce.event_name, cet.type_name, cet.category,
         j.country_code, j.region, j.authority_name, ce.due_date,
         ce.priority, ce.status;

-- Overdue Compliance Items View
CREATE VIEW overdue_compliance_items AS
SELECT
    ce.event_id,
    ce.event_name,
    cet.type_name,
    cet.category,
    j.authority_name,
    ce.due_date,
    (CURRENT_DATE - ce.due_date) AS days_overdue,
    ce.priority,
    STRING_AGG(DISTINCT erp.user_id, ', ') AS responsible_parties,
    COUNT(DISTINCT ah.alert_id) FILTER (WHERE ah.sent_at > ce.due_date) AS overdue_alerts_sent
FROM compliance_events ce
JOIN compliance_event_types cet ON ce.event_type_id = cet.event_type_id
JOIN jurisdictions j ON ce.jurisdiction_id = j.jurisdiction_id
LEFT JOIN event_responsible_parties erp ON ce.event_id = erp.event_id
LEFT JOIN alert_history ah ON ce.event_id = ah.event_id
WHERE ce.status IN ('Pending', 'In Progress')
AND ce.due_date < CURRENT_DATE
GROUP BY ce.event_id, ce.event_name, cet.type_name, cet.category,
         j.authority_name, ce.due_date, ce.priority;

-- User Compliance Calendar View
CREATE VIEW user_compliance_calendar AS
SELECT
    erp.user_id,
    ce.event_id,
    ce.event_name,
    cet.type_name,
    cet.category,
    ce.due_date,
    (ce.due_date - CURRENT_DATE) AS days_remaining,
    ce.priority,
    ce.status,
    j.authority_name,
    COUNT(DISTINCT cd.doc_id) FILTER (WHERE cd.is_required AND cd.status != 'Submitted') AS pending_docs,
    EXISTS (
        SELECT 1 FROM alert_history ah
        JOIN alert_rules ar ON ah.rule_id = ar.rule_id
        WHERE ah.event_id = ce.event_id
        AND ah.sent_to->>'user_id' = erp.user_id
        AND ar.notify_days_before = 1
    ) AS final_alert_sent
FROM event_responsible_parties erp
JOIN compliance_events ce ON erp.event_id = ce.event_id
JOIN compliance_event_types cet ON ce.event_type_id = cet.event_type_id
JOIN jurisdictions j ON ce.jurisdiction_id = j.jurisdiction_id
LEFT JOIN compliance_documents cd ON ce.event_id = cd.event_id
WHERE ce.status IN ('Pending', 'In Progress')
GROUP BY erp.user_id, ce.event_id, ce.event_name, cet.type_name, cet.category,
         ce.due_date, ce.priority, ce.status, j.authority_name;

-- Alert Readiness View
CREATE VIEW alert_readiness_view AS
SELECT
    ce.event_id,
    ce.event_name,
    cet.type_name,
    ar.rule_id,
    ar.rule_name,
    ar.notify_days_before,
    (ce.due_date - CURRENT_DATE) AS days_until_due,
    (ce.due_date - CURRENT_DATE) <= ar.notify_days_before AS should_trigger,
    EXISTS (
        SELECT 1 FROM alert_history ah
        WHERE ah.event_id = ce.event_id
        AND ah.rule_id = ar.rule_id
    ) AS already_sent,
    ARRAY(
        SELECT erp.user_id
        FROM event_responsible_parties erp
        WHERE erp.event_id = ce.event_id
    ) AS recipients
FROM compliance_events ce
JOIN compliance_event_types cet ON ce.event_type_id = cet.event_type_id
JOIN alert_rules ar ON cet.event_type_id = ar.event_type_id
WHERE ce.status IN ('Pending', 'In Progress')
AND ar.is_active = TRUE;

-- Stored Procedures for Compliance Calendar

-- Schedule Compliance Event
CREATE OR REPLACE FUNCTION schedule_compliance_event(
    p_event_type_id INTEGER,
    p_jurisdiction_id INTEGER,
    p_event_name VARCHAR,
    p_due_date DATE,
    p_start_date DATE DEFAULT NULL,
    p_priority INTEGER DEFAULT NULL,
    p_recurrence_pattern VARCHAR DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_event_id INTEGER;
    v_default_priority INTEGER;
BEGIN
    -- Get default priority if not provided
    IF p_priority IS NULL THEN
        SELECT default_priority INTO v_default_priority
        FROM compliance_event_types
        WHERE event_type_id = p_event_type_id;
    ELSE
        v_default_priority := p_priority;
    END IF;

    -- Create the event
    INSERT INTO compliance_events (
        event_type_id, jurisdiction_id, event_name,
        description, due_date, start_date,
        priority, recurrence_pattern
    )
    VALUES (
        p_event_type_id, p_jurisdiction_id, p_event_name,
        p_description, p_due_date, p_start_date,
        v_default_priority, p_recurrence_pattern
    )
    RETURNING event_id INTO v_event_id;

    -- If recurring, create future instances
    IF p_recurrence_pattern IS NOT NULL THEN
        PERFORM generate_recurring_events(v_event_id);
    END IF;

    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Generate Recurring Events
CREATE OR REPLACE FUNCTION generate_recurring_events(
    p_parent_event_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_parent RECORD;
    v_next_date DATE;
    v_event_id INTEGER;
    v_count INTEGER := 0;
    v_recurrence RECORD;
BEGIN
    -- Get parent event details
    SELECT * INTO v_parent
    FROM compliance_events
    WHERE event_id = p_parent_event_id;

    -- Parse recurrence pattern (simplified example)
    -- In production, use a proper recurrence parser like RFC 5545
    IF v_parent.recurrence_pattern LIKE 'FREQ=YEARLY%' THEN
        v_next_date := v_parent.due_date + INTERVAL '1 year';

        -- Create next instance
        INSERT INTO compliance_events (
            event_type_id, jurisdiction_id, event_name,
            description, due_date, start_date,
            priority, recurrence_pattern, parent_event_id
        )
        VALUES (
            v_parent.event_type_id, v_parent.jurisdiction_id, v_parent.event_name,
            v_parent.description, v_next_date,
            CASE WHEN v_parent.start_date IS NOT NULL
                 THEN v_parent.start_date + INTERVAL '1 year'
                 ELSE NULL END,
            v_parent.priority, v_parent.recurrence_pattern, p_parent_event_id
        )
        RETURNING event_id INTO v_event_id;

        v_count := v_count + 1;
    END IF;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Process Due Alerts
CREATE OR REPLACE FUNCTION process_due_alerts() RETURNS INTEGER AS $$
DECLARE
    v_alert_count INTEGER := 0;
    v_alert RECORD;
    v_message TEXT;
    v_channels VARCHAR(50)[];
    v_user RECORD;
BEGIN
    -- Get all alerts that should be triggered
    FOR v_alert IN
        SELECT
            ar.rule_id,
            ar.notify_days_before,
            ar.notification_channels,
            ar.message_template,
            ce.event_id,
            ce.event_name,
            ce.due_date,
            cet.type_name,
            cet.category,
            j.authority_name,
            ARRAY(
                SELECT erp.user_id
                FROM event_responsible_parties erp
                WHERE erp.event_id = ce.event_id
            ) AS recipients
        FROM alert_rules ar
        JOIN compliance_event_types cet ON ar.event_type_id = cet.event_type_id
        JOIN compliance_events ce ON cet.event_type_id = ce.event_type_id
        JOIN jurisdictions j ON ce.jurisdiction_id = j.jurisdiction_id
        WHERE ar.is_active = TRUE
        AND ce.status IN ('Pending', 'In Progress')
        AND (ce.due_date - CURRENT_DATE) <= ar.notify_days_before
        AND NOT EXISTS (
            SELECT 1 FROM alert_history ah
            WHERE ah.event_id = ce.event_id
            AND ah.rule_id = ar.rule_id
        )
    LOOP
        -- Process each recipient
        FOREACH v_user.user_id IN ARRAY v_alert.recipients
        LOOP
            -- Get user details (in production, would come from user service)
            -- For this example, we'll simulate user data
            v_user.email := v_user.user_id || '@company.com';
            v_user.name := 'User ' || v_user.user_id;

            -- Build message from template
            v_message := REPLACE(v_alert.message_template, '{event_name}', v_alert.event_name);
            v_message := REPLACE(v_message, '{due_date}', v_alert.due_date::TEXT);
            v_message := REPLACE(v_message, '{days_remaining}', (v_alert.due_date - CURRENT_DATE)::TEXT);
            v_message := REPLACE(v_message, '{authority}', v_alert.authority_name);

            -- Send to all configured channels
            FOREACH v_channels IN ARRAY v_alert.notification_channels
            LOOP
                -- In production, this would call actual notification services
                -- For this example, we'll just log the alerts
                INSERT INTO alert_history (
                    event_id, rule_id, sent_to, channel, message
                )
                VALUES (
                    v_alert.event_id, v_alert.rule_id,
                    jsonb_build_object(
                        'user_id', v_user.user_id,
                        'email', v_user.email,
                        'name', v_user.name
                    ),
                    v_channels, v_message
                );

                v_alert_count := v_alert_count + 1;
            END LOOP;
        END LOOP;
    END LOOP;

    RETURN v_alert_count;
END;
$$ LANGUAGE plpgsql;

-- Sync Calendar with External Service
CREATE OR REPLACE FUNCTION sync_calendar_with_external(
    p_integration_id INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_integration RECORD;
    v_event RECORD;
    v_sync_count INTEGER := 0;
    v_external_id VARCHAR;
BEGIN
    -- Get integration details
    SELECT * INTO v_integration
    FROM calendar_integrations
    WHERE integration_id = p_integration_id;

    -- Only sync active integrations
    IF v_integration.sync_status != 'Active' THEN
        RETURN 0;
    END IF;

    -- Get events that need to be synced
    FOR v_event IN
        SELECT ce.*, cet.type_name, j.authority_name
        FROM compliance_events ce
        JOIN compliance_event_types cet ON ce.event_type_id = cet.event_type_id
        JOIN jurisdictions j ON ce.jurisdiction_id = j.jurisdiction_id
        WHERE (ce.external_id IS NULL OR ce.external_id NOT LIKE v_integration.integration_type || '%')
        AND ce.due_date >= CURRENT_DATE - INTERVAL '1 month'
        AND ce.due_date <= CURRENT_DATE + INTERVAL '1 year'
    LOOP
        -- Generate unique external ID
        v_external_id := v_integration.integration_type || '-' || v_event.event_id;

        -- In production, this would call the actual calendar API
        -- For this example, we'll simulate the sync
        BEGIN
            -- Simulate API call
            PERFORM pg_sleep(0.1);

            -- Update event with external ID
            UPDATE compliance_events
            SET external_id = v_external_id
            WHERE event_id = v_event.event_id;

            v_sync_count := v_sync_count + 1;
        EXCEPTION WHEN OTHERS THEN
            -- Log failure but continue with next event
            RAISE NOTICE 'Failed to sync event %: %', v_event.event_id, SQLERRM;
        END;
    END LOOP;

    -- Update integration status
    UPDATE calendar_integrations
    SET last_sync = CURRENT_TIMESTAMP
    WHERE integration_id = p_integration_id;

    RETURN v_sync_count;
END;
$$ LANGUAGE plpgsql;

--compliance calender indexes
CREATE INDEX idx_compliance_events_dates ON compliance_events(due_date, status);
CREATE INDEX idx_compliance_events_type ON compliance_events(event_type_id, jurisdiction_id);
CREATE INDEX idx_alert_rules_event_type ON alert_rules(event_type_id);
CREATE INDEX idx_alert_history_event ON alert_history(event_id, sent_at);
CREATE INDEX idx_event_responsible ON event_responsible_parties(user_id, event_id);
CREATE INDEX idx_compliance_documents_event ON compliance_documents(event_id, is_required, status);

-- Add Legal Entity Management tables to the enterprise_cpa schema

-- Legal Entities
CREATE TABLE legal_entities (
    entity_id SERIAL PRIMARY KEY,
    legal_name VARCHAR(200) NOT NULL,
    trading_name VARCHAR(200),
    entity_type VARCHAR(50) CHECK (entity_type IN ('Company', 'LLC', 'Partnership', 'Trust', 'SPV', 'Branch')),
    jurisdiction VARCHAR(100) NOT NULL,
    registration_number VARCHAR(50) NOT NULL,
    incorporation_date DATE,
    tax_id VARCHAR(50),
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Dormant', 'In Liquidation', 'Dissolved')),
    is_public BOOLEAN DEFAULT FALSE,
    fiscal_year_end VARCHAR(5) CHECK (fiscal_year_end ~ '^(0[1-9]|1[0-2])-[0-3][0-9]$'), -- MM-DD format
    legal_address JSONB,
    UNIQUE(jurisdiction, registration_number)
);

-- Entity Ownership
CREATE TABLE entity_ownership (
    ownership_id SERIAL PRIMARY KEY,
    parent_entity_id INTEGER REFERENCES legal_entities(entity_id),
    owned_entity_id INTEGER REFERENCES legal_entities(entity_id),
    ownership_type VARCHAR(50) CHECK (ownership_type IN ('Direct', 'Indirect', 'Beneficial')),
    ownership_percentage NUMERIC(5,2) CHECK (ownership_percentage BETWEEN 0 AND 100),
    effective_from DATE NOT NULL,
    effective_to DATE,
    voting_rights_percentage NUMERIC(5,2),
    is_ultimate_beneficial_owner BOOLEAN DEFAULT FALSE,
    UNIQUE(parent_entity_id, owned_entity_id, effective_from)
);

-- Individual Stakeholders
CREATE TABLE individuals (
    individual_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    nationality VARCHAR(100),
    tax_id VARCHAR(50),
    is_pep BOOLEAN DEFAULT FALSE, -- Politically Exposed Person
    UNIQUE(first_name, last_name, date_of_birth)
);

-- Individual Roles
CREATE TABLE individual_roles (
    role_id SERIAL PRIMARY KEY,
    individual_id INTEGER REFERENCES individuals(individual_id),
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    role_type VARCHAR(50) CHECK (role_type IN ('Director', 'Shareholder', 'Secretary', 'Trustee', 'Beneficial Owner', 'Signatory')),
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_current BOOLEAN GENERATED ALWAYS AS (
        CASE WHEN effective_to IS NULL OR effective_to >= CURRENT_DATE THEN TRUE
        ELSE FALSE END
    ) STORED,
    UNIQUE(individual_id, entity_id, role_type, effective_from)
);

-- Board Members
CREATE TABLE board_members (
    board_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    individual_id INTEGER REFERENCES individuals(individual_id),
    position VARCHAR(100) NOT NULL, -- CEO, CFO, etc.
    is_chairperson BOOLEAN DEFAULT FALSE,
    start_date DATE NOT NULL,
    end_date DATE,
    term_length_months INTEGER,
    UNIQUE(entity_id, individual_id, position, start_date)
);

-- Statutory Registers
CREATE TABLE statutory_registers (
    register_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    register_type VARCHAR(50) CHECK (register_type IN ('Directors', 'Members', 'Secretaries', 'Charges', 'Beneficial Owners')),
    current_version INTEGER NOT NULL,
    last_updated DATE,
    last_updated_by VARCHAR(100),
    storage_location VARCHAR(255),
    is_compliant BOOLEAN DEFAULT TRUE,
    UNIQUE(entity_id, register_type)
);

-- Corporate Documents
CREATE TABLE corporate_documents (
    document_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    document_type VARCHAR(50) CHECK (document_type IN ('Memorandum', 'Articles', 'Bylaws', 'Resolution', 'Minutes', 'Certificate')),
    document_name VARCHAR(200) NOT NULL,
    effective_date DATE NOT NULL,
    expiration_date DATE,
    storage_url VARCHAR(255) NOT NULL,
    is_template BOOLEAN DEFAULT FALSE,
    template_id INTEGER REFERENCES corporate_documents(document_id),
    approved_by VARCHAR(100),
    approved_date DATE,
    UNIQUE(entity_id, document_type, effective_date)
);

-- Compliance Requirements
CREATE TABLE compliance_requirements (
    requirement_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    jurisdiction_id INTEGER REFERENCES jurisdictions(jurisdiction_id),
    requirement_name VARCHAR(200) NOT NULL,
    requirement_type VARCHAR(50) CHECK (requirement_type IN ('Filing', 'Report', 'License', 'Tax', 'Meeting')),
    frequency VARCHAR(20) CHECK (frequency IN ('Annual', 'Quarterly', 'Monthly', 'Biennial', 'One-time')),
    due_date DATE,
    deadline_rule VARCHAR(100), -- e.g., "90 days after fiscal year end"
    is_critical BOOLEAN DEFAULT TRUE,
    penalty_description TEXT,
    UNIQUE(entity_id, jurisdiction_id, requirement_name, due_date)
);

-- Compliance Activities
CREATE TABLE compliance_activities (
    activity_id SERIAL PRIMARY KEY,
    requirement_id INTEGER REFERENCES compliance_requirements(requirement_id),
    due_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Late', 'Waived')),
    responsible_party VARCHAR(100),
    notes TEXT,
    document_id INTEGER REFERENCES corporate_documents(document_id),
    UNIQUE(requirement_id, due_date)
);

-- Document Templates
CREATE TABLE document_templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(200) NOT NULL,
    template_type VARCHAR(50) CHECK (template_type IN ('Minutes', 'Resolution', 'Report', 'Certificate')),
    jurisdiction VARCHAR(100),
    entity_type VARCHAR(50),
    template_content TEXT NOT NULL,
    variables JSONB, -- Placeholders for dynamic content
    version VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(template_name, jurisdiction, entity_type, version)
);

-- Entity Changes (Audit Log)
CREATE TABLE entity_changes (
    change_id SERIAL PRIMARY KEY,
    entity_id INTEGER REFERENCES legal_entities(entity_id),
    change_type VARCHAR(50) NOT NULL,
    change_description TEXT NOT NULL,
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    previous_value JSONB,
    new_value JSONB,
    approval_status VARCHAR(20) DEFAULT 'Approved' CHECK (approval_status IN ('Pending', 'Approved', 'Rejected'))
);

-- Views for Legal Entity Management Portal

-- Entity Structure View
CREATE VIEW entity_structure_view AS
WITH RECURSIVE entity_hierarchy AS (
    -- Base case: top-level entities (those not owned by others)
    SELECT
        e.entity_id,
        e.legal_name,
        e.entity_type,
        e.jurisdiction,
        0 AS level,
        ARRAY[e.entity_id] AS path,
        ARRAY[e.legal_name] AS name_path
    FROM legal_entities e
    WHERE NOT EXISTS (
        SELECT 1 FROM entity_ownership o
        WHERE o.owned_entity_id = e.entity_id
        AND (o.effective_to IS NULL OR o.effective_to >= CURRENT_DATE)
    )

    UNION ALL

    -- Recursive case: child entities
    SELECT
        e.entity_id,
        e.legal_name,
        e.entity_type,
        e.jurisdiction,
        h.level + 1,
        h.path || e.entity_id,
        h.name_path || e.legal_name
    FROM legal_entities e
    JOIN entity_ownership o ON e.entity_id = o.owned_entity_id
    JOIN entity_hierarchy h ON o.parent_entity_id = h.entity_id
    WHERE o.effective_to IS NULL OR o.effective_to >= CURRENT_DATE
)
SELECT
    entity_id,
    legal_name,
    entity_type,
    jurisdiction,
    level,
    path,
    name_path,
    (SELECT COUNT(*) FROM entity_ownership o
     WHERE o.parent_entity_id = h.entity_id
     AND (o.effective_to IS NULL OR o.effective_to >= CURRENT_DATE)) AS child_count
FROM entity_hierarchy h
ORDER BY path;

-- Compliance Calendar View
CREATE VIEW compliance_calendar_view AS
SELECT
    e.entity_id,
    e.legal_name,
    cr.requirement_id,
    cr.requirement_name,
    cr.requirement_type,
    ca.activity_id,
    ca.due_date,
    (ca.due_date - CURRENT_DATE) AS days_remaining,
    ca.status,
    ca.responsible_party,
    j.country_code,
    j.region,
    j.authority_name,
    CASE
        WHEN ca.due_date < CURRENT_DATE AND ca.status != 'Completed' THEN 'Overdue'
        WHEN (ca.due_date - CURRENT_DATE) <= 30 AND ca.status != 'Completed' THEN 'Due Soon'
        ELSE 'Upcoming'
    END AS urgency
FROM compliance_requirements cr
JOIN compliance_activities ca ON cr.requirement_id = ca.requirement_id
JOIN legal_entities e ON cr.entity_id = e.entity_id
JOIN jurisdictions j ON cr.jurisdiction_id = j.jurisdiction_id
WHERE ca.status != 'Completed' OR ca.completion_date >= CURRENT_DATE - INTERVAL '1 month'
ORDER BY ca.due_date;

-- Document Status View
CREATE VIEW document_status_view AS
SELECT
    e.entity_id,
    e.legal_name,
    cd.document_id,
    cd.document_type,
    cd.document_name,
    cd.effective_date,
    cd.expiration_date,
    CASE
        WHEN cd.expiration_date IS NULL THEN 'Valid'
        WHEN cd.expiration_date < CURRENT_DATE THEN 'Expired'
        ELSE 'Valid'
    END AS status,
    (SELECT COUNT(*) FROM corporate_documents
     WHERE entity_id = e.entity_id
     AND document_type = cd.document_type
     AND effective_date > cd.effective_date) AS newer_versions
FROM corporate_documents cd
JOIN legal_entities e ON cd.entity_id = e.entity_id
ORDER BY e.legal_name, cd.document_type, cd.effective_date DESC;

-- Ultimate Beneficial Owners View
CREATE VIEW ubo_view AS
WITH RECURSIVE ownership_trace AS (
    -- Base case: direct ownership by individuals
    SELECT
        e.entity_id,
        e.legal_name,
        i.individual_id,
        i.first_name,
        i.last_name,
        ir.ownership_percentage,
        1 AS level,
        ARRAY[e.entity_id] AS entity_path
    FROM legal_entities e
    JOIN individual_roles ir ON e.entity_id = ir.entity_id
    JOIN individuals i ON ir.individual_id = i.individual_id
    WHERE ir.role_type = 'Shareholder'
    AND ir.is_current = TRUE

    UNION ALL

    -- Recursive case: entity ownership chains
    SELECT
        ot.entity_id,
        ot.legal_name,
        i.individual_id,
        i.first_name,
        i.last_name,
        ot.ownership_percentage * eo.ownership_percentage / 100 AS ownership_percentage,
        ot.level + 1,
        ot.entity_path || eo.owned_entity_id
    FROM ownership_trace ot
    JOIN entity_ownership eo ON ot.individual_id IS NULL AND ot.entity_id = eo.owned_entity_id
    JOIN legal_entities e ON eo.parent_entity_id = e.entity_id
    LEFT JOIN individual_roles ir ON e.entity_id = ir.entity_id AND ir.role_type = 'Shareholder' AND ir.is_current = TRUE
    LEFT JOIN individuals i ON ir.individual_id = i.individual_id
    WHERE NOT eo.owned_entity_id = ANY(ot.entity_path) -- Prevent cycles
    AND eo.effective_to IS NULL OR eo.effective_to >= CURRENT_DATE
)
SELECT DISTINCT ON (entity_id, individual_id)
    entity_id,
    legal_name,
    individual_id,
    first_name,
    last_name,
    ownership_percentage,
    level
FROM ownership_trace
WHERE individual_id IS NOT NULL
AND ownership_percentage >= 10 -- Typically UBO threshold
ORDER BY entity_id, individual_id, level DESC;

-- Stored Procedures for Legal Entity Management Portal

-- Generate Corporate Document
CREATE OR REPLACE FUNCTION generate_corporate_document(
    p_entity_id INTEGER,
    p_document_type VARCHAR,
    p_template_id INTEGER,
    p_variables JSONB,
    p_effective_date DATE,
    p_approved_by VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_document_id INTEGER;
    v_template_content TEXT;
    v_document_content TEXT;
    v_entity RECORD;
    v_document_name VARCHAR;
    v_version INTEGER;
BEGIN
    -- Get template content
    SELECT template_content INTO v_template_content
    FROM document_templates
    WHERE template_id = p_template_id;

    -- Get entity details
    SELECT legal_name, entity_type, jurisdiction INTO v_entity
    FROM legal_entities
    WHERE entity_id = p_entity_id;

    -- Generate document name
    v_document_name := v_entity.legal_name || ' ' ||
        INITCAP(p_document_type) || ' (' || TO_CHAR(p_effective_date, 'YYYY-MM-DD') || ')';

    -- Get next version number
    SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
    FROM corporate_documents
    WHERE entity_id = p_entity_id
    AND document_type = p_document_type;

    -- Replace template variables (simplified example)
    v_document_content := v_template_content;
    v_document_content := REPLACE(v_document_content, '{entity_name}', v_entity.legal_name);
    v_document_content := REPLACE(v_document_content, '{effective_date}', TO_CHAR(p_effective_date, 'YYYY-MM-DD'));

    -- In production, would replace all variables from p_variables

    -- Create document record (storage_url would be generated in production)
    INSERT INTO corporate_documents (
        entity_id, document_type, document_name,
        effective_date, storage_url, approved_by,
        approved_date
    )
    VALUES (
        p_entity_id, p_document_type, v_document_name,
        p_effective_date, '/documents/' || p_entity_id || '/' ||
        LOWER(REPLACE(p_document_type, ' ', '_')) || '_' ||
        TO_CHAR(p_effective_date, 'YYYYMMDD') || '.docx',
        p_approved_by, CURRENT_DATE
    )
    RETURNING document_id INTO v_document_id;

    RETURN v_document_id;
END;
$$ LANGUAGE plpgsql;

-- Calculate Compliance Due Dates
CREATE OR REPLACE FUNCTION calculate_compliance_due_dates(
    p_entity_id INTEGER,
    p_year INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_requirement RECORD;
    v_due_date DATE;
    v_count INTEGER := 0;
    v_fiscal_year_end DATE;
BEGIN
    -- Get fiscal year end for the entity
    SELECT TO_DATE(TO_CHAR(p_year) || '-' || fiscal_year_end, 'YYYY-MM-DD') INTO v_fiscal_year_end
    FROM legal_entities
    WHERE entity_id = p_entity_id;

    -- Process each requirement
    FOR v_requirement IN
        SELECT * FROM compliance_requirements
        WHERE entity_id = p_entity_id
        AND (requirement_type != 'One-time' OR
             (due_date IS NULL OR EXTRACT(YEAR FROM due_date) = p_year))
    LOOP
        -- Calculate due date based on deadline rule
        IF v_requirement.deadline_rule IS NOT NULL THEN
            -- Simple rule parsing (in production would use more sophisticated logic)
            IF v_requirement.deadline_rule LIKE '%fiscal year end%' THEN
                v_due_date := v_fiscal_year_end +
                    CAST(SUBSTRING(v_requirement.deadline_rule FROM '[0-9]+') AS INTEGER) * INTERVAL '1 day';
            ELSIF v_requirement.deadline_rule LIKE '%calendar year end%' THEN
                v_due_date := TO_DATE(TO_CHAR(p_year) || '-12-31', 'YYYY-MM-DD') +
                    CAST(SUBSTRING(v_requirement.deadline_rule FROM '[0-9]+') AS INTEGER) * INTERVAL '1 day';
            ELSE
                -- Default to existing due date or fiscal year end
                v_due_date := COALESCE(v_requirement.due_date, v_fiscal_year_end);
            END IF;
        ELSE
            v_due_date := v_requirement.due_date;
        END IF;

        -- Create or update compliance activity
        INSERT INTO compliance_activities (
            requirement_id, due_date, responsible_party
        )
        VALUES (
            v_requirement.requirement_id, v_due_date, v_requirement.responsible_party
        )
        ON CONFLICT (requirement_id, due_date)
        DO UPDATE SET
            responsible_party = EXCLUDED.responsible_party,
            status = CASE WHEN compliance_activities.status = 'Completed' THEN 'Completed'
                          ELSE EXCLUDED.status END;

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Update Entity Structure
CREATE OR REPLACE FUNCTION update_entity_ownership(
    p_parent_entity_id INTEGER,
    p_owned_entity_id INTEGER,
    p_ownership_percentage NUMERIC,
    p_effective_from DATE,
    p_effective_to DATE DEFAULT NULL,
    p_ownership_type VARCHAR DEFAULT 'Direct',
    p_voting_rights_percentage NUMERIC DEFAULT NULL,
    p_is_ubo BOOLEAN DEFAULT FALSE,
    p_updated_by VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_ownership_id INTEGER;
    v_change_description TEXT;
BEGIN
    -- Close any existing overlapping ownership records
    UPDATE entity_ownership
    SET effective_to = p_effective_from - INTERVAL '1 day'
    WHERE owned_entity_id = p_owned_entity_id
    AND parent_entity_id = p_parent_entity_id
    AND (effective_to IS NULL OR effective_to >= p_effective_from);

    -- Create new ownership record
    INSERT INTO entity_ownership (
        parent_entity_id, owned_entity_id, ownership_type,
        ownership_percentage, effective_from, effective_to,
        voting_rights_percentage, is_ultimate_beneficial_owner
    )
    VALUES (
        p_parent_entity_id, p_owned_entity_id, p_ownership_type,
        p_ownership_percentage, p_effective_from, p_effective_to,
        p_voting_rights_percentage, p_is_ubo
    )
    RETURNING ownership_id INTO v_ownership_id;

    -- Log the change
    v_change_description := 'Ownership of ' ||
        (SELECT legal_name FROM legal_entities WHERE entity_id = p_owned_entity_id) ||
        ' by ' || (SELECT legal_name FROM legal_entities WHERE entity_id = p_parent_entity_id) ||
        ' set to ' || p_ownership_percentage || '%';

    INSERT INTO entity_changes (
        entity_id, change_type, change_description, changed_by
    )
    VALUES (
        p_owned_entity_id, 'Ownership', v_change_description, p_updated_by
    );

    RETURN v_ownership_id;
END;
$$ LANGUAGE plpgsql;

-- legal entity management indexes
CREATE INDEX idx_legal_entities_jurisdiction ON legal_entities(jurisdiction, status);
CREATE INDEX idx_entity_ownership_dates ON entity_ownership(effective_from, effective_to);
CREATE INDEX idx_individual_roles_current ON individual_roles(entity_id, is_current);
CREATE INDEX idx_compliance_activities_due ON compliance_activities(due_date, status);
CREATE INDEX idx_statutory_registers_entity ON statutory_registers(entity_id, register_type);
CREATE INDEX idx_corporate_documents_entity ON corporate_documents(entity_id, document_type, effective_date);

-- Add Role-Based Dashboard tables to the enterprise_cpa schema

-- Dashboard Roles
CREATE TABLE dashboard_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    UNIQUE(role_name)
);

-- Default System Roles
INSERT INTO dashboard_roles (role_name, description, is_system_role) VALUES
('CFO', 'Chief Financial Officer - Strategic financial overview', TRUE),
('Controller', 'Financial Controller - Operational metrics and compliance', TRUE),
('Treasurer', 'Treasury - Cash and liquidity management', TRUE),
('Auditor', 'Internal/External Audit - Compliance and risk monitoring', TRUE),
('Tax Director', 'Tax strategy and compliance', TRUE);

-- Dashboard Templates
CREATE TABLE dashboard_templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    description TEXT,
    default_for_role_id INTEGER REFERENCES dashboard_roles(role_id),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(template_name)
);

-- Dashboard Widgets
CREATE TABLE dashboard_widgets (
    widget_id SERIAL PRIMARY KEY,
    widget_name VARCHAR(100) NOT NULL,
    widget_type VARCHAR(50) CHECK (widget_type IN ('KPI', 'Chart', 'Table', 'Heatmap', 'Gauge', 'Trend')),
    data_source VARCHAR(100) NOT NULL, -- View or function that provides data
    default_width INTEGER CHECK (default_width BETWEEN 1 AND 4) DEFAULT 2,
    default_height INTEGER CHECK (default_height BETWEEN 1 AND 4) DEFAULT 2,
    settings JSONB, -- Configuration options for the widget
    required_permissions VARCHAR(50)[], -- Permissions needed to use this widget
    UNIQUE(widget_name)
);

-- Dashboard Layouts
CREATE TABLE dashboard_layouts (
    layout_id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES dashboard_templates(template_id),
    user_id VARCHAR(50), -- NULL means system default
    role_id INTEGER REFERENCES dashboard_roles(role_id),
    layout_name VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP,
    UNIQUE(template_id, COALESCE(user_id, ''), role_id, layout_name)
);

-- Layout Widgets
CREATE TABLE layout_widgets (
    layout_widget_id SERIAL PRIMARY KEY,
    layout_id INTEGER REFERENCES dashboard_layouts(layout_id),
    widget_id INTEGER REFERENCES dashboard_widgets(widget_id),
    x_position INTEGER NOT NULL,
    y_position INTEGER NOT NULL,
    width INTEGER CHECK (width BETWEEN 1 AND 4) DEFAULT 2,
    height INTEGER CHECK (height BETWEEN 1 AND 4) DEFAULT 2,
    settings JSONB, -- User-specific widget settings
    refresh_interval_minutes INTEGER DEFAULT 60,
    UNIQUE(layout_id, widget_id, x_position, y_position)
);

-- Scheduled Exports
CREATE TABLE dashboard_exports (
    export_id SERIAL PRIMARY KEY,
    layout_id INTEGER REFERENCES dashboard_layouts(layout_id),
    user_id VARCHAR(50) NOT NULL,
    export_format VARCHAR(20) CHECK (export_format IN ('PDF', 'Excel', 'PowerPoint', 'Image')),
    schedule VARCHAR(50) CHECK (schedule IN ('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Manual')),
    delivery_method VARCHAR(50) CHECK (delivery_method IN ('Email', 'Cloud', 'API')),
    recipients VARCHAR(50)[], -- User IDs or email addresses
    last_exported TIMESTAMP,
    next_export TIMESTAMP GENERATED ALWAYS AS (
        CASE schedule
            WHEN 'Daily' THEN COALESCE(last_exported, CURRENT_TIMESTAMP) + INTERVAL '1 day'
            WHEN 'Weekly' THEN COALESCE(last_exported, CURRENT_TIMESTAMP) + INTERVAL '1 week'
            WHEN 'Monthly' THEN COALESCE(last_exported, CURRENT_TIMESTAMP) + INTERVAL '1 month'
            WHEN 'Quarterly' THEN COALESCE(last_exported, CURRENT_TIMESTAMP) + INTERVAL '3 months'
            ELSE NULL
        END
    ) STORED,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(layout_id, user_id, schedule, delivery_method)
);

-- User Dashboard Preferences
CREATE TABLE user_dashboard_prefs (
    user_id VARCHAR(50) NOT NULL,
    role_id INTEGER REFERENCES dashboard_roles(role_id),
    current_layout_id INTEGER REFERENCES dashboard_layouts(layout_id),
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

-- Dashboard Interaction Logs
CREATE TABLE dashboard_logs (
    log_id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    layout_id INTEGER REFERENCES dashboard_layouts(layout_id),
    action VARCHAR(50) CHECK (action IN ('View', 'Export', 'Configure', 'Drilldown')),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    widget_id INTEGER REFERENCES dashboard_widgets(widget_id),
    details JSONB
);

-- Views for Role-Based Dashboards

-- CFO Dashboard View
CREATE VIEW cfo_dashboard_widgets AS
SELECT
    w.widget_id,
    w.widget_name,
    w.widget_type,
    w.data_source,
    lw.x_position,
    lw.y_position,
    lw.width,
    lw.height,
    lw.settings
FROM dashboard_widgets w
JOIN layout_widgets lw ON w.widget_id = lw.widget_id
JOIN dashboard_layouts l ON lw.layout_id = l.layout_id
JOIN dashboard_roles r ON l.role_id = r.role_id
WHERE r.role_name = 'CFO'
AND l.is_default = TRUE
ORDER BY lw.y_position, lw.x_position;

-- Controller Dashboard View
CREATE VIEW controller_dashboard_widgets AS
SELECT
    w.widget_id,
    w.widget_name,
    w.widget_type,
    w.data_source,
    lw.x_position,
    lw.y_position,
    lw.width,
    lw.height,
    lw.settings
FROM dashboard_widgets w
JOIN layout_widgets lw ON w.widget_id = lw.widget_id
JOIN dashboard_layouts l ON lw.layout_id = l.layout_id
JOIN dashboard_roles r ON l.role_id = r.role_id
WHERE r.role_name = 'Controller'
AND l.is_default = TRUE
ORDER BY lw.y_position, lw.x_position;

-- Treasurer Dashboard View
CREATE VIEW treasurer_dashboard_widgets AS
SELECT
    w.widget_id,
    w.widget_name,
    w.widget_type,
    w.data_source,
    lw.x_position,
    lw.y_position,
    lw.width,
    lw.height,
    lw.settings
FROM dashboard_widgets w
JOIN layout_widgets lw ON w.widget_id = lw.widget_id
JOIN dashboard_layouts l ON lw.layout_id = l.layout_id
JOIN dashboard_roles r ON l.role_id = r.role_id
WHERE r.role_name = 'Treasurer'
AND l.is_default = TRUE
ORDER BY lw.y_position, lw.x_position;

-- Widget Usage Analytics
CREATE VIEW widget_usage_analytics AS
SELECT
    w.widget_id,
    w.widget_name,
    w.widget_type,
    COUNT(DISTINCT dl.log_id) FILTER (WHERE dl.action = 'View') AS view_count,
    COUNT(DISTINCT dl.log_id) FILTER (WHERE dl.action = 'Drilldown') AS drilldown_count,
    COUNT(DISTINCT l.layout_id) AS layout_count,
    COUNT(DISTINCT up.user_id) AS user_count,
    MAX(dl.action_timestamp) AS last_accessed
FROM dashboard_widgets w
LEFT JOIN layout_widgets lw ON w.widget_id = lw.widget_id
LEFT JOIN dashboard_layouts l ON lw.layout_id = l.layout_id
LEFT JOIN user_dashboard_prefs up ON l.layout_id = up.current_layout_id
LEFT JOIN dashboard_logs dl ON w.widget_id = dl.widget_id
GROUP BY w.widget_id, w.widget_name, w.widget_type;

-- Stored Procedures for Role-Based Dashboards

-- Create User Dashboard
CREATE OR REPLACE FUNCTION create_user_dashboard(
    p_user_id VARCHAR,
    p_role_id INTEGER,
    p_template_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_layout_id INTEGER;
    v_template_id INTEGER;
    v_widget RECORD;
BEGIN
    -- Determine template to use
    IF p_template_id IS NULL THEN
        SELECT template_id INTO v_template_id
        FROM dashboard_templates
        WHERE default_for_role_id = p_role_id
        AND is_active = TRUE
        LIMIT 1;
    ELSE
        v_template_id := p_template_id;
    END IF;

    -- Create new layout for this user
    INSERT INTO dashboard_layouts (
        template_id, user_id, role_id, layout_name
    )
    VALUES (
        v_template_id, p_user_id, p_role_id, 'Personalized Dashboard'
    )
    RETURNING layout_id INTO v_layout_id;

    -- Copy widgets from default layout
    FOR v_widget IN
        SELECT lw.widget_id, lw.x_position, lw.y_position, lw.width, lw.height, lw.settings
        FROM layout_widgets lw
        JOIN dashboard_layouts l ON lw.layout_id = l.layout_id
        WHERE l.template_id = v_template_id
        AND l.user_id IS NULL
        AND l.role_id = p_role_id
        AND l.is_default = TRUE
    LOOP
        INSERT INTO layout_widgets (
            layout_id, widget_id, x_position, y_position,
            width, height, settings
        )
        VALUES (
            v_layout_id, v_widget.widget_id, v_widget.x_position,
            v_widget.y_position, v_widget.width, v_widget.height,
            v_widget.settings
        );
    END LOOP;

    -- Set as user's current dashboard
    INSERT INTO user_dashboard_prefs (
        user_id, role_id, current_layout_id
    )
    VALUES (
        p_user_id, p_role_id, v_layout_id
    )
    ON CONFLICT (user_id, role_id)
    DO UPDATE SET current_layout_id = v_layout_id;

    RETURN v_layout_id;
END;
$$ LANGUAGE plpgsql;

-- Export Dashboard
CREATE OR REPLACE FUNCTION export_dashboard(
    p_layout_id INTEGER,
    p_user_id VARCHAR,
    p_export_format VARCHAR,
    p_delivery_method VARCHAR,
    p_recipients VARCHAR[] DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_export_id INTEGER;
    v_content TEXT; -- In production would be bytea for binary formats
BEGIN
    -- Generate export content (simplified example)
    -- In production, this would use a proper reporting engine
    SELECT string_agg(w.widget_name || ' (' || w.widget_type || ')', ', ')
    INTO v_content
    FROM layout_widgets lw
    JOIN dashboard_widgets w ON lw.widget_id = w.widget_id
    WHERE lw.layout_id = p_layout_id;

    -- Create export record
    INSERT INTO dashboard_exports (
        layout_id, user_id, export_format,
        delivery_method, recipients, schedule,
        last_exported
    )
    VALUES (
        p_layout_id, p_user_id, p_export_format,
        p_delivery_method, p_recipients, 'Manual',
        CURRENT_TIMESTAMP
    )
    RETURNING export_id INTO v_export_id;

    -- Log the export
    INSERT INTO dashboard_logs (
        user_id, layout_id, action, widget_id,
        details
    )
    VALUES (
        p_user_id, p_layout_id, 'Export', NULL,
        jsonb_build_object(
            'format', p_export_format,
            'method', p_delivery_method,
            'content_length', COALESCE(LENGTH(v_content), 0)
        )
    );

    RETURN v_export_id;
END;
$$ LANGUAGE plpgsql;

-- Process Scheduled Exports
CREATE OR REPLACE FUNCTION process_scheduled_exports() RETURNS INTEGER AS $$
DECLARE
    v_export RECORD;
    v_count INTEGER := 0;
BEGIN
    -- Process all exports due
    FOR v_export IN
        SELECT * FROM dashboard_exports
        WHERE is_active = TRUE
        AND (schedule != 'Manual' AND next_export <= CURRENT_TIMESTAMP)
    LOOP
        -- In production, this would generate and send the actual export
        -- For this example, we'll just update the timestamp

        UPDATE dashboard_exports
        SET last_exported = CURRENT_TIMESTAMP
        WHERE export_id = v_export.export_id;

        -- Log the export
        INSERT INTO dashboard_logs (
            user_id, layout_id, action,
            details
        )
        VALUES (
            v_export.user_id, v_export.layout_id, 'Export',
            jsonb_build_object(
                'schedule', v_export.schedule,
                'method', v_export.delivery_method,
                'auto', TRUE
            )
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Update Widget Position
CREATE OR REPLACE FUNCTION update_widget_position(
    p_layout_id INTEGER,
    p_widget_id INTEGER,
    p_x_position INTEGER,
    p_y_position INTEGER,
    p_width INTEGER,
    p_height INTEGER,
    p_user_id VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_updated INTEGER;
BEGIN
    -- Update widget position
    UPDATE layout_widgets
    SET
        x_position = p_x_position,
        y_position = p_y_position,
        width = p_width,
        height = p_height,
        settings = COALESCE(settings, '{}'::jsonb) ||
            jsonb_build_object('last_modified_by', p_user_id, 'last_modified', CURRENT_TIMESTAMP)
    WHERE layout_id = p_layout_id
    AND widget_id = p_widget_id
    RETURNING layout_widget_id INTO v_updated;

    -- Update layout modified timestamp
    UPDATE dashboard_layouts
    SET last_modified = CURRENT_TIMESTAMP
    WHERE layout_id = p_layout_id;

    -- Log the change
    INSERT INTO dashboard_logs (
        user_id, layout_id, action, widget_id,
        details
    )
    VALUES (
        p_user_id, p_layout_id, 'Configure', p_widget_id,
        jsonb_build_object(
            'x', p_x_position,
            'y', p_y_position,
            'width', p_width,
            'height', p_height
        )
    );

    RETURN v_updated;
END;
$$ LANGUAGE plpgsql;

-- customizable roles dashboard indexes
CREATE INDEX idx_dashboard_layouts_role ON dashboard_layouts(role_id, user_id);
CREATE INDEX idx_layout_widgets_layout ON layout_widgets(layout_id);
CREATE INDEX idx_dashboard_exports_schedule ON dashboard_exports(next_export, is_active);
CREATE INDEX idx_dashboard_logs_user ON dashboard_logs(user_id, action_timestamp);
CREATE INDEX idx_user_dashboard_prefs ON user_dashboard_prefs(user_id, role_id);

--voice interface and natural language processing --nice to have features

CREATE TABLE voice_command_profiles (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    voice_profile_id VARCHAR(255), -- Reference to voice recognition system
    preferred_language VARCHAR(50) NOT NULL DEFAULT 'en',
    accounting_vocabulary JSONB, -- Custom vocabulary for the user
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE voice_interaction_logs (
    interaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    session_id VARCHAR(255) NOT NULL,
    raw_audio_path TEXT,
    transcript_text TEXT NOT NULL,
    intent VARCHAR(255) NOT NULL,
    confidence_score DECIMAL(5,4) NOT NULL,
    system_response TEXT,
    action_executed VARCHAR(255),
    action_result JSONB,
    device_type VARCHAR(100),
    interaction_duration_ms INTEGER,
    feedback_score INTEGER,
    feedback_comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE nlp_training_phrases (
    phrase_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
    intent VARCHAR(255) NOT NULL,
    phrase_text TEXT NOT NULL,
    parameters JSONB,
    variants TEXT[],
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance optimization

--REegulatory monitoring alert indexes
CREATE INDEX idx_regulatory_documents_jurisdiction ON regulatory_documents(jurisdiction_id, status, effective_date);
CREATE INDEX idx_compliance_requirements_document ON compliance_requirements(document_id, deadline);
CREATE INDEX idx_client_compliance_tasks_deadline ON client_compliance_tasks(client_id, current_deadline, status);
CREATE INDEX idx_document_analysis_document ON document_analysis(document_id);
CREATE INDEX idx_notification_recipients_status ON notification_recipients(status, sent_at);

-- predictive cash flow index
CREATE INDEX idx_cash_flow_history_dates ON cash_flow_history(entity_id, entry_date);
CREATE INDEX idx_forecast_details_forecast ON forecast_details(forecast_id, forecast_day);
CREATE INDEX idx_economic_indicator_values ON economic_indicator_values(indicator_id, value_date);
CREATE INDEX idx_liquidity_alerts_entity ON liquidity_alerts(entity_id, status, projected_date);


-- financial planning analysis
CREATE INDEX idx_fpa_cell_data_version ON fpa_cell_data(version_id);
CREATE INDEX idx_fpa_cell_data_members ON fpa_cell_data(time_member_id, account_member_id, entity_member_id, scenario_member_id);
CREATE INDEX idx_fpa_dimension_members_dim ON fpa_dimension_members(dimension_id);
CREATE INDEX idx_fpa_model_versions_model ON fpa_model_versions(model_id);
CREATE INDEX idx_fpa_scenarios_model ON fpa_scenarios(model_id);

--real-time consolidation indexes

CREATE INDEX idx_consolidated_balances_statement ON consolidated_balances(statement_id);
CREATE INDEX idx_intercompany_trans_period ON intercompany_transactions(period_id);
CREATE INDEX idx_consolidation_audit_period ON consolidation_audit_log(period_id);
CREATE INDEX idx_transaction_links_balance ON consolidated_transaction_links(consolidated_balance_id);


--Technology and Automation Indexes

CREATE INDEX idx_uptime_metrics_system ON system_uptime_metrics(system_id);
CREATE INDEX idx_productivity_system ON automation_productivity(system_id);
CREATE INDEX idx_error_metrics_system ON error_metrics(system_id);
CREATE INDEX idx_integration_attempts_project ON integration_attempts(integration_id);

--strategic advisory metrics

CREATE INDEX idx_synergy_metrics_transaction ON synergy_metrics(transaction_id);
CREATE INDEX idx_clv_metrics_segment ON clv_metrics(segment_id);
CREATE INDEX idx_initiative_roi_initiative ON initiative_roi(initiative_id);
CREATE INDEX idx_capital_returns_project ON capital_returns(project_id);


--ESG Metrics
CREATE INDEX idx_esg_data_points_metric_entity ON esg_data_points(metric_id, entity_id);
CREATE INDEX idx_carbon_footprint_entity_period ON carbon_footprint(entity_id, reporting_period);
CREATE INDEX idx_workforce_metrics_turnover ON workforce_metrics(entity_id, voluntary_turnover_rate);
CREATE INDEX idx_esg_goals_metric_status ON esg_goals(metric_id, status);
CREATE INDEX idx_esg_benchmarks_metric_industry ON esg_benchmarks(metric_id, industry_code);
CREATE INDEX idx_esg_disclosures_report_metric ON esg_disclosures(report_id, metric_id);


--Indexes for performacne optimization
CREATE INDEX idx_risk_assessments_tenant_entity ON risk_assessments(tenant_id, entity_id);
CREATE INDEX idx_identified_risks_assessment ON identified_risks(assessment_id);
CREATE INDEX idx_audit_findings_engagement_status ON audit_findings(engagement_id, status);
CREATE INDEX idx_risk_incidents_entity_severity ON risk_incidents(entity_id, severity);
CREATE INDEX idx_sod_violations_rule_user ON sod_violations(rule_id, user_id);
CREATE INDEX idx_risk_metric_results_entity_metric ON risk_metric_results(entity_id, metric_id);
CREATE INDEX idx_control_tests_control_result ON control_tests(control_id, test_result);

--tax metrics index
CREATE INDEX idx_tax_provisions_entity_period ON tax_provisions(entity_id, period_id);
CREATE INDEX idx_tax_filings_jurisdiction_due ON tax_filings(jurisdiction_id, due_date);
CREATE INDEX idx_deferred_tax_items_entity_type ON deferred_tax_items(entity_id, item_type);
CREATE INDEX idx_tax_risks_entity_status ON tax_risks(entity_id, status);
CREATE INDEX idx_r_d_tax_credits_entity_period ON r_d_tax_credits(entity_id, claim_period);
CREATE INDEX idx_tax_benchmarks_metric_industry ON tax_benchmarks(metric_id, industry_code);
CREATE INDEX idx_tax_alerts_entity_jurisdiction ON tax_alerts(entity_id, jurisdiction_id);

--cost metrics index
CREATE INDEX idx_cost_results_entity_period ON cost_results(entity_id, period_id);
CREATE INDEX idx_cost_results_metric ON cost_results(metric_id);
CREATE INDEX idx_product_cost_models_product ON product_cost_models(product_id);
CREATE INDEX idx_cost_variances_element_period ON cost_variances(cost_element, period_id);
CREATE INDEX idx_cost_benchmarks_metric_industry ON cost_benchmarks(metric_id, industry_code);
CREATE INDEX idx_cost_alerts_entity_metric ON cost_alerts(entity_id, metric_id);

--efficiency index
CREATE INDEX idx_efficiency_results_entity_period ON efficiency_results(entity_id, period_id);
CREATE INDEX idx_efficiency_results_metric ON efficiency_results(metric_id);
CREATE INDEX idx_inventory_analysis_entity_period ON inventory_analysis(entity_id, period_id);
CREATE INDEX idx_working_capital_efficiency_entity_period ON working_capital_efficiency(entity_id, period_id);
CREATE INDEX idx_efficiency_alerts_entity_metric ON efficiency_alerts(entity_id, metric_id);
CREATE INDEX idx_efficiency_benchmarks_metric_industry ON efficiency_benchmarks(metric_id, industry_code);

--solvency index
CREATE INDEX idx_solvency_results_entity_period ON solvency_results(entity_id, period_id);
CREATE INDEX idx_solvency_results_metric ON solvency_results(metric_id);
CREATE INDEX idx_debt_instruments_entity ON debt_instruments(entity_id);
CREATE INDEX idx_debt_service_schedule_instrument ON debt_service_schedule(instrument_id);
CREATE INDEX idx_covenant_test_results_covenant ON covenant_test_results(covenant_id);
CREATE INDEX idx_solvency_alerts_entity_metric ON solvency_alerts(entity_id, metric_id);
CREATE INDEX idx_solvency_benchmarks_metric_industry ON solvency_benchmarks(metric_id, industry_code);

--liquidity metrics
CREATE INDEX idx_liquidity_results_entity_period ON liquidity_results(entity_id, period_id);
CREATE INDEX idx_liquidity_results_metric ON liquidity_results(metric_id);
CREATE INDEX idx_cash_flow_analysis_entity_period ON cash_flow_analysis(entity_id, period_id);
CREATE INDEX idx_working_capital_snapshots_entity_date ON working_capital_snapshots(entity_id, snapshot_date);
CREATE INDEX idx_liquidity_alerts_entity_metric ON liquidity_alerts(entity_id, metric_id);
CREATE INDEX idx_cash_flow_forecast_items_forecast ON cash_flow_forecast_items(forecast_id);
CREATE INDEX idx_liquidity_benchmarks_metric_industry ON liquidity_benchmarks(metric_id, industry_code);

--profitablity metrics index
CREATE INDEX idx_profitability_results_entity_period ON profitability_results(entity_id, period_id);
CREATE INDEX idx_profitability_results_metric ON profitability_results(metric_id);
CREATE INDEX idx_profitability_benchmarks_metric_industry ON profitability_benchmarks(metric_id, industry_code);
CREATE INDEX idx_profitability_alerts_entity_metric ON profitability_alerts(entity_id, metric_id);
CREATE INDEX idx_initiative_progress_initiative_date ON initiative_progress(initiative_id, reporting_date);
CREATE INDEX idx_forecast_metric_projections_forecast ON forecast_metric_projections(forecast_id);
---
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_legal_entities_tenant ON legal_entities(tenant_id);
CREATE INDEX idx_chart_of_accounts_entity ON chart_of_accounts(entity_id);
CREATE INDEX idx_financial_statements_entity_period ON financial_statements(entity_id, period_id);
CREATE INDEX idx_regulatory_filings_entity_period ON regulatory_filings(entity_id, period_id);
CREATE INDEX idx_tax_filings_entity_period ON tax_filings(entity_id, period_id);
CREATE INDEX idx_risk_items_assessment ON risk_items(assessment_id);
CREATE INDEX idx_audit_findings_engagement ON audit_findings(engagement_id);
CREATE INDEX idx_documents_tenant_entity ON documents(tenant_id, entity_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_kpi_values_entity_period ON kpi_values(entity_id, period_id);
CREATE INDEX idx_integrations_tenant ON integrations(tenant_id);
CREATE INDEX idx_audit_logs_tenant_user ON audit_logs(tenant_id, user_id);
CREATE INDEX idx_transaction_classification_tenant_date ON transaction_classification_log(tenant_id, transaction_date);
