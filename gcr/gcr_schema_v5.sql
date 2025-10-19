/*
 * World-Class Decentralized Citizen Journalism Platform
 * PostgreSQL Schema v1.0
 * Author: Awase Khirni Syed Ph.D.
 * Copyright: 2025 Beta ORI Inc. Canada. All Rights Reserved.
 * Features:
 * - Role-Based Access Control (RBAC)
 * - GDPR Compliance
 * - Data Lifecycle Management
 * - Data Quality Controls
 * - Data Lineage Tracking
 * - Data Profiling
 * - Data Catalog
 * - Data Dictionary
 * - Comprehensive Auditing
 * - Analytics & Visitor Tracking
 * - Key Performance Indicators (KPIs)
 * - ActivityPub Integration for Federation
 * - Decentralized Content Moderation
 * - Cryptographically Verifiable Content
 * - Token-based Incentivization
 * - AI-assisted Fact Checking
 */

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "ltree";
CREATE EXTENSION IF NOT EXISTS postgis;


CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    display_name VARCHAR(100),
    profile_image_url TEXT,
    bio TEXT,
    location VARCHAR(100),
    website_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deletion_requested_at TIMESTAMP WITH TIME ZONE,
    gdpr_compliant BOOLEAN DEFAULT FALSE,
    public_key TEXT, -- For decentralized identity
    encrypted_private_key TEXT, -- Encrypted with user\'s password
    activity_pub_actor_id TEXT, -- For federated identity
    CONSTRAINT chk_email CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

COMMENT ON TABLE users IS 'Stores user account information with GDPR compliance and decentralized identity support';
COMMENT ON COLUMN users.public_key IS 'Public key for cryptographic verification of user content';
COMMENT ON COLUMN users.activity_pub_actor_id IS 'ActivityPub actor ID for federated identity';


-- User GDPR consent tracking
CREATE TABLE user_consents (
    consent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    consent_type VARCHAR(50) NOT NULL,
    consent_version VARCHAR(20) NOT NULL,
    granted BOOLEAN NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

COMMENT ON TABLE user_consents IS 'Tracks user consent for GDPR compliance, recording when and how consent was given';



-- User roles for RBAC
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE roles IS 'Defines roles for Role-Based Access Control (RBAC) system';


-- Default system roles
INSERT INTO roles (role_name, description, is_system_role) VALUES
('admin', 'System administrator with full access', TRUE),
('editor', 'Can edit and moderate content', TRUE),
('reporter', 'Verified citizen journalist', TRUE),
('contributor', 'Can submit content but not publish directly', TRUE),
('reader', 'Basic read-only access', TRUE),
('moderator', 'Can moderate content and users', TRUE),
('fact_checker', 'Can verify facts in reports', TRUE),
('api_client', 'System role for API clients', TRUE);


-- User role assignments
CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(user_id),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (user_id, role_id)
);

COMMENT ON TABLE user_roles IS 'Assigns roles to users for RBAC implementation';



-- Permissions
CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE permissions IS 'Defines granular permissions that can be assigned to roles';



-- Role permissions
CREATE TABLE role_permissions (
    role_permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    permission_id UUID NOT NULL REFERENCES permissions(permission_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(user_id),
    UNIQUE (role_id, permission_id)
);

COMMENT ON TABLE role_permissions IS 'Assigns permissions to roles for RBAC implementation';




-- User sessions
CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_revoked BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE user_sessions IS 'Tracks user sessions for authentication and security purposes';



-- Two-factor authentication
CREATE TABLE user_2fa (
    two_fa_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    method VARCHAR(20) NOT NULL CHECK (method IN ('sms', 'email', 'totp', 'u2f', 'webauthn')),
    secret TEXT,
    phone_number VARCHAR(20),
    backup_codes TEXT[],
    is_enabled BOOLEAN DEFAULT FALSE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, method)
);

COMMENT ON TABLE user_2fa IS 'Stores two-factor authentication settings for users';



CREATE TABLE content_types (
    content_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_types IS 'Defines types of content that can be created on the platform';


-- Default content types
INSERT INTO content_types (type_name, description, icon) VALUES
('article', 'Long-form written content', 'article'),
('news', 'Short news report', 'news'),
('opinion', 'Opinion piece or editorial', 'opinion'),
('investigation', 'In-depth investigation', 'investigation'),
('interview', 'Interview transcript or summary', 'interview'),
('video', 'Video content', 'video'),
('audio', 'Audio content or podcast', 'audio'),
('photo', 'Photo essay or single image', 'photo'),
('live', 'Live reporting or event coverage', 'live');




-- Content categories
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES categories(category_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categories IS 'Hierarchical categorization system for content';

-- Tags
CREATE TABLE tags (
    tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE tags IS 'Tagging system for content organization and discovery';





-- Content table
CREATE TABLE content (
    content_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type_id UUID NOT NULL REFERENCES content_types(content_type_id),
    author_id UUID NOT NULL REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    excerpt TEXT,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'pending_review', 'published', 'rejected', 'archived')),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(user_id),
    language VARCHAR(10) DEFAULT 'en',
    is_featured BOOLEAN DEFAULT FALSE,
    is_breaking BOOLEAN DEFAULT FALSE,
    is_opinion BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_score INTEGER DEFAULT 0,
    location GEOGRAPHY(POINT, 4326),
    location_text VARCHAR(255),
    encrypted_content_key TEXT, -- For E2E encrypted content
    content_hash TEXT NOT NULL, -- Cryptographic hash of content for verification
    previous_version_id UUID REFERENCES content(content_id),
    activity_pub_object_id TEXT, -- For federated content
    UNIQUE (slug, published_at)
);

COMMENT ON TABLE content IS 'Main table for storing journalism content with versioning and federated capabilities';
COMMENT ON COLUMN content.content_hash IS 'SHA-256 hash of content body for cryptographic verification';
COMMENT ON COLUMN content.activity_pub_object_id IS 'ActivityPub object ID for federated content';

-- Content metadata
CREATE TABLE content_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    meta_key VARCHAR(100) NOT NULL,
    meta_value TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, meta_key)
);

COMMENT ON TABLE content_metadata IS 'Stores additional metadata for content in key-value pairs';

-- Content to category mapping
CREATE TABLE content_categories (
    content_category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(category_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(user_id),
    UNIQUE (content_id, category_id)
);

COMMENT ON TABLE content_categories IS 'Maps content to categories for organization and discovery';

-- Content to tag mapping
CREATE TABLE content_tags (
    content_tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(tag_id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(user_id),
    UNIQUE (content_id, tag_id)
);

COMMENT ON TABLE content_tags IS 'Maps content to tags for organization and discovery';

-- Content media attachments
CREATE TABLE content_media (
    media_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    media_type VARCHAR(50) NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'document', 'embed')),
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    alt_text TEXT,
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- in seconds
    file_size INTEGER, -- in bytes
    mime_type VARCHAR(100),
    is_featured BOOLEAN DEFAULT FALSE,
    position INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

COMMENT ON TABLE content_media IS 'Stores media attachments associated with content';

-- Content versions
CREATE TABLE content_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    excerpt TEXT,
    updated_by UUID REFERENCES users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    change_reason TEXT,
    UNIQUE (content_id, version_number)
);

COMMENT ON TABLE content_versions IS 'Tracks historical versions of content for auditing and rollback';

-- Content collaboration
CREATE TABLE content_collaborators (
    collaboration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    role VARCHAR(50) NOT NULL CHECK (role IN ('author', 'editor', 'reviewer', 'fact_checker', 'photographer', 'translator')),
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    invited_by UUID REFERENCES users(user_id),
    accepted_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (content_id, user_id, role)
);

COMMENT ON TABLE content_collaborators IS 'Tracks collaborators on content pieces with different roles';

-- Content review workflow
CREATE TABLE content_reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(user_id),
    review_status VARCHAR(20) NOT NULL CHECK (review_status IN ('pending', 'approved', 'rejected', 'changes_requested')),
    review_comments TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version_number INTEGER NOT NULL,
    next_review_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE content_reviews IS 'Tracks editorial review process for content';

-- Content fact checks
CREATE TABLE content_fact_checks (
    fact_check_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    fact_checker_id UUID NOT NULL REFERENCES users(user_id),
    claim_text TEXT NOT NULL,
    verdict VARCHAR(50) NOT NULL CHECK (verdict IN ('true', 'mostly_true', 'half_true', 'mostly_false', 'false', 'unverifiable')),
    explanation TEXT NOT NULL,
    sources TEXT,
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_fact_checks IS 'Stores fact-checking results for claims in content';

-- Content translations
CREATE TABLE content_translations (
    translation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    translator_id UUID REFERENCES users(user_id),
    language VARCHAR(10) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_score INTEGER DEFAULT 0,
    UNIQUE (content_id, language)
);

COMMENT ON TABLE content_translations IS 'Stores translated versions of content for multilingual support';

-- Content verification sources
CREATE TABLE content_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('document', 'interview', 'official_record', 'eyewitness', 'expert', 'other')),
    description TEXT NOT NULL,
    url TEXT,
    attachment_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_sources IS 'Tracks sources used to verify content claims';

-- Content verification witnesses
CREATE TABLE content_witnesses (
    witness_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    contact_info TEXT,
    statement TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_witnesses IS 'Tracks eyewitness accounts used to verify content';

-- Content blockchain verification
CREATE TABLE content_blockchain_verification (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    blockchain_name VARCHAR(50) NOT NULL,
    transaction_hash TEXT NOT NULL,
    block_number BIGINT,
    timestamp TIMESTAMP WITH TIME ZONE,
    smart_contract_address TEXT,
    verification_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, blockchain_name)
);

COMMENT ON TABLE content_blockchain_verification IS 'Stores blockchain verification records for content immutability';

-- =============================================
-- SECTION 2: USER ENGAGEMENT & SOCIAL FEATURES
-- =============================================

-- User reactions to content
CREATE TABLE content_reactions (
    reaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('like', 'dislike', 'love', 'laugh', 'sad', 'angry', 'surprise', 'trust', 'distrust')),
    reacted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    weight INTEGER DEFAULT 1,
    UNIQUE (content_id, user_id, reaction_type)
);

COMMENT ON TABLE content_reactions IS 'Tracks user reactions to content with various reaction types';

-- Content comments
CREATE TABLE content_comments (
    comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    parent_comment_id UUID REFERENCES content_comments(comment_id),
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'deleted', 'flagged', 'hidden')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_score INTEGER DEFAULT 0,
    encrypted_body TEXT, -- For E2E encrypted comments
    content_hash TEXT NOT NULL -- Cryptographic hash of comment for verification
);

COMMENT ON TABLE content_comments IS 'Stores user comments on content with threading and moderation capabilities';

-- Comment reactions
CREATE TABLE comment_reactions (
    reaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES content_comments(comment_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('like', 'dislike', 'love', 'laugh', 'sad', 'angry', 'agree', 'disagree')),
    reacted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (comment_id, user_id, reaction_type)
);

COMMENT ON TABLE comment_reactions IS 'Tracks user reactions to comments';

-- Bookmarks
CREATE TABLE user_bookmarks (
    bookmark_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    comment_id UUID REFERENCES content_comments(comment_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    folder VARCHAR(50),
    notes TEXT,
    UNIQUE (user_id, content_id, comment_id)
);

COMMENT ON TABLE user_bookmarks IS 'Tracks content and comments bookmarked by users';

-- User follows
CREATE TABLE user_follows (
    follow_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(user_id),
    followed_id UUID NOT NULL REFERENCES users(user_id),
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    mute BOOLEAN DEFAULT FALSE,
    UNIQUE (follower_id, followed_id)
);

COMMENT ON TABLE user_follows IS 'Tracks user following relationships';

-- User content subscriptions
CREATE TABLE user_content_subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(category_id),
    tag_id UUID REFERENCES tags(tag_id),
    author_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notification_preference VARCHAR(20) DEFAULT 'email' CHECK (notification_preference IN ('email', 'push', 'both', 'none')),
    is_active BOOLEAN DEFAULT TRUE,
    CHECK (
        (content_id IS NOT NULL)::integer +
        (category_id IS NOT NULL)::integer +
        (tag_id IS NOT NULL)::integer +
        (author_id IS NOT NULL)::integer = 1
    )
);

COMMENT ON TABLE user_content_subscriptions IS 'Tracks user subscriptions to specific content, categories, tags, or authors';

-- User notifications
CREATE TABLE user_notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    related_content_id UUID REFERENCES content(content_id),
    related_comment_id UUID REFERENCES content_comments(comment_id),
    related_user_id UUID REFERENCES users(user_id),
    action_url TEXT,
    metadata JSONB
);

COMMENT ON TABLE user_notifications IS 'Stores user notifications for various platform activities';

-- User notification preferences
CREATE TABLE user_notification_preferences (
    preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, notification_type)
);

COMMENT ON TABLE user_notification_preferences IS 'Stores user preferences for different types of notifications';

-- User activity feed
CREATE TABLE user_activity (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    activity_type VARCHAR(50) NOT NULL,
    activity_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_public BOOLEAN DEFAULT TRUE,
    ip_address INET,
    user_agent TEXT
);

COMMENT ON TABLE user_activity IS 'Tracks user activity on the platform for personal feeds and analytics';

-- User reputation system
CREATE TABLE user_reputation (
    reputation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    reputation_score INTEGER NOT NULL DEFAULT 0,
    credibility_score INTEGER NOT NULL DEFAULT 50,
    last_calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id)
);

COMMENT ON TABLE user_reputation IS 'Tracks user reputation scores based on content quality and community interactions';

-- Reputation history
CREATE TABLE user_reputation_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    change_amount INTEGER NOT NULL,
    new_score INTEGER NOT NULL,
    reason VARCHAR(100) NOT NULL,
    related_content_id UUID REFERENCES content(content_id),
    related_comment_id UUID REFERENCES content_comments(comment_id),
    changed_by UUID REFERENCES users(user_id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_reputation_history IS 'Tracks changes to user reputation scores over time';

-- User badges
CREATE TABLE badges (
    badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE badges IS 'Defines badges that can be earned by users';

-- User badge assignments
CREATE TABLE user_badges (
    user_badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    badge_id UUID NOT NULL REFERENCES badges(badge_id),
    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    awarded_by UUID REFERENCES users(user_id),
    is_featured BOOLEAN DEFAULT FALSE,
    UNIQUE (user_id, badge_id)
);

COMMENT ON TABLE user_badges IS 'Tracks badges awarded to users';

-- =============================================
-- SECTION 3: MODERATION & TRUST SYSTEMS
-- =============================================

-- Content flags
CREATE TABLE content_flags (
    flag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id),
    flag_type VARCHAR(50) NOT NULL CHECK (flag_type IN ('spam', 'inappropriate', 'misinformation', 'hate_speech', 'harassment', 'copyright', 'other')),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(user_id),
    review_notes TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE content_flags IS 'Tracks user flags/reports of problematic content for moderation';

-- Comment flags
CREATE TABLE comment_flags (
    flag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES content_comments(comment_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id),
    flag_type VARCHAR(50) NOT NULL CHECK (flag_type IN ('spam', 'inappropriate', 'harassment', 'hate_speech', 'off_topic', 'other')),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(user_id),
    review_notes TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE comment_flags IS 'Tracks user flags/reports of problematic comments for moderation';

-- User flags
CREATE TABLE user_flags (
    flag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reported_user_id UUID NOT NULL REFERENCES users(user_id),
    reporting_user_id UUID REFERENCES users(user_id),
    flag_type VARCHAR(50) NOT NULL CHECK (flag_type IN ('spam', 'inappropriate', 'harassment', 'impersonation', 'other')),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(user_id),
    review_notes TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE user_flags IS 'Tracks user flags/reports of problematic users for moderation';

-- Moderation actions
CREATE TABLE moderation_actions (
    action_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    moderator_id UUID NOT NULL REFERENCES users(user_id),
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('content_removed', 'content_hidden', 'comment_removed', 'user_warned', 'user_suspended', 'user_banned', 'flag_dismissed', 'other')),
    target_content_id UUID REFERENCES content(content_id),
    target_comment_id UUID REFERENCES content_comments(comment_id),
    target_user_id UUID REFERENCES users(user_id),
    target_flag_id UUID,
    reason TEXT NOT NULL,
    duration INTERVAL, -- For temporary actions
    notes TEXT,
    action_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE moderation_actions IS 'Records actions taken by moderators against content, comments, or users';

-- User bans/suspensions
CREATE TABLE user_bans (
    ban_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    moderator_id UUID NOT NULL REFERENCES users(user_id),
    reason TEXT NOT NULL,
    ban_type VARCHAR(20) NOT NULL CHECK (ban_type IN ('warning', 'suspension', 'permanent')),
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITH TIME ZONE, -- NULL for permanent bans
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    appeal_status VARCHAR(20) DEFAULT 'none' CHECK (appeal_status IN ('none', 'pending', 'approved', 'rejected'))
);

COMMENT ON TABLE user_bans IS 'Tracks user bans and suspensions with appeal capabilities';

-- Trust scores
CREATE TABLE content_trust_scores (
    score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    score_type VARCHAR(50) NOT NULL CHECK (score_type IN ('automated', 'community', 'expert')),
    score_value NUMERIC(5,2) NOT NULL,
    confidence NUMERIC(5,2),
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    algorithm_version VARCHAR(50),
    details JSONB,
    UNIQUE (content_id, score_type)
);

COMMENT ON TABLE content_trust_scores IS 'Stores various trustworthiness scores for content from different sources';

-- Trust indicators
CREATE TABLE content_trust_indicators (
    indicator_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    indicator_type VARCHAR(50) NOT NULL CHECK (indicator_type IN ('source_reputation', 'author_reputation', 'corroboration', 'transparency', 'professional_journalism', 'community_rating')),
    value NUMERIC(5,2) NOT NULL,
    weight NUMERIC(5,2) NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

COMMENT ON TABLE content_trust_indicators IS 'Stores detailed trust indicators that contribute to overall trust scores';

-- Community verification votes
CREATE TABLE content_verification_votes (
    vote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    vote_type VARCHAR(20) NOT NULL CHECK (vote_type IN ('verify', 'dispute')),
    confidence_level INTEGER CHECK (confidence_level BETWEEN 1 AND 5),
    comments TEXT,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, user_id)
);

COMMENT ON TABLE content_verification_votes IS 'Tracks community votes on content verification status';

-- =============================================
-- SECTION 4: DATA GOVERNANCE & QUALITY
-- =============================================

-- Data dictionary
CREATE TABLE data_dictionary (
    entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    business_definition TEXT,
    sensitivity_level VARCHAR(20) CHECK (sensitivity_level IN ('public', 'internal', 'confidential', 'restricted')),
    pii_flag BOOLEAN DEFAULT FALSE,
    gdpr_category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (table_name, column_name)
);

COMMENT ON TABLE data_dictionary IS 'Comprehensive data dictionary documenting all tables and columns';

-- Data lineage
CREATE TABLE data_lineage (
    lineage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_table VARCHAR(100) NOT NULL,
    source_column VARCHAR(100) NOT NULL,
    target_table VARCHAR(100) NOT NULL,
    target_column VARCHAR(100) NOT NULL,
    transformation_description TEXT,
    transformation_logic TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_lineage IS 'Tracks data lineage and transformations between tables';

-- Data quality rules
CREATE TABLE data_quality_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT NOT NULL,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('completeness', 'validity', 'uniqueness', 'consistency', 'timeliness', 'accuracy')),
    rule_expression TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality_rules IS 'Defines data quality rules for monitoring and validation';

-- Data quality issues
CREATE TABLE data_quality_issues (
    issue_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES data_quality_rules(rule_id),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    record_id TEXT, -- Could be UUID or other ID format
    issue_description TEXT NOT NULL,
    issue_details JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'wont_fix')),
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(user_id),
    resolution_notes TEXT
);

COMMENT ON TABLE data_quality_issues IS 'Tracks data quality issues identified by quality rules';

-- Data profiling
CREATE TABLE data_profiling (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    profile_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    row_count BIGINT NOT NULL,
    null_count BIGINT NOT NULL,
    distinct_count BIGINT NOT NULL,
    min_value TEXT,
    max_value TEXT,
    avg_value NUMERIC,
    median_value NUMERIC,
    data_type VARCHAR(50) NOT NULL,
    sample_values TEXT[],
    pattern_analysis JSONB,
    value_distribution JSONB,
    UNIQUE (table_name, column_name, profile_date)
);

COMMENT ON TABLE data_profiling IS 'Stores data profiling results for monitoring data characteristics';

-- Data catalog
CREATE TABLE data_catalog (
    catalog_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_name VARCHAR(100) NOT NULL,
    asset_type VARCHAR(50) NOT NULL CHECK (asset_type IN ('table', 'view', 'report', 'dashboard', 'dataset', 'api')),
    description TEXT NOT NULL,
    owner VARCHAR(100),
    domain VARCHAR(100),
    sensitivity_level VARCHAR(20) CHECK (sensitivity_level IN ('public', 'internal', 'confidential', 'restricted')),
    pii_flag BOOLEAN DEFAULT FALSE,
    gdpr_relevant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_profiled_at TIMESTAMP WITH TIME ZONE,
    data_quality_score NUMERIC(5,2),
    UNIQUE (asset_name, asset_type)
);

COMMENT ON TABLE data_catalog IS 'Central catalog of all data assets in the platform';

-- Data retention policies
CREATE TABLE data_retention_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    retention_period INTERVAL NOT NULL,
    retention_criteria TEXT,
    archival_strategy VARCHAR(100),
    disposal_method VARCHAR(100) NOT NULL,
    gdpr_compliance_notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (table_name)
);

COMMENT ON TABLE data_retention_policies IS 'Defines data retention policies for GDPR and lifecycle management';

-- Data subject requests (GDPR)
CREATE TABLE data_subject_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('access', 'rectification', 'erasure', 'restriction', 'portability', 'object')),
    request_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'processing', 'completed', 'rejected')),
    completion_date TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(user_id),
    verification_method VARCHAR(50),
    request_details TEXT,
    response_details TEXT,
    is_automated BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE data_subject_requests IS 'Tracks GDPR data subject requests (DSRs) from users';

-- Data access logs
CREATE TABLE data_access_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    access_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(100) NOT NULL,
    record_id TEXT,
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('select', 'insert', 'update', 'delete')),
    ip_address INET,
    user_agent TEXT,
    query_parameters TEXT,
    accessed_columns TEXT[],
    changes JSONB
);

COMMENT ON TABLE data_access_logs IS 'Logs all data access for auditing and GDPR compliance';

-- =============================================
-- SECTION 5: ANALYTICS & PERFORMANCE
-- =============================================

-- Visitor analytics
CREATE TABLE visitor_sessions (
    session_uuid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visitor_id TEXT NOT NULL,
    first_visit_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    entry_url TEXT NOT NULL,
    exit_url TEXT,
    referrer_url TEXT,
    referrer_domain TEXT,
    device_type VARCHAR(50),
    device_name VARCHAR(100),
    os_name VARCHAR(50),
    os_version VARCHAR(50),
    browser_name VARCHAR(50),
    browser_version VARCHAR(50),
    screen_width INTEGER,
    screen_height INTEGER,
    language VARCHAR(10),
    country_code VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    is_bot BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES users(user_id)
);

COMMENT ON TABLE visitor_sessions IS 'Tracks visitor sessions for web analytics';

-- Page views
CREATE TABLE page_views (
    view_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_uuid UUID NOT NULL REFERENCES visitor_sessions(session_uuid),
    view_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    url TEXT NOT NULL,
    path VARCHAR(255) NOT NULL,
    query_parameters TEXT,
    content_id UUID REFERENCES content(content_id),
    category_id UUID REFERENCES categories(category_id),
    tag_id UUID REFERENCES tags(tag_id),
    author_id UUID REFERENCES users(user_id),
    duration INTERVAL,
    scroll_depth INTEGER,
    is_logged_in BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE page_views IS 'Tracks individual page views within visitor sessions';

-- Content analytics
CREATE TABLE content_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    date DATE NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    unique_visitors INTEGER NOT NULL DEFAULT 0,
    completions INTEGER NOT NULL DEFAULT 0, -- Read/watch completions
    shares INTEGER NOT NULL DEFAULT 0,
    comments_count INTEGER NOT NULL DEFAULT 0,
    reactions_count INTEGER NOT NULL DEFAULT 0,
    backlinks_count INTEGER NOT NULL DEFAULT 0,
    avg_read_time INTERVAL,
    scroll_depth_avg NUMERIC(5,2),
    bounce_rate NUMERIC(5,2),
    UNIQUE (content_id, date)
);

