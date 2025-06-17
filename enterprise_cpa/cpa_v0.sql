--2025 β ORI Inc.Canada All Rights Reserved.
-- PostgreSQL Schema for All-in-One Marketing & CRM Operating System
-- Version: 1.0
-- Created: 2025-05-25
-- Author: Awase Khirni Syed, Simra Fathima Syed
-- this was built to support my daughter in her business accounting course inturn it would help my own company


--postgresql schema extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "jsonb_accessor"; -- Optional

-- 🔐 Core Identity & Access Management
CREATE TYPE user_role AS ENUM ('CLIENT', 'ACCOUNTANT', 'TAX_ADVISOR', 'AUDITOR', 'ADMIN');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    company_id UUID REFERENCES companies(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    trading_name VARCHAR(255),
    registration_number VARCHAR(100),
    country_code CHAR(2) NOT NULL,
    fiscal_year_end DATE,
    currency_code CHAR(3) DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 🏢 Organization Structure
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    name VARCHAR(100) NOT NULL,
    permissions JSONB
);

-- 📊 Financial Reporting
CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    account_number VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE')),
    parent_account_id UUID REFERENCES chart_of_accounts(id),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    account_id UUID REFERENCES chart_of_accounts(id),
    entry_date DATE NOT NULL,
    description TEXT,
    debit NUMERIC(18, 2),
    credit NUMERIC(18, 2),
    source VARCHAR(100), -- e.g., "AP", "AR", "Payroll"
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE financial_statements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    statement_type VARCHAR(50) NOT NULL CHECK (statement_type IN ('BALANCE_SHEET', 'INCOME_STATEMENT', 'CASH_FLOW')),
    period_start DATE,
    period_end DATE,
    data JSONB,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    generated_by UUID REFERENCES users(id)
);

-- 💰 Tax Compliance & Advisory
CREATE TABLE tax_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    jurisdiction VARCHAR(100),
    tax_id_number VARCHAR(100),
    registration_date DATE,
    filing_frequency VARCHAR(50) CHECK (filing_frequency IN ('MONTHLY', 'QUARTERLY', 'ANNUALLY'))
);

CREATE TABLE tax_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_profile_id UUID REFERENCES tax_profiles(id),
    period DATE NOT NULL,
    form_type VARCHAR(100),
    submission_deadline DATE,
    status VARCHAR(50) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'REVIEW', 'SUBMITTED', 'ACCEPTED')),
    submitted_at TIMESTAMPTZ,
    submitted_by UUID REFERENCES users(id),
    attachments JSONB
);

CREATE TABLE tax_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    name VARCHAR(255),
    assumptions JSONB,
    results JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 🛡️ Audit & Risk Management
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    category VARCHAR(100),
    likelihood_score INT CHECK (likelihood_score BETWEEN 1 AND 5),
    impact_score INT CHECK (impact_score BETWEEN 1 AND 5),
    risk_owner UUID REFERENCES users(id),
    mitigation_plan TEXT,
    due_date DATE,
    status VARCHAR(50) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED'))
);

CREATE TABLE audit_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    start_date DATE,
    end_date DATE,
    objectives TEXT,
    team_members UUID[],
    status VARCHAR(50) DEFAULT 'PLANNING' CHECK (status IN ('PLANNING', 'EXECUTION', 'REPORTING', 'CLOSED'))
);

-- 🧮 Payroll & HR Advisory
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    department_id UUID REFERENCES departments(id),
    job_title VARCHAR(100),
    salary NUMERIC(12, 2),
    hire_date DATE,
    termination_date DATE
);

CREATE TABLE payroll_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    cycle_date DATE NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    payslips JSONB
);

-- 💹 Treasury & Cash Flow
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    institution VARCHAR(255),
    account_number VARCHAR(100),
    currency_code CHAR(3),
    current_balance NUMERIC(18, 2)
);

CREATE TABLE cash_flow_forecasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    forecast_period DATE,
    projected_inflow NUMERIC(18, 2),
    projected_outflow NUMERIC(18, 2),
    net_cash_flow NUMERIC(18, 2),
    assumptions TEXT
);

-- 🤖 AI Insights & Automation
CREATE TABLE ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    insight_type VARCHAR(100),
    content TEXT,
    confidence_score NUMERIC(4, 2),
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    related_module VARCHAR(100)
);

CREATE TABLE smart_categorization_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    description_pattern TEXT,
    suggested_account_id UUID REFERENCES chart_of_accounts(id),
    confidence_threshold NUMERIC(4, 2)
);

-- 📣 Notifications & Alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    user_id UUID REFERENCES users(id),
    message TEXT,
    alert_type VARCHAR(100),
    severity VARCHAR(20) CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 📎 Documents & Collaboration
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    file_url TEXT,
    document_type VARCHAR(100),
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    description TEXT,
    assigned_to UUID REFERENCES users(id),
    due_date DATE,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED')),
    related_module VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 📈 Dashboards & Analytics
CREATE TABLE dashboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    layout JSONB,
    role_restriction VARCHAR(100),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    title VARCHAR(255),
    report_type VARCHAR(100),
    filters JSONB,
    schedule JSONB,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 🔄 Integrations & External Systems
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    integration_type VARCHAR(100),
    external_id VARCHAR(255),
    credentials JSONB,
    active BOOLEAN DEFAULT TRUE,
    last_synced TIMESTAMPTZ
);

-- 🕒 Audit Trail
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(255),
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
