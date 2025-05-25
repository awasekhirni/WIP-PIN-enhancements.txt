-- Awase Khirni Syed Copyright 2025  β ORI Inc. March 2025.
-- PostgreSQL Professional Network Schema (Enhanced Version)
-- This schema has been improved to address various issues and incorporate enhancements

CREATE SCHEMA public;
GRANT USAGE, CREATE ON SCHEMA public TO awasekhirnisyed;
SELECT tablename
FROM pg_catalog.pg_tables
WHERE schemaname = 'public';


SET search_path TO public;
ALTER ROLE awasekhirnisyed SET search_path TO public;

SET
statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


-- Conditionally enable pg_cron if available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron') THEN
        CREATE EXTENSION IF NOT EXISTS pg_cron;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_cron extension not available. Scheduled tasks will not be created.';
END $$;

-- Create industries table (previously missing)
CREATE TABLE public.industries (
    industry_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.industries IS 'Lookup table for industry classifications';

-- Create roles table (previously missing)
CREATE TABLE public.roles (
    role_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(50) NOT NULL UNIQUE,
    description text,
    permissions jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.roles IS 'User roles for authorization and access control';

-- Insert default roles
INSERT INTO public.roles (name, description, permissions) VALUES
('admin', 'Administrator with full system access', '{"all": true}'),
('user', 'Standard user', '{"profile": true, "connections": true, "content": true}'),
('moderator', 'Content moderator', '{"profile": true, "connections": true, "content": true, "moderation": true}'),
('employer', 'Employer with company management access', '{"profile": true, "connections": true, "content": true, "jobs": true, "company": true}');

-- Create current_user_id function (previously missing)
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS uuid AS $$
DECLARE
    user_id uuid;
BEGIN
    -- Get user_id from session variable or current setting
    user_id := current_setting('app.current_user_id', true)::uuid;
    RETURN user_id;
EXCEPTION
    WHEN OTHERS THEN
        -- Return NULL if not set or invalid
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.current_user_id() IS 'Returns the UUID of the currently authenticated user';

-- Create automatic timestamp update function
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_timestamp() IS 'Automatically updates the updated_at timestamp column';

-- Core Tables (3NF Compliant)
CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    email varchar(255) NOT NULL UNIQUE,
    email_encrypted bytea,
    phone varchar(50),
    phone_encrypted bytea,
    password_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    last_updated_by uuid,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    account_locked boolean DEFAULT false,
    failed_login_attempts integer DEFAULT 0,
    password_reset_token uuid,
    password_reset_expires timestamp with time zone,
    email_verified boolean DEFAULT false,
    email_verification_token uuid,
    mfa_enabled boolean DEFAULT false,
    mfa_secret text
);

COMMENT ON TABLE public.users IS 'Core user accounts with authentication data';

-- Create trigger for updated_at
CREATE TRIGGER update_users_timestamp
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- User Roles junction table
CREATE TABLE public.user_roles (
    user_role_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    role_id integer NOT NULL REFERENCES public.roles(role_id) ON DELETE RESTRICT,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    assigned_by uuid REFERENCES public.users(user_id),
    expires_at timestamp with time zone,
    is_active boolean DEFAULT true,
    CONSTRAINT unique_user_role UNIQUE (user_id, role_id)
);

COMMENT ON TABLE public.user_roles IS 'Junction table linking users to their assigned roles';

-- User History Table (Temporal Data)
CREATE TABLE public.users_history (
    history_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL,
    email varchar(255),
    password_hash text,
    is_active boolean,
    valid_from timestamp with time zone NOT NULL,
    valid_to timestamp with time zone,
    changed_by uuid,
    change_reason text,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

COMMENT ON TABLE public.users_history IS 'Historical record of user account changes for audit purposes';

CREATE INDEX idx_users_history_user_id ON public.users_history(user_id);
CREATE INDEX idx_users_history_valid_range ON public.users_history(valid_from, valid_to);

CREATE TABLE public.user_profiles (
    profile_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    first_name varchar(100),
    last_name varchar(100),
    full_name varchar(255) GENERATED ALWAYS AS (
        CASE
            WHEN first_name IS NULL AND last_name IS NULL THEN NULL
            WHEN first_name IS NULL THEN last_name
            WHEN last_name IS NULL THEN first_name
            ELSE first_name || ' ' || last_name
        END
    ) STORED,
    profile_summary text,
    headline varchar(255),
    location_country varchar(100),
    location_state varchar(100),
    location_city varchar(100),
    language_preference varchar(10) DEFAULT 'en',
    profile_visibility varchar(50) DEFAULT 'public',
    is_profile_approved boolean DEFAULT false,
    industry_id integer REFERENCES public.industries(industry_id),
    is_verified_influencer boolean DEFAULT false,
    availability text,
    profile_picture_url text,
    background_image_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    search_vector tsvector,
    CONSTRAINT profile_visibility_check CHECK (profile_visibility IN ('public', 'connections', 'private'))
);

COMMENT ON TABLE public.user_profiles IS 'Extended user profile information';

-- Create trigger for updated_at
CREATE TRIGGER update_user_profiles_timestamp
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Search optimization
CREATE INDEX idx_user_profiles_search ON public.user_profiles USING gin(search_vector);
CREATE INDEX idx_user_profiles_industry ON public.user_profiles(industry_id);
CREATE INDEX idx_user_profiles_location ON public.user_profiles(location_country, location_state, location_city);

-- Professional Network (Partitioned)
CREATE TABLE public.user_connections (
    connection_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    connected_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    connection_status varchar(50) DEFAULT 'pending',
    connection_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_interaction_date timestamp with time zone,
    connection_strength integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT connection_status_check CHECK (connection_status IN ('pending', 'accepted', 'rejected', 'blocked')),
    CONSTRAINT no_self_connection CHECK (user_id <> connected_user_id),
    CONSTRAINT unique_connection UNIQUE (user_id, connected_user_id, connection_date)
) PARTITION BY RANGE (connection_date);

COMMENT ON TABLE public.user_connections IS 'Network connections between users with partitioning by date';


-- Create function to generate partitions automatically
CREATE OR REPLACE FUNCTION public.create_connection_partition(year int)
RETURNS void AS $$
DECLARE
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_name := 'user_connections_y' || year;
    start_date := year || '-01-01';
    end_date := (year + 1) || '-01-01';

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I
        PARTITION OF public.user_connections
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);

    -- Create indexes on the partition
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_user_id
        ON public.%I(user_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_connected_user_id
        ON public.%I(connected_user_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_status
        ON public.%I(connection_status)
        WHERE connection_status = ''accepted''
    ', partition_name, partition_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_connection_partition(int) IS 'Creates a yearly partition for user_connections table';

-- Create partitions for current and next year
SELECT public.create_connection_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int);
SELECT public.create_connection_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

-- Create default partition
CREATE TABLE public.user_connections_default PARTITION OF public.user_connections DEFAULT;

CREATE INDEX idx_user_connections_default_user_id ON public.user_connections_default(user_id);
CREATE INDEX idx_user_connections_default_connected_user_id ON public.user_connections_default(connected_user_id);
CREATE INDEX idx_user_connections_default_status ON public.user_connections_default(connection_status)
    WHERE connection_status = 'accepted';

CREATE TABLE public.profile_visits (
    visit_id uuid DEFAULT gen_random_uuid() NOT NULL,
    visitor_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    profile_id uuid NOT NULL REFERENCES public.user_profiles(profile_id) ON DELETE CASCADE,
    visit_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    visit_duration interval,
    visit_source varchar(255),
    visit_purpose varchar(50),
    is_reported boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (visit_id, visit_timestamp),
    CONSTRAINT visit_purpose_check CHECK (visit_purpose IN ('networking', 'job_application', 'mentorship', 'general_interest', 'other'))
) PARTITION BY RANGE (visit_timestamp);

COMMENT ON TABLE public.profile_visits IS 'Record of user profile visits with partitioning by date';

-- Create function to generate profile visit partitions automatically
CREATE OR REPLACE FUNCTION public.create_profile_visit_partition(year int)
RETURNS void AS $$
DECLARE
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_name := 'profile_visits_y' || year;
    start_date := year || '-01-01';
    end_date := (year + 1) || '-01-01';

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I
        PARTITION OF public.profile_visits
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);

    -- Create indexes on the partition
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_visitor_id
        ON public.%I(visitor_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_profile_id
        ON public.%I(profile_id)
    ', partition_name, partition_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_profile_visit_partition(int) IS 'Creates a yearly partition for profile_visits table';

-- Create partitions for current and next year
SELECT public.create_profile_visit_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int);
SELECT public.create_profile_visit_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

-- Create default partition
CREATE TABLE public.profile_visits_default PARTITION OF public.profile_visits DEFAULT;

CREATE INDEX idx_profile_visits_default_visitor_id ON public.profile_visits_default(visitor_id);
CREATE INDEX idx_profile_visits_default_profile_id ON public.profile_visits_default(profile_id);

-- Skills and Endorsements
CREATE TABLE public.skill_categories (
    category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    parent_category_id integer REFERENCES public.skill_categories(category_id),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.skill_categories IS 'Hierarchical categories for skills';

CREATE TRIGGER update_skill_categories_timestamp
BEFORE UPDATE ON public.skill_categories
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.skills (
    skill_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    category_id integer REFERENCES public.skill_categories(category_id),
    description text,
    is_verified boolean DEFAULT false,
    popularity_score integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.skills IS 'Skills that can be added to user profiles';

CREATE TRIGGER update_skills_timestamp
BEFORE UPDATE ON public.skills
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_skills_category ON public.skills(category_id);
CREATE INDEX idx_skills_popularity ON public.skills(popularity_score DESC);

CREATE TABLE public.user_skills (
    user_skill_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    skill_id integer NOT NULL REFERENCES public.skills(skill_id) ON DELETE RESTRICT,
    experience_years numeric(4,1),
    proficiency_level varchar(50),
    last_used_date date,
    is_highlighted boolean DEFAULT false,
    endorsement_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_skill UNIQUE (user_id, skill_id),
    CONSTRAINT proficiency_level_check CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'expert'))
);

COMMENT ON TABLE public.user_skills IS 'Skills associated with user profiles';

CREATE TRIGGER update_user_skills_timestamp
BEFORE UPDATE ON public.user_skills
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_user_skills_user_id ON public.user_skills(user_id);
CREATE INDEX idx_user_skills_skill_id ON public.user_skills(skill_id);

CREATE TABLE public.skill_endorsements (
    endorsement_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_skill_id uuid NOT NULL REFERENCES public.user_skills(user_skill_id) ON DELETE CASCADE,
    endorsed_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    comment text,
    endorsed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    relationship varchar(50),
    weight integer DEFAULT 1,
    CONSTRAINT relationship_check CHECK (relationship IN ('colleague', 'manager', 'client', 'peer', 'other'))
);

COMMENT ON TABLE public.skill_endorsements IS 'Endorsements of user skills by other users';

-- Fix the problematic subquery in the CHECK constraint with a trigger
CREATE OR REPLACE FUNCTION public.validate_endorsement()
RETURNS TRIGGER AS $$
DECLARE
    skill_owner uuid;
BEGIN
    -- Get the user_id of the skill owner
    SELECT user_id INTO skill_owner
    FROM public.user_skills
    WHERE user_skill_id = NEW.user_skill_id;

    -- Check if the endorser is not the skill owner
    IF skill_owner = NEW.endorsed_by THEN
        RAISE EXCEPTION 'Users cannot endorse their own skills';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.validate_endorsement() IS 'Prevents users from endorsing their own skills';

CREATE TRIGGER check_self_endorsement
BEFORE INSERT OR UPDATE ON public.skill_endorsements
FOR EACH ROW EXECUTE FUNCTION public.validate_endorsement();

CREATE INDEX idx_skill_endorsements_user_skill_id ON public.skill_endorsements(user_skill_id);
CREATE INDEX idx_skill_endorsements_endorsed_by ON public.skill_endorsements(endorsed_by);

-- Content System
CREATE TABLE public.content_types (
    content_type_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(50) NOT NULL UNIQUE,
    description text,
    allowed_formats text[],
    max_size_kb integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.content_types IS 'Types of content that can be created by users';

CREATE TRIGGER update_content_types_timestamp
BEFORE UPDATE ON public.content_types
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default content types
INSERT INTO public.content_types (name, description, allowed_formats, max_size_kb) VALUES
('article', 'Long-form written content', ARRAY['text/html', 'text/markdown'], 100000),
('post', 'Short-form status update', ARRAY['text/plain', 'text/html'], 5000),
('image', 'Image content', ARRAY['image/jpeg', 'image/png', 'image/gif'], 10000),
('video', 'Video content', ARRAY['video/mp4', 'video/quicktime'], 500000),
('document', 'Uploaded document', ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'], 50000);

CREATE TABLE public.content_categories (
    category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    parent_category_id integer REFERENCES public.content_categories(category_id),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.content_categories IS 'Categories for organizing content';

CREATE TRIGGER update_content_categories_timestamp
BEFORE UPDATE ON public.content_categories
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.contents (
    content_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_type_id integer NOT NULL REFERENCES public.content_types(content_type_id) ON DELETE RESTRICT,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    body text NOT NULL,
    summary text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    published_at timestamp with time zone,
    visibility varchar(50) DEFAULT 'public',
    status varchar(50) DEFAULT 'draft',
    version integer DEFAULT 1,
    search_vector tsvector,
    CONSTRAINT visibility_check CHECK (visibility IN ('public', 'connections', 'private')),
    CONSTRAINT status_check CHECK (status IN ('draft', 'published', 'archived', 'flagged'))
);

COMMENT ON TABLE public.contents IS 'User-generated content such as articles, posts, and updates';

CREATE TRIGGER update_contents_timestamp
BEFORE UPDATE ON public.contents
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_contents_search ON public.contents USING gin(search_vector);
CREATE INDEX idx_contents_user_id ON public.contents(user_id);
CREATE INDEX idx_contents_type_id ON public.contents(content_type_id);
CREATE INDEX idx_contents_status ON public.contents(status, visibility)
    WHERE status = 'published' AND visibility = 'public';

CREATE TABLE public.content_categories_map (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    category_id integer NOT NULL REFERENCES public.content_categories(category_id) ON DELETE RESTRICT,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_content_category UNIQUE (content_id, category_id)
);

COMMENT ON TABLE public.content_categories_map IS 'Junction table mapping content to categories';

CREATE INDEX idx_content_categories_map_content_id ON public.content_categories_map(content_id);
CREATE INDEX idx_content_categories_map_category_id ON public.content_categories_map(category_id);

CREATE TABLE public.content_versions (
    version_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    version_number integer NOT NULL,
    title varchar(255) NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE RESTRICT,
    change_summary text,
    CONSTRAINT unique_content_version UNIQUE (content_id, version_number)
);

COMMENT ON TABLE public.content_versions IS 'Historical versions of content for tracking changes';

CREATE INDEX idx_content_versions_content_id ON public.content_versions(content_id);

-- Job System
CREATE TABLE public.companies (
    company_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name varchar(255) NOT NULL UNIQUE,
    description text,
    website_url varchar(255),
    headquarters_country varchar(100),
    headquarters_state varchar(100),
    headquarters_city varchar(100),
    founded_year integer,
    company_size varchar(50),
    revenue varchar(100),
    industry_id integer REFERENCES public.industries(industry_id) ON DELETE SET NULL,
    logo_url text,
    banner_url text,
    overall_rating numeric(3,2),
    is_verified boolean DEFAULT false,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    search_vector tsvector,
    CONSTRAINT company_size_check CHECK (company_size IN (
        '1-10', '11-50', '51-200', '201-500', '501-1000', '1001-5000', '5001-10000', '10001+'
    ))
);

COMMENT ON TABLE public.companies IS 'Company profiles for employers and organizations';

CREATE TRIGGER update_companies_timestamp
BEFORE UPDATE ON public.companies
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_companies_industry_id ON public.companies(industry_id);
CREATE INDEX idx_companies_search ON public.companies USING gin(search_vector);
CREATE INDEX idx_companies_location ON public.companies(headquarters_country, headquarters_state, headquarters_city);

CREATE TABLE public.company_admins (
    admin_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    role varchar(50) DEFAULT 'admin',
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_admin UNIQUE (company_id, user_id),
    CONSTRAINT admin_role_check CHECK (role IN ('owner', 'admin', 'editor', 'analyst'))
);

COMMENT ON TABLE public.company_admins IS 'Users with administrative access to company profiles';

CREATE TRIGGER update_company_admins_timestamp
BEFORE UPDATE ON public.company_admins
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_company_admins_company_id ON public.company_admins(company_id);
CREATE INDEX idx_company_admins_user_id ON public.company_admins(user_id);

CREATE TABLE public.job_types (
    job_type_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(50) NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.job_types IS 'Types of employment for job listings';

CREATE TRIGGER update_job_types_timestamp
BEFORE UPDATE ON public.job_types
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default job types
INSERT INTO public.job_types (name, description) VALUES
('full-time', 'Standard full-time employment'),
('part-time', 'Part-time employment with reduced hours'),
('contract', 'Fixed-term contract employment'),
('freelance', 'Independent contractor or freelance work'),
('internship', 'Temporary position for students or trainees'),
('apprenticeship', 'Combination of on-the-job training and education'),
('volunteer', 'Unpaid volunteer position'),
('temporary', 'Short-term temporary employment');

CREATE TABLE public.job_listings (
    job_listing_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    posted_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE RESTRICT,
    title varchar(255) NOT NULL,
    description text NOT NULL,
    responsibilities text,
    qualifications text,
    benefits text,
    location_country varchar(100),
    location_state varchar(100),
    location_city varchar(100),
    is_remote boolean DEFAULT false,
    job_type_id integer NOT NULL REFERENCES public.job_types(job_type_id) ON DELETE RESTRICT,
    salary_min numeric(12,2),
    salary_max numeric(12,2),
    salary_currency varchar(3) DEFAULT 'USD',
    salary_period varchar(20) DEFAULT 'yearly',
    posted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    application_deadline timestamp with time zone,
    is_active boolean DEFAULT true,
    views_count integer DEFAULT 0,
    applications_count integer DEFAULT 0,
    experience_level varchar(50),
    education_level varchar(50),
    search_vector tsvector,
    CONSTRAINT salary_range_check CHECK (salary_max >= salary_min),
    CONSTRAINT salary_period_check CHECK (salary_period IN ('hourly', 'daily', 'weekly', 'monthly', 'yearly')),
    CONSTRAINT experience_level_check CHECK (experience_level IN (
        'entry', 'junior', 'mid-level', 'senior', 'executive', 'not-specified'
    )),
    CONSTRAINT education_level_check CHECK (education_level IN (
        'high-school', 'associate', 'bachelor', 'master', 'doctorate', 'certification', 'not-specified'
    ))
);

COMMENT ON TABLE public.job_listings IS 'Job postings from companies';

CREATE TRIGGER update_job_listings_timestamp
BEFORE UPDATE ON public.job_listings
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_job_listings_search ON public.job_listings USING gin(search_vector);
CREATE INDEX idx_job_listings_company_id ON public.job_listings(company_id);
CREATE INDEX idx_job_listings_job_type_id ON public.job_listings(job_type_id);
CREATE INDEX idx_job_listings_location ON public.job_listings(location_country, location_state, location_city);
CREATE INDEX idx_job_listings_active ON public.job_listings(job_listing_id)
    WHERE is_active = true;

CREATE INDEX idx_job_listings_remote ON public.job_listings(is_remote) WHERE is_remote = true;

CREATE TABLE public.job_applications (
    application_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    job_listing_id uuid NOT NULL REFERENCES public.job_listings(job_listing_id) ON DELETE CASCADE,
    applicant_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    resume_url text,
    cover_letter text,
    application_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'submitted',
    last_status_change timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    is_withdrawn boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_job_application UNIQUE (job_listing_id, applicant_id),
    CONSTRAINT application_status_check CHECK (status IN (
        'submitted', 'reviewed', 'interviewing', 'offered', 'hired', 'rejected', 'withdrawn'
    ))
);

COMMENT ON TABLE public.job_applications IS 'Applications submitted by users for job listings';

CREATE TRIGGER update_job_applications_timestamp
BEFORE UPDATE ON public.job_applications
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_job_applications_job_listing_id ON public.job_applications(job_listing_id);
CREATE INDEX idx_job_applications_applicant_id ON public.job_applications(applicant_id);
CREATE INDEX idx_job_applications_status ON public.job_applications(status);

-- HR System
CREATE TABLE public.employees (
    employee_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL UNIQUE REFERENCES public.users(user_id) ON DELETE RESTRICT,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    employee_number varchar(50),
    department varchar(255),
    job_title varchar(255),
    date_of_joining date NOT NULL,
    employment_status varchar(50) DEFAULT 'active',
    manager_id uuid REFERENCES public.employees(employee_id),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT employment_status_check CHECK (employment_status IN ('active', 'inactive', 'on_leave', 'terminated'))
);

COMMENT ON TABLE public.employees IS 'Employee records for HR management';

CREATE TRIGGER update_employees_timestamp
BEFORE UPDATE ON public.employees
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_employees_company_id ON public.employees(company_id);
CREATE INDEX idx_employees_manager_id ON public.employees(manager_id);
CREATE INDEX idx_employees_department ON public.employees(department);

CREATE TABLE public.attendance (
    attendance_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL REFERENCES public.employees(employee_id) ON DELETE CASCADE,
    check_in_time timestamp with time zone NOT NULL,
    check_out_time timestamp with time zone,
    status varchar(50) DEFAULT 'present',
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id, check_in_time),
    CONSTRAINT attendance_status_check CHECK (status IN ('present', 'absent', 'late', 'half_day', 'on_leave')),
    CONSTRAINT valid_time_range CHECK (check_out_time IS NULL OR check_out_time > check_in_time)
) PARTITION BY RANGE (check_in_time);



-- Create function to generate attendance partitions automatically
CREATE OR REPLACE FUNCTION public.create_attendance_partition(year int)
RETURNS void AS $$
DECLARE
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_name := 'attendance_y' || year;
    start_date := year || '-01-01';
    end_date := (year + 1) || '-01-01';

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I
        PARTITION OF public.attendance
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);

    -- Create indexes on the partition
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_employee_id
        ON public.%I(employee_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_status
        ON public.%I(status)
    ', partition_name, partition_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_attendance_partition(int) IS 'Creates a yearly partition for attendance table';

-- Create partitions for current and next year
SELECT public.create_attendance_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int);
SELECT public.create_attendance_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

-- Create default partition
CREATE TABLE public.attendance_default PARTITION OF public.attendance DEFAULT;

CREATE INDEX idx_attendance_default_employee_id ON public.attendance_default(employee_id);
CREATE INDEX idx_attendance_default_status ON public.attendance_default(status);

-- ======================
-- Review Features
-- ======================

-- Company Reviews
CREATE TABLE public.company_reviews (
    review_id uuid NOT NULL,
    review_date date NOT NULL DEFAULT CURRENT_DATE,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    job_title varchar(255) NOT NULL,
    employment_status varchar(50) NOT NULL,
    overall_rating smallint NOT NULL,
    work_life_balance smallint,
    culture_values smallint,
    career_opportunities smallint,
    compensation_benefits smallint,
    senior_management smallint,
    pros text,
    cons text,
    advice_to_management text,
    is_current_employee boolean NOT NULL,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    PRIMARY KEY (review_id, review_date),
    CONSTRAINT rating_range CHECK (
        overall_rating BETWEEN 1 AND 5 AND
        (work_life_balance IS NULL OR work_life_balance BETWEEN 1 AND 5) AND
        (culture_values IS NULL OR culture_values BETWEEN 1 AND 5) AND
        (career_opportunities IS NULL OR career_opportunities BETWEEN 1 AND 5) AND
        (compensation_benefits IS NULL OR compensation_benefits BETWEEN 1 AND 5) AND
        (senior_management IS NULL OR senior_management BETWEEN 1 AND 5)
    ),
    CONSTRAINT employment_status_check CHECK (employment_status IN (
        'current', 'former', 'contractor', 'intern', 'freelance'
    )),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
) PARTITION BY RANGE (review_date);

COMMENT ON TABLE public.company_reviews IS 'User reviews of companies with partitioning by date';


CREATE TRIGGER update_company_reviews_timestamp
BEFORE UPDATE ON public.company_reviews
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Create function to generate company review partitions automatically
CREATE OR REPLACE FUNCTION public.create_company_review_partition(year int)
RETURNS void AS $$
DECLARE
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_name := 'company_reviews_y' || year;
    start_date := year || '-01-01';
    end_date := (year + 1) || '-01-01';

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I
        PARTITION OF public.company_reviews
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);

    -- Create indexes on the partition
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_company_id
        ON public.%I(company_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_user_id
        ON public.%I(user_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_approval_status
        ON public.%I(approval_status)
        WHERE approval_status = ''approved''
    ', partition_name, partition_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_company_review_partition(int) IS 'Creates a yearly partition for company_reviews table';

-- Create partitions for current and next year
SELECT public.create_company_review_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int);
SELECT public.create_company_review_partition(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1);

-- Create default partition
CREATE TABLE public.company_reviews_default PARTITION OF public.company_reviews DEFAULT;

CREATE INDEX idx_company_reviews_default_company_id ON public.company_reviews_default(company_id);
CREATE INDEX idx_company_reviews_default_user_id ON public.company_reviews_default(user_id);
CREATE INDEX idx_company_reviews_default_approval_status ON public.company_reviews_default(approval_status)
    WHERE approval_status = 'approved';

-- Manager Reviews
CREATE TABLE public.manager_reviews (
    review_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    manager_id uuid NOT NULL REFERENCES public.employees(employee_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    job_title varchar(255) NOT NULL,
    employment_status varchar(50) NOT NULL,
    review_date date NOT NULL DEFAULT CURRENT_DATE,
    overall_rating smallint NOT NULL,
    communication smallint,
    leadership smallint,
    supportiveness smallint,
    fairness smallint,
    feedback_quality smallint,
    pros text,
    cons text,
    advice_to_manager text,
    is_current_employee boolean NOT NULL,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT rating_range CHECK (
        overall_rating BETWEEN 1 AND 5 AND
        (communication IS NULL OR communication BETWEEN 1 AND 5) AND
        (leadership IS NULL OR leadership BETWEEN 1 AND 5) AND
        (supportiveness IS NULL OR supportiveness BETWEEN 1 AND 5) AND
        (fairness IS NULL OR fairness BETWEEN 1 AND 5) AND
        (feedback_quality IS NULL OR feedback_quality BETWEEN 1 AND 5)
    ),
    CONSTRAINT employment_status_check CHECK (employment_status IN (
        'current', 'former', 'contractor', 'intern', 'freelance'
    )),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
);

COMMENT ON TABLE public.manager_reviews IS 'User reviews of managers';

CREATE TRIGGER update_manager_reviews_timestamp
BEFORE UPDATE ON public.manager_reviews
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_manager_reviews_manager_id ON public.manager_reviews(manager_id);
CREATE INDEX idx_manager_reviews_company_id ON public.manager_reviews(company_id);
CREATE INDEX idx_manager_reviews_user_id ON public.manager_reviews(user_id);
CREATE INDEX idx_manager_reviews_approval_status ON public.manager_reviews(approval_status)
    WHERE approval_status = 'approved';

-- Interview Experiences
CREATE TABLE public.interview_experiences (
    experience_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    job_title varchar(255) NOT NULL,
    interview_date date,
    offer_status varchar(50) NOT NULL,
    difficulty smallint,
    interview_duration smallint, -- in days
    interview_process text,
    questions_asked text,
    interview_outcome text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    CONSTRAINT difficulty_check CHECK (difficulty BETWEEN 1 AND 5),
    CONSTRAINT offer_status_check CHECK (offer_status IN (
        'accepted', 'declined', 'no_offer', 'negotiating', 'pending'
    )),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
);

COMMENT ON TABLE public.interview_experiences IS 'User-reported interview experiences';

CREATE TRIGGER update_interview_experiences_timestamp
BEFORE UPDATE ON public.interview_experiences
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_interview_experiences_company_id ON public.interview_experiences(company_id);
CREATE INDEX idx_interview_experiences_user_id ON public.interview_experiences(user_id);
CREATE INDEX idx_interview_experiences_approval_status ON public.interview_experiences(approval_status)
    WHERE approval_status = 'approved';

-- Salary Reports
CREATE TABLE public.salary_reports (
    report_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid REFERENCES public.companies(company_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    job_title varchar(255) NOT NULL,
    base_salary numeric(12,2) NOT NULL,
    bonus numeric(12,2),
    stock_options numeric(12,2),
    profit_sharing numeric(12,2),
    commission numeric(12,2),
    total_compensation numeric(12,2) GENERATED ALWAYS AS (
        base_salary + COALESCE(bonus, 0) + COALESCE(stock_options, 0) +
        COALESCE(profit_sharing, 0) + COALESCE(commission, 0)
    ) STORED,
    currency varchar(3) DEFAULT 'USD',
    years_experience smallint NOT NULL,
    years_at_company smallint,
    location_country varchar(100),
    location_state varchar(100),
    location_city varchar(100),
    employment_status varchar(50) NOT NULL,
    report_date date NOT NULL DEFAULT CURRENT_DATE,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT employment_status_check CHECK (employment_status IN (
        'full_time', 'part_time', 'contract', 'intern', 'freelance'
    )),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
);

COMMENT ON TABLE public.salary_reports IS 'User-reported salary information';

CREATE TRIGGER update_salary_reports_timestamp
BEFORE UPDATE ON public.salary_reports
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_salary_reports_company_id ON public.salary_reports(company_id);
CREATE INDEX idx_salary_reports_user_id ON public.salary_reports(user_id);
CREATE INDEX idx_salary_reports_job_title ON public.salary_reports(job_title);
CREATE INDEX idx_salary_reports_location ON public.salary_reports(location_country, location_state, location_city);
CREATE INDEX idx_salary_reports_approval_status ON public.salary_reports(approval_status)
    WHERE approval_status = 'approved';

-- Benefits Information
CREATE TABLE public.benefit_types (
    benefit_type_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    category varchar(50) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT category_check CHECK (category IN (
        'health', 'financial', 'time_off', 'professional', 'lifestyle', 'other'
    ))
);

COMMENT ON TABLE public.benefit_types IS 'Types of employee benefits';

CREATE TRIGGER update_benefit_types_timestamp
BEFORE UPDATE ON public.benefit_types
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default benefit types
INSERT INTO public.benefit_types (name, category, description) VALUES
('health_insurance', 'health', 'Medical, dental, and vision insurance'),
('retirement_plan', 'financial', '401(k), pension, or other retirement savings plans'),
('paid_time_off', 'time_off', 'Vacation, sick leave, and personal days'),
('parental_leave', 'time_off', 'Maternity, paternity, and adoption leave'),
('flexible_work', 'lifestyle', 'Remote work options and flexible schedules'),
('professional_development', 'professional', 'Training, education, and career advancement opportunities'),
('wellness_program', 'health', 'Fitness programs, mental health support, and wellness initiatives');

CREATE TABLE public.company_benefits (
    benefit_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    benefit_type_id integer NOT NULL REFERENCES public.benefit_types(benefit_type_id) ON DELETE RESTRICT,
    benefit_description text,
    is_offered boolean NOT NULL,
    last_verified date,
    verified_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_benefit UNIQUE (company_id, benefit_type_id)
);

COMMENT ON TABLE public.company_benefits IS 'Benefits offered by companies';

CREATE TRIGGER update_company_benefits_timestamp
BEFORE UPDATE ON public.company_benefits
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_company_benefits_company_id ON public.company_benefits(company_id);
CREATE INDEX idx_company_benefits_benefit_type_id ON public.company_benefits(benefit_type_id);

-- Office Photos
CREATE TABLE public.office_photos (
    photo_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    thumbnail_url text,
    caption text,
    photo_date date,
    photo_type varchar(50) DEFAULT 'office',
    is_featured boolean DEFAULT false,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT photo_type_check CHECK (photo_type IN (
        'office', 'event', 'team', 'product', 'other'
    )),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
);

COMMENT ON TABLE public.office_photos IS 'Photos of company offices and workspaces';

CREATE TRIGGER update_office_photos_timestamp
BEFORE UPDATE ON public.office_photos
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_office_photos_company_id ON public.office_photos(company_id);
CREATE INDEX idx_office_photos_user_id ON public.office_photos(user_id);
CREATE INDEX idx_office_photos_approval_status ON public.office_photos(approval_status)
    WHERE approval_status = 'approved';

-- Company Awards
CREATE TABLE public.company_awards (
    award_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    award_name varchar(255) NOT NULL,
    awarding_organization varchar(255),
    award_year smallint NOT NULL,
    award_category varchar(255),
    description text,
    logo_url text,
    is_verified boolean DEFAULT false,
    verified_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.company_awards IS 'Awards and recognitions received by companies';

CREATE TRIGGER update_company_awards_timestamp
BEFORE UPDATE ON public.company_awards
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_company_awards_company_id ON public.company_awards(company_id);
CREATE INDEX idx_company_awards_award_year ON public.company_awards(award_year DESC);

-- CEO Ratings
CREATE TABLE public.company_executives (
    executive_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    name varchar(255) NOT NULL,
    title varchar(255) NOT NULL,
    is_current boolean DEFAULT true NOT NULL,
    start_date date NOT NULL,
    end_date date,
    bio text,
    photo_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT date_check CHECK (
        (end_date IS NULL AND is_current = true) OR 
        (end_date IS NOT NULL AND end_date >= start_date AND is_current = false)
    ),
    CONSTRAINT valid_executive_period CHECK (
        (is_current = true AND end_date IS NULL) OR
        (is_current = false AND end_date IS NOT NULL)
    )
);

-- Create a partial unique index instead of a constraint with WHERE clause
CREATE UNIQUE INDEX unique_current_executive ON public.company_executives (company_id, title)
WHERE is_current = true;
COMMENT ON TABLE public.company_executives IS 'Executive leadership of companies';

CREATE TRIGGER update_company_executives_timestamp
BEFORE UPDATE ON public.company_executives
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_company_executives_company_id ON public.company_executives(company_id);

CREATE TABLE public.executive_ratings (
    rating_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    executive_id uuid NOT NULL REFERENCES public.company_executives(executive_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    approval_rating smallint NOT NULL,
    rating_date date NOT NULL DEFAULT CURRENT_DATE,
    comment text,
    is_current_employee boolean NOT NULL,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT rating_check CHECK (approval_rating BETWEEN 1 AND 100),
    CONSTRAINT approval_status_check CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'flagged'
    ))
);

COMMENT ON TABLE public.executive_ratings IS 'User ratings of company executives';

CREATE TRIGGER update_executive_ratings_timestamp
BEFORE UPDATE ON public.executive_ratings
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_executive_ratings_executive_id ON public.executive_ratings(executive_id);
CREATE INDEX idx_executive_ratings_user_id ON public.executive_ratings(user_id);
CREATE INDEX idx_executive_ratings_approval_status ON public.executive_ratings(approval_status)
    WHERE approval_status = 'approved';

-- Company Statistics (Aggregated Data)
CREATE TABLE public.company_statistics (
    stat_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    stat_date date NOT NULL DEFAULT CURRENT_DATE,
    average_rating numeric(3,2),
    recommend_to_friend_percent numeric(5,2),
    executive_approval_percent numeric(5,2),
    total_reviews integer DEFAULT 0,
    total_salaries integer DEFAULT 0,
    total_interviews integer DEFAULT 0,
    total_photos integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_date UNIQUE (company_id, stat_date)
);

COMMENT ON TABLE public.company_statistics IS 'Aggregated statistics about companies';

CREATE TRIGGER update_company_statistics_timestamp
BEFORE UPDATE ON public.company_statistics
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_company_statistics_company_id ON public.company_statistics(company_id);
CREATE INDEX idx_company_statistics_stat_date ON public.company_statistics(stat_date DESC);

-- Manager Statistics (Aggregated Data)
CREATE TABLE public.manager_statistics (
    stat_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    manager_id uuid NOT NULL REFERENCES public.employees(employee_id) ON DELETE CASCADE,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    stat_date date NOT NULL DEFAULT CURRENT_DATE,
    average_rating numeric(3,2),
    communication_rating numeric(3,2),
    leadership_rating numeric(3,2),
    supportiveness_rating numeric(3,2),
    fairness_rating numeric(3,2),
    feedback_quality_rating numeric(3,2),
    total_reviews integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_manager_date UNIQUE (manager_id, stat_date)
);

COMMENT ON TABLE public.manager_statistics IS 'Aggregated statistics about managers';

CREATE TRIGGER update_manager_statistics_timestamp
BEFORE UPDATE ON public.manager_statistics
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_manager_statistics_manager_id ON public.manager_statistics(manager_id);
CREATE INDEX idx_manager_statistics_company_id ON public.manager_statistics(company_id);
CREATE INDEX idx_manager_statistics_stat_date ON public.manager_statistics(stat_date DESC);

-- Helpfulness Tracking
CREATE TABLE public.content_helpfulness (
    helpfulness_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_type varchar(50) NOT NULL,
    content_id uuid NOT NULL,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    is_helpful boolean NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_content_user UNIQUE (content_type, content_id, user_id),
    CONSTRAINT content_type_check CHECK (content_type IN (
        'company_review', 'manager_review', 'salary_report', 'interview_experience'
    ))
);

COMMENT ON TABLE public.content_helpfulness IS 'User feedback on the helpfulness of content';

CREATE TRIGGER update_content_helpfulness_timestamp
BEFORE UPDATE ON public.content_helpfulness
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_content_helpfulness_content ON public.content_helpfulness(content_type, content_id);
CREATE INDEX idx_content_helpfulness_user_id ON public.content_helpfulness(user_id);

-- GDPR Compliance Tables
CREATE TABLE public.data_subjects (
    subject_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    is_eu_citizen boolean DEFAULT false,
    data_protection_officer_contact uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    consent_version varchar(50),
    privacy_settings jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.data_subjects IS 'GDPR data subject information';

CREATE TRIGGER update_data_subjects_timestamp
BEFORE UPDATE ON public.data_subjects
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_subjects_user_id ON public.data_subjects(user_id);

CREATE TABLE public.data_processing_purposes (
    purpose_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.data_processing_purposes IS 'Purposes for data processing under GDPR';

CREATE TRIGGER update_data_processing_purposes_timestamp
BEFORE UPDATE ON public.data_processing_purposes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default processing purposes
INSERT INTO public.data_processing_purposes (name, description) VALUES
('account_management', 'Processing necessary for user account creation and management'),
('content_delivery', 'Processing necessary to deliver content and services'),
('analytics', 'Processing for analytics and service improvement'),
('marketing', 'Processing for marketing and promotional communications'),
('legal_compliance', 'Processing required for legal and regulatory compliance');

CREATE TABLE public.data_categories (
    category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text NOT NULL,
    sensitivity_level varchar(50) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT sensitivity_level_check CHECK (sensitivity_level IN (
        'basic', 'personal', 'sensitive', 'special_category'
    ))
);

COMMENT ON TABLE public.data_categories IS 'Categories of personal data under GDPR';

CREATE TRIGGER update_data_categories_timestamp
BEFORE UPDATE ON public.data_categories
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default data categories
INSERT INTO public.data_categories (name, description, sensitivity_level) VALUES
('contact_info', 'Basic contact information like email and phone', 'personal'),
('account_data', 'Account credentials and settings', 'personal'),
('profile_data', 'Professional profile information', 'personal'),
('usage_data', 'Service usage patterns and behavior', 'basic'),
('location_data', 'Geographic location information', 'personal'),
('special_category_data', 'Special category data under GDPR Article 9', 'special_category');

CREATE TABLE public.data_processing_activities (
    activity_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    purpose_id integer NOT NULL REFERENCES public.data_processing_purposes(purpose_id) ON DELETE RESTRICT,
    legal_basis varchar(100) NOT NULL,
    retention_period interval NOT NULL,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT legal_basis_check CHECK (legal_basis IN (
        'consent', 'contract', 'legal_obligation', 'vital_interest', 'public_task', 'legitimate_interest'
    ))
);

COMMENT ON TABLE public.data_processing_activities IS 'Data processing activities under GDPR';

CREATE TRIGGER update_data_processing_activities_timestamp
BEFORE UPDATE ON public.data_processing_activities
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_processing_activities_purpose_id ON public.data_processing_activities(purpose_id);

CREATE TABLE public.data_processing_categories (
    mapping_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    activity_id uuid NOT NULL REFERENCES public.data_processing_activities(activity_id) ON DELETE CASCADE,
    category_id integer NOT NULL REFERENCES public.data_categories(category_id) ON DELETE RESTRICT,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_activity_category UNIQUE (activity_id, category_id)
);

COMMENT ON TABLE public.data_processing_categories IS 'Junction table linking processing activities to data categories';

CREATE INDEX idx_data_processing_categories_activity_id ON public.data_processing_categories(activity_id);
CREATE INDEX idx_data_processing_categories_category_id ON public.data_processing_categories(category_id);

CREATE TABLE public.consent_records (
    consent_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    activity_id uuid NOT NULL REFERENCES public.data_processing_activities(activity_id) ON DELETE CASCADE,
    consent_given boolean NOT NULL,
    consent_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    withdrawal_timestamp timestamp with time zone,
    ip_address inet,
    user_agent text,
    version varchar(50) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.consent_records IS 'Records of user consent for data processing';

CREATE TRIGGER update_consent_records_timestamp
BEFORE UPDATE ON public.consent_records
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_consent_records_user_id ON public.consent_records(user_id);
CREATE INDEX idx_consent_records_activity_id ON public.consent_records(activity_id);
CREATE INDEX idx_consent_records_consent_given ON public.consent_records(consent_given);

CREATE TABLE public.data_subject_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    request_type varchar(50) NOT NULL,
    request_details text,
    request_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'pending',
    completion_date timestamp with time zone,
    handled_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT request_type_check CHECK (request_type IN (
        'access', 'rectification', 'erasure', 'restriction', 'portability', 'objection'
    )),
    CONSTRAINT status_check CHECK (status IN (
        'pending', 'in_progress', 'completed', 'rejected', 'cancelled'
    ))
);

COMMENT ON TABLE public.data_subject_requests IS 'Requests from data subjects under GDPR';

CREATE TRIGGER update_data_subject_requests_timestamp
BEFORE UPDATE ON public.data_subject_requests
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_subject_requests_user_id ON public.data_subject_requests(user_id);
CREATE INDEX idx_data_subject_requests_status ON public.data_subject_requests(status);
CREATE INDEX idx_data_subject_requests_request_type ON public.data_subject_requests(request_type);


CREATE TABLE public.categories (
    category_id integer PRIMARY KEY,
    category_name varchar(100) NOT NULL
);


CREATE TABLE public.data_breaches (
    breach_id uuid PRIMARY KEY,
    incident_time timestamp with time zone NOT NULL,
    detection_time timestamp with time zone NOT NULL,
    affected_data_subjects integer,
    breach_description text NOT NULL,
    data_categories_affected text ,
    containment_actions text,
    notification_sent boolean DEFAULT false,
    notification_date timestamp with time zone,
    severity varchar(20) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT severity_check CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);
-- Junction table to link data breaches to categories
CREATE TABLE public.data_breaches_categories (
    breach_id uuid NOT NULL REFERENCES public.data_breaches(breach_id) ON DELETE CASCADE,
    category_id integer NOT NULL REFERENCES public.categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (breach_id, category_id)
);
-- Trying to add FK here fails
-- revisit this 
ALTER TABLE public.data_breaches
ADD CONSTRAINT data_breaches_data_categories_affected_fkey
FOREIGN KEY (data_categories_affected) REFERENCES categories(category_id);

COMMENT ON TABLE public.data_breaches IS 'Records of data breach incidents';

CREATE TRIGGER update_data_breaches_timestamp
BEFORE UPDATE ON public.data_breaches
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_breaches_incident_time ON public.data_breaches(incident_time);
CREATE INDEX idx_data_breaches_severity ON public.data_breaches(severity);

-- Data Lifecycle Management
CREATE TABLE public.data_retention_policies (
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    table_name varchar(255) NOT NULL,
    retention_period interval NOT NULL,
    archival_strategy varchar(100),
    disposal_method varchar(100) NOT NULL,
    last_review_date date,
    next_review_date date NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT disposal_method_check CHECK (disposal_method IN (
        'deletion', 'anonymization', 'pseudonymization', 'aggregation'
    ))
);

COMMENT ON TABLE public.data_retention_policies IS 'Policies for data retention and disposal';

CREATE TRIGGER update_data_retention_policies_timestamp
BEFORE UPDATE ON public.data_retention_policies
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_retention_policies_table_name ON public.data_retention_policies(table_name);
CREATE INDEX idx_data_retention_policies_next_review_date ON public.data_retention_policies(next_review_date);

CREATE TABLE public.data_archives (
    archive_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    source_table varchar(255) NOT NULL,
    archive_criteria text NOT NULL,
    records_count integer NOT NULL,
    archive_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    storage_location text NOT NULL,
    retention_end_date timestamp with time zone NOT NULL,
    is_encrypted boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.data_archives IS 'Records of archived data';

CREATE TRIGGER update_data_archives_timestamp
BEFORE UPDATE ON public.data_archives
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_archives_source_table ON public.data_archives(source_table);
CREATE INDEX idx_data_archives_retention_end_date ON public.data_archives(retention_end_date);

-- Data Quality Monitoring
CREATE TABLE public.data_quality_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    table_name varchar(255) NOT NULL,
    metric_date date NOT NULL,
    completeness_score numeric(5,2) NOT NULL,
    accuracy_score numeric(5,2) NOT NULL,
    consistency_score numeric(5,2) NOT NULL,
    timeliness_score numeric(5,2) NOT NULL,
    valid_records integer NOT NULL,
    total_records integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT valid_records_check CHECK (valid_records <= total_records),
    CONSTRAINT score_range_check CHECK (
        completeness_score BETWEEN 0 AND 100 AND
        accuracy_score BETWEEN 0 AND 100 AND
        consistency_score BETWEEN 0 AND 100 AND
        timeliness_score BETWEEN 0 AND 100
    )
);

COMMENT ON TABLE public.data_quality_metrics IS 'Metrics for data quality monitoring';

CREATE TRIGGER update_data_quality_metrics_timestamp
BEFORE UPDATE ON public.data_quality_metrics
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_quality_metrics_table_name ON public.data_quality_metrics(table_name);
CREATE INDEX idx_data_quality_metrics_metric_date ON public.data_quality_metrics(metric_date DESC);

CREATE TABLE public.data_quality_issues (
    issue_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    table_name varchar(255) NOT NULL,
    column_name varchar(255),
    issue_type varchar(100) NOT NULL,
    affected_records integer NOT NULL,
    severity varchar(20) NOT NULL,
    detection_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    resolution_status varchar(50) DEFAULT 'open',
    resolution_time timestamp with time zone,
    resolution_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT severity_check CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT status_check CHECK (resolution_status IN ('open', 'in_progress', 'resolved', 'wont_fix'))
);

COMMENT ON TABLE public.data_quality_issues IS 'Identified data quality issues';

CREATE TRIGGER update_data_quality_issues_timestamp
BEFORE UPDATE ON public.data_quality_issues
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_quality_issues_table_name ON public.data_quality_issues(table_name);
CREATE INDEX idx_data_quality_issues_severity ON public.data_quality_issues(severity);
CREATE INDEX idx_data_quality_issues_resolution_status ON public.data_quality_issues(resolution_status);

-- Data Profiling
CREATE TABLE public.data_profiles (
    profile_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    table_name varchar(255) NOT NULL,
    profile_date date NOT NULL,
    column_count integer NOT NULL,
    row_count integer NOT NULL,
    null_value_percentage numeric(5,2) NOT NULL,
    distinct_value_percentage numeric(5,2) NOT NULL,
    data_type_distribution jsonb,
    pattern_analysis jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.data_profiles IS 'Profiles of database tables for monitoring';

CREATE TRIGGER update_data_profiles_timestamp
BEFORE UPDATE ON public.data_profiles
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_profiles_table_name ON public.data_profiles(table_name);
CREATE INDEX idx_data_profiles_profile_date ON public.data_profiles(profile_date DESC);

-- Materialized Views for Aggregates
CREATE MATERIALIZED VIEW public.company_aggregates AS
SELECT
    c.company_id,
    c.name,
    c.industry_id,
    i.name AS industry_name,
    COUNT(DISTINCT cr.review_id) AS review_count,
    AVG(cr.overall_rating) AS avg_rating,
    COUNT(DISTINCT sr.report_id) AS salary_report_count,
    COUNT(DISTINCT ie.experience_id) AS interview_count,
    COUNT(DISTINCT op.photo_id) AS photo_count,
    AVG(cr.work_life_balance) AS avg_work_life_balance,
    AVG(cr.culture_values) AS avg_culture_values,
    AVG(cr.career_opportunities) AS avg_career_opportunities,
    AVG(cr.compensation_benefits) AS avg_compensation,
    AVG(cr.senior_management) AS avg_senior_management,
    AVG(er.approval_rating) AS executive_approval_percent,
    COUNT(DISTINCT jl.job_listing_id) AS active_job_count,
    COUNT(DISTINCT e.employee_id) AS employee_count
FROM
    public.companies c
    LEFT JOIN public.industries i ON c.industry_id = i.industry_id
    LEFT JOIN public.company_reviews cr ON c.company_id = cr.company_id AND cr.approval_status = 'approved'
    LEFT JOIN public.salary_reports sr ON c.company_id = sr.company_id AND sr.approval_status = 'approved'
    LEFT JOIN public.interview_experiences ie ON c.company_id = ie.company_id AND ie.approval_status = 'approved'
    LEFT JOIN public.office_photos op ON c.company_id = op.company_id AND op.approval_status = 'approved'
    LEFT JOIN public.company_executives ce ON c.company_id = ce.company_id AND ce.is_current = true
    LEFT JOIN public.executive_ratings er ON ce.executive_id = er.executive_id AND er.approval_status = 'approved'
    LEFT JOIN public.job_listings jl ON c.company_id = jl.company_id AND jl.is_active = true
    LEFT JOIN public.employees e ON c.company_id = e.company_id AND e.employment_status = 'active'
GROUP BY
    c.company_id, c.name, c.industry_id, i.name;

COMMENT ON MATERIALIZED VIEW public.company_aggregates IS 'Aggregated company metrics for reporting';

CREATE UNIQUE INDEX idx_company_aggregates ON public.company_aggregates (company_id);

CREATE MATERIALIZED VIEW public.manager_aggregates AS
SELECT
    e.employee_id AS manager_id,
    up.full_name AS manager_name,
    c.company_id,
    c.name AS company_name,
    COUNT(DISTINCT mr.review_id) AS review_count,
    AVG(mr.overall_rating) AS avg_rating,
    AVG(mr.communication) AS avg_communication,
    AVG(mr.leadership) AS avg_leadership,
    AVG(mr.supportiveness) AS avg_supportiveness,
    AVG(mr.fairness) AS avg_fairness,
    AVG(mr.feedback_quality) AS avg_feedback_quality,
    COUNT(DISTINCT se.employee_id) AS direct_reports_count
FROM
    public.employees e
    JOIN public.users u ON e.user_id = u.user_id
    JOIN public.user_profiles up ON u.user_id = up.user_id
    JOIN public.companies c ON e.company_id = c.company_id
    LEFT JOIN public.manager_reviews mr ON e.employee_id = mr.manager_id AND mr.approval_status = 'approved'
    LEFT JOIN public.employees se ON se.manager_id = e.employee_id
WHERE
    e.employee_id IN (SELECT DISTINCT manager_id FROM public.employees WHERE manager_id IS NOT NULL)
GROUP BY
    e.employee_id, up.full_name, c.company_id, c.name;

COMMENT ON MATERIALIZED VIEW public.manager_aggregates IS 'Aggregated manager metrics for reporting';

CREATE UNIQUE INDEX idx_manager_aggregates ON public.manager_aggregates (manager_id);

-- Recommendation System
CREATE TABLE public.recommendation_models (
    model_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    model_name varchar(100) NOT NULL,
    model_version varchar(50) NOT NULL,
    model_type varchar(50) NOT NULL,
    is_active boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    last_trained_at timestamp with time zone,
    model_parameters jsonb,
    performance_metrics jsonb,
    CONSTRAINT model_type_check CHECK (model_type IN (
        'job', 'connection', 'content', 'learning', 'company'
    ))
);

COMMENT ON TABLE public.recommendation_models IS 'Machine learning models for recommendations';

CREATE TRIGGER update_recommendation_models_timestamp
BEFORE UPDATE ON public.recommendation_models
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_recommendation_models_type ON public.recommendation_models(model_type);
CREATE INDEX idx_recommendation_models_active ON public.recommendation_models(is_active) WHERE is_active = true;

CREATE TABLE public.user_recommendations (
    recommendation_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    model_id uuid NOT NULL REFERENCES public.recommendation_models(model_id) ON DELETE CASCADE,
    recommended_item_id uuid NOT NULL,
    item_type varchar(50) NOT NULL,
    relevance_score numeric(5,4) NOT NULL,
    recommendation_reason text,
    is_clicked boolean DEFAULT false,
    is_converted boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT item_type_check CHECK (item_type IN (
        'job', 'user', 'company', 'content', 'skill', 'learning'
    )),
    CONSTRAINT relevance_score_check CHECK (relevance_score BETWEEN 0 AND 1)
);

COMMENT ON TABLE public.user_recommendations IS 'Recommendations generated for users';

CREATE TRIGGER update_user_recommendations_timestamp
BEFORE UPDATE ON public.user_recommendations
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_user_recommendations_user_id ON public.user_recommendations(user_id);
CREATE INDEX idx_user_recommendations_item_type ON public.user_recommendations(item_type);
CREATE INDEX idx_user_recommendations_relevance ON public.user_recommendations(relevance_score DESC);

-- Analytics and Reporting
CREATE TABLE public.user_activities (
    activity_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    activity_type varchar(50) NOT NULL,
    activity_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    object_type varchar(50),
    object_id uuid,
    metadata jsonb,
    session_id uuid,
    ip_address inet,
    user_agent text,
    CONSTRAINT activity_type_check CHECK (activity_type IN (
        'login', 'logout', 'view', 'search', 'apply', 'connect', 'message', 'post', 'like', 'comment', 'share'
    ))
);

COMMENT ON TABLE public.user_activities IS 'User activity tracking for analytics';

CREATE INDEX idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX idx_user_activities_activity_type ON public.user_activities(activity_type);
CREATE INDEX idx_user_activities_timestamp ON public.user_activities(activity_timestamp);
CREATE INDEX idx_user_activities_object ON public.user_activities(object_type, object_id);

-- Localization Support
CREATE TABLE public.languages (
    language_code varchar(10) PRIMARY KEY,
    name varchar(100) NOT NULL,
    native_name varchar(100) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.languages IS 'Supported languages for localization';

CREATE TRIGGER update_languages_timestamp
BEFORE UPDATE ON public.languages
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default languages
INSERT INTO public.languages (language_code, name, native_name) VALUES
('en', 'English', 'English'),
('es', 'Spanish', 'Español'),
('fr', 'French', 'Français'),
('de', 'German', 'Deutsch'),
('zh', 'Chinese', '中文'),
('ja', 'Japanese', '日本語'),
('pt', 'Portuguese', 'Português');

CREATE TABLE public.translation_keys (
    key_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    key_name varchar(255) NOT NULL UNIQUE,
    description text,
    context text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);

COMMENT ON TABLE public.translation_keys IS 'Keys for translatable content';

CREATE TRIGGER update_translation_keys_timestamp
BEFORE UPDATE ON public.translation_keys
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.translations (
    translation_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    key_id uuid NOT NULL REFERENCES public.translation_keys(key_id) ON DELETE CASCADE,
    language_code varchar(10) NOT NULL REFERENCES public.languages(language_code) ON DELETE CASCADE,
    translation_text text NOT NULL,
    is_approved boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_key_language UNIQUE (key_id, language_code)
);

COMMENT ON TABLE public.translations IS 'Translated content for different languages';

CREATE TRIGGER update_translations_timestamp
BEFORE UPDATE ON public.translations
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_translations_key_id ON public.translations(key_id);
CREATE INDEX idx_translations_language_code ON public.translations(language_code);

-- Security: Row-Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manager_reviews ENABLE ROW LEVEL SECURITY;

---revisit the row level security policies, once db is setup. 
-- enable the RLS Policies
-- RLS Policies
CREATE POLICY user_own_data_policy ON public.users
    USING (user_id = current_user_id() OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name = 'admin'));

CREATE POLICY user_profile_policy ON public.user_profiles
    USING (user_id = current_user_id() OR
           profile_visibility = 'public' OR
           (profile_visibility = 'connections' AND
            EXISTS (SELECT 1 FROM public.user_connections uc
                   WHERE (uc.user_id = current_user_id() AND uc.connected_user_id = user_profiles.user_id OR
                          uc.connected_user_id = current_user_id() AND uc.user_id = user_profiles.user_id) AND
                          uc.connection_status = 'accepted')) OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name IN ('admin', 'moderator')));

CREATE POLICY user_connections_policy ON public.user_connections
    USING (user_id = current_user_id() OR
           connected_user_id = current_user_id() OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name = 'admin'));

CREATE POLICY content_policy ON public.contents
    USING (user_id = current_user_id() OR
           visibility = 'public' OR
           (visibility = 'connections' AND
            EXISTS (SELECT 1 FROM public.user_connections uc
                   WHERE (uc.user_id = current_user_id() AND uc.connected_user_id = contents.user_id OR
                          uc.connected_user_id = current_user_id() AND uc.user_id = contents.user_id) AND
                          uc.connection_status = 'accepted')) OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name IN ('admin', 'moderator')));

CREATE POLICY job_applications_policy ON public.job_applications
    USING (applicant_id = current_user_id() OR
           EXISTS (SELECT 1 FROM public.job_listings jl
                  JOIN public.company_admins ca ON jl.company_id = ca.company_id
                  WHERE jl.job_listing_id = job_applications.job_listing_id AND
                        ca.user_id = current_user_id()) OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name = 'admin'));

CREATE POLICY salary_reports_policy ON public.salary_reports
    USING (user_id = current_user_id() OR
           approval_status = 'approved' OR
           EXISTS (SELECT 1 FROM public.user_roles ur
                  JOIN public.roles r ON ur.role_id = r.role_id
                  WHERE ur.user_id = current_user_id() AND r.name IN ('admin', 'moderator')));
---end of code that needs to be executed later

-- Triggers for Search Vectors
CREATE OR REPLACE FUNCTION public.update_user_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.first_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.last_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.full_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.headline, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.profile_summary, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_content_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.summary, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.body, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_job_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.responsibilities, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.qualifications, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_company_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--encrypt later --endofcode
CREATE TRIGGER user_search_vector_update
BEFORE INSERT OR UPDATE ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION update_user_search_vector();

CREATE TRIGGER content_search_vector_update
BEFORE INSERT OR UPDATE ON public.contents
FOR EACH ROW EXECUTE FUNCTION update_content_search_vector();

CREATE TRIGGER job_search_vector_update
BEFORE INSERT OR UPDATE ON public.job_listings
FOR EACH ROW EXECUTE FUNCTION update_job_search_vector();

CREATE TRIGGER company_search_vector_update
BEFORE INSERT OR UPDATE ON public.companies
FOR EACH ROW EXECUTE FUNCTION update_company_search_vector();

-- Encryption Functions
CREATE OR REPLACE FUNCTION encrypt_sensitive_data()
RETURNS TRIGGER AS $$
DECLARE
    encryption_key text;
BEGIN
    -- Get encryption key from secure source (e.g., environment variable)
    encryption_key := current_setting('app.encryption_key', true);

    IF encryption_key IS NULL THEN
        RAISE WARNING 'Encryption key not found. Using fallback method.';
        encryption_key := 'temporary_key_for_development_only';
    END IF;

    IF NEW.email IS NOT NULL AND NEW.email_encrypted IS NULL THEN
        NEW.email_encrypted := pgp_sym_encrypt(NEW.email, encryption_key);
    END IF;

    IF NEW.phone IS NOT NULL AND NEW.phone_encrypted IS NULL THEN
        NEW.phone_encrypted := pgp_sym_encrypt(NEW.phone, encryption_key);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encrypt_data_trigger
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION encrypt_sensitive_data();

--encrypt later --endofcode

-- User History Tracking
CREATE OR REPLACE FUNCTION public.log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.users_history(
            user_id, email, password_hash, is_active,
            valid_from, changed_by, change_reason
        ) VALUES (
            OLD.user_id, OLD.email, OLD.password_hash, OLD.is_active,
            CURRENT_TIMESTAMP, NEW.last_updated_by, 'regular update'
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.users_history(
            user_id, email, password_hash, is_active,
            valid_from, changed_by, change_reason
        ) VALUES (
            OLD.user_id, OLD.email, OLD.password_hash, OLD.is_active,
            CURRENT_TIMESTAMP, current_user_id(), 'deletion'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_history_trigger
AFTER UPDATE OR DELETE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.log_user_changes();

-- Manager Relationship Validation
CREATE OR REPLACE FUNCTION public.validate_manager_relationship()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if employee is trying to be their own manager
    IF NEW.manager_id IS NOT NULL AND NEW.manager_id = NEW.employee_id THEN
        RAISE EXCEPTION 'Employee cannot be their own manager';
    END IF;

    -- Check if manager is from the same company
    IF NEW.manager_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.employees
            WHERE employee_id = NEW.manager_id AND company_id = NEW.company_id
        ) THEN
            RAISE EXCEPTION 'Manager must be from the same company';
        END IF;

        -- Check for circular references in management hierarchy
        WITH RECURSIVE management_chain AS (
            -- Base case: start with the manager
            SELECT employee_id, manager_id, 1 AS depth
            FROM public.employees
            WHERE employee_id = NEW.manager_id

            UNION ALL

            -- Recursive case: get the manager's manager
            SELECT e.employee_id, e.manager_id, mc.depth + 1
            FROM public.employees e
            JOIN management_chain mc ON e.employee_id = mc.manager_id
            WHERE e.manager_id IS NOT NULL AND mc.depth < 10 -- Prevent infinite recursion
        )
        SELECT COUNT(*) INTO STRICT count
        FROM management_chain
        WHERE manager_id = NEW.employee_id;

        IF count > 0 THEN
            RAISE EXCEPTION 'Circular reference detected in management hierarchy';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_manager_relationship
BEFORE INSERT OR UPDATE ON public.employees
FOR EACH ROW EXECUTE FUNCTION public.validate_manager_relationship();

-- Materialized View Refresh Functions
CREATE OR REPLACE FUNCTION public.refresh_company_aggregates()
RETURNS TRIGGER AS $$
BEGIN
    -- Schedule a refresh of the materialized view
    PERFORM pg_notify('refresh_company_aggregates', '');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.refresh_manager_aggregates()
RETURNS TRIGGER AS $$
BEGIN
    -- Schedule a refresh of the materialized view
    PERFORM pg_notify('refresh_manager_aggregates', '');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create more efficient triggers that use notification instead of immediate refresh
CREATE TRIGGER update_company_aggregates_after_review
AFTER INSERT OR UPDATE OR DELETE ON public.company_reviews
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_company_aggregates();

CREATE TRIGGER update_company_aggregates_after_salary
AFTER INSERT OR UPDATE OR DELETE ON public.salary_reports
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_company_aggregates();

CREATE TRIGGER update_company_aggregates_after_interview
AFTER INSERT OR UPDATE OR DELETE ON public.interview_experiences
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_company_aggregates();

CREATE TRIGGER update_company_aggregates_after_photo
AFTER INSERT OR UPDATE OR DELETE ON public.office_photos
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_company_aggregates();

CREATE TRIGGER update_company_aggregates_after_executive_rating
AFTER INSERT OR UPDATE OR DELETE ON public.executive_ratings
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_company_aggregates();

CREATE TRIGGER update_manager_aggregates_after_review
AFTER INSERT OR UPDATE OR DELETE ON public.manager_reviews
FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_manager_aggregates();

-- Scheduled Refresh of Materialized Views (if pg_cron is available)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        PERFORM cron.schedule('refresh-company-aggregates', '0 4 * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY public.company_aggregates');
        PERFORM cron.schedule('refresh-manager-aggregates', '0 5 * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY public.manager_aggregates');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_cron extension not available. Scheduled refreshes will not be created.';
END $$;

-- Comments on schema objects
COMMENT ON SCHEMA public IS 'Professional network database schema with Glassdoor-style features';
-- Definitions for Missing Tables (Professional Network Schema Enhancement)

-- User Profile Extensions

CREATE TABLE public.user_education (
    education_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    institution_name varchar(255) NOT NULL,
    degree varchar(100),
    field_of_study varchar(100),
    start_date date,
    end_date date,
    grade varchar(50),
    description text,
    is_current boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT date_check CHECK (end_date IS NULL OR end_date >= start_date)
);
COMMENT ON TABLE public.user_education IS 'User educational background';
CREATE TRIGGER update_user_education_timestamp BEFORE UPDATE ON public.user_education FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_education_user_id ON public.user_education(user_id);

CREATE TABLE public.user_certifications (
    certification_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    name varchar(255) NOT NULL,
    issuing_organization varchar(255),
    issue_date date,
    expiration_date date,
    credential_id varchar(100),
    credential_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT date_check CHECK (expiration_date IS NULL OR expiration_date >= issue_date)
);
COMMENT ON TABLE public.user_certifications IS 'User professional certifications';
CREATE TRIGGER update_user_certifications_timestamp BEFORE UPDATE ON public.user_certifications FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_certifications_user_id ON public.user_certifications(user_id);

CREATE TABLE public.user_languages (
    user_language_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    language_code varchar(10) NOT NULL REFERENCES public.languages(language_code) ON DELETE RESTRICT,
    proficiency varchar(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_language UNIQUE (user_id, language_code),
    CONSTRAINT proficiency_check CHECK (proficiency IN ('elementary', 'limited_working', 'professional_working', 'full_professional', 'native_or_bilingual'))
);
COMMENT ON TABLE public.user_languages IS 'Languages spoken by the user';
CREATE TRIGGER update_user_languages_timestamp BEFORE UPDATE ON public.user_languages FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_languages_user_id ON public.user_languages(user_id);

CREATE TABLE public.user_achievements (
    achievement_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    issuer varchar(255),
    issue_date date,
    description text,
    associated_with varchar(100), -- e.g., 'education', 'job', 'project'
    associated_id uuid, -- Reference to the related entity (e.g., education_id)
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.user_achievements IS 'User honors, awards, and significant achievements';
CREATE TRIGGER update_user_achievements_timestamp BEFORE UPDATE ON public.user_achievements FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_achievements_user_id ON public.user_achievements(user_id);

CREATE TABLE public.user_portfolio (
    portfolio_item_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    description text,
    project_url text,
    media_url text,
    item_type varchar(50), -- e.g., 'website', 'article', 'video', 'presentation'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.user_portfolio IS 'User portfolio items showcasing work';
CREATE TRIGGER update_user_portfolio_timestamp BEFORE UPDATE ON public.user_portfolio FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_portfolio_user_id ON public.user_portfolio(user_id);

CREATE TABLE public.user_publications (
    publication_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(500) NOT NULL,
    publisher varchar(255),
    publication_date date,
    authors text,
    publication_url text,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.user_publications IS 'User published works';
CREATE TRIGGER update_user_publications_timestamp BEFORE UPDATE ON public.user_publications FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_publications_user_id ON public.user_publications(user_id);

CREATE TABLE public.user_patents (
    patent_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(500) NOT NULL,
    patent_office varchar(100),
    patent_number varchar(100) NOT NULL,
    status varchar(50), -- e.g., 'pending', 'issued'
    issue_date date,
    application_date date,
    inventors text,
    patent_url text,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_patent_number UNIQUE (patent_office, patent_number)
);
COMMENT ON TABLE public.user_patents IS 'User patents';
CREATE TRIGGER update_user_patents_timestamp BEFORE UPDATE ON public.user_patents FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_patents_user_id ON public.user_patents(user_id);

CREATE TABLE public.user_volunteering (
    volunteering_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    organization_name varchar(255) NOT NULL,
    role varchar(255),
    cause varchar(100),
    start_date date,
    end_date date,
    is_current boolean DEFAULT false,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT date_check CHECK (end_date IS NULL OR end_date >= start_date)
);
COMMENT ON TABLE public.user_volunteering IS 'User volunteering experience';
CREATE TRIGGER update_user_volunteering_timestamp BEFORE UPDATE ON public.user_volunteering FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_volunteering_user_id ON public.user_volunteering(user_id);

CREATE TABLE public.user_interests (
    interest_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    interest_name varchar(100) NOT NULL,
    category varchar(100), -- e.g., 'professional', 'personal'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_interest UNIQUE (user_id, interest_name)
);
COMMENT ON TABLE public.user_interests IS 'User interests';
CREATE TRIGGER update_user_interests_timestamp BEFORE UPDATE ON public.user_interests FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_interests_user_id ON public.user_interests(user_id);

CREATE TABLE public.user_preferences (
    preference_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    preference_key varchar(100) NOT NULL,
    preference_value text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_preference UNIQUE (user_id, preference_key)
);
COMMENT ON TABLE public.user_preferences IS 'User application preferences and settings';
CREATE TRIGGER update_user_preferences_timestamp BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_preferences_user_id ON public.user_preferences(user_id);

CREATE TABLE public.user_privacy_settings (
    privacy_setting_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    setting_key varchar(100) NOT NULL,
    setting_value varchar(100) NOT NULL, -- e.g., 'public', 'connections', 'private'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_privacy_setting UNIQUE (user_id, setting_key)
);
COMMENT ON TABLE public.user_privacy_settings IS 'Granular user privacy settings';
CREATE TRIGGER update_user_privacy_settings_timestamp BEFORE UPDATE ON public.user_privacy_settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_privacy_settings_user_id ON public.user_privacy_settings(user_id);

CREATE TABLE public.user_device_history (
    device_history_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    device_type varchar(50), -- e.g., 'desktop', 'mobile', 'tablet'
    os varchar(50),
    browser varchar(50),
    ip_address inet,
    last_seen timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.user_device_history IS 'History of devices used by the user';
CREATE TRIGGER update_user_device_history_timestamp BEFORE UPDATE ON public.user_device_history FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_device_history_user_id ON public.user_device_history(user_id);

CREATE TABLE public.user_login_history (
    login_history_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    login_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    ip_address inet,
    user_agent text,
    login_successful boolean NOT NULL,
    failure_reason varchar(100)
);
COMMENT ON TABLE public.user_login_history IS 'User login attempts history';
CREATE INDEX idx_user_login_history_user_id ON public.user_login_history(user_id);
CREATE INDEX idx_user_login_history_timestamp ON public.user_login_history(login_timestamp DESC);

CREATE TABLE public.user_notifications (
    notification_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    notification_type varchar(50) NOT NULL,
    content text NOT NULL,
    related_object_type varchar(50),
    related_object_id uuid,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.user_notifications IS 'User notifications';
CREATE TRIGGER update_user_notifications_timestamp BEFORE UPDATE ON public.user_notifications FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_user_notifications_user_id ON public.user_notifications(user_id, is_read, created_at DESC);

CREATE TABLE public.user_saved_items (
    saved_item_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    item_type varchar(50) NOT NULL, -- e.g., 'job', 'content', 'user', 'company'
    item_id uuid NOT NULL,
    saved_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    folder_id uuid, -- Optional: reference to a user-defined folder
    CONSTRAINT unique_user_saved_item UNIQUE (user_id, item_type, item_id)
);
COMMENT ON TABLE public.user_saved_items IS 'Items saved by the user';
CREATE INDEX idx_user_saved_items_user_id ON public.user_saved_items(user_id, item_type);

CREATE TABLE public.user_blocks (
    block_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    blocker_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    blocked_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    blocked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    reason text,
    CONSTRAINT no_self_block CHECK (blocker_user_id <> blocked_user_id),
    CONSTRAINT unique_user_block UNIQUE (blocker_user_id, blocked_user_id)
);
COMMENT ON TABLE public.user_blocks IS 'Users blocked by other users';
CREATE INDEX idx_user_blocks_blocker ON public.user_blocks(blocker_user_id);
CREATE INDEX idx_user_blocks_blocked ON public.user_blocks(blocked_user_id);

CREATE TABLE public.user_follows (
    follow_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    follower_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    followed_entity_type varchar(50) NOT NULL, -- e.g., 'user', 'company', 'topic'
    followed_entity_id uuid NOT NULL,
    followed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_follow CHECK (follower_user_id <> followed_entity_id OR followed_entity_type <> 'user'),
    CONSTRAINT unique_user_follow UNIQUE (follower_user_id, followed_entity_type, followed_entity_id)
);
COMMENT ON TABLE public.user_follows IS 'User following relationships (users, companies, topics)';
CREATE INDEX idx_user_follows_follower ON public.user_follows(follower_user_id);
CREATE INDEX idx_user_follows_followed ON public.user_follows(followed_entity_type, followed_entity_id);

CREATE TABLE public.user_profile_views_analytics (
    view_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    profile_id uuid NOT NULL REFERENCES public.user_profiles(profile_id) ON DELETE CASCADE,
    viewer_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL, -- Null if anonymous
    view_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    viewer_company_id uuid REFERENCES public.companies(company_id) ON DELETE SET NULL,
    viewer_job_title varchar(255),
    source varchar(100) -- e.g., 'search', 'connection', 'recommendation'
);
COMMENT ON TABLE public.user_profile_views_analytics IS 'Analytics for profile views';
CREATE INDEX idx_user_profile_views_profile_id ON public.user_profile_views_analytics(profile_id, view_timestamp DESC);
CREATE INDEX idx_user_profile_views_viewer_id ON public.user_profile_views_analytics(viewer_id);

CREATE TABLE public.user_profile_completion (
    completion_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE UNIQUE,
    completion_percentage numeric(5,2) NOT NULL DEFAULT 0,
    last_calculated timestamp with time zone,
    missing_sections text[],
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT percentage_check CHECK (completion_percentage BETWEEN 0 AND 100)
);
COMMENT ON TABLE public.user_profile_completion IS 'Tracks user profile completion status';
CREATE TRIGGER update_user_profile_completion_timestamp BEFORE UPDATE ON public.user_profile_completion FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Content System Extensions

CREATE TABLE public.content_comments (
    comment_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    parent_comment_id uuid REFERENCES public.content_comments(comment_id) ON DELETE CASCADE,
    comment_text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    is_edited boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    like_count integer DEFAULT 0
);
COMMENT ON TABLE public.content_comments IS 'Comments on content items';
CREATE TRIGGER update_content_comments_timestamp BEFORE UPDATE ON public.content_comments FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_comments_content_id ON public.content_comments(content_id, created_at);
CREATE INDEX idx_content_comments_user_id ON public.content_comments(user_id);
CREATE INDEX idx_content_comments_parent ON public.content_comments(parent_comment_id);

CREATE TABLE public.content_likes (
    like_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    liked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_content_like UNIQUE (content_id, user_id)
);
COMMENT ON TABLE public.content_likes IS 'Likes on content items';
CREATE INDEX idx_content_likes_content_id ON public.content_likes(content_id);
CREATE INDEX idx_content_likes_user_id ON public.content_likes(user_id);

CREATE TABLE public.content_shares (
    share_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    shared_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    platform varchar(50), -- e.g., 'internal', 'linkedin', 'twitter'
    share_comment text
);
COMMENT ON TABLE public.content_shares IS 'Shares of content items';
CREATE INDEX idx_content_shares_content_id ON public.content_shares(content_id);
CREATE INDEX idx_content_shares_user_id ON public.content_shares(user_id);

CREATE TABLE public.content_bookmarks (
    bookmark_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    bookmarked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    folder_id uuid, -- Optional: reference to a user-defined folder
    CONSTRAINT unique_content_bookmark UNIQUE (content_id, user_id)
);
COMMENT ON TABLE public.content_bookmarks IS 'Bookmarks for content items';
CREATE INDEX idx_content_bookmarks_user_id ON public.content_bookmarks(user_id, bookmarked_at DESC);

CREATE TABLE public.content_reports (
    report_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    reporter_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    report_reason text NOT NULL,
    report_details text,
    reported_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'pending', -- e.g., 'pending', 'reviewed', 'action_taken', 'dismissed'
    reviewed_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    reviewed_at timestamp with time zone,
    action_taken text
);
COMMENT ON TABLE public.content_reports IS 'Reports submitted against content items';
CREATE INDEX idx_content_reports_content_id ON public.content_reports(content_id);
CREATE INDEX idx_content_reports_status ON public.content_reports(status);

CREATE TABLE public.content_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE UNIQUE,
    view_count integer DEFAULT 0,
    unique_view_count integer DEFAULT 0,
    like_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    bookmark_count integer DEFAULT 0,
    engagement_score numeric(5,2) DEFAULT 0,
    last_updated timestamp with time zone
);
COMMENT ON TABLE public.content_analytics IS 'Aggregated analytics for content items';
CREATE TRIGGER update_content_analytics_timestamp BEFORE UPDATE ON public.content_analytics FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.content_tags (
    tag_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    tag_name varchar(100) NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_tags IS 'Tags for categorizing content';
CREATE TRIGGER update_content_tags_timestamp BEFORE UPDATE ON public.content_tags FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.content_tag_map (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    tag_id uuid NOT NULL REFERENCES public.content_tags(tag_id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_content_tag UNIQUE (content_id, tag_id)
);
COMMENT ON TABLE public.content_tag_map IS 'Mapping content items to tags';
CREATE INDEX idx_content_tag_map_content_id ON public.content_tag_map(content_id);
CREATE INDEX idx_content_tag_map_tag_id ON public.content_tag_map(tag_id);

CREATE TABLE public.content_mentions (
    mention_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    mentioned_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    mentioned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.content_mentions IS 'Mentions of users within content';
CREATE INDEX idx_content_mentions_content_id ON public.content_mentions(content_id);
CREATE INDEX idx_content_mentions_mentioned_user_id ON public.content_mentions(mentioned_user_id);

CREATE TABLE public.content_polls (
    poll_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE UNIQUE,
    question text NOT NULL,
    end_date timestamp with time zone,
    allow_multiple_choices boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_polls IS 'Polls associated with content items';
CREATE TRIGGER update_content_polls_timestamp BEFORE UPDATE ON public.content_polls FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.content_poll_options (
    option_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    poll_id uuid NOT NULL REFERENCES public.content_polls(poll_id) ON DELETE CASCADE,
    option_text varchar(255) NOT NULL,
    vote_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.content_poll_options IS 'Options for a content poll';
CREATE INDEX idx_content_poll_options_poll_id ON public.content_poll_options(poll_id);

CREATE TABLE public.content_poll_votes (
    vote_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    option_id uuid NOT NULL REFERENCES public.content_poll_options(option_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    voted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_poll_vote UNIQUE (option_id, user_id) -- Assuming one vote per user per option
);
COMMENT ON TABLE public.content_poll_votes IS 'Votes cast in content polls';
CREATE INDEX idx_content_poll_votes_option_id ON public.content_poll_votes(option_id);
CREATE INDEX idx_content_poll_votes_user_id ON public.content_poll_votes(user_id);

CREATE TABLE public.content_media (
    media_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    media_type varchar(50) NOT NULL, -- e.g., 'image', 'video', 'document'
    media_url text NOT NULL,
    thumbnail_url text,
    caption text,
    alt_text text,
    file_size_kb integer,
    duration_seconds integer, -- For video/audio
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_media IS 'Media files associated with content';
CREATE TRIGGER update_content_media_timestamp BEFORE UPDATE ON public.content_media FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_media_content_id ON public.content_media(content_id);

CREATE TABLE public.content_drafts (
    draft_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    content_type_id integer NOT NULL REFERENCES public.content_types(content_type_id) ON DELETE RESTRICT,
    title varchar(255),
    body text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_drafts IS 'Drafts of content being created';
CREATE TRIGGER update_content_drafts_timestamp BEFORE UPDATE ON public.content_drafts FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_drafts_user_id ON public.content_drafts(user_id, updated_at DESC);

CREATE TABLE public.content_revisions (
    revision_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE RESTRICT,
    revision_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    title varchar(255),
    body text,
    change_summary text
);
COMMENT ON TABLE public.content_revisions IS 'Revisions history for content (alternative to content_versions)';
CREATE INDEX idx_content_revisions_content_id ON public.content_revisions(content_id, revision_timestamp DESC);

CREATE TABLE public.content_translations (
    content_translation_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    language_code varchar(10) NOT NULL REFERENCES public.languages(language_code) ON DELETE CASCADE,
    title varchar(255),
    body text,
    summary text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_content_language UNIQUE (content_id, language_code)
);
COMMENT ON TABLE public.content_translations IS 'Translations of content items';
CREATE TRIGGER update_content_translations_timestamp BEFORE UPDATE ON public.content_translations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_translations_content_id ON public.content_translations(content_id);
CREATE INDEX idx_content_translations_language_code ON public.content_translations(language_code);

CREATE TABLE public.content_schedules (
    schedule_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE UNIQUE,
    publish_at timestamp with time zone NOT NULL,
    status varchar(50) DEFAULT 'scheduled', -- e.g., 'scheduled', 'published', 'failed'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_schedules IS 'Scheduled publishing for content';
CREATE TRIGGER update_content_schedules_timestamp BEFORE UPDATE ON public.content_schedules FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_schedules_publish_at ON public.content_schedules(publish_at, status);

CREATE TABLE public.content_series (
    series_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_series IS 'Series or collections of related content';
CREATE TRIGGER update_content_series_timestamp BEFORE UPDATE ON public.content_series FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_series_user_id ON public.content_series(user_id);

CREATE TABLE public.content_series_map (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    series_id uuid NOT NULL REFERENCES public.content_series(series_id) ON DELETE CASCADE,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    sequence_order integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_series_content UNIQUE (series_id, content_id)
);
COMMENT ON TABLE public.content_series_map IS 'Mapping content items to series';
CREATE INDEX idx_content_series_map_series_id ON public.content_series_map(series_id, sequence_order);
CREATE INDEX idx_content_series_map_content_id ON public.content_series_map(content_id);

CREATE TABLE public.content_collections (
    collection_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    name varchar(255) NOT NULL,
    description text,
    is_private boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_collections IS 'User-curated collections of content';
CREATE TRIGGER update_content_collections_timestamp BEFORE UPDATE ON public.content_collections FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_collections_user_id ON public.content_collections(user_id);

CREATE TABLE public.content_collection_items (
    item_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    collection_id uuid NOT NULL REFERENCES public.content_collections(collection_id) ON DELETE CASCADE,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    CONSTRAINT unique_collection_content UNIQUE (collection_id, content_id)
);
COMMENT ON TABLE public.content_collection_items IS 'Items within a user collection';
CREATE INDEX idx_content_collection_items_collection_id ON public.content_collection_items(collection_id);
CREATE INDEX idx_content_collection_items_content_id ON public.content_collection_items(content_id);

CREATE TABLE public.content_collaborators (
    collaboration_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    role varchar(50) DEFAULT 'contributor', -- e.g., 'author', 'editor', 'contributor'
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_content_collaborator UNIQUE (content_id, user_id)
);
COMMENT ON TABLE public.content_collaborators IS 'Collaborators on content items';
CREATE INDEX idx_content_collaborators_content_id ON public.content_collaborators(content_id);
CREATE INDEX idx_content_collaborators_user_id ON public.content_collaborators(user_id);

CREATE TABLE public.content_permissions (
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    user_id uuid REFERENCES public.users(user_id) ON DELETE CASCADE, -- Null for public/connections
    group_id uuid, -- Optional: reference to a group
    permission_type varchar(50) NOT NULL, -- e.g., 'view', 'comment', 'edit'
    access_level varchar(50) NOT NULL, -- e.g., 'public', 'connections', 'specific_users', 'group'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_permissions IS 'Granular permissions for content access';
CREATE TRIGGER update_content_permissions_timestamp BEFORE UPDATE ON public.content_permissions FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_content_permissions_content_id ON public.content_permissions(content_id);
CREATE INDEX idx_content_permissions_user_id ON public.content_permissions(user_id);

CREATE TABLE public.content_monetization (
    monetization_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE UNIQUE,
    monetization_model varchar(50), -- e.g., 'subscription', 'paywall', 'ads'
    price numeric(10,2),
    currency varchar(3),
    is_active boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.content_monetization IS 'Monetization settings for content';
CREATE TRIGGER update_content_monetization_timestamp BEFORE UPDATE ON public.content_monetization FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Messaging System

CREATE TABLE public.conversations (
    conversation_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    title varchar(255), -- For group conversations
    is_group_conversation boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone, -- Last message time
    last_message_id uuid -- Reference to the last message
);
COMMENT ON TABLE public.conversations IS 'Messaging conversations';
CREATE TRIGGER update_conversations_timestamp BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_conversations_updated_at ON public.conversations(updated_at DESC);

CREATE TABLE public.conversation_participants (
    participant_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES public.conversations(conversation_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_read_timestamp timestamp with time zone,
    is_admin boolean DEFAULT false, -- For group conversations
    is_muted boolean DEFAULT false,
    is_archived boolean DEFAULT false,
    CONSTRAINT unique_conversation_participant UNIQUE (conversation_id, user_id)
);
COMMENT ON TABLE public.conversation_participants IS 'Participants in a conversation';
CREATE INDEX idx_conversation_participants_conversation_id ON public.conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_user_id ON public.conversation_participants(user_id, is_archived, joined_at DESC);

CREATE TABLE public.messages (
    message_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES public.conversations(conversation_id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    message_text text,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_edited boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    parent_message_id uuid REFERENCES public.messages(message_id) ON DELETE SET NULL -- For replies
);
COMMENT ON TABLE public.messages IS 'Individual messages within conversations';
CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id, sent_at DESC);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);

-- Add foreign key constraint for last_message_id in conversations
ALTER TABLE public.conversations ADD CONSTRAINT fk_last_message FOREIGN KEY (last_message_id) REFERENCES public.messages(message_id) ON DELETE SET NULL;

CREATE TABLE public.message_attachments (
    attachment_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    message_id uuid NOT NULL REFERENCES public.messages(message_id) ON DELETE CASCADE,
    attachment_type varchar(50) NOT NULL, -- e.g., 'image', 'file', 'link_preview'
    attachment_url text NOT NULL,
    file_name varchar(255),
    file_size_kb integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.message_attachments IS 'Attachments to messages';
CREATE INDEX idx_message_attachments_message_id ON public.message_attachments(message_id);

CREATE TABLE public.message_reactions (
    reaction_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    message_id uuid NOT NULL REFERENCES public.messages(message_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    reaction_type varchar(50) NOT NULL, -- e.g., 'like', 'love', 'laugh', 'sad'
    reacted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_message_reaction UNIQUE (message_id, user_id, reaction_type)
);
COMMENT ON TABLE public.message_reactions IS 'Reactions to messages';
CREATE INDEX idx_message_reactions_message_id ON public.message_reactions(message_id);
CREATE INDEX idx_message_reactions_user_id ON public.message_reactions(user_id);

CREATE TABLE public.message_read_status (
    read_status_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    message_id uuid NOT NULL REFERENCES public.messages(message_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    read_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_message_read UNIQUE (message_id, user_id)
);
COMMENT ON TABLE public.message_read_status IS 'Tracks read status of messages per user';
CREATE INDEX idx_message_read_status_message_id ON public.message_read_status(message_id);
CREATE INDEX idx_message_read_status_user_id ON public.message_read_status(user_id);

CREATE TABLE public.message_templates (
    template_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    template_name varchar(100) NOT NULL,
    template_body text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.message_templates IS 'User-defined message templates/canned responses';
CREATE TRIGGER update_message_templates_timestamp BEFORE UPDATE ON public.message_templates FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_message_templates_user_id ON public.message_templates(user_id);

CREATE TABLE public.message_folders (
    folder_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    folder_name varchar(100) NOT NULL,
    parent_folder_id uuid REFERENCES public.message_folders(folder_id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_folder_name UNIQUE (user_id, folder_name, parent_folder_id)
);
COMMENT ON TABLE public.message_folders IS 'User-defined folders for organizing conversations';
CREATE TRIGGER update_message_folders_timestamp BEFORE UPDATE ON public.message_folders FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_message_folders_user_id ON public.message_folders(user_id);

-- Add folder_id to conversation_participants
ALTER TABLE public.conversation_participants ADD COLUMN folder_id uuid REFERENCES public.message_folders(folder_id) ON DELETE SET NULL;
CREATE INDEX idx_conversation_participants_folder_id ON public.conversation_participants(folder_id);

CREATE TABLE public.message_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE UNIQUE,
    allow_messages_from varchar(50) DEFAULT 'connections', -- e.g., 'everyone', 'connections', 'nobody'
    read_receipts_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.message_settings IS 'User settings related to messaging';
CREATE TRIGGER update_message_settings_timestamp BEFORE UPDATE ON public.message_settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.message_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    analytic_date date NOT NULL DEFAULT CURRENT_DATE,
    messages_sent integer DEFAULT 0,
    messages_received integer DEFAULT 0,
    conversations_started integer DEFAULT 0,
    average_response_time interval,
    CONSTRAINT unique_user_message_analytic_date UNIQUE (user_id, analytic_date)
);
COMMENT ON TABLE public.message_analytics IS 'Analytics related to user messaging activity';
CREATE INDEX idx_message_analytics_user_id ON public.message_analytics(user_id, analytic_date DESC);

-- Events System

CREATE TABLE public.event_categories (
    category_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    parent_category_id uuid REFERENCES public.event_categories(category_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.event_categories IS 'Categories for events';
CREATE TRIGGER update_event_categories_timestamp BEFORE UPDATE ON public.event_categories FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    organizer_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE, -- Can also be company_id
    organizer_type varchar(50) DEFAULT 'user', -- 'user' or 'company'
    title varchar(255) NOT NULL,
    description text,
    category_id uuid REFERENCES public.event_categories(category_id) ON DELETE SET NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    event_type varchar(50), -- e.g., 'online', 'in-person', 'hybrid'
    location_address text,
    location_city varchar(100),
    location_state varchar(100),
    location_country varchar(100),
    online_url text,
    visibility varchar(50) DEFAULT 'public', -- 'public', 'private', 'unlisted'
    status varchar(50) DEFAULT 'scheduled', -- 'scheduled', 'ongoing', 'completed', 'cancelled'
    banner_image_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT time_check CHECK (end_time > start_time)
);
COMMENT ON TABLE public.events IS 'Events organized on the platform';
CREATE TRIGGER update_events_timestamp BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_events_organizer ON public.events(organizer_type, organizer_id);
CREATE INDEX idx_events_category_id ON public.events(category_id);
CREATE INDEX idx_events_start_time ON public.events(start_time);
CREATE INDEX idx_events_location ON public.events(location_country, location_state, location_city);

CREATE TABLE public.event_attendees (
    attendee_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    registration_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'registered', -- 'registered', 'attended', 'cancelled', 'waitlisted'
    ticket_id uuid, -- Optional: reference to event_tickets
    CONSTRAINT unique_event_attendee UNIQUE (event_id, user_id)
);
COMMENT ON TABLE public.event_attendees IS 'Users attending events';
CREATE INDEX idx_event_attendees_event_id ON public.event_attendees(event_id);
CREATE INDEX idx_event_attendees_user_id ON public.event_attendees(user_id);

CREATE TABLE public.event_speakers (
    speaker_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    user_id uuid REFERENCES public.users(user_id) ON DELETE CASCADE, -- If speaker is a platform user
    speaker_name varchar(255), -- If speaker is external
    speaker_title varchar(255),
    speaker_bio text,
    speaker_photo_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.event_speakers IS 'Speakers presenting at events';
CREATE TRIGGER update_event_speakers_timestamp BEFORE UPDATE ON public.event_speakers FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_event_speakers_event_id ON public.event_speakers(event_id);

CREATE TABLE public.event_sponsors (
    sponsor_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    company_id uuid REFERENCES public.companies(company_id) ON DELETE CASCADE, -- If sponsor is a platform company
    sponsor_name varchar(255), -- If sponsor is external
    sponsorship_level varchar(100),
    sponsor_logo_url text,
    sponsor_website_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.event_sponsors IS 'Sponsors of events';
CREATE TRIGGER update_event_sponsors_timestamp BEFORE UPDATE ON public.event_sponsors FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_event_sponsors_event_id ON public.event_sponsors(event_id);

CREATE TABLE public.event_sessions (
    session_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    description text,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    location varchar(255), -- Room name or virtual link
    track varchar(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT time_check CHECK (end_time > start_time)
);
COMMENT ON TABLE public.event_sessions IS 'Individual sessions within an event';
CREATE TRIGGER update_event_sessions_timestamp BEFORE UPDATE ON public.event_sessions FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_event_sessions_event_id ON public.event_sessions(event_id, start_time);

-- Link speakers to sessions (Many-to-Many)
CREATE TABLE public.event_session_speakers (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    session_id uuid NOT NULL REFERENCES public.event_sessions(session_id) ON DELETE CASCADE,
    speaker_id uuid NOT NULL REFERENCES public.event_speakers(speaker_id) ON DELETE CASCADE,
    CONSTRAINT unique_session_speaker UNIQUE (session_id, speaker_id)
);
COMMENT ON TABLE public.event_session_speakers IS 'Mapping speakers to event sessions';
CREATE INDEX idx_event_session_speakers_session_id ON public.event_session_speakers(session_id);
CREATE INDEX idx_event_session_speakers_speaker_id ON public.event_session_speakers(speaker_id);

CREATE TABLE public.event_locations (
    location_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    location_name varchar(255) NOT NULL, -- e.g., 'Main Hall', 'Room 101'
    capacity integer,
    map_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.event_locations IS 'Specific locations/rooms within an in-person event venue';
CREATE TRIGGER update_event_locations_timestamp BEFORE UPDATE ON public.event_locations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_event_locations_event_id ON public.event_locations(event_id);

CREATE TABLE public.event_tickets (
    ticket_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    ticket_type_name varchar(100) NOT NULL, -- e.g., 'General Admission', 'VIP'
    price numeric(10,2) NOT NULL DEFAULT 0,
    currency varchar(3) DEFAULT 'USD',
    quantity_available integer,
    quantity_sold integer DEFAULT 0,
    sales_start_date timestamp with time zone,
    sales_end_date timestamp with time zone,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.event_tickets IS 'Ticket types available for an event';
CREATE TRIGGER update_event_tickets_timestamp BEFORE UPDATE ON public.event_tickets FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_event_tickets_event_id ON public.event_tickets(event_id);

-- Add ticket_id reference to event_attendees
ALTER TABLE public.event_attendees ADD CONSTRAINT fk_ticket FOREIGN KEY (ticket_id) REFERENCES public.event_tickets(ticket_id) ON DELETE SET NULL;

CREATE TABLE public.event_reviews (
    review_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    rating smallint NOT NULL,
    comment text,
    review_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    CONSTRAINT rating_check CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT approval_status_check CHECK (approval_status IN ('pending', 'approved', 'rejected', 'flagged'))
);
COMMENT ON TABLE public.event_reviews IS 'User reviews of events';
CREATE INDEX idx_event_reviews_event_id ON public.event_reviews(event_id);
CREATE INDEX idx_event_reviews_user_id ON public.event_reviews(user_id);

CREATE TABLE public.event_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE UNIQUE,
    view_count integer DEFAULT 0,
    registration_count integer DEFAULT 0,
    attendance_count integer DEFAULT 0,
    average_rating numeric(3,2),
    last_updated timestamp with time zone
);
COMMENT ON TABLE public.event_analytics IS 'Aggregated analytics for events';
CREATE TRIGGER update_event_analytics_timestamp BEFORE UPDATE ON public.event_analytics FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Learning System

CREATE TABLE public.course_categories (
    category_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    parent_category_id uuid REFERENCES public.course_categories(category_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.course_categories IS 'Categories for learning courses';
CREATE TRIGGER update_course_categories_timestamp BEFORE UPDATE ON public.course_categories FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.courses (
    course_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    title varchar(255) NOT NULL,
    description text,
    category_id uuid REFERENCES public.course_categories(category_id) ON DELETE SET NULL,
    instructor_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL, -- Assuming instructors are users
    difficulty_level varchar(50), -- e.g., 'beginner', 'intermediate', 'advanced'
    estimated_duration interval,
    language_code varchar(10) REFERENCES public.languages(language_code) ON DELETE RESTRICT,
    price numeric(10,2) DEFAULT 0,
    currency varchar(3) DEFAULT 'USD',
    banner_image_url text,
    introduction_video_url text,
    status varchar(50) DEFAULT 'draft', -- 'draft', 'published', 'archived'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.courses IS 'Online learning courses';
CREATE TRIGGER update_courses_timestamp BEFORE UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_courses_category_id ON public.courses(category_id);
CREATE INDEX idx_courses_instructor_id ON public.courses(instructor_id);
CREATE INDEX idx_courses_status ON public.courses(status);

CREATE TABLE public.course_modules (
    module_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    course_id uuid NOT NULL REFERENCES public.courses(course_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    description text,
    sequence_order integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.course_modules IS 'Modules within a course';
CREATE TRIGGER update_course_modules_timestamp BEFORE UPDATE ON public.course_modules FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_course_modules_course_id ON public.course_modules(course_id, sequence_order);

CREATE TABLE public.course_lessons (
    lesson_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    module_id uuid NOT NULL REFERENCES public.course_modules(module_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    lesson_type varchar(50) NOT NULL, -- e.g., 'video', 'text', 'quiz', 'assignment'
    content text, -- For text lessons
    video_url text,
    estimated_duration interval,
    sequence_order integer NOT NULL,
    is_previewable boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.course_lessons IS 'Individual lessons within a course module';
CREATE TRIGGER update_course_lessons_timestamp BEFORE UPDATE ON public.course_lessons FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_course_lessons_module_id ON public.course_lessons(module_id, sequence_order);

CREATE TABLE public.course_enrollments (
    enrollment_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    course_id uuid NOT NULL REFERENCES public.courses(course_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    enrollment_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    completion_date timestamp with time zone,
    status varchar(50) DEFAULT 'enrolled', -- 'enrolled', 'completed', 'dropped'
    progress_percentage numeric(5,2) DEFAULT 0,
    CONSTRAINT unique_course_enrollment UNIQUE (course_id, user_id),
    CONSTRAINT percentage_check CHECK (progress_percentage BETWEEN 0 AND 100)
);
COMMENT ON TABLE public.course_enrollments IS 'User enrollments in courses';
CREATE INDEX idx_course_enrollments_course_id ON public.course_enrollments(course_id);
CREATE INDEX idx_course_enrollments_user_id ON public.course_enrollments(user_id, enrollment_date DESC);

CREATE TABLE public.course_progress (
    progress_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    enrollment_id uuid NOT NULL REFERENCES public.course_enrollments(enrollment_id) ON DELETE CASCADE,
    lesson_id uuid NOT NULL REFERENCES public.course_lessons(lesson_id) ON DELETE CASCADE,
    completed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'completed', -- 'started', 'completed'
    CONSTRAINT unique_enrollment_lesson UNIQUE (enrollment_id, lesson_id)
);
COMMENT ON TABLE public.course_progress IS 'Tracking user progress through course lessons';
CREATE INDEX idx_course_progress_enrollment_id ON public.course_progress(enrollment_id);
CREATE INDEX idx_course_progress_lesson_id ON public.course_progress(lesson_id);

CREATE TABLE public.course_completions (
    completion_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    enrollment_id uuid NOT NULL REFERENCES public.course_enrollments(enrollment_id) ON DELETE CASCADE UNIQUE,
    completion_date timestamp with time zone NOT NULL,
    certificate_url text,
    grade numeric(5,2)
);
COMMENT ON TABLE public.course_completions IS 'Records of course completions';
CREATE INDEX idx_course_completions_enrollment_id ON public.course_completions(enrollment_id);

CREATE TABLE public.course_reviews (
    review_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    course_id uuid NOT NULL REFERENCES public.courses(course_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    rating smallint NOT NULL,
    comment text,
    review_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_anonymous boolean DEFAULT false,
    approval_status varchar(20) DEFAULT 'pending',
    CONSTRAINT rating_check CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT approval_status_check CHECK (approval_status IN ('pending', 'approved', 'rejected', 'flagged')),
    CONSTRAINT unique_course_review UNIQUE (course_id, user_id)
);
COMMENT ON TABLE public.course_reviews IS 'User reviews of courses';
CREATE INDEX idx_course_reviews_course_id ON public.course_reviews(course_id);
CREATE INDEX idx_course_reviews_user_id ON public.course_reviews(user_id);

CREATE TABLE public.course_instructors (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    course_id uuid NOT NULL REFERENCES public.courses(course_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE, -- Instructor user ID
    role varchar(50) DEFAULT 'primary', -- 'primary', 'assistant'
    CONSTRAINT unique_course_instructor UNIQUE (course_id, user_id)
);
COMMENT ON TABLE public.course_instructors IS 'Mapping instructors to courses';
CREATE INDEX idx_course_instructors_course_id ON public.course_instructors(course_id);
CREATE INDEX idx_course_instructors_user_id ON public.course_instructors(user_id);

CREATE TABLE public.course_materials (
    material_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    lesson_id uuid NOT NULL REFERENCES public.course_lessons(lesson_id) ON DELETE CASCADE,
    title varchar(255) NOT NULL,
    material_type varchar(50) NOT NULL, -- e.g., 'document', 'link', 'code_snippet'
    material_url text,
    material_content text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.course_materials IS 'Supplementary materials for course lessons';
CREATE TRIGGER update_course_materials_timestamp BEFORE UPDATE ON public.course_materials FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_course_materials_lesson_id ON public.course_materials(lesson_id);

CREATE TABLE public.course_quizzes (
    quiz_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    lesson_id uuid NOT NULL REFERENCES public.course_lessons(lesson_id) ON DELETE CASCADE UNIQUE,
    title varchar(255) NOT NULL,
    description text,
    time_limit interval,
    passing_score numeric(5,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.course_quizzes IS 'Quizzes associated with course lessons';
CREATE TRIGGER update_course_quizzes_timestamp BEFORE UPDATE ON public.course_quizzes FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.quiz_questions (
    question_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    quiz_id uuid NOT NULL REFERENCES public.course_quizzes(quiz_id) ON DELETE CASCADE,
    question_text text NOT NULL,
    question_type varchar(50) NOT NULL, -- e.g., 'multiple_choice', 'true_false', 'short_answer'
    points smallint DEFAULT 1,
    sequence_order integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.quiz_questions IS 'Questions within a quiz';
CREATE TRIGGER update_quiz_questions_timestamp BEFORE UPDATE ON public.quiz_questions FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_quiz_questions_quiz_id ON public.quiz_questions(quiz_id, sequence_order);

CREATE TABLE public.quiz_answers (
    answer_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    question_id uuid NOT NULL REFERENCES public.quiz_questions(question_id) ON DELETE CASCADE,
    answer_text text NOT NULL,
    is_correct boolean NOT NULL,
    explanation text,
    sequence_order integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.quiz_answers IS 'Possible answers for quiz questions';
CREATE TRIGGER update_quiz_answers_timestamp BEFORE UPDATE ON public.quiz_answers FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_quiz_answers_question_id ON public.quiz_answers(question_id, sequence_order);

CREATE TABLE public.quiz_attempts (
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    quiz_id uuid NOT NULL REFERENCES public.course_quizzes(quiz_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    end_time timestamp with time zone,
    score numeric(5,2),
    status varchar(50) DEFAULT 'in_progress', -- 'in_progress', 'completed'
    CONSTRAINT unique_quiz_attempt UNIQUE (quiz_id, user_id, start_time) -- Allow retries
);
COMMENT ON TABLE public.quiz_attempts IS 'User attempts at taking quizzes';
CREATE INDEX idx_quiz_attempts_quiz_id ON public.quiz_attempts(quiz_id);
CREATE INDEX idx_quiz_attempts_user_id ON public.quiz_attempts(user_id, start_time DESC);

CREATE TABLE public.quiz_attempt_answers (
    attempt_answer_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    attempt_id uuid NOT NULL REFERENCES public.quiz_attempts(attempt_id) ON DELETE CASCADE,
    question_id uuid NOT NULL REFERENCES public.quiz_questions(question_id) ON DELETE CASCADE,
    selected_answer_id uuid REFERENCES public.quiz_answers(answer_id) ON DELETE SET NULL, -- For multiple choice
    answer_text text, -- For short answer
    is_correct boolean,
    points_awarded smallint
);
COMMENT ON TABLE public.quiz_attempt_answers IS 'User answers submitted during a quiz attempt';
CREATE INDEX idx_quiz_attempt_answers_attempt_id ON public.quiz_attempt_answers(attempt_id);
CREATE INDEX idx_quiz_attempt_answers_question_id ON public.quiz_attempt_answers(question_id);

CREATE TABLE public.learning_paths (
    path_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    title varchar(255) NOT NULL,
    description text,
    created_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    is_public boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.learning_paths IS 'Curated learning paths combining multiple courses';
CREATE TRIGGER update_learning_paths_timestamp BEFORE UPDATE ON public.learning_paths FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.learning_path_courses (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    path_id uuid NOT NULL REFERENCES public.learning_paths(path_id) ON DELETE CASCADE,
    course_id uuid NOT NULL REFERENCES public.courses(course_id) ON DELETE CASCADE,
    sequence_order integer NOT NULL,
    CONSTRAINT unique_path_course UNIQUE (path_id, course_id)
);
COMMENT ON TABLE public.learning_path_courses IS 'Mapping courses to learning paths';
CREATE INDEX idx_learning_path_courses_path_id ON public.learning_path_courses(path_id, sequence_order);
CREATE INDEX idx_learning_path_courses_course_id ON public.learning_path_courses(course_id);

CREATE TABLE public.learning_achievements (
    achievement_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    achievement_type varchar(50) NOT NULL, -- e.g., 'course_completion', 'path_completion', 'quiz_mastery'
    related_entity_id uuid NOT NULL, -- e.g., course_id, path_id, quiz_id
    achieved_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    badge_url text,
    title varchar(255)
);
COMMENT ON TABLE public.learning_achievements IS 'Achievements earned by users in the learning system';
CREATE INDEX idx_learning_achievements_user_id ON public.learning_achievements(user_id, achieved_at DESC);

-- Job System Extensions

CREATE TABLE public.job_categories (
    category_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text,
    parent_category_id uuid REFERENCES public.job_categories(category_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_categories IS 'Categories for job listings';
CREATE TRIGGER update_job_categories_timestamp BEFORE UPDATE ON public.job_categories FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Add category_id to job_listings
ALTER TABLE public.job_listings ADD COLUMN category_id uuid REFERENCES public.job_categories(category_id) ON DELETE SET NULL;
CREATE INDEX idx_job_listings_category_id ON public.job_listings(category_id);

CREATE TABLE public.job_skills (
    job_skill_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    job_listing_id uuid NOT NULL REFERENCES public.job_listings(job_listing_id) ON DELETE CASCADE,
    skill_id integer NOT NULL REFERENCES public.skills(skill_id) ON DELETE RESTRICT,
    importance_level varchar(50), -- e.g., 'required', 'preferred'
    CONSTRAINT unique_job_skill UNIQUE (job_listing_id, skill_id)
);
COMMENT ON TABLE public.job_skills IS 'Skills required or preferred for a job listing';
CREATE INDEX idx_job_skills_job_listing_id ON public.job_skills(job_listing_id);
CREATE INDEX idx_job_skills_skill_id ON public.job_skills(skill_id);

CREATE TABLE public.job_application_stages (
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    stage_name varchar(100) NOT NULL,
    sequence_order integer NOT NULL,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_stage_name UNIQUE (company_id, stage_name)
);
COMMENT ON TABLE public.job_application_stages IS 'Customizable stages for job application pipelines';
CREATE TRIGGER update_job_application_stages_timestamp BEFORE UPDATE ON public.job_application_stages FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_job_application_stages_company_id ON public.job_application_stages(company_id, sequence_order);

-- Add stage_id to job_applications
ALTER TABLE public.job_applications ADD COLUMN stage_id uuid REFERENCES public.job_application_stages(stage_id) ON DELETE SET NULL;
CREATE INDEX idx_job_applications_stage_id ON public.job_applications(stage_id);

CREATE TABLE public.job_application_notes (
    note_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES public.job_applications(application_id) ON DELETE CASCADE,
    author_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE, -- Recruiter/Hiring Manager
    note_text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    visibility varchar(50) DEFAULT 'internal' -- 'internal', 'shared_with_applicant'
);
COMMENT ON TABLE public.job_application_notes IS 'Internal notes on job applications';
CREATE TRIGGER update_job_application_notes_timestamp BEFORE UPDATE ON public.job_application_notes FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_job_application_notes_application_id ON public.job_application_notes(application_id);

CREATE TABLE public.job_interviews (
    interview_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES public.job_applications(application_id) ON DELETE CASCADE,
    interviewer_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    interview_type varchar(50), -- e.g., 'phone_screen', 'technical', 'behavioral', 'panel'
    scheduled_time timestamp with time zone,
    duration interval,
    location varchar(255), -- Physical or virtual link
    feedback text,
    rating smallint,
    status varchar(50) DEFAULT 'scheduled', -- 'scheduled', 'completed', 'cancelled'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_interviews IS 'Scheduled interviews for job applications';
CREATE TRIGGER update_job_interviews_timestamp BEFORE UPDATE ON public.job_interviews FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_job_interviews_application_id ON public.job_interviews(application_id);
CREATE INDEX idx_job_interviews_interviewer_id ON public.job_interviews(interviewer_id);

CREATE TABLE public.job_offers (
    offer_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES public.job_applications(application_id) ON DELETE CASCADE UNIQUE,
    offer_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expiry_date timestamp with time zone,
    salary_offered numeric(12,2),
    bonus_offered numeric(12,2),
    stock_options_offered text,
    benefits_summary text,
    status varchar(50) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'rescinded'
    response_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_offers IS 'Job offers extended to applicants';
CREATE TRIGGER update_job_offers_timestamp BEFORE UPDATE ON public.job_offers FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.job_rejections (
    rejection_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES public.job_applications(application_id) ON DELETE CASCADE UNIQUE,
    rejection_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    rejection_reason text,
    feedback_provided text,
    rejected_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_rejections IS 'Rejection details for job applications';
CREATE TRIGGER update_job_rejections_timestamp BEFORE UPDATE ON public.job_rejections FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.job_saved_searches (
    search_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    search_name varchar(100) NOT NULL,
    search_query jsonb NOT NULL, -- Store search parameters as JSON
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_saved_searches IS 'User saved job search criteria';
CREATE TRIGGER update_job_saved_searches_timestamp BEFORE UPDATE ON public.job_saved_searches FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_job_saved_searches_user_id ON public.job_saved_searches(user_id);

CREATE TABLE public.job_alerts (
    alert_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    saved_search_id uuid REFERENCES public.job_saved_searches(search_id) ON DELETE CASCADE,
    alert_frequency varchar(50) DEFAULT 'daily', -- 'daily', 'weekly', 'instant'
    last_sent_at timestamp with time zone,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.job_alerts IS 'Job alert subscriptions based on saved searches';
CREATE TRIGGER update_job_alerts_timestamp BEFORE UPDATE ON public.job_alerts FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_job_alerts_user_id ON public.job_alerts(user_id, is_active);

CREATE TABLE public.job_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    job_listing_id uuid NOT NULL REFERENCES public.job_listings(job_listing_id) ON DELETE CASCADE UNIQUE,
    view_count integer DEFAULT 0,
    application_count integer DEFAULT 0,
    unique_applicant_count integer DEFAULT 0,
    time_to_fill interval,
    source_of_hire_distribution jsonb,
    last_updated timestamp with time zone
);
COMMENT ON TABLE public.job_analytics IS 'Analytics for individual job listings';
CREATE TRIGGER update_job_analytics_timestamp BEFORE UPDATE ON public.job_analytics FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.recruiter_profiles (
    recruiter_profile_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE UNIQUE,
    company_id uuid REFERENCES public.companies(company_id) ON DELETE SET NULL,
    specialization text,
    years_experience smallint,
    contact_email varchar(255),
    contact_phone varchar(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.recruiter_profiles IS 'Profiles for users acting as recruiters';
CREATE TRIGGER update_recruiter_profiles_timestamp BEFORE UPDATE ON public.recruiter_profiles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_recruiter_profiles_company_id ON public.recruiter_profiles(company_id);

CREATE TABLE public.candidate_pools (
    pool_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    recruiter_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    pool_name varchar(100) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.candidate_pools IS 'Pools of potential candidates curated by recruiters';
CREATE TRIGGER update_candidate_pools_timestamp BEFORE UPDATE ON public.candidate_pools FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_candidate_pools_recruiter_id ON public.candidate_pools(recruiter_id);

CREATE TABLE public.candidate_pool_members (
    member_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    pool_id uuid NOT NULL REFERENCES public.candidate_pools(pool_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    CONSTRAINT unique_pool_candidate UNIQUE (pool_id, user_id)
);
COMMENT ON TABLE public.candidate_pool_members IS 'Users added to candidate pools';
CREATE INDEX idx_candidate_pool_members_pool_id ON public.candidate_pool_members(pool_id);
CREATE INDEX idx_candidate_pool_members_user_id ON public.candidate_pool_members(user_id);

CREATE TABLE public.candidate_notes (
    note_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    candidate_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    author_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE, -- Recruiter
    note_text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.candidate_notes IS 'Internal notes about potential candidates';
CREATE TRIGGER update_candidate_notes_timestamp BEFORE UPDATE ON public.candidate_notes FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_candidate_notes_candidate_user_id ON public.candidate_notes(candidate_user_id);

CREATE TABLE public.candidate_tags (
    tag_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    tag_name varchar(100) NOT NULL UNIQUE,
    created_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.candidate_tags IS 'Tags used to categorize candidates';

CREATE TABLE public.candidate_tag_map (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    candidate_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    tag_id uuid NOT NULL REFERENCES public.candidate_tags(tag_id) ON DELETE CASCADE,
    assigned_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_candidate_tag UNIQUE (candidate_user_id, tag_id)
);
COMMENT ON TABLE public.candidate_tag_map IS 'Mapping tags to candidates';
CREATE INDEX idx_candidate_tag_map_candidate_user_id ON public.candidate_tag_map(candidate_user_id);
CREATE INDEX idx_candidate_tag_map_tag_id ON public.candidate_tag_map(tag_id);

-- Company Extensions

CREATE TABLE public.company_locations (
    location_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    location_name varchar(100), -- e.g., 'HQ', 'Sales Office'
    address_line1 varchar(255),
    address_line2 varchar(255),
    city varchar(100),
    state varchar(100),
    postal_code varchar(20),
    country varchar(100),
    phone_number varchar(50),
    is_primary boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_locations IS 'Physical locations of company offices';
CREATE TRIGGER update_company_locations_timestamp BEFORE UPDATE ON public.company_locations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_locations_company_id ON public.company_locations(company_id);

CREATE TABLE public.company_departments (
    department_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    department_name varchar(100) NOT NULL,
    parent_department_id uuid REFERENCES public.company_departments(department_id) ON DELETE SET NULL,
    manager_id uuid REFERENCES public.employees(employee_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_department_name UNIQUE (company_id, department_name, parent_department_id)
);
COMMENT ON TABLE public.company_departments IS 'Departments within a company';
CREATE TRIGGER update_company_departments_timestamp BEFORE UPDATE ON public.company_departments FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_departments_company_id ON public.company_departments(company_id);

-- Add department_id to employees table
ALTER TABLE public.employees ADD COLUMN department_id uuid REFERENCES public.company_departments(department_id) ON DELETE SET NULL;
CREATE INDEX idx_employees_department_id ON public.employees(department_id);

CREATE TABLE public.company_teams (
    team_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    department_id uuid REFERENCES public.company_departments(department_id) ON DELETE SET NULL,
    team_name varchar(100) NOT NULL,
    team_lead_id uuid REFERENCES public.employees(employee_id) ON DELETE SET NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_team_name UNIQUE (company_id, team_name)
);
COMMENT ON TABLE public.company_teams IS 'Teams within a company/department';
CREATE TRIGGER update_company_teams_timestamp BEFORE UPDATE ON public.company_teams FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_teams_company_id ON public.company_teams(company_id);
CREATE INDEX idx_company_teams_department_id ON public.company_teams(department_id);

-- Add team_id to employees table
ALTER TABLE public.employees ADD COLUMN team_id uuid REFERENCES public.company_teams(team_id) ON DELETE SET NULL;
CREATE INDEX idx_employees_team_id ON public.employees(team_id);

CREATE TABLE public.company_products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    product_name varchar(255) NOT NULL,
    description text,
    product_url text,
    launch_date date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_products IS 'Products offered by the company';
CREATE TRIGGER update_company_products_timestamp BEFORE UPDATE ON public.company_products FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_products_company_id ON public.company_products(company_id);

CREATE TABLE public.company_services (
    service_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    service_name varchar(255) NOT NULL,
    description text,
    service_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_services IS 'Services offered by the company';
CREATE TRIGGER update_company_services_timestamp BEFORE UPDATE ON public.company_services FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_services_company_id ON public.company_services(company_id);

CREATE TABLE public.company_competitors (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    competitor_company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    notes text,
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_competition CHECK (company_id <> competitor_company_id),
    CONSTRAINT unique_company_competitor UNIQUE (company_id, competitor_company_id)
);
COMMENT ON TABLE public.company_competitors IS 'Competitors of the company';
CREATE INDEX idx_company_competitors_company_id ON public.company_competitors(company_id);
CREATE INDEX idx_company_competitors_competitor_id ON public.company_competitors(competitor_company_id);

CREATE TABLE public.company_investors (
    investor_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    investor_name varchar(255) NOT NULL,
    investor_type varchar(50), -- e.g., 'VC', 'Angel', 'Firm'
    website_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_investors IS 'Investors (individuals or firms)';
CREATE TRIGGER update_company_investors_timestamp BEFORE UPDATE ON public.company_investors FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.company_funding_rounds (
    round_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    round_type varchar(50) NOT NULL, -- e.g., 'Seed', 'Series A', 'IPO'
    funding_date date NOT NULL,
    amount_raised numeric(15,2),
    currency varchar(3) DEFAULT 'USD',
    valuation numeric(18,2),
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_funding_rounds IS 'Funding rounds raised by the company';
CREATE TRIGGER update_company_funding_rounds_timestamp BEFORE UPDATE ON public.company_funding_rounds FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_funding_rounds_company_id ON public.company_funding_rounds(company_id, funding_date DESC);

-- Link investors to funding rounds (Many-to-Many)
CREATE TABLE public.funding_round_investors (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    round_id uuid NOT NULL REFERENCES public.company_funding_rounds(round_id) ON DELETE CASCADE,
    investor_id uuid NOT NULL REFERENCES public.company_investors(investor_id) ON DELETE CASCADE,
    is_lead_investor boolean DEFAULT false,
    CONSTRAINT unique_round_investor UNIQUE (round_id, investor_id)
);
COMMENT ON TABLE public.funding_round_investors IS 'Mapping investors to funding rounds';
CREATE INDEX idx_funding_round_investors_round_id ON public.funding_round_investors(round_id);
CREATE INDEX idx_funding_round_investors_investor_id ON public.funding_round_investors(investor_id);

CREATE TABLE public.company_acquisitions (
    acquisition_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    acquiring_company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    acquired_company_name varchar(255) NOT NULL,
    acquired_company_id uuid REFERENCES public.companies(company_id) ON DELETE SET NULL, -- If acquired company is on platform
    acquisition_date date NOT NULL,
    price numeric(15,2),
    currency varchar(3) DEFAULT 'USD',
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_acquisitions IS 'Acquisitions made by the company';
CREATE TRIGGER update_company_acquisitions_timestamp BEFORE UPDATE ON public.company_acquisitions FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_acquisitions_acquiring_id ON public.company_acquisitions(acquiring_company_id, acquisition_date DESC);

CREATE TABLE public.company_partnerships (
    partnership_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    partner_company_name varchar(255) NOT NULL,
    partner_company_id uuid REFERENCES public.companies(company_id) ON DELETE SET NULL, -- If partner is on platform
    partnership_type varchar(100),
    start_date date,
    end_date date,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.company_partnerships IS 'Partnerships involving the company';
CREATE TRIGGER update_company_partnerships_timestamp BEFORE UPDATE ON public.company_partnerships FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_partnerships_company_id ON public.company_partnerships(company_id);

CREATE TABLE public.company_social_profiles (
    profile_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE,
    platform_name varchar(50) NOT NULL, -- e.g., 'LinkedIn', 'Twitter', 'Facebook'
    profile_url text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_company_social_profile UNIQUE (company_id, platform_name)
);
COMMENT ON TABLE public.company_social_profiles IS 'Social media profiles of the company';
CREATE TRIGGER update_company_social_profiles_timestamp BEFORE UPDATE ON public.company_social_profiles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_company_social_profiles_company_id ON public.company_social_profiles(company_id);

CREATE TABLE public.company_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(company_id) ON DELETE CASCADE UNIQUE,
    profile_view_count integer DEFAULT 0,
    follower_count integer DEFAULT 0,
    employee_count integer DEFAULT 0,
    job_posting_count integer DEFAULT 0,
    engagement_score numeric(5,2) DEFAULT 0,
    last_updated timestamp with time zone
);
COMMENT ON TABLE public.company_analytics IS 'Aggregated analytics for company profiles';
CREATE TRIGGER update_company_analytics_timestamp BEFORE UPDATE ON public.company_analytics FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Groups and Communities

CREATE TABLE public.groups (
    group_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_name varchar(255) NOT NULL,
    description text,
    group_type varchar(50) DEFAULT 'public', -- 'public', 'private', 'hidden'
    created_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    banner_image_url text,
    logo_url text,
    rules text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.groups IS 'User groups and communities';
CREATE TRIGGER update_groups_timestamp BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_groups_created_by ON public.groups(created_by);
CREATE INDEX idx_groups_type ON public.groups(group_type);

CREATE TABLE public.group_members (
    membership_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    role varchar(50) DEFAULT 'member', -- 'member', 'admin', 'moderator'
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'active', -- 'active', 'pending', 'banned'
    CONSTRAINT unique_group_member UNIQUE (group_id, user_id)
);
COMMENT ON TABLE public.group_members IS 'Membership information for groups';
CREATE INDEX idx_group_members_group_id ON public.group_members(group_id, status);
CREATE INDEX idx_group_members_user_id ON public.group_members(user_id);

CREATE TABLE public.group_roles (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    role_name varchar(50) NOT NULL,
    permissions jsonb, -- Store permissions as JSON
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_group_role_name UNIQUE (group_id, role_name)
);
COMMENT ON TABLE public.group_roles IS 'Custom roles within a group';
CREATE TRIGGER update_group_roles_timestamp BEFORE UPDATE ON public.group_roles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE INDEX idx_group_roles_group_id ON public.group_roles(group_id);

-- Add role_id to group_members
ALTER TABLE public.group_members ADD COLUMN group_role_id uuid REFERENCES public.group_roles(role_id) ON DELETE SET NULL;
CREATE INDEX idx_group_members_role_id ON public.group_members(group_role_id);

CREATE TABLE public.group_content (
    group_content_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    posted_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    posted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_pinned boolean DEFAULT false,
    CONSTRAINT unique_group_content UNIQUE (group_id, content_id)
);
COMMENT ON TABLE public.group_content IS 'Content posted within groups';
CREATE INDEX idx_group_content_group_id ON public.group_content(group_id, posted_at DESC);
CREATE INDEX idx_group_content_content_id ON public.group_content(content_id);

CREATE TABLE public.group_events (
    group_event_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    event_id uuid NOT NULL REFERENCES public.events(event_id) ON DELETE CASCADE,
    created_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_group_event UNIQUE (group_id, event_id)
);
COMMENT ON TABLE public.group_events IS 'Events associated with groups';
CREATE INDEX idx_group_events_group_id ON public.group_events(group_id);
CREATE INDEX idx_group_events_event_id ON public.group_events(event_id);

CREATE TABLE public.group_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE UNIQUE,
    allow_member_posts boolean DEFAULT true,
    post_approval_required boolean DEFAULT false,
    membership_approval_required boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.group_settings IS 'Settings specific to a group';
CREATE TRIGGER update_group_settings_timestamp BEFORE UPDATE ON public.group_settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.group_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE UNIQUE,
    member_count integer DEFAULT 0,
    active_member_count integer DEFAULT 0,
    post_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    engagement_rate numeric(5,2) DEFAULT 0,
    last_updated timestamp with time zone
);
COMMENT ON TABLE public.group_analytics IS 'Analytics for group activity';
CREATE TRIGGER update_group_analytics_timestamp BEFORE UPDATE ON public.group_analytics FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.group_invitations (
    invitation_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    invited_by uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    invited_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    invited_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    expires_at timestamp with time zone,
    CONSTRAINT unique_group_invitation UNIQUE (group_id, invited_user_id)
);
COMMENT ON TABLE public.group_invitations IS 'Invitations to join groups';
CREATE INDEX idx_group_invitations_group_id ON public.group_invitations(group_id);
CREATE INDEX idx_group_invitations_invited_user_id ON public.group_invitations(invited_user_id, status);

CREATE TABLE public.group_join_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    group_id uuid NOT NULL REFERENCES public.groups(group_id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    requested_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    reviewed_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    reviewed_at timestamp with time zone,
    CONSTRAINT unique_group_join_request UNIQUE (group_id, user_id)
);
COMMENT ON TABLE public.group_join_requests IS 'Requests from users to join private groups';
CREATE INDEX idx_group_join_requests_group_id ON public.group_join_requests(group_id, status);
CREATE INDEX idx_group_join_requests_user_id ON public.group_join_requests(user_id);

-- Analytics and Reporting Extensions

CREATE TABLE public.user_engagement_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    metric_date date NOT NULL DEFAULT CURRENT_DATE,
    time_spent_seconds integer DEFAULT 0,
    logins integer DEFAULT 0,
    profile_views integer DEFAULT 0,
    connections_made integer DEFAULT 0,
    content_posted integer DEFAULT 0,
    content_liked integer DEFAULT 0,
    content_commented integer DEFAULT 0,
    messages_sent integer DEFAULT 0,
    engagement_score numeric(5,2) DEFAULT 0,
    CONSTRAINT unique_user_engagement_date UNIQUE (user_id, metric_date)
);
COMMENT ON TABLE public.user_engagement_metrics IS 'Daily user engagement metrics';
CREATE INDEX idx_user_engagement_metrics_user_id ON public.user_engagement_metrics(user_id, metric_date DESC);

CREATE TABLE public.content_performance_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    content_id uuid NOT NULL REFERENCES public.contents(content_id) ON DELETE CASCADE,
    metric_date date NOT NULL DEFAULT CURRENT_DATE,
    views integer DEFAULT 0,
    likes integer DEFAULT 0,
    comments integer DEFAULT 0,
    shares integer DEFAULT 0,
    click_through_rate numeric(5,4),
    CONSTRAINT unique_content_performance_date UNIQUE (content_id, metric_date)
);
COMMENT ON TABLE public.content_performance_metrics IS 'Daily performance metrics for content items';
CREATE INDEX idx_content_performance_metrics_content_id ON public.content_performance_metrics(content_id, metric_date DESC);

CREATE TABLE public.job_market_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    analytic_date date NOT NULL DEFAULT CURRENT_DATE,
    industry_id integer REFERENCES public.industries(industry_id) ON DELETE SET NULL,
    location_country varchar(100),
    location_state varchar(100),
    location_city varchar(100),
    total_jobs_posted integer DEFAULT 0,
    total_applications integer DEFAULT 0,
    average_salary numeric(12,2),
    top_skills jsonb,
    top_companies jsonb,
    CONSTRAINT unique_job_market_analytic UNIQUE (analytic_date, industry_id, location_country, location_state, location_city)
);
COMMENT ON TABLE public.job_market_analytics IS 'Aggregated job market analytics';
CREATE INDEX idx_job_market_analytics_date ON public.job_market_analytics(analytic_date DESC);
CREATE INDEX idx_job_market_analytics_industry ON public.job_market_analytics(industry_id);
CREATE INDEX idx_job_market_analytics_location ON public.job_market_analytics(location_country, location_state, location_city);

CREATE TABLE public.industry_trends (
    trend_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    industry_id integer NOT NULL REFERENCES public.industries(industry_id) ON DELETE CASCADE,
    trend_date date NOT NULL DEFAULT CURRENT_DATE,
    trend_topic varchar(255) NOT NULL,
    sentiment_score numeric(3,2),
    related_keywords text[],
    source_urls text[],
    CONSTRAINT unique_industry_trend UNIQUE (industry_id, trend_date, trend_topic)
);
COMMENT ON TABLE public.industry_trends IS 'Trends identified within specific industries';
CREATE INDEX idx_industry_trends_industry_id ON public.industry_trends(industry_id, trend_date DESC);

CREATE TABLE public.network_analytics (
    analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    analytic_date date NOT NULL DEFAULT CURRENT_DATE,
    total_users integer,
    active_users integer,
    new_users integer,
    total_connections integer,
    average_connections_per_user numeric(8,2),
    network_density numeric(5,4),
    CONSTRAINT unique_network_analytic_date UNIQUE (analytic_date)
);
COMMENT ON TABLE public.network_analytics IS 'Overall platform network growth and density analytics';
CREATE INDEX idx_network_analytics_date ON public.network_analytics(analytic_date DESC);

CREATE TABLE public.search_analytics (
    search_analytic_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    search_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL, -- Null for anonymous searches
    search_query text NOT NULL,
    search_type varchar(50), -- e.g., 'user', 'job', 'content', 'company'
    result_count integer,
    clicked_result_id uuid,
    clicked_result_type varchar(50),
    session_id uuid,
    ip_address inet
);
COMMENT ON TABLE public.search_analytics IS 'Analytics on user search queries';
CREATE INDEX idx_search_analytics_timestamp ON public.search_analytics(search_timestamp DESC);
CREATE INDEX idx_search_analytics_user_id ON public.search_analytics(user_id);
CREATE INDEX idx_search_analytics_type ON public.search_analytics(search_type);

CREATE TABLE public.feature_usage_analytics (
    usage_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    usage_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    feature_name varchar(100) NOT NULL,
    action_name varchar(100) NOT NULL,
    metadata jsonb,
    session_id uuid
);
COMMENT ON TABLE public.feature_usage_analytics IS 'Tracking usage of specific platform features';
CREATE INDEX idx_feature_usage_analytics_timestamp ON public.feature_usage_analytics(usage_timestamp DESC);
CREATE INDEX idx_feature_usage_analytics_user_id ON public.feature_usage_analytics(user_id);
CREATE INDEX idx_feature_usage_analytics_feature ON public.feature_usage_analytics(feature_name, action_name);

CREATE TABLE public.revenue_analytics (
    revenue_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    analytic_date date NOT NULL DEFAULT CURRENT_DATE,
    revenue_source varchar(100), -- e.g., 'subscriptions', 'job_postings', 'ads'
    amount numeric(15,2) NOT NULL,
    currency varchar(3) DEFAULT 'USD',
    transaction_count integer,
    CONSTRAINT unique_revenue_analytic UNIQUE (analytic_date, revenue_source)
);
COMMENT ON TABLE public.revenue_analytics IS 'Platform revenue analytics';
CREATE INDEX idx_revenue_analytics_date ON public.revenue_analytics(analytic_date DESC);

CREATE TABLE public.retention_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    metric_date date NOT NULL DEFAULT CURRENT_DATE,
    cohort_date date NOT NULL,
    day_1_retention numeric(5,2),
    day_7_retention numeric(5,2),
    day_30_retention numeric(5,2),
    user_segment varchar(100), -- e.g., 'all', 'paid', 'free'
    CONSTRAINT unique_retention_metric UNIQUE (metric_date, cohort_date, user_segment)
);
COMMENT ON TABLE public.retention_metrics IS 'User retention metrics by cohort';
CREATE INDEX idx_retention_metrics_date ON public.retention_metrics(metric_date DESC);
CREATE INDEX idx_retention_metrics_cohort ON public.retention_metrics(cohort_date);

CREATE TABLE public.growth_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    metric_date date NOT NULL DEFAULT CURRENT_DATE,
    metric_name varchar(100) NOT NULL, -- e.g., 'mau', 'dau', 'wau', 'new_signups'
    metric_value integer NOT NULL,
    CONSTRAINT unique_growth_metric UNIQUE (metric_date, metric_name)
);
COMMENT ON TABLE public.growth_metrics IS 'Key platform growth metrics';
CREATE INDEX idx_growth_metrics_date ON public.growth_metrics(metric_date DESC, metric_name);

-- Platform Administration

CREATE TABLE public.admin_roles (
    admin_role_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    role_name varchar(50) NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.admin_roles IS 'Roles for platform administrators';
CREATE TRIGGER update_admin_roles_timestamp BEFORE UPDATE ON public.admin_roles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.admin_permissions (
    permission_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    permission_name varchar(100) NOT NULL UNIQUE, -- e.g., 'manage_users', 'moderate_content', 'view_analytics'
    description text,
    category varchar(50), -- e.g., 'user_management', 'content', 'settings'
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public.admin_permissions IS 'Specific permissions for admin actions';

-- Map permissions to admin roles (Many-to-Many)
CREATE TABLE public.admin_role_permissions (
    map_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    admin_role_id uuid NOT NULL REFERENCES public.admin_roles(admin_role_id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES public.admin_permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT unique_admin_role_permission UNIQUE (admin_role_id, permission_id)
);
COMMENT ON TABLE public.admin_role_permissions IS 'Mapping permissions to admin roles';
CREATE INDEX idx_admin_role_permissions_role_id ON public.admin_role_permissions(admin_role_id);
CREATE INDEX idx_admin_role_permissions_permission_id ON public.admin_role_permissions(permission_id);

-- Assign admin roles to users
ALTER TABLE public.user_roles ADD COLUMN admin_role_id uuid REFERENCES public.admin_roles(admin_role_id) ON DELETE SET NULL;
COMMENT ON COLUMN public.user_roles.admin_role_id IS 'Admin role assigned to the user (if applicable)';
CREATE INDEX idx_user_roles_admin_role_id ON public.user_roles(admin_role_id);

CREATE TABLE public.admin_actions (
    action_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    admin_user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE RESTRICT,
    action_type varchar(100) NOT NULL,
    target_entity_type varchar(50),
    target_entity_id uuid,
    action_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    details jsonb,
    ip_address inet
);
COMMENT ON TABLE public.admin_actions IS 'Log of actions performed by administrators';
CREATE INDEX idx_admin_actions_admin_user_id ON public.admin_actions(admin_user_id);
CREATE INDEX idx_admin_actions_timestamp ON public.admin_actions(action_timestamp DESC);
CREATE INDEX idx_admin_actions_target ON public.admin_actions(target_entity_type, target_entity_id);

CREATE TABLE public.admin_settings (
    setting_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    setting_key varchar(100) NOT NULL UNIQUE,
    setting_value text NOT NULL,
    description text,
    last_updated_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.admin_settings IS 'Platform-wide administrative settings';
CREATE TRIGGER update_admin_settings_timestamp BEFORE UPDATE ON public.admin_settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.system_configurations (
    config_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    config_key varchar(100) NOT NULL UNIQUE,
    config_value text NOT NULL,
    description text,
    is_encrypted boolean DEFAULT false,
    last_updated_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone
);
COMMENT ON TABLE public.system_configurations IS 'System configuration parameters';
CREATE TRIGGER update_system_configurations_timestamp BEFORE UPDATE ON public.system_configurations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.feature_flags (
    flag_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    flag_name varchar(100) NOT NULL UNIQUE,
    description text,
    is_enabled boolean DEFAULT false,
    rollout_percentage smallint DEFAULT 0,
    target_users uuid[], -- Specific users to enable for
    target_groups uuid[], -- Specific groups to enable for
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT percentage_check CHECK (rollout_percentage BETWEEN 0 AND 100)
);
COMMENT ON TABLE public.feature_flags IS 'Flags for enabling/disabling features';
CREATE TRIGGER update_feature_flags_timestamp BEFORE UPDATE ON public.feature_flags FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TABLE public.maintenance_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    description text NOT NULL,
    performed_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    status varchar(50) NOT NULL DEFAULT 'completed',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_time_range CHECK (
        end_time IS NULL OR 
        end_time >= start_time
    ),
    CONSTRAINT valid_status CHECK (
        status IN ('scheduled', 'in_progress', 'completed', 'failed')
    )
);

-- Create a trigger to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_maintenance_log_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_maintenance_logs_timestamp
BEFORE UPDATE ON public.maintenance_logs
FOR EACH ROW
EXECUTE FUNCTION public.update_maintenance_log_timestamp();

COMMENT ON TABLE public.maintenance_logs IS 'Logs of system maintenance activities';
CREATE INDEX idx_maintenance_logs_start_time ON public.maintenance_logs(start_time DESC);

CREATE TABLE public.error_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    log_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    error_level varchar(20) NOT NULL, -- 'debug', 'info', 'warning', 'error', 'critical'
    error_message text NOT NULL,
    stack_trace text,
    source_component varchar(100),
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    request_id uuid,
    ip_address inet
);
COMMENT ON TABLE public.error_logs IS 'System error logs';
CREATE INDEX idx_error_logs_timestamp ON public.error_logs(log_timestamp DESC);
CREATE INDEX idx_error_logs_level ON public.error_logs(error_level);

CREATE TABLE public.performance_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    metric_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    metric_name varchar(100) NOT NULL, -- e.g., 'avg_request_time', 'db_query_time', 'cpu_usage'
    metric_value numeric(10,4) NOT NULL,
    unit varchar(20), -- e.g., 'ms', '%'
    server_hostname varchar(100),
    component_name varchar(100)
);
COMMENT ON TABLE public.performance_metrics IS 'System performance metrics';
CREATE INDEX idx_performance_metrics_timestamp ON public.performance_metrics(metric_timestamp DESC);
CREATE INDEX idx_performance_metrics_name ON public.performance_metrics(metric_name);

CREATE TABLE public.security_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    log_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    event_type varchar(100) NOT NULL, -- e.g., 'failed_login', 'permission_change', 'suspicious_activity'
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    ip_address inet,
    details jsonb,
    severity varchar(20) DEFAULT 'info' -- 'info', 'low', 'medium', 'high', 'critical'
);
COMMENT ON TABLE public.security_logs IS 'Security-related event logs';
CREATE INDEX idx_security_logs_timestamp ON public.security_logs(log_timestamp DESC);
CREATE INDEX idx_security_logs_event_type ON public.security_logs(event_type);
CREATE INDEX idx_security_logs_user_id ON public.security_logs(user_id);

CREATE TABLE public.audit_trails (
    audit_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    audit_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    action varchar(100) NOT NULL, -- e.g., 'create', 'update', 'delete'
    table_name varchar(100) NOT NULL,
    record_id uuid,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text
);
COMMENT ON TABLE public.audit_trails IS 'Detailed audit trail for critical data changes';
CREATE INDEX idx_audit_trails_timestamp ON public.audit_trails(audit_timestamp DESC);
CREATE INDEX idx_audit_trails_user_id ON public.audit_trails(user_id);
CREATE INDEX idx_audit_trails_table_record ON public.audit_trails(table_name, record_id);

---
-- PostgreSQL Professional Network Schema Enhancements
-- Focusing on GDPR Compliance, Data Quality Management, and Comprehensive Audit Framework

-- =============================================
-- GDPR COMPLIANCE ENHANCEMENTS
-- =============================================

-- 1. Data Subject Rights Management Table
CREATE TABLE public.data_subject_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    request_type varchar(50) NOT NULL,
    request_details jsonb NOT NULL,
    request_status varchar(50) DEFAULT 'pending' NOT NULL,
    requested_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed_at timestamp with time zone,
    processed_by uuid REFERENCES public.users(user_id),
    response_details jsonb,
    retention_expires_at timestamp with time zone,
    CONSTRAINT request_type_check CHECK (request_type IN (
        'access', 'rectification', 'erasure', 'restriction', 'portability',
        'objection', 'automated_decision', 'consent_withdrawal'
    )),
    CONSTRAINT request_status_check CHECK (request_status IN (
        'pending', 'in_progress', 'completed', 'rejected', 'cancelled'
    ))
);

COMMENT ON TABLE public.data_subject_requests IS 'Tracks and manages GDPR data subject rights requests';

CREATE INDEX idx_data_subject_requests_user_id ON public.data_subject_requests(user_id);
CREATE INDEX idx_data_subject_requests_status ON public.data_subject_requests(request_status);
CREATE INDEX idx_data_subject_requests_type ON public.data_subject_requests(request_type);

-- 2. Consent Management System
CREATE TABLE public.consent_purposes (
    purpose_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text NOT NULL,
    is_essential boolean DEFAULT false NOT NULL,
    legal_basis varchar(50) NOT NULL,
    retention_period interval,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT legal_basis_check CHECK (legal_basis IN (
        'consent', 'contract', 'legal_obligation', 'vital_interest',
        'public_interest', 'legitimate_interest'
    ))
);

COMMENT ON TABLE public.consent_purposes IS 'Defines purposes for which user consent may be requested';

CREATE TRIGGER update_consent_purposes_timestamp
BEFORE UPDATE ON public.consent_purposes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert essential consent purposes
INSERT INTO public.consent_purposes (name, description, is_essential, legal_basis) VALUES
('account_management', 'Essential processing for account creation and management', true, 'contract'),
('security', 'Security and fraud prevention measures', true, 'legitimate_interest'),
('marketing_email', 'Email marketing communications', false, 'consent'),
('analytics', 'Website and service usage analytics', false, 'consent'),
('third_party_sharing', 'Sharing data with third-party partners', false, 'consent'),
('profiling', 'Personalization and profile enrichment', false, 'consent');

CREATE TABLE public.user_consents (
    consent_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    purpose_id integer NOT NULL REFERENCES public.consent_purposes(purpose_id) ON DELETE RESTRICT,
    is_granted boolean NOT NULL,
    consent_version varchar(50) NOT NULL,
    granted_at timestamp with time zone,
    revoked_at timestamp with time zone,
    expires_at timestamp with time zone,
    ip_address inet,
    user_agent text,
    consent_proof text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_user_purpose UNIQUE (user_id, purpose_id)
);

COMMENT ON TABLE public.user_consents IS 'Records user consent decisions for various processing purposes';

CREATE TRIGGER update_user_consents_timestamp
BEFORE UPDATE ON public.user_consents
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_user_consents_user_id ON public.user_consents(user_id);
CREATE INDEX idx_user_consents_purpose_id ON public.user_consents(purpose_id);
CREATE INDEX idx_user_consents_granted ON public.user_consents(is_granted);

-- 3. Data Retention Policy Table
CREATE TABLE public.data_retention_policies (
    policy_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name varchar(100) NOT NULL,
    column_name varchar(100),
    retention_period interval NOT NULL,
    anonymization_strategy varchar(50),
    legal_basis text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_table_column UNIQUE (table_name, column_name),
    CONSTRAINT anonymization_strategy_check CHECK (anonymization_strategy IN (
        'deletion', 'nullify', 'pseudonymize', 'aggregate', 'hash', 'truncate'
    ))
);

COMMENT ON TABLE public.data_retention_policies IS 'Defines data retention periods and anonymization strategies';

CREATE TRIGGER update_data_retention_policies_timestamp
BEFORE UPDATE ON public.data_retention_policies
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert sample retention policies
INSERT INTO public.data_retention_policies (
    table_name, column_name, retention_period, anonymization_strategy, legal_basis, description
) VALUES
('users', NULL, '7 years', 'pseudonymize', 'Legal obligation for account records', 'User account data retention'),
('profile_visits', NULL, '1 year', 'aggregate', 'Legitimate interest', 'Profile visit analytics'),
('user_connections', NULL, '7 years', 'pseudonymize', 'Legitimate interest', 'Network connection data'),
('job_applications', NULL, '2 years', 'pseudonymize', 'Legitimate interest', 'Job application history'),
('attendance', NULL, '5 years', 'aggregate', 'Legal obligation for employment records', 'Employee attendance records');

-- 4. Data Processing Register
CREATE TABLE public.data_processing_activities (
    activity_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL UNIQUE,
    description text NOT NULL,
    purpose text NOT NULL,
    categories_of_data text[] NOT NULL,
    categories_of_subjects text[] NOT NULL,
    recipients text[],
    transfers_to_third_countries text[],
    retention_period interval,
    security_measures text,
    legal_basis varchar(50) NOT NULL,
    dpia_conducted boolean DEFAULT false,
    dpia_reference text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT legal_basis_check CHECK (legal_basis IN (
        'consent', 'contract', 'legal_obligation', 'vital_interest',
        'public_interest', 'legitimate_interest'
    ))
);

COMMENT ON TABLE public.data_processing_activities IS 'Register of data processing activities as required by GDPR Article 30';

CREATE TRIGGER update_data_processing_activities_timestamp
BEFORE UPDATE ON public.data_processing_activities
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- 5. Right to be Forgotten Function
CREATE OR REPLACE FUNCTION public.anonymize_user_data(p_user_id uuid)
RETURNS void AS $$
DECLARE
    anonymized_email text;
    anonymized_name text;
BEGIN
    -- Generate anonymized values
    anonymized_email := 'anonymized_' || substr(md5(random()::text), 1, 10) || '@anonymized.com';
    anonymized_name := 'Anonymized User';

    -- Update user record (keep the record but remove personal data)
    UPDATE public.users
    SET
        email = anonymized_email,
        email_encrypted = NULL,
        phone = NULL,
        phone_encrypted = NULL,
        is_active = false,
        email_verified = false,
        mfa_enabled = false,
        mfa_secret = NULL
    WHERE user_id = p_user_id;

    -- Update user profile
    UPDATE public.user_profiles
    SET
        first_name = anonymized_name,
        last_name = NULL,
        profile_summary = NULL,
        headline = NULL,
        location_country = NULL,
        location_state = NULL,
        location_city = NULL,
        profile_picture_url = NULL,
        background_image_url = NULL
    WHERE user_id = p_user_id;

    -- Record the anonymization action in audit log
    INSERT INTO public.audit_logs (
        entity_type,
        entity_id,
        action,
        action_timestamp,
        actor_id,
        action_details
    ) VALUES (
        'users',
        p_user_id,
        'anonymize',
        CURRENT_TIMESTAMP,
        current_user_id(),
        jsonb_build_object('reason', 'GDPR Right to be Forgotten request')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.anonymize_user_data(uuid) IS 'Anonymizes user data for GDPR right to be forgotten requests';

-- =============================================
-- DATA QUALITY MANAGEMENT ENHANCEMENTS
-- =============================================

-- 1. Data Quality Rules Table
CREATE TABLE public.data_quality_rules (
    rule_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name varchar(100) NOT NULL,
    column_name varchar(100) NOT NULL,
    rule_type varchar(50) NOT NULL,
    rule_definition jsonb NOT NULL,
    severity varchar(20) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT rule_type_check CHECK (rule_type IN (
        'not_null', 'unique', 'format', 'range', 'enum', 'relationship',
        'custom_check', 'regex', 'length', 'business_rule'
    )),
    CONSTRAINT severity_check CHECK (severity IN ('info', 'warning', 'error', 'critical'))
);

COMMENT ON TABLE public.data_quality_rules IS 'Defines data quality validation rules for database columns';

CREATE TRIGGER update_data_quality_rules_timestamp
BEFORE UPDATE ON public.data_quality_rules
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE INDEX idx_data_quality_rules_table ON public.data_quality_rules(table_name, column_name);

-- Insert sample data quality rules
INSERT INTO public.data_quality_rules (
    table_name, column_name, rule_type, rule_definition, severity, description
) VALUES
('users', 'email', 'format', '{"pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"}', 'critical', 'Email must be in valid format'),
('user_profiles', 'first_name', 'length', '{"min": 1, "max": 100}', 'warning', 'First name length check'),
('user_profiles', 'last_name', 'length', '{"min": 1, "max": 100}', 'warning', 'Last name length check'),
('job_listings', 'salary_min', 'range', '{"min": 0}', 'error', 'Minimum salary must be non-negative'),
('job_listings', 'salary_max', 'range', '{"min": 0}', 'error', 'Maximum salary must be non-negative');

-- 2. Data Quality Validation Results Table
CREATE TABLE public.data_quality_validation_results (
    result_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    rule_id integer NOT NULL REFERENCES public.data_quality_rules(rule_id) ON DELETE CASCADE,
    entity_id text NOT NULL,
    validation_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_valid boolean NOT NULL,
    error_message text,
    error_details jsonb,
    fixed_at timestamp with time zone,
    fixed_by uuid REFERENCES public.users(user_id)
);

COMMENT ON TABLE public.data_quality_validation_results IS 'Records results of data quality validation checks';

CREATE INDEX idx_data_quality_validation_results_rule_id ON public.data_quality_validation_results(rule_id);
CREATE INDEX idx_data_quality_validation_results_entity_id ON public.data_quality_validation_results(entity_id);
CREATE INDEX idx_data_quality_validation_results_timestamp ON public.data_quality_validation_results(validation_timestamp);
CREATE INDEX idx_data_quality_validation_results_valid ON public.data_quality_validation_results(is_valid);

-- 3. Data Quality Metrics Table
CREATE TABLE public.data_quality_metrics (
    metric_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    table_name varchar(100) NOT NULL,
    column_name varchar(100),
    metric_type varchar(50) NOT NULL,
    metric_value numeric NOT NULL,
    measurement_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    details jsonb,
    CONSTRAINT metric_type_check CHECK (metric_type IN (
        'completeness', 'accuracy', 'consistency', 'timeliness',
        'uniqueness', 'validity', 'integrity'
    ))
);

COMMENT ON TABLE public.data_quality_metrics IS 'Stores data quality metrics for monitoring and reporting';

CREATE INDEX idx_data_quality_metrics_table ON public.data_quality_metrics(table_name, column_name);
CREATE INDEX idx_data_quality_metrics_timestamp ON public.data_quality_metrics(measurement_timestamp);
CREATE INDEX idx_data_quality_metrics_type ON public.data_quality_metrics(metric_type);

-- 4. Data Quality Validation Function
CREATE OR REPLACE FUNCTION public.validate_data_quality(
    p_table_name varchar,
    p_column_name varchar DEFAULT NULL
)
RETURNS TABLE (
    rule_id integer,
    entity_id text,
    is_valid boolean,
    error_message text
) AS $$
DECLARE
    v_rule record;
    v_query text;
    v_result record;
BEGIN
    FOR v_rule IN
        SELECT * FROM public.data_quality_rules
        WHERE table_name = p_table_name
        AND (p_column_name IS NULL OR column_name = p_column_name)
        AND is_active = true
    LOOP
        -- Construct validation query based on rule type
        CASE v_rule.rule_type
            WHEN 'not_null' THEN
                v_query := format(
                    'SELECT id::text as entity_id, %I IS NOT NULL as is_valid,
                     CASE WHEN %I IS NULL THEN %L ELSE NULL END as error_message
                     FROM %I.%I',
                    v_rule.column_name, v_rule.column_name,
                    'Column ' || v_rule.column_name || ' cannot be null',
                    'public', v_rule.table_name
                );

            WHEN 'format' THEN
                IF v_rule.rule_definition->>'pattern' IS NOT NULL THEN
                    v_query := format(
                        'SELECT id::text as entity_id,
                         %I ~ %L as is_valid,
                         CASE WHEN %I !~ %L THEN %L ELSE NULL END as error_message
                         FROM %I.%I WHERE %I IS NOT NULL',
                        v_rule.column_name, v_rule.rule_definition->>'pattern',
                        v_rule.column_name, v_rule.rule_definition->>'pattern',
                        'Column ' || v_rule.column_name || ' does not match required format',
                        'public', v_rule.table_name, v_rule.column_name
                    );
                END IF;

            WHEN 'range' THEN
                v_query := format(
                    'SELECT id::text as entity_id,
                     (%I >= %s AND %I <= %s) as is_valid,
                     CASE WHEN NOT (%I >= %s AND %I <= %s) THEN %L ELSE NULL END as error_message
                     FROM %I.%I WHERE %I IS NOT NULL',
                    v_rule.column_name, COALESCE(v_rule.rule_definition->>'min', '-infinity'),
                    v_rule.column_name, COALESCE(v_rule.rule_definition->>'max', 'infinity'),
                    v_rule.column_name, COALESCE(v_rule.rule_definition->>'min', '-infinity'),
                    v_rule.column_name, COALESCE(v_rule.rule_definition->>'max', 'infinity'),
                    'Column ' || v_rule.column_name || ' is outside valid range',
                    'public', v_rule.table_name, v_rule.column_name
                );

            -- Add more rule types as needed

            ELSE
                CONTINUE; -- Skip unsupported rule types
        END CASE;

        -- Execute validation query and return results
        RETURN QUERY EXECUTE v_query;

        -- Record validation results
        FOR v_result IN EXECUTE v_query LOOP
            IF NOT v_result.is_valid THEN
                INSERT INTO public.data_quality_validation_results (
                    rule_id, entity_id, is_valid, error_message
                ) VALUES (
                    v_rule.rule_id, v_result.entity_id, v_result.is_valid, v_result.error_message
                );
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.validate_data_quality(varchar, varchar) IS 'Validates data quality based on defined rules';

-- 5. Data Quality Profiling Function
CREATE OR REPLACE FUNCTION public.profile_table_data_quality(p_table_name varchar)
RETURNS void AS $$
DECLARE
    v_column record;
    v_query text;
    v_completeness numeric;
    v_uniqueness numeric;
    v_total_rows numeric;
BEGIN
    -- Get total row count
    EXECUTE format('SELECT COUNT(*) FROM %I.%I', 'public', p_table_name) INTO v_total_rows;

    -- Skip if table is empty
    IF v_total_rows = 0 THEN
        RETURN;
    END IF;

    -- Profile each column
    FOR v_column IN
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = p_table_name
    LOOP
        -- Calculate completeness (non-null percentage)
        EXECUTE format(
            'SELECT (COUNT(*) - COUNT(*) FILTER (WHERE %I IS NULL)) / COUNT(*)::numeric
             FROM %I.%I',
            v_column.column_name, 'public', p_table_name
        ) INTO v_completeness;

        -- Record completeness metric
        INSERT INTO public.data_quality_metrics (
            table_name, column_name, metric_type, metric_value, details
        ) VALUES (
            p_table_name, v_column.column_name, 'completeness', v_completeness,
            jsonb_build_object('total_rows', v_total_rows)
        );

        -- Calculate uniqueness for non-array types
        IF v_column.data_type NOT LIKE '%[]' AND v_column.data_type NOT IN ('json', 'jsonb') THEN
            EXECUTE format(
                'SELECT COUNT(DISTINCT %I)::numeric / COUNT(*)::numeric
                 FROM %I.%I
                 WHERE %I IS NOT NULL',
                v_column.column_name, 'public', p_table_name, v_column.column_name
            ) INTO v_uniqueness;

            -- Record uniqueness metric
            INSERT INTO public.data_quality_metrics (
                table_name, column_name, metric_type, metric_value, details
            ) VALUES (
                p_table_name, v_column.column_name, 'uniqueness', v_uniqueness,
                jsonb_build_object('total_rows', v_total_rows)
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.profile_table_data_quality(varchar) IS 'Profiles data quality metrics for a table';

-- =============================================
-- COMPREHENSIVE AUDIT FRAMEWORK ENHANCEMENTS
-- =============================================
-- to be incorporated in the next version 
-- 1. Central Audit Log Table
CREATE TABLE public.audit_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    entity_type varchar(100) NOT NULL,
    entity_id uuid NOT NULL,
    action varchar(50) NOT NULL,
    action_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    actor_id uuid,
    actor_type varchar(50) DEFAULT 'user',
    ip_address inet,
    user_agent text,
    action_details jsonb,
    previous_state jsonb,
    new_state jsonb,
    CONSTRAINT action_check CHECK (action IN (
        'create', 'read', 'update', 'delete', 'login', 'logout', 'export',
        'share', 'anonymize', 'consent', 'access_request', 'admin_action'
    )),
    CONSTRAINT actor_type_check CHECK (actor_type IN ('user', 'system', 'admin', 'api'))
) PARTITION BY RANGE (action_timestamp);

COMMENT ON TABLE public.audit_logs IS 'Centralized immutable audit log for all system actions';

-- Create function to generate audit log partitions automatically
CREATE OR REPLACE FUNCTION public.create_audit_log_partition(year int, month int)
RETURNS void AS $$
DECLARE
    partition_name text;
    start_date text;
    end_date text;
BEGIN
    partition_name := format('audit_logs_y%sm%s', year, LPAD(month::text, 2, '0'));

    IF month = 12 THEN
        start_date := format('%s-%s-01', year, LPAD(month::text, 2, '0'));
        end_date := format('%s-01-01', year + 1);
    ELSE
        start_date := format('%s-%s-01', year, LPAD(month::text, 2, '0'));
        end_date := format('%s-%s-01', year, LPAD((month + 1)::text, 2, '0'));
    END IF;

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I
        PARTITION OF public.audit_logs
        FOR VALUES FROM (%L) TO (%L)
    ', partition_name, start_date, end_date);

    -- Create indexes on the partition
    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_entity
        ON public.%I(entity_type, entity_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_actor_id
        ON public.%I(actor_id)
    ', partition_name, partition_name);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS idx_%I_action
        ON public.%I(action)
    ', partition_name, partition_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_audit_log_partition(int, int) IS 'Creates a monthly partition for audit_logs table';

-- Create partitions for current month and next month
DO $$
DECLARE
    current_year int := EXTRACT(YEAR FROM CURRENT_DATE)::int;
    current_month int := EXTRACT(MONTH FROM CURRENT_DATE)::int;
    next_month int;
    next_year int;
BEGIN
    -- Create current month partition
    PERFORM public.create_audit_log_partition(current_year, current_month);

    -- Calculate next month and year
    IF current_month = 12 THEN
        next_month := 1;
        next_year := current_year + 1;
    ELSE
        next_month := current_month + 1;
        next_year := current_year;
    END IF;

    -- Create next month partition
    PERFORM public.create_audit_log_partition(next_year, next_month);
END $$;

-- Create default partition
CREATE TABLE public.audit_logs_default PARTITION OF public.audit_logs DEFAULT;

CREATE INDEX idx_audit_logs_default_entity ON public.audit_logs_default(entity_type, entity_id);
CREATE INDEX idx_audit_logs_default_actor_id ON public.audit_logs_default(actor_id);
CREATE INDEX idx_audit_logs_default_action ON public.audit_logs_default(action);

-- 2. Audit Trigger Function
CREATE OR REPLACE FUNCTION public.audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data jsonb;
    v_new_data jsonb;
    v_actor_id uuid;
BEGIN
    -- Get current user ID
    v_actor_id := current_user_id();

    IF (TG_OP = 'UPDATE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);

        -- Only audit if data actually changed
        IF v_old_data = v_new_data THEN
            RETURN NEW;
        END IF;

        INSERT INTO public.audit_logs(
            entity_type,
            entity_id,
            action,
            actor_id,
            previous_state,
            new_state
        ) VALUES (
            TG_TABLE_NAME,
            CASE
                WHEN TG_TABLE_NAME = 'users' THEN NEW.user_id
                ELSE (v_new_data->>'id')::uuid
            END,
            'update',
            v_actor_id,
            v_old_data,
            v_new_data
        );

    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := to_jsonb(OLD);

        INSERT INTO public.audit_logs(
            entity_type,
            entity_id,
            action,
            actor_id,
            previous_state
        ) VALUES (
            TG_TABLE_NAME,
            CASE
                WHEN TG_TABLE_NAME = 'users' THEN OLD.user_id
                ELSE (v_old_data->>'id')::uuid
            END,
            'delete',
            v_actor_id,
            v_old_data
        );
        RETURN OLD;

    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := to_jsonb(NEW);

        INSERT INTO public.audit_logs(
            entity_type,
            entity_id,
            action,
            actor_id,
            new_state
        ) VALUES (
            TG_TABLE_NAME,
            CASE
                WHEN TG_TABLE_NAME = 'users' THEN NEW.user_id
                ELSE (v_new_data->>'id')::uuid
            END,
            'create',
            v_actor_id,
            v_new_data
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.audit_trigger_function() IS 'Generic audit trigger function for tracking changes';

-- 3. Security Event Log Table
CREATE TABLE public.security_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    event_type varchar(100) NOT NULL,
    severity varchar(20) NOT NULL,
    user_id uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    ip_address inet,
    user_agent text,
    event_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_details jsonb,
    is_resolved boolean DEFAULT false,
    resolved_at timestamp with time zone,
    resolved_by uuid REFERENCES public.users(user_id) ON DELETE SET NULL,
    resolution_notes text,
    CONSTRAINT severity_check CHECK (severity IN ('info', 'low', 'medium', 'high', 'critical'))
);

COMMENT ON TABLE public.security_events IS 'Logs security-related events for monitoring and alerting';

CREATE INDEX idx_security_events_type ON public.security_events(event_type);
CREATE INDEX idx_security_events_user_id ON public.security_events(user_id);
CREATE INDEX idx_security_events_timestamp ON public.security_events(event_timestamp);
CREATE INDEX idx_security_events_severity ON public.security_events(severity);
CREATE INDEX idx_security_events_resolved ON public.security_events(is_resolved);

-- 4. Audit Policy Table
CREATE TABLE public.audit_policies (
    policy_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_type varchar(100) NOT NULL,
    actions text[] NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    description text,
    alert_threshold integer,
    retention_period interval,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    CONSTRAINT unique_entity_policy UNIQUE (entity_type)
);

COMMENT ON TABLE public.audit_policies IS 'Defines auditing policies for different entity types';

CREATE TRIGGER update_audit_policies_timestamp
BEFORE UPDATE ON public.audit_policies
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Insert default audit policies
INSERT INTO public.audit_policies (
    entity_type, actions, description, alert_threshold, retention_period
) VALUES
('users', ARRAY['create', 'update', 'delete', 'login', 'logout'],
 'Audit policy for user account actions', 5, '7 years'),
('user_profiles', ARRAY['create', 'update', 'delete'],
 'Audit policy for user profile changes', NULL, '7 years'),
('user_consents', ARRAY['create', 'update', 'delete'],
 'Audit policy for consent changes', 1, '7 years'),
('job_listings', ARRAY['create', 'update', 'delete'],
 'Audit policy for job listing changes', NULL, '3 years'),
('job_applications', ARRAY['create', 'update', 'delete'],
 'Audit policy for job application changes', NULL, '3 years');

-- 5. Apply Audit Triggers to Key Tables
-- Create a function to apply audit triggers to tables
CREATE OR REPLACE FUNCTION public.apply_audit_trigger(p_table_name varchar)
RETURNS void AS $$
BEGIN
    EXECUTE format('
        DROP TRIGGER IF EXISTS audit_trigger ON %I.%I;
        CREATE TRIGGER audit_trigger
        AFTER INSERT OR UPDATE OR DELETE ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();
    ', 'public', p_table_name, 'public', p_table_name);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.apply_audit_trigger(varchar) IS 'Applies audit trigger to specified table';

-- Apply audit triggers to key tables
SELECT public.apply_audit_trigger('users');
SELECT public.apply_audit_trigger('user_profiles');
SELECT public.apply_audit_trigger('user_consents');
SELECT public.apply_audit_trigger('job_listings');
SELECT public.apply_audit_trigger('job_applications');
SELECT public.apply_audit_trigger('company_reviews');

-- 6. Data Access Log View
CREATE OR REPLACE VIEW public.data_access_logs AS
SELECT
    log_id,
    entity_type,
    entity_id,
    action,
    action_timestamp,
    actor_id,
    actor_type,
    ip_address,
    user_agent
FROM
    public.audit_logs
WHERE
    action IN ('read', 'export', 'access_request');

COMMENT ON VIEW public.data_access_logs IS 'View for monitoring data access activities';

-- 7. Suspicious Activity Detection Function
CREATE OR REPLACE FUNCTION public.detect_suspicious_activity(
    p_lookback_period interval DEFAULT '1 day'::interval
)
RETURNS TABLE (
    user_id uuid,
    event_count bigint,
    event_types text[],
    first_event_time timestamp with time zone,
    last_event_time timestamp with time zone,
    risk_score numeric
) AS $$
BEGIN
    RETURN QUERY
    WITH user_events AS (
        SELECT
            al.actor_id,
            COUNT(*) as event_count,
            array_agg(DISTINCT al.action) as event_types,
            MIN(al.action_timestamp) as first_event_time,
            MAX(al.action_timestamp) as last_event_time,
            COUNT(DISTINCT al.entity_id) as distinct_entities,
            COUNT(DISTINCT al.ip_address) as distinct_ips
        FROM
            public.audit_logs al
        WHERE
            al.action_timestamp >= (CURRENT_TIMESTAMP - p_lookback_period)
            AND al.actor_id IS NOT NULL
        GROUP BY
            al.actor_id
    )
    SELECT
        ue.actor_id,
        ue.event_count,
        ue.event_types,
        ue.first_event_time,
        ue.last_event_time,
        -- Calculate risk score based on various factors
        (
            (ue.event_count / 10.0) +
            (ue.distinct_entities / 5.0) +
            (ue.distinct_ips * 2.0) +
            -- Higher score for sensitive actions
            (CASE WHEN 'delete' = ANY(ue.event_types) THEN 5.0 ELSE 0.0 END) +
            (CASE WHEN 'admin_action' = ANY(ue.event_types) THEN 3.0 ELSE 0.0 END) +
            (CASE WHEN 'export' = ANY(ue.event_types) THEN 2.0 ELSE 0.0 END)
        ) as risk_score
    FROM
        user_events ue
    WHERE
        -- Filter for potentially suspicious activity
        ue.event_count > 50 OR
        ue.distinct_entities > 20 OR
        ue.distinct_ips > 2 OR
        'delete' = ANY(ue.event_types) OR
        array_length(ue.event_types, 1) > 5
    ORDER BY
        risk_score DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.detect_suspicious_activity(interval) IS 'Detects potentially suspicious user activity based on audit logs';


---end of version 1
