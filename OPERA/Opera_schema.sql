-- O.P.E.R.A DATABASE SCHEMA
--Version 1.0
-- Date: 2025-04-05
--2025 Copyright Beta ORI Inc. Canada
-- Author: Awase Khirni Syed Ph.D.
--Module 01: INCIDENT INTELLIGENCE ENGINE (IIE)
--Purpose: it enables real-time event processing, intelligent correlations
-- ML-driven anomaly detection, root cause suggestion, auto-triage and prescriptive analytics_core

--Execution Note:
-- Requires super user privileges due to the extension creation
-- ensure TimescaleDB is installed before running

--Enums list
-- event_severity, alert_status, incident_priority, correlation_type
---- resolution_status, model_lifecycle_stage, access_level
---- environment_type, change_impact_category, sentiment_polarity

-- Tables List
-- iie.raw_events - Raw event ingestion
---- iie.enriched_events - Context-enriched events
---- iie.correlated_incidents - Unified incident records
---- iie.incident_correlations - Event-incident relationships
---- iie.ml_models - ML model registry
---- iie.model_feedback_log - Human feedback tracking
-- =============================================================================
-- 1. SCHEMA CREATION
-- ------------------------------------------------------------------------------
-- Purpose: Create a dedicated schema for the Incident Intelligence Engine (IIE).
-- Ensures modularity, access control, and logical grouping of related objects.
-- =============================================================================

DROP SCHEMA IF EXISTS iie CASCADE;
CREATE SCHEMA IF NOT EXISTS iie;

COMMENT ON SCHEMA iie IS
'Incident Intelligence Engine (IIE) - Core module responsible for transforming raw operational events into actionable intelligence through real-time processing, correlation, ML-driven anomaly detection, root cause suggestion, auto-triage, and prescriptive recommendations.
All tables, views, functions, and types within this schema support the end-to-end lifecycle of incident understanding and response optimization.';
-- =============================================================================
-- 2. EXTENSIONS
-- ------------------------------------------------------------------------------
-- Purpose: Enable advanced PostgreSQL capabilities required for scalability,
-- analytics, security, and AI/ML integration.
-- Each extension is documented with its purpose and functional contribution.
-- =============================================================================

-- Generate UUIDs for globally unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA pg_catalog;

COMMENT ON EXTENSION "uuid-ossp" IS
'Generates UUIDs (v1, v4) for globally unique identifiers across distributed systems. Used for incident IDs, event fingerprints, session tracking, and secure references throughout O.P.E.R.A. Critical for multi-source aggregation (IIE-002) and synthetic testing (IIE-059).';

-- Cryptographic functions for hashing and token generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA public;

COMMENT ON EXTENSION "pgcrypto" IS
'Provides cryptographic functions (e.g., digest, hmac, gen_salt). Used for secure hashing in alert deduplication (IIE-003), anonymization, and authentication tokens. Supports integrity checks and noise suppression filtering (IIE-004).';

-- B-tree indexing over GIN for composite searches on arrays/tags
CREATE EXTENSION IF NOT EXISTS "btree_gin" WITH SCHEMA public;

COMMENT ON EXTENSION "btree_gin" IS
'Allows B-tree values (e.g., timestamps, integers) to be indexed using GIN. Optimizes queries combining temporal filters with tag-based metadata searches. Essential for contextual enrichment (IIE-039) and service health scoring (IIE-031).';

-- Support for exclusion constraints and range queries
CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA public;

COMMENT ON EXTENSION "btree_gist" IS
'Supports exclusion constraints and efficient overlap queries (e.g., time ranges). Crucial for maintenance window logic (IIE-062), temporal correlation (IIE-006), and silent mode enforcement. Prevents conflicting schedules or overlapping alerts.';

-- Efficient integer array operations
CREATE EXTENSION IF NOT EXISTS "intarray" WITH SCHEMA public;

COMMENT ON EXTENSION "intarray" IS
'Enables fast intersection, union, and containment operations on integer arrays. Used in dependency mapping (IIE-007), team assignment algorithms (IIE-044), and cascading failure simulation (IIE-069). Enhances performance in graph-based traversals.';

-- Key-value storage for flexible metadata
CREATE EXTENSION IF NOT EXISTS "hstore" WITH SCHEMA public;

COMMENT ON EXTENSION "hstore" IS
'Key-value pair storage within a single column. Ideal for dynamic metadata enrichment (IIE-039), tagging (IIE-040), and storing transient context without schema changes. Enables self-service labeling and business function mapping (IIE-042).';

CREATE EXTENSION IF NOT EXISTS vector CASCADE;

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
-- Time-series database engine
CREATE EXTENSION IF NOT EXISTS "timescaledb" WITH SCHEMA public;

COMMENT ON EXTENSION "timescaledb" IS
'Turns PostgreSQL into a scalable time-series database. Automatically partitions data into chunks, enables compression, and supports continuous aggregates. Foundational for high-volume event streams (IIE-001), metric outlier detection (IIE-016), and historical trend comparison (IIE-064).';

-- Optional: Uncomment if vector search is enabled (e.g., pgvector)
-- CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA public;
-- COMMENT ON EXTENSION "vector" IS 'Supports embedding storage and cosine similarity search for NLU (IIE-010), semantic matching (IIE-011), and knowledge retrieval (IIE-027).';


-- =============================================================================
-- 3. ENUMS
-- ------------------------------------------------------------------------------
-- Purpose: Define enumerated types to standardize domain values, ensure data
-- integrity, and improve readability. Each enum includes documentation and list
-- of possible values.
-- =============================================================================

-- Drop existing enums safely
DO $$ BEGIN
    DROP TYPE IF EXISTS iie.event_severity;
    DROP TYPE IF EXISTS iie.alert_status;
    DROP TYPE IF EXISTS iie.incident_priority;
    DROP TYPE IF EXISTS iie.correlation_type;
    DROP TYPE IF EXISTS iie.resolution_status;
    DROP TYPE IF EXISTS iie.model_lifecycle_stage;
    DROP TYPE IF EXISTS iie.access_level;
    DROP TYPE IF EXISTS iie.environment_type;
    DROP TYPE IF EXISTS iie.change_impact_category;
    DROP TYPE IF EXISTS iie.sentiment_polarity;
END $$;

-- Enum: Severity levels for events/incidents
CREATE TYPE iie.event_severity AS ENUM (
    'info',        -- Low impact, informational only
    'warning',     -- Potential issue, requires monitoring
    'error',       -- Functional degradation
    'critical'     -- Severe outage or security threat
);

COMMENT ON TYPE iie.event_severity IS
'Indicates the technical and business impact level of an event. Drives routing, escalation, SLA handling, and UI prioritization.
Used in Dynamic Severity Scoring (IIE-005), Security Triaging (IIE-092), and Noise Suppression (IIE-004).';

-- Enum: Alert lifecycle status
CREATE TYPE iie.alert_status AS ENUM (
    'active',      -- New alert triggered
    'suppressed',  -- Intentionally muted (e.g., maintenance)
    'deduplicated',-- Merged with another alert
    'correlated',  -- Linked to an incident
    'resolved',    -- Successfully closed
    'ignored'      -- Marked as false positive
);

COMMENT ON TYPE iie.alert_status IS
'Lifecycle state of an alert from ingestion to closure. Supports audit trails, feedback loops (IIE-052), and KPI tracking such as False Positive Reduction % (IIE-013).';

-- Enum: Incident priority (AI-assigned or manual)
CREATE TYPE iie.incident_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

COMMENT ON TYPE iie.incident_priority IS
'Priority assigned based on user impact, SLA risk, and system criticality (IIE-048, IIE-049). Influences queue ordering (IIE-061), resource allocation, and executive visibility.';

-- Enum: Correlation method used
CREATE TYPE iie.correlation_type AS ENUM (
    'temporal',           -- Events close in time (IIE-006)
    'topological',        -- Based on service dependencies (IIE-007)
    'semantic',           -- Similar meaning/title (IIE-011)
    'statistical',        -- Outlier clusters (IIE-016)
    'cross-domain'        -- Across IT, support, finance (IIE-017)
);

COMMENT ON TYPE iie.correlation_type IS
'Method used to link related events during correlation. Enables attribution of effectiveness per technique and supports Explainable AI (IIE-055).';

-- Enum: Resolution outcome
CREATE TYPE iie.resolution_status AS ENUM (
    'fixed',
    'workaround_applied',
    'false_positive',
    'deferred',
    'unresolved'
);

COMMENT ON TYPE iie.resolution_status IS
'Final disposition of an incident after investigation. Used in recurrence estimation (IIE-024), PIR automation (IIE-014), and model retraining (IIE-080).';

-- Enum: ML Model Lifecycle Stage
CREATE TYPE iie.model_lifecycle_stage AS ENUM (
    'development',
    'testing',
    'production',
    'deprecated',
    'archived'
);

COMMENT ON TYPE iie.model_lifecycle_stage IS
'Tracks deployment stage of ML models (IIE-054). Supports drift monitoring (IIE-053), rollback safety, and compliance reporting (IIE-095).';

-- Enum: Access sensitivity level
CREATE TYPE iie.access_level AS ENUM (
    'public',
    'internal',
    'confidential',
    'restricted'
);

COMMENT ON TYPE iie.access_level IS
'Used for RBAC (IIE-096), compliance flagging (IIE-093), and secure audit mode (IIE-097). Aligns with GDPR/HIPAA classifications and supports ethical AI governance (IIE-121).';

-- Enum: Environment type
CREATE TYPE iie.environment_type AS ENUM (
    'prod',
    'staging',
    'dev',
    'canary',
    'dark_launch'
);

COMMENT ON TYPE iie.environment_type IS
'Supports canary analysis (IIE-084), blue-green monitoring (IIE-085), and dark launch detection (IIE-098). Enables comparative analytics and regression catching.';

-- Enum: Change Impact Category
CREATE TYPE iie.change_impact_category AS ENUM (
    'deployment',
    'config_change',
    'feature_flag_toggle',
    'license_expiration',
    'capacity_threshold'
);

COMMENT ON TYPE iie.change_impact_category IS
'Categorizes operational changes linked to incidents (IIE-030, IIE-086, IIE-088). Enables RCA acceleration and long-term remediation planning.';

-- Enum: Sentiment Polarity
CREATE TYPE iie.sentiment_polarity AS ENUM (
    'positive',
    'neutral',
    'negative',
    'severe_stress'
);

COMMENT ON TYPE iie.sentiment_polarity IS
'Result of sentiment analysis on communication logs (IIE-028). Used to assess cognitive load (IIE-074), responder fatigue (IIE-047), and team coordination quality.';


--------
--checks for timescaledb 

-- CREATE EXTENSION IF NOT EXISTS timescaledb;
-- -- Check if TimescaleDB extension is available
-- SELECT name, default_version, installed_version 
-- FROM pg_available_extensions 
-- WHERE name = 'timescaledb';

-- -- Check if extension is installed
-- SELECT * FROM pg_extension WHERE extname = 'timescaledb';

-- -- Check loaded shared libraries (requires superuser)
-- SHOW shared_preload_libraries;

-- =============================================================================
-- 4. DDL STATEMENTS
-- ------------------------------------------------------------------------------
-- For each table:
--   - Name
--   - Description
--   - Business Case
--   - KPIs
--   - Feature References (Traceability)
-- =============================================================================

-- ----------------------------------------------------------------------
-- TABLE: iie.raw_events
--
-- DESCRIPTION:
-- Stores all incoming raw events from monitoring tools before processing.
-- Serves as immutable source of truth for replay (IIE-122), forensic analysis (IIE-025),
-- and synthetic testing (IIE-059). Designed for high-throughput ingestion.
--
-- BUSINESS CASE:
-- Enable lossless, scalable ingestion of heterogeneous event streams (logs, metrics, traces)
-- from diverse sources (Datadog, Jira, Splunk, Prometheus, etc.) to eliminate tool silos (IIE-002).
--
-- KPIS:
-- - Event Processing Latency: Time between event_timestamp and processed_at
-- - % Alerts Aggregated: Count distinct sources / total expected tools
--
-- FEATURE REFERENCES:
-- IIE-001, IIE-002, IIE-003, IIE-059, IIE-122
-- ----------------------------------------------------------------------

-- Drop table if exists
DROP TABLE IF EXISTS iie.raw_events;

-- Create the table with native partitioning
CREATE TABLE iie.raw_events (
    event_id UUID NOT NULL DEFAULT gen_random_uuid(),
    source_system TEXT NOT NULL,                    -- e.g., Datadog, Jira, Slack
    source_instance TEXT,                           -- Hostname, pod, service
    event_timestamp TIMESTAMPTZ NOT NULL,           -- When event occurred
    received_at TIMESTAMPTZ DEFAULT NOW(),          -- When ingested into O.P.E.R.A
    payload JSONB NOT NULL,                         -- Full unstructured content
    fingerprint TEXT,                               -- SHA-256 hash for deduplication
    tenant_id UUID,                                 -- For multi-tenancy (IIE-106)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (event_id, event_timestamp)  -- Include partition key in primary key
) PARTITION BY RANGE (event_timestamp);

-- Create monthly partitions for current and next months
CREATE TABLE iie.raw_events_current PARTITION OF iie.raw_events
    FOR VALUES FROM (date_trunc('month', NOW())) TO (date_trunc('month', NOW()) + INTERVAL '1 month');

CREATE TABLE iie.raw_events_next_1 PARTITION OF iie.raw_events
    FOR VALUES FROM (date_trunc('month', NOW()) + INTERVAL '1 month') TO (date_trunc('month', NOW()) + INTERVAL '2 months');

CREATE TABLE iie.raw_events_next_2 PARTITION OF iie.raw_events
    FOR VALUES FROM (date_trunc('month', NOW()) + INTERVAL '2 months') TO (date_trunc('month', NOW()) + INTERVAL '3 months');

-- Create default partition for any data that doesn't fit
CREATE TABLE iie.raw_events_default PARTITION OF iie.raw_events DEFAULT;

