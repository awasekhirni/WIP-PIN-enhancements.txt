-- © Copyright 2025 β ORI Inc. Canada. All Rights Reserved. Awase Khirni Syed 
--partial schema for toxicity score module -- immutable feedback


-- Enable critical extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For encryption
CREATE EXTENSION IF NOT EXISTS "hstore"; -- For dynamic key-value storage

-- ====== CORE TABLES (Immutable Base) ======
CREATE TABLE companies (
    company_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    domain TEXT UNIQUE, -- For email verification
    crunchbase_id TEXT, -- For funding/turnover data
    linkedin_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_company UNIQUE (legal_name, domain)
);

-- Zero-Knowledge Proof Compatible User System
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    anonymous_id TEXT GENERATED ALWAYS AS (
        'anon_' || encode(hmac(user_id::text, 'secret_salt', 'sha256'), 'hex')
    ) STORED UNIQUE,
    zkp_public_key TEXT, -- For ZKP auth
    toxicity_preferences JSONB NOT NULL DEFAULT '{
        "wlb_tolerance": 5,
        "micromanagement_tolerance": 3,
        "allow_contact": false
    }',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== BLOCKCHAIN-INTEGRATED FEEDBACK ======
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(company_id),
    user_id UUID REFERENCES users(user_id),
    source TEXT NOT NULL CHECK (source IN ('user', 'glassdoor', 'indeed', 'api')),

    -- Content
    original_text TEXT NOT NULL,
    encrypted_text BYTEA, -- For sensitive reports (PGP)
    sentiment_score FLOAT,
    sarcasm_score FLOAT, -- AI-detected sarcasm (0-1)
    tone TEXT CHECK (tone IN ('positive', 'negative', 'neutral', 'mixed')),

    -- Blockchain
    blockchain_tx_hash TEXT, -- Ethereum/Polygon transaction ID
    blockchain_block_number INTEGER,
    text_hash TEXT NOT NULL, -- sha256 hash of original_text

    -- Moderation
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method TEXT CHECK (verification_method IN ('email', 'zkp', 'manual')),
    is_deleted BOOLEAN DEFAULT FALSE,

    -- Metadata
    original_metadata JSONB NOT NULL, -- IP, user-agent, etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== AI ANALYSIS TABLES ======
CREATE TABLE toxicity_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version TEXT NOT NULL,
    description TEXT,
    bias_audit_results JSONB,
    deployed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE toxicity_scores (
    score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(company_id),
    model_id UUID REFERENCES toxicity_models(model_id),
    score FLOAT NOT NULL CHECK (score BETWEEN 0 AND 100),
    confidence FLOAT,
    components JSONB NOT NULL DEFAULT '{}', -- Breakdown by category
    time_weight FLOAT NOT NULL DEFAULT 1.0, -- Recent reviews weighted higher
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== REAL-TIME INTERVIEW TOOLS ======
CREATE TABLE interview_redflags (
    flag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phrase TEXT NOT NULL, -- E.g., "We're like a family"
    category TEXT NOT NULL, -- E.g., "guilt-tripping"
    severity INT CHECK (severity BETWEEN 1 AND 5),
    ai_confidence FLOAT
);

-- ====== LEGAL SAFEGUARDS ======
CREATE TABLE dmca_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(company_id),
    review_id UUID REFERENCES reviews(review_id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'rejected', 'approved')),
    counter_notice_text TEXT,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== VIRAL ACCOUNTABILITY ======
CREATE TABLE public_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(company_id),
    trigger_reason TEXT NOT NULL, -- E.g., "score_drop_20pct"
    social_media_posted BOOLEAN DEFAULT FALSE,
    posted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== AUDIT TRAILS ======
CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action TEXT NOT NULL, -- E.g., 'review_edit_attempt'
    target_type TEXT NOT NULL,
    target_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    blockchain_tx_hash TEXT, -- For immutable logging
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====== ENCRYPTION VIEWS ======
CREATE VIEW encrypted_reviews AS
SELECT
    review_id,
    company_id,
    pgp_sym_decrypt(encrypted_text, 'encryption_key') AS decrypted_text,
    text_hash
FROM reviews
WHERE encrypted_text IS NOT NULL;

-- ====== INDEXES ======
-- Performance
CREATE INDEX idx_reviews_sentiment ON reviews(sentiment_score, sarcasm_score);
CREATE INDEX idx_companies_domain ON companies(domain);
CREATE INDEX idx_toxicity_time ON toxicity_scores(calculated_at DESC);

-- Blockchain verification
CREATE INDEX idx_reviews_blockchain ON reviews(blockchain_tx_hash)
WHERE blockchain_tx_hash IS NOT NULL;

-- Text search
CREATE INDEX idx_reviews_text_search ON reviews USING GIN (original_text gin_trgm_ops);


--critical security functions
-- Auto-hash new reviews for blockchain
CREATE OR REPLACE FUNCTION hash_review()
RETURNS TRIGGER AS $$
BEGIN
    NEW.text_hash := encode(hmac(NEW.original_text, 'secret_salt', 'sha256'), 'hex');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hash_review
BEFORE INSERT ON reviews
FOR EACH ROW EXECUTE FUNCTION hash_review();