COMMENT ON TABLE content_analytics IS 'Aggregated daily analytics for content performance';

-- User engagement metrics
CREATE TABLE user_engagement (
    engagement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    date DATE NOT NULL,
    sessions INTEGER NOT NULL DEFAULT 0,
    page_views INTEGER NOT NULL DEFAULT 0,
    content_created INTEGER NOT NULL DEFAULT 0,
    comments_posted INTEGER NOT NULL DEFAULT 0,
    reactions_given INTEGER NOT NULL DEFAULT 0,
    shares_made INTEGER NOT NULL DEFAULT 0,
    time_spent INTERVAL NOT NULL DEFAULT '0 minutes',
    last_active TIMESTAMP WITH TIME ZONE,
    UNIQUE (user_id, date)
);

COMMENT ON TABLE user_engagement IS 'Tracks daily user engagement metrics';

-- Platform KPIs
CREATE TABLE platform_kpis (
    kpi_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_name VARCHAR(100) NOT NULL UNIQUE,
    kpi_description TEXT NOT NULL,
    measurement_unit VARCHAR(50) NOT NULL,
    target_value NUMERIC,
    is_higher_better BOOLEAN DEFAULT TRUE,
    category VARCHAR(50) NOT NULL,
    reporting_frequency VARCHAR(20) NOT NULL CHECK (reporting_frequency IN ('hourly', 'daily', 'weekly', 'monthly', 'quarterly')),
    owner VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE platform_kpis IS 'Defines Key Performance Indicators (KPIs) for the platform';

-- KPI measurements
CREATE TABLE kpi_measurements (
    measurement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL REFERENCES platform_kpis(kpi_id),
    measurement_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    value NUMERIC NOT NULL,
    dimension VARCHAR(100), -- For segmented KPIs (e.g., by country, content type)
    notes TEXT,
    UNIQUE (kpi_id, measurement_time, dimension)
);

COMMENT ON TABLE kpi_measurements IS 'Records measurements of platform KPIs over time';

-- A/B tests
CREATE TABLE ab_tests (
    test_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_metric VARCHAR(100) NOT NULL,
    success_criteria TEXT NOT NULL,
    sample_size INTEGER,
    audience_criteria JSONB
);

COMMENT ON TABLE ab_tests IS 'Tracks A/B tests for platform features and user experience';

-- A/B test variants
CREATE TABLE ab_test_variants (
    variant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID NOT NULL REFERENCES ab_tests(test_id) ON DELETE CASCADE,
    variant_name VARCHAR(50) NOT NULL,
    variant_description TEXT,
    allocation_percentage NUMERIC(5,2) NOT NULL,
    configuration JSONB NOT NULL,
    is_control BOOLEAN DEFAULT FALSE,
    UNIQUE (test_id, variant_name)
);

COMMENT ON TABLE ab_test_variants IS 'Defines variants for A/B tests with configuration and allocation';

-- A/B test assignments
CREATE TABLE ab_test_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID NOT NULL REFERENCES ab_tests(test_id),
    variant_id UUID NOT NULL REFERENCES ab_test_variants(variant_id),
    user_id UUID REFERENCES users(user_id),
    visitor_id TEXT,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (test_id, COALESCE(user_id::text, visitor_id))
);

COMMENT ON TABLE ab_test_assignments IS 'Tracks which users/visitors are assigned to which test variants';

-- A/B test results
CREATE TABLE ab_test_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID NOT NULL REFERENCES ab_tests(test_id),
    variant_id UUID NOT NULL REFERENCES ab_test_variants(variant_id),
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC NOT NULL,
    sample_size INTEGER NOT NULL,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC,
    p_value NUMERIC,
    is_winner BOOLEAN,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (test_id, variant_id, metric_name)
);

COMMENT ON TABLE ab_test_results IS 'Stores statistical results of A/B tests for each variant';

-- =============================================
-- SECTION 6: DECENTRALIZED & FEDERATED FEATURES
-- =============================================

-- ActivityPub actors (for federation)
CREATE TABLE activity_pub_actors (
    actor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    actor_type VARCHAR(20) NOT NULL CHECK (actor_type IN ('Person', 'Organization', 'Application', 'Group')),
    username VARCHAR(100) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    public_key TEXT NOT NULL,
    private_key TEXT,
    inbox_url TEXT NOT NULL,
    outbox_url TEXT NOT NULL,
    shared_inbox_url TEXT,
    followers_url TEXT,
    following_url TEXT,
    featured_url TEXT,
    is_local BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (username, domain)
);

COMMENT ON TABLE activity_pub_actors IS 'Stores ActivityPub actors for federated identity and content sharing';

-- ActivityPub activities (for federation)
CREATE TABLE activity_pub_activities (
    activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('Create', 'Update', 'Delete', 'Follow', 'Accept', 'Reject', 'Like', 'Announce', 'Undo', 'Block')),
    actor_id UUID NOT NULL REFERENCES activity_pub_actors(actor_id),
    object_id TEXT NOT NULL, -- URI of the object
    object_type VARCHAR(50),
    local_object_id UUID, -- Reference to local content if applicable
    original_activity JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    processing_errors TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (actor_id, object_id, activity_type)
);

COMMENT ON TABLE activity_pub_activities IS 'Stores ActivityPub activities for federated content sharing';

-- ActivityPub inbox
CREATE TABLE activity_pub_inbox (
    inbox_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id TEXT NOT NULL, -- URI of the activity
    actor_id TEXT NOT NULL, -- URI of the actor
    activity_type VARCHAR(50) NOT NULL,
    activity_json JSONB NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_status VARCHAR(20) DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed', 'ignored')),
    processing_errors TEXT[],
    is_local BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE activity_pub_inbox IS 'Inbox for receiving ActivityPub activities from federated instances';

-- ActivityPub outbox
CREATE TABLE activity_pub_outbox (
    outbox_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    activity_id TEXT NOT NULL, -- URI of the activity
    actor_id UUID NOT NULL REFERENCES activity_pub_actors(actor_id),
    activity_type VARCHAR(50) NOT NULL,
    activity_json JSONB NOT NULL,
    target_inbox TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    send_status VARCHAR(20) DEFAULT 'pending' CHECK (send_status IN ('pending', 'sent', 'failed', 'retrying')),
    send_attempts INTEGER DEFAULT 0,
    last_error TEXT,
    UNIQUE (activity_id)
);

COMMENT ON TABLE activity_pub_outbox IS 'Outbox for sending ActivityPub activities to federated instances';

-- Federated instances
CREATE TABLE federated_instances (
    instance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    domain VARCHAR(255) NOT NULL UNIQUE,
    software_name VARCHAR(100),
    software_version VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    icon_url TEXT,
    banner_url TEXT,
    theme_color VARCHAR(7),
    is_blocked BOOLEAN DEFAULT FALSE,
    block_reason TEXT,
    last_contacted_at TIMESTAMP WITH TIME ZONE,
    last_successful_contact_at TIMESTAMP WITH TIME ZONE,
    reputation_score NUMERIC(5,2) DEFAULT 50,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE federated_instances IS 'Tracks known federated instances and their status';

-- Instance relationships
CREATE TABLE instance_relationships (
    relationship_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_instance_id UUID NOT NULL REFERENCES federated_instances(instance_id),
    target_instance_id UUID NOT NULL REFERENCES federated_instances(instance_id),
    relationship_type VARCHAR(20) NOT NULL CHECK (relationship_type IN ('follows', 'blocks', 'endorses', 'rejects')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_instance_id, target_instance_id, relationship_type)
);

COMMENT ON TABLE instance_relationships IS 'Tracks relationships between federated instances';

-- Content federation status
CREATE TABLE content_federation (
    federation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    federated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    federated_by UUID REFERENCES users(user_id),
    is_public BOOLEAN DEFAULT TRUE,
    is_unlisted BOOLEAN DEFAULT FALSE,
    is_followers_only BOOLEAN DEFAULT FALSE,
    is_moderated BOOLEAN DEFAULT FALSE,
    activity_pub_object_id TEXT UNIQUE,
    federated_to_instances TEXT[],
    UNIQUE (content_id)
);

COMMENT ON TABLE content_federation IS 'Tracks federation status of content to other instances';

-- Decentralized identity
CREATE TABLE decentralized_identity (
    identity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    identity_type VARCHAR(50) NOT NULL CHECK (identity_type IN ('did', 'pgp', 'ssh', 'minisign', 'ethereum')),
    identifier TEXT NOT NULL,
    public_key TEXT NOT NULL,
    private_key_encrypted TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, identity_type),
    UNIQUE (identifier)
);

COMMENT ON TABLE decentralized_identity IS 'Stores decentralized identity information for users';

-- Content verification proofs
CREATE TABLE content_verification_proofs (
    proof_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    proof_type VARCHAR(50) NOT NULL CHECK (proof_type IN ('signature', 'timestamp', 'witness', 'location', 'media')),
    proof_method VARCHAR(50) NOT NULL,
    proof_data JSONB NOT NULL,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE content_verification_proofs IS 'Stores cryptographic and other proofs for content verification';

-- Decentralized reputation
CREATE TABLE decentralized_reputation (
    reputation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    reputation_network VARCHAR(50) NOT NULL,
    reputation_protocol VARCHAR(50) NOT NULL,
    reputation_score NUMERIC NOT NULL,
    reputation_data JSONB,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    proof TEXT,
    UNIQUE (user_id, reputation_network, reputation_protocol)
);

COMMENT ON TABLE decentralized_reputation IS 'Tracks reputation scores from decentralized reputation networks';

-- =============================================
-- SECTION 7: MONETIZATION & INCENTIVES
-- =============================================

-- Cryptocurrency wallets
CREATE TABLE user_wallets (
    wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    wallet_type VARCHAR(50) NOT NULL CHECK (wallet_type IN ('ethereum', 'bitcoin', 'lightning', 'solana', 'cosmos')),
    address TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, wallet_type, address)
);

COMMENT ON TABLE user_wallets IS 'Stores cryptocurrency wallet addresses for users';

-- Token balances
CREATE TABLE token_balances (
    balance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    token_type VARCHAR(50) NOT NULL CHECK (token_type IN ('platform', 'ethereum', 'bitcoin', 'lightning', 'reputation')),
    balance NUMERIC(20,8) NOT NULL DEFAULT 0,
    locked_balance NUMERIC(20,8) NOT NULL DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, token_type)
);

COMMENT ON TABLE token_balances IS 'Tracks token balances for users across different token types';

-- Token transactions
CREATE TABLE token_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_user_id UUID REFERENCES users(user_id),
    to_user_id UUID REFERENCES users(user_id),
    token_type VARCHAR(50) NOT NULL CHECK (token_type IN ('platform', 'ethereum', 'bitcoin', 'lightning', 'reputation')),
    amount NUMERIC(20,8) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('tip', 'reward', 'purchase', 'withdrawal', 'deposit', 'transfer', 'staking', 'burn')),
    content_id UUID REFERENCES content(content_id),
    comment_id UUID REFERENCES content_comments(comment_id),
    transaction_hash TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

COMMENT ON TABLE token_transactions IS 'Records all token transactions between users and the platform';

-- Reward distributions
CREATE TABLE reward_distributions (
    distribution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    distribution_type VARCHAR(50) NOT NULL CHECK (distribution_type IN ('content', 'engagement', 'moderation', 'verification')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_amount NUMERIC(20,8) NOT NULL,
    distributed_amount NUMERIC(20,8) NOT NULL DEFAULT 0,
    distribution_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (distribution_status IN ('pending', 'calculating', 'ready', 'distributing', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    algorithm_version VARCHAR(50) NOT NULL,
    parameters JSONB NOT NULL
);

COMMENT ON TABLE reward_distributions IS 'Tracks periodic reward distributions to users';

-- Reward distribution items
CREATE TABLE reward_distribution_items (
    item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    distribution_id UUID NOT NULL REFERENCES reward_distributions(distribution_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    amount NUMERIC(20,8) NOT NULL,
    content_id UUID REFERENCES content(content_id),
    reason TEXT NOT NULL,
    distributed_at TIMESTAMP WITH TIME ZONE,
    transaction_id UUID REFERENCES token_transactions(transaction_id),
    UNIQUE (distribution_id, user_id, content_id, reason)
);

COMMENT ON TABLE reward_distribution_items IS 'Records individual rewards within a distribution';

-- Subscription plans
CREATE TABLE subscription_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_amount NUMERIC(10,2) NOT NULL,
    price_currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    billing_period VARCHAR(20) NOT NULL CHECK (billing_period IN ('monthly', 'quarterly', 'yearly', 'one_time')),
    is_active BOOLEAN DEFAULT TRUE,
    features JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE subscription_plans IS 'Defines subscription plans for premium features';

-- User subscriptions
CREATE TABLE user_subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    plan_id UUID NOT NULL REFERENCES subscription_plans(plan_id),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'paused')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    next_billing_date TIMESTAMP WITH TIME ZONE,
    payment_method VARCHAR(50),
    is_auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_subscriptions IS 'Tracks user subscriptions to premium plans';

-- Advertisements
CREATE TABLE advertisements (
    ad_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    advertiser_id UUID NOT NULL REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    target_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    budget_amount NUMERIC(10,2) NOT NULL,
    budget_currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    spent_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    targeting_criteria JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE advertisements IS 'Stores advertisements that can be displayed on the platform';

-- Ad impressions
CREATE TABLE ad_impressions (
    impression_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ad_id UUID NOT NULL REFERENCES advertisements(ad_id),
    user_id UUID REFERENCES users(user_id),
    visitor_id TEXT,
    impression_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    page_url TEXT NOT NULL,
    click_through BOOLEAN DEFAULT FALSE,
    click_through_time TIMESTAMP WITH TIME ZONE,
    cost NUMERIC(10,6) NOT NULL DEFAULT 0
);

COMMENT ON TABLE ad_impressions IS 'Tracks impressions and clicks for advertisements';

-- =============================================
-- SECTION 8: SYSTEM & OPERATIONAL TABLES
-- =============================================

-- System settings
CREATE TABLE system_settings (
    setting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    setting_group VARCHAR(50) NOT NULL,
    data_type VARCHAR(20) NOT NULL CHECK (data_type IN ('string', 'number', 'boolean', 'json', 'array')),
    is_public BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE system_settings IS 'Stores system configuration settings with different data types';

-- API keys
CREATE TABLE api_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    key_name VARCHAR(100) NOT NULL,
    api_key TEXT NOT NULL UNIQUE,
    api_secret TEXT NOT NULL,
    scopes TEXT[] NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE api_keys IS 'Stores API keys for system access with specific scopes';

-- System jobs
CREATE TABLE system_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(100) NOT NULL,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'retrying')),
    payload JSONB,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    last_heartbeat TIMESTAMP WITH TIME ZONE,
    progress NUMERIC(5,2) DEFAULT 0,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE system_jobs IS 'Tracks background jobs and their execution status';

-- Job logs
CREATE TABLE job_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES system_jobs(job_id) ON DELETE CASCADE,
    log_level VARCHAR(20) NOT NULL CHECK (log_level IN ('debug', 'info', 'warning', 'error', 'critical')),
    message TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE job_logs IS 'Stores detailed logs for system job execution';

-- System events
CREATE TABLE system_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    triggered_by UUID REFERENCES users(user_id),
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

COMMENT ON TABLE system_events IS 'Logs significant system events for auditing and monitoring';

-- System health metrics
CREATE TABLE system_health_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC NOT NULL,
    unit VARCHAR(20),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    UNIQUE (metric_name, collected_at)
);

COMMENT ON TABLE system_health_metrics IS 'Tracks system health metrics over time for monitoring';

-- Database migrations
CREATE TABLE database_migrations (
    migration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    migration_name VARCHAR(100) NOT NULL UNIQUE,
    batch INTEGER NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE database_migrations IS 'Tracks which database migrations have been executed';

-- =============================================
-- SECTION 9: VIEWS
-- =============================================

/*
 * View: published_content_view
 * Description: Shows all published content with author information and engagement metrics
 * Business Case: Used for content discovery feeds, search results, and analytics dashboards
 */
CREATE OR REPLACE VIEW published_content_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.excerpt,
    c.status,
    c.published_at,
    c.language,
    c.is_featured,
    c.is_breaking,
    c.is_verified,
    c.verification_score,
    ct.type_name AS content_type,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    u.profile_image_url AS author_profile_image,
    COALESCE(ca.views, 0) AS views,
    COALESCE(ca.unique_visitors, 0) AS unique_visitors,
    COALESCE(ca.completions, 0) AS completions,
    COALESCE(ca.shares, 0) AS shares,
    COALESCE(ca.comments_count, 0) AS comments_count,
    COALESCE(ca.reactions_count, 0) AS reactions_count,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'like') AS likes,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'trust') AS trust_votes,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'distrust') AS distrust_votes,
    (SELECT AVG(cts.score_value) FROM content_trust_scores cts WHERE cts.content_id = c.content_id) AS avg_trust_score,
    (SELECT STRING_AGG(t.name, ', ') FROM content_tags ct JOIN tags t ON ct.tag_id = t.tag_id WHERE ct.content_id = c.content_id) AS tags,
    (SELECT STRING_AGG(cat.name, ', ') FROM content_categories cc JOIN categories cat ON cc.category_id = cat.category_id WHERE cc.content_id = c.content_id) AS categories,
    cf.activity_pub_object_id IS NOT NULL AS is_federated
FROM
    content c
JOIN
    content_types ct ON c.content_type_id = ct.content_type_id
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    content_analytics ca ON c.content_id = ca.content_id AND ca.date = CURRENT_DATE
LEFT JOIN
    content_federation cf ON c.content_id = cf.content_id
WHERE
    c.status = 'published';

COMMENT ON VIEW published_content_view IS 'Shows all published content with author information and engagement metrics for discovery feeds and analytics';

/*
 * View: content_with_trust_view
 * Description: Shows content with detailed trust indicators and verification information
 * Business Case: Used for trust badges, content credibility displays, and fact-checking interfaces
 */
CREATE OR REPLACE VIEW content_with_trust_view AS
SELECT
    c.content_id,
    c.title,
    c.published_at,
    u.user_id AS author_id,
    u.display_name AS author_name,
    ur.reputation_score AS author_reputation,
    ur.credibility_score AS author_credibility,
    (SELECT COUNT(*) FROM content_fact_checks cfc WHERE cfc.content_id = c.content_id AND cfc.verdict IN ('true', 'mostly_true')) AS true_verdicts,
    (SELECT COUNT(*) FROM content_fact_checks cfc WHERE cfc.content_id = c.content_id AND cfc.verdict IN ('false', 'mostly_false')) AS false_verdicts,
    (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'verify') AS verify_votes,
    (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') AS dispute_votes,
    (SELECT COUNT(*) FROM content_sources cs WHERE cs.content_id = c.content_id AND cs.is_verified = TRUE) AS verified_sources,
    (SELECT COUNT(*) FROM content_witnesses cw WHERE cw.content_id = c.content_id AND cw.is_verified = TRUE) AS verified_witnesses,
    (SELECT AVG(cts.score_value) FROM content_trust_scores cts WHERE cts.content_id = c.content_id AND cts.score_type = 'community') AS community_trust_score,
    (SELECT AVG(cts.score_value) FROM content_trust_scores cts WHERE cts.content_id = c.content_id AND cts.score_type = 'expert') AS expert_trust_score,
    (SELECT STRING_AGG(cfv.flag_type, ', ') FROM content_flags cfv WHERE cfv.content_id = c.content_id AND cfv.status = 'pending') AS pending_flags,
    c.verification_score,
    c.is_verified
FROM
    content c
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    user_reputation ur ON u.user_id = ur.user_id
WHERE
    c.status = 'published';

COMMENT ON VIEW content_with_trust_view IS 'Shows content with detailed trust indicators and verification information for credibility assessment';

/*
 * View: user_engagement_metrics_view
 * Description: Aggregates user engagement metrics for analytics and leaderboards
 * Business Case: Used for user profiles, moderation dashboards, and reward calculations
 */
CREATE OR REPLACE VIEW user_engagement_metrics_view AS
SELECT
    u.user_id,
    u.username,
    u.display_name,
    u.profile_image_url,
    u.created_at AS join_date,
    ur.reputation_score,
    ur.credibility_score,
    (SELECT COUNT(*) FROM content c WHERE c.author_id = u.user_id AND c.status = 'published') AS published_content_count,
    (SELECT COUNT(*) FROM content c WHERE c.author_id = u.user_id AND c.is_verified = TRUE) AS verified_content_count,
    (SELECT COUNT(*) FROM content_comments cc WHERE cc.user_id = u.user_id AND cc.status = 'published') AS comments_count,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.user_id = u.user_id) AS reactions_given,
    (SELECT COUNT(*) FROM content_reactions cr JOIN content c ON cr.content_id = c.content_id WHERE c.author_id = u.user_id) AS reactions_received,
    (SELECT COUNT(*) FROM user_follows uf WHERE uf.followed_id = u.user_id) AS followers_count,
    (SELECT COUNT(*) FROM user_follows uf WHERE uf.follower_id = u.user_id) AS following_count,
    (SELECT COALESCE(SUM(ue.time_spent), INTERVAL '0 seconds') FROM user_engagement ue WHERE ue.user_id = u.user_id) AS total_time_spent,
    (SELECT COALESCE(SUM(tt.amount), 0) FROM token_transactions tt WHERE tt.to_user_id = u.user_id AND tt.token_type = 'platform' AND tt.status = 'completed') AS tokens_earned,
    (SELECT COALESCE(SUM(tt.amount), 0) FROM token_transactions tt WHERE tt.from_user_id = u.user_id AND tt.token_type = 'platform' AND tt.status = 'completed') AS tokens_spent,
    (SELECT COUNT(*) FROM user_badges ub WHERE ub.user_id = u.user_id) AS badge_count,
    (SELECT COUNT(*) FROM content_flags cf WHERE cf.user_id = u.user_id AND cf.status = 'actioned') AS flags_actioned,
    (SELECT COUNT(*) FROM content_fact_checks cfc WHERE cfc.fact_checker_id = u.user_id) AS fact_checks_count
FROM
    users u
LEFT JOIN
    user_reputation ur ON u.user_id = ur.user_id
WHERE
    u.is_deleted = FALSE;

COMMENT ON VIEW user_engagement_metrics_view IS 'Aggregates user engagement metrics for analytics and leaderboards';

/*
 * View: platform_kpi_dashboard_view
 * Description: Aggregates all KPIs for platform performance monitoring
 * Business Case: Used for executive dashboards and performance reporting
 */
CREATE OR REPLACE VIEW platform_kpi_dashboard_view AS
WITH daily_metrics AS (
    SELECT
        DATE_TRUNC('day', CURRENT_DATE) AS report_date,
        (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '1 day' AND is_deleted = FALSE) AS new_users,
        (SELECT COUNT(*) FROM content WHERE published_at >= CURRENT_DATE - INTERVAL '1 day' AND status = 'published') AS new_content,
        (SELECT COUNT(*) FROM content_comments WHERE created_at >= CURRENT_DATE - INTERVAL '1 day' AND status = 'published') AS new_comments,
        (SELECT COUNT(DISTINCT visitor_id) FROM visitor_sessions WHERE first_visit_at >= CURRENT_DATE - INTERVAL '1 day') AS new_visitors,
        (SELECT COUNT(DISTINCT visitor_id) FROM visitor_sessions WHERE last_activity_at >= CURRENT_DATE - INTERVAL '1 day') AS daily_active_users,
        (SELECT COUNT(*) FROM page_views WHERE view_time >= CURRENT_DATE - INTERVAL '1 day') AS page_views,
        (SELECT AVG(duration) FROM page_views WHERE view_time >= CURRENT_DATE - INTERVAL '1 day') AS avg_session_duration,
        (SELECT COUNT(*) FROM token_transactions WHERE created_at >= CURRENT_DATE - INTERVAL '1 day' AND status = 'completed') AS transactions,
        (SELECT COALESCE(SUM(amount), 0) FROM token_transactions WHERE created_at >= CURRENT_DATE - INTERVAL '1 day' AND status = 'completed' AND token_type = 'platform') AS tokens_circulated,
        (SELECT COUNT(*) FROM content_flags WHERE created_at >= CURRENT_DATE - INTERVAL '1 day') AS flags_submitted,
        (SELECT COUNT(*) FROM content_flags WHERE status = 'actioned' AND reviewed_at >= CURRENT_DATE - INTERVAL '1 day') AS flags_actioned
)
SELECT
    k.kpi_name,
    k.measurement_unit,
    k.target_value,
    k.is_higher_better,
    CASE
        WHEN k.kpi_name = 'Daily Active Users' THEN dm.daily_active_users
        WHEN k.kpi_name = 'New Users' THEN dm.new_users
        WHEN k.kpi_name = 'New Content' THEN dm.new_content
        WHEN k.kpi_name = 'Page Views' THEN dm.page_views
        WHEN k.kpi_name = 'Avg Session Duration' THEN dm.avg_session_duration
        WHEN k.kpi_name = 'Token Circulation' THEN dm.tokens_circulated
        WHEN k.kpi_name = 'Content Flags Actioned' THEN dm.flags_actioned
        ELSE (SELECT km.value FROM kpi_measurements km WHERE km.kpi_id = k.kpi_id ORDER BY km.measurement_time DESC LIMIT 1)
    END AS current_value,
    dm.report_date