-- Create regular indexes (not concurrent) for initial setup
CREATE INDEX IF NOT EXISTS idx_raw_events_timestamp ON iie.raw_events (event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_raw_events_source_system ON iie.raw_events (source_system, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_raw_events_tenant ON iie.raw_events (tenant_id, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_raw_events_fingerprint ON iie.raw_events (fingerprint);
CREATE INDEX IF NOT EXISTS idx_raw_events_payload_gin ON iie.raw_events USING GIN (payload);


-- ----------------------------------------------------------------------
-- TABLE: iie.enriched_events
--
-- DESCRIPTION:
-- Post-processing layer where raw events are augmented with business context,
-- geolocation, financial impact, and semantic embeddings. Forms basis for
-- intelligent triage, prioritization, and cross-domain insight.
--
-- BUSINESS CASE:
-- Transform technical alerts into business-aware events using contextual enrichment
-- (IIE-039), cost modeling (IIE-043), and semantic understanding (IIE-010).
--
-- KPIS:
-- - Enrichment Coverage %: Proportion of events with enriched fields
-- - Customer Impact Accuracy: Validated against actual outage reports
--
-- FEATURE REFERENCES:
-- IIE-039, IIE-040, IIE-041, IIE-042, IIE-043, IIE-030, IIE-086, IIE-011
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS iie.enriched_events;
CREATE TABLE iie.enriched_events (
    enriched_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL,
    event_timestamp TIMESTAMPTZ NOT NULL,  -- Added for partitioning compatibility
    service_name TEXT,
    host_name TEXT,
    error_code TEXT,
    user_impact_estimate INTEGER,
    geo_location POINT,                             -- (longitude, latitude)
    business_function TEXT,                         -- e.g., checkout, billing
    sla_tier TEXT,
    cost_per_minute NUMERIC(10,2),                  -- USD/min downtime cost
    change_id UUID,                                 -- Git/Jira commit ID
    feature_flag TEXT,
    environment TEXT CHECK (environment IN ('development', 'staging', 'production')),
    severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
    priority TEXT CHECK (priority IN ('P0', 'P1', 'P2', 'P3', 'P4')),
    tags JSONB,                                     -- Using JSONB instead of HSTORE for better compatibility
    embedding vector(384),                          -- pgvector embedding (optional)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (event_id, event_timestamp) REFERENCES iie.raw_events(event_id, event_timestamp) ON DELETE CASCADE
);

-- Regular indexes for initial setup
CREATE INDEX IF NOT EXISTS idx_enriched_events_service ON iie.enriched_events(service_name);
CREATE INDEX IF NOT EXISTS idx_enriched_events_severity ON iie.enriched_events(severity);
CREATE INDEX IF NOT EXISTS idx_enriched_events_tags ON iie.enriched_events USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_enriched_events_event_id ON iie.enriched_events(event_id, event_timestamp);
CREATE INDEX IF NOT EXISTS idx_enriched_events_timestamp ON iie.enriched_events(event_timestamp DESC);


-- ----------------------------------------------------------------------
-- TABLE: iie.correlated_incidents
--
-- DESCRIPTION:
-- Unified incident record formed by correlating multiple events. Represents
-- a logical problem requiring response. Contains AI-generated insights including
-- root cause, confidence, explanations, and predicted outcomes.
--
-- BUSINESS CASE:
-- Replace fragmented alerts with coherent incidents that include predictive
-- intelligence (MTTR prediction), prescriptive actions, and business impact.
--
-- KPIS:
-- - MTTD, MTTR: Derived from timestamps
-- - First-Suggestion Accuracy Rate: Compare suggested vs actual root cause
-- - SLA Compliance %: Based on breach risk forecasts
--
-- FEATURE REFERENCES:
-- IIE-006–007, IIE-009, IIE-037, IIE-048–049, IIE-051, IIE-055, IIE-075, IIE-100, IIE-120
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS iie.correlated_incidents;
CREATE TABLE iie.correlated_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    summary TEXT,
    severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')) NOT NULL,
    priority TEXT CHECK (priority IN ('P0', 'P1', 'P2', 'P3', 'P4')) NOT NULL,
    status TEXT CHECK (status IN ('active', 'resolved', 'acknowledged', 'suppressed')) DEFAULT 'active',
    detected_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ,
    mtt_detection INTERVAL,
    mtt_response INTERVAL,
    mtt_resolution INTERVAL,
    root_cause_suggestion TEXT,
    root_cause_confidence NUMERIC(3,2),
    xai_explanation JSONB,
    complexity_score NUMERIC(4,2),
    fatigue_risk_score NUMERIC(3,2),
    sla_breach_risk NUMERIC(3,2),
    predicted_resolution_time INTERVAL,
    resilience_score_before NUMERIC(3,2),
    resilience_score_after NUMERIC(3,2),
    carbon_impact_kg_co2 NUMERIC(8,4),
    tenant_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Regular indexes for initial setup
CREATE INDEX IF NOT EXISTS idx_correlated_incidents_sev_pri ON iie.correlated_incidents(severity, priority);
CREATE INDEX IF NOT EXISTS idx_correlated_incidents_status ON iie.correlated_incidents(status);
CREATE INDEX IF NOT EXISTS idx_correlated_incidents_detected ON iie.correlated_incidents(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_correlated_incidents_root_cause ON iie.correlated_incidents(root_cause_suggestion);
CREATE INDEX IF NOT EXISTS idx_correlated_incidents_tenant ON iie.correlated_incidents(tenant_id);


-- ----------------------------------------------------------------------
-- TABLE: iie.incident_correlations
--
-- DESCRIPTION:
-- Junction table linking raw events to correlated incidents, capturing how
-- they were associated (temporal, topological, etc.) and with what confidence.
--
-- BUSINESS CASE:
-- Maintain provenance and evidence trail for every correlation decision.
-- Supports Explainable AI (IIE-055) and forensic review (IIE-025).
--
-- KPIS:
-- - Dependency Chain Coverage: % of known dependencies correctly identified
-- - Cross-Domain Insight Yield: Number of inter-system correlations detected
--
-- FEATURE REFERENCES:
-- IIE-006–007, IIE-017, IIE-064, IIE-069, IIE-072
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS iie.incident_correlations;
CREATE TABLE iie.incident_correlations (
    correlation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    event_id UUID NOT NULL,
    event_timestamp TIMESTAMPTZ NOT NULL,  -- Added for partitioning compatibility
    correlation_type TEXT CHECK (correlation_type IN ('temporal', 'topological', 'semantic', 'causal', 'statistical')) NOT NULL,
    confidence_score NUMERIC(3,2) NOT NULL,
    evidence_path TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (event_id, event_timestamp) REFERENCES iie.raw_events(event_id, event_timestamp)
);

CREATE INDEX IF NOT EXISTS idx_incident_correlations_incident ON iie.incident_correlations(incident_id);
CREATE INDEX IF NOT EXISTS idx_incident_correlations_type ON iie.incident_correlations(correlation_type);
CREATE INDEX IF NOT EXISTS idx_incident_correlations_event ON iie.incident_correlations(event_id, event_timestamp);


-- ----------------------------------------------------------------------
-- TABLE: iie.ml_models
--
-- DESCRIPTION:
-- Registry of all ML models powering the IIE. Tracks version, performance,
-- lifecycle stage, drift detection, and configuration.
--
-- BUSINESS CASE:
-- Centralize model observability (IIE-054), enable retraining pipelines,
-- and support concept drift monitoring (IIE-053).
--
-- KPIS:
-- - Model Observability Score: % models with active monitoring
-- - Drift Detection Latency: Time between drift onset and detection
--
-- FEATURE REFERENCES:
-- IIE-008–015, IIE-053–058, IIE-060, IIE-079, IIE-080, IIE-117
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS iie.ml_models;
CREATE TABLE iie.ml_models (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    task TEXT NOT NULL,
    algorithm TEXT NOT NULL,
    stage TEXT CHECK (stage IN ('development', 'staging', 'production', 'retired')) DEFAULT 'development',
    accuracy NUMERIC(4,3),
    precision NUMERIC(4,3),
    recall NUMERIC(4,3),
    f1_score NUMERIC(4,3),
    drift_detected_at TIMESTAMPTZ,
    last_trained_at TIMESTAMPTZ DEFAULT NOW(),
    config JSONB,
    artifact_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ml_models_task ON iie.ml_models(task);
CREATE INDEX IF NOT EXISTS idx_ml_models_stage ON iie.ml_models(stage);
CREATE INDEX IF NOT EXISTS idx_ml_models_name_version ON iie.ml_models(name, version);


-- ----------------------------------------------------------------------
-- TABLE: iie.model_feedback_log
--
-- DESCRIPTION:
-- Captures human feedback on AI suggestions (accept/reject/modify).
-- Drives online learning and model retraining.
--
-- BUSINESS CASE:
-- Close the loop between AI predictions and human expertise to improve
-- accuracy over time (IIE-052, IIE-080).
--
-- KPIS:
-- - Model Accuracy Improvement Rate: Trend over feedback cycles
--
-- FEATURE REFERENCES:
-- IIE-052, IIE-080
-- ----------------------------------------------------------------------

DROP TABLE IF EXISTS iie.model_feedback_log;
CREATE TABLE iie.model_feedback_log (
    feedback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    input_data JSONB NOT NULL,
    prediction JSONB NOT NULL,
    user_action TEXT NOT NULL CHECK (user_action IN ('accepted', 'rejected', 'modified')),
    explanation_helpful BOOLEAN,
    notes TEXT,
    responded_by UUID,
    responded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_model_feedback_model ON iie.model_feedback_log(model_id);
CREATE INDEX IF NOT EXISTS idx_model_feedback_incident ON iie.model_feedback_log(incident_id);
CREATE INDEX IF NOT EXISTS idx_model_feedback_action ON iie.model_feedback_log(user_action);


-- Create update trigger function for updated_at timestamps
CREATE OR REPLACE FUNCTION iie.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at columns
CREATE TRIGGER trigger_update_enriched_events_updated_at
    BEFORE UPDATE ON iie.enriched_events
    FOR EACH ROW
    EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_correlated_incidents_updated_at
    BEFORE UPDATE ON iie.correlated_incidents
    FOR EACH ROW
    EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_ml_models_updated_at
    BEFORE UPDATE ON iie.ml_models
    FOR EACH ROW
    EXECUTE FUNCTION iie.update_updated_at_column();


-- Function to automatically manage partitions
CREATE OR REPLACE FUNCTION iie.create_raw_events_partitions()
RETURNS VOID AS $$
DECLARE
    partition_start DATE;
    partition_end DATE;
    partition_name TEXT;
    i INTEGER;
BEGIN
    -- Create partitions for next 12 months if they don't exist
    FOR i IN 0..11 LOOP
        partition_start := date_trunc('month', NOW()) + (i || ' months')::INTERVAL;
        partition_end := partition_start + INTERVAL '1 month';
        partition_name := 'raw_events_' || to_char(partition_start, 'YYYY_MM');
        
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'iie' AND tablename = partition_name) THEN
            EXECUTE format(
                'CREATE TABLE iie.%I PARTITION OF iie.raw_events FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                partition_start,
                partition_end
            );
            RAISE NOTICE 'Created partition: iie.%', partition_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to archive old data
CREATE OR REPLACE FUNCTION iie.archive_old_raw_events(retention_months INTEGER DEFAULT 12)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := NOW() - (retention_months || ' months')::INTERVAL;
    
    -- Create archive table if it doesn't exist
    CREATE TABLE IF NOT EXISTS iie.raw_events_archive (
        LIKE iie.raw_events INCLUDING ALL
    );
    
    -- Move old data to archive
    WITH moved_rows AS (
        DELETE FROM iie.raw_events 
        WHERE event_timestamp < cutoff_date
        RETURNING *
    )
    INSERT INTO iie.raw_events_archive
    SELECT * FROM moved_rows;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate MTTD for incidents
CREATE OR REPLACE FUNCTION iie.calculate_incident_mttd(incident_id UUID)
RETURNS INTERVAL AS $$
DECLARE
    first_event_time TIMESTAMPTZ;
    detection_time TIMESTAMPTZ;
    result INTERVAL;
BEGIN
    SELECT detected_at INTO detection_time 
    FROM iie.correlated_incidents 
    WHERE incident_id = calculate_incident_mttd.incident_id;
    
    SELECT MIN(r.event_timestamp) INTO first_event_time
    FROM iie.raw_events r
    JOIN iie.incident_correlations ic ON r.event_id = ic.event_id
    WHERE ic.incident_id = calculate_incident_mttd.incident_id;
    
    IF first_event_time IS NOT NULL AND detection_time IS NOT NULL THEN
        result := detection_time - first_event_time;
    ELSE
        result := NULL;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Initialize partitions
-- SELECT iie.create_raw_events_partitions();

-- =============================================================================
-- ENHANCEMENT 1: INCIDENT RESPONSE WORKFLOW TABLES
-- ------------------------------------------------------------------------------
-- Purpose: Track incident response actions, team assignments, and communication
-- Supports: IIE-044, IIE-047, IIE-074, IIE-100

-- =============================================================================

-- Table: iie.incident_response_actions
DROP TABLE IF EXISTS iie.incident_response_actions CASCADE;
CREATE TABLE iie.incident_response_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    action_type TEXT NOT NULL CHECK (action_type IN ('mitigation', 'diagnosis', 'communication', 'escalation')),
    description TEXT NOT NULL,
    assigned_team UUID,
    assigned_individual UUID,
    status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    time_to_complete INTERVAL,
    effectiveness_score NUMERIC(3,2),
    notes TEXT
);

COMMENT ON TABLE iie.incident_response_actions IS
'Tracks prescribed and manual response actions for incidents. Supports auto-triage (IIE-100), team coordination (IIE-044), and fatigue monitoring (IIE-047).';

-- Indexes (without CONCURRENTLY for transaction compatibility)
CREATE INDEX IF NOT EXISTS idx_response_actions_incident ON iie.incident_response_actions(incident_id);
CREATE INDEX IF NOT EXISTS idx_response_actions_team ON iie.incident_response_actions(assigned_team);
CREATE INDEX IF NOT EXISTS idx_response_actions_status ON iie.incident_response_actions(status);
CREATE INDEX IF NOT EXISTS idx_response_actions_created_at ON iie.incident_response_actions(created_at);

-- Function to calculate time_to_complete
CREATE OR REPLACE FUNCTION iie.calculate_response_action_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.completed_at IS NOT NULL AND NEW.started_at IS NOT NULL THEN
        NEW.time_to_complete := NEW.completed_at - NEW.started_at;
    ELSE
        NEW.time_to_complete := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically calculate time_to_complete
CREATE TRIGGER trigger_calculate_response_time
    BEFORE INSERT OR UPDATE ON iie.incident_response_actions
    FOR EACH ROW
    EXECUTE FUNCTION iie.calculate_response_action_time();

-- Function to update effectiveness score based on incident resolution
CREATE OR REPLACE FUNCTION iie.update_action_effectiveness()
RETURNS TRIGGER AS $$
BEGIN
    -- If this action completed and incident was resolved around the same time, consider it effective
    IF NEW.status = 'completed' AND NEW.completed_at IS NOT NULL THEN
        UPDATE iie.incident_response_actions
        SET effectiveness_score = COALESCE(
            (SELECT 
                CASE 
                    WHEN c.resolved_at IS NOT NULL AND 
                         ABS(EXTRACT(EPOCH FROM (c.resolved_at - NEW.completed_at))) < 300 -- within 5 minutes
                    THEN 0.9
                    WHEN c.resolved_at IS NOT NULL AND 
                         ABS(EXTRACT(EPOCH FROM (c.resolved_at - NEW.completed_at))) < 900 -- within 15 minutes
                    THEN 0.7
                    ELSE 0.5
                END
             FROM iie.correlated_incidents c
             WHERE c.incident_id = NEW.incident_id),
            0.5
        )
        WHERE action_id = NEW.action_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update effectiveness when actions are completed
CREATE TRIGGER trigger_update_effectiveness
    AFTER UPDATE OF status ON iie.incident_response_actions
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION iie.update_action_effectiveness();

-- View for response action analytics
CREATE OR REPLACE VIEW iie.response_actions_analytics AS
SELECT 
    ira.action_id,
    ira.incident_id,
    ira.action_type,
    ira.description,
    ira.assigned_team,
    ira.assigned_individual,
    ira.status,
    ira.created_at,
    ira.started_at,
    ira.completed_at,
    ira.time_to_complete,
    ira.effectiveness_score,
    ira.notes,
    ci.title as incident_title,
    ci.severity as incident_severity,
    ci.priority as incident_priority,
    EXTRACT(EPOCH FROM ira.time_to_complete) / 60 as time_to_complete_minutes
FROM iie.incident_response_actions ira
LEFT JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id;

COMMENT ON VIEW iie.response_actions_analytics IS
'Provides analytics view of response actions with incident context for reporting and monitoring.';

-- Function to get team performance metrics
CREATE OR REPLACE FUNCTION iie.get_team_response_metrics(
    p_team_id UUID DEFAULT NULL,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    team_id UUID,
    total_actions BIGINT,
    completed_actions BIGINT,
    avg_completion_time_minutes NUMERIC,
    avg_effectiveness_score NUMERIC,
    most_common_action_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ira.assigned_team as team_id,
        COUNT(*) as total_actions,
        COUNT(*) FILTER (WHERE ira.status = 'completed') as completed_actions,
        ROUND(AVG(EXTRACT(EPOCH FROM ira.time_to_complete) / 60)::NUMERIC, 2) as avg_completion_time_minutes,
        ROUND(AVG(ira.effectiveness_score)::NUMERIC, 3) as avg_effectiveness_score,
        MODE() WITHIN GROUP (ORDER BY ira.action_type) as most_common_action_type
    FROM iie.incident_response_actions ira
    WHERE ira.created_at >= NOW() - (p_days_back || ' days')::INTERVAL
      AND (p_team_id IS NULL OR ira.assigned_team = p_team_id)
    GROUP BY ira.assigned_team;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.get_team_response_metrics IS
'Calculates team performance metrics for incident response actions over specified period.';

-- Function to get response time statistics by action type
CREATE OR REPLACE FUNCTION iie.get_action_type_metrics(p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    action_type TEXT,
    total_actions BIGINT,
    avg_completion_time_minutes NUMERIC,
    completion_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ira.action_type,
        COUNT(*) as total_actions,
        ROUND(AVG(EXTRACT(EPOCH FROM ira.time_to_complete) / 60)::NUMERIC, 2) as avg_completion_time_minutes,
        ROUND(COUNT(*) FILTER (WHERE ira.status = 'completed')::NUMERIC / COUNT(*)::NUMERIC, 3) as completion_rate
    FROM iie.incident_response_actions ira
    WHERE ira.created_at >= NOW() - (p_days_back || ' days')::INTERVAL
    GROUP BY ira.action_type
    ORDER BY total_actions DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.get_action_type_metrics IS
'Calculates performance metrics by action type for process optimization.';

-- =============================================================================
-- ENHANCEMENT 2: SERVICE DEPENDENCY GRAPH
-- ------------------------------------------------------------------------------
-- Purpose: Model service dependencies for topological correlation and impact analysis
-- Supports: IIE-007, IIE-069, IIE-072
-- features added: Recursive Dependency Traversal, Criticality Scoring, Cycle Detection, Performacne Optimization, Analyticsview 
-- =============================================================================

-- Table: iie.service_dependencies
DROP TABLE IF EXISTS iie.service_dependencies CASCADE;
CREATE TABLE iie.service_dependencies (
    dependency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_service TEXT NOT NULL,
    target_service TEXT NOT NULL,
    dependency_type TEXT NOT NULL CHECK (dependency_type IN ('api', 'database', 'message_queue', 'file_system', 'network')),
    criticality TEXT NOT NULL CHECK (criticality IN ('low', 'medium', 'high', 'critical')),
    health_check_endpoint TEXT,
    expected_latency_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(source_service, target_service)
);

COMMENT ON TABLE iie.service_dependencies IS
'Stores service dependency graph for topological correlation (IIE-007) and cascading failure simulation (IIE-069). Enables proactive impact analysis.';

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_service_deps_source ON iie.service_dependencies(source_service);
CREATE INDEX IF NOT EXISTS idx_service_deps_target ON iie.service_dependencies(target_service);
CREATE INDEX IF NOT EXISTS idx_service_deps_criticality ON iie.service_dependencies(criticality);
CREATE INDEX IF NOT EXISTS idx_service_deps_type ON iie.service_dependencies(dependency_type);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION iie.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger
DROP TRIGGER IF EXISTS trigger_update_service_deps_updated_at ON iie.service_dependencies;
CREATE TRIGGER trigger_update_service_deps_updated_at
    BEFORE UPDATE ON iie.service_dependencies
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

-- Function to find downstream dependencies (cascading impact)
CREATE OR REPLACE FUNCTION iie.get_downstream_dependencies(
    p_service_name TEXT,
    p_max_depth INTEGER DEFAULT 3
)
RETURNS TABLE (
    depth INTEGER,
    service_name TEXT,
    dependency_path TEXT[],
    criticality TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE dependency_tree AS (
        -- Base case: direct dependencies
        SELECT 
            1 as depth,
            target_service as service_name,
            ARRAY[source_service, target_service] as dependency_path,
            criticality
        FROM iie.service_dependencies
        WHERE source_service = p_service_name
        
        UNION ALL
        
        -- Recursive case: traverse downstream
        SELECT 
            dt.depth + 1,
            sd.target_service,
            dt.dependency_path || sd.target_service,
            CASE 
                WHEN sd.criticality = 'critical' OR dt.criticality = 'critical' THEN 'critical'
                WHEN sd.criticality = 'high' OR dt.criticality = 'high' THEN 'high'
                WHEN sd.criticality = 'medium' OR dt.criticality = 'medium' THEN 'medium'
                ELSE 'low'
            END
        FROM iie.service_dependencies sd
        INNER JOIN dependency_tree dt ON sd.source_service = dt.service_name
        WHERE dt.depth < p_max_depth
          AND sd.target_service != ALL(dt.dependency_path) -- Avoid cycles
    )
    SELECT DISTINCT 
        depth,
        service_name,
        dependency_path,
        criticality
    FROM dependency_tree
    ORDER BY depth, criticality DESC, service_name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.get_downstream_dependencies IS
'Recursively finds all downstream dependencies of a service for impact analysis and cascading failure simulation.';

-- Function to find upstream dependencies (root cause analysis)
CREATE OR REPLACE FUNCTION iie.get_upstream_dependencies(
    p_service_name TEXT,
    p_max_depth INTEGER DEFAULT 3
)
RETURNS TABLE (
    depth INTEGER,
    service_name TEXT,
    dependency_path TEXT[],
    criticality TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE dependency_tree AS (
        -- Base case: direct dependencies
        SELECT 
            1 as depth,
            source_service as service_name,
            ARRAY[target_service, source_service] as dependency_path,
            criticality
        FROM iie.service_dependencies
        WHERE target_service = p_service_name
        
        UNION ALL
        
        -- Recursive case: traverse upstream
        SELECT 
            dt.depth + 1,
            sd.source_service,
            sd.target_service || dt.dependency_path,
            CASE 
                WHEN sd.criticality = 'critical' OR dt.criticality = 'critical' THEN 'critical'
                WHEN sd.criticality = 'high' OR dt.criticality = 'high' THEN 'high'
                WHEN sd.criticality = 'medium' OR dt.criticality = 'medium' THEN 'medium'
                ELSE 'low'
            END
        FROM iie.service_dependencies sd
        INNER JOIN dependency_tree dt ON sd.target_service = dt.service_name
        WHERE dt.depth < p_max_depth
          AND sd.source_service != ALL(dt.dependency_path) -- Avoid cycles
    )
    SELECT DISTINCT 
        depth,
        service_name,
        dependency_path,
        criticality
    FROM dependency_tree
    ORDER BY depth, criticality DESC, service_name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.get_upstream_dependencies IS
'Recursively finds all upstream dependencies of a service for root cause analysis and dependency chain discovery.';

-- Function to calculate service criticality score (for risk assessment)
CREATE OR REPLACE FUNCTION iie.calculate_service_criticality(p_service_name TEXT)
RETURNS NUMERIC(3,2) AS $$
DECLARE
    downstream_count INTEGER;
    upstream_count INTEGER;
    max_dependencies INTEGER;
    critical_deps INTEGER;
    score NUMERIC(3,2);
BEGIN
    -- Count downstream dependencies (services that depend on this one)
    SELECT COUNT(*) INTO downstream_count
    FROM iie.get_downstream_dependencies(p_service_name, 5);
    
    -- Count upstream dependencies (services this one depends on)
    SELECT COUNT(*) INTO upstream_count
    FROM iie.get_upstream_dependencies(p_service_name, 5);
    
    -- Find maximum dependencies in the system for normalization
    SELECT MAX(dep_count) INTO max_dependencies
    FROM (
        SELECT COUNT(*) as dep_count FROM iie.service_dependencies GROUP BY source_service
        UNION ALL
        SELECT COUNT(*) as dep_count FROM iie.service_dependencies GROUP BY target_service
    ) counts;
    
    -- Count critical dependencies
    SELECT COUNT(*) INTO critical_deps
    FROM iie.service_dependencies
    WHERE (source_service = p_service_name OR target_service = p_service_name)
    AND criticality IN ('critical', 'high');
    
    -- Calculate composite score (0.0 to 1.0)
    score := (
        (downstream_count::NUMERIC / GREATEST(max_dependencies, 1)) * 0.4 +
        (upstream_count::NUMERIC / GREATEST(max_dependencies, 1)) * 0.3 +
        (critical_deps::NUMERIC / GREATEST(downstream_count + upstream_count, 1)) * 0.3
    );
    
    RETURN LEAST(score, 1.0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.calculate_service_criticality IS
'Calculates a composite criticality score for a service based on its dependency graph position and critical dependencies.';

-- View for service dependency overview
CREATE OR REPLACE VIEW iie.service_dependency_overview AS
SELECT 
    sd.dependency_id,
    sd.source_service,
    sd.target_service,
    sd.dependency_type,
    sd.criticality,
    sd.health_check_endpoint,
    sd.expected_latency_ms,
    sd.created_at,
    sd.updated_at,
    iie.calculate_service_criticality(sd.source_service) as source_criticality_score,
    iie.calculate_service_criticality(sd.target_service) as target_criticality_score
FROM iie.service_dependencies sd;

COMMENT ON VIEW iie.service_dependency_overview IS
'Provides comprehensive view of service dependencies with calculated criticality scores for impact analysis.';

-- Function to detect dependency cycles
CREATE OR REPLACE FUNCTION iie.detect_dependency_cycles()
RETURNS TABLE (
    cycle_path TEXT[],
    cycle_length INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE path_finder AS (
        SELECT 
            source_service,
            target_service,
            ARRAY[source_service, target_service] as path,
            1 as depth
        FROM iie.service_dependencies
        
        UNION ALL
        
        SELECT 
            pf.source_service,
            sd.target_service,
            pf.path || sd.target_service,
            pf.depth + 1
        FROM iie.service_dependencies sd
        INNER JOIN path_finder pf ON sd.source_service = pf.target_service
        WHERE sd.target_service != ALL(pf.path) -- Avoid revisiting nodes
          AND pf.depth < 10 -- Prevent infinite recursion
    )
    SELECT 
        path as cycle_path,
        array_length(path, 1) as cycle_length
    FROM path_finder
    WHERE path[1] = path[array_length(path, 1)]
      AND array_length(path, 1) > 2
    GROUP BY path
    ORDER BY cycle_length;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.detect_dependency_cycles IS
'Detects circular dependencies in the service graph that could cause deadlocks or infinite loops.';



-- =============================================================================
-- ENHANCEMENT 3: MODEL PERFORMANCE MONITORING
-- ------------------------------------------------------------------------------
-- Purpose: Track model performance metrics and concept drift over time
-- Supports: IIE-053, IIE-054, IIE-080
-- new features added: concept drift detection (statistical analysis to detect model performance degradation), 
-- performance trend analysis- daily trend calculations for model metrics 
--automated archiving - function to archive old metrics for performance 
-- performance overview - comprehensive view of model performance with trends 
-- automatic drift detection: trigger to automatically detect and flag concept drift 
-- partition management-- automated monthly partition creation 
-- =============================================================================
-- =============================================================================
-- ENHANCEMENT 3: MODEL PERFORMANCE MONITORING
-- ------------------------------------------------------------------------------
-- Purpose: Track model performance metrics and concept drift over time
-- Supports: IIE-053, IIE-054, IIE-080
-- =============================================================================

-- Table: iie.model_performance_metrics
DROP TABLE IF EXISTS iie.model_performance_metrics CASCADE;
CREATE TABLE iie.model_performance_metrics (
    metric_id UUID NOT NULL DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    metric_name TEXT NOT NULL,
    metric_value NUMERIC(10,6) NOT NULL,
    sample_size INTEGER,
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    window_start TIMESTAMPTZ,
    window_end TIMESTAMPTZ,
    PRIMARY KEY (metric_id, measured_at)  -- Include partition key in primary key
) PARTITION BY RANGE (measured_at);

COMMENT ON TABLE iie.model_performance_metrics IS
'Tracks temporal performance metrics for ML models to detect concept drift (IIE-053) and trigger retraining (IIE-080).';

-- Create monthly partitions for current and next 6 months
CREATE TABLE iie.model_metrics_current PARTITION OF iie.model_performance_metrics
    FOR VALUES FROM (date_trunc('month', NOW())) TO (date_trunc('month', NOW()) + INTERVAL '1 month');

CREATE TABLE iie.model_metrics_next_1 PARTITION OF iie.model_performance_metrics
    FOR VALUES FROM (date_trunc('month', NOW()) + INTERVAL '1 month') TO (date_trunc('month', NOW()) + INTERVAL '2 months');

CREATE TABLE iie.model_metrics_next_2 PARTITION OF iie.model_performance_metrics
    FOR VALUES FROM (date_trunc('month', NOW()) + INTERVAL '2 months') TO (date_trunc('month', NOW()) + INTERVAL '3 months');

-- Create default partition
CREATE TABLE iie.model_metrics_default PARTITION OF iie.model_performance_metrics DEFAULT;

-- Indexes (without CONCURRENTLY for transaction compatibility)
CREATE INDEX IF NOT EXISTS idx_model_metrics_model ON iie.model_performance_metrics(model_id, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_model_metrics_name ON iie.model_performance_metrics(metric_name, measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_model_metrics_time ON iie.model_performance_metrics(measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_model_metrics_composite ON iie.model_performance_metrics(model_id, metric_name, measured_at DESC);

-- Function to automatically manage partitions
CREATE OR REPLACE FUNCTION iie.create_model_metrics_partitions()
RETURNS VOID AS $$
DECLARE
    partition_start DATE;
    partition_end DATE;
    partition_name TEXT;
    i INTEGER;
BEGIN
    -- Create partitions for next 12 months if they don't exist
    FOR i IN 0..11 LOOP
        partition_start := date_trunc('month', NOW()) + (i || ' months')::INTERVAL;
        partition_end := partition_start + INTERVAL '1 month';
        partition_name := 'model_metrics_' || to_char(partition_start, 'YYYY_MM');
        
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'iie' AND tablename = partition_name) THEN
            EXECUTE format(
                'CREATE TABLE iie.%I PARTITION OF iie.model_performance_metrics FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                partition_start,
                partition_end
            );
            RAISE NOTICE 'Created partition: iie.%', partition_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to detect concept drift
CREATE OR REPLACE FUNCTION iie.detect_concept_drift(
    p_model_id UUID,
    p_metric_name TEXT,
    p_lookback_days INTEGER DEFAULT 30,
    p_threshold_stddev NUMERIC DEFAULT 2.0
)
RETURNS TABLE (
    current_avg NUMERIC,
    historical_avg NUMERIC,
    std_dev NUMERIC,
    z_score NUMERIC,
    drift_detected BOOLEAN
) AS $$
DECLARE
    current_period_start TIMESTAMPTZ;
    historical_period_start TIMESTAMPTZ;
    historical_period_end TIMESTAMPTZ;
BEGIN
    current_period_start := NOW() - INTERVAL '7 days';
    historical_period_end := current_period_start;
    historical_period_start := historical_period_end - (p_lookback_days || ' days')::INTERVAL;
    
    RETURN QUERY
    WITH current_stats AS (
        SELECT AVG(metric_value) as avg_value
        FROM iie.model_performance_metrics
        WHERE model_id = p_model_id
          AND metric_name = p_metric_name
          AND measured_at >= current_period_start
    ),
    historical_stats AS (
        SELECT 
            AVG(metric_value) as avg_value,
            STDDEV(metric_value) as std_value
        FROM iie.model_performance_metrics
        WHERE model_id = p_model_id
          AND metric_name = p_metric_name
          AND measured_at BETWEEN historical_period_start AND historical_period_end
    )
    SELECT 
        cs.avg_value as current_avg,
        hs.avg_value as historical_avg,
        hs.std_value as std_dev,
        CASE 
            WHEN hs.std_value > 0 THEN (cs.avg_value - hs.avg_value) / hs.std_value
            ELSE 0 
        END as z_score,
        CASE 
            WHEN hs.std_value > 0 AND ABS((cs.avg_value - hs.avg_value) / hs.std_value) > p_threshold_stddev THEN true
            ELSE false
        END as drift_detected
    FROM current_stats cs, historical_stats hs;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.detect_concept_drift IS
'Detects concept drift by comparing recent performance metrics against historical baseline using statistical testing.';

-- Function to get model performance trends
CREATE OR REPLACE FUNCTION iie.get_model_performance_trend(
    p_model_id UUID,
    p_metric_name TEXT,
    p_days_back INTEGER DEFAULT 90
)
RETURNS TABLE (
    period_date DATE,
    avg_metric_value NUMERIC,
    min_metric_value NUMERIC,
    max_metric_value NUMERIC,
    sample_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(measured_at) as period_date,
        AVG(metric_value) as avg_metric_value,
        MIN(metric_value) as min_metric_value,
        MAX(metric_value) as max_metric_value,
        COUNT(*) as sample_count
    FROM iie.model_performance_metrics
    WHERE model_id = p_model_id
      AND metric_name = p_metric_name
      AND measured_at >= NOW() - (p_days_back || ' days')::INTERVAL
    GROUP BY DATE(measured_at)
    ORDER BY period_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.get_model_performance_trend IS
'Calculates daily performance trends for a specific model and metric over specified period.';

-- Function to archive old metrics
CREATE OR REPLACE FUNCTION iie.archive_old_model_metrics(
    p_retention_months INTEGER DEFAULT 24
)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := NOW() - (p_retention_months || ' months')::INTERVAL;
    
    -- Create archive table if it doesn't exist
    CREATE TABLE IF NOT EXISTS iie.model_performance_metrics_archive (
        LIKE iie.model_performance_metrics INCLUDING ALL
    );
    
    -- Move old data to archive
    WITH moved_rows AS (
        DELETE FROM iie.model_performance_metrics 
        WHERE measured_at < cutoff_date
        RETURNING *
    )
    INSERT INTO iie.model_performance_metrics_archive
    SELECT * FROM moved_rows;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.archive_old_model_metrics IS
'Archives old performance metrics to maintain database performance while preserving historical data.';

-- View for model performance overview
CREATE OR REPLACE VIEW iie.model_performance_overview AS
SELECT 
    m.model_id,
    m.name as model_name,
    m.version as model_version,
    m.stage as model_stage,
    metric.metric_name,
    metric.latest_value,
    metric.avg_7d,
    metric.avg_30d,
    metric.trend,
    COALESCE(drift.drift_detected, false) as concept_drift_detected
FROM iie.ml_models m
CROSS JOIN LATERAL (
    SELECT 
        metric_name,
        AVG(metric_value) FILTER (WHERE measured_at >= NOW() - INTERVAL '24 hours') as latest_value,
        AVG(metric_value) FILTER (WHERE measured_at >= NOW() - INTERVAL '7 days') as avg_7d,
        AVG(metric_value) FILTER (WHERE measured_at >= NOW() - INTERVAL '30 days') as avg_30d,
        CASE 
            WHEN AVG(metric_value) FILTER (WHERE measured_at >= NOW() - INTERVAL '7 days') > 
                 AVG(metric_value) FILTER (WHERE measured_at BETWEEN NOW() - INTERVAL '14 days' AND NOW() - INTERVAL '7 days') THEN 'improving'
            WHEN AVG(metric_value) FILTER (WHERE measured_at >= NOW() - INTERVAL '7 days') < 
                 AVG(metric_value) FILTER (WHERE measured_at BETWEEN NOW() - INTERVAL '14 days' AND NOW() - INTERVAL '7 days') THEN 'declining'
            ELSE 'stable'
        END as trend
    FROM iie.model_performance_metrics mpm
    WHERE mpm.model_id = m.model_id
      AND mpm.measured_at >= NOW() - INTERVAL '30 days'
    GROUP BY metric_name
) metric
LEFT JOIN LATERAL (
    SELECT true as drift_detected
    FROM iie.detect_concept_drift(m.model_id, 'accuracy', 30, 2.0)
    WHERE drift_detected = true
    LIMIT 1
) drift ON true;

COMMENT ON VIEW iie.model_performance_overview IS
'Provides comprehensive overview of model performance with trends and concept drift detection for monitoring and alerting.';

-- Function to log performance metrics with drift checking
CREATE OR REPLACE FUNCTION iie.log_model_metric(
    p_model_id UUID,
    p_metric_name TEXT,
    p_metric_value NUMERIC,
    p_sample_size INTEGER DEFAULT NULL,
    p_window_start TIMESTAMPTZ DEFAULT NULL,
    p_window_end TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_metric_id UUID;
    drift_found BOOLEAN;
BEGIN
    -- Insert the metric
    INSERT INTO iie.model_performance_metrics (
        model_id,
        metric_name,
        metric_value,
        sample_size,
        window_start,
        window_end,
        measured_at
    ) VALUES (
        p_model_id,
        p_metric_name,
        p_metric_value,
        p_sample_size,
        p_window_start,
        p_window_end,
        NOW()
    )
    RETURNING metric_id INTO v_metric_id;
    
    -- Check for concept drift in key metrics
    IF p_metric_name IN ('accuracy', 'f1_score', 'precision', 'recall') THEN
        SELECT drift_detected INTO drift_found
        FROM iie.detect_concept_drift(p_model_id, p_metric_name, 30, 2.0);
        
        IF drift_found THEN
            UPDATE iie.ml_models 
            SET drift_detected_at = NOW(),
                updated_at = NOW()
            WHERE model_id = p_model_id;
            
            RAISE NOTICE 'Concept drift detected for model %, metric %', p_model_id, p_metric_name;
        END IF;
    END IF;
    
    RETURN v_metric_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.log_model_metric IS
'Convenience function to log model metrics with automatic concept drift detection for key performance indicators.';

-- Initialize partitions
-- SELECT iie.create_model_metrics_partitions();


-- Basic select with pagination
SELECT event_id, source_system, source_instance, event_timestamp, received_at, tenant_id
FROM iie.raw_events 
WHERE event_timestamp >= NOW() - INTERVAL '1 day'
ORDER BY event_timestamp DESC 
LIMIT 100;

-- Search events by source system
SELECT event_id, source_system, event_timestamp, payload->>'message' as message
FROM iie.raw_events 
WHERE source_system = 'Datadog'
  AND event_timestamp BETWEEN NOW() - INTERVAL '1 hour' AND NOW()
ORDER BY event_timestamp DESC;

-- JSON payload query
SELECT event_id, source_system, 
       payload->>'severity' as severity,
       payload->>'message' as message,
       payload->'tags' as tags
FROM iie.raw_events 
WHERE payload->>'severity' = 'error'
  AND event_timestamp >= NOW() - INTERVAL '24 hours';
  
-- Enriched events with business context
SELECT ee.enriched_event_id, ee.service_name, ee.host_name, 
       ee.severity, ee.priority, ee.business_function,
       ee.cost_per_minute, ee.user_impact_estimate,
       re.source_system, re.event_timestamp
FROM iie.enriched_events ee
JOIN iie.raw_events re ON ee.event_id = re.event_id
WHERE ee.severity IN ('critical', 'high')
  AND ee.created_at >= NOW() - INTERVAL '1 day'
ORDER BY ee.priority, re.event_timestamp DESC;

-- Service performance analysis
SELECT service_name, 
       COUNT(*) as event_count,
       AVG(cost_per_minute) as avg_cost_per_minute,
       SUM(user_impact_estimate) as total_user_impact
FROM iie.enriched_events
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY service_name
ORDER BY total_user_impact DESC;


-- Active incidents
SELECT incident_id, title, severity, priority, status,
       detected_at, root_cause_suggestion,
       complexity_score, fatigue_risk_score
FROM iie.correlated_incidents
WHERE status = 'active'
ORDER BY severity DESC, priority, detected_at DESC;

-- Incident metrics and trends
SELECT 
    DATE(detected_at) as incident_date,
    COUNT(*) as incident_count,
    AVG(EXTRACT(EPOCH FROM mtt_detection)/60) as avg_mttd_minutes,
    AVG(EXTRACT(EPOCH FROM mtt_resolution)/60) as avg_mttr_minutes,
    AVG(complexity_score) as avg_complexity
FROM iie.correlated_incidents
WHERE detected_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(detected_at)
ORDER BY incident_date DESC;


-- Correlation analysis for specific incident -- update the ic.incident_id="your_incident-uuid-here"
SELECT ic.correlation_id, ic.correlation_type, ic.confidence_score,
       re.source_system, re.event_timestamp,
       ee.service_name, ee.severity
FROM iie.incident_correlations ic
JOIN iie.raw_events re ON ic.event_id = re.event_id
LEFT JOIN iie.enriched_events ee ON re.event_id = ee.event_id
WHERE ic.incident_id = 'your-incident-uuid-here'
ORDER BY ic.confidence_score DESC;

-- Correlation type distribution
SELECT correlation_type, 
       COUNT(*) as correlation_count,
       AVG(confidence_score) as avg_confidence
FROM iie.incident_correlations
GROUP BY correlation_type
ORDER BY correlation_count DESC;


-- Model performance overview
SELECT model_id, name, version, stage, task,
       accuracy, precision, recall, f1_score,
       last_trained_at, drift_detected_at
FROM iie.ml_models
WHERE stage = 'production'
ORDER BY last_trained_at DESC;

-- Model accuracy trends by task
SELECT task, 
       COUNT(*) as model_count,
       AVG(accuracy) as avg_accuracy,
       AVG(f1_score) as avg_f1_score
FROM iie.ml_models
WHERE stage IN ('production', 'staging')
GROUP BY task
ORDER BY avg_accuracy DESC;


-- User feedback analysis
SELECT m.name as model_name, 
       mf.user_action,
       COUNT(*) as feedback_count,
       AVG(CASE WHEN mf.explanation_helpful THEN 1 ELSE 0 END) as helpful_rate
FROM iie.model_feedback_log mf
JOIN iie.ml_models m ON mf.model_id = m.model_id
WHERE mf.responded_at >= NOW() - INTERVAL '30 days'
GROUP BY m.name, mf.user_action
ORDER BY feedback_count DESC;

-- Recent feedback with context
SELECT mf.feedback_id, m.name as model_name, 
       mf.user_action, mf.explanation_helpful,
       ci.title as incident_title,
       mf.responded_at
FROM iie.model_feedback_log mf
JOIN iie.ml_models m ON mf.model_id = m.model_id
LEFT JOIN iie.correlated_incidents ci ON mf.incident_id = ci.incident_id
ORDER BY mf.responded_at DESC
LIMIT 50;


-- Active response actions
SELECT ira.action_id, ci.title as incident_title,
       ira.action_type, ira.description, ira.status,
       ira.assigned_team, ira.created_at, ira.started_at
FROM iie.incident_response_actions ira
JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
WHERE ira.status IN ('pending', 'in_progress')
ORDER BY ci.severity DESC, ira.created_at;

-- Action performance metrics
SELECT action_type,
       COUNT(*) as total_actions,
       AVG(EXTRACT(EPOCH FROM time_to_complete)/60) as avg_completion_minutes,
       AVG(effectiveness_score) as avg_effectiveness
FROM iie.incident_response_actions
WHERE status = 'completed'
  AND completed_at >= NOW() - INTERVAL '30 days'
GROUP BY action_type
ORDER BY total_actions DESC;

-- Critical dependencies
SELECT source_service, target_service, dependency_type, criticality,
       expected_latency_ms, health_check_endpoint
FROM iie.service_dependencies
WHERE criticality IN ('critical', 'high')
ORDER BY criticality DESC, source_service;

-- Dependency graph analysis
SELECT source_service,
       COUNT(*) as total_dependencies,
       COUNT(*) FILTER (WHERE criticality = 'critical') as critical_deps,
       COUNT(*) FILTER (WHERE criticality = 'high') as high_deps
FROM iie.service_dependencies
GROUP BY source_service
HAVING COUNT(*) FILTER (WHERE criticality IN ('critical', 'high')) > 0
ORDER BY critical_deps DESC, high_deps DESC;


-- Recent metrics for specific model-- update the below code with model_id="your-model-uuid-here"
SELECT metric_name, metric_value, measured_at, sample_size
FROM iie.model_performance_metrics
WHERE model_id = 'your-model-uuid-here'
  AND metric_name = 'accuracy'
  AND measured_at >= NOW() - INTERVAL '7 days'
ORDER BY measured_at DESC;

-- Metric comparison across models
SELECT m.name as model_name, 
       mpm.metric_name,
       AVG(mpm.metric_value) as avg_value,
       STDDEV(mpm.metric_value) as std_dev
FROM iie.model_performance_metrics mpm
JOIN iie.ml_models m ON mpm.model_id = m.model_id
WHERE mpm.measured_at >= NOW() - INTERVAL '30 days'
  AND m.stage = 'production'
GROUP BY m.name, mpm.metric_name
ORDER BY m.name, mpm.metric_name;

--Response Actions Analytics view 
-- Comprehensive action analysis
SELECT incident_title, action_type, status,
       time_to_complete_minutes, effectiveness_score,
       incident_severity, incident_priority
FROM iie.response_actions_analytics
WHERE created_at >= NOW() - INTERVAL '7 days'
ORDER BY incident_severity DESC, time_to_complete_minutes DESC;

-- Team performance via view
SELECT assigned_team,
       COUNT(*) as total_actions,
       AVG(time_to_complete_minutes) as avg_completion_time,
       AVG(effectiveness_score) as avg_effectiveness
FROM iie.response_actions_analytics
WHERE status = 'completed'
  AND completed_at >= NOW() - INTERVAL '30 days'
GROUP BY assigned_team
ORDER BY avg_effectiveness DESC;


-- Critical dependency analysis
SELECT source_service, target_service, dependency_type, criticality,
       source_criticality_score, target_criticality_score
FROM iie.service_dependency_overview
WHERE criticality IN ('critical', 'high')
ORDER BY source_criticality_score DESC, target_criticality_score DESC;

-- High-risk services
SELECT source_service,
       COUNT(*) as total_dependencies,
       MAX(source_criticality_score) as criticality_score
FROM iie.service_dependency_overview
GROUP BY source_service
HAVING MAX(source_criticality_score) > 0.7
ORDER BY criticality_score DESC;

-- Production model performance
SELECT model_name, model_version, metric_name,
       latest_value, avg_7d, avg_30d, trend,
       concept_drift_detected
FROM iie.model_performance_overview
WHERE model_stage = 'production'
ORDER BY model_name, metric_name;

-- Models needing attention
SELECT model_name, metric_name, latest_value, trend,
       concept_drift_detected
FROM iie.model_performance_overview
WHERE concept_drift_detected = true
   OR trend = 'declining'
ORDER BY model_name, metric_name;

--Team performance Metrics 
-- All teams performance
SELECT * FROM iie.get_team_response_metrics();

-- Specific team performance-- update team id 
SELECT * FROM iie.get_team_response_metrics('team-uuid-here', 30);

-- Action type metrics
SELECT * FROM iie.get_action_type_metrics(30);


-- Service criticality score
SELECT service_name, iie.calculate_service_criticality(service_name) as criticality_score
FROM (SELECT DISTINCT source_service as service_name FROM iie.service_dependencies
      UNION 
      SELECT DISTINCT target_service as service_name FROM iie.service_dependencies) services
ORDER BY criticality_score DESC;

-- Detect dependency cycles
SELECT * FROM iie.detect_dependency_cycles();

--Model Performance functions -- update model-uuid-here 
-- Concept drift detection
SELECT * FROM iie.detect_concept_drift(
    'model-uuid-here', 
    'accuracy', 
    30, 
    2.0
);

-- Performance trends
SELECT * FROM iie.get_model_performance_trend(
    'model-uuid-here',
    'f1_score',
    90
);

-- Log new metric with drift detection
SELECT iie.log_model_metric(
    'model-uuid-here',
    'accuracy',
    0.945,
    1000,
    NOW() - INTERVAL '1 hour',
    NOW()
);
  
  
  --Utility functions 
  -- Calculate MTTD for specific incident
SELECT iie.calculate_incident_mttd('incident-uuid-here');

-- Archive old data
SELECT iie.archive_old_raw_events(12) as archived_events_count;
SELECT iie.archive_old_model_metrics(24) as archived_metrics_count;

-- -- Create partitions (maintenance)
-- SELECT iie.create_raw_events_partitions();
-- SELECT iie.create_model_metrics_partitions();


--incident Analytics 
-- Monthly incident trends
SELECT 
    DATE_TRUNC('month', detected_at) as month,
    COUNT(*) as incident_count,
    AVG(EXTRACT(EPOCH FROM mtt_resolution)/3600) as avg_mttr_hours,
    AVG(complexity_score) as avg_complexity,
    COUNT(*) FILTER (WHERE root_cause_suggestion IS NOT NULL) as incidents_with_root_cause
FROM iie.correlated_incidents
WHERE detected_at >= NOW() - INTERVAL '1 year'
GROUP BY DATE_TRUNC('month', detected_at)
ORDER BY month DESC;

-- Severity distribution by service
SELECT ee.service_name,
       COUNT(*) FILTER (WHERE ci.severity = 'critical') as critical_count,
       COUNT(*) FILTER (WHERE ci.severity = 'high') as high_count,
       COUNT(*) FILTER (WHERE ci.severity = 'medium') as medium_count,
       COUNT(*) as total_incidents
FROM iie.correlated_incidents ci
JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
JOIN iie.enriched_events ee ON ic.event_id = ee.event_id
WHERE ci.detected_at >= NOW() - INTERVAL '90 days'
GROUP BY ee.service_name
HAVING COUNT(*) > 5
ORDER BY critical_count DESC;


-- Model accuracy over time
SELECT 
    m.name as model_name,
    DATE(mpm.measured_at) as measurement_date,
    AVG(mpm.metric_value) as daily_accuracy,
    COUNT(*) as measurements_count
FROM iie.model_performance_metrics mpm
JOIN iie.ml_models m ON mpm.model_id = m.model_id
WHERE mpm.metric_name = 'accuracy'
  AND mpm.measured_at >= NOW() - INTERVAL '30 days'
  AND m.stage = 'production'
GROUP BY m.name, DATE(mpm.measured_at)
ORDER BY m.name, measurement_date DESC;


-- =============================================================================
-- ENHANCEMENT 4: OPERATIONAL INTELLIGENCE VIEWS
-- ------------------------------------------------------------------------------
-- Purpose: Provide actionable insights for different stakeholder groups
-- Supports: IIE-065, IIE-074, IIE-100
-- =============================================================================

-- View: Team Performance and Workload
CREATE OR REPLACE VIEW iie.vw_team_performance AS
SELECT 
    ira.assigned_team,
    COUNT(DISTINCT ci.incident_id) AS total_incidents,
    AVG(EXTRACT(EPOCH FROM ci.mtt_resolution)) AS avg_resolution_seconds,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') AS critical_incidents,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.sla_breach_risk > 0.8) AS high_risk_incidents,
    COUNT(ira.action_id) AS total_actions,
    AVG(EXTRACT(EPOCH FROM ira.time_to_complete)) AS avg_action_completion_seconds,
    AVG(ira.effectiveness_score) AS avg_action_effectiveness
FROM iie.correlated_incidents ci
LEFT JOIN iie.incident_response_actions ira ON ci.incident_id = ira.incident_id
WHERE ci.status = 'resolved'
  AND ci.resolved_at >= NOW() - INTERVAL '30 days'
GROUP BY ira.assigned_team;

COMMENT ON VIEW iie.vw_team_performance IS
'Provides team performance metrics including incident resolution times, workload distribution, and action effectiveness for operational reviews.';

-- View: Service Health and Dependency Risk
CREATE OR REPLACE VIEW iie.vw_service_health AS
SELECT 
    ee.service_name,
    COUNT(DISTINCT ci.incident_id) AS total_incidents,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') AS critical_incidents,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'high') AS high_incidents,
    AVG(EXTRACT(EPOCH FROM ci.mtt_resolution)/60) AS avg_resolution_minutes,
    AVG(ci.complexity_score) AS avg_complexity,
    AVG(ee.cost_per_minute) AS avg_cost_per_minute,
    iie.calculate_service_criticality(ee.service_name) AS criticality_score,
    COUNT(DISTINCT sd.dependency_id) AS total_dependencies,
    COUNT(DISTINCT sd.dependency_id) FILTER (WHERE sd.criticality = 'critical') AS critical_dependencies
FROM iie.enriched_events ee
JOIN iie.incident_correlations ic ON ee.event_id = ic.event_id AND ee.event_timestamp = ic.event_timestamp
JOIN iie.correlated_incidents ci ON ic.incident_id = ci.incident_id
LEFT JOIN iie.service_dependencies sd ON ee.service_name = sd.source_service
WHERE ci.detected_at >= NOW() - INTERVAL '90 days'
GROUP BY ee.service_name;

COMMENT ON VIEW iie.vw_service_health IS
'Comprehensive service health assessment including incident history, cost impact, and dependency risk analysis.';

-- Materialized View: Service Health Scoring (Refresh daily)
DROP MATERIALIZED VIEW IF EXISTS iie.mv_service_health_scores;
CREATE MATERIALIZED VIEW iie.mv_service_health_scores AS
SELECT
    ee.service_name,
    DATE(ci.detected_at) AS date,
    COUNT(DISTINCT ci.incident_id) AS total_incidents,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') AS critical_incidents,
    COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'high') AS high_incidents,
    AVG(EXTRACT(EPOCH FROM ci.mtt_resolution)/60) AS avg_resolution_minutes,
    AVG(ci.complexity_score) AS avg_complexity,
    CASE 
        WHEN COUNT(DISTINCT ci.incident_id) = 0 THEN 100
        ELSE GREATEST(0, 100 - 
            (COUNT(DISTINCT ci.incident_id) * 2 + 
             COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') * 10 +
             COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'high') * 5))
    END AS health_score,
    SUM(ee.cost_per_minute * EXTRACT(EPOCH FROM COALESCE(ci.mtt_resolution, INTERVAL '0 minutes'))/60) AS total_cost_impact
FROM iie.correlated_incidents ci
JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
WHERE ci.detected_at >= NOW() - INTERVAL '90 days'
GROUP BY ee.service_name, DATE(ci.detected_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_service_health_unique 
ON iie.mv_service_health_scores(service_name, date);

COMMENT ON MATERIALIZED VIEW iie.mv_service_health_scores IS
'Daily service health scores with cost impact analysis for trend monitoring and capacity planning.';

-- View: Model Performance and Drift Monitoring
CREATE OR REPLACE VIEW iie.vw_model_monitoring AS
SELECT 
    m.model_id,
    m.name AS model_name,
    m.version AS model_version,
    m.stage AS model_stage,
    m.task AS model_task,
    m.accuracy AS training_accuracy,
    m.last_trained_at,
    m.drift_detected_at,
    perf.metric_name,
    perf.latest_value,
    perf.avg_7d,
    perf.avg_30d,
    perf.trend,
    perf.concept_drift_detected,
    COUNT(mf.feedback_id) AS feedback_count,
    COUNT(mf.feedback_id) FILTER (WHERE mf.user_action = 'accepted') AS accepted_predictions,
    COUNT(mf.feedback_id) FILTER (WHERE mf.user_action = 'rejected') AS rejected_predictions,
    CASE 
        WHEN COUNT(mf.feedback_id) > 0 THEN 
            COUNT(mf.feedback_id) FILTER (WHERE mf.user_action = 'accepted')::NUMERIC / COUNT(mf.feedback_id)
        ELSE NULL 
    END AS acceptance_rate
FROM iie.ml_models m
LEFT JOIN iie.model_performance_overview perf ON m.model_id = perf.model_id
LEFT JOIN iie.model_feedback_log mf ON m.model_id = mf.model_id 
    AND mf.responded_at >= NOW() - INTERVAL '30 days'
GROUP BY 
    m.model_id, m.name, m.version, m.stage, m.task, m.accuracy, 
    m.last_trained_at, m.drift_detected_at,
    perf.metric_name, perf.latest_value, perf.avg_7d, perf.avg_30d, 
    perf.trend, perf.concept_drift_detected;

COMMENT ON VIEW iie.vw_model_monitoring IS
'Comprehensive model performance monitoring including accuracy trends, concept drift detection, and user feedback analysis.';

-- View: Incident Response Efficiency
CREATE OR REPLACE VIEW iie.vw_incident_response_efficiency AS
SELECT 
    ci.incident_id,
    ci.title,
    ci.severity,
    ci.priority,
    ci.detected_at,
    ci.resolved_at,
    EXTRACT(EPOCH FROM ci.mtt_resolution)/60 AS resolution_minutes,
    ci.complexity_score,
    ci.fatigue_risk_score,
    COUNT(ira.action_id) AS total_actions,
    COUNT(ira.action_id) FILTER (WHERE ira.status = 'completed') AS completed_actions,
    AVG(EXTRACT(EPOCH FROM ira.time_to_complete)/60) FILTER (WHERE ira.status = 'completed') AS avg_action_minutes,
    AVG(ira.effectiveness_score) FILTER (WHERE ira.status = 'completed') AS avg_effectiveness,
    COUNT(DISTINCT ic.event_id) AS correlated_events,
    COUNT(DISTINCT ic.event_id) FILTER (WHERE ic.correlation_type = 'root_cause') AS root_cause_events
FROM iie.correlated_incidents ci
LEFT JOIN iie.incident_response_actions ira ON ci.incident_id = ira.incident_id
LEFT JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
WHERE ci.detected_at >= NOW() - INTERVAL '30 days'
GROUP BY 
    ci.incident_id, ci.title, ci.severity, ci.priority, 
    ci.detected_at, ci.resolved_at, ci.mtt_resolution,
    ci.complexity_score, ci.fatigue_risk_score;

COMMENT ON VIEW iie.vw_incident_response_efficiency IS
'Incident response efficiency analysis including action completion times, effectiveness scores, and correlation patterns.';

-- View: Cost Impact Analysis
CREATE OR REPLACE VIEW iie.vw_cost_impact_analysis AS
SELECT 
    ee.service_name,
    ee.business_function,
    COUNT(DISTINCT ci.incident_id) AS incident_count,
    SUM(ee.cost_per_minute * EXTRACT(EPOCH FROM COALESCE(ci.mtt_resolution, INTERVAL '0 minutes'))/60) AS total_cost_impact,
    AVG(ee.cost_per_minute) AS avg_cost_per_minute,
    AVG(EXTRACT(EPOCH FROM ci.mtt_resolution)/60) AS avg_resolution_minutes,
    SUM(ee.user_impact_estimate) AS total_user_impact,
    iie.calculate_service_criticality(ee.service_name) AS service_criticality
FROM iie.enriched_events ee
JOIN iie.incident_correlations ic ON ee.event_id = ic.event_id AND ee.event_timestamp = ic.event_timestamp
JOIN iie.correlated_incidents ci ON ic.incident_id = ci.incident_id
WHERE ci.detected_at >= NOW() - INTERVAL '90 days'
  AND ci.status = 'resolved'
GROUP BY ee.service_name, ee.business_function
ORDER BY total_cost_impact DESC;

COMMENT ON VIEW iie.vw_cost_impact_analysis IS
'Financial impact analysis of incidents by service and business function for cost optimization and investment prioritization.';

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION iie.refresh_operational_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY iie.mv_service_health_scores;
    RAISE NOTICE 'Operational views refreshed successfully';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.refresh_operational_views IS
'Refreshes all materialized views for operational intelligence reporting.';



--Team performance view 

-- Overall team performance dashboard
SELECT 
    assigned_team,
    total_incidents,
    ROUND(avg_resolution_seconds / 60, 2) as avg_resolution_minutes,
    critical_incidents,
    high_risk_incidents,
    total_actions,
    ROUND(avg_action_completion_seconds / 60, 2) as avg_action_minutes,
    ROUND(avg_action_effectiveness, 3) as effectiveness_score
FROM iie.vw_team_performance
ORDER BY total_incidents DESC;

-- Team workload distribution
SELECT 
    assigned_team,
    total_incidents,
    critical_incidents,
    ROUND((critical_incidents::NUMERIC / total_incidents) * 100, 1) as critical_percentage,
    high_risk_incidents,
    total_actions
FROM iie.vw_team_performance
WHERE total_incidents > 0
ORDER BY critical_percentage DESC;

-- Team efficiency analysis
SELECT 
    assigned_team,
    ROUND(avg_resolution_seconds / 3600, 2) as avg_resolution_hours,
    ROUND(avg_action_completion_seconds / 60, 2) as avg_action_minutes,
    ROUND(avg_action_effectiveness, 3) as effectiveness_score,
    CASE 
        WHEN avg_action_effectiveness > 0.8 THEN 'High'
        WHEN avg_action_effectiveness > 0.6 THEN 'Medium'
        ELSE 'Low'
    END as effectiveness_rating
FROM iie.vw_team_performance
WHERE total_actions > 5
ORDER BY effectiveness_score DESC;


--Service Health View 

-- Service health dashboard
SELECT 
    service_name,
    total_incidents,
    critical_incidents,
    high_incidents,
    ROUND(avg_resolution_minutes, 2) as avg_resolution_mins,
    ROUND(avg_complexity, 2) as complexity_score,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(criticality_score, 3) as dependency_criticality,
    total_dependencies,
    critical_dependencies
FROM iie.vw_service_health
ORDER BY criticality_score DESC NULLS LAST;

-- High-risk services identification
SELECT 
    service_name,
    critical_incidents,
    ROUND(criticality_score, 3) as dependency_criticality,
    critical_dependencies,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(avg_complexity, 2) as complexity_score
FROM iie.vw_service_health
WHERE critical_incidents > 0 
   OR criticality_score > 0.7
ORDER BY critical_incidents DESC, criticality_score DESC;

-- Service cost and impact analysis
SELECT 
    service_name,
    total_incidents,
    ROUND(avg_cost_per_minute, 2) as avg_cost_per_minute,
    ROUND(avg_cost_per_minute * avg_resolution_minutes * total_incidents, 2) as estimated_total_cost,
    ROUND(avg_complexity, 2) as complexity_score
FROM iie.vw_service_health
WHERE avg_cost_per_minute > 0
ORDER BY estimated_total_cost DESC;

-- Model performance dashboard
SELECT 
    model_name,
    model_version,
    model_stage,
    metric_name,
    ROUND(latest_value, 4) as current_value,
    ROUND(avg_7d, 4) as weekly_avg,
    ROUND(avg_30d, 4) as monthly_avg,
    trend,
    concept_drift_detected,
    feedback_count,
    ROUND(acceptance_rate, 3) as acceptance_rate
FROM iie.vw_model_monitoring
WHERE model_stage = 'production'
ORDER BY model_name, metric_name;

-- Models requiring attention
SELECT 
    model_name,
    model_version,
    metric_name,
    ROUND(latest_value, 4) as current_value,
    trend,
    concept_drift_detected,
    last_trained_at,
    feedback_count,
    ROUND(acceptance_rate, 3) as acceptance_rate
FROM iie.vw_model_monitoring
WHERE concept_drift_detected = true 
   OR trend = 'declining'
   OR acceptance_rate < 0.7
ORDER BY concept_drift_detected DESC, acceptance_rate ASC;

-- Model feedback analysis
SELECT 
    model_name,
    model_task,
    feedback_count,
    accepted_predictions,
    rejected_predictions,
    ROUND(acceptance_rate, 3) as acceptance_rate,
    CASE 
        WHEN acceptance_rate >= 0.8 THEN 'High'
        WHEN acceptance_rate >= 0.6 THEN 'Medium'
        ELSE 'Low'
    END as confidence_level
FROM iie.vw_model_monitoring
WHERE feedback_count > 0
ORDER BY acceptance_rate DESC;

-- Incident response performance
SELECT 
    incident_id,
    title,
    severity,
    priority,
    detected_at,
    resolved_at,
    ROUND(resolution_minutes, 2) as resolution_mins,
    ROUND(complexity_score, 2) as complexity,
    ROUND(fatigue_risk_score, 2) as fatigue_risk,
    total_actions,
    completed_actions,
    ROUND(avg_action_minutes, 2) as avg_action_mins,
    ROUND(avg_effectiveness, 3) as effectiveness,
    correlated_events,
    root_cause_events
FROM iie.vw_incident_response_efficiency
ORDER BY resolution_minutes DESC
LIMIT 50;

-- High complexity incident analysis
SELECT 
    title,
    severity,
    ROUND(complexity_score, 2) as complexity,
    ROUND(fatigue_risk_score, 2) as fatigue_risk,
    total_actions,
    completed_actions,
    ROUND(resolution_minutes, 2) as resolution_mins,
    correlated_events,
    root_cause_events
FROM iie.vw_incident_response_efficiency
WHERE complexity_score > 7.0
ORDER BY complexity_score DESC;

-- Response efficiency metrics by severity
SELECT 
    severity,
    COUNT(*) as incident_count,
    ROUND(AVG(resolution_minutes), 2) as avg_resolution_mins,
    ROUND(AVG(complexity_score), 2) as avg_complexity,
    ROUND(AVG(total_actions), 1) as avg_actions_per_incident,
    ROUND(AVG(avg_effectiveness), 3) as avg_effectiveness
FROM iie.vw_incident_response_efficiency
GROUP BY severity
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END;
	
--COST IMPACT ANALYSIS VIEW 
-- Top cost-impacting services
SELECT 
    service_name,
    business_function,
    incident_count,
    ROUND(total_cost_impact, 2) as total_cost,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(avg_resolution_minutes, 2) as avg_resolution_mins,
    total_user_impact,
    ROUND(service_criticality, 3) as criticality_score
FROM iie.vw_cost_impact_analysis
ORDER BY total_cost_impact DESC
LIMIT 20;

-- Cost analysis by business function
SELECT 
    business_function,
    SUM(incident_count) as total_incidents,
    ROUND(SUM(total_cost_impact), 2) as total_cost,
    ROUND(AVG(avg_cost_per_minute), 2) as avg_cost_per_minute,
    SUM(total_user_impact) as total_users_impacted
FROM iie.vw_cost_impact_analysis
GROUP BY business_function
ORDER BY total_cost DESC;

-- High criticality cost drivers
SELECT 
    service_name,
    ROUND(service_criticality, 3) as criticality_score,
    ROUND(total_cost_impact, 2) as total_cost,
    incident_count,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute
FROM iie.vw_cost_impact_analysis
WHERE service_criticality > 0.8
ORDER BY total_cost_impact DESC;


--CROSS-VIEW ANALYTICAL QUERIES 
-- Comprehensive operational dashboard
SELECT 
    'Team Performance' as category,
    COUNT(*) as metric_count,
    SUM(total_incidents) as total_incidents,
    ROUND(AVG(avg_action_effectiveness), 3) as avg_effectiveness
FROM iie.vw_team_performance
UNION ALL
SELECT 
    'Service Health' as category,
    COUNT(*) as metric_count,
    SUM(total_incidents) as total_incidents,
    ROUND(AVG(criticality_score), 3) as avg_criticality
FROM iie.vw_service_health
UNION ALL
SELECT 
    'Model Performance' as category,
    COUNT(DISTINCT model_name) as metric_count,
    SUM(feedback_count) as total_feedback,
    ROUND(AVG(acceptance_rate), 3) as avg_acceptance
FROM iie.vw_model_monitoring;

-- Service health vs cost impact correlation
SELECT 
    sh.service_name,
    sh.total_incidents,
    ROUND(sh.avg_complexity, 2) as complexity,
    ROUND(sh.criticality_score, 3) as dependency_criticality,
    ROUND(cia.total_cost_impact, 2) as total_cost,
    ROUND((cia.total_cost_impact / NULLIF(sh.total_incidents, 0)), 2) as cost_per_incident
FROM iie.vw_service_health sh
JOIN iie.vw_cost_impact_analysis cia ON sh.service_name = cia.service_name
WHERE sh.total_incidents > 5
ORDER BY cost_per_incident DESC;

-- Refresh materialized views for reporting
SELECT iie.refresh_operational_views();

-- Overall team performance dashboard
SELECT 
    assigned_team,
    total_incidents,
    ROUND(avg_resolution_seconds / 60, 2) as avg_resolution_minutes,
    critical_incidents,
    high_risk_incidents,
    total_actions,
    ROUND(avg_action_completion_seconds / 60, 2) as avg_action_minutes,
    ROUND(avg_action_effectiveness, 3) as effectiveness_score
FROM iie.vw_team_performance
ORDER BY total_incidents DESC;

-- Team workload distribution
SELECT 
    assigned_team,
    total_incidents,
    critical_incidents,
    ROUND((critical_incidents::NUMERIC / total_incidents) * 100, 1) as critical_percentage,
    high_risk_incidents,
    total_actions
FROM iie.vw_team_performance
WHERE total_incidents > 0
ORDER BY critical_percentage DESC;

-- Team efficiency analysis
SELECT 
    assigned_team,
    ROUND(avg_resolution_seconds / 3600, 2) as avg_resolution_hours,
    ROUND(avg_action_completion_seconds / 60, 2) as avg_action_minutes,
    ROUND(avg_action_effectiveness, 3) as effectiveness_score,
    CASE 
        WHEN avg_action_effectiveness > 0.8 THEN 'High'
        WHEN avg_action_effectiveness > 0.6 THEN 'Medium'
        ELSE 'Low'
    END as effectiveness_rating
FROM iie.vw_team_performance
WHERE total_actions > 5
ORDER BY effectiveness_score DESC;


-- Service health dashboard
SELECT 
    service_name,
    total_incidents,
    critical_incidents,
    high_incidents,
    ROUND(avg_resolution_minutes, 2) as avg_resolution_mins,
    ROUND(avg_complexity, 2) as complexity_score,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(criticality_score, 3) as dependency_criticality,
    total_dependencies,
    critical_dependencies
FROM iie.vw_service_health
ORDER BY criticality_score DESC NULLS LAST;

-- High-risk services identification
SELECT 
    service_name,
    critical_incidents,
    ROUND(criticality_score, 3) as dependency_criticality,
    critical_dependencies,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(avg_complexity, 2) as complexity_score
FROM iie.vw_service_health
WHERE critical_incidents > 0 
   OR criticality_score > 0.7
ORDER BY critical_incidents DESC, criticality_score DESC;

-- Service cost and impact analysis
SELECT 
    service_name,
    total_incidents,
    ROUND(avg_cost_per_minute, 2) as avg_cost_per_minute,
    ROUND(avg_cost_per_minute * avg_resolution_minutes * total_incidents, 2) as estimated_total_cost,
    ROUND(avg_complexity, 2) as complexity_score
FROM iie.vw_service_health
WHERE avg_cost_per_minute > 0
ORDER BY estimated_total_cost DESC;


--Service health Scores Materialized View 
-- Daily service health trends
SELECT 
    service_name,
    date,
    health_score,
    total_incidents,
    critical_incidents,
    ROUND(avg_resolution_minutes, 2) as resolution_mins,
    ROUND(total_cost_impact, 2) as daily_cost_impact
FROM iie.mv_service_health_scores
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY date DESC, health_score ASC;

-- Service health degradation detection
SELECT 
    service_name,
    MIN(health_score) as min_health_score,
    MAX(health_score) as max_health_score,
    AVG(health_score) as avg_health_score,
    COUNT(*) as days_monitored
FROM iie.mv_service_health_scores
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY service_name
HAVING MIN(health_score) < 70
ORDER BY min_health_score ASC;

-- Weekly health score aggregation
SELECT 
    service_name,
    DATE_TRUNC('week', date) as week_start,
    AVG(health_score) as weekly_health_score,
    SUM(total_incidents) as weekly_incidents,
    SUM(critical_incidents) as weekly_critical_incidents,
    SUM(total_cost_impact) as weekly_cost_impact
FROM iie.mv_service_health_scores
WHERE date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY service_name, DATE_TRUNC('week', date)
ORDER BY week_start DESC, weekly_health_score ASC;


--Model Monitoring View 
-- Model performance dashboard
SELECT 
    model_name,
    model_version,
    model_stage,
    metric_name,
    ROUND(latest_value, 4) as current_value,
    ROUND(avg_7d, 4) as weekly_avg,
    ROUND(avg_30d, 4) as monthly_avg,
    trend,
    concept_drift_detected,
    feedback_count,
    ROUND(acceptance_rate, 3) as acceptance_rate
FROM iie.vw_model_monitoring
WHERE model_stage = 'production'
ORDER BY model_name, metric_name;

-- Models requiring attention
SELECT 
    model_name,
    model_version,
    metric_name,
    ROUND(latest_value, 4) as current_value,
    trend,
    concept_drift_detected,
    last_trained_at,
    feedback_count,
    ROUND(acceptance_rate, 3) as acceptance_rate
FROM iie.vw_model_monitoring
WHERE concept_drift_detected = true 
   OR trend = 'declining'
   OR acceptance_rate < 0.7
ORDER BY concept_drift_detected DESC, acceptance_rate ASC;

-- Model feedback analysis
SELECT 
    model_name,
    model_task,
    feedback_count,
    accepted_predictions,
    rejected_predictions,
    ROUND(acceptance_rate, 3) as acceptance_rate,
    CASE 
        WHEN acceptance_rate >= 0.8 THEN 'High'
        WHEN acceptance_rate >= 0.6 THEN 'Medium'
        ELSE 'Low'
    END as confidence_level
FROM iie.vw_model_monitoring
WHERE feedback_count > 0
ORDER BY acceptance_rate DESC;


--INCIDENT RESPONSE EFFICIENCY VIEW 
-- Incident response performance
SELECT 
    incident_id,
    title,
    severity,
    priority,
    detected_at,
    resolved_at,
    ROUND(resolution_minutes, 2) as resolution_mins,
    ROUND(complexity_score, 2) as complexity,
    ROUND(fatigue_risk_score, 2) as fatigue_risk,
    total_actions,
    completed_actions,
    ROUND(avg_action_minutes, 2) as avg_action_mins,
    ROUND(avg_effectiveness, 3) as effectiveness,
    correlated_events,
    root_cause_events
FROM iie.vw_incident_response_efficiency
ORDER BY resolution_minutes DESC
LIMIT 50;

-- High complexity incident analysis
SELECT 
    title,
    severity,
    ROUND(complexity_score, 2) as complexity,
    ROUND(fatigue_risk_score, 2) as fatigue_risk,
    total_actions,
    completed_actions,
    ROUND(resolution_minutes, 2) as resolution_mins,
    correlated_events,
    root_cause_events
FROM iie.vw_incident_response_efficiency
WHERE complexity_score > 7.0
ORDER BY complexity_score DESC;

-- Response efficiency metrics by severity
SELECT 
    severity,
    COUNT(*) as incident_count,
    ROUND(AVG(resolution_minutes), 2) as avg_resolution_mins,
    ROUND(AVG(complexity_score), 2) as avg_complexity,
    ROUND(AVG(total_actions), 1) as avg_actions_per_incident,
    ROUND(AVG(avg_effectiveness), 3) as avg_effectiveness
FROM iie.vw_incident_response_efficiency
GROUP BY severity
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END;
	
	
--COST IMPACT ANALYSIS VIEW 
-- Top cost-impacting services
SELECT 
    service_name,
    business_function,
    incident_count,
    ROUND(total_cost_impact, 2) as total_cost,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute,
    ROUND(avg_resolution_minutes, 2) as avg_resolution_mins,
    total_user_impact,
    ROUND(service_criticality, 3) as criticality_score
FROM iie.vw_cost_impact_analysis
ORDER BY total_cost_impact DESC
LIMIT 20;

-- Cost analysis by business function
SELECT 
    business_function,
    SUM(incident_count) as total_incidents,
    ROUND(SUM(total_cost_impact), 2) as total_cost,
    ROUND(AVG(avg_cost_per_minute), 2) as avg_cost_per_minute,
    SUM(total_user_impact) as total_users_impacted
FROM iie.vw_cost_impact_analysis
GROUP BY business_function
ORDER BY total_cost DESC;

-- High criticality cost drivers
SELECT 
    service_name,
    ROUND(service_criticality, 3) as criticality_score,
    ROUND(total_cost_impact, 2) as total_cost,
    incident_count,
    ROUND(avg_cost_per_minute, 2) as cost_per_minute
FROM iie.vw_cost_impact_analysis
WHERE service_criticality > 0.8
ORDER BY total_cost_impact DESC;


-- Comprehensive operational dashboard
SELECT 
    'Team Performance' as category,
    COUNT(*) as metric_count,
    SUM(total_incidents) as total_incidents,
    ROUND(AVG(avg_action_effectiveness), 3) as avg_effectiveness
FROM iie.vw_team_performance
UNION ALL
SELECT 
    'Service Health' as category,
    COUNT(*) as metric_count,
    SUM(total_incidents) as total_incidents,
    ROUND(AVG(criticality_score), 3) as avg_criticality
FROM iie.vw_service_health
UNION ALL
SELECT 
    'Model Performance' as category,
    COUNT(DISTINCT model_name) as metric_count,
    SUM(feedback_count) as total_feedback,
    ROUND(AVG(acceptance_rate), 3) as avg_acceptance
FROM iie.vw_model_monitoring;

-- Service health vs cost impact correlation
SELECT 
    sh.service_name,
    sh.total_incidents,
    ROUND(sh.avg_complexity, 2) as complexity,
    ROUND(sh.criticality_score, 3) as dependency_criticality,
    ROUND(cia.total_cost_impact, 2) as total_cost,
    ROUND((cia.total_cost_impact / NULLIF(sh.total_incidents, 0)), 2) as cost_per_incident
FROM iie.vw_service_health sh
JOIN iie.vw_cost_impact_analysis cia ON sh.service_name = cia.service_name
WHERE sh.total_incidents > 5
ORDER BY cost_per_incident DESC;

-- Check available materialized views
SELECT 
    schemaname,
    matviewname
FROM pg_catalog.pg_matviews 
WHERE schemaname = 'iie'
ORDER BY matviewname;


--Executive Reporting Queries 
-- Monthly operational summary
SELECT 
    'Last 30 Days' as period,
    (SELECT COUNT(*) FROM iie.vw_team_performance) as active_teams,
    (SELECT SUM(total_incidents) FROM iie.vw_team_performance) as total_incidents,
    (SELECT ROUND(AVG(health_score), 1) FROM iie.mv_service_health_scores WHERE date >= CURRENT_DATE - INTERVAL '30 days') as avg_health_score,
    (SELECT SUM(total_cost_impact) FROM iie.vw_cost_impact_analysis) as total_cost_impact,
    (SELECT COUNT(*) FROM iie.vw_model_monitoring WHERE concept_drift_detected = true) as models_with_drift;

-- Service reliability ranking
SELECT 
    ss.service_name,
    ss.health_score,
    ss.total_incidents,
    ss.critical_incidents,
    ROUND(ss.criticality_score, 3) as dependency_risk,
    CASE 
        WHEN ss.health_score >= 90 THEN 'Excellent'
        WHEN ss.health_score >= 80 THEN 'Good'
        WHEN ss.health_score >= 70 THEN 'Fair'
        ELSE 'Poor'
    END as reliability_rating
FROM (
    SELECT 
        shs.service_name,
        AVG(shs.health_score) as health_score,
        SUM(shs.total_incidents) as total_incidents,
        SUM(shs.critical_incidents) as critical_incidents,
        MAX(sh.criticality_score) as criticality_score
    FROM iie.mv_service_health_scores shs
    LEFT JOIN iie.vw_service_health sh ON shs.service_name = sh.service_name
    WHERE shs.date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY shs.service_name
) ss
ORDER BY ss.health_score DESC;

-- Quarterly performance trends
SELECT 
    DATE_TRUNC('quarter', shs.date) as quarter,
    COUNT(DISTINCT shs.service_name) as services_monitored,
    ROUND(AVG(shs.health_score), 1) as avg_health_score,
    SUM(shs.total_incidents) as total_incidents,
    SUM(shs.critical_incidents) as critical_incidents,
    ROUND(SUM(shs.total_cost_impact), 2) as total_cost_impact
FROM iie.mv_service_health_scores shs
WHERE shs.date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY DATE_TRUNC('quarter', shs.date)
ORDER BY quarter DESC;

-- Team performance executive summary
SELECT 
    'Team Performance' as metric_category,
    COUNT(*) as team_count,
    SUM(tp.total_incidents) as total_incidents_handled,
    ROUND(AVG(tp.avg_resolution_seconds/3600), 2) as avg_resolution_hours,
    ROUND(AVG(tp.avg_action_effectiveness), 3) as avg_effectiveness_score
FROM iie.vw_team_performance tp
UNION ALL
SELECT 
    'Service Health' as metric_category,
    COUNT(*) as service_count,
    SUM(sh.total_incidents) as total_incidents,
    ROUND(AVG(sh.avg_resolution_minutes/60), 2) as avg_resolution_hours,
    ROUND(AVG(sh.criticality_score), 3) as avg_criticality
FROM iie.vw_service_health sh
UNION ALL
SELECT 
    'Cost Impact' as metric_category,
    COUNT(*) as service_count,
    SUM(cia.incident_count) as total_incidents,
    NULL as avg_resolution_hours,
    ROUND(SUM(cia.total_cost_impact), 2) as total_cost
FROM iie.vw_cost_impact_analysis cia;

-- Model performance executive dashboard
SELECT 
    mm.model_stage,
    COUNT(DISTINCT mm.model_id) as model_count,
    COUNT(*) FILTER (WHERE mm.concept_drift_detected = true) as models_with_drift,
    ROUND(AVG(mm.acceptance_rate), 3) as avg_acceptance_rate,
    COUNT(*) FILTER (WHERE mm.trend = 'declining') as models_declining,
    COUNT(*) FILTER (WHERE mm.trend = 'improving') as models_improving
FROM iie.vw_model_monitoring mm
GROUP BY mm.model_stage
ORDER BY 
    CASE mm.model_stage 
        WHEN 'production' THEN 1
        WHEN 'staging' THEN 2
        WHEN 'development' THEN 3
        ELSE 4
    END;

-- Refresh materialized views for reporting
SELECT iie.refresh_operational_views();

-- Verify refresh worked by checking recent data
SELECT 
    shs.service_name,
    MAX(shs.date) as latest_data_date,
    COUNT(*) as records_count
FROM iie.mv_service_health_scores shs
GROUP BY shs.service_name
ORDER BY latest_data_date DESC;

-- =============================================================================
-- ROOT CAUSE ANALYSIS FRAMEWORK
-- ------------------------------------------------------------------------------
-- Purpose: Causal graph storage and probabilistic reasoning for root cause analysis
-- Supports: IIE-009 (Root Cause Analysis), IIE-025 (Forensic Analysis)
-- =============================================================================

-- Table: Causal Graph Nodes (Root Causes, Symptoms, Events)
DROP TABLE IF EXISTS iie.causal_graph_nodes CASCADE;
CREATE TABLE iie.causal_graph_nodes (
    node_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_type TEXT NOT NULL CHECK (node_type IN ('root_cause', 'symptom', 'event', 'condition', 'action')),
    node_name TEXT NOT NULL,
    description TEXT,
    category TEXT,  -- e.g., 'infrastructure', 'application', 'deployment', 'network'
    severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    probability_prior NUMERIC(3,2) DEFAULT 0.1,  -- Prior probability of this node occurring
    cost_impact NUMERIC(10,2),  -- Estimated cost impact
    mitigation_strategy TEXT,
    detection_guidance TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.causal_graph_nodes IS 'Stores causal graph nodes representing root causes, symptoms, and events for probabilistic reasoning and forensic analysis.';

-- Table: Causal Graph Edges (Causal Relationships)
DROP TABLE IF EXISTS iie.causal_graph_edges CASCADE;
CREATE TABLE iie.causal_graph_edges (
    edge_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    target_node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    relationship_type TEXT NOT NULL CHECK (relationship_type IN ('causes', 'triggers', 'enables', 'mitigates', 'correlates_with')),
    strength NUMERIC(3,2) NOT NULL DEFAULT 0.5,  -- Strength of causal relationship (0-1)
    confidence NUMERIC(3,2) NOT NULL DEFAULT 0.7,  -- Confidence in this relationship
    description TEXT,
    evidence_count INTEGER DEFAULT 0,  -- Number of historical incidents supporting this edge
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(source_node_id, target_node_id, relationship_type)
);

COMMENT ON TABLE iie.causal_graph_edges IS 'Stores directed edges representing causal relationships between nodes in the causal graph.';

-- Table: Root Cause Analysis Sessions
DROP TABLE IF EXISTS iie.rca_sessions CASCADE;
CREATE TABLE iie.rca_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'validated', 'invalid')) DEFAULT 'active',
    initiated_by UUID,  -- User who initiated the RCA
    initiated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    confidence_score NUMERIC(3,2),  -- Overall confidence in the root cause determination
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.rca_sessions IS 'Tracks root cause analysis sessions linked to incidents, supporting forensic analysis and learning.';

-- Table: RCA Evidence (Observations supporting root cause hypotheses)
DROP TABLE IF EXISTS iie.rca_evidence CASCADE;
CREATE TABLE iie.rca_evidence (
    evidence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES iie.rca_sessions(session_id),
    node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    evidence_type TEXT NOT NULL CHECK (evidence_type IN ('log', 'metric', 'event', 'test', 'witness', 'configuration')),
    description TEXT NOT NULL,
    source TEXT,  -- Source of evidence (e.g., 'splunk', 'datadog', 'test_result')
    confidence NUMERIC(3,2) DEFAULT 0.8,  -- Confidence in this evidence
    observed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.rca_evidence IS 'Stores evidence collected during root cause analysis that supports or refutes causal graph nodes.';

-- Table: RCA Hypotheses (Probabilistic reasoning about root causes)
DROP TABLE IF EXISTS iie.rca_hypotheses CASCADE;
CREATE TABLE iie.rca_hypotheses (
    hypothesis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES iie.rca_sessions(session_id),
    root_cause_node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    probability NUMERIC(3,2) NOT NULL,  -- Calculated probability of this hypothesis
    confidence NUMERIC(3,2) NOT NULL,  -- Confidence in the probability calculation
    explanation TEXT,  -- Human-readable explanation of why this is likely
    supporting_evidence_count INTEGER DEFAULT 0,
    conflicting_evidence_count INTEGER DEFAULT 0,
    is_selected BOOLEAN DEFAULT FALSE,  -- Whether this was the final selected root cause
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.rca_hypotheses IS 'Stores probabilistic hypotheses about root causes generated during analysis sessions.';

-- Table: Bayesian Network Parameters (For probabilistic reasoning)
DROP TABLE IF EXISTS iie.bayesian_network_params CASCADE;
CREATE TABLE iie.bayesian_network_params (
    param_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    parent_configuration TEXT,  -- JSON representation of parent states
    probability NUMERIC(3,2) NOT NULL,  -- P(node|parent_configuration)
    sample_size INTEGER DEFAULT 0,  -- Number of observations supporting this parameter
    learned_from_data BOOLEAN DEFAULT FALSE,  -- Whether this was learned from historical data
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(node_id, parent_configuration)
);

COMMENT ON TABLE iie.bayesian_network_params IS 'Stores conditional probability tables for Bayesian network reasoning in root cause analysis.';

-- Table: Historical Root Cause Patterns
DROP TABLE IF EXISTS iie.historical_root_causes CASCADE;
CREATE TABLE iie.historical_root_causes (
    pattern_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    root_cause_node_id UUID REFERENCES iie.causal_graph_nodes(node_id),
    incident_pattern TEXT,  -- Pattern of symptoms/events that led to this root cause
    frequency INTEGER DEFAULT 1,  -- How often this pattern has occurred
    avg_resolution_time_minutes INTEGER,
    success_rate NUMERIC(3,2),  -- How often this was the correct root cause
    first_observed_at TIMESTAMPTZ,
    last_observed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.historical_root_causes IS 'Stores learned patterns from historical incidents to improve future root cause analysis.';

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_causal_nodes_type ON iie.causal_graph_nodes(node_type);
CREATE INDEX IF NOT EXISTS idx_causal_nodes_category ON iie.causal_graph_nodes(category);
CREATE INDEX IF NOT EXISTS idx_causal_edges_source ON iie.causal_graph_edges(source_node_id);
CREATE INDEX IF NOT EXISTS idx_causal_edges_target ON iie.causal_graph_edges(target_node_id);
CREATE INDEX IF NOT EXISTS idx_rca_sessions_incident ON iie.rca_sessions(incident_id);
CREATE INDEX IF NOT EXISTS idx_rca_sessions_status ON iie.rca_sessions(status);
CREATE INDEX IF NOT EXISTS idx_rca_evidence_session ON iie.rca_evidence(session_id);
CREATE INDEX IF NOT EXISTS idx_rca_hypotheses_session ON iie.rca_hypotheses(session_id);
CREATE INDEX IF NOT EXISTS idx_bayesian_params_node ON iie.bayesian_network_params(node_id);

-- Triggers for updated_at
CREATE TRIGGER trigger_update_causal_nodes_updated_at
    BEFORE UPDATE ON iie.causal_graph_nodes
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_causal_edges_updated_at
    BEFORE UPDATE ON iie.causal_graph_edges
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_rca_sessions_updated_at
    BEFORE UPDATE ON iie.rca_sessions
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_rca_hypotheses_updated_at
    BEFORE UPDATE ON iie.rca_hypotheses
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_bayesian_params_updated_at
    BEFORE UPDATE ON iie.bayesian_network_params
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

-- =============================================================================
-- PROBABILISTIC REASONING FUNCTIONS
-- =============================================================================

-- Function to calculate posterior probabilities for root causes given evidence
CREATE OR REPLACE FUNCTION iie.calculate_root_cause_probabilities(
    p_session_id UUID
)
RETURNS TABLE (
    root_cause_node_id UUID,
    root_cause_name TEXT,
    prior_probability NUMERIC(3,2),
    posterior_probability NUMERIC(3,2),
    probability_increase NUMERIC(3,2),
    supporting_evidence_count INTEGER,
    confidence_score NUMERIC(3,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH evidence_summary AS (
        SELECT 
            e.node_id,
            COUNT(*) as evidence_count,
            AVG(e.confidence) as avg_evidence_confidence
        FROM iie.rca_evidence e
        WHERE e.session_id = p_session_id
        GROUP BY e.node_id
    ),
    causal_paths AS (
        -- Find all root causes that could explain the observed evidence
        SELECT DISTINCT
            n.node_id,
            n.node_name,
            n.probability_prior as prior_probability
        FROM iie.causal_graph_nodes n
        WHERE n.node_type = 'root_cause'
    ),
    evidence_support AS (
        -- Calculate how much evidence supports each root cause
        SELECT 
            cp.node_id,
            cp.prior_probability,
            COALESCE(SUM(
                e.evidence_count * e.avg_evidence_confidence * 
                (SELECT strength FROM iie.causal_graph_edges WHERE target_node_id = es.node_id AND source_node_id = cp.node_id)
            ), 0) as evidence_support_score
        FROM causal_paths cp
        LEFT JOIN evidence_summary es ON 1=1
        LEFT JOIN iie.causal_graph_edges e ON e.source_node_id = cp.node_id AND e.target_node_id = es.node_id
        GROUP BY cp.node_id, cp.prior_probability
    )
    SELECT 
        es.node_id as root_cause_node_id,
        n.node_name as root_cause_name,
        es.prior_probability,
        LEAST(0.99, GREATEST(0.01, 
            es.prior_probability + (es.evidence_support_score * 0.1)
        )) as posterior_probability,
        (LEAST(0.99, GREATEST(0.01, 
            es.prior_probability + (es.evidence_support_score * 0.1)
        )) - es.prior_probability) as probability_increase,
        (SELECT COUNT(*) FROM evidence_summary es2 
         JOIN iie.causal_graph_edges edge ON edge.source_node_id = es.node_id AND edge.target_node_id = es2.node_id
         WHERE es2.evidence_count > 0) as supporting_evidence_count,
        (SELECT AVG(confidence) FROM iie.causal_graph_edges 
         WHERE source_node_id = es.node_id AND target_node_id IN (
             SELECT node_id FROM evidence_summary WHERE evidence_count > 0
         )) as confidence_score
    FROM evidence_support es
    JOIN iie.causal_graph_nodes n ON es.node_id = n.node_id
    ORDER BY posterior_probability DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.calculate_root_cause_probabilities IS 'Calculates posterior probabilities for root causes given observed evidence using causal graph relationships.';

-- Function to generate root cause hypotheses
CREATE OR REPLACE FUNCTION iie.generate_root_cause_hypotheses(
    p_session_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_hypothesis_id UUID;
    rc_record RECORD;
BEGIN
    -- Calculate probabilities for all potential root causes
    FOR rc_record IN 
        SELECT * FROM iie.calculate_root_cause_probabilities(p_session_id)
    LOOP
        INSERT INTO iie.rca_hypotheses (
            session_id,
            root_cause_node_id,
            probability,
            confidence,
            explanation,
            supporting_evidence_count
        ) VALUES (
            p_session_id,
            rc_record.root_cause_node_id,
            rc_record.posterior_probability,
            rc_record.confidence_score,
            format('Root cause probability calculated based on %s supporting evidence paths with %.2f confidence', 
                   rc_record.supporting_evidence_count, rc_record.confidence_score),
            rc_record.supporting_evidence_count
        )
        RETURNING hypothesis_id INTO v_hypothesis_id;
    END LOOP;

    RETURN v_hypothesis_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.generate_root_cause_hypotheses IS 'Generates probabilistic root cause hypotheses for an RCA session based on causal graph reasoning.';

-- Function to find similar historical incidents
CREATE OR REPLACE FUNCTION iie.find_similar_historical_incidents(
    p_incident_id UUID,
    p_similarity_threshold NUMERIC DEFAULT 0.7
)
RETURNS TABLE (
    historical_incident_id UUID,
    historical_incident_title TEXT,
    root_cause_name TEXT,
    similarity_score NUMERIC(3,2),
    resolution_time_minutes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH current_incident_events AS (
        SELECT DISTINCT ee.service_name, ee.error_code, ee.severity
        FROM iie.incident_correlations ic
        JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        WHERE ic.incident_id = p_incident_id
    ),
    historical_matches AS (
        SELECT 
            ci.incident_id,
            ci.title,
            (SELECT node_name FROM iie.causal_graph_nodes WHERE node_id = (
                SELECT root_cause_node_id FROM iie.rca_hypotheses 
                WHERE session_id = rs.session_id AND is_selected = true
                LIMIT 1
            )) as root_cause,
            COUNT(DISTINCT hee.service_name)::NUMERIC / 
            GREATEST(COUNT(DISTINCT cee.service_name), 1) as similarity_score,
            EXTRACT(EPOCH FROM ci.mtt_resolution)/60 as resolution_minutes
        FROM iie.correlated_incidents ci
        JOIN iie.rca_sessions rs ON ci.incident_id = rs.incident_id
        JOIN iie.incident_correlations hic ON ci.incident_id = hic.incident_id
        JOIN iie.enriched_events hee ON hic.event_id = hee.event_id AND hic.event_timestamp = hee.event_timestamp
        CROSS JOIN current_incident_events cee
        WHERE ci.incident_id != p_incident_id
          AND ci.status = 'resolved'
          AND rs.status = 'completed'
          AND hee.service_name = cee.service_name
        GROUP BY ci.incident_id, ci.title, rs.session_id, ci.mtt_resolution
    )
    SELECT 
        incident_id as historical_incident_id,
        title as historical_incident_title,
        root_cause as root_cause_name,
        similarity_score,
        resolution_minutes::INTEGER as resolution_time_minutes
    FROM historical_matches
    WHERE similarity_score >= p_similarity_threshold
    ORDER BY similarity_score DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.find_similar_historical_incidents IS 'Finds historically similar incidents to provide context and potential root causes for current incidents.';

-- Function to update Bayesian network parameters from resolved incidents
CREATE OR REPLACE FUNCTION iie.update_bayesian_parameters()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
    resolved_record RECORD;
BEGIN
    FOR resolved_record IN 
        SELECT 
            rs.session_id,
            rh.root_cause_node_id,
            array_agg(DISTINCT re.node_id) as evidence_nodes
        FROM iie.rca_sessions rs
        JOIN iie.rca_hypotheses rh ON rs.session_id = rh.session_id
        JOIN iie.rca_evidence re ON rs.session_id = re.session_id
        WHERE rs.status = 'completed' 
          AND rh.is_selected = true
          AND rs.completed_at >= NOW() - INTERVAL '90 days'
        GROUP BY rs.session_id, rh.root_cause_node_id
    LOOP
        -- Update conditional probabilities for each evidence node given the root cause
        FOR i IN 1 .. array_length(resolved_record.evidence_nodes, 1)
        LOOP
            INSERT INTO iie.bayesian_network_params (
                node_id,
                parent_configuration,
                probability,
                sample_size,
                learned_from_data
            ) VALUES (
                resolved_record.evidence_nodes[i],
                json_build_object('root_cause', resolved_record.root_cause_node_id)::TEXT,
                0.9,  -- High probability of evidence given root cause
                1,
                true
            )
            ON CONFLICT (node_id, parent_configuration) 
            DO UPDATE SET
                probability = (bayesian_network_params.probability * bayesian_network_params.sample_size + 0.9) / (bayesian_network_params.sample_size + 1),
                sample_size = bayesian_network_params.sample_size + 1,
                updated_at = NOW();
            
            updated_count := updated_count + 1;
        END LOOP;
    END LOOP;

    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.update_bayesian_parameters IS 'Updates Bayesian network parameters based on resolved incidents to improve future probabilistic reasoning.';

-- View: Root Cause Analysis Dashboard
CREATE OR REPLACE VIEW iie.vw_rca_dashboard AS
SELECT 
    rs.session_id,
    ci.incident_id,
    ci.title as incident_title,
    ci.severity,
    rs.status as rca_status,
    rs.initiated_at,
    rs.completed_at,
    (SELECT COUNT(*) FROM iie.rca_hypotheses rh WHERE rh.session_id = rs.session_id) as hypothesis_count,
    (SELECT node_name FROM iie.causal_graph_nodes WHERE node_id = (
        SELECT root_cause_node_id FROM iie.rca_hypotheses 
        WHERE session_id = rs.session_id AND is_selected = true 
        LIMIT 1
    )) as selected_root_cause,
    (SELECT probability FROM iie.rca_hypotheses 
     WHERE session_id = rs.session_id AND is_selected = true 
     LIMIT 1) as selected_probability,
    (SELECT COUNT(*) FROM iie.rca_evidence WHERE session_id = rs.session_id) as evidence_count,
    rs.confidence_score
FROM iie.rca_sessions rs
JOIN iie.correlated_incidents ci ON rs.incident_id = ci.incident_id;

COMMENT ON VIEW iie.vw_rca_dashboard IS 'Provides overview of root cause analysis sessions with key metrics and status information.';

-- View: Causal Graph Analysis
CREATE OR REPLACE VIEW iie.vw_causal_graph_analysis AS
SELECT 
    n.node_id,
    n.node_name,
    n.node_type,
    n.category,
    n.probability_prior,
    COUNT(DISTINCT e_in.edge_id) as incoming_edges,
    COUNT(DISTINCT e_out.edge_id) as outgoing_edges,
    (SELECT COUNT(*) FROM iie.rca_hypotheses rh WHERE rh.root_cause_node_id = n.node_id AND rh.is_selected = true) as times_confirmed_root_cause,
    (SELECT AVG(rh.probability) FROM iie.rca_hypotheses rh WHERE rh.root_cause_node_id = n.node_id) as avg_hypothesis_probability
FROM iie.causal_graph_nodes n
LEFT JOIN iie.causal_graph_edges e_in ON n.node_id = e_in.target_node_id
LEFT JOIN iie.causal_graph_edges e_out ON n.node_id = e_out.source_node_id
GROUP BY n.node_id, n.node_name, n.node_type, n.category, n.probability_prior;

COMMENT ON VIEW iie.vw_causal_graph_analysis IS 'Analyzes causal graph structure and node importance for root cause analysis.';

-- Initialize with common root cause patterns
INSERT INTO iie.causal_graph_nodes (node_type, node_name, description, category, severity, probability_prior, cost_impact) VALUES
('root_cause', 'Database Connection Pool Exhaustion', 'Database connections exhausted due to connection leaks or high load', 'infrastructure', 'high', 0.05, 5000),
('root_cause', 'Memory Leak in Application', 'Application memory leak causing gradual performance degradation', 'application', 'high', 0.03, 3000),
('root_cause', 'Network Latency Spike', 'Sudden increase in network latency affecting distributed services', 'network', 'medium', 0.08, 2000),
('root_cause', 'Deployment Configuration Error', 'Incorrect configuration deployed to production environment', 'deployment', 'critical', 0.02, 10000),
('root_cause', 'Third-party API Outage', 'External dependency service outage impacting functionality', 'external', 'high', 0.06, 4000),
('symptom', 'High Response Times', 'Increased latency in service responses', 'performance', 'medium', 0.10, NULL),
('symptom', 'Database Timeout Errors', 'Database query timeouts occurring frequently', 'database', 'high', 0.04, NULL),
('symptom', 'Memory Usage Spike', 'Sudden increase in memory consumption', 'infrastructure', 'high', 0.03, NULL),
('symptom', 'CPU Saturation', 'CPU usage at or near 100% capacity', 'infrastructure', 'high', 0.05, NULL);

-- Insert causal relationships
INSERT INTO iie.causal_graph_edges (source_node_id, target_node_id, relationship_type, strength, confidence) 
SELECT 
    rc.node_id, 
    sym.node_id,
    'causes',
    0.8,
    0.9
FROM iie.causal_graph_nodes rc, iie.causal_graph_nodes sym
WHERE rc.node_type = 'root_cause' 
  AND sym.node_type = 'symptom'
  AND ((rc.node_name = 'Database Connection Pool Exhaustion' AND sym.node_name = 'Database Timeout Errors') OR
       (rc.node_name = 'Memory Leak in Application' AND sym.node_name = 'Memory Usage Spike') OR
       (rc.node_name = 'Network Latency Spike' AND sym.node_name = 'High Response Times') OR
       (rc.node_name = 'Deployment Configuration Error' AND sym.node_name IN ('High Response Times', 'Database Timeout Errors')) OR
       (rc.node_name = 'Third-party API Outage' AND sym.node_name = 'High Response Times'));

SELECT iie.update_bayesian_parameters();

--Causal Graph Nodes 

-- All root cause nodes with probabilities
SELECT 
    node_id,
    node_name,
    node_type,
    category,
    severity,
    ROUND(probability_prior, 3) as prior_probability,
    cost_impact,
    mitigation_strategy
FROM iie.causal_graph_nodes
WHERE node_type = 'root_cause'
ORDER BY probability_prior DESC;

-- High probability root causes
SELECT 
    node_name,
    category,
    ROUND(probability_prior, 3) as prior_probability,
    cost_impact,
    description
FROM iie.causal_graph_nodes
WHERE node_type = 'root_cause'
  AND probability_prior > 0.05
ORDER BY cost_impact DESC NULLS LAST;

-- Symptoms and events for monitoring
SELECT 
    node_name,
    node_type,
    category,
    severity,
    description
FROM iie.causal_graph_nodes
WHERE node_type IN ('symptom', 'event')
ORDER BY node_type, severity DESC;

--Causal Graph Relationships 

-- Strong causal relationships
SELECT 
    src.node_name as cause,
    tgt.node_name as effect,
    e.relationship_type,
    ROUND(e.strength, 3) as relationship_strength,
    ROUND(e.confidence, 3) as confidence,
    e.evidence_count
FROM iie.causal_graph_edges e
JOIN iie.causal_graph_nodes src ON e.source_node_id = src.node_id
JOIN iie.causal_graph_nodes tgt ON e.target_node_id = tgt.node_id
WHERE e.strength > 0.7
ORDER BY e.strength DESC;

-- Root causes and their symptoms
SELECT 
    rc.node_name as root_cause,
    sym.node_name as symptom,
    e.relationship_type,
    ROUND(e.strength, 3) as causal_strength
FROM iie.causal_graph_edges e
JOIN iie.causal_graph_nodes rc ON e.source_node_id = rc.node_id
JOIN iie.causal_graph_nodes sym ON e.target_node_id = sym.node_id
WHERE rc.node_type = 'root_cause'
  AND sym.node_type = 'symptom'
ORDER BY rc.node_name, e.strength DESC;

-- Network analysis: nodes with most connections
SELECT 
    n.node_name,
    n.node_type,
    COUNT(e_in.edge_id) as incoming_edges,
    COUNT(e_out.edge_id) as outgoing_edges,
    (COUNT(e_in.edge_id) + COUNT(e_out.edge_id)) as total_connections
FROM iie.causal_graph_nodes n
LEFT JOIN iie.causal_graph_edges e_in ON n.node_id = e_in.target_node_id
LEFT JOIN iie.causal_graph_edges e_out ON n.node_id = e_out.source_node_id
GROUP BY n.node_id, n.node_name, n.node_type
HAVING (COUNT(e_in.edge_id) + COUNT(e_out.edge_id)) > 0
ORDER BY total_connections DESC;


--Active RCA Sessions and evidences 
-- Current active root cause analyses
SELECT 
    rs.session_id,
    ci.incident_id,
    ci.title as incident_title,
    ci.severity,
    rs.status,
    rs.initiated_at,
    rs.confidence_score,
    (SELECT COUNT(*) FROM iie.rca_evidence WHERE session_id = rs.session_id) as evidence_count,
    (SELECT COUNT(*) FROM iie.rca_hypotheses WHERE session_id = rs.session_id) as hypothesis_count
FROM iie.rca_sessions rs
JOIN iie.correlated_incidents ci ON rs.incident_id = ci.incident_id
WHERE rs.status = 'active'
ORDER BY rs.initiated_at DESC;

-- Completed RCA sessions with results
SELECT 
    rs.session_id,
    ci.title as incident_title,
    ci.severity,
    rs.completed_at,
    rh.root_cause_node_id,
    cn.node_name as root_cause,
    ROUND(rh.probability, 3) as probability,
    ROUND(rh.confidence, 3) as confidence
FROM iie.rca_sessions rs
JOIN iie.correlated_incidents ci ON rs.incident_id = ci.incident_id
JOIN iie.rca_hypotheses rh ON rs.session_id = rh.session_id
JOIN iie.causal_graph_nodes cn ON rh.root_cause_node_id = cn.node_id
WHERE rs.status = 'completed'
  AND rh.is_selected = true
ORDER BY rs.completed_at DESC;

--RCA Evidence Analysis 
-- Evidence for specific RCA session
SELECT 
    e.evidence_id,
    cn.node_name as related_node,
    e.evidence_type,
    e.description,
    e.source,
    ROUND(e.confidence, 3) as evidence_confidence,
    e.observed_at
FROM iie.rca_evidence e
JOIN iie.causal_graph_nodes cn ON e.node_id = cn.node_id
WHERE e.session_id = 'your-session-uuid-here'
ORDER BY e.confidence DESC;

-- Evidence types and confidence levels
SELECT 
    evidence_type,
    COUNT(*) as evidence_count,
    ROUND(AVG(confidence), 3) as avg_confidence,
    MIN(confidence) as min_confidence,
    MAX(confidence) as max_confidence
FROM iie.rca_evidence
GROUP BY evidence_type
ORDER BY evidence_count DESC;

-- High-confidence evidence sources
SELECT 
    source,
    evidence_type,
    COUNT(*) as evidence_count,
    ROUND(AVG(confidence), 3) as avg_confidence
FROM iie.rca_evidence
GROUP BY source, evidence_type
HAVING COUNT(*) > 5
ORDER BY avg_confidence DESC;

--Probabilistic Hypotheses and Reasoning 
-- Current hypotheses for active session
SELECT 
    h.hypothesis_id,
    cn.node_name as root_cause,
    cn.category,
    ROUND(h.probability, 3) as probability,
    ROUND(h.confidence, 3) as confidence,
    h.supporting_evidence_count,
    h.conflicting_evidence_count,
    h.explanation,
    h.is_selected
FROM iie.rca_hypotheses h
JOIN iie.causal_graph_nodes cn ON h.root_cause_node_id = cn.node_id
WHERE h.session_id = 'your-session-uuid-here'
ORDER BY h.probability DESC;

-- Hypothesis confidence analysis
SELECT 
    CASE 
        WHEN probability >= 0.8 THEN 'High (≥0.8)'
        WHEN probability >= 0.6 THEN 'Medium (0.6-0.8)'
        WHEN probability >= 0.4 THEN 'Low (0.4-0.6)'
        ELSE 'Very Low (<0.4)'
    END as probability_range,
    COUNT(*) as hypothesis_count,
    ROUND(AVG(confidence), 3) as avg_confidence,
    ROUND(AVG(supporting_evidence_count), 1) as avg_supporting_evidence
FROM iie.rca_hypotheses
GROUP BY 
    CASE 
        WHEN probability >= 0.8 THEN 'High (≥0.8)'
        WHEN probability >= 0.6 THEN 'Medium (0.6-0.8)'
        WHEN probability >= 0.4 THEN 'Low (0.4-0.6)'
        ELSE 'Very Low (<0.4)'
    END
ORDER BY probability_range;


--Bayesian Network parameters 
-- Conditional probability tables
SELECT 
    cn.node_name,
    bp.parent_configuration,
    ROUND(bp.probability, 3) as conditional_probability,
    bp.sample_size,
    bp.learned_from_data
FROM iie.bayesian_network_params bp
JOIN iie.causal_graph_nodes cn ON bp.node_id = cn.node_id
WHERE bp.sample_size > 0
ORDER BY bp.sample_size DESC, cn.node_name;

-- Well-supported Bayesian parameters
SELECT 
    cn.node_name as evidence_node,
    parent_cn.node_name as parent_cause,
    ROUND(bp.probability, 3) as p_evidence_given_cause,
    bp.sample_size
FROM iie.bayesian_network_params bp
JOIN iie.causal_graph_nodes cn ON bp.node_id = cn.node_id
CROSS JOIN LATERAL (
    SELECT node_name 
    FROM iie.causal_graph_nodes 
    WHERE node_id = (bp.parent_configuration::json->>'root_cause')::UUID
) parent_cn
WHERE bp.sample_size >= 5
ORDER BY bp.sample_size DESC;

--Historical Patterns and learning 
-- Historical Root cause Patterns 
-- Most frequent root cause patterns
SELECT 
    cn.node_name as root_cause,
    hrc.frequency,
    hrc.avg_resolution_time_minutes,
    ROUND(hrc.success_rate, 3) as success_rate,
    hrc.first_observed_at,
    hrc.last_observed_at
FROM iie.historical_root_causes hrc
JOIN iie.causal_graph_nodes cn ON hrc.root_cause_node_id = cn.node_id
ORDER BY hrc.frequency DESC;

-- High-success rate root causes
SELECT 
    cn.node_name as root_cause,
    cn.category,
    hrc.frequency,
    ROUND(hrc.success_rate, 3) as success_rate,
    hrc.avg_resolution_time_minutes
FROM iie.historical_root_causes hrc
JOIN iie.causal_graph_nodes cn ON hrc.root_cause_node_id = cn.node_id
WHERE hrc.success_rate >= 0.8
  AND hrc.frequency >= 3
ORDER BY hrc.success_rate DESC;


--Probabilisitc Reasoning function calls 
-- Calculate probabilities for specific RCA session
SELECT * FROM iie.calculate_root_cause_probabilities('your-session-uuid-here');

-- Top probable root causes with evidence support
SELECT 
    root_cause_name,
    ROUND(prior_probability, 3) as prior,
    ROUND(posterior_probability, 3) as posterior,
    ROUND(probability_increase, 3) as increase,
    supporting_evidence_count,
    ROUND(confidence_score, 3) as confidence
FROM iie.calculate_root_cause_probabilities('your-session-uuid-here')
WHERE posterior_probability > 0.3
ORDER BY posterior_probability DESC;


--Finding similar historical incidents 
-- Find similar past incidents for current incident
SELECT * FROM iie.find_similar_historical_incidents('your-incident-uuid-here', 0.7);

-- High-similarity historical matches
SELECT 
    historical_incident_title,
    root_cause_name,
    ROUND(similarity_score, 3) as similarity,
    resolution_time_minutes
FROM iie.find_similar_historical_incidents('your-incident-uuid-here', 0.8)
ORDER BY similarity_score DESC;

--Bayesian Network updates 
-- Update Bayesian parameters from recent incidents
SELECT iie.update_bayesian_parameters() as parameters_updated;

-- Check update impact
SELECT 
    COUNT(*) as total_parameters,
    SUM(sample_size) as total_observations,
    ROUND(AVG(probability), 3) as avg_probability,
    COUNT(*) FILTER (WHERE learned_from_data = true) as data_learned_params
FROM iie.bayesian_network_params;

--RCA Dashboard views 
-- Complete RCA dashboard
SELECT 
    session_id,
    incident_title,
    severity,
    rca_status,
    initiated_at,
    completed_at,
    hypothesis_count,
    selected_root_cause,
    ROUND(selected_probability, 3) as selected_probability,
    evidence_count,
    ROUND(confidence_score, 3) as confidence
FROM iie.vw_rca_dashboard
WHERE initiated_at >= NOW() - INTERVAL '30 days'
ORDER BY initiated_at DESC;

-- RCA success metrics
SELECT 
    rca_status,
    COUNT(*) as session_count,
    ROUND(AVG(confidence_score), 3) as avg_confidence,
    ROUND(AVG(selected_probability), 3) as avg_selected_probability,
    AVG(evidence_count) as avg_evidence_count
FROM iie.vw_rca_dashboard
GROUP BY rca_status
ORDER BY session_count DESC;

--Causal Graph Analysis View 

-- Causal graph node importance
SELECT 
    node_name,
    node_type,
    category,
    ROUND(probability_prior, 3) as prior_probability,
    incoming_edges,
    outgoing_edges,
    times_confirmed_root_cause,
    ROUND(avg_hypothesis_probability, 3) as avg_hypothesis_prob
FROM iie.vw_causal_graph_analysis
WHERE node_type = 'root_cause'
ORDER BY times_confirmed_root_cause DESC NULLS LAST;

-- High-impact root causes
SELECT 
    node_name,
    category,
    incoming_edges + outgoing_edges as total_connections,
    times_confirmed_root_cause,
    ROUND(avg_hypothesis_probability, 3) as avg_hypothesis_prob
FROM iie.vw_causal_graph_analysis
WHERE node_type = 'root_cause'
  AND times_confirmed_root_cause > 0
ORDER BY times_confirmed_root_cause DESC, total_connections DESC;

---Advanced Analytical Queries 
--Root cause Effectiveness Analysis 
-- Root cause resolution effectiveness
SELECT 
    cn.node_name as root_cause,
    cn.category,
    COUNT(DISTINCT rh.session_id) as times_identified,
    ROUND(AVG(rh.probability), 3) as avg_probability_when_identified,
    ROUND(AVG(ci.complexity_score), 2) as avg_incident_complexity,
    ROUND(AVG(EXTRACT(EPOCH FROM ci.mtt_resolution)/60), 1) as avg_resolution_minutes
FROM iie.rca_hypotheses rh
JOIN iie.causal_graph_nodes cn ON rh.root_cause_node_id = cn.node_id
JOIN iie.rca_sessions rs ON rh.session_id = rs.session_id
JOIN iie.correlated_incidents ci ON rs.incident_id = ci.incident_id
WHERE rh.is_selected = true
  AND rs.status = 'completed'
GROUP BY cn.node_id, cn.node_name, cn.category
HAVING COUNT(DISTINCT rh.session_id) >= 2
ORDER BY times_identified DESC;

--Evidence Quality Analysis
-- Evidence quality by type and source
SELECT 
    evidence_type,
    source,
    COUNT(*) as evidence_count,
    ROUND(AVG(confidence), 3) as avg_confidence,
    COUNT(DISTINCT session_id) as sessions_used_in,
    ROUND(COUNT(*) * AVG(confidence), 2) as quality_score
FROM iie.rca_evidence
GROUP BY evidence_type, source
HAVING COUNT(*) >= 3
ORDER BY quality_score DESC;

-- High-value evidence patterns
SELECT 
    cn.node_name as evidence_node,
    e.evidence_type,
    COUNT(*) as times_used,
    ROUND(AVG(e.confidence), 3) as avg_confidence,
    COUNT(DISTINCT e.session_id) as unique_sessions
FROM iie.rca_evidence e
JOIN iie.causal_graph_nodes cn ON e.node_id = cn.node_id
GROUP BY cn.node_name, e.evidence_type
HAVING COUNT(*) >= 5
ORDER BY times_used DESC;


-- =============================================================================
-- MODEL RETRAINING PIPELINE FRAMEWORK
-- ------------------------------------------------------------------------------
-- Purpose: Automated model retraining with drift detection, A/B testing, and performance monitoring
-- Supports: IIE-053 (Concept Drift Detection), IIE-080 (Model Retraining)
-- =============================================================================

-- Table: Model Training Jobs
DROP TABLE IF EXISTS iie.model_training_jobs CASCADE;
CREATE TABLE iie.model_training_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    job_type TEXT NOT NULL CHECK (job_type IN ('initial', 'retrain', 'rollback', 'experiment')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')) DEFAULT 'pending',
    trigger_reason TEXT CHECK (trigger_reason IN ('scheduled', 'drift_detected', 'performance_degradation', 'manual', 'data_refresh')),
    training_data_range_start TIMESTAMPTZ,
    training_data_range_end TIMESTAMPTZ,
    training_parameters JSONB,
    artifact_path TEXT,
    version_tag TEXT,
    base_model_id UUID REFERENCES iie.ml_models(model_id),  -- For retraining from existing model
    metrics JSONB,  -- Training metrics (loss, accuracy, etc.)
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT
);

COMMENT ON TABLE iie.model_training_jobs IS 'Tracks model training and retraining jobs with parameters and status for pipeline management.';

-- Table: Model Deployment History
DROP TABLE IF EXISTS iie.model_deployments CASCADE;
CREATE TABLE iie.model_deployments (
    deployment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    job_id UUID REFERENCES iie.model_training_jobs(job_id),
    environment TEXT NOT NULL CHECK (environment IN ('development', 'staging', 'production', 'shadow', 'canary')),
    deployment_type TEXT NOT NULL CHECK (deployment_type IN ('full', 'canary', 'blue-green', 'shadow')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'deploying', 'active', 'rollback', 'inactive')) DEFAULT 'pending',
    traffic_percentage NUMERIC(3,2) DEFAULT 1.0,  -- For canary deployments
    performance_baseline_id UUID,  -- Reference to baseline model for comparison
    deployed_by UUID,
    deployed_at TIMESTAMPTZ DEFAULT NOW(),
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,
    rollback_reason TEXT
);

COMMENT ON TABLE iie.model_deployments IS 'Tracks model deployment history including canary releases and rollbacks for A/B testing.';

-- Table: Drift Detection Results
DROP TABLE IF EXISTS iie.drift_detection_results CASCADE;
CREATE TABLE iie.drift_detection_results (
    detection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    detection_type TEXT NOT NULL CHECK (detection_type IN ('concept_drift', 'data_drift', 'performance_drift')),
    metric_name TEXT NOT NULL,
    reference_period_start TIMESTAMPTZ,
    reference_period_end TIMESTAMPTZ,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    reference_value NUMERIC(10,6),
    current_value NUMERIC(10,6),
    drift_score NUMERIC(5,4),
    threshold NUMERIC(5,4),
    is_drift_detected BOOLEAN NOT NULL,
    confidence NUMERIC(3,2),
    sample_size INTEGER,
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    triggered_retraining BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE iie.drift_detection_results IS 'Stores results of automated drift detection monitoring for model performance and data distribution changes.';

-- Table: A/B Test Experiments
DROP TABLE IF EXISTS iie.ab_test_experiments CASCADE;
CREATE TABLE iie.ab_test_experiments (
    experiment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    control_model_id UUID REFERENCES iie.ml_models(model_id),
    treatment_model_id UUID REFERENCES iie.ml_models(model_id),
    hypothesis TEXT,
    primary_metric TEXT NOT NULL,
    secondary_metrics TEXT[],
    status TEXT NOT NULL CHECK (status IN ('draft', 'running', 'paused', 'completed', 'cancelled')) DEFAULT 'draft',
    target_traffic_percentage NUMERIC(3,2) DEFAULT 0.5,
    min_sample_size INTEGER,
    confidence_level NUMERIC(3,2) DEFAULT 0.95,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.ab_test_experiments IS 'Manages A/B testing experiments for comparing model versions with statistical significance testing.';

-- Table: A/B Test Results
DROP TABLE IF EXISTS iie.ab_test_results CASCADE;
CREATE TABLE iie.ab_test_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id UUID REFERENCES iie.ab_test_experiments(experiment_id),
    model_id UUID REFERENCES iie.ml_models(model_id),
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    sample_size INTEGER,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC(10,6) NOT NULL,
    standard_error NUMERIC(10,6),
    confidence_interval_lower NUMERIC(10,6),
    confidence_interval_upper NUMERIC(10,6),
    is_primary_metric BOOLEAN DEFAULT FALSE,
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.ab_test_results IS 'Stores statistical results from A/B test experiments for model comparison and decision making.';

-- Table: Performance Regression Alerts
DROP TABLE IF EXISTS iie.performance_regression_alerts CASCADE;
CREATE TABLE iie.performance_regression_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    alert_type TEXT NOT NULL CHECK (alert_type IN ('performance_degradation', 'drift_detected', 'training_failure', 'deployment_failure')),
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')) DEFAULT 'medium',
    metric_name TEXT,
    current_value NUMERIC(10,6),
    expected_value NUMERIC(10,6),
    deviation_percentage NUMERIC(5,2),
    description TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'acknowledged', 'resolved', 'suppressed')) DEFAULT 'active',
    triggered_by_job_id UUID REFERENCES iie.model_training_jobs(job_id),
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT
);

COMMENT ON TABLE iie.performance_regression_alerts IS 'Tracks performance regression alerts and monitoring events for model quality assurance.';

-- Table: Model Pipeline Configuration
DROP TABLE IF EXISTS iie.model_pipeline_config CASCADE;
CREATE TABLE iie.model_pipeline_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES iie.ml_models(model_id),
    retraining_schedule TEXT,  -- cron expression for scheduled retraining
    drift_detection_enabled BOOLEAN DEFAULT TRUE,
    performance_monitoring_enabled BOOLEAN DEFAULT TRUE,
    auto_retrain_on_drift BOOLEAN DEFAULT FALSE,
    drift_threshold NUMERIC(5,4) DEFAULT 0.1,
    performance_threshold NUMERIC(5,4) DEFAULT 0.05,
    min_retraining_interval_days INTEGER DEFAULT 7,
    max_retraining_interval_days INTEGER DEFAULT 90,
    data_quality_checks JSONB,
    notification_channels JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.model_pipeline_config IS 'Stores configuration for automated model retraining pipelines including drift detection thresholds and schedules.';

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_training_jobs_model ON iie.model_training_jobs(model_id);
CREATE INDEX IF NOT EXISTS idx_training_jobs_status ON iie.model_training_jobs(status);
CREATE INDEX IF NOT EXISTS idx_deployments_model ON iie.model_deployments(model_id);
CREATE INDEX IF NOT EXISTS idx_deployments_status ON iie.model_deployments(status);
CREATE INDEX IF NOT EXISTS idx_drift_detection_model ON iie.drift_detection_results(model_id);
CREATE INDEX IF NOT EXISTS idx_drift_detection_time ON iie.drift_detection_results(detected_at);
CREATE INDEX IF NOT EXISTS idx_ab_test_status ON iie.ab_test_experiments(status);
CREATE INDEX IF NOT EXISTS idx_performance_alerts_model ON iie.performance_regression_alerts(model_id);
CREATE INDEX IF NOT EXISTS idx_performance_alerts_status ON iie.performance_regression_alerts(status);

-- Triggers for updated_at
CREATE TRIGGER trigger_update_ab_test_updated_at
    BEFORE UPDATE ON iie.ab_test_experiments
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_pipeline_config_updated_at
    BEFORE UPDATE ON iie.model_pipeline_config
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

-- =============================================================================
-- PIPELINE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Function to check for drift and trigger retraining
CREATE OR REPLACE FUNCTION iie.check_and_trigger_retraining()
RETURNS TABLE (
    model_id UUID,
    model_name TEXT,
    drift_type TEXT,
    drift_score NUMERIC,
    should_retrain BOOLEAN
) AS $$
DECLARE
    model_record RECORD;
    config_record RECORD;
    drift_result RECORD;
BEGIN
    FOR model_record IN 
        SELECT m.model_id, m.name, m.stage
        FROM iie.ml_models m
        WHERE m.stage = 'production'
    LOOP
        -- Get pipeline configuration
        SELECT * INTO config_record 
        FROM iie.model_pipeline_config 
        WHERE model_id = model_record.model_id;
        
        -- Skip if no configuration or drift detection disabled
        CONTINUE WHEN config_record IS NULL OR NOT config_record.drift_detection_enabled;
        
        -- Check for recent drift detection
        FOR drift_result IN
            SELECT detection_type, drift_score, is_drift_detected
            FROM iie.drift_detection_results
            WHERE model_id = model_record.model_id
              AND detected_at >= NOW() - INTERVAL '24 hours'
              AND is_drift_detected = true
        LOOP
            -- Determine if retraining should be triggered
            should_retrain := drift_result.drift_score >= config_record.drift_threshold 
                            AND config_record.auto_retrain_on_drift;
            
            RETURN QUERY SELECT 
                model_record.model_id,
                model_record.name::TEXT,
                drift_result.detection_type::TEXT,
                drift_result.drift_score,
                should_retrain;
                
            -- If retraining should be triggered, create training job
            IF should_retrain THEN
                INSERT INTO iie.model_training_jobs (
                    model_id,
                    job_type,
                    trigger_reason,
                    status,
                    training_parameters
                ) VALUES (
                    model_record.model_id,
                    'retrain',
                    'drift_detected',
                    'pending',
                    jsonb_build_object(
                        'drift_type', drift_result.detection_type,
                        'drift_score', drift_result.drift_score,
                        'auto_triggered', true
                    )
                );
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.check_and_trigger_retraining IS 'Automatically checks for model drift and triggers retraining jobs based on configured thresholds.';

-- Function to evaluate A/B test results
CREATE OR REPLACE FUNCTION iie.evaluate_ab_test_results(
    p_experiment_id UUID
)
RETURNS TABLE (
    metric_name TEXT,
    control_value NUMERIC,
    treatment_value NUMERIC,
    absolute_difference NUMERIC,
    relative_improvement NUMERIC,
    p_value NUMERIC,
    is_statistically_significant BOOLEAN,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC
) AS $$
DECLARE
    experiment_record RECORD;
    control_results RECORD;
    treatment_results RECORD;
    total_sample_size INTEGER;
    z_score NUMERIC;
BEGIN
    -- Get experiment details
    SELECT * INTO experiment_record 
    FROM iie.ab_test_experiments 
    WHERE experiment_id = p_experiment_id;
    
    -- Calculate results for each metric
    FOR metric_name IN 
        SELECT DISTINCT metric_name 
        FROM iie.ab_test_results 
        WHERE experiment_id = p_experiment_id
    LOOP
        -- Get control results
        SELECT 
            AVG(metric_value) as avg_value,
            STDDEV(metric_value) as std_value,
            COUNT(*) as sample_size
        INTO control_results
        FROM iie.ab_test_results
        WHERE experiment_id = p_experiment_id
          AND model_id = experiment_record.control_model_id
          AND metric_name = evaluate_ab_test_results.metric_name;
        
        -- Get treatment results  
        SELECT 
            AVG(metric_value) as avg_value,
            STDDEV(metric_value) as std_value,
            COUNT(*) as sample_size
        INTO treatment_results
        FROM iie.ab_test_results
        WHERE experiment_id = p_experiment_id
          AND model_id = experiment_record.treatment_model_id
          AND metric_name = evaluate_ab_test_results.metric_name;
        
        -- Calculate statistical significance
        IF control_results.sample_size > 30 AND treatment_results.sample_size > 30 THEN
            -- Z-test for large samples
            z_score := ABS(control_results.avg_value - treatment_results.avg_value) / 
                      SQRT(POWER(control_results.std_value, 2)/control_results.sample_size + 
                           POWER(treatment_results.std_value, 2)/treatment_results.sample_size);
            
            -- Calculate p-value (two-tailed test)
            p_value := (1 - (1 - ABS(1 - (2 * (1 - (1 / (1 + EXP(-1.5976 * z_score / SQRT(2))))))))) * 2;
        ELSE
            -- For small samples, use t-test approximation
            p_value := 0.05;  -- Simplified for example
        END IF;
        
        -- Return results
        RETURN QUERY SELECT
            metric_name,
            control_results.avg_value as control_value,
            treatment_results.avg_value as treatment_value,
            (treatment_results.avg_value - control_results.avg_value) as absolute_difference,
            CASE 
                WHEN control_results.avg_value != 0 THEN 
                    (treatment_results.avg_value - control_results.avg_value) / control_results.avg_value 
                ELSE NULL 
            END as relative_improvement,
            p_value,
            (p_value < (1 - experiment_record.confidence_level)) as is_statistically_significant,
            (treatment_results.avg_value - 1.96 * treatment_results.std_value / SQRT(treatment_results.sample_size)) as confidence_interval_lower,
            (treatment_results.avg_value + 1.96 * treatment_results.std_value / SQRT(treatment_results.sample_size)) as confidence_interval_upper;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.evaluate_ab_test_results IS 'Evaluates A/B test results with statistical significance testing and confidence intervals.';

-- Function to deploy model with canary release
CREATE OR REPLACE FUNCTION iie.deploy_model_canary(
    p_model_id UUID,
    p_job_id UUID,
    p_traffic_percentage NUMERIC DEFAULT 0.1,
    p_environment TEXT DEFAULT 'production'
)
RETURNS UUID AS $$
DECLARE
    v_deployment_id UUID;
    v_baseline_id UUID;
BEGIN
    -- Get current active deployment as baseline
    SELECT model_id INTO v_baseline_id
    FROM iie.model_deployments
    WHERE environment = p_environment
      AND status = 'active'
    ORDER BY activated_at DESC
    LIMIT 1;
    
    -- Create canary deployment
    INSERT INTO iie.model_deployments (
        model_id,
        job_id,
        environment,
        deployment_type,
        traffic_percentage,
        performance_baseline_id
    ) VALUES (
        p_model_id,
        p_job_id,
        p_environment,
        'canary',
        p_traffic_percentage,
        v_baseline_id
    )
    RETURNING deployment_id INTO v_deployment_id;
    
    -- Log deployment event
    INSERT INTO iie.performance_regression_alerts (
        model_id,
        alert_type,
        severity,
        description,
        status
    ) VALUES (
        p_model_id,
        'deployment_failure',
        'low',
        format('Canary deployment initiated for model %s with %s%% traffic', p_model_id, p_traffic_percentage * 100),
        'resolved'
    );
    
    RETURN v_deployment_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.deploy_model_canary IS 'Deploys a model using canary release strategy with controlled traffic percentage for gradual rollout.';

-- Function to monitor performance regressions
CREATE OR REPLACE FUNCTION iie.monitor_performance_regressions()
RETURNS INTEGER AS $$
DECLARE
    alert_count INTEGER := 0;
    model_record RECORD;
    metric_record RECORD;
    baseline_value NUMERIC;
    current_value NUMERIC;
    deviation NUMERIC;
    threshold NUMERIC;
BEGIN
    FOR model_record IN
        SELECT m.model_id, m.name, pc.performance_threshold
        FROM iie.ml_models m
        JOIN iie.model_pipeline_config pc ON m.model_id = pc.model_id
        WHERE m.stage = 'production'
          AND pc.performance_monitoring_enabled = true
    LOOP
        -- Check recent performance metrics
        FOR metric_record IN
            SELECT metric_name, AVG(metric_value) as current_avg
            FROM iie.model_performance_metrics
            WHERE model_id = model_record.model_id
              AND measured_at >= NOW() - INTERVAL '1 hour'
            GROUP BY metric_name
        LOOP
            -- Get baseline (last 24 hours excluding current hour)
            SELECT AVG(metric_value) INTO baseline_value
            FROM iie.model_performance_metrics
            WHERE model_id = model_record.model_id
              AND metric_name = metric_record.metric_name
              AND measured_at BETWEEN NOW() - INTERVAL '25 hours' AND NOW() - INTERVAL '1 hour';
            
            -- Calculate deviation
            IF baseline_value IS NOT NULL AND baseline_value != 0 THEN
                deviation := ABS(metric_record.current_avg - baseline_value) / baseline_value;
                
                -- Check if deviation exceeds threshold
                IF deviation > model_record.performance_threshold THEN
                    INSERT INTO iie.performance_regression_alerts (
                        model_id,
                        alert_type,
                        severity,
                        metric_name,
                        current_value,
                        expected_value,
                        deviation_percentage,
                        description
                    ) VALUES (
                        model_record.model_id,
                        'performance_degradation',
                        CASE 
                            WHEN deviation > 0.2 THEN 'critical'
                            WHEN deviation > 0.1 THEN 'high' 
                            ELSE 'medium'
                        END,
                        metric_record.metric_name,
                        metric_record.current_avg,
                        baseline_value,
                        deviation * 100,
                        format('Performance regression detected for metric %s: %.2f%% deviation from baseline', 
                               metric_record.metric_name, deviation * 100)
                    );
                    
                    alert_count := alert_count + 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN alert_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.monitor_performance_regressions IS 'Monitors model performance metrics for regressions and creates alerts when deviations exceed thresholds.';

-- View: Model Pipeline Dashboard
CREATE OR REPLACE VIEW iie.vw_model_pipeline_dashboard AS
SELECT 
    m.model_id,
    m.name as model_name,
    m.version,
    m.stage,
    pc.retraining_schedule,
    pc.drift_detection_enabled,
    pc.auto_retrain_on_drift,
    (SELECT COUNT(*) FROM iie.model_training_jobs tj 
     WHERE tj.model_id = m.model_id AND tj.status = 'running') as active_training_jobs,
    (SELECT COUNT(*) FROM iie.drift_detection_results dr 
     WHERE dr.model_id = m.model_id AND dr.is_drift_detected = true 
     AND dr.detected_at >= NOW() - INTERVAL '7 days') as drift_detections_7d,
    (SELECT COUNT(*) FROM iie.performance_regression_alerts pa 
     WHERE pa.model_id = m.model_id AND pa.status = 'active') as active_alerts,
    (SELECT MAX(deployed_at) FROM iie.model_deployments md 
     WHERE md.model_id = m.model_id) as last_deployed_at
FROM iie.ml_models m
LEFT JOIN iie.model_pipeline_config pc ON m.model_id = pc.model_id
WHERE m.stage IN ('production', 'staging');

COMMENT ON VIEW iie.vw_model_pipeline_dashboard IS 'Provides overview of model pipeline status including training jobs, drift detection, and deployments.';

-- View: A/B Test Performance Comparison
CREATE OR REPLACE VIEW iie.vw_ab_test_performance AS
SELECT 
    e.experiment_id,
    e.name as experiment_name,
    e.status,
    control_m.name as control_model,
    treatment_m.name as treatment_model,
    e.primary_metric,
    e.start_date,
    e.end_date,
    (SELECT COUNT(*) FROM iie.ab_test_results r WHERE r.experiment_id = e.experiment_id) as result_count
FROM iie.ab_test_experiments e
JOIN iie.ml_models control_m ON e.control_model_id = control_m.model_id
JOIN iie.ml_models treatment_m ON e.treatment_model_id = treatment_m.model_id
WHERE e.status IN ('running', 'completed');

COMMENT ON VIEW iie.vw_ab_test_performance IS 'Shows active and completed A/B test experiments with model comparisons and result counts.';

--Model Pipeline Dashbaord 
-- Complete pipeline overview
SELECT 
    model_name,
    version,
    stage,
    retraining_schedule,
    drift_detection_enabled,
    auto_retrain_on_drift,
    active_training_jobs,
    drift_detections_7d,
    active_alerts,
    last_deployed_at
FROM iie.vw_model_pipeline_dashboard
ORDER BY active_alerts DESC, drift_detections_7d DESC;

-- High-risk models needing attention
SELECT 
    model_name,
    version,
    active_training_jobs,
    drift_detections_7d,
    active_alerts
FROM iie.vw_model_pipeline_dashboard
WHERE active_alerts > 0 OR drift_detections_7d > 0
ORDER BY active_alerts DESC;

--Model Training Jobs 
-- Current training jobs with status
SELECT 
    j.job_id,
    m.name as model_name,
    m.version,
    j.job_type,
    j.status,
    j.trigger_reason,
    j.created_at,
    j.started_at,
    j.completed_at,
    j.error_message
FROM iie.model_training_jobs j
JOIN iie.ml_models m ON j.model_id = m.model_id
WHERE j.status IN ('pending', 'running')
ORDER BY j.created_at DESC;

-- Recent completed training jobs
SELECT 
    m.name as model_name,
    j.job_type,
    j.trigger_reason,
    j.status,
    j.started_at,
    j.completed_at,
    EXTRACT(EPOCH FROM (j.completed_at - j.started_at))/60 as duration_minutes,
    j.metrics->>'accuracy' as accuracy,
    j.metrics->>'loss' as loss
FROM iie.model_training_jobs j
JOIN iie.ml_models m ON j.model_id = m.model_id
WHERE j.status = 'completed'
  AND j.completed_at >= NOW() - INTERVAL '7 days'
ORDER BY j.completed_at DESC;

-- Training job success rates by type
SELECT 
    job_type,
    COUNT(*) as total_jobs,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_jobs,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_jobs,
    ROUND(COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*) * 100, 1) as success_rate,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/60) as avg_duration_minutes
FROM iie.model_training_jobs
WHERE started_at IS NOT NULL
GROUP BY job_type
ORDER BY total_jobs DESC;


--Training job analysis 
-- Training job metrics over time
SELECT 
    DATE(created_at) as job_date,
    job_type,
    COUNT(*) as job_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/60), 1) as avg_duration_minutes,
    ROUND(COUNT(*) FILTER (WHERE status = 'failed')::NUMERIC / COUNT(*) * 100, 1) as failure_rate
FROM iie.model_training_jobs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), job_type
ORDER BY job_date DESC, job_type;

-- Most common retraining triggers
SELECT 
    trigger_reason,
    COUNT(*) as job_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (completed_at - started_at))/60), 1) as avg_duration_minutes,
    ROUND(COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*) * 100, 1) as success_rate
FROM iie.model_training_jobs
WHERE job_type = 'retrain'
GROUP BY trigger_reason
ORDER BY job_count DESC;

--Drift Detection Results 
-- Recent drift detection results
SELECT 
    m.name as model_name,
    d.detection_type,
    d.metric_name,
    ROUND(d.drift_score, 4) as drift_score,
    ROUND(d.threshold, 4) as threshold,
    d.is_drift_detected,
    ROUND(d.confidence, 3) as confidence,
    d.detected_at,
    d.triggered_retraining
FROM iie.drift_detection_results d
JOIN iie.ml_models m ON d.model_id = m.model_id
WHERE d.detected_at >= NOW() - INTERVAL '7 days'
ORDER BY d.detected_at DESC, d.drift_score DESC;

-- Models with frequent drift detection
SELECT 
    m.name as model_name,
    COUNT(*) as total_drift_events,
    COUNT(*) FILTER (WHERE d.is_drift_detected = true) as confirmed_drift_events,
    ROUND(AVG(d.drift_score), 4) as avg_drift_score,
    MAX(d.detected_at) as last_detected_at
FROM iie.drift_detection_results d
JOIN iie.ml_models m ON d.model_id = m.model_id
WHERE d.detected_at >= NOW() - INTERVAL '30 days'
GROUP BY m.model_id, m.name
HAVING COUNT(*) FILTER (WHERE d.is_drift_detected = true) > 0
ORDER BY confirmed_drift_events DESC;

-- Drift detection by type and severity
SELECT 
    detection_type,
    metric_name,
    COUNT(*) as detection_count,
    ROUND(AVG(drift_score), 4) as avg_drift_score,
    COUNT(*) FILTER (WHERE drift_score > 0.2) as high_drift_count,
    COUNT(*) FILTER (WHERE triggered_retraining = true) as retraining_triggered
FROM iie.drift_detection_results
WHERE detected_at >= NOW() - INTERVAL '30 days'
GROUP BY detection_type, metric_name
ORDER BY detection_count DESC;

--Drift Analysis over time 
-- Drift trends by model
SELECT 
    m.name as model_name,
    DATE(d.detected_at) as detection_date,
    detection_type,
    COUNT(*) as daily_detections,
    ROUND(AVG(drift_score), 4) as avg_drift_score,
    COUNT(*) FILTER (WHERE is_drift_detected = true) as confirmed_drifts
FROM iie.drift_detection_results d
JOIN iie.ml_models m ON d.model_id = m.model_id
WHERE d.detected_at >= NOW() - INTERVAL '90 days'
GROUP BY m.name, DATE(d.detected_at), detection_type
ORDER BY detection_date DESC, daily_detections DESC;

-- Most sensitive drift detection metrics
SELECT 
    metric_name,
    detection_type,
    COUNT(*) as total_checks,
    COUNT(*) FILTER (WHERE is_drift_detected = true) as drift_detections,
    ROUND(COUNT(*) FILTER (WHERE is_drift_detected = true)::NUMERIC / COUNT(*) * 100, 1) as detection_rate,
    ROUND(AVG(drift_score), 4) as avg_drift_score
FROM iie.drift_detection_results
WHERE detected_at >= NOW() - INTERVAL '30 days'
GROUP BY metric_name, detection_type
HAVING COUNT(*) >= 10
ORDER BY detection_rate DESC;

--A/B Testing Experiments 


-- A/B test results with statistical significance
SELECT 
    e.name as experiment_name,
    control_m.name as control_model,
    treatment_m.name as treatment_model,
    r.metric_name,
    ROUND(r.metric_value, 4) as metric_value,
    ROUND(r.standard_error, 4) as std_error,
    ROUND(r.confidence_interval_lower, 4) as ci_lower,
    ROUND(r.confidence_interval_upper, 4) as ci_upper,
    r.is_primary_metric,
    r.calculated_at
FROM iie.ab_test_results r
JOIN iie.ab_test_experiments e ON r.experiment_id = e.experiment_id
JOIN iie.ml_models control_m ON e.control_model_id = control_m.model_id
JOIN iie.ml_models treatment_m ON e.treatment_model_id = treatment_m.model_id
WHERE e.status = 'running'
  AND r.period_end >= NOW() - INTERVAL '1 hour'
ORDER BY e.name, r.metric_name;


-- Evaluate specific A/B test results
SELECT * FROM iie.evaluate_ab_test_results('your-experiment-uuid-here');

-- A/B test completion rates and outcomes
SELECT 
    e.name as experiment_name,
    e.status,
    e.primary_metric,
    e.start_date,
    e.end_date,
    COUNT(r.result_id) as result_count,
    ROUND(AVG(r.metric_value) FILTER (WHERE r.model_id = e.control_model_id), 4) as control_avg,
    ROUND(AVG(r.metric_value) FILTER (WHERE r.model_id = e.treatment_model_id), 4) as treatment_avg
FROM iie.ab_test_experiments e
LEFT JOIN iie.ab_test_results r ON e.experiment_id = r.experiment_id
GROUP BY e.experiment_id, e.name, e.status, e.primary_metric, e.start_date, e.end_date
ORDER BY e.start_date DESC;

--Model Deployments 
-- Recent model deployments
SELECT 
    m.name as model_name,
    m.version,
    d.environment,
    d.deployment_type,
    d.status,
    ROUND(d.traffic_percentage * 100, 1) as traffic_percentage,
    d.deployed_at,
    d.activated_at,
    d.deactivated_at,
    d.rollback_reason
FROM iie.model_deployments d
JOIN iie.ml_models m ON d.model_id = m.model_id
WHERE d.deployed_at >= NOW() - INTERVAL '30 days'
ORDER BY d.deployed_at DESC;

-- Active deployments by environment
SELECT 
    environment,
    deployment_type,
    COUNT(*) as active_deployments,
    ROUND(AVG(traffic_percentage) * 100, 1) as avg_traffic_percentage,
    MAX(deployed_at) as latest_deployment
FROM iie.model_deployments
WHERE status = 'active'
GROUP BY environment, deployment_type
ORDER BY environment, active_deployments DESC;

-- Deployment success rates
SELECT 
    deployment_type,
    environment,
    COUNT(*) as total_deployments,
    COUNT(*) FILTER (WHERE status = 'active') as successful_deployments,
    COUNT(*) FILTER (WHERE status = 'rollback') as rollbacks,
    ROUND(COUNT(*) FILTER (WHERE status = 'active')::NUMERIC / COUNT(*) * 100, 1) as success_rate
FROM iie.model_deployments
WHERE deployed_at >= NOW() - INTERVAL '90 days'
GROUP BY deployment_type, environment
ORDER BY total_deployments DESC;


--Canary Deployment Analysis
-- Canary deployment progress
SELECT 
    m.name as model_name,
    d.deployment_id,
    d.traffic_percentage,
    d.deployed_at,
    d.activated_at,
    baseline_m.name as baseline_model,
    (SELECT COUNT(*) FROM iie.performance_regression_alerts pa 
     WHERE pa.triggered_by_job_id = d.job_id AND pa.status = 'active') as active_alerts
FROM iie.model_deployments d
JOIN iie.ml_models m ON d.model_id = m.model_id
LEFT JOIN iie.ml_models baseline_m ON d.performance_baseline_id = baseline_m.model_id
WHERE d.deployment_type = 'canary'
  AND d.status = 'active'
ORDER BY d.deployed_at DESC;

-- Canary deployment performance
SELECT 
    m.name as model_name,
    d.traffic_percentage,
    COUNT(pa.alert_id) as performance_alerts,
    AVG(mp.metric_value) as current_performance,
    (SELECT AVG(metric_value) 
     FROM iie.model_performance_metrics 
     WHERE model_id = d.performance_baseline_id 
       AND measured_at >= d.deployed_at - INTERVAL '1 hour') as baseline_performance
FROM iie.model_deployments d
JOIN iie.ml_models m ON d.model_id = m.model_id
LEFT JOIN iie.performance_regression_alerts pa ON d.model_id = pa.model_id AND pa.detected_at >= d.deployed_at
LEFT JOIN iie.model_performance_metrics mp ON d.model_id = mp.model_id AND mp.measured_at >= NOW() - INTERVAL '15 minutes'
WHERE d.deployment_type = 'canary'
  AND d.status = 'active'
GROUP BY m.name, d.traffic_percentage, d.performance_baseline_id, d.deployed_at;


-- Current performance regression alerts
SELECT 
    m.name as model_name,
    pa.alert_type,
    pa.severity,
    pa.metric_name,
    ROUND(pa.current_value, 4) as current_value,
    ROUND(pa.expected_value, 4) as expected_value,
    ROUND(pa.deviation_percentage, 1) as deviation_pct,
    pa.description,
    pa.status,
    pa.detected_at,
    pa.acknowledged_at
FROM iie.performance_regression_alerts pa
JOIN iie.ml_models m ON pa.model_id = m.model_id
WHERE pa.status = 'active'
ORDER BY pa.severity DESC, pa.detected_at DESC;

-- Alert trends and patterns
SELECT 
    alert_type,
    severity,
    COUNT(*) as alert_count,
    ROUND(AVG(deviation_percentage), 1) as avg_deviation_pct,
    COUNT(*) FILTER (WHERE status = 'active') as active_alerts,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_alerts,
    ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/3600), 1) as avg_resolution_hours
FROM iie.performance_regression_alerts
WHERE detected_at >= NOW() - INTERVAL '30 days'
GROUP BY alert_type, severity
ORDER BY alert_count DESC;


-- Model-specific alert history
SELECT 
    m.name as model_name,
    DATE(pa.detected_at) as alert_date,
    pa.alert_type,
    pa.severity,
    COUNT(*) as daily_alerts,
    ROUND(AVG(pa.deviation_percentage), 1) as avg_deviation_pct
FROM iie.performance_regression_alerts pa
JOIN iie.ml_models m ON pa.model_id = m.model_id
WHERE pa.detected_at >= NOW() - INTERVAL '90 days'
GROUP BY m.name, DATE(pa.detected_at), pa.alert_type, pa.severity
ORDER BY alert_date DESC, daily_alerts DESC;

-- Alert resolution performance
SELECT 
    m.name as model_name,
    COUNT(*) as total_alerts,
    COUNT(*) FILTER (WHERE status = 'resolved') as resolved_alerts,
    ROUND(COUNT(*) FILTER (WHERE status = 'resolved')::NUMERIC / COUNT(*) * 100, 1) as resolution_rate,
    ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/3600) FILTER (WHERE status = 'resolved'), 1) as avg_resolution_hours
FROM iie.performance_regression_alerts pa
JOIN iie.ml_models m ON pa.model_id = m.model_id
WHERE pa.detected_at >= NOW() - INTERVAL '30 days'
GROUP BY m.name
HAVING COUNT(*) >= 5
ORDER BY resolution_rate ASC;

-- Current pipeline configurations
SELECT 
    m.name as model_name,
    m.stage,
    pc.retraining_schedule,
    pc.drift_detection_enabled,
    pc.performance_monitoring_enabled,
    pc.auto_retrain_on_drift,
    ROUND(pc.drift_threshold, 4) as drift_threshold,
    ROUND(pc.performance_threshold, 4) as performance_threshold,
    pc.min_retraining_interval_days,
    pc.max_retraining_interval_days
FROM iie.model_pipeline_config pc
JOIN iie.ml_models m ON pc.model_id = m.model_id
ORDER BY m.stage, m.name;

-- Configuration effectiveness analysis
SELECT 
    pc.auto_retrain_on_drift,
    pc.drift_threshold,
    COUNT(*) as model_count,
    AVG((SELECT COUNT(*) FROM iie.drift_detection_results dr 
         WHERE dr.model_id = pc.model_id AND dr.is_drift_detected = true 
         AND dr.detected_at >= NOW() - INTERVAL '30 days')) as avg_drift_events_30d,
    AVG((SELECT COUNT(*) FROM iie.performance_regression_alerts pa 
         WHERE pa.model_id = pc.model_id AND pa.status = 'active')) as avg_active_alerts
FROM iie.model_pipeline_config pc
GROUP BY pc.auto_retrain_on_drift, pc.drift_threshold
ORDER BY model_count DESC;

-- Check and trigger retraining based on drift
SELECT * FROM iie.check_and_trigger_retraining();

-- Monitor performance regressions
SELECT iie.monitor_performance_regressions() as new_alerts_created;

-- Deploy model with canary strategy--input model id and job id 
SELECT iie.deploy_model_canary(
    'your-model-uuid-here', 
    'your-job-uuid-here', 
    0.1,  -- 10% traffic
    'production'
) as deployment_id;

-- Evaluate A/B test for decision making --input experiment uuid
SELECT * FROM iie.evaluate_ab_test_results('your-experiment-uuid-here');

--Comprehensive Pipeline Health check 
--Pipeline Health dashbaord 
-- Overall pipeline health status
SELECT 
    'Training Jobs' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'running') as active,
    COUNT(*) FILTER (WHERE status = 'failed') as failed
FROM iie.model_training_jobs
WHERE created_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Drift Detections' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE is_drift_detected = true) as active,
    COUNT(*) FILTER (WHERE triggered_retraining = true) as triggered_retraining
FROM iie.drift_detection_results
WHERE detected_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Active Deployments' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'active') as active,
    COUNT(*) FILTER (WHERE status = 'rollback') as failed
FROM iie.model_deployments
WHERE deployed_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Performance Alerts' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'active') as active,
    COUNT(*) FILTER (WHERE severity = 'critical') as critical
FROM iie.performance_regression_alerts
WHERE detected_at >= NOW() - INTERVAL '24 hours';

-- Pipeline performance metrics
SELECT 
    m.name as model_name,
    (SELECT COUNT(*) FROM iie.model_training_jobs tj 
     WHERE tj.model_id = m.model_id AND tj.status = 'completed' 
     AND tj.completed_at >= NOW() - INTERVAL '30 days') as training_jobs_30d,
    (SELECT COUNT(*) FROM iie.drift_detection_results dr 
     WHERE dr.model_id = m.model_id AND dr.is_drift_detected = true 
     AND dr.detected_at >= NOW() - INTERVAL '30 days') as drift_events_30d,
    (SELECT COUNT(*) FROM iie.performance_regression_alerts pa 
     WHERE pa.model_id = m.model_id AND pa.status = 'active') as active_alerts,
    (SELECT MAX(deployed_at) FROM iie.model_deployments md 
     WHERE md.model_id = m.model_id) as last_deployment
FROM iie.ml_models m
WHERE m.stage = 'production'
ORDER BY active_alerts DESC, drift_events_30d DESC;


-- enhancements for extending the incident response system with team handoff tracking
--skill-based routing and collaboration analytics 

-- =============================================================================
-- INCIDENT RESPONSE TEAM MANAGEMENT EXTENSION
-- ------------------------------------------------------------------------------
-- Purpose: Team handoff tracking, skill-based routing, and collaboration analytics
-- Supports: IIE-044 (Team Coordination), IIE-047 (Fatigue Monitoring)
-- =============================================================================

-- Table: Response Teams
DROP TABLE IF EXISTS iie.response_teams CASCADE;
CREATE TABLE iie.response_teams (
    team_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_name TEXT NOT NULL UNIQUE,
    team_type TEXT NOT NULL CHECK (team_type IN ('primary', 'escalation', 'specialist', 'management')),
    description TEXT,
    escalation_path JSONB,  -- JSON array of team_ids for escalation
    on_call_schedule JSONB,  -- Schedule definition
    skill_requirements JSONB,  -- Required skills for this team
    max_active_incidents INTEGER DEFAULT 5,
    fatigue_threshold NUMERIC(3,2) DEFAULT 0.8,  -- Team fatigue threshold
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.response_teams IS 'Stores response team configurations with escalation paths and skill requirements for intelligent routing.';

-- Table: Team Members
DROP TABLE IF EXISTS iie.team_members CASCADE;
CREATE TABLE iie.team_members (
    member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES iie.response_teams(team_id),
    user_id UUID NOT NULL,  -- Reference to user management system
    role TEXT NOT NULL CHECK (role IN ('manager', 'lead', 'responder', 'specialist', 'analyst')),
    skills JSONB,  -- JSON array of skills and proficiency levels
    max_weekly_hours INTEGER DEFAULT 40,
    is_on_call BOOLEAN DEFAULT FALSE,
    proficiency_score NUMERIC(3,2) DEFAULT 0.7,  -- Overall proficiency score
    availability_status TEXT CHECK (availability_status IN ('available', 'busy', 'offline', 'on_break')) DEFAULT 'available',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

COMMENT ON TABLE iie.team_members IS 'Tracks team members with skills, availability, and role information for skill-based routing.';

-- Table: Incident Handoffs
DROP TABLE IF EXISTS iie.incident_handoffs CASCADE;
CREATE TABLE iie.incident_handoffs (
    handoff_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    from_team_id UUID REFERENCES iie.response_teams(team_id),
    to_team_id UUID REFERENCES iie.response_teams(team_id),
    from_user_id UUID,  -- User initiating handoff
    to_user_id UUID,   -- User receiving handoff
    handoff_type TEXT NOT NULL CHECK (handoff_type IN ('escalation', 'transfer', 'consultation', 'resolution')),
    reason TEXT NOT NULL,
    context_summary TEXT,  -- Summary of current situation
    pending_actions TEXT[],  -- Array of pending actions
    priority_change TEXT CHECK (priority_change IN ('increase', 'decrease', 'same')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')) DEFAULT 'pending',
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    expiration_time TIMESTAMPTZ,
    time_to_accept INTERVAL,  -- Time between request and acceptance
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.incident_handoffs IS 'Tracks incident handoffs between teams and individuals with context and timing information.';

-- Table: Skill-Based Routing Rules
DROP TABLE IF EXISTS iie.routing_rules CASCADE;
CREATE TABLE iie.routing_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL,
    rule_conditions JSONB NOT NULL,  -- Conditions for rule activation
    target_team_id UUID REFERENCES iie.response_teams(team_id),
    target_skills JSONB,  -- Required skills for routing
    priority INTEGER DEFAULT 1,  -- Rule priority (lower = higher priority)
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.routing_rules IS 'Defines skill-based routing rules for automatic incident assignment based on incident characteristics.';

-- Table: Team Collaboration Log
DROP TABLE IF EXISTS iie.team_collaboration_log CASCADE;
CREATE TABLE iie.team_collaboration_log (
    collaboration_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID REFERENCES iie.correlated_incidents(incident_id),
    team_id UUID REFERENCES iie.response_teams(team_id),
    user_id UUID,
    action_type TEXT NOT NULL CHECK (action_type IN ('comment', 'update', 'handoff', 'escalation', 'consultation', 'resolution')),
    description TEXT NOT NULL,
    metadata JSONB,  -- Additional context about the collaboration
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.team_collaboration_log IS 'Logs team collaboration activities for analytics and coordination monitoring.';

-- Table: Team Fatigue Metrics
DROP TABLE IF EXISTS iie.team_fatigue_metrics CASCADE;
CREATE TABLE iie.team_fatigue_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES iie.response_teams(team_id),
    user_id UUID,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    incident_count INTEGER DEFAULT 0,
    total_hours_worked NUMERIC(5,2) DEFAULT 0,
    handoff_count INTEGER DEFAULT 0,
    escalation_count INTEGER DEFAULT 0,
    complexity_score_avg NUMERIC(4,2) DEFAULT 0,
    fatigue_score NUMERIC(3,2) DEFAULT 0,  -- Calculated fatigue score (0-1)
    burnout_risk_level TEXT CHECK (burnout_risk_level IN ('low', 'medium', 'high', 'critical')) DEFAULT 'low',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.team_fatigue_metrics IS 'Tracks team and individual fatigue metrics for burnout prevention and workload management.';

-- Table: Escalation Policies
DROP TABLE IF EXISTS iie.escalation_policies CASCADE;
CREATE TABLE iie.escalation_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name TEXT NOT NULL,
    conditions JSONB NOT NULL,  -- Conditions triggering escalation
    escalation_path JSONB NOT NULL,  -- Ordered list of team_ids for escalation
    time_between_escalations INTERVAL DEFAULT '30 minutes',
    max_escalation_level INTEGER DEFAULT 3,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.escalation_policies IS 'Defines escalation policies for automatic incident escalation based on time and conditions.';

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_team_members_team ON iie.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_availability ON iie.team_members(availability_status);
CREATE INDEX IF NOT EXISTS idx_handoffs_incident ON iie.incident_handoffs(incident_id);
CREATE INDEX IF NOT EXISTS idx_handoffs_status ON iie.incident_handoffs(status);
CREATE INDEX IF NOT EXISTS idx_handoffs_teams ON iie.incident_handoffs(from_team_id, to_team_id);
CREATE INDEX IF NOT EXISTS idx_collaboration_incident ON iie.team_collaboration_log(incident_id);
CREATE INDEX IF NOT EXISTS idx_collaboration_team ON iie.team_collaboration_log(team_id);
CREATE INDEX IF NOT EXISTS idx_fatigue_team ON iie.team_fatigue_metrics(team_id);
CREATE INDEX IF NOT EXISTS idx_fatigue_period ON iie.team_fatigue_metrics(period_start, period_end);

-- Triggers for updated_at
CREATE TRIGGER trigger_update_response_teams_updated_at
    BEFORE UPDATE ON iie.response_teams
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_team_members_updated_at
    BEFORE UPDATE ON iie.team_members
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_routing_rules_updated_at
    BEFORE UPDATE ON iie.routing_rules
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

CREATE TRIGGER trigger_update_escalation_policies_updated_at
    BEFORE UPDATE ON iie.escalation_policies
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

-- =============================================================================
-- TEAM MANAGEMENT AND ROUTING FUNCTIONS
-- =============================================================================

-- Function to find optimal team for incident routing
CREATE OR REPLACE FUNCTION iie.find_optimal_team(
    p_incident_id UUID,
    p_required_skills TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    team_id UUID,
    team_name TEXT,
    match_score NUMERIC(3,2),
    available_members INTEGER,
    avg_proficiency NUMERIC(3,2),
    current_workload INTEGER,
    fatigue_score NUMERIC(3,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH incident_details AS (
        SELECT 
            ci.severity,
            ci.priority,
            ci.complexity_score,
            ee.service_name,
            ee.business_function
        FROM iie.correlated_incidents ci
        LEFT JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
        LEFT JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        WHERE ci.incident_id = p_incident_id
        LIMIT 1
    ),
    team_skills_match AS (
        SELECT 
            rt.team_id,
            rt.team_name,
            CASE 
                WHEN p_required_skills IS NULL THEN 1.0
                ELSE (
                    SELECT COUNT(*)::NUMERIC / GREATEST(array_length(p_required_skills, 1), 1)
                    FROM jsonb_array_elements_text(rt.skill_requirements) skill
                    WHERE skill = ANY(p_required_skills)
                )
            END as skills_match_score
        FROM iie.response_teams rt
        WHERE rt.is_active = true
    ),
    team_availability AS (
        SELECT 
            tm.team_id,
            COUNT(DISTINCT tm.member_id) as total_members,
            COUNT(DISTINCT tm.member_id) FILTER (WHERE tm.availability_status = 'available') as available_members,
            AVG(tm.proficiency_score) as avg_proficiency
        FROM iie.team_members tm
        GROUP BY tm.team_id
    ),
    team_workload AS (
        SELECT 
            ira.assigned_team as team_id,
            COUNT(DISTINCT ira.incident_id) as active_incidents
        FROM iie.incident_response_actions ira
        WHERE ira.status IN ('pending', 'in_progress')
          AND ira.assigned_team IS NOT NULL
        GROUP BY ira.assigned_team
    ),
    team_fatigue AS (
        SELECT 
            tfm.team_id,
            AVG(tfm.fatigue_score) as current_fatigue_score
        FROM iie.team_fatigue_metrics tfm
        WHERE tfm.period_end >= NOW() - INTERVAL '1 day'
        GROUP BY tfm.team_id
    )
    SELECT 
        tsm.team_id,
        tsm.team_name,
        ROUND(
            (tsm.skills_match_score * 0.4) +
            (GREATEST(0, 1 - (tw.active_incidents::NUMERIC / rt.max_active_incidents)) * 0.3) +
            (COALESCE(ta.avg_proficiency, 0.5) * 0.2) +
            (GREATEST(0, 1 - COALESCE(tf.current_fatigue_score, 0)) * 0.1),
        3
        ) as match_score,
        COALESCE(ta.available_members, 0) as available_members,
        COALESCE(ta.avg_proficiency, 0.5) as avg_proficiency,
        COALESCE(tw.active_incidents, 0) as current_workload,
        COALESCE(tf.current_fatigue_score, 0) as fatigue_score
    FROM team_skills_match tsm
    JOIN iie.response_teams rt ON tsm.team_id = rt.team_id
    LEFT JOIN team_availability ta ON tsm.team_id = ta.team_id
    LEFT JOIN team_workload tw ON tsm.team_id = tw.team_id
    LEFT JOIN team_fatigue tf ON tsm.team_id = tf.team_id
    WHERE COALESCE(ta.available_members, 0) > 0
    ORDER BY match_score DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.find_optimal_team IS 'Finds the optimal team for incident assignment based on skills, availability, workload, and fatigue metrics.';

-- Function to initiate team handoff
CREATE OR REPLACE FUNCTION iie.initiate_team_handoff(
    p_incident_id UUID,
    p_from_team_id UUID,
    p_to_team_id UUID,
    p_handoff_type TEXT,
    p_reason TEXT,
    p_context_summary TEXT DEFAULT NULL,
    p_pending_actions TEXT[] DEFAULT NULL,
    p_priority_change TEXT DEFAULT 'same',
    p_expiration_minutes INTEGER DEFAULT 30
)
RETURNS UUID AS $$
DECLARE
    v_handoff_id UUID;
    v_from_user_id UUID;
BEGIN
    -- Get current user from session or system (simplified)
    -- In practice, this would come from application context
    SELECT member_id INTO v_from_user_id
    FROM iie.team_members
    WHERE team_id = p_from_team_id
    LIMIT 1;
    
    -- Create handoff record
    INSERT INTO iie.incident_handoffs (
        incident_id,
        from_team_id,
        to_team_id,
        from_user_id,
        handoff_type,
        reason,
        context_summary,
        pending_actions,
        priority_change,
        expiration_time
    ) VALUES (
        p_incident_id,
        p_from_team_id,
        p_to_team_id,
        v_from_user_id,
        p_handoff_type,
        p_reason,
        p_context_summary,
        p_pending_actions,
        p_priority_change,
        NOW() + (p_expiration_minutes || ' minutes')::INTERVAL
    )
    RETURNING handoff_id INTO v_handoff_id;
    
    -- Log collaboration event
    INSERT INTO iie.team_collaboration_log (
        incident_id,
        team_id,
        user_id,
        action_type,
        description,
        metadata
    ) VALUES (
        p_incident_id,
        p_from_team_id,
        v_from_user_id,
        'handoff',
        format('Initiated %s handoff to team %s', p_handoff_type, p_to_team_id),
        jsonb_build_object(
            'handoff_id', v_handoff_id,
            'reason', p_reason,
            'handoff_type', p_handoff_type
        )
    );
    
    RETURN v_handoff_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.initiate_team_handoff IS 'Initiates a team handoff with context and tracking for smooth incident transitions.';

-- Function to calculate team fatigue scores
CREATE OR REPLACE FUNCTION iie.calculate_team_fatigue(
    p_team_id UUID DEFAULT NULL,
    p_period_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    team_id UUID,
    team_name TEXT,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    total_incidents INTEGER,
    total_hours_worked NUMERIC(8,2),
    avg_complexity NUMERIC(4,2),
    handoff_count INTEGER,
    escalation_count INTEGER,
    fatigue_score NUMERIC(3,2),
    burnout_risk TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH team_incidents AS (
        SELECT 
            ira.assigned_team as team_id,
            COUNT(DISTINCT ira.incident_id) as incident_count,
            AVG(ci.complexity_score) as avg_complexity,
            COUNT(ih.handoff_id) as handoff_count,
            COUNT(ih.handoff_id) FILTER (WHERE ih.handoff_type = 'escalation') as escalation_count
        FROM iie.incident_response_actions ira
        JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
        LEFT JOIN iie.incident_handoffs ih ON ira.incident_id = ih.incident_id
        WHERE ira.assigned_team IS NOT NULL
          AND ira.created_at >= NOW() - (p_period_days || ' days')::INTERVAL
          AND (p_team_id IS NULL OR ira.assigned_team = p_team_id)
        GROUP BY ira.assigned_team
    ),
    team_hours AS (
        SELECT 
            tm.team_id,
            SUM(
                CASE 
                    WHEN tm.is_on_call THEN 40  -- Assume on-call means full availability
                    ELSE 20  -- Part-time engagement
                END
            ) as total_capacity_hours
        FROM iie.team_members tm
        WHERE (p_team_id IS NULL OR tm.team_id = p_team_id)
        GROUP BY tm.team_id
    ),
    fatigue_calculation AS (
        SELECT 
            ti.team_id,
            rt.team_name,
            NOW() - (p_period_days || ' days')::INTERVAL as period_start,
            NOW() as period_end,
            ti.incident_count,
            th.total_capacity_hours,
            ti.avg_complexity,
            ti.handoff_count,
            ti.escalation_count,
            -- Calculate fatigue score (0-1, higher = more fatigued)
            LEAST(1.0, GREATEST(0,
                (ti.incident_count::NUMERIC / 20) * 0.3 +  -- Incident volume component
                (COALESCE(ti.avg_complexity, 0) / 10) * 0.3 +  -- Complexity component
                ((ti.handoff_count + ti.escalation_count)::NUMERIC / 10) * 0.2 +  -- Coordination complexity
                (th.total_capacity_hours::NUMERIC / (40 * (SELECT COUNT(*) FROM iie.team_members WHERE team_id = ti.team_id))) * 0.2  -- Workload component
            )) as calculated_fatigue
        FROM team_incidents ti
        JOIN iie.response_teams rt ON ti.team_id = rt.team_id
        LEFT JOIN team_hours th ON ti.team_id = th.team_id
    )
    SELECT 
        team_id,
        team_name,
        period_start,
        period_end,
        incident_count as total_incidents,
        total_capacity_hours as total_hours_worked,
        avg_complexity,
        handoff_count,
        escalation_count,
        ROUND(calculated_fatigue, 3) as fatigue_score,
        CASE 
            WHEN calculated_fatigue >= 0.8 THEN 'critical'
            WHEN calculated_fatigue >= 0.6 THEN 'high'
            WHEN calculated_fatigue >= 0.4 THEN 'medium'
            ELSE 'low'
        END as burnout_risk
    FROM fatigue_calculation
    ORDER BY calculated_fatigue DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.calculate_team_fatigue IS 'Calculates team fatigue scores based on incident volume, complexity, handoffs, and workload over specified period.';

-- Function to auto-escalate incidents based on policies
CREATE OR REPLACE FUNCTION iie.auto_escalate_incidents()
RETURNS TABLE (
    incident_id UUID,
    incident_title TEXT,
    current_team_id UUID,
    next_team_id UUID,
    escalation_reason TEXT,
    policy_name TEXT
) AS $$
DECLARE
    policy_record RECORD;
    incident_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT * FROM iie.escalation_policies WHERE is_active = true
    LOOP
        FOR incident_record IN
            SELECT 
                ci.incident_id,
                ci.title,
                ci.detected_at,
                ci.severity,
                ci.priority,
                ci.status,
                ira.assigned_team
            FROM iie.correlated_incidents ci
            LEFT JOIN iie.incident_response_actions ira ON ci.incident_id = ira.incident_id
            WHERE ci.status = 'active'
              AND ci.detected_at <= NOW() - policy_record.time_between_escalations
        LOOP
            -- Check if incident matches escalation conditions
            -- This is a simplified condition check - in practice would use JSONB condition evaluation
            IF incident_record.severity IN ('critical', 'high') AND incident_record.status = 'active' THEN
                -- Find next team in escalation path
                WITH escalation_path AS (
                    SELECT 
                        (jsonb_array_elements_text(policy_record.escalation_path)::UUID) as team_id,
                        ordinality - 1 as escalation_level
                    FROM jsonb_array_elements_text(policy_record.escalation_path) WITH ORDINALITY
                )
                SELECT team_id INTO incident_record.assigned_team
                FROM escalation_path
                WHERE escalation_level > 0  -- Skip current team
                ORDER BY escalation_level
                LIMIT 1;
                
                IF FOUND THEN
                    RETURN QUERY SELECT
                        incident_record.incident_id,
                        incident_record.title::TEXT,
                        incident_record.assigned_team as current_team_id,
                        escalation_path.team_id as next_team_id,
                        'Auto-escalation due to time and severity'::TEXT as escalation_reason,
                        policy_record.policy_name::TEXT
                    FROM escalation_path
                    LIMIT 1;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.auto_escalate_incidents IS 'Automatically escalates incidents based on configured escalation policies and conditions.';

-- View: Team Collaboration Analytics
CREATE OR REPLACE VIEW iie.vw_team_collaboration_analytics AS
SELECT 
    rt.team_name,
    DATE(tcl.created_at) as collaboration_date,
    COUNT(*) as total_activities,
    COUNT(*) FILTER (WHERE tcl.action_type = 'handoff') as handoff_count,
    COUNT(*) FILTER (WHERE tcl.action_type = 'escalation') as escalation_count,
    COUNT(*) FILTER (WHERE tcl.action_type = 'consultation') as consultation_count,
    COUNT(DISTINCT tcl.incident_id) as unique_incidents,
    COUNT(DISTINCT tcl.user_id) as unique_contributors
FROM iie.team_collaboration_log tcl
JOIN iie.response_teams rt ON tcl.team_id = rt.team_id
WHERE tcl.created_at >= NOW() - INTERVAL '30 days'
GROUP BY rt.team_name, DATE(tcl.created_at)
ORDER BY collaboration_date DESC, total_activities DESC;

COMMENT ON VIEW iie.vw_team_collaboration_analytics IS 'Provides analytics on team collaboration patterns including handoffs, escalations, and consultations.';

-- View: Handoff Performance Metrics
CREATE OR REPLACE VIEW iie.vw_handoff_performance AS
SELECT 
    from_rt.team_name as from_team,
    to_rt.team_name as to_team,
    ih.handoff_type,
    COUNT(*) as total_handoffs,
    ROUND(AVG(EXTRACT(EPOCH FROM (ih.accepted_at - ih.requested_at))/60) FILTER (WHERE ih.accepted_at IS NOT NULL), 1) as avg_accept_minutes,
    COUNT(*) FILTER (WHERE ih.status = 'accepted') as accepted_handoffs,
    COUNT(*) FILTER (WHERE ih.status = 'rejected') as rejected_handoffs,
    COUNT(*) FILTER (WHERE ih.status = 'expired') as expired_handoffs,
    ROUND(COUNT(*) FILTER (WHERE ih.status = 'accepted')::NUMERIC / COUNT(*) * 100, 1) as acceptance_rate
FROM iie.incident_handoffs ih
JOIN iie.response_teams from_rt ON ih.from_team_id = from_rt.team_id
JOIN iie.response_teams to_rt ON ih.to_team_id = to_rt.team_id
WHERE ih.requested_at >= NOW() - INTERVAL '30 days'
GROUP BY from_rt.team_name, to_rt.team_name, ih.handoff_type
ORDER BY total_handoffs DESC;

COMMENT ON VIEW iie.vw_handoff_performance IS 'Analyzes handoff performance between teams including acceptance rates and timing metrics.';

-- Initialize with sample teams and members
INSERT INTO iie.response_teams (team_name, team_type, description, max_active_incidents, skill_requirements) VALUES
('L1 Support', 'primary', 'First line incident response team', 8, '["troubleshooting", "monitoring", "documentation"]'),
('SRE Team', 'escalation', 'Site Reliability Engineering escalation team', 5, '["kubernetes", "docker", "prometheus", "grafana"]'),
('Database Team', 'specialist', 'Database incident specialists', 3, '["postgresql", "mongodb", "redis", "performance"]'),
('Security Team', 'specialist', 'Security incident response', 4, '["security", "compliance", "incident_response", "forensics"]');

-- Insert sample team members
INSERT INTO iie.team_members (team_id, user_id, role, skills, proficiency_score) VALUES
((SELECT team_id FROM iie.response_teams WHERE team_name = 'L1 Support'), gen_random_uuid(), 'responder', '["troubleshooting", "monitoring", "documentation"]', 0.8),
((SELECT team_id FROM iie.response_teams WHERE team_name = 'SRE Team'), gen_random_uuid(), 'lead', '["kubernetes", "docker", "prometheus", "grafana"]', 0.85),
((SELECT team_id FROM iie.response_teams WHERE team_name = 'Database Team'), gen_random_uuid(), 'specialist', '["postgresql", "mongodb", "performance"]', 0.9);
-- Insert escalation policies
INSERT INTO iie.escalation_policies (policy_name, conditions, escalation_path, time_between_escalations) VALUES
('Critical Incident Escalation', 
 '{"severity": ["critical", "high"], "time_elapsed_minutes": 30}'::jsonb,
 (SELECT jsonb_agg(team_id) FROM iie.response_teams WHERE team_name IN ('L1 Support', 'SRE Team', 'Database Team')),
 '30 minutes'::interval);


-- Team Structure and Composition 

-- All active teams with member counts
SELECT 
    rt.team_id,
    rt.team_name,
    rt.team_type,
    rt.description,
    rt.max_active_incidents,
    rt.fatigue_threshold,
    COUNT(tm.member_id) as member_count,
    COUNT(tm.member_id) FILTER (WHERE tm.is_on_call = true) as on_call_count,
    COUNT(tm.member_id) FILTER (WHERE tm.availability_status = 'available') as available_members
FROM iie.response_teams rt
LEFT JOIN iie.team_members tm ON rt.team_id = tm.team_id
WHERE rt.is_active = true
GROUP BY rt.team_id, rt.team_name, rt.team_type, rt.description, rt.max_active_incidents, rt.fatigue_threshold
ORDER BY rt.team_type, member_count DESC;

-- Team skill inventory
SELECT 
    rt.team_name,
    rt.team_type,
    jsonb_array_elements_text(rt.skill_requirements) as required_skill,
    COUNT(DISTINCT tm.member_id) as members_with_skill
FROM iie.response_teams rt
LEFT JOIN iie.team_members tm ON rt.team_id = tm.team_id
WHERE rt.is_active = true
GROUP BY rt.team_name, rt.team_type, jsonb_array_elements_text(rt.skill_requirements)
ORDER BY rt.team_name, members_with_skill DESC;


-- Team member roster with skills and availability
SELECT 
    rt.team_name,
    tm.member_id,
    tm.role,
    tm.skills,
    ROUND(tm.proficiency_score, 3) as proficiency_score,
    tm.availability_status,
    tm.is_on_call,
    tm.max_weekly_hours,
    tm.created_at
FROM iie.team_members tm
JOIN iie.response_teams rt ON tm.team_id = rt.team_id
WHERE rt.is_active = true
ORDER BY rt.team_name, tm.role, tm.proficiency_score DESC;

-- Available team members for immediate assignment
SELECT 
    rt.team_name,
    tm.member_id,
    tm.role,
    tm.skills,
    ROUND(tm.proficiency_score, 3) as proficiency,
    tm.max_weekly_hours
FROM iie.team_members tm
JOIN iie.response_teams rt ON tm.team_id = rt.team_id
WHERE tm.availability_status = 'available'
  AND rt.is_active = true
ORDER BY rt.team_name, tm.proficiency_score DESC;

--SKILL-BASED ROUTING AND MATCHING 
-- Find optimal teams for a specific incident --input
SELECT * FROM iie.find_optimal_team('your-incident-uuid-here');

-- Find teams with specific skill requirements--input
SELECT * FROM iie.find_optimal_team('your-incident-uuid-here', 
    ARRAY['kubernetes', 'docker', 'monitoring']);

-- Team matching scores for different skill sets
-- SELECT 
--     rt.team_name,
--     rt.team_type,
--     (SELECT COUNT(*) FROM jsonb_array_elements_text(rt.skill_requirements) 
--      WHERE value IN ('kubernetes', 'docker', 'prometheus')) as matching_skills,
--     array_length(rt.skill_requirements::text[], 1) as total_required_skills,
--     ROUND(
--         (SELECT COUNT(*) FROM jsonb_array_elements_text(rt.skill_requirements) 
--          WHERE value IN ('kubernetes', 'docker', 'prometheus'))::NUMERIC / 
--         GREATEST(array_length(rt.skill_requirements::text[], 1), 1),
--     3) as skill_match_ratio
-- FROM iie.response_teams rt
-- WHERE rt.is_active = true
-- ORDER BY skill_match_ratio DESC;

--Routing rules Analysis 
-- Active routing rules
SELECT 
    rr.rule_id,
    rr.rule_name,
    rr.rule_conditions,
    rt.team_name as target_team,
    rr.target_skills,
    rr.priority,
    rr.is_active,
    rr.description
FROM iie.routing_rules rr
JOIN iie.response_teams rt ON rr.target_team_id = rt.team_id
WHERE rr.is_active = true
ORDER BY rr.priority, rr.rule_name;

-- Routing rule effectiveness
SELECT 
    rr.rule_name,
    rt.team_name,
    COUNT(ira.action_id) as assignments_made,
    AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) as avg_resolution_minutes
FROM iie.routing_rules rr
JOIN iie.response_teams rt ON rr.target_team_id = rt.team_id
LEFT JOIN iie.incident_response_actions ira ON rt.team_id = ira.assigned_team
LEFT JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
WHERE rr.is_active = true
  AND ira.created_at >= NOW() - INTERVAL '30 days'
GROUP BY rr.rule_name, rt.team_name
ORDER BY assignments_made DESC;

--Handoff Tracking and Performance 
-- Pending handoffs requiring action
SELECT 
    ih.handoff_id,
    ci.incident_id,
    ci.title as incident_title,
    ci.severity,
    from_rt.team_name as from_team,
    to_rt.team_name as to_team,
    ih.handoff_type,
    ih.reason,
    ih.context_summary,
    ih.status,
    ih.requested_at,
    ih.expiration_time,
    EXTRACT(EPOCH FROM (ih.expiration_time - NOW()))/60 as minutes_until_expiry
FROM iie.incident_handoffs ih
JOIN iie.correlated_incidents ci ON ih.incident_id = ci.incident_id
JOIN iie.response_teams from_rt ON ih.from_team_id = from_rt.team_id
JOIN iie.response_teams to_rt ON ih.to_team_id = to_rt.team_id
WHERE ih.status = 'pending'
  AND ih.expiration_time > NOW()
ORDER BY ih.expiration_time ASC;

-- Recent handoff history
SELECT 
    ih.handoff_id,
    ci.title as incident_title,
    from_rt.team_name as from_team,
    to_rt.team_name as to_team,
    ih.handoff_type,
    ih.reason,
    ih.status,
    ih.requested_at,
    ih.accepted_at,
    ROUND(EXTRACT(EPOCH FROM (ih.accepted_at - ih.requested_at))/60, 1) as time_to_accept_minutes
FROM iie.incident_handoffs ih
JOIN iie.correlated_incidents ci ON ih.incident_id = ci.incident_id
JOIN iie.response_teams from_rt ON ih.from_team_id = from_rt.team_id
JOIN iie.response_teams to_rt ON ih.to_team_id = to_rt.team_id
WHERE ih.requested_at >= NOW() - INTERVAL '7 days'
ORDER BY ih.requested_at DESC;


--Handoff Performance Analytics
-- Handoff performance metrics from view
SELECT 
    from_team,
    to_team,
    handoff_type,
    total_handoffs,
    avg_accept_minutes,
    accepted_handoffs,
    rejected_handoffs,
    expired_handoffs,
    acceptance_rate
FROM iie.vw_handoff_performance
ORDER BY total_handoffs DESC;

-- Handoff reasons and patterns
SELECT 
    ih.handoff_type,
    ih.reason,
    COUNT(*) as handoff_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (ih.accepted_at - ih.requested_at))/60) FILTER (WHERE ih.accepted_at IS NOT NULL), 1) as avg_accept_minutes,
    ROUND(COUNT(*) FILTER (WHERE ih.status = 'accepted')::NUMERIC / COUNT(*) * 100, 1) as acceptance_rate
FROM iie.incident_handoffs ih
WHERE ih.requested_at >= NOW() - INTERVAL '30 days'
GROUP BY ih.handoff_type, ih.reason
ORDER BY handoff_count DESC;

--Fatigue monitoring and workload management 

-- Current team fatigue scores
SELECT * FROM iie.calculate_team_fatigue();

-- Fatigue analysis for specific team
SELECT * FROM iie.calculate_team_fatigue('your-team-uuid-here', 7);

-- -- Teams at high burnout risk
-- SELECT 
--     team_id,
--     total_incidents,
--     total_hours_worked,
--     avg_complexity,
--     fatigue_score,
--     burnout_risk
-- FROM iie.calculate_team_fatigue()
-- WHERE burnout_risk IN ('high', 'critical')
-- ORDER BY fatigue_score DESC;

-- Fatigue trends over time
SELECT 
    tfm.team_id,
    rt.team_name,
    DATE(tfm.period_start) as period_date,
    tfm.incident_count,
    tfm.fatigue_score,
    tfm.burnout_risk_level
FROM iie.team_fatigue_metrics tfm
JOIN iie.response_teams rt ON tfm.team_id = rt.team_id
WHERE tfm.period_start >= NOW() - INTERVAL '30 days'
ORDER BY tfm.period_start DESC, tfm.fatigue_score DESC;

--Workload Distribution 

-- Current team workload
SELECT 
    rt.team_name,
    rt.max_active_incidents,
    COUNT(DISTINCT ira.incident_id) FILTER (WHERE ira.status IN ('pending', 'in_progress')) as current_active_incidents,
    ROUND(COUNT(DISTINCT ira.incident_id) FILTER (WHERE ira.status IN ('pending', 'in_progress'))::NUMERIC / rt.max_active_incidents * 100, 1) as capacity_utilization_pct,
    COUNT(DISTINCT tm.member_id) as team_size,
    COUNT(DISTINCT tm.member_id) FILTER (WHERE tm.availability_status = 'available') as available_members
FROM iie.response_teams rt
LEFT JOIN iie.incident_response_actions ira ON rt.team_id = ira.assigned_team
LEFT JOIN iie.team_members tm ON rt.team_id = tm.team_id
WHERE rt.is_active = true
  AND (ira.status IN ('pending', 'in_progress') OR ira.incident_id IS NULL)
GROUP BY rt.team_id, rt.team_name, rt.max_active_incidents
ORDER BY capacity_utilization_pct DESC;

-- Individual member workload
SELECT 
    rt.team_name,
    tm.member_id,
    tm.role,
    COUNT(ira.action_id) as assigned_actions,
    COUNT(ira.action_id) FILTER (WHERE ira.status IN ('pending', 'in_progress')) as active_actions,
    tm.max_weekly_hours,
    ROUND(tm.proficiency_score, 3) as proficiency
FROM iie.team_members tm
JOIN iie.response_teams rt ON tm.team_id = rt.team_id
LEFT JOIN iie.incident_response_actions ira ON tm.member_id = ira.assigned_individual
WHERE rt.is_active = true
GROUP BY rt.team_name, tm.member_id, tm.role, tm.max_weekly_hours, tm.proficiency_score
ORDER BY rt.team_name, active_actions DESC;


--Collaboration Analytics 
-- Collaboration analytics from view
SELECT 
    team_name,
    collaboration_date,
    total_activities,
    handoff_count,
    escalation_count,
    consultation_count,
    unique_incidents,
    unique_contributors
FROM iie.vw_team_collaboration_analytics
ORDER BY collaboration_date DESC, total_activities DESC;

-- Detailed collaboration log
SELECT 
    rt.team_name,
    ci.title as incident_title,
    tcl.action_type,
    tcl.description,
    tcl.metadata,
    tcl.created_at
FROM iie.team_collaboration_log tcl
JOIN iie.response_teams rt ON tcl.team_id = rt.team_id
JOIN iie.correlated_incidents ci ON tcl.incident_id = ci.incident_id
WHERE tcl.created_at >= NOW() - INTERVAL '7 days'
ORDER BY tcl.created_at DESC;

-- Most collaborative teams
SELECT 
    rt.team_name,
    COUNT(DISTINCT tcl.incident_id) as incidents_involved,
    COUNT(DISTINCT tcl.collaboration_id) as total_collaborations,
    COUNT(DISTINCT tcl.collaboration_id) FILTER (WHERE tcl.action_type = 'handoff') as handoffs_initiated,
    COUNT(DISTINCT tcl.collaboration_id) FILTER (WHERE tcl.action_type = 'consultation') as consultations
FROM iie.team_collaboration_log tcl
JOIN iie.response_teams rt ON tcl.team_id = rt.team_id
WHERE tcl.created_at >= NOW() - INTERVAL '30 days'
GROUP BY rt.team_name
ORDER BY total_collaborations DESC;

--Escalation management 
-- Active escalation policies
SELECT 
    ep.policy_id,
    ep.policy_name,
    ep.conditions,
    ep.escalation_path,
    ep.time_between_escalations,
    ep.max_escalation_level,
    ep.is_active
FROM iie.escalation_policies ep
WHERE ep.is_active = true
ORDER BY ep.policy_name;

-- Escalation path visualization
SELECT 
    ep.policy_name,
    teams.team_name,
    teams.escalation_level
FROM iie.escalation_policies ep
CROSS JOIN LATERAL (
    SELECT 
        rt.team_name,
        ordinality - 1 as escalation_level
    FROM jsonb_array_elements_text(ep.escalation_path) WITH ORDINALITY arr(team_id)
    JOIN iie.response_teams rt ON (arr.team_id)::UUID = rt.team_id
) teams
WHERE ep.is_active = true
ORDER BY ep.policy_name, teams.escalation_level;

--Auto-Escalation Analysis 
-- Check for incidents needing escalation
SELECT * FROM iie.auto_escalate_incidents();

-- Escalation history
SELECT 
    ci.incident_id,
    ci.title,
    ci.severity,
    from_rt.team_name as from_team,
    to_rt.team_name as to_team,
    ih.handoff_type,
    ih.reason,
    ih.requested_at,
    ih.accepted_at
FROM iie.incident_handoffs ih
JOIN iie.correlated_incidents ci ON ih.incident_id = ci.incident_id
JOIN iie.response_teams from_rt ON ih.from_team_id = from_rt.team_id
JOIN iie.response_teams to_rt ON ih.to_team_id = to_rt.team_id
WHERE ih.handoff_type = 'escalation'
  AND ih.requested_at >= NOW() - INTERVAL '30 days'
ORDER BY ih.requested_at DESC;


-- Team Performance Metrics 
-- Team resolution performance
SELECT 
    rt.team_name,
    COUNT(DISTINCT ira.incident_id) as total_incidents_handled,
    COUNT(DISTINCT ira.incident_id) FILTER (WHERE ci.status = 'resolved') as resolved_incidents,
    ROUND(AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60), 1) as avg_resolution_minutes,
    ROUND(AVG(ci.complexity_score), 2) as avg_complexity,
    ROUND(AVG(ira.effectiveness_score), 3) as avg_effectiveness
FROM iie.incident_response_actions ira
JOIN iie.response_teams rt ON ira.assigned_team = rt.team_id
JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
WHERE ira.created_at >= NOW() - INTERVAL '30 days'
GROUP BY rt.team_name
ORDER BY resolved_incidents DESC;

-- Team response time analysis
SELECT 
    rt.team_name,
    COUNT(ira.action_id) as total_actions,
    ROUND(AVG(EXTRACT(EPOCH FROM (ira.completed_at - ira.started_at))/60) FILTER (WHERE ira.completed_at IS NOT NULL), 1) as avg_completion_minutes,
    ROUND(AVG(ira.effectiveness_score), 3) as avg_effectiveness,
    COUNT(ih.handoff_id) as handoffs_received
FROM iie.incident_response_actions ira
JOIN iie.response_teams rt ON ira.assigned_team = rt.team_id
LEFT JOIN iie.incident_handoffs ih ON ira.incident_id = ih.incident_id AND ih.to_team_id = rt.team_id
WHERE ira.created_at >= NOW() - INTERVAL '30 days'
GROUP BY rt.team_name
ORDER BY avg_effectiveness DESC;

---calculate team fatigue
CREATE OR REPLACE FUNCTION iie.calculate_team_fatigue(
    p_team_id UUID DEFAULT NULL,
    p_period_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    team_id UUID,
    team_name TEXT,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    total_incidents INTEGER,
    total_hours_worked NUMERIC(8,2),
    avg_complexity NUMERIC(4,2),
    handoff_count INTEGER,
    escalation_count INTEGER,
    fatigue_score NUMERIC(3,2),
    burnout_risk TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH team_incidents AS (
        SELECT 
            ira.assigned_team as incident_team_id,
            COUNT(DISTINCT ira.incident_id)::INTEGER as incident_count,
            AVG(ci.complexity_score)::NUMERIC(4,2) as avg_complexity,  -- Cast to NUMERIC(4,2)
            COUNT(ih.handoff_id)::INTEGER as handoff_count,
            COUNT(ih.handoff_id) FILTER (WHERE ih.handoff_type = 'escalation')::INTEGER as escalation_count
        FROM iie.incident_response_actions ira
        JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
        LEFT JOIN iie.incident_handoffs ih ON ira.incident_id = ih.incident_id
        WHERE ira.assigned_team IS NOT NULL
          AND ira.created_at >= NOW() - (p_period_days || ' days')::INTERVAL
          AND (p_team_id IS NULL OR ira.assigned_team = p_team_id)
        GROUP BY ira.assigned_team
    ),
    team_hours AS (
        SELECT 
            tm.team_id as member_team_id,
            SUM(
                CASE 
                    WHEN tm.is_on_call THEN 40
                    ELSE 20
                END
            )::NUMERIC(8,2) as total_capacity_hours  -- Cast to NUMERIC(8,2)
        FROM iie.team_members tm
        WHERE (p_team_id IS NULL OR tm.team_id = p_team_id)
        GROUP BY tm.team_id
    ),
    fatigue_calculation AS (
        SELECT 
            ti.incident_team_id,
            rt.team_name,
            NOW() - (p_period_days || ' days')::INTERVAL as period_start,
            NOW() as period_end,
            ti.incident_count,
            th.total_capacity_hours,
            ti.avg_complexity,
            ti.handoff_count,
            ti.escalation_count,
            LEAST(1.0, GREATEST(0,
                (ti.incident_count::NUMERIC / 20) * 0.3 +
                (COALESCE(ti.avg_complexity, 0) / 10) * 0.3 +
                ((ti.handoff_count + ti.escalation_count)::NUMERIC / 10) * 0.2 +
                (th.total_capacity_hours::NUMERIC / (40 * (SELECT COUNT(*) FROM iie.team_members WHERE team_members.team_id = ti.incident_team_id))) * 0.2
            )) as calculated_fatigue
        FROM team_incidents ti
        JOIN iie.response_teams rt ON ti.incident_team_id = rt.team_id
        LEFT JOIN team_hours th ON ti.incident_team_id = th.member_team_id
    )
    SELECT 
        fc.incident_team_id,
        fc.team_name,
        fc.period_start,
        fc.period_end,
        fc.incident_count as total_incidents,
        fc.total_capacity_hours as total_hours_worked,
        fc.avg_complexity,
        fc.handoff_count,
        fc.escalation_count,
        ROUND(fc.calculated_fatigue, 3) as fatigue_score,
        CASE 
            WHEN fc.calculated_fatigue >= 0.8 THEN 'critical'
            WHEN fc.calculated_fatigue >= 0.6 THEN 'high'
            WHEN fc.calculated_fatigue >= 0.4 THEN 'medium'
            ELSE 'low'
        END as burnout_risk
    FROM fatigue_calculation fc
    ORDER BY fc.calculated_fatigue DESC;
END;
$$ LANGUAGE plpgsql;

--Operational Health Checks 
-- Team management system health
SELECT 
    'Response Teams' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE is_active = true) as active
FROM iie.response_teams
UNION ALL
SELECT 
    'Team Members' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE availability_status = 'available') as available
FROM iie.team_members
UNION ALL
SELECT 
    'Active Handoffs' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'pending') as pending
FROM iie.incident_handoffs
WHERE requested_at >= NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    'Fatigue Alerts' as category,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE burnout_risk IN ('high', 'critical')) as critical
FROM iie.calculate_team_fatigue();

-- Team capacity overview
SELECT 
    rt.team_name,
    rt.max_active_incidents,
    (SELECT COUNT(*) FROM iie.incident_response_actions 
     WHERE assigned_team = rt.team_id AND status IN ('pending', 'in_progress')) as current_load,
    (SELECT COUNT(*) FROM iie.team_members 
     WHERE team_id = rt.team_id AND availability_status = 'available') as available_members,
    COALESCE(tf.fatigue_score, 0) as fatigue_score
FROM iie.response_teams rt
LEFT JOIN iie.calculate_team_fatigue() tf ON rt.team_id = tf.team_id
WHERE rt.is_active = true
ORDER BY current_load DESC;



-- Team capacity overview (simplified - remove fatigue score)
SELECT 
    rt.team_name,
    rt.max_active_incidents,
    (SELECT COUNT(*) FROM iie.incident_response_actions 
     WHERE assigned_team = rt.team_id AND status IN ('pending', 'in_progress')) as current_load,
    (SELECT COUNT(*) FROM iie.team_members 
     WHERE team_id = rt.team_id AND availability_status = 'available') as available_members
FROM iie.response_teams rt
WHERE rt.is_active = true
ORDER BY current_load DESC;

--- Comprehensive Predictive Analytics Framework 

-- =============================================================================
-- PREDICTIVE ANALYTICS FRAMEWORK
-- ------------------------------------------------------------------------------
-- Purpose: Capacity planning, seasonal trend detection, and business impact forecasting
-- Supports: IIE-064 (Cross-Domain Insight), IIE-065 (Operational Intelligence)
-- =============================================================================

-- Table: Capacity Forecast Models
DROP TABLE IF EXISTS iie.capacity_forecast_models CASCADE;
CREATE TABLE iie.capacity_forecast_models (
    forecast_model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    forecast_type TEXT NOT NULL CHECK (forecast_type IN ('incident_volume', 'response_capacity', 'cost_impact', 'resource_utilization')),
    target_entity TEXT NOT NULL,  -- 'team', 'service', 'business_function'
    target_entity_id UUID,  -- Specific team/service ID or NULL for aggregate
    algorithm TEXT NOT NULL CHECK (algorithm IN ('arima', 'prophet', 'exponential_smoothing', 'random_forest', 'lstm')),
    hyperparameters JSONB,
    training_data_range_start TIMESTAMPTZ,
    training_data_range_end TIMESTAMPTZ,
    seasonality_patterns JSONB,  -- Detected seasonal patterns
    accuracy_metrics JSONB,  -- MAE, RMSE, MAPE, etc.
    forecast_horizon_days INTEGER NOT NULL,  -- How far ahead to forecast
    retrain_frequency_days INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_trained_at TIMESTAMPTZ,
    next_retrain_at TIMESTAMPTZ
);

COMMENT ON TABLE iie.capacity_forecast_models IS 'Stores predictive models for capacity planning and trend forecasting with performance metrics.';

-- Table: Forecast Results
DROP TABLE IF EXISTS iie.forecast_results CASCADE;
CREATE TABLE iie.forecast_results (
    forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forecast_model_id UUID REFERENCES iie.capacity_forecast_models(forecast_model_id),
    forecast_date DATE NOT NULL,  -- Date being forecasted
    forecast_value NUMERIC(12,4) NOT NULL,
    confidence_interval_lower NUMERIC(12,4),
    confidence_interval_upper NUMERIC(12,4),
    confidence_level NUMERIC(3,2) DEFAULT 0.95,
    is_actual BOOLEAN DEFAULT FALSE,  -- Whether this is actual observed data
    actual_value NUMERIC(12,4),  -- Actual value when available
    forecast_error NUMERIC(12,4),  -- Difference between forecast and actual
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(forecast_model_id, forecast_date, is_actual)
);

COMMENT ON TABLE iie.forecast_results IS 'Stores forecast results with confidence intervals and actuals for model validation.';

-- Table: Seasonal Patterns
DROP TABLE IF EXISTS iie.seasonal_patterns CASCADE;
CREATE TABLE iie.seasonal_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('service', 'team', 'business_function', 'incident_type')),
    entity_id UUID,  -- Specific entity or NULL for global patterns
    pattern_type TEXT NOT NULL CHECK (pattern_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
    seasonality_strength NUMERIC(3,2) NOT NULL,  -- 0-1 strength of pattern
    pattern_data JSONB NOT NULL,  -- JSON with pattern details (hourly, day-of-week, etc.)
    confidence NUMERIC(3,2) NOT NULL,
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ
);

COMMENT ON TABLE iie.seasonal_patterns IS 'Stores detected seasonal patterns in incident volume and business impact.';

-- Table: Business Impact Scenarios
DROP TABLE IF EXISTS iie.business_impact_scenarios CASCADE;
CREATE TABLE iie.business_impact_scenarios (
    scenario_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_name TEXT NOT NULL,
    scenario_type TEXT NOT NULL CHECK (scenario_type IN ('capacity_shortfall', 'seasonal_spike', 'infrastructure_outage', 'new_feature_launch')),
    description TEXT,
    assumptions JSONB NOT NULL,
    impacted_services JSONB,  -- Services affected by this scenario
    probability NUMERIC(3,2) NOT NULL,  -- 0-1 probability of occurrence
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    time_horizon TEXT NOT NULL CHECK (time_horizon IN ('immediate', 'short_term', 'medium_term', 'long_term')),
    estimated_cost_impact NUMERIC(12,2),
    estimated_user_impact INTEGER,
    mitigation_strategies JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE iie.business_impact_scenarios IS 'Stores business impact scenarios for what-if analysis and risk assessment.';

-- Table: Resource Capacity Projections
DROP TABLE IF EXISTS iie.resource_capacity_projections CASCADE;
CREATE TABLE iie.resource_capacity_projections (
    projection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES iie.response_teams(team_id),
    service_name TEXT,
    projection_date DATE NOT NULL,
    projected_incident_volume INTEGER,
    available_capacity INTEGER,  -- Available team capacity in incidents
    capacity_gap INTEGER,  -- projected_incident_volume - available_capacity
    required_additional_capacity INTEGER,
    confidence_level NUMERIC(3,2) DEFAULT 0.8,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, service_name, projection_date)
);

COMMENT ON TABLE iie.resource_capacity_projections IS 'Projects resource capacity gaps for proactive team scaling and resource allocation.';

-- Table: Anomaly Detection Results
DROP TABLE IF EXISTS iie.anomaly_detection_results CASCADE;
CREATE TABLE iie.anomaly_detection_results (
    anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL,
    entity_id UUID,
    metric_name TEXT NOT NULL,
    expected_value NUMERIC(12,4),
    actual_value NUMERIC(12,4),
    anomaly_score NUMERIC(5,4) NOT NULL,  -- 0-1 anomaly score
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    explanation TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ
);

COMMENT ON TABLE iie.anomaly_detection_results IS 'Stores detected anomalies in operational metrics for early warning and intervention.';

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_forecast_models_type ON iie.capacity_forecast_models(forecast_type, is_active);
CREATE INDEX IF NOT EXISTS idx_forecast_results_date ON iie.forecast_results(forecast_date);
CREATE INDEX IF NOT EXISTS idx_forecast_results_model ON iie.forecast_results(forecast_model_id, forecast_date);
CREATE INDEX IF NOT EXISTS idx_seasonal_patterns_type ON iie.seasonal_patterns(entity_type, pattern_type);
CREATE INDEX IF NOT EXISTS idx_capacity_projections_date ON iie.resource_capacity_projections(projection_date);
CREATE INDEX IF NOT EXISTS idx_anomaly_detection_time ON iie.anomaly_detection_results(detected_at);
CREATE INDEX IF NOT EXISTS idx_anomaly_severity ON iie.anomaly_detection_results(severity, is_resolved);

-- Triggers for updated_at
CREATE TRIGGER trigger_update_business_scenarios_updated_at
    BEFORE UPDATE ON iie.business_impact_scenarios
    FOR EACH ROW EXECUTE FUNCTION iie.update_updated_at_column();

-- Initialize with sample forecast models
INSERT INTO iie.capacity_forecast_models (
    model_name, 
    forecast_type, 
    target_entity, 
    algorithm, 
    forecast_horizon_days,
    hyperparameters
) VALUES 
('Service Incident Volume', 'incident_volume', 'service', 'prophet', 30, '{"seasonality_mode": "multiplicative", "changepoint_prior_scale": 0.05}'),
('Team Capacity', 'response_capacity', 'team', 'arima', 14, '{"order": [2,1,2], "seasonal_order": [1,1,1,7]}'),
('Cost Impact', 'cost_impact', 'business_function', 'random_forest', 30, '{"n_estimators": 100, "max_depth": 10}');

-- Initialize with sample seasonal patterns
INSERT INTO iie.seasonal_patterns (
    entity_type, 
    pattern_type, 
    seasonality_strength, 
    pattern_data, 
    confidence,
    valid_from
) VALUES 
('service', 'daily', 0.8, 
 '{"peak_hours": [9, 10, 11, 14, 15, 16], "trough_hours": [0, 1, 2, 3, 4, 5]}', 
 0.9, NOW() - INTERVAL '1 day'),
('service', 'weekly', 0.6, 
 '{"peak_days": [1, 2, 3, 4], "trough_days": [0, 6]}', 
 0.8, NOW() - INTERVAL '1 day');

-- =============================================================================
-- PREDICTIVE ANALYTICS FUNCTIONS
-- =============================================================================

-- Function to generate incident volume forecasts
--drop the existing function
DROP FUNCTION IF EXISTS iie.generate_incident_volume_forecast(INTEGER, NUMERIC);


-- Then recreate the function with the fixed ROUND calls
CREATE OR REPLACE FUNCTION iie.generate_incident_volume_forecast(
    p_forecast_horizon_days INTEGER DEFAULT 30,
    p_confidence_level NUMERIC DEFAULT 0.95
)
RETURNS TABLE (
    forecast_date DATE,
    forecast_service_name TEXT,
    projected_incidents NUMERIC(10,2),
    confidence_lower NUMERIC(10,2),
    confidence_upper NUMERIC(10,2),
    trend_direction TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH historical_data AS (
        SELECT 
            ee.service_name,
            DATE(ci.detected_at) as incident_date,
            COUNT(*) as daily_incidents
        FROM iie.correlated_incidents ci
        JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
        JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        WHERE ci.detected_at >= NOW() - INTERVAL '90 days'
          AND ee.service_name IS NOT NULL
        GROUP BY ee.service_name, DATE(ci.detected_at)
    ),
    service_trends AS (
        SELECT 
            hd.service_name,
            AVG(hd.daily_incidents) as avg_incidents,
            STDDEV(hd.daily_incidents) as std_incidents,
            CORR(EXTRACT(EPOCH FROM hd.incident_date)::NUMERIC, hd.daily_incidents::NUMERIC) as trend_correlation
        FROM historical_data hd
        GROUP BY hd.service_name
    ),
    date_series AS (
        SELECT 
            generate_series(
                CURRENT_DATE + 1, 
                CURRENT_DATE + p_forecast_horizon_days, 
                '1 day'::interval
            )::DATE as forecast_date
    ),
    forecasts AS (
        SELECT 
            ds.forecast_date,
            st.service_name,
            -- Simple linear forecast with seasonality adjustment
            GREATEST(0, 
                st.avg_incidents + 
                (st.trend_correlation * (EXTRACT(EPOCH FROM ds.forecast_date) - EXTRACT(EPOCH FROM CURRENT_DATE)) / 86400 * 0.1) +
                -- Weekly seasonality component
                (st.avg_incidents * 
                 CASE EXTRACT(DOW FROM ds.forecast_date)
                    WHEN 0 THEN -0.1  -- Sunday
                    WHEN 6 THEN -0.15 -- Saturday
                    ELSE 0.05         -- Weekdays
                 END)
            ) as projected_incidents,
            st.std_incidents
        FROM date_series ds
        CROSS JOIN service_trends st
        WHERE st.avg_incidents > 1  -- Only forecast for services with sufficient history
    )
    SELECT 
        f.forecast_date,
        f.service_name as forecast_service_name,
        -- Cast to NUMERIC before using ROUND with precision
        ROUND(f.projected_incidents::NUMERIC, 2) as projected_incidents,
        ROUND(GREATEST(0, f.projected_incidents - (f.std_incidents * 1.96))::NUMERIC, 2) as confidence_lower,
        ROUND((f.projected_incidents + (f.std_incidents * 1.96))::NUMERIC, 2) as confidence_upper,
        CASE 
            WHEN f.projected_incidents > (SELECT st2.avg_incidents FROM service_trends st2 WHERE st2.service_name = f.service_name) THEN 'increasing'
            WHEN f.projected_incidents < (SELECT st2.avg_incidents FROM service_trends st2 WHERE st2.service_name = f.service_name) THEN 'decreasing'
            ELSE 'stable'
        END as trend_direction
    FROM forecasts f
    ORDER BY f.forecast_date, f.projected_incidents DESC;
END;
$$ LANGUAGE plpgsql;


---new version 
DROP FUNCTION iie.detect_seasonal_patterns;
CREATE OR REPLACE FUNCTION iie.detect_seasonal_patterns(
    p_lookback_days INTEGER DEFAULT 180
)
RETURNS TABLE (
    detected_entity_type TEXT,
    detected_entity_name TEXT,
    detected_pattern_type TEXT,
    detected_seasonality_strength NUMERIC(3,2),
    detected_pattern_details JSONB,
    detected_confidence NUMERIC(3,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH incident_data AS (
        -- Daily patterns by service
        SELECT 
            'service' as entity_type,
            ee.service_name as entity_name,
            EXTRACT(HOUR FROM ci.detected_at) as hour_of_day,
            EXTRACT(DOW FROM ci.detected_at) as day_of_week,
            COUNT(*) as incident_count
        FROM iie.correlated_incidents ci
        JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
        JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        WHERE ci.detected_at >= NOW() - (p_lookback_days || ' days')::INTERVAL
          AND ee.service_name IS NOT NULL
        GROUP BY ee.service_name, EXTRACT(HOUR FROM ci.detected_at), EXTRACT(DOW FROM ci.detected_at)
    ),
    entity_totals AS (
        -- Calculate total incidents per entity for relative frequency
        SELECT 
            entity_name,
            SUM(incident_count) as total_incidents
        FROM incident_data
        GROUP BY entity_name
    ),
    pattern_analysis AS (
        SELECT 
            id.entity_type,
            id.entity_name,
            'daily' as pattern_type,
            -- Calculate seasonality strength (coefficient of variation across hours)
            (STDDEV(id.incident_count) / NULLIF(AVG(id.incident_count), 0))::NUMERIC(3,2) as seasonality_strength,
            jsonb_agg(
                jsonb_build_object(
                    'hour', id.hour_of_day,
                    'incident_count', id.incident_count,
                    'relative_frequency', ROUND(id.incident_count::NUMERIC / et.total_incidents, 3)
                )
            ) as pattern_details,
            -- Confidence based on data volume
            LEAST(1.0, et.total_incidents::NUMERIC / 1000) as confidence
        FROM incident_data id
        JOIN entity_totals et ON id.entity_name = et.entity_name
        GROUP BY id.entity_type, id.entity_name, et.total_incidents
        HAVING et.total_incidents >= 50  -- Minimum data threshold
    )
    SELECT 
        pa.entity_type as detected_entity_type,
        pa.entity_name as detected_entity_name,
        pa.pattern_type as detected_pattern_type,
        pa.seasonality_strength as detected_seasonality_strength,
        pa.pattern_details as detected_pattern_details,
        pa.confidence as detected_confidence
    FROM pattern_analysis pa
    WHERE pa.seasonality_strength > 0.3  -- Only report meaningful patterns
    ORDER BY pa.seasonality_strength DESC;
END;
$$ LANGUAGE plpgsql;

-- COMMENT ON FUNCTION iie.detect_seasonal_patterns IS 'Detects seasonal patterns in incident data for capacity planning and proactive monitoring.';

-- Function to project resource capacity gaps
CREATE OR REPLACE FUNCTION iie.project_capacity_gaps(
    p_forecast_days INTEGER DEFAULT 14
)
RETURNS TABLE (
    team_name TEXT,
    projection_date DATE,
    projected_incident_volume NUMERIC(8,2),
    available_capacity INTEGER,
    capacity_gap NUMERIC(8,2),
    risk_level TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH team_capacity AS (
        SELECT 
            rt.team_id,
            rt.team_name,
            rt.max_active_incidents as max_capacity,
            COUNT(tm.member_id) as team_size,
            COUNT(tm.member_id) FILTER (WHERE tm.availability_status = 'available') as available_members
        FROM iie.response_teams rt
        LEFT JOIN iie.team_members tm ON rt.team_id = tm.team_id
        WHERE rt.is_active = true
        GROUP BY rt.team_id, rt.team_name, rt.max_active_incidents
    ),
    incident_forecast AS (
        SELECT 
            ivf.forecast_date,
            -- For simplicity, assume incidents are distributed to teams based on historical patterns
            ROUND(ivf.projected_incidents * 0.3) as team_incidents  -- 30% of service incidents go to teams
        FROM iie.generate_incident_volume_forecast(p_forecast_days) ivf
        WHERE ivf.forecast_date <= CURRENT_DATE + p_forecast_days
    ),
    capacity_calculation AS (
        SELECT 
            tc.team_name,
            ifc.forecast_date as projection_date,
            ifc.team_incidents as projected_incident_volume,
            tc.max_capacity as available_capacity,
            (ifc.team_incidents - tc.max_capacity) as capacity_gap
        FROM team_capacity tc
        CROSS JOIN incident_forecast ifc
    )
    SELECT 
        cc.team_name,
        cc.projection_date,
        cc.projected_incident_volume,
        cc.available_capacity,
        cc.capacity_gap,
        CASE 
            WHEN cc.capacity_gap > (cc.available_capacity * 0.5) THEN 'critical'
            WHEN cc.capacity_gap > (cc.available_capacity * 0.2) THEN 'high'
            WHEN cc.capacity_gap > 0 THEN 'medium'
            ELSE 'low'
        END as risk_level
    FROM capacity_calculation cc
    ORDER BY cc.projection_date, cc.capacity_gap DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.project_capacity_gaps IS 'Projects capacity gaps for response teams based on incident volume forecasts.';

--drop the existing function fixing the errors
--  drop the dependent view
DROP VIEW IF EXISTS iie.vw_predictive_analytics_dashboard;

-- Then drop and recreate the function
DROP FUNCTION IF EXISTS iie.estimate_business_impact(TEXT, INTEGER);

-- Recreate the function with unique return column names
CREATE OR REPLACE FUNCTION iie.estimate_business_impact(
    p_service_name TEXT DEFAULT NULL,
    p_forecast_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    result_service_name TEXT,
    result_forecast_date DATE,
    result_projected_incidents INTEGER,
    result_estimated_cost_impact NUMERIC(12,2),
    result_estimated_user_impact INTEGER,
    result_risk_category TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH cost_data AS (
        SELECT 
            ee.service_name,
            AVG(ee.cost_per_minute) as avg_cost_per_minute,
            AVG(ee.user_impact_estimate) as avg_user_impact,
            AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) as avg_resolution_minutes
        FROM iie.enriched_events ee
        JOIN iie.incident_correlations ic ON ee.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        JOIN iie.correlated_incidents ci ON ic.incident_id = ci.incident_id
        WHERE ci.resolved_at IS NOT NULL
          AND ee.cost_per_minute > 0
          AND (p_service_name IS NULL OR ee.service_name = p_service_name)
        GROUP BY ee.service_name
    ),
    incident_forecast AS (
        SELECT 
            ivf.forecast_date,
            ivf.forecast_service_name as service_name,
            ROUND(ivf.projected_incidents)::INTEGER as projected_incidents
        FROM iie.generate_incident_volume_forecast(p_forecast_days) ivf
        WHERE (p_service_name IS NULL OR ivf.forecast_service_name = p_service_name)
    )
    SELECT 
        ifc.service_name as result_service_name,
        ifc.forecast_date as result_forecast_date,
        ifc.projected_incidents as result_projected_incidents,
        ROUND(
            ifc.projected_incidents * 
            COALESCE(cd.avg_cost_per_minute, 100) * 
            COALESCE(cd.avg_resolution_minutes, 30),
        2) as result_estimated_cost_impact,
        (ifc.projected_incidents * COALESCE(cd.avg_user_impact, 1000))::INTEGER as result_estimated_user_impact,
        CASE 
            WHEN (ifc.projected_incidents * COALESCE(cd.avg_cost_per_minute, 100) * COALESCE(cd.avg_resolution_minutes, 30)) > 10000 THEN 'high'
            WHEN (ifc.projected_incidents * COALESCE(cd.avg_cost_per_minute, 100) * COALESCE(cd.avg_resolution_minutes, 30)) > 5000 THEN 'medium'
            ELSE 'low'
        END as result_risk_category
    FROM incident_forecast ifc
    LEFT JOIN cost_data cd ON ifc.service_name = cd.service_name
    ORDER BY ifc.forecast_date, result_estimated_cost_impact DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.estimate_business_impact IS 'Estimates business impact of projected incidents including cost and user impact.';

-- Business Impact Forecasting
SELECT * FROM iie.estimate_business_impact(NULL, 30);

-- High-impact services
SELECT 
    result_service_name as service_name,
    result_forecast_date as forecast_date,
    result_projected_incidents as projected_incidents,
    result_estimated_cost_impact as estimated_cost_impact,
    result_estimated_user_impact as estimated_user_impact,
    result_risk_category as risk_category
FROM iie.estimate_business_impact(NULL, 14)
WHERE result_risk_category = 'high'
  AND result_forecast_date <= CURRENT_DATE + 7
ORDER BY result_estimated_cost_impact DESC;

-- Cumulative business impact
SELECT 
    result_service_name as service_name,
    SUM(result_projected_incidents) as total_projected_incidents,
    ROUND(SUM(result_estimated_cost_impact), 2) as total_cost_impact,
    SUM(result_estimated_user_impact) as total_user_impact,
    MAX(result_risk_category) as highest_risk
FROM iie.estimate_business_impact(NULL, 30)
GROUP BY result_service_name
HAVING SUM(result_estimated_cost_impact) > 1000
ORDER BY total_cost_impact DESC;

-- Finally, recreate the view with the updated function references
CREATE OR REPLACE VIEW iie.vw_predictive_analytics_dashboard AS
SELECT 
    'Capacity Forecast' as category,
    COUNT(DISTINCT team_name) as entity_count,
    SUM(CASE WHEN risk_level = 'critical' THEN 1 ELSE 0 END) as critical_items,
    MAX(projection_date) as latest_forecast_date
FROM iie.project_capacity_gaps(14)
WHERE projection_date = CURRENT_DATE + 1

UNION ALL

SELECT 
    'Seasonal Patterns' as category,
    COUNT(DISTINCT seasonal_patterns.entity_type) as entity_count,
    COUNT(*) FILTER (WHERE seasonality_strength > 0.7) as critical_items,
    MAX(detected_at) as latest_forecast_date
FROM iie.seasonal_patterns
WHERE valid_to IS NULL OR valid_to > NOW()

UNION ALL

SELECT 
    'Business Impact' as category,
    COUNT(DISTINCT result_service_name) as entity_count,
    COUNT(*) FILTER (WHERE result_risk_category = 'high') as critical_items,
    MAX(result_forecast_date) as latest_forecast_date
FROM iie.estimate_business_impact(NULL, 7)

UNION ALL

SELECT 
    'Anomalies' as category,
    COUNT(DISTINCT entity_id) as entity_count,
    COUNT(*) FILTER (WHERE severity IN ('high', 'critical')) as critical_items,
    MAX(detected_at) as latest_forecast_date
FROM iie.anomaly_detection_results
WHERE is_resolved = false;

COMMENT ON VIEW iie.vw_predictive_analytics_dashboard IS 'Provides overview of predictive analytics capabilities and current risk levels.';


-- Function to detect anomalies in operational metrics

DROP FUNCTION iie.detect_operational_anomalies;
-- Fixed detect_operational_anomalies function
-- Alternative version with proper moving averages
-- Fixed detect_operational_anomalies function with unambiguous column references
CREATE OR REPLACE FUNCTION iie.detect_operational_anomalies()
RETURNS TABLE (
    detected_entity_type TEXT,
    detected_entity_id UUID,
    detected_metric_name TEXT,
    detected_expected_value NUMERIC(12,4),
    detected_actual_value NUMERIC(12,4),
    detected_anomaly_score NUMERIC(5,4),
    detected_severity TEXT,
    detected_explanation TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH service_incidents AS (
        -- Get daily incident counts per service for the last 8 days
        SELECT 
            ee.service_name,
            DATE(ci.detected_at) as incident_date,
            COUNT(*) as daily_incidents
        FROM iie.correlated_incidents ci
        JOIN iie.incident_correlations ic ON ci.incident_id = ic.incident_id
        JOIN iie.enriched_events ee ON ic.event_id = ee.event_id AND ic.event_timestamp = ee.event_timestamp
        WHERE ci.detected_at >= NOW() - INTERVAL '8 days'
          AND ee.service_name IS NOT NULL
        GROUP BY ee.service_name, DATE(ci.detected_at)
    ),
    service_volume_anomalies AS (
        -- Incident volume anomalies using LAG for expected value
        SELECT 
            'service' as anomaly_entity_type,
            NULL::UUID as anomaly_entity_id,
            si.service_name as entity_identifier,
            'incident_volume' as anomaly_metric_name,
            si.daily_incidents as current_value,
            LAG(si.daily_incidents, 1) OVER (
                PARTITION BY si.service_name 
                ORDER BY si.incident_date
            ) as expected_value
        FROM service_incidents si
        WHERE si.incident_date = CURRENT_DATE  -- Today's data
    ),
    team_resolution_data AS (
        -- Get resolution times per team for the last 15 days
        SELECT 
            ira.assigned_team,
            rt.team_name,
            DATE(ci.resolved_at) as resolution_date,
            AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) as avg_resolution_minutes
        FROM iie.incident_response_actions ira
        JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
        JOIN iie.response_teams rt ON ira.assigned_team = rt.team_id
        WHERE ci.resolved_at >= NOW() - INTERVAL '15 days'
          AND ira.assigned_team IS NOT NULL
          AND ci.resolved_at IS NOT NULL
        GROUP BY ira.assigned_team, rt.team_name, DATE(ci.resolved_at)
    ),
    team_resolution_anomalies AS (
        -- Resolution time anomalies using LAG for expected value
        SELECT 
            'team' as anomaly_entity_type,
            trd.assigned_team as anomaly_entity_id,
            trd.team_name as entity_identifier,
            'resolution_time' as anomaly_metric_name,
            trd.avg_resolution_minutes as current_value,
            LAG(trd.avg_resolution_minutes, 1) OVER (
                PARTITION BY trd.assigned_team
                ORDER BY trd.resolution_date
            ) as expected_value
        FROM team_resolution_data trd
        WHERE trd.resolution_date = CURRENT_DATE  -- Today's data
    ),
    recent_metrics AS (
        SELECT * FROM service_volume_anomalies
        WHERE expected_value IS NOT NULL
        UNION ALL
        SELECT * FROM team_resolution_anomalies
        WHERE expected_value IS NOT NULL
    ),
    anomaly_scoring AS (
        SELECT 
            rm.anomaly_entity_type,
            rm.anomaly_entity_id,
            rm.anomaly_metric_name,
            rm.expected_value,
            rm.current_value as actual_value,
            -- Calculate anomaly score based on deviation from expected
            LEAST(1.0, GREATEST(0, 
                ABS(rm.current_value - COALESCE(rm.expected_value, rm.current_value)) / 
                NULLIF(GREATEST(rm.expected_value, rm.current_value, 1), 0)
            )) as anomaly_score
        FROM recent_metrics rm
        WHERE rm.expected_value IS NOT NULL
    )
    SELECT 
        ans.anomaly_entity_type,
        ans.anomaly_entity_id,
        ans.anomaly_metric_name,
        ans.expected_value,
        ans.actual_value,
        ans.anomaly_score,
        CASE 
            WHEN ans.anomaly_score > 0.7 THEN 'critical'
            WHEN ans.anomaly_score > 0.5 THEN 'high'
            WHEN ans.anomaly_score > 0.3 THEN 'medium'
            ELSE 'low'
        END,
        format('Unexpected %s detected: expected %.2f, got %.2f', 
               ans.anomaly_metric_name, ans.expected_value, ans.actual_value)
    FROM anomaly_scoring ans
    WHERE ans.anomaly_score > 0.3  -- Only report significant anomalies
    ORDER BY ans.anomaly_score DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION iie.detect_operational_anomalies IS 'Detects anomalies in operational metrics for early warning and proactive intervention.';

-- View: Predictive Analytics Dashboard (MUST BE CREATED AFTER ALL TABLES)
CREATE OR REPLACE VIEW iie.vw_predictive_analytics_dashboard AS
SELECT 
    'Capacity Forecast' as category,
    COUNT(DISTINCT team_name) as entity_count,
    SUM(CASE WHEN risk_level = 'critical' THEN 1 ELSE 0 END) as critical_items,
    MAX(projection_date) as latest_forecast_date
FROM iie.project_capacity_gaps(14)
WHERE projection_date = CURRENT_DATE + 1

UNION ALL

SELECT 
    'Seasonal Patterns' as category,
    COUNT(DISTINCT seasonal_patterns.entity_type) as entity_count,
    COUNT(*) FILTER (WHERE seasonality_strength > 0.7) as critical_items,
    MAX(detected_at) as latest_forecast_date
FROM iie.seasonal_patterns
WHERE valid_to IS NULL OR valid_to > NOW()

UNION ALL

SELECT 
    'Business Impact' as category,
    COUNT(DISTINCT service_name) as entity_count,
    COUNT(*) FILTER (WHERE risk_category = 'high') as critical_items,
    MAX(forecast_date) as latest_forecast_date
FROM iie.estimate_business_impact(NULL, 7)

UNION ALL

SELECT 
    'Anomalies' as category,
    COUNT(DISTINCT entity_id) as entity_count,
    COUNT(*) FILTER (WHERE severity IN ('high', 'critical')) as critical_items,
    MAX(detected_at) as latest_forecast_date
FROM iie.anomaly_detection_results
WHERE is_resolved = false;

COMMENT ON VIEW iie.vw_predictive_analytics_dashboard IS 'Provides overview of predictive analytics capabilities and current risk levels.';


-- Capacity Forecast models 
--model configuration and statuss 

-- Active forecast models with configuration
SELECT 
    model_name,
    forecast_type,
    target_entity,
    algorithm,
    forecast_horizon_days,
    retrain_frequency_days,
    is_active,
    last_trained_at,
    next_retrain_at,
    accuracy_metrics->>'mae' as mae,
    accuracy_metrics->>'rmse' as rmse,
    accuracy_metrics->>'mape' as mape_percentage
FROM iie.capacity_forecast_models
WHERE is_active = true
ORDER BY forecast_type, model_name;

-- Model performance comparison
SELECT 
    forecast_type,
    COUNT(*) as model_count,
    ROUND(AVG((accuracy_metrics->>'mae')::NUMERIC), 4) as avg_mae,
    ROUND(AVG((accuracy_metrics->>'rmse')::NUMERIC), 4) as avg_rmse,
    ROUND(AVG((accuracy_metrics->>'mape')::NUMERIC), 2) as avg_mape_pct,
    MAX(last_trained_at) as latest_training
FROM iie.capacity_forecast_models
WHERE accuracy_metrics IS NOT NULL
GROUP BY forecast_type
ORDER BY avg_mae;

-- Recent forecast results with actuals comparison
SELECT 
    cm.model_name,
    fr.forecast_date,
    fr.forecast_value,
    fr.actual_value,
    fr.forecast_error,
    ROUND(ABS(fr.forecast_error / NULLIF(fr.actual_value, 0)) * 100, 2) as error_percentage,
    fr.confidence_interval_lower,
    fr.confidence_interval_upper,
    CASE 
        WHEN fr.actual_value BETWEEN fr.confidence_interval_lower AND fr.confidence_interval_upper THEN 'within_ci'
        ELSE 'outside_ci'
    END as confidence_status
FROM iie.forecast_results fr
JOIN iie.capacity_forecast_models cm ON fr.forecast_model_id = cm.forecast_model_id
WHERE fr.forecast_date >= CURRENT_DATE - INTERVAL '30 days'
  AND fr.is_actual = false
  AND fr.actual_value IS NOT NULL
ORDER BY fr.forecast_date DESC, ABS(fr.forecast_error) DESC;

-- Forecast accuracy over time
SELECT 
    DATE(fr.created_at) as forecast_generation_date,
    cm.model_name,
    COUNT(*) as forecast_count,
    ROUND(AVG(ABS(fr.forecast_error)), 4) as mean_absolute_error,
    ROUND(AVG(ABS(fr.forecast_error / NULLIF(fr.actual_value, 0)) * 100), 2) as mean_absolute_percentage_error,
    ROUND(COUNT(*) FILTER (WHERE fr.actual_value BETWEEN fr.confidence_interval_lower AND fr.confidence_interval_upper)::NUMERIC / COUNT(*) * 100, 1) as confidence_interval_hit_rate
FROM iie.forecast_results fr
JOIN iie.capacity_forecast_models cm ON fr.forecast_model_id = cm.forecast_model_id
WHERE fr.is_actual = false
  AND fr.actual_value IS NOT NULL
  AND fr.created_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE(fr.created_at), cm.model_name
ORDER BY forecast_generation_date DESC, mean_absolute_error;


--Seasonal Patterns Analysis 
-- Strong seasonal patterns by entity
SELECT 
    entity_type,
    entity_id,
    pattern_type,
    ROUND(seasonality_strength, 3) as strength,
    ROUND(confidence, 3) as confidence,
    detected_at,
    valid_from,
    valid_to
FROM iie.seasonal_patterns
WHERE (valid_to IS NULL OR valid_to > NOW())
  AND seasonality_strength > 0.5
ORDER BY seasonality_strength DESC, confidence DESC;



-- Detect current seasonal patterns
SELECT * FROM iie.detect_seasonal_patterns(90);

-- High-confidence patterns only
SELECT 
    detected_entity_type as entity_type,
    detected_entity_name as entity_name,
    detected_pattern_type as pattern_type,
    ROUND(detected_seasonality_strength, 3) as strength,
    ROUND(detected_confidence, 3) as confidence_level
FROM iie.detect_seasonal_patterns(180)
WHERE detected_confidence > 0.7
  AND detected_seasonality_strength > 0.4
ORDER BY detected_seasonality_strength DESC;




--- incident volume forecasting 
-- Generate 30-day incident volume forecasts
SELECT * FROM iie.generate_incident_volume_forecast(30);

-- High-risk service forecasts (FIXED)
SELECT 
    forecast_date,
    forecast_service_name as service_name,
    projected_incidents,
    confidence_lower,
    confidence_upper,
    trend_direction
FROM iie.generate_incident_volume_forecast(14)
WHERE projected_incidents > 10
  AND trend_direction = 'increasing'
ORDER BY forecast_date, projected_incidents DESC;

-- Forecast confidence analysis
SELECT 
    forecast_service_name as service_name,
    COUNT(*) as forecast_days,
    ROUND(AVG(projected_incidents), 2) as avg_projected,
    ROUND(AVG(confidence_upper - confidence_lower), 2) as avg_confidence_range,
    MIN(confidence_lower) as min_confidence,
    MAX(confidence_upper) as max_confidence
FROM iie.generate_incident_volume_forecast(30)
GROUP BY service_name
HAVING AVG(projected_incidents) > 5
ORDER BY avg_confidence_range DESC;



---Capacity planning and gap analysis 
--capacity gap projections 

-- Project capacity gaps for next 14 days
SELECT * FROM iie.project_capacity_gaps(14);

-- Critical capacity gaps requiring immediate attention
SELECT 
    team_name,
    projection_date,
    projected_incident_volume,
    available_capacity,
    capacity_gap,
    risk_level
FROM iie.project_capacity_gaps(14)
WHERE risk_level IN ('critical', 'high')
  AND projection_date <= CURRENT_DATE + 7
ORDER BY projection_date, capacity_gap DESC;

-- Team capacity utilization trends
SELECT 
    team_name,
    COUNT(*) as projection_days,
    ROUND(AVG(projected_incident_volume), 2) as avg_projected_volume,
    AVG(available_capacity) as avg_available_capacity,
    ROUND(AVG(projected_incident_volume / NULLIF(available_capacity, 0)) * 100, 1) as avg_utilization_pct,
    COUNT(*) FILTER (WHERE risk_level = 'critical') as critical_days,
    COUNT(*) FILTER (WHERE risk_level = 'high') as high_risk_days
FROM iie.project_capacity_gaps(30)
GROUP BY team_name
ORDER BY avg_utilization_pct DESC;


--Resource Capacity Projections Table 
-- Stored capacity projections
SELECT 
    rt.team_name,
    rcp.projection_date,
    rcp.projected_incident_volume,
    rcp.available_capacity,
    rcp.capacity_gap,
    rcp.required_additional_capacity,
    ROUND(rcp.confidence_level, 3) as confidence,
    rcp.created_at
FROM iie.resource_capacity_projections rcp
JOIN iie.response_teams rt ON rcp.team_id = rt.team_id
WHERE rcp.projection_date >= CURRENT_DATE
ORDER BY rcp.projection_date, rcp.capacity_gap DESC;

-- Projection accuracy analysis
SELECT 
    rt.team_name,
    COUNT(*) as total_projections,
    ROUND(AVG(ABS(rcp.projected_incident_volume - 
        (SELECT COUNT(*) FROM iie.incident_response_actions ira 
         WHERE ira.assigned_team = rcp.team_id 
         AND DATE(ira.created_at) = rcp.projection_date))), 2) as avg_absolute_error,
    ROUND(AVG(rcp.confidence_level), 3) as avg_confidence
FROM iie.resource_capacity_projections rcp
JOIN iie.response_teams rt ON rcp.team_id = rt.team_id
WHERE rcp.projection_date < CURRENT_DATE
GROUP BY rt.team_name
ORDER BY avg_absolute_error;





-- Anomaly detection results from table
SELECT 
    entity_type,
    metric_name,
    COUNT(*) as anomaly_count,
    ROUND(AVG(anomaly_score), 3) as avg_anomaly_score,
    COUNT(*) FILTER (WHERE severity = 'critical') as critical_count,
    COUNT(*) FILTER (WHERE severity = 'high') as high_count,
    COUNT(*) FILTER (WHERE is_resolved = true) as resolved_count
FROM iie.anomaly_detection_results
WHERE detected_at >= NOW() - INTERVAL '30 days'
GROUP BY entity_type, metric_name
ORDER BY anomaly_count DESC;


--Anomaly Trends and Resolution 
-- Unresolved anomalies
SELECT 
    entity_type,
    metric_name,
    severity,
    actual_value,
    expected_value,
    detected_at,
    explanation
FROM iie.anomaly_detection_results
WHERE is_resolved = false
ORDER BY detected_at DESC, severity DESC;

-- Anomaly resolution performance
SELECT 
    DATE(detected_at) as detection_date,
    entity_type,
    COUNT(*) as total_anomalies,
    COUNT(*) FILTER (WHERE is_resolved = true) as resolved_anomalies,
    ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/3600) FILTER (WHERE is_resolved = true), 1) as avg_resolution_hours,
    ROUND(COUNT(*) FILTER (WHERE is_resolved = true)::NUMERIC / COUNT(*) * 100, 1) as resolution_rate
FROM iie.anomaly_detection_results
WHERE detected_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE(detected_at), entity_type
ORDER BY detection_date DESC, resolution_rate;


--Predictive Analytics Dashboards
--comprehensive dashboard views

-- Predictive analytics dashboard overview
SELECT * FROM iie.vw_predictive_analytics_dashboard;

--Forecasting Performance Metrics 
-- Overall forecasting performance
SELECT 
    cm.forecast_type,
    COUNT(DISTINCT fr.forecast_model_id) as active_models,
    COUNT(fr.forecast_id) as total_forecasts,
    COUNT(fr.forecast_id) FILTER (WHERE fr.actual_value IS NOT NULL) as forecasts_with_actuals,
    ROUND(AVG(ABS(fr.forecast_error)) FILTER (WHERE fr.actual_value IS NOT NULL), 4) as mean_absolute_error,
    ROUND(AVG(ABS(fr.forecast_error / NULLIF(fr.actual_value, 0)) * 100) FILTER (WHERE fr.actual_value IS NOT NULL), 2) as mean_absolute_percentage_error,
    ROUND(COUNT(fr.forecast_id) FILTER (WHERE fr.actual_value BETWEEN fr.confidence_interval_lower AND fr.confidence_interval_upper)::NUMERIC / 
          COUNT(fr.forecast_id) FILTER (WHERE fr.actual_value IS NOT NULL) * 100, 1) as confidence_interval_accuracy
FROM iie.forecast_results fr
JOIN iie.capacity_forecast_models cm ON fr.forecast_model_id = cm.forecast_model_id
WHERE fr.created_at >= NOW() - INTERVAL '90 days'
GROUP BY cm.forecast_type
ORDER BY mean_absolute_error;

--Advanced Analytical Queries 
-- Model algorithm performance comparison
SELECT 
    algorithm,
    forecast_type,
    COUNT(*) as model_count,
    ROUND(AVG((accuracy_metrics->>'mae')::NUMERIC), 4) as avg_mae,
    ROUND(AVG((accuracy_metrics->>'rmse')::NUMERIC), 4) as avg_rmse,
    ROUND(AVG((accuracy_metrics->>'mape')::NUMERIC), 2) as avg_mape_pct
FROM iie.capacity_forecast_models
WHERE accuracy_metrics IS NOT NULL
  AND last_trained_at >= NOW() - INTERVAL '180 days'
GROUP BY algorithm, forecast_type
ORDER BY forecast_type, avg_mae;

-- Seasonal pattern effectiveness
SELECT 
    sp.entity_type,
    sp.pattern_type,
    COUNT(*) as pattern_count,
    ROUND(AVG(sp.seasonality_strength), 3) as avg_strength,
    ROUND(AVG(sp.confidence), 3) as avg_confidence,
    MIN(sp.detected_at) as first_detected,
    MAX(sp.detected_at) as last_detected
FROM iie.seasonal_patterns sp
WHERE sp.valid_to IS NULL OR sp.valid_to > NOW()
GROUP BY sp.entity_type, sp.pattern_type
ORDER BY avg_strength DESC;

---Risk Forecasting and Alerting 
-- Combined risk forecast for executive reporting
-- Combined risk forecast with corrected column names matching detect_operational_anomalies()
WITH capacity_risks AS (
    SELECT 
        'capacity_gap' as risk_type,
        team_name as entity,
        projection_date as risk_date,
        risk_level,
        capacity_gap as impact_metric,
        'team_capacity' as details
    FROM iie.project_capacity_gaps(14)
    WHERE risk_level IN ('critical', 'high')
),
business_risks AS (
    SELECT 
        'business_impact' as risk_type,
        result_service_name as entity,
        result_forecast_date as risk_date,
        result_risk_category as risk_level,
        result_estimated_cost_impact as impact_metric,
        'cost_impact' as details
    FROM iie.estimate_business_impact(NULL, 14)
    WHERE result_risk_category IN ('high')
),
anomaly_risks AS (
    SELECT 
        'anomaly' as risk_type,
        detected_entity_type || ':' || COALESCE(detected_entity_id::TEXT, 'global') as entity,
        CURRENT_DATE as risk_date,
        detected_severity as risk_level,
        (detected_anomaly_score * 100)::NUMERIC as impact_metric,
        detected_metric_name as details
    FROM iie.detect_operational_anomalies()
    WHERE detected_severity IN ('critical', 'high')
),
combined_risks AS (
    SELECT 
        risk_type,
        entity,
        risk_date,
        risk_level,
        ROUND(impact_metric::NUMERIC, 2) as impact_metric,
        details
    FROM capacity_risks
    UNION ALL 
    SELECT 
        risk_type,
        entity,
        risk_date,
        risk_level,
        ROUND(impact_metric::NUMERIC, 2) as impact_metric,
        details
    FROM business_risks
    UNION ALL 
    SELECT 
        risk_type,
        entity,
        risk_date,
        risk_level,
        ROUND(impact_metric::NUMERIC, 2) as impact_metric,
        details
    FROM anomaly_risks
)
SELECT 
    risk_type,
    entity,
    risk_date,
    risk_level,
    impact_metric,
    details,
    -- Add a normalized risk score for sorting (0-100 scale)
    CASE 
        WHEN risk_level = 'critical' THEN 100
        WHEN risk_level = 'high' THEN 75
        WHEN risk_level = 'medium' THEN 50
        ELSE 25
    END as risk_score
FROM combined_risks
ORDER BY 
    risk_score DESC,
    risk_date ASC,
    impact_metric DESC;
	
	-----Anomaly Detection (operational Anomalies)
-- Detect current operational anomalies
SELECT * FROM iie.detect_operational_anomalies();

-- -- Critical anomalies requiring immediate attention
SELECT 
    detected_entity_type as entity_type,
    detected_metric_name as metric_name,
    detected_expected_value as expected_value,
    detected_actual_value as actual_value,
    ROUND(detected_anomaly_score, 3) as score,
    detected_severity as severity,
    detected_explanation as explanation
FROM iie.detect_operational_anomalies()
WHERE detected_severity IN ('critical', 'high')
ORDER BY detected_anomaly_score DESC;


-- Key performance indicators to monitor
SELECT 
    'Event Processing Lag' as metric,
    AVG(EXTRACT(EPOCH FROM (received_at - event_timestamp))) as avg_seconds
FROM iie.raw_events 
WHERE received_at >= NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
    'Incident MTTD' as metric,
    AVG(EXTRACT(EPOCH FROM mtt_detection)/60) as avg_minutes
FROM iie.correlated_incidents 
WHERE detected_at >= NOW() - INTERVAL '24 hours';

-- Automated archiving procedures
SELECT iie.archive_old_raw_events(12);  -- Keep 12 months
SELECT iie.archive_old_model_metrics(24); -- Keep 24 months

-- Add materialized views for expensive aggregations
CREATE MATERIALIZED VIEW iie.mv_daily_incident_metrics AS
SELECT DATE(detected_at) as date,
       COUNT(*) as incident_count,
       AVG(EXTRACT(EPOCH FROM mtt_resolution)/60) as avg_mttr_minutes
FROM iie.correlated_incidents
GROUP BY DATE(detected_at);


-- Cost and user impact estimation
SELECT * FROM iie.estimate_business_impact('service-name', 30);

-- Seasonal pattern detection
SELECT * FROM iie.detect_seasonal_patterns(180);

-- Skill-based routing --input incident id 
SELECT * FROM iie.find_optimal_team('incident-uuid', ARRAY['kubernetes', 'docker']);

-- Capacity gap projection  
SELECT * FROM iie.project_capacity_gaps(14);

-- Fatigue monitoring
SELECT * FROM iie.calculate_team_fatigue();

----------------------------------------------------------------------

-- Advanced Executive Dashboard - Comprehensive Risk & Performance Overview
CREATE OR REPLACE VIEW iie.vw_executive_dashboard AS
WITH 
-- 1. CURRENT OPERATIONAL STATUS
operational_status AS (
    SELECT 
        'active_incidents' as metric_category,
        COUNT(*) as metric_value,
        'Active Incidents' as metric_name,
        CASE 
            WHEN COUNT(*) = 0 THEN 'success'
            WHEN COUNT(*) <= 5 THEN 'warning' 
            ELSE 'critical'
        END as status
    FROM iie.correlated_incidents 
    WHERE status = 'active'
    
    UNION ALL
    
    SELECT 
        'avg_mttr' as metric_category,
        ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/60)::NUMERIC, 1) as metric_value,
        'Avg MTTR (minutes)' as metric_name,
        CASE 
            WHEN AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/60) <= 30 THEN 'success'
            WHEN AVG(EXTRACT(EPOCH FROM (resolved_at - detected_at))/60) <= 60 THEN 'warning'
            ELSE 'critical'
        END as status
    FROM iie.correlated_incidents 
    WHERE status = 'resolved' 
      AND resolved_at >= NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    SELECT 
        'team_capacity_utilization' as metric_category,
        ROUND(
            (SELECT COUNT(*) FROM iie.incident_response_actions WHERE status IN ('pending', 'in_progress'))::NUMERIC / 
            NULLIF((SELECT SUM(max_active_incidents) FROM iie.response_teams WHERE is_active = true), 0) * 100,
        1) as metric_value,
        'Team Capacity Used %' as metric_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM iie.incident_response_actions WHERE status IN ('pending', 'in_progress'))::NUMERIC / 
                 NULLIF((SELECT SUM(max_active_incidents) FROM iie.response_teams WHERE is_active = true), 0) * 100 <= 60 THEN 'success'
            WHEN (SELECT COUNT(*) FROM iie.incident_response_actions WHERE status IN ('pending', 'in_progress'))::NUMERIC / 
                 NULLIF((SELECT SUM(max_active_incidents) FROM iie.response_teams WHERE is_active = true), 0) * 100 <= 85 THEN 'warning'
            ELSE 'critical'
        END as status
),

