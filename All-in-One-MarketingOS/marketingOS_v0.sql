--2025 β ORI Inc.Canada All Rights Reserved.
-- PostgreSQL Schema for All-in-One Marketing & CRM Operating System
-- Version: 1.0 (Enhanced)
-- Created: 2025-05-04
-- Author: Awase Khirni Syed

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "ltree";

--geosaptial query -- enable postgis extension
CREATE EXTENSION IF NOT EXISTS postgis;

--text search --knowledge base support
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Create enum types for various classifications
CREATE TYPE consent_type AS ENUM ('email', 'sms', 'cookies', 'data_processing', 'third_party_sharing');
CREATE TYPE campaign_channel AS ENUM ('email', 'sms', 'social', 'push', 'web', 'in_app');
CREATE TYPE lead_status AS ENUM ('new', 'contacted', 'qualified', 'disqualified', 'converted');
CREATE TYPE deal_stage AS ENUM ('prospect', 'qualification', 'proposal', 'negotiation', 'closed_won', 'closed_lost');
CREATE TYPE data_classification AS ENUM ('public', 'internal', 'confidential', 'pii', 'sensitive');
CREATE TYPE kpi_period AS ENUM ('daily', 'weekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE visitor_behavior AS ENUM ('page_view', 'click', 'form_submit', 'download', 'video_view', 'cart_add');

-- Create tables with enhanced features based on PRS

-- 1. Core User and Organization Structure
CREATE TABLE organizations (
    org_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    industry VARCHAR(100),
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en-US',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_domain UNIQUE (domain)
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password_hash TEXT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_email_per_org UNIQUE (org_id, email)
);

-- 2. Marketing Automation Module
CREATE TABLE marketing_campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    channel campaign_channel NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    budget DECIMAL(15,2),
    expected_roi DECIMAL(5,2),
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE campaign_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID REFERENCES marketing_campaigns(campaign_id) ON DELETE CASCADE,
    asset_type VARCHAR(50) NOT NULL, -- 'landing_page', 'email_template', 'banner', etc.
    content JSONB,
    variants JSONB, -- For A/B testing
    version INT DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lead_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'website', 'event', 'social', 'referral', etc.
    utm_parameters JSONB, -- Store UTM parameters
    cost_per_lead DECIMAL(15,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. CRM Module
CREATE TABLE contacts (
    contact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    company VARCHAR(255),
    job_title VARCHAR(255),
    lead_status lead_status DEFAULT 'new',
    lead_score INT DEFAULT 0,
    source_id UUID REFERENCES lead_sources(source_id),
    owner_id UUID REFERENCES users(user_id),
    last_contacted TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT unique_email_per_org UNIQUE (org_id, email)
);

CREATE TABLE deals (
    deal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2),
    stage deal_stage DEFAULT 'prospect',
    probability DECIMAL(5,2),
    expected_close_date TIMESTAMP WITH TIME ZONE,
    contact_id UUID REFERENCES contacts(contact_id),
    owner_id UUID REFERENCES users(user_id),
    campaign_id UUID REFERENCES marketing_campaigns(campaign_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- 4. GDPR & Data Governance Module
CREATE TABLE consent_records (
    consent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contact_id UUID REFERENCES contacts(contact_id) ON DELETE CASCADE,
    consent_type consent_type NOT NULL,
    granted BOOLEAN NOT NULL,
    purpose TEXT,
    collection_channel VARCHAR(100),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    version VARCHAR(50),
    ip_address INET,
    user_agent TEXT
);

CREATE TABLE data_processing_activities (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    lawful_basis VARCHAR(100) NOT NULL, -- 'consent', 'contract', 'legal_obligation', etc.
    data_categories JSONB NOT NULL, -- Types of data processed
    retention_period INT, -- In days
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Data Lifecycle Intelligence
CREATE TABLE data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'api', 'database', 'file', 'webhook', etc.
    connection_details JSONB,
    ingestion_frequency VARCHAR(50), -- 'real_time', 'daily', 'weekly', etc.
    data_classification data_classification DEFAULT 'internal',
    retention_policy VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Data Quality & Profiling
CREATE TABLE data_quality_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    field_path VARCHAR(255) NOT NULL, -- e.g., 'contacts.email'
    rule_type VARCHAR(50) NOT NULL, -- 'format', 'completeness', 'uniqueness', etc.
    rule_definition JSONB NOT NULL, -- e.g., {"regex": "^[^@]+@[^@]+\\.[^@]+$"}
    severity VARCHAR(20) DEFAULT 'warning', -- 'info', 'warning', 'error'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. KPI & Dashboarding Module
CREATE TABLE kpi_definitions (
    kpi_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    calculation TEXT NOT NULL, -- SQL or formula definition
    period kpi_period DEFAULT 'monthly',
    target_value DECIMAL(15,2),
    target_direction VARCHAR(10), -- 'higher', 'lower', 'equal'
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    layout_config JSONB NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Audit & Compliance Reporting
CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Analytics & Visitor Behavior Module
CREATE TABLE visitor_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    visitor_id VARCHAR(255) NOT NULL,
    device_id VARCHAR(255),
    first_visit TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    referrer_url TEXT,
    referrer_domain VARCHAR(255),
    utm_parameters JSONB,
    geo_data JSONB, -- Country, city, etc.
    device_data JSONB, -- Browser, OS, etc.
    contact_id UUID REFERENCES contacts(contact_id)
);

CREATE TABLE visitor_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES visitor_sessions(session_id) ON DELETE CASCADE,
    event_type visitor_behavior NOT NULL,
    event_data JSONB,
    url_path VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. Sales Funnel & Conversion Optimization
CREATE TABLE sales_funnels (
    funnel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    stages JSONB NOT NULL, -- Array of stage definitions
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enhanced tables for AI/ML features
CREATE TABLE ml_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID REFERENCES organizations(org_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    purpose VARCHAR(255) NOT NULL, -- 'lead_scoring', 'churn_prediction', etc.
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'training',
    training_data_range JSONB, -- Start and end dates for training data
    performance_metrics JSONB,
    deployed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


--predictive customer lifetime value
CREATE TABLE customer_lifetime_value (
    clv_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    predicted_value DECIMAL(15,2),
    confidence_interval JSONB, -- {lower: x, upper: y}
    refresh_frequency VARCHAR(20),
    last_calculated TIMESTAMP,
    next_refresh TIMESTAMP
);

CREATE OR REPLACE FUNCTION calculate_clv(contact_id UUID)
RETURNS JSONB AS $$
-- Machine learning model integration would go here
$$ LANGUAGE plpgsql;


--omnichannel journey orchestration
CREATE TABLE customer_journeys (
    journey_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    current_state VARCHAR(100),
    path_history JSONB[], -- Array of journey steps
    next_best_actions JSONB, -- AI-recommended actions
    engagement_score INT
);

CREATE INDEX idx_journey_current_state ON customer_journeys(current_state);


--AI powered content generation logging
CREATE TABLE ai_content_generation (
    content_id UUID PRIMARY KEY,
    original_prompt TEXT,
    generated_content TEXT,
    model_version VARCHAR(50),
    variants JSONB, -- A/B test versions
    performance_metrics JSONB,
    bias_audit_results JSONB
);


--Real-time personalization engine
CREATE TABLE personalization_rules (
    rule_id UUID PRIMARY KEY,
    segment_conditions JSONB,
    content_variants JSONB,
    priority INT,
    activation_schedule JSONB
);

CREATE TABLE personalization_events (
    event_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    rule_id UUID REFERENCES personalization_rules(rule_id),
    displayed_variant VARCHAR(50),
    display_context JSONB
);


--conversational commerce integration
CREATE TABLE conversation_threads (
    thread_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    channel VARCHAR(50), -- whatsapp, messenger, etc.
    thread_state JSONB,
    last_message_at TIMESTAMP,
    sentiment_score DECIMAL(3,2)
);

CREATE TABLE commerce_events (
    event_id UUID PRIMARY KEY,
    thread_id UUID REFERENCES conversation_threads(thread_id),
    product_ids UUID[],
    cart_state JSONB,
    payment_intent_id VARCHAR(100)
);

--predictive inventory recommendations
CREATE TABLE inventory_recommendations (
    rec_id UUID PRIMARY KEY,
    product_id UUID,
    predicted_demand INT,
    recommended_stock INT,
    confidence_score DECIMAL(3,2),
    seasonal_adjustment JSONB
);

--Ehtical AI governance
CREATE TABLE ai_governance (
    audit_id UUID PRIMARY KEY,
    model_id UUID REFERENCES ml_models(model_id),
    fairness_report JSONB,
    bias_metrics JSONB,
    explainability_data JSONB,
    last_audited TIMESTAMP
);


--cross-channel attribution modeling
CREATE TABLE attribution_models (
    model_id UUID PRIMARY KEY,
    name VARCHAR(100),
    definition JSONB, -- Contains weightings for each channel
    is_active BOOLEAN
);

CREATE TABLE attribution_results (
    result_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    model_id UUID REFERENCES attribution_models(model_id),
    touchpoints JSONB,
    credit_distribution JSONB
);

--dynamic pricing integration
CREATE TABLE pricing_strategies (
    strategy_id UUID PRIMARY KEY,
    product_id UUID,
    base_price DECIMAL(15,2),
    rules JSONB, -- Segmentation rules + price adjustments
    ai_optimization BOOLEAN
);

CREATE TABLE price_optimization_logs (
    log_id UUID PRIMARY KEY,
    strategy_id UUID REFERENCES pricing_strategies(strategy_id),
    recommended_price DECIMAL(15,2),
    confidence_score DECIMAL(3,2),
    factors JSONB -- Competitor prices, demand, etc.
);


--voice of customer sentiment analysis
CREATE TABLE customer_feedback (
    feedback_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    source VARCHAR(50), -- survey, call, review, etc.
    raw_text TEXT,
    sentiment_score DECIMAL(3,2),
    topics JSONB, -- AI-detected topics
    urgency_score INT
);

CREATE MATERIALIZED VIEW mv_customer_sentiment_trends AS
SELECT
    DATE_TRUNC('week', created_at) AS week,
    AVG(sentiment_score) AS avg_sentiment,
    COUNT(*) FILTER (WHERE sentiment_score < 0.3) AS negative_count
FROM customer_feedback
GROUP BY DATE_TRUNC('week', created_at);


--augmented reality engagement tracking
CREATE TABLE ar_experiences (
    experience_id UUID PRIMARY KEY,
    product_id UUID,
    marker_data JSONB,
    content_urls JSONB
);

CREATE TABLE ar_engagements (
    engagement_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    experience_id UUID REFERENCES ar_experiences(experience_id),
    duration_seconds INT,
    interactions JSONB,
    conversion_result VARCHAR(50)
);



--block chain based consent ledger
CREATE TABLE consent_transactions (
    tx_hash VARCHAR(66) PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    consent_type consent_type,
    block_number BIGINT,
    blockchain_data JSONB,
    immutable_record TEXT -- Cryptographic proof
);


--predictive maintenance for marketing assets
CREATE TABLE asset_health_monitoring (
    monitor_id UUID PRIMARY KEY,
    asset_id UUID REFERENCES campaign_assets(asset_id),
    performance_metrics JSONB,
    degradation_score DECIMAL(5,2),
    recommended_refresh BOOLEAN,
    predicted_obsolescence_date DATE
);

--event-driven architecture
CREATE TABLE system_events (
    event_id UUID PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE FUNCTION notify_event() RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('system_events', NEW.event_id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--graphql federation ready
CREATE TABLE api_entities (
    entity_id UUID PRIMARY KEY,
    entity_name VARCHAR(100) NOT NULL,
    schema_definition JSONB NOT NULL,
    version INT NOT NULL
);


--edge computing sync
CREATE TABLE edge_sync_logs (
    sync_id UUID PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    last_sync TIMESTAMP NOT NULL,
    data_hash VARCHAR(64) NOT NULL,
    conflict_resolution JSONB
);

--Autonomous Campaign Optimization
CREATE TABLE campaign_auto_optimizations (
    optimization_id UUID PRIMARY KEY,
    campaign_id UUID REFERENCES marketing_campaigns(campaign_id),
    adjustment_type VARCHAR(50), -- "budget", "targeting", "creative"
    before_state JSONB,
    after_state JSONB,
    ai_justification TEXT,
    performance_impact DECIMAL(5,2) -- % improvement
);

CREATE OR REPLACE FUNCTION auto_optimize_campaign()
RETURNS TRIGGER AS $BODY$
BEGIN
    -- AI-driven real-time campaign adjustments
    -- Would integrate with reinforcement learning system
END;
$BODY$ LANGUAGE plpgsql;

--Multi-agent negotation system
CREATE TABLE negotiation_agents (
    agent_id UUID PRIMARY KEY,
    deal_id UUID REFERENCES deals(deal_id),
    agent_type VARCHAR(50), -- "pricing", "terms", "timing"
    strategy_parameters JSONB,
    concession_patterns JSONB,
    final_outcome VARCHAR(100)
);

CREATE TABLE negotiation_transcripts (
    turn_id UUID PRIMARY KEY,
    agent_id UUID REFERENCES negotiation_agents(agent_id),
    utterance TEXT,
    semantic_frame JSONB,
    non_verbal_cues JSONB
);

--self healing data pipelines
CREATE TABLE data_pipeline_health (
    pipeline_id UUID PRIMARY KEY,
    source_id UUID REFERENCES data_sources(source_id),
    anomaly_detection_model VARCHAR(100),
    recovery_actions JSONB, -- Automated repair protocols
    last_incident TIMESTAMP,
    mean_time_to_repair INTERVAL
);

CREATE OR REPLACE FUNCTION pipeline_autoheal()
RETURNS TRIGGER AS $$
BEGIN
    -- Would contain logic for automatic data quality recovery
END;
$$ LANGUAGE plpgsql;

--cross reality customer journeys --nice to have
CREATE TABLE xr_journey_mapping (
    journey_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    physical_touchpoints JSONB,
    digital_touchpoints JSONB,
    augmented_reality_events JSONB,
    virtual_reality_sessions JSONB,
    unified_engagement_score DECIMAL(5,2)
) PARTITION BY RANGE (unified_engagement_score);


--autonomous legal compliance
CREATE TABLE compliance_agents (
    agent_id UUID PRIMARY KEY,
    jurisdiction VARCHAR(100),
    regulation_versions JSONB,
    decision_log JSONB,
    audit_trail_hashchain TEXT
);

CREATE TABLE compliance_actions (
    action_id UUID PRIMARY KEY,
    agent_id UUID REFERENCES compliance_agents(agent_id),
    operation VARCHAR(100), -- "data_retention", "consent_check"
    executed_at TIMESTAMP,
    legal_basis TEXT
);

--predictive customer service
CREATE TABLE service_intervention_points (
    intervention_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    predicted_issue VARCHAR(100),
    recommended_solutions JSONB,
    preemptive_actions JSONB,
    expected_savings DECIMAL(10,2)
);

CREATE OR REPLACE FUNCTION trigger_preemptive_service()
RETURNS TRIGGER AS $$
BEGIN
    -- Would initiate service workflows before customer contacts support
END;
$$ LANGUAGE plpgsql;


--self-learning data ontology
CREATE TABLE dynamic_ontology (
    concept_id UUID PRIMARY KEY,
    parent_path LTREE,
    semantic_definition JSONB,
    vector_embedding VECTOR(1536), -- Using pgvector extension
    auto_relationships JSONB
);

CREATE INDEX idx_ontology_path_gist ON dynamic_ontology USING GIST(parent_path);
CREATE INDEX idx_ontology_embedding ON dynamic_ontology USING ivfflat(vector_embedding);


--temporal database features
CREATE TABLE customer_value_history (
    hist_id UUID PRIMARY KEY,
    contact_id UUID,
    effective_range TSTZRANGE,
    tier VARCHAR(50),
    predicted_lifetime_value DECIMAL(15,2)
);

CREATE INDEX idx_customer_value_temporal ON customer_value_history USING GIST(effective_range);


--distributed consensus logs
CREATE TABLE distributed_consensus (
    log_id UUID PRIMARY KEY,
    operation_hash VARCHAR(64),
    merkle_proof TEXT,
    participant_nodes VARCHAR(100)[],
    confirmed_at TIMESTAMP
) WITH (autovacuum_enabled = false);


--loyalty management module
CREATE TABLE loyalty_programs (
    program_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    name VARCHAR(100) NOT NULL,
    tier_config JSONB NOT NULL, -- {tier_name: {threshold: x, benefits: [...]}}
    earning_rules JSONB NOT NULL, -- {action: points, expiration: days}
    redemption_rules JSONB NOT NULL,
    dynamic_rewards BOOLEAN DEFAULT FALSE,
    ai_optimization_enabled BOOLEAN DEFAULT FALSE
);

CREATE TABLE loyalty_members (
    member_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    program_id UUID REFERENCES loyalty_programs(program_id),
    current_tier VARCHAR(50),
    lifetime_points BIGINT,
    available_points BIGINT,
    next_tier_progress DECIMAL(5,2),
    last_activity TIMESTAMP
);

CREATE TABLE loyalty_events (
    event_id UUID PRIMARY KEY,
    member_id UUID REFERENCES loyalty_members(member_id),
    event_type VARCHAR(50) NOT NULL, -- 'earn', 'burn', 'expire'
    points_value INT NOT NULL,
    reference_id UUID, -- Links to purchase/activity
    expires_at TIMESTAMP,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dynamic_reward_offers (
    offer_id UUID PRIMARY KEY,
    program_id UUID REFERENCES loyalty_programs(program_id),
    target_segment JSONB NOT NULL,
    reward_parameters JSONB NOT NULL,
    success_metrics JSONB,
    ai_generated BOOLEAN DEFAULT FALSE
);


--advanced loyalty analytics views
CREATE MATERIALIZED VIEW mv_loyalty_tier_distribution AS
SELECT
    program_id,
    current_tier,
    COUNT(*) AS member_count,
    AVG(lifetime_points) AS avg_points,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lifetime_points) AS median_points
FROM loyalty_members
GROUP BY program_id, current_tier;

CREATE VIEW vw_loyalty_velocity AS
SELECT
    lm.member_id,
    lm.program_id,
    COUNT(le.event_id) FILTER (WHERE le.event_type = 'earn') AS earn_events,
    COUNT(le.event_id) FILTER (WHERE le.event_type = 'burn') AS redemption_events,
    EXTRACT(DAY FROM (NOW() - MIN(le.processed_at))) AS days_active,
    (COUNT(le.event_id)::FLOAT / NULLIF(EXTRACT(DAY FROM (NOW() - MIN(le.processed_at)))::FLOAT, 0) AS daily_activity_rate
FROM loyalty_members lm
JOIN loyalty_events le ON lm.member_id = le.member_id
GROUP BY lm.member_id, lm.program_id;

CREATE VIEW vw_predicted_churn_risk AS
SELECT
    lm.member_id,
    lm.contact_id,
    lm.program_id,
    CASE
        WHEN NOW() - lm.last_activity > INTERVAL '90 days' THEN 'high'
        WHEN NOW() - lm.last_activity > INTERVAL '60 days' AND lm.available_points > 0 THEN 'medium'
        ELSE 'low'
    END AS churn_risk,
    lm.available_points AS at_risk_points
FROM loyalty_members lm;


--account based marketing
CREATE TABLE target_accounts (
    account_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    company_name VARCHAR(255) NOT NULL,
    industry VARCHAR(100),
    employee_range VARCHAR(50),
    annual_revenue_range VARCHAR(50),
    tech_stack JSONB, -- Technographic data
    buying_committee JSONB[] -- Stakeholder profiles
);

CREATE TABLE abm_plays (
    play_id UUID PRIMARY KEY,
    account_id UUID REFERENCES target_accounts(account_id),
    playbook JSONB NOT NULL, -- Multi-touch engagement plan
    priority INT CHECK (priority BETWEEN 1 AND 5),
    predicted_impact DECIMAL(5,2)
);


--configure price quote engine

CREATE TABLE product_catalog (
    product_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    configurable_attributes JSONB, -- {color: ["red","blue"], storage: ["256GB","512GB"]}
    pricing_rules JSONB NOT NULL -- {base_price: 999, volume_discounts: [...]}
);

CREATE TABLE quote_templates (
    template_id UUID PRIMARY KEY,
    sales_team_id UUID REFERENCES sales_teams(team_id),
    legal_terms TEXT,
    approval_workflow JSONB
);

CREATE TABLE quotes (
    quote_id UUID PRIMARY KEY,
    opportunity_id UUID REFERENCES deals(deal_id),
    line_items JSONB NOT NULL, -- [{product_id: x, qty: 2, price: 1998}]
    discount_applied DECIMAL(5,2),
    expiry_date TIMESTAMP,
    approval_status VARCHAR(20) DEFAULT 'draft'
);


--enterprise case management
CREATE TABLE service_cases (
    case_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    severity VARCHAR(20) CHECK (severity IN ('low','medium','high','critical')),
    sla_terms JSONB NOT NULL, -- {response_time: "2h", resolution_time: "24h"}
    assigned_team UUID REFERENCES service_teams(team_id),
    escalation_path JSONB,
    root_cause_analysis TEXT
);

CREATE TABLE case_workflow (
    step_id UUID PRIMARY KEY,
    case_id UUID REFERENCES service_cases(case_id),
    action_type VARCHAR(50) NOT NULL,
    completed_at TIMESTAMP,
    sla_breached BOOLEAN DEFAULT FALSE,
    agent_notes TEXT
);


--coalition loyalty program
CREATE TABLE coalition_partners (
    partner_id UUID PRIMARY KEY,
    program_id UUID REFERENCES loyalty_programs(program_id),
    points_exchange_rate DECIMAL(5,2) NOT NULL,
    shared_segments JSONB -- Data sharing permissions
);

CREATE TABLE cross_partner_redemptions (
    redemption_id UUID PRIMARY KEY,
    member_id UUID REFERENCES loyalty_members(member_id),
    partner_id UUID REFERENCES coalition_partners(partner_id),
    points_redeemed INT NOT NULL,
    partner_transaction_id VARCHAR(100)
) PARTITION BY RANGE (points_redeemed);


--data sovereignty controls
CREATE TABLE data_residency_rules (
    rule_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    data_category VARCHAR(100) NOT NULL, -- 'pii', 'financial', etc.
    required_geo VARCHAR(3) NOT NULL, -- ISO country code
    encryption_standard VARCHAR(50) NOT NULL,
    access_policy JSONB NOT NULL
);

CREATE TABLE data_location_audit (
    audit_id UUID PRIMARY KEY,
    entity_type VARCHAR(100) NOT NULL, -- 'contact', 'deal', etc.
    entity_id UUID NOT NULL,
    storage_location VARCHAR(3) NOT NULL,
    verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);






---advanced KPI metrics --predictive KPI tables
CREATE TABLE predictive_kpis (
    kpi_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    base_kpi_id UUID REFERENCES kpi_definitions(kpi_id),
    forecast_model VARCHAR(100) NOT NULL,
    confidence_interval JSONB NOT NULL, -- {lower: x, upper: y}
    time_horizon VARCHAR(20) NOT NULL, -- '7d', '30d', '90d'
    last_updated TIMESTAMP NOT NULL
);

CREATE TABLE kpi_anomalies (
    anomaly_id UUID PRIMARY KEY,
    kpi_id UUID REFERENCES kpi_definitions(kpi_id),
    detected_at TIMESTAMP NOT NULL,
    deviation_amount DECIMAL(10,2) NOT NULL,
    root_cause_analysis JSONB,
    status VARCHAR(20) DEFAULT 'unreviewed'
);


--prescriptive analytics

CREATE TABLE prescriptive_recommendations (
    rec_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    insight_type VARCHAR(50) NOT NULL, -- 'next-best-action', 'churn-prevention'
    recommended_actions JSONB NOT NULL,
    expected_impact DECIMAL(5,2), -- % improvement predicted
    confidence_score DECIMAL(3,2)
);

CREATE TABLE action_outcomes (
    outcome_id UUID PRIMARY KEY,
    rec_id UUID REFERENCES prescriptive_recommendations(rec_id),
    actual_impact DECIMAL(5,2),
    feedback_loop JSONB -- Why recommendation succeeded/failed
);


--enterprise integration
CREATE TABLE integration_adapters (
    adapter_id UUID PRIMARY KEY,
    system_type VARCHAR(50) NOT NULL, -- 'sap', 'oracle', 'netsuite'
    auth_protocol VARCHAR(50) NOT NULL, -- 'oauth2', 'saml', 'basic'
    field_mappings JSONB NOT NULL,
    last_sync TIMESTAMP,
    error_queue JSONB
);

CREATE TABLE data_warehouse_feeds (
    feed_id UUID PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL,
    change_data_capture BOOLEAN DEFAULT TRUE,
    sync_frequency VARCHAR(20) NOT NULL, -- '15m', 'daily', 'weekly'
    destination_config JSONB NOT NULL
);


--global user identity resolution
CREATE TABLE identity_graph (
    graph_id UUID PRIMARY KEY,
    master_person_id UUID NOT NULL,
    identity_vertices JSONB NOT NULL, -- {email: ["a@x.com","b@y.com"], phone: ["+123..."]}
    confidence_score DECIMAL(3,2) NOT NULL
) WITH (autovacuum_enabled = false);



--enterprise security additions
CREATE TABLE data_masking_profiles (
    profile_id UUID PRIMARY KEY,
    role_id UUID REFERENCES roles(role_id),
    masking_rules JSONB NOT NULL -- {contacts.email: "regex", deals.amount: "nullify"}
);

CREATE TABLE session_forensics (
    session_id UUID PRIMARY KEY,
    risk_score DECIMAL(3,2),
    anomalous_behavior JSONB, -- {location_jumping: true, speed_fill: true}
    mitigation_action VARCHAR(50) -- 'challenge', 'lock', 'allow'
);


--multi-instance architecture
CREATE TABLE tenant_shards (
    shard_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    database_shard VARCHAR(50) NOT NULL,
    storage_region VARCHAR(3) NOT NULL,
    replication_factor INT DEFAULT 3
);

CREATE TABLE cross_shard_queries (
    query_id UUID PRIMARY KEY,
    federated_sql TEXT NOT NULL,
    result_cache JSONB,
    ttl_seconds INT DEFAULT 3600
);

---opportunity splits (Team Selling)
CREATE TABLE opportunity_splits (
    split_id UUID PRIMARY KEY,
    opportunity_id UUID REFERENCES deals(deal_id),
    user_id UUID REFERENCES users(user_id),
    split_percentage DECIMAL(5,2) CHECK (split_percentage BETWEEN 0 AND 100),
    split_reason VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_opp_splits ON opportunity_splits(opportunity_id, user_id);


--campaign influence attribution
CREATE TABLE campaign_influence (
    influence_id UUID PRIMARY KEY,
    campaign_id UUID REFERENCES marketing_campaigns(campaign_id),
    opportunity_id UUID REFERENCES deals(deal_id),
    influence_percentage DECIMAL(5,2),
    touchpoint_count INT,
    first_responded BOOLEAN DEFAULT FALSE
);

CREATE MATERIALIZED VIEW mv_campaign_roi AS
SELECT
    c.campaign_id,
    SUM(d.amount * ci.influence_percentage/100) AS influenced_revenue,
    c.budget,
    (SUM(d.amount * ci.influence_percentage/100) - c.budget) / NULLIF(c.budget, 0) AS roi
FROM marketing_campaigns c
JOIN campaign_influence ci ON c.campaign_id = ci.campaign_id
JOIN deals d ON ci.opportunity_id = d.deal_id
GROUP BY c.campaign_id;


--forecasting quotas and adjustments
CREATE TABLE sales_forecasts (
    forecast_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    period DATE NOT NULL, -- First day of month/quarter
    forecast_amount DECIMAL(15,2) NOT NULL,
    adjusted_amount DECIMAL(15,2),
    pipeline_coverage DECIMAL(5,2),
    commit_status VARCHAR(20) CHECK (commit_status IN ('best_case','commit','closed'))
);

CREATE TABLE forecast_adjustments (
    adjustment_id UUID PRIMARY KEY,
    forecast_id UUID REFERENCES sales_forecasts(forecast_id),
    reason_code VARCHAR(50),
    adjustment_amount DECIMAL(15,2),
    approved_by UUID REFERENCES users(user_id)
);

--price books and product options
CREATE TABLE price_books (
    price_book_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    name VARCHAR(100) NOT NULL,
    is_standard BOOLEAN DEFAULT FALSE,
    valid_from DATE,
    valid_to DATE
);

CREATE TABLE price_book_entries (
    entry_id UUID PRIMARY KEY,
    price_book_id UUID REFERENCES price_books(price_book_id),
    product_id UUID REFERENCES product_catalog(product_id),
    unit_price DECIMAL(15,2) NOT NULL,
    discount_tiers JSONB -- {quantity: price} pairs
);

CREATE INDEX idx_price_book_products ON price_book_entries(product_id);

--lead scoring rules engine
CREATE TABLE lead_scoring_rules (
    rule_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    rule_name VARCHAR(100) NOT NULL,
    rule_condition JSONB NOT NULL, -- {field: "company_size", operator: ">", value: 500}
    points INT NOT NULL,
    expiration_days INT
);

CREATE OR REPLACE FUNCTION calculate_lead_score(p_contact_id UUID)
RETURNS INT AS $$
DECLARE
    v_score INT := 0;
    v_contact RECORD;
BEGIN
    SELECT * INTO v_contact FROM contacts WHERE contact_id = p_contact_id;

    -- Dynamic rule evaluation
    SELECT SUM(points) INTO v_score
    FROM lead_scoring_rules
    WHERE org_id = v_contact.org_id
    AND jsonb_path_match(
        jsonb_build_object(
            'company_size', v_contact.company_size,
            'lead_source', v_contact.lead_source,
            'job_title', v_contact.job_title
        ),
        rule_condition
    );

    RETURN LEAST(COALESCE(v_score, 0), 100);
END;
$$ LANGUAGE plpgsql;

--territory management
CREATE TABLE sales_territories (
    territory_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    name VARCHAR(100) NOT NULL,
    geo_boundaries GEOGRAPHY(POLYGON, 4326),
    account_segment VARCHAR(50)
);

CREATE TABLE territory_assignments (
    assignment_id UUID PRIMARY KEY,
    territory_id UUID REFERENCES sales_territories(territory_id),
    user_id UUID REFERENCES users(user_id),
    role VARCHAR(20) CHECK (role IN ('owner','reader','contributor'))
);

CREATE INDEX idx_territory_geo ON sales_territories USING GIST(geo_boundaries);

--case milestones and entitlements
CREATE TABLE service_entitlements (
    entitlement_id UUID PRIMARY KEY,
    account_id UUID REFERENCES target_accounts(account_id),
    support_level VARCHAR(50) NOT NULL,
    remaining_cases INT,
    renewal_date DATE
);

CREATE TABLE case_milestones (
    milestone_id UUID PRIMARY KEY,
    case_id UUID REFERENCES service_cases(case_id),
    milestone_type VARCHAR(50) NOT NULL, -- 'first_response','resolution'
    target_time INTERVAL NOT NULL,
    actual_time INTERVAL,
    status VARCHAR(20) DEFAULT 'pending'
);

--knowledge base with AI search
CREATE TABLE knowledge_articles (
    article_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    search_vector TSVECTOR,
    views INT DEFAULT 0,
    helpful_count INT DEFAULT 0
);

CREATE INDEX idx_knowledge_search ON knowledge_articles USING GIN(search_vector);

CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector =
        setweight(to_tsvector('english', COALESCE(NEW.title,'')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.content,'')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_knowledge_search
BEFORE INSERT OR UPDATE ON knowledge_articles
FOR EACH ROW EXECUTE FUNCTION update_search_vector();


--partner relationship management
CREATE TABLE partner_programs (
    program_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    name VARCHAR(100) NOT NULL,
    deal_registration BOOLEAN DEFAULT TRUE,
    referral_fees JSONB -- {type: "%", value: 15, cap: 50000}
);

CREATE TABLE partner_deals (
    partner_deal_id UUID PRIMARY KEY,
    partner_id UUID REFERENCES contacts(contact_id),
    opportunity_id UUID REFERENCES deals(deal_id),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approval_status VARCHAR(20) DEFAULT 'pending'
);

--user workspace

CREATE TABLE user_workspaces (
    workspace_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    layout_config JSONB NOT NULL, -- Component placement
    pinned_entities JSONB, -- Frequently accessed records
    last_accessed TIMESTAMP
);

CREATE TABLE workspace_components (
    component_id UUID PRIMARY KEY,
    workspace_id UUID REFERENCES user_workspaces(workspace_id),
    component_type VARCHAR(50) NOT NULL, -- 'recent_records','performance_chart'
    config JSONB NOT NULL,
    refresh_interval INT DEFAULT 300 -- Seconds
);


--automation workflows
CREATE TABLE automation_flows (
    flow_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    name VARCHAR(100) NOT NULL,
    trigger_condition JSONB NOT NULL,
    actions JSONB NOT NULL, -- Sequential steps
    version INT DEFAULT 1,
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE flow_executions (
    execution_id UUID PRIMARY KEY,
    flow_id UUID REFERENCES automation_flows(flow_id),
    trigger_record_id UUID,
    execution_log JSONB,
    status VARCHAR(20) DEFAULT 'started'
);



---Analytical Insights
CREATE TABLE ai_insights (
    insight_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    insight_type VARCHAR(50) NOT NULL, -- 'opportunity_risk','lead_priority'
    related_record_id UUID,
    confidence_score DECIMAL(3,2),
    recommended_actions JSONB,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE insight_models (
    model_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    model_type VARCHAR(50) NOT NULL,
    training_metrics JSONB,
    active_version VARCHAR(50),
    retrain_frequency INTERVAL DEFAULT '30 days'
);

--Sandbox Environments
CREATE TABLE sandbox_environments (
    sandbox_id UUID PRIMARY KEY,
    org_id UUID REFERENCES organizations(org_id),
    source_environment VARCHAR(50) NOT NULL,
    copy_config JSONB NOT NULL, -- Which data to include
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    storage_size BIGINT
);

CREATE TABLE sandbox_refresh_history (
    refresh_id UUID PRIMARY KEY,
    sandbox_id UUID REFERENCES sandbox_environments(sandbox_id),
    status VARCHAR(20) NOT NULL,
    duration INTERVAL,
    record_counts JSONB
);

--change data capture
CREATE TABLE cdc_events (
    event_id UUID PRIMARY KEY,
    entity_name VARCHAR(100) NOT NULL, -- 'contacts','deals'
    record_id UUID NOT NULL,
    change_type VARCHAR(10) CHECK (change_type IN ('CREATE','UPDATE','DELETE')),
    changed_fields JSONB,
    transaction_id VARCHAR(100),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cdc_entity ON cdc_events(entity_name, record_id);

ALTER TABLE cdc_events SET (autovacuum_enabled = false);
CREATE INDEX idx_cdc_time ON cdc_events USING BRIN(event_time);


--executive dashboard views
CREATE MATERIALIZED VIEW mv_executive_overview AS
SELECT
    o.org_id,
    o.name AS org_name,
    COUNT(DISTINCT c.contact_id) AS total_contacts,
    COUNT(DISTINCT CASE WHEN c.lead_status = 'converted' THEN c.contact_id END) AS converted_leads,
    COUNT(DISTINCT d.deal_id) AS total_deals,
    SUM(d.amount) AS total_revenue,
    (SELECT COUNT(DISTINCT member_id) FROM loyalty_members WHERE program_id IN
        (SELECT program_id FROM loyalty_programs WHERE org_id = o.org_id)) AS loyalty_members,
    (SELECT SUM(available_points) FROM loyalty_members WHERE program_id IN
        (SELECT program_id FROM loyalty_programs WHERE org_id = o.org_id)) AS outstanding_points_value
FROM organizations o
LEFT JOIN contacts c ON o.org_id = c.org_id
LEFT JOIN deals d ON o.org_id = d.org_id AND d.stage = 'closed_won'
GROUP BY o.org_id;

CREATE VIEW vw_customer_journey_health AS
WITH journey_metrics AS (
    SELECT
        org_id,
        COUNT(*) AS total_journeys,
        AVG(engagement_score) AS avg_engagement,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY engagement_score) AS median_engagement,
        COUNT(*) FILTER (WHERE engagement_score < 50) AS low_engagement_count
    FROM customer_journeys
    GROUP BY org_id
)
SELECT
    jm.*,
    (low_engagement_count::FLOAT / total_journeys) AS low_engagement_pct,
    (SELECT COUNT(*) FROM contacts c WHERE c.org_id = jm.org_id AND c.lead_status = 'converted') AS converted_count
FROM journey_metrics jm;


--real-time KPI steaming view
CREATE VIEW vw_realtime_kpi_pulse AS
SELECT
    k.kpi_id,
    k.name AS kpi_name,
    k.period,
    d.value AS current_value,
    p.forecast_model,
    p.confidence_interval,
    a.anomaly_id IS NOT NULL AS has_anomaly
FROM kpi_definitions k
JOIN LATERAL (
    SELECT value
    FROM kpi_data
    WHERE kpi_id = k.kpi_id
    ORDER BY measured_at DESC
    LIMIT 1
) d ON true
LEFT JOIN predictive_kpis p ON k.kpi_id = p.base_kpi_id
LEFT JOIN kpi_anomalies a ON k.kpi_id = a.kpi_id AND a.status = 'unreviewed';


--loyalty program automation
CREATE OR REPLACE FUNCTION process_loyalty_earning()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-process points for qualified activities
    INSERT INTO loyalty_events (member_id, event_type, points_value)
    SELECT
        lm.member_id,
        'earn',
        (NEW.amount * lp.earning_rules->>'purchase_multiplier')::INT
    FROM loyalty_members lm
    JOIN loyalty_programs lp ON lm.program_id = lp.program_id
    WHERE lm.contact_id = NEW.contact_id
    AND lp.earning_rules->>'purchase_multiplier' IS NOT NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchase_to_loyalty
AFTER INSERT ON deals
FOR EACH ROW WHEN (NEW.stage = 'closed_won')
EXECUTE FUNCTION process_loyalty_earning();


--KPI benchmarking
CREATE TABLE industry_benchmarks (
    benchmark_id UUID PRIMARY KEY,
    industry VARCHAR(100) NOT NULL,
    kpi_name VARCHAR(100) NOT NULL,
    percentile_25 DECIMAL(15,2),
    percentile_50 DECIMAL(15,2),
    percentile_75 DECIMAL(15,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW vw_kpi_vs_benchmark AS
SELECT
    k.kpi_id,
    k.name AS kpi_name,
    d.value AS our_value,
    b.percentile_50 AS industry_median,
    (d.value - b.percentile_50) AS difference,
    (d.value / NULLIF(b.percentile_50, 0)) AS percent_of_benchmark
FROM kpi_definitions k
JOIN LATERAL (
    SELECT value
    FROM kpi_data
    WHERE kpi_id = k.kpi_id
    ORDER BY measured_at DESC
    LIMIT 1
) d ON true
JOIN organizations o ON k.org_id = o.org_id
JOIN industry_benchmarks b ON b.industry = o.industry AND b.kpi_name = k.name;






--virtual world assets integration
CREATE TABLE virtual_world_assets (
    asset_id UUID PRIMARY KEY,
    metaverse_platform VARCHAR(50),
    virtual_coordinates JSONB,
    nft_metadata JSONB,
    commerce_enabled BOOLEAN
);

CREATE TABLE virtual_commerce_events (
    event_id UUID PRIMARY KEY,
    contact_id UUID REFERENCES contacts(contact_id),
    asset_id UUID REFERENCES virtual_world_assets(asset_id),
    event_type VARCHAR(50),
    virtual_currency_amount DECIMAL(15,2),
    real_world_value DECIMAL(15,2)
);

--nice to have
CREATE TABLE encrypted_data_vault (
    vault_id UUID PRIMARY KEY,
    encrypted_payload BYTEA,
    encryption_metadata JSONB,
    post_quantum_signature TEXT,
    access_policy JSONB
);

--end of nice to have

-- Views for common queries
CREATE VIEW vw_lead_conversion_metrics AS
SELECT
    c.org_id,
    COUNT(*) AS total_leads,
    COUNT(CASE WHEN c.lead_status = 'converted' THEN 1 END) AS converted_leads,
    ROUND(COUNT(CASE WHEN c.lead_status = 'converted' THEN 1 END)::numeric / COUNT(*), 2) AS conversion_rate,
    AVG(c.lead_score) AS avg_lead_score
FROM contacts c
GROUP BY c.org_id;

-- Materialized views for performance
CREATE MATERIALIZED VIEW mv_daily_kpi_snapshot AS
SELECT
    org_id,
    DATE(created_at) AS snapshot_date,
    COUNT(*) AS new_contacts,
    COUNT(DISTINCT session_id) AS unique_visitors,
    COUNT(CASE WHEN lead_status = 'converted' THEN 1 END) AS converted_leads
FROM contacts c
LEFT JOIN visitor_sessions vs ON c.contact_id = vs.contact_id
GROUP BY org_id, DATE(created_at);

-- Stored procedures
CREATE OR REPLACE FUNCTION process_rtbf_request(contact_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Anonymize contact data
    UPDATE contacts SET
        first_name = 'Anonymous',
        last_name = 'User',
        email = CONCAT('anon_', uuid_generate_v4(), '@deleted.example'),
        phone = NULL,
        company = NULL,
        job_title = NULL,
        deleted_at = CURRENT_TIMESTAMP
    WHERE contact_id = contact_id;

    -- Log the deletion
    INSERT INTO audit_logs (org_id, action, entity_type, entity_id)
    SELECT org_id, 'RTBF_REQUEST', 'contact', contact_id
    FROM contacts WHERE contact_id = contact_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Indexes for performance
CREATE INDEX idx_contacts_org_email ON contacts(org_id, email);
CREATE INDEX idx_visitor_sessions_contact ON visitor_sessions(contact_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- Security: Row-level security policies (PostgreSQL 9.5+)
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY contacts_org_policy ON contacts
    USING (org_id = current_setting('app.current_org_id')::UUID);

-- Documentation comments
COMMENT ON TABLE contacts IS 'Centralized customer/lead database with full activity tracking';
COMMENT ON COLUMN contacts.lead_score IS 'Calculated score (0-100) based on engagement and fit';
COMMENT ON MATERIALIZED VIEW mv_daily_kpi_snapshot IS 'Pre-aggregated daily metrics for dashboard performance';

-- Database triggers for maintaining data integrity
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_contacts_timestamp
BEFORE UPDATE ON contacts
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_campaigns_timestamp
BEFORE UPDATE ON marketing_campaigns
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Enhanced functions for AI/ML features
CREATE OR REPLACE FUNCTION calculate_lead_score(p_contact_id UUID)
RETURNS INT AS $$
DECLARE
    v_score INT;
    v_engagement FLOAT;
    v_fit FLOAT;
BEGIN
    -- Calculate engagement component (based on activities)
    SELECT COALESCE(SUM(
        CASE
            WHEN event_type = 'page_view' THEN 1
            WHEN event_type = 'form_submit' THEN 5
            WHEN event_type = 'download' THEN 3
            ELSE 0
        END), 0) * 0.5
    INTO v_engagement
    FROM visitor_events ve
    JOIN visitor_sessions vs ON ve.session_id = vs.session_id
    WHERE vs.contact_id = p_contact_id;

    -- Calculate fit component (based on profile)
    SELECT
        CASE
            WHEN job_title LIKE '%Manager%' THEN 30
            WHEN job_title LIKE '%Director%' THEN 40
            WHEN job_title LIKE '%VP%' THEN 50
            WHEN job_title LIKE '%C-Level%' THEN 60
            ELSE 10
        END +
        CASE WHEN company IS NOT NULL THEN 10 ELSE 0 END
    INTO v_fit
    FROM contacts
    WHERE contact_id = p_contact_id;

    -- Combine components (max 100)
    v_score := LEAST(v_engagement + v_fit, 100);

    -- Update the contact record
    UPDATE contacts SET lead_score = v_score WHERE contact_id = p_contact_id;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- GDPR compliance functions
CREATE OR REPLACE FUNCTION check_consent(p_contact_id UUID, p_consent_type consent_type)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_consent BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM consent_records
        WHERE contact_id = p_contact_id
        AND consent_type = p_consent_type
        AND granted = TRUE
        AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    ) INTO v_has_consent;

    RETURN v_has_consent;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced reporting function
CREATE OR REPLACE FUNCTION generate_campaign_report(p_campaign_id UUID)
RETURNS TABLE (
    metric_name VARCHAR,
    metric_value NUMERIC,
    change_from_previous NUMERIC,
    target_value NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH campaign_stats AS (
        SELECT
            COUNT(DISTINCT c.contact_id) AS total_leads,
            COUNT(DISTINCT CASE WHEN c.lead_status = 'converted' THEN c.contact_id END) AS converted_leads,
            SUM(d.amount) AS revenue_generated,
            (SELECT budget FROM marketing_campaigns WHERE campaign_id = p_campaign_id) AS budget
        FROM contacts c
        LEFT JOIN deals d ON c.contact_id = d.contact_id
        WHERE c.campaign_id = p_campaign_id
    )
    SELECT
        'Leads Generated'::VARCHAR,
        total_leads::NUMERIC,
        NULL::NUMERIC,
        NULL::NUMERIC
    FROM campaign_stats
    UNION ALL
    SELECT
        'Conversion Rate'::VARCHAR,
        ROUND((converted_leads::FLOAT / NULLIF(total_leads, 0)) * 100, 2),
        NULL::NUMERIC,
        NULL::NUMERIC
    FROM campaign_stats
    UNION ALL
    SELECT
        'ROI'::VARCHAR,
        CASE WHEN budget > 0 THEN ROUND((revenue_generated - budget) / budget * 100, 2) ELSE NULL END,
        NULL::NUMERIC,
        NULL::NUMERIC
    FROM campaign_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Data quality monitoring function
CREATE OR REPLACE FUNCTION check_data_quality(p_org_id UUID)
RETURNS TABLE (
    rule_name VARCHAR,
    field_path VARCHAR,
    error_count BIGINT,
    last_checked TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dqr.name AS rule_name,
        dqr.field_path,
        COUNT(*) AS error_count,
        MAX(audit_logs.created_at) AS last_checked
    FROM data_quality_rules dqr
    LEFT JOIN audit_logs ON
        audit_logs.org_id = p_org_id AND
        audit_logs.action = 'DATA_VALIDATION_FAILED' AND
        audit_logs.entity_type = 'contact' AND
        audit_logs.new_values->>'rule_id' = dqr.rule_id::TEXT
    WHERE dqr.org_id = p_org_id AND dqr.is_active = TRUE
    GROUP BY dqr.rule_id, dqr.name, dqr.field_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Setup default data
INSERT INTO organizations (org_id, name, domain)
VALUES ('00000000-0000-0000-0000-000000000000', 'System Template', 'template.example');

-- Insert default sales funnel stages
INSERT INTO sales_funnels (org_id, name, description, stages, is_default)
VALUES ('00000000-0000-0000-0000-000000000000', 'Default Sales Funnel', 'Standard sales process',
        '[{"name": "Prospect", "probability": 10}, {"name": "Qualified", "probability": 30},
          {"name": "Proposal", "probability": 50}, {"name": "Negotiation", "probability": 70},
          {"name": "Closed Won", "probability": 100}, {"name": "Closed Lost", "probability": 0}]',
        TRUE);
