-- Copyright 2025 β ORI Inc. Awase Khirni Syed
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- For performance monitoring
CREATE EXTENSION IF NOT EXISTS "hstore"; -- For flexible key-value storage

--------------------------------------------------------------------------------
-- TABLES
--------------------------------------------------------------------------------

-- Encryption key management table (secure storage for encryption keys)
CREATE TABLE encryption_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name TEXT NOT NULL UNIQUE,
    key_value TEXT NOT NULL, -- In production, use external key management
    key_rotation_date TIMESTAMPTZ NOT NULL,
    key_expiry_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Passengers with enhanced security and search capabilities
CREATE TABLE passengers (
    passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Encrypted sensitive data
    encrypted_first_name BYTEA NOT NULL,
    encrypted_last_name BYTEA NOT NULL,
    encrypted_email BYTEA NOT NULL,
    encrypted_phone BYTEA,
    encrypted_date_of_birth BYTEA,

    -- Searchable hashes for encrypted fields
    email_hash TEXT GENERATED ALWAYS AS (digest(encrypted_email::text, 'sha256')) STORED,
    phone_hash TEXT GENERATED ALWAYS AS (digest(encrypted_phone::text, 'sha256')) STORED,

    -- GDPR and data management
    gdpr_consent BOOLEAN NOT NULL DEFAULT FALSE,
    consent_date TIMESTAMPTZ,
    data_pseudonymized BOOLEAN DEFAULT FALSE,
    data_retention_date TIMESTAMPTZ,

    -- System fields
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID, -- Track who last modified the record

    -- Indexes for searchable hashes
    CONSTRAINT unique_email_hash UNIQUE (email_hash)
);

-- Passenger documents (passports, IDs)
CREATE TABLE passenger_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id) ON DELETE CASCADE,

    document_type TEXT NOT NULL CHECK (document_type IN ('passport', 'id_card', 'driver_license')),
    encrypted_document_number BYTEA NOT NULL,
    encrypted_issuing_country BYTEA NOT NULL,
    encrypted_expiry_date BYTEA NOT NULL,

    document_hash TEXT GENERATED ALWAYS AS (digest(encrypted_document_number::text, 'sha256')) STORED,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enhanced address table with geocoding support
CREATE TABLE passenger_addresses (
    address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id) ON DELETE CASCADE,

    encrypted_address_line1 BYTEA NOT NULL,
    encrypted_address_line2 BYTEA,
    encrypted_city BYTEA NOT NULL,
    encrypted_postal_code BYTEA NOT NULL,
    encrypted_country BYTEA NOT NULL,

    -- Geocoded fields (encrypted)
    encrypted_latitude BYTEA,
    encrypted_longitude BYTEA,

    address_type TEXT NOT NULL CHECK (address_type IN ('home', 'work', 'billing', 'other')),
    is_primary BOOLEAN DEFAULT FALSE,

    metadata HSTORE, -- Flexible key-value storage for additional data

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enhanced carriers table with compliance info
CREATE TABLE carriers (
    carrier_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name TEXT NOT NULL,
    trading_name TEXT,
    carrier_type TEXT NOT NULL CHECK (carrier_type IN ('airline', 'train', 'bus', 'ferry', 'other')),

    -- Identification codes
    iata_code CHAR(3),
    icao_code CHAR(4),
    national_code TEXT,

    -- Compliance info
    safety_rating TEXT,
    operating_license TEXT,
    insurance_details TEXT,

    -- Contact info
    encrypted_customer_service_email BYTEA,
    encrypted_customer_service_phone BYTEA,

    -- Operational status
    is_active BOOLEAN DEFAULT TRUE,
    operational_since DATE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Routes with enhanced scheduling capabilities
CREATE TABLE routes (
    route_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    carrier_id UUID REFERENCES carriers(carrier_id),

    origin_code TEXT NOT NULL, -- Airport/IATA code
    origin_name TEXT NOT NULL,
    destination_code TEXT NOT NULL,
    destination_name TEXT NOT NULL,

    -- Schedule information
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival TIMESTAMPTZ NOT NULL,
    duration_minutes INT GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (scheduled_arrival - scheduled_departure))/60) STORED,

    -- Operational details
    route_distance_km FLOAT,
    typical_equipment TEXT, -- Aircraft type or train model
    timezone TEXT,

    -- Recurring schedule pattern
    schedule_pattern TEXT, -- e.g., "Mo,We,Fr" or "1-5" for weekdays
    valid_from DATE NOT NULL,
    valid_to DATE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT valid_schedule CHECK (scheduled_arrival > scheduled_departure)
);

-- Enhanced booking agents with performance tracking
CREATE TABLE booking_agents (
    agent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    agent_type TEXT NOT NULL CHECK (agent_type IN ('individual', 'corporate', 'online', 'affiliate')),

    -- Contact info
    encrypted_contact_email BYTEA,
    encrypted_contact_phone BYTEA,

    -- Identification
    iata_agent_code TEXT,
    tax_id TEXT,

    -- Commission structure
    default_commission_rate DECIMAL(5,2),
    commission_calculation_method TEXT CHECK (commission_calculation_method IN ('percentage', 'flat_rate', 'tiered')),

    -- Performance metrics (updated via trigger)
    total_bookings INT DEFAULT 0,
    successful_bookings INT DEFAULT 0,
    last_booking_date TIMESTAMPTZ,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    activation_date DATE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Bookings with enhanced payment and blockchain features
CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    route_id UUID REFERENCES routes(route_id),
    booking_agent_id UUID REFERENCES booking_agents(agent_id),

    -- Booking details
    booking_reference TEXT NOT NULL UNIQUE,
    booking_date TIMESTAMPTZ DEFAULT now() NOT NULL,
    travel_class TEXT CHECK (travel_class IN ('economy', 'premium_economy', 'business', 'first')),

    -- Status tracking
    status TEXT NOT NULL CHECK (status IN ('confirmed', 'cancelled', 'pending', 'waitlisted', 'refunded')),
    status_reason TEXT,
    status_changed_at TIMESTAMPTZ DEFAULT now(),

    -- Payment info
    payment_status TEXT NOT NULL CHECK (payment_status IN ('paid', 'unpaid', 'partial', 'refunded', 'disputed')),
    payment_method TEXT CHECK (payment_method IN ('credit_card', 'debit_card', 'bank_transfer', 'crypto', 'wallet')),
    total_amount DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    payment_due_date TIMESTAMPTZ,

    -- Blockchain integration
    blockchain_tx_hash TEXT,
    blockchain_network TEXT CHECK (blockchain_network IN ('ethereum', 'hyperledger', 'solana', 'other')),
    blockchain_confirmation_blocks INT,
    blockchain_status TEXT CHECK (blockchain_status IN ('pending', 'confirmed', 'failed')),
    blockchain_timestamp TIMESTAMPTZ,

    -- GDPR compliance
    gdpr_data_processing_consent BOOLEAN NOT NULL DEFAULT FALSE,
    consent_version TEXT,
    is_data_pseudonymized BOOLEAN DEFAULT FALSE,

    -- System fields
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- Indexes
    INDEX idx_booking_reference (booking_reference),
    INDEX idx_booking_status (status)
);

-- Booking passengers (for group bookings)
CREATE TABLE booking_passengers (
    booking_passenger_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id) ON DELETE CASCADE,
    passenger_id UUID REFERENCES passengers(passenger_id),

    passenger_type TEXT CHECK (passenger_type IN ('adult', 'child', 'infant', 'senior', 'student')),
    seat_assignment TEXT,
    special_requests TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enhanced audit logs with session tracking
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),

    -- User context
    changed_by UUID, -- user_id or system process
    session_id TEXT,
    ip_address INET,
    user_agent TEXT,

    -- Change details
    changed_at TIMESTAMPTZ DEFAULT now(),
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[],

    -- Business context
    application_module TEXT,
    transaction_id UUID
);

-- Data quality profiles with enhanced metrics
CREATE TABLE data_quality_profiles (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    column_name TEXT NOT NULL,

    -- Quality metrics
    completeness DECIMAL(5,4) CHECK (completeness >= 0 AND completeness <= 1),
    uniqueness DECIMAL(5,4) CHECK (uniqueness >= 0 AND uniqueness <= 1),
    validity DECIMAL(5,4) CHECK (validity >= 0 AND validity <= 1),
    timeliness DECIMAL(5,4) CHECK (timeliness >= 0 AND timeliness <= 1),
    accuracy DECIMAL(5,4) CHECK (accuracy >= 0 AND accuracy <= 1),

    -- Statistical info
    min_value TEXT,
    max_value TEXT,
    avg_value TEXT,
    distinct_count INT,
    null_count INT,

    -- Profiling metadata
    sample_size INT,
    profiling_method TEXT,
    last_profiled TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT unique_profile UNIQUE (table_name, column_name)
);