-- 2. RISK OVERVIEW
risk_overview AS (
    WITH risk_data AS (
        -- Capacity Risks
        SELECT 
            'capacity_gap' as risk_type,
            team_name as entity,
            projection_date as risk_date,
            risk_level,
            capacity_gap as impact_metric,
            'team_capacity' as details
        FROM iie.project_capacity_gaps(7)
        WHERE risk_level IN ('critical', 'high')
        
        UNION ALL
        
        -- Business Risks
        SELECT 
            'business_impact' as risk_type,
            result_service_name as entity,
            result_forecast_date as risk_date,
            result_risk_category as risk_level,
            result_estimated_cost_impact as impact_metric,
            'cost_impact' as details
        FROM iie.estimate_business_impact(NULL, 7)
        WHERE result_risk_category IN ('high')
        
        UNION ALL
        
        -- Anomaly Risks
        SELECT 
            'anomaly' as risk_type,
            detected_entity_type || ':' || COALESCE(detected_entity_id::TEXT, 'global') as entity,
            CURRENT_DATE as risk_date,
            detected_severity as risk_level,
            (detected_anomaly_score * 100)::NUMERIC as impact_metric,
            detected_metric_name as details
        FROM iie.detect_operational_anomalies()
        WHERE detected_severity IN ('critical', 'high')
    )
    SELECT 
        risk_type,
        COUNT(*) as risk_count,
        COUNT(*) FILTER (WHERE risk_level = 'critical') as critical_count,
        COUNT(*) FILTER (WHERE risk_level = 'high') as high_count,
        ROUND(AVG(
            CASE 
                WHEN risk_level = 'critical' THEN 100
                WHEN risk_level = 'high' THEN 75
                WHEN risk_level = 'medium' THEN 50
                ELSE 25
            END
        ), 1) as avg_risk_score
    FROM risk_data
    WHERE risk_date <= CURRENT_DATE + 3
    GROUP BY risk_type
),