FROM
    platform_kpis k
CROSS JOIN
    daily_metrics dm
WHERE
    k.reporting_frequency = 'daily';

COMMENT ON VIEW platform_kpi_dashboard_view IS 'Aggregates all KPIs for platform performance monitoring in executive dashboards';

/*
 * Materialized View: trending_content_view
 * Description: Pre-aggregates content trending metrics for performance
 * Business Case: Used for trending content sections and recommendation engines
 * Refresh: Refreshed hourly
 */
CREATE MATERIALIZED VIEW trending_content_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.published_at,
    c.content_type_id,
    ct.type_name AS content_type,
    c.author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    ca.views,
    ca.unique_visitors,
    ca.completions,
    ca.shares,
    ca.comments_count,
    ca.reactions_count,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'like') AS likes,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'trust') AS trust_votes,
    (SELECT COUNT(*) FROM content_reactions cr WHERE cr.content_id = c.content_id AND cr.reaction_type = 'distrust') AS distrust_votes,
    (SELECT AVG(cts.score_value) FROM content_trust_scores cts WHERE cts.content_id = c.content_id) AS avg_trust_score,
    EXTRACT(EPOCH FROM (NOW() - c.published_at)) / 3600 AS hours_since_publish,
    -- Trending score calculation (weighted algorithm)
    (
        (COALESCE(ca.views, 0) * 0.3) +
        (COALESCE(ca.completions, 0) * 0.5) +
        (COALESCE(ca.shares, 0) * 2) +
        (COALESCE(ca.comments_count, 0) * 1.2) +
        (COALESCE(ca.reactions_count, 0) * 0.8) +
        (SELECT COALESCE(AVG(cts.score_value), 0) * 10 FROM content_trust_scores cts WHERE cts.content_id = c.content_id)
    ) /
    GREATEST(POWER(EXTRACT(EPOCH FROM (NOW() - c.published_at)) / 3600 + 2, 1.8), 1) AS trending_score
FROM
    content c
JOIN
    content_types ct ON c.content_type_id = ct.content_type_id
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    content_analytics ca ON c.content_id = ca.content_id AND ca.date = CURRENT_DATE
WHERE
    c.status = 'published'
    AND c.published_at >= NOW() - INTERVAL '7 days'
ORDER BY
    trending_score DESC
LIMIT 100;

COMMENT ON MATERIALIZED VIEW trending_content_view IS 'Pre-aggregates content trending metrics using a weighted algorithm for performance in recommendation systems';

CREATE UNIQUE INDEX idx_trending_content_view ON trending_content_view (content_id);

-- Refresh function for materialized view
CREATE OR REPLACE FUNCTION refresh_trending_content_view()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY trending_content_view;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

/*
 * View: content_moderation_queue_view
 * Description: Shows content needing moderation with priority scoring
 * Business Case: Used by moderators to prioritize content review
 */
