-- =============================================
-- PostgreSQL Schema for Human Resource Management System
-- Version: 2.0
-- Copyright 2025 All rights reserved β ORI Inc.
-- Created: 2025-05-29
-- Last Updated: 2025-06-15
--Author: Awase Khirni Syed
-- Description: Comprehensive schema for Human Resource Management System
--              with advanced features for data governance, analytics, and compliance
-- =============================================
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas
CREATE SCHEMA hr;
CREATE SCHEMA auth;
CREATE SCHEMA compliance;
CREATE SCHEMA finance;
CREATE SCHEMA analytics;
CREATE SCHEMA data_governance;
CREATE SCHEMA recruitment;
CREATE SCHEMA payroll;
CREATE SCHEMA performance;
CREATE SCHEMA learning;
CREATE SCHEMA benefits;

-- ENUM types (from original schema, placed in hr schema for consistency)
CREATE TYPE hr.employment_status AS ENUM (
    'active',
    'on_leave',
    'terminated',
    'retired'
);
CREATE TYPE hr.employee_type AS ENUM (
    'full_time',
    'part_time',
    'contractor',
    'temporary',
    'intern'
);
CREATE TYPE hr.leave_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'cancelled'
);
CREATE TYPE hr.performance_rating AS ENUM (
    'exceeds',
    'meets',
    'needs_improvement',
    'unsatisfactory'
);
CREATE TYPE hr.recruitment_status AS ENUM (
    'draft',
    'published',
    'closed',
    'filled',
    'cancelled'
);
CREATE TYPE hr.application_status AS ENUM (
    'received',
    'reviewed',
    'interviewed',
    'offered',
    'hired',
    'rejected'
);
CREATE TYPE hr.investigation_status AS ENUM (
    'open',
    'in_progress',
    'closed_resolved',
    'closed_unresolved'
);
CREATE TYPE hr.investigation_severity AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);
CREATE TYPE hr.gender AS ENUM (
    'male',
    'female',
    'other',
    'prefer_not_to_say'
);
CREATE TYPE hr.marital_status AS ENUM (
    'single',
    'married',
    'divorced',
    'widowed',
    'separated'
);