-- 3. SERVICE HEALTH SCORING
service_health AS (
    SELECT 
        ee.service_name,
        COUNT(DISTINCT ci.incident_id) as incident_count_7d,
        COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') as critical_incidents_7d,
        ROUND(AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) FILTER (WHERE ci.resolved_at IS NOT NULL), 1) as avg_resolution_minutes,
        ROUND(AVG(ee.cost_per_minute), 2) as avg_cost_per_minute,
        CASE 
            WHEN COUNT(DISTINCT ci.incident_id) = 0 THEN 100
            ELSE GREATEST(0, 100 - 
                (COUNT(DISTINCT ci.incident_id) * 2 + 
                 COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') * 10))
        END as health_score
    FROM iie.enriched_events ee
    JOIN iie.incident_correlations ic ON ee.event_id = ic.event_id AND ee.event_timestamp = ic.event_timestamp
    JOIN iie.correlated_incidents ci ON ic.incident_id = ci.incident_id
    WHERE ci.detected_at >= NOW() - INTERVAL '7 days'
      AND ee.service_name IS NOT NULL
    GROUP BY ee.service_name
    HAVING COUNT(DISTINCT ci.incident_id) > 0
),

-- 4. TEAM PERFORMANCE
team_performance AS (
    SELECT 
        rt.team_name,
        COUNT(DISTINCT ira.incident_id) as incidents_handled_7d,
        ROUND(AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) FILTER (WHERE ci.resolved_at IS NOT NULL), 1) as avg_resolution_minutes,
        ROUND(AVG(ira.effectiveness_score) FILTER (WHERE ira.effectiveness_score IS NOT NULL), 2) as avg_effectiveness,
        COUNT(DISTINCT ih.handoff_id) FILTER (WHERE ih.handoff_type = 'escalation') as escalations_received
    FROM iie.response_teams rt
    LEFT JOIN iie.incident_response_actions ira ON rt.team_id = ira.assigned_team
    LEFT JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
    LEFT JOIN iie.incident_handoffs ih ON rt.team_id = ih.to_team_id
    WHERE ira.created_at >= NOW() - INTERVAL '7 days'
      AND rt.is_active = true
    GROUP BY rt.team_id, rt.team_name
),

