--#Blockchain based Opine Draft
--# β ORI Inc. April 2025 Awase Khirni Syed 
--Postgresql work in progress

-- ENUMS / CONSTANTS
CREATE TYPE user_role AS ENUM ('user', 'moderator', 'admin');
CREATE TYPE post_type_enum AS ENUM (
    'standard', 'announcement', 'question', 'poll', 'image',
    'link', 'article', 'media', 'document'
);
CREATE TYPE consent_type_enum AS ENUM ('data_processing', 'email_notifications', 'marketing');
CREATE TYPE issue_type_enum AS ENUM ('missing_fields', 'invalid_format', 'spam', 'abuse', 'other');
CREATE TYPE access_type_enum AS ENUM ('export', 'view');
CREATE TYPE reputation_change_reason AS ENUM (
    'post_upvote', 'post_downvote',
    'comment_upvote', 'comment_downvote',
    'answer_accepted', 'answer_upvote',
    'reward', 'penalty', 'achievement',
    'helpful_flag', 'rejected_flag'
);
CREATE TYPE content_type_enum AS ENUM ('post', 'comment', 'message');
CREATE TYPE relation_type_enum AS ENUM (
    'duplicate', 'translation', 'followup',
    'reference', 'collection', 'series'
);
CREATE TYPE achievement_type_enum AS ENUM (
    'contributor', 'expert', 'helper',
    'curator', 'popular', 'quality',
    'trusted_flagger', 'community_guardian'
);
CREATE TYPE community_type_enum AS ENUM (
    'standard', 'federated', 'qa', 'image_board',
    'blockchain', 'chat_based', 'microblog',
    'special_interest', 'anonymous', 'document_collaboration'
);
CREATE TYPE federation_protocol_enum AS ENUM ('activitypub', 'matrix', 'diaspora', 'none');
CREATE TYPE moderation_tag_category_enum AS ENUM (
    'spam', 'misinformation', 'harassment', 'hate_speech',
    'nudity', 'violence', 'copyright', 'privacy_violation',
    'off_topic', 'low_quality', 'duplicate', 'rule_violation'
);
CREATE TYPE moderation_tag_severity_enum AS ENUM ('minor', 'moderate', 'severe', 'critical');
CREATE TYPE schedule_status_enum AS ENUM ('draft', 'scheduled', 'published', 'canceled');
CREATE TYPE flag_status_enum AS ENUM ('pending', 'approved', 'rejected', 'disputed');
CREATE TYPE gdpr_request_type AS ENUM (
    'access_request', 'erasure_request', 'rectification_request',
    'restriction_request', 'data_portability', 'objection'
);
CREATE TYPE audit_event_type AS ENUM (
    'content_moderation', 'user_action', 'system_event',
    'data_access', 'configuration_change', 'security_event'
);
CREATE TYPE data_quality_status AS ENUM (
    'valid', 'invalid', 'incomplete', 'inconsistent', 'duplicate', 'outdated'
);
CREATE TYPE analytics_scope AS ENUM (
    'community_health', 'user_behavior', 'content_trends',
    'moderation_efficiency', 'system_performance', 'business_metrics'
);
CREATE TYPE moderation_escalation_level AS ENUM ('community', 'platform', 'legal', 'law_enforcement');

-- CORE TABLES

-- USERS
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    reputation INTEGER NOT NULL DEFAULT 0 CHECK (reputation >= 0),
    bio TEXT,
    interests TEXT[],
    profile_privacy JSONB DEFAULT '{"public": true}'::JSONB,
    reputation_decay FLOAT DEFAULT 0.01 CHECK (reputation_decay >= 0 AND reputation_decay <= 1),
    last_reputation_decay TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    country_code VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    is_anonymized BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    federated_id TEXT,
    home_instance_url TEXT,
    federation_metadata JSONB,
    flagging_reputation INTEGER DEFAULT 0,
    flags_helpful INTEGER DEFAULT 0,
    flags_rejected INTEGER DEFAULT 0,
    flags_disputed INTEGER DEFAULT 0,
    content_visibility_level VARCHAR(20) DEFAULT 'normal' CHECK (content_visibility_level IN ('normal', 'reduced', 'probation', 'restricted')),
    achievement_score INTEGER DEFAULT 0,
    last_achievement_at TIMESTAMP WITH TIME ZONE,
    content_edit_count INTEGER DEFAULT 0,
    accepted_answer_count INTEGER DEFAULT 0
) PARTITION BY RANGE (created_at);

CREATE TABLE users_y2025 PARTITION OF users FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_geo ON users(country_code, region, city);
CREATE INDEX idx_users_reputation ON users(reputation) WHERE is_deleted = FALSE;
CREATE INDEX idx_users_federated_id ON users(federated_id) WHERE federated_id IS NOT NULL;
CREATE INDEX idx_users_flagging_reputation ON users(flagging_reputation);
CREATE INDEX idx_users_content_visibility ON users(content_visibility_level) WHERE content_visibility_level != 'normal';
CREATE INDEX idx_users_achievement_score ON users(achievement_score) WHERE is_deleted = FALSE;

-- REPUTATION CHANGES
CREATE TABLE reputation_changes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    change_amount INTEGER NOT NULL,
    reason reputation_change_reason NOT NULL,
    content_type content_type_enum,
    content_id INTEGER,
    community_id INTEGER REFERENCES communities(id) ON DELETE SET NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (calculated_at);

