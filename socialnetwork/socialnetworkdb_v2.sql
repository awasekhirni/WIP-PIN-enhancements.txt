-- =============================================
-- PostgreSQL Schema for Social Networking Platform
-- Version: 2.0
-- Copyright 2025 All rights reserved β ORI Inc.
-- Created: 2025-04-15
-- Last Updated: 2025-04-15
--Author: Awase Khirni Syed 
-- Description: Comprehensive schema for a Facebook-like social networking platform
--              with advanced features for data governance, analytics, and compliance
-- =============================================
-- Todo more 
--- Activitypub integration 
-- views, materialize views 
-- =============================================
-- SECTION 1: CORE TABLES
-- =============================================

-- Users and Authentication
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(256) NOT NULL UNIQUE,
    email VARCHAR(256) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    first_name VARCHAR(256),
    last_name VARCHAR(256),
    date_of_birth DATE,
    gender_id INTEGER,
    country_id INTEGER,
    profile_picture VARCHAR(256),
    cover_picture VARCHAR(256),
    bio TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITHOUT TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP WITHOUT TIME ZONE,
    gdpr_consent_status BOOLEAN NOT NULL DEFAULT FALSE,
    gdpr_consent_date TIMESTAMP WITHOUT TIME ZONE,
    data_retention_preference VARCHAR(50) DEFAULT 'standard'
);

-- User Sessions
CREATE TABLE users_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    session_token VARCHAR(256) NOT NULL UNIQUE,
    login_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(256),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_user_session FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- SECTION 2: CONTENT MANAGEMENT
-- =============================================

-- Posts
CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    post_type VARCHAR(64) NOT NULL,
    post_text TEXT,
    post_media TEXT,
    post_location VARCHAR(256),
    post_latitude DOUBLE PRECISION,
    post_longitude DOUBLE PRECISION,
    post_privacy VARCHAR(32) NOT NULL,
    post_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    post_views INTEGER NOT NULL DEFAULT 0,
    post_likes INTEGER NOT NULL DEFAULT 0,
    post_comments INTEGER NOT NULL DEFAULT 0,
    post_shares INTEGER NOT NULL DEFAULT 0,
    is_promoted BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    data_retention_date TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Post Media
CREATE TABLE posts_media (
    media_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    media_url VARCHAR(256) NOT NULL,
    media_type VARCHAR(32) NOT NULL,
    media_width INTEGER,
    media_height INTEGER,
    media_duration INTEGER,
    media_size INTEGER,
    media_format VARCHAR(32),
    thumbnail_url VARCHAR(256),
    CONSTRAINT fk_media_post FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

-- Post Comments
CREATE TABLE posts_comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    comment_text TEXT NOT NULL,
    comment_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    parent_comment_id INTEGER,
    is_edited BOOLEAN NOT NULL DEFAULT FALSE,
    last_edit_time TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_comment_post FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_parent_comment FOREIGN KEY (parent_comment_id) REFERENCES posts_comments(comment_id) ON DELETE SET NULL
);

-- =============================================
-- SECTION 3: SOCIAL GRAPH
-- =============================================