-- 5. COST IMPACT ANALYSIS
cost_impact AS (
    SELECT 
        result_service_name as service_name,
        SUM(result_estimated_cost_impact) as total_projected_cost_7d,
        SUM(result_projected_incidents) as total_projected_incidents_7d,
        MAX(result_risk_category) as highest_risk
    FROM iie.estimate_business_impact(NULL, 7)
    WHERE result_forecast_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7
    GROUP BY result_service_name
    HAVING SUM(result_estimated_cost_impact) > 0
),

-- 6. ANOMALY SUMMARY
anomaly_summary AS (
    SELECT 
        detected_entity_type as entity_type,
        COUNT(*) as anomaly_count,
        ROUND(AVG(detected_anomaly_score), 3) as avg_anomaly_score,
        COUNT(*) FILTER (WHERE detected_severity = 'critical') as critical_anomalies,
        COUNT(*) FILTER (WHERE detected_severity = 'high') as high_anomalies
    FROM iie.detect_operational_anomalies()
    WHERE detected_anomaly_score > 0.3
    GROUP BY detected_entity_type
)

-- MAIN DASHBOARD QUERY
SELECT 
    -- Operational Status Summary
    (SELECT metric_value FROM operational_status WHERE metric_category = 'active_incidents') as active_incidents_count,
    (SELECT metric_value FROM operational_status WHERE metric_category = 'avg_mttr') as average_mttr_minutes,
    (SELECT metric_value FROM operational_status WHERE metric_category = 'team_capacity_utilization') as capacity_utilization_percent,
    
    -- Risk Summary
    (SELECT SUM(risk_count) FROM risk_overview) as total_risks,
    (SELECT SUM(critical_count) FROM risk_overview) as critical_risks,
    (SELECT SUM(high_count) FROM risk_overview) as high_risks,
    (SELECT ROUND(AVG(avg_risk_score), 1) FROM risk_overview) as overall_risk_score,
    
    -- Service Health Summary
    (SELECT COUNT(*) FROM service_health WHERE health_score >= 80) as healthy_services,
    (SELECT COUNT(*) FROM service_health WHERE health_score BETWEEN 60 AND 79) as warning_services,
    (SELECT COUNT(*) FROM service_health WHERE health_score < 60) as critical_services,
    (SELECT ROUND(AVG(health_score), 1) FROM service_health) as avg_service_health_score,
    
    -- Cost Impact Summary
    (SELECT COUNT(*) FROM cost_impact) as services_with_cost_risk,
    (SELECT ROUND(SUM(total_projected_cost_7d), 2) FROM cost_impact) as total_projected_cost_impact,
    
    -- Anomaly Summary
    (SELECT SUM(anomaly_count) FROM anomaly_summary) as total_anomalies,
    (SELECT SUM(critical_anomalies) FROM anomaly_summary) as critical_anomalies_count,
    (SELECT SUM(high_anomalies) FROM anomaly_summary) as high_anomalies_count,
    
    -- Timestamp
    NOW() as dashboard_last_updated;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----RISK DETAILS VIEW 