CREATE TABLE reputation_changes_y2025 PARTITION OF reputation_changes FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- USER ACHIEVEMENTS
CREATE TABLE user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    achievement_type achievement_type_enum NOT NULL,
    achievement_level SMALLINT NOT NULL DEFAULT 1,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- COMMUNITIES
CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    community_type community_type_enum NOT NULL DEFAULT 'standard',
    federation_protocol federation_protocol_enum NOT NULL DEFAULT 'none',
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    is_nsfw BOOLEAN NOT NULL DEFAULT FALSE,
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    flag_threshold INTEGER DEFAULT 3,
    auto_hide_threshold INTEGER DEFAULT 5,
    require_flag_reason BOOLEAN DEFAULT TRUE,
    flag_decay_rate FLOAT DEFAULT 0.1 CHECK (flag_decay_rate >= 0 AND flag_decay_rate <= 1),
    last_flag_decay TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_communities_slug ON communities(slug);
CREATE INDEX idx_communities_type ON communities(community_type);
CREATE INDEX idx_communities_public ON communities(is_public) WHERE is_public = TRUE;

-- CONTENT BASE
CREATE TABLE content_base (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    original_id INTEGER NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    body TEXT NOT NULL CHECK (length(body) > 0),
    metadata JSONB,
    language VARCHAR(10) DEFAULT 'en',
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    score INTEGER NOT NULL DEFAULT 0,
    country_code VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tsv tsvector,
    flag_count INTEGER DEFAULT 0,
    is_auto_hidden BOOLEAN DEFAULT FALSE,
    last_flag_at TIMESTAMP WITH TIME ZONE,
    current_version INTEGER DEFAULT 1,
    is_federated BOOLEAN DEFAULT FALSE,
    federated_id TEXT,
    federated_origin TEXT
) PARTITION BY RANGE (created_at);

CREATE TABLE content_base_y2025 PARTITION OF content_base FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_content_base_type ON content_base(content_type, original_id);
CREATE INDEX idx_content_base_user ON content_base(user_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_content_base_geo ON content_base(country_code, region, city);
CREATE INDEX idx_content_base_tsv ON content_base USING GIN(tsv);
CREATE INDEX idx_content_base_score ON content_base(score DESC) WHERE is_deleted = FALSE;
CREATE INDEX idx_content_base_created ON content_base(created_at DESC) WHERE is_deleted = FALSE;
CREATE INDEX idx_content_base_flags ON content_base(flag_count) WHERE is_deleted = FALSE;
CREATE INDEX idx_content_base_auto_hidden ON content_base(is_auto_hidden) WHERE is_auto_hidden = TRUE;

-- CONTENT VERSIONS
CREATE TABLE content_versions (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    version_number INTEGER NOT NULL,
    body TEXT NOT NULL,
    edited_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    edit_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (content_type, content_id, version_number)
);

CREATE INDEX idx_content_versions_content ON content_versions(content_type, content_id);
CREATE INDEX idx_content_versions_user ON content_versions(edited_by_user_id);
CREATE INDEX idx_content_versions_created ON content_versions(created_at DESC);

-- POSTS
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    content_base_id INTEGER NOT NULL REFERENCES content_base(id) ON DELETE CASCADE,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (length(title) > 0),
    post_type post_type_enum DEFAULT 'standard',
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    is_ephemeral BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE,
    visible_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    visible_until TIMESTAMP WITH TIME ZONE,
    view_count INTEGER NOT NULL DEFAULT 0,
    is_question BOOLEAN DEFAULT FALSE,
    has_accepted_answer BOOLEAN DEFAULT FALSE,
    accepted_answer_id INTEGER,
    blockchain_transaction_id TEXT,
    blockchain_metadata JSONB,
    is_thread BOOLEAN DEFAULT FALSE,
    thread_position INTEGER,
    thread_bump_count INTEGER DEFAULT 0,
    thread_last_bump_at TIMESTAMP WITH TIME ZONE,
    schedule_status schedule_status_enum DEFAULT 'published',
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    is_part_of_series BOOLEAN DEFAULT FALSE,
    series_position INTEGER,
    CONSTRAINT valid_visibility_window CHECK (
        visible_until IS NULL OR visible_from IS NULL OR visible_until > visible_from
    ),
    CONSTRAINT valid_expiration CHECK (
        expires_at IS NULL OR expires_at > created_at
    ),
    CONSTRAINT valid_schedule CHECK (
        (schedule_status != 'scheduled' OR scheduled_publish_at IS NOT NULL) AND
        (schedule_status != 'published' OR scheduled_publish_at IS NULL OR scheduled_publish_at <= NOW())
    )
) PARTITION BY RANGE (created_at);

CREATE TABLE posts_y2025 PARTITION OF posts FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_posts_community ON posts(community_id);
CREATE INDEX idx_posts_content_base ON posts(content_base_id);
CREATE INDEX idx_posts_question ON posts(is_question, has_accepted_answer) WHERE is_question = TRUE;
CREATE INDEX idx_posts_thread ON posts(is_thread, thread_last_bump_at) WHERE is_thread = TRUE;
CREATE INDEX idx_posts_schedule ON posts(schedule_status, scheduled_publish_at) WHERE schedule_status = 'scheduled';
CREATE INDEX idx_posts_series ON posts(is_part_of_series, series_position) WHERE is_part_of_series = TRUE;