CREATE OR REPLACE VIEW content_moderation_queue_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.status,
    c.published_at,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    ur.reputation_score AS author_reputation,
    (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS pending_flags,
    (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') AS dispute_votes,
    (SELECT STRING_AGG(cf.flag_type, ', ') FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS flag_types,
    -- Moderation priority score calculation
    (
        (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') * 10 +
        (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') * 5 +
        CASE WHEN c.is_breaking THEN 20 ELSE 0 END +
        CASE WHEN c.verification_score < 50 THEN 15 ELSE 0 END +
        CASE WHEN ur.reputation_score < 50 THEN 10 ELSE 0 END
    ) AS priority_score,
    (SELECT STRING_AGG(t.name, ', ') FROM content_tags ct JOIN tags t ON ct.tag_id = t.tag_id WHERE ct.content_id = c.content_id) AS tags
FROM
    content c
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    user_reputation ur ON u.user_id = ur.user_id
WHERE
    (c.status = 'pending_review' OR
     EXISTS (SELECT 1 FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending'))
ORDER BY
    priority_score DESC;

COMMENT ON VIEW content_moderation_queue_view IS 'Shows content needing moderation with priority scoring for efficient review workflow';


/*
 * View: federated_content_view
 * Description: Shows content from both local and federated sources
 * Business Case: Used for federated content discovery and aggregation
 */
CREATE OR REPLACE VIEW content_moderation_queue_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.status,
    c.published_at,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    ur.reputation_score AS author_reputation,
    (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS pending_flags,
    (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') AS dispute_votes,
    (SELECT STRING_AGG(cf.flag_type, ', ') FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS flag_types,
    -- Moderation priority score calculation
    (
        (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') * 10 +
        (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') * 5 +
        CASE WHEN c.is_breaking THEN 20 ELSE 0 END +
        CASE WHEN c.verification_score < 50 THEN 15 ELSE 0 END +
        CASE WHEN ur.reputation_score < 50 THEN 10 ELSE 0 END
    ) AS priority_score,
    (SELECT STRING_AGG(t.name, ', ') FROM content_tags ct JOIN tags t ON ct.tag_id = t.tag_id WHERE ct.content_id = c.content_id) AS tags
FROM
    content c
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    user_reputation ur ON u.user_id = ur.user_id
WHERE
    (c.status = 'pending_review' OR
     EXISTS (SELECT 1 FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending'))
ORDER BY
    priority_score DESC;

COMMENT ON VIEW content_moderation_queue_view IS 'Shows content needing moderation with priority scoring for efficient review workflow';

-- =============================================
-- SECTION 10: STORED PROCEDURES
-- =============================================

/*
 * Procedure: publish_content
 * Description: Handles content publishing workflow with validation and notifications
 * Business Case: Ensures proper workflow for content publishing with all necessary checks
 */
CREATE OR REPLACE PROCEDURE publish_content(
    p_content_id UUID,
    p_publisher_id UUID,
    p_publish_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_author_id UUID;
    v_current_status VARCHAR(20);
    v_content_type VARCHAR(50);
    v_title VARCHAR(255);
    v_author_username VARCHAR(50);
    v_author_display_name VARCHAR(100);
    v_followers_count INTEGER;
    v_notification_id UUID;
BEGIN
    -- Get current content status and author
    SELECT author_id, status, title, (SELECT type_name FROM content_types WHERE content_type_id = c.content_type_id)
    INTO v_author_id, v_current_status, v_title, v_content_type
    FROM content c
    WHERE content_id = p_content_id;

    -- Validate content can be published
    IF v_current_status NOT IN ('draft', 'pending_review') THEN
        RAISE EXCEPTION 'Content cannot be published from current status: %', v_current_status;
    END IF;

    -- Check publisher permissions
    IF NOT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.permission_id
        WHERE ur.user_id = p_publisher_id
        AND p.permission_name = 'publish_content'
        AND ur.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'User does not have permission to publish content';
    END IF;

    -- Update content status
    UPDATE content
    SET
        status = 'published',
        published_at = COALESCE(p_publish_at, NOW()),
        updated_at = NOW(),
        updated_by = p_publisher_id
    WHERE content_id = p_content_id;

    -- Create a version snapshot
    INSERT INTO content_versions (
        content_id,
        version_number,
        title,
        body,
        excerpt,
        updated_by,
        change_reason
    )
    SELECT
        content_id,
        COALESCE((SELECT MAX(version_number) FROM content_versions WHERE content_id = p_content_id), 0) + 1,
        title,
        body,
        excerpt,
        p_publisher_id,
        'Published version'
    FROM content
    WHERE content_id = p_content_id;

    -- Get author info for notifications
    SELECT username, display_name INTO v_author_username, v_author_display_name
    FROM users WHERE user_id = v_author_id;

    -- Notify author
    INSERT INTO user_notifications (
        user_id,
        notification_type,
        title,
        message,
        related_content_id,
        action_url
    ) VALUES (
        v_author_id,
        'content_published',
        'Your content has been published',
        'Your ' || v_content_type || ' "' || v_title || '" has been published',
        p_content_id,
        '/content/' || (SELECT slug FROM content WHERE content_id = p_content_id)
    );

    -- Notify followers if author has any
    SELECT COUNT(*) INTO v_followers_count FROM user_follows WHERE followed_id = v_author_id;

    IF v_followers_count > 0 THEN
        -- Create a notification batch
        v_notification_id := uuid_generate_v4();

        INSERT INTO user_notifications (
            notification_id,
            user_id,
            notification_type,
            title,
            message,
            related_content_id,
            related_user_id,
            action_url
        )
        SELECT
            v_notification_id,
            uf.follower_id,
            'followed_author_published',
            v_author_display_name || ' published new content',
            v_author_username || ' has published a new ' || v_content_type || ': "' || v_title || '"',
            p_content_id,
            v_author_id,
            '/content/' || (SELECT slug FROM content WHERE content_id = p_content_id)
        FROM
            user_follows uf
        WHERE
            uf.followed_id = v_author_id
            AND uf.mute = FALSE
            AND EXISTS (
                SELECT 1 FROM user_notification_preferences unp
                WHERE unp.user_id = uf.follower_id
                AND unp.notification_type = 'followed_author_published'
                AND (unp.in_app_enabled = TRUE OR unp.email_enabled = TRUE OR unp.push_enabled = TRUE)
            );
    END IF;

    -- If federated, add to federation queue
    IF EXISTS (
        SELECT 1 FROM system_settings
        WHERE setting_key = 'federation.enabled'
        AND setting_value = 'true'
    ) THEN
        INSERT INTO content_federation (
            content_id,
            federated_by,
            is_public
        ) VALUES (
            p_content_id,
            p_publisher_id,
            TRUE
        );
    END IF;

    -- Log the publishing event
    INSERT INTO system_events (
        event_type,
        event_data,
        triggered_by
    ) VALUES (
        'content_published',
        jsonb_build_object('content_id', p_content_id, 'publisher_id', p_publisher_id),
        p_publisher_id
    );
END;
$$;

COMMENT ON PROCEDURE publish_content IS 'Handles content publishing workflow with validation, versioning, and notifications';

/*
 * Procedure: flag_content
 * Description: Handles content flagging by users with spam/abuse checks
 * Business Case: Ensures proper handling of user reports with anti-abuse mechanisms
 */
CREATE OR REPLACE PROCEDURE flag_content(
    p_content_id UUID,
    p_user_id UUID,
    p_flag_type VARCHAR(50),
    p_reason TEXT,
    p_is_anonymous BOOLEAN DEFAULT FALSE,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_author_id UUID;
    v_existing_flag_id UUID;
    v_flags_last_hour INTEGER;
    v_auto_ban_threshold INTEGER := 5; -- Configurable threshold
    v_moderator_notification_id UUID;
BEGIN
    -- Check if content exists and get author
    SELECT author_id INTO v_author_id FROM content WHERE content_id = p_content_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Content not found';
    END IF;

    -- Check if user is flagging their own content
    IF p_user_id = v_author_id THEN
        RAISE EXCEPTION 'You cannot flag your own content';
    END IF;

    -- Check for existing flag by this user
    SELECT flag_id INTO v_existing_flag_id
    FROM content_flags
    WHERE content_id = p_content_id AND user_id = p_user_id AND status = 'pending';

    IF v_existing_flag_id IS NOT NULL THEN
        RAISE EXCEPTION 'You have already flagged this content';
    END IF;

    -- Check for potential flag spam (same user flagging many items)
    SELECT COUNT(*) INTO v_flags_last_hour
    FROM content_flags
    WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '1 hour';

    IF v_flags_last_hour >= v_auto_ban_threshold THEN
        -- Automatic temporary ban for potential abuse
        INSERT INTO user_bans (
            user_id,
            moderator_id,
            reason,
            ban_type,
            ends_at
        ) VALUES (
            p_user_id,
            NULL, -- System automated ban
            'Excessive content flagging - possible spam',
            'suspension',
            NOW() + INTERVAL '24 hours'
        );

        RAISE EXCEPTION 'Your account has been temporarily suspended for excessive flagging';
    END IF;

    -- Create the flag
    INSERT INTO content_flags (
        content_id,
        user_id,
        flag_type,
        reason,
        status,
        is_anonymous,
        ip_address,
        user_agent
    ) VALUES (
        p_content_id,
        CASE WHEN p_is_anonymous THEN NULL ELSE p_user_id END,
        p_flag_type,
        p_reason,
        'pending',
        p_is_anonymous,
        p_ip_address,
        p_user_agent
    );

    -- Notify moderators if this is the first flag
    IF (SELECT COUNT(*) FROM content_flags WHERE content_id = p_content_id) = 1 THEN
        v_moderator_notification_id := uuid_generate_v4();

        -- Notify all active moderators
        INSERT INTO user_notifications (
            notification_id,
            user_id,
            notification_type,
            title,
            message,
            related_content_id,
            action_url
        )
        SELECT
            v_moderator_notification_id,
            ur.user_id,
            'content_flagged',
            'Content flagged for review',
            'Content "' || (SELECT title FROM content WHERE content_id = p_content_id) || '" has been flagged as ' || p_flag_type,
            p_content_id,
            '/moderate/content/' || p_content_id
        FROM
            user_roles ur
        JOIN
            roles r ON ur.role_id = r.role_id
        WHERE
            r.role_name = 'moderator'
            AND ur.is_active = TRUE
            AND EXISTS (
                SELECT 1 FROM user_notification_preferences unp
                WHERE unp.user_id = ur.user_id
                AND unp.notification_type = 'content_flagged'
                AND (unp.in_app_enabled = TRUE OR unp.email_enabled = TRUE OR unp.push_enabled = TRUE)
            );
    END IF;

    -- Log the flagging event
    INSERT INTO system_events (
        event_type,
        event_data,
        triggered_by
    ) VALUES (
        'content_flagged',
        jsonb_build_object(
            'content_id', p_content_id,
            'flag_type', p_flag_type,
            'anonymous', p_is_anonymous
        ),
        p_user_id
    );
END;
$$;

COMMENT ON PROCEDURE flag_content IS 'Handles content flagging by users with spam/abuse checks and moderator notifications';

/*
 * Procedure: calculate_user_reputation
 * Description: Recalculates user reputation scores based on activities
 * Business Case: Ensures reputation scores stay current and reflect user contributions
 */
CREATE OR REPLACE PROCEDURE calculate_user_reputation(
    p_user_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_reputation INTEGER := 0;
    v_new_credibility INTEGER := 50; -- Start at neutral 50/100
    v_published_content_count INTEGER;
    v_verified_content_count INTEGER;
    v_content_views_total BIGINT;
    v_content_likes_total INTEGER;
    v_content_trust_votes_total INTEGER;
    v_content_distrust_votes_total INTEGER;
    v_comments_count INTEGER;
    v_comment_likes_total INTEGER;
    v_followers_count INTEGER;
    v_flags_against_content INTEGER;
    v_flags_actioned_against_content INTEGER;
    v_fact_checks_count INTEGER;
    v_fact_checks_accurate_count INTEGER;
    v_account_age_days INTEGER;
    v_previous_reputation INTEGER;
    v_previous_credibility INTEGER;
BEGIN
    -- Get basic activity metrics
    SELECT
        COUNT(*) FILTER (WHERE status = 'published'),
        COUNT(*) FILTER (WHERE status = 'published' AND is_verified = TRUE),
        COALESCE(SUM(views), 0),
        COALESCE(SUM(likes), 0),
        COALESCE(SUM(trust_votes), 0),
        COALESCE(SUM(distrust_votes), 0)
    INTO
        v_published_content_count,
        v_verified_content_count,
        v_content_views_total,
        v_content_likes_total,
        v_content_trust_votes_total,
        v_content_distrust_votes_total
    FROM
        published_content_view
    WHERE
        author_id = p_user_id;

    -- Get comment metrics
    SELECT
        COUNT(*),
        COALESCE(SUM((SELECT COUNT(*) FROM comment_reactions cr WHERE cr.comment_id = cc.comment_id AND cr.reaction_type = 'like')), 0)
    INTO
        v_comments_count,
        v_comment_likes_total
    FROM
        content_comments cc
    WHERE
        cc.user_id = p_user_id
        AND cc.status = 'published';

    -- Get social metrics
    SELECT COUNT(*) INTO v_followers_count FROM user_follows WHERE followed_id = p_user_id;

    -- Get moderation metrics
    SELECT
        COUNT(*) FILTER (WHERE reported_user_id = p_user_id),
        COUNT(*) FILTER (WHERE reported_user_id = p_user_id AND status = 'actioned')
    INTO
        v_flags_against_content,
        v_flags_actioned_against_content
    FROM
        user_flags
    WHERE
        reported_user_id = p_user_id;

    -- Get fact-checking metrics
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE verdict IN ('true', 'mostly_true'))
    INTO
        v_fact_checks_count,
        v_fact_checks_accurate_count
    FROM
        content_fact_checks
    WHERE
        fact_checker_id = p_user_id;

    -- Get account age
    SELECT EXTRACT(DAY FROM NOW() - created_at) INTO v_account_age_days
    FROM users WHERE user_id = p_user_id;

    -- Get previous scores for comparison
    SELECT reputation_score, credibility_score
    INTO v_previous_reputation, v_previous_credibility
    FROM user_reputation WHERE user_id = p_user_id;

    -- Calculate new reputation score (weighted algorithm)
    v_new_reputation :=
        -- Base for having an account
        10 +
        -- Published content (weighted by verification status)
        (v_published_content_count * 5) + (v_verified_content_count * 15) +
        -- Content engagement
        LEAST(v_content_views_total / 100, 50) + -- Cap at 50 points for views
        (v_content_likes_total * 2) +
        -- Trust signals
        (v_content_trust_votes_total * 3) - (v_content_distrust_votes_total * 2) +
        -- Comments
        (v_comments_count * 1) + (v_comment_likes_total * 1) +
        -- Social proof
        LEAST(v_followers_count * 2, 100) + -- Cap at 100 points for followers
        -- Fact checking contributions
        (v_fact_checks_count * 3) + (v_fact_checks_accurate_count * 5) +
        -- Account age bonus
        LEAST(v_account_age_days / 30, 50); -- Cap at 50 points for longevity

    -- Ensure reputation doesn't go below 0
    v_new_reputation := GREATEST(v_new_reputation, 0);

    -- Calculate credibility score (0-100 scale)
    IF v_published_content_count > 0 THEN
        -- Base credibility on content verification and community trust
        v_new_credibility := 50 + -- Start at neutral
            -- Verified content bonus
            (v_verified_content_count * 100 / GREATEST(v_published_content_count, 1)) / 2 +
            -- Community trust signals
            ((v_content_trust_votes_total - v_content_distrust_votes_total) * 100 / GREATEST(v_content_trust_votes_total + v_content_distrust_votes_total, 1)) / 4 +
            -- Fact checking accuracy
            CASE WHEN v_fact_checks_count > 0
                 THEN (v_fact_checks_accurate_count * 100 / v_fact_checks_count) / 4
                 ELSE 0 END -
            -- Penalty for actioned flags
            (v_flags_actioned_against_content * 10);

        -- Ensure credibility stays within bounds
        v_new_credibility := GREATEST(LEAST(v_new_credibility, 100), 0);
    END IF;

    -- Update or insert reputation record
    INSERT INTO user_reputation (
        user_id,
        reputation_score,
        credibility_score,
        last_calculated_at
    ) VALUES (
        p_user_id,
        v_new_reputation,
        v_new_credibility,
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        reputation_score = v_new_reputation,
        credibility_score = v_new_credibility,
        last_calculated_at = NOW();

    -- Record history if scores changed significantly
    IF v_previous_reputation IS NULL OR
       ABS(v_new_reputation - v_previous_reputation) > 5 OR
       ABS(v_new_credibility - v_previous_credibility) > 5 THEN
        INSERT INTO user_reputation_history (
            user_id,
            change_amount,
            new_score,
            reason,
            changed_at
        ) VALUES (
            p_user_id,
            v_new_reputation - COALESCE(v_previous_reputation, 0),
            v_new_reputation,
            'Periodic recalculation',
            NOW()
        );

        INSERT INTO user_reputation_history (
            user_id,
            change_amount,
            new_score,
            reason,
            changed_at
        ) VALUES (
            p_user_id,
            v_new_credibility - COALESCE(v_previous_credibility, 50),
            v_new_credibility,
            'Periodic recalculation',
            NOW()
        );
    END IF;

    -- Log the reputation update
    INSERT INTO system_events (
        event_type,
        event_data,
        triggered_by
    ) VALUES (
        'user_reputation_updated',
        jsonb_build_object(
            'user_id', p_user_id,
            'old_reputation', v_previous_reputation,
            'new_reputation', v_new_reputation,
            'old_credibility', v_previous_credibility,
            'new_credibility', v_new_credibility
        ),
        NULL -- System triggered
    );
END;
$$;

COMMENT ON PROCEDURE calculate_user_reputation IS 'Recalculates user reputation and credibility scores based on content, engagement, and community signals';

/*
 * Procedure: process_activity_pub_inbox
 * Description: Processes incoming ActivityPub activities from federated instances
 * Business Case: Handles federation with other ActivityPub-compatible platforms
 */
CREATE OR REPLACE PROCEDURE process_activity_pub_inbox()
LANGUAGE plpgsql
AS $$
DECLARE
    v_inbox_item RECORD;
    v_actor_id UUID;
    v_local_actor_id UUID;
    v_content_id UUID;
    v_activity_type VARCHAR(50);
    v_object_type VARCHAR(50);
    v_object_id TEXT;
    v_actor_json JSONB;
    v_object_json JSONB;
    v_processed BOOLEAN := FALSE;
    v_error TEXT;
BEGIN
    -- Check if federation is enabled
    IF NOT EXISTS (
        SELECT 1 FROM system_settings
        WHERE setting_key = 'federation.enabled'
        AND setting_value = 'true'
    ) THEN
        RETURN; -- Federation is disabled
    END IF;

    -- Process up to 10 inbox items at a time to avoid long transactions
    FOR v_inbox_item IN
        SELECT * FROM activity_pub_inbox
        WHERE processing_status = 'pending'
        ORDER BY received_at
        LIMIT 10
    LOOP
        BEGIN
            v_activity_type := v_inbox_item.activity_json->>'type';
            v_object_type := v_inbox_item.activity_json->>'object'->>'type';
            v_object_id := v_inbox_item.activity_json->>'object'->>'id';
            v_actor_json := v_inbox_item.activity_json->>'actor';
            v_object_json := v_inbox_item.activity_json->>'object';

            -- First, ensure we have the actor in our database
            SELECT actor_id INTO v_actor_id
            FROM activity_pub_actors
            WHERE username = v_actor_json->>'preferredUsername'
            AND domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)');

            IF v_actor_id IS NULL THEN
                -- Create new actor record for remote actor
                INSERT INTO activity_pub_actors (
                    actor_type,
                    username,
                    domain,
                    public_key,
                    inbox_url,
                    outbox_url,
                    shared_inbox_url,
                    followers_url,
                    following_url,
                    is_local,
                    created_at,
                    updated_at
                ) VALUES (
                    v_actor_json->>'type',
                    v_actor_json->>'preferredUsername',
                    SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)'),
                    v_actor_json->>'publicKey'->>'publicKeyPem',
                    v_actor_json->>'inbox',
                    v_actor_json->>'outbox',
                    v_actor_json->>'endpoints'->>'sharedInbox',
                    v_actor_json->>'followers',
                    v_actor_json->>'following',
                    FALSE,
                    NOW(),
                    NOW()
                ) RETURNING actor_id INTO v_actor_id;
            END IF;

            -- Handle different activity types
            CASE v_activity_type
                WHEN 'Create' THEN
                    -- Handle content creation
                    IF v_object_type IN ('Article', 'NewsArticle', 'Note', 'Video', 'Audio') THEN
                        -- Only process if from instances we follow or that are not blocked
                        IF EXISTS (
                            SELECT 1 FROM federated_instances fi
                            JOIN instance_relationships ir ON fi.instance_id = ir.target_instance_id
                            WHERE fi.domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)')
                            AND ir.relationship_type = 'follows'
                            AND NOT EXISTS (
                                SELECT 1 FROM federated_instances fi
                                JOIN instance_relationships ir ON fi.instance_id = ir.target_instance_id
                                WHERE fi.domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)')
                                AND ir.relationship_type = 'blocks'
                            )
                        ) THEN
                            -- Store the activity for display in federated feeds
                            INSERT INTO activity_pub_activities (
                                activity_type,
                                actor_id,
                                object_id,
                                object_type,
                                original_activity,
                                processed
                            ) VALUES (
                                v_activity_type,
                                v_actor_id,
                                v_object_id,
                                v_object_type,
                                v_inbox_item.activity_json,
                                TRUE
                            );

                            v_processed := TRUE;
                        END IF;
                    END IF;

                WHEN 'Follow' THEN
                    -- Handle follow requests
                    IF v_object_json->>'id' LIKE '%/actor' THEN
                        -- This is a follow request for our instance actor
                        -- Check if we want to accept follows from this instance
                        IF EXISTS (
                            SELECT 1 FROM federated_instances fi
                            WHERE fi.domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)')
                            AND fi.is_blocked = FALSE
                        ) THEN
                            -- Create an Accept activity in our outbox
                            INSERT INTO activity_pub_outbox (
                                activity_id,
                                actor_id,
                                activity_type,
                                activity_json,
                                target_inbox
                            ) VALUES (
                                'urn:uuid:' || uuid_generate_v4(),
                                (SELECT actor_id FROM activity_pub_actors WHERE is_local = TRUE AND actor_type = 'Application' LIMIT 1),
                                'Accept',
                                jsonb_build_object(
                                    '@context', 'https://www.w3.org/ns/activitystreams',
                                    'type', 'Accept',
                                    'actor', (SELECT actor_id FROM activity_pub_actors WHERE is_local = TRUE AND actor_type = 'Application' LIMIT 1),
                                    'object', v_inbox_item.activity_json
                                ),
                                v_actor_json->>'inbox'
                            );

                            -- Record the follow relationship
                            INSERT INTO instance_relationships (
                                source_instance_id,
                                target_instance_id,
                                relationship_type
                            ) VALUES (
                                (SELECT instance_id FROM federated_instances WHERE domain = (SELECT domain FROM activity_pub_actors WHERE actor_id = (SELECT actor_id FROM activity_pub_actors WHERE is_local = TRUE AND actor_type = 'Application' LIMIT 1))),
                                (SELECT instance_id FROM federated_instances WHERE domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)')),
                                'follows'
                            )
                            ON CONFLICT (source_instance_id, target_instance_id, relationship_type) DO NOTHING;

                            v_processed := TRUE;
                        END IF;
                    END IF;

                WHEN 'Like', 'Announce' THEN
                    -- Handle likes and boosts (announces) of our content
                    IF v_object_json->>'id' LIKE '%/content/%' THEN
                        -- Extract our content UUID from the object ID
                        v_content_id := SUBSTRING(v_object_json->>'id' FROM 'content/([a-f0-9-]+)')::UUID;

                        -- Verify the content exists
                        IF EXISTS (SELECT 1 FROM content WHERE content_id = v_content_id) THEN
                            -- Record the reaction
                            IF v_activity_type = 'Like' THEN
                                -- Get our local actor for the system user
                                SELECT actor_id INTO v_local_actor_id
                                FROM activity_pub_actors
                                WHERE is_local = TRUE AND actor_type = 'Application';

                                -- Record the like
                                INSERT INTO content_reactions (
                                    content_id,
                                    user_id,
                                    reaction_type,
                                    reacted_at
                                ) VALUES (
                                    v_content_id,
                                    (SELECT user_id FROM users WHERE username = 'system'),
                                    'like',
                                    (v_inbox_item.activity_json->>'published')::TIMESTAMP WITH TIME ZONE
                                )
                                ON CONFLICT (content_id, user_id, reaction_type) DO NOTHING;
                            ELSIF v_activity_type = 'Announce' THEN
                                -- Record the share
                                INSERT INTO content_metadata (
                                    content_id,
                                    meta_key,
                                    meta_value
                                ) VALUES (
                                    v_content_id,
                                    'federated_shares',
                                    COALESCE(
                                        (SELECT meta_value FROM content_metadata
                                         WHERE content_id = v_content_id AND meta_key = 'federated_shares'),
                                        '0'
                                    )::INTEGER + 1
                                )
                                ON CONFLICT (content_id, meta_key) DO UPDATE
                                SET meta_value = EXCLUDED.meta_value;
                            END IF;

                            v_processed := TRUE;
                        END IF;
                    END IF;

                WHEN 'Undo' THEN
                    -- Handle undo activities (unlike, unfollow, etc.)
                    IF v_object_json->>'type' = 'Like' AND v_object_json->>'object' LIKE '%/content/%' THEN
                        -- Extract our content UUID from the object ID
                        v_content_id := SUBSTRING(v_object_json->>'object' FROM 'content/([a-f0-9-]+)')::UUID;

                        -- Remove the like
                        DELETE FROM content_reactions
                        WHERE content_id = v_content_id
                        AND user_id = (SELECT user_id FROM users WHERE username = 'system')
                        AND reaction_type = 'like';

                        v_processed := TRUE;
                    ELSIF v_object_json->>'type' = 'Follow' AND v_object_json->>'object' LIKE '%/actor' THEN
                        -- Remove the follow relationship
                        DELETE FROM instance_relationships
                        WHERE source_instance_id = (SELECT instance_id FROM federated_instances WHERE domain = SUBSTRING(v_actor_json->>'id' FROM 'https?://([^/]+)'))
                        AND target_instance_id = (SELECT instance_id FROM federated_instances WHERE domain = (SELECT domain FROM activity_pub_actors WHERE actor_id = (SELECT actor_id FROM activity_pub_actors WHERE is_local = TRUE AND actor_type = 'Application' LIMIT 1)))
                        AND relationship_type = 'follows';

                        v_processed := TRUE;
                    END IF;

                ELSE
                    -- Unsupported activity type
                    v_processed := FALSE;
            END CASE;

            -- Update inbox item status
            UPDATE activity_pub_inbox
            SET
                processing_status = CASE WHEN v_processed THEN 'processed' ELSE 'ignored' END,
                processed_at = NOW(),
                processing_errors = CASE WHEN NOT v_processed THEN ARRAY['Unsupported activity type'] ELSE NULL END
            WHERE
                inbox_item_id = v_inbox_item.inbox_item_id;

        EXCEPTION WHEN OTHERS THEN
            -- Record processing error
            v_error := SQLERRM;

            UPDATE activity_pub_inbox
            SET
                processing_status = 'failed',
                processed_at = NOW(),
                processing_errors = ARRAY[v_error]
            WHERE
                inbox_item_id = v_inbox_item.inbox_item_id;
        END;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE process_activity_pub_inbox IS 'Processes incoming ActivityPub activities from federated instances, handling content, follows, likes, and other interactions';

/*
 * Procedure: federate_content
 * Description: Publishes content to federated instances via ActivityPub
 * Business Case: Enables decentralized distribution of content to other platforms
 */
CREATE OR REPLACE PROCEDURE federate_content(
    p_content_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_content RECORD;
    v_author RECORD;
    v_author_actor RECORD;
    v_instance RECORD;
    v_activity_id TEXT;
    v_activity_json JSONB;
    v_followers TEXT[];
BEGIN
    -- Check if federation is enabled
    IF NOT EXISTS (
        SELECT 1 FROM system_settings
        WHERE setting_key = 'federation.enabled'
        AND setting_value = 'true'
    ) THEN
        RETURN; -- Federation is disabled
    END IF;

    -- Get content and author details
    SELECT
        c.content_id, c.title, c.body, c.slug, c.published_at,
        c.language, c.is_verified, c.verification_score,
        ct.type_name AS content_type,
        u.user_id, u.username, u.display_name, u.profile_image_url
    INTO v_content
    FROM
        content c
    JOIN
        content_types ct ON c.content_type_id = ct.content_type_id
    JOIN
        users u ON c.author_id = u.user_id
    WHERE
        c.content_id = p_content_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Content not found';
    END IF;

    -- Get author's ActivityPub actor
    SELECT * INTO v_author_actor
    FROM activity_pub_actors
    WHERE user_id = v_content.user_id;

    IF NOT FOUND THEN
        -- Create actor record if it doesn't exist
        INSERT INTO activity_pub_actors (
            user_id,
            actor_type,
            username,
            domain,
            public_key,
            private_key,
            inbox_url,
            outbox_url,
            followers_url,
            following_url,
            is_local,
            created_at,
            updated_at
        ) VALUES (
            v_content.user_id,
            'Person',
            v_content.username,
            (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain'),
            -- In a real implementation, we'd generate actual keys here
            '-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----',
            '-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----',
            'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/actor/' || v_content.username || '/inbox',
            'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/actor/' || v_content.username || '/outbox',
            'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/actor/' || v_content.username || '/followers',
            'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/actor/' || v_content.username || '/following',
            TRUE,
            NOW(),
            NOW()
        ) RETURNING * INTO v_author_actor;
    END IF;

    -- Create ActivityPub object for the content
    v_activity_id := 'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/activities/' || uuid_generate_v4();

    -- Determine the appropriate ActivityStreams type
    CASE v_content.content_type
        WHEN 'article' THEN v_activity_json := jsonb_build_object('type', 'Article');
        WHEN 'video' THEN v_activity_json := jsonb_build_object('type', 'Video');
        WHEN 'audio' THEN v_activity_json := jsonb_build_object('type', 'Audio');
        ELSE v_activity_json := jsonb_build_object('type', 'Note');
    END CASE;

    -- Add common properties
    v_activity_json := v_activity_json || jsonb_build_object(
        'id', 'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/content/' || v_content.content_id,
        'attributedTo', v_author_actor.actor_id,
        'content', v_content.body,
        'name', v_content.title,
        'published', v_content.published_at,
        'url', 'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/content/' || v_content.slug,
        'to', 'https://www.w3.org/ns/activitystreams#Public',
        'cc', ARRAY[v_author_actor.followers_url],
        'tag', ARRAY[]::JSONB[] -- Would include hashtags in a real implementation
    );

    -- Add verification info if content is verified
    IF v_content.is_verified THEN
        v_activity_json := v_activity_json || jsonb_build_object(
            'verification', jsonb_build_object(
                'verified', TRUE,
                'score', v_content.verification_score
            )
        );
    END IF;

    -- Create the Create activity
    v_activity_json := jsonb_build_object(
        '@context', 'https://www.w3.org/ns/activitystreams',
        'id', v_activity_id,
        'type', 'Create',
        'actor', v_author_actor.actor_id,
        'published', NOW(),
        'to', 'https://www.w3.org/ns/activitystreams#Public',
        'cc', ARRAY[v_author_actor.followers_url],
        'object', v_activity_json
    );

    -- Store the activity in our database
    INSERT INTO activity_pub_activities (
        activity_type,
        actor_id,
        object_id,
        object_type,
        local_object_id,
        original_activity,
        processed,
        published_at
    ) VALUES (
        'Create',
        v_author_actor.actor_id,
        'https://' || (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain') || '/content/' || v_content.content_id,
        v_content.content_type,
        v_content.content_id,
        v_activity_json,
        TRUE,
        NOW()
    );

    -- Get all instances that follow our instance or this author
    SELECT ARRAY(
        SELECT fi.domain
        FROM federated_instances fi
        JOIN instance_relationships ir ON fi.instance_id = ir.source_instance_id
        WHERE ir.relationship_type = 'follows'
        AND (ir.target_instance_id = (SELECT instance_id FROM federated_instances WHERE domain = (SELECT setting_value FROM system_settings WHERE setting_key = 'instance.domain'))
            OR ir.target_instance_id = (SELECT instance_id FROM federated_instances WHERE domain = v_author_actor.domain))
        AND fi.is_blocked = FALSE
    ) INTO v_followers;

    -- For each follower, add to outbox for delivery
    FOREACH v_instance.domain IN ARRAY v_followers
    LOOP
        -- In a real implementation, we'd look up the shared inbox if available
        INSERT INTO activity_pub_outbox (
            activity_id,
            actor_id,
            activity_type,
            activity_json,
            target_inbox
        ) VALUES (
            v_activity_id,
            v_author_actor.actor_id,
            'Create',
            v_activity_json,
            'https://' || v_instance.domain || '/inbox'
        );
    END LOOP;

    -- Update federation status
    UPDATE content_federation
    SET
        federated_at = NOW(),
        federated_to_instances = v_followers
    WHERE
        content_id = p_content_id;

    -- Log the federation event
    INSERT INTO system_events (
        event_type,
        event_data,
        triggered_by
    ) VALUES (
        'content_federated',
        jsonb_build_object(
            'content_id', p_content_id,
            'author_id', v_content.user_id,
            'federated_to', v_followers
        ),
        NULL -- System triggered
    );
END;
$$;

COMMENT ON PROCEDURE federate_content IS 'Publishes content to federated instances via ActivityPub for decentralized distribution';

/*
 * Procedure: calculate_content_trust_score
 * Description: Calculates a comprehensive trust score for content
 * Business Case: Provides automated trust assessment for content credibility
 */
CREATE OR REPLACE PROCEDURE calculate_content_trust_score(
    p_content_id UUID
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_author_id UUID;
    v_author_reputation INTEGER;
    v_author_credibility INTEGER;
    v_community_trust_score NUMERIC := 0;
    v_automated_trust_score NUMERIC := 0;
    v_expert_trust_score NUMERIC := 0;
    v_final_trust_score NUMERIC := 0;
    v_verdict_ratio NUMERIC := 0;
    v_source_count INTEGER := 0;
    v_verified_source_count INTEGER := 0;
    v_witness_count INTEGER := 0;
    v_verified_witness_count INTEGER := 0;
    v_trust_votes INTEGER := 0;
    v_distrust_votes INTEGER := 0;
    v_flag_count INTEGER := 0;
    v_media_count INTEGER := 0;
    v_media_with_proof_count INTEGER := 0;
    v_blockchain_verifications INTEGER := 0;
    v_content_length INTEGER;
    v_word_count INTEGER;
    v_sentiment_score NUMERIC;
    v_readability_score NUMERIC;
    v_previous_verification_score INTEGER;
    v_previous_is_verified BOOLEAN;
BEGIN
    -- Get author information
    SELECT
        author_id,
        verification_score,
        is_verified
    INTO
        v_author_id,
        v_previous_verification_score,
        v_previous_is_verified
    FROM
        content
    WHERE
        content_id = p_content_id;

    -- Get author reputation
    SELECT
        reputation_score,
        credibility_score
    INTO
        v_author_reputation,
        v_author_credibility
    FROM
        user_reputation
    WHERE
        user_id = v_author_id;

    -- If no reputation record exists, use defaults
    v_author_reputation := COALESCE(v_author_reputation, 50);
    v_author_credibility := COALESCE(v_author_credibility, 50);

    -- Calculate community trust signals
    SELECT
        COUNT(*) FILTER (WHERE vote_type = 'verify'),
        COUNT(*) FILTER (WHERE vote_type = 'dispute')
    INTO
        v_trust_votes,
        v_distrust_votes
    FROM
        content_verification_votes
    WHERE
        content_id = p_content_id;

    -- Calculate ratio of verify to dispute votes
    IF (v_trust_votes + v_distrust_votes) > 0 THEN
        v_community_trust_score := (v_trust_votes * 100.0 / (v_trust_votes + v_distrust_votes));
    END IF;

    -- Count flags
    SELECT COUNT(*) INTO v_flag_count
    FROM content_flags
    WHERE content_id = p_content_id AND status = 'pending';

    -- Calculate fact-check verdicts
    SELECT
        COUNT(*) FILTER (WHERE verdict IN ('true', 'mostly_true')),
        COUNT(*) FILTER (WHERE verdict IN ('false', 'mostly_false')),
        COUNT(*) AS total
    INTO
        v_verdict_ratio,
        v_verdict_ratio, -- Reusing variable for false count
        v_verdict_ratio -- Reusing variable for total count
    FROM
        content_fact_checks
    WHERE
        content_id = p_content_id;

    -- Calculate verdict ratio if we have fact checks
    IF v_verdict_ratio > 0 THEN
        v_verdict_ratio := ((v_verdict_ratio - v_verdict_ratio) * 100.0 / v_verdict_ratio); -- (true - false) / total
    END IF;

    -- Count sources and witnesses
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE is_verified = TRUE)
    INTO
        v_source_count,
        v_verified_source_count
    FROM
        content_sources
    WHERE
        content_id = p_content_id;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE is_verified = TRUE)
    INTO
        v_witness_count,
        v_verified_witness_count
    FROM
        content_witnesses
    WHERE
        content_id = p_content_id;

    -- Count media with verification proofs
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE metadata->>'verification_proof' IS NOT NULL)
    INTO
        v_media_count,
        v_media_with_proof_count
    FROM
        content_media
    WHERE
        content_id = p_content_id;

    -- Count blockchain verifications
    SELECT COUNT(*) INTO v_blockchain_verifications
    FROM content_blockchain_verification
    WHERE content_id = p_content_id;

    -- Calculate automated signals (would be more sophisticated in reality)
    SELECT
        LENGTH(body),
        ARRAY_LENGTH(REGEXP_SPLIT_TO_ARRAY(body, '\s+'), 1),
        -- These would come from actual analysis in a real implementation
        0.5, -- Placeholder for sentiment score
        70.0 -- Placeholder for readability score
    INTO
        v_content_length,
        v_word_count,
        v_sentiment_score,
        v_readability_score
    FROM
        content
    WHERE
        content_id = p_content_id;

    -- Calculate automated trust score (simplified example)
    v_automated_trust_score :=
        CASE WHEN v_word_count > 500 THEN 20 ELSE 10 END + -- Longer content gets more trust
        CASE WHEN v_sentiment_score > 0.7 THEN -10 WHEN v_sentiment_score < 0.3 THEN -5 ELSE 0 END + -- Neutral sentiment is best
        CASE WHEN v_readability_score > 60 THEN 10 ELSE 0 END + -- Good readability helps
        CASE WHEN v_media_count > 0 THEN 10 ELSE 0 END + -- Media presence helps
        (v_media_with_proof_count * 5) + -- Verified media helps more
        (v_blockchain_verifications * 15); -- Blockchain verification is strong signal

    -- Calculate expert trust score (simplified example)
    v_expert_trust_score :=
        (v_author_credibility * 0.3) + -- Author credibility matters
        (v_verdict_ratio * 0.5) + -- Fact check verdicts matter
        (CASE WHEN v_source_count > 0 THEN (v_verified_source_count * 100.0 / v_source_count) ELSE 0 END * 0.2);

    -- Combine scores with weights
    v_final_trust_score :=
        (v_author_reputation * 0.2) +
        (v_community_trust_score * 0.3) +
        (v_automated_trust_score * 0.2) +
        (v_expert_trust_score * 0.3) -
        (v_flag_count * 5); -- Flags reduce trust

    -- Ensure score is within bounds
    v_final_trust_score := GREATEST(LEAST(v_final_trust_score, 100), 0);

    -- Update content with new verification status
    UPDATE content
    SET
        verification_score = ROUND(v_final_trust_score),
        is_verified = CASE WHEN v_final_trust_score >= 75 THEN TRUE ELSE FALSE END,
        updated_at = NOW()
    WHERE
        content_id = p_content_id;

    -- Store detailed trust scores
    INSERT INTO content_trust_scores (
        content_id,
        score_type,
        score_value,
        confidence,
        calculated_at,
        algorithm_version,
        details
    ) VALUES
    (
        p_content_id,
        'community',
        v_community_trust_score,
        0.8,
        NOW(),
        '1.0',
        jsonb_build_object(
            'trust_votes', v_trust_votes,
            'distrust_votes', v_distrust_votes,
            'flag_count', v_flag_count
        )
    ),
    (
        p_content_id,
        'automated',
        v_automated_trust_score,
        0.6,
        NOW(),
        '1.0',
        jsonb_build_object(
            'content_length', v_content_length,
            'word_count', v_word_count,
            'sentiment_score', v_sentiment_score,
            'readability_score', v_readability_score,
            'media_count', v_media_count,
            'media_with_proof_count', v_media_with_proof_count,
            'blockchain_verifications', v_blockchain_verifications
        )
    ),
    (
        p_content_id,
        'expert',
        v_expert_trust_score,
        0.9,
        NOW(),
        '1.0',
        jsonb_build_object(
            'author_credibility', v_author_credibility,
            'verdict_ratio', v_verdict_ratio,
            'source_count', v_source_count,
            'verified_source_count', v_verified_source_count,
            'witness_count', v_witness_count,
            'verified_witness_count', v_verified_witness_count
        )
    )
    ON CONFLICT (content_id, score_type)
    DO UPDATE SET
        score_value = EXCLUDED.score_value,
        confidence = EXCLUDED.confidence,
        calculated_at = EXCLUDED.calculated_at,
        algorithm_version = EXCLUDED.algorithm_version,
        details = EXCLUDED.details;

    -- If verification status changed, log an event
    IF (v_previous_verification_score IS DISTINCT FROM ROUND(v_final_trust_score)) OR
       (v_previous_is_verified IS DISTINCT FROM (v_final_trust_score >= 75)) THEN
        INSERT INTO system_events (
            event_type,
            event_data,
            triggered_by
        ) VALUES (
            'content_trust_score_updated',
            jsonb_build_object(
                'content_id', p_content_id,
                'old_score', v_previous_verification_score,
                'new_score', ROUND(v_final_trust_score),
                'old_verified', v_previous_is_verified,
                'new_verified', (v_final_trust_score >= 75),
                'author_id', v_author_id
            ),
            NULL -- System triggered
        );
    END IF;
END;
$$;

COMMENT ON PROCEDURE calculate_content_trust_score IS 'Calculates a comprehensive trust score for content based on author reputation, community signals, and automated analysis';

-- =============================================
-- SECTION 11: TRIGGERS
-- =============================================

-- Trigger for content update versioning
CREATE OR REPLACE FUNCTION content_update_versioning()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.body <> OLD.body OR NEW.title <> OLD.title OR NEW.excerpt <> OLD.excerpt THEN
        INSERT INTO content_versions (
            content_id,
            version_number,
            title,
            body,
            excerpt,
            updated_by,
            change_reason
        )
        SELECT
            OLD.content_id,
            COALESCE((SELECT MAX(version_number) FROM content_versions WHERE content_id = OLD.content_id), 0) + 1,
            OLD.title,
            OLD.body,
            OLD.excerpt,
            OLD.updated_by,
            'Automatic version before update'
        WHERE
            OLD.status = 'published'; -- Only version published content
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER content_update_versioning_trigger
BEFORE UPDATE ON content
FOR EACH ROW
EXECUTE FUNCTION content_update_versioning();

-- Trigger for updating content search vectors (for full-text search)
CREATE OR REPLACE FUNCTION content_search_vector_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- In a real implementation, we'd update a tsvector column for search
    -- This is a placeholder to show where search functionality would integrate
    RETURN NEW;
END;
$$;

CREATE TRIGGER content_search_vector_trigger
BEFORE INSERT OR UPDATE ON content
FOR EACH ROW
EXECUTE FUNCTION content_search_vector_update();

-- Trigger for updating analytics on content view
CREATE OR REPLACE FUNCTION content_view_analytics()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update daily analytics record
    INSERT INTO content_analytics (
        content_id,
        date,
        views,
        unique_visitors
    ) VALUES (
        NEW.content_id,
        CURRENT_DATE,
        1,
        1
    )
    ON CONFLICT (content_id, date)
    DO UPDATE SET
        views = content_analytics.views + 1,
        unique_visitors = content_analytics.unique_visitors +
            CASE WHEN NOT EXISTS (
                SELECT 1 FROM page_views
                WHERE content_id = NEW.content_id
                AND date_trunc('day', view_time) = CURRENT_DATE
                AND session_uuid = NEW.session_uuid
            ) THEN 1 ELSE 0 END;

    RETURN NEW;
END;
$$;

CREATE TRIGGER content_view_analytics_trigger
AFTER INSERT ON page_views
FOR EACH ROW
WHEN (NEW.content_id IS NOT NULL)
EXECUTE FUNCTION content_view_analytics();

-- Trigger for user reputation recalculation after significant events
CREATE OR REPLACE FUNCTION user_reputation_event_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Recalculate reputation after relevant events
    IF (TG_TABLE_NAME = 'content' AND NEW.status = 'published') OR
       (TG_TABLE_NAME = 'content_fact_checks' AND TG_OP = 'INSERT') OR
       (TG_TABLE_NAME = 'content_flags' AND TG_OP = 'INSERT') OR
       (TG_TABLE_NAME = 'user_follows' AND TG_OP = 'INSERT') THEN

        CALL calculate_user_reputation(
            CASE
                WHEN TG_TABLE_NAME = 'content' THEN NEW.author_id
                WHEN TG_TABLE_NAME = 'content_fact_checks' THEN NEW.fact_checker_id
                WHEN TG_TABLE_NAME = 'content_flags' THEN NEW.user_id
                WHEN TG_TABLE_NAME = 'user_follows' THEN NEW.followed_id
            END
        );
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER content_published_reputation_trigger
AFTER INSERT OR UPDATE ON content
FOR EACH ROW
WHEN (NEW.status = 'published')
EXECUTE FUNCTION user_reputation_event_handler();

CREATE TRIGGER fact_check_reputation_trigger
AFTER INSERT ON content_fact_checks
FOR EACH ROW
EXECUTE FUNCTION user_reputation_event_handler();

CREATE TRIGGER content_flag_reputation_trigger
AFTER INSERT ON content_flags
FOR EACH ROW
EXECUTE FUNCTION user_reputation_event_handler();

CREATE TRIGGER user_follow_reputation_trigger
AFTER INSERT ON user_follows
FOR EACH ROW
EXECUTE FUNCTION user_reputation_event_handler();

-- =============================================
-- SECTION 12: ENHANCEMENTS & UNIQUE FEATURES
-- =============================================

/*
 * Enhancement: Collaborative Investigation Framework
 * Tables to support collaborative investigative journalism with task assignment
 * and progress tracking.
 */
CREATE TABLE investigations (
    investigation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('planning', 'active', 'review', 'published', 'archived')),
    lead_investigator_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_publish_date TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    published_content_id UUID REFERENCES content(content_id),
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE investigations IS 'Tracks investigative journalism projects with multiple collaborators';

CREATE TABLE investigation_team (
    team_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investigation_id UUID NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    role VARCHAR(50) NOT NULL CHECK (role IN ('investigator', 'researcher', 'editor', 'fact_checker', 'photographer', 'data_analyst')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    invited_by UUID REFERENCES users(user_id),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (investigation_id, user_id, role)
);

COMMENT ON TABLE investigation_team IS 'Tracks team members assigned to investigations with specific roles';

CREATE TABLE investigation_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investigation_id UUID NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES users(user_id),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('todo', 'in_progress', 'review', 'completed', 'blocked')),
    priority VARCHAR(10) CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    estimated_hours NUMERIC(5,2)
);

COMMENT ON TABLE investigation_tasks IS 'Tracks tasks within investigative projects with assignments and deadlines';

CREATE TABLE investigation_resources (
    resource_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investigation_id UUID NOT NULL REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    resource_type VARCHAR(50) NOT NULL CHECK (resource_type IN ('document', 'interview', 'dataset', 'image', 'video', 'audio', 'link', 'other')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    url TEXT,
    attachment_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    added_by UUID NOT NULL REFERENCES users(user_id),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sensitivity_level VARCHAR(20) CHECK (sensitivity_level IN ('public', 'team', 'confidential'))
);

COMMENT ON TABLE investigation_resources IS 'Stores resources collected during investigations with verification status';

/*
 * Enhancement: Crowdsourced Verification
 * Tables to support crowdsourced verification of claims and evidence
 */
CREATE TABLE verification_claims (
    claim_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    investigation_id UUID REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    claim_text TEXT NOT NULL,
    context TEXT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('unverified', 'in_progress', 'verified_true', 'verified_false', 'unverifiable', 'disputed')),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE,
    closed_by UUID REFERENCES users(user_id),
    confidence_score NUMERIC(5,2)
);

COMMENT ON TABLE verification_claims IS 'Tracks specific claims that need verification, which can be from content or investigations';

CREATE TABLE claim_verification_evidence (
    evidence_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    claim_id UUID NOT NULL REFERENCES verification_claims(claim_id) ON DELETE CASCADE,
    evidence_type VARCHAR(50) NOT NULL CHECK (evidence_type IN ('document', 'expert', 'witness', 'data', 'media', 'other')),
    description TEXT NOT NULL,
    content TEXT,
    url TEXT,
    attachment_url TEXT,
    submitted_by UUID NOT NULL REFERENCES users(user_id),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT,
    weight NUMERIC(5,2) DEFAULT 1.0
);

COMMENT ON TABLE claim_verification_evidence IS 'Stores evidence submitted to verify or dispute claims with verification status';

CREATE TABLE claim_verification_votes (
    vote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    claim_id UUID NOT NULL REFERENCES verification_claims(claim_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    vote_type VARCHAR(20) NOT NULL CHECK (vote_type IN ('verify', 'dispute', 'neutral')),
    confidence_level INTEGER CHECK (confidence_level BETWEEN 1 AND 5),
    comments TEXT,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (claim_id, user_id)
);

COMMENT ON TABLE claim_verification_votes IS 'Tracks community votes on claim verification status with confidence levels';

/*
 * Enhancement: Token-based Incentivization System
 * Extended tables for sophisticated token rewards and incentives
 */
CREATE TABLE reward_campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    reward_per_action NUMERIC(20,8) NOT NULL,
    reward_cap NUMERIC(20,8),
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('content_publish', 'content_verify', 'fact_check', 'comment', 'share', 'moderation', 'engagement')),
    action_criteria JSONB,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reward_campaigns IS 'Defines campaigns that reward users with tokens for specific actions';

CREATE TABLE user_reward_balances (
    balance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    campaign_id UUID NOT NULL REFERENCES reward_campaigns(campaign_id),
    earned_amount NUMERIC(20,8) NOT NULL DEFAULT 0,
    claimed_amount NUMERIC(20,8) NOT NULL DEFAULT 0,
    last_earned_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (user_id, campaign_id)
);

COMMENT ON TABLE user_reward_balances IS 'Tracks user token balances per reward campaign';

CREATE TABLE reward_distribution_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('content_quality', 'engagement', 'verification', 'moderation', 'community_growth')),
    metric_name VARCHAR(100) NOT NULL,
    metric_min_value NUMERIC,
    metric_max_value NUMERIC,
    token_amount NUMERIC(20,8) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reward_distribution_rules IS 'Defines rules for automatic token distribution based on quality and engagement metrics';

/*
 * Enhancement: AI-assisted Journalism Tools
 * Tables to support AI-generated insights and assistance
 */
CREATE TABLE ai_analysis_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    investigation_id UUID REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    claim_id UUID REFERENCES verification_claims(claim_id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('fact_check', 'sentiment', 'bias', 'summary', 'evidence_search', 'source_verification')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    requested_by UUID NOT NULL REFERENCES users(user_id),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    results JSONB,
    confidence_score NUMERIC(5,2),
    model_name VARCHAR(100),
    model_version VARCHAR(50)
);

COMMENT ON TABLE ai_analysis_jobs IS 'Tracks AI analysis jobs for content, investigations, or claims with results storage';

CREATE TABLE ai_generated_insights (
    insight_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    investigation_id UUID REFERENCES investigations(investigation_id) ON DELETE CASCADE,
    claim_id UUID REFERENCES verification_claims(claim_id) ON DELETE CASCADE,
    insight_type VARCHAR(50) NOT NULL CHECK (insight_type IN ('fact_check', 'bias', 'summary', 'related_content', 'source_analysis')),
    insight_text TEXT NOT NULL,
    confidence_score NUMERIC(5,2),
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_by_job UUID REFERENCES ai_analysis_jobs(job_id),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT
);

COMMENT ON TABLE ai_generated_insights IS 'Stores AI-generated insights with verification status by human journalists';

/*
 * Enhancement: Decentralized Content Moderation
 * Tables for community-driven content moderation with blockchain backing
 */
CREATE TABLE moderation_proposals (
    proposal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    comment_id UUID REFERENCES content_comments(comment_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    proposal_type VARCHAR(50) NOT NULL CHECK (proposal_type IN ('remove', 'hide', 'label', 'verify', 'unverify')),
    proposal_reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('proposed', 'voting', 'executed', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    voting_start_at TIMESTAMP WITH TIME ZONE,
    voting_end_at TIMESTAMP WITH TIME ZONE,
    executed_at TIMESTAMP WITH TIME ZONE,
    executed_by UUID REFERENCES users(user_id),
    transaction_hash TEXT
);

COMMENT ON TABLE moderation_proposals IS 'Tracks community proposals for content moderation actions with voting';

CREATE TABLE moderation_votes (
    vote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id UUID NOT NULL REFERENCES moderation_proposals(proposal_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    vote_choice VARCHAR(10) NOT NULL CHECK (vote_choice IN ('for', 'against', 'abstain')),
    vote_weight NUMERIC(20,8) NOT NULL DEFAULT 1.0,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transaction_hash TEXT,
    UNIQUE (proposal_id, user_id)
);

COMMENT ON TABLE moderation_votes IS 'Records community votes on moderation proposals with token-weighted voting';

CREATE TABLE moderation_labels (
    label_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    label_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE moderation_labels IS 'Defines labels that can be applied to content through community moderation';

CREATE TABLE content_moderation_labels (
    content_label_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    label_id UUID NOT NULL REFERENCES moderation_labels(label_id),
    applied_by_proposal UUID REFERENCES moderation_proposals(proposal_id),
    applied_by_user UUID REFERENCES users(user_id),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_removed BOOLEAN DEFAULT FALSE,
    removed_at TIMESTAMP WITH TIME ZONE,
    removed_by UUID REFERENCES users(user_id),
    UNIQUE (content_id, label_id, is_removed)
);

COMMENT ON TABLE content_moderation_labels IS 'Tracks labels applied to content through community moderation processes';

/*
 * Enhancement: Data Journalism Support
 * Tables for data journalism with dataset management and visualization
 */
CREATE TABLE datasets (
    dataset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES users(user_id),
    is_public BOOLEAN DEFAULT FALSE,
    license VARCHAR(100),
    source_attribution TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    file_url TEXT,
    file_size BIGINT,
    file_type VARCHAR(50),
    rows_count INTEGER,
    columns_count INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE datasets IS 'Stores datasets uploaded for data journalism with verification status';

CREATE TABLE dataset_columns (
    column_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(dataset_id) ON DELETE CASCADE,
    column_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    description TEXT,
    is_index BOOLEAN DEFAULT FALSE,
    is_required BOOLEAN DEFAULT FALSE,
    position INTEGER NOT NULL,
    UNIQUE (dataset_id, column_name)
);

COMMENT ON TABLE dataset_columns IS 'Defines columns within datasets for data journalism';

CREATE TABLE dataset_records (
    record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(dataset_id) ON DELETE CASCADE,
    row_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dataset_records IS 'Stores individual records within datasets for data journalism';

CREATE TABLE data_visualizations (
    visualization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID REFERENCES datasets(dataset_id) ON DELETE CASCADE,
    content_id UUID REFERENCES content(content_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    visualization_type VARCHAR(50) NOT NULL CHECK (visualization_type IN ('chart', 'map', 'table', 'graph', 'timeline')),
    config JSONB NOT NULL,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_interactive BOOLEAN DEFAULT FALSE,
    embed_code TEXT
);

COMMENT ON TABLE data_visualizations IS 'Stores data visualizations created from datasets for use in content';

/*
 * Enhancement: Cryptographically Verifiable Content
 * Tables for cryptographic content verification and timestamping
 */
CREATE TABLE content_signatures (
    signature_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    signer_id UUID NOT NULL REFERENCES users(user_id),
    signature_type VARCHAR(50) NOT NULL CHECK (signature_type IN ('author', 'editor', 'witness', 'verifier')),
    signature TEXT NOT NULL,
    public_key TEXT NOT NULL,
    signing_algorithm VARCHAR(50) NOT NULL,
    signed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    blockchain_tx_hash TEXT,
    UNIQUE (content_id, signer_id, signature_type)
);

COMMENT ON TABLE content_signatures IS 'Stores cryptographic signatures for content verification by authors and editors';

CREATE TABLE content_timestamps (
    timestamp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    timestamp_type VARCHAR(50) NOT NULL CHECK (timestamp_type IN ('creation', 'publication', 'modification', 'verification')),
    blockchain_name VARCHAR(50) NOT NULL,
    transaction_hash TEXT NOT NULL,
    block_number BIGINT,
    block_time TIMESTAMP WITH TIME ZONE,
    timestamped_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, timestamp_type)
);

COMMENT ON TABLE content_timestamps IS 'Records blockchain timestamps for key content events to prove existence at points in time';

/*
 * Enhancement: Location-based Journalism
 * Tables for geospatial journalism and event mapping
 */
CREATE TABLE geo_locations (
    location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    region VARCHAR(100),
    country_code VARCHAR(2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE geo_locations IS 'Stores named geographic locations for mapping and geospatial journalism';

CREATE TABLE geo_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('incident', 'protest', 'press_conference', 'hearing', 'natural_disaster', 'other')),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    location_id UUID REFERENCES geo_locations(location_id),
    custom_location GEOGRAPHY(POINT, 4326),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    content_id UUID REFERENCES content(content_id) ON DELETE SET NULL
);

COMMENT ON TABLE geo_events IS 'Tracks real-world events with geospatial data for mapping and verification';

CREATE TABLE event_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES geo_events(event_id) ON DELETE CASCADE,
    attachment_type VARCHAR(50) NOT NULL CHECK (attachment_type IN ('image', 'video', 'audio', 'document', 'link')),
    url TEXT NOT NULL,
    caption TEXT,
    uploaded_by UUID NOT NULL REFERENCES users(user_id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE event_attachments IS 'Stores media attachments for geo-events with verification status';

/*
 * Enhancement: Media Asset Management
 * Advanced media handling with provenance tracking
 */
CREATE TABLE media_assets (
    asset_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    asset_type VARCHAR(50) NOT NULL CHECK (asset_type IN ('image', 'video', 'audio', 'document')),
    mime_type VARCHAR(100) NOT NULL,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_size BIGINT NOT NULL,
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- in seconds
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    captured_at TIMESTAMP WITH TIME ZONE,
    captured_by VARCHAR(255),
    captured_location GEOGRAPHY(POINT, 4326),
    copyright_info TEXT,
    license_type VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(user_id),
    verified_at TIMESTAMP WITH TIME ZONE,
    provenance_chain JSONB -- Tracks origin and modifications of the asset
);

COMMENT ON TABLE media_assets IS 'Central repository for media assets with detailed provenance and verification data';

CREATE TABLE media_asset_versions (
    version_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES media_assets(asset_id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    file_url TEXT NOT NULL,
    modification_description TEXT,
    modified_by UUID NOT NULL REFERENCES users(user_id),
    modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (asset_id, version_number)
);

COMMENT ON TABLE media_asset_versions IS 'Tracks different versions of media assets with modification history';

CREATE TABLE media_asset_verification (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES media_assets(asset_id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN ('metadata', 'forensic', 'provenance', 'source')),
    verification_method VARCHAR(100) NOT NULL,
    result VARCHAR(20) NOT NULL CHECK (result IN ('authentic', 'modified', 'fabricated', 'inconclusive')),
    confidence_level INTEGER CHECK (confidence_level BETWEEN 1 AND 5),
    performed_by UUID NOT NULL REFERENCES users(user_id),
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tools_used TEXT[],
    report TEXT
);

COMMENT ON TABLE media_asset_verification IS 'Records detailed verification processes applied to media assets';

-- =============================================
-- SECTION 13: FINAL SETUP
-- =============================================

-- Create indexes for performance
CREATE INDEX idx_content_author ON content(author_id);
CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_content_published ON content(published_at) WHERE status = 'published';
CREATE INDEX idx_content_verified ON content(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_content_type ON content(content_type_id);
CREATE INDEX idx_content_slug ON content(slug);
CREATE INDEX idx_content_tags_tag ON content_tags(tag_id);
CREATE INDEX idx_content_categories_category ON content_categories(category_id);
CREATE INDEX idx_content_flags_content ON content_flags(content_id);
CREATE INDEX idx_content_flags_status ON content_flags(status);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_user_follows_followed ON user_follows(followed_id);
CREATE INDEX idx_content_reactions_content ON content_reactions(content_id);
CREATE INDEX idx_content_reactions_user ON content_reactions(user_id);
CREATE INDEX idx_content_analytics_content ON content_analytics(content_id);
CREATE INDEX idx_content_analytics_date ON content_analytics(date);
CREATE INDEX idx_activity_pub_activities_actor ON activity_pub_activities(actor_id);
CREATE INDEX idx_activity_pub_activities_processed ON activity_pub_activities(processed);
CREATE INDEX idx_visitor_sessions_user ON visitor_sessions(user_id);
CREATE INDEX idx_visitor_sessions_first_visit ON visitor_sessions(first_visit_at);
CREATE INDEX idx_page_views_session ON page_views(session_uuid);
CREATE INDEX idx_page_views_content ON page_views(content_id);
CREATE INDEX idx_user_engagement_user ON user_engagement(user_id);
CREATE INDEX idx_user_engagement_date ON user_engagement(date);
CREATE INDEX idx_investigation_team_investigation ON investigation_team(investigation_id);
CREATE INDEX idx_investigation_team_user ON investigation_team(user_id);
CREATE INDEX idx_investigation_tasks_investigation ON investigation_tasks(investigation_id);
CREATE INDEX idx_investigation_tasks_assigned ON investigation_tasks(assigned_to);
CREATE INDEX idx_verification_claims_content ON verification_claims(content_id);
CREATE INDEX idx_verification_claims_status ON verification_claims(status);
CREATE INDEX idx_claim_verification_evidence_claim ON claim_verification_evidence(claim_id);
CREATE INDEX idx_moderation_proposals_content ON moderation_proposals(content_id);
CREATE INDEX idx_moderation_proposals_status ON moderation_proposals(status);
CREATE INDEX idx_moderation_votes_proposal ON moderation_votes(proposal_id);
CREATE INDEX idx_geo_events_location ON geo_events(location_id);
CREATE INDEX idx_geo_events_time ON geo_events(start_time, end_time);
CREATE INDEX idx_geo_events_verified ON geo_events(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_media_assets_verified ON media_assets(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_media_assets_type ON media_assets(asset_type);

-- Create full-text search indexes (implementation would vary based on search solution)
-- CREATE INDEX idx_content_search ON content USING gin(to_tsvector('english', title || ' ' || body));
-- CREATE INDEX idx_content_metadata_search ON content_metadata USING gin(to_tsvector('english', meta_value));

-- Create spatial indexes for geographic data
CREATE INDEX idx_content_location ON content USING GIST(location);
CREATE INDEX idx_geo_locations_location ON geo_locations USING GIST(location);
CREATE INDEX idx_geo_events_location_geo ON geo_events USING GIST(custom_location);
CREATE INDEX idx_media_assets_location ON media_assets USING GIST(captured_location);

-- Create unique indexes for constraints
CREATE UNIQUE INDEX idx_user_email ON users(email) WHERE is_deleted = FALSE;
CREATE UNIQUE INDEX idx_user_username ON users(username) WHERE is_deleted = FALSE;
CREATE UNIQUE INDEX idx_category_slug ON categories(slug);
CREATE UNIQUE INDEX idx_tag_slug ON tags(slug);
CREATE UNIQUE INDEX idx_content_slug_published ON content(slug, published_at) WHERE published_at IS NOT NULL;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers to tables with updated_at columns
DO $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
        AND table_schema = 'public'
        AND table_name NOT IN ('data_profiling', 'system_health_metrics') -- Exclude tables that are auto-updated
    LOOP
        EXECUTE format('CREATE TRIGGER update_%s_timestamp
                       BEFORE UPDATE ON %I
                       FOR EACH ROW EXECUTE FUNCTION update_timestamp()',
                       t.table_name, t.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create function to maintain history of important changes
CREATE OR REPLACE FUNCTION log_important_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- In a real implementation, we'd log specific changes to an audit table
    -- This is a placeholder to show where comprehensive auditing would be implemented
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to important tables
DO $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name IN ('users', 'content', 'content_metadata', 'user_roles', 'moderation_actions')
    LOOP
        EXECUTE format('CREATE TRIGGER audit_%s_changes
                       AFTER INSERT OR UPDATE OR DELETE ON %I
                       FOR EACH ROW EXECUTE FUNCTION log_important_changes()',
                       t.table_name, t.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create function to generate slugs
CREATE OR REPLACE FUNCTION generate_slug(p_text TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Convert to lowercase
    p_text := LOWER(p_text);

    -- Replace spaces with dashes
    p_text := REGEXP_REPLACE(p_text, '\s+', '-', 'g');

    -- Remove all non-alphanumeric characters except dashes
    p_text := REGEXP_REPLACE(p_text, '[^a-z0-9-]', '', 'g');

    -- Remove multiple consecutive dashes
    p_text := REGEXP_REPLACE(p_text, '-+', '-', 'g');

    -- Trim dashes from start and end
    p_text := TRIM(BOTH '-' FROM p_text);

    RETURN p_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_slug IS 'Generates URL-friendly slugs from text by converting to lowercase, replacing spaces with dashes, and removing special characters';

-- Create function to encrypt data
CREATE OR REPLACE FUNCTION encrypt_data(p_data TEXT, p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_encrypt(p_data, p_key);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION encrypt_data IS 'Encrypts data using PGP symmetric encryption with the provided key';

-- Create function to decrypt data
CREATE OR REPLACE FUNCTION decrypt_data(p_data TEXT, p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(p_data::bytea, p_key);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION decrypt_data IS 'Decrypts data using PGP symmetric encryption with the provided key';

-- Initialize data dictionary
INSERT INTO data_dictionary (table_name, column_name, data_type, description, business_definition, sensitivity_level, pii_flag, gdpr_category)
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    COALESCE(pd.description, 'No description available'),
    COALESCE(pd.business_definition, 'No business definition available'),
    CASE
        WHEN c.column_name IN ('email', 'password_hash', 'private_key') THEN 'restricted'
        WHEN c.column_name LIKE '%name%' OR c.column_name LIKE '%email%' THEN 'confidential'
        WHEN c.column_name LIKE '%ip_address%' OR c.column_name LIKE '%user_agent%' THEN 'internal'
        ELSE 'public'
    END,
    CASE
        WHEN c.column_name IN ('email', 'ip_address') THEN TRUE
        ELSE FALSE
    END,
    CASE
        WHEN c.column_name = 'email' THEN 'contact_data'
        WHEN c.column_name LIKE '%ip_address%' THEN 'technical_data'
        WHEN c.column_name LIKE '%name%' THEN 'identity_data'
        ELSE NULL
    END
FROM
    information_schema.tables t
JOIN
    information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN
    (VALUES
        ('users', 'email', 'User email address', 'Primary contact and identification email for the user'),
        ('users', 'password_hash', 'Hashed password', 'Securely hashed user password for authentication'),
        ('content', 'body', 'Content body text', 'Main textual content of the journalism piece'),
        ('content', 'status', 'Content status', 'Workflow status of the content (draft, published, etc.)')
    ) AS pd(table_name, column_name, description, business_definition)
    ON t.table_name = pd.table_name AND c.column_name = pd.column_name
WHERE
    t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
ON CONFLICT (table_name, column_name) DO UPDATE SET
    description = EXCLUDED.description,
    business_definition = EXCLUDED.business_definition,
    sensitivity_level = EXCLUDED.sensitivity_level,
    pii_flag = EXCLUDED.pii_flag,
    gdpr_category = EXCLUDED.gdpr_category;

-- Initialize data lineage
INSERT INTO data_lineage (source_table, source_column, target_table, target_column, transformation_description)
VALUES
('users', 'user_id', 'content', 'author_id', 'Direct copy of user ID to content author ID'),
('content_types', 'content_type_id', 'content', 'content_type_id', 'Direct copy of content type ID'),
('content', 'content_id', 'content_versions', 'content_id', 'Direct copy when creating new versions'),
('content', 'content_id', 'content_media', 'content_id', 'Direct copy when attaching media to content'),
('users', 'user_id', 'content_reactions', 'user_id', 'Direct copy when user reacts to content');

-- Initialize data quality rules
INSERT INTO data_quality_rules (table_name, column_name, rule_name, rule_description, rule_type, rule_expression, severity)
VALUES
('users', 'email', 'valid_email_format', 'Email must be in valid format', 'validity', 'email ~* ''^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$''', 'critical'),
('content', 'slug', 'unique_slug_per_publish_date', 'Slug must be unique per publish date', 'uniqueness', 'COUNT(*) = 1 WHEN published_at IS NOT NULL', 'high'),
('content', 'status', 'valid_status_value', 'Status must be one of allowed values', 'validity', 'status IN (''draft'', ''pending_review'', ''published'', ''rejected'', ''archived'')', 'high'),
('user_roles', 'user_id', 'user_exists', 'User ID must exist in users table', 'consistency', 'user_id IN (SELECT user_id FROM users)', 'critical'),
('user_roles', 'role_id', 'role_exists', 'Role ID must exist in roles table', 'consistency', 'role_id IN (SELECT role_id FROM roles)', 'critical');

-- Initialize data retention policies
INSERT INTO data_retention_policies (table_name, retention_period, retention_criteria, archival_strategy, disposal_method, gdpr_compliance_notes)
VALUES
('visitor_sessions', '1 year', 'All sessions', 'Aggregate statistics kept indefinitely', 'Anonymize then delete', 'IP addresses anonymized after 30 days'),
('user_activity', '6 months', 'All activity', 'None', 'Delete', 'User can request export before deletion'),
('content_flags', '2 years', 'Resolved flags', 'Keep metadata about flag types and counts', 'Anonymize then delete', 'Personal data removed after resolution'),
('system_events', '5 years', 'All events', 'Compress and archive', 'Delete', 'Security events kept for auditing'),
('data_access_logs', '1 year', 'All logs', 'None', 'Delete', 'Anonymized after 30 days');

-- Initialize platform KPIs
INSERT INTO platform_kpis (kpi_name, kpi_description, measurement_unit, target_value, is_higher_better, category, reporting_frequency, owner)
VALUES
('Daily Active Users', 'Number of unique active users per day', 'users', 10000, TRUE, 'engagement', 'daily', 'Growth Team'),
('Content Production Rate', 'Number of new content pieces published per day', 'content', 50, TRUE, 'content', 'daily', 'Editorial Team'),
('User Retention', 'Percentage of users returning after 30 days', 'percentage', 40, TRUE, 'engagement', 'monthly', 'Growth Team'),
('Content Verification Rate', 'Percentage of content that passes verification', 'percentage', 85, TRUE, 'quality', 'weekly', 'Moderation Team'),
('Average Session Duration', 'Average time spent per user session', 'seconds', 180, TRUE, 'engagement', 'daily', 'Product Team'),
('Flag Resolution Time', 'Average time to resolve content flags', 'hours', 24, FALSE, 'moderation', 'weekly', 'Moderation Team'),
('Federated Content Share', 'Percentage of content from federated sources', 'percentage', 20, TRUE, 'federation', 'monthly', 'Community Team');

-- Initialize system settings
INSERT INTO system_settings (setting_key, setting_value, setting_group, data_type, is_public, description)
VALUES
('federation.enabled', 'true', 'federation', 'boolean', TRUE, 'Enable ActivityPub federation with other instances'),
('user.registration.open', 'true', 'authentication', 'boolean', TRUE, 'Allow new user registrations'),
('content.verification.required', 'false', 'content', 'boolean', TRUE, 'Require verification before publishing'),
('ui.default_theme', 'light', 'appearance', 'string', TRUE, 'Default color theme for the interface'),
('email.notifications.enabled', 'true', 'notifications', 'boolean', TRUE, 'Enable email notifications'),
('analytics.tracking.enabled', 'true', 'analytics', 'boolean', FALSE, 'Enable visitor analytics tracking'),
('token.rewards.enabled', 'true', 'economy', 'boolean', TRUE, 'Enable token reward system'),
('instance.name', 'Decentralized Journalism Network', 'instance', 'string', TRUE, 'Public name of this instance'),
('instance.domain', 'journalism.example', 'instance', 'string', TRUE, 'Primary domain of this instance'),
('moderation.queue.threshold', '3', 'moderation', 'number', FALSE, 'Number of flags needed to enter moderation queue');

-- check allowed values for the asset_type column
SELECT pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname = 'data_catalog_asset_type_check';



-- content moderation queue view
CREATE OR REPLACE VIEW content_moderation_queue_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.status,
    c.published_at,
    c.is_breaking,
    c.verification_score,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    COALESCE(ur.reputation_score, 0) AS author_reputation,
    (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS pending_flags,
    (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') AS dispute_votes,
    (SELECT STRING_AGG(cf.flag_type, ', ' ORDER BY cf.flag_type)
        FROM content_flags cf
        WHERE cf.content_id = c.content_id AND cf.status = 'pending') AS flag_types,
    -- Moderation priority score calculation
    (
        (SELECT COUNT(*) FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending') * 10 +
        (SELECT COUNT(*) FROM content_verification_votes cvv WHERE cvv.content_id = c.content_id AND cvv.vote_type = 'dispute') * 5 +
        CASE WHEN c.is_breaking THEN 20 ELSE 0 END +
        CASE WHEN c.verification_score < 50 THEN 15 ELSE 0 END +
        CASE WHEN COALESCE(ur.reputation_score, 0) < 50 THEN 10 ELSE 0 END
    ) AS priority_score,
    (SELECT STRING_AGG(t.name, ', ' ORDER BY t.name)
        FROM content_tags ct
        JOIN tags t ON ct.tag_id = t.tag_id
        WHERE ct.content_id = c.content_id) AS tags
FROM
    content c
JOIN
    users u ON c.author_id = u.user_id
LEFT JOIN
    user_reputation ur ON u.user_id = ur.user_id
WHERE
    (c.status = 'pending_review' OR
     EXISTS (SELECT 1 FROM content_flags cf WHERE cf.content_id = c.content_id AND cf.status = 'pending'))
ORDER BY
    priority_score DESC;

COMMENT ON VIEW content_moderation_queue_view IS 'Shows content needing moderation with priority scoring for efficient review workflow';

-- First modify the constraint to allow 'procedure' type
ALTER TABLE data_catalog
DROP CONSTRAINT IF EXISTS data_catalog_asset_type_check;

ALTER TABLE data_catalog
ADD CONSTRAINT data_catalog_asset_type_check
CHECK (asset_type IN ('table', 'view', 'function', 'procedure', 'trigger', 'sequence'));



-- check the allowed values for sensitivity_level (if needed)
SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'data_catalog_sensitivity_level_check';

-- Then insert with original values
INSERT INTO data_catalog (
    asset_name,
    asset_type,
    description,
    owner,
    domain,
    sensitivity_level,
    pii_flag,
    gdpr_relevant
) VALUES
('users', 'table', 'User account information', 'Platform Team', 'user_management', 'confidential', TRUE, TRUE),
('content', 'table', 'Journalism content pieces', 'Editorial Team', 'content_management', 'public', FALSE, FALSE),
('content_analytics', 'table', 'Content engagement metrics', 'Analytics Team', 'business_intelligence', 'internal', FALSE, FALSE),
('published_content_view', 'view', 'View of published content with metrics', 'Editorial Team', 'content_management', 'public', FALSE, FALSE),
('user_engagement_metrics_view', 'view', 'Aggregated user engagement metrics', 'Growth Team', 'business_intelligence', 'internal', FALSE, TRUE),
('platform_kpi_dashboard_view', 'dashboard', 'Aggregated platform KPIs for dashboards', 'Executive Team', 'business_intelligence', 'internal', FALSE, FALSE),
('content_api', 'api', 'Content delivery API endpoint', 'Engineering Team', 'content_delivery', 'public', FALSE, FALSE),
('process_activity_pub_inbox', 'dataset', 'Processes incoming federated activities', 'Federation Team', 'federation', 'internal', FALSE, FALSE);



-- Initialize some sample badges
INSERT INTO badges (name, description, image_url, is_active)
VALUES
('Verified Journalist', 'Awarded to journalists who have verified their identity and credentials', '/badges/verified.png', TRUE),
('Fact Checker', 'Awarded to users who have contributed high-quality fact checks', '/badges/fact-checker.png', TRUE),
('Community Moderator', 'Awarded to trusted community moderators', '/badges/moderator.png', TRUE),
('Early Adopter', 'Awarded to users who joined in the first year', '/badges/early-adopter.png', TRUE),
('Top Contributor', 'Awarded to users in the top 10% of content contributors', '/badges/top-contributor.png', TRUE);

-- Initialize some sample permissions
INSERT INTO permissions (permission_name, description, resource_type, action)
VALUES
('create_content', 'Create new content', 'content', 'create'),
('edit_content', 'Edit existing content', 'content', 'update'),
('publish_content', 'Publish content', 'content', 'publish'),
('delete_content', 'Delete content', 'content', 'delete'),
('moderate_content', 'Moderate content', 'content', 'moderate'),
('view_analytics', 'View platform analytics', 'analytics', 'read'),
('manage_users', 'Manage user accounts', 'users', 'manage'),
('manage_system', 'Manage system settings', 'system', 'manage'),
('federate_content', 'Federate content to other instances', 'content', 'federate');

-- Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id, assigned_by)
SELECT r.role_id, p.permission_id, (SELECT user_id FROM users WHERE username = 'admin' LIMIT 1)
FROM roles r
CROSS JOIN permissions p
WHERE
    (r.role_name = 'admin' AND p.permission_name IN ('create_content', 'edit_content', 'publish_content', 'delete_content', 'moderate_content', 'view_analytics', 'manage_users', 'manage_system', 'federate_content')) OR
    (r.role_name = 'editor' AND p.permission_name IN ('create_content', 'edit_content', 'publish_content', 'moderate_content', 'federate_content')) OR
    (r.role_name = 'reporter' AND p.permission_name IN ('create_content', 'edit_content')) OR
    (r.role_name = 'moderator' AND p.permission_name IN ('moderate_content')) OR
    (r.role_name = 'fact_checker' AND p.permission_name IN ('moderate_content'));

-- Create initial admin user if not exists
INSERT INTO users (user_id, username, email, email_verified, password_hash, salt, display_name, is_active, gdpr_compliant)
VALUES
('11111111-1111-1111-1111-111111111111', 'admin', 'admin@example.com', TRUE,
 'bd2b1aaf7ef4f09be9f52ce2d8d599674d81aa9d6a4421696dc4d93dd0619d68', -- hash of 'admin123'
 'random_salt',
 'System Admin', TRUE, TRUE)
ON CONFLICT (username) DO NOTHING;

-- Assign admin role to admin user
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT '11111111-1111-1111-1111-111111111111', role_id, '11111111-1111-1111-1111-111111111111'
FROM roles WHERE role_name = 'admin'
ON CONFLICT (user_id, role_id) DO NOTHING;

-- Initialize data profiling (example for users table)
INSERT INTO data_profiling (
    table_name,
    column_name,
    profile_date,
    row_count,
    null_count,
    distinct_count,
    min_value,
    max_value,
    avg_value,
    median_value,
    data_type,
    sample_values,
    pattern_analysis,
    value_distribution
)
VALUES
('users', 'username', NOW(),
 (SELECT COUNT(*) FROM users),
 (SELECT COUNT(*) FROM users WHERE username IS NULL),
 (SELECT COUNT(DISTINCT username) FROM users),
 (SELECT MIN(username) FROM users),
 (SELECT MAX(username) FROM users),
 NULL, NULL,
 'character varying',
 ARRAY(SELECT username FROM users LIMIT 5),
 jsonb_build_object('pattern', '^[a-z0-9_]+$', 'min_length', 3, 'max_length', 50),
 jsonb_build_object('length_distribution', jsonb_build_object(
     '1-10', (SELECT COUNT(*) FROM users WHERE LENGTH(username) BETWEEN 1 AND 10),
     '11-20', (SELECT COUNT(*) FROM users WHERE LENGTH(username) BETWEEN 11 AND 20),
     '21-30', (SELECT COUNT(*) FROM users WHERE LENGTH(username) BETWEEN 21 AND 30),
     '31+', (SELECT COUNT(*) FROM users WHERE LENGTH(username) > 30)
 )));

-- Log schema creation completion
INSERT INTO system_events (event_type, event_data)
VALUES (
    'schema_created',
    jsonb_build_object(
        'version', '1.0',
        'tables', (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'),
        'views', (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public'),
        'functions', (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public')
    )
);


-- -------------------------------------------
-- 9.1 Community-Based Content Moderation System
-- -------------------------------------------

-- New table for moderation disputes
CREATE TABLE moderation_disputes (
    dispute_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id UUID REFERENCES moderation_proposals(proposal_id) ON DELETE CASCADE, -- The proposal being disputed
    action_id UUID REFERENCES moderation_actions(action_id) ON DELETE CASCADE, -- The action being disputed
    user_id UUID NOT NULL REFERENCES users(user_id), -- User initiating the dispute
    dispute_reason TEXT NOT NULL, -- Reason for the dispute
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved_upheld', 'resolved_overturned', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_by UUID REFERENCES users(user_id), -- Moderator or admin who reviewed the dispute
    reviewed_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT, -- Notes on how the dispute was resolved
    UNIQUE (proposal_id, user_id), -- A user can dispute a proposal only once
    UNIQUE (action_id, user_id) -- A user can dispute an action only once
);

COMMENT ON TABLE moderation_disputes IS 'Tracks user disputes against moderation proposals or actions.';

-- New table for comprehensive moderation audit log
CREATE TABLE moderation_audit_log (
    audit_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'content_flagged', 'comment_flagged', 'user_flagged',
        'moderation_proposal_created', 'moderation_vote_cast', 'moderation_proposal_executed', 'moderation_proposal_rejected',
        'content_removed', 'content_hidden', 'comment_removed', 'user_warned', 'user_suspended', 'user_banned',
        'moderation_dispute_created', 'moderation_dispute_resolved',
        'label_applied', 'label_removed', 'trust_score_recalculated'
    )),
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actor_id UUID REFERENCES users(user_id), -- User or system performing the action
    target_content_id UUID REFERENCES content(content_id),
    target_comment_id UUID REFERENCES content_comments(comment_id),
    target_user_id UUID REFERENCES users(user_id),
    target_proposal_id UUID REFERENCES moderation_proposals(proposal_id),
    target_action_id UUID REFERENCES moderation_actions(action_id),
    details JSONB, -- JSONB field for storing event-specific details (e.g., flag reason, vote weight, ban duration)
    ip_address INET, -- IP address of the actor, if applicable
    user_agent TEXT -- User agent of the actor, if applicable
);

COMMENT ON TABLE moderation_audit_log IS 'Comprehensive, immutable log of all moderation-related events for auditing and transparency.';

-- -------------------------------------------
--  Monetization Strategies and Rewards Systems
-- -------------------------------------------

-- New tables for premium content access
CREATE TABLE premium_content_access (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    access_type VARCHAR(20) NOT NULL CHECK (access_type IN (
        'subscription_only', 'pay_per_view', 'tiered_access'
    )),
    price_amount NUMERIC(10,2), -- For pay-per-view
    price_currency VARCHAR(3) DEFAULT 'USD',
    required_plan_id UUID REFERENCES subscription_plans(plan_id), -- For subscription_only or tiered_access
    required_access_level INTEGER, -- For tiered_access
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE premium_content_access IS 'Manages access rules and pricing for premium content.';

CREATE TABLE user_content_purchases (
    purchase_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    amount_paid NUMERIC(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    transaction_id UUID REFERENCES token_transactions(transaction_id), -- Link to token transaction if applicable
    access_expires_at TIMESTAMP WITH TIME ZONE, -- For time-limited access
    UNIQUE (user_id, content_id) -- A user can only purchase access to a content once
);

COMMENT ON TABLE user_content_purchases IS 'Records individual user purchases of premium content.';

-- New table for creator payouts
CREATE TABLE creator_payouts (
    payout_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id), -- Creator receiving payout
    payout_amount NUMERIC(20,8) NOT NULL,
    payout_currency VARCHAR(10) NOT NULL, -- e.g., 'USD', 'platform_token'
    payout_method VARCHAR(50) NOT NULL, -- e.g., 'crypto_wallet', 'bank_transfer', 'paypal'
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'canceled'
    )),
    request_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_date TIMESTAMP WITH TIME ZONE,
    transaction_reference TEXT, -- e.g., blockchain transaction hash, bank transfer ID
    notes TEXT,
    related_revenue_share JSONB -- Details on how the payout was calculated (e.g., ad revenue share, tips)
);

COMMENT ON TABLE creator_payouts IS 'Manages payouts to content creators from various revenue streams.';

-- New tables for bounties
CREATE TABLE bounties (
    bounty_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    reward_amount NUMERIC(20,8) NOT NULL,
    reward_currency VARCHAR(10) NOT NULL DEFAULT 'platform_token',
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'open', 'in_progress', 'under_review', 'completed', 'canceled'
    )),
    created_by UUID NOT NULL REFERENCES users(user_id), -- User or system creating the bounty
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    assigned_to UUID REFERENCES users(user_id), -- User who claimed the bounty
    completed_by UUID REFERENCES users(user_id), -- User who completed the bounty
    completed_at TIMESTAMP WITH TIME ZONE,
    verification_criteria TEXT, -- How the bounty completion will be verified
    related_content_id UUID REFERENCES content(content_id), -- If bounty is related to specific content
    related_claim_id UUID REFERENCES verification_claims(claim_id) -- If bounty is related to a specific claim
);

COMMENT ON TABLE bounties IS 'Defines tasks with associated rewards for specific contributions.';

CREATE TABLE bounty_submissions (
    submission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bounty_id UUID NOT NULL REFERENCES bounties(bounty_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id), -- User submitting work for the bounty
    submission_details TEXT NOT NULL, -- Description of the submitted work
    submission_url TEXT, -- Link to the work (e.g., content ID, external link)
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'pending_review', 'approved', 'rejected'
    )),
    reviewed_by UUID REFERENCES users(user_id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    reward_transaction_id UUID REFERENCES token_transactions(transaction_id) -- Link to the reward transaction
);

COMMENT ON TABLE bounty_submissions IS 'Tracks submissions for bounties and their review status.';



-- -- Create badges table first if it doesn't exist
-- CREATE TABLE IF NOT EXISTS badges (
--     badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     name VARCHAR(100) NOT NULL UNIQUE,
--     description TEXT NOT NULL,
--     image_url VARCHAR(255),
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- Then create gamification_achievements table
CREATE TABLE gamification_achievements (
    achievement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    criteria JSONB NOT NULL, -- JSONB for flexible criteria (e.g., {"action": "create_content", "count": 10})
    reward_points INTEGER, -- Points awarded for this achievement
    reward_badge_id UUID REFERENCES badges(badge_id), -- Badge awarded for this achievement
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE gamification_achievements IS 'Defines achievements that users can unlock through various activities.';



-- CREATE TABLE user_achievements (
--     user_achievement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     user_id UUID NOT NULL REFERENCES users(user_id),
--     achievement_id UUID NOT NULL REFERENCES gamification_achievements(achievement_id),
--     unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE (user_id, achievement_id)
-- );

-- COMMENT ON TABLE user_achievements IS 'Tracks which achievements have been unlocked by each user.';



-- New tables for user groups/communities
CREATE TABLE user_groups (
    group_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    profile_image_url TEXT,
    banner_image_url TEXT,
    is_public BOOLEAN DEFAULT TRUE, -- Publicly visible vs. private
    is_open BOOLEAN DEFAULT TRUE, -- Open to join vs. invite-only
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_groups IS 'Defines user-created groups or communities for focused discussions.';


CREATE TABLE group_members (
    member_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES user_groups(group_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    role VARCHAR(20) NOT NULL CHECK (role IN ('member', 'moderator', 'admin')) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_banned BOOLEAN DEFAULT FALSE,
    banned_at TIMESTAMP WITH TIME ZONE,
    banned_by UUID REFERENCES users(user_id),
    UNIQUE (group_id, user_id)
);



CREATE TABLE group_content (
    group_content_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES user_groups(group_id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    added_by UUID NOT NULL REFERENCES users(user_id),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_pinned BOOLEAN DEFAULT FALSE,
    UNIQUE (group_id, content_id)
);

COMMENT ON TABLE group_content IS 'Associates content with specific user groups.';

-- New table for direct messaging
CREATE TABLE direct_messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(user_id),
    recipient_id UUID NOT NULL REFERENCES users(user_id),
    body TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    is_deleted_by_sender BOOLEAN DEFAULT FALSE,
    is_deleted_by_recipient BOOLEAN DEFAULT FALSE,
    encrypted_body TEXT -- For E2E encrypted messages
);

COMMENT ON TABLE direct_messages IS 'Stores one-to-one direct messages between users.';

-- New tables for events
CREATE TABLE events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    location_text VARCHAR(255),
    location_geo GEOGRAPHY(POINT, 4326),
    is_online BOOLEAN DEFAULT FALSE,
    online_url TEXT,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    group_id UUID REFERENCES user_groups(group_id) -- Optional link to a group
);

COMMENT ON TABLE events IS 'Defines community events, both online and offline.';

CREATE TABLE event_rsvps (
    rsvp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('attending', 'interested', 'not_attending')),
    rsvped_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, user_id)
);

COMMENT ON TABLE event_rsvps IS 'Tracks user RSVPs for events.';

-- New tables for polls
CREATE TABLE polls (
    poll_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closes_at TIMESTAMP WITH TIME ZONE,
    is_anonymous BOOLEAN DEFAULT FALSE,
    allow_multiple_choices BOOLEAN DEFAULT FALSE,
    related_content_id UUID REFERENCES content(content_id) -- Optional link to content
);

COMMENT ON TABLE polls IS 'Defines polls that can be attached to content or stand alone.';

CREATE TABLE poll_options (
    option_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(poll_id) ON DELETE CASCADE,
    option_text VARCHAR(255) NOT NULL,
    position INTEGER DEFAULT 0
);

COMMENT ON TABLE poll_options IS 'Stores the individual options for a poll.';

CREATE TABLE poll_votes (
    vote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(poll_id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES poll_options(option_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (poll_id, user_id, option_id) -- Ensures a user votes for an option only once
);

COMMENT ON TABLE poll_votes IS 'Records user votes on poll options.';

-- -------------------------------------------
--Code and Schema Improvements
-- -------------------------------------------

-- New table for content scheduling
CREATE TABLE content_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    publish_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'published', 'canceled')) DEFAULT 'scheduled',
    scheduled_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id)
);

COMMENT ON TABLE content_schedules IS 'Manages scheduled publishing of content.';

-- New table for content drafts
CREATE TABLE content_drafts (
    draft_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content(content_id), -- Can be NULL for new content
    user_id UUID NOT NULL REFERENCES users(user_id),
    title VARCHAR(255),
    body TEXT,
    excerpt TEXT,
    metadata JSONB, -- Store other content fields like categories, tags, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_autosave BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE content_drafts IS 'Stores user-saved drafts and auto-saves of content.';

-----------------------
--- other enhancements
-----------------------

-- Add columns to `content` for enhanced moderation and discovery
ALTER TABLE content
    ADD COLUMN moderation_status VARCHAR(20) NOT NULL DEFAULT 'none' CHECK (moderation_status IN ('none', 'under_review', 'action_taken', 'escalated')),
    ADD COLUMN moderation_notes TEXT,
    ADD COLUMN last_moderated_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN visibility VARCHAR(20) NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'unlisted', 'followers_only', 'private')),
    ADD COLUMN requires_premium BOOLEAN DEFAULT FALSE; -- For premium content

-- Add columns to `users` for gamification and enhanced profiles
ALTER TABLE users
    ADD COLUMN gamification_points INTEGER DEFAULT 0,
    ADD COLUMN last_seen_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN profile_views INTEGER DEFAULT 0;

-- Add columns to `user_reputation` for more granular scores
ALTER TABLE user_reputation
    ADD COLUMN moderation_accuracy_score NUMERIC(5,2) DEFAULT 50.00,
    ADD COLUMN fact_checking_score NUMERIC(5,2) DEFAULT 50.00;

-- Add column to `content_comments` for moderation
ALTER TABLE content_comments
    ADD COLUMN moderation_status VARCHAR(20) NOT NULL DEFAULT 'none' CHECK (moderation_status IN ('none', 'under_review', 'action_taken'));



=============================================
-- SECTION INDEXES (Original & Enhanced)
-- =============================================

-- Indexes for `users` table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Indexes for `content` table
CREATE INDEX idx_content_author_id ON content(author_id);
CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_content_published_at ON content(published_at);
CREATE INDEX idx_content_location ON content USING GIST (location);
CREATE INDEX idx_content_title_search ON content USING GIN (to_tsvector('english', title));
CREATE INDEX idx_content_body_search ON content USING GIN (to_tsvector('english', body));

-- Indexes for `content_comments` table
CREATE INDEX idx_content_comments_content_id ON content_comments(content_id);
CREATE INDEX idx_content_comments_user_id ON content_comments(user_id);
CREATE INDEX idx_content_comments_parent_comment_id ON content_comments(parent_comment_id);

-- Indexes for `content_reactions` table
CREATE INDEX idx_content_reactions_content_id ON content_reactions(content_id);
CREATE INDEX idx_content_reactions_user_id ON content_reactions(user_id);

-- Indexes for `user_follows` table
CREATE INDEX idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX idx_user_follows_followed_id ON user_follows(followed_id);

-- Indexes for `content_flags` table
CREATE INDEX idx_content_flags_content_id ON content_flags(content_id);
CREATE INDEX idx_content_flags_status ON content_flags(status);

-- Indexes for `token_transactions` table
CREATE INDEX idx_token_transactions_from_user_id ON token_transactions(from_user_id);
CREATE INDEX idx_token_transactions_to_user_id ON token_transactions(to_user_id);
CREATE INDEX idx_token_transactions_transaction_type ON token_transactions(transaction_type);

-- Indexes for new tables
CREATE INDEX idx_moderation_proposals_status ON moderation_proposals(status);
CREATE INDEX idx_moderation_votes_proposal_id ON moderation_votes(proposal_id);
CREATE INDEX idx_moderation_votes_user_id ON moderation_votes(user_id);
CREATE INDEX idx_moderation_disputes_status ON moderation_disputes(status);
CREATE INDEX idx_moderation_audit_log_event_type ON moderation_audit_log(event_type);
CREATE INDEX idx_moderation_audit_log_actor_id ON moderation_audit_log(actor_id);
CREATE INDEX idx_bounties_status ON bounties(status);
CREATE INDEX idx_bounty_submissions_bounty_id ON bounty_submissions(bounty_id);
CREATE INDEX idx_user_groups_slug ON user_groups(slug);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_direct_messages_sender_id ON direct_messages(sender_id);
CREATE INDEX idx_direct_messages_recipient_id ON direct_messages(recipient_id);
CREATE INDEX idx_content_schedules_publish_at ON content_schedules(publish_at);



=============================================
-- SECTION : VIEWS (Original & Enhanced)
-- =============================================

-- View for user profile information
CREATE OR REPLACE VIEW view_user_profile AS
SELECT
    u.user_id,
    u.username,
    u.display_name,
    u.profile_image_url,
    u.bio,
    u.location,
    u.website_url,
    u.created_at,
    u.last_login_at,
    ur.reputation_score,
    ur.credibility_score,
    (SELECT COUNT(*) FROM user_follows WHERE follower_id = u.user_id) AS following_count,
    (SELECT COUNT(*) FROM user_follows WHERE followed_id = u.user_id) AS followers_count,
    (SELECT COUNT(*) FROM content WHERE author_id = u.user_id AND status = 'published') AS published_content_count
FROM users u
LEFT JOIN user_reputation ur ON u.user_id = ur.user_id
WHERE u.is_active = TRUE AND u.is_deleted = FALSE;

-- View for detailed content information
CREATE OR REPLACE VIEW view_content_details AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.excerpt,
    c.body,
    c.status,
    c.published_at,
    c.created_at,
    c.updated_at,
    ct.type_name AS content_type,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    (SELECT COUNT(*) FROM content_reactions WHERE content_id = c.content_id AND reaction_type = 'like') AS like_count,
    (SELECT COUNT(*) FROM content_reactions WHERE content_id = c.content_id AND reaction_type = 'dislike') AS dislike_count,
    (SELECT COUNT(*) FROM content_comments WHERE content_id = c.content_id) AS comment_count,
    (SELECT STRING_AGG(cat.name, ', ') FROM categories cat JOIN content_categories cc ON cat.category_id = cc.category_id WHERE cc.content_id = c.content_id) AS categories,
    (SELECT STRING_AGG(t.name, ', ') FROM tags t JOIN content_tags ct ON t.tag_id = ct.tag_id WHERE ct.content_id = c.content_id) AS tags
FROM content c
JOIN content_types ct ON c.content_type_id = ct.content_type_id
JOIN users u ON c.author_id = u.user_id;

-- Enhanced view for moderation queue
CREATE OR REPLACE VIEW view_moderation_queue AS
SELECT
    'content' AS item_type,
    cf.flag_id,
    cf.content_id AS item_id,
    c.title AS item_title,
    cf.flag_type,
    cf.reason,
    cf.status,
    cf.created_at AS flagged_at,
    cf.user_id AS flagged_by_user_id
FROM content_flags cf
JOIN content c ON cf.content_id = c.content_id
WHERE cf.status = 'pending'
UNION ALL
SELECT
    'comment' AS item_type,
    cmf.flag_id,
    cmf.comment_id AS item_id,
    SUBSTRING(cc.body, 1, 100) AS item_title,
    cmf.flag_type,
    cmf.reason,
    cmf.status,
    cmf.created_at AS flagged_at,
    cmf.user_id AS flagged_by_user_id
FROM comment_flags cmf
JOIN content_comments cc ON cmf.comment_id = cc.comment_id
WHERE cmf.status = 'pending'
UNION ALL
SELECT
    'user' AS item_type,
    uf.flag_id,
    uf.reported_user_id AS item_id,
    u.username AS item_title,
    uf.flag_type,
    uf.reason,
    uf.status,
    uf.created_at AS flagged_at,
    uf.reporting_user_id AS flagged_by_user_id
FROM user_flags uf
JOIN users u ON uf.reported_user_id = u.user_id
WHERE uf.status = 'pending';

-- View for platform analytics dashboard
CREATE OR REPLACE VIEW view_platform_analytics_summary AS
SELECT
    (SELECT COUNT(*) FROM users WHERE is_active = TRUE) AS total_users,
    (SELECT COUNT(*) FROM content WHERE status = 'published') AS total_published_content,
    (SELECT COUNT(*) FROM content_comments WHERE status = 'published') AS total_comments,
    (SELECT COUNT(*) FROM token_transactions WHERE status = 'completed') AS total_transactions,
    (SELECT SUM(amount) FROM token_transactions WHERE transaction_type = 'tip' AND status = 'completed') AS total_tips_volume,
    (SELECT COUNT(*) FROM page_views WHERE view_time > NOW() - INTERVAL '24 hours') AS page_views_last_24h;

-- =============================================
-- SECTION: FUNCTIONS & PROCEDURES (Original & Enhanced)
-- =============================================


-- =============================================
-- SECTION 12: VIEWS (Original & Enhanced)
-- =============================================

-- View for user profile information
CREATE OR REPLACE VIEW view_user_profile AS
SELECT
    u.user_id,
    u.username,
    u.display_name,
    u.profile_image_url,
    u.bio,
    u.location,
    u.website_url,
    u.created_at,
    u.last_login_at,
    ur.reputation_score,
    ur.credibility_score,
    (SELECT COUNT(*) FROM user_follows WHERE follower_id = u.user_id) AS following_count,
    (SELECT COUNT(*) FROM user_follows WHERE followed_id = u.user_id) AS followers_count,
    (SELECT COUNT(*) FROM content WHERE author_id = u.user_id AND status = 'published') AS published_content_count
FROM users u
LEFT JOIN user_reputation ur ON u.user_id = ur.user_id
WHERE u.is_active = TRUE AND u.is_deleted = FALSE;

-- View for detailed content information
CREATE OR REPLACE VIEW view_content_details AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.excerpt,
    c.body,
    c.status,
    c.published_at,
    c.created_at,
    c.updated_at,
    ct.type_name AS content_type,
    u.user_id AS author_id,
    u.username AS author_username,
    u.display_name AS author_display_name,
    (SELECT COUNT(*) FROM content_reactions WHERE content_id = c.content_id AND reaction_type = 'like') AS like_count,
    (SELECT COUNT(*) FROM content_reactions WHERE content_id = c.content_id AND reaction_type = 'dislike') AS dislike_count,
    (SELECT COUNT(*) FROM content_comments WHERE content_id = c.content_id) AS comment_count,
    (SELECT STRING_AGG(cat.name, ', ') FROM categories cat JOIN content_categories cc ON cat.category_id = cc.category_id WHERE cc.content_id = c.content_id) AS categories,
    (SELECT STRING_AGG(t.name, ', ') FROM tags t JOIN content_tags ct ON t.tag_id = ct.tag_id WHERE ct.content_id = c.content_id) AS tags
FROM content c
JOIN content_types ct ON c.content_type_id = ct.content_type_id
JOIN users u ON c.author_id = u.user_id;

-- Enhanced view for moderation queue
CREATE OR REPLACE VIEW view_moderation_queue AS
SELECT
    'content' AS item_type,
    cf.flag_id,
    cf.content_id AS item_id,
    c.title AS item_title,
    cf.flag_type,
    cf.reason,
    cf.status,
    cf.created_at AS flagged_at,
    cf.user_id AS flagged_by_user_id
FROM content_flags cf
JOIN content c ON cf.content_id = c.content_id
WHERE cf.status = 'pending'
UNION ALL
SELECT
    'comment' AS item_type,
    cmf.flag_id,
    cmf.comment_id AS item_id,
    SUBSTRING(cc.body, 1, 100) AS item_title,
    cmf.flag_type,
    cmf.reason,
    cmf.status,
    cmf.created_at AS flagged_at,
    cmf.user_id AS flagged_by_user_id
FROM comment_flags cmf
JOIN content_comments cc ON cmf.comment_id = cc.comment_id
WHERE cmf.status = 'pending'
UNION ALL
SELECT
    'user' AS item_type,
    uf.flag_id,
    uf.reported_user_id AS item_id,
    u.username AS item_title,
    uf.flag_type,
    uf.reason,
    uf.status,
    uf.created_at AS flagged_at,
    uf.reporting_user_id AS flagged_by_user_id
FROM user_flags uf
JOIN users u ON uf.reported_user_id = u.user_id
WHERE uf.status = 'pending';

-- View for platform analytics dashboard
CREATE OR REPLACE VIEW view_platform_analytics_summary AS
SELECT
    (SELECT COUNT(*) FROM users WHERE is_active = TRUE) AS total_users,
    (SELECT COUNT(*) FROM content WHERE status = 'published') AS total_published_content,
    (SELECT COUNT(*) FROM content_comments WHERE status = 'published') AS total_comments,
    (SELECT COUNT(*) FROM token_transactions WHERE status = 'completed') AS total_transactions,
    (SELECT SUM(amount) FROM token_transactions WHERE transaction_type = 'tip' AND status = 'completed') AS total_tips_volume,
    (SELECT COUNT(*) FROM page_views WHERE view_time > NOW() - INTERVAL '24 hours') AS page_views_last_24h;

-- =============================================
-- SECTION 13: FUNCTIONS & PROCEDURES (Original & Enhanced)
-- =============================================

-- Function to update `updated_at` timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- First drop the procedure if it exists
DROP PROCEDURE IF EXISTS calculate_user_reputation;

-- Then create it as a function
CREATE OR REPLACE FUNCTION calculate_user_reputation(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_reputation_score INTEGER;
BEGIN
    SELECT
        COALESCE(SUM(
            CASE
                WHEN rh.change_amount > 0 THEN rh.change_amount
                ELSE 0
            END
        ), 0) -
        COALESCE(SUM(
            CASE
                WHEN rh.change_amount < 0 THEN ABS(rh.change_amount)
                ELSE 0
            END
        ), 0)
    INTO v_reputation_score
    FROM user_reputation_history rh
    WHERE rh.user_id = p_user_id;

    UPDATE user_reputation
    SET reputation_score = v_reputation_score, last_calculated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN v_reputation_score;
END;
$$ LANGUAGE plpgsql;

-- Procedure to create a new user with role
CREATE OR REPLACE PROCEDURE create_user_with_role(
    p_username VARCHAR,
    p_email VARCHAR,
    p_password TEXT,
    p_role_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
    v_salt TEXT;
BEGIN
    v_salt := gen_salt('bf', 8);
    INSERT INTO users (username, email, password_hash, salt)
    VALUES (p_username, p_email, crypt(p_password, v_salt), v_salt)
    RETURNING user_id INTO v_user_id;

    SELECT role_id INTO v_role_id FROM roles WHERE role_name = p_role_name;

    IF v_role_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id)
        VALUES (v_user_id, v_role_id);
    ELSE
        RAISE EXCEPTION 'Role not found: %', p_role_name;
    END IF;
END;
$$;

-- Enhanced procedure to publish content with scheduling
CREATE OR REPLACE PROCEDURE publish_content(
    p_content_id UUID,
    p_publish_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_publish_at IS NULL OR p_publish_at <= NOW() THEN
        -- Publish immediately
        UPDATE content
        SET status = 'published', published_at = NOW()
        WHERE content_id = p_content_id;

        DELETE FROM content_schedules WHERE content_id = p_content_id;
    ELSE
        -- Schedule for later
        INSERT INTO content_schedules (content_id, publish_at, scheduled_by)
        VALUES (p_content_id, p_publish_at, (SELECT author_id FROM content WHERE content_id = p_content_id))
        ON CONFLICT (content_id) DO UPDATE
        SET publish_at = EXCLUDED.publish_at, status = 'scheduled';
    END IF;
END;
$$;

-- =============================================
-- SECTION 14: TRIGGERS (Original & Enhanced)
-- =============================================

-- Trigger to update `updated_at` on various tables
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_content_updated_at BEFORE UPDATE ON content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_content_comments_updated_at BEFORE UPDATE ON content_comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to create a reputation entry for a new user
CREATE OR REPLACE FUNCTION create_user_reputation_entry()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_reputation (user_id) VALUES (NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_user_reputation AFTER INSERT ON users FOR EACH ROW EXECUTE FUNCTION create_user_reputation_entry();

-- Trigger to log moderation actions in the audit log
CREATE OR REPLACE FUNCTION log_moderation_action()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO moderation_audit_log (
        event_type,
        actor_id,
        target_content_id,
        target_comment_id,
        target_user_id,
        action_details
    )
    VALUES (
        TG_ARGV[0],
        NEW.moderator_id,
        NEW.content_id,
        NEW.comment_id,
        NEW.user_id,
        jsonb_build_object('reason', COALESCE(NEW.reason, ''), 'action', NEW.action_type)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_moderation_action AFTER INSERT ON moderation_actions
FOR EACH ROW EXECUTE FUNCTION log_moderation_action('moderation_action_taken');

-- Trigger to update content moderation status when a flag is created
CREATE OR REPLACE FUNCTION update_content_moderation_status_on_flag()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE content
    SET moderation_status = 'under_review', last_moderated_at = NOW()
    WHERE content_id = NEW.content_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_content_moderation_status AFTER INSERT ON content_flags
FOR EACH ROW EXECUTE FUNCTION update_content_moderation_status_on_flag();

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Function to update `updated_at` timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Procedure to create a new user with role
CREATE OR REPLACE PROCEDURE create_user_with_role(
    p_username VARCHAR,
    p_email VARCHAR,
    p_password TEXT,
    p_role_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
    v_salt TEXT;
BEGIN
    v_salt := gen_salt('bf', 8);
    INSERT INTO users (username, email, password_hash, salt)
    VALUES (p_username, p_email, crypt(p_password, v_salt), v_salt)
    RETURNING user_id INTO v_user_id;

    SELECT role_id INTO v_role_id FROM roles WHERE role_name = p_role_name;

    IF v_role_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role_id)
        VALUES (v_user_id, v_role_id);
    ELSE
        RAISE EXCEPTION 'Role not found: %', p_role_name;
    END IF;
END;
$$;

-- Enhanced procedure to publish content with scheduling
CREATE OR REPLACE PROCEDURE publish_content(
    p_content_id UUID,
    p_publish_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_publish_at IS NULL OR p_publish_at <= NOW() THEN
        -- Publish immediately
        UPDATE content
        SET status = 'published', published_at = NOW()
        WHERE content_id = p_content_id;

        DELETE FROM content_schedules WHERE content_id = p_content_id;
    ELSE
        -- Schedule for later
        INSERT INTO content_schedules (content_id, publish_at, scheduled_by)
        VALUES (p_content_id, p_publish_at, (SELECT author_id FROM content WHERE content_id = p_content_id))
        ON CONFLICT (content_id) DO UPDATE
        SET publish_at = EXCLUDED.publish_at, status = 'scheduled';
    END IF;
END;
$$;

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Advanced Security Enhancements - Zero Trust Architecture Implementation
----------------------------------------------------------------------------------------------------
-- for advanced text searche features
create extension if not exists "pg_trgm";

/*
 * Table: zero_trust_policies
 * Description: Defines access control policies following Zero Trust principles
 * Business Case: Implements granular access control based on multiple verification factors
 * Security: Enforces least privilege access and continuous verification
 */
CREATE TABLE zero_trust_policies (
    policy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50) NOT NULL, -- 'api', 'content', 'user_data', etc.
    access_conditions JSONB NOT NULL, -- Conditions that must be met for access
    verification_methods TEXT[] NOT NULL, -- ['2fa', 'device_check', 'behavioral_analysis']
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

/*
 * Table: access_sessions
 * Description: Tracks authenticated sessions with security context
 * Business Case: Provides session management with risk scoring for adaptive authentication
 * Security: Includes device fingerprinting and continuous risk assessment
 */

CREATE TABLE access_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    device_id UUID NOT NULL,
    device_fingerprint TEXT NOT NULL,
    ip_address INET NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    risk_score NUMERIC(5,2) DEFAULT 0,
    last_verified_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE
);

CREATE TABLE security_events (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL, -- 'login', 'access_denied', 'policy_violation'
    user_id UUID REFERENCES users(user_id),
    session_id UUID REFERENCES access_sessions(session_id),
    resource_type VARCHAR(50),
    resource_id UUID,
    event_data JSONB,
    risk_score NUMERIC(5,2),
    action_taken VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

--------------------
---- Advanced Threat Detection
------------------
CREATE TABLE threat_detection_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    rule_condition TEXT NOT NULL, -- SQL-like condition
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    action VARCHAR(100) NOT NULL, -- 'block', 'notify', 'require_verification'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE detected_threats (
    threat_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES threat_detection_rules(rule_id),
    user_id UUID REFERENCES users(user_id),
    session_id UUID REFERENCES access_sessions(session_id),
    threat_data JSONB NOT NULL,
    action_taken VARCHAR(100) NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

--------------------
---- Enhanced Content Verification System -- Multilayer verification Framework
------------------
/*
 * Table: verification_methods
 * Description: Defines different methods for content verification
 * Business Case: Supports multi-layered verification framework
 * Trust: Enables transparent scoring of content credibility
 */
CREATE TABLE verification_methods (
    method_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN (
        'source', 'witness', 'technical', 'blockchain', 'expert', 'crowd'
    )),
    weight NUMERIC(3,2) NOT NULL, -- Weight in overall verification score
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE content_verification_attestations (
    attestation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    method_id UUID NOT NULL REFERENCES verification_methods(method_id),
    verifier_id UUID REFERENCES users(user_id), -- NULL for automated methods
    attestation_data JSONB NOT NULL,
    confidence_score NUMERIC(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE -- NULL for permanent attestations
);

CREATE TABLE verification_workflows (
    workflow_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    required_methods UUID[] NOT NULL, -- Array of method_ids
    threshold_score NUMERIC(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

----------------
--AI powered Deepfake detection
--------------

CREATE TABLE media_forensic_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    media_id UUID NOT NULL REFERENCES content_media(media_id),
    analysis_type VARCHAR(50) NOT NULL CHECK (analysis_type IN (
        'deepfake', 'manipulation', 'metadata', 'provenance'
    )),
    algorithm_name VARCHAR(100) NOT NULL,
    algorithm_version VARCHAR(50) NOT NULL,
    raw_results JSONB NOT NULL,
    confidence_score NUMERIC(5,2) NOT NULL,
    analysis_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE forensic_analysis_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    media_types VARCHAR(50)[] NOT NULL, -- ['image', 'video', 'audio']
    risk_threshold NUMERIC(5,2) NOT NULL,
    action VARCHAR(100) NOT NULL, -- 'flag', 'block', 'require_human_review'
    is_active BOOLEAN DEFAULT TRUE
);
----------------
--Dyanmic Reward Engine -- Advanced Monetization and Incentives
--------------
/*
 * Table: reward_models
 * Description: Defines algorithms for calculating user rewards
 * Business Case: Flexible reward system adaptable to different platform goals
 * Incentives: Drives quality content creation and community participation
 */
CREATE TABLE reward_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    model_parameters JSONB NOT NULL,
    activation_rules JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reward_calculations (
    calculation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES reward_models(model_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    input_metrics JSONB NOT NULL,
    calculated_rewards JSONB NOT NULL, -- Breakdown of rewards
    total_reward NUMERIC(20,8) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('calculated', 'approved', 'distributed', 'rejected')),
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    distributed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE reward_distribution_pools (
    pool_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    allocation_rules JSONB NOT NULL,
    total_amount NUMERIC(20,8) NOT NULL,
    distributed_amount NUMERIC(20,8) DEFAULT 0,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);


----------------
--NFT Based Content Certification
--------------
/*
 * Table: content_nfts
 * Description: Links content to blockchain-based NFTs for ownership and monetization
 * Business Case: Enables content tokenization and creator monetization
 * Innovation: Combines journalism with Web3 technologies
 */
CREATE TABLE content_nfts (
    nft_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    blockchain VARCHAR(50) NOT NULL,
    contract_address TEXT NOT NULL,
    token_id TEXT NOT NULL,
    token_standard VARCHAR(20) NOT NULL,
    metadata_url TEXT,
    minted_by UUID NOT NULL REFERENCES users(user_id),
    minted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id)
);

/*
 * Table: nft_licensing
 * Description: Manages licensing terms for NFT-based content
 * Business Case: Enables commercial use of content while protecting creator rights
 * Innovation: Blockchain-based digital rights management
 */
CREATE TABLE nft_licensing (
    license_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nft_id UUID NOT NULL REFERENCES content_nfts(nft_id),
    license_type VARCHAR(50) NOT NULL,
    terms TEXT NOT NULL,
    price_amount NUMERIC(20,8),
    price_currency VARCHAR(10),
    is_transferable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE nft_ownership (
    ownership_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nft_id UUID NOT NULL REFERENCES content_nfts(nft_id),
    owner_address TEXT NOT NULL,
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    relinquished_at TIMESTAMP WITH TIME ZONE,
    current_owner BOOLEAN DEFAULT TRUE
);


----------------
--Decentralized Autonomous Organization (DAO)Integration
--------------
/*
 * Table: dao_proposals
 * Description: Community governance proposals for platform decisions
 * Business Case: Decentralized platform governance
 * Democracy: Enables community-led decision making
 */
CREATE TABLE dao_proposals (
    proposal_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    proposal_type VARCHAR(50) NOT NULL CHECK (proposal_type IN (
        'platform_change', 'funding', 'moderation_policy', 'content_policy'
    )),
    creator_id UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    voting_start TIMESTAMP WITH TIME ZONE,
    voting_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'draft', 'active', 'passed', 'rejected', 'implemented'
    )),
    implementation_data JSONB
);

CREATE TABLE dao_votes (
    vote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id UUID NOT NULL REFERENCES dao_proposals(proposal_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    vote_power NUMERIC(20,8) NOT NULL,
    vote_choice VARCHAR(20) NOT NULL CHECK (vote_choice IN ('for', 'against', 'abstain')),
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    blockchain_tx_hash TEXT,
    UNIQUE (proposal_id, user_id)
);

CREATE TABLE dao_delegations (
    delegation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegator_id UUID NOT NULL REFERENCES users(user_id),
    delegatee_id UUID NOT NULL REFERENCES users(user_id),
    proposal_type VARCHAR(50), -- NULL for all proposals
    voting_power_percentage NUMERIC(5,2) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-------------
---Reputation Based Governance
------------
CREATE TABLE reputation_tiers (
    tier_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    min_score INTEGER NOT NULL,
    max_score INTEGER,
    governance_power NUMERIC(5,2) NOT NULL,
    privileges JSONB NOT NULL, -- {'create_proposals': true, 'vote_weight': 1.5}
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE reputation_decay_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    decay_formula TEXT NOT NULL, -- e.g., "score * 0.99"
    application_frequency VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly'
    min_score INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);
-------------
--- Advanced Analytics and Personalization Featueres
-------------


CREATE TABLE predictive_analytics_models (
    model_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    model_type VARCHAR(50) NOT NULL, -- 'content_success', 'user_churn', etc.
    version VARCHAR(50) NOT NULL,
    training_data_range DATERANGE NOT NULL,
    performance_metrics JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE content_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    content_id UUID NOT NULL REFERENCES content(content_id),
    algorithm_name VARCHAR(100) NOT NULL,
    recommendation_score NUMERIC(10,2) NOT NULL,
    recommendation_reason VARCHAR(255),
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    was_consumed BOOLEAN DEFAULT FALSE,
    consumed_at TIMESTAMP WITH TIME ZONE
);


----------------
---Advanced User Segmentation
---------------
CREATE TABLE user_segments (
    segment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    segment_rules JSONB NOT NULL,
    estimated_size INTEGER,
    refresh_frequency VARCHAR(20) NOT NULL,
    last_refreshed TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE user_segment_membership (
    membership_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID NOT NULL REFERENCES user_segments(segment_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN DEFAULT TRUE
);

-- Create a partial unique index instead of the UNIQUE constraint with WHERE
CREATE UNIQUE INDEX idx_user_segment_membership_current
ON user_segment_membership (segment_id, user_id)
WHERE is_current;

CREATE TABLE segment_based_content_rules (
    rule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID NOT NULL REFERENCES user_segments(segment_id),
    content_type_id UUID REFERENCES content_types(content_type_id),
    priority INTEGER NOT NULL,
    display_rules JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);


------------------------------------------------------------------------------------------------------------------
---- Structured Content Templates for ENhanced Content Managemnet
------------------------------------------------------------------------------------------------------------------
CREATE TABLE content_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    content_type_id UUID NOT NULL REFERENCES content_types(content_type_id),
    template_structure JSONB NOT NULL, -- Schema for the content
    default_values JSONB,
    is_system_template BOOLEAN DEFAULT FALSE,
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE template_fields (
    field_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES content_templates(template_id),
    name VARCHAR(100) NOT NULL,
    field_type VARCHAR(50) NOT NULL, -- 'text', 'image', 'location', etc.
    is_required BOOLEAN DEFAULT FALSE,
    validation_rules JSONB,
    position INTEGER NOT NULL,
    UNIQUE (template_id, name)
);

------------------------------------------------------------------------------------------------------------------
---- Collaborative Editing Framework
------------------------------------------------------------------------------------------------------------------
CREATE TABLE collaborative_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    created_by UUID NOT NULL REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    session_state JSONB NOT NULL
);

CREATE TABLE session_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES collaborative_sessions(session_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    join_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    leave_time TIMESTAMP WITH TIME ZONE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('editor', 'reviewer', 'observer')),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE content_edit_changes (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES collaborative_sessions(session_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    change_type VARCHAR(50) NOT NULL, -- 'insert', 'delete', 'format', etc.
    change_data JSONB NOT NULL,
    change_position INTEGER NOT NULL,
    change_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------------------------------------------
----Cross-Platform Content Syndication for Enhanced federation and interoperability
------------------------------------------------------------------------------------------------------------------
CREATE TABLE syndication_partners (
    partner_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    partnership_type VARCHAR(50) NOT NULL CHECK (partnership_type IN (
        'syndication', 'aggregation', 'mutual', 'commercial'
    )),
    api_endpoint TEXT,
    auth_method VARCHAR(50) NOT NULL,
    auth_credentials JSONB,
    content_license VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP WITH TIME ZONE
);

CREATE TABLE content_syndication (
    syndication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    partner_id UUID NOT NULL REFERENCES syndication_partners(partner_id),
    syndicated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    syndication_status VARCHAR(20) NOT NULL CHECK (syndication_status IN (
        'pending', 'approved', 'rejected', 'published', 'removed'
    )),
    external_reference TEXT,
    performance_metrics JSONB
);

------------------------------------------------------------------------------------------------------------------
----universal content Addressing
------------------------------------------------------------------------------------------------------------------
/*
 * Table: content_uris
 * Description: Universal content addressing across protocols
 * Business Case: Ensures content permanence and cross-platform access
 * Innovation: Supports decentralized storage solutions
 */
CREATE TABLE content_uris (
    uri_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    uri_scheme VARCHAR(50) NOT NULL, -- 'ipfs', 'arweave', 'http', etc.
    uri_path TEXT NOT NULL,
    is_canonical BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Add a partial unique index to enforce uniqueness only for canonical URIs
CREATE UNIQUE INDEX idx_unique_canonical_uri
ON content_uris (content_id, uri_scheme)
WHERE is_canonical;


CREATE TABLE uri_resolution_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    uri_id UUID NOT NULL REFERENCES content_uris(uri_id),
    resolved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolver_node VARCHAR(255) NOT NULL,
    resolution_time_ms INTEGER,
    cache_status VARCHAR(20) NOT NULL,
    client_info JSONB
);


-- Content discovery indexes
CREATE INDEX idx_content_author_status ON content(author_id, status);
CREATE INDEX idx_content_verified ON content(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_content_published ON content(published_at) WHERE status = 'published';

-- Security indexes
CREATE INDEX idx_access_sessions_user ON access_sessions(user_id);
CREATE INDEX idx_access_sessions_risk ON access_sessions(risk_score) WHERE is_revoked = FALSE;

-- Search optimization
CREATE INDEX idx_content_title_trgm ON content USING gin(title gin_trgm_ops);
CREATE INDEX idx_content_body_trgm ON content USING gin(body gin_trgm_ops);

/*
 * View: verified_content_view
 * Description: Shows all verified content with trust indicators
 * Business Case: Powers high-integrity content feeds and fact-checking interfaces
 * Trust: Highlights content that has passed rigorous verification
 */
CREATE OR REPLACE VIEW verified_content_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.published_at,
    u.user_id AS author_id,
    u.display_name AS author_name,
    c.verification_score,
    (SELECT COUNT(*) FROM content_verification_attestations WHERE content_id = c.content_id) AS attestation_count,
    (SELECT jsonb_agg(jsonb_build_object('method', vm.name, 'score', cva.confidence_score))
     FROM content_verification_attestations cva
     JOIN verification_methods vm ON cva.method_id = vm.method_id
     WHERE cva.content_id = c.content_id) AS verification_details
FROM content c
JOIN users u ON c.author_id = u.user_id
WHERE c.is_verified = TRUE AND c.status = 'published'
ORDER BY c.verification_score DESC;




/*
 * Function: verify_content_automatically
 * Description: Runs automated verification checks on content
 * Business Case: Initial content screening before human review
 * Automation: Applies multiple verification methods algorithmically
 */
CREATE OR REPLACE FUNCTION verify_content_automatically(p_content_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_method RECORD;
BEGIN
    -- Apply each active verification method
    FOR v_method IN SELECT * FROM verification_methods WHERE is_active = TRUE
    LOOP
        CASE v_method.verification_type
            WHEN 'technical' THEN
                -- Run technical verification (image hashing, metadata analysis)
                INSERT INTO content_verification_attestations (
                    content_id, method_id, confidence_score
                ) VALUES (
                    p_content_id, v_method.method_id,
                    (SELECT calculate_technical_trust_score(p_content_id))
                )
                ON CONFLICT (content_id, method_id) DO UPDATE
                SET confidence_score = EXCLUDED.confidence_score;

                v_score := v_score + (SELECT calculate_technical_trust_score(p_content_id) * v_method.weight);

            -- Additional verification methods would be implemented here
            ELSE
                -- Other verification types
                NULL;
        END CASE;
    END LOOP;

    -- Update content with new verification score
    UPDATE content
    SET verification_score = v_score,
        is_verified = CASE WHEN v_score >= 70 THEN TRUE ELSE FALSE END
    WHERE content_id = p_content_id;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;


/*
 * Function: log_security_event
 * Description: Records security-relevant actions for auditing
 * Business Case: Compliance and threat detection
 * Security: Creates immutable audit trail
 */
CREATE OR REPLACE FUNCTION log_security_event()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO security_events (
        event_type, user_id, session_id, event_data
    ) VALUES (
        TG_ARGV[0],
        CASE WHEN TG_TABLE_NAME = 'users' THEN NEW.user_id ELSE NULL END,
        NULL, -- Session ID would be captured from application context
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to sensitive tables
CREATE TRIGGER tr_users_security_audit
AFTER INSERT OR UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION log_security_event('user_account_change');


/*
 * Procedure: rotate_mfa_secrets
 * Description: Bulk updates MFA secrets for enhanced security
 * Business Case: Periodic security hardening
 * Security: Mitigates risks from potential secret leaks
 */
CREATE OR REPLACE PROCEDURE rotate_mfa_secrets(
    p_batch_size INTEGER DEFAULT 100
) AS $$
BEGIN
    UPDATE users
    SET mfa_secret = encode(gen_random_bytes(32), 'base64')
    WHERE user_id IN (
        SELECT user_id
        FROM users
        WHERE mfa_secret IS NOT NULL
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    );
END;
$$ LANGUAGE plpgsql;

/*
 * View: security_dashboard
 * Description: Aggregates key security metrics for monitoring
 * Business Case: Real-time security monitoring
 * Security: Provides operational security visibility
 */
CREATE VIEW security_dashboard AS
SELECT
    COUNT(DISTINCT user_id) AS active_users,
    (SELECT COUNT(*) FROM security_events
     WHERE created_at > NOW() - INTERVAL '24 hours') AS daily_events,
    (SELECT COUNT(*) FROM login_attempts
     WHERE success = FALSE
     AND attempt_time > NOW() - INTERVAL '1 hour') AS recent_failed_logins,
    (SELECT COUNT(*) FROM users
     WHERE password_changed_at < NOW() - INTERVAL '90 days') AS expired_passwords;


--fix the errros

-- -- Insert core content types
-- INSERT INTO content_types (type_name, description, icon) VALUES
-- ('article', 'Long-form written content', 'article'),
-- ('fact_check', 'Fact-checking report with sources', 'fact_check'),
-- ('investigation', 'In-depth investigative piece', 'investigation');

-- Insert default verification methods
INSERT INTO verification_methods (name, description, verification_type, weight) VALUES
('Technical Analysis', 'Automated media forensics', 'technical', 0.3),
('Source Verification', 'Primary source validation', 'source', 0.4),
('Expert Review', 'Domain expert evaluation', 'expert', 0.5);
/*
 * Table: login_attempts
 * Description: Tracks authentication attempts for security analysis
 * Business Case: Brute force detection and account lockout
 * Security: Critical for identifying credential attacks
 */
CREATE TABLE login_attempts (
    attempt_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    ip_address INET NOT NULL,
    success BOOLEAN NOT NULL,
    attempt_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT
);
/*
 * View: user_permissions
 * Description: Consolidated view of effective user permissions
 * Business Case: Authorization decisions and permission reporting
 * Security: Used by security middleware for access control
 */
CREATE VIEW user_permissions AS
SELECT u.user_id, u.username, r.role_name, r.description as role_description
FROM users u
JOIN user_roles ur ON u.user_id = ur.user_id
JOIN roles r ON ur.role_id = r.role_id
WHERE u.is_active = TRUE;


/*
 * Function: log_security_event
 * Description: Records security-relevant actions for auditing
 * Business Case: Compliance and threat detection
 * Security: Creates immutable audit trail
 */
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id INTEGER,
    p_event_type VARCHAR(50),
    p_ip_address INET,
    p_user_agent TEXT,
    p_event_details JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO security_events(
        user_id,
        event_type,
        ip_address,
        user_agent,
        event_details
    ) VALUES (
        p_user_id,
        p_event_type,
        p_ip_address,
        p_user_agent,
        p_event_details
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Function: check_failed_logins
 * Description: Detects potential brute force attacks by counting recent failures
 * Business Case: Account security and automated threat response
 * Security: Prevents credential stuffing attacks
 */
CREATE OR REPLACE FUNCTION check_failed_logins(
    p_username VARCHAR(50),
    p_threshold INTEGER DEFAULT 5,
    p_minutes INTEGER DEFAULT 15
) RETURNS BOOLEAN AS $$
DECLARE
    v_failed_attempts INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_failed_attempts
    FROM login_attempts
    WHERE username = p_username
    AND success = FALSE
    AND attempt_time > (NOW() - (p_minutes * INTERVAL '1 minute'));

    RETURN v_failed_attempts >= p_threshold;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


/*
 * Table: system_settings
 * Description: Platform configuration and feature flags
 * Business Case: Centralized management of system behavior
 * Operations: Allows runtime configuration without code changes
*/
-- INSERT INTO system_settings (setting_key, setting_value, description) VALUES
-- ('content.auto_verify_threshold', '70', 'Minimum score for automatic content verification'),
-- ('security.zero_trust.enabled', 'true', 'Enable Zero Trust security model'),
-- ('monetization.nft.enabled', 'true', 'Enable NFT content tokenization');


/*
 * Table: content_collaboration_invites
 * Description: Tracks invitations for collaborative content creation
 * Business Case: Enables team-based journalism workflows
 * Workflow: Manages invite lifecycle from sending to acceptance/rejection
 */
CREATE TABLE content_collaboration_invites (
    invite_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    sender_id UUID NOT NULL REFERENCES users(user_id),
    recipient_id UUID NOT NULL REFERENCES users(user_id),
    role VARCHAR(50) NOT NULL CHECK (role IN ('coauthor', 'editor', 'researcher')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'revoked')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE
);

/*
 * Table: content_edit_suggestions
 * Description: Stores proposed edits to published content
 * Business Case: Enables community contributions while maintaining editorial control
 * Versioning: Tracks suggested changes without modifying original content
 */
CREATE TABLE content_edit_suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    suggested_by UUID NOT NULL REFERENCES users(user_id),
    original_text TEXT NOT NULL,
    suggested_text TEXT NOT NULL,
    reasoning TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(user_id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

/*
 * View: contributor_impact_view
 * Description: Aggregates user contributions across multiple dimensions
 * Business Case: Provides comprehensive contributor analytics
 * Incentives: Powers reputation systems and reward calculations
 */
CREATE OR REPLACE VIEW contributor_impact_view AS
SELECT
    u.user_id,
    u.username,
    u.display_name,
    COUNT(DISTINCT c.content_id) AS content_count,
    COUNT(DISTINCT cc.comment_id) AS comment_count,
    COUNT(DISTINCT cf.fact_check_id) AS fact_check_count,
    COUNT(DISTINCT es.suggestion_id) FILTER (WHERE es.status = 'approved') AS accepted_edits,
    ur.reputation_score,
    ur.credibility_score
FROM users u
LEFT JOIN content c ON u.user_id = c.author_id
LEFT JOIN content_comments cc ON u.user_id = cc.user_id
LEFT JOIN content_fact_checks cf ON u.user_id = cf.fact_checker_id
LEFT JOIN content_edit_suggestions es ON u.user_id = es.suggested_by
LEFT JOIN user_reputation ur ON u.user_id = ur.user_id
GROUP BY u.user_id, ur.reputation_score, ur.credibility_score;

/*
 * Function: apply_content_edit_suggestion
 * Description: Applies approved edits to content with version tracking
 * Business Case: Maintains content quality through community contributions
 * Audit: Preserves original content in version history
 */
CREATE OR REPLACE FUNCTION apply_content_edit_suggestion(p_suggestion_id UUID, p_reviewer_id UUID)
RETURNS VOID AS $$
DECLARE
    v_content_id UUID;
    v_suggested_text TEXT;
BEGIN
    -- Get suggestion details
    SELECT content_id, suggested_text INTO v_content_id, v_suggested_text
    FROM content_edit_suggestions
    WHERE suggestion_id = p_suggestion_id;

    -- Create version snapshot
    INSERT INTO content_versions (
        content_id,
        version_number,
        title,
        body,
        excerpt,
        updated_by,
        change_reason
    )
    SELECT
        content_id,
        COALESCE((SELECT MAX(version_number) FROM content_versions WHERE content_id = v_content_id), 0) + 1,
        title,
        body,
        excerpt,
        p_reviewer_id,
        'Community edit suggestion applied'
    FROM content
    WHERE content_id = v_content_id;

    -- Update content
    UPDATE content
    SET body = v_suggested_text,
        updated_at = NOW(),
        updated_by = p_reviewer_id
    WHERE content_id = v_content_id;

    -- Update suggestion status
    UPDATE content_edit_suggestions
    SET status = 'approved',
        reviewed_by = p_reviewer_id,
        reviewed_at = NOW()
    WHERE suggestion_id = p_suggestion_id;
END;
$$ LANGUAGE plpgsql;

/*
 * Procedure: escalate_content_moderation
 * Description: Handles complex moderation cases requiring multiple reviewers
 * Business Case: Ensures fair and thorough content evaluation
 * Governance: Implements multi-tier moderation workflow
 */
CREATE OR REPLACE PROCEDURE escalate_content_moderation(
    p_content_id UUID,
    p_reason TEXT,
    p_escalated_by UUID
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update content moderation status
    UPDATE content
    SET moderation_status = 'escalated',
        moderation_notes = COALESCE(moderation_notes || E'\n' || p_reason, p_reason),
        last_moderated_at = NOW()
    WHERE content_id = p_content_id;

    -- Notify senior moderators
    INSERT INTO user_notifications (
        user_id,
        notification_type,
        title,
        message,
        related_content_id,
        action_url
    )
    SELECT
        ur.user_id,
        'moderation_escalation',
        'Content Moderation Escalation',
        'Content "' || (SELECT title FROM content WHERE content_id = p_content_id) || '" has been escalated for review',
        p_content_id,
        '/moderate/escalated/' || p_content_id
    FROM user_roles ur
    JOIN roles r ON ur.role_id = r.role_id
    WHERE r.role_name = 'senior_moderator'
    AND ur.is_active = TRUE;

    -- Log escalation event
    INSERT INTO moderation_audit_log (
        event_type,
        actor_id,
        target_content_id,
        details
    ) VALUES (
        'escalation',
        p_escalated_by,
        p_content_id,
        jsonb_build_object('reason', p_reason)
    );
END;
$$;

/*
 * Table: content_access_tokens
 * Description: Manages temporary access tokens for premium content
 * Business Case: Enables flexible content monetization
 * Security: Time-limited tokens with usage tracking
 */
CREATE TABLE content_access_tokens (
    token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    user_id UUID REFERENCES users(user_id), -- NULL for anonymous access
    token_hash TEXT NOT NULL UNIQUE,
    access_level VARCHAR(20) NOT NULL CHECK (access_level IN ('preview', 'full', 'download')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    uses_remaining INTEGER,
    is_active BOOLEAN DEFAULT TRUE
);

/*
 * Function: generate_content_access_token
 * Description: Creates secure, expiring access tokens for content
 * Business Case: Supports pay-per-view and temporary access models
 * Security: Uses cryptographic hashing for token generation
 */
CREATE OR REPLACE FUNCTION generate_content_access_token(
    p_content_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_access_level VARCHAR DEFAULT 'full',
    p_valid_hours INTEGER DEFAULT 24,
    p_uses INTEGER DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_token TEXT;
    v_token_hash TEXT;
BEGIN
    -- Generate random token
    v_token := encode(gen_random_bytes(32), 'hex');
    v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

    -- Store hashed token
    INSERT INTO content_access_tokens (
        content_id,
        user_id,
        token_hash,
        access_level,
        expires_at,
        uses_remaining
    ) VALUES (
        p_content_id,
        p_user_id,
        v_token_hash,
        p_access_level,
        NOW() + (p_valid_hours || ' hours')::INTERVAL,
        p_uses
    );

    RETURN v_token;
END;
$$ LANGUAGE plpgsql;

/*
 * Table: content_licensing
 * Description: Manages licensing terms for content reuse
 * Business Case: Enables commercial content syndication
 * Compliance: Tracks usage rights and restrictions
 */
CREATE TABLE content_licensing (
    license_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id),
    license_type VARCHAR(50) NOT NULL CHECK (license_type IN ('CC_BY', 'CC_BY_SA', 'CC_BY_NC', 'commercial', 'custom')),
    terms_url TEXT,
    attribution_requirements TEXT,
    commercial_use_allowed BOOLEAN NOT NULL,
    modifications_allowed BOOLEAN NOT NULL,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL REFERENCES users(user_id)
);

/*
 * View: licensed_content_view
 * Description: Shows content available for reuse with licensing details
 * Business Case: Facilitates content discovery for legal reuse
 * Compliance: Clearly displays usage rights and restrictions
 */
CREATE OR REPLACE VIEW licensed_content_view AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.published_at,
    u.user_id AS author_id,
    u.display_name AS author_name,
    cl.license_type,
    cl.commercial_use_allowed,
    cl.modifications_allowed,
    cl.terms_url
FROM content c
JOIN users u ON c.author_id = u.user_id
JOIN content_licensing cl ON c.content_id = cl.content_id
WHERE c.status = 'published'
AND (cl.valid_until IS NULL OR cl.valid_until > NOW())
ORDER BY c.published_at DESC;




/*
 * Table: content_performance_metrics
 * Description: Aggregated performance data for content
 * Business Case: Powers recommendation systems and creator analytics
 * Insights: Multi-dimensional content performance tracking
 */
-- Create new table structure
CREATE TABLE content_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(content_id) ON DELETE CASCADE,
    time_period VARCHAR(20) NOT NULL CHECK (time_period IN ('hourly', 'daily', 'weekly', 'monthly')),
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    engagement_score NUMERIC(10,2) NOT NULL,
    quality_score NUMERIC(10,2) NOT NULL,
    virality_score NUMERIC(10,2) NOT NULL,
    retention_score NUMERIC(10,2) NOT NULL,
    demographic_breakdown JSONB,
    device_breakdown JSONB,
    referrer_breakdown JSONB,
    UNIQUE (content_id, time_period, period_start)
);

/*
 * Materialized View: trending_content_rankings
 * Description: Pre-computed trending content with ranking scores
 * Business Case: Powers "Trending Now" sections and personalized feeds
 * Refresh Strategy: Hourly with incremental updates
 */
CREATE MATERIALIZED VIEW trending_content_rankings AS
SELECT
    c.content_id,
    c.title,
    c.slug,
    c.published_at,
    c.content_type_id,
    ct.type_name AS content_type,
    c.author_id,
    u.username AS author_username,
    -- Scoring algorithm weights different engagement metrics
    (COALESCE(pm.engagement_score, 0) * 0.4 +
    (COALESCE(pm.quality_score, 0) * 0.3 +
    (COALESCE(pm.virality_score, 0) * 0.2 +
    (COALESCE(pm.retention_score, 0) * 0.1 AS trending_score,
    -- Time decay factor gives newer content a boost
    EXP(-EXTRACT(EPOCH FROM (NOW() - c.published_at)/86400) AS time_decay_factor,
    -- Final score combines metrics with time decay
    (COALESCE(pm.engagement_score, 0) * 0.4 +
    (COALESCE(pm.quality_score, 0) * 0.3 +
    (COALESCE(pm.virality_score, 0) * 0.2 +
    (COALESCE(pm.retention_score, 0) * 0.1 *
    EXP(-EXTRACT(EPOCH FROM (NOW() - c.published_at)/86400) AS final_score
FROM content c
JOIN content_types ct ON c.content_type_id = ct.content_type_id
JOIN users u ON c.author_id = u.user_id
LEFT JOIN content_performance_metrics pm ON c.content_id = pm.content_id
    AND pm.time_period = 'daily'
    AND pm.period_start = CURRENT_DATE
WHERE c.status = 'published'
ORDER BY final_score DESC
LIMIT 100;