CREATE OR REPLACE VIEW iie.vw_executive_risk_details AS
SELECT 
    risk_type,
    entity,
    risk_date,
    risk_level,
    impact_metric,
    details,
    CASE 
        WHEN risk_level = 'critical' THEN 100
        WHEN risk_level = 'high' THEN 75
        WHEN risk_level = 'medium' THEN 50
        ELSE 25
    END as risk_score,
    CASE 
        WHEN risk_date = CURRENT_DATE THEN 'today'
        WHEN risk_date = CURRENT_DATE + 1 THEN 'tomorrow'
        WHEN risk_date <= CURRENT_DATE + 3 THEN 'this_week'
        ELSE 'future'
    END as time_horizon
FROM (
    -- Capacity Risks
    SELECT 
        'capacity_gap' as risk_type,
        team_name as entity,
        projection_date as risk_date,
        risk_level,
        capacity_gap as impact_metric,
        'Team: ' || team_name as details
    FROM iie.project_capacity_gaps(7)
    WHERE risk_level IN ('critical', 'high')
    
    UNION ALL
    
    -- Business Risks
    SELECT 
        'business_impact' as risk_type,
        result_service_name as entity,
        result_forecast_date as risk_date,
        result_risk_category as risk_level,
        result_estimated_cost_impact as impact_metric,
        'Service: ' || result_service_name as details
    FROM iie.estimate_business_impact(NULL, 7)
    WHERE result_risk_category IN ('high')
    
    UNION ALL
    
    -- Anomaly Risks
    SELECT 
        'anomaly' as risk_type,
        detected_entity_type || ':' || COALESCE(detected_entity_id::TEXT, 'global') as entity,
        CURRENT_DATE as risk_date,
        detected_severity as risk_level,
        (detected_anomaly_score * 100)::NUMERIC as impact_metric,
        'Metric: ' || detected_metric_name as details
    FROM iie.detect_operational_anomalies()
    WHERE detected_severity IN ('critical', 'high')
) all_risks
ORDER BY risk_score DESC, risk_date ASC;