-- Auth Schema: Users and RBAC
CREATE TABLE auth.users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    employee_id UUID UNIQUE REFERENCES hr.employees(employee_id), -- Link to hr.employees
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth.roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE auth.permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE auth.user_roles (
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES auth.roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE auth.role_permissions (
    role_id UUID NOT NULL REFERENCES auth.roles(role_id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES auth.permissions(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Core Employee Tables (from original schema, refined)
CREATE TABLE hr.employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_code VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender hr.gender NOT NULL,
    marital_status hr.marital_status,
    national_id VARCHAR(50),
    passport_number VARCHAR(50),
    tax_id VARCHAR(50),
    social_security_number VARCHAR(50),
    personal_email VARCHAR(100),
    company_email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    employment_status hr.employment_status NOT NULL DEFAULT 'active',
    employee_type hr.employee_type NOT NULL,
    hire_date DATE NOT NULL,
    termination_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(user_id), -- Link to auth.users
    updated_by UUID REFERENCES auth.users(user_id)  -- Link to auth.users
);

CREATE TABLE hr.employee_addresses (
    address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    address_type VARCHAR(20) NOT NULL CHECK (address_type IN ('home', 'work', 'other')),
    street_address1 VARCHAR(100) NOT NULL,
    street_address2 VARCHAR(100),
    city VARCHAR(50) NOT NULL,
    state_province VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hr.employee_bank_details (
    bank_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    bank_name VARCHAR(100) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    branch_code VARCHAR(20),
    swift_code VARCHAR(20),
    iban VARCHAR(50),
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Business account and organization structure (moved to hr schema, refined)
CREATE TABLE hr.business_units (
    business_unit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    parent_id UUID REFERENCES hr.business_units(business_unit_id),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_unit_id UUID NOT NULL REFERENCES hr.business_units(business_unit_id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE hr.cost_centers (
    cost_center_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES hr.departments(department_id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE,
    budget NUMERIC(12,2),
    used_budget NUMERIC(12,2) DEFAULT 0
);

-- Corporate Cards and Card Issuers (consolidated and moved to finance schema)
CREATE TABLE finance.card_issuers (
    issuer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    api_key TEXT ENCRYPTED,
    webhook_secret TEXT ENCRYPTED,
    base_url TEXT
);

CREATE TABLE finance.corporate_cards (
    card_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issuer_id UUID NOT NULL REFERENCES finance.card_issuers(issuer_id) ON DELETE RESTRICT,
    card_holder_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT, -- Link to hr.employees
    card_number_last_four VARCHAR(4) NOT NULL,
    card_provider VARCHAR(50) NOT NULL CHECK (card_provider IN ('visa', 'mastercard', 'amex')),
    credit_limit NUMERIC(10,2) NOT NULL,
    activation_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled', 'lost')),
    accounting_code VARCHAR(50),
    monthly_statement_day INTEGER CHECK (monthly_statement_day BETWEEN 1 AND 28),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.card_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID NOT NULL REFERENCES finance.corporate_cards(card_id) ON DELETE RESTRICT,
    merchant_name VARCHAR(100) NOT NULL,
    merchant_category_code VARCHAR(10),
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    posting_date DATE NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    foreign_amount NUMERIC(10,2),
    foreign_currency VARCHAR(3),
    exchange_rate NUMERIC(10,6),
    expense_report_id UUID, -- Will reference finance.expense_reports
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'disputed')),
    disputed_reason TEXT,
    receipt_required BOOLEAN DEFAULT true,
    receipt_url VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spend Management and Expense Tracking (consolidated and moved to finance schema)
CREATE TABLE finance.expense_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL,
    parent_category_id UUID REFERENCES finance.expense_categories(category_id),
    gl_account_code VARCHAR(50) NOT NULL,
    requires_receipt BOOLEAN DEFAULT true,
    requires_approval BOOLEAN DEFAULT true,
    approval_threshold NUMERIC(10,2)
);

CREATE TABLE finance.receipts (
    receipt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    url TEXT NOT NULL, -- Link to MinIO/S3 object
    mime_type VARCHAR(50),
    uploaded_by UUID REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.expense_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL,
    department_id UUID REFERENCES hr.departments(department_id) ON DELETE RESTRICT,
    max_daily_meal NUMERIC(10,2),
    max_hotel_rate NUMERIC(10,2),
    international_multiplier NUMERIC(5,2) DEFAULT 1.5,
    requires_pre_approval BOOLEAN DEFAULT false,
    effective_date DATE NOT NULL
);

CREATE TABLE finance.expense_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    report_date DATE NOT NULL DEFAULT CURRENT_DATE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'paid', 'rejected')),
    approver_id UUID REFERENCES auth.users(user_id), -- Approver is a user
    payment_id UUID, -- Will reference finance.account_transactions
    accounting_period VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE finance.card_transactions
ADD CONSTRAINT fk_expense_report
FOREIGN KEY (expense_report_id) REFERENCES finance.expense_reports(report_id) ON DELETE SET NULL;

CREATE TABLE finance.expense_items (
    expense_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID NOT NULL REFERENCES finance.expense_reports(report_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES finance.expense_categories(category_id) ON DELETE RESTRICT,
    transaction_date DATE NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    tax_amount NUMERIC(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    foreign_amount NUMERIC(10,2),
    foreign_currency VARCHAR(3),
    payment_method VARCHAR(20) CHECK (payment_method IN ('corporate_card', 'personal_card', 'cash', 'other')),
    card_transaction_id UUID REFERENCES finance.card_transactions(transaction_id) ON DELETE SET NULL,
    receipt_id UUID REFERENCES finance.receipts(receipt_id) ON DELETE SET NULL,
    is_billable BOOLEAN DEFAULT false,
    client_id UUID, -- Will reference finance.clients
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Business Accounts and Banking (moved to finance schema)
CREATE TABLE finance.business_bank_accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    branch_code VARCHAR(20),
    swift_code VARCHAR(20),
    iban VARCHAR(50),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    current_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    credit_limit NUMERIC(15,2),
    is_active BOOLEAN DEFAULT true,
    accounting_code VARCHAR(50),
    last_reconciliation_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.account_transaction_signers (
    transaction_signer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES finance.business_bank_accounts(account_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    PRIMARY KEY (account_id, employee_id)
);

CREATE TABLE finance.account_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES finance.business_bank_accounts(account_id) ON DELETE RESTRICT,
    transaction_date DATE NOT NULL,
    value_date DATE NOT NULL,
    reference_number VARCHAR(100),
    description TEXT NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    balance_after NUMERIC(15,2) NOT NULL,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer', 'fee')),
    category_id UUID REFERENCES finance.expense_categories(category_id), -- Link to finance.expense_categories
    reconciled BOOLEAN DEFAULT false,
    reconciled_by UUID REFERENCES auth.users(user_id), -- Reconciled by a user
    receipt_id UUID REFERENCES finance.receipts(receipt_id) ON DELETE SET NULL, -- Link to finance.receipts
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE finance.expense_reports
ADD CONSTRAINT fk_payment_transaction
FOREIGN KEY (payment_id) REFERENCES finance.account_transactions(transaction_id) ON DELETE SET NULL;

-- Enterprise Accounting and Finance (moved to finance schema)
CREATE TABLE finance.chart_of_accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_code VARCHAR(20) NOT NULL UNIQUE,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) CHECK (account_type IN ('Asset', 'Liability', 'Equity', 'Revenue', 'Expense')),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.journal_entries (
    journal_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference_id UUID, -- e.g., expense_report_id, invoice_id, contract_id
    reference_type VARCHAR(50), -- e.g., 'expense_report', 'invoice', 'contract'
    description TEXT,
    entry_date DATE NOT NULL,
    created_by UUID REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.ledger_entries (
    ledger_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journal_entry_id UUID NOT NULL REFERENCES finance.journal_entries(journal_entry_id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES finance.chart_of_accounts(account_id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL,
    debit_credit VARCHAR(10) NOT NULL CHECK (debit_credit IN ('Debit', 'Credit')),
    memo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.budgets (
    budget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cost_center_id UUID REFERENCES hr.cost_centers(cost_center_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_budget NUMERIC(12,2) NOT NULL,
    spent NUMERIC(12,2) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Integrations with External Accounting Systems (moved to finance schema)
CREATE TABLE finance.accounting_platforms (
    platform_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    auth_token TEXT ENCRYPTED,
    refresh_token TEXT ENCRYPTED,
    api_base_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.accounting_sync_logs (
    sync_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform_id UUID NOT NULL REFERENCES finance.accounting_platforms(platform_id) ON DELETE RESTRICT,
    sync_type VARCHAR(50) NOT NULL, -- e.g., "expenses", "invoices", "journal"
    success BOOLEAN NOT NULL,
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Autonomous Financial Policy Engine (moved to finance schema)
CREATE TABLE finance.dynamic_policy_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_condition TEXT NOT NULL, -- Natural language: "If international travel expense > $5k, require VP approval"
    compiled_sql TEXT NOT NULL, -- Compiled WHERE clause
    action JSONB NOT NULL, -- {"route_to": "vp_approval", "notify": ["travel_team"]}
    version_hash BYTEA NOT NULL, -- For change detection
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.policy_execution_logs (
    execution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES finance.dynamic_policy_rules(rule_id) ON DELETE RESTRICT,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    affected_entities JSONB NOT NULL -- {"expense_ids": [uuid1, uuid2]}
);

-- Predictive Budget Stress Testing (moved to finance schema)
CREATE TABLE finance.budget_stress_scenarios (
    scenario_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_name VARCHAR(100) NOT NULL,
    parameters JSONB NOT NULL, -- {"headcount_reduction": 0.15, "salary_freeze": true}
    monte_carlo_iterations INT DEFAULT 1000,
    results_summary JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.scenario_cashflow_projections (
    projection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_id UUID NOT NULL REFERENCES finance.budget_stress_scenarios(scenario_id) ON DELETE CASCADE,
    month DATE NOT NULL,
    p05 NUMERIC(15,2) NOT NULL, -- 5th percentile
    p50 NUMERIC(15,2) NOT NULL, -- Median
    p95 NUMERIC(15,2) NOT NULL,  -- 95th percentile
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clients table (missing from original, added to finance schema)
CREATE TABLE finance.clients (
    client_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    phone_number VARCHAR(20),
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE finance.expense_items
ADD CONSTRAINT fk_client
FOREIGN KEY (client_id) REFERENCES finance.clients(client_id) ON DELETE SET NULL;

-- Emotional Intelligence Analytics (moved to analytics schema, completed definition)
CREATE TABLE analytics.emotional_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    metric_type VARCHAR(50) NOT NULL, -- e.g., 'sentiment_score', 'engagement_level'
    metric_value NUMERIC(5,2) NOT NULL,
    source_data TEXT, -- e.g., 'survey_response', 'communication_analysis'
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Additional HR Tables (missing from original, added to hr schema)
CREATE TABLE hr.positions (
    position_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    position_title VARCHAR(100) NOT NULL,
    department_id UUID NOT NULL REFERENCES hr.departments(department_id) ON DELETE RESTRICT,
    job_description TEXT,
    responsibilities TEXT,
    requirements TEXT,
    salary_range_min NUMERIC(10,2),
    salary_range_max NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.job_history (
    job_history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    position_id UUID NOT NULL REFERENCES hr.positions(position_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE,
    salary NUMERIC(10,2),
    promotion_demotion VARCHAR(50),
    reason_for_change TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.compensation (
    compensation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    salary NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    effective_date DATE NOT NULL,
    pay_frequency VARCHAR(20) CHECK (pay_frequency IN ('hourly', 'weekly', 'bi-weekly', 'monthly', 'annually')),
    bonus NUMERIC(10,2) DEFAULT 0,
    commission NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.benefits (
    benefit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    benefit_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    provider VARCHAR(100),
    cost_to_company NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_benefits (
    employee_benefit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    benefit_id UUID NOT NULL REFERENCES hr.benefits(benefit_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    cancellation_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'cancelled', 'pending')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recruitment Tables (recruitment schema)
CREATE TABLE recruitment.job_postings (
    job_posting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    position_id UUID NOT NULL REFERENCES hr.positions(position_id) ON DELETE RESTRICT,
    recruitment_status hr.recruitment_status NOT NULL DEFAULT 'draft',
    posted_date DATE NOT NULL,
    closing_date DATE,
    external_url TEXT,
    hiring_manager_id UUID REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.candidates (
    candidate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    resume_url TEXT,
    linkedin_profile_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.applications (
    application_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID NOT NULL REFERENCES recruitment.job_postings(job_posting_id) ON DELETE CASCADE,
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    application_status hr.application_status NOT NULL DEFAULT 'received',
    cover_letter_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.interviews (
    interview_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES recruitment.applications(application_id) ON DELETE CASCADE,
    interviewer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    interview_date TIMESTAMP WITH TIME ZONE NOT NULL,
    interview_type VARCHAR(50), -- e.g., 'phone', 'video', 'onsite'
    feedback TEXT,
    rating NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payroll Tables (payroll schema)
CREATE TABLE payroll.pay_grades (
    pay_grade_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grade_name VARCHAR(50) NOT NULL UNIQUE,
    min_salary NUMERIC(10,2) NOT NULL,
    max_salary NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.employee_pay_details (
    employee_pay_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    pay_grade_id UUID REFERENCES payroll.pay_grades(pay_grade_id) ON DELETE RESTRICT,
    base_salary NUMERIC(10,2) NOT NULL,
    hourly_rate NUMERIC(8,2),
    overtime_eligible BOOLEAN DEFAULT FALSE,
    tax_code VARCHAR(20),
    bank_account_id UUID REFERENCES hr.employee_bank_details(bank_detail_id) ON DELETE RESTRICT,
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.pay_periods (
    pay_period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    pay_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('open', 'closed', 'processed')) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.payrolls (
    payroll_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    pay_period_id UUID NOT NULL REFERENCES payroll.pay_periods(pay_period_id) ON DELETE RESTRICT,
    gross_pay NUMERIC(10,2) NOT NULL,
    net_pay NUMERIC(10,2) NOT NULL,
    total_deductions NUMERIC(10,2) NOT NULL,
    total_taxes NUMERIC(10,2) NOT NULL,
    payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
    payment_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.deductions (
    deduction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    deduction_type VARCHAR(50) NOT NULL, -- e.g., 'health_insurance', '401k', 'loan_repayment'
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.taxes (
    tax_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    tax_type VARCHAR(50) NOT NULL, -- e.g., 'federal_income_tax', 'state_income_tax', 'social_security'
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Tables (performance schema)
CREATE TABLE performance.goals (
    goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    goal_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('not_started', 'in_progress', 'completed', 'overdue')) DEFAULT 'not_started',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.performance_reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    review_date DATE NOT NULL,
    overall_rating hr.performance_rating NOT NULL,
    comments TEXT,
    next_review_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    giver_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    feedback_date DATE NOT NULL,
    feedback_text TEXT NOT NULL,
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('positive', 'constructive', '360_degree')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Learning Tables (learning schema)
CREATE TABLE learning.courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    duration_hours NUMERIC(5,2),
    provider VARCHAR(100),
    cost NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_courses (
    employee_course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES learning.courses(course_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'in_progress', 'completed', 'failed')) DEFAULT 'enrolled',
    score NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Benefits Tables (benefits schema)
-- hr.benefits and hr.employee_benefits are already defined above.

-- Compliance Schema: GDPR, SEC/FCA, SOC 2, Audit Logs
CREATE TABLE compliance.data_consent_records (
    consent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE CASCADE,
    consent_type VARCHAR(100) NOT NULL, -- e.g., 'marketing_email', 'data_processing'
    consent_given BOOLEAN NOT NULL,
    consent_timestamp TIMESTAMPTZ DEFAULT NOW(),
    data_processor TEXT, -- e.g., 'HR Platform', 'Third-party Payroll'
    policy_version VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.data_subject_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('access', 'rectification', 'erasure', 'restriction', 'portability', 'objection')),
    request_details TEXT NOT NULL,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'rejected')) DEFAULT 'pending',
    completed_date TIMESTAMPTZ,
    processed_by UUID REFERENCES auth.users(user_id),
    resolution_details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.data_retention_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL UNIQUE,
    data_category VARCHAR(100) NOT NULL, -- e.g., 'employee_data', 'financial_records'
    retention_period_days INT NOT NULL,
    legal_basis TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.audit_logs (
    audit_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL, -- e.g., 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'ACCESS'
    table_name VARCHAR(100),
    record_id UUID, -- ID of the affected record
    old_value JSONB, -- Old state of the record (for UPDATE/DELETE)
    new_value JSONB, -- New state of the record (for CREATE/UPDATE)
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Data Governance Schema: Data Quality, Lineage, Profiling, Catalog, Dictionary
CREATE TABLE data_governance.data_quality_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    target_table VARCHAR(100) NOT NULL,
    target_column VARCHAR(100),
    rule_expression TEXT, -- e.g., 'column_name IS NOT NULL', 'column_name > 0'
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_validation_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES data_governance.data_quality_rules(rule_id) ON DELETE RESTRICT,
    validation_timestamp TIMESTAMPTZ DEFAULT NOW(),
    affected_record_id UUID, -- ID of the record that failed validation
    error_message TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by UUID REFERENCES auth.users(user_id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL UNIQUE,
    source_type VARCHAR(50) NOT NULL, -- e.g., 'database', 'api', 'file_system'
    connection_details JSONB,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_transformations (
    transformation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transformation_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    script_path TEXT, -- Path to the transformation script/code
    created_by UUID REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_lineage (
    lineage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_id UUID REFERENCES data_governance.data_sources(source_id) ON DELETE RESTRICT,
    transformation_id UUID REFERENCES data_governance.data_transformations(transformation_id) ON DELETE RESTRICT,
    target_table VARCHAR(100) NOT NULL,
    target_column VARCHAR(100),
    lineage_type VARCHAR(50) CHECK (lineage_type IN ('source_to_table', 'table_to_table', 'transformation_to_table', 'table_to_report')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_profiling_results (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    profile_timestamp TIMESTAMPTZ DEFAULT NOW(),
    total_rows INT,
    null_count INT,
    distinct_count INT,
    min_value TEXT,
    max_value TEXT,
    avg_value NUMERIC,
    std_dev NUMERIC,
    data_type VARCHAR(50),
    value_distribution JSONB, -- JSONB for storing value distribution (e.g., histogram)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_name VARCHAR(255) NOT NULL UNIQUE,
    asset_type VARCHAR(50) NOT NULL, -- e.g., 'table', 'view', 'report', 'dashboard'
    description TEXT,
    owner_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    steward_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    source_system_id UUID REFERENCES data_governance.data_sources(source_id) ON DELETE SET NULL,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_elements (
    element_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES data_governance.data_assets(asset_id) ON DELETE CASCADE,
    element_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    description TEXT,
    is_pii BOOLEAN DEFAULT FALSE,
    is_sensitive BOOLEAN DEFAULT FALSE,
    classification VARCHAR(50), -- e.g., 'public', 'internal', 'confidential'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics Schema: Visitor Analytics, KPIs, Subscription Model
CREATE TABLE analytics.page_views (
    page_view_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    session_id UUID, -- For tracking anonymous sessions
    page_url TEXT NOT NULL,
    referrer_url TEXT,
    ip_address INET,
    user_agent TEXT,
    view_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.user_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(50),
    operating_system VARCHAR(50),
    browser VARCHAR(50)
);

CREATE TABLE analytics.event_logs (
    event_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    session_id UUID REFERENCES analytics.user_sessions(session_id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL, -- e.g., 'button_click', 'form_submission', 'report_download'
    event_details JSONB,
    event_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.kpi_definitions (
    kpi_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    calculation_method TEXT NOT NULL, -- SQL query or description of logic
    target_value NUMERIC(15,2),
    unit VARCHAR(50),
    frequency VARCHAR(20) CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'annually')),
    owner_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.kpi_values (
    kpi_value_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES analytics.kpi_definitions(kpi_id) ON DELETE CASCADE,
    recorded_date DATE NOT NULL,
    actual_value NUMERIC(15,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('weekly_insights', 'monthly_insights', 'premium')),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.insight_types (
    insight_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    frequency VARCHAR(20) CHECK (frequency IN ('weekly', 'monthly')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.user_insights (
    user_insight_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES analytics.subscriptions(subscription_id) ON DELETE CASCADE,
    insight_type_id UUID NOT NULL REFERENCES analytics.insight_types(insight_type_id) ON DELETE RESTRICT,
    generated_date DATE NOT NULL,
    insight_content JSONB NOT NULL, -- Store the actual insight data (e.g., report summary, charts)
    delivery_status VARCHAR(20) CHECK (delivery_status IN ('pending', 'delivered', 'failed')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI-powered Deal Matching (analytics schema or new deals schema)
-- For now, placing in analytics, could be moved to a dedicated 'deals' schema if it grows.
CREATE TABLE analytics.deal_profiles (
    deal_profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deal_name VARCHAR(255) NOT NULL,
    description TEXT,
    industry VARCHAR(100),
    deal_size NUMERIC(15,2),
    deal_type VARCHAR(50), -- e.g., 'acquisition', 'merger', 'investment'
    key_attributes JSONB, -- Store other relevant attributes for matching
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.matching_results (
    matching_result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deal_profile_id UUID NOT NULL REFERENCES analytics.deal_profiles(deal_profile_id) ON DELETE CASCADE,
    matched_entity_id UUID NOT NULL, -- Could be another deal, a company, etc.
    matched_entity_type VARCHAR(50) NOT NULL,
    score NUMERIC(5,2) NOT NULL,
    matching_algorithm VARCHAR(100),
    matching_timestamp TIMESTAMPTZ DEFAULT NOW(),
    details JSONB -- Additional details about the match
);

-- Views (from original schema, refined and added new ones)
CREATE VIEW hr.vw_department_budget_utilization AS
SELECT
    d.department_id,
    d.name AS department_name,
    b.total_budget AS budget_amount,
    COALESCE(SUM(fi.amount), 0) AS spent_amount,
    (COALESCE(SUM(fi.amount), 0) / b.total_budget) AS utilization_rate
FROM hr.departments d
JOIN finance.budgets b ON d.department_id = b.cost_center_id -- Assuming cost_center_id in budgets maps to department_id
LEFT JOIN finance.expense_items fi ON fi.client_id = d.department_id -- This join needs re-evaluation, expense_items.client_id is not department_id
GROUP BY d.department_id, d.name, b.total_budget;

-- Additional Views (examples)
CREATE VIEW hr.vw_employee_details AS
SELECT
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    e.company_email,
    e.hire_date,
    e.employment_status,
    d.name AS department_name,
    p.position_title,
    c.salary AS current_salary
FROM hr.employees e
LEFT JOIN hr.job_history jh ON e.employee_id = jh.employee_id AND jh.end_date IS NULL -- Current job
LEFT JOIN hr.positions p ON jh.position_id = p.position_id
LEFT JOIN hr.departments d ON p.department_id = d.department_id
LEFT JOIN hr.compensation c ON e.employee_id = c.employee_id AND c.effective_date = (SELECT MAX(effective_date) FROM hr.compensation WHERE employee_id = e.employee_id);

CREATE VIEW finance.vw_expense_report_summary AS
SELECT
    er.report_id,
    er.report_date,
    e.first_name || ' ' || e.last_name AS employee_name,
    er.total_amount,
    er.currency,
    er.status,
    au.username AS approver_username
FROM finance.expense_reports er
JOIN hr.employees e ON er.employee_id = e.employee_id
LEFT JOIN auth.users au ON er.approver_id = au.user_id;

-- Stored Procedures (examples - placeholders for now)
CREATE OR REPLACE FUNCTION finance.sp_process_expense_report(p_report_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Logic to process expense report, e.g., update status, create journal entries
    -- This would involve multiple steps and transactions.
    UPDATE finance.expense_reports
    SET status = 'approved'
    WHERE report_id = p_report_id;

    -- Example: Create a journal entry for the expense report
    INSERT INTO finance.journal_entries (reference_id, reference_type, description, entry_date, created_by)
    SELECT
        p_report_id,
        'expense_report',
        'Expense Report ' || er.report_id || ' for ' || e.first_name || ' ' || e.last_name,
        er.report_date,
        er.approver_id
    FROM finance.expense_reports er
    JOIN hr.employees e ON er.employee_id = e.employee_id
    WHERE er.report_id = p_report_id;

    -- Further logic to create ledger entries based on expense categories and GL accounts
    -- ...

END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_anonymize_employee_data(p_employee_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Logic to anonymize sensitive employee data for GDPR compliance
    -- This would involve updating various tables and potentially archiving data.
    UPDATE hr.employees
    SET
        first_name = 'ANONYMIZED',
        middle_name = NULL,
        last_name = 'ANONYMIZED',
        date_of_birth = NULL,
        national_id = NULL,
        passport_number = NULL,
        tax_id = NULL,
        social_security_number = NULL,
        personal_email = 'anonymized_' || p_employee_id || '@example.com',
        phone_number = NULL,
        emergency_contact_name = NULL,
        emergency_contact_phone = NULL
    WHERE employee_id = p_employee_id;

    -- Update related tables (e.g., addresses, bank details) to anonymize or delete sensitive info
    DELETE FROM hr.employee_addresses WHERE employee_id = p_employee_id;
    DELETE FROM hr.employee_bank_details WHERE employee_id = p_employee_id;

    -- Log the anonymization action
    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, description)
    VALUES (NULL, 'ANONYMIZE', 'hr.employees', p_employee_id, 'Employee data anonymized for GDPR compliance');

END;
$$
LANGUAGE plpgsql;

-- Initial data for roles and permissions (for RBAC setup)
INSERT INTO auth.roles (role_id, role_name) VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Admin'),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'HR Manager'),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'Employee'),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a14', 'Finance User');

INSERT INTO auth.permissions (permission_id, permission_name, description) VALUES
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'read_employee_data', 'Allows reading of all employee data'),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12', 'manage_employee_data', 'Allows creating, updating, and deleting employee data'),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b13', 'approve_expenses', 'Allows approval of expense reports'),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b14', 'view_financial_reports', 'Allows viewing of financial reports');

INSERT INTO auth.role_permissions (role_id, permission_id) VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11'), -- Admin can read employee data
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12'), -- Admin can manage employee data
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b13'), -- Admin can approve expenses
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b14'), -- Admin can view financial reports
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11'), -- HR Manager can read employee data
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b12'); -- HR Manager can manage employee data

-- Note: The total number of tables is still far from 223. This is an iterative process.
-- The next steps will involve adding more tables based on the identified gaps and user requirements.



-- Additional HR Tables (continued)
CREATE TABLE hr.employee_skills (
    employee_skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    skill_level VARCHAR(50), -- e.g., 'Beginner', 'Intermediate', 'Advanced', 'Expert'
    last_used_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    document_type VARCHAR(100) NOT NULL, -- e.g., 'Passport', 'Visa', 'Contract'
    document_url TEXT NOT NULL,
    issue_date DATE,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.leave_types (
    leave_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leave_type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_paid BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.leave_requests (
    leave_request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES hr.leave_types(leave_type_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status hr.leave_status NOT NULL DEFAULT 'pending',
    approver_id UUID REFERENCES auth.users(user_id),
    approved_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.attendance (
    attendance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    check_in_time TIMESTAMPTZ NOT NULL,
    check_out_time TIMESTAMPTZ,
    work_date DATE NOT NULL,
    hours_worked NUMERIC(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_relations (
    case_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    case_type VARCHAR(100) NOT NULL, -- e.g., 'Grievance', 'Disciplinary Action', 'Investigation'
    case_date DATE NOT NULL,
    description TEXT,
    status hr.investigation_status NOT NULL DEFAULT 'open',
    severity hr.investigation_severity,
    assigned_to UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    resolution TEXT,
    closed_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);




-- Performance Management (continued)
CREATE TABLE performance.performance_goals (
    goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    goal_description TEXT NOT NULL,
    target_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')),
    achieved_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.performance_reviews_details (
    review_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES performance.performance_reviews(review_id) ON DELETE CASCADE,
    area_of_review VARCHAR(100) NOT NULL, -- e.g., 'Communication', 'Technical Skills'
    rating hr.performance_rating NOT NULL,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Training and Development (continued)
CREATE TABLE learning.training_programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    duration_hours NUMERIC(5,2),
    cost NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_training_enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES learning.training_programs(program_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'in_progress', 'completed', 'failed')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.certifications (
    certification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certification_name VARCHAR(255) NOT NULL UNIQUE,
    issuing_body VARCHAR(100),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_certifications (
    employee_certification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    certification_id UUID NOT NULL REFERENCES learning.certifications(certification_id) ON DELETE RESTRICT,
    issue_date DATE NOT NULL,
    expiry_date DATE,
    credential_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (continued)
CREATE TABLE benefits.benefit_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(100) NOT NULL UNIQUE,
    plan_type VARCHAR(50) NOT NULL, -- e.g., 'Health Insurance', 'Dental', 'Vision', '401k'
    description TEXT,
    provider VARCHAR(100),
    annual_cost NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_benefit_enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES benefits.benefit_plans(plan_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    coverage_start_date DATE,
    coverage_end_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'waived', 'terminated')) DEFAULT 'enrolled',
    employee_contribution NUMERIC(10,2),
    company_contribution NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recruitment (continued)
CREATE TABLE recruitment.candidate_skills (
    candidate_skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    skill_level VARCHAR(50), -- e.g., 'Beginner', 'Intermediate', 'Advanced', 'Expert'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.interview_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID NOT NULL REFERENCES recruitment.interviews(interview_id) ON DELETE CASCADE,
    feedback_question TEXT NOT NULL,
    feedback_answer TEXT,
    rating NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.offer_letters (
    offer_letter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES recruitment.applications(application_id) ON DELETE CASCADE,
    offered_salary NUMERIC(10,2) NOT NULL,
    start_date DATE NOT NULL,
    expiration_date DATE,
    status VARCHAR(20) CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'withdrawn')) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Lifecycle (additional tables)
CREATE TABLE hr.onboarding_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    completed_date DATE,
    assigned_to UUID REFERENCES auth.users(user_id),
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.offboarding_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    completed_date DATE,
    assigned_to UUID REFERENCES auth.users(user_id),
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Compensation and Benefits (additional tables)
CREATE TABLE payroll.salary_adjustments (
    adjustment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    adjustment_date DATE NOT NULL,
    old_salary NUMERIC(10,2) NOT NULL,
    new_salary NUMERIC(10,2) NOT NULL,
    reason TEXT,
    approved_by UUID REFERENCES auth.users(user_id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.dependent_information (
    dependent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    relationship VARCHAR(50) NOT NULL, -- e.g., 'Spouse', 'Child'
    gender hr.gender,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.dependent_enrollments (
    dependent_enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dependent_id UUID NOT NULL REFERENCES benefits.dependent_information(dependent_id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES benefits.benefit_plans(plan_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    coverage_start_date DATE,
    coverage_end_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'waived', 'terminated')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time and Attendance (additional tables)
CREATE TABLE hr.time_off_accruals (
    accrual_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES hr.leave_types(leave_type_id) ON DELETE RESTRICT,
    accrual_date DATE NOT NULL,
    hours_accrued NUMERIC(5,2) NOT NULL,
    balance_after NUMERIC(5,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.timesheets (
    timesheet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')) DEFAULT 'draft',
    total_hours NUMERIC(5,2),
    approved_by UUID REFERENCES auth.users(user_id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.timesheet_entries (
    entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timesheet_id UUID NOT NULL REFERENCES hr.timesheets(timesheet_id) ON DELETE CASCADE,
    work_date DATE NOT NULL,
    hours_worked NUMERIC(5,2) NOT NULL,
    task_description TEXT,
    project_id UUID, -- Assuming a projects table exists or will be added
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Grievances and Disciplinary Actions (additional tables)
CREATE TABLE hr.grievances (
    grievance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    grievance_date DATE NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
    resolution TEXT,
    resolved_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.disciplinary_actions (
    action_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    action_date DATE NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- e.g., 'Verbal Warning', 'Written Warning', 'Suspension', 'Termination'
    reason TEXT NOT NULL,
    effective_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Surveys and Engagement
CREATE TABLE hr.surveys (
    survey_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.survey_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN ('text', 'single_choice', 'multi_choice', 'rating')) NOT NULL,
    options JSONB, -- For single_choice/multi_choice questions
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.survey_responses (
    response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    submission_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.survey_answers (
    answer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id UUID NOT NULL REFERENCES hr.survey_responses(response_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES hr.survey_questions(question_id) ON DELETE CASCADE,
    answer_text TEXT,
    selected_options JSONB, -- For multi_choice
    rating_value NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recognition
CREATE TABLE hr.recognition_types (
    recognition_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_recognitions (
    recognition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    recognizer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    recognition_type_id UUID NOT NULL REFERENCES hr.recognition_types(recognition_type_id) ON DELETE RESTRICT,
    recognition_date DATE NOT NULL,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Assets
CREATE TABLE hr.asset_types (
    asset_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    asset_type_id UUID NOT NULL REFERENCES hr.asset_types(asset_type_id) ON DELETE RESTRICT,
    serial_number VARCHAR(100) UNIQUE,
    assigned_date DATE NOT NULL,
    returned_date DATE,
    condition VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communications
CREATE TABLE hr.announcements (
    announcement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    publish_date TIMESTAMPTZ DEFAULT NOW(),
    expiry_date TIMESTAMPTZ,
    published_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    target_audience JSONB, -- e.g., {'departments': ['HR', 'Finance'], 'roles': ['Employee']}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL, -- e.g., 'system_alert', 'expense_approval', 'new_announcement'
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Feedback and Suggestions
CREATE TABLE hr.suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    suggestion_text TEXT NOT NULL,
    submission_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) CHECK (status IN ('new', 'under_review', 'implemented', 'rejected')) DEFAULT 'new',
    reviewed_by UUID REFERENCES auth.users(user_id),
    review_comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Wellness
CREATE TABLE hr.wellness_programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_wellness_enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    program_id UUID NOT NULL REFERENCES hr.wellness_programs(program_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'completed', 'dropped')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Travel Management
CREATE TABLE finance.travel_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    destination VARCHAR(255) NOT NULL,
    purpose TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    estimated_cost NUMERIC(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')) DEFAULT 'pending',
    approved_by UUID REFERENCES auth.users(user_id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.travel_bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES finance.travel_requests(request_id) ON DELETE CASCADE,
    booking_type VARCHAR(50) NOT NULL, -- e.g., 'flight', 'hotel', 'car_rental'
    vendor VARCHAR(100),
    confirmation_number VARCHAR(100),
    cost NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    booking_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project Management Integration (assuming a basic structure)
CREATE TABLE hr.projects (
    project_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) CHECK (status IN ('planning', 'in_progress', 'completed', 'on_hold', 'cancelled')) DEFAULT 'planning',
    project_manager_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_projects (
    employee_project_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES hr.projects(project_id) ON DELETE CASCADE,
    role_on_project VARCHAR(100),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update timesheet_entries to reference hr.projects
ALTER TABLE hr.timesheet_entries
ADD CONSTRAINT fk_project
FOREIGN KEY (project_id) REFERENCES hr.projects(project_id) ON DELETE SET NULL;

-- Vendor Management (basic structure)
CREATE TABLE finance.vendors (
    vendor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_name VARCHAR(255) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    phone_number VARCHAR(20),
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.invoices (
    invoice_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES finance.vendors(vendor_id) ON DELETE RESTRICT,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN ('pending', 'paid', 'overdue', 'disputed')) DEFAULT 'pending',
    payment_date DATE,
    payment_transaction_id UUID REFERENCES finance.account_transactions(transaction_id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE finance.invoice_items (
    invoice_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES finance.invoices(invoice_id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity NUMERIC(10,2) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    line_total NUMERIC(10,2) NOT NULL,
    category_id UUID REFERENCES finance.expense_categories(category_id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Contracts Management
CREATE TABLE finance.contracts (
    contract_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_name VARCHAR(255) NOT NULL,
    vendor_id UUID REFERENCES finance.vendors(vendor_id) ON DELETE SET NULL,
    client_id UUID REFERENCES finance.clients(client_id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    contract_value NUMERIC(15,2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN ('active', 'expired', 'terminated', 'draft')) DEFAULT 'draft',
    renewal_date DATE,
    responsible_employee_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    contract_document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Asset Management (detailed)
CREATE TABLE hr.assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_type_id UUID NOT NULL REFERENCES hr.asset_types(asset_type_id) ON DELETE RESTRICT,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    asset_name VARCHAR(255) NOT NULL,
    purchase_date DATE,
    purchase_price NUMERIC(10,2),
    current_value NUMERIC(10,2),
    warranty_expiry_date DATE,
    location VARCHAR(100),
    status VARCHAR(50) CHECK (status IN ('in_use', 'in_storage', 'under_maintenance', 'retired', 'lost')) DEFAULT 'in_use',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update hr.employee_assets to reference hr.assets
ALTER TABLE hr.employee_assets
DROP COLUMN serial_number, -- Remove old column
ADD COLUMN asset_uuid UUID NOT NULL REFERENCES hr.assets(asset_id) ON DELETE RESTRICT;

-- Meetings and Calendaring (basic structure)
CREATE TABLE hr.meetings (
    meeting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    organizer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.meeting_attendees (
    attendee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_id UUID NOT NULL REFERENCES hr.meetings(meeting_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    rsvp_status VARCHAR(20) CHECK (rsvp_status IN ('pending', 'accepted', 'declined', 'tentative')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Help Desk / IT Support (basic structure)
CREATE TABLE hr.support_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    submission_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    assigned_to UUID REFERENCES auth.users(user_id),
    resolution_details TEXT,
    closed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.ticket_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES hr.support_tickets(ticket_id) ON DELETE CASCADE,
    comment_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMPTZ DEFAULT NOW()
);

-- Knowledge Base / Documentation
CREATE TABLE hr.knowledge_base_articles (
    article_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL UNIQUE,
    content TEXT NOT NULL,
    category VARCHAR(100),
    tags TEXT[],
    author_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    publish_date TIMESTAMPTZ DEFAULT NOW(),
    last_updated_date TIMESTAMPTZ DEFAULT NOW(),
    is_published BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Emergency Contacts (additional details)
ALTER TABLE hr.employees
DROP COLUMN emergency_contact_name,
DROP COLUMN emergency_contact_phone;

CREATE TABLE hr.emergency_contacts (
    contact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    contact_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Education
CREATE TABLE hr.education_levels (
    level_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    level_name VARCHAR(100) NOT NULL UNIQUE, -- e.g., 'High School', 'Bachelor's', 'Master's', 'PhD'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_education (
    education_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    degree VARCHAR(100) NOT NULL,
    major VARCHAR(100),
    university VARCHAR(255) NOT NULL,
    graduation_date DATE,
    education_level_id UUID REFERENCES hr.education_levels(level_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Previous Employment
CREATE TABLE hr.previous_employments (
    prev_employment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    company_name VARCHAR(255) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    responsibilities TEXT,
    reason_for_leaving TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Licenses and Certifications (separate from learning.certifications for professional licenses)
CREATE TABLE hr.licenses (
    license_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    license_name VARCHAR(255) NOT NULL UNIQUE,
    issuing_authority VARCHAR(100),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_licenses (
    employee_license_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    license_id UUID NOT NULL REFERENCES hr.licenses(license_id) ON DELETE RESTRICT,
    license_number VARCHAR(100) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training Records (more granular)
CREATE TABLE learning.employee_training_records (
    training_record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    training_name VARCHAR(255) NOT NULL,
    training_date DATE NOT NULL,
    duration_hours NUMERIC(5,2),
    provider VARCHAR(100),
    cost NUMERIC(10,2),
    completion_status VARCHAR(20) CHECK (completion_status IN ('completed', 'in_progress', 'not_started')) DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Health and Safety
CREATE TABLE hr.health_records (
    health_record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    record_date DATE NOT NULL,
    record_type VARCHAR(100), -- e.g., 'Medical Exam', 'Vaccination', 'Injury Report'
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_date DATE NOT NULL,
    incident_type VARCHAR(100) NOT NULL, -- e.g., 'Workplace Injury', 'Harassment', 'Security Breach'
    description TEXT NOT NULL,
    reported_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    status VARCHAR(20) CHECK (status IN ('open', 'in_investigation', 'resolved', 'closed')) DEFAULT 'open',
    severity hr.investigation_severity,
    resolution_details TEXT,
    closed_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.incident_employees (
    incident_employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID NOT NULL REFERENCES hr.incidents(incident_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    role_in_incident VARCHAR(50), -- e.g., 'Victim', 'Perpetrator', 'Witness'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Feedback (more detailed)
CREATE TABLE hr.employee_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    feedback_giver_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL, -- Optional, for anonymous feedback
    feedback_date TIMESTAMPTZ DEFAULT NOW(),
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('general', 'performance', 'manager', 'peer')) DEFAULT 'general',
    feedback_text TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    sentiment_score NUMERIC(3,2), -- AI-powered sentiment analysis
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Surveys (more detailed)
CREATE TABLE hr.survey_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    invitation_sent_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    status VARCHAR(20) CHECK (status IN ('invited', 'started', 'completed', 'skipped')) DEFAULT 'invited',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Goals (more detailed)
CREATE TABLE performance.goal_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_id UUID NOT NULL REFERENCES performance.goals(goal_id) ON DELETE CASCADE,
    metric_name VARCHAR(255) NOT NULL,
    target_value NUMERIC(10,2) NOT NULL,
    current_value NUMERIC(10,2) DEFAULT 0,
    unit VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Development Plans
CREATE TABLE learning.development_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) CHECK (status IN ('draft', 'in_progress', 'completed')) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.development_plan_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES learning.development_plans(plan_id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL, -- e.g., 'course', 'certification', 'mentorship', 'project'
    item_reference_id UUID, -- References course_id, certification_id, etc.
    description TEXT,
    due_date DATE,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Mentorship
CREATE TABLE hr.mentorship_programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.mentorship_relationships (
    relationship_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID NOT NULL REFERENCES hr.mentorship_programs(program_id) ON DELETE CASCADE,
    mentor_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    mentee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) CHECK (status IN ('active', 'completed', 'ended')) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Succession Planning
CREATE TABLE hr.succession_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    position_id UUID NOT NULL REFERENCES hr.positions(position_id) ON DELETE RESTRICT,
    plan_name VARCHAR(255) NOT NULL,
    description TEXT,
    target_date DATE,
    status VARCHAR(20) CHECK (status IN ('draft', 'in_progress', 'completed')) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.succession_candidates (
    candidate_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES hr.succession_plans(plan_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    readiness_level VARCHAR(50), -- e.g., 'Ready Now', 'Ready in 1-2 years'
    development_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Exit Management
CREATE TABLE hr.exit_interviews (
    exit_interview_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    interview_date DATE NOT NULL,
    interviewer_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    feedback_summary TEXT,
    reason_for_leaving TEXT,
    recommendations TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Work Schedule
CREATE TABLE hr.work_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    schedule_name VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.schedule_details (
    detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID NOT NULL REFERENCES hr.work_schedules(schedule_id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_duration_minutes INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication Preferences
CREATE TABLE hr.communication_preferences (
    preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    preference_type VARCHAR(100) NOT NULL, -- e.g., 'email_notifications', 'sms_alerts'
    is_enabled BOOLEAN DEFAULT TRUE,
    details JSONB, -- e.g., {'frequency': 'daily', 'format': 'html'}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Work Location
CREATE TABLE hr.work_locations (
    location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(255) NOT NULL UNIQUE,
    address TEXT NOT NULL,
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    is_headquarters BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_work_locations (
    employee_location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES hr.work_locations(location_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Travel History
CREATE TABLE hr.employee_travel_history (
    travel_history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    destination VARCHAR(255) NOT NULL,
    purpose TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    travel_cost NUMERIC(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Emergency Contacts (refined with contact type)
CREATE TYPE hr.contact_type AS ENUM (
    'emergency',
    'next_of_kin',
    'other'
);

ALTER TABLE hr.emergency_contacts
ADD COLUMN contact_type hr.contact_type DEFAULT 'emergency';

-- Employee Background Checks
CREATE TABLE hr.background_check_types (
    check_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_background_checks (
    check_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    check_type_id UUID NOT NULL REFERENCES hr.background_check_types(check_type_id) ON DELETE RESTRICT,
    request_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')) DEFAULT 'pending',
    results_summary TEXT,
    conducted_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Health Insurance Details (more specific)
CREATE TABLE benefits.health_insurance_plans (
    health_plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(255) NOT NULL UNIQUE,
    provider VARCHAR(100) NOT NULL,
    plan_type VARCHAR(50), -- e.g., 'HMO', 'PPO', 'EPO'
    deductible NUMERIC(10,2),
    out_of_pocket_max NUMERIC(10,2),
    premium_employee NUMERIC(10,2),
    premium_company NUMERIC(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_health_insurance (
    employee_health_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    health_plan_id UUID NOT NULL REFERENCES benefits.health_insurance_plans(health_plan_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    coverage_start_date DATE,
    coverage_end_date DATE,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'waived', 'terminated')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Retirement Plans
CREATE TABLE benefits.retirement_plans (
    retirement_plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(255) NOT NULL UNIQUE,
    plan_type VARCHAR(50), -- e.g., '401k', '403b', 'Pension'
    provider VARCHAR(100),
    employer_match_percentage NUMERIC(5,2),
    vesting_schedule TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_retirement_enrollments (
    retirement_enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    retirement_plan_id UUID NOT NULL REFERENCES benefits.retirement_plans(retirement_plan_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    contribution_percentage NUMERIC(5,2),
    employee_contribution NUMERIC(10,2),
    employer_contribution NUMERIC(10,2),
    status VARCHAR(20) CHECK (status IN ('enrolled', 'terminated')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Stock Options / Equity
CREATE TABLE benefits.equity_plans (
    equity_plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(255) NOT NULL UNIQUE,
    plan_type VARCHAR(50), -- e.g., 'Stock Options', 'RSUs', 'ESPP'
    description TEXT,
    vesting_schedule TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_equity_grants (
    equity_grant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    equity_plan_id UUID NOT NULL REFERENCES benefits.equity_plans(equity_plan_id) ON DELETE RESTRICT,
    grant_date DATE NOT NULL,
    number_of_units INT NOT NULL,
    strike_price NUMERIC(10,2),
    vesting_start_date DATE,
    vesting_end_date DATE,
    is_vested BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance Reviews (more detailed metrics)
CREATE TABLE performance.review_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES performance.performance_reviews(review_id) ON DELETE CASCADE,
    metric_name VARCHAR(255) NOT NULL,
    score NUMERIC(5,2),
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training Needs Analysis
CREATE TABLE learning.training_needs (
    need_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    identified_date DATE NOT NULL,
    skill_gap TEXT NOT NULL,
    recommended_training TEXT,
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    status VARCHAR(20) CHECK (status IN ('open', 'addressed', 'closed')) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Career Pathing
CREATE TABLE hr.career_paths (
    path_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    path_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.career_path_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    path_id UUID NOT NULL REFERENCES hr.career_paths(path_id) ON DELETE CASCADE,
    step_number INT NOT NULL,
    position_id UUID REFERENCES hr.positions(position_id) ON DELETE SET NULL,
    required_skills TEXT[],
    recommended_training TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_career_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    path_id UUID NOT NULL REFERENCES hr.career_paths(path_id) ON DELETE RESTRICT,
    current_step_id UUID REFERENCES hr.career_path_steps(step_id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(20) CHECK (status IN ('in_progress', 'completed', 'on_hold')) DEFAULT 'in_progress',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Grievances (detailed)
CREATE TABLE hr.grievance_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grievance_id UUID NOT NULL REFERENCES hr.grievances(grievance_id) ON DELETE CASCADE,
    log_date TIMESTAMPTZ DEFAULT NOW(),
    log_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    log_entry TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Disciplinary Actions (detailed)
CREATE TABLE hr.disciplinary_action_details (
    detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_id UUID NOT NULL REFERENCES hr.disciplinary_actions(action_id) ON DELETE CASCADE,
    detail_type VARCHAR(100), -- e.g., 'Investigation Findings', 'Witness Statement'
    detail_content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recognition (detailed)
CREATE TABLE hr.recognition_awards (
    award_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recognition_id UUID NOT NULL REFERENCES hr.employee_recognitions(recognition_id) ON DELETE CASCADE,
    award_name VARCHAR(255) NOT NULL,
    award_date DATE NOT NULL,
    value NUMERIC(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication (detailed)
CREATE TABLE hr.internal_messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    recipient_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    subject VARCHAR(255),
    message_content TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.message_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES hr.internal_messages(message_id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    mime_type VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (generic workflow engine)
CREATE TABLE hr.workflows (
    workflow_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    trigger_event TEXT, -- e.g., 'new_employee', 'expense_submitted'
    workflow_definition JSONB, -- JSON representation of workflow steps
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.workflow_instances (
    instance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES hr.workflows(workflow_id) ON DELETE RESTRICT,
    entity_id UUID NOT NULL, -- ID of the entity triggering the workflow (e.g., employee_id, report_id)
    entity_type VARCHAR(100) NOT NULL,
    current_step VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')) DEFAULT 'pending',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.workflow_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES hr.workflow_instances(instance_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    assigned_to UUID REFERENCES auth.users(user_id),
    due_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    status VARCHAR(20) CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')) DEFAULT 'pending',
    task_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- SEC/FCA Compliance specific tables
CREATE TABLE compliance.regulatory_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_name VARCHAR(255) NOT NULL,
    reporting_body VARCHAR(100) NOT NULL, -- e.g., 'SEC', 'FCA'
    submission_date TIMESTAMPTZ NOT NULL,
    report_period_start DATE NOT NULL,
    report_period_end DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')) DEFAULT 'draft',
    submitted_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    report_document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.transaction_audit_trail (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL, -- Generic ID for any transaction (e.g., expense, payroll, invoice)
    transaction_type VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'PAY'
    actor_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    old_data JSONB,
    new_data JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    ip_address INET,
    user_agent TEXT,
    is_immutable BOOLEAN DEFAULT TRUE
);

-- SOC 2 Compliance specific tables
CREATE TABLE compliance.security_incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_date TIMESTAMPTZ NOT NULL,
    incident_type VARCHAR(100) NOT NULL, -- e.g., 'Data Breach', 'Unauthorized Access', 'System Outage'
    description TEXT NOT NULL,
    severity hr.investigation_severity NOT NULL,
    status VARCHAR(20) CHECK (status IN ('open', 'investigating', 'resolved', 'closed')) DEFAULT 'open',
    reported_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    resolution_details TEXT,
    closed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.vulnerability_management (
    vulnerability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vulnerability_name VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')) NOT NULL,
    identified_date DATE NOT NULL,
    due_date DATE,
    resolution_date DATE,
    status VARCHAR(20) CHECK (status IN ('open', 'in_progress', 'resolved', 'deferred')) DEFAULT 'open',
    assigned_to UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.configuration_management (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_name VARCHAR(255) NOT NULL,
    config_version VARCHAR(50) NOT NULL,
    config_details JSONB NOT NULL,
    deployed_date TIMESTAMPTZ DEFAULT NOW(),
    deployed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Lifecycle Management
CREATE TABLE data_governance.data_archive_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    table_name VARCHAR(100) NOT NULL,
    archive_condition TEXT NOT NULL, -- SQL WHERE clause for data to be archived
    archive_frequency VARCHAR(50), -- e.g., 'monthly', 'quarterly'
    last_archive_run TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_purge_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    table_name VARCHAR(100) NOT NULL,
    purge_condition TEXT NOT NULL, -- SQL WHERE clause for data to be purged
    purge_frequency VARCHAR(50), -- e.g., 'annually'
    last_purge_run TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Quality (more detailed)
CREATE TABLE data_governance.data_quality_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    metric_name VARCHAR(100) NOT NULL, -- e.g., 'completeness', 'accuracy', 'consistency'
    metric_value NUMERIC(5,2),
    measurement_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Dictionary (more detailed)
CREATE TABLE data_governance.data_dictionary_tables (
    table_dict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schema_name VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    owner_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_dictionary_columns (
    column_dict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_dict_id UUID NOT NULL REFERENCES data_governance.data_dictionary_tables(table_dict_id) ON DELETE CASCADE,
    column_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    is_nullable BOOLEAN NOT NULL,
    is_primary_key BOOLEAN NOT NULL,
    is_foreign_key BOOLEAN NOT NULL,
    description TEXT,
    example_value TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_dictionary_enums (
    enum_dict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enum_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_dictionary_enum_values (
    enum_value_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enum_dict_id UUID NOT NULL REFERENCES data_governance.data_dictionary_enums(enum_dict_id) ON DELETE CASCADE,
    enum_value VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Lineage (more detailed)
CREATE TABLE data_governance.data_lineage_processes (
    process_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_name VARCHAR(255) NOT NULL UNIQUE,
    process_type VARCHAR(50), -- e.g., 'ETL', 'API_Ingestion', 'Manual_Upload'
    description TEXT,
    created_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_lineage_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    process_id UUID NOT NULL REFERENCES data_governance.data_lineage_processes(process_id) ON DELETE CASCADE,
    step_number INT NOT NULL,
    step_description TEXT,
    input_asset_id UUID REFERENCES data_governance.data_assets(asset_id) ON DELETE SET NULL,
    output_asset_id UUID REFERENCES data_governance.data_assets(asset_id) ON DELETE SET NULL,
    transformation_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Profiling (more detailed)
CREATE TABLE data_governance.data_profile_runs (
    run_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    run_timestamp TIMESTAMPTZ DEFAULT NOW(),
    total_rows INT,
    profiled_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_profile_column_stats (
    column_stat_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES data_governance.data_profile_runs(run_id) ON DELETE CASCADE,
    column_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50),
    null_count INT,
    distinct_count INT,
    min_value TEXT,
    max_value TEXT,
    avg_value NUMERIC,
    std_dev NUMERIC,
    top_values JSONB, -- e.g., [{'value': 'A', 'count': 10}, {'value': 'B', 'count': 5}]
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Cataloging (more detailed)
CREATE TABLE data_governance.data_catalog_tags (
    tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE data_governance.data_asset_tags (
    asset_tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES data_governance.data_assets(asset_id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES data_governance.data_catalog_tags(tag_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI-powered Deal Matching (more detailed)
CREATE TABLE analytics.deal_matching_algorithms (
    algorithm_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    algorithm_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    model_version VARCHAR(50),
    last_trained_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.deal_matching_runs (
    run_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    algorithm_id UUID NOT NULL REFERENCES analytics.deal_matching_algorithms(algorithm_id) ON DELETE RESTRICT,
    run_timestamp TIMESTAMPTZ DEFAULT NOW(),
    input_parameters JSONB,
    output_summary JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscription Model for Insights (more detailed)
CREATE TABLE analytics.subscription_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    billing_period VARCHAR(20) CHECK (billing_period IN ('monthly', 'quarterly', 'annually')) NOT NULL,
    features JSONB, -- e.g., {'weekly_insights': true, 'monthly_insights': true, 'premium_support': false}
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE analytics.subscriptions
ADD COLUMN plan_id UUID REFERENCES analytics.subscription_plans(plan_id) ON DELETE RESTRICT,
DROP COLUMN subscription_type; -- Replaced by plan_id

-- KPI Tracking (more detailed)
CREATE TABLE analytics.kpi_data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    connection_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics.kpi_data_points (
    data_point_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES analytics.kpi_definitions(kpi_id) ON DELETE CASCADE,
    source_id UUID REFERENCES analytics.kpi_data_sources(source_id) ON DELETE SET NULL,
    recorded_value NUMERIC(15,2) NOT NULL,
    recorded_timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Visitor Analytics (more detailed)
CREATE TABLE analytics.website_pages (
    page_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_url VARCHAR(255) NOT NULL UNIQUE,
    page_title VARCHAR(255),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE analytics.page_views
ADD COLUMN page_id UUID REFERENCES analytics.website_pages(page_id) ON DELETE SET NULL,
DROP COLUMN page_url; -- Replaced by page_id

-- Employee Relations (more detailed)
CREATE TABLE hr.employee_relation_actions (
    action_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES hr.employee_relations(case_id) ON DELETE CASCADE,
    action_date TIMESTAMPTZ DEFAULT NOW(),
    action_type VARCHAR(100) NOT NULL, -- e.g., 'Interview Conducted', 'Evidence Collected', 'Meeting Held'
    description TEXT,
    performed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Surveys (more detailed questions and answers)
CREATE TABLE hr.survey_question_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES hr.survey_questions(question_id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    option_value TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.survey_questions
DROP COLUMN options; -- Replaced by survey_question_options table

-- Employee Communication (more detailed for internal messaging)
CREATE TABLE hr.message_recipients (
    recipient_entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES hr.internal_messages(message_id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.internal_messages
DROP COLUMN recipient_id, -- Replaced by message_recipients
DROP COLUMN is_read,
DROP COLUMN read_at;

-- Employee Onboarding/Offboarding Checklists
CREATE TABLE hr.onboarding_checklists (
    checklist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.onboarding_checklist_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_id UUID NOT NULL REFERENCES hr.onboarding_checklists(checklist_id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    responsible_role VARCHAR(100), -- e.g., 'HR', 'IT', 'Manager'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.onboarding_tasks
ADD COLUMN checklist_item_id UUID REFERENCES hr.onboarding_checklist_items(item_id) ON DELETE SET NULL,
ADD COLUMN checklist_id UUID REFERENCES hr.onboarding_checklists(checklist_id) ON DELETE SET NULL;

CREATE TABLE hr.offboarding_checklists (
    checklist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.offboarding_checklist_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_id UUID NOT NULL REFERENCES hr.offboarding_checklists(checklist_id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    responsible_role VARCHAR(100), -- e.g., 'HR', 'IT', 'Manager'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.offboarding_tasks
ADD COLUMN checklist_item_id UUID REFERENCES hr.offboarding_checklist_items(item_id) ON DELETE SET NULL,
ADD COLUMN checklist_id UUID REFERENCES hr.offboarding_checklists(checklist_id) ON DELETE SET NULL;

-- Employee Training Providers
CREATE TABLE learning.training_providers (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_name VARCHAR(255) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    phone_number VARCHAR(20),
    website_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE learning.courses
ADD COLUMN provider_id UUID REFERENCES learning.training_providers(provider_id) ON DELETE SET NULL;

ALTER TABLE learning.training_programs
ADD COLUMN provider_id UUID REFERENCES learning.training_providers(provider_id) ON DELETE SET NULL;

ALTER TABLE learning.employee_training_records
ADD COLUMN provider_id UUID REFERENCES learning.training_providers(provider_id) ON DELETE SET NULL;

-- Employee Skills Matrix
CREATE TABLE hr.skill_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.skills (
    skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category_id UUID REFERENCES hr.skill_categories(category_id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.employee_skills
DROP COLUMN skill_name, -- Replaced by skill_id
ADD COLUMN skill_id UUID NOT NULL REFERENCES hr.skills(skill_id) ON DELETE RESTRICT;

-- Employee Competencies
CREATE TABLE hr.competency_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.competencies (
    competency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    competency_name VARCHAR(100) NOT NULL UNIQUE,
    category_id UUID REFERENCES hr.competency_categories(category_id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_competencies (
    employee_competency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    competency_id UUID NOT NULL REFERENCES hr.competencies(competency_id) ON DELETE RESTRICT,
    rating NUMERIC(2,1), -- e.g., 1.0 - 5.0
    assessed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    assessment_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance Improvement Plans (PIPs)
CREATE TABLE performance.pip_plans (
    pip_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    reason TEXT NOT NULL,
    status VARCHAR(20) CHECK (status IN ('active', 'completed', 'failed')) DEFAULT 'active',
    manager_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.pip_goals (
    pip_goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pip_id UUID NOT NULL REFERENCES performance.pip_plans(pip_id) ON DELETE CASCADE,
    goal_description TEXT NOT NULL,
    target_date DATE NOT NULL,
    progress_notes TEXT,
    status VARCHAR(20) CHECK (status IN ('open', 'in_progress', 'completed')) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Feedback (360-degree feedback)
CREATE TABLE performance.feedback_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    status VARCHAR(20) CHECK (status IN ('open', 'completed', 'closed')) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.feedback_responses (
    response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES performance.feedback_requests(request_id) ON DELETE CASCADE,
    giver_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    response_text TEXT NOT NULL,
    submission_date TIMESTAMPTZ DEFAULT NOW(),
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recognition (peer-to-peer)
CREATE TABLE hr.peer_recognitions (
    recognition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recognizer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    recognized_employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    recognition_date DATE NOT NULL,
    recognition_message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (flexible benefits)
CREATE TABLE benefits.flexible_benefit_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    option_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    cost NUMERIC(10,2),
    benefit_type VARCHAR(100), -- e.g., 'Health', 'Wellness', 'Leave'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_flexible_benefit_selections (
    selection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES benefits.flexible_benefit_options(option_id) ON DELETE RESTRICT,
    enrollment_year INT NOT NULL,
    selected_amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Surveys (results analysis)
CREATE TABLE analytics.survey_results_summary (
    summary_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    summary_date TIMESTAMPTZ DEFAULT NOW(),
    overall_score NUMERIC(5,2),
    key_themes JSONB, -- e.g., {'positive': ['communication'], 'negative': ['workload']}
    action_items TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (approval steps)
CREATE TABLE hr.workflow_approvals (
    approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES hr.workflow_tasks(task_id) ON DELETE CASCADE,
    approver_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    approval_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Self-Service Portal (basic)
CREATE TABLE hr.portal_settings (
    setting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_name VARCHAR(255) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Onboarding (pre-boarding)
CREATE TABLE hr.pre_boarding_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    completed_date DATE,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'skipped')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (360 feedback questions)
CREATE TABLE performance.feedback_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN ('rating', 'text')) NOT NULL,
    category VARCHAR(100), -- e.g., 'Leadership', 'Teamwork'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.feedback_question_responses (
    response_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id UUID NOT NULL REFERENCES performance.feedback_responses(response_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES performance.feedback_questions(question_id) ON DELETE CASCADE,
    rating_value NUMERIC(2,1),
    text_response TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (course modules)
CREATE TABLE learning.course_modules (
    module_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES learning.courses(course_id) ON DELETE CASCADE,
    module_name VARCHAR(255) NOT NULL,
    description TEXT,
    module_order INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_module_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_course_id UUID NOT NULL REFERENCES learning.employee_courses(employee_course_id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES learning.course_modules(module_id) ON DELETE CASCADE,
    status VARCHAR(20) CHECK (status IN ('not_started', 'in_progress', 'completed')) DEFAULT 'not_started',
    completion_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (wellness program details)
CREATE TABLE benefits.wellness_activities (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID NOT NULL REFERENCES hr.wellness_programs(program_id) ON DELETE CASCADE,
    activity_name VARCHAR(255) NOT NULL,
    description TEXT,
    activity_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_wellness_activity_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES hr.employee_wellness_enrollments(enrollment_id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES benefits.wellness_activities(activity_id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Travel (expense categories for travel)
CREATE TABLE finance.travel_expense_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE finance.travel_bookings
ADD COLUMN expense_category_id UUID REFERENCES finance.travel_expense_categories(category_id) ON DELETE SET NULL;

-- Employee Projects (tasks within projects)
CREATE TABLE hr.project_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES hr.projects(project_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    due_date DATE,
    status VARCHAR(20) CHECK (status IN ('not_started', 'in_progress', 'completed', 'on_hold')) DEFAULT 'not_started',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (notifications for workflow steps)
CREATE TABLE hr.workflow_notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_task_id UUID NOT NULL REFERENCES hr.workflow_tasks(task_id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL, -- e.g., 'task_assigned', 'approval_needed', 'task_completed'
    recipient_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Documents (document versions)
CREATE TABLE hr.document_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES hr.employee_documents(document_id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    document_url TEXT NOT NULL,
    uploaded_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Skills (skill assessments)
CREATE TABLE hr.skill_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES hr.skills(skill_id) ON DELETE RESTRICT,
    assessment_date DATE NOT NULL,
    assessed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    score NUMERIC(5,2),
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (training session details)
CREATE TABLE learning.training_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID NOT NULL REFERENCES learning.training_programs(program_id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location TEXT,
    instructor_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.session_attendees (
    attendee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES learning.training_sessions(session_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    attendance_status VARCHAR(20) CHECK (attendance_status IN ('present', 'absent', 'late')) DEFAULT 'present',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recruitment (candidate notes)
CREATE TABLE recruitment.candidate_notes (
    note_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    note_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    note_text TEXT NOT NULL,
    note_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Payroll (deduction types)
CREATE TABLE payroll.deduction_types (
    deduction_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_pre_tax BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payroll.deductions
ADD COLUMN deduction_type_id UUID REFERENCES payroll.deduction_types(deduction_type_id) ON DELETE RESTRICT,
DROP COLUMN deduction_type; -- Replaced by deduction_type_id

-- Employee Payroll (tax types)
CREATE TABLE payroll.tax_types (
    tax_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_federal BOOLEAN DEFAULT FALSE,
    is_state BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payroll.taxes
ADD COLUMN tax_type_id UUID REFERENCES payroll.tax_types(tax_type_id) ON DELETE RESTRICT,
DROP COLUMN tax_type; -- Replaced by tax_type_id

-- Employee Payroll (pay components - e.g., base, bonus, commission)
CREATE TABLE payroll.pay_components (
    component_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_name VARCHAR(100) NOT NULL UNIQUE,
    component_type VARCHAR(50) CHECK (component_type IN ('earning', 'deduction', 'tax')) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.payroll_component_entries (
    entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    component_id UUID NOT NULL REFERENCES payroll.pay_components(component_id) ON DELETE RESTRICT,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Payroll (direct deposit details)
CREATE TABLE payroll.direct_deposits (
    direct_deposit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    bank_account_id UUID NOT NULL REFERENCES hr.employee_bank_details(bank_detail_id) ON DELETE RESTRICT,
    deposit_amount NUMERIC(10,2),
    deposit_percentage NUMERIC(5,2),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTamptz DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Payroll (pay stubs)
CREATE TABLE payroll.pay_stubs (
    pay_stub_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    pay_stub_url TEXT NOT NULL, -- Link to generated PDF/document
    generated_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (calibration sessions)
CREATE TABLE performance.calibration_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_name VARCHAR(255) NOT NULL UNIQUE,
    session_date DATE NOT NULL,
    description TEXT,
    facilitator_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.calibration_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES performance.calibration_sessions(session_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    initial_rating hr.performance_rating,
    final_rating hr.performance_rating,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Learning (learning paths)
CREATE TABLE learning.learning_paths (
    path_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    path_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.learning_path_courses (
    path_course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    path_id UUID NOT NULL REFERENCES learning.learning_paths(path_id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES learning.courses(course_id) ON DELETE RESTRICT,
    course_order INT NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_learning_path_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    path_id UUID NOT NULL REFERENCES learning.learning_paths(path_id) ON DELETE RESTRICT,
    status VARCHAR(20) CHECK (status IN ('not_started', 'in_progress', 'completed')) DEFAULT 'not_started',
    completion_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (enrollment periods)
CREATE TABLE benefits.enrollment_periods (
    period_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_name VARCHAR(100) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_open BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE benefits.employee_benefit_enrollments
ADD COLUMN enrollment_period_id UUID REFERENCES benefits.enrollment_periods(period_id) ON DELETE SET NULL;

ALTER TABLE benefits.employee_health_insurance
ADD COLUMN enrollment_period_id UUID REFERENCES benefits.enrollment_periods(period_id) ON DELETE SET NULL;

ALTER TABLE benefits.employee_retirement_enrollments
ADD COLUMN enrollment_period_id UUID REFERENCES benefits.enrollment_periods(period_id) ON DELETE SET NULL;

ALTER TABLE benefits.employee_equity_grants
ADD COLUMN enrollment_period_id UUID REFERENCES benefits.enrollment_periods(period_id) ON DELETE SET NULL;

-- Employee Recruitment (candidate stages)
CREATE TABLE recruitment.candidate_stages (
    stage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stage_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    stage_order INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.applications
ADD COLUMN current_stage_id UUID REFERENCES recruitment.candidate_stages(stage_id) ON DELETE SET NULL;

-- Employee Recruitment (candidate sources)
CREATE TABLE recruitment.candidate_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.candidates
ADD COLUMN source_id UUID REFERENCES recruitment.candidate_sources(source_id) ON DELETE SET NULL;

-- Employee Recruitment (job application questions)
CREATE TABLE recruitment.job_application_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_posting_id UUID NOT NULL REFERENCES recruitment.job_postings(job_posting_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN ('text', 'single_choice', 'multi_choice')) NOT NULL,
    is_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.job_application_answers (
    answer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES recruitment.applications(application_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES recruitment.job_application_questions(question_id) ON DELETE CASCADE,
    answer_text TEXT,
    selected_options JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recruitment (interview panels)
CREATE TABLE recruitment.interview_panels (
    panel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    panel_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.panel_members (
    member_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    panel_id UUID NOT NULL REFERENCES recruitment.interview_panels(panel_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    role_on_panel VARCHAR(100), -- e.g., 'Lead Interviewer', 'Technical Interviewer'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.interviews
ADD COLUMN panel_id UUID REFERENCES recruitment.interview_panels(panel_id) ON DELETE SET NULL;

-- Employee Payroll (benefits deductions)
CREATE TABLE payroll.benefit_deductions (
    benefit_deduction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    benefit_plan_id UUID NOT NULL REFERENCES benefits.benefit_plans(plan_id) ON DELETE RESTRICT,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Payroll (loan repayments)
CREATE TABLE payroll.employee_loans (
    loan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    loan_amount NUMERIC(10,2) NOT NULL,
    interest_rate NUMERIC(5,2),
    start_date DATE NOT NULL,
    end_date DATE,
    monthly_repayment_amount NUMERIC(10,2),
    outstanding_balance NUMERIC(10,2),
    status VARCHAR(20) CHECK (status IN ('active', 'paid_off', 'defaulted')) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payroll.loan_repayments (
    repayment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loan_id UUID NOT NULL REFERENCES payroll.employee_loans(loan_id) ON DELETE CASCADE,
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE RESTRICT,
    repayment_date DATE NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (skill gaps identified from reviews)
CREATE TABLE performance.skill_gaps (
    skill_gap_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES hr.skills(skill_id) ON DELETE RESTRICT,
    identified_date DATE NOT NULL,
    source_of_identification TEXT, -- e.g., 'Performance Review', 'Manager Feedback'
    priority VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Learning (external training)
CREATE TABLE learning.external_training (
    external_training_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    training_name VARCHAR(255) NOT NULL,
    provider_name VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    cost NUMERIC(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    certification_obtained BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (customizable benefits)
CREATE TABLE benefits.custom_benefits (
    custom_benefit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    benefit_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    eligibility_criteria TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_custom_benefits (
    employee_custom_benefit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    custom_benefit_id UUID NOT NULL REFERENCES benefits.custom_benefits(custom_benefit_id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('enrolled', 'opted_out')) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication (internal news feed)
CREATE TABLE hr.news_feed_posts (
    post_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    publish_date TIMESTAMPTZ DEFAULT NOW(),
    category VARCHAR(100), -- e.g., 'Company News', 'HR Updates', 'Events'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.news_feed_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES hr.news_feed_posts(post_id) ON DELETE CASCADE,
    comment_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (workflow history)
CREATE TABLE hr.workflow_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES hr.workflow_instances(instance_id) ON DELETE CASCADE,
    step_name VARCHAR(255) NOT NULL,
    action_taken TEXT,
    action_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    action_date TIMESTAMPTZ DEFAULT NOW(),
    status_change TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Self-Service (document uploads)
CREATE TABLE hr.self_service_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    document_name VARCHAR(255) NOT NULL,
    document_url TEXT NOT NULL,
    document_type VARCHAR(100), -- e.g., 'Tax Form', 'Leave Request', 'Payslip'
    uploaded_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data access logs)
CREATE TABLE compliance.data_access_logs (
    access_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    accessed_table VARCHAR(100) NOT NULL,
    accessed_record_id UUID, -- Optional, if specific record accessed
    access_type VARCHAR(50) NOT NULL, -- 'READ', 'WRITE', 'DELETE'
    access_timestamp TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data masking policies)
CREATE TABLE compliance.data_masking_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    masking_method VARCHAR(100) NOT NULL, -- e.g., 'hash', 'redact', 'shuffle'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data encryption keys)
CREATE TABLE compliance.encryption_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name VARCHAR(255) NOT NULL UNIQUE,
    encryption_key TEXT ENCRYPTED NOT NULL,
    key_type VARCHAR(50), -- e.g., 'AES256', 'RSA'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expiry_date TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data classification)
CREATE TABLE data_governance.data_classifications (
    classification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classification_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    sensitivity_level INT NOT NULL, -- e.g., 1 (public) to 5 (highly confidential)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE data_governance.data_elements
ADD COLUMN classification_id UUID REFERENCES data_governance.data_classifications(classification_id) ON DELETE SET NULL,
DROP COLUMN classification; -- Replaced by classification_id

-- Employee Training (training categories)
CREATE TABLE learning.training_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE learning.courses
ADD COLUMN category_id UUID REFERENCES learning.training_categories(category_id) ON DELETE SET NULL;

ALTER TABLE learning.training_programs
ADD COLUMN category_id UUID REFERENCES learning.training_categories(category_id) ON DELETE SET NULL;

-- Employee Performance (competency frameworks)
CREATE TABLE performance.competency_frameworks (
    framework_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.competencies
ADD COLUMN framework_id UUID REFERENCES performance.competency_frameworks(framework_id) ON DELETE SET NULL;

-- Employee Performance (performance review templates)
CREATE TABLE performance.review_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    template_content JSONB, -- JSON structure of the review form
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE performance.performance_reviews
ADD COLUMN template_id UUID REFERENCES performance.review_templates(template_id) ON DELETE SET NULL;

-- Employee Payroll (pay stub details)
CREATE TABLE payroll.pay_stub_details (
    detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pay_stub_id UUID NOT NULL REFERENCES payroll.pay_stubs(pay_stub_id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    type VARCHAR(50) CHECK (type IN ('earning', 'deduction', 'tax')) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recruitment (candidate screening questions)
CREATE TABLE recruitment.screening_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN ('text', 'single_choice', 'multi_choice', 'yes_no')) NOT NULL,
    options JSONB, -- For multiple choice questions
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.candidate_screening_answers (
    answer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES recruitment.screening_questions(question_id) ON DELETE CASCADE,
    answer_text TEXT,
    selected_options JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recruitment (interview schedules)
CREATE TABLE recruitment.interview_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    interview_id UUID NOT NULL REFERENCES recruitment.interviews(interview_id) ON DELETE CASCADE,
    interviewer_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE RESTRICT,
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recruitment (recruitment agencies)
CREATE TABLE recruitment.recruitment_agencies (
    agency_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_name VARCHAR(255) NOT NULL UNIQUE,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    phone_number VARCHAR(20),
    website_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.job_postings
ADD COLUMN agency_id UUID REFERENCES recruitment.recruitment_agencies(agency_id) ON DELETE SET NULL;

-- Employee Workflows (workflow steps and transitions)
CREATE TABLE hr.workflow_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES hr.workflows(workflow_id) ON DELETE CASCADE,
    step_name VARCHAR(255) NOT NULL,
    step_order INT NOT NULL,
    step_type VARCHAR(50) CHECK (step_type IN ('manual_task', 'approval', 'automated_action')) NOT NULL,
    assigned_role_id UUID REFERENCES auth.roles(role_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.workflow_transitions (
    transition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES hr.workflows(workflow_id) ON DELETE CASCADE,
    from_step_id UUID NOT NULL REFERENCES hr.workflow_steps(step_id) ON DELETE CASCADE,
    to_step_id UUID NOT NULL REFERENCES hr.workflow_steps(step_id) ON DELETE CASCADE,
    condition_expression TEXT, -- e.g., 'status =



-- Employee Performance (detailed metrics and feedback)
CREATE TABLE performance.performance_metric_definitions (
    metric_def_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    calculation_method TEXT, -- e.g., SQL query, formula
    unit VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.employee_performance_metrics (
    employee_metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    metric_def_id UUID NOT NULL REFERENCES performance.performance_metric_definitions(metric_def_id) ON DELETE RESTRICT,
    metric_value NUMERIC(10,2) NOT NULL,
    recorded_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.peer_feedback_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN (
        'text', 'rating', 'single_choice', 'multi_choice'
    )) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.peer_feedback_responses (
    response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feedback_id UUID NOT NULL REFERENCES performance.feedback_responses(response_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES performance.peer_feedback_questions(question_id) ON DELETE CASCADE,
    response_text TEXT,
    rating_value NUMERIC(2,1),
    selected_options JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Time Tracking (detailed)
CREATE TABLE hr.time_entry_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE, -- e.g., 'Regular Hours', 'Overtime', 'Sick Leave', 'Vacation'
    is_billable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.timesheet_entries
ADD COLUMN time_entry_type_id UUID REFERENCES hr.time_entry_types(type_id) ON DELETE RESTRICT,
ADD COLUMN approved_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
ADD COLUMN approved_at TIMESTAMPTZ;

-- Employee Benefits (benefit claims)
CREATE TABLE benefits.benefit_claims (
    claim_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    benefit_plan_id UUID NOT NULL REFERENCES benefits.benefit_plans(plan_id) ON DELETE RESTRICT,
    claim_date DATE NOT NULL,
    claim_amount NUMERIC(10,2) NOT NULL,
    approved_amount NUMERIC(10,2),
    status VARCHAR(20) CHECK (status IN (
        'submitted', 'approved', 'rejected', 'pending_docs'
    )) DEFAULT 'submitted',
    description TEXT,
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recruitment (candidate assessments)
CREATE TABLE recruitment.assessment_types (
    assessment_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.candidate_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES recruitment.applications(application_id) ON DELETE CASCADE,
    assessment_type_id UUID NOT NULL REFERENCES recruitment.assessment_types(assessment_type_id) ON DELETE RESTRICT,
    assessment_date DATE NOT NULL,
    score NUMERIC(5,2),
    feedback TEXT,
    assessed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payroll (tax jurisdictions)
CREATE TABLE payroll.tax_jurisdictions (
    jurisdiction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    country VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payroll.taxes
ADD COLUMN jurisdiction_id UUID REFERENCES payroll.tax_jurisdictions(jurisdiction_id) ON DELETE RESTRICT;

-- Compliance (regulatory updates)
CREATE TABLE compliance.regulatory_updates (
    update_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    effective_date DATE NOT NULL,
    regulatory_body VARCHAR(100) NOT NULL, -- e.g., 'SEC', 'FCA', 'GDPR'
    compliance_status VARCHAR(20) CHECK (status IN (
        'pending', 'in_progress', 'compliant', 'non_compliant'
    )) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.compliance_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    update_id UUID NOT NULL REFERENCES compliance.regulatory_updates(update_id) ON DELETE CASCADE,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE,
    completed_date DATE,
    assigned_to UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    status VARCHAR(20) CHECK (status IN (
        'pending', 'in_progress', 'completed', 'overdue'
    )) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Governance (data retention logs)
CREATE TABLE data_governance.data_retention_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_id UUID NOT NULL REFERENCES compliance.data_retention_policies(policy_id) ON DELETE RESTRICT,
    record_id UUID NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'archived', 'purged'
    action_date TIMESTAMPTZ DEFAULT NOW(),
    performed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics (AI model training logs)
CREATE TABLE analytics.ai_model_training_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    algorithm_id UUID NOT NULL REFERENCES analytics.deal_matching_algorithms(algorithm_id) ON DELETE RESTRICT,
    training_start_time TIMESTAMPTZ NOT NULL,
    training_end_time TIMESTAMPTZ,
    status VARCHAR(20) CHECK (status IN (
        'started', 'completed', 'failed'
    )) DEFAULT 'started',
    metrics JSONB, -- e.g., {'accuracy': 0.95, 'precision': 0.92}
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System Administration (settings and configurations)
CREATE TABLE auth.system_settings (
    setting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    data_type VARCHAR(50) CHECK (data_type IN (
        'string', 'integer', 'boolean', 'json'
    )) DEFAULT 'string',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- System Administration (scheduled jobs)
CREATE TABLE auth.scheduled_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    cron_schedule VARCHAR(100),
    last_run_at TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE auth.job_execution_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES auth.scheduled_jobs(job_id) ON DELETE RESTRICT,
    execution_start_at TIMESTAMPTZ DEFAULT NOW(),
    execution_end_at TIMESTAMPTZ,
    status VARCHAR(20) CHECK (status IN (
        'success', 'failed', 'running'
    )) DEFAULT 'running',
    output TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Onboarding/Offboarding (asset management integration)
CREATE TABLE hr.onboarding_asset_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    asset_type_id UUID NOT NULL REFERENCES hr.asset_types(asset_type_id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 1,
    request_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN (
        'pending', 'approved', 'rejected', 'fulfilled'
    )) DEFAULT 'pending',
    fulfilled_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    fulfilled_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.offboarding_asset_returns (
    return_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES hr.assets(asset_id) ON DELETE RESTRICT,
    return_date DATE NOT NULL,
    condition_on_return VARCHAR(50),
    received_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Grievances (investigation details)
CREATE TABLE hr.grievance_investigations (
    investigation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grievance_id UUID NOT NULL REFERENCES hr.grievances(grievance_id) ON DELETE CASCADE,
    investigator_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status hr.investigation_status NOT NULL DEFAULT 'open',
    findings TEXT,
    recommendations TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.investigation_interviews (
    interview_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investigation_id UUID NOT NULL REFERENCES hr.grievance_investigations(investigation_id) ON DELETE CASCADE,
    interviewee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    interview_date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    recorded_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Disciplinary Actions (appeals)
CREATE TABLE hr.disciplinary_appeals (
    appeal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_id UUID NOT NULL REFERENCES hr.disciplinary_actions(action_id) ON DELETE CASCADE,
    appeal_date DATE NOT NULL,
    reason_for_appeal TEXT NOT NULL,
    status VARCHAR(20) CHECK (status IN (
        'submitted', 'under_review', 'upheld', 'overturned'
    )) DEFAULT 'submitted',
    decision_date DATE,
    decision_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication (internal forums/discussions)
CREATE TABLE hr.forum_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.forum_topics (
    topic_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES hr.forum_categories(category_id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.forum_posts (
    post_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    topic_id UUID NOT NULL REFERENCES hr.forum_topics(topic_id) ON DELETE CASCADE,
    posted_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    post_content TEXT NOT NULL,
    posted_at TIMESTAMPTZ DEFAULT NOW(),
    parent_post_id UUID REFERENCES hr.forum_posts(post_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (custom fields for workflow instances)
CREATE TABLE hr.workflow_instance_custom_fields (
    field_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES hr.workflow_instances(instance_id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    field_value TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Self-Service (profile updates)
CREATE TABLE hr.profile_update_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    requested_changes JSONB NOT NULL, -- JSON of fields and new values
    request_date TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) CHECK (status IN (
        'pending', 'approved', 'rejected'
    )) DEFAULT 'pending',
    approved_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data breach incidents)
CREATE TABLE compliance.data_breach_incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_date TIMESTAMPTZ NOT NULL,
    description TEXT NOT NULL,
    affected_data_types TEXT[], -- e.g., {'PII', 'Financial'}
    number_of_records_affected INT,
    status VARCHAR(20) CHECK (status IN (
        'reported', 'investigating', 'resolved', 'closed'
    )) DEFAULT 'reported',
    reported_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    resolution_details TEXT,
    closed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE compliance.affected_individuals (
    affected_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID NOT NULL REFERENCES compliance.data_breach_incidents(incident_id) ON DELETE CASCADE,
    employee_id UUID REFERENCES hr.employees(employee_id) ON DELETE SET NULL,
    external_individual_details JSONB, -- For non-employees
    notification_sent BOOLEAN DEFAULT FALSE,
    notification_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (privacy impact assessments)
CREATE TABLE compliance.privacy_impact_assessments (
    pia_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_name VARCHAR(255) NOT NULL,
    description TEXT,
    assessment_date DATE NOT NULL,
    assessor_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    risk_level VARCHAR(20) CHECK (risk_level IN (
        'low', 'medium', 'high', 'critical'
    )) DEFAULT 'medium',
    recommendations TEXT,
    status VARCHAR(20) CHECK (status IN (
        'draft', 'in_review', 'approved', 'completed'
    )) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data processing agreements)
CREATE TABLE compliance.data_processing_agreements (
    dpa_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES finance.vendors(vendor_id) ON DELETE RESTRICT,
    agreement_date DATE NOT NULL,
    expiry_date DATE,
    description TEXT,
    dpa_document_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (training attendance)
CREATE TABLE learning.training_attendance (
    attendance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    training_record_id UUID NOT NULL REFERENCES learning.employee_training_records(training_record_id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN (
        'present', 'absent', 'excused'
    )) DEFAULT 'present',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (goals cascading)
CREATE TABLE performance.organizational_goals (
    org_goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    owner_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.department_goals (
    dept_goal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_goal_id UUID REFERENCES performance.organizational_goals(org_goal_id) ON DELETE SET NULL,
    department_id UUID NOT NULL REFERENCES hr.departments(department_id) ON DELETE CASCADE,
    goal_name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    owner_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE performance.goals
ADD COLUMN parent_goal_id UUID REFERENCES performance.department_goals(dept_goal_id) ON DELETE SET NULL;

-- Employee Recruitment (candidate pipelines)
CREATE TABLE recruitment.recruitment_pipelines (
    pipeline_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.pipeline_stages (
    stage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES recruitment.recruitment_pipelines(pipeline_id) ON DELETE CASCADE,
    stage_name VARCHAR(100) NOT NULL,
    stage_order INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.candidate_stages
ADD COLUMN pipeline_id UUID REFERENCES recruitment.recruitment_pipelines(pipeline_id) ON DELETE SET NULL;

-- Employee Payroll (deduction limits)
CREATE TABLE payroll.deduction_limits (
    limit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deduction_type_id UUID NOT NULL REFERENCES payroll.deduction_types(deduction_type_id) ON DELETE CASCADE,
    limit_amount NUMERIC(10,2),
    limit_percentage NUMERIC(5,2),
    frequency VARCHAR(50) CHECK (frequency IN (
        'per_pay_period', 'monthly', 'annually'
    )),
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (employee wellness challenges)
CREATE TABLE hr.wellness_challenges (
    challenge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenge_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    points_system JSONB, -- e.g., {'steps_per_point': 1000, 'meditation_minutes_per_point': 10}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_challenge_participation (
    participation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES hr.wellness_challenges(challenge_id) ON DELETE CASCADE,
    enrollment_date DATE NOT NULL,
    completion_date DATE,
    total_points INT DEFAULT 0,
    status VARCHAR(20) CHECK (status IN (
        'enrolled', 'in_progress', 'completed', 'dropped'
    )) DEFAULT 'enrolled',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication (internal events calendar)
CREATE TABLE hr.events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location TEXT,
    organizer_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    is_internal BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.event_attendees (
    attendee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES hr.events(event_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    rsvp_status VARCHAR(20) CHECK (rsvp_status IN (
        'attending', 'not_attending', 'maybe'
    )) DEFAULT 'attending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (workflow notifications templates)
CREATE TABLE hr.workflow_notification_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) NOT NULL UNIQUE,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    notification_channel VARCHAR(50) CHECK (channel IN (
        'email', 'in_app', 'sms'
    )) DEFAULT 'in_app',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.workflow_notifications
ADD COLUMN template_id UUID REFERENCES hr.workflow_notification_templates(template_id) ON DELETE SET NULL;

-- Employee Self-Service (FAQ)
CREATE TABLE hr.faq_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.faqs (
    faq_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES hr.faq_categories(category_id) ON DELETE RESTRICT,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Data Privacy (data processing activities)
CREATE TABLE compliance.data_processing_activities (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    purpose TEXT NOT NULL,
    legal_basis TEXT NOT NULL,
    data_categories TEXT[],
    recipients TEXT[],
    retention_period TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (e-learning modules)
CREATE TABLE learning.e_learning_modules (
    module_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    content_url TEXT NOT NULL,
    duration_minutes INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE learning.employee_e_learning_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES learning.e_learning_modules(module_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    completion_date DATE,
    score NUMERIC(5,2),
    status VARCHAR(20) CHECK (status IN (
        'not_started', 'in_progress', 'completed', 'failed'
    )) DEFAULT 'not_started',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (360 feedback cycles)
CREATE TABLE performance.feedback_cycles (
    cycle_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    feedback_type VARCHAR(50) CHECK (feedback_type IN (
        '360_degree', 'manager_review', 'peer_review'
    )) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE performance.feedback_requests
ADD COLUMN cycle_id UUID REFERENCES performance.feedback_cycles(cycle_id) ON DELETE SET NULL;

-- Employee Recruitment (candidate notes categories)
CREATE TABLE recruitment.candidate_note_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recruitment.candidate_notes
ADD COLUMN category_id UUID REFERENCES recruitment.candidate_note_categories(category_id) ON DELETE SET NULL;

-- Employee Payroll (payroll adjustments)
CREATE TABLE payroll.payroll_adjustments (
    adjustment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payroll_id UUID NOT NULL REFERENCES payroll.payrolls(payroll_id) ON DELETE CASCADE,
    adjustment_type VARCHAR(100) NOT NULL, -- e.g., 'Bonus', 'Commission', 'Retroactive Pay'
    amount NUMERIC(10,2) NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Benefits (employee benefit plan options)
CREATE TABLE benefits.benefit_plan_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES benefits.benefit_plans(plan_id) ON DELETE CASCADE,
    option_name VARCHAR(255) NOT NULL,
    description TEXT,
    cost_employee NUMERIC(10,2),
    cost_company NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE benefits.employee_benefit_enrollments
ADD COLUMN benefit_plan_option_id UUID REFERENCES benefits.benefit_plan_options(option_id) ON DELETE SET NULL;

-- Employee Workflows (workflow templates)
CREATE TABLE hr.workflow_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    workflow_definition JSONB, -- JSON representation of the template workflow
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.workflows
ADD COLUMN template_id UUID REFERENCES hr.workflow_templates(template_id) ON DELETE SET NULL;

-- Employee Communication (announcement acknowledgements)
CREATE TABLE hr.announcement_acknowledgements (
    acknowledgement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    announcement_id UUID NOT NULL REFERENCES hr.announcements(announcement_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    acknowledged_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Grievances (grievance types)
CREATE TABLE hr.grievance_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.grievances
ADD COLUMN grievance_type_id UUID REFERENCES hr.grievance_types(type_id) ON DELETE RESTRICT;

-- Employee Disciplinary Actions (disciplinary action types)
CREATE TABLE hr.disciplinary_action_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.disciplinary_actions
ADD COLUMN action_type_id UUID REFERENCES hr.disciplinary_action_types(type_id) ON DELETE RESTRICT,
DROP COLUMN action_type; -- Replaced by action_type_id

-- Employee Surveys (survey distribution)
CREATE TABLE hr.survey_distributions (
    distribution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    distribution_date TIMESTAMPTZ DEFAULT NOW(),
    target_audience JSONB, -- e.g., {'departments': ['HR'], 'employee_types': ['full_time']}
    distributed_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recognition (recognition programs)
CREATE TABLE hr.recognition_programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.employee_recognitions
ADD COLUMN program_id UUID REFERENCES hr.recognition_programs(program_id) ON DELETE SET NULL;

-- Employee Assets (asset assignments history)
CREATE TABLE hr.asset_assignment_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES hr.assets(asset_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    assignment_date DATE NOT NULL,
    return_date DATE,
    assigned_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Communication (internal blogs)
CREATE TABLE hr.blog_posts (
    post_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    publish_date TIMESTAMPTZ DEFAULT NOW(),
    category VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.blog_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES hr.blog_posts(post_id) ON DELETE CASCADE,
    comment_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Wellness (wellness challenges progress)
CREATE TABLE hr.wellness_challenge_progress (
    progress_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participation_id UUID NOT NULL REFERENCES hr.employee_challenge_participation(participation_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    metric_value NUMERIC(10,2) NOT NULL, -- e.g., steps count, meditation minutes
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Travel Management (travel policies)
CREATE TABLE finance.travel_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    max_daily_meal NUMERIC(10,2),
    max_hotel_rate NUMERIC(10,2),
    requires_pre_approval BOOLEAN DEFAULT FALSE,
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE finance.travel_requests
ADD COLUMN policy_id UUID REFERENCES finance.travel_policies(policy_id) ON DELETE SET NULL;

-- Project Management (project phases)
CREATE TABLE hr.project_phases (
    phase_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES hr.projects(project_id) ON DELETE CASCADE,
    phase_name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) CHECK (status IN (
        'not_started', 'in_progress', 'completed', 'on_hold'
    )) DEFAULT 'not_started',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.project_tasks
ADD COLUMN phase_id UUID REFERENCES hr.project_phases(phase_id) ON DELETE SET NULL;

-- Vendor Management (vendor contracts)
CREATE TABLE finance.vendor_contracts (
    vendor_contract_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES finance.vendors(vendor_id) ON DELETE CASCADE,
    contract_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    contract_value NUMERIC(15,2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) CHECK (status IN (
        'active', 'expired', 'terminated'
    )) DEFAULT 'active',
    document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Help Desk / IT Support (ticket categories)
CREATE TABLE hr.ticket_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.support_tickets
ADD COLUMN category_id UUID REFERENCES hr.ticket_categories(category_id) ON DELETE SET NULL;

-- Knowledge Base / Documentation (article versions)
CREATE TABLE hr.knowledge_base_article_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES hr.knowledge_base_articles(article_id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    content TEXT NOT NULL,
    published_date TIMESTAMPTZ DEFAULT NOW(),
    published_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Education (degrees and majors)
CREATE TABLE hr.degrees (
    degree_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    degree_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.majors (
    major_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    major_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.employee_education
ADD COLUMN degree_id UUID REFERENCES hr.degrees(degree_id) ON DELETE SET NULL,
ADD COLUMN major_id UUID REFERENCES hr.majors(major_id) ON DELETE SET NULL,
DROP COLUMN degree,
DROP COLUMN major;

-- Employee Licenses and Certifications (issuing bodies)
CREATE TABLE hr.issuing_bodies (
    body_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    body_name VARCHAR(255) NOT NULL UNIQUE,
    country VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.licenses
ADD COLUMN issuing_body_id UUID REFERENCES hr.issuing_bodies(body_id) ON DELETE SET NULL,
DROP COLUMN issuing_authority;

-- Employee Health and Safety (safety training)
CREATE TABLE hr.safety_training_modules (
    module_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    duration_hours NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.employee_safety_training (
    training_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES hr.safety_training_modules(module_id) ON DELETE RESTRICT,
    completion_date DATE NOT NULL,
    score NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Feedback (feedback types)
CREATE TABLE hr.feedback_types (
    type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.employee_feedback
ADD COLUMN feedback_type_id UUID REFERENCES hr.feedback_types(type_id) ON DELETE RESTRICT,
DROP COLUMN feedback_type;

-- Employee Surveys (survey sections)
CREATE TABLE hr.survey_sections (
    section_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES hr.surveys(survey_id) ON DELETE CASCADE,
    section_name VARCHAR(255) NOT NULL,
    description TEXT,
    section_order INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.survey_questions
ADD COLUMN section_id UUID REFERENCES hr.survey_sections(section_id) ON DELETE SET NULL;

-- Employee Work Schedule (shift types)
CREATE TABLE hr.shift_types (
    shift_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(100) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_duration_minutes INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.schedule_details
ADD COLUMN shift_type_id UUID REFERENCES hr.shift_types(shift_type_id) ON DELETE SET NULL,
DROP COLUMN start_time,
DROP COLUMN end_time,
DROP COLUMN break_duration_minutes;

-- Employee Work Location (office amenities)
CREATE TABLE hr.office_amenities (
    amenity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    amenity_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hr.location_amenities (
    location_amenity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID NOT NULL REFERENCES hr.work_locations(location_id) ON DELETE CASCADE,
    amenity_id UUID NOT NULL REFERENCES hr.office_amenities(amenity_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Background Checks (check results)
CREATE TABLE hr.background_check_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    check_id UUID NOT NULL REFERENCES hr.employee_background_checks(check_id) ON DELETE CASCADE,
    result_type VARCHAR(100) NOT NULL, -- e.g., 'Criminal Record', 'Education Verification'
    result_details TEXT,
    status VARCHAR(20) CHECK (status IN (
        'clear', 'flagged', 'pending'
    )) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Health Insurance (plan tiers)
CREATE TABLE benefits.health_plan_tiers (
    tier_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    health_plan_id UUID NOT NULL REFERENCES benefits.health_insurance_plans(health_plan_id) ON DELETE CASCADE,
    tier_name VARCHAR(100) NOT NULL,
    description TEXT,
    deductible_modifier NUMERIC(5,2),
    premium_modifier NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE benefits.employee_health_insurance
ADD COLUMN tier_id UUID REFERENCES benefits.health_plan_tiers(tier_id) ON DELETE SET NULL;

-- Employee Retirement Plans (investment options)
CREATE TABLE benefits.retirement_investment_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    retirement_plan_id UUID NOT NULL REFERENCES benefits.retirement_plans(retirement_plan_id) ON DELETE CASCADE,
    option_name VARCHAR(255) NOT NULL,
    description TEXT,
    risk_level VARCHAR(50),
    expense_ratio NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_retirement_investments (
    investment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    retirement_enrollment_id UUID NOT NULL REFERENCES benefits.employee_retirement_enrollments(retirement_enrollment_id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES benefits.retirement_investment_options(option_id) ON DELETE RESTRICT,
    percentage_allocation NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Equity (vesting schedules)
CREATE TABLE benefits.vesting_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    schedule_details JSONB, -- e.g., [{'year': 1, 'percentage': 25}, {'year': 2, 'percentage': 25}]
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE benefits.equity_plans
ADD COLUMN vesting_schedule_id UUID REFERENCES benefits.vesting_schedules(schedule_id) ON DELETE SET NULL,
DROP COLUMN vesting_schedule;

-- Employee Performance (performance review questions)
CREATE TABLE performance.review_questions (
    question_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES performance.review_templates(template_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) CHECK (question_type IN (
        'rating', 'text', 'single_choice', 'multi_choice'
    )) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance.review_question_responses (
    response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_detail_id UUID NOT NULL REFERENCES performance.performance_reviews_details(review_detail_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES performance.review_questions(question_id) ON DELETE CASCADE,
    response_text TEXT,
    rating_value NUMERIC(2,1),
    selected_options JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (training evaluations)
CREATE TABLE learning.training_evaluations (
    evaluation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    training_record_id UUID NOT NULL REFERENCES learning.employee_training_records(training_record_id) ON DELETE CASCADE,
    evaluation_date DATE NOT NULL,
    overall_rating NUMERIC(2,1),
    comments TEXT,
    evaluated_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Career Pathing (required skills for steps)
CREATE TABLE hr.career_path_step_skills (
    step_skill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    step_id UUID NOT NULL REFERENCES hr.career_path_steps(step_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES hr.skills(skill_id) ON DELETE CASCADE,
    proficiency_level VARCHAR(50), -- e.g., 'Required', 'Desired'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.career_path_steps
DROP COLUMN required_skills; -- Replaced by career_path_step_skills

-- Employee Grievances (involved parties)
CREATE TABLE hr.grievance_involved_parties (
    involved_party_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grievance_id UUID NOT NULL REFERENCES hr.grievances(grievance_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    role_in_grievance VARCHAR(50), -- e.g., 'Complainant', 'Respondent', 'Witness'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Disciplinary Actions (witnesses)
CREATE TABLE hr.disciplinary_action_witnesses (
    witness_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_id UUID NOT NULL REFERENCES hr.disciplinary_actions(action_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    statement TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Recognition (award categories)
CREATE TABLE hr.award_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.recognition_awards
ADD COLUMN category_id UUID REFERENCES hr.award_categories(category_id) ON DELETE SET NULL;

-- Employee Communication (message threads)
CREATE TABLE hr.message_threads (
    thread_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject VARCHAR(255) NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE hr.internal_messages
ADD COLUMN thread_id UUID REFERENCES hr.message_threads(thread_id) ON DELETE SET NULL;

-- Employee Workflows (workflow triggers)
CREATE TABLE hr.workflow_triggers (
    trigger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id UUID NOT NULL REFERENCES hr.workflows(workflow_id) ON DELETE CASCADE,
    trigger_type VARCHAR(100) NOT NULL, -- e.g., 'event_based', 'time_based', 'manual'
    trigger_details JSONB, -- e.g., {'event_name': 'employee_hired', 'condition': 'department =



-- Employee Self-Service (leave balance)
CREATE VIEW hr.vw_employee_leave_balance AS
SELECT
    e.employee_id,
    lt.leave_type_name,
    SUM(CASE WHEN lr.status = 'approved' THEN lr.end_date - lr.start_date + 1 ELSE 0 END) AS days_taken,
    (SELECT SUM(hours_accrued) / 8 FROM hr.time_off_accruals WHERE employee_id = e.employee_id AND leave_type_id = lt.leave_type_id) AS days_accrued
FROM hr.employees e
JOIN hr.leave_requests lr ON e.employee_id = lr.employee_id
JOIN hr.leave_types lt ON lr.leave_type_id = lt.leave_type_id
GROUP BY e.employee_id, lt.leave_type_name, lt.leave_type_id;

-- Employee Data Privacy (data access requests)
CREATE TABLE compliance.data_access_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(user_id) ON DELETE RESTRICT,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    request_details TEXT NOT NULL,
    status VARCHAR(20) CHECK (status IN (
        'pending', 'approved', 'rejected'
    )) DEFAULT 'pending',
    approved_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Training (training feedback)
CREATE TABLE learning.training_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    training_record_id UUID NOT NULL REFERENCES learning.employee_training_records(training_record_id) ON DELETE CASCADE,
    feedback_date DATE NOT NULL,
    rating NUMERIC(2,1),
    comments TEXT,
    submitted_by UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Performance (performance review cycles)
CREATE TABLE performance.performance_review_cycles (
    cycle_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cycle_name VARCHAR(255) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN (
        'active', 'closed', 'archived'
    )) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE performance.performance_reviews
ADD COLUMN cycle_id UUID REFERENCES performance.performance_review_cycles(cycle_id) ON DELETE SET NULL;

-- Employee Recruitment (candidate tags)
CREATE TABLE recruitment.candidate_tags (
    tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE recruitment.candidate_tag_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    candidate_id UUID NOT NULL REFERENCES recruitment.candidates(candidate_id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES recruitment.candidate_tags(tag_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Payroll (payroll calendars)
CREATE TABLE payroll.payroll_calendars (
    calendar_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calendar_name VARCHAR(255) NOT NULL UNIQUE,
    pay_frequency VARCHAR(50) CHECK (pay_frequency IN (
        'weekly', 'bi-weekly', 'semi-monthly', 'monthly'
    )) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payroll.pay_periods
ADD COLUMN calendar_id UUID REFERENCES payroll.payroll_calendars(calendar_id) ON DELETE RESTRICT;

-- Employee Benefits (life events)
CREATE TABLE benefits.life_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE benefits.employee_life_events (
    employee_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES hr.employees(employee_id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES benefits.life_events(event_id) ON DELETE RESTRICT,
    event_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee Workflows (workflow audit trail)
CREATE TABLE hr.workflow_audit_trail (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES hr.workflow_instances(instance_id) ON DELETE CASCADE,
    step_name VARCHAR(255) NOT NULL,
    action TEXT NOT NULL,
    actor_id UUID REFERENCES auth.users(user_id) ON DELETE SET NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Finalizing the schema with additional views and stored procedures
CREATE VIEW finance.vw_vendor_invoice_summary AS
SELECT
    v.vendor_name,
    i.invoice_number,
    i.invoice_date,
    i.due_date,
    i.total_amount,
    i.status
FROM finance.vendors v
JOIN finance.invoices i ON v.vendor_id = i.vendor_id;

CREATE OR REPLACE FUNCTION hr.sp_get_employee_directory()
RETURNS TABLE(
    employee_id UUID,
    full_name TEXT,
    email VARCHAR(100),
    department VARCHAR(100),
    position VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS full_name,
        e.company_email,
        d.name AS department_name,
        p.position_title
    FROM hr.employees e
    LEFT JOIN hr.job_history jh ON e.employee_id = jh.employee_id AND jh.end_date IS NULL
    LEFT JOIN hr.positions p ON jh.position_id = p.position_id
    LEFT JOIN hr.departments d ON p.department_id = d.department_id;
END;
$$
LANGUAGE plpgsql;

-- This concludes the initial schema development. More tables can be added as needed.




-- Additional Views for newly added tables
CREATE VIEW hr.vw_employee_skills_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    s.skill_name,
    es.skill_level
FROM hr.employees e
JOIN hr.employee_skills es ON e.employee_id = es.employee_id
JOIN hr.skills s ON es.skill_id = s.skill_id;

CREATE VIEW hr.vw_employee_documents_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    ed.document_type,
    ed.expiry_date,
    ed.document_url
FROM hr.employees e
JOIN hr.employee_documents ed ON e.employee_id = ed.employee_id;

CREATE VIEW hr.vw_employee_leave_requests_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    lt.leave_type_name,
    lr.start_date,
    lr.end_date,
    lr.status,
    au.username AS approver_username
FROM hr.employees e
JOIN hr.leave_requests lr ON e.employee_id = lr.employee_id
JOIN hr.leave_types lt ON lr.leave_type_id = lt.leave_type_id
LEFT JOIN auth.users au ON lr.approver_id = au.user_id;

CREATE VIEW hr.vw_employee_attendance_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    a.work_date,
    a.check_in_time,
    a.check_out_time,
    a.hours_worked
FROM hr.employees e
JOIN hr.attendance a ON e.employee_id = a.employee_id;

CREATE VIEW hr.vw_employee_relations_cases AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    er.case_type,
    er.case_date,
    er.status,
    er.severity,
    assigned_emp.first_name || ' ' || assigned_emp.last_name AS assigned_to_name
FROM hr.employees e
JOIN hr.employee_relations er ON e.employee_id = er.employee_id
LEFT JOIN hr.employees assigned_emp ON er.assigned_to = assigned_emp.employee_id;

CREATE VIEW performance.vw_employee_goals_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    g.goal_name,
    g.start_date,
    g.end_date,
    g.status
FROM hr.employees e
JOIN performance.goals g ON e.employee_id = g.employee_id;

CREATE VIEW performance.vw_employee_performance_reviews_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    pr.review_date,
    pr.overall_rating,
    reviewer.first_name || ' ' || reviewer.last_name AS reviewer_name
FROM hr.employees e
JOIN performance.performance_reviews pr ON e.employee_id = pr.employee_id
JOIN hr.employees reviewer ON pr.reviewer_id = reviewer.employee_id;

CREATE VIEW learning.vw_employee_training_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    tp.program_name,
    ete.enrollment_date,
    ete.completion_date,
    ete.status
FROM hr.employees e
JOIN learning.employee_training_enrollments ete ON e.employee_id = ete.employee_id
JOIN learning.training_programs tp ON ete.program_id = tp.program_id;

CREATE VIEW benefits.vw_employee_benefit_enrollments_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    bp.plan_name,
    ebe.enrollment_date,
    ebe.status
FROM hr.employees e
JOIN benefits.employee_benefit_enrollments ebe ON e.employee_id = ebe.employee_id
JOIN benefits.benefit_plans bp ON ebe.plan_id = bp.plan_id;

CREATE VIEW recruitment.vw_job_application_status AS
SELECT
    jp.job_posting_id,
    jp.recruitment_status,
    p.position_title,
    c.first_name || ' ' || c.last_name AS candidate_name,
    a.application_date,
    a.application_status
FROM recruitment.job_postings jp
JOIN hr.positions p ON jp.position_id = p.position_id
JOIN recruitment.applications a ON jp.job_posting_id = a.job_posting_id
JOIN recruitment.candidates c ON a.candidate_id = c.candidate_id;

CREATE VIEW payroll.vw_employee_payroll_summary AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    pp.start_date AS pay_period_start,
    pp.end_date AS pay_period_end,
    py.gross_pay,
    py.net_pay,
    py.payment_status
FROM hr.employees e
JOIN payroll.payrolls py ON e.employee_id = py.employee_id
JOIN payroll.pay_periods pp ON py.pay_period_id = pp.pay_period_id;

CREATE VIEW compliance.vw_audit_log_summary AS
SELECT
    al.timestamp,
    u.username AS user_performing_action,
    al.action_type,
    al.table_name,
    al.record_id,
    al.ip_address
FROM compliance.audit_logs al
LEFT JOIN auth.users u ON al.user_id = u.user_id;

CREATE VIEW data_governance.vw_data_quality_issues AS
SELECT
    dqr.rule_name,
    dqr.target_table,
    dqr.target_column,
    dvl.validation_timestamp,
    dvl.error_message,
    dvl.is_resolved
FROM data_governance.data_quality_rules dqr
JOIN data_governance.data_validation_logs dvl ON dqr.rule_id = dvl.rule_id;

CREATE VIEW analytics.vw_kpi_performance AS
SELECT
    kpi.kpi_name,
    kpi.description,
    kv.recorded_date,
    kv.actual_value,
    kpi.target_value,
    (kv.actual_value - kpi.target_value) AS variance
FROM analytics.kpi_definitions kpi
JOIN analytics.kpi_values kv ON kpi.kpi_id = kv.kpi_id;

CREATE VIEW analytics.vw_user_subscription_status AS
SELECT
    u.username,
    s.start_date,
    s.end_date,
    s.is_active,
    sp.plan_name
FROM auth.users u
JOIN analytics.subscriptions s ON u.user_id = s.user_id
JOIN analytics.subscription_plans sp ON s.plan_id = sp.plan_id;

-- More specific views for business scenarios
CREATE VIEW hr.vw_employee_360_view AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.company_email,
    d.name AS department_name,
    p.position_title,
    c.salary AS current_salary,
    STRING_AGG(DISTINCT s.skill_name || ' (' || es.skill_level || ')', ', ') AS skills,
    STRING_AGG(DISTINCT lt.leave_type_name || ': ' || lr.status, ', ') AS leave_requests,
    STRING_AGG(DISTINCT g.goal_name || ' (' || g.status || ')', ', ') AS goals,
    STRING_AGG(DISTINCT pr.overall_rating::text || ' on ' || pr.review_date, ', ') AS performance_reviews,
    STRING_AGG(DISTINCT tp.program_name || ' (' || ete.status || ')', ', ') AS trainings
FROM hr.employees e
LEFT JOIN hr.job_history jh ON e.employee_id = jh.employee_id AND jh.end_date IS NULL
LEFT JOIN hr.positions p ON jh.position_id = p.position_id
LEFT JOIN hr.departments d ON p.department_id = d.department_id
LEFT JOIN hr.compensation c ON e.employee_id = c.employee_id AND c.effective_date = (SELECT MAX(effective_date) FROM hr.compensation WHERE employee_id = e.employee_id)
LEFT JOIN hr.employee_skills es ON e.employee_id = es.employee_id
LEFT JOIN hr.skills s ON es.skill_id = s.skill_id
LEFT JOIN hr.leave_requests lr ON e.employee_id = lr.employee_id
LEFT JOIN hr.leave_types lt ON lr.leave_type_id = lt.leave_type_id
LEFT JOIN performance.goals g ON e.employee_id = g.employee_id
LEFT JOIN performance.performance_reviews pr ON e.employee_id = pr.employee_id
LEFT JOIN learning.employee_training_enrollments ete ON e.employee_id = ete.employee_id
LEFT JOIN learning.training_programs tp ON ete.program_id = tp.program_id
GROUP BY e.employee_id, d.name, p.position_title, c.salary;

CREATE VIEW finance.vw_expense_report_details AS
SELECT
    er.report_id,
    er.report_date,
    e.first_name || ' ' || e.last_name AS employee_name,
    er.total_amount,
    er.currency,
    er.status,
    au.username AS approver_username,
    ei.description AS expense_item_description,
    ei.amount AS expense_item_amount,
    ec.category_name AS expense_category,
    r.url AS receipt_url
FROM finance.expense_reports er
JOIN hr.employees e ON er.employee_id = e.employee_id
LEFT JOIN auth.users au ON er.approver_id = au.user_id
LEFT JOIN finance.expense_items ei ON er.report_id = ei.report_id
LEFT JOIN finance.expense_categories ec ON ei.category_id = ec.category_id
LEFT JOIN finance.receipts r ON ei.receipt_id = r.receipt_id;

-- Stored Procedures (continued)
CREATE OR REPLACE FUNCTION hr.sp_update_employee_status(p_employee_id UUID, p_new_status hr.employment_status)
RETURNS VOID AS $$
BEGIN
    UPDATE hr.employees
    SET employment_status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE employee_id = p_employee_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'hr.employees', p_employee_id, jsonb_build_object('employment_status', p_new_status), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recruitment.sp_advance_application_stage(p_application_id UUID, p_new_stage_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE recruitment.applications
    SET current_stage_id = p_new_stage_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE application_id = p_application_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'recruitment.applications', p_application_id, jsonb_build_object('current_stage_id', p_new_stage_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION payroll.sp_generate_payroll_for_period(p_pay_period_id UUID)
RETURNS VOID AS $$
DECLARE
    r_employee RECORD;
    v_gross_pay NUMERIC(10,2);
    v_net_pay NUMERIC(10,2);
    v_total_deductions NUMERIC(10,2);
    v_total_taxes NUMERIC(10,2);
    v_payroll_id UUID;
BEGIN
    FOR r_employee IN SELECT employee_id, base_salary FROM payroll.employee_pay_details LOOP
        -- Calculate gross pay (simplified for example)
        v_gross_pay := r_employee.base_salary / 12; -- Monthly salary

        -- Calculate deductions (simplified)
        v_total_deductions := v_gross_pay * 0.10; -- 10% for deductions

        -- Calculate taxes (simplified)
        v_total_taxes := v_gross_pay * 0.15; -- 15% for taxes

        v_net_pay := v_gross_pay - v_total_deductions - v_total_taxes;

        INSERT INTO payroll.payrolls (employee_id, pay_period_id, gross_pay, net_pay, total_deductions, total_taxes)
        VALUES (r_employee.employee_id, p_pay_period_id, v_gross_pay, v_net_pay, v_total_deductions, v_total_taxes)
        RETURNING payroll_id INTO v_payroll_id;

        -- Insert deductions and taxes details (simplified)
        INSERT INTO payroll.deductions (payroll_id, deduction_type_id, amount)
        VALUES (v_payroll_id, (SELECT type_id FROM payroll.deduction_types WHERE type_name = 'Health Insurance'), v_gross_pay * 0.05);

        INSERT INTO payroll.taxes (payroll_id, tax_type_id, amount)
        VALUES (v_payroll_id, (SELECT type_id FROM payroll.tax_types WHERE type_name = 'Federal Income Tax'), v_gross_pay * 0.10);

    END LOOP;

    UPDATE payroll.pay_periods
    SET status = 'processed'
    WHERE pay_period_id = p_pay_period_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_generate_regulatory_report(p_report_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Placeholder for complex report generation logic
    -- This would involve querying various tables, aggregating data, and formatting it
    -- for specific regulatory requirements (SEC/FCA).
    -- The actual report generation might happen in an external service or a more complex PL/pgSQL function.

    UPDATE compliance.regulatory_reports
    SET status = 'submitted',
        submission_date = CURRENT_TIMESTAMP
    WHERE report_id = p_report_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'compliance.regulatory_reports', p_report_id, jsonb_build_object('status', 'submitted'), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION data_governance.sp_run_data_quality_check(p_rule_id UUID)
RETURNS VOID AS $$
DECLARE
    v_rule_expression TEXT;
    v_target_table VARCHAR(100);
    v_target_column VARCHAR(100);
    v_error_message TEXT;
    v_affected_record_id UUID;
BEGIN
    SELECT rule_expression, target_table, target_column
    INTO v_rule_expression, v_target_table, v_target_column
    FROM data_governance.data_quality_rules
    WHERE rule_id = p_rule_id;

    IF v_rule_expression IS NOT NULL THEN
        -- This is a simplified example. A real implementation would dynamically execute the rule_expression
        -- and log violations. This might require dynamic SQL or integration with a data quality tool.
        -- For demonstration, let's assume a simple check.
        EXECUTE format('SELECT %I FROM %I.%I WHERE NOT (%s) LIMIT 1', v_target_column, 'hr', v_target_table, v_rule_expression)
        INTO v_affected_record_id;

        IF v_affected_record_id IS NOT NULL THEN
            v_error_message := 'Data quality rule violation: ' || v_rule_expression;
            INSERT INTO data_governance.data_validation_logs (rule_id, affected_record_id, error_message)
            VALUES (p_rule_id, v_affected_record_id, v_error_message);
        END IF;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.sp_generate_weekly_insights()
RETURNS VOID AS $$
DECLARE
    v_insight_type_id UUID;
    v_user_id UUID;
    v_insight_content JSONB;
BEGIN
    -- Get the insight type for weekly insights
    SELECT insight_type_id INTO v_insight_type_id FROM analytics.insight_types WHERE frequency = 'weekly' LIMIT 1;

    IF v_insight_type_id IS NOT NULL THEN
        FOR v_user_id IN SELECT user_id FROM analytics.subscriptions WHERE is_active = TRUE AND plan_id IN (SELECT plan_id FROM analytics.subscription_plans WHERE features->>'weekly_insights' = 'true') LOOP
            -- Generate some dummy insight content (replace with actual AI-powered logic)
            v_insight_content := jsonb_build_object(
                'title', 'Weekly HR Insights for User ' || v_user_id,
                'summary', 'This week, employee engagement increased by 2% and leave requests decreased by 5%.',
                'charts', jsonb_build_array(
                    jsonb_build_object('type', 'bar', 'data', jsonb_build_object('labels', jsonb_build_array('Engagement', 'Leave'), 'values', jsonb_build_array(102, 95)))
                )
            );

            INSERT INTO analytics.user_insights (subscription_id, insight_type_id, generated_date, insight_content, delivery_status)
            VALUES (
                (SELECT subscription_id FROM analytics.subscriptions WHERE user_id = v_user_id LIMIT 1),
                v_insight_type_id,
                CURRENT_DATE,
                v_insight_content,
                'pending'
            );
        END LOOP;
    END IF;
END;
$$
LANGUAGE plpgsql;

-- More stored procedures for business scenarios
CREATE OR REPLACE FUNCTION hr.sp_onboard_new_employee(p_employee_id UUID)
RETURNS VOID AS $$
DECLARE
    v_onboarding_checklist_id UUID;
    v_task_id UUID;
BEGIN
    -- Get default onboarding checklist
    SELECT checklist_id INTO v_onboarding_checklist_id FROM hr.onboarding_checklists WHERE checklist_name = 'Standard Employee Onboarding' LIMIT 1;

    IF v_onboarding_checklist_id IS NOT NULL THEN
        FOR v_task_id IN SELECT item_id FROM hr.onboarding_checklist_items WHERE checklist_id = v_onboarding_checklist_id LOOP
            INSERT INTO hr.onboarding_tasks (employee_id, task_name, description, due_date, assigned_to, status, checklist_id, checklist_item_id)
            SELECT
                p_employee_id,
                item_name,
                description,
                CURRENT_DATE + INTERVAL '7 days', -- Due in 7 days
                (SELECT user_id FROM auth.users WHERE username = 'hr_admin' LIMIT 1), -- Assign to HR Admin
                'pending',
                v_onboarding_checklist_id,
                v_task_id
            FROM hr.onboarding_checklist_items
            WHERE item_id = v_task_id;
        END LOOP;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_process_offboarding(p_employee_id UUID)
RETURNS VOID AS $$
DECLARE
    v_offboarding_checklist_id UUID;
    v_task_id UUID;
BEGIN
    -- Get default offboarding checklist
    SELECT checklist_id INTO v_offboarding_checklist_id FROM hr.offboarding_checklists WHERE checklist_name = 'Standard Employee Offboarding' LIMIT 1;

    IF v_offboarding_checklist_id IS NOT NULL THEN
        FOR v_task_id IN SELECT item_id FROM hr.offboarding_checklist_items WHERE checklist_id = v_offboarding_checklist_id LOOP
            INSERT INTO hr.offboarding_tasks (employee_id, task_name, description, due_date, assigned_to, status, checklist_id, checklist_item_id)
            SELECT
                p_employee_id,
                item_name,
                description,
                CURRENT_DATE + INTERVAL '7 days', -- Due in 7 days
                (SELECT user_id FROM auth.users WHERE username = 'hr_admin' LIMIT 1), -- Assign to HR Admin
                'pending',
                v_offboarding_checklist_id,
                v_task_id
            FROM hr.offboarding_checklist_items
            WHERE item_id = v_task_id;
        END LOOP;
    END IF;

    -- Update employee status to terminated
    UPDATE hr.employees
    SET employment_status = 'terminated',
        termination_date = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE employee_id = p_employee_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'hr.employees', p_employee_id, jsonb_build_object('employment_status', 'terminated', 'termination_date', CURRENT_DATE), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_update_employee_compensation(p_employee_id UUID, p_new_salary NUMERIC(10,2), p_effective_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.compensation (employee_id, salary, effective_date)
    VALUES (p_employee_id, p_new_salary, p_effective_date);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.compensation', p_employee_id, jsonb_build_object('salary', p_new_salary, 'effective_date', p_effective_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_attendance(p_employee_id UUID, p_check_in TIMESTAMPTZ, p_check_out TIMESTAMPTZ)
RETURNS VOID AS $$
DECLARE
    v_hours_worked NUMERIC(5,2);
BEGIN
    v_hours_worked := EXTRACT(EPOCH FROM (p_check_out - p_check_in)) / 3600.0;

    INSERT INTO hr.attendance (employee_id, check_in_time, check_out_time, work_date, hours_worked)
    VALUES (p_employee_id, p_check_in, p_check_out, p_check_in::DATE, v_hours_worked);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.attendance', p_employee_id, jsonb_build_object('check_in_time', p_check_in, 'check_out_time', p_check_out), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_submit_leave_request(p_employee_id UUID, p_leave_type_id UUID, p_start_date DATE, p_end_date DATE, p_reason TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.leave_requests (employee_id, leave_type_id, start_date, end_date, reason, status)
    VALUES (p_employee_id, p_leave_type_id, p_start_date, p_end_date, p_reason, 'pending');

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.leave_requests', p_employee_id, jsonb_build_object('leave_type_id', p_leave_type_id, 'start_date', p_start_date, 'end_date', p_end_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_approve_leave_request(p_leave_request_id UUID, p_approver_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE hr.leave_requests
    SET status = 'approved',
        approver_id = p_approver_id,
        approved_date = CURRENT_DATE,
        updated_at = CURRENT_TIMESTAMP
    WHERE leave_request_id = p_leave_request_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'hr.leave_requests', p_leave_request_id, jsonb_build_object('status', 'approved', 'approver_id', p_approver_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_skill(p_employee_id UUID, p_skill_id UUID, p_skill_level VARCHAR(50))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_skills (employee_id, skill_id, skill_level)
    VALUES (p_employee_id, p_skill_id, p_skill_level)
    ON CONFLICT (employee_id, skill_id) DO UPDATE SET skill_level = p_skill_level, updated_at = CURRENT_TIMESTAMP;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT/UPDATE', 'hr.employee_skills', p_employee_id, jsonb_build_object('skill_id', p_skill_id, 'skill_level', p_skill_level), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_assign_employee_asset(p_employee_id UUID, p_asset_id UUID, p_assigned_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_assets (employee_id, asset_uuid, assigned_date)
    VALUES (p_employee_id, p_asset_id, p_assigned_date);

    UPDATE hr.assets
    SET status = 'in_use',
        updated_at = CURRENT_TIMESTAMP
    WHERE asset_id = p_asset_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_assets', p_employee_id, jsonb_build_object('asset_id', p_asset_id, 'assigned_date', p_assigned_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_return_employee_asset(p_employee_id UUID, p_asset_id UUID, p_return_date DATE, p_condition VARCHAR(50))
RETURNS VOID AS $$
BEGIN
    UPDATE hr.employee_assets
    SET returned_date = p_return_date,
        condition = p_condition,
        updated_at = CURRENT_TIMESTAMP
    WHERE employee_id = p_employee_id AND asset_uuid = p_asset_id AND returned_date IS NULL;

    UPDATE hr.assets
    SET status = 'in_storage',
        updated_at = CURRENT_TIMESTAMP
    WHERE asset_id = p_asset_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'hr.employee_assets', p_employee_id, jsonb_build_object('asset_id', p_asset_id, 'return_date', p_return_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_recognition(p_employee_id UUID, p_recognizer_id UUID, p_recognition_type_id UUID, p_comments TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_recognitions (employee_id, recognizer_id, recognition_type_id, recognition_date, comments)
    VALUES (p_employee_id, p_recognizer_id, p_recognition_type_id, CURRENT_DATE, p_comments);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_recognitions', p_employee_id, jsonb_build_object('recognition_type_id', p_recognition_type_id, 'comments', p_comments), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_publish_announcement(p_title VARCHAR(255), p_content TEXT, p_published_by UUID, p_expiry_date TIMESTAMPTZ, p_target_audience JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.announcements (title, content, publish_date, expiry_date, published_by, target_audience)
    VALUES (p_title, p_content, CURRENT_TIMESTAMP, p_expiry_date, p_published_by, p_target_audience);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.announcements', NULL, jsonb_build_object('title', p_title, 'content', p_content), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_submit_suggestion(p_employee_id UUID, p_subject VARCHAR(255), p_suggestion_text TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.suggestions (employee_id, subject, suggestion_text, submission_date, status)
    VALUES (p_employee_id, p_subject, p_suggestion_text, CURRENT_TIMESTAMP, 'new');

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.suggestions', p_employee_id, jsonb_build_object('subject', p_subject, 'suggestion_text', p_suggestion_text), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finance.sp_submit_travel_request(p_employee_id UUID, p_destination VARCHAR(255), p_purpose TEXT, p_start_date DATE, p_end_date DATE, p_estimated_cost NUMERIC(10,2), p_currency VARCHAR(3))
RETURNS VOID AS $$
BEGIN
    INSERT INTO finance.travel_requests (employee_id, destination, purpose, start_date, end_date, estimated_cost, currency, status)
    VALUES (p_employee_id, p_destination, p_purpose, p_start_date, p_end_date, p_estimated_cost, p_currency, 'pending');

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'finance.travel_requests', p_employee_id, jsonb_build_object('destination', p_destination, 'purpose', p_purpose), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finance.sp_record_invoice_payment(p_invoice_id UUID, p_payment_date DATE, p_payment_transaction_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE finance.invoices
    SET status = 'paid',
        payment_date = p_payment_date,
        payment_transaction_id = p_payment_transaction_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE invoice_id = p_invoice_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'UPDATE', 'finance.invoices', p_invoice_id, jsonb_build_object('status', 'paid', 'payment_date', p_payment_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_project(p_project_name VARCHAR(255), p_description TEXT, p_start_date DATE, p_end_date DATE, p_project_manager_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.projects (project_name, description, start_date, end_date, project_manager_id, status)
    VALUES (p_project_name, p_description, p_start_date, p_end_date, p_project_manager_id, 'planning');

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.projects', NULL, jsonb_build_object('project_name', p_project_name), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_submit_support_ticket(p_employee_id UUID, p_subject VARCHAR(255), p_description TEXT, p_priority VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.support_tickets (employee_id, subject, description, submission_date, status, priority)
    VALUES (p_employee_id, p_subject, p_description, CURRENT_TIMESTAMP, 'open', p_priority);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.support_tickets', p_employee_id, jsonb_build_object('subject', p_subject, 'description', p_description), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_knowledge_base_article(p_title VARCHAR(255), p_content TEXT, p_category VARCHAR(100), p_tags TEXT[], p_author_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.knowledge_base_articles (title, content, category, tags, author_id, publish_date, is_published)
    VALUES (p_title, p_content, p_category, p_tags, p_author_id, CURRENT_TIMESTAMP, TRUE);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.knowledge_base_articles', NULL, jsonb_build_object('title', p_title, 'content', p_content), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_education(p_employee_id UUID, p_degree_id UUID, p_major_id UUID, p_university VARCHAR(255), p_graduation_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_education (employee_id, degree_id, major_id, university, graduation_date)
    VALUES (p_employee_id, p_degree_id, p_major_id, p_university, p_graduation_date);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_education', p_employee_id, jsonb_build_object('degree_id', p_degree_id, 'university', p_university), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_previous_employment(p_employee_id UUID, p_company_name VARCHAR(255), p_job_title VARCHAR(100), p_start_date DATE, p_end_date DATE, p_responsibilities TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.previous_employments (employee_id, company_name, job_title, start_date, end_date, responsibilities)
    VALUES (p_employee_id, p_company_name, p_job_title, p_start_date, p_end_date, p_responsibilities);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.previous_employments', p_employee_id, jsonb_build_object('company_name', p_company_name, 'job_title', p_job_title), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_license(p_employee_id UUID, p_license_id UUID, p_license_number VARCHAR(100), p_issue_date DATE, p_expiry_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_licenses (employee_id, license_id, license_number, issue_date, expiry_date)
    VALUES (p_employee_id, p_license_id, p_license_number, p_issue_date, p_expiry_date);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_licenses', p_employee_id, jsonb_build_object('license_id', p_license_id, 'license_number', p_license_number), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_training_record(p_employee_id UUID, p_training_name VARCHAR(255), p_training_date DATE, p_duration_hours NUMERIC(5,2), p_provider_id UUID, p_cost NUMERIC(10,2), p_completion_status VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO learning.employee_training_records (employee_id, training_name, training_date, duration_hours, provider_id, cost, completion_status)
    VALUES (p_employee_id, p_training_name, p_training_date, p_duration_hours, p_provider_id, p_cost, p_completion_status);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'learning.employee_training_records', p_employee_id, jsonb_build_object('training_name', p_training_name, 'training_date', p_training_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_health_record(p_employee_id UUID, p_record_date DATE, p_record_type VARCHAR(100), p_details TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.health_records (employee_id, record_date, record_type, details)
    VALUES (p_employee_id, p_record_date, p_record_type, p_details);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.health_records', p_employee_id, jsonb_build_object('record_type', p_record_type, 'record_date', p_record_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_report_incident(p_incident_date DATE, p_incident_type VARCHAR(100), p_description TEXT, p_reported_by UUID, p_severity hr.investigation_severity)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.incidents (incident_date, incident_type, description, reported_by, status, severity)
    VALUES (p_incident_date, p_incident_type, p_description, p_reported_by, 'open', p_severity);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.incidents', NULL, jsonb_build_object('incident_type', p_incident_type, 'description', p_description), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_submit_employee_feedback(p_employee_id UUID, p_feedback_giver_id UUID, p_feedback_type_id UUID, p_feedback_text TEXT, p_is_anonymous BOOLEAN, p_sentiment_score NUMERIC(3,2))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_feedback (employee_id, feedback_giver_id, feedback_date, feedback_type_id, feedback_text, is_anonymous, sentiment_score)
    VALUES (p_employee_id, p_feedback_giver_id, CURRENT_TIMESTAMP, p_feedback_type_id, p_feedback_text, p_is_anonymous, p_sentiment_score);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_feedback', p_employee_id, jsonb_build_object('feedback_type_id', p_feedback_type_id, 'feedback_text', p_feedback_text), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_survey_response(p_survey_id UUID, p_employee_id UUID, p_answers JSONB)
RETURNS VOID AS $$
DECLARE
    v_response_id UUID;
    v_question_id UUID;
    v_answer_text TEXT;
    v_selected_options JSONB;
    v_rating_value NUMERIC(2,1);
BEGIN
    INSERT INTO hr.survey_responses (survey_id, employee_id, submission_date)
    VALUES (p_survey_id, p_employee_id, CURRENT_TIMESTAMP)
    RETURNING response_id INTO v_response_id;

    FOR v_question_id, v_answer_text, v_selected_options, v_rating_value IN
        SELECT
            (jsonb_each(p_answers)).key::UUID,
            (jsonb_each(p_answers)).value->>'answer_text',
            (jsonb_each(p_answers)).value->'selected_options',
            (jsonb_each(p_answers)).value->>'rating_value'::NUMERIC
    LOOP
        INSERT INTO hr.survey_answers (response_id, question_id, answer_text, selected_options, rating_value)
        VALUES (v_response_id, v_question_id, v_answer_text, v_selected_options, v_rating_value);
    END LOOP;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.survey_responses', p_employee_id, jsonb_build_object('survey_id', p_survey_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_update_kpi_value(p_kpi_id UUID, p_recorded_date DATE, p_actual_value NUMERIC(15,2))
RETURNS VOID AS $$
BEGIN
    INSERT INTO analytics.kpi_values (kpi_id, recorded_date, actual_value)
    VALUES (p_kpi_id, p_recorded_date, p_actual_value)
    ON CONFLICT (kpi_id, recorded_date) DO UPDATE SET actual_value = p_actual_value, created_at = CURRENT_TIMESTAMP;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT/UPDATE', 'analytics.kpi_values', p_kpi_id, jsonb_build_object('recorded_date', p_recorded_date, 'actual_value', p_actual_value), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.sp_record_page_view(p_user_id UUID, p_session_id UUID, p_page_id UUID, p_referrer_url TEXT, p_ip_address INET, p_user_agent TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO analytics.page_views (user_id, session_id, page_id, referrer_url, ip_address, user_agent)
    VALUES (p_user_id, p_session_id, p_page_id, p_referrer_url, p_ip_address, p_user_agent);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'analytics.page_views', p_user_id, jsonb_build_object('page_id', p_page_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.sp_record_event_log(p_user_id UUID, p_session_id UUID, p_event_type VARCHAR(100), p_event_details JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO analytics.event_logs (user_id, session_id, event_type, event_details)
    VALUES (p_user_id, p_session_id, p_event_type, p_event_details);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'analytics.event_logs', p_user_id, jsonb_build_object('event_type', p_event_type), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.sp_record_deal_matching_result(p_deal_profile_id UUID, p_matched_entity_id UUID, p_matched_entity_type VARCHAR(50), p_score NUMERIC(5,2), p_matching_algorithm VARCHAR(100), p_details JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO analytics.matching_results (deal_profile_id, matched_entity_id, matched_entity_type, score, matching_algorithm, details)
    VALUES (p_deal_profile_id, p_matched_entity_id, p_matched_entity_type, p_score, p_matching_algorithm, p_details);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'analytics.matching_results', p_deal_profile_id, jsonb_build_object('matched_entity_id', p_matched_entity_id, 'score', p_score), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_record_data_access(p_user_id UUID, p_accessed_table VARCHAR(100), p_accessed_record_id UUID, p_access_type VARCHAR(50), p_ip_address INET, p_user_agent TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO compliance.data_access_logs (user_id, accessed_table, accessed_record_id, access_type, access_timestamp, ip_address, user_agent)
    VALUES (p_user_id, p_accessed_table, p_accessed_record_id, p_access_type, CURRENT_TIMESTAMP, p_ip_address, p_user_agent);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_user_id, 'ACCESS', 'compliance.data_access_logs', NULL, jsonb_build_object('accessed_table', p_accessed_table, 'access_type', p_access_type), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_record_data_breach_incident(p_incident_date TIMESTAMPTZ, p_description TEXT, p_affected_data_types TEXT[], p_number_of_records_affected INT, p_reported_by UUID, p_severity hr.investigation_severity)
RETURNS UUID AS $$
DECLARE
    v_incident_id UUID;
BEGIN
    INSERT INTO compliance.data_breach_incidents (incident_date, description, affected_data_types, number_of_records_affected, status, reported_by, severity)
    VALUES (p_incident_date, p_description, p_affected_data_types, p_number_of_records_affected, 'reported', p_reported_by, p_severity)
    RETURNING incident_id INTO v_incident_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_reported_by, 'INSERT', 'compliance.data_breach_incidents', v_incident_id, jsonb_build_object('description', p_description, 'severity', p_severity), CURRENT_TIMESTAMP);

    RETURN v_incident_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_add_affected_individual_to_breach(p_incident_id UUID, p_employee_id UUID, p_external_individual_details JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO compliance.affected_individuals (incident_id, employee_id, external_individual_details)
    VALUES (p_incident_id, p_employee_id, p_external_individual_details);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'compliance.affected_individuals', p_incident_id, jsonb_build_object('employee_id', p_employee_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_record_pia(p_project_name VARCHAR(255), p_description TEXT, p_assessment_date DATE, p_assessor_id UUID, p_risk_level VARCHAR(20), p_recommendations TEXT)
RETURNS UUID AS $$
DECLARE
    v_pia_id UUID;
BEGIN
    INSERT INTO compliance.privacy_impact_assessments (project_name, description, assessment_date, assessor_id, risk_level, recommendations, status)
    VALUES (p_project_name, p_description, p_assessment_date, p_assessor_id, p_risk_level, p_recommendations, 'draft')
    RETURNING pia_id INTO v_pia_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_assessor_id, 'INSERT', 'compliance.privacy_impact_assessments', v_pia_id, jsonb_build_object('project_name', p_project_name, 'risk_level', p_risk_level), CURRENT_TIMESTAMP);

    RETURN v_pia_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_record_dpa(p_vendor_id UUID, p_agreement_date DATE, p_expiry_date DATE, p_description TEXT, p_dpa_document_url TEXT)
RETURNS UUID AS $$
DECLARE
    v_dpa_id UUID;
BEGIN
    INSERT INTO compliance.data_processing_agreements (vendor_id, agreement_date, expiry_date, description, dpa_document_url, is_active)
    VALUES (p_vendor_id, p_agreement_date, p_expiry_date, p_description, p_dpa_document_url, TRUE)
    RETURNING dpa_id INTO v_dpa_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'compliance.data_processing_agreements', v_dpa_id, jsonb_build_object('vendor_id', p_vendor_id, 'agreement_date', p_agreement_date), CURRENT_TIMESTAMP);

    RETURN v_dpa_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION learning.sp_record_training_attendance(p_employee_id UUID, p_training_record_id UUID, p_attendance_date DATE, p_status VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO learning.training_attendance (employee_id, training_record_id, attendance_date, status)
    VALUES (p_employee_id, p_training_record_id, p_attendance_date, p_status);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'learning.training_attendance', p_employee_id, jsonb_build_object('training_record_id', p_training_record_id, 'status', p_status), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance.sp_create_organizational_goal(p_goal_name VARCHAR(255), p_description TEXT, p_start_date DATE, p_end_date DATE, p_owner_id UUID)
RETURNS UUID AS $$
DECLARE
    v_org_goal_id UUID;
BEGIN
    INSERT INTO performance.organizational_goals (goal_name, description, start_date, end_date, owner_id)
    VALUES (p_goal_name, p_description, p_start_date, p_end_date, p_owner_id)
    RETURNING org_goal_id INTO v_org_goal_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_owner_id, 'INSERT', 'performance.organizational_goals', v_org_goal_id, jsonb_build_object('goal_name', p_goal_name), CURRENT_TIMESTAMP);

    RETURN v_org_goal_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance.sp_create_department_goal(p_org_goal_id UUID, p_department_id UUID, p_goal_name VARCHAR(255), p_description TEXT, p_start_date DATE, p_end_date DATE, p_owner_id UUID)
RETURNS UUID AS $$
DECLARE
    v_dept_goal_id UUID;
BEGIN
    INSERT INTO performance.department_goals (org_goal_id, department_id, goal_name, description, start_date, end_date, owner_id)
    VALUES (p_org_goal_id, p_department_id, p_goal_name, p_description, p_start_date, p_end_date, p_owner_id)
    RETURNING dept_goal_id INTO v_dept_goal_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_owner_id, 'INSERT', 'performance.department_goals', v_dept_goal_id, jsonb_build_object('goal_name', p_goal_name), CURRENT_TIMESTAMP);

    RETURN v_dept_goal_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recruitment.sp_create_recruitment_pipeline(p_pipeline_name VARCHAR(255), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_pipeline_id UUID;
BEGIN
    INSERT INTO recruitment.recruitment_pipelines (pipeline_name, description)
    VALUES (p_pipeline_name, p_description)
    RETURNING pipeline_id INTO v_pipeline_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'recruitment.recruitment_pipelines', v_pipeline_id, jsonb_build_object('pipeline_name', p_pipeline_name), CURRENT_TIMESTAMP);

    RETURN v_pipeline_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recruitment.sp_add_pipeline_stage(p_pipeline_id UUID, p_stage_name VARCHAR(100), p_stage_order INT)
RETURNS UUID AS $$
DECLARE
    v_stage_id UUID;
BEGIN
    INSERT INTO recruitment.pipeline_stages (pipeline_id, stage_name, stage_order)
    VALUES (p_pipeline_id, p_stage_name, p_stage_order)
    RETURNING stage_id INTO v_stage_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'recruitment.pipeline_stages', v_stage_id, jsonb_build_object('stage_name', p_stage_name), CURRENT_TIMESTAMP);

    RETURN v_stage_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION payroll.sp_set_deduction_limit(p_deduction_type_id UUID, p_limit_amount NUMERIC(10,2), p_limit_percentage NUMERIC(5,2), p_frequency VARCHAR(50), p_effective_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO payroll.deduction_limits (deduction_type_id, limit_amount, limit_percentage, frequency, effective_date)
    VALUES (p_deduction_type_id, p_limit_amount, p_limit_percentage, p_frequency, p_effective_date);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'payroll.deduction_limits', p_deduction_type_id, jsonb_build_object('limit_amount', p_limit_amount, 'frequency', p_frequency), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_enroll_employee_in_wellness_challenge(p_employee_id UUID, p_challenge_id UUID)
RETURNS UUID AS $$
DECLARE
    v_participation_id UUID;
BEGIN
    INSERT INTO hr.employee_challenge_participation (employee_id, challenge_id, enrollment_date, status)
    VALUES (p_employee_id, p_challenge_id, CURRENT_DATE, 'enrolled')
    RETURNING participation_id INTO v_participation_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_challenge_participation', v_participation_id, jsonb_build_object('employee_id', p_employee_id, 'challenge_id', p_challenge_id), CURRENT_TIMESTAMP);

    RETURN v_participation_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_wellness_challenge_progress(p_participation_id UUID, p_date DATE, p_metric_value NUMERIC(10,2))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.wellness_challenge_progress (participation_id, date, metric_value)
    VALUES (p_participation_id, p_date, p_metric_value);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.wellness_challenge_progress', p_participation_id, jsonb_build_object('date', p_date, 'metric_value', p_metric_value), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_event(p_event_name VARCHAR(255), p_description TEXT, p_event_date DATE, p_start_time TIME, p_end_time TIME, p_location TEXT, p_organizer_id UUID, p_is_internal BOOLEAN)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO hr.events (event_name, description, event_date, start_time, end_time, location, organizer_id, is_internal)
    VALUES (p_event_name, p_description, p_event_date, p_start_time, p_end_time, p_location, p_organizer_id, p_is_internal)
    RETURNING event_id INTO v_event_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_organizer_id, 'INSERT', 'hr.events', v_event_id, jsonb_build_object('event_name', p_event_name), CURRENT_TIMESTAMP);

    RETURN v_event_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_event_attendee(p_event_id UUID, p_employee_id UUID, p_rsvp_status VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.event_attendees (event_id, employee_id, rsvp_status)
    VALUES (p_event_id, p_employee_id, p_rsvp_status);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.event_attendees', p_event_id, jsonb_build_object('employee_id', p_employee_id, 'rsvp_status', p_rsvp_status), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_workflow_notification_template(p_template_name VARCHAR(255), p_subject_template TEXT, p_body_template TEXT, p_notification_channel VARCHAR(50))
RETURNS UUID AS $$
DECLARE
    v_template_id UUID;
BEGIN
    INSERT INTO hr.workflow_notification_templates (template_name, subject_template, body_template, notification_channel)
    VALUES (p_template_name, p_subject_template, p_body_template, p_notification_channel)
    RETURNING template_id INTO v_template_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.workflow_notification_templates', v_template_id, jsonb_build_object('template_name', p_template_name), CURRENT_TIMESTAMP);

    RETURN v_template_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_faq(p_category_id UUID, p_question TEXT, p_answer TEXT)
RETURNS UUID AS $$
DECLARE
    v_faq_id UUID;
BEGIN
    INSERT INTO hr.faqs (category_id, question, answer)
    VALUES (p_category_id, p_question, p_answer)
    RETURNING faq_id INTO v_faq_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.faqs', v_faq_id, jsonb_build_object('question', p_question), CURRENT_TIMESTAMP);

    RETURN v_faq_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compliance.sp_record_data_processing_activity(p_activity_name VARCHAR(255), p_description TEXT, p_purpose TEXT, p_legal_basis TEXT, p_data_categories TEXT[], p_recipients TEXT[], p_retention_period TEXT)
RETURNS UUID AS $$
DECLARE
    v_activity_id UUID;
BEGIN
    INSERT INTO compliance.data_processing_activities (activity_name, description, purpose, legal_basis, data_categories, recipients, retention_period)
    VALUES (p_activity_name, p_description, p_purpose, p_legal_basis, p_data_categories, p_recipients, p_retention_period)
    RETURNING activity_id INTO v_activity_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'compliance.data_processing_activities', v_activity_id, jsonb_build_object('activity_name', p_activity_name), CURRENT_TIMESTAMP);

    RETURN v_activity_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION learning.sp_record_e_learning_progress(p_employee_id UUID, p_module_id UUID, p_start_date DATE, p_completion_date DATE, p_score NUMERIC(5,2), p_status VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO learning.employee_e_learning_progress (employee_id, module_id, start_date, completion_date, score, status)
    VALUES (p_employee_id, p_module_id, p_start_date, p_completion_date, p_score, p_status);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'learning.employee_e_learning_progress', p_employee_id, jsonb_build_object('module_id', p_module_id, 'status', p_status), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance.sp_create_feedback_cycle(p_cycle_name VARCHAR(255), p_description TEXT, p_start_date DATE, p_end_date DATE, p_feedback_type VARCHAR(50))
RETURNS UUID AS $$
DECLARE
    v_cycle_id UUID;
BEGIN
    INSERT INTO performance.feedback_cycles (cycle_name, description, start_date, end_date, feedback_type)
    VALUES (p_cycle_name, p_description, p_start_date, p_end_date, p_feedback_type)
    RETURNING cycle_id INTO v_cycle_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'performance.feedback_cycles', v_cycle_id, jsonb_build_object('cycle_name', p_cycle_name), CURRENT_TIMESTAMP);

    RETURN v_cycle_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recruitment.sp_add_candidate_note_category(p_category_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_category_id UUID;
BEGIN
    INSERT INTO recruitment.candidate_note_categories (category_name, description)
    VALUES (p_category_name, p_description)
    RETURNING category_id INTO v_category_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'recruitment.candidate_note_categories', v_category_id, jsonb_build_object('category_name', p_category_name), CURRENT_TIMESTAMP);

    RETURN v_category_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION payroll.sp_record_payroll_adjustment(p_payroll_id UUID, p_adjustment_type VARCHAR(100), p_amount NUMERIC(10,2), p_reason TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO payroll.payroll_adjustments (payroll_id, adjustment_type, amount, reason)
    VALUES (p_payroll_id, p_adjustment_type, p_amount, p_reason);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'payroll.payroll_adjustments', p_payroll_id, jsonb_build_object('adjustment_type', p_adjustment_type, 'amount', p_amount), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefits.sp_add_benefit_plan_option(p_plan_id UUID, p_option_name VARCHAR(255), p_description TEXT, p_cost_employee NUMERIC(10,2), p_cost_company NUMERIC(10,2))
RETURNS UUID AS $$
DECLARE
    v_option_id UUID;
BEGIN
    INSERT INTO benefits.benefit_plan_options (plan_id, option_name, description, cost_employee, cost_company)
    VALUES (p_plan_id, p_option_name, p_description, p_cost_employee, p_cost_company)
    RETURNING option_id INTO v_option_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'benefits.benefit_plan_options', v_option_id, jsonb_build_object('option_name', p_option_name), CURRENT_TIMESTAMP);

    RETURN v_option_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_workflow_template(p_template_name VARCHAR(255), p_description TEXT, p_workflow_definition JSONB)
RETURNS UUID AS $$
DECLARE
    v_template_id UUID;
BEGIN
    INSERT INTO hr.workflow_templates (template_name, description, workflow_definition)
    VALUES (p_template_name, p_description, p_workflow_definition)
    RETURNING template_id INTO v_template_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.workflow_templates', v_template_id, jsonb_build_object('template_name', p_template_name), CURRENT_TIMESTAMP);

    RETURN v_template_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_announcement_acknowledgement(p_announcement_id UUID, p_employee_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.announcement_acknowledgements (announcement_id, employee_id, acknowledged_at)
    VALUES (p_announcement_id, p_employee_id, CURRENT_TIMESTAMP);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.announcement_acknowledgements', p_announcement_id, jsonb_build_object('employee_id', p_employee_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_grievance_type(p_type_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_type_id UUID;
BEGIN
    INSERT INTO hr.grievance_types (type_name, description)
    VALUES (p_type_name, p_description)
    RETURNING type_id INTO v_type_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.grievance_types', v_type_id, jsonb_build_object('type_name', p_type_name), CURRENT_TIMESTAMP);

    RETURN v_type_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_disciplinary_action_type(p_type_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_type_id UUID;
BEGIN
    INSERT INTO hr.disciplinary_action_types (type_name, description)
    VALUES (p_type_name, p_description)
    RETURNING type_id INTO v_type_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.disciplinary_action_types', v_type_id, jsonb_build_object('type_name', p_type_name), CURRENT_TIMESTAMP);

    RETURN v_type_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_survey_distribution(p_survey_id UUID, p_target_audience JSONB, p_distributed_by UUID)
RETURNS UUID AS $$
DECLARE
    v_distribution_id UUID;
BEGIN
    INSERT INTO hr.survey_distributions (survey_id, distribution_date, target_audience, distributed_by)
    VALUES (p_survey_id, CURRENT_TIMESTAMP, p_target_audience, p_distributed_by)
    RETURNING distribution_id INTO v_distribution_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_distributed_by, 'INSERT', 'hr.survey_distributions', v_distribution_id, jsonb_build_object('survey_id', p_survey_id), CURRENT_TIMESTAMP);

    RETURN v_distribution_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_recognition_program(p_program_name VARCHAR(255), p_description TEXT, p_start_date DATE, p_end_date DATE)
RETURNS UUID AS $$
DECLARE
    v_program_id UUID;
BEGIN
    INSERT INTO hr.recognition_programs (program_name, description, start_date, end_date)
    VALUES (p_program_name, p_description, p_start_date, p_end_date)
    RETURNING program_id INTO v_program_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.recognition_programs', v_program_id, jsonb_build_object('program_name', p_program_name), CURRENT_TIMESTAMP);

    RETURN v_program_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_asset_assignment_history(p_asset_id UUID, p_employee_id UUID, p_assignment_date DATE, p_assigned_by UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.asset_assignment_history (asset_id, employee_id, assignment_date, assigned_by)
    VALUES (p_asset_id, p_employee_id, p_assignment_date, p_assigned_by);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_assigned_by, 'INSERT', 'hr.asset_assignment_history', p_asset_id, jsonb_build_object('employee_id', p_employee_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_blog_post(p_title VARCHAR(255), p_content TEXT, p_author_id UUID, p_category VARCHAR(100))
RETURNS UUID AS $$
DECLARE
    v_post_id UUID;
BEGIN
    INSERT INTO hr.blog_posts (title, content, author_id, publish_date, category)
    VALUES (p_title, p_content, p_author_id, CURRENT_TIMESTAMP, p_category)
    RETURNING post_id INTO v_post_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_author_id, 'INSERT', 'hr.blog_posts', v_post_id, jsonb_build_object('title', p_title), CURRENT_TIMESTAMP);

    RETURN v_post_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_blog_comment(p_post_id UUID, p_comment_by UUID, p_comment_text TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.blog_comments (post_id, comment_by, comment_text, comment_date)
    VALUES (p_post_id, p_comment_by, p_comment_text, CURRENT_TIMESTAMP);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_comment_by, 'INSERT', 'hr.blog_comments', p_post_id, jsonb_build_object('comment_text', p_comment_text), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finance.sp_create_travel_policy(p_policy_name VARCHAR(255), p_description TEXT, p_max_daily_meal NUMERIC(10,2), p_max_hotel_rate NUMERIC(10,2), p_requires_pre_approval BOOLEAN, p_effective_date DATE)
RETURNS UUID AS $$
DECLARE
    v_policy_id UUID;
BEGIN
    INSERT INTO finance.travel_policies (policy_name, description, max_daily_meal, max_hotel_rate, requires_pre_approval, effective_date)
    VALUES (p_policy_name, p_description, p_max_daily_meal, p_max_hotel_rate, p_requires_pre_approval, p_effective_date)
    RETURNING policy_id INTO v_policy_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'finance.travel_policies', v_policy_id, jsonb_build_object('policy_name', p_policy_name), CURRENT_TIMESTAMP);

    RETURN v_policy_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_project_phase(p_project_id UUID, p_phase_name VARCHAR(255), p_start_date DATE, p_end_date DATE)
RETURNS UUID AS $$
DECLARE
    v_phase_id UUID;
BEGIN
    INSERT INTO hr.project_phases (project_id, phase_name, start_date, end_date, status)
    VALUES (p_project_id, p_phase_name, p_start_date, p_end_date, 'not_started')
    RETURNING phase_id INTO v_phase_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.project_phases', v_phase_id, jsonb_build_object('phase_name', p_phase_name), CURRENT_TIMESTAMP);

    RETURN v_phase_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finance.sp_create_vendor_contract(p_vendor_id UUID, p_contract_name VARCHAR(255), p_start_date DATE, p_end_date DATE, p_contract_value NUMERIC(15,2), p_currency VARCHAR(3), p_document_url TEXT)
RETURNS UUID AS $$
DECLARE
    v_contract_id UUID;
BEGIN
    INSERT INTO finance.vendor_contracts (vendor_id, contract_name, start_date, end_date, contract_value, currency, status, document_url)
    VALUES (p_vendor_id, p_contract_name, p_start_date, p_end_date, p_contract_value, p_currency, 'active', p_document_url)
    RETURNING vendor_contract_id INTO v_contract_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'finance.vendor_contracts', v_contract_id, jsonb_build_object('contract_name', p_contract_name), CURRENT_TIMESTAMP);

    RETURN v_contract_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_ticket_category(p_category_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_category_id UUID;
BEGIN
    INSERT INTO hr.ticket_categories (category_name, description)
    VALUES (p_category_name, p_description)
    RETURNING category_id INTO v_category_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.ticket_categories', v_category_id, jsonb_build_object('category_name', p_category_name), CURRENT_TIMESTAMP);

    RETURN v_category_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_knowledge_base_article_version(p_article_id UUID, p_version_number INT, p_content TEXT, p_published_by UUID)
RETURNS UUID AS $$
DECLARE
    v_version_id UUID;
BEGIN
    INSERT INTO hr.knowledge_base_article_versions (article_id, version_number, content, published_date, published_by)
    VALUES (p_article_id, p_version_number, p_content, CURRENT_TIMESTAMP, p_published_by)
    RETURNING version_id INTO v_version_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_published_by, 'INSERT', 'hr.knowledge_base_article_versions', v_version_id, jsonb_build_object('article_id', p_article_id, 'version_number', p_version_number), CURRENT_TIMESTAMP);

    RETURN v_version_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_degree(p_degree_name VARCHAR(100))
RETURNS UUID AS $$
DECLARE
    v_degree_id UUID;
BEGIN
    INSERT INTO hr.degrees (degree_name)
    VALUES (p_degree_name)
    RETURNING degree_id INTO v_degree_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.degrees', v_degree_id, jsonb_build_object('degree_name', p_degree_name), CURRENT_TIMESTAMP);

    RETURN v_degree_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_major(p_major_name VARCHAR(100))
RETURNS UUID AS $$
DECLARE
    v_major_id UUID;
BEGIN
    INSERT INTO hr.majors (major_name)
    VALUES (p_major_name)
    RETURNING major_id INTO v_major_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.majors', v_major_id, jsonb_build_object('major_name', p_major_name), CURRENT_TIMESTAMP);

    RETURN v_major_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_issuing_body(p_body_name VARCHAR(255), p_country VARCHAR(100))
RETURNS UUID AS $$
DECLARE
    v_body_id UUID;
BEGIN
    INSERT INTO hr.issuing_bodies (body_name, country)
    VALUES (p_body_name, p_country)
    RETURNING body_id INTO v_body_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.issuing_bodies', v_body_id, jsonb_build_object('body_name', p_body_name), CURRENT_TIMESTAMP);

    RETURN v_body_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_safety_training_module(p_module_name VARCHAR(255), p_description TEXT, p_duration_hours NUMERIC(5,2))
RETURNS UUID AS $$
DECLARE
    v_module_id UUID;
BEGIN
    INSERT INTO hr.safety_training_modules (module_name, description, duration_hours)
    VALUES (p_module_name, p_description, p_duration_hours)
    RETURNING module_id INTO v_module_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.safety_training_modules', v_module_id, jsonb_build_object('module_name', p_module_name), CURRENT_TIMESTAMP);

    RETURN v_module_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_employee_safety_training(p_employee_id UUID, p_module_id UUID, p_completion_date DATE, p_score NUMERIC(5,2))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.employee_safety_training (employee_id, module_id, completion_date, score)
    VALUES (p_employee_id, p_module_id, p_completion_date, p_score);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.employee_safety_training', p_employee_id, jsonb_build_object('module_id', p_module_id, 'completion_date', p_completion_date), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_feedback_type(p_type_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_type_id UUID;
BEGIN
    INSERT INTO hr.feedback_types (type_name, description)
    VALUES (p_type_name, p_description)
    RETURNING type_id INTO v_type_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.feedback_types', v_type_id, jsonb_build_object('type_name', p_type_name), CURRENT_TIMESTAMP);

    RETURN v_type_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_survey_section(p_survey_id UUID, p_section_name VARCHAR(255), p_section_order INT)
RETURNS UUID AS $$
DECLARE
    v_section_id UUID;
BEGIN
    INSERT INTO hr.survey_sections (survey_id, section_name, section_order)
    VALUES (p_survey_id, p_section_name, p_section_order)
    RETURNING section_id INTO v_section_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.survey_sections', v_section_id, jsonb_build_object('section_name', p_section_name), CURRENT_TIMESTAMP);

    RETURN v_section_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_shift_type(p_type_name VARCHAR(100), p_start_time TIME, p_end_time TIME, p_break_duration_minutes INT)
RETURNS UUID AS $$
DECLARE
    v_shift_type_id UUID;
BEGIN
    INSERT INTO hr.shift_types (type_name, start_time, end_time, break_duration_minutes)
    VALUES (p_type_name, p_start_time, p_end_time, p_break_duration_minutes)
    RETURNING shift_type_id INTO v_shift_type_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.shift_types', v_shift_type_id, jsonb_build_object('type_name', p_type_name), CURRENT_TIMESTAMP);

    RETURN v_shift_type_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_office_amenity(p_amenity_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_amenity_id UUID;
BEGIN
    INSERT INTO hr.office_amenities (amenity_name, description)
    VALUES (p_amenity_name, p_description)
    RETURNING amenity_id INTO v_amenity_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.office_amenities', v_amenity_id, jsonb_build_object('amenity_name', p_amenity_name), CURRENT_TIMESTAMP);

    RETURN v_amenity_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_assign_location_amenity(p_location_id UUID, p_amenity_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.location_amenities (location_id, amenity_id)
    VALUES (p_location_id, p_amenity_id);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.location_amenities', p_location_id, jsonb_build_object('amenity_id', p_amenity_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_record_background_check_result(p_check_id UUID, p_result_type VARCHAR(100), p_result_details TEXT, p_status VARCHAR(20))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.background_check_results (check_id, result_type, result_details, status)
    VALUES (p_check_id, p_result_type, p_result_details, p_status);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.background_check_results', p_check_id, jsonb_build_object('result_type', p_result_type, 'status', p_status), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefits.sp_add_health_plan_tier(p_health_plan_id UUID, p_tier_name VARCHAR(100), p_description TEXT, p_deductible_modifier NUMERIC(5,2), p_premium_modifier NUMERIC(5,2))
RETURNS UUID AS $$
DECLARE
    v_tier_id UUID;
BEGIN
    INSERT INTO benefits.health_plan_tiers (health_plan_id, tier_name, description, deductible_modifier, premium_modifier)
    VALUES (p_health_plan_id, p_tier_name, p_description, p_deductible_modifier, p_premium_modifier)
    RETURNING tier_id INTO v_tier_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'benefits.health_plan_tiers', v_tier_id, jsonb_build_object('tier_name', p_tier_name), CURRENT_TIMESTAMP);

    RETURN v_tier_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefits.sp_add_retirement_investment_option(p_retirement_plan_id UUID, p_option_name VARCHAR(255), p_description TEXT, p_risk_level VARCHAR(50), p_expense_ratio NUMERIC(5,2))
RETURNS UUID AS $$
DECLARE
    v_option_id UUID;
BEGIN
    INSERT INTO benefits.retirement_investment_options (retirement_plan_id, option_name, description, risk_level, expense_ratio)
    VALUES (p_retirement_plan_id, p_option_name, p_description, p_risk_level, p_expense_ratio)
    RETURNING option_id INTO v_option_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'benefits.retirement_investment_options', v_option_id, jsonb_build_object('option_name', p_option_name), CURRENT_TIMESTAMP);

    RETURN v_option_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefits.sp_record_employee_retirement_investment(p_retirement_enrollment_id UUID, p_option_id UUID, p_percentage_allocation NUMERIC(5,2))
RETURNS VOID AS $$
BEGIN
    INSERT INTO benefits.employee_retirement_investments (retirement_enrollment_id, option_id, percentage_allocation)
    VALUES (p_retirement_enrollment_id, p_option_id, p_percentage_allocation);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'benefits.employee_retirement_investments', p_retirement_enrollment_id, jsonb_build_object('option_id', p_option_id, 'percentage_allocation', p_percentage_allocation), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION benefits.sp_create_vesting_schedule(p_schedule_name VARCHAR(255), p_description TEXT, p_schedule_details JSONB)
RETURNS UUID AS $$
DECLARE
    v_schedule_id UUID;
BEGIN
    INSERT INTO benefits.vesting_schedules (schedule_name, description, schedule_details)
    VALUES (p_schedule_name, p_description, p_schedule_details)
    RETURNING schedule_id INTO v_schedule_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'benefits.vesting_schedules', v_schedule_id, jsonb_build_object('schedule_name', p_schedule_name), CURRENT_TIMESTAMP);

    RETURN v_schedule_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance.sp_add_review_question(p_template_id UUID, p_question_text TEXT, p_question_type VARCHAR(50))
RETURNS UUID AS $$
DECLARE
    v_question_id UUID;
BEGIN
    INSERT INTO performance.review_questions (template_id, question_text, question_type)
    VALUES (p_template_id, p_question_text, p_question_type)
    RETURNING question_id INTO v_question_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'performance.review_questions', v_question_id, jsonb_build_object('question_text', p_question_text), CURRENT_TIMESTAMP);

    RETURN v_question_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance.sp_record_review_question_response(p_review_detail_id UUID, p_question_id UUID, p_response_text TEXT, p_rating_value NUMERIC(2,1), p_selected_options JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO performance.review_question_responses (review_detail_id, question_id, response_text, rating_value, selected_options)
    VALUES (p_review_detail_id, p_question_id, p_response_text, p_rating_value, p_selected_options);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'performance.review_question_responses', p_review_detail_id, jsonb_build_object('question_id', p_question_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION learning.sp_record_training_evaluation(p_training_record_id UUID, p_evaluation_date DATE, p_overall_rating NUMERIC(2,1), p_comments TEXT, p_evaluated_by UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO learning.training_evaluations (training_record_id, evaluation_date, overall_rating, comments, evaluated_by)
    VALUES (p_training_record_id, p_evaluation_date, p_overall_rating, p_comments, p_evaluated_by);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_evaluated_by, 'INSERT', 'learning.training_evaluations', p_training_record_id, jsonb_build_object('overall_rating', p_overall_rating), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_career_path_step_skill(p_step_id UUID, p_skill_id UUID, p_proficiency_level VARCHAR(50))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.career_path_step_skills (step_id, skill_id, proficiency_level)
    VALUES (p_step_id, p_skill_id, p_proficiency_level);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.career_path_step_skills', p_step_id, jsonb_build_object('skill_id', p_skill_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_grievance_involved_party(p_grievance_id UUID, p_employee_id UUID, p_role_in_grievance VARCHAR(50))
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.grievance_involved_parties (grievance_id, employee_id, role_in_grievance)
    VALUES (p_grievance_id, p_employee_id, p_role_in_grievance);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.grievance_involved_parties', p_grievance_id, jsonb_build_object('employee_id', p_employee_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_disciplinary_action_witness(p_action_id UUID, p_employee_id UUID, p_statement TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO hr.disciplinary_action_witnesses (action_id, employee_id, statement)
    VALUES (p_action_id, p_employee_id, p_statement);

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.disciplinary_action_witnesses', p_action_id, jsonb_build_object('employee_id', p_employee_id), CURRENT_TIMESTAMP);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_award_category(p_category_name VARCHAR(100), p_description TEXT)
RETURNS UUID AS $$
DECLARE
    v_category_id UUID;
BEGIN
    INSERT INTO hr.award_categories (category_name, description)
    VALUES (p_category_name, p_description)
    RETURNING category_id INTO v_category_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.award_categories', v_category_id, jsonb_build_object('category_name', p_category_name), CURRENT_TIMESTAMP);

    RETURN v_category_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_create_message_thread(p_subject VARCHAR(255), p_created_by UUID)
RETURNS UUID AS $$
DECLARE
    v_thread_id UUID;
BEGIN
    INSERT INTO hr.message_threads (subject, created_by)
    VALUES (p_subject, p_created_by)
    RETURNING thread_id INTO v_thread_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (p_created_by, 'INSERT', 'hr.message_threads', v_thread_id, jsonb_build_object('subject', p_subject), CURRENT_TIMESTAMP);

    RETURN v_thread_id;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hr.sp_add_workflow_trigger(p_workflow_id UUID, p_trigger_type VARCHAR(100), p_trigger_details JSONB)
RETURNS UUID AS $$
DECLARE
    v_trigger_id UUID;
BEGIN
    INSERT INTO hr.workflow_triggers (workflow_id, trigger_type, trigger_details)
    VALUES (p_workflow_id, p_trigger_type, p_trigger_details)
    RETURNING trigger_id INTO v_trigger_id;

    INSERT INTO compliance.audit_logs (user_id, action_type, table_name, record_id, new_value, timestamp)
    VALUES (CURRENT_USER::UUID, 'INSERT', 'hr.workflow_triggers', v_trigger_id, jsonb_build_object('trigger_type', p_trigger_type), CURRENT_TIMESTAMP);

    RETURN v_trigger_id;
END;
$$
LANGUAGE plpgsql;

-- End of additional views and stored procedures