-- Data cleansing logs with enhanced tracking
CREATE TABLE data_cleansing_logs (
    cleansing_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    column_name TEXT NOT NULL,

    -- Cleansing details
    cleansing_rule TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    cleansing_status TEXT CHECK (cleansing_status IN ('applied', 'reviewed', 'rejected')),

    -- Context
    cleansing_date TIMESTAMPTZ DEFAULT now(),
    performed_by UUID,
    batch_id UUID,

    -- Impact analysis
    business_impact TEXT,
    notes TEXT
);

-- Page visits with enhanced analytics
CREATE TABLE page_visits (
    visit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),

    -- Page context
    page_url TEXT NOT NULL,
    page_title TEXT,
    referrer_url TEXT,
    visit_timestamp TIMESTAMPTZ DEFAULT now(),

    -- Technical context
    user_agent TEXT,
    ip_address INET,
    device_type TEXT CHECK (device_type IN ('desktop', 'mobile', 'tablet', 'other')),
    browser_family TEXT,
    os_family TEXT,

    -- Geographic context
    country_code CHAR(2),
    region TEXT,
    city TEXT,

    -- Session context
    session_id TEXT NOT NULL,
    is_new_session BOOLEAN DEFAULT TRUE,
    session_start TIMESTAMPTZ,

    -- Marketing context
    campaign_id TEXT,
    source_medium TEXT,
    gclid TEXT, -- Google Click ID
    fbclid TEXT, -- Facebook Click ID
    utm_parameters JSONB
);

-- Pricing and fare rules
CREATE TABLE fare_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES routes(route_id),
    carrier_id UUID REFERENCES carriers(carrier_id),

    fare_class TEXT NOT NULL,
    fare_basis TEXT NOT NULL,
    booking_class CHAR(1),

    -- Pricing
    base_price DECIMAL(10,2) NOT NULL,
    taxes DECIMAL(10,2) NOT NULL,
    fees DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL,

    -- Rules
    advance_purchase_days INT,
    minimum_stay_days INT,
    maximum_stay_days INT,
    is_refundable BOOLEAN DEFAULT FALSE,
    change_fee DECIMAL(10,2),
    cancellation_fee DECIMAL(10,2),

    -- Validity
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Loyalty programs
CREATE TABLE loyalty_programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    carrier_id UUID REFERENCES carriers(carrier_id),
    program_name TEXT NOT NULL,
    description TEXT,

    -- Earning rules
    points_per_currency DECIMAL(10,2),
    tier_multipliers JSONB, -- { "silver": 1.1, "gold": 1.25, "platinum": 1.5 }

    -- Status levels
    tier_thresholds JSONB, -- { "silver": 10000, "gold": 50000, "platinum": 100000 }

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Passenger loyalty accounts
CREATE TABLE passenger_loyalty (
    loyalty_account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    program_id UUID REFERENCES loyalty_programs(program_id),

    account_number TEXT NOT NULL UNIQUE,
    current_tier TEXT NOT NULL,
    current_points DECIMAL(12,2) NOT NULL DEFAULT 0,
    lifetime_points DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Status
    join_date DATE NOT NULL,
    tier_expiry_date DATE,
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Loyalty transactions
CREATE TABLE loyalty_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loyalty_account_id UUID REFERENCES passenger_loyalty(loyalty_account_id),
    booking_id UUID REFERENCES bookings(booking_id),

    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earn', 'burn', 'adjustment', 'expiry')),
    points_amount DECIMAL(12,2) NOT NULL,
    transaction_date TIMESTAMPTZ DEFAULT now(),

    -- Context
    description TEXT,
    reference_number TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);

--------------------------------------------------------------------------------
-- ENCRYPTION & DATA MASKING STRATEGIES
--------------------------------------------------------------------------------