-------------------------------------------------------------------------------------------------------------------------------
---SERVICE HEALTH DETAILS VIEW 
CREATE OR REPLACE VIEW iie.vw_executive_service_health AS
WITH service_health_data AS (
    SELECT 
        ee.service_name,
        COUNT(DISTINCT ci.incident_id) as incident_count_7d,
        COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') as critical_incidents_7d,
        ROUND(AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) FILTER (WHERE ci.resolved_at IS NOT NULL), 1) as avg_resolution_minutes,
        ROUND(AVG(ee.cost_per_minute), 2) as avg_cost_per_minute,
        CASE 
            WHEN COUNT(DISTINCT ci.incident_id) = 0 THEN 100
            ELSE GREATEST(0, 100 - 
                (COUNT(DISTINCT ci.incident_id) * 2 + 
                 COUNT(DISTINCT ci.incident_id) FILTER (WHERE ci.severity = 'critical') * 10))
        END as health_score
    FROM iie.enriched_events ee
    JOIN iie.incident_correlations ic ON ee.event_id = ic.event_id AND ee.event_timestamp = ic.event_timestamp
    JOIN iie.correlated_incidents ci ON ic.incident_id = ci.incident_id
    WHERE ci.detected_at >= NOW() - INTERVAL '7 days'
      AND ee.service_name IS NOT NULL
    GROUP BY ee.service_name
    HAVING COUNT(DISTINCT ci.incident_id) > 0
),
cost_impact_data AS (
    SELECT 
        result_service_name as service_name,
        SUM(result_estimated_cost_impact) as total_projected_cost_7d,
        MAX(result_risk_category) as highest_risk
    FROM iie.estimate_business_impact(NULL, 7)
    WHERE result_forecast_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7
    GROUP BY result_service_name
    HAVING SUM(result_estimated_cost_impact) > 0
)
SELECT 
    sh.service_name,
    sh.incident_count_7d,
    sh.critical_incidents_7d,
    sh.avg_resolution_minutes,
    sh.avg_cost_per_minute,
    sh.health_score,
    COALESCE(ci.total_projected_cost_7d, 0) as total_projected_cost_7d,
    COALESCE(ci.highest_risk, 'low') as cost_risk_level,
    CASE 
        WHEN sh.health_score >= 80 THEN 'healthy'
        WHEN sh.health_score >= 60 THEN 'degraded'
        ELSE 'critical'
    END as health_status