-- COMMENTS
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    content_base_id INTEGER NOT NULL REFERENCES content_base(id) ON DELETE CASCADE,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
    is_answer BOOLEAN DEFAULT FALSE,
    is_accepted_answer BOOLEAN DEFAULT FALSE,
    image_attachment JSONB
) PARTITION BY RANGE (created_at);

CREATE TABLE comments_y2025 PARTITION OF comments FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_content_base ON comments(content_base_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_comments_answer ON comments(is_answer, is_accepted_answer) WHERE is_answer = TRUE;

-- MODERATION TAGS
CREATE TABLE moderation_tags (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category moderation_tag_category_enum NOT NULL,
    severity moderation_tag_severity_enum NOT NULL DEFAULT 'moderate',
    community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
    is_global BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (name, community_id)
);

CREATE INDEX idx_moderation_tags_category ON moderation_tags(category);
CREATE INDEX idx_moderation_tags_severity ON moderation_tags(severity);
CREATE INDEX idx_moderation_tags_community ON moderation_tags(community_id) WHERE community_id IS NOT NULL;
CREATE INDEX idx_moderation_tags_global ON moderation_tags(is_global) WHERE is_global = TRUE;

-- CONTENT FLAGS
CREATE TABLE content_flags (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL REFERENCES moderation_tags(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    status flag_status_enum DEFAULT 'pending',
    reason TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (content_type, content_id, tag_id, user_id)
) PARTITION BY RANGE (created_at);

CREATE TABLE content_flags_y2025 PARTITION OF content_flags FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_content_flags_content ON content_flags(content_type, content_id);
CREATE INDEX idx_content_flags_tag ON content_flags(tag_id);
CREATE INDEX idx_content_flags_user ON content_flags(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_content_flags_community ON content_flags(community_id);
CREATE INDEX idx_content_flags_status ON content_flags(status) WHERE status = 'pending';
CREATE INDEX idx_content_flags_created ON content_flags(created_at DESC);

-- FLAG CONSENSUS
CREATE TABLE flag_consensus (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL REFERENCES moderation_tags(id) ON DELETE CASCADE,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    flag_count INTEGER NOT NULL DEFAULT 0,
    unique_flaggers INTEGER NOT NULL DEFAULT 0,
    last_flag_at TIMESTAMP WITH TIME ZONE,
    action_taken TEXT,
    action_taken_at TIMESTAMP WITH TIME ZONE,
    action_taken_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (content_type, content_id, tag_id, community_id)
);

CREATE INDEX idx_flag_consensus_content ON flag_consensus(content_type, content_id);
CREATE INDEX idx_flag_consensus_tag ON flag_consensus(tag_id);
CREATE INDEX idx_flag_consensus_community ON flag_consensus(community_id);
CREATE INDEX idx_flag_consensus_count ON flag_consensus(flag_count DESC);
CREATE INDEX idx_flag_consensus_action ON flag_consensus(action_taken) WHERE action_taken IS NOT NULL;

-- FLAG REVIEWS
CREATE TABLE flag_reviews (
    id SERIAL PRIMARY KEY,
    flag_id INTEGER NOT NULL REFERENCES content_flags(id) ON DELETE CASCADE,
    reviewer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    decision flag_status_enum NOT NULL,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_flag_reviews_flag ON flag_reviews(flag_id);
CREATE INDEX idx_flag_reviews_reviewer ON flag_reviews(reviewer_id);
CREATE INDEX idx_flag_reviews_decision ON flag_reviews(decision);

-- COMMUNITY MODERATION RULES
CREATE TABLE community_moderation_rules (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES moderation_tags(id) ON DELETE CASCADE,
    category moderation_tag_category_enum,
    severity moderation_tag_severity_enum,
    action_threshold INTEGER NOT NULL DEFAULT 3,
    action_type TEXT NOT NULL,
    action_metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (tag_id IS NOT NULL OR category IS NOT NULL)
);

CREATE INDEX idx_community_mod_rules_community ON community_moderation_rules(community_id);
CREATE INDEX idx_community_mod_rules_tag ON community_moderation_rules(tag_id) WHERE tag_id IS NOT NULL;
CREATE INDEX idx_community_mod_rules_category ON community_moderation_rules(category) WHERE category IS NOT NULL;
CREATE INDEX idx_community_mod_rules_active ON community_moderation_rules(is_active) WHERE is_active = TRUE;

-- GDPR REQUESTS
CREATE TABLE gdpr_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    request_type gdpr_request_type NOT NULL,
    request_details JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    completed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    verification_data JSONB,
    notes TEXT,
    anonymization_applied BOOLEAN DEFAULT FALSE,
    anonymization_details JSONB,
    export_format TEXT,
    export_storage_path TEXT
) PARTITION BY RANGE (requested_at);

CREATE TABLE gdpr_requests_y2025 PARTITION OF gdpr_requests FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_gdpr_requests_user ON gdpr_requests(user_id);
CREATE INDEX idx_gdpr_requests_type ON gdpr_requests(request_type);
CREATE INDEX idx_gdpr_requests_status ON gdpr_requests(status) WHERE status = 'pending';

-- DATA PROCESSING ACTIVITIES
CREATE TABLE data_processing_activities (
    id SERIAL PRIMARY KEY,
    processing_activity TEXT NOT NULL,
    description TEXT NOT NULL,
    purpose TEXT NOT NULL,
    categories_of_data TEXT[] NOT NULL,
    categories_of_subjects TEXT[] NOT NULL,
    recipients TEXT[],
    retention_period TEXT NOT NULL,
    lawful_basis TEXT NOT NULL,
    international_transfers BOOLEAN DEFAULT FALSE,
    transfer_mechanism TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_protection_impact_assessment BOOLEAN DEFAULT FALSE,
    dpia_reference TEXT
);

CREATE INDEX idx_data_processing_activities_scope ON data_processing_activities(processing_activity);

-- DPA IMPACT ASSESSMENTS
CREATE TABLE dpia_records (
    id SERIAL PRIMARY KEY,
    processing_activity_id INTEGER REFERENCES data_processing_activities(id) ON DELETE CASCADE,
    conducted_at TIMESTAMP WITH TIME ZONE NOT NULL,
    conducted_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    risks_identified JSONB NOT NULL,
    mitigation_measures JSONB NOT NULL,
    residual_risk TEXT NOT NULL CHECK (residual_risk IN ('low', 'medium', 'high')),
    approval_status TEXT NOT NULL DEFAULT 'draft' CHECK (approval_status IN ('draft', 'approved', 'rejected')),
    approved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    review_schedule TEXT NOT NULL
);

-- AUDIT LOG
--SOC2 secutity and compliance monitoring
-- ISO27001 Logging  support
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    event_type audit_event_type NOT NULL,
    event_subtype TEXT,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    ip_address INET,
    user_agent TEXT,
    event_data JSONB NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    moderation_action_id INTEGER,
    content_type content_type_enum,
    content_id INTEGER,
    community_id INTEGER REFERENCES communities(id) ON DELETE SET NULL,
    data_subject_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    access_type TEXT,
    cryptographic_hash TEXT NOT NULL,
    blockchain_tx_id TEXT
) PARTITION BY RANGE (recorded_at);

CREATE TABLE audit_log_y2025 PARTITION OF audit_log FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);
CREATE INDEX idx_audit_log_user ON audit_log(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_log_content ON audit_log(content_type, content_id) WHERE content_type IS NOT NULL;
CREATE INDEX idx_audit_log_community ON audit_log(community_id) WHERE community_id IS NOT NULL;
CREATE INDEX idx_audit_log_timestamp ON audit_log(recorded_at DESC);

-- DATA QUALITY RULES
CREATE TABLE data_quality_rules (
    id SERIAL PRIMARY KEY,
    rule_name TEXT NOT NULL,
    description TEXT NOT NULL,
    scope TEXT NOT NULL CHECK (scope IN ('user', 'content', 'moderation', 'system')),
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    validation_query TEXT NOT NULL,
    error_message TEXT NOT NULL,
    remediation_action TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- DATA QUALITY ISSUES
CREATE TABLE data_quality_issues (
    id SERIAL PRIMARY KEY,
    rule_id INTEGER REFERENCES data_quality_rules(id) ON DELETE CASCADE,
    status data_quality_status NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id INTEGER NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    automatic_resolution BOOLEAN DEFAULT FALSE
) PARTITION BY RANGE (detected_at);

CREATE TABLE data_quality_issues_y2025 PARTITION OF data_quality_issues FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_data_quality_issues_rule ON data_quality_issues(rule_id);
CREATE INDEX idx_data_quality_issues_entity ON data_quality_issues(entity_type, entity_id);
CREATE INDEX idx_data_quality_issues_status ON data_quality_issues(status) WHERE status != 'valid';

-- DATA LINEAGE
CREATE TABLE data_lineage (
    id SERIAL PRIMARY KEY,
    source_entity TEXT NOT NULL,
    source_id INTEGER NOT NULL,
    destination_entity TEXT NOT NULL,
    destination_id INTEGER NOT NULL,
    transformation_description TEXT,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_by TEXT,
    business_justification TEXT,
    retention_period TEXT
);

CREATE INDEX idx_data_lineage_source ON data_lineage(source_entity, source_id);
CREATE INDEX idx_data_lineage_destination ON data_lineage(destination_entity, destination_id);

-- ANALYTICS DATASETS
CREATE TABLE analytics_datasets (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    scope analytics_scope NOT NULL,
    refresh_schedule TEXT NOT NULL,
    data_retention_period TEXT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    is_community_visible BOOLEAN DEFAULT FALSE,
    community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_refreshed_at TIMESTAMP WITH TIME ZONE,
    data_quality_score INTEGER CHECK (data_quality_score BETWEEN 0 AND 100),
    UNIQUE (name, community_id)
);

-- DATASET VERSIONS
CREATE TABLE analytics_dataset_versions (
    id SERIAL PRIMARY KEY,
    dataset_id INTEGER NOT NULL REFERENCES analytics_datasets(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    data_schema JSONB NOT NULL,
    sample_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (dataset_id, version_number)
);

-- DATASET ACCESS LOG
CREATE TABLE analytics_access_log (
    id SERIAL PRIMARY KEY,
    dataset_id INTEGER NOT NULL REFERENCES analytics_datasets(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_purpose TEXT,
    filters_applied JSONB,
    rows_returned INTEGER,
    api_key_used TEXT,
    ip_address INET
) PARTITION BY RANGE (accessed_at);

CREATE TABLE analytics_access_log_y2025 PARTITION OF analytics_access_log FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- MODERATION ESCALATIONS
CREATE TABLE moderation_escalations (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    original_flag_id INTEGER REFERENCES content_flags(id) ON DELETE SET NULL,
    escalation_level moderation_escalation_level NOT NULL,
    reason TEXT NOT NULL,
    escalated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    escalated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'action_taken', 'dismissed')),
    reviewed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    action_taken TEXT,
    action_taken_at TIMESTAMP WITH TIME ZONE,
    external_reference TEXT
);

CREATE INDEX idx_moderation_escalations_content ON moderation_escalations(content_type, content_id);
CREATE INDEX idx_moderation_escalations_level ON moderation_escalations(escalation_level);
CREATE INDEX idx_moderation_escalations_status ON moderation_escalations(status) WHERE status = 'pending';

-- MODERATION COMMITTEES
CREATE TABLE community_moderation_committees (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    formation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    dissolution_date TIMESTAMP WITH TIME ZONE,
    governance_document TEXT,
    UNIQUE (community_id, name)
);

-- COMMITTEE MEMBERS
CREATE TABLE committee_members (
    id SERIAL PRIMARY KEY,
    committee_id INTEGER NOT NULL REFERENCES community_moderation_committees(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    join_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    leave_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    voting_weight INTEGER DEFAULT 1 CHECK (voting_weight >= 0),
    UNIQUE (committee_id, user_id)
);

-- MODERATION CONSENSUS ROUNDS
CREATE TABLE moderation_consensus_rounds (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    committee_id INTEGER REFERENCES community_moderation_committees(id) ON DELETE SET NULL,
    initiated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conclusion_reached_at TIMESTAMP WITH TIME ZONE,
    decision TEXT,
    decision_notes TEXT,
    required_quorum INTEGER NOT NULL DEFAULT 3,
    votes_received INTEGER NOT NULL DEFAULT 0,
    UNIQUE (content_type, content_id, committee_id) WHERE committee_id IS NOT NULL
);

-- COMMITTEE VOTES
CREATE TABLE committee_votes (
    id SERIAL PRIMARY KEY,
    round_id INTEGER NOT NULL REFERENCES moderation_consensus_rounds(id) ON DELETE CASCADE,
    member_id INTEGER NOT NULL REFERENCES committee_members(id) ON DELETE CASCADE,
    vote TEXT NOT NULL,
    vote_reason TEXT,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_public BOOLEAN DEFAULT FALSE,
    UNIQUE (round_id, member_id)
);

-- REPUTATION AUDITS
CREATE TABLE reputation_audits (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    change_amount INTEGER NOT NULL,
    reason reputation_change_reason NOT NULL,
    content_type content_type_enum,
    content_id INTEGER,
    community_id INTEGER REFERENCES communities(id) ON DELETE SET NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calculated_by TEXT DEFAULT 'system',
    audit_hash TEXT NOT NULL,
    blockchain_tx_id TEXT
) PARTITION BY RANGE (calculated_at);

CREATE TABLE reputation_audits_y2025 PARTITION OF reputation_audits FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- TRIGGERS AND FUNCTIONS

-- Insert into content_base before inserting into posts/comments
CREATE OR REPLACE FUNCTION insert_content_base()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO content_base (
        content_type, original_id, user_id, body, metadata,
        language, is_deleted, score, country_code, region, city,
        created_at, updated_at, tsv, is_federated, federated_id, federated_origin
    ) VALUES (
        TG_ARGV[0], NEW.id, NEW.user_id, NEW.body, NEW.metadata,
        NEW.language, NEW.is_deleted, NEW.score, NEW.country_code, NEW.region, NEW.city,
        NEW.created_at, NEW.updated_at, NEW.tsv, NEW.is_federated, NEW.federated_id, NEW.federated_origin
    ) RETURNING id INTO NEW.content_base_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_post_content_base
BEFORE INSERT ON posts
FOR EACH ROW EXECUTE FUNCTION insert_content_base('post');

CREATE TRIGGER insert_comment_content_base
BEFORE INSERT ON comments
FOR EACH ROW EXECUTE FUNCTION insert_content_base('comment');

-- Update content versions when posts/comments are edited
CREATE OR REPLACE FUNCTION update_content_version()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.body <> OLD.body THEN
        INSERT INTO content_versions (
            content_type, content_id, version_number, body,
            edited_by_user_id, edit_reason
        ) VALUES (
            (SELECT content_type FROM content_base WHERE id = NEW.content_base_id),
            NEW.id,
            NEW.current_version,
            OLD.body,
            NEW.user_id,
            NEW.edit_reason
        );
        NEW.current_version = NEW.current_version + 1;
        NEW.updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_post_version
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_content_version();

CREATE TRIGGER update_comment_version
BEFORE UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION update_content_version();

-- Additional triggers follow similar structure...
-- Function to auto-update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to key tables
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_communities_updated_at
BEFORE UPDATE ON communities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
BEFORE UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_moderation_tags_updated_at
BEFORE UPDATE ON moderation_tags
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


----
-- Function to generate tsvector from body
CREATE OR REPLACE FUNCTION update_tsv()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR OLD.body IS DISTINCT FROM NEW.body THEN
        NEW.tsv := to_tsvector('simple', COALESCE(NEW.body, ''));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to content_base
CREATE TRIGGER content_base_tsv_update
BEFORE INSERT OR UPDATE OF body ON content_base
FOR EACH ROW EXECUTE FUNCTION update_tsv();


-- Function to prevent modification of deleted content
CREATE OR REPLACE FUNCTION prevent_deleted_content_modification()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_deleted THEN
        RAISE EXCEPTION 'Cannot modify deleted content';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to posts/comments
CREATE TRIGGER prevent_deleted_post_modification
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION prevent_deleted_content_modification();

CREATE TRIGGER prevent_deleted_comment_modification
BEFORE UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION prevent_deleted_content_modification();


INSERT INTO content_base (
    content_type, original_id, user_id, body, metadata,
    language, is_deleted, score, country_code, region, city,
    created_at, updated_at, tsv, is_federated, federated_id
) VALUES
('comment', 2001, 2, 'Great post!', '{}', 'en', FALSE, 0, 'GB', 'ENG', 'London',
NOW(), NOW(), to_tsvector('great post'), FALSE, NULL);

INSERT INTO comments (
    id, content_base_id, post_id, parent_comment_id, is_answer
) VALUES
(2001, 2, 1001, NULL, FALSE);


CREATE VIEW top_users_by_reputation AS
SELECT id, username, reputation, role
FROM users
WHERE is_deleted = FALSE AND is_anonymized = FALSE
ORDER BY reputation DESC
LIMIT 10;


CREATE VIEW most_flagged_content AS
SELECT cb.id, cb.content_type, cb.body, cb.flag_count, c.title
FROM content_base cb
LEFT JOIN posts p ON cb.content_type = 'post' AND cb.original_id = p.id
WHERE cb.flag_count > 0
ORDER BY cb.flag_count DESC
LIMIT 20;



CREATE VIEW moderation_queue AS
SELECT cf.id, cf.content_type, cf.content_id, cf.reason, mt.name AS tag_name, u.username AS flagger
FROM content_flags cf
JOIN moderation_tags mt ON cf.tag_id = mt.id
LEFT JOIN users u ON cf.user_id = u.id
WHERE cf.status = 'pending'
ORDER BY cf.created_at DESC;


CREATE MATERIALIZED VIEW community_activity_summary AS
SELECT
    c.id AS community_id,
    c.name,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT cm.id) AS total_comments,
    SUM(cb.score) AS total_upvotes,
    SUM(cb.flag_count) AS total_flags,
    MAX(p.created_at) AS latest_post_time,
    MAX(cm.created_at) AS latest_comment_time
FROM communities c
LEFT JOIN posts p ON p.community_id = c.id
LEFT JOIN comments cm ON cm.post_id = p.id
LEFT JOIN content_base cb ON cb.content_type IN ('post', 'comment') AND cb.original_id IN (p.id, cm.id)
GROUP BY c.id, c.name;



REFRESH MATERIALIZED VIEW community_activity_summary;


CREATE OR REPLACE PROCEDURE submit_gdpr_erasure_request(
    IN user_id INTEGER,
    OUT request_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO gdpr_requests (
        user_id, request_type, status, requested_at
    ) VALUES (
        user_id, 'erasure_request', 'pending', NOW()
    ) RETURNING id INTO request_id;
END;
$$;


CREATE OR REPLACE PROCEDURE award_achievement(
    IN user_id INTEGER,
    IN achievement_type achievement_type_enum,
    IN achievement_level SMALLINT DEFAULT 1
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO user_achievements (
        user_id, achievement_type, achievement_level
    ) VALUES (
        user_id, achievement_type, achievement_level
    );

    -- Update user's achievement score
    UPDATE users
    SET
        achievement_score = achievement_score + 10,
        last_achievement_at = NOW()
    WHERE id = user_id;
END;
$$;


CREATE OR REPLACE PROCEDURE create_post_with_check(
    IN user_id INTEGER,
    IN community_id INTEGER,
    IN title TEXT,
    IN body TEXT,
    OUT post_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    mod_rule RECORD;
BEGIN
    -- Insert into content_base first
    INSERT INTO content_base (
        content_type, original_id, user_id, body, created_at, updated_at
    ) VALUES (
        'post', nextval('posts_id_seq'), user_id, body, NOW(), NOW()
    );

    -- Then insert into posts
    INSERT INTO posts (
        id, content_base_id, community_id, title
    ) VALUES (
        nextval('posts_id_seq'), currval('content_base_id_seq'), community_id, title
    ) RETURNING id INTO post_id;

    -- Check moderation rules
    FOR mod_rule IN
        SELECT * FROM community_moderation_rules
        WHERE community_id = community_id AND is_active = TRUE
    LOOP
        -- Placeholder for rule-based action
        IF mod_rule.action_type = 'auto_approve' THEN
            -- Do something like mark as visible
            CONTINUE;
        ELSIF mod_rule.action_type = 'flag_for_review' THEN
            INSERT INTO content_flags (
                content_type, content_id, tag_id, community_id, reason, status
            ) VALUES (
                'post', post_id, mod_rule.tag_id, community_id, 'Auto-flagged', 'pending'
            );
        END IF;
    END LOOP;
END;
$$;

---ai moderation predictions

--April 10 2025 -- Awase Khirni Syed
CREATE TABLE ai_moderation_predictions (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    prediction JSONB NOT NULL,
    confidence REAL CHECK (confidence BETWEEN 0 AND 1),
    model_version TEXT,
    predicted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ai_mod_content ON ai_moderation_predictions(content_type, content_id);
CREATE INDEX idx_ai_mod_confidence ON ai_moderation_predictions(confidence);
CREATE INDEX idx_ai_mod_model ON ai_moderation_predictions(model_version);

--add badges - tiered achievements with visual badges
--allow communities to define custom achievements
-- images and descriptions stored
--display badges on profiles and posts
ALTER TABLE user_achievements ADD COLUMN badge_image_url TEXT;

--ferated identity and activity pub integration
--ensure full compliance with activity pub to support decentralized social networks
-- enable bidirectional federation
CREATE TABLE activitypub_inbox (
    id SERIAL PRIMARY KEY,
    actor TEXT NOT NULL,
    object JSONB NOT NULL,
    type TEXT NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE activitypub_outbox (
    id SERIAL PRIMARY KEY,
    actor TEXT NOT NULL,
    object JSONB NOT NULL,
    type TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending'
);

--corresponding Indexes for Activity pub
CREATE INDEX idx_ap_inbox_actor ON activitypub_inbox(actor);
CREATE INDEX idx_ap_inbox_received ON activitypub_inbox(received_at DESC);

CREATE INDEX idx_ap_outbox_status ON activitypub_outbox(status);
CREATE INDEX idx_ap_outbox_sent ON activitypub_outbox(sent_at DESC);

--Integrate with Apache Kafka or Pulsar to stream events into a real-time analytics engine (e.g., Flink, Spark Streaming)
--todo

--Immutable Event log
CREATE TABLE event_log (
    id BIGSERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    subject_type TEXT NOT NULL,
    subject_id INTEGER,
    action TEXT NOT NULL,
    context JSONB,
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_event_log_type ON event_log(event_type);
CREATE INDEX idx_event_log_subject ON event_log(subject_type, subject_id);
CREATE INDEX idx_event_log_time ON event_log(occurred_at DESC);

--advanced data export capabilities
-- support for Parquest, Avro or Delta Lake
-- integration support with cloud data lakes (AWS S3, Azure Blob, GCP)


--GDPR Compliance and Privacy Controls
-- expanding consent_type_enum to include granular consent types
-- to allow users to opt-in/out at a feature level
-- for personalized ads vs analytics
CREATE TYPE consent_scope_enum AS ENUM ('analytics', 'ads', 'personalization', 'email');

CREATE TABLE user_consent_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    scope consent_scope_enum NOT NULL,
    granted BOOLEAN NOT NULL,
    ip_address INET,
    user_agent TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, scope)
);


CREATE INDEX idx_user_consent_user ON user_consent_records(user_id);
CREATE INDEX idx_user_consent_scope ON user_consent_records(scope);


--reputation audits
-- alter to add blockchain support
ALTER TABLE reputation_audits ADD COLUMN audit_hash TEXT NOT NULL;
ALTER TABLE reputation_audits ADD COLUMN blockchain_tx_id TEXT;


--Right to be forgotten Automation
-- automate erasure requests across all related data - MASK PII in logs
 --Remove user references from content -- this should be standard feature, to ensure free speech is protected and against any retaliation
 --add a background process to complete these request asynchronously



 ---support for end-to-end encryption for messages
 -- add private messages e2ee using protocols like OpenPGP



 ---horizontal sharding strategy for scalability and Performance optimizations
 -- i need to shard these large tables - content_base, audit_log by tenant id or region
 -- need to look at citusDB as an alternative to logical replication for scale-out



 -- Query Caching layer -- use redis or memcached for frequently accessed views and queries
 -- to do


 --integrate with EVm compatible blockchains like Ethereum, Polygon, include features for token or NFTs for contributions
 -- reward for accepted answers, out of the box insights


 --Immutable Content Hashing
 -- Add SHA-256 hashes of conent to block chain via smart contracts
 --enable proof of existence and tamper detection
 ALTER TABLE content_base ADD COLUMN content_hash TEXT;

 --Reward Distribution Engine
 --distribute tokens/crypto rewards to users based on engagement metrics
 --integrate with wallets and token bridges

 -- add polls and voting systems
 -- add support for multi-option polls with weighted or ranked-choice voting
 -- tie poll outcomes to governance or moderation decisions



 -- to provide funcationality to extend architecture to plugin architecture
 -- currently a draft approach
 -- plugins/hooks if needed
 CREATE TABLE plugin_hooks (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    hook_type TEXT NOT NULL,
    endpoint_url TEXT NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

--community and collaboration features
--adding feature for group messages
CREATE TABLE group_messages (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    thread_id INTEGER,
    parent_message_id INTEGER REFERENCES messages(id),
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER update_group_message_updated_at
BEFORE UPDATE ON group_messages
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


--Threat intelligence feeds
-- blocked entities fields

CREATE TABLE blocked_entities (
    id SERIAL PRIMARY KEY,
    entity_type TEXT NOT NULL, -- e.g., 'ip', 'domain', 'user'
    value TEXT NOT NULL,
    reason TEXT,
    source TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    added_by INTEGER REFERENCES users(id),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

--indexes for blocked entities
CREATE INDEX idx_blocked_entity_type_value ON blocked_entities(entity_type, value);
CREATE INDEX idx_blocked_expires ON blocked_entities(expires_at);


---zero trust architectures
-- to include auth flow


--user preferred theme selections --nice to have not immediate
ALTER TABLE communities ADD COLUMN theme_settings JSONB;

--user feedback to allow communities to define and vote on governance proposals, such as rule changes, moderation committee elections, or content policy updates
-- to support decentralized decision-making and increases community ownership
-- community proposals table
CREATE TABLE community_proposals (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    proposer_user_id INTEGER NOT NULL REFERENCES users(id),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'closed', 'rejected', 'approved')),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE community_votes (
    id SERIAL PRIMARY KEY,
    proposal_id INTEGER NOT NULL REFERENCES community_proposals(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id),
    vote_direction TEXT NOT NULL CHECK (vote_direction IN ('yes', 'no', 'abstain')),
    weight NUMERIC(10,2) NOT NULL DEFAULT 1.0,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(proposal_id, user_id)
);


ALTER TABLE posts ADD COLUMN is_sticky BOOLEAN DEFAULT FALSE;
ALTER TABLE posts ADD COLUMN sticky_until TIMESTAMP WITH TIME ZONE;


-- need support for discovery of related content --easy discovery
CREATE TABLE content_relations (
    id SERIAL PRIMARY KEY,
    source_content_type content_type_enum NOT NULL,
    source_content_id INTEGER NOT NULL,
    target_content_type content_type_enum NOT NULL,
    target_content_id INTEGER NOT NULL,
    relation_type relation_type_enum NOT NULL,
    created_by INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_content_relations_source ON content_relations(source_content_type, source_content_id);
CREATE INDEX idx_content_relations_target ON content_relations(target_content_type, target_content_id);
CREATE INDEX idx_content_relations_type ON content_relations(relation_type);

--create reputation milestones  based on activity and contribution
-- to provide candid conversations, positive notions and highlight top contributors
CREATE TABLE reputation_milestones (
    id SERIAL PRIMARY KEY,
    threshold INTEGER NOT NULL,
    badge_name TEXT NOT NULL,
    badge_icon_url TEXT,
    description TEXT,
    community_id INTEGER REFERENCES communities(id) ON DELETE SET NULL,
    is_global BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


--extension for platform flexibility without modifying the core schema
CREATE TABLE custom_content_types (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    schema JSONB NOT NULL,
    renderer TEXT NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE posts ADD COLUMN custom_content_type_id INTEGER REFERENCES custom_content_types(id);


---data export templates and GDPR compliance reports
CREATE TABLE data_export_templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    format TEXT NOT NULL CHECK (format IN ('json', 'csv', 'pdf', 'parquet')),
    query TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- moderation enhancements
CREATE TABLE moderator_workload (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    community_id INTEGER NOT NULL REFERENCES communities(id),
    assigned_flags INTEGER DEFAULT 0,
    resolved_flags INTEGER DEFAULT 0,
    rejected_flags INTEGER DEFAULT 0,
    average_resolution_time INTERVAL,
    last_assigned TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE,
    load_level TEXT DEFAULT 'normal' CHECK (load_level IN ('light', 'normal', 'high', 'overloaded'))
);

CREATE INDEX idx_mod_workload_user_community ON moderator_workload(user_id, community_id);


---moderation appeals
CREATE TABLE moderation_appeals (
    id SERIAL PRIMARY KEY,
    content_type content_type_enum NOT NULL,
    content_id INTEGER NOT NULL,
    flag_id INTEGER REFERENCES content_flags(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    reason TEXT NOT NULL,
    decision TEXT,
    reviewed_by INTEGER REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    appeal_status TEXT NOT NULL DEFAULT 'pending' CHECK (appeal_status IN ('pending', 'granted', 'denied')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_mod_appeals_content ON moderation_appeals(content_type, content_id);
CREATE INDEX idx_mod_appeals_flag ON moderation_appeals(flag_id);
CREATE INDEX idx_mod_appeals_user ON moderation_appeals(user_id);


--advanced analytics
--actionable insights into user behaviour, moderation trends and system health
CREATE MATERIALIZED VIEW moderation_efficiency AS
SELECT
    u.id AS moderator_id,
    u.username,
    COUNT(*) AS total_actions,
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))) AS avg_resolution_time_seconds,
    SUM(CASE WHEN cf.status = 'approved' THEN 1 ELSE 0 END) AS approved_flags,
    SUM(CASE WHEN cf.status = 'rejected' THEN 1 ELSE 0 END) AS rejected_flags
FROM content_flags cf
JOIN users u ON cf.resolved_by = u.id
WHERE cf.resolved_at IS NOT NULL
GROUP BY u.id, u.username;

REFRESH MATERIALIZED VIEW moderation_efficiency;


--two factor authentication and session management
-- using totp based 2fa, session revocation and device fingerprinting
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_hash TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);

ALTER TABLE users ADD COLUMN two_factor_secret TEXT;
ALTER TABLE users ADD COLUMN two_factor_enabled BOOLEAN DEFAULT FALSE;