-- Friendships
CREATE TABLE friends (
    id SERIAL PRIMARY KEY,
    user_one_id INTEGER NOT NULL,
    user_two_id INTEGER NOT NULL,
    status BOOLEAN NOT NULL,
    time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_one FOREIGN KEY (user_one_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_two FOREIGN KEY (user_two_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT check_user_order CHECK (user_one_id < user_two_id),
    CONSTRAINT unique_friendship UNIQUE (user_one_id, user_two_id)
);

-- Followings
CREATE TABLE followings (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER NOT NULL,
    following_id INTEGER NOT NULL,
    time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notification_preferences JSONB DEFAULT '{"posts": true, "stories": true, "live": true}',
    CONSTRAINT fk_follower FOREIGN KEY (follower_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_following FOREIGN KEY (following_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_following UNIQUE (follower_id, following_id)
);

-- =============================================
-- SECTION 4: MESSAGING
-- =============================================

-- Conversations
CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    last_message_id INTEGER,
    color VARCHAR(32),
    node_id INTEGER,
    node_type VARCHAR(128),
    is_group BOOLEAN NOT NULL DEFAULT FALSE,
    group_name VARCHAR(256),
    group_photo VARCHAR(256),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Conversation Messages
CREATE TABLE conversations_messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    image VARCHAR(256),
    voice_note VARCHAR(256),
    time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_edited BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_message_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    CONSTRAINT fk_message_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Conversation Participants
CREATE TABLE conversations_users (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP WITHOUT TIME ZONE,
    notification_preferences JSONB DEFAULT '{"messages": true, "calls": true}',
    CONSTRAINT fk_participant_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    CONSTRAINT fk_participant_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_participation UNIQUE (conversation_id, user_id)
);

-- =============================================
-- SECTION 5: NOTIFICATIONS
-- =============================================

-- Notifications
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    notifier_id INTEGER NOT NULL,
    type VARCHAR(64) NOT NULL,
    entity_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_notifier FOREIGN KEY (notifier_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Notification Preferences
CREATE TABLE notification_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    preferences JSONB DEFAULT '{
        "friend_requests": true,
        "messages": true,
        "comments": true,
        "likes": true,
        "shares": true,
        "mentions": true,
        "events": true,
        "groups": true,
        "live": true,
        "recommendations": true
    }',
    CONSTRAINT fk_preference_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- SECTION 6: GROUPS AND PAGES
-- =============================================

-- Groups
CREATE TABLE groups (
    group_id SERIAL PRIMARY KEY,
    group_user_id INTEGER NOT NULL,
    group_category_id INTEGER,
    group_name VARCHAR(256) NOT NULL,
    group_title VARCHAR(256) NOT NULL,
    group_description TEXT NOT NULL,
    group_website VARCHAR(256),
    group_privacy VARCHAR(32) NOT NULL,
    group_cover VARCHAR(256),
    group_photo VARCHAR(256),
    group_created_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    member_count INTEGER NOT NULL DEFAULT 0,
    post_count INTEGER NOT NULL DEFAULT 0,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_group_creator FOREIGN KEY (group_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Group Members
CREATE TABLE groups_members (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    status VARCHAR(32) NOT NULL,
    time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITHOUT TIME ZONE,
    notification_preferences JSONB DEFAULT '{"posts": true, "events": true}',
    CONSTRAINT fk_member_group FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_member_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_membership UNIQUE (group_id, user_id)
);

-- Pages
CREATE TABLE pages (
    page_id SERIAL PRIMARY KEY,
    page_user_id INTEGER NOT NULL,
    page_category_id INTEGER,
    page_name VARCHAR(256) NOT NULL,
    page_title VARCHAR(256) NOT NULL,
    page_description TEXT NOT NULL,
    page_website VARCHAR(256),
    page_privacy VARCHAR(32) NOT NULL,
    page_cover VARCHAR(256),
    page_photo VARCHAR(256),
    page_created_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    like_count INTEGER NOT NULL DEFAULT 0,
    post_count INTEGER NOT NULL DEFAULT 0,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_page_creator FOREIGN KEY (page_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- SECTION 7: MEDIA AND CONTENT
-- =============================================

-- Photos
CREATE TABLE photos (
    photo_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    album_id INTEGER,
    photo_url VARCHAR(256) NOT NULL,
    thumbnail_url VARCHAR(256),
    width INTEGER,
    height INTEGER,
    size INTEGER,
    caption TEXT,
    upload_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    privacy VARCHAR(32) NOT NULL,
    location VARCHAR(256),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_photo_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Photo Albums
CREATE TABLE photo_albums (
    album_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    album_name VARCHAR(256) NOT NULL,
    album_description TEXT,
    cover_photo_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    privacy VARCHAR(32) NOT NULL,
    photo_count INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_album_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Videos
CREATE TABLE videos (
    video_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    video_url VARCHAR(256) NOT NULL,
    thumbnail_url VARCHAR(256),
    duration_seconds INTEGER,
    width INTEGER,
    height INTEGER,
    size INTEGER,
    title VARCHAR(256),
    description TEXT,
    upload_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    privacy VARCHAR(32) NOT NULL,
    view_count INTEGER NOT NULL DEFAULT 0,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_video_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- SECTION 8: EVENTS AND ACTIVITIES
-- =============================================

-- Events
CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    event_user_id INTEGER NOT NULL,
    event_category_id INTEGER,
    event_title VARCHAR(256) NOT NULL,
    event_description TEXT NOT NULL,
    event_start_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    event_end_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    event_location VARCHAR(256) NOT NULL,
    event_latitude DOUBLE PRECISION,
    event_longitude DOUBLE PRECISION,
    event_privacy VARCHAR(32) NOT NULL,
    event_cover VARCHAR(256),
    event_created_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_canceled BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_event_creator FOREIGN KEY (event_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Event Members
CREATE TABLE events_members (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    status VARCHAR(32) NOT NULL,
    rsvp_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notification_preferences JSONB DEFAULT '{"updates": true, "reminders": true}',
    CONSTRAINT fk_member_event FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    CONSTRAINT fk_member_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_event_membership UNIQUE (event_id, user_id)
);

-- =============================================
-- SECTION 9: COMMERCE AND PAYMENTS
-- =============================================

-- User Wallet
CREATE TABLE user_wallets (
    wallet_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    last_updated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Wallet Transactions
CREATE TABLE wallet_transactions (
    transaction_id SERIAL PRIMARY KEY,
    wallet_id INTEGER NOT NULL,
    transaction_type VARCHAR(64) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    transaction_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    reference_id VARCHAR(256),
    status VARCHAR(32) NOT NULL,
    metadata JSONB,
    CONSTRAINT fk_transaction_wallet FOREIGN KEY (wallet_id) REFERENCES user_wallets(wallet_id) ON DELETE CASCADE
);

-- Payment Methods
CREATE TABLE payment_methods (
    method_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    method_type VARCHAR(64) NOT NULL,
    details JSONB NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    added_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_payment_method_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- SECTION 10: SYSTEM TABLES
-- =============================================

-- System Countries
CREATE TABLE system_countries (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(256) NOT NULL,
    country_code VARCHAR(10) NOT NULL UNIQUE,
    phone_code VARCHAR(10),
    currency_code VARCHAR(10),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- System Languages
CREATE TABLE system_languages (
    language_id SERIAL PRIMARY KEY,
    language_name VARCHAR(256) NOT NULL,
    language_code VARCHAR(10) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE
);

-- System Settings
CREATE TABLE system_settings (
    setting_id SERIAL PRIMARY KEY,
    setting_name VARCHAR(256) NOT NULL UNIQUE,
    setting_value TEXT,
    setting_group VARCHAR(64) NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    data_type VARCHAR(32) NOT NULL DEFAULT 'string',
    last_updated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SECTION 11: GDPR COMPLIANCE
-- =============================================

-- GDPR Consents
CREATE TABLE gdpr_consents (
    consent_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consent_type VARCHAR(255) NOT NULL,
    consent_version VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    withdrawn_at TIMESTAMP WITH TIME ZONE,
    details TEXT,
    processor_ip_address INET,
    CONSTRAINT fk_consent_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- GDPR Data Subject Requests
CREATE TABLE gdpr_data_subject_requests (
    request_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    request_type VARCHAR(50) NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    details TEXT,
    admin_notes TEXT,
    processor_id INTEGER,
    processor_notes TEXT,
    CONSTRAINT fk_request_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- GDPR Data Processing Activities
CREATE TABLE gdpr_processing_activities (
    activity_id SERIAL PRIMARY KEY,
    activity_name VARCHAR(255) NOT NULL,
    description TEXT,
    purpose TEXT NOT NULL,
    lawful_basis VARCHAR(100) NOT NULL,
    data_categories TEXT NOT NULL,
    retention_period VARCHAR(100) NOT NULL,
    data_recipients TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- =============================================
-- SECTION 12: DATA GOVERNANCE
-- =============================================

-- Data Retention Policies
CREATE TABLE data_retention_policies (
    policy_id SERIAL PRIMARY KEY,
    table_name VARCHAR(128) NOT NULL,
    column_name VARCHAR(128),
    retention_period_days INTEGER NOT NULL,
    action_after_retention VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_executed_at TIMESTAMP WITH TIME ZONE
);

-- Data Archive Logs
CREATE TABLE data_archive_logs (
    archive_id SERIAL PRIMARY KEY,
    table_name VARCHAR(128) NOT NULL,
    record_ids_archived JSONB,
    archive_location TEXT,
    archived_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    policy_id INTEGER,
    records_count INTEGER NOT NULL,
    execution_time_ms INTEGER,
    CONSTRAINT fk_archive_policy FOREIGN KEY (policy_id) REFERENCES data_retention_policies(policy_id) ON DELETE SET NULL
);

-- Data Quality Rules
CREATE TABLE data_quality_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(128) NOT NULL,
    column_name VARCHAR(128),
    rule_description TEXT,
    check_query TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'medium',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Data Quality Logs
CREATE TABLE data_quality_logs (
    log_id SERIAL PRIMARY KEY,
    rule_id INTEGER NOT NULL,
    check_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    records_affected INTEGER,
    details JSONB,
    execution_time_ms INTEGER,
    CONSTRAINT fk_log_rule FOREIGN KEY (rule_id) REFERENCES data_quality_rules(rule_id) ON DELETE CASCADE
);

-- Data Profiling Results
CREATE TABLE data_profiling_results (
    profile_id SERIAL PRIMARY KEY,
    table_name VARCHAR(128) NOT NULL,
    column_name VARCHAR(128) NOT NULL,
    profile_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_type VARCHAR(50),
    total_rows BIGINT,
    null_count BIGINT,
    distinct_count BIGINT,
    min_value TEXT,
    max_value TEXT,
    avg_value TEXT,
    stddev_value TEXT,
    most_common_values JSONB,
    histogram JSONB,
    execution_time_ms INTEGER
);

-- Data Lineage
CREATE TABLE data_lineage (
    lineage_id SERIAL PRIMARY KEY,
    source_table VARCHAR(128) NOT NULL,
    source_column VARCHAR(128),
    target_table VARCHAR(128) NOT NULL,
    target_column VARCHAR(128),
    transformation_description TEXT,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SECTION 13: AUDIT TRAIL
-- =============================================

-- Audit Logs
CREATE TABLE audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(128),
    record_id TEXT,
    old_data JSONB,
    new_data JSONB,
    action_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- System Health Metrics
CREATE TABLE system_health_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    metric_value NUMERIC NOT NULL,
    unit VARCHAR(50),
    component VARCHAR(100) NOT NULL,
    collected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- System Health Logs
CREATE TABLE system_health_logs (
    log_id SERIAL PRIMARY KEY,
    log_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    level VARCHAR(50) NOT NULL,
    source VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    details JSONB
);

-- =============================================
-- SECTION 14: ANALYTICS
-- =============================================

-- User Activity Logs
CREATE TABLE user_activity_logs (
    activity_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    target_id INTEGER,
    target_type VARCHAR(100),
    activity_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(256),
    location POINT,
    CONSTRAINT fk_activity_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Content Engagement Metrics
CREATE TABLE content_engagement_metrics (
    engagement_id BIGSERIAL PRIMARY KEY,
    content_type VARCHAR(50) NOT NULL,
    content_id INTEGER NOT NULL,
    user_id INTEGER,
    engagement_type VARCHAR(50) NOT NULL,
    engagement_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INTEGER,
    metadata JSONB,
    CONSTRAINT fk_engagement_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Visitor Analytics
CREATE TABLE visitor_analytics (
    visit_id BIGSERIAL PRIMARY KEY,
    visitor_ip_address INET NOT NULL,
    user_id INTEGER,
    session_start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    session_end_time TIMESTAMP WITH TIME ZONE,
    user_agent TEXT,
    referrer TEXT,
    landing_page TEXT,
    pages_viewed_count INTEGER DEFAULT 1,
    device_type VARCHAR(50),
    browser_name VARCHAR(100),
    os_name VARCHAR(100),
    geolocation POINT,
    CONSTRAINT fk_visitor_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- KPI Metrics
CREATE TABLE kpi_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    metric_value NUMERIC NOT NULL,
    time_period VARCHAR(50) NOT NULL,
    metric_date DATE NOT NULL,
    dimension1 VARCHAR(100),
    dimension2 VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SECTION 15: ROLE-BASED ACCESS CONTROL (RBAC)
-- =============================================

-- Roles
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    role_description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Permissions
CREATE TABLE permissions (
    permission_id SERIAL PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    permission_description TEXT,
    resource_type VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Role Permissions
CREATE TABLE role_permissions (
    role_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permission_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permission_permission FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE
);

-- User Roles
CREATE TABLE user_roles (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_assigner FOREIGN KEY (assigned_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- =============================================
-- SECTION 16: INDEXES
-- =============================================

-- Users Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Posts Indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_post_time ON posts(post_time);
CREATE INDEX idx_posts_post_type ON posts(post_type);
CREATE INDEX idx_posts_privacy ON posts(post_privacy);

-- Friends Indexes
CREATE INDEX idx_friends_user_one ON friends(user_one_id);
CREATE INDEX idx_friends_user_two ON friends(user_two_id);
CREATE INDEX idx_friends_status ON friends(status);

-- Followings Indexes
CREATE INDEX idx_followings_follower ON followings(follower_id);
CREATE INDEX idx_followings_following ON followings(following_id);

-- Conversations Indexes
CREATE INDEX idx_conversations_is_group ON conversations(is_group);
CREATE INDEX idx_conversations_node ON conversations(node_id, node_type);

-- Messages Indexes
CREATE INDEX idx_messages_conversation ON conversations_messages(conversation_id);
CREATE INDEX idx_messages_user ON conversations_messages(user_id);
CREATE INDEX idx_messages_time ON conversations_messages(time);

-- Notifications Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- GDPR Indexes
CREATE INDEX idx_gdpr_consents_user ON gdpr_consents(user_id);
CREATE INDEX idx_gdpr_requests_user ON gdpr_data_subject_requests(user_id);
CREATE INDEX idx_gdpr_requests_status ON gdpr_data_subject_requests(status);

-- Audit Logs Indexes
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action_type);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_time ON audit_logs(action_timestamp);

-- Activity Logs Indexes
CREATE INDEX idx_activity_logs_user ON user_activity_logs(user_id);
CREATE INDEX idx_activity_logs_type ON user_activity_logs(activity_type);
CREATE INDEX idx_activity_logs_time ON user_activity_logs(activity_timestamp);

-- Visitor Analytics Indexes
CREATE INDEX idx_visitor_analytics_user ON visitor_analytics(user_id);
CREATE INDEX idx_visitor_analytics_time ON visitor_analytics(session_start_time);
CREATE INDEX idx_visitor_analytics_ip ON visitor_analytics(visitor_ip_address);

-- =============================================
-- SECTION 17: VIEWS
-- =============================================

-- User Profile ViewCREATE OR REPLACE VIEW vw_user_profiles AS
CREATE OR REPLACE VIEW vw_user_profiles AS
SELECT
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.date_of_birth,
    sc.country_name AS country,
    u.gender_id, -- or remove if not needed
    u.profile_picture,
    u.cover_picture,
    u.bio,
    u.created_at,
    u.last_login,
    u.is_verified,
    (
        SELECT COUNT(*)
        FROM friends f
        WHERE ((f.user_one_id = u.user_id OR f.user_two_id = u.user_id) AND f.status = TRUE)
    ) AS friend_count,
    (
        SELECT COUNT(*)
        FROM followings f
        WHERE f.follower_id = u.user_id
    ) AS following_count,
    (
        SELECT COUNT(*)
        FROM followings f
        WHERE f.following_id = u.user_id
    ) AS follower_count,
    (
        SELECT COUNT(*)
        FROM posts p
        WHERE p.user_id = u.user_id
    ) AS post_count
FROM
    users u
LEFT JOIN system_countries sc ON u.country_id = sc.country_id;

-- Post Engagement View
CREATE OR REPLACE VIEW vw_post_engagement AS
SELECT
    p.post_id,
    p.user_id,
    u.username,
    p.post_type,
    p.post_time,
    COALESCE(p.post_views, 0) AS post_views,
    COALESCE(p.post_likes, 0) AS post_likes,
    COALESCE(p.post_comments, 0) AS post_comments,
    COALESCE(p.post_shares, 0) AS post_shares,
    (
        COALESCE(p.post_views, 0) * 0.1 +
        COALESCE(p.post_likes, 0) * 0.5 +
        COALESCE(p.post_comments, 0) * 0.8 +
        COALESCE(p.post_shares, 0) * 1.0
    ) AS engagement_score,
    COALESCE(pc.comment_count, 0) AS actual_comments,
    0 AS actual_reactions -- Hardcoded as 0 since posts_reactions doesn't exist
FROM
    posts p
JOIN
    users u ON p.user_id = u.user_id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS comment_count
    FROM posts_comments
    GROUP BY post_id
) pc ON p.post_id = pc.post_id;

-- Daily Active Users View
CREATE OR REPLACE VIEW vw_daily_active_users AS
SELECT
    DATE_TRUNC('day', activity_timestamp)::DATE AS activity_date,
    COUNT(DISTINCT user_id) AS active_users
FROM
    user_activity_logs
WHERE
    activity_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    DATE_TRUNC('day', activity_timestamp)::DATE
ORDER BY
    activity_date DESC;

-- Content Performance View
CREATE OR REPLACE VIEW vw_content_performance AS
SELECT
    content_type,
    COUNT(*) AS total_content,
    SUM(CASE WHEN engagement_type = 'view' THEN 1 ELSE 0 END) AS total_views,
    SUM(CASE WHEN engagement_type = 'like' THEN 1 ELSE 0 END) AS total_likes,
    SUM(CASE WHEN engagement_type = 'comment' THEN 1 ELSE 0 END) AS total_comments,
    SUM(CASE WHEN engagement_type = 'share' THEN 1 ELSE 0 END) AS total_shares,
    AVG(duration_seconds) AS avg_engagement_duration
FROM
    content_engagement_metrics
WHERE
    engagement_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    content_type;

-- User Activity Summary View
CREATE OR REPLACE VIEW vw_user_activity_summary AS
SELECT
    u.user_id,
    u.username,
    COUNT(DISTINCT CASE WHEN a.activity_type = 'login' THEN a.activity_id END) AS login_count,
    COUNT(DISTINCT CASE WHEN a.activity_type = 'post_create' THEN a.activity_id END) AS post_count,
    COUNT(DISTINCT CASE WHEN a.activity_type = 'comment_create' THEN a.activity_id END) AS comment_count,
    COUNT(DISTINCT CASE WHEN a.activity_type = 'like' THEN a.activity_id END) AS like_count,
    COUNT(DISTINCT CASE WHEN a.activity_type = 'share' THEN a.activity_id END) AS share_count,
    MAX(a.activity_timestamp) AS last_activity_time
FROM
    users u
LEFT JOIN
    user_activity_logs a ON u.user_id = a.user_id
WHERE
    a.activity_timestamp >= CURRENT_DATE - INTERVAL '30 days' OR a.activity_id IS NULL
GROUP BY
    u.user_id, u.username;

-- =============================================
-- SECTION 18: STORED PROCEDURES
-- =============================================

-- Procedure: sp_create_user
CREATE OR REPLACE PROCEDURE sp_create_user(
    OUT p_user_id INTEGER,
    p_username VARCHAR,
    p_email VARCHAR,
    p_password_hash VARCHAR,
    p_first_name VARCHAR DEFAULT NULL,
    p_last_name VARCHAR DEFAULT NULL,
    p_country_id INTEGER DEFAULT NULL,
    p_gender_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users (
        username,
        email,
        password_hash,
        first_name,
        last_name,
        country_id,
        gender_id,
        gdpr_consent_status,
        gdpr_consent_date
    )
    VALUES (
        p_username,
        p_email,
        p_password_hash,
        p_first_name,
        p_last_name,
        p_country_id,
        p_gender_id,
        TRUE,
        CURRENT_TIMESTAMP
    )
    RETURNING user_id INTO p_user_id;

    -- Create default notification preferences
    INSERT INTO notification_preferences (user_id) VALUES (p_user_id);

    -- Create wallet for the user
    INSERT INTO user_wallets (user_id) VALUES (p_user_id);

    -- Log the user creation
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        new_data
    )
    VALUES (
        p_user_id,
        'CREATE',
        'users',
        p_user_id::TEXT,
        jsonb_build_object(
            'username', p_username,
            'email', p_email,
            'first_name', p_first_name,
            'last_name', p_last_name
        )
    );
END;
$$;

-- Procedure: sp_deactivate_user
CREATE OR REPLACE PROCEDURE sp_deactivate_user(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_username VARCHAR;
BEGIN
    SELECT username INTO v_username FROM users WHERE user_id = p_user_id;

    UPDATE users
    SET
        is_active = FALSE,
        last_login = NULL
    WHERE
        user_id = p_user_id;

    -- Terminate all active sessions
    UPDATE users_sessions
    SET
        is_active = FALSE
    WHERE
        user_id = p_user_id AND is_active = TRUE;

    -- Log the deactivation
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        old_data,
        new_data
    )
    VALUES (
        p_user_id,
        'UPDATE',
        'users',
        p_user_id::TEXT,
        jsonb_build_object('is_active', TRUE),
        jsonb_build_object('is_active', FALSE)
    );

    -- Log the action
    RAISE NOTICE 'User % (ID: %) has been deactivated', v_username, p_user_id;
END;
$$;

-- Procedure: sp_anonymize_user (GDPR compliance)
CREATE OR REPLACE PROCEDURE sp_anonymize_user(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_username VARCHAR;
    v_email VARCHAR;
BEGIN
    SELECT username, email INTO v_username, v_email FROM users WHERE user_id = p_user_id;

    -- Anonymize user data
    UPDATE users
    SET
        username = 'anon_' || p_user_id || '_' || substr(md5(random()::text), 1, 8),
        email = 'anon_' || p_user_id || '_' || substr(md5(random()::text), 1, 8) || '@example.com',
        password_hash = 'anonymized',
        first_name = 'Anonymous',
        last_name = 'User',
        date_of_birth = NULL,
        gender_id = NULL,
        country_id = NULL,
        profile_picture = 'default_anon.png',
        cover_picture = 'default_anon_cover.png',
        bio = 'This user has been anonymized due to a data erasure request.',
        is_active = FALSE,
        is_verified = FALSE,
        is_deleted = TRUE,
        deleted_at = CURRENT_TIMESTAMP
    WHERE
        user_id = p_user_id;

    -- Delete sensitive data from related tables
    DELETE FROM users_addresses WHERE user_id = p_user_id;
    DELETE FROM users_sms WHERE user_id = p_user_id;
    DELETE FROM payment_methods WHERE user_id = p_user_id;

    -- Log the anonymization
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        old_data,
        new_data
    )
    VALUES (
        p_user_id,
        'ANONYMIZE',
        'users',
        p_user_id::TEXT,
        jsonb_build_object('username', v_username, 'email', v_email),
        jsonb_build_object('username', 'anonymized', 'email', 'anonymized')
    );

    -- Log the action
    RAISE NOTICE 'User % (ID: %) has been anonymized', v_username, p_user_id;
END;
$$;

-- Procedure: sp_process_gdpr_request
CREATE OR REPLACE PROCEDURE sp_process_gdpr_request(
    p_request_id INTEGER,
    p_status VARCHAR,
    p_admin_id INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    v_request_type VARCHAR;
    v_current_status VARCHAR;
BEGIN
    -- Get request details
    SELECT user_id, request_type, status
    INTO v_user_id, v_request_type, v_current_status
    FROM gdpr_data_subject_requests
    WHERE request_id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'GDPR request with ID % not found', p_request_id;
    END IF;

    IF v_current_status = 'completed' OR v_current_status = 'rejected' THEN
        RAISE EXCEPTION 'Request already processed with status %', v_current_status;
    END IF;

    -- Update request status
    UPDATE gdpr_data_subject_requests
    SET
        status = p_status,
        fulfilled_at = CASE WHEN p_status = 'completed' THEN CURRENT_TIMESTAMP ELSE NULL END,
        processor_id = p_admin_id,
        processor_notes = p_notes
    WHERE
        request_id = p_request_id;

    -- If request is approved and is an erasure request, anonymize the user
    IF p_status = 'completed' AND v_request_type = 'erasure' THEN
        CALL sp_anonymize_user(v_user_id);
    END IF;

    -- Log the processing
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        new_data
    )
    VALUES (
        p_admin_id,
        'PROCESS_GDPR_REQUEST',
        'gdpr_data_subject_requests',
        p_request_id::TEXT,
        jsonb_build_object('status', p_status, 'request_type', v_request_type)
    );

    -- Log the action
    RAISE NOTICE 'GDPR request % for user % processed with status %', p_request_id, v_user_id, p_status;
END;
$$;

-- Procedure: sp_apply_data_retention_policy
CREATE OR REPLACE PROCEDURE sp_apply_data_retention_policy(
    p_policy_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_policy RECORD;
    v_sql TEXT;
    v_where_clause TEXT;
    v_count INTEGER;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time INTEGER;
BEGIN
    v_start_time := clock_timestamp();

    -- Get policy details
    SELECT * INTO v_policy
    FROM data_retention_policies
    WHERE policy_id = p_policy_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active retention policy with ID % not found', p_policy_id;
    END IF;

    -- Build WHERE clause based on column name
    IF v_policy.column_name IS NULL THEN
        v_where_clause := 'created_at < NOW() - INTERVAL ''' || v_policy.retention_period_days || ' days''';
    ELSE
        v_where_clause := v_policy.column_name || ' < NOW() - INTERVAL ''' || v_policy.retention_period_days || ' days''';
    END IF;

    -- Execute appropriate action
    IF v_policy.action_after_retention = 'delete' THEN
        -- Count records to be deleted
        EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(v_policy.table_name) || ' WHERE ' || v_where_clause INTO v_count;

        -- Delete records
        EXECUTE 'DELETE FROM ' || quote_ident(v_policy.table_name) || ' WHERE ' || v_where_clause;

        -- Log the deletion
        INSERT INTO data_archive_logs (
            table_name,
            record_ids_archived,
            archive_location,
            archived_at,
            policy_id,
            records_count
        )
        VALUES (
            v_policy.table_name,
            NULL,
            'deleted',
            CURRENT_TIMESTAMP,
            p_policy_id,
            v_count
        );

    ELSIF v_policy.action_after_retention = 'archive' THEN
        -- For demonstration, we'll just log that it should be archived
        -- In production, this would move data to an archive table or external storage
        EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(v_policy.table_name) || ' WHERE ' || v_where_clause INTO v_count;

        INSERT INTO data_archive_logs (
            table_name,
            record_ids_archived,
            archive_location,
            archived_at,
            policy_id,
            records_count
        )
        VALUES (
            v_policy.table_name,
            NULL,
            'external_archive_system',
            CURRENT_TIMESTAMP,
            p_policy_id,
            v_count
        );

        RAISE NOTICE 'Data for table % (policy ID %) marked for archiving. % records affected.',
            v_policy.table_name, p_policy_id, v_count;
    ELSIF v_policy.action_after_retention = 'anonymize' THEN
        -- This would require specific logic per table to anonymize data in place
        RAISE NOTICE 'Anonymization action for table % (policy ID %) requires specific implementation.',
            v_policy.table_name, p_policy_id;
    END IF;

    -- Update policy last execution time
    UPDATE data_retention_policies
    SET last_executed_at = CURRENT_TIMESTAMP
    WHERE policy_id = p_policy_id;

    v_end_time := clock_timestamp();
    v_execution_time := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    -- Log the policy execution
    INSERT INTO audit_logs (
        action_type,
        table_name,
        action_timestamp,
        details
    )
    VALUES (
        'DATA_RETENTION_POLICY_EXECUTED',
        v_policy.table_name,
        CURRENT_TIMESTAMP,
        jsonb_build_object(
            'policy_id', p_policy_id,
            'action', v_policy.action_after_retention,
            'records_affected', COALESCE(v_count, 0),
            'execution_time_ms', v_execution_time
        )
    );

    -- Log the action
    RAISE NOTICE 'Retention policy % for table % executed in % ms',
        p_policy_id, v_policy.table_name, v_execution_time;
END;
$$;

-- Procedure: sp_execute_data_quality_check
CREATE OR REPLACE PROCEDURE sp_execute_data_quality_check(
    p_rule_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rule RECORD;
    v_failed_count INTEGER;
    v_status VARCHAR(50);
    v_details JSONB;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time INTEGER;
BEGIN
    v_start_time := clock_timestamp();

    -- Get rule details
    SELECT * INTO v_rule
    FROM data_quality_rules
    WHERE rule_id = p_rule_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active data quality rule with ID % not found', p_rule_id;
    END IF;

    -- Execute the rule check
    BEGIN
        EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(v_rule.table_name) ||
                ' WHERE NOT (' || v_rule.check_query || ')'
        INTO v_failed_count;

        IF v_failed_count > 0 THEN
            v_status := 'failed';
            v_details := jsonb_build_object(
                'message', 'Data quality rule failed',
                'failed_count', v_failed_count,
                'severity', v_rule.severity
            );
        ELSE
            v_status := 'passed';
            v_details := jsonb_build_object('message', 'Data quality rule passed');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            v_status := 'error';
            v_failed_count := NULL;
            v_details := jsonb_build_object(
                'message', SQLERRM,
                'sqlstate', SQLSTATE,
                'error', 'Error executing data quality rule'
            );
    END;

    v_end_time := clock_timestamp();
    v_execution_time := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    -- Log the result
    INSERT INTO data_quality_logs (
        rule_id,
        check_timestamp,
        status,
        records_affected,
        details,
        execution_time_ms
    )
    VALUES (
        p_rule_id,
        CURRENT_TIMESTAMP,
        v_status,
        v_failed_count,
        v_details,
        v_execution_time
    );

    -- Log the check in audit logs
    INSERT INTO audit_logs (
        action_type,
        table_name,
        action_timestamp,
        details
    )
    VALUES (
        'DATA_QUALITY_CHECK',
        v_rule.table_name,
        CURRENT_TIMESTAMP,
        jsonb_build_object(
            'rule_id', p_rule_id,
            'rule_name', v_rule.rule_name,
            'status', v_status,
            'failed_count', COALESCE(v_failed_count, 0),
            'execution_time_ms', v_execution_time
        )
    );

    -- Log the action
    RAISE NOTICE 'Data quality rule % for table % executed with status % in % ms',
        p_rule_id, v_rule.table_name, v_status, v_execution_time;
END;
$$;

-- Procedure: sp_perform_data_profiling
CREATE OR REPLACE PROCEDURE sp_perform_data_profiling(
    p_table_name VARCHAR,
    p_column_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_data_type TEXT;
    v_total_rows BIGINT;
    v_null_count BIGINT;
    v_distinct_count BIGINT;
    v_min_value TEXT;
    v_max_value TEXT;
    v_avg_value TEXT;
    v_stddev_value TEXT;
    v_most_common_values JSONB;
    v_histogram JSONB;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time INTEGER;
BEGIN
    v_start_time := clock_timestamp();

    -- Get data type from information_schema
    SELECT data_type INTO v_data_type
    FROM information_schema.columns
    WHERE table_name = p_table_name AND column_name = p_column_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Table % or column % not found in information_schema', p_table_name, p_column_name;
    END IF;

    -- Get total rows
    EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(p_table_name) INTO v_total_rows;

    -- Get null count
    EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(p_table_name) ||
            ' WHERE ' || quote_ident(p_column_name) || ' IS NULL' INTO v_null_count;

    -- Get distinct count
    EXECUTE 'SELECT COUNT(DISTINCT ' || quote_ident(p_column_name) || ') FROM ' ||
            quote_ident(p_table_name) INTO v_distinct_count;

    -- Get min, max, avg, stddev (if applicable)
    IF v_data_type IN ('integer', 'bigint', 'smallint', 'numeric', 'double precision', 'real') THEN
        EXECUTE 'SELECT MIN(' || quote_ident(p_column_name) || ')::TEXT, ' ||
                       'MAX(' || quote_ident(p_column_name) || ')::TEXT, ' ||
                       'AVG(' || quote_ident(p_column_name) || ')::TEXT, ' ||
                       'STDDEV(' || quote_ident(p_column_name) || ')::TEXT ' ||
                'FROM ' || quote_ident(p_table_name)
        INTO v_min_value, v_max_value, v_avg_value, v_stddev_value;
    ELSIF v_data_type IN ('date', 'timestamp', 'timestamp with time zone') THEN
        EXECUTE 'SELECT MIN(' || quote_ident(p_column_name) || ')::TEXT, ' ||
                       'MAX(' || quote_ident(p_column_name) || ')::TEXT ' ||
                'FROM ' || quote_ident(p_table_name)
        INTO v_min_value, v_max_value;
    ELSE
        EXECUTE 'SELECT MIN(' || quote_ident(p_column_name) || ')::TEXT, ' ||
                       'MAX(' || quote_ident(p_column_name) || ')::TEXT ' ||
                'FROM ' || quote_ident(p_table_name)
        INTO v_min_value, v_max_value;
    END IF;

    -- Get most common values (top 10)
    EXECUTE 'SELECT jsonb_agg(row_to_json(t)) FROM (' ||
            'SELECT ' || quote_ident(p_column_name) || ' AS value, COUNT(*)::INTEGER AS count ' ||
            'FROM ' || quote_ident(p_table_name) || ' ' ||
            'GROUP BY ' || quote_ident(p_column_name) || ' ' ||
            'ORDER BY count DESC LIMIT 10) t'
    INTO v_most_common_values;

    -- Get histogram (simplified for numerical/date types)
    IF v_data_type IN ('integer', 'bigint', 'smallint', 'numeric', 'double precision', 'real') THEN
        EXECUTE 'SELECT jsonb_object_agg(width_bucket, count) FROM (' ||
                'SELECT width_bucket(' || quote_ident(p_column_name) || ', ' ||
                '(SELECT MIN(' || quote_ident(p_column_name) || ') FROM ' || quote_ident(p_table_name) || '), ' ||
                '(SELECT MAX(' || quote_ident(p_column_name) || ') FROM ' || quote_ident(p_table_name) || '), 10) AS width_bucket, ' ||
                'COUNT(*)::INTEGER FROM ' || quote_ident(p_table_name) || ' ' ||
                'GROUP BY width_bucket ORDER BY width_bucket) AS buckets'
        INTO v_histogram;
    ELSIF v_data_type IN ('date', 'timestamp', 'timestamp with time zone') THEN
        EXECUTE 'SELECT jsonb_object_agg(to_char(' || quote_ident(p_column_name) || ', ''YYYY-MM''), count) FROM (' ||
                'SELECT ' || quote_ident(p_column_name) || ', COUNT(*)::INTEGER ' ||
                'FROM ' || quote_ident(p_table_name) || ' ' ||
                'GROUP BY 1 ORDER BY 1) AS monthly_counts'
        INTO v_histogram;
    END IF;

    v_end_time := clock_timestamp();
    v_execution_time := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    -- Store profiling results
    INSERT INTO data_profiling_results (
        table_name,
        column_name,
        profile_timestamp,
        data_type,
        total_rows,
        null_count,
        distinct_count,
        min_value,
        max_value,
        avg_value,
        stddev_value,
        most_common_values,
        histogram,
        execution_time_ms
    )
    VALUES (
        p_table_name,
        p_column_name,
        CURRENT_TIMESTAMP,
        v_data_type,
        v_total_rows,
        v_null_count,
        v_distinct_count,
        v_min_value,
        v_max_value,
        v_avg_value,
        v_stddev_value,
        v_most_common_values,
        v_histogram,
        v_execution_time
    );

    -- Log the profiling in audit logs
    INSERT INTO audit_logs (
        action_type,
        table_name,
        action_timestamp,
        details
    )
    VALUES (
        'DATA_PROFILING',
        p_table_name,
        CURRENT_TIMESTAMP,
        jsonb_build_object(
            'column_name', p_column_name,
            'data_type', v_data_type,
            'execution_time_ms', v_execution_time
        )
    );

    -- Log the action
    RAISE NOTICE 'Data profiling for table %.% completed in % ms',
        p_table_name, p_column_name, v_execution_time;
END;
$$;

-- Procedure: sp_log_user_activity
CREATE OR REPLACE PROCEDURE sp_log_user_activity(
    p_user_id INTEGER,
    p_activity_type VARCHAR,
    p_target_id INTEGER DEFAULT NULL,
    p_target_type VARCHAR DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_device_id VARCHAR DEFAULT NULL,
    p_location POINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO user_activity_logs (
        user_id,
        activity_type,
        target_id,
        target_type,
        activity_timestamp,
        ip_address,
        user_agent,
        device_id,
        location
    )
    VALUES (
        p_user_id,
        p_activity_type,
        p_target_id,
        p_target_type,
        CURRENT_TIMESTAMP,
        p_ip_address,
        p_user_agent,
        p_device_id,
        p_location
    );

    -- Update user's last activity time
    UPDATE users
    SET last_login = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
END;
$$;

-- Procedure: sp_log_content_engagement
CREATE OR REPLACE PROCEDURE sp_log_content_engagement(
    p_content_type VARCHAR,
    p_content_id INTEGER,
    p_engagement_type VARCHAR,
    p_user_id INTEGER DEFAULT NULL,
    p_duration_seconds INTEGER DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO content_engagement_metrics (
        content_type,
        content_id,
        user_id,
        engagement_type,
        engagement_timestamp,
        duration_seconds,
        metadata
    )
    VALUES (
        p_content_type,
        p_content_id,
        p_user_id,
        p_engagement_type,
        CURRENT_TIMESTAMP,
        p_duration_seconds,
        p_metadata
    );

    -- Update content statistics based on engagement type
    IF p_engagement_type = 'view' THEN
        EXECUTE 'UPDATE ' || quote_ident(p_content_type || 's') ||
                ' SET view_count = view_count + 1 WHERE ' ||
                quote_ident(p_content_type || '_id') || ' = ' || p_content_id;
    ELSIF p_engagement_type = 'like' THEN
        EXECUTE 'UPDATE ' || quote_ident(p_content_type || 's') ||
                ' SET like_count = like_count + 1 WHERE ' ||
                quote_ident(p_content_type || '_id') || ' = ' || p_content_id;
    ELSIF p_engagement_type = 'comment' THEN
        EXECUTE 'UPDATE ' || quote_ident(p_content_type || 's') ||
                ' SET comment_count = comment_count + 1 WHERE ' ||
                quote_ident(p_content_type || '_id') || ' = ' || p_content_id;
    END IF;
END;
$$;




-- Procedure: sp_start_visitor_session
CREATE OR REPLACE FUNCTION sp_start_visitor_session(
    p_visitor_ip_address INET,
    p_user_id INTEGER DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_referrer TEXT DEFAULT NULL,
    p_landing_page TEXT DEFAULT NULL,
    p_device_type VARCHAR DEFAULT NULL,
    p_browser_name VARCHAR DEFAULT NULL,
    p_os_name VARCHAR DEFAULT NULL,
    p_geolocation POINT DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_visit_id BIGINT;
BEGIN
    INSERT INTO visitor_analytics (
        visitor_ip_address,
        user_id,
        session_start_time,
        user_agent,
        referrer,
        landing_page,
        device_type,
        browser_name,
        os_name,
        geolocation
    )
    VALUES (
        p_visitor_ip_address,
        p_user_id,
        CURRENT_TIMESTAMP,
        p_user_agent,
        p_referrer,
        p_landing_page,
        p_device_type,
        p_browser_name,
        p_os_name,
        p_geolocation
    )
    RETURNING visit_id INTO v_visit_id;

    RETURN v_visit_id;
END;
$$;

-- Procedure: sp_end_visitor_session
CREATE OR REPLACE PROCEDURE sp_end_visitor_session(
    p_visit_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE visitor_analytics
    SET session_end_time = CURRENT_TIMESTAMP
    WHERE visit_id = p_visit_id AND session_end_time IS NULL;
END;
$$;

-- Procedure: sp_increment_page_view
CREATE OR REPLACE PROCEDURE sp_increment_page_view(
    p_visit_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE visitor_analytics
    SET pages_viewed_count = COALESCE(pages_viewed_count, 0) + 1
    WHERE visit_id = p_visit_id;
END;
$$;

-- Procedure: sp_calculate_kpis
CREATE OR REPLACE PROCEDURE sp_calculate_kpis(
    p_time_period VARCHAR DEFAULT 'daily',
    p_metric_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP;
    v_end_date TIMESTAMP;
    v_new_users INTEGER;
    v_active_users INTEGER;
    v_dau_percentage NUMERIC;
    v_engagement_rate NUMERIC;
    v_avg_session_duration NUMERIC;
    v_retention_rate NUMERIC;
    v_content_created INTEGER;
    v_content_engagement NUMERIC;
BEGIN
    -- Determine date range based on time period
    IF p_time_period = 'daily' THEN
        v_start_date := p_metric_date;
        v_end_date := p_metric_date + INTERVAL '1 day';
    ELSIF p_time_period = 'weekly' THEN
        v_start_date := DATE_TRUNC('week', p_metric_date)::DATE;
        v_end_date := (DATE_TRUNC('week', p_metric_date) + INTERVAL '1 week')::DATE;
    ELSIF p_time_period = 'monthly' THEN
        v_start_date := DATE_TRUNC('month', p_metric_date)::DATE;
        v_end_date := (DATE_TRUNC('month', p_metric_date) + INTERVAL '1 month')::DATE;
    ELSE
        RAISE EXCEPTION 'Invalid time period: %. Valid values are "daily", "weekly", "monthly"', p_time_period;
    END IF;

    -- New Users
    SELECT COUNT(*)
    INTO v_new_users
    FROM users
    WHERE created_at >= v_start_date AND created_at < v_end_date;

    -- Active Users
    SELECT COUNT(DISTINCT user_id)
    INTO v_active_users
    FROM user_activity_logs
    WHERE activity_timestamp >= v_start_date AND activity_timestamp < v_end_date;

    -- DAU Percentage (daily active users / total users)
    SELECT (
        COUNT(DISTINCT a.user_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT u.user_id), 0)
        * 100
    )
    INTO v_dau_percentage
    FROM users u
    LEFT JOIN user_activity_logs a ON u.user_id = a.user_id
        AND a.activity_timestamp >= v_start_date
        AND a.activity_timestamp < v_end_date
    WHERE u.created_at < v_end_date;

    -- Engagement Rate (engaged users / active users)
    SELECT (
        COUNT(DISTINCT CASE WHEN activity_type IN ('post_create', 'comment_create', 'like', 'share') THEN user_id END)::NUMERIC
        / NULLIF(COUNT(DISTINCT user_id), 0)
        * 100
    )
    INTO v_engagement_rate
    FROM user_activity_logs
    WHERE activity_timestamp >= v_start_date AND activity_timestamp < v_end_date;

    -- Average Session Duration (for visitors with session end time)
    SELECT AVG(EXTRACT(EPOCH FROM (session_end_time - session_start_time)))
    INTO v_avg_session_duration
    FROM visitor_analytics
    WHERE session_start_time >= v_start_date
      AND session_start_time < v_end_date
      AND session_end_time IS NOT NULL;

    -- Retention Rate (users active in current and previous period)
    IF p_time_period = 'daily' THEN
        WITH previous_day_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= (v_start_date - INTERVAL '1 day')
              AND activity_timestamp < v_start_date
              AND user_id IS NOT NULL
        ),
        current_day_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= v_start_date
              AND activity_timestamp < v_end_date
              AND user_id IS NOT NULL
        )
        SELECT (
            COUNT(DISTINCT c.user_id)::NUMERIC
            / NULLIF(COUNT(DISTINCT p.user_id), 0)
            * 100
        )
        INTO v_retention_rate
        FROM previous_day_users p
        LEFT JOIN current_day_users c ON p.user_id = c.user_id;

    ELSIF p_time_period = 'weekly' THEN
        WITH previous_week_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= (v_start_date - INTERVAL '1 week')
              AND activity_timestamp < v_start_date
              AND user_id IS NOT NULL
        ),
        current_week_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= v_start_date
              AND activity_timestamp < v_end_date
              AND user_id IS NOT NULL
        )
        SELECT (
            COUNT(DISTINCT c.user_id)::NUMERIC
            / NULLIF(COUNT(DISTINCT p.user_id), 0)
            * 100
        )
        INTO v_retention_rate
        FROM previous_week_users p
        LEFT JOIN current_week_users c ON p.user_id = c.user_id;

    ELSIF p_time_period = 'monthly' THEN
        WITH previous_month_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= (v_start_date - INTERVAL '1 month')
              AND activity_timestamp < v_start_date
              AND user_id IS NOT NULL
        ),
        current_month_users AS (
            SELECT DISTINCT user_id
            FROM user_activity_logs
            WHERE activity_timestamp >= v_start_date
              AND activity_timestamp < v_end_date
              AND user_id IS NOT NULL
        )
        SELECT (
            COUNT(DISTINCT c.user_id)::NUMERIC
            / NULLIF(COUNT(DISTINCT p.user_id), 0)
            * 100
        )
        INTO v_retention_rate
        FROM previous_month_users p
        LEFT JOIN current_month_users c ON p.user_id = c.user_id;
    END IF;

    -- Content Created
    SELECT COUNT(*)
    INTO v_content_created
    FROM posts
    WHERE post_time >= v_start_date AND post_time < v_end_date;

    -- Content Engagement (average engagements per content item)
    SELECT AVG(
        COALESCE(post_views, 0) * 0.1 +
        COALESCE(post_likes, 0) * 0.5 +
        COALESCE(post_comments, 0) * 0.8 +
        COALESCE(post_shares, 0) * 1.0
    )
    INTO v_content_engagement
    FROM posts
    WHERE post_time >= v_start_date AND post_time < v_end_date;

    -- Insert KPI metrics
    INSERT INTO kpi_metrics (
        metric_name,
        metric_value,
        time_period,
        metric_date,
        dimension1
    )
    VALUES
        ('new_users', v_new_users, p_time_period, p_metric_date, NULL),
        ('active_users', v_active_users, p_time_period, p_metric_date, NULL),
        ('dau_percentage', v_dau_percentage, p_time_period, p_metric_date, NULL),
        ('engagement_rate', v_engagement_rate, p_time_period, p_metric_date, NULL),
        ('avg_session_duration', v_avg_session_duration, p_time_period, p_metric_date, NULL),
        ('retention_rate', v_retention_rate, p_time_period, p_metric_date, NULL),
        ('content_created', v_content_created, p_time_period, p_metric_date, NULL),
        ('content_engagement', v_content_engagement, p_time_period, p_metric_date, NULL);

    -- Log the KPI calculation
    INSERT INTO audit_logs (
        action_type,
        action_timestamp,
        details
    )
    VALUES (
        'KPI_CALCULATION',
        CURRENT_TIMESTAMP,
        jsonb_build_object(
            'time_period', p_time_period,
            'metric_date', p_metric_date,
            'new_users', v_new_users,
            'active_users', v_active_users,
            'dau_percentage', v_dau_percentage,
            'engagement_rate', v_engagement_rate,
            'avg_session_duration', v_avg_session_duration,
            'retention_rate', v_retention_rate,
            'content_created', v_content_created,
            'content_engagement', v_content_engagement
        )
    );

    -- Log the action
    RAISE NOTICE 'KPIs calculated for % period ending %', p_time_period, p_metric_date;
END;
$$;

-- =============================================
-- SECTION 19: TRIGGERS
-- =============================================

-- Trigger: trg_update_last_message
-- Updates the last_message_id in conversations when a new message is inserted
CREATE OR REPLACE FUNCTION fn_update_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE conversations
    SET
        last_message_id = NEW.message_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE conversation_id = NEW.conversation_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_last_message
AFTER INSERT ON conversations_messages
FOR EACH ROW
EXECUTE FUNCTION fn_update_last_message();

-- Trigger: trg_update_post_stats
-- Updates post statistics when a comment is added
CREATE OR REPLACE FUNCTION fn_update_post_stats_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE posts
    SET post_comments = post_comments + 1
    WHERE post_id = NEW.post_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_post_stats_comment
AFTER INSERT ON posts_comments
FOR EACH ROW
EXECUTE FUNCTION fn_update_post_stats_comment();

-- Trigger: trg_log_audit_on_user_update
-- Logs changes to user data in the audit log
CREATE OR REPLACE FUNCTION fn_log_audit_on_user_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_changed_fields JSONB := '{}';
BEGIN
    IF NEW.username <> OLD.username THEN
        v_changed_fields := jsonb_insert(v_changed_fields, '{username}', jsonb_build_object('old', OLD.username, 'new', NEW.username));
    END IF;

    IF NEW.email <> OLD.email THEN
        v_changed_fields := jsonb_insert(v_changed_fields, '{email}', jsonb_build_object('old', OLD.email, 'new', NEW.email));
    END IF;

    IF NEW.is_active <> OLD.is_active THEN
        v_changed_fields := jsonb_insert(v_changed_fields, '{is_active}', jsonb_build_object('old', OLD.is_active, 'new', NEW.is_active));
    END IF;

    IF NEW.is_verified <> OLD.is_verified THEN
        v_changed_fields := jsonb_insert(v_changed_fields, '{is_verified}', jsonb_build_object('old', OLD.is_verified, 'new', NEW.is_verified));
    END IF;

    IF v_changed_fields <> '{}' THEN
        INSERT INTO audit_logs (
            user_id,
            action_type,
            table_name,
            record_id,
            old_data,
            new_data
        )
        VALUES (
            NEW.user_id,
            'UPDATE',
            'users',
            NEW.user_id::TEXT,
            jsonb_build_object(
                'username', OLD.username,
                'email', OLD.email,
                'is_active', OLD.is_active,
                'is_verified', OLD.is_verified
            ),
            jsonb_build_object(
                'username', NEW.username,
                'email', NEW.email,
                'is_active', NEW.is_active,
                'is_verified', NEW.is_verified
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_audit_on_user_update
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION fn_log_audit_on_user_update();

-- Trigger: trg_check_data_quality_on_post
-- Example data quality check on post insertion
CREATE OR REPLACE FUNCTION fn_check_data_quality_on_post()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if post text is too long (example rule)
    IF NEW.post_text IS NOT NULL AND length(NEW.post_text) > 10000 THEN
        INSERT INTO data_quality_logs (
            rule_id,
            check_timestamp,
            status,
            records_affected,
            details
        )
        VALUES (
            (SELECT rule_id FROM data_quality_rules WHERE rule_name = 'post_text_length' LIMIT 1),
            CURRENT_TIMESTAMP,
            'failed',
            1,
            jsonb_build_object(
                'message', 'Post text exceeds maximum allowed length',
                'length', length(NEW.post_text),
                'max_allowed', 10000
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_data_quality_on_post
AFTER INSERT OR UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION fn_check_data_quality_on_post();

-- =============================================
-- SECTION 20: INITIAL DATA
-- =============================================

-- Insert system roles
INSERT INTO roles (role_name, role_description, is_system_role) VALUES
('admin', 'System administrator with full access', TRUE),
('moderator', 'Content moderator with limited administrative access', TRUE),
('user', 'Regular user with standard permissions', TRUE),
('content_creator', 'User with enhanced content creation permissions', FALSE),
('analyst', 'User with access to analytics and reporting', FALSE);

-- Insert system permissions
INSERT INTO permissions (permission_name, permission_description, resource_type, action) VALUES
-- User permissions
('user_create', 'Create new users', 'user', 'create'),
('user_read', 'View user profiles', 'user', 'read'),
('user_update', 'Update user information', 'user', 'update'),
('user_delete', 'Delete users', 'user', 'delete'),
-- Post permissions
('post_create', 'Create posts', 'post', 'create'),
('post_read', 'View posts', 'post', 'read'),
('post_update', 'Edit posts', 'post', 'update'),
('post_delete', 'Delete posts', 'post', 'delete'),
-- Comment permissions
('comment_create', 'Create comments', 'comment', 'create'),
('comment_read', 'View comments', 'comment', 'read'),
('comment_update', 'Edit comments', 'comment', 'update'),
('comment_delete', 'Delete comments', 'comment', 'delete'),
-- Message permissions
('message_send', 'Send messages', 'message', 'create'),
('message_read', 'Read messages', 'message', 'read'),
-- Group permissions
('group_create', 'Create groups', 'group', 'create'),
('group_join', 'Join groups', 'group', 'join'),
('group_manage', 'Manage group settings', 'group', 'manage'),
-- Admin permissions
('system_settings', 'Manage system settings', 'system', 'manage'),
('user_management', 'Manage all users', 'user', 'manage'),
('content_moderation', 'Moderate all content', 'content', 'moderate'),
('analytics_view', 'View analytics dashboards', 'analytics', 'read'),
('gdpr_manage', 'Process GDPR requests', 'gdpr', 'manage');

-- Assign permissions to roles
-- Admin gets all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'admin';

-- Moderator permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'moderator'
AND p.permission_name IN (
    'user_read',
    'post_read',
    'post_delete',
    'comment_read',
    'comment_delete',
    'content_moderation'
);

-- User permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'user'
AND p.permission_name IN (
    'user_read',
    'post_create',
    'post_read',
    'post_update',
    'post_delete',
    'comment_create',
    'comment_read',
    'comment_update',
    'comment_delete',
    'message_send',
    'message_read',
    'group_create',
    'group_join'
);

-- Content creator permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'content_creator'
AND p.permission_name IN (
    'user_read',
    'post_create',
    'post_read',
    'post_update',
    'post_delete',
    'comment_create',
    'comment_read',
    'comment_update',
    'comment_delete',
    'message_send',
    'message_read',
    'group_create',
    'group_join'
);

-- Analyst permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'analyst'
AND p.permission_name IN (
    'user_read',
    'post_read',
    'comment_read',
    'analytics_view'
);

-- Insert system countries
INSERT INTO system_countries (country_name, country_code, phone_code, currency_code) VALUES
('United States', 'US', '+1', 'USD'),
('United Kingdom', 'GB', '+44', 'GBP'),
('Canada', 'CA', '+1', 'CAD'),
('Australia', 'AU', '+61', 'AUD'),
('Germany', 'DE', '+49', 'EUR'),
('France', 'FR', '+33', 'EUR'),
('Japan', 'JP', '+81', 'JPY'),
('India', 'IN', '+91', 'INR'),
('Brazil', 'BR', '+55', 'BRL'),
('South Africa', 'ZA', '+27', 'ZAR');

-- Insert system genders
INSERT INTO system_genders (gender_name) VALUES
('Male'),
('Female'),
('Non-binary'),
('Other'),
('Prefer not to say');

-- Insert system languages
INSERT INTO system_languages (language_name, language_code, is_active, is_default) VALUES
('English', 'en', TRUE, TRUE),
('Spanish', 'es', TRUE, FALSE),
('French', 'fr', TRUE, FALSE),
('German', 'de', TRUE, FALSE),
('Japanese', 'ja', TRUE, FALSE),
('Chinese', 'zh', TRUE, FALSE),
('Russian', 'ru', TRUE, FALSE),
('Portuguese', 'pt', TRUE, FALSE),
('Arabic', 'ar', TRUE, FALSE),
('Hindi', 'hi', TRUE, FALSE);

-- Insert GDPR processing activities
INSERT INTO gdpr_processing_activities (
    activity_name,
    description,
    purpose,
    lawful_basis,
    data_categories,
    retention_period,
    data_recipients
) VALUES
(
    'User Account Management',
    'Processing of user account data for registration, authentication, and account management',
    'To provide and maintain user accounts on the platform',
    'Contractual necessity',
    'Username, email, password hash, name, profile information',
    '5 years after account deletion',
    'Internal systems only'
),
(
    'Content Sharing',
    'Processing of user-generated content shared on the platform',
    'To enable users to share content and interact with each other',
    'Legitimate interest',
    'Posts, comments, messages, media uploads',
    '3 years after account deletion',
    'Other platform users according to privacy settings'
),
(
    'Analytics and Improvement',
    'Processing of usage data for analytics and service improvement',
    'To analyze usage patterns and improve the platform',
    'Legitimate interest',
    'Usage logs, engagement metrics, device information',
    '2 years from collection',
    'Internal analytics team, third-party analytics providers'
),
(
    'Marketing Communications',
    'Processing of user data for marketing purposes',
    'To send promotional communications to users',
    'Consent',
    'Email address, name, preferences',
    'Until consent is withdrawn',
    'Marketing team, email service providers'
);

-- Insert data retention policies
INSERT INTO data_retention_policies (
    table_name,
    column_name,
    retention_period_days,
    action_after_retention,
    is_active
) VALUES
('user_activity_logs', 'activity_timestamp', 365, 'delete', TRUE),
('visitor_analytics', 'session_start_time', 180, 'archive', TRUE),
('audit_logs', 'action_timestamp', 730, 'archive', TRUE),
('gdpr_consents', 'granted_at', 1095, 'delete', TRUE),
('notifications', 'created_at', 90, 'delete', TRUE);

-- Insert data quality rules
INSERT INTO data_quality_rules (
    rule_name,
    table_name,
    column_name,
    rule_description,
    check_query,
    severity
) VALUES
(
    'user_email_format',
    'users',
    'email',
    'Check that user email addresses are in valid format',
    'email ~* ''^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$''',
    'high'
),
(
    'post_text_length',
    'posts',
    'post_text',
    'Check that post text does not exceed maximum length',
    'post_text IS NULL OR length(post_text) <= 10000',
    'medium'
),
(
    'active_user_session',
    'users_sessions',
    NULL,
    'Check that active sessions have recent activity',
    'NOT is_active OR last_activity_time > NOW() - INTERVAL ''30 minutes''',
    'high'
),
(
    'notification_read_status',
    'notifications',
    NULL,
    'Check that old notifications are marked as read',
    'NOT is_read OR created_at > NOW() - INTERVAL ''30 days''',
    'low'
);

-- Insert initial admin user (password hash is for "admin123" - should be changed in production)
INSERT INTO users (
    username,
    email,
    password_hash,
    first_name,
    last_name,
    is_verified,
    is_active
) VALUES (
    'admin',
    'admin@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMy.MrYV8Z7W27Z7kHm8pB.jn6L5.2QYy/G',
    'System',
    'Administrator',
    TRUE,
    TRUE
);

-- Assign admin role to admin user
INSERT INTO user_roles (user_id, role_id, assigned_by)
VALUES (
    (SELECT user_id FROM users WHERE username = 'admin'),
    (SELECT role_id FROM roles WHERE role_name = 'admin'),
    (SELECT user_id FROM users WHERE username = 'admin')
);

-- =============================================
-- SECTION 21: DOCUMENTATION
-- =============================================

COMMENT ON TABLE users IS 'Stores user account information including authentication details and profile data';
COMMENT ON COLUMN users.gdpr_consent_status IS 'Indicates whether the user has consented to GDPR data processing';
COMMENT ON COLUMN users.data_retention_preference IS 'User preference for data retention period (standard, reduced, extended)';

COMMENT ON TABLE gdpr_consents IS 'Tracks user consents for GDPR compliance, including type of consent and expiration';
COMMENT ON TABLE gdpr_data_subject_requests IS 'Records user requests under GDPR (access, rectification, erasure, etc.)';

COMMENT ON TABLE data_retention_policies IS 'Defines policies for how long different types of data should be retained';
COMMENT ON TABLE data_archive_logs IS 'Logs actions taken when data is archived or deleted according to retention policies';

COMMENT ON TABLE data_quality_rules IS 'Defines rules for ensuring data quality across the database';
COMMENT ON TABLE data_quality_logs IS 'Records the results of data quality rule executions';

COMMENT ON TABLE data_profiling_results IS 'Stores results of data profiling activities showing statistics about data distribution';
COMMENT ON TABLE data_lineage IS 'Documents the lineage of data elements showing sources and transformations';

COMMENT ON TABLE audit_logs IS 'Comprehensive log of all significant data changes and system actions for accountability';
COMMENT ON TABLE system_health_metrics IS 'Tracks key system health metrics over time for monitoring';

COMMENT ON TABLE user_activity_logs IS 'Detailed log of user activities for analytics and auditing';
COMMENT ON TABLE content_engagement_metrics IS 'Measures how users engage with different types of content';
COMMENT ON TABLE visitor_analytics IS 'Tracks anonymous visitor behavior for analytics purposes';
COMMENT ON TABLE kpi_metrics IS 'Stores calculated key performance indicators for reporting';

COMMENT ON TABLE roles IS 'Defines different roles in the system for RBAC (Role-Based Access Control)';
COMMENT ON TABLE permissions IS 'Defines individual permissions that can be assigned to roles';
COMMENT ON TABLE role_permissions IS 'Associates permissions with roles in a many-to-many relationship';
COMMENT ON TABLE user_roles IS 'Assigns roles to users in a many-to-many relationship';

-- COMMENT ON FUNCTION sp_create_user IS 'Creates a new user account with default settings and associated records';
-- COMMENT ON FUNCTION sp_deactivate_user IS 'Deactivates a user account and terminates all active sessions';
-- COMMENT ON FUNCTION sp_anonymize_user IS 'Anonymizes user data for GDPR compliance, removing PII while retaining some activity data';

-- COMMENT ON FUNCTION sp_process_gdpr_request IS 'Processes a GDPR request (access, rectification, erasure, etc.)';
-- COMMENT ON FUNCTION sp_apply_data_retention_policy IS 'Applies a data retention policy to the specified table, archiving or deleting old records';

-- COMMENT ON FUNCTION sp_execute_data_quality_check IS 'Executes a data quality rule and records the results';
-- COMMENT ON FUNCTION sp_perform_data_profiling IS 'Performs data profiling on a specific table column, collecting statistics about data distribution';

-- COMMENT ON FUNCTION sp_log_user_activity IS 'Records a user activity event for analytics and auditing';
-- COMMENT ON FUNCTION sp_log_content_engagement IS 'Records user engagement with content for analytics';
-- COMMENT ON FUNCTION sp_start_visitor_session IS 'Starts a new visitor session for analytics tracking';
-- COMMENT ON FUNCTION sp_end_visitor_session IS 'Ends an active visitor session';
-- COMMENT ON FUNCTION sp_increment_page_view IS 'Increments the page view count for a visitor session';
-- COMMENT ON FUNCTION sp_calculate_kpis IS 'Calculates key performance indicators for the specified time period';

COMMENT ON VIEW vw_user_profiles IS 'Provides a comprehensive view of user profiles with aggregated statistics';
COMMENT ON VIEW vw_post_engagement IS 'Shows engagement metrics for posts with calculated engagement scores';
COMMENT ON VIEW vw_daily_active_users IS 'Shows the count of daily active users over time';
COMMENT ON VIEW vw_content_performance IS 'Compares performance metrics across different content types';
COMMENT ON VIEW vw_user_activity_summary IS 'Summarizes user activity metrics for reporting and analytics';

-- COMMENT ON TRIGGER trg_update_last_message IS 'Updates the last message reference in conversations when new messages are added';
-- COMMENT ON TRIGGER trg_update_post_stats IS 'Updates post statistics when related content (comments, reactions) are added';
-- COMMENT ON TRIGGER trg_log_audit_on_user_update IS 'Logs changes to user data in the audit log for accountability';
-- COMMENT ON TRIGGER trg_check_data_quality_on_post IS 'Example data quality check that validates post content on insertion';



--enhanced content recommendation system
-- User content preferences
CREATE TABLE user_content_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    category_id INTEGER,
    preference_score NUMERIC(3,2) NOT NULL DEFAULT 0.5,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_preference_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Content similarity matrix
CREATE TABLE content_similarity (
    similarity_id SERIAL PRIMARY KEY,
    content_id1 INTEGER NOT NULL,
    content_type1 VARCHAR(50) NOT NULL,
    content_id2 INTEGER NOT NULL,
    content_type2 VARCHAR(50) NOT NULL,
    similarity_score NUMERIC(5,4) NOT NULL,
    last_calculated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--materialized views
-- Top recommended content per user (refreshed daily)
CREATE MATERIALIZED VIEW mv_user_content_recommendations AS
WITH user_engagement AS (
    SELECT
        user_id,
        content_type,
        content_id,
        COUNT(*) FILTER (WHERE engagement_type = 'view') AS view_count,
        COUNT(*) FILTER (WHERE engagement_type = 'like') AS like_count,
        COUNT(*) FILTER (WHERE engagement_type = 'comment') AS comment_count,
        COUNT(*) FILTER (WHERE engagement_type = 'share') AS share_count
    FROM content_engagement_metrics
    WHERE engagement_timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id, content_type, content_id
),
content_similarity AS (
    SELECT
        cs.content_id1 AS source_content_id,
        cs.content_type1 AS source_content_type,
        cs.content_id2 AS recommended_content_id,
        cs.content_type2 AS recommended_content_type,
        cs.similarity_score
    FROM content_similarity cs
    WHERE cs.similarity_score >= 0.7
)
SELECT
    u.user_id,
    r.recommended_content_type,
    r.recommended_content_id,
    SUM(
        CASE
            WHEN ue.view_count > 0 THEN ue.view_count * 0.1 * r.similarity_score
            WHEN ue.like_count > 0 THEN ue.like_count * 0.3 * r.similarity_score
            WHEN ue.comment_count > 0 THEN ue.comment_count * 0.5 * r.similarity_score
            WHEN ue.share_count > 0 THEN ue.share_count * 0.8 * r.similarity_score
            ELSE 0
        END
    ) AS recommendation_score
FROM user_engagement ue
JOIN content_similarity r ON ue.content_id = r.source_content_id AND ue.content_type = r.source_content_type
JOIN users u ON ue.user_id = u.user_id
GROUP BY u.user_id, r.recommended_content_type, r.recommended_content_id
ORDER BY u.user_id, recommendation_score DESC;

CREATE UNIQUE INDEX ON mv_user_content_recommendations (user_id, recommended_content_type, recommended_content_id);



---stored procedure
-- Procedure to refresh content recommendations
CREATE OR REPLACE PROCEDURE sp_refresh_content_recommendations()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_user_content_recommendations;
    INSERT INTO audit_logs (action_type, action_timestamp)
    VALUES ('REFRESH_CONTENT_RECOMMENDATIONS', CURRENT_TIMESTAMP);
END;
$$;

-- Procedure to calculate content similarity
CREATE OR REPLACE PROCEDURE sp_calculate_content_similarity()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear existing similarities
    TRUNCATE content_similarity;

    -- Calculate post similarity based on tags and engagement
    WITH post_tags AS (
        SELECT
            p.post_id,
            COUNT(ht.hashtag_id) AS tag_count,
            STRING_AGG(ht.hashtag_name, ' ') AS tag_text
        FROM posts p
        LEFT JOIN hashtags_posts hp ON p.post_id = hp.post_id
        LEFT JOIN hashtags ht ON hp.hashtag_id = ht.hashtag_id
        GROUP BY p.post_id
    ),
    post_vectors AS (
        SELECT
            post_id,
            to_tsvector('english', COALESCE(p.post_text, '') || ' ' || COALESCE(pt.tag_text, '')) AS search_vector
        FROM posts p
        JOIN post_tags pt ON p.post_id = pt.post_id
    )
    INSERT INTO content_similarity (
        content_id1, content_type1,
        content_id2, content_type2,
        similarity_score
    )
    SELECT
        p1.post_id, 'post',
        p2.post_id, 'post',
        ts_rank_cd(p1.search_vector, p2.search_vector) AS similarity_score
    FROM post_vectors p1
    CROSS JOIN post_vectors p2
    WHERE p1.post_id <> p2.post_id
    AND ts_rank_cd(p1.search_vector, p2.search_vector) > 0.5;

    -- Log the operation
    INSERT INTO audit_logs (action_type, action_timestamp)
    VALUES ('CALCULATE_CONTENT_SIMILARITY', CURRENT_TIMESTAMP);
END;
$$;


--advanced user segmentation
-- User segments
CREATE TABLE user_segments (
    segment_id SERIAL PRIMARY KEY,
    segment_name VARCHAR(100) NOT NULL,
    segment_description TEXT,
    is_system_segment BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Segment rules
CREATE TABLE segment_rules (
    rule_id SERIAL PRIMARY KEY,
    segment_id INTEGER NOT NULL,
    rule_condition JSONB NOT NULL,
    rule_order INTEGER NOT NULL,
    CONSTRAINT fk_rule_segment FOREIGN KEY (segment_id) REFERENCES user_segments(segment_id) ON DELETE CASCADE
);

-- User segment assignments
CREATE TABLE user_segment_assignments (
    assignment_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    segment_id INTEGER NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_assignment_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_segment FOREIGN KEY (segment_id) REFERENCES user_segments(segment_id) ON DELETE CASCADE,
    CONSTRAINT unique_user_segment UNIQUE (user_id, segment_id)
);

--materialized views
-- Active user segments (refreshed hourly)
CREATE MATERIALIZED VIEW mv_active_user_segments AS
SELECT
    s.segment_id,
    s.segment_name,
    COUNT(DISTINCT usa.user_id) AS user_count,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.created_at))/86400)::INTEGER AS avg_account_age_days,
    AVG(ue.engagement_score) AS avg_engagement_score
FROM user_segments s
JOIN user_segment_assignments usa ON s.segment_id = usa.segment_id
JOIN users u ON usa.user_id = u.user_id
LEFT JOIN (
    SELECT
        user_id,
        (COUNT(*) FILTER (WHERE activity_type = 'post_create') * 0.5 +
         COUNT(*) FILTER (WHERE activity_type = 'comment_create') * 0.3 +
         COUNT(*) FILTER (WHERE activity_type = 'like') * 0.2) AS engagement_score
    FROM user_activity_logs
    WHERE activity_timestamp >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY user_id
) ue ON usa.user_id = ue.user_id
WHERE usa.expires_at IS NULL OR usa.expires_at > CURRENT_TIMESTAMP
GROUP BY s.segment_id, s.segment_name
ORDER BY user_count DESC;

CREATE UNIQUE INDEX ON mv_active_user_segments (segment_id);


--stored procedures
-- Procedure to evaluate and assign user segments
CREATE OR REPLACE PROCEDURE sp_evaluate_user_segments()
LANGUAGE plpgsql
AS $$
DECLARE
    v_segment RECORD;
    v_rule RECORD;
    v_sql TEXT;
    v_where TEXT;
    v_condition TEXT;
BEGIN
    -- Clear existing temporary assignments
    DELETE FROM user_segment_assignments
    WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;

    -- Process each segment
    FOR v_segment IN SELECT * FROM user_segments WHERE is_system_segment = FALSE
    LOOP
        -- Build dynamic SQL for segment rules
        v_sql := 'INSERT INTO user_segment_assignments (user_id, segment_id) ' ||
                 'SELECT DISTINCT u.user_id, ' || v_segment.segment_id || ' FROM users u WHERE ';

        v_where := '';

        FOR v_rule IN SELECT * FROM segment_rules WHERE segment_id = v_segment.segment_id ORDER BY rule_order
        LOOP
            -- Convert JSON condition to SQL WHERE clause
            -- This is a simplified example - real implementation would need more complex parsing
            v_condition := ' (';

            IF v_rule.rule_condition->>'attribute' = 'account_age' THEN
                v_condition := v_condition || 'EXTRACT(DAY FROM (CURRENT_TIMESTAMP - u.created_at)) ' ||
                              v_rule.rule_condition->>'operator' || ' ' ||
                              (v_rule.rule_condition->>'value')::INTEGER;
            ELSIF v_rule.rule_condition->>'attribute' = 'engagement_level' THEN
                v_condition := v_condition || '(
                    SELECT COUNT(*) FROM user_activity_logs a
                    WHERE a.user_id = u.user_id AND
                    a.activity_timestamp >= CURRENT_DATE - INTERVAL ''30 days''
                ) ' || v_rule.rule_condition->>'operator' || ' ' ||
                (v_rule.rule_condition->>'value')::INTEGER;
            END IF;

            v_condition := v_condition || ') ';

            IF v_where <> '' THEN
                v_where := v_where || ' AND ';
            END IF;

            v_where := v_where || v_condition;
        END LOOP;

        -- Execute the dynamic SQL if we have conditions
        IF v_where <> '' THEN
            v_sql := v_sql || v_where ||
                    ' AND NOT EXISTS (
                        SELECT 1 FROM user_segment_assignments usa
                        WHERE usa.user_id = u.user_id AND usa.segment_id = ' ||
                        v_segment.segment_id || '
                    )';

            EXECUTE v_sql;
        END IF;
    END LOOP;

    -- Log the operation
    INSERT INTO audit_logs (action_type, action_timestamp)
    VALUES ('EVALUATE_USER_SEGMENTS', CURRENT_TIMESTAMP);
END;
$$;

-- Procedure to get users in a segment
CREATE OR REPLACE FUNCTION fn_get_segment_users(
    p_segment_id INTEGER,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR,
    email VARCHAR,
    account_age_days INTEGER,
    last_activity TIMESTAMP WITH TIME ZONE,
    engagement_score NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.username,
        u.email,
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - u.created_at))::INTEGER AS account_age_days,
        u.last_login AS last_activity,
        COALESCE((
            SELECT COUNT(*) FROM user_activity_logs a
            WHERE a.user_id = u.user_id AND
            a.activity_timestamp >= CURRENT_DATE - INTERVAL '30 days'
        ), 0) AS engagement_score
    FROM users u
    JOIN user_segment_assignments usa ON u.user_id = usa.user_id
    WHERE usa.segment_id = p_segment_id
    AND (usa.expires_at IS NULL OR usa.expires_at > CURRENT_TIMESTAMP)
    ORDER BY engagement_score DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;



--enhanced advertising system
-- Advertisers
CREATE TABLE advertisers (
    advertiser_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(50),
    billing_email VARCHAR(255) NOT NULL,
    billing_address JSONB NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_advertiser_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Ad campaigns
CREATE TABLE ad_campaigns (
    campaign_id SERIAL PRIMARY KEY,
    advertiser_id INTEGER NOT NULL,
    campaign_name VARCHAR(255) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    daily_budget DECIMAL(15,2) NOT NULL,
    total_budget DECIMAL(15,2) NOT NULL,
    bid_strategy VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    target_audience JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_campaign_advertiser FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id) ON DELETE CASCADE
);

-- Ad creatives
CREATE TABLE ad_creatives (
    creative_id SERIAL PRIMARY KEY,
    campaign_id INTEGER NOT NULL,
    creative_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    description TEXT,
    image_url VARCHAR(512),
    video_url VARCHAR(512),
    destination_url VARCHAR(512) NOT NULL,
    call_to_action VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_creative_campaign FOREIGN KEY (campaign_id) REFERENCES ad_campaigns(campaign_id) ON DELETE CASCADE
);

-- Ad placements
CREATE TABLE ad_placements (
    placement_id SERIAL PRIMARY KEY,
    placement_name VARCHAR(255) NOT NULL,
    placement_description TEXT,
    placement_type VARCHAR(50) NOT NULL,
    base_bid_price DECIMAL(15,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Ad delivery
CREATE TABLE ad_delivery (
    delivery_id SERIAL PRIMARY KEY,
    creative_id INTEGER NOT NULL,
    placement_id INTEGER NOT NULL,
    user_id INTEGER,
    display_count INTEGER NOT NULL DEFAULT 1,
    click_count INTEGER NOT NULL DEFAULT 0,
    conversion_count INTEGER NOT NULL DEFAULT 0,
    first_delivered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_delivered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_delivery_creative FOREIGN KEY (creative_id) REFERENCES ad_creatives(creative_id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_placement FOREIGN KEY (placement_id) REFERENCES ad_placements(placement_id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);


-- Campaign performance summary (refreshed hourly)
CREATE MATERIALIZED VIEW mv_campaign_performance AS
SELECT
    c.campaign_id,
    c.campaign_name,
    a.company_name AS advertiser_name,
    c.start_date,
    c.end_date,
    c.total_budget,
    c.daily_budget,
    SUM(d.display_count) AS total_impressions,
    SUM(d.click_count) AS total_clicks,
    SUM(d.conversion_count) AS total_conversions,
    CASE
        WHEN SUM(d.display_count) = 0 THEN 0
        ELSE (SUM(d.click_count)::NUMERIC / SUM(d.display_count)) * 100
    END AS ctr_percentage,
    CASE
        WHEN SUM(d.click_count) = 0 THEN 0
        ELSE (SUM(d.conversion_count)::NUMERIC / SUM(d.click_count)) * 100
    END AS conversion_rate,
    CASE
        WHEN SUM(d.click_count) = 0 THEN 0
        ELSE (c.total_budget / SUM(d.click_count))
    END AS cpc
FROM ad_campaigns c
JOIN advertisers a ON c.advertiser_id = a.advertiser_id
LEFT JOIN ad_creatives cr ON c.campaign_id = cr.campaign_id
LEFT JOIN ad_delivery d ON cr.creative_id = d.creative_id
WHERE c.status = 'active'
GROUP BY c.campaign_id, c.campaign_name, a.company_name, c.start_date, c.end_date, c.total_budget, c.daily_budget
ORDER BY total_clicks DESC;

CREATE UNIQUE INDEX ON mv_campaign_performance (campaign_id);

-- User ad engagement profile (refreshed daily)
CREATE MATERIALIZED VIEW mv_user_ad_profile AS
SELECT
    u.user_id,
    COUNT(DISTINCT d.creative_id) AS ads_seen_count,
    COUNT(DISTINCT CASE WHEN d.click_count > 0 THEN d.creative_id END) AS ads_clicked_count,
    COUNT(DISTINCT CASE WHEN d.conversion_count > 0 THEN d.creative_id END) AS ads_converted_count,
    CASE
        WHEN COUNT(DISTINCT d.creative_id) = 0 THEN 0
        ELSE (COUNT(DISTINCT CASE WHEN d.click_count > 0 THEN d.creative_id END)::NUMERIC /
             COUNT(DISTINCT d.creative_id)) * 100
    END AS click_rate,
    STRING_AGG(DISTINCT cr.creative_type, ', ') AS ad_types_seen,
    MODE() WITHIN GROUP (ORDER BY p.placement_type) AS most_common_placement_type,
    AVG(CASE WHEN d.click_count > 0 THEN 1 ELSE 0 END) AS avg_click_probability
FROM users u
LEFT JOIN ad_delivery d ON u.user_id = d.user_id
LEFT JOIN ad_creatives cr ON d.creative_id = cr.creative_id
LEFT JOIN ad_placements p ON d.placement_id = p.placement_id
GROUP BY u.user_id;

CREATE UNIQUE INDEX ON mv_user_ad_profile (user_id);


-- Procedure to select ad for user
CREATE OR REPLACE FUNCTION fn_select_ad_for_user(
    p_user_id INTEGER,
    p_placement_id INTEGER
)
RETURNS TABLE (
    creative_id INTEGER,
    title VARCHAR,
    description TEXT,
    image_url VARCHAR,
    video_url VARCHAR,
    destination_url VARCHAR,
    call_to_action VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH user_segments AS (
        SELECT segment_id FROM user_segment_assignments
        WHERE user_id = p_user_id AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    ),
    eligible_campaigns AS (
        SELECT c.campaign_id
        FROM ad_campaigns c
        WHERE c.status = 'active'
        AND CURRENT_TIMESTAMP BETWEEN c.start_date AND c.end_date
        AND (
            c.target_audience->>'segments' IS NULL OR
            EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(c.target_audience->'segments') s
                JOIN user_segments us ON s::INTEGER = us.segment_id
            )
        )
    ),
    eligible_creatives AS (
        SELECT
            cr.creative_id,
            cr.title,
            cr.description,
            cr.image_url,
            cr.video_url,
            cr.destination_url,
            cr.call_to_action,
            -- Scoring based on relevance and performance
            COALESCE((
                SELECT SUM(d.click_count) / NULLIF(SUM(d.display_count), 0)
                FROM ad_delivery d
                WHERE d.creative_id = cr.creative_id
            ), 0.1) AS performance_score,
            RANDOM() AS random_factor
        FROM ad_creatives cr
        JOIN eligible_campaigns ec ON cr.campaign_id = ec.campaign_id
        WHERE cr.is_active = TRUE
        AND EXISTS (
            SELECT 1 FROM ad_placements p
            WHERE p.placement_id = p_placement_id
            AND p.is_active = TRUE
        )
    )
    SELECT
        ec.creative_id,
        ec.title,
        ec.description,
        ec.image_url,
        ec.video_url,
        ec.destination_url,
        ec.call_to_action
    FROM eligible_creatives ec
    ORDER BY (ec.performance_score * 0.7 + ec.random_factor * 0.3) DESC
    LIMIT 1;
END;
$$;

-- Procedure to record ad delivery
CREATE OR REPLACE PROCEDURE sp_record_ad_delivery(
    p_creative_id INTEGER,
    p_placement_id INTEGER,
    p_user_id INTEGER DEFAULT NULL,
    p_clicked BOOLEAN DEFAULT FALSE,
    p_converted BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if delivery record already exists
    IF EXISTS (
        SELECT 1 FROM ad_delivery
        WHERE creative_id = p_creative_id
        AND placement_id = p_placement_id
        AND user_id = p_user_id
    ) THEN
        -- Update existing record
        UPDATE ad_delivery
        SET
            display_count = display_count + 1,
            click_count = click_count + CASE WHEN p_clicked THEN 1 ELSE 0 END,
            conversion_count = conversion_count + CASE WHEN p_converted THEN 1 ELSE 0 END,
            last_delivered_at = CURRENT_TIMESTAMP
        WHERE
            creative_id = p_creative_id
            AND placement_id = p_placement_id
            AND user_id = p_user_id;
    ELSE
        -- Insert new record
        INSERT INTO ad_delivery (
            creative_id,
            placement_id,
            user_id,
            display_count,
            click_count,
            conversion_count
        )
        VALUES (
            p_creative_id,
            p_placement_id,
            p_user_id,
            1,
            CASE WHEN p_clicked THEN 1 ELSE 0 END,
            CASE WHEN p_converted THEN 1 ELSE 0 END
        );
    END IF;

    -- Update campaign budget if this was a click or conversion
    IF p_clicked OR p_converted THEN
        UPDATE ad_campaigns c
        SET total_budget = total_budget - p.base_bid_price
        FROM ad_creatives cr, ad_placements p
        WHERE c.campaign_id = cr.campaign_id
        AND cr.creative_id = p_creative_id
        AND p.placement_id = p_placement_id;
    END IF;
END;
$$;


--enhanced community management

-- Community guidelines
CREATE TABLE community_guidelines (
    guideline_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    severity_level VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Moderator actions
CREATE TABLE moderator_actions (
    action_id SERIAL PRIMARY KEY,
    moderator_id INTEGER NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id INTEGER NOT NULL,
    reason VARCHAR(255),
    guideline_id INTEGER,
    details TEXT,
    action_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_action_moderator FOREIGN KEY (moderator_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_action_guideline FOREIGN KEY (guideline_id) REFERENCES community_guidelines(guideline_id) ON DELETE SET NULL
);

-- User moderation status
CREATE TABLE user_moderation_status (
    user_id INTEGER PRIMARY KEY,
    warning_count INTEGER NOT NULL DEFAULT 0,
    last_warning_date TIMESTAMP WITH TIME ZONE,
    is_restricted BOOLEAN NOT NULL DEFAULT FALSE,
    restriction_reason VARCHAR(255),
    restriction_end_date TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_moderation_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

--community health metrics
-- Community health metrics (refreshed daily)
CREATE MATERIALIZED VIEW mv_community_health AS
SELECT
    DATE_TRUNC('day', ma.action_timestamp)::DATE AS action_date,
    ma.action_type,
    COUNT(*) AS action_count,
    COUNT(DISTINCT ma.moderator_id) AS unique_moderators,
    COUNT(DISTINCT ma.target_id) FILTER (WHERE ma.target_type = 'user') AS affected_users,
    COUNT(DISTINCT ma.target_id) FILTER (WHERE ma.target_type = 'post') AS affected_posts,
    COUNT(DISTINCT ma.target_id) FILTER (WHERE ma.target_type = 'comment') AS affected_comments,
    AVG(ums.warning_count) AS avg_user_warnings
FROM moderator_actions ma
LEFT JOIN user_moderation_status ums ON ma.target_id = ums.user_id AND ma.target_type = 'user'
WHERE ma.action_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', ma.action_timestamp)::DATE, ma.action_type
ORDER BY action_date DESC, action_count DESC;

CREATE UNIQUE INDEX ON mv_community_health (action_date, action_type);

-- Top moderators (refreshed weekly)
CREATE MATERIALIZED VIEW mv_top_moderators AS
SELECT
    u.user_id,
    u.username,
    COUNT(*) FILTER (WHERE ma.action_type = 'content_removal') AS removals,
    COUNT(*) FILTER (WHERE ma.action_type = 'user_warning') AS warnings,
    COUNT(*) FILTER (WHERE ma.action_type = 'user_restriction') AS restrictions,
    COUNT(*) FILTER (WHERE ma.action_type = 'appeal_approval') AS appeals_approved,
    COUNT(*) FILTER (WHERE ma.action_type = 'appeal_rejection') AS appeals_rejected,
    COUNT(DISTINCT DATE_TRUNC('day', ma.action_timestamp)) AS active_days,
    COUNT(*) AS total_actions,
    MIN(ma.action_timestamp) AS first_action_date,
    MAX(ma.action_timestamp) AS last_action_date
FROM users u
JOIN moderator_actions ma ON u.user_id = ma.moderator_id
WHERE ma.action_timestamp >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY u.user_id, u.username
ORDER BY total_actions DESC
LIMIT 100;

CREATE UNIQUE INDEX ON mv_top_moderators (user_id);


-- Procedure to apply moderation action
CREATE OR REPLACE PROCEDURE sp_apply_moderation_action(
    p_moderator_id INTEGER,
    p_action_type VARCHAR,
    p_target_type VARCHAR,
    p_target_id INTEGER,
    p_reason VARCHAR DEFAULT NULL,
    p_guideline_id INTEGER DEFAULT NULL,
    p_details TEXT DEFAULT NULL,
    p_restriction_days INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_restriction_end TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Record the action
    INSERT INTO moderator_actions (
        moderator_id,
        action_type,
        target_type,
        target_id,
        reason,
        guideline_id,
        details
    )
    VALUES (
        p_moderator_id,
        p_action_type,
        p_target_type,
        p_target_id,
        p_reason,
        p_guideline_id,
        p_details
    );

    -- Handle user-specific actions
    IF p_target_type = 'user' THEN
        -- Initialize user moderation status if not exists
        INSERT INTO user_moderation_status (user_id)
        VALUES (p_target_id)
        ON CONFLICT (user_id) DO NOTHING;

        -- Update warning count
        IF p_action_type = 'user_warning' THEN
            UPDATE user_moderation_status
            SET
                warning_count = warning_count + 1,
                last_warning_date = CURRENT_TIMESTAMP
            WHERE user_id = p_target_id;

            -- Automatically restrict if too many warnings
            IF (SELECT warning_count FROM user_moderation_status WHERE user_id = p_target_id) >= 3 THEN
                v_restriction_end := CURRENT_TIMESTAMP + INTERVAL '7 days';

                UPDATE user_moderation_status
                SET
                    is_restricted = TRUE,
                    restriction_reason = 'Automatic restriction due to multiple warnings',
                    restriction_end_date = v_restriction_end
                WHERE user_id = p_target_id;

                -- Record the automatic restriction
                INSERT INTO moderator_actions (
                    moderator_id,
                    action_type,
                    target_type,
                    target_id,
                    reason,
                    details
                )
                VALUES (
                    p_moderator_id,
                    'user_restriction',
                    'user',
                    p_target_id,
                    'Automatic restriction due to multiple warnings',
                    'Applied after 3 warnings'
                );
            END IF;
        ELSIF p_action_type = 'user_restriction' AND p_restriction_days IS NOT NULL THEN
            v_restriction_end := CURRENT_TIMESTAMP + (p_restriction_days * INTERVAL '1 day');

            UPDATE user_moderation_status
            SET
                is_restricted = TRUE,
                restriction_reason = p_reason,
                restriction_end_date = v_restriction_end
            WHERE user_id = p_target_id;
        ELSIF p_action_type = 'user_restriction_removal' THEN
            UPDATE user_moderation_status
            SET
                is_restricted = FALSE,
                restriction_reason = NULL,
                restriction_end_date = NULL
            WHERE user_id = p_target_id;
        END IF;
    -- Handle content removal
    ELSIF p_action_type = 'content_removal' THEN
        IF p_target_type = 'post' THEN
            UPDATE posts SET is_deleted = TRUE WHERE post_id = p_target_id;
        ELSIF p_target_type = 'comment' THEN
            UPDATE posts_comments SET is_deleted = TRUE WHERE comment_id = p_target_id;
        END IF;
    END IF;

    -- Log the action
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        p_moderator_id,
        'MODERATION_ACTION',
        p_target_type || 's',
        p_target_id::TEXT,
        jsonb_build_object(
            'action_type', p_action_type,
            'reason', p_reason,
            'guideline_id', p_guideline_id
        )
    );
END;
$$;

-- Procedure to check restricted users
CREATE OR REPLACE PROCEDURE sp_check_restricted_users()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Lift expired restrictions
    UPDATE user_moderation_status
    SET
        is_restricted = FALSE,
        restriction_reason = NULL,
        restriction_end_date = NULL
    WHERE is_restricted = TRUE
    AND restriction_end_date < CURRENT_TIMESTAMP;

    -- Log the action
    INSERT INTO audit_logs (action_type, action_timestamp)
    VALUES ('CHECK_RESTRICTED_USERS', CURRENT_TIMESTAMP);
END;
$$;

--Realtime analytics dashboard
-- Dashboard widgets
CREATE TABLE dashboard_widgets (
    widget_id SERIAL PRIMARY KEY,
    widget_name VARCHAR(255) NOT NULL,
    widget_description TEXT,
    widget_type VARCHAR(50) NOT NULL,
    data_source VARCHAR(255) NOT NULL,
    refresh_interval INTEGER NOT NULL DEFAULT 3600,
    is_system_widget BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- User dashboard configurations
CREATE TABLE user_dashboards (
    dashboard_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    dashboard_name VARCHAR(255) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dashboard_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Dashboard widget assignments
CREATE TABLE dashboard_widget_assignments (
    assignment_id SERIAL PRIMARY KEY,
    dashboard_id INTEGER NOT NULL,
    widget_id INTEGER NOT NULL,
    position_x INTEGER NOT NULL,
    position_y INTEGER NOT NULL,
    width INTEGER NOT NULL DEFAULT 2,
    height INTEGER NOT NULL DEFAULT 2,
    CONSTRAINT fk_assignment_dashboard FOREIGN KEY (dashboard_id) REFERENCES user_dashboards(dashboard_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_widget FOREIGN KEY (widget_id) REFERENCES dashboard_widgets(widget_id) ON DELETE CASCADE
);

-- Cached widget data
CREATE TABLE widget_data_cache (
    cache_id SERIAL PRIMARY KEY,
    widget_id INTEGER NOT NULL,
    data JSONB NOT NULL,
    cached_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_cache_widget FOREIGN KEY (widget_id) REFERENCES dashboard_widgets(widget_id) ON DELETE CASCADE
);


--stored procedures

-- Procedure to refresh widget data
CREATE OR REPLACE PROCEDURE sp_refresh_widget_data(
    p_widget_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_widget RECORD;
    v_data JSONB;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get widget details
    SELECT * INTO v_widget FROM dashboard_widgets WHERE widget_id = p_widget_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Widget with ID % not found', p_widget_id;
    END IF;
    
    -- Generate data based on widget type
    CASE v_widget.widget_type
        WHEN 'user_growth' THEN
            SELECT INTO v_data (
                SELECT jsonb_build_object(
                    'total_users', (SELECT COUNT(*) FROM users),
                    'new_users_today', (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE),
                    'new_users_week', (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
                    'active_users_today', (SELECT COUNT(DISTINCT user_id) FROM user_activity_logs WHERE activity_timestamp >= CURRENT_DATE)
                )
            );
            
        WHEN 'content_metrics' THEN
            SELECT INTO v_data (
                SELECT jsonb_build_object(
                    'total_posts', (SELECT COUNT(*) FROM posts),
                    'posts_today', (SELECT COUNT(*) FROM posts WHERE post_time >= CURRENT_DATE),
                    'total_comments', (SELECT COUNT(*) FROM posts_comments),
                    'comments_today', (SELECT COUNT(*) FROM posts_comments WHERE comment_time >= CURRENT_DATE)
                )
            );
            
        WHEN 'engagement_metrics' THEN
            SELECT INTO v_data (
                SELECT jsonb_build_object(
                    'avg_engagement', (SELECT AVG(post_views * 0.1 + post_likes * 0.5 + post_comments * 0.8 + post_shares * 1.0) FROM posts),
                    'top_posts', (
                        SELECT jsonb_agg(jsonb_build_object(
                            'post_id', post_id,
                            'user_id', user_id,
                            'engagement_score', post_views * 0.1 + post_likes * 0.5 + post_comments * 0.8 + post_shares * 1.0
                        ))
                        FROM posts
                        ORDER BY post_views * 0.1 + post_likes * 0.5 + post_comments * 0.8 + post_shares * 1.0 DESC
                        LIMIT 5
                    )
                )
            );
            
        WHEN 'revenue_metrics' THEN
            SELECT INTO v_data (
                SELECT jsonb_build_object(
                    'total_revenue', (SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE transaction_type = 'deposit'),
                    'today_revenue', (SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE transaction_type = 'deposit' AND transaction_time >= CURRENT_DATE),
                    'top_revenue_sources', (
                        SELECT jsonb_agg(jsonb_build_object(
                            'source', transaction_type,
                            'amount', SUM(amount)
                        ))
                        FROM wallet_transactions
                        WHERE transaction_time >= CURRENT_DATE - INTERVAL '30 days'
                        GROUP BY transaction_type
                        ORDER BY SUM(amount) DESC
                        LIMIT 5
                    )
                )
            );
            
        ELSE
            RAISE EXCEPTION 'Unknown widget type: %', v_widget.widget_type;
    END CASE;
    
    -- Set expiration time
    v_expires_at := CURRENT_TIMESTAMP + (v_widget.refresh_interval * INTERVAL '1 second');
    
    -- Update or insert cache
    IF EXISTS (SELECT 1 FROM widget_data_cache WHERE widget_id = p_widget_id) THEN
        UPDATE widget_data_cache
        SET 
            data = v_data,
            cached_at = CURRENT_TIMESTAMP,
            expires_at = v_expires_at
        WHERE widget_id = p_widget_id;
    ELSE
        INSERT INTO widget_data_cache (
            widget_id,
            data,
            expires_at
        )
        VALUES (
            p_widget_id,
            v_data,
            v_expires_at
        );
    END IF;
    
    -- Log the refresh
    INSERT INTO audit_logs (
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        'REFRESH_WIDGET_DATA',
        'dashboard_widgets',
        p_widget_id::TEXT,
        jsonb_build_object('widget_type', v_widget.widget_type)
    );
END;
$$;

-- Procedure to get dashboard data
CREATE OR REPLACE FUNCTION fn_get_dashboard_data(
    p_dashboard_id INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSONB := '[]'::JSONB;
    v_widget RECORD;
BEGIN
    FOR v_widget IN 
        SELECT 
            w.widget_id,
            w.widget_name,
            w.widget_type,
            w.data_source,
            wc.data AS cached_data,
            wc.expires_at
        FROM dashboard_widget_assignments dwa
        JOIN dashboard_widgets w ON dwa.widget_id = w.widget_id
        LEFT JOIN widget_data_cache wc ON w.widget_id = wc.widget_id
        WHERE dwa.dashboard_id = p_dashboard_id
        ORDER BY dwa.position_y, dwa.position_x
    LOOP
        -- Refresh data if expired or not available
        IF v_widget.cached_data IS NULL OR v_widget.expires_at < CURRENT_TIMESTAMP THEN
            CALL sp_refresh_widget_data(v_widget.widget_id);
            
            SELECT data INTO v_widget.cached_data
            FROM widget_data_cache
            WHERE widget_id = v_widget.widget_id;
        END IF;
        
        -- Add widget to result
        v_result := jsonb_insert(
            v_result,
            '{0}',
            jsonb_build_object(
                'widget_id', v_widget.widget_id,
                'widget_name', v_widget.widget_name,
                'widget_type', v_widget.widget_type,
                'data', v_widget.cached_data
            )
        );
    END LOOP;
    
    RETURN v_result;
END;
$$;

--enhanced notifications system

-- Notification templates
CREATE TABLE notification_templates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(255) NOT NULL,
    template_key VARCHAR(100) NOT NULL UNIQUE,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Notification delivery methods
CREATE TABLE notification_delivery_methods (
    method_id SERIAL PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL,
    method_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    config JSONB
);

-- Notification queue
CREATE TABLE notification_queue (
    queue_id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    delivery_method_id INTEGER NOT NULL,
    context_data JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    priority INTEGER NOT NULL DEFAULT 0,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_queue_template FOREIGN KEY (template_id) REFERENCES notification_templates(template_id) ON DELETE CASCADE,
    CONSTRAINT fk_queue_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_queue_method FOREIGN KEY (delivery_method_id) REFERENCES notification_delivery_methods(method_id) ON DELETE CASCADE
);

--stored procedure 
-- Procedure to queue notification
CREATE OR REPLACE PROCEDURE sp_queue_notification(
    p_template_key VARCHAR,
    p_user_id INTEGER,
    p_context_data JSONB,
    p_delivery_method_type VARCHAR DEFAULT 'in_app',
    p_priority INTEGER DEFAULT 0,
    p_scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_template_id INTEGER;
    v_method_id INTEGER;
BEGIN
    -- Get template ID
    SELECT template_id INTO v_template_id
    FROM notification_templates
    WHERE template_key = p_template_key
    AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Notification template with key % not found or inactive', p_template_key;
    END IF;
    
    -- Get delivery method ID
    SELECT method_id INTO v_method_id
    FROM notification_delivery_methods
    WHERE method_type = p_delivery_method_type
    AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Delivery method with type % not found or inactive', p_delivery_method_type;
    END IF;
    
    -- Insert into queue
    INSERT INTO notification_queue (
        template_id,
        user_id,
        delivery_method_id,
        context_data,
        priority,
        scheduled_at
    )
    VALUES (
        v_template_id,
        p_user_id,
        v_method_id,
        p_context_data,
        p_priority,
        COALESCE(p_scheduled_at, CURRENT_TIMESTAMP)
    );
    
    -- Log the action
    INSERT INTO audit_logs (
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        'QUEUE_NOTIFICATION',
        'notification_queue',
        currval('notification_queue_queue_id_seq')::TEXT,
        jsonb_build_object(
            'template_key', p_template_key,
            'user_id', p_user_id,
            'delivery_method', p_delivery_method_type
        )
    );
END;
$$;

-- Procedure to process notification queue
CREATE OR REPLACE PROCEDURE sp_process_notification_queue(
    p_batch_size INTEGER DEFAULT 100
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_notification RECORD;
    v_subject TEXT;
    v_body TEXT;
    v_success BOOLEAN;
    v_error_message TEXT;
    key TEXT; -- Variable to hold JSONB key during iteration
BEGIN
    -- Process pending notifications in priority order
    FOR v_notification IN 
        SELECT 
            q.queue_id,
            q.template_id,
            q.user_id,
            q.delivery_method_id,
            q.context_data,
            t.template_key,
            t.subject_template,
            t.body_template,
            m.method_type
        FROM notification_queue q
        JOIN notification_templates t ON q.template_id = t.template_id
        JOIN notification_delivery_methods m ON q.delivery_method_id = m.method_id
        WHERE q.status = 'pending'
        AND q.scheduled_at <= CURRENT_TIMESTAMP
        ORDER BY q.priority DESC, q.scheduled_at
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    LOOP
        BEGIN
            -- Reset variables for each notification
            v_subject := v_notification.subject_template;
            v_body := v_notification.body_template;

            -- Render templates with context data
            FOREACH key IN ARRAY array(SELECT jsonb_object_keys(v_notification.context_data))
            LOOP
                v_subject := REPLACE(v_subject, '{' || key || '}', v_notification.context_data->>key);
                v_body := REPLACE(v_body, '{' || key || '}', v_notification.context_data->>key);
            END LOOP;
            
            -- Process based on delivery method
            CASE v_notification.method_type
                WHEN 'in_app' THEN
                    -- Insert in-app notification
                    INSERT INTO notifications (
                        user_id,
                        notifier_id,
                        type,
                        entity_id,
                        created_at
                    )
                    VALUES (
                        v_notification.user_id,
                        COALESCE((v_notification.context_data->>'actor_id')::INTEGER, 0),
                        v_notification.template_key,
                        (v_notification.context_data->>'entity_id')::INTEGER,
                        CURRENT_TIMESTAMP
                    );
                    
                    v_success := TRUE;
                    
                WHEN 'email' THEN
                    -- In production, this would call an email service
                    -- For now, just log that we would send an email
                    INSERT INTO audit_logs (
                        action_type,
                        table_name,
                        record_id,
                        details
                    )
                    VALUES (
                        'SEND_EMAIL_NOTIFICATION',
                        'notification_queue',
                        v_notification.queue_id::TEXT,
                        jsonb_build_object(
                            'user_id', v_notification.user_id,
                            'subject', v_subject,
                            'body', v_body
                        )
                    );
                    
                    v_success := TRUE;
                    
                WHEN 'push' THEN
                    -- In production, this would call a push notification service
                    -- For now, just log that we would send a push
                    INSERT INTO audit_logs (
                        action_type,
                        table_name,
                        record_id,
                        details
                    )
                    VALUES (
                        'SEND_PUSH_NOTIFICATION',
                        'notification_queue',
                        v_notification.queue_id::TEXT,
                        jsonb_build_object(
                            'user_id', v_notification.user_id,
                            'title', v_subject,
                            'message', v_body
                        )
                    );
                    
                    v_success := TRUE;
                    
                ELSE
                    v_success := FALSE;
                    v_error_message := 'Unknown delivery method: ' || v_notification.method_type;
            END CASE;
            
            -- Update queue status
            IF v_success THEN
                UPDATE notification_queue
                SET 
                    status = 'delivered',
                    processed_at = CURRENT_TIMESTAMP
                WHERE queue_id = v_notification.queue_id;
            ELSE
                UPDATE notification_queue
                SET 
                    status = CASE WHEN retry_count >= 3 THEN 'failed' ELSE 'retry' END,
                    processed_at = CURRENT_TIMESTAMP,
                    retry_count = retry_count + 1
                WHERE queue_id = v_notification.queue_id;
                
                -- Log the failure
                INSERT INTO audit_logs (
                    action_type,
                    table_name,
                    record_id,
                    details
                )
                VALUES (
                    'NOTIFICATION_DELIVERY_FAILED',
                    'notification_queue',
                    v_notification.queue_id::TEXT,
                    jsonb_build_object(
                        'error', v_error_message,
                        'retry_count', v_notification.retry_count + 1
                    )
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Log the error
                INSERT INTO audit_logs (
                    action_type,
                    action_timestamp,
                    table_name,
                    record_id,
                    details
                )
                VALUES (
                    'NOTIFICATION_PROCESSING_ERROR',
                    CURRENT_TIMESTAMP,
                    'notification_queue',
                    v_notification.queue_id::TEXT,
                    jsonb_build_object(
                        'error', SQLERRM,
                        'sqlstate', SQLSTATE
                    )
                );
                
                -- Mark as failed
                UPDATE notification_queue
                SET 
                    status = 'failed',
                    processed_at = CURRENT_TIMESTAMP
                WHERE queue_id = v_notification.queue_id;
        END;
    END LOOP;
    
    -- Log the batch processing
    INSERT INTO audit_logs (action_type, action_timestamp)
    VALUES ('PROCESS_NOTIFICATION_QUEUE', CURRENT_TIMESTAMP);
END;
$$;


----webhook integrations 
-- Webhook endpoints
CREATE TABLE webhook_endpoints (
    endpoint_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(512) NOT NULL,
    secret_key VARCHAR(256),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER NOT NULL,
    last_modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_webhook_creator FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Webhook events
CREATE TABLE webhook_events (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Webhook subscriptions
CREATE TABLE webhook_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    endpoint_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    config JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_endpoint FOREIGN KEY (endpoint_id) REFERENCES webhook_endpoints(endpoint_id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_event FOREIGN KEY (event_id) REFERENCES webhook_events(event_id) ON DELETE CASCADE,
    CONSTRAINT unique_endpoint_event UNIQUE (endpoint_id, event_id)
);

-- Webhook delivery logs
CREATE TABLE webhook_delivery_logs (
    log_id SERIAL PRIMARY KEY,
    subscription_id INTEGER NOT NULL,
    payload JSONB NOT NULL,
    response_status INTEGER,
    response_body TEXT,
    attempt_count INTEGER NOT NULL DEFAULT 1,
    delivered_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_log_subscription FOREIGN KEY (subscription_id) REFERENCES webhook_subscriptions(subscription_id) ON DELETE CASCADE
);

--stored procedures 
-- Procedure to dispatch webhook event
CREATE OR REPLACE PROCEDURE sp_dispatch_webhook_event(
    p_event_name VARCHAR,
    p_payload JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_subscription RECORD;
    v_signature TEXT;
    v_log_id BIGINT;
BEGIN
    -- Find all active subscriptions for this event
    FOR v_subscription IN 
        SELECT 
            s.subscription_id,
            e.url,
            e.secret_key
        FROM webhook_subscriptions s
        JOIN webhook_endpoints e ON s.endpoint_id = e.endpoint_id
        JOIN webhook_events ev ON s.event_id = ev.event_id
        WHERE ev.event_name = p_event_name
        AND s.is_active = TRUE
        AND e.is_active = TRUE
    LOOP
        -- In a real implementation, this would make an HTTP request to the webhook URL
        -- For this example, we'll simulate the process and log it
        
        -- Generate signature if secret key exists
        IF v_subscription.secret_key IS NOT NULL THEN
            v_signature := encode(hmac(p_payload::text, v_subscription.secret_key, 'sha256'), 'hex');
        ELSE
            v_signature := NULL;
        END IF;
        
        -- Log the delivery attempt
        INSERT INTO webhook_delivery_logs (
            subscription_id,
            payload,
            created_at,
            next_retry_at
        )
        VALUES (
            v_subscription.subscription_id,
            jsonb_set(p_payload, '{metadata}', jsonb_build_object(
                'attempt', 1,
                'signature', v_signature,
                'event', p_event_name
            )),
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '5 minutes'
        )
        RETURNING log_id INTO v_log_id;
        
        -- Log the action
        INSERT INTO audit_logs (
            action_type,
            table_name,
            record_id,
            details
        )
        VALUES (
            'WEBHOOK_DISPATCH',
            'webhook_delivery_logs',
            v_log_id::TEXT,
            jsonb_build_object(
                'event', p_event_name,
                'subscription_id', v_subscription.subscription_id,
                'endpoint_url', v_subscription.url
            )
        );
    END LOOP;
END;
$$;

-- Procedure to retry failed webhooks
CREATE OR REPLACE PROCEDURE sp_retry_failed_webhooks(
    p_max_attempts INTEGER DEFAULT 3,
    p_batch_size INTEGER DEFAULT 100
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_log RECORD;
    v_updated_count INTEGER := 0;
BEGIN
    -- Process failed webhooks that are due for retry
    FOR v_log IN 
        SELECT log_id, subscription_id, payload
        FROM webhook_delivery_logs
        WHERE delivered_at IS NULL
        AND (failed_at IS NULL OR failed_at < CURRENT_TIMESTAMP - INTERVAL '1 hour')
        AND attempt_count < p_max_attempts
        AND next_retry_at <= CURRENT_TIMESTAMP
        ORDER BY created_at
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    LOOP
        -- Simulate retry (in practice, this would make an HTTP request)
        UPDATE webhook_delivery_logs
        SET 
            attempt_count = attempt_count + 1,
            next_retry_at = CURRENT_TIMESTAMP + (LEAST(attempt_count, 5) * INTERVAL '5 minutes')
        WHERE log_id = v_log.log_id;
        
        v_updated_count := v_updated_count + 1;
        
        -- Log the retry
        INSERT INTO audit_logs (
            action_type,
            table_name,
            record_id,
            details
        )
        VALUES (
            'WEBHOOK_RETRY',
            'webhook_delivery_logs',
            v_log.log_id::TEXT,
            jsonb_build_object(
                'attempt', v_log.attempt_count + 1,
                'max_attempts', p_max_attempts
            )
        );
    END LOOP;
    
    -- Log the batch processing
    INSERT INTO audit_logs (
        action_type,
        details
    )
    VALUES (
        'WEBHOOK_RETRY_BATCH',
        jsonb_build_object('processed_count', v_updated_count)
    );
END;
$$;

-- Common webhook events
INSERT INTO webhook_events (event_name, description) VALUES
('user.registered', 'Triggered when a new user registers'),
('user.deleted', 'Triggered when a user account is deleted'),
('content.created', 'Triggered when new content is posted'),
('content.updated', 'Triggered when content is updated'),
('content.deleted', 'Triggered when content is deleted'),
('message.sent', 'Triggered when a new message is sent'),
('payment.processed', 'Triggered when a payment is processed'),
('moderation.action', 'Triggered when a moderation action occurs');


--Real-time chat analytics 
-- Chat quality metrics
CREATE TABLE chat_quality_metrics (
    metric_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    metric_value NUMERIC NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_metric_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE
);

-- Chat sentiment analysis
CREATE TABLE chat_sentiment_analysis (
    analysis_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    message_id INTEGER,
    sentiment_score NUMERIC(5,4) NOT NULL,
    sentiment_label VARCHAR(50) NOT NULL,
    keywords TEXT[],
    analyzed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_analysis_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    CONSTRAINT fk_analysis_message FOREIGN KEY (message_id) REFERENCES conversations_messages(message_id) ON DELETE CASCADE
);

-- Chat response times
CREATE TABLE chat_response_times (
    response_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    message_id INTEGER NOT NULL,
    responder_id INTEGER NOT NULL,
    response_time_seconds INTEGER NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_response_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    CONSTRAINT fk_response_message FOREIGN KEY (message_id) REFERENCES conversations_messages(message_id) ON DELETE CASCADE,
    CONSTRAINT fk_response_responder FOREIGN KEY (responder_id) REFERENCES users(user_id) ON DELETE CASCADE
);

--materialized views 
-- Conversation quality summary (refreshed hourly)
CREATE MATERIALIZED VIEW mv_conversation_quality AS
SELECT 
    c.conversation_id,
    c.is_group,
    COUNT(DISTINCT cm.message_id) AS message_count,
    COUNT(DISTINCT cm.user_id) AS participant_count,
    AVG(cqm.metric_value) FILTER (WHERE cqm.metric_name = 'sentiment') AS avg_sentiment,
    AVG(crt.response_time_seconds) AS avg_response_time_seconds,
    COUNT(DISTINCT crt.responder_id) AS active_responders,
    MIN(cm.time) AS first_message_time,
    MAX(cm.time) AS last_message_time
FROM conversations c
LEFT JOIN conversations_messages cm ON c.conversation_id = cm.conversation_id
LEFT JOIN chat_quality_metrics cqm ON c.conversation_id = cqm.conversation_id
LEFT JOIN chat_response_times crt ON c.conversation_id = crt.conversation_id
GROUP BY c.conversation_id, c.is_group;

CREATE UNIQUE INDEX ON mv_conversation_quality (conversation_id);

-- User chat performance (refreshed daily)
CREATE MATERIALIZED VIEW mv_user_chat_performance AS
SELECT 
    u.user_id,
    u.username,
    COUNT(DISTINCT c.conversation_id) AS conversation_count,
    COUNT(DISTINCT cm.message_id) AS message_count,
    AVG(crt.response_time_seconds) AS avg_response_time_seconds,
    AVG(csa.sentiment_score) AS avg_sentiment_score,
    COUNT(DISTINCT CASE WHEN c.is_group THEN c.conversation_id END) AS group_chat_count,
    COUNT(DISTINCT CASE WHEN NOT c.is_group THEN c.conversation_id END) AS direct_chat_count,
    MIN(cm.time) AS first_message_time,
    MAX(cm.time) AS last_message_time
FROM users u
LEFT JOIN conversations_messages cm ON u.user_id = cm.user_id
LEFT JOIN conversations c ON cm.conversation_id = c.conversation_id
LEFT JOIN chat_response_times crt ON cm.message_id = crt.message_id AND u.user_id = crt.responder_id
LEFT JOIN chat_sentiment_analysis csa ON cm.message_id = csa.message_id
GROUP BY u.user_id, u.username;

CREATE UNIQUE INDEX ON mv_user_chat_performance (user_id);

--stored procedures 
-- Procedure to analyze conversation sentiment
CREATE OR REPLACE PROCEDURE sp_analyze_conversation_sentiment(
    p_conversation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_message RECORD;
    v_sentiment_score NUMERIC;
    v_sentiment_label VARCHAR;
    v_keywords TEXT[];
BEGIN
    -- Clear existing analysis for this conversation
    DELETE FROM chat_sentiment_analysis WHERE conversation_id = p_conversation_id;
    
    -- Analyze each message (simplified example - in practice would call a sentiment analysis API)
    FOR v_message IN 
        SELECT 
            message_id,
            message
        FROM conversations_messages
        WHERE conversation_id = p_conversation_id
        AND message IS NOT NULL
    LOOP
        -- Simulate sentiment analysis (real implementation would use a proper NLP service)
        -- This is a placeholder for the actual analysis logic
        v_sentiment_score := (random() * 2) - 1; -- Random score between -1 and 1
        IF v_sentiment_score > 0.5 THEN
            v_sentiment_label := 'positive';
        ELSIF v_sentiment_score < -0.5 THEN
            v_sentiment_label := 'negative';
        ELSE
            v_sentiment_label := 'neutral';
        END IF;
        
        -- Simple keyword extraction (placeholder)
        v_keywords := ARRAY(
            SELECT DISTINCT LOWER(word)
            FROM regexp_split_to_table(v_message.message, '\s+') AS word
            WHERE length(word) > 3
            AND word !~ '^[0-9]+$'
            LIMIT 5
        );
        
        -- Store the analysis
        INSERT INTO chat_sentiment_analysis (
            conversation_id,
            message_id,
            sentiment_score,
            sentiment_label,
            keywords
        )
        VALUES (
            p_conversation_id,
            v_message.message_id,
            v_sentiment_score,
            v_sentiment_label,
            v_keywords
        );
    END LOOP;
    
    -- Calculate and store conversation-level sentiment
    INSERT INTO chat_quality_metrics (
        conversation_id,
        metric_name,
        metric_value
    )
    SELECT 
        p_conversation_id,
        'sentiment',
        AVG(sentiment_score)
    FROM chat_sentiment_analysis
    WHERE conversation_id = p_conversation_id;
    
    -- Log the analysis
    INSERT INTO audit_logs (
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        'ANALYZE_CONVERSATION_SENTIMENT',
        'conversations',
        p_conversation_id::TEXT,
        jsonb_build_object(
            'messages_analyzed', (SELECT COUNT(*) FROM conversations_messages WHERE conversation_id = p_conversation_id),
            'avg_sentiment', (SELECT AVG(sentiment_score) FROM chat_sentiment_analysis WHERE conversation_id = p_conversation_id)
        )
    );
END;
$$;

-- Procedure to calculate response times
CREATE OR REPLACE PROCEDURE sp_calculate_response_times(
    p_conversation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_previous_message RECORD;
    v_response_time INTEGER;
BEGIN
    -- Clear existing response times for this conversation
    DELETE FROM chat_response_times WHERE conversation_id = p_conversation_id;
    
    -- Calculate response times between messages
    FOR v_previous_message IN 
        SELECT 
            message_id,
            user_id,
            time
        FROM conversations_messages
        WHERE conversation_id = p_conversation_id
        ORDER BY time
    LOOP
        -- Find the next message by a different user
        SELECT 
            EXTRACT(EPOCH FROM (cm.time - v_previous_message.time))::INTEGER,
            cm.message_id,
            cm.user_id
        INTO v_response_time
        FROM conversations_messages cm
        WHERE cm.conversation_id = p_conversation_id
        AND cm.time > v_previous_message.time
        AND cm.user_id <> v_previous_message.user_id
        ORDER BY cm.time
        LIMIT 1;
        
        -- Store the response time if found
        IF v_response_time IS NOT NULL THEN
            INSERT INTO chat_response_times (
                conversation_id,
                message_id,
                responder_id,
                response_time_seconds
            )
            VALUES (
                p_conversation_id,
                v_previous_message.message_id,
                v_previous_message.user_id,
                v_response_time
            );
        END IF;
    END LOOP;
    
    -- Calculate and store average response time metric
    INSERT INTO chat_quality_metrics (
        conversation_id,
        metric_name,
        metric_value
    )
    SELECT 
        p_conversation_id,
        'avg_response_time',
        AVG(response_time_seconds)
    FROM chat_response_times
    WHERE conversation_id = p_conversation_id;
    
    -- Log the calculation
    INSERT INTO audit_logs (
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        'CALCULATE_RESPONSE_TIMES',
        'conversations',
        p_conversation_id::TEXT,
        jsonb_build_object(
            'avg_response_time_seconds', (SELECT AVG(response_time_seconds) FROM chat_response_times WHERE conversation_id = p_conversation_id),
            'response_pairs_count', (SELECT COUNT(*) FROM chat_response_times WHERE conversation_id = p_conversation_id)
        )
    );
END;
$$;


--AB Testing Framework 
-- A/B test experiments
CREATE TABLE ab_test_experiments (
    experiment_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_experiment_creator FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Experiment variants
CREATE TABLE ab_test_variants (
    variant_id SERIAL PRIMARY KEY,
    experiment_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    allocation_percentage NUMERIC(5,2) NOT NULL,
    config JSONB NOT NULL,
    is_control BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_variant_experiment FOREIGN KEY (experiment_id) REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE
);

-- User variant assignments
CREATE TABLE ab_test_assignments (
    assignment_id SERIAL PRIMARY KEY,
    experiment_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_assignment_experiment FOREIGN KEY (experiment_id) REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_variant FOREIGN KEY (variant_id) REFERENCES ab_test_variants(variant_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_user_experiment UNIQUE (experiment_id, user_id)
);

-- Experiment metrics
CREATE TABLE ab_test_metrics (
    metric_id SERIAL PRIMARY KEY,
    experiment_id INTEGER NOT NULL,
    metric_name VARCHAR(255) NOT NULL,
    metric_description TEXT,
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    aggregation_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_metric_experiment FOREIGN KEY (experiment_id) REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE
);

-- Experiment results
CREATE TABLE ab_test_results (
    result_id SERIAL PRIMARY KEY,
    experiment_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    metric_id INTEGER NOT NULL,
    value NUMERIC NOT NULL,
    sample_size INTEGER NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_result_experiment FOREIGN KEY (experiment_id) REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE,
    CONSTRAINT fk_result_variant FOREIGN KEY (variant_id) REFERENCES ab_test_variants(variant_id) ON DELETE CASCADE,
    CONSTRAINT fk_result_metric FOREIGN KEY (metric_id) REFERENCES ab_test_metrics(metric_id) ON DELETE CASCADE
);

--stored procedures 
-- Procedure to assign user to experiment variant
CREATE OR REPLACE FUNCTION fn_assign_user_to_experiment(
    p_user_id INTEGER,
    p_experiment_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_variant_id INTEGER;
    v_assignment_id INTEGER;
    v_random NUMERIC;
BEGIN
    -- Check if user is already assigned
    SELECT variant_id INTO v_variant_id
    FROM ab_test_assignments
    WHERE user_id = p_user_id AND experiment_id = p_experiment_id;
    
    IF v_variant_id IS NOT NULL THEN
        RETURN v_variant_id;
    END IF;
    
    -- Get active experiment
    IF NOT EXISTS (
        SELECT 1 FROM ab_test_experiments 
        WHERE experiment_id = p_experiment_id 
        AND is_active = TRUE
        AND start_date <= CURRENT_TIMESTAMP
        AND (end_date IS NULL OR end_date > CURRENT_TIMESTAMP)
    ) THEN
        RETURN NULL;
    END IF;
    
    -- Generate random number for variant allocation
    v_random := random();
    
    -- Find appropriate variant based on allocation percentages
    SELECT variant_id INTO v_variant_id
    FROM (
        SELECT 
            variant_id,
            SUM(allocation_percentage) OVER (ORDER BY variant_id) - allocation_percentage AS lower_bound,
            SUM(allocation_percentage) OVER (ORDER BY variant_id) AS upper_bound
        FROM ab_test_variants
        WHERE experiment_id = p_experiment_id
    ) t
    WHERE v_random >= lower_bound AND v_random < upper_bound
    LIMIT 1;
    
    -- Assign user to variant
    INSERT INTO ab_test_assignments (
        experiment_id,
        variant_id,
        user_id
    )
    VALUES (
        p_experiment_id,
        v_variant_id,
        p_user_id
    )
    RETURNING assignment_id INTO v_assignment_id;
    
    -- Log the assignment
    INSERT INTO audit_logs (
        user_id,
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        p_user_id,
        'AB_TEST_ASSIGNMENT',
        'ab_test_assignments',
        v_assignment_id::TEXT,
        jsonb_build_object(
            'experiment_id', p_experiment_id,
            'variant_id', v_variant_id
        )
    );
    
    RETURN v_variant_id;
END;
$$;

-- Procedure to calculate experiment results
CREATE OR REPLACE PROCEDURE sp_calculate_experiment_results(
    p_experiment_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_metric RECORD;
    v_variant RECORD;
    v_sql TEXT;
    v_result NUMERIC;
    v_count INTEGER;
BEGIN
    -- Clear existing results for this experiment
    DELETE FROM ab_test_results WHERE experiment_id = p_experiment_id;
    
    -- Calculate each metric for each variant
    FOR v_metric IN SELECT * FROM ab_test_metrics WHERE experiment_id = p_experiment_id
    LOOP
        FOR v_variant IN SELECT * FROM ab_test_variants WHERE experiment_id = p_experiment_id
        LOOP
            -- Build dynamic SQL based on metric definition
            v_sql := 'SELECT ';
            
            -- Determine aggregation
            CASE v_metric.aggregation_type
                WHEN 'count' THEN v_sql := v_sql || 'COUNT(*)';
                WHEN 'sum' THEN v_sql := v_sql || 'COALESCE(SUM(' || quote_ident(v_metric.target_column) || '), 0)';
                WHEN 'avg' THEN v_sql := v_sql || 'COALESCE(AVG(' || quote_ident(v_metric.target_column) || '), 0)';
                WHEN 'rate' THEN v_sql := v_sql || 
                    'COALESCE(SUM(CASE WHEN ' || quote_ident(v_metric.target_column) || ' THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0), 0)';
                ELSE RAISE EXCEPTION 'Unknown aggregation type: %', v_metric.aggregation_type;
            END CASE;
            
            v_sql := v_sql || ', COUNT(*) FROM ' || quote_ident(v_metric.target_table) || ' t ';
            v_sql := v_sql || 'JOIN ab_test_assignments a ON t.user_id = a.user_id ';
            v_sql := v_sql || 'WHERE a.experiment_id = ' || p_experiment_id || ' ';
            v_sql := v_sql || 'AND a.variant_id = ' || v_variant.variant_id;
            
            -- Execute the query
            EXECUTE v_sql INTO v_result, v_count;
            
            -- Store the result
            INSERT INTO ab_test_results (
                experiment_id,
                variant_id,
                metric_id,
                value,
                sample_size
            )
            VALUES (
                p_experiment_id,
                v_variant.variant_id,
                v_metric.metric_id,
                v_result,
                v_count
            );
        END LOOP;
    END LOOP;
    
    -- Log the calculation
    INSERT INTO audit_logs (
        action_type,
        table_name,
        record_id,
        details
    )
    VALUES (
        'CALCULATE_AB_TEST_RESULTS',
        'ab_test_experiments',
        p_experiment_id::TEXT,
        jsonb_build_object('metrics_calculated', (
            SELECT COUNT(*) FROM ab_test_metrics WHERE experiment_id = p_experiment_id
        ))
    );
END;
$$;

---secure chat encryption keys 
-- Create a table to store encryption keys securely
-- First add a UUID column to users table
ALTER TABLE users ADD COLUMN user_uuid UUID DEFAULT gen_random_uuid() UNIQUE;

--Create the chats table 
CREATE TABLE chats (
    chat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_name VARCHAR(255),
    created_by INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--create the encryption keys table with UUID reference
CREATE TABLE chat_encryption_keys (
    key_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    chat_id UUID NOT NULL REFERENCES chats(chat_id) ON DELETE CASCADE,
    encrypted_key BYTEA NOT NULL,
    key_salt BYTEA NOT NULL,
    key_iterations INTEGER NOT NULL DEFAULT 100000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_chat_key UNIQUE (user_id, chat_id),
    FOREIGN KEY (user_id) REFERENCES users(user_uuid) ON DELETE CASCADE
);

-- Add security label for sensitive data
COMMENT ON TABLE chat_encryption_keys IS 'Stores encrypted chat encryption keys with high security';


--database access control modification 
-- -- Create a restricted role for application access
-- CREATE ROLE chat_app WITH LOGIN PASSWORD 'secure_password';
-- GRANT CONNECT ON DATABASE your_db TO chat_app;
-- GRANT SELECT, INSERT, UPDATE ON chat_encryption_keys TO chat_app;
-- -- Explicitly deny access to encrypted_key column from other roles
-- REVOKE ALL ON chat_encryption_keys FROM PUBLIC;

--Audit Trail 
-- Add audit table for key access
-- Key access audit table (fixed type mismatch)
CREATE TABLE IF NOT EXISTS key_access_audit (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_id UUID NOT NULL REFERENCES chat_encryption_keys(key_id),
    accessed_by INTEGER NOT NULL REFERENCES users(user_id),
    access_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    access_type TEXT NOT NULL CHECK (access_type IN ('decrypt', 'rotate', 'create'))
);

--Timestamp update function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--drop triggers if they exist (prevent duplicate trigger errors)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_chats_timestamp') THEN
        EXECUTE 'DROP TRIGGER update_chats_timestamp ON chats';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_keys_timestamp') THEN
        EXECUTE 'DROP TRIGGER update_keys_timestamp ON chat_encryption_keys';
    END IF;
END
$$;

--Create triggers (without IF NOT EXISTS)
CREATE TRIGGER update_chats_timestamp
BEFORE UPDATE ON chats
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_keys_timestamp
BEFORE UPDATE ON chat_encryption_keys
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

--Enhanced UserProfiles 


CREATE TABLE locations (
    locations_id SERIAL PRIMARY KEY,
    city VARCHAR(100),
    state_province VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

CREATE TABLE industries (
    industries_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE user_profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    headline VARCHAR(100),
    summary TEXT,
    website_url VARCHAR(255),
    location_id INTEGER REFERENCES locations(locations_id),
    industry_id INTEGER REFERENCES industries(industries_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

--Enhanced Content Management 
CREATE TABLE post_types (
    post_types_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT
);

-- Add type to posts
ALTER TABLE posts ADD COLUMN type_id INTEGER REFERENCES post_types(post_types_id);
ALTER TABLE posts ADD COLUMN language_code CHAR(2) DEFAULT 'en';
ALTER TABLE posts ADD COLUMN is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE posts ADD COLUMN pinned_at TIMESTAMP WITH TIME ZONE;

-- For rich media content
CREATE TABLE media_attachments (
    media_attachments_id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(post_id) ON DELETE CASCADE,
    url VARCHAR(255) NOT NULL,
    media_type VARCHAR(20) NOT NULL, -- 'image', 'video', 'audio', 'document'
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- for video/audio
    thumbnail_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


--advanced relationships feature 
CREATE TABLE relationship_types (
    relationship_types_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    reciprocal_name VARCHAR(50), -- e.g., "followed by", "parent of"
    is_symmetric BOOLEAN DEFAULT FALSE -- if true, reciprocal_name is same as name
);

-- Replace simple follows with more flexible relationships
CREATE TABLE user_relationships (
    user_relationships_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    related_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    relationship_type_id INTEGER NOT NULL REFERENCES relationship_types(relationship_types_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, related_user_id, relationship_type_id)
);

-- Add relationship strength/weight
ALTER TABLE user_relationships ADD COLUMN strength DECIMAL(3,2) DEFAULT 1.0;


--privacy controls 
CREATE TABLE privacy_settings (
    privacy_settings_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    profile_visibility VARCHAR(20) DEFAULT 'public', -- public, friends, private
    post_default_visibility VARCHAR(20) DEFAULT 'public',
    message_permissions VARCHAR(20) DEFAULT 'friends', -- everyone, friends, none
    location_sharing BOOLEAN DEFAULT FALSE,
    search_engine_indexing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_visibility (
    post_visibility_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    visibility_type VARCHAR(20) NOT NULL, -- public, friends, custom
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_visibility_custom (
    post_visibility_custom_id SERIAL PRIMARY KEY,
    visibility_id INTEGER NOT NULL REFERENCES post_visibility(post_visibility_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    UNIQUE (visibility_id, user_id, group_id)
);


--analytcis and recommendations 

CREATE TABLE user_activities (
    user_activities_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'post_created', 'like_given', etc.
    target_id INTEGER, -- ID of the target entity (post, comment, etc.)
    target_type VARCHAR(50), -- Type of the target entity
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE content_recommendations (
    content_recommendations_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_id INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    score DECIMAL(5,4) NOT NULL,
    algorithm VARCHAR(50) NOT NULL, -- 'collaborative_filtering', 'content_based', etc.
    recommended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, post_id, algorithm)
);

CREATE TABLE user_similarity (
    user1_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    user2_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    similarity_score DECIMAL(5,4) NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user1_id, user2_id),
    CHECK (user1_id < user2_id) -- ensure no duplicate pairs
);

--monetization features 

CREATE TABLE subscription_plans (
    subscription_plans_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(20) NOT NULL, -- monthly, yearly
    features JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_subscriptions (
    user_subscriptions_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    plan_id INTEGER NOT NULL REFERENCES subscription_plans(subscription_plans_id),
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    payment_method_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE creator_monetization (
    creator_monetization_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    is_monetized BOOLEAN DEFAULT FALSE,
    payment_method_setup BOOLEAN DEFAULT FALSE,
    minimum_tip_amount DECIMAL(10,2) DEFAULT 1.00,
    supporter_perks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- enhanced search functionality 
-- For full-text search optimization
ALTER TABLE posts ADD COLUMN search_vector TSVECTOR;
CREATE INDEX idx_post_search ON posts USING GIN(search_vector);

CREATE TABLE search_history (
    search_history_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    results_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE trending_topics (
    trending_topics_id SERIAL PRIMARY KEY,
    topic VARCHAR(100) NOT NULL,
    post_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


--Notifications System 
CREATE TABLE notification_types (
    notification_types_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    default_template TEXT NOT NULL
);

CREATE TABLE user_notifications (
    user_notifications_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    notification_type_id INTEGER NOT NULL REFERENCES notification_types(notification_types_id),
    sender_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    related_entity_id INTEGER,
    related_entity_type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- CREATE TABLE notification_preferences (
--     notification_preferences_id SERIAL PRIMARY KEY,
--     user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
--     notification_type_id INTEGER NOT NULL REFERENCES notification_types(notification_types_id),
--     receive_email BOOLEAN DEFAULT TRUE,
--     receive_push BOOLEAN DEFAULT TRUE,
--     receive_in_app BOOLEAN DEFAULT TRUE,
--     UNIQUE (user_id, notification_type_id)
-- );

--adding feature for graph-based relationship analytics 
-- Extended relationship tracking with weights and directions
CREATE TABLE relationship_graph (
    source_user INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    target_user INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    relationship_type INTEGER NOT NULL REFERENCES relationship_types(relationship_types_id),
    weight DECIMAL(5,4) DEFAULT 1.0,
    last_interaction TIMESTAMP WITH TIME ZONE,
    interaction_count INTEGER DEFAULT 1,
    PRIMARY KEY (source_user, target_user, relationship_type)
);

-- Materialized view for fast graph analytics
CREATE MATERIALIZED VIEW user_centrality AS
WITH graph AS (
    SELECT source_user AS user1, target_user AS user2, weight 
    FROM relationship_graph
    UNION ALL
    SELECT target_user AS user1, source_user AS user2, weight 
    FROM relationship_graph
    WHERE relationship_type IN (SELECT relationship_types_id FROM relationship_types WHERE is_symmetric = TRUE)
)
SELECT 
    user1 AS user_id,
    COUNT(DISTINCT user2) AS degree_centrality,
    LOG(COUNT(DISTINCT user2) + 1) * SUM(weight) AS weighted_centrality
FROM graph
GROUP BY user1;

-- Graph path analysis
CREATE TABLE shortest_path_cache (
    user1 INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    user2 INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    distance INTEGER NOT NULL,
    path_count INTEGER NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user1, user2),
    CHECK (user1 < user2)
);

--blockchain verified identity 
CREATE TABLE blockchain_identity (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id),
    wallet_address CHAR(42) UNIQUE,
    verification_tx_hash CHAR(66),
    verified_at TIMESTAMP WITH TIME ZONE,
    last_verified_block INTEGER
);

--AI powered content moderation 
CREATE TABLE content_moderation (
    content_id INTEGER NOT NULL,
    content_type VARCHAR(20) CHECK (content_type IN ('post', 'comment', 'media')),
    toxicity_score DECIMAL(3,2),
    sentiment_score DECIMAL(3,2),
    flagged_categories VARCHAR(255)[],
    ai_model_version VARCHAR(50),
    last_analyzed_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (content_id, content_type)
);



--real-time engagement tracking 
-- to enhance this to use timescaledb -- we should start using timescale db 
CREATE TABLE engagement_windows (
    window_id SERIAL PRIMARY KEY,
    window_size INTERVAL NOT NULL
);

CREATE TABLE live_engagement (
    window_id INTEGER REFERENCES engagement_windows,
    content_id INTEGER NOT NULL,
    content_type VARCHAR(20) NOT NULL,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    view_count INTEGER DEFAULT 0,
    engagement_score DECIMAL(10,2),
    PRIMARY KEY (content_id, content_type, window_start),
    FOREIGN KEY (window_id) REFERENCES engagement_windows
);

CREATE INDEX idx_live_engagement_time ON live_engagement (window_start);




--neural network recommendations 
CREATE TABLE neural_recommendations (
    user_id INTEGER REFERENCES users(user_id),
    recommended_item INTEGER NOT NULL,
    item_type VARCHAR(20) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(5,4),
    recommendation_context JSONB,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recommended_item, item_type)
);

--call metrics for voice/video 
CREATE TABLE call_metrics (
    call_id UUID PRIMARY KEY,
    initiator INTEGER REFERENCES users(user_id),
    recipient INTEGER REFERENCES users(user_id),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    quality_metrics JSONB,
    emotion_analysis JSONB,
    transcript_tsvector TSVECTOR
);


--predictive churn modeling - measuring the rate at which customers attrition
CREATE TABLE churn_predictions (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id),
    churn_probability DECIMAL(5,4),
    predicted_churn_date DATE,
    key_factors VARCHAR(255)[],
    model_version VARCHAR(50),
    last_updated TIMESTAMP WITH TIME ZONE
);

--cross platform integration 
CREATE TABLE external_platforms (
    user_id INTEGER REFERENCES users(user_id),
    platform_name VARCHAR(50) NOT NULL,
    platform_user_id VARCHAR(255) NOT NULL,
    oauth_token JSONB,
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_frequency INTERVAL,
    PRIMARY KEY (user_id, platform_name)
);


--network dynamcis advanced analytics 
CREATE TABLE network_dynamics_snapshots (
    snapshot_date DATE PRIMARY KEY,
    active_users INTEGER NOT NULL,
    total_interactions INTEGER NOT NULL,
    avg_connection_strength DECIMAL(10,4) NOT NULL
);

CREATE OR REPLACE FUNCTION update_network_dynamics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO network_dynamics_snapshots
    SELECT 
        CURRENT_DATE,
        COUNT(DISTINCT source_user),
        SUM(interaction_count),
        AVG(weight)
    FROM relationship_graph
    WHERE last_interaction >= CURRENT_DATE
    ON CONFLICT (snapshot_date) 
    DO UPDATE SET
        active_users = EXCLUDED.active_users,
        total_interactions = EXCLUDED.total_interactions,
        avg_connection_strength = EXCLUDED.avg_connection_strength;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_network_dynamics
AFTER INSERT OR UPDATE ON relationship_graph
EXECUTE FUNCTION update_network_dynamics();

--views additional i happen to miss out 
--usergrowth funnel
-- adding additional flag to the users table 
ALTER TABLE users
ADD COLUMN profile_complete BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE users ADD COLUMN signup_source VARCHAR(255);

CREATE OR REPLACE VIEW user_growth_funnel AS
WITH stages AS (
    SELECT 
        DATE(created_at) AS day,
        COUNT(*) FILTER (WHERE users.is_verified = TRUE) AS verified_users, -- changed from email_verified
        COUNT(*) FILTER (WHERE users.profile_complete = TRUE) AS completed_profiles, -- changed from profile_completion_status
        COUNT(*) FILTER (WHERE users.last_login > NOW() - INTERVAL '7 days') AS active_users -- changed from last_active_at
    FROM users
    GROUP BY DATE(created_at)
)
SELECT 
    day,
    verified_users,
    completed_profiles,
    active_users,
    CASE WHEN verified_users > 0 
         THEN ROUND(100.0 * completed_profiles / verified_users, 2)
         ELSE 0 END AS profile_completion_rate,
    CASE WHEN completed_profiles > 0
         THEN ROUND(100.0 * active_users / completed_profiles, 2)
         ELSE 0 END AS activation_rate
FROM stages;

--create post metrics 
CREATE TABLE post_metrics (
    post_metrics_id UUID PRIMARY KEY,
    like_count INT,
    comment_count INT,
    share_count INT
);
--content performance heatmap 

CREATE VIEW content_heatmap AS
SELECT 
    p.user_id,
    DATE_TRUNC('hour', p.post_time) AS post_hour,
    TO_CHAR(p.post_time, 'Day') AS day_of_week,
    COUNT(*) AS post_count,
    AVG(p.post_likes) AS avg_likes,
    AVG(p.post_comments) AS avg_comments,
    AVG(p.post_shares) AS avg_shares
FROM posts p
GROUP BY 
    p.user_id, 
    DATE_TRUNC('hour', p.post_time), 
    TO_CHAR(p.post_time, 'Day');



--create view to check relationship network health 
CREATE VIEW network_health AS
SELECT
    DATE_TRUNC('week', rg.last_interaction) AS week,
    COUNT(DISTINCT rg.source_user) AS active_connectors,
    AVG(rg.interaction_count) AS avg_interactions_per_connection,
    COUNT(DISTINCT CASE WHEN rg.interaction_count > 5 THEN rg.source_user END) AS highly_active_users,
    COUNT(*) FILTER (WHERE rg.weight > 0.7) AS strong_connections
FROM relationship_graph rg
GROUP BY DATE_TRUNC('week', rg.last_interaction);

--measuring revenue attribution 
-- Add user_id to link directly to users
ALTER TABLE wallet_transactions ADD COLUMN user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE;

-- Add campaign source for revenue attribution
ALTER TABLE wallet_transactions ADD COLUMN campaign_source VARCHAR(256);

-- Add signup source for cohort analysis
ALTER TABLE wallet_transactions ADD COLUMN signup_source VARCHAR(256);

-- Add payment method ID for payment channel analysis
ALTER TABLE wallet_transactions ADD COLUMN payment_method_id INTEGER REFERENCES payment_methods(method_id);

-- Add related subscription ID (optional)
ALTER TABLE wallet_transactions ADD COLUMN related_subscription_id INTEGER REFERENCES user_subscriptions(user_subscriptions_id);

-- Add refund flag
ALTER TABLE wallet_transactions ADD COLUMN is_refunded BOOLEAN DEFAULT FALSE;

-- Add fee and computed net_amount column
ALTER TABLE wallet_transactions ADD COLUMN fee DECIMAL(15, 2) DEFAULT 0.00;

-- Add generated column for net_amount (requires PostgreSQL 12+)
ALTER TABLE wallet_transactions 
ADD COLUMN net_amount DECIMAL(15, 2) GENERATED ALWAYS AS (amount - fee) STORED;

CREATE INDEX idx_wallet_transactions_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_campaign ON wallet_transactions(campaign_source);
CREATE INDEX idx_wallet_transactions_signup ON wallet_transactions(signup_source);
CREATE INDEX idx_wallet_transactions_time ON wallet_transactions(transaction_time);
--usecases for revenue attribution 
--by campaign source 
SELECT campaign_source, COUNT(*) AS transactions, SUM(net_amount) AS total_revenue
FROM wallet_transactions
WHERE transaction_type = 'deposit' AND status = 'completed'
GROUP BY campaign_source;


--by signup source 
SELECT signup_source, COUNT(*) AS paying_users, SUM(net_amount) AS total_revenue
FROM wallet_transactions
WHERE transaction_type = 'deposit' AND status = 'completed'
GROUP BY signup_source;

--by subscription revenue over time 
SELECT DATE_TRUNC('month', transaction_time) AS month, 
       SUM(net_amount) AS monthly_revenue
FROM wallet_transactions
WHERE related_subscription_id IS NOT NULL
GROUP BY month;

-- Measuring revenue attribution by signup source
CREATE OR REPLACE VIEW revenue_attribution AS
SELECT
    u.signup_source,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT t.user_id) AS paying_users,
    COUNT(t.transaction_id) AS total_deposits,
    SUM(t.amount) AS total_revenue,
    AVG(t.amount) AS avg_transaction_value
FROM
    users u
LEFT JOIN wallet_transactions t 
    ON u.user_id = t.user_id 
    AND t.transaction_type = 'deposit'
    AND t.status = 'completed'
GROUP BY
    u.signup_source;


--flagged content 
CREATE TABLE flagged_content (
    flagged_id SERIAL PRIMARY KEY,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('post', 'comment')),
    content_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    flagged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    is_reviewed BOOLEAN DEFAULT FALSE,
    reviewed_by INTEGER REFERENCES users(user_id),
    reviewed_at TIMESTAMP WITH TIME ZONE
);

-- Add action_taken to content_moderation
ALTER TABLE content_moderation 
ADD COLUMN IF NOT EXISTS action_taken VARCHAR(50);

COMMENT ON COLUMN content_moderation.action_taken IS 'Type of action taken by moderator (e.g., removed, warned)';

-- Add reviewed_at to content_moderation
ALTER TABLE content_moderation 
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN content_moderation.reviewed_at IS 'Timestamp when content was reviewed by a moderator';

--measuring moderation effectiveness 
CREATE OR REPLACE VIEW moderation_effectiveness AS
SELECT
    DATE_TRUNC('day', ma.action_timestamp) AS day,
    COUNT(*) AS total_flagged,
    COUNT(*) FILTER (WHERE ma.action_type = 'content_removal') AS removed_content,
    COUNT(*) FILTER (WHERE ma.action_type = 'user_warning') AS warned_users,
    AVG(cm.toxicity_score) AS avg_toxicity,
    COUNT(*) FILTER (
        WHERE ma.action_timestamp - f.flagged_at < INTERVAL '1 hour'
    ) AS fast_resolutions
FROM moderator_actions ma
LEFT JOIN content_moderation cm ON 
    (ma.target_type = 'post' AND ma.target_id = cm.content_id AND cm.content_type = 'post') OR
    (ma.target_type = 'comment' AND ma.target_id = cm.content_id AND cm.content_type = 'comment')
LEFT JOIN flagged_content f ON 
    (f.content_type = ma.target_type AND f.content_id = ma.target_id)
WHERE ma.action_type IN ('content_removal', 'user_warning', 'flag_review')
GROUP BY DATE_TRUNC('day', ma.action_timestamp)
ORDER BY day DESC;



--content virality pathways 
WITH viral_posts AS (
    SELECT 
        post_id,
        post_time AS created_at,
        post_shares
    FROM 
        posts
    WHERE 
        post_shares > (
            SELECT AVG(post_shares) * 5
            FROM posts
            WHERE post_shares > 0
        )
),
viral_timing AS (
    SELECT 
        vp.post_id,
        MIN(cem.engagement_timestamp) AS first_shared_at
    FROM 
        viral_posts vp
    JOIN 
        content_engagement_metrics cem 
        ON vp.post_id = cem.content_id
       AND cem.content_type = 'post'
       AND cem.engagement_type = 'share'
    GROUP BY 
        vp.post_id
)
SELECT 
    p.post_type AS content_type,
    p.language_code,
    COUNT(*) AS viral_post_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (vt.first_shared_at - p.post_time)) / 3600), 2) AS avg_hours_to_viral,
    ARRAY_AGG(DISTINCT p.user_id) AS origin_users
FROM 
    viral_posts vp
JOIN 
    posts p ON vp.post_id = p.post_id
JOIN 
    viral_timing vt ON vp.post_id = vt.post_id
GROUP BY 
    p.post_type, p.language_code;


--user retention view 
CREATE OR REPLACE VIEW retention_cohorts AS
WITH user_cohorts AS (
    SELECT 
        user_id,
        DATE_TRUNC('week', created_at) AS signup_week
    FROM users
)
SELECT
    uc.signup_week,
    COUNT(DISTINCT uc.user_id) AS cohort_size,
    COUNT(DISTINCT a.user_id) FILTER (WHERE a.activity_week = uc.signup_week) AS week_0,
    COUNT(DISTINCT a.user_id) FILTER (WHERE a.activity_week = uc.signup_week + INTERVAL '1 week') AS week_1,
    COUNT(DISTINCT a.user_id) FILTER (WHERE a.activity_week = uc.signup_week + INTERVAL '2 weeks') AS week_2
FROM user_cohorts uc
LEFT JOIN (
    SELECT 
        user_id,
        DATE_TRUNC('week', activity_timestamp) AS activity_week
    FROM user_activity_logs
    WHERE activity_type IN ('login', 'post_create', 'comment_create', 'like', 'share')
) a ON uc.user_id = a.user_id
GROUP BY uc.signup_week
ORDER BY uc.signup_week;

---feature adoption funnel
CREATE OR REPLACE VIEW feature_adoption AS
WITH feature_usage_cte AS (
    SELECT
        activity_type AS feature_name,
        user_id,
        MIN(created_at) AS first_interaction,
        COUNT(*) AS usage_count
    FROM user_activities
    WHERE activity_type IN (
        'post_create', 'comment_create', 'like', 'share',
        'chat_send_message', 'notification_settings_update'
    )
    GROUP BY activity_type, user_id
)
SELECT
    feature_name,
    COUNT(DISTINCT user_id) AS users_exposed,
    COUNT(DISTINCT CASE WHEN first_interaction IS NOT NULL THEN user_id END) AS users_tried,
    COUNT(DISTINCT CASE WHEN usage_count > 3 THEN user_id END) AS regular_users,
    AVG(CASE WHEN usage_count > 0 THEN usage_count END) AS avg_usage_per_user
FROM feature_usage_cte
GROUP BY feature_name;


--content production velocity measures 
CREATE OR REPLACE VIEW content_velocity AS
SELECT
    user_id,
    COUNT(*) AS total_posts,
    COUNT(*) FILTER (WHERE post_time >= NOW() - INTERVAL '30 days') AS last_30_days,
    COUNT(*) FILTER (WHERE post_time >= NOW() - INTERVAL '7 days') AS last_7_days,
    ROUND(
        EXTRACT(EPOCH FROM (MAX(post_time) - MIN(post_time))) / 86400 / NULLIF(COUNT(*) - 1, 0),
        2
    ) AS avg_days_between_posts
FROM posts
GROUP BY user_id
HAVING COUNT(*) > 5;


--user value segmentation view 
CREATE OR REPLACE VIEW user_value_segmentation AS
WITH user_activity_stats AS (
    SELECT
        user_id,
        COUNT(*) FILTER (WHERE activity_type IN ('post_create', 'comment_create')) AS content_count,
        COUNT(*) FILTER (WHERE activity_type IN ('like', 'share')) AS engagement_count,
        MAX(activity_timestamp) AS last_active_time,
        EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(activity_timestamp)) AS days_since_last_activity
    FROM user_activity_logs
    GROUP BY user_id
),
user_monetization AS (
    SELECT
        u.user_id,
        COALESCE(SUM(wt.amount), 0) AS total_deposits,
        COUNT(DISTINCT wt.transaction_id) AS deposit_count,
        MAX(wt.transaction_time) AS last_deposit_time,
        EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(wt.transaction_time)) AS days_since_last_deposit,
        COUNT(DISTINCT us.plan_id) AS subscription_count,
        BOOL_OR(us.is_active) AS has_active_subscription
    FROM users u
    LEFT JOIN wallet_transactions wt ON u.user_id = wt.user_id AND wt.transaction_type = 'deposit'
    LEFT JOIN user_subscriptions us ON u.user_id = us.user_id AND us.is_active = TRUE
    GROUP BY u.user_id
),
user_segments AS (
    SELECT
        u.user_id,
        u.username,
        u.email,
        u.created_at,
        COALESCE(act.content_count, 0) AS content_count,
        COALESCE(act.engagement_count, 0) AS engagement_count,
        COALESCE(mon.total_deposits, 0) AS total_deposits,
        COALESCE(mon.deposit_count, 0) AS deposit_count,
        mon.has_active_subscription,
        COALESCE(act.days_since_last_activity, 9999) AS days_since_last_activity,
        COALESCE(mon.days_since_last_deposit, 9999) AS days_since_last_deposit,
        CASE
            WHEN mon.total_deposits > 100 THEN 'High Value'
            WHEN mon.total_deposits > 0 THEN 'Medium Value'
            WHEN act.days_since_last_activity < 7 THEN 'Active Non-Payer'
            WHEN act.days_since_last_activity BETWEEN 7 AND 30 THEN 'Dormant Active'
            ELSE 'Inactive'
        END AS value_segment
    FROM users u
    LEFT JOIN user_activity_stats act ON u.user_id = act.user_id
    LEFT JOIN user_monetization mon ON u.user_id = mon.user_id
)
SELECT * FROM user_segments;

--api logs
CREATE TABLE api_logs (
    log_id SERIAL PRIMARY KEY,
    endpoint VARCHAR(255) NOT NULL,
    user_id INTEGER REFERENCES users(user_id),
    called_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_time_ms INTEGER,
    status_code INTEGER,
    ip_address INET,
    user_agent TEXT
);

--api usage analytics view 
CREATE OR REPLACE VIEW api_usage_metrics AS
SELECT
    endpoint,
    DATE_TRUNC('day', called_at) AS day,
    COUNT(*) AS call_count,
    AVG(response_time_ms) AS avg_response_time,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) FILTER (WHERE status_code >= 400) AS error_count,
    COUNT(*) FILTER (WHERE status_code BETWEEN 200 AND 299) AS successful_calls
FROM api_logs
GROUP BY endpoint, DATE_TRUNC('day', called_at)
ORDER BY day DESC, call_count DESC;


--moderation workload forecast 
CREATE OR REPLACE VIEW moderation_workload_forecast AS
WITH daily_actions AS (
    SELECT
        DATE_TRUNC('day', action_timestamp) AS day,
        COUNT(*) AS total_actions,
        COUNT(*) FILTER (WHERE action_type = 'content_removal') AS content_removals,
        COUNT(*) FILTER (WHERE action_type = 'user_warning') AS user_warnings,
        COUNT(*) FILTER (WHERE action_type = 'flag_review') AS flag_reviews
    FROM moderator_actions
    WHERE action_timestamp >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE_TRUNC('day', action_timestamp)
),
daily_averages AS (
    SELECT
        AVG(total_actions) AS avg_daily_actions,
        AVG(content_removals) AS avg_content_removals,
        AVG(user_warnings) AS avg_user_warnings,
        AVG(flag_reviews) AS avg_flag_reviews
    FROM daily_actions
    WHERE day BETWEEN CURRENT_DATE - INTERVAL '60 days' AND CURRENT_DATE - INTERVAL '1 day'
),
projected_actions AS (
    SELECT
        generate_series AS day,
        ROUND(avg_daily_actions) AS projected_total_actions,
        ROUND(avg_content_removals) AS projected_content_removals,
        ROUND(avg_user_warnings) AS projected_user_warnings,
        ROUND(avg_flag_reviews) AS projected_flag_reviews
    FROM daily_averages
    CROSS JOIN GENERATE_SERIES(CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days', INTERVAL '1 day')
)
SELECT * FROM projected_actions
ORDER BY day;

--posts table adding trending score 
ALTER TABLE posts ADD COLUMN IF NOT EXISTS trending_score DECIMAL(10,2) DEFAULT 0;
-- Trending index
CREATE INDEX IF NOT EXISTS idx_posts_trending ON posts(trending_score DESC);

-- Activity time index
CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON user_activity_logs(activity_timestamp);

-- Message time index
CREATE INDEX IF NOT EXISTS idx_message_time ON conversations_messages(time);

--view for measuring realtime network pulse 