-- Immutable audit logging
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (
        action, target_type, target_id, old_data, new_data
    ) VALUES (
        TG_OP, TG_TABLE_NAME,
        COALESCE(OLD.review_id, OLD.company_id, OLD.user_id),
        to_jsonb(OLD), to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_reviews
AFTER UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION log_audit();


-- add sarcasm detection
ALTER TABLE reviews ADD COLUMN sarcasm_score FLOAT;

--toxicity scores
UPDATE toxicity_scores
SET time_weight = 1.0 - EXTRACT(EPOCH FROM (NOW() - calculated_at)) / 31536000
WHERE calculated_at > NOW() - INTERVAL '1 year';


--blockchain verification query
-- Verify a review hasn't been tampered with
SELECT
    r.review_id,
    r.text_hash = encode(hmac(r.original_text, 'secret_salt', 'sha256'), 'hex') AS is_verified,
    r.blockchain_tx_hash
FROM reviews r
WHERE r.company_id = 'uuid-here';

-- to do awase
-- learn and implement anonymization procedures for GDPR compliance
-- add custom PII detection rules for your region
-- API endpoints for user data requests
-- monthly, quarterly and annually  generate gdpr_data_retention cleanup, requests summary, unsolved requests, completed requests.


--Pseudonymization vs Anonymization
--Pseudonymization is a reversible process - it replaces direct identifiers with aliases
--Anonymization is a irreversible process - it permanently removes all identifying information
-- Add pseudonymization fields
ALTER TABLE users ADD COLUMN pseudonym TEXT GENERATED ALWAYS AS (
    'user_' || encode(hmac(user_id::text, 'gdpr_salt_' || current_date, 'sha256'), 'hex')
) STORED;

ALTER TABLE reviews ADD COLUMN reviewer_pseudonym TEXT;


--Automated Data Anonymization Procedure
CREATE OR REPLACE FUNCTION anonymize_user_data(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
    review_record RECORD;
BEGIN
    -- Step 1: Pseudonymize user table
    UPDATE users
    SET
        email = 'anon_' || user_id || '@deleted.com',
        zkp_public_key = NULL,
        original_metadata = jsonb_set(original_metadata, '{ip}', '"0.0.0.0"')
    WHERE user_id = user_uuid;

    -- Step 2: Anonymize all user's reviews
    FOR review_record IN SELECT review_id FROM reviews WHERE user_id = user_uuid
    LOOP
        UPDATE reviews
        SET
            original_text = '[REDACTED - GDPR REMOVAL]',
            encrypted_text = NULL,
            reviewer_pseudonym = 'user_' || encode(hmac(user_uuid::text, 'review_salt', 'sha256'), 'hex'),
            original_metadata = original_metadata - 'user_agent' - 'device_fingerprint'
        WHERE review_id = review_record.review_id;
    END LOOP;

    -- Step 3: Log the anonymization
    INSERT INTO audit_logs (action, target_type, target_id)
    VALUES ('gdpr_anonymize', 'user', user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


---automatic right to be forgotten compliance
CREATE OR REPLACE FUNCTION process_gdpr_deletion_request()
RETURNS TRIGGER AS $$
BEGIN
    -- Anonymize after 30 days (grace period for dispute resolution)
    PERFORM pg_sleep(2592000); -- 30 days in seconds

    EXECUTE format('SELECT anonymize_user_data(%L)', OLD.user_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_gdpr_deletion
AFTER DELETE ON users
FOR EACH ROW EXECUTE FUNCTION process_gdpr_deletion_request();

--data subject access request DSAR view
CREATE VIEW dsar_user_data AS
SELECT
    u.user_id,
    u.pseudonym,
    u.created_at,
    COUNT(r.review_id) AS review_count,
    array_agg(DISTINCT c.display_name) AS companies_reviewed
FROM users u
LEFT JOIN reviews r ON u.user_id = r.user_id
LEFT JOIN companies c ON r.company_id = c.company_id
GROUP BY u.user_id;


--Personal Identity Identification PII detection and masking
-- Detect potential PII in reviews
CREATE OR REPLACE FUNCTION mask_pii(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(input_text,
        '(\S+@\S+|\+?\d[\d -]{7,}\d|[\d\-\.]{9,})',
        '[PII_REDACTED]',
        'gi');
END;
$$ LANGUAGE plpgsql;

-- Apply to all new reviews
CREATE TRIGGER trigger_mask_pii
BEFORE INSERT ON reviews
FOR EACH ROW EXECUTE FUNCTION mask_pii(original_text);


--secure data retention policy
-- Auto-anonymize old data
CREATE OR REPLACE PROCEDURE gdpr_data_retention_cleanup()
AS $$
BEGIN
    -- Anonymize users inactive for 5+ years
    PERFORM anonymize_user_data(user_id)
    FROM users
    WHERE last_login_at < NOW() - INTERVAL '5 years';

    -- Remove orphaned metadata
    UPDATE reviews
    SET original_metadata = original_metadata - 'ip' - 'geo_location'
    WHERE created_at < NOW() - INTERVAL '2 years';
END;
$$ LANGUAGE plpgsql;

-- Schedule with pg_cron
-- (Run monthly at 2AM)
SELECT cron.schedule(
    'gdpr_cleanup',
    '0 2 1 * *',
    'CALL gdpr_data_retention_cleanup()'
);


--audit trail for compliance
CREATE TABLE gdpr_requests (
    request_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    request_type TEXT NOT NULL CHECK (request_type IN ('access', 'deletion', 'correction')),
    status TEXT NOT NULL DEFAULT 'pending',
    processed_at TIMESTAMPTZ,
    proof_of_verification TEXT, -- ZKP token or govt ID hash
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Log all GDPR-related actions
CREATE OR REPLACE FUNCTION log_gdpr_action()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (action, target_type, target_id, new_data)
    VALUES (
        'gdpr_' || TG_TABLE_NAME,
        TG_TABLE_NAME,
        COALESCE(NEW.user_id, NEW.request_id),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--check procedure match the jurisdiction requirements
-- Test anonymization
SELECT anonymize_user_data('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');

-- Verify DSAR view
SELECT * FROM dsar_user_data WHERE pseudonym = 'user_abc123';