FROM service_health_data sh
LEFT JOIN cost_impact_data ci ON sh.service_name = ci.service_name
ORDER BY sh.health_score ASC, ci.total_projected_cost_7d DESC NULLS LAST;
	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--TEAM PERFORMANCE DETAILS VIEWS 
CREATE OR REPLACE VIEW iie.vw_executive_team_performance AS
WITH team_performance_data AS (
    SELECT 
        rt.team_name,
        COUNT(DISTINCT ira.incident_id) as incidents_handled_7d,
        ROUND(AVG(EXTRACT(EPOCH FROM (ci.resolved_at - ci.detected_at))/60) FILTER (WHERE ci.resolved_at IS NOT NULL), 1) as avg_resolution_minutes,
        ROUND(AVG(ira.effectiveness_score) FILTER (WHERE ira.effectiveness_score IS NOT NULL), 2) as avg_effectiveness,
        COUNT(DISTINCT ih.handoff_id) FILTER (WHERE ih.handoff_type = 'escalation') as escalations_received
    FROM iie.response_teams rt
    LEFT JOIN iie.incident_response_actions ira ON rt.team_id = ira.assigned_team
    LEFT JOIN iie.correlated_incidents ci ON ira.incident_id = ci.incident_id
    LEFT JOIN iie.incident_handoffs ih ON rt.team_id = ih.to_team_id
    WHERE ira.created_at >= NOW() - INTERVAL '7 days'
      AND rt.is_active = true
    GROUP BY rt.team_id, rt.team_name
),
team_fatigue_data AS (
    SELECT 
        team_name,
        fatigue_score,
        burnout_risk
    FROM iie.calculate_team_fatigue()
)
SELECT 
    tp.team_name,
    tp.incidents_handled_7d,
    tp.avg_resolution_minutes,
    tp.avg_effectiveness,
    tp.escalations_received,
    COALESCE(tf.fatigue_score, 0) as fatigue_score,
    COALESCE(tf.burnout_risk, 'low') as burnout_risk,
    CASE 
        WHEN tp.avg_effectiveness >= 0.8 THEN 'high'
        WHEN tp.avg_effectiveness >= 0.6 THEN 'medium'
        ELSE 'low'
    END as performance_tier
FROM team_performance_data tp
LEFT JOIN team_fatigue_data tf ON tp.team_name = tf.team_name
ORDER BY tp.avg_effectiveness DESC NULLS LAST;
	
-------
--complete dashboard
SELECT * FROM iie.vw_executive_dashboard;
-- select top risks 
SELECT * FROM iie.vw_executive_risk_details 
WHERE risk_score >= 75 
ORDER BY risk_score DESC, risk_date 
LIMIT 10;

-- get service health 
SELECT * FROM iie.vw_executive_service_health 
WHERE health_status != 'healthy' 
ORDER BY health_score ASC 
LIMIT 15;


--- get team performance 
SELECT * FROM iie.vw_executive_team_performance 
ORDER BY performance_tier, avg_effectiveness DESC;

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--todo Awase: advanced features to consider and explore 
--- dependency graph traversals -- neo4j
--- investigate strategies for measuring real-time impact analysis 
--- real-time correlation engine  
-- Integration with Apache Kafka for event streaming 
-- NLP for automated ticket analysis 
-- reinforcement learning for routing optimization

---end of module 1----------------------------------------