-- Key management function
CREATE OR REPLACE FUNCTION get_encryption_key(p_key_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_key_value TEXT;
BEGIN
    SELECT key_value INTO v_key_value
    FROM encryption_keys
    WHERE key_name = p_key_name AND is_active = TRUE AND (key_expiry_date IS NULL OR key_expiry_date > now())
    ORDER BY key_rotation_date DESC
    LIMIT 1;

    IF v_key_value IS NULL THEN
        RAISE EXCEPTION 'No active encryption key found for key name: %', p_key_name;
    END IF;

    RETURN v_key_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced encrypt function with key rotation support
CREATE OR REPLACE FUNCTION encrypt_text(plaintext TEXT, p_key_name TEXT DEFAULT 'passenger_data') RETURNS BYTEA AS $$
DECLARE
    v_key TEXT;
BEGIN
    -- Get the current active key
    v_key := get_encryption_key(p_key_name);

    -- Encrypt with compression and strong cipher
    RETURN pgp_sym_encrypt(
        plaintext,
        v_key,
        'compress-algo=1, cipher-algo=aes256, s2k-mode=3, s2k-count=65011712'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced decrypt function
CREATE OR REPLACE FUNCTION decrypt_text(ciphertext BYTEA, p_key_name TEXT DEFAULT 'passenger_data') RETURNS TEXT AS $$
DECLARE
    v_key TEXT;
BEGIN
    -- Get the current active key
    v_key := get_encryption_key(p_key_name);

    -- Attempt decryption
    BEGIN
        RETURN pgp_sym_decrypt(ciphertext, v_key);
    EXCEPTION WHEN OTHERS THEN
        -- Try with previous keys if decryption fails
        FOR v_key IN
            SELECT key_value FROM encryption_keys
            WHERE key_name = p_key_name
            ORDER BY key_rotation_date DESC
        LOOP
            BEGIN
                RETURN pgp_sym_decrypt(ciphertext, v_key);
            EXCEPTION WHEN OTHERS THEN
                CONTINUE;
            END;
        END LOOP;

        RAISE EXCEPTION 'Failed to decrypt with any available key for key name: %', p_key_name;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Data masking functions
CREATE OR REPLACE FUNCTION mask_email(email TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(email, '^(.)(.*)(@.*)$', '\1****\3', 'i');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION mask_phone(phone TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(phone, '(\d{3})\d{4}(\d{3})', '\1****\2');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Masked view for passengers with different masking levels
CREATE VIEW passenger_masked_view AS
SELECT
    passenger_id,

    -- Level 1 masking (basic)
    CASE
        WHEN data_pseudonymized THEN 'ANONYMIZED'
        ELSE substr(decrypt_text(encrypted_first_name), 1, 1) || '****'
    END AS first_name_masked,

    CASE
        WHEN data_pseudonymized THEN 'ANONYMIZED'
        ELSE substr(decrypt_text(encrypted_last_name), 1, 1) || '****'
    END AS last_name_masked,

    -- Level 2 masking (email with domain preserved)
    CASE
        WHEN data_pseudonymized THEN 'anonymous@example.com'
        ELSE mask_email(decrypt_text(encrypted_email))
    END AS email_masked,

    -- Level 3 masking (full anonymization for sensitive data)
    CASE
        WHEN data_pseudonymized THEN NULL
        WHEN encrypted_phone IS NULL THEN NULL
        ELSE mask_phone(decrypt_text(encrypted_phone))
    END AS phone_masked,

    -- Metadata
    gdpr_consent,
    data_pseudonymized,
    created_at
FROM passengers;

--------------------------------------------------------------------------------
-- ANALYTIC VIEWS
--------------------------------------------------------------------------------

-- Enhanced booking summary with revenue and carrier info
CREATE VIEW booking_summary_analytics AS
SELECT
    r.route_id,
    c.carrier_id,
    c.legal_name AS carrier_name,
    c.carrier_type,
    r.origin_code,
    r.origin_name,
    r.destination_code,
    r.destination_name,

    -- Time dimensions
    date_trunc('day', b.booking_date) AS booking_day,
    date_trunc('week', b.booking_date) AS booking_week,
    date_trunc('month', b.booking_date) AS booking_month,

    -- Booking metrics
    COUNT(b.booking_id) AS total_bookings,
    SUM(CASE WHEN b.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_bookings,
    SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings,
    SUM(CASE WHEN b.payment_status = 'paid' THEN 1 ELSE 0 END) AS paid_bookings,

    -- Financial metrics
    SUM(b.total_amount) AS total_revenue,
    SUM(CASE WHEN b.status = 'confirmed' THEN b.total_amount ELSE 0 END) AS confirmed_revenue,
    SUM(CASE WHEN b.status = 'cancelled' THEN b.total_amount ELSE 0 END) AS cancelled_revenue,

    -- Passenger metrics
    COUNT(DISTINCT b.passenger_id) AS unique_passengers,
    COUNT(DISTINCT bp.passenger_id) AS total_passengers,

    -- Blockchain metrics
    SUM(CASE WHEN b.blockchain_status = 'confirmed' THEN 1 ELSE 0 END) AS blockchain_confirmed,
    SUM(CASE WHEN b.blockchain_status = 'pending' THEN 1 ELSE 0 END) AS blockchain_pending

FROM bookings b
JOIN routes r ON b.route_id = r.route_id
JOIN carriers c ON r.carrier_id = c.carrier_id
LEFT JOIN booking_passengers bp ON b.booking_id = bp.booking_id
GROUP BY
    r.route_id, c.carrier_id, c.legal_name, c.carrier_type,
    r.origin_code, r.origin_name, r.destination_code, r.destination_name,
    booking_day, booking_week, booking_month;

-- Agent performance dashboard view
CREATE VIEW agent_performance_dashboard AS
SELECT
    a.agent_id,
    a.name AS agent_name,
    a.agent_type,
    a.default_commission_rate,

    -- Booking metrics
    a.total_bookings,
    a.successful_bookings,
    COUNT(b.booking_id) AS period_bookings,
    SUM(CASE WHEN b.status = 'confirmed' THEN 1 ELSE 0 END) AS period_confirmed,
    SUM(CASE WHEN b.status = 'cancelled' THEN 1 ELSE 0 END) AS period_cancelled,

    -- Financial metrics
    SUM(b.total_amount) AS period_sales,
    SUM(CASE WHEN b.status = 'confirmed' THEN b.total_amount ELSE 0 END) AS confirmed_sales,
    SUM(CASE WHEN b.payment_status = 'paid' THEN b.total_amount ELSE 0 END) AS paid_sales,

    -- Time metrics
    MIN(b.booking_date) AS first_booking_date,
    MAX(b.booking_date) AS last_booking_date,

    -- Quality metrics
    ROUND(SUM(CASE WHEN b.status = 'confirmed' THEN 1 ELSE 0 END)::DECIMAL /
          NULLIF(COUNT(b.booking_id), 0), 4) AS confirmation_rate,

    -- Blockchain metrics
    SUM(CASE WHEN b.blockchain_status = 'confirmed' THEN 1 ELSE 0 END) AS blockchain_confirmed

FROM booking_agents a
LEFT JOIN bookings b ON a.agent_id = b.booking_agent_id
    AND b.booking_date >= date_trunc('month', CURRENT_DATE - INTERVAL '12 months')
GROUP BY a.agent_id, a.name, a.agent_type, a.default_commission_rate,
         a.total_bookings, a.successful_bookings;

-- Passenger value analysis view
CREATE VIEW passenger_value_analysis AS
SELECT
    p.passenger_id,

    -- Identity (masked)
    substr(decrypt_text(p.encrypted_first_name), 1, 1) || '****' AS first_initial,
    substr(decrypt_text(p.encrypted_last_name), 1, 1) || '****' AS last_initial,
    mask_email(decrypt_text(p.encrypted_email)) AS masked_email,

    -- Booking activity
    COUNT(b.booking_id) AS total_bookings,
    SUM(CASE WHEN b.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_bookings,
    MIN(b.booking_date) AS first_booking_date,
    MAX(b.booking_date) AS last_booking_date,

    -- Financial value
    SUM(b.total_amount) AS total_spend,
    AVG(b.total_amount) AS avg_booking_value,

    -- Travel preferences
    MODE() WITHIN GROUP (ORDER BY r.origin_code) AS most_frequent_origin,
    MODE() WITHIN GROUP (ORDER BY r.destination_code) AS most_frequent_destination,
    MODE() WITHIN GROUP (ORDER BY b.travel_class) AS preferred_travel_class,

    -- Loyalty status
    COALESCE(MAX(pl.current_tier), 'none') AS loyalty_tier,
    COALESCE(MAX(pl.current_points), 0) AS loyalty_points

FROM passengers p
LEFT JOIN bookings b ON p.passenger_id = b.passenger_id
LEFT JOIN routes r ON b.route_id = r.route_id
LEFT JOIN passenger_loyalty pl ON p.passenger_id = pl.passenger_id
GROUP BY p.passenger_id, p.encrypted_first_name, p.encrypted_last_name, p.encrypted_email;

--------------------------------------------------------------------------------
-- GDPR-RELATED PROCEDURES
--------------------------------------------------------------------------------

-- Enhanced pseudonymization procedure with logging
CREATE OR REPLACE FUNCTION pseudonymize_passenger_data(
    p_passenger_id UUID,
    p_requested_by UUID DEFAULT NULL,
    p_reason TEXT DEFAULT 'GDPR compliance'
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_old_data JSONB;
    v_new_data JSONB;
BEGIN
    -- Get old data for audit
    SELECT jsonb_build_object(
        'first_name', decrypt_text(encrypted_first_name),
        'last_name', decrypt_text(encrypted_last_name),
        'email', decrypt_text(encrypted_email),
        'phone', CASE WHEN encrypted_phone IS NULL THEN NULL ELSE decrypt_text(encrypted_phone) END,
        'dob', CASE WHEN encrypted_date_of_birth IS NULL THEN NULL ELSE decrypt_text(encrypted_date_of_birth) END
    ) INTO v_old_data
    FROM passengers
    WHERE passenger_id = p_passenger_id;

    -- Perform pseudonymization
    UPDATE passengers SET
        encrypted_first_name = encrypt_text('ANONYMIZED'),
        encrypted_last_name = encrypt_text('ANONYMIZED'),
        encrypted_email = encrypt_text('anonymous_' || p_passenger_id || '@example.com'),
        encrypted_phone = NULL,
        encrypted_date_of_birth = NULL,
        data_pseudonymized = TRUE,
        updated_at = now(),
        updated_by = p_requested_by
    WHERE passenger_id = p_passenger_id;

    -- Get new data for audit
    SELECT jsonb_build_object(
        'first_name', 'ANONYMIZED',
        'last_name', 'ANONYMIZED',
        'email', 'anonymous_' || p_passenger_id || '@example.com',
        'phone', NULL,
        'dob', NULL
    ) INTO v_new_data;

    -- Log the pseudonymization
    INSERT INTO audit_logs (
        table_name,
        record_id,
        operation,
        changed_by,
        old_data,
        new_data,
        changed_fields,
        application_module,
        transaction_id
    ) VALUES (
        'passengers',
        p_passenger_id,
        'UPDATE',
        p_requested_by,
        v_old_data,
        v_new_data,
        ARRAY['encrypted_first_name', 'encrypted_last_name', 'encrypted_email', 'encrypted_phone', 'encrypted_date_of_birth'],
        'GDPR Compliance',
        uuid_generate_v4()
    );

    -- Also pseudonymize related addresses
    PERFORM pseudonymize_addresses_for_passenger(p_passenger_id, p_requested_by);

    -- Return success with details
    v_result := jsonb_build_object(
        'status', 'success',
        'passenger_id', p_passenger_id,
        'pseudonymized_at', now(),
        'affected_fields', ARRAY['first_name', 'last_name', 'email', 'phone', 'date_of_birth']
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to pseudonymize addresses
CREATE OR REPLACE FUNCTION pseudonymize_addresses_for_passenger(
    p_passenger_id UUID,
    p_requested_by UUID DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE passenger_addresses SET
        encrypted_address_line1 = encrypt_text('ANONYMIZED'),
        encrypted_address_line2 = NULL,
        encrypted_city = encrypt_text('ANONYMIZED'),
        encrypted_postal_code = encrypt_text('00000'),
        encrypted_country = encrypt_text('ANONYMIZED'),
        encrypted_latitude = NULL,
        encrypted_longitude = NULL,
        updated_at = now(),
        updated_by = p_requested_by
    WHERE passenger_id = p_passenger_id;

    -- Log address pseudonymization
    INSERT INTO audit_logs (
        table_name,
        record_id,
        operation,
        changed_by,
        application_module,
        transaction_id
    ) VALUES (
        'passenger_addresses',
        p_passenger_id,
        'UPDATE',
        p_requested_by,
        'GDPR Compliance',
        uuid_generate_v4()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced data deletion procedure with comprehensive cleanup
CREATE OR REPLACE FUNCTION delete_passenger_data(
    p_passenger_id UUID,
    p_requested_by UUID DEFAULT NULL,
    p_reason TEXT DEFAULT 'GDPR right to be forgotten'
) RETURNS JSONB AS $$
DECLARE
    v_booking_count INT;
    v_address_count INT;
    v_loyalty_count INT;
    v_result JSONB;
BEGIN
    -- Get counts for reporting
    SELECT COUNT(*) INTO v_booking_count FROM bookings WHERE passenger_id = p_passenger_id;
    SELECT COUNT(*) INTO v_address_count FROM passenger_addresses WHERE passenger_id = p_passenger_id;
    SELECT COUNT(*) INTO v_loyalty_count FROM passenger_loyalty WHERE passenger_id = p_passenger_id;

    -- Log the deletion request before performing it
    INSERT INTO audit_logs (
        table_name,
        record_id,
        operation,
        changed_by,
        new_data,
        application_module,
        transaction_id
    ) VALUES (
        'passengers',
        p_passenger_id,
        'DELETE',
        p_requested_by,
        jsonb_build_object(
            'reason', p_reason,
            'affected_bookings', v_booking_count,
            'affected_addresses', v_address_count,
            'affected_loyalty_accounts', v_loyalty_count
        ),
        'GDPR Compliance',
        uuid_generate_v4()
    );

    -- Delete dependent records
    DELETE FROM booking_passengers WHERE passenger_id = p_passenger_id;
    DELETE FROM passenger_loyalty WHERE passenger_id = p_passenger_id;
    DELETE FROM passenger_documents WHERE passenger_id = p_passenger_id;
    DELETE FROM passenger_addresses WHERE passenger_id = p_passenger_id;

    -- Update bookings to remove reference (but keep booking records for business purposes)
    UPDATE bookings SET
        passenger_id = NULL,
        is_data_pseudonymized = TRUE,
        updated_at = now(),
        updated_by = p_requested_by
    WHERE passenger_id = p_passenger_id;

    -- Finally delete the passenger
    DELETE FROM passengers WHERE passenger_id = p_passenger_id;

    -- Return result with statistics
    v_result := jsonb_build_object(
        'status', 'success',
        'passenger_id', p_passenger_id,
        'deleted_at', now(),
        'affected_records', jsonb_build_object(
            'bookings', v_booking_count,
            'addresses', v_address_count,
            'loyalty_accounts', v_loyalty_count
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Consent management procedure
CREATE OR REPLACE FUNCTION update_passenger_consent(
    p_passenger_id UUID,
    p_consent_status BOOLEAN,
    p_consent_type TEXT DEFAULT 'data_processing',
    p_requested_by UUID DEFAULT NULL,
    p_consent_version TEXT DEFAULT '1.0'
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    IF p_consent_type = 'data_processing' THEN
        UPDATE passengers SET
            gdpr_consent = p_consent_status,
            consent_date = CASE WHEN p_consent_status THEN now() ELSE NULL END,
            consent_version = CASE WHEN p_consent_status THEN p_consent_version ELSE NULL END,
            updated_at = now(),
            updated_by = p_requested_by
        WHERE passenger_id = p_passenger_id;

        -- Log consent change
        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            new_data,
            changed_fields,
            application_module
        ) VALUES (
            'passengers',
            p_passenger_id,
            'UPDATE',
            p_requested_by,
            jsonb_build_object('gdpr_consent', p_consent_status, 'consent_version', p_consent_version),
            ARRAY['gdpr_consent', 'consent_date', 'consent_version'],
            'Consent Management'
        );

        v_result := jsonb_build_object(
            'status', 'success',
            'passenger_id', p_passenger_id,
            'consent_type', p_consent_type,
            'new_status', p_consent_status,
            'updated_at', now()
        );
    ELSE
        v_result := jsonb_build_object(
            'status', 'error',
            'message', 'Unsupported consent type',
            'supported_types', ARRAY['data_processing']
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------------------
-- TRIGGERS
--------------------------------------------------------------------------------

-- Timestamp update trigger (for all tables with updated_at)
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
    LOOP
        EXECUTE format('CREATE TRIGGER trg_update_timestamp
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION update_timestamp()',
            t.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Enhanced audit trigger for passengers
CREATE OR REPLACE FUNCTION audit_passenger_changes() RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_json JSONB;
    v_new_json JSONB;
BEGIN
    -- Initialize changed fields array
    v_changed_fields := '{}';

    -- Compare each field for updates
    IF TG_OP = 'UPDATE' THEN
        IF NEW.encrypted_first_name IS DISTINCT FROM OLD.encrypted_first_name THEN
            v_changed_fields := array_append(v_changed_fields, 'first_name');
        END IF;

        IF NEW.encrypted_last_name IS DISTINCT FROM OLD.encrypted_last_name THEN
            v_changed_fields := array_append(v_changed_fields, 'last_name');
        END IF;

        IF NEW.encrypted_email IS DISTINCT FROM OLD.encrypted_email THEN
            v_changed_fields := array_append(v_changed_fields, 'email');
        END IF;

        -- Only include sensitive fields if they changed and weren't pseudonymized
        IF NOT NEW.data_pseudonymized THEN
            IF NEW.encrypted_phone IS DISTINCT FROM OLD.encrypted_phone THEN
                v_changed_fields := array_append(v_changed_fields, 'phone');
            END IF;

            IF NEW.encrypted_date_of_birth IS DISTINCT FROM OLD.encrypted_date_of_birth THEN
                v_changed_fields := array_append(v_changed_fields, 'date_of_birth');
            END IF;
        END IF;

        IF NEW.gdpr_consent IS DISTINCT FROM OLD.gdpr_consent THEN
            v_changed_fields := array_append(v_changed_fields, 'gdpr_consent');
        END IF;

        IF NEW.data_pseudonymized IS DISTINCT FROM OLD.data_pseudonymized THEN
            v_changed_fields := array_append(v_changed_fields, 'data_pseudonymized');
        END IF;

        -- Only create audit log if something actually changed
        IF array_length(v_changed_fields, 1) > 0 THEN
            -- Build JSON representations with proper decryption
            v_old_json := jsonb_build_object(
                'first_name', CASE WHEN OLD.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(OLD.encrypted_first_name) END,
                'last_name', CASE WHEN OLD.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(OLD.encrypted_last_name) END,
                'email', CASE WHEN OLD.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(OLD.encrypted_email) END,
                'phone', CASE WHEN OLD.data_pseudonymized OR OLD.encrypted_phone IS NULL THEN NULL ELSE decrypt_text(OLD.encrypted_phone) END,
                'date_of_birth', CASE WHEN OLD.data_pseudonymized OR OLD.encrypted_date_of_birth IS NULL THEN NULL ELSE decrypt_text(OLD.encrypted_date_of_birth) END,
                'gdpr_consent', OLD.gdpr_consent,
                'data_pseudonymized', OLD.data_pseudonymized
            );

            v_new_json := jsonb_build_object(
                'first_name', CASE WHEN NEW.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(NEW.encrypted_first_name) END,
                'last_name', CASE WHEN NEW.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(NEW.encrypted_last_name) END,
                'email', CASE WHEN NEW.data_pseudonymized THEN 'ANONYMIZED' ELSE decrypt_text(NEW.encrypted_email) END,
                'phone', CASE WHEN NEW.data_pseudonymized OR NEW.encrypted_phone IS NULL THEN NULL ELSE decrypt_text(NEW.encrypted_phone) END,
                'date_of_birth', CASE WHEN NEW.data_pseudonymized OR NEW.encrypted_date_of_birth IS NULL THEN NULL ELSE decrypt_text(NEW.encrypted_date_of_birth) END,
                'gdpr_consent', NEW.gdpr_consent,
                'data_pseudonymized', NEW.data_pseudonymized
            );

            INSERT INTO audit_logs (
                table_name,
                record_id,
                operation,
                changed_by,
                old_data,
                new_data,
                changed_fields
            ) VALUES (
                TG_TABLE_NAME,
                NEW.passenger_id,
                'UPDATE',
                NEW.updated_by,
                v_old_json,
                v_new_json,
                v_changed_fields
            );
        END IF;

        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- For deletes, log what we can (without decryption)
        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            old_data
        ) VALUES (
            TG_TABLE_NAME,
            OLD.passenger_id,
            'DELETE',
            jsonb_build_object(
                'gdpr_consent', OLD.gdpr_consent,
                'data_pseudonymized', OLD.data_pseudonymized
            )
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_passenger
    AFTER UPDATE OR DELETE ON passengers
    FOR EACH ROW EXECUTE FUNCTION audit_passenger_changes();

-- Booking status change trigger
CREATE OR REPLACE FUNCTION log_booking_status_change() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            old_data,
            new_data,
            changed_fields
        ) VALUES (
            TG_TABLE_NAME,
            NEW.booking_id,
            'UPDATE',
            NEW.updated_by,
            jsonb_build_object('status', OLD.status, 'status_reason', OLD.status_reason),
            jsonb_build_object('status', NEW.status, 'status_reason', NEW.status_reason),
            ARRAY['status', 'status_reason']
        );
    END IF;

    IF TG_OP = 'UPDATE' AND NEW.payment_status IS DISTINCT FROM OLD.payment_status THEN
        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation,
            changed_by,
            old_data,
            new_data,
            changed_fields
        ) VALUES (
            TG_TABLE_NAME,
            NEW.booking_id,
            'UPDATE',
            NEW.updated_by,
            jsonb_build_object('payment_status', OLD.payment_status),
            jsonb_build_object('payment_status', NEW.payment_status),
            ARRAY['payment_status']
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_booking_status_change
    AFTER UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION log_booking_status_change();

-- Agent performance tracking trigger
CREATE OR REPLACE FUNCTION update_agent_performance() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE booking_agents SET
            total_bookings = total_bookings + 1,
            successful_bookings = successful_bookings + CASE WHEN NEW.status = 'confirmed' THEN 1 ELSE 0 END,
            last_booking_date = NEW.booking_date
        WHERE agent_id = NEW.booking_agent_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        -- If status changed from confirmed to something else
        IF OLD.status = 'confirmed' AND NEW.status != 'confirmed' THEN
            UPDATE booking_agents SET
                successful_bookings = successful_bookings - 1
            WHERE agent_id = NEW.booking_agent_id;
        -- If status changed to confirmed from something else
        ELSIF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
            UPDATE booking_agents SET
                successful_bookings = successful_bookings + 1
            WHERE agent_id = NEW.booking_agent_id;
        END IF;
    END IF;

    RETURN NULL; -- This is an AFTER trigger, return value is ignored
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_agent_performance_insert
    AFTER INSERT ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_agent_performance();

CREATE TRIGGER trg_agent_performance_update
    AFTER UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_agent_performance();

--------------------------------------------------------------------------------
-- BLOCKCHAIN INTEGRATION FUNCTIONS
--------------------------------------------------------------------------------

-- Function to submit booking to blockchain
CREATE OR REPLACE FUNCTION submit_booking_to_blockchain(
    p_booking_id UUID,
    p_network TEXT DEFAULT 'ethereum'
) RETURNS JSONB AS $$
DECLARE
    v_booking RECORD;
    v_tx_hash TEXT;
    v_result JSONB;
BEGIN
    -- Get booking details
    SELECT
        b.booking_reference,
        b.total_amount,
        b.currency,
        r.origin_code,
        r.destination_code,
        r.scheduled_departure,
        c.iata_code AS carrier_code
    INTO v_booking
    FROM bookings b
    JOIN routes r ON b.route_id = r.route_id
    JOIN carriers c ON r.carrier_id = c.carrier_id
    WHERE b.booking_id = p_booking_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Booking not found');
    END IF;

    -- In a real implementation, this would call an external service or smart contract
    -- For this example, we'll simulate a transaction hash
    v_tx_hash := encode(digest(random()::text || p_booking_id::text || now()::text, 'sha256'), 'hex');

    -- Update booking with blockchain info
    UPDATE bookings SET
        blockchain_tx_hash = v_tx_hash,
        blockchain_network = p_network,
        blockchain_status = 'pending',
        blockchain_timestamp = now(),
        updated_at = now()
    WHERE booking_id = p_booking_id;

    -- Log the blockchain submission
    INSERT INTO audit_logs (
        table_name,
        record_id,
        operation,
        new_data,
        application_module
    ) VALUES (
        'bookings',
        p_booking_id,
        'UPDATE',
        jsonb_build_object(
            'blockchain_tx_hash', v_tx_hash,
            'blockchain_network', p_network,
            'blockchain_status', 'pending'
        ),
        'Blockchain Integration'
    );

    -- Return result
    v_result := jsonb_build_object(
        'status', 'success',
        'booking_id', p_booking_id,
        'tx_hash', v_tx_hash,
        'network', p_network,
        'submitted_at', now()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to confirm blockchain transaction
CREATE OR REPLACE FUNCTION confirm_blockchain_transaction(
    p_booking_id UUID,
    p_confirmations INT DEFAULT 12,
    p_block_number INT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Update booking with confirmation
    UPDATE bookings SET
        blockchain_status = 'confirmed',
        blockchain_confirmation_blocks = p_confirmations,
        updated_at = now()
    WHERE booking_id = p_booking_id;

    -- Log the confirmation
    INSERT INTO audit_logs (
        table_name,
        record_id,
        operation,
        new_data,
        application_module
    ) VALUES (
        'bookings',
        p_booking_id,
        'UPDATE',
        jsonb_build_object(
            'blockchain_status', 'confirmed',
            'blockchain_confirmation_blocks', p_confirmations
        ),
        'Blockchain Integration'
    );

    -- Return result
    v_result := jsonb_build_object(
        'status', 'success',
        'booking_id', p_booking_id,
        'confirmed_at', now(),
        'confirmations', p_confirmations
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------------------
-- DATA QUALITY FUNCTIONS
--------------------------------------------------------------------------------

-- Function to profile table data quality
CREATE OR REPLACE FUNCTION profile_data_quality(
    p_table_name TEXT,
    p_sample_size INT DEFAULT 1000
) RETURNS JSONB AS $$
DECLARE
    v_column RECORD;
    v_result JSONB := '[]'::JSONB;
    v_sql TEXT;
    v_completeness FLOAT;
    v_uniqueness FLOAT;
    v_validity FLOAT;
    v_distinct_count INT;
    v_null_count INT;
    v_min TEXT;
    v_max TEXT;
    v_avg TEXT;
BEGIN
    -- For each column in the table
    FOR v_column IN
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = p_table_name
        AND table_schema = 'public'
    LOOP
        -- Calculate completeness (non-null ratio)
        EXECUTE format('
            SELECT
                COUNT(*)::FLOAT / NULLIF(SUM(CASE WHEN %I IS NULL THEN 0 ELSE 1 END), 0),
                COUNT(DISTINCT %I)::FLOAT / NULLIF(COUNT(*), 0),
                COUNT(*) - COUNT(%I)
            FROM (
                SELECT %I FROM %I LIMIT %s
            ) sample',
            v_column.column_name, v_column.column_name, v_column.column_name,
            v_column.column_name, p_table_name, p_sample_size
        ) INTO v_completeness, v_uniqueness, v_null_count;

        -- For numeric columns, calculate min/max/avg
        IF v_column.data_type IN ('integer', 'bigint', 'numeric', 'real', 'double precision') THEN
            EXECUTE format('
                SELECT
                    MIN(%I)::TEXT,
                    MAX(%I)::TEXT,
                    AVG(%I)::TEXT
                FROM %I',
                v_column.column_name, v_column.column_name, v_column.column_name, p_table_name
            ) INTO v_min, v_max, v_avg;
        ELSE
            v_min := NULL;
            v_max := NULL;
            v_avg := NULL;
        END IF;

        -- Get distinct count
        EXECUTE format('
            SELECT COUNT(DISTINCT %I)
            FROM %I',
            v_column.column_name, p_table_name
        ) INTO v_distinct_count;

        -- For now, set validity to same as completeness (could add specific validation rules)
        v_validity := v_completeness;

        -- Upsert the profile data
        INSERT INTO data_quality_profiles (
            table_name,
            column_name,
            completeness,
            uniqueness,
            validity,
            timeliness, -- Not calculated in this simple version
            accuracy, -- Not calculated in this simple version
            min_value,
            max_value,
            avg_value,
            distinct_count,
            null_count,
            sample_size,
            profiling_method
        ) VALUES (
            p_table_name,
            v_column.column_name,
            v_completeness,
            v_uniqueness,
            v_validity,
            1.0, -- Placeholder
            1.0, -- Placeholder
            v_min,
            v_max,
            v_avg,
            v_distinct_count,
            v_null_count,
            p_sample_size,
            'basic_profiling'
        )
        ON CONFLICT (table_name, column_name)
        DO UPDATE SET
            completeness = EXCLUDED.completeness,
            uniqueness = EXCLUDED.uniqueness,
            validity = EXCLUDED.validity,
            min_value = EXCLUDED.min_value,
            max_value = EXCLUDED.max_value,
            avg_value = EXCLUDED.avg_value,
            distinct_count = EXCLUDED.distinct_count,
            null_count = EXCLUDED.null_count,
            last_profiled = now();

        -- Append to result
        v_result := v_result || jsonb_build_object(
            'column', v_column.column_name,
            'completeness', v_completeness,
            'uniqueness', v_uniqueness,
            'validity', v_validity,
            'distinct_count', v_distinct_count,
            'null_count', v_null_count
        );
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'success',
        'table', p_table_name,
        'sample_size', p_sample_size,
        'columns', v_result
    );
END;
$$ LANGUAGE plpgsql;

-- Function to cleanse email formats
CREATE OR REPLACE FUNCTION cleanse_email_formats(
    p_batch_size INT DEFAULT 100,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_cleansed_count INT := 0;
    v_error_count INT := 0;
    v_batch_id UUID := uuid_generate_v4();
    v_result JSONB;
    v_record RECORD;
BEGIN
    -- Process records with potentially malformed emails
    FOR v_record IN
        SELECT
            p.passenger_id,
            decrypt_text(p.encrypted_email) AS old_email,
            lower(trim(decrypt_text(p.encrypted_email))) AS new_email
        FROM passengers p
        WHERE decrypt_text(p.encrypted_email) ~* '[[:space:]]'
           OR decrypt_text(p.encrypted_email) ~* '[A-Z]'
        LIMIT p_batch_size
    LOOP
        BEGIN
            IF v_record.old_email != v_record.new_email THEN
                v_cleansed_count := v_cleansed_count + 1;

                IF NOT p_dry_run THEN
                    -- Update the email
                    UPDATE passengers SET
                        encrypted_email = encrypt_text(v_record.new_email),
                        updated_at = now()
                    WHERE passenger_id = v_record.passenger_id;

                    -- Log the cleansing
                    INSERT INTO data_cleansing_logs (
                        table_name,
                        record_id,
                        column_name,
                        cleansing_rule,
                        old_value,
                        new_value,
                        cleansing_status,
                        batch_id
                    ) VALUES (
                        'passengers',
                        v_record.passenger_id,
                        'email',
                        'lowercase_and_trim',
                        v_record.old_email,
                        v_record.new_email,
                        'applied',
                        v_batch_id
                    );
                END IF;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;

            -- Log the error
            INSERT INTO data_cleansing_logs (
                table_name,
                record_id,
                column_name,
                cleansing_rule,
                old_value,
                new_value,
                cleansing_status,
                batch_id,
                notes
            ) VALUES (
                'passengers',
                v_record.passenger_id,
                'email',
                'lowercase_and_trim',
                v_record.old_email,
                v_record.new_email,
                'failed',
                v_batch_id,
                SQLERRM
            );
        END;
    END LOOP;

    -- Return result
    v_result := jsonb_build_object(
        'status', 'success',
        'batch_id', v_batch_id,
        'total_processed', p_batch_size,
        'cleansed_count', v_cleansed_count,
        'error_count', v_error_count,
        'dry_run', p_dry_run
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

-- Insert initial encryption key
INSERT INTO encryption_keys (
    key_name,
    key_value,
    key_rotation_date,
    key_expiry_date,
    is_active
) VALUES (
    'passenger_data',
    'my_very_secure_key_32bytes_long_1234!', -- In production, use a proper key management system
    now(),
    now() + INTERVAL '1 year',
    TRUE
);

-- Sample carrier data
INSERT INTO carriers (
    legal_name,
    trading_name,
    carrier_type,
    iata_code,
    icao_code,
    safety_rating,
    is_active,
    operational_since
) VALUES
('Delta Air Lines, Inc.', 'Delta', 'airline', 'DL', 'DAL', '7-star', TRUE, '1929-05-30'),
('Amtrak', 'Amtrak', 'train', NULL, NULL, '5-star', TRUE, '1971-05-01'),
('Greyhound Lines, Inc.', 'Greyhound', 'bus', NULL, NULL, '4-star', TRUE, '1914-01-01');

-- Sample route data
INSERT INTO routes (
    carrier_id,
    origin_code,
    origin_name,
    destination_code,
    destination_name,
    scheduled_departure,
    scheduled_arrival,
    schedule_pattern,
    valid_from,
    valid_to
) VALUES
((SELECT carrier_id FROM carriers WHERE iata_code = 'DL'), 'JFK', 'New York JFK', 'LAX', 'Los Angeles',
 '2023-06-01 08:00:00', '2023-06-01 11:30:00', '1-7', '2023-06-01', '2023-12-31'),
((SELECT carrier_id FROM carriers WHERE iata_code = 'DL'), 'LAX', 'Los Angeles', 'JFK', 'New York JFK',
 '2023-06-01 13:00:00', '2023-06-01 21:30:00', '1-7', '2023-06-01', '2023-12-31'),
((SELECT carrier_id FROM carriers WHERE legal_name = 'Amtrak'), 'NYP', 'New York Penn', 'WAS', 'Washington Union',
 '2023-06-01 06:00:00', '2023-06-01 09:30:00', '1-5', '2023-06-01', '2023-12-31');

-- Sample booking agent
INSERT INTO booking_agents (
    name,
    agent_type,
    default_commission_rate,
    commission_calculation_method,
    is_active
) VALUES
('TravelWorld Inc.', 'corporate', 10.00, 'percentage', TRUE),
('OnlineBookings LLC', 'online', 8.50, 'flat_rate', TRUE);

--------------------------------------------------------------------------------
-- SCAM PREVENTION TABLES
--------------------------------------------------------------------------------

-- Known fraud patterns table
CREATE TABLE fraud_patterns (
    pattern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_name TEXT NOT NULL,
    pattern_description TEXT,
    pattern_conditions JSONB NOT NULL, -- Conditions that trigger this fraud pattern
    risk_score INT CHECK (risk_score BETWEEN 1 AND 10),
    mitigation_action TEXT CHECK (mitigation_action IN ('flag', 'hold', 'block', 'require_verification')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Fraud attempts log
CREATE TABLE fraud_attempts (
    attempt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id UUID REFERENCES fraud_patterns(pattern_id),
    booking_id UUID REFERENCES bookings(booking_id),
    passenger_id UUID REFERENCES passengers(passenger_id),
    matched_conditions JSONB NOT NULL,
    risk_score INT CHECK (risk_score BETWEEN 1 AND 10),
    action_taken TEXT NOT NULL,
    action_result TEXT,
    reviewed_by UUID, -- Staff member who reviewed
    reviewed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Payment verification table
CREATE TABLE payment_verifications (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(booking_id),
    payment_method TEXT NOT NULL,
    verification_status TEXT NOT NULL CHECK (verification_status IN ('pending', 'verified', 'failed', 'suspicious')),
    verification_method TEXT CHECK (verification_method IN ('3ds', 'avs', 'manual', 'biometric')),
    verification_data JSONB,
    verification_score INT CHECK (verification_score BETWEEN 0 AND 100),
    verified_at TIMESTAMPTZ,
    verified_by UUID, -- Staff member if manual verification
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Device fingerprinting table
CREATE TABLE device_fingerprints (
    fingerprint_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id),
    device_hash TEXT NOT NULL, -- Hashed device fingerprint
    user_agent TEXT,
    ip_address INET,
    screen_resolution TEXT,
    plugins TEXT[],
    fonts TEXT[],
    canvas_hash TEXT,
    webgl_hash TEXT,
    is_trusted BOOLEAN DEFAULT FALSE,
    first_seen TIMESTAMPTZ DEFAULT now(),
    last_seen TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_fingerprint UNIQUE (device_hash, passenger_id)
);

-- IP reputation table
CREATE TABLE ip_reputation (
    ip_address INET PRIMARY KEY,
    reputation_score INT CHECK (reputation_score BETWEEN 0 AND 100),
    is_vpn BOOLEAN DEFAULT FALSE,
    is_proxy BOOLEAN DEFAULT FALSE,
    is_tor BOOLEAN DEFAULT FALSE,
    is_cloud_provider BOOLEAN DEFAULT FALSE,
    last_checked TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Account security table
CREATE TABLE account_security (
    security_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID REFERENCES passengers(passenger_id) ON DELETE CASCADE,
    failed_login_attempts INT DEFAULT 0,
    last_failed_login TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_method TEXT CHECK (mfa_method IN ('sms', 'email', 'totp', 'biometric', 'none')),
    security_questions JSONB, -- Encrypted security questions
    account_locked BOOLEAN DEFAULT FALSE,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

--------------------------------------------------------------------------------
-- SCAM PREVENTION FUNCTIONS
--------------------------------------------------------------------------------

-- Function to check booking for fraud patterns
CREATE OR REPLACE FUNCTION check_booking_fraud(
    p_booking_id UUID,
    p_strict_mode BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
DECLARE
    v_booking RECORD;
    v_passenger RECORD;
    v_payment RECORD;
    v_pattern RECORD;
    v_matched BOOLEAN;
    v_conditions JSONB;
    v_result JSONB := '{"matches": []}';
    v_total_risk INT := 0;
    v_action TEXT := 'none';
BEGIN
    -- Get booking details
    SELECT * INTO v_booking FROM bookings WHERE booking_id = p_booking_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Booking not found');
    END IF;

    -- Get passenger details
    SELECT * INTO v_passenger FROM passengers WHERE passenger_id = v_booking.passenger_id;

    -- Get payment details
    SELECT * FROM payment_verifications
    WHERE booking_id = p_booking_id
    ORDER BY created_at DESC LIMIT 1
    INTO v_payment;

    -- Check against all active fraud patterns
    FOR v_pattern IN SELECT * FROM fraud_patterns WHERE is_active = TRUE
    LOOP
        v_matched := FALSE;
        v_conditions := v_pattern.pattern_conditions;

        -- Example condition checks (real implementation would be more sophisticated)
        IF v_conditions->>'high_value_last_minute' = 'true' THEN
            IF v_booking.total_amount > 1000 AND
               (v_booking.scheduled_departure - now()) < INTERVAL '24 hours' THEN
                v_matched := TRUE;
            END IF;
        END IF;

        IF v_conditions->>'unusual_ip_location' = 'true' THEN
            -- Check if IP country doesn't match passenger's country
            -- This would require additional data not shown in this example
            v_matched := TRUE; -- Simplified for example
        END IF;

        IF v_matched THEN
            -- Record the match
            v_result := jsonb_set(v_result, '{matches}',
                v_result->'matches' || jsonb_build_object(
                    'pattern_id', v_pattern.pattern_id,
                    'pattern_name', v_pattern.pattern_name,
                    'risk_score', v_pattern.risk_score
                ));

            v_total_risk := v_total_risk + v_pattern.risk_score;

            -- Determine most severe action needed
            IF v_pattern.mitigation_action = 'block' THEN
                v_action := 'block';
            ELSIF v_pattern.mitigation_action = 'hold' AND v_action != 'block' THEN
                v_action := 'hold';
            ELSIF v_pattern.mitigation_action = 'require_verification' AND
                  v_action NOT IN ('block', 'hold') THEN
                v_action := 'require_verification';
            ELSIF v_pattern.mitigation_action = 'flag' AND v_action = 'none' THEN
                v_action := 'flag';
            END IF;

            -- Log the fraud attempt
            INSERT INTO fraud_attempts (
                pattern_id,
                booking_id,
                passenger_id,
                matched_conditions,
                risk_score,
                action_taken,
                created_at
            ) VALUES (
                v_pattern.pattern_id,
                p_booking_id,
                v_booking.passenger_id,
                v_conditions,
                v_pattern.risk_score,
                v_pattern.mitigation_action,
                now()
            );
        END IF;
    END LOOP;

    -- Set overall result
    v_result := jsonb_set(v_result, '{total_risk_score}', to_jsonb(v_total_risk));
    v_result := jsonb_set(v_result, '{recommended_action}', to_jsonb(v_action));

    -- If in strict mode, automatically apply the recommended action
    IF p_strict_mode AND v_action != 'none' THEN
        PERFORM apply_fraud_action(p_booking_id, v_action);
        v_result := jsonb_set(v_result, '{action_applied}', to_jsonb(v_action));
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to apply fraud prevention actions
CREATE OR REPLACE FUNCTION apply_fraud_action(
    p_booking_id UUID,
    p_action TEXT
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    IF p_action = 'block' THEN
        -- Cancel the booking and block payment
        UPDATE bookings SET
            status = 'cancelled',
            payment_status = 'refunded',
            updated_at = now()
        WHERE booking_id = p_booking_id;

        -- Log the action
        INSERT INTO fraud_attempts (
            booking_id,
            matched_conditions,
            risk_score,
            action_taken,
            action_result,
            created_at
        ) VALUES (
            p_booking_id,
            jsonb_build_object('action', 'auto_block'),
            10, -- Highest risk
            'block',
            'booking_cancelled',
            now()
        );

        v_result := jsonb_build_object('status', 'success', 'action', 'block', 'result', 'booking_cancelled');

    ELSIF p_action = 'hold' THEN
        -- Put booking on hold
        UPDATE bookings SET
            status = 'pending',
            updated_at = now()
        WHERE booking_id = p_booking_id;

        -- Log the action
        INSERT INTO fraud_attempts (
            booking_id,
            matched_conditions,
            risk_score,
            action_taken,
            action_result,
            created_at
        ) VALUES (
            p_booking_id,
            jsonb_build_object('action', 'auto_hold'),
            7, -- Medium-high risk
            'hold',
            'booking_held',
            now()
        );

        v_result := jsonb_build_object('status', 'success', 'action', 'hold', 'result', 'booking_held');

    ELSIF p_action = 'require_verification' THEN
        -- Require additional verification
        INSERT INTO payment_verifications (
            booking_id,
            payment_method,
            verification_status,
            verification_method,
            verification_score,
            created_at
        ) VALUES (
            p_booking_id,
            (SELECT payment_method FROM bookings WHERE booking_id = p_booking_id),
            'pending',
            'manual',
            50, -- Medium risk
            now()
        );

        -- Log the action
        INSERT INTO fraud_attempts (
            booking_id,
            matched_conditions,
            risk_score,
            action_taken,
            action_result,
            created_at
        ) VALUES (
            p_booking_id,
            jsonb_build_object('action', 'require_verification'),
            5, -- Medium risk
            'require_verification',
            'verification_requested',
            now()
        );

        v_result := jsonb_build_object('status', 'success', 'action', 'require_verification', 'result', 'verification_requested');

    ELSE
        v_result := jsonb_build_object('status', 'error', 'message', 'Invalid action specified');
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify payment with 3D Secure
CREATE OR REPLACE FUNCTION verify_payment_3ds(
    p_booking_id UUID,
    p_verification_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_booking RECORD;
    v_result JSONB;
    v_score INT;
BEGIN
    -- Get booking details
    SELECT * INTO v_booking FROM bookings WHERE booking_id = p_booking_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Booking not found');
    END IF;

    -- Simulate 3DS verification (in real implementation, call payment processor API)
    -- This would check the verification data against the payment processor's response
    IF p_verification_data->>'status' = 'success' THEN
        v_score := 95; -- High confidence
    ELSIF p_verification_data->>'status' = 'challenge' THEN
        v_score := 70; -- Medium confidence
    ELSE
        v_score := 30; -- Low confidence
    END IF;

    -- Record verification result
    INSERT INTO payment_verifications (
        booking_id,
        payment_method,
        verification_status,
        verification_method,
        verification_data,
        verification_score,
        verified_at,
        created_at
    ) VALUES (
        p_booking_id,
        v_booking.payment_method,
        CASE WHEN v_score > 80 THEN 'verified' ELSE 'suspicious' END,
        '3ds',
        p_verification_data,
        v_score,
        now(),
        now()
    );

    -- Update booking status if verified
    IF v_score > 80 THEN
        UPDATE bookings SET
            payment_status = 'paid',
            updated_at = now()
        WHERE booking_id = p_booking_id;

        v_result := jsonb_build_object(
            'status', 'success',
            'verification_result', 'verified',
            'score', v_score
        );
    ELSE
        -- Flag for manual review
        PERFORM check_booking_fraud(p_booking_id, TRUE);

        v_result := jsonb_build_object(
            'status', 'review',
            'verification_result', 'requires_review',
            'score', v_score
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check device reputation
CREATE OR REPLACE FUNCTION check_device_reputation(
    p_passenger_id UUID,
    p_device_hash TEXT,
    p_user_agent TEXT,
    p_ip_address INET
) RETURNS JSONB AS $$
DECLARE
    v_device RECORD;
    v_ip_reputation RECORD;
    v_trust_score INT := 100; -- Start with perfect score
    v_result JSONB;
BEGIN
    -- Check if device is known
    SELECT * INTO v_device FROM device_fingerprints
    WHERE device_hash = p_device_hash AND passenger_id = p_passenger_id;

    -- Check IP reputation
    SELECT * INTO v_ip_reputation FROM ip_reputation
    WHERE ip_address = p_ip_address;

    -- Adjust trust score based on factors
    IF v_device IS NULL THEN
        -- New device, slightly reduce score
        v_trust_score := v_trust_score - 10;
    END IF;

    IF v_ip_reputation IS NOT NULL THEN
        -- Adjust based on IP reputation
        v_trust_score := v_trust_score - (100 - v_ip_reputation.reputation_score);

        -- Penalize for known bad IP types
        IF v_ip_reputation.is_vpn THEN v_trust_score := v_trust_score - 15; END IF;
        IF v_ip_reputation.is_proxy THEN v_trust_score := v_trust_score - 20; END IF;
        IF v_ip_reputation.is_tor THEN v_trust_score := v_trust_score - 30; END IF;
    END IF;

    -- Ensure score is within bounds
    v_trust_score := GREATEST(0, LEAST(100, v_trust_score));

    -- Return result with recommendations
    v_result := jsonb_build_object(
        'trust_score', v_trust_score,
        'recommend_mfa', CASE WHEN v_trust_score < 70 THEN TRUE ELSE FALSE END,
        'ip_reputation', CASE
            WHEN v_ip_reputation IS NULL THEN 'unknown'
            WHEN v_ip_reputation.reputation_score > 80 THEN 'good'
            WHEN v_ip_reputation.reputation_score > 50 THEN 'neutral'
            ELSE 'poor'
        END,
        'device_status', CASE
            WHEN v_device IS NULL THEN 'new_device'
            WHEN v_device.is_trusted THEN 'trusted'
            ELSE 'known_device'
        END
    );

    -- Update or create device fingerprint
    IF v_device IS NULL THEN
        INSERT INTO device_fingerprints (
            passenger_id,
            device_hash,
            user_agent,
            ip_address,
            first_seen,
            last_seen
        ) VALUES (
            p_passenger_id,
            p_device_hash,
            p_user_agent,
            p_ip_address,
            now(),
            now()
        );
    ELSE
        UPDATE device_fingerprints SET
            last_seen = now(),
            ip_address = p_ip_address
        WHERE fingerprint_id = v_device.fingerprint_id;
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to enforce MFA based on risk
CREATE OR REPLACE FUNCTION enforce_mfa(
    p_passenger_id UUID,
    p_action TEXT, -- 'login', 'booking', 'payment'
    p_device_hash TEXT,
    p_ip_address INET
) RETURNS JSONB AS $$
DECLARE
    v_account RECORD;
    v_device_check JSONB;
    v_requires_mfa BOOLEAN := FALSE;
    v_reason TEXT;
BEGIN
    -- Get account security info
    SELECT * INTO v_account FROM account_security
    WHERE passenger_id = p_passenger_id;

    -- Check device reputation
    v_device_check := check_device_reputation(p_passenger_id, p_device_hash, NULL, p_ip_address);

    -- Determine if MFA is required
    IF v_account.account_locked AND v_account.locked_until > now() THEN
        v_requires_mfa := TRUE;
        v_reason := 'account_locked';
    ELSIF v_account.failed_login_attempts >= 3 THEN
        v_requires_mfa := TRUE;
        v_reason := 'failed_attempts';
    ELSIF (v_device_check->>'trust_score')::INT < 70 THEN
        v_requires_mfa := TRUE;
        v_reason := 'device_reputation';
    ELSIF p_action = 'payment' AND (v_device_check->>'trust_score')::INT < 80 THEN
        v_requires_mfa := TRUE;
        v_reason := 'high_risk_action';
    ELSIF p_action = 'booking' AND (v_device_check->>'ip_reputation')::TEXT = 'poor' THEN
        v_requires_mfa := TRUE;
        v_reason := 'poor_ip_reputation';
    END IF;

    RETURN jsonb_build_object(
        'requires_mfa', v_requires_mfa,
        'reason', CASE WHEN v_requires_mfa THEN v_reason ELSE NULL END,
        'current_device', v_device_check
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------------------
-- SCAM PREVENTION TRIGGERS
--------------------------------------------------------------------------------

-- Trigger to check for fraud on booking creation
CREATE OR REPLACE FUNCTION check_new_booking_fraud() RETURNS TRIGGER AS $$
DECLARE
    v_fraud_check JSONB;
BEGIN
    -- Perform fraud check
    v_fraud_check := check_booking_fraud(NEW.booking_id, TRUE);

    -- If high risk, prevent booking confirmation
    IF (v_fraud_check->>'recommended_action')::TEXT IN ('block', 'hold') THEN
        NEW.status := 'pending';
        NEW.payment_status := 'unpaid';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_new_booking_fraud
    BEFORE INSERT ON bookings
    FOR EACH ROW EXECUTE FUNCTION check_new_booking_fraud();

-- Trigger to log failed login attempts
CREATE OR REPLACE FUNCTION log_failed_login() RETURNS TRIGGER AS $$
BEGIN
    -- Increment failed attempts counter
    UPDATE account_security SET
        failed_login_attempts = failed_login_attempts + 1,
        last_failed_login = now(),
        updated_at = now()
    WHERE passenger_id = NEW.passenger_id;

    -- Lock account after 5 failed attempts
    UPDATE account_security SET
        account_locked = TRUE,
        locked_until = now() + INTERVAL '1 hour',
        updated_at = now()
    WHERE passenger_id = NEW.passenger_id
    AND failed_login_attempts >= 5;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_failed_login
    AFTER UPDATE OF status ON passengers
    WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'login_failed')
    FOR EACH ROW EXECUTE FUNCTION log_failed_login();

--------------------------------------------------------------------------------
-- INITIAL FRAUD PATTERNS
--------------------------------------------------------------------------------

-- Common fraud patterns
INSERT INTO fraud_patterns (
    pattern_name,
    pattern_description,
    pattern_conditions,
    risk_score,
    mitigation_action,
    is_active
) VALUES
('High Value Last Minute Booking', 'Expensive bookings made shortly before departure',
 '{"high_value_last_minute": "true"}', 8, 'require_verification', TRUE),
('Unusual IP Location', 'Booking from IP address not matching passenger''s country',
 '{"unusual_ip_location": "true"}', 6, 'flag', TRUE),
('Multiple Failed Payments', 'Multiple failed payment attempts before success',
 '{"multiple_failed_payments": "true"}', 7, 'hold', TRUE),
('New Device High Value', 'High value booking from unrecognized device',
 '{"new_device_high_value": "true"}', 7, 'require_verification', TRUE),
('Billing Shipping Mismatch', 'Billing and shipping addresses in different countries',
 '{"billing_shipping_mismatch": "true"}', 5, 'flag', TRUE),
('Rapid Account Creation', 'New account making immediate high value booking',
 '{"rapid_account_creation": "true"}', 8, 'hold', TRUE);

--------------------------------------------------------------------------------
-- SECURITY INDEXES
--------------------------------------------------------------------------------

-- Create indexes for fraud detection performance
CREATE INDEX idx_fraud_attempts_booking ON fraud_attempts(booking_id);
CREATE INDEX idx_fraud_attempts_passenger ON fraud_attempts(passenger_id);
CREATE INDEX idx_fraud_attempts_created ON fraud_attempts(created_at);
CREATE INDEX idx_payment_verification_status ON payment_verifications(verification_status);
CREATE INDEX idx_device_fingerprint_hash ON device_fingerprints(device_hash);
CREATE INDEX idx_ip_reputation_score ON ip_reputation(reputation_score);
