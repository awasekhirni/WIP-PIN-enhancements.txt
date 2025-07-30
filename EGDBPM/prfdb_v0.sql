-- =============================================
-- β Trace Enterprise Database Performance Platform
-- Version: 1.0
-- Created: 2025-07-15
-- Last Updated: 2025-07-30
-- Description: β Trace Enterprise Database Performance Platform
-- Author: Awase Khirni Syed
-- Copyright: 2025 β ORI Inc. Canada. All Rights Reserved.
-- =============================================


--- Database performance platform
-- Query Performance Analysis for Postgresql
---- Intelligent Analysis -- Automatic query complexity scoring and optimization suggestions
---- proactive monitoring: real-time alerts and anomaly detection
---- historical intelligence -- performance baselines and trending analysis
-- operational excellence -- resource usage tracking and forecasting
--- security compliance -- enhanced audit trails and session tracking
-- scalability -- data archiving and partitioning for long-term retention
-- integration ready -- api end points for external monitoring tools
-- business context -- query tagging and business process mapping
--- multi-instance monitoring -- to track performance across multiple databse instanaces
-- regression detection -- automatically detect peformance degradations
-- query rewriting -- suggest query optimization
-- configuration management -- database parameter tuning recommendations
-- advanced alerting -- to have a sophisticated alerting system with custom rules
-- beenchmarking framework-- performacne testing and comparison capabiltieis
-- ML integration -- machine learning features for predictive analytics
-- distributed tracking -- corss database query monitoring and performance tracking 
--- resource governance -- advanced workload amnagement and resource allcoation 
--intelligent caching -- query result caching with invalidation 
-- security compliance monitoring -- advanced audit logging and data sensitivity monitoring 
-- backup monitoring -- comprehensive backup/recovery performance tracking 
-- cost management -- query cost attribution and optimization recommendation




-- Create performance monitoring schema and tables
CREATE SCHEMA IF NOT EXISTS query_performance;

-- Table to store query performance data
CREATE TABLE IF NOT EXISTS query_performance.query_log (
    log_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    query_text TEXT NOT NULL,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    total_time_ms DECIMAL(12,3),
    rows_returned BIGINT,
    tables_used TEXT[],
    query_type TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT DEFAULT CURRENT_USER,
    client_ip INET,
    query_hash TEXT
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_query_log_schema_time ON query_performance.query_log(schema_name, executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_query_log_execution_time ON query_performance.query_log(execution_time_ms DESC);
CREATE INDEX IF NOT EXISTS idx_query_log_tables_used ON query_performance.query_log USING GIN(tables_used);

-- Function to extract table names from query
CREATE OR REPLACE FUNCTION query_performance.extract_table_names(query_text TEXT)
RETURNS TEXT[] AS $$
DECLARE
    table_names TEXT[];
    rec RECORD;
BEGIN
    -- Extract potential table names from the query
    SELECT ARRAY_AGG(DISTINCT relname) INTO table_names
    FROM (
        SELECT DISTINCT
            regexp_replace(
                regexp_replace(
                    trim(both FROM unnest(
                        regexp_split_to_array(
                            lower(query_text),
                            '\s+(?:from|join|into|update|delete\s+from)\s+'
                        )
                    )),
                    '^[^a-z_].*', '', 'g'
                ),
                '[\s,;].*$', '', 'g'
            ) AS relname
        WHERE unnest(regexp_split_to_array(lower(query_text), '\s+(?:from|join|into|update|delete\s+from)\s+')) != ''
    ) sub
    WHERE relname ~ '^[a-z_][a-z0-9_]*$';

    RETURN COALESCE(table_names, ARRAY[]::TEXT[]);
END;
$$ LANGUAGE plpgsql;

-- Function to determine query type
CREATE OR REPLACE FUNCTION query_performance.get_query_type(query_text TEXT)
RETURNS TEXT AS $$
BEGIN
    CASE
        WHEN lower(query_text) ~ '^\s*select' THEN RETURN 'SELECT';
        WHEN lower(query_text) ~ '^\s*insert' THEN RETURN 'INSERT';
        WHEN lower(query_text) ~ '^\s*update' THEN RETURN 'UPDATE';
        WHEN lower(query_text) ~ '^\s*delete' THEN RETURN 'DELETE';
        WHEN lower(query_text) ~ '^\s*create' THEN RETURN 'CREATE';
        WHEN lower(query_text) ~ '^\s*alter' THEN RETURN 'ALTER';
        WHEN lower(query_text) ~ '^\s*drop' THEN RETURN 'DROP';
        ELSE RETURN 'OTHER';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Main function to log query performance
CREATE OR REPLACE FUNCTION query_performance.log_query_performance(
    p_schema_name TEXT,
    p_query_text TEXT,
    p_execution_time_ms DECIMAL DEFAULT NULL,
    p_planning_time_ms DECIMAL DEFAULT NULL,
    p_total_time_ms DECIMAL DEFAULT NULL,
    p_rows_returned BIGINT DEFAULT NULL,
    p_client_ip INET DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_tables_used TEXT[];
    v_query_type TEXT;
    v_query_hash TEXT;
BEGIN
    -- Extract table names and query type
    v_tables_used := query_performance.extract_table_names(p_query_text);
    v_query_type := query_performance.get_query_type(p_query_text);
    v_query_hash := md5(p_query_text);

    -- Insert performance data
    INSERT INTO query_performance.query_log (
        schema_name,
        query_text,
        execution_time_ms,
        planning_time_ms,
        total_time_ms,
        rows_returned,
        tables_used,
        query_type,
        user_name,
        client_ip,
        query_hash
    ) VALUES (
        p_schema_name,
        p_query_text,
        p_execution_time_ms,
        p_planning_time_ms,
        p_total_time_ms,
        p_rows_returned,
        v_tables_used,
        v_query_type,
        CURRENT_USER,
        p_client_ip,
        v_query_hash
    );
END;
$$ LANGUAGE plpgsql;

-- Function to execute and log a query with performance tracking
CREATE OR REPLACE FUNCTION query_performance.execute_and_log_query(
    p_schema_name TEXT,
    p_query_text TEXT,
    p_client_ip INET DEFAULT NULL
)
RETURNS SETOF RECORD AS $$
DECLARE
    v_start_time TIMESTAMP WITH TIME ZONE;
    v_end_time TIMESTAMP WITH TIME ZONE;
    v_execution_time_ms DECIMAL(12,3);
    v_planning_time_ms DECIMAL(12,3);
    v_total_time_ms DECIMAL(12,3);
    v_rows_returned BIGINT;
    v_result RECORD;
    v_query_result REFCURSOR;
BEGIN
    -- Record start time
    v_start_time := clock_timestamp();

    -- Execute the query and capture results
    FOR v_result IN EXECUTE p_query_text
    LOOP
        RETURN NEXT v_result;
    END LOOP;

    -- Get row count (this is approximate for SELECT queries)
    GET DIAGNOSTICS v_rows_returned = ROW_COUNT;

    -- Record end time
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;

    -- Log the performance data
    PERFORM query_performance.log_query_performance(
        p_schema_name => p_schema_name,
        p_query_text => p_query_text,
        p_execution_time_ms => v_execution_time_ms,
        p_planning_time_ms => NULL, -- Would need EXPLAIN ANALYZE for accurate planning time
        p_total_time_ms => v_execution_time_ms,
        p_rows_returned => v_rows_returned,
        p_client_ip => p_client_ip
    );

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- View to analyze performance by schema
CREATE OR REPLACE VIEW query_performance.schema_performance_summary AS
SELECT
    schema_name,
    COUNT(*) as query_count,
    AVG(execution_time_ms) as avg_execution_time_ms,
    MAX(execution_time_ms) as max_execution_time_ms,
    MIN(execution_time_ms) as min_execution_time_ms,
    SUM(rows_returned) as total_rows_returned,
    COUNT(DISTINCT query_hash) as unique_queries
FROM query_performance.query_log
GROUP BY schema_name;

-- View to analyze performance by table usage
CREATE OR REPLACE VIEW query_performance.table_performance_summary AS
SELECT
    unnest(tables_used) as table_name,
    COUNT(*) as query_count,
    AVG(execution_time_ms) as avg_execution_time_ms,
    MAX(execution_time_ms) as max_execution_time_ms,
    SUM(rows_returned) as total_rows_returned
FROM query_performance.query_log
WHERE tables_used IS NOT NULL AND array_length(tables_used, 1) > 0
GROUP BY unnest(tables_used);

-- View to analyze slow queries
CREATE OR REPLACE VIEW query_performance.slow_queries AS
SELECT
    schema_name,
    query_text,
    execution_time_ms,
    rows_returned,
    tables_used,
    query_type,
    executed_at
FROM query_performance.query_log
WHERE execution_time_ms > 1000  -- Queries taking more than 1 second
ORDER BY execution_time_ms DESC
LIMIT 100;

-- Function to clean old performance data
CREATE OR REPLACE FUNCTION query_performance.cleanup_old_logs(
    days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM query_performance.query_log
    WHERE executed_at < NOW() - INTERVAL '1 day' * days_to_keep;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;



-- Grant permissions (adjust as needed)
GRANT USAGE ON SCHEMA query_performance TO PUBLIC;
GRANT SELECT, INSERT ON TABLE query_performance.query_log TO PUBLIC;
GRANT EXECUTE ON FUNCTION query_performance.log_query_performance TO PUBLIC;
GRANT EXECUTE ON FUNCTION query_performance.execute_and_log_query TO PUBLIC;
GRANT EXECUTE ON FUNCTION query_performance.cleanup_old_logs TO PUBLIC;
-- GRANT SELECT ON ALL VIEWS IN SCHEMA query_performance TO PUBLIC;

COMMENT ON SCHEMA query_performance IS 'Schema for query performance monitoring';
COMMENT ON TABLE query_performance.query_log IS 'Logs query performance metrics by schema';




-- usage
--  View performance summary by schema
SELECT * FROM query_performance.schema_performance_summary;

-- View slow queries
SELECT * FROM query_performance.slow_queries;

-- Clean up old logs (keep last 30 days)
SELECT query_performance.cleanup_old_logs(30);


-- Function to extract more detailed query metadata
-- advanced querya nalysis 

CREATE OR REPLACE FUNCTION query_performance.analyze_query_complexity(query_text TEXT)
RETURNS TABLE(
    complexity_score INTEGER,
    join_count INTEGER,
    subquery_count INTEGER,
    where_clause_complexity INTEGER,
    has_aggregation BOOLEAN
) AS $$
DECLARE
    v_join_count INTEGER;
    v_subquery_count INTEGER;
    v_where_complexity INTEGER;
    v_has_agg BOOLEAN;
    v_complexity INTEGER;
BEGIN
    -- Count JOINs
    SELECT COUNT(*) INTO v_join_count
    FROM regexp_matches(lower(query_text), '\s+join\s+', 'g');
    
    -- Count subqueries (approximate)
    SELECT COUNT(*) INTO v_subquery_count
    FROM regexp_matches(lower(query_text), '\(\s*select', 'g');
    
    -- Analyze WHERE clause complexity
    SELECT COUNT(*) INTO v_where_complexity
    FROM regexp_matches(lower(query_text), '(and|or)\s+\w+\s*(=|!=|>|<|like|in)', 'g');
    
    -- Check for aggregations
    v_has_agg := lower(query_text) ~ '\b(count|sum|avg|max|min|group by)\b';
    
    -- Calculate complexity score
    v_complexity := v_join_count * 10 + v_subquery_count * 15 + 
                   v_where_complexity * 5 + (CASE WHEN v_has_agg THEN 8 ELSE 0 END);
    
    RETURN QUERY SELECT v_complexity, v_join_count, v_subquery_count, 
                        v_where_complexity, v_has_agg;
END;
$$ LANGUAGE plpgsql;


--- integrating query plan analysis function 
-- Function to capture actual execution plans
CREATE OR REPLACE FUNCTION query_performance.get_query_plan_with_stats(query_text TEXT)
RETURNS TABLE(
    plan_json JSONB,
    actual_execution_time NUMERIC,
    actual_rows BIGINT
) AS $$
DECLARE
    plan_result RECORD;
BEGIN
    -- This requires enabling pg_stat_statements extension
    EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || query_text INTO plan_result;
    
    RETURN QUERY SELECT 
        plan_result."QUERY PLAN"::JSONB,
        (plan_result."QUERY PLAN"::JSONB->0->'Execution Time')::NUMERIC,
        (plan_result."QUERY PLAN"::JSONB->0->'Plan'->>'Actual Rows')::BIGINT;
END;
$$ LANGUAGE plpgsql;

--- to store performancee baselines and anomaly detection 
-- Table to store performance baselines
CREATE TABLE IF NOT EXISTS query_performance.query_baselines (
    baseline_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    query_hash TEXT NOT NULL,
    avg_execution_time_ms DECIMAL(12,3),
    avg_rows_returned BIGINT,
    execution_count BIGINT,
    first_seen TIMESTAMP WITH TIME ZONE,
    last_seen TIMESTAMP WITH TIME ZONE,
    UNIQUE(schema_name, query_hash)
);

-- Function to update baselines
CREATE OR REPLACE FUNCTION query_performance.update_query_baselines()
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance.query_baselines (
        schema_name, query_hash, avg_execution_time_ms, avg_rows_returned, 
        execution_count, first_seen, last_seen
    )
    SELECT 
        schema_name, query_hash,
        AVG(execution_time_ms) as avg_execution_time,
        AVG(rows_returned) as avg_rows,
        COUNT(*) as exec_count,
        MIN(executed_at) as first_seen,
        MAX(executed_at) as last_seen
    FROM query_performance.query_log
    WHERE executed_at > NOW() - INTERVAL '1 hour'
    GROUP BY schema_name, query_hash
    ON CONFLICT (schema_name, query_hash)
    DO UPDATE SET
        avg_execution_time_ms = (
            (query_performance.query_baselines.avg_execution_time_ms * query_performance.query_baselines.execution_count) + 
            (EXCLUDED.avg_execution_time_ms * EXCLUDED.execution_count)
        ) / (query_performance.query_baselines.execution_count + EXCLUDED.execution_count),
        avg_rows_returned = (
            (query_performance.query_baselines.avg_rows_returned * query_performance.query_baselines.execution_count) + 
            (EXCLUDED.avg_rows_returned * EXCLUDED.execution_count)
        ) / (query_performance.query_baselines.execution_count + EXCLUDED.execution_count),
        execution_count = query_performance.query_baselines.execution_count + EXCLUDED.execution_count,
        last_seen = EXCLUDED.last_seen;
END;
$$ LANGUAGE plpgsql;

-- Anomaly detection view
CREATE OR REPLACE VIEW query_performance.query_anomalies AS
SELECT 
    ql.*,
    qb.avg_execution_time_ms as baseline_time,
    CASE 
        WHEN ql.execution_time_ms > qb.avg_execution_time_ms * 2 
        THEN 'SLOW' 
        ELSE 'NORMAL' 
    END as performance_status
FROM query_performance.query_log ql
JOIN query_performance.query_baselines qb 
    ON ql.schema_name = qb.schema_name AND ql.query_hash = qb.query_hash
WHERE ql.executed_at > NOW() - INTERVAL '1 day'
    AND ql.execution_time_ms > qb.avg_execution_time_ms * 2;

-- resource usage monitoring 
-- Enhanced logging table with resource metrics
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS cpu_time_ms DECIMAL(12,3);
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS io_time_ms DECIMAL(12,3);
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS memory_usage_mb DECIMAL(12,2);
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS temp_files_used BOOLEAN DEFAULT FALSE;

-- Function to capture system resource usage (requires custom extensions)
CREATE OR REPLACE FUNCTION query_performance.capture_resource_usage()
RETURNS TABLE(
    cpu_time_ms DECIMAL(12,3),
    io_time_ms DECIMAL(12,3),
    memory_mb DECIMAL(12,2)
) AS $$
BEGIN
    -- This would require custom C extensions or external monitoring
    -- Placeholder implementation
    RETURN QUERY SELECT 0.0::DECIMAL, 0.0::DECIMAL, 0.0::DECIMAL;
END;
$$ LANGUAGE plpgsql;

---optimization suggestions 
-- Table for optimization suggestions
CREATE TABLE IF NOT EXISTS query_performance.optimization_suggestions (
    suggestion_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    query_hash TEXT NOT NULL,
    suggestion_type TEXT NOT NULL, -- MISSING_INDEX, QUERY_REWRITE, etc.
    suggestion_text TEXT NOT NULL,
    priority INTEGER, -- 1-5, 5 being highest
    impact_score DECIMAL(5,2), -- Estimated performance improvement
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    implemented BOOLEAN DEFAULT FALSE
);

-- Function to generate optimization suggestions
CREATE OR REPLACE FUNCTION query_performance.generate_optimization_suggestions()
RETURNS VOID AS $$
BEGIN
    -- Suggest indexes for frequently used WHERE clauses
    INSERT INTO query_performance.optimization_suggestions (
        schema_name, query_hash, suggestion_type, suggestion_text, priority, impact_score
    )
    SELECT 
        schema_name, query_hash, 'MISSING_INDEX',
        'Consider adding index on columns used in WHERE clauses: ' || array_to_string(tables_used, ', '),
        4,
        0.75
    FROM query_performance.query_log ql
    WHERE query_type = 'SELECT'
        AND execution_time_ms > 100
        AND tables_used IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM query_performance.optimization_suggestions os
            WHERE os.schema_name = ql.schema_name 
                AND os.query_hash = ql.query_hash
                AND os.suggestion_type = 'MISSING_INDEX'
        )
    GROUP BY schema_name, query_hash, tables_used
    HAVING COUNT(*) > 10;
END;
$$ LANGUAGE plpgsql;

---real-time monitoring and alerts implementation 
-- Table for alert configurations
CREATE TABLE IF NOT EXISTS query_performance.alert_configurations (
    config_id SERIAL PRIMARY KEY,
    alert_name TEXT UNIQUE NOT NULL,
    schema_name TEXT,
    query_pattern TEXT, -- regex pattern
    threshold_execution_time_ms DECIMAL(12,3),
    threshold_rows_returned BIGINT,
    alert_channel TEXT, -- email, slack, etc.
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for alert logs
CREATE TABLE IF NOT EXISTS query_performance.alert_logs (
    alert_id SERIAL PRIMARY KEY,
    config_id INTEGER REFERENCES query_performance.alert_configurations(config_id),
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    query_log_id INTEGER REFERENCES query_performance.query_log(log_id),
    alert_message TEXT
);

-- Function to check and trigger alerts
CREATE OR REPLACE FUNCTION query_performance.check_alerts()
RETURNS VOID AS $$
DECLARE
    alert_rec RECORD;
    query_rec RECORD;
BEGIN
    FOR alert_rec IN 
        SELECT * FROM query_performance.alert_configurations WHERE enabled = TRUE
    LOOP
        -- Check for queries that exceed thresholds
        FOR query_rec IN
            SELECT * FROM query_performance.query_log
            WHERE executed_at > NOW() - INTERVAL '5 minutes'
                AND execution_time_ms > alert_rec.threshold_execution_time_ms
                AND (alert_rec.schema_name IS NULL OR schema_name = alert_rec.schema_name)
                AND (alert_rec.query_pattern IS NULL OR query_text ~ alert_rec.query_pattern)
        LOOP
            -- Log the alert
            INSERT INTO query_performance.alert_logs (config_id, query_log_id, alert_message)
            VALUES (
                alert_rec.config_id, 
                query_rec.log_id,
                'Query exceeded threshold: ' || query_rec.execution_time_ms || 'ms > ' || alert_rec.threshold_execution_time_ms || 'ms'
            );
            
            -- Here you would implement actual alert delivery (email, Slack, etc.)
            RAISE NOTICE 'ALERT: Query % exceeded threshold in schema %', 
                        query_rec.query_text, query_rec.schema_name;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--enahncement to classify and tag the queries 
-- Add tagging support
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS business_process TEXT;

-- Function to auto-tag queries based on patterns
CREATE OR REPLACE FUNCTION query_performance.auto_tag_queries()
RETURNS VOID AS $$
BEGIN
    UPDATE query_performance.query_log 
    SET tags = ARRAY['reporting'] 
    WHERE query_text ~* '\b(report|summary|dashboard)\b' 
        AND tags IS NULL;

    UPDATE query_performance.query_log 
    SET tags = ARRAY['etl'] 
    WHERE query_text ~* '\b(insert|update|delete|copy|import)\b' 
        AND tags IS NULL;

    UPDATE query_performance.query_log 
    SET tags = ARRAY['search'] 
    WHERE query_text ~* '\b(where.*like|fulltext|tsvector)\b' 
        AND tags IS NULL;
END;
$$ LANGUAGE plpgsql;


-- enahncement to create views for performance trends and forecasting 
-- View for performance trends
CREATE OR REPLACE VIEW query_performance.performance_trends AS
SELECT 
    schema_name,
    DATE_TRUNC('hour', executed_at) as hour_bucket,
    COUNT(*) as query_count,
    AVG(execution_time_ms) as avg_execution_time,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) as median_execution_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_execution_time
FROM query_performance.query_log
WHERE executed_at > NOW() - INTERVAL '7 days'
GROUP BY schema_name, DATE_TRUNC('hour', executed_at)
ORDER BY hour_bucket DESC;

-- Function for performance forecasting
CREATE OR REPLACE FUNCTION query_performance.forecast_performance(
    p_schema_name TEXT,
    hours_ahead INTEGER DEFAULT 24
)
RETURNS TABLE(
    forecast_time TIMESTAMP WITH TIME ZONE,
    predicted_avg_time DECIMAL(12,3),
    confidence_interval_lower DECIMAL(12,3),
    confidence_interval_upper DECIMAL(12,3)
) AS $$
BEGIN
    -- This would typically use statistical forecasting methods
    -- Placeholder for now
    RETURN QUERY 
    SELECT 
        NOW() + (n || ' hours')::INTERVAL as forecast_time,
        100.0::DECIMAL as predicted_avg_time,
        80.0::DECIMAL as confidence_interval_lower,
        120.0::DECIMAL as confidence_interval_upper
    FROM generate_series(1, hours_ahead) n;
END;
$$ LANGUAGE plpgsql;

--security and audit enhancements 
-- Add security-related fields
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS session_id TEXT;
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS application_name TEXT;
ALTER TABLE query_performance.query_log ADD COLUMN IF NOT EXISTS query_parameters JSONB;

-- Enhanced logging function with security context
CREATE OR REPLACE FUNCTION query_performance.log_query_performance_enhanced(
    p_schema_name TEXT,
    p_query_text TEXT,
    p_execution_time_ms DECIMAL DEFAULT NULL,
    p_planning_time_ms DECIMAL DEFAULT NULL,
    p_total_time_ms DECIMAL DEFAULT NULL,
    p_rows_returned BIGINT DEFAULT NULL,
    p_client_ip INET DEFAULT NULL,
    p_session_id TEXT DEFAULT NULL,
    p_application_name TEXT DEFAULT NULL,
    p_parameters JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_tables_used TEXT[];
    v_query_type TEXT;
    v_query_hash TEXT;
BEGIN
    -- Extract table names and query type
    v_tables_used := query_performance.extract_table_names(p_query_text);
    v_query_type := query_performance.get_query_type(p_query_text);
    v_query_hash := md5(p_query_text);
    
    -- Insert performance data with enhanced security context
    INSERT INTO query_performance.query_log (
        schema_name, query_text, execution_time_ms, planning_time_ms, total_time_ms,
        rows_returned, tables_used, query_type, user_name, client_ip, query_hash,
        session_id, application_name, query_parameters
    ) VALUES (
        p_schema_name, p_query_text, p_execution_time_ms, p_planning_time_ms, p_total_time_ms,
        p_rows_returned, v_tables_used, v_query_type, CURRENT_USER, p_client_ip, v_query_hash,
        p_session_id, p_application_name, p_parameters
    );
END;
$$ LANGUAGE plpgsql;


-- data retention and archiving strategy 
-- Partitioned table for long-term storage
-- Create the main partitioned table 
CREATE TABLE IF NOT EXISTS query_performance.query_log_archive (
    log_id SERIAL,
    schema_name TEXT NOT NULL,
    query_text TEXT NOT NULL,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    total_time_ms DECIMAL(12,3),
    rows_returned BIGINT,
    tables_used TEXT[],
    query_type TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT DEFAULT CURRENT_USER,
    client_ip INET,
    query_hash TEXT,
    -- Additional columns from the enhanced version
    cpu_time_ms DECIMAL(12,3),
    io_time_ms DECIMAL(12,3),
    memory_usage_mb DECIMAL(12,2),
    temp_files_used BOOLEAN DEFAULT FALSE,
    tags TEXT[],
    business_process TEXT,
    session_id TEXT,
    application_name TEXT,
    query_parameters JSONB,
    -- Primary key must include partition key
    PRIMARY KEY (log_id, executed_at)
) PARTITION BY RANGE (executed_at);

-- Create monthly partitions (example for 2024)
CREATE TABLE IF NOT EXISTS query_performance.query_log_archive_2024_01
PARTITION OF query_performance.query_log_archive
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE IF NOT EXISTS query_performance.query_log_archive_2024_02
PARTITION OF query_performance.query_log_archive
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE IF NOT EXISTS query_performance.query_log_archive_2024_03
PARTITION OF query_performance.query_log_archive
FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Add indexes to the partitioned table
CREATE INDEX IF NOT EXISTS idx_query_log_archive_schema_time 
ON query_performance.query_log_archive (schema_name, executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_query_log_archive_execution_time 
ON query_performance.query_log_archive (execution_time_ms DESC);

CREATE INDEX IF NOT EXISTS idx_query_log_archive_tables_used 
ON query_performance.query_log_archive USING GIN (tables_used);

-- Function to create partitions automatically
CREATE OR REPLACE FUNCTION query_performance.create_monthly_partition(
    target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    start_date := DATE_TRUNC('month', target_date);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'query_log_archive_' || TO_CHAR(start_date, 'YYYY_MM');
    
    -- Check if partition already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'query_performance' 
        AND tablename = partition_name
    ) THEN
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS query_performance.%I
            PARTITION OF query_performance.query_log_archive
            FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
        RETURN 'Created partition: ' || partition_name;
    ELSE
        RETURN 'Partition already exists: ' || partition_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically create partitions for next 3 months
CREATE OR REPLACE FUNCTION query_performance.create_future_partitions(
    months_ahead INTEGER DEFAULT 3
)
RETURNS TABLE(partition_info TEXT) AS $$
DECLARE
    i INTEGER;
    target_date DATE;
BEGIN
    FOR i IN 0..months_ahead-1 LOOP
        target_date := CURRENT_DATE + (i || ' months')::INTERVAL;
        RETURN QUERY SELECT query_performance.create_monthly_partition(target_date);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Enhanced archive function that works with partitioned table
CREATE OR REPLACE FUNCTION query_performance.archive_old_logs(
    older_than_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
    cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    cutoff_date := NOW() - INTERVAL '1 day' * older_than_days;
    
    -- Move old data to archive table (partitioned)
    INSERT INTO query_performance.query_log_archive
    SELECT * FROM query_performance.query_log
    WHERE executed_at < cutoff_date;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    -- Delete from main table
    DELETE FROM query_performance.query_log
    WHERE executed_at < cutoff_date;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get archive statistics
CREATE OR REPLACE VIEW query_performance.archive_statistics AS
SELECT 
    'query_log_archive' as table_name,
    COUNT(*) as total_rows,
    MIN(executed_at) as earliest_date,
    MAX(executed_at) as latest_date,
    COUNT(DISTINCT DATE_TRUNC('month', executed_at)) as months_covered
FROM query_performance.query_log_archive;

-- Function to drop old partitions (cleanup very old archived data)
CREATE OR REPLACE FUNCTION query_performance.drop_old_partitions(
    older_than_months INTEGER DEFAULT 24
)
RETURNS TABLE(dropped_partition TEXT, drop_status TEXT) AS $$
DECLARE
    partition_rec RECORD;
    cutoff_date DATE;
BEGIN
    cutoff_date := DATE_TRUNC('month', CURRENT_DATE - (older_than_months || ' months')::INTERVAL);
    
    FOR partition_rec IN
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'query_performance' 
        AND tablename LIKE 'query_log_archive_%'
        AND tablename < 'query_log_archive_' || TO_CHAR(cutoff_date, 'YYYY_MM')
    LOOP
        BEGIN
            EXECUTE 'DROP TABLE query_performance.' || partition_rec.tablename;
            RETURN QUERY SELECT partition_rec.tablename, 'DROPPED'::TEXT;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT partition_rec.tablename, 'ERROR: ' || SQLERRM;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Create partitions for the next 6 months
SELECT * FROM query_performance.create_future_partitions(6);

-- Archive old data
SELECT query_performance.archive_old_logs(90);

-- Drop partitions older than 24 months
SELECT * FROM query_performance.drop_old_partitions(24);


--- External Monitoring of API endpoints 
-- Function to generate performance report JSON
CREATE OR REPLACE FUNCTION query_performance.get_performance_report(
    p_schema_name TEXT DEFAULT NULL,
    p_hours_back INTEGER DEFAULT 24
)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'report_generated', NOW(),
            'schema_filter', p_schema_name,
            'time_range_hours', p_hours_back,
            'summary', json_build_object(
                'total_queries', COUNT(*),
                'avg_execution_time_ms', ROUND(AVG(execution_time_ms), 2),
                'max_execution_time_ms', MAX(execution_time_ms),
                'total_rows_processed', SUM(rows_returned)
            ),
            'top_slow_queries', (
                SELECT json_agg(json_build_object(
                    'query_text', LEFT(query_text, 100),
                    'execution_time_ms', execution_time_ms,
                    'tables_used', tables_used
                ))
                FROM (
                    SELECT query_text, execution_time_ms, tables_used
                    FROM query_performance.query_log
                    WHERE (p_schema_name IS NULL OR schema_name = p_schema_name)
                        AND executed_at > NOW() - INTERVAL '1 hour' * p_hours_back
                    ORDER BY execution_time_ms DESC
                    LIMIT 10
                ) slow
            )
        )
        FROM query_performance.query_log
        WHERE (p_schema_name IS NULL OR schema_name = p_schema_name)
            AND executed_at > NOW() - INTERVAL '1 hour' * p_hours_back
    );
END;
$$ LANGUAGE plpgsql;


-- table for database health metrics 
-- Table for database health metrics
CREATE TABLE IF NOT EXISTS query_performance.database_health_metrics (
    metric_id SERIAL PRIMARY KEY,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    database_name TEXT,
    active_connections INTEGER,
    max_connections INTEGER,
    connection_utilization_percent DECIMAL(5,2),
    cache_hit_ratio DECIMAL(5,2),
    dead_tuples BIGINT,
    autovacuum_running BOOLEAN,
    background_workers_active INTEGER,
    replication_lag_bytes BIGINT,
    disk_usage_percent DECIMAL(5,2),
    load_average_1min DECIMAL(6,2),
    load_average_5min DECIMAL(6,2),
    load_average_15min DECIMAL(6,2)
);

-- Function to collect database health metrics
CREATE OR REPLACE FUNCTION query_performance.collect_database_health()
RETURNS VOID AS $$
DECLARE
    v_active_conn INTEGER;
    v_max_conn INTEGER;
    v_cache_hit DECIMAL(5,2);
    v_dead_tuples BIGINT;
    v_autovacuum BOOLEAN;
    v_bg_workers INTEGER;
BEGIN
    -- Active connections
    SELECT COUNT(*) INTO v_active_conn FROM pg_stat_activity WHERE state = 'active';
    SELECT setting::INTEGER INTO v_max_conn FROM pg_settings WHERE name = 'max_connections';
    
    -- Cache hit ratio (approximate)
    SELECT 
        CASE 
            WHEN (sum(heap_blks_hit) + sum(heap_blks_read)) > 0 
            THEN ROUND((sum(heap_blks_hit)::DECIMAL / (sum(heap_blks_hit) + sum(heap_blks_read))) * 100, 2)
            ELSE 0 
        END INTO v_cache_hit
    FROM pg_statio_user_tables;
    
    -- Dead tuples
    SELECT COALESCE(SUM(n_dead_tup), 0) INTO v_dead_tuples FROM pg_stat_user_tables;
    
    -- Autovacuum status
    SELECT EXISTS (
        SELECT 1 FROM pg_stat_activity 
        WHERE query LIKE '%autovacuum%' AND state = 'active'
    ) INTO v_autovacuum;
    
    -- Background workers
    SELECT COUNT(*) INTO v_bg_workers 
    FROM pg_stat_activity 
    WHERE backend_type = 'background worker';
    
    INSERT INTO query_performance.database_health_metrics (
        database_name, active_connections, max_connections, 
        connection_utilization_percent, cache_hit_ratio, dead_tuples,
        autovacuum_running, background_workers_active
    ) VALUES (
        current_database(), v_active_conn, v_max_conn,
        ROUND((v_active_conn::DECIMAL / v_max_conn) * 100, 2),
        v_cache_hit, v_dead_tuples,
        v_autovacuum, v_bg_workers
    );
END;
$$ LANGUAGE plpgsql;

-- Health dashboard view
CREATE OR REPLACE VIEW query_performance.database_health_dashboard AS
SELECT 
    collected_at,
    database_name,
    active_connections,
    connection_utilization_percent,
    cache_hit_ratio,
    dead_tuples,
    autovacuum_running,
    background_workers_active,
    CASE 
        WHEN connection_utilization_percent > 80 THEN 'CRITICAL'
        WHEN connection_utilization_percent > 60 THEN 'WARNING'
        WHEN cache_hit_ratio < 90 THEN 'WARNING'
        WHEN dead_tuples > 1000000 THEN 'WARNING'
        ELSE 'HEALTHY'
    END as health_status
FROM query_performance.database_health_metrics
WHERE collected_at > NOW() - INTERVAL '1 hour'
ORDER BY collected_at DESC;

--- Indexes performance and usage analysis -- we need to track this as well
-- Table for index performance tracking
CREATE TABLE IF NOT EXISTS query_performance.index_performance (
    index_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    index_name TEXT NOT NULL,
    index_type TEXT,
    index_size_bytes BIGINT,
    scans BIGINT,
    tuples_read BIGINT,
    tuples_fetched BIGINT,
    last_scan TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to collect index statistics
CREATE OR REPLACE FUNCTION query_performance.collect_index_statistics()
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance.index_performance (
        schema_name, table_name, index_name, index_type,
        index_size_bytes, scans, tuples_read, tuples_fetched, last_scan
    )
    SELECT 
        schemaname, tablename, indexname, 
        CASE 
            WHEN indexdef ILIKE '%btree%' THEN 'BTREE'
            WHEN indexdef ILIKE '%hash%' THEN 'HASH'
            WHEN indexdef ILIKE '%gist%' THEN 'GIST'
            WHEN indexdef ILIKE '%gin%' THEN 'GIN'
            WHEN indexdef ILIKE '%brin%' THEN 'BRIN'
            ELSE 'OTHER'
        END as index_type,
        pg_relation_size(schemaname || '.' || indexname) as index_size_bytes,
        idx_scan as scans,
        idx_tup_read as tuples_read,
        idx_tup_fetch as tuples_fetched,
        last_idx_scan as last_scan
    FROM pg_stat_user_indexes psi
    JOIN pg_indexes pi ON psi.schemaname = pi.schemaname AND psi.indexname = pi.indexname
    ON CONFLICT (schema_name, table_name, index_name) 
    DO UPDATE SET
        scans = EXCLUDED.scans,
        tuples_read = EXCLUDED.tuples_read,
        tuples_fetched = EXCLUDED.tuples_fetched,
        last_scan = EXCLUDED.last_scan,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Unused indexes view
CREATE OR REPLACE VIEW query_performance.unused_indexes AS
SELECT 
    schema_name,
    table_name,
    index_name,
    index_size_bytes,
    scans,
    tuples_read,
    tuples_fetched,
    pg_size_pretty(index_size_bytes) as size_pretty
FROM query_performance.index_performance
WHERE scans = 0 
    AND created_at < NOW() - INTERVAL '30 days'
    AND index_name NOT LIKE '%_pkey'  -- Exclude primary keys
ORDER BY index_size_bytes DESC;


--- Query execution plan analysis 
-- storing the execution plan 
-- Table for execution plan storage
CREATE TABLE IF NOT EXISTS query_performance.query_execution_plans (
    plan_id SERIAL PRIMARY KEY,
    query_hash TEXT NOT NULL,
    schema_name TEXT NOT NULL,
    plan_json JSONB,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    actual_rows BIGINT,
    plan_cost DECIMAL(12,2),
    plan_width INTEGER,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- Create indexes 
CREATE INDEX IF NOT EXISTS idx_query_plans_hash ON query_performance.query_execution_plans (query_hash);
CREATE INDEX IF NOT EXISTS idx_query_plans_time ON query_performance.query_execution_plans (collected_at);
CREATE INDEX IF NOT EXISTS idx_query_plans_schema_time ON query_performance.query_execution_plans (schema_name, collected_at DESC);


CREATE TABLE IF NOT EXISTS query_performance.external_monitoring (
    integration_id SERIAL PRIMARY KEY,
    system_name TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    metric_labels JSONB,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_external_metrics ON query_performance.external_monitoring (system_name, metric_name, collected_at);
-- Function to capture and analyze execution plans
CREATE OR REPLACE FUNCTION query_performance.capture_execution_plan(
    p_schema_name TEXT,
    p_query_text TEXT
)
RETURNS TABLE(
    plan_id INTEGER,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    actual_rows BIGINT
) AS $$
DECLARE
    plan_result JSONB;
    v_query_hash TEXT;
    v_plan_id INTEGER;
    v_execution_time DECIMAL(12,3);
    v_planning_time DECIMAL(12,3);
    v_actual_rows BIGINT;
BEGIN
    v_query_hash := md5(p_query_text);
    
    -- Capture execution plan (this requires proper permissions)
    BEGIN
        EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || p_query_text INTO plan_result;
        
        -- Extract metrics from plan
        v_execution_time := (plan_result->0->>'Execution Time')::DECIMAL(12,3);
        v_planning_time := (plan_result->0->>'Planning Time')::DECIMAL(12,3);
        v_actual_rows := (plan_result->0->'Plan'->>'Actual Rows')::BIGINT;
        
        -- Store plan
        INSERT INTO query_performance.query_execution_plans (
            query_hash, schema_name, plan_json, execution_time_ms, 
            planning_time_ms, actual_rows, plan_cost, plan_width
        ) VALUES (
            v_query_hash, p_schema_name, plan_result, v_execution_time,
            v_planning_time, v_actual_rows,
            (plan_result->0->'Plan'->>'Total Cost')::DECIMAL(12,2),
            (plan_result->0->'Plan'->>'Plan Width')::INTEGER
        ) RETURNING query_execution_plans.plan_id INTO v_plan_id;
        
        RETURN QUERY SELECT v_plan_id, v_execution_time, v_planning_time, v_actual_rows;
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail
        RAISE NOTICE 'Could not capture execution plan: %', SQLERRM;
        RETURN QUERY SELECT NULL::INTEGER, 0.0::DECIMAL, 0.0::DECIMAL, 0::BIGINT;
    END;
END;
$$ LANGUAGE plpgsql;


-- Create indexes for health metrics
CREATE INDEX IF NOT EXISTS idx_health_metrics_time ON query_performance.database_health_metrics (collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_metrics_db_time ON query_performance.database_health_metrics (database_name, collected_at DESC);



-- Enhanced index performance table
CREATE TABLE IF NOT EXISTS query_performance.index_performance (
    index_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    index_name TEXT NOT NULL,
    index_type TEXT,
    index_size_bytes BIGINT,
    scans BIGINT,
    tuples_read BIGINT,
    tuples_fetched BIGINT,
    last_scan TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(schema_name, table_name, index_name)
);

-- Create indexes for index performance
CREATE INDEX IF NOT EXISTS idx_index_perf_schema_table ON query_performance.index_performance (schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_index_perf_scans ON query_performance.index_performance (scans);
CREATE INDEX IF NOT EXISTS idx_index_perf_updated ON query_performance.index_performance (updated_at DESC);

-- Enhanced workload patterns table
CREATE TABLE IF NOT EXISTS query_performance.workload_patterns (
    pattern_id SERIAL PRIMARY KEY,
    pattern_hash TEXT UNIQUE NOT NULL,
    pattern_template TEXT,
    query_category TEXT,
    avg_execution_time_ms DECIMAL(12,3),
    execution_count BIGINT,
    peak_hour INTEGER,
    day_of_week INTEGER,
    seasonal_pattern TEXT,
    resource_intensity TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for workload patterns
CREATE INDEX IF NOT EXISTS idx_workload_pattern_hash ON query_performance.workload_patterns (pattern_hash);
CREATE INDEX IF NOT EXISTS idx_workload_last_seen ON query_performance.workload_patterns (last_seen DESC);
CREATE INDEX IF NOT EXISTS idx_workload_category ON query_performance.workload_patterns (query_category);

-- Enhanced tuning recommendations table
CREATE TABLE IF NOT EXISTS query_performance.tuning_recommendations (
    recommendation_id SERIAL PRIMARY KEY,
    recommendation_type TEXT NOT NULL,
    target_object TEXT,
    current_state JSONB,
    recommended_action TEXT,
    expected_improvement_percent DECIMAL(5,2),
    implementation_difficulty TEXT,
    priority_score INTEGER,
    status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    implemented_at TIMESTAMP WITH TIME ZONE,
    created_by TEXT DEFAULT CURRENT_USER
);

-- Create indexes for tuning recommendations
CREATE INDEX IF NOT EXISTS idx_tuning_type_status ON query_performance.tuning_recommendations (recommendation_type, status);
CREATE INDEX IF NOT EXISTS idx_tuning_priority ON query_performance.tuning_recommendations (priority_score DESC);
CREATE INDEX IF NOT EXISTS idx_tuning_created ON query_performance.tuning_recommendations (created_at DESC);

-- Enhanced capacity planning table
CREATE TABLE IF NOT EXISTS query_performance.capacity_planning (
    capacity_id SERIAL PRIMARY KEY,
    metric_type TEXT NOT NULL,
    current_value DECIMAL(15,2),
    projected_value DECIMAL(15,2),
    threshold_value DECIMAL(15,2),
    projected_date DATE,
    confidence_level DECIMAL(5,2),
    recommendation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for capacity planning
CREATE INDEX IF NOT EXISTS idx_capacity_metric_date ON query_performance.capacity_planning (metric_type, projected_date);
CREATE INDEX IF NOT EXISTS idx_capacity_created ON query_performance.capacity_planning (created_at DESC);




-- Function for capacity forecasting
CREATE OR REPLACE FUNCTION query_performance.forecast_capacity_needs()
RETURNS VOID AS $$
DECLARE
    avg_growth_rate DECIMAL(8,4);
    current_disk_usage BIGINT;
    projected_disk_usage BIGINT;
    disk_threshold BIGINT;
BEGIN
    -- Disk usage forecasting (simplified linear growth model)
    SELECT COALESCE(AVG(disk_usage_bytes), 0) INTO current_disk_usage
    FROM (
        SELECT SUM(pg_database_size(datname)) as disk_usage_bytes
        FROM pg_database
        WHERE datname = current_database()
        ORDER BY pg_database_size(datname) DESC
        LIMIT 10
    ) recent_usage;
    
    -- Calculate average growth rate (last 30 days)
    WITH usage_trend AS (
        SELECT 
            date_trunc('day', collected_at) as day,
            AVG(disk_usage_bytes) as avg_usage
        FROM query_performance.database_health_metrics
        WHERE collected_at > NOW() - INTERVAL '30 days'
        GROUP BY date_trunc('day', collected_at)
        ORDER BY day
    )
    SELECT 
        CASE 
            WHEN COUNT(*) > 1 
            THEN (MAX(avg_usage) - MIN(avg_usage)) / (COUNT(*) * MIN(avg_usage))
            ELSE 0.01 
        END INTO avg_growth_rate
    FROM usage_trend;
    
    -- Project 90 days ahead
    projected_disk_usage := (current_disk_usage * (1 + avg_growth_rate * 90))::BIGINT;
    disk_threshold := (current_disk_usage * 1.5)::BIGINT; -- 50% buffer
    
    INSERT INTO query_performance.capacity_planning (
        metric_type, current_value, projected_value, threshold_value,
        projected_date, confidence_level, recommendation
    ) VALUES (
        'DISK',
        current_disk_usage,
        projected_disk_usage,
        disk_threshold,
        CURRENT_DATE + INTERVAL '90 days',
        CASE WHEN avg_growth_rate > 0 THEN 100 - (avg_growth_rate * 1000) ELSE 95 END,
        CASE 
            WHEN projected_disk_usage > disk_threshold 
            THEN 'Plan disk expansion: ' || pg_size_pretty((projected_disk_usage - disk_threshold)::BIGINT)
            ELSE 'Current capacity sufficient'
        END
    );
END;
$$ LANGUAGE plpgsql;

-- Capacity planning dashboard
CREATE OR REPLACE VIEW query_performance.capacity_dashboard AS
SELECT 
    metric_type,
    pg_size_pretty(current_value::BIGINT) as current_usage,
    pg_size_pretty(projected_value::BIGINT) as projected_usage,
    pg_size_pretty(threshold_value::BIGINT) as threshold,
    projected_date,
    confidence_level,
    recommendation,
    CASE 
        WHEN projected_value > threshold_value THEN 'ACTION REQUIRED'
        WHEN projected_value > threshold_value * 0.8 THEN 'MONITOR CLOSELY'
        ELSE 'HEALTHY'
    END as status
FROM query_performance.capacity_planning
WHERE created_at > NOW() - INTERVAL '1 week'
ORDER BY created_at DESC;




-- Function to normalize and categorize queries
CREATE OR REPLACE FUNCTION query_performance.normalize_query_pattern(query_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN regexp_replace(
        regexp_replace(
            lower(trim(query_text)),
            '\$[0-9]+', '$N', 'g'
        ),
        '[0-9]{4}-[0-9]{2}-[0-9]{2}', 'DATE', 'g'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to categorize query workloads
CREATE OR REPLACE FUNCTION query_performance.categorize_workload(query_text TEXT)
RETURNS TEXT AS $$
BEGIN
    CASE 
        WHEN query_text ILIKE '%select%count(%' AND query_text !~* 'limit' THEN RETURN 'REPORTING';
        WHEN query_text ILIKE '%join%' AND query_text ILIKE '%group by%' THEN RETURN 'ANALYTICS';
        WHEN length(query_text) < 200 AND query_text ILIKE '%where%id%=%' THEN RETURN 'OLTP';
        WHEN query_text ILIKE '%insert%' OR query_text ILIKE '%update%' OR query_text ILIKE '%delete%' THEN RETURN 'DML';
        WHEN query_text ILIKE '%create%' OR query_text ILIKE '%alter%' OR query_text ILIKE '%drop%' THEN RETURN 'DDL';
        ELSE RETURN 'MISCELLANEOUS';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to analyze workload patterns
CREATE OR REPLACE FUNCTION query_performance.analyze_workload_patterns()
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance.workload_patterns (
        pattern_hash, pattern_template, query_category,
        avg_execution_time_ms, execution_count, peak_hour, day_of_week,
        seasonal_pattern, resource_intensity
    )
    SELECT 
        md5(query_performance.normalize_query_pattern(query_text)) as pattern_hash,
        query_performance.normalize_query_pattern(query_text) as pattern_template,
        query_performance.categorize_workload(query_text) as query_category,
        AVG(execution_time_ms) as avg_execution_time,
        COUNT(*) as execution_count,
        EXTRACT(HOUR FROM executed_at)::INTEGER as peak_hour,
        EXTRACT(DOW FROM executed_at)::INTEGER as day_of_week,
        CASE 
            WHEN EXTRACT(DOW FROM executed_at) IN (0,6) THEN 'WEEKEND'
            ELSE 'WEEKDAY'
        END as seasonal_pattern,
        CASE 
            WHEN AVG(execution_time_ms) > 1000 THEN 'HIGH'
            WHEN AVG(execution_time_ms) > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END as resource_intensity
    FROM query_performance.query_log
    WHERE executed_at > NOW() - INTERVAL '7 days'
    GROUP BY 
        md5(query_performance.normalize_query_pattern(query_text)),
        query_performance.normalize_query_pattern(query_text),
        query_performance.categorize_workload(query_text),
        EXTRACT(HOUR FROM executed_at),
        EXTRACT(DOW FROM executed_at)
    ON CONFLICT (pattern_hash)
    DO UPDATE SET
        avg_execution_time_ms = (
            (query_performance.workload_patterns.avg_execution_time_ms * query_performance.workload_patterns.execution_count) + 
            (EXCLUDED.avg_execution_time_ms * EXCLUDED.execution_count)
        ) / (query_performance.workload_patterns.execution_count + EXCLUDED.execution_count),
        execution_count = query_performance.workload_patterns.execution_count + EXCLUDED.execution_count,
        last_seen = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Workload analysis dashboard
CREATE OR REPLACE VIEW query_performance.workload_analysis AS
SELECT 
    query_category,
    COUNT(*) as pattern_count,
    SUM(execution_count) as total_executions,
    AVG(avg_execution_time_ms) as avg_time_ms,
    string_agg(DISTINCT seasonal_pattern, ', ') as patterns,
    COUNT(DISTINCT peak_hour) as active_hours
FROM query_performance.workload_patterns
WHERE last_seen > NOW() - INTERVAL '30 days'
GROUP BY query_category
ORDER BY total_executions DESC;


-- Function to generate index recommendations
CREATE OR REPLACE FUNCTION query_performance.generate_index_recommendations()
RETURNS VOID AS $$
DECLARE
    slow_query_rec RECORD;
BEGIN
    -- Find slow queries with WHERE clauses but no matching indexes
    FOR slow_query_rec IN
        SELECT 
            query_hash,
            schema_name,
            query_text,
            execution_time_ms,
            tables_used
        FROM query_performance.query_log
        WHERE query_type = 'SELECT'
            AND execution_time_ms > 500  -- Slow queries
            AND query_text ILIKE '%where%'
            AND executed_at > NOW() - INTERVAL '1 day'
        ORDER BY execution_time_ms DESC
        LIMIT 50
    LOOP
        -- Simple recommendation logic (enhance with more sophisticated analysis)
        INSERT INTO query_performance.tuning_recommendations (
            recommendation_type, target_object, 
            current_state, recommended_action,
            expected_improvement_percent, implementation_difficulty,
            priority_score
        )
        SELECT 
            'INDEX',
            slow_query_rec.schema_name || '.' || unnest(slow_query_rec.tables_used),
            jsonb_build_object(
                'query_hash', slow_query_rec.query_hash,
                'execution_time_ms', slow_query_rec.execution_time_ms,
                'query_text', LEFT(slow_query_rec.query_text, 200)
            ),
            'Consider creating index on columns used in WHERE clause',
            60.0, -- Estimated 60% improvement
            'EASY',
            CASE 
                WHEN slow_query_rec.execution_time_ms > 5000 THEN 10
                WHEN slow_query_rec.execution_time_ms > 1000 THEN 7
                ELSE 5
            END
        WHERE NOT EXISTS (
            SELECT 1 FROM query_performance.tuning_recommendations tr
            WHERE tr.target_object = slow_query_rec.schema_name || '.' || unnest(slow_query_rec.tables_used)
                AND tr.recommendation_type = 'INDEX'
                AND tr.status = 'PENDING'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Comprehensive tuning dashboard
CREATE OR REPLACE VIEW query_performance.tuning_dashboard AS
SELECT 
    recommendation_type,
    COUNT(*) as recommendation_count,
    AVG(expected_improvement_percent) as avg_expected_improvement,
    COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_count,
    COUNT(CASE WHEN status = 'IMPLEMENTED' THEN 1 END) as implemented_count,
    string_agg(DISTINCT implementation_difficulty, ', ') as difficulties
FROM query_performance.tuning_recommendations
GROUP BY recommendation_type
ORDER BY AVG(expected_improvement_percent) DESC;



-- Function to export metrics for Prometheus
CREATE OR REPLACE FUNCTION query_performance.export_prometheus_metrics()
RETURNS TABLE(
    metric_line TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT format(
        'db_query_avg_duration_ms{schema="%s"} %s %s',
        schema_name,
        ROUND(AVG(execution_time_ms), 2),
        EXTRACT(EPOCH FROM MAX(executed_at))::BIGINT * 1000
    ) as metric_line
    FROM query_performance.query_log
    WHERE executed_at > NOW() - INTERVAL '5 minutes'
    GROUP BY schema_name
    
    UNION ALL
    
    SELECT format(
        'db_active_connections %s %s',
        active_connections,
        EXTRACT(EPOCH FROM collected_at)::BIGINT * 1000
    ) as metric_line
    FROM query_performance.database_health_metrics
    WHERE collected_at > NOW() - INTERVAL '5 minutes'
    ORDER BY 1;
END;
$$ LANGUAGE plpgsql;

-- -- Function to send alerts to external systems
-- CREATE OR REPLACE FUNCTION query_performance.send_external_alert(
--     alert_message TEXT,
--     alert_level TEXT DEFAULT 'WARNING', -- CRITICAL, WARNING, INFO
--     target_system TEXT DEFAULT 'SLACK' -- SLACK, EMAIL, WEBHOOK
-- )
-- RETURNS VOID AS $$
-- DECLARE
--     webhook_url TEXT;
-- BEGIN
--     -- This would integrate with actual external systems
--     -- For now, just log the alert
--     RAISE NOTICE 'EXTERNAL ALERT [%] to %: %', alert_level, target_system, alert_message;
    
--     -- In production, you would:
--     -- 1. Get webhook URL from configuration
--     -- 2. Make HTTP call to external system
--     -- 3. Handle response and errors
-- END;
-- $$ LANGUAGE plpgsql;


--support of multiple database instance mnitoring 
-- Table for monitoring multiple database instances
CREATE TABLE IF NOT EXISTS query_performance.database_instances (
    instance_id SERIAL PRIMARY KEY,
    instance_name TEXT UNIQUE NOT NULL,
    host_name TEXT NOT NULL,
    port INTEGER DEFAULT 5432,
    database_version TEXT,
    instance_type TEXT, -- PRIMARY, REPLICA, STANDBY
    environment TEXT, -- PROD, STAGING, DEV
    region TEXT,
    status TEXT DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, MAINTENANCE
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enhanced health metrics to include instance tracking
ALTER TABLE query_performance.database_health_metrics 
ADD COLUMN IF NOT EXISTS instance_id INTEGER REFERENCES query_performance.database_instances(instance_id);

-- Function to register database instances
CREATE OR REPLACE FUNCTION query_performance.register_database_instance(
    p_instance_name TEXT,
    p_host_name TEXT,
    p_port INTEGER DEFAULT 5432,
    p_instance_type TEXT DEFAULT 'PRIMARY',
    p_environment TEXT DEFAULT 'PROD',
    p_region TEXT DEFAULT 'LOCAL'
)
RETURNS INTEGER AS $$
DECLARE
    v_instance_id INTEGER;
BEGIN
    INSERT INTO query_performance.database_instances (
        instance_name, host_name, port, instance_type, environment, region
    ) VALUES (
        p_instance_name, p_host_name, p_port, p_instance_type, p_environment, p_region
    )
    ON CONFLICT (instance_name) 
    DO UPDATE SET
        host_name = EXCLUDED.host_name,
        port = EXCLUDED.port,
        instance_type = EXCLUDED.instance_type,
        environment = EXCLUDED.environment,
        region = EXCLUDED.region,
        last_seen = CURRENT_TIMESTAMP
    RETURNING instance_id INTO v_instance_id;
    
    RETURN v_instance_id;
END;
$$ LANGUAGE plpgsql;

-- query performance regression detection 
-- Table for storing query performance history
CREATE TABLE IF NOT EXISTS query_performance.query_performance_history (
    history_id SERIAL PRIMARY KEY,
    query_hash TEXT NOT NULL,
    schema_name TEXT NOT NULL,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    rows_returned BIGINT,
    execution_date DATE NOT NULL,
    execution_count INTEGER DEFAULT 1,
    UNIQUE(query_hash, schema_name, execution_date)
);

-- Function to detect performance regressions
CREATE OR REPLACE FUNCTION query_performance.detect_performance_regressions(
    days_back INTEGER DEFAULT 7,
    regression_threshold_percent DECIMAL(5,2) DEFAULT 25.0
)
RETURNS TABLE(
    query_hash TEXT,
    schema_name TEXT,
    current_avg_time DECIMAL(12,3),
    previous_avg_time DECIMAL(12,3),
    regression_percent DECIMAL(5,2),
    regression_severity TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH current_period AS (
        SELECT 
            query_hash,
            schema_name,
            AVG(execution_time_ms) as avg_time
        FROM query_performance.query_log
        WHERE executed_at >= CURRENT_DATE - INTERVAL '1 day'
        GROUP BY query_hash, schema_name
    ),
    previous_period AS (
        SELECT 
            query_hash,
            schema_name,
            AVG(execution_time_ms) as avg_time
        FROM query_performance.query_log
        WHERE executed_at >= CURRENT_DATE - INTERVAL '1 day' * (days_back + 1)
            AND executed_at < CURRENT_DATE - INTERVAL '1 day'
        GROUP BY query_hash, schema_name
    )
    SELECT 
        c.query_hash,
        c.schema_name,
        c.avg_time as current_avg_time,
        p.avg_time as previous_avg_time,
        ROUND(((c.avg_time - p.avg_time) / p.avg_time) * 100, 2) as regression_percent,
        CASE 
            WHEN ((c.avg_time - p.avg_time) / p.avg_time) * 100 > regression_threshold_percent * 2 THEN 'SEVERE'
            WHEN ((c.avg_time - p.avg_time) / p.avg_time) * 100 > regression_threshold_percent THEN 'MODERATE'
            ELSE 'MILD'
        END as regression_severity
    FROM current_period c
    JOIN previous_period p ON c.query_hash = p.query_hash AND c.schema_name = p.schema_name
    WHERE p.avg_time > 0
        AND ((c.avg_time - p.avg_time) / p.avg_time) * 100 > regression_threshold_percent
    ORDER BY regression_percent DESC;
END;
$$ LANGUAGE plpgsql;

-- Automated regression alerting
CREATE OR REPLACE FUNCTION query_performance.check_performance_regressions()
RETURNS VOID AS $$
DECLARE
    regression_rec RECORD;
BEGIN
    FOR regression_rec IN
        SELECT * FROM query_performance.detect_performance_regressions(7, 25.0)
    LOOP
        -- Log the regression
        INSERT INTO query_performance.tuning_recommendations (
            recommendation_type,
            target_object,
            current_state,
            recommended_action,
            expected_improvement_percent,
            implementation_difficulty,
            priority_score,
            status
        ) VALUES (
            'PERFORMANCE_REGRESSION',
            regression_rec.schema_name || ':' || LEFT(regression_rec.query_hash, 16),
            jsonb_build_object(
                'current_time', regression_rec.current_avg_time,
                'previous_time', regression_rec.previous_avg_time,
                'regression_percent', regression_rec.regression_percent
            ),
            'Investigate performance regression for query pattern',
            regression_rec.regression_percent,
            'MEDIUM',
            CASE 
                WHEN regression_rec.regression_severity = 'SEVERE' THEN 9
                WHEN regression_rec.regression_severity = 'MODERATE' THEN 7
                ELSE 5
            END,
            'PENDING'
        );
        
        -- Send alert for severe regressions
        IF regression_rec.regression_severity = 'SEVERE' THEN
            PERFORM query_performance.send_external_alert(
                format('SEVERE Performance Regression: Query %s in schema %s slowed by %s%%',
                       LEFT(regression_rec.query_hash, 16),
                       regression_rec.schema_name,
                       regression_rec.regression_percent),
                'CRITICAL',
                'SLACK'
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Table for query rewriting suggestions
CREATE TABLE IF NOT EXISTS query_performance.query_rewrite_suggestions (
    suggestion_id SERIAL PRIMARY KEY,
    original_query_hash TEXT NOT NULL,
    rewritten_query_hash TEXT NOT NULL,
    original_query TEXT,
    rewritten_query TEXT,
    expected_performance_gain_percent DECIMAL(5,2),
    rewrite_pattern TEXT, -- SUBQUERY_TO_JOIN, EXISTS_TO_JOIN, etc.
    complexity_reduction INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    applied BOOLEAN DEFAULT FALSE,
    applied_at TIMESTAMP WITH TIME ZONE
);

-- Function to suggest query rewrites
CREATE OR REPLACE FUNCTION query_performance.suggest_query_rewrites()
RETURNS VOID AS $$
DECLARE
    slow_query_rec RECORD;
BEGIN
    -- Find queries that could benefit from rewriting
    FOR slow_query_rec IN
        SELECT 
            query_hash,
            schema_name,
            query_text,
            execution_time_ms,
            rows_returned
        FROM query_performance.query_log
        WHERE query_type = 'SELECT'
            AND execution_time_ms > 500
            AND (query_text ILIKE '%select%select%' OR query_text ILIKE '%not exists%')
            AND executed_at > NOW() - INTERVAL '1 day'
        ORDER BY execution_time_ms DESC
        LIMIT 20
    LOOP
        -- Suggest subquery to JOIN conversion
        IF slow_query_rec.query_text ILIKE '%select%select%' THEN
            INSERT INTO query_performance.query_rewrite_suggestions (
                original_query_hash,
                rewritten_query_hash,
                original_query,
                rewritten_query,
                expected_performance_gain_percent,
                rewrite_pattern,
                complexity_reduction
            ) VALUES (
                slow_query_rec.query_hash,
                md5(regexp_replace(slow_query_rec.query_text, 'select.*select', 'JOIN version', 'gi')),
                slow_query_rec.query_text,
                '-- Suggested rewrite: Convert correlated subquery to JOIN',
                40.0,
                'SUBQUERY_TO_JOIN',
                2
            )
            ON CONFLICT DO NOTHING;
        END IF;
        
        -- Suggest EXISTS to JOIN conversion
        IF slow_query_rec.query_text ILIKE '%not exists%' THEN
            INSERT INTO query_performance.query_rewrite_suggestions (
                original_query_hash,
                rewritten_query_hash,
                original_query,
                rewritten_query,
                expected_performance_gain_percent,
                rewrite_pattern,
                complexity_reduction
            ) VALUES (
                slow_query_rec.query_hash,
                md5(regexp_replace(slow_query_rec.query_text, 'not exists', 'LEFT JOIN', 'gi')),
                slow_query_rec.query_text,
                '-- Suggested rewrite: Convert NOT EXISTS to LEFT JOIN with IS NULL',
                35.0,
                'EXISTS_TO_JOIN',
                1
            )
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- View for query rewrite opportunities
CREATE OR REPLACE VIEW query_performance.query_rewrite_opportunities AS
SELECT 
    rewrite_pattern,
    COUNT(*) as suggestion_count,
    AVG(expected_performance_gain_percent) as avg_gain_percent,
    SUM(CASE WHEN applied THEN 1 ELSE 0 END) as applied_count,
    string_agg(DISTINCT LEFT(original_query_hash, 16), ', ') as affected_queries
FROM query_performance.query_rewrite_suggestions
GROUP BY rewrite_pattern
ORDER BY avg_gain_percent DESC;


-- Table for tracking database configuration changes
CREATE TABLE IF NOT EXISTS query_performance.database_config_changes (
    change_id SERIAL PRIMARY KEY,
    parameter_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_type TEXT, -- MANUAL, AUTOMATIC, SCHEDULED
    changed_by TEXT DEFAULT CURRENT_USER,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    impact_assessment TEXT,
    rollback_possible BOOLEAN DEFAULT TRUE
);

-- Table for recommended configuration settings
CREATE TABLE IF NOT EXISTS query_performance.config_recommendations (
    recommendation_id SERIAL PRIMARY KEY,
    parameter_name TEXT NOT NULL,
    current_value TEXT,
    recommended_value TEXT,
    rationale TEXT,
    impact_level TEXT, -- LOW, MEDIUM, HIGH, CRITICAL
    category TEXT, -- MEMORY, CONNECTIONS, QUERY, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'PENDING' -- PENDING, APPLIED, REJECTED
);

-- Function to analyze current configuration
CREATE OR REPLACE FUNCTION query_performance.analyze_database_configuration()
RETURNS VOID AS $$
DECLARE
    current_setting RECORD;
BEGIN
    -- Check shared_buffers setting
    SELECT setting INTO current_setting FROM pg_settings WHERE name = 'shared_buffers';
    IF current_setting.setting::BIGINT < 131072 THEN -- Less than 1GB
        INSERT INTO query_performance.config_recommendations (
            parameter_name, current_value, recommended_value,
            rationale, impact_level, category
        ) VALUES (
            'shared_buffers',
            current_setting.setting,
            '131072', -- 1GB
            'Increase shared_buffers for better cache performance',
            'HIGH',
            'MEMORY'
        ) ON CONFLICT DO NOTHING;
    END IF;
    
    -- Check work_mem setting
    SELECT setting INTO current_setting FROM pg_settings WHERE name = 'work_mem';
    IF current_setting.setting::INTEGER < 4096 THEN -- Less than 4MB
        INSERT INTO query_performance.config_recommendations (
            parameter_name, current_value, recommended_value,
            rationale, impact_level, category
        ) VALUES (
            'work_mem',
            current_setting.setting,
            '8192', -- 8MB
            'Increase work_mem for better sort and hash performance',
            'MEDIUM',
            'MEMORY'
        ) ON CONFLICT DO NOTHING;
    END IF;
    
    -- Check max_connections setting
    SELECT setting INTO current_setting FROM pg_settings WHERE name = 'max_connections';
    IF current_setting.setting::INTEGER > 200 THEN
        INSERT INTO query_performance.config_recommendations (
            parameter_name, current_value, recommended_value,
            rationale, impact_level, category
        ) VALUES (
            'max_connections',
            current_setting.setting,
            '100', -- Adjust based on your needs
            'High connection count may impact performance. Consider connection pooling',
            'MEDIUM',
            'CONNECTIONS'
        ) ON CONFLICT DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Configuration dashboard
CREATE OR REPLACE VIEW query_performance.config_dashboard AS
SELECT 
    category,
    COUNT(*) as recommendation_count,
    string_agg(parameter_name || ': ' || current_value || ' → ' || recommended_value, '; ') as changes,
    COUNT(CASE WHEN impact_level = 'CRITICAL' THEN 1 END) as critical_count,
    COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_count
FROM query_performance.config_recommendations
GROUP BY category
ORDER BY 
    MAX(CASE WHEN impact_level = 'CRITICAL' THEN 1 WHEN impact_level = 'HIGH' THEN 2 WHEN impact_level = 'MEDIUM' THEN 3 ELSE 4 END);
	
	
-- Enhanced alert configurations
CREATE TABLE IF NOT EXISTS query_performance.alert_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name TEXT UNIQUE NOT NULL,
    rule_description TEXT,
    metric_type TEXT NOT NULL, -- QUERY_PERFORMANCE, DATABASE_HEALTH, etc.
    condition_expression TEXT NOT NULL, -- e.g., "execution_time_ms > 1000"
    threshold_value NUMERIC,
    duration INTERVAL, -- How long condition must persist
    severity TEXT NOT NULL, -- INFO, WARNING, CRITICAL
    notification_channels TEXT[], -- EMAIL, SLACK, SMS, WEBHOOK
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_triggered TIMESTAMP WITH TIME ZONE
);

-- Alert history table
CREATE TABLE IF NOT EXISTS query_performance.alert_history (
    alert_id SERIAL PRIMARY KEY,
    rule_id INTEGER REFERENCES query_performance.alert_rules(rule_id),
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    alert_message TEXT,
    alert_data JSONB,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by TEXT
);

-- Function to evaluate alert rules
CREATE OR REPLACE FUNCTION query_performance.evaluate_alert_rules()
RETURNS VOID AS $$
DECLARE
    rule_rec RECORD;
    alert_triggered BOOLEAN;
    alert_message TEXT;
BEGIN
    FOR rule_rec IN
        SELECT * FROM query_performance.alert_rules WHERE enabled = TRUE
    LOOP
        alert_triggered := FALSE;
        alert_message := '';
        
        -- Evaluate different types of conditions
        CASE rule_rec.metric_type
            WHEN 'QUERY_PERFORMANCE' THEN
                IF EXISTS (
                    SELECT 1 FROM query_performance.query_log
                    WHERE executed_at > NOW() - COALESCE(rule_rec.duration, INTERVAL '5 minutes')
                        AND execution_time_ms > rule_rec.threshold_value
                ) THEN
                    alert_triggered := TRUE;
                    alert_message := format('Slow queries detected: execution time > %s ms', rule_rec.threshold_value);
                END IF;
                
            WHEN 'DATABASE_HEALTH' THEN
                IF EXISTS (
                    SELECT 1 FROM query_performance.database_health_metrics
                    WHERE collected_at > NOW() - COALESCE(rule_rec.duration, INTERVAL '5 minutes')
                        AND connection_utilization_percent > rule_rec.threshold_value
                ) THEN
                    alert_triggered := TRUE;
                    alert_message := format('High connection utilization: %s%% > %s%%', 
                                          (SELECT MAX(connection_utilization_percent) FROM query_performance.database_health_metrics),
                                          rule_rec.threshold_value);
                END IF;
                
            WHEN 'INDEX_PERFORMANCE' THEN
                IF EXISTS (
                    SELECT 1 FROM query_performance.index_performance
                    WHERE scans = 0 AND created_at < NOW() - INTERVAL '30 days'
                ) THEN
                    alert_triggered := TRUE;
                    alert_message := 'Unused indexes detected that may impact performance';
                END IF;
        END CASE;
        
        -- Trigger alert if condition met
        IF alert_triggered THEN
            INSERT INTO query_performance.alert_history (
                rule_id, alert_message, alert_data
            ) VALUES (
                rule_rec.rule_id,
                alert_message,
                jsonb_build_object('threshold', rule_rec.threshold_value, 'severity', rule_rec.severity)
            );
            
            UPDATE query_performance.alert_rules 
            SET last_triggered = CURRENT_TIMESTAMP 
            WHERE rule_id = rule_rec.rule_id;
            
            -- Send notifications (simplified)
            PERFORM query_performance.send_external_alert(
                alert_message,
                rule_rec.severity,
                unnest(rule_rec.notification_channels)
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Sample alert rules
INSERT INTO query_performance.alert_rules (
    rule_name, rule_description, metric_type, condition_expression,
    threshold_value, duration, severity, notification_channels
) VALUES
    ('slow_queries', 'Alert on queries taking longer than 2 seconds', 
     'QUERY_PERFORMANCE', 'execution_time_ms > 2000',
     2000, INTERVAL '5 minutes', 'WARNING', ARRAY['SLACK', 'EMAIL']),
     
    ('high_connections', 'Alert on high database connection utilization',
     'DATABASE_HEALTH', 'connection_utilization_percent > 80',
     80, INTERVAL '10 minutes', 'CRITICAL', ARRAY['SLACK', 'SMS']),
     
    ('unused_indexes', 'Alert on unused indexes that waste resources',
     'INDEX_PERFORMANCE', 'scans = 0',
     0, INTERVAL '1 day', 'INFO', ARRAY['EMAIL']);
	 
	 
-- Table for performance benchmarks
CREATE TABLE IF NOT EXISTS query_performance.benchmarks (
    benchmark_id SERIAL PRIMARY KEY,
    benchmark_name TEXT NOT NULL,
    benchmark_type TEXT NOT NULL, -- QUERY, WORKLOAD, SCHEMA
    target_object TEXT, -- query_hash, table_name, etc.
    baseline_metrics JSONB,
    current_metrics JSONB,
    improvement_percent DECIMAL(5,2),
    test_duration INTERVAL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    executed_by TEXT DEFAULT CURRENT_USER,
    status TEXT DEFAULT 'COMPLETED' -- RUNNING, COMPLETED, FAILED
);

-- Function to run query benchmarks
CREATE OR REPLACE FUNCTION query_performance.run_query_benchmark(
    p_benchmark_name TEXT,
    p_query_text TEXT,
    p_iterations INTEGER DEFAULT 10
)
RETURNS TABLE(
    iteration INTEGER,
    execution_time_ms DECIMAL(12,3),
    planning_time_ms DECIMAL(12,3),
    rows_returned BIGINT
) AS $$
DECLARE
    i INTEGER;
    start_time TIMESTAMP WITH TIME ZONE;
    end_time TIMESTAMP WITH TIME ZONE;
    exec_time DECIMAL(12,3);
    plan_time DECIMAL(12,3);
    rows_ret BIGINT;
BEGIN
    FOR i IN 1..p_iterations LOOP
        start_time := clock_timestamp();
        
        -- Execute the query
        EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || p_query_text INTO plan_time;
        
        end_time := clock_timestamp();
        exec_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
        
        -- Get row count
        GET DIAGNOSTICS rows_ret = ROW_COUNT;
        
        RETURN QUERY SELECT i, exec_time, plan_time, rows_ret;
        
        -- Store in benchmarks table
        INSERT INTO query_performance.benchmarks (
            benchmark_name, benchmark_type, target_object,
            current_metrics, test_duration
        ) VALUES (
            p_benchmark_name, 'QUERY', md5(p_query_text),
            jsonb_build_object(
                'iteration', i,
                'execution_time_ms', exec_time,
                'planning_time_ms', plan_time,
                'rows_returned', rows_ret
            ),
            (end_time - start_time)
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Benchmark comparison view
CREATE OR REPLACE VIEW query_performance.benchmark_comparison AS
SELECT 
    benchmark_name,
    COUNT(*) as test_runs,
    AVG((current_metrics->>'execution_time_ms')::DECIMAL) as avg_execution_time,
    MIN((current_metrics->>'execution_time_ms')::DECIMAL) as min_execution_time,
    MAX((current_metrics->>'execution_time_ms')::DECIMAL) as max_execution_time,
    STDDEV((current_metrics->>'execution_time_ms')::DECIMAL) as stddev_execution_time,
    AVG((current_metrics->>'rows_returned')::BIGINT) as avg_rows_returned
FROM query_performance.benchmarks
WHERE status = 'COMPLETED'
GROUP BY benchmark_name
ORDER BY avg_execution_time DESC;




-- Table for ML model training data
CREATE TABLE IF NOT EXISTS query_performance.ml_training_data (
    training_id SERIAL PRIMARY KEY,
    query_hash TEXT NOT NULL,
    query_features JSONB, -- Features like table count, join count, etc.
    execution_time_ms DECIMAL(12,3),
    resource_usage JSONB, -- CPU, memory, IO usage
    query_complexity_score INTEGER,
    historical_context JSONB, -- Time of day, day of week, etc.
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to extract ML features from queries
CREATE OR REPLACE FUNCTION query_performance.extract_ml_features(query_text TEXT)
RETURNS JSONB AS $$
DECLARE
    features JSONB;
    table_count INTEGER;
    join_count INTEGER;
    where_clause_present BOOLEAN;
    group_by_present BOOLEAN;
    having_present BOOLEAN;
BEGIN
    -- Count tables
    SELECT array_length(query_performance.extract_table_names(query_text), 1) INTO table_count;
    
    -- Count JOINs
    SELECT COUNT(*) INTO join_count FROM regexp_matches(lower(query_text), '\s+join\s+', 'g');
    
    -- Check for clauses
    where_clause_present := lower(query_text) ~ '\s+where\s+';
    group_by_present := lower(query_text) ~ '\s+group\s+by\s+';
    having_present := lower(query_text) ~ '\s+having\s+';
    
    features := jsonb_build_object(
        'table_count', COALESCE(table_count, 0),
        'join_count', join_count,
        'where_clause', where_clause_present,
        'group_by_clause', group_by_present,
        'having_clause', having_present,
        'query_length', length(query_text),
        'subquery_count', (SELECT COUNT(*) FROM regexp_matches(lower(query_text), '\(\s*select', 'g'))
    );
    
    RETURN features;
END;
$$ LANGUAGE plpgsql;

-- Function to prepare training data
CREATE OR REPLACE FUNCTION query_performance.prepare_ml_training_data(
    days_back INTEGER DEFAULT 30
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance.ml_training_data (
        query_hash, query_features, execution_time_ms, 
        query_complexity_score, historical_context
    )
    SELECT 
        query_hash,
        query_performance.extract_ml_features(query_text) as query_features,
        execution_time_ms,
        (SELECT complexity_score FROM query_performance.analyze_query_complexity(query_text) LIMIT 1),
        jsonb_build_object(
            'hour_of_day', EXTRACT(HOUR FROM executed_at),
            'day_of_week', EXTRACT(DOW FROM executed_at),
            'is_weekend', CASE WHEN EXTRACT(DOW FROM executed_at) IN (0,6) THEN true ELSE false END
        ) as historical_context
    FROM query_performance.query_log
    WHERE executed_at > NOW() - INTERVAL '1 day' * days_back
        AND execution_time_ms IS NOT NULL
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;


---distributed query monitoring and tracing todo
-- Table for distributed query tracking
CREATE TABLE IF NOT EXISTS query_performance.distributed_queries (
    trace_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_trace_id UUID,
    query_id TEXT NOT NULL,
    service_name TEXT NOT NULL,
    operation_name TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_ms DECIMAL(12,3),
    status TEXT, -- SUCCESS, ERROR, TIMEOUT
    error_message TEXT,
    tags JSONB,
    logs JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for cross-database query correlation
CREATE TABLE IF NOT EXISTS query_performance.cross_database_queries (
    correlation_id SERIAL PRIMARY KEY,
    trace_id UUID NOT NULL,
    source_database TEXT NOT NULL,
    target_database TEXT NOT NULL,
    query_text TEXT,
    execution_time_ms DECIMAL(12,3),
    data_transferred_bytes BIGINT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Function to start distributed query trace
CREATE OR REPLACE FUNCTION query_performance.start_distributed_trace(
    p_query_id TEXT,
    p_service_name TEXT,
    p_operation_name TEXT DEFAULT NULL,
    p_parent_trace_id UUID DEFAULT NULL,
    p_tags JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_trace_id UUID;
BEGIN
    v_trace_id := gen_random_uuid();
    
    INSERT INTO query_performance.distributed_queries (
        trace_id, parent_trace_id, query_id, service_name, 
        operation_name, start_time, status, tags
    ) VALUES (
        v_trace_id, p_parent_trace_id, p_query_id, p_service_name,
        p_operation_name, CURRENT_TIMESTAMP, 'RUNNING', p_tags
    );
    
    RETURN v_trace_id;
END;
$$ LANGUAGE plpgsql;

-- Function to end distributed query trace
CREATE OR REPLACE FUNCTION query_performance.end_distributed_trace(
    p_trace_id UUID,
    p_status TEXT DEFAULT 'SUCCESS',
    p_error_message TEXT DEFAULT NULL,
    p_execution_time_ms DECIMAL(12,3) DEFAULT NULL,
    p_logs JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE query_performance.distributed_queries
    SET 
        end_time = CURRENT_TIMESTAMP,
        duration_ms = COALESCE(p_execution_time_ms, 
                              EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - start_time)) * 1000),
        status = p_status,
        error_message = p_error_message,
        logs = p_logs
    WHERE trace_id = p_trace_id;
END;
$$ LANGUAGE plpgsql;

-- Distributed query performance view
CREATE OR REPLACE VIEW query_performance.distributed_query_performance AS
SELECT 
    service_name,
    operation_name,
    COUNT(*) as query_count,
    AVG(duration_ms) as avg_duration_ms,
    MAX(duration_ms) as max_duration_ms,
    MIN(duration_ms) as min_duration_ms,
    COUNT(CASE WHEN status != 'SUCCESS' THEN 1 END) as error_count,
    ROUND(COUNT(CASE WHEN status != 'SUCCESS' THEN 1 END) * 100.0 / COUNT(*), 2) as error_rate_percent
FROM query_performance.distributed_queries
WHERE start_time > NOW() - INTERVAL '1 hour'
GROUP BY service_name, operation_name
ORDER BY avg_duration_ms DESC;


--- advanced resource governance and workload management 
-- Table for resource pools and workload management
CREATE TABLE IF NOT EXISTS query_performance.resource_pools (
    pool_id SERIAL PRIMARY KEY,
    pool_name TEXT UNIQUE NOT NULL,
    max_cpu_percent INTEGER DEFAULT 100,
    max_memory_percent INTEGER DEFAULT 100,
    max_concurrent_queries INTEGER,
    priority_level INTEGER DEFAULT 5, -- 1-10, 10 being highest
    allowed_users TEXT[], -- NULL means all users
    allowed_schemas TEXT[], -- NULL means all schemas
    query_timeouts INTERVAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for workload classification rules
CREATE TABLE IF NOT EXISTS query_performance.workload_classification_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name TEXT UNIQUE NOT NULL,
    rule_order INTEGER DEFAULT 1,
    condition_pattern TEXT, -- Regex pattern to match queries
    target_pool_id INTEGER REFERENCES query_performance.resource_pools(pool_id),
    assigned_priority INTEGER DEFAULT 5,
    enforcement_action TEXT DEFAULT 'ROUTE', -- ROUTE, REJECT, DELAY
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for active resource allocations
CREATE TABLE IF NOT EXISTS query_performance.active_resource_allocations (
    allocation_id SERIAL PRIMARY KEY,
    pool_id INTEGER REFERENCES query_performance.resource_pools(pool_id),
    query_hash TEXT,
    allocated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    resource_usage JSONB
);

-- Function to classify and route queries
CREATE OR REPLACE FUNCTION query_performance.classify_and_route_query(
    p_query_text TEXT,
    p_user_name TEXT,
    p_schema_name TEXT
)
RETURNS TABLE(
    pool_name TEXT,
    priority_level INTEGER,
    max_execution_time INTERVAL,
    enforcement_action TEXT
) AS $$
DECLARE
    rule_rec RECORD;
BEGIN
    -- Find matching classification rule
    FOR rule_rec IN
        SELECT wcr.*, rp.pool_name, rp.priority_level, rp.query_timeouts
        FROM query_performance.workload_classification_rules wcr
        JOIN query_performance.resource_pools rp ON wcr.target_pool_id = rp.pool_id
        WHERE wcr.enabled = TRUE
            AND (wcr.condition_pattern IS NULL OR p_query_text ~* wcr.condition_pattern)
            AND (rp.allowed_users IS NULL OR p_user_name = ANY(rp.allowed_users))
            AND (rp.allowed_schemas IS NULL OR p_schema_name = ANY(rp.allowed_schemas))
        ORDER BY wcr.rule_order
        LIMIT 1
    LOOP
        RETURN QUERY SELECT 
            rule_rec.pool_name,
            rule_rec.priority_level,
            rule_rec.query_timeouts,
            rule_rec.enforcement_action;
        RETURN;
    END LOOP;
    
    -- Default to system pool if no rules match
    RETURN QUERY SELECT 
        'DEFAULT'::TEXT,
        5::INTEGER,
        INTERVAL '30 minutes'::INTERVAL,
        'ROUTE'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Resource utilization monitoring
CREATE OR REPLACE VIEW query_performance.resource_utilization AS
SELECT 
    rp.pool_name,
    COUNT(ara.allocation_id) as active_queries,
    rp.max_concurrent_queries,
    ROUND(COUNT(ara.allocation_id) * 100.0 / rp.max_concurrent_queries, 2) as utilization_percent,
    AVG(rp.priority_level) as avg_priority,
    MAX(ara.allocated_at) as last_allocation
FROM query_performance.resource_pools rp
LEFT JOIN query_performance.active_resource_allocations ara 
    ON rp.pool_id = ara.pool_id 
    AND ara.expires_at > CURRENT_TIMESTAMP
GROUP BY rp.pool_name, rp.max_concurrent_queries
ORDER BY utilization_percent DESC;



-- security compliance monitoring 
-- Table for security audit logging
CREATE TABLE IF NOT EXISTS query_performance.security_audit_log (
    audit_id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL,
    client_ip INET,
    query_text TEXT,
    query_type TEXT,
    accessed_tables TEXT[],
    sensitive_data_accessed BOOLEAN DEFAULT FALSE,
    access_level TEXT, -- READ, WRITE, ADMIN
    compliance_check_result TEXT, -- PASSED, FAILED, REVIEW
    risk_score INTEGER, -- 1-10
    session_id TEXT,
    application_name TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    audit_notes TEXT
);

-- Table for data sensitivity classification
CREATE TABLE IF NOT EXISTS query_performance.data_sensitivity_classification (
    classification_id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    column_name TEXT,
    sensitivity_level TEXT NOT NULL, -- PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED
    data_category TEXT, -- PII, PCI, PHI, FINANCIAL, etc.
    retention_policy TEXT,
    access_controls TEXT[],
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(schema_name, table_name, column_name)
);

-- Function to perform security audit
CREATE OR REPLACE FUNCTION query_performance.perform_security_audit(
    p_user_name TEXT,
    p_query_text TEXT,
    p_client_ip INET DEFAULT NULL,
    p_session_id TEXT DEFAULT NULL,
    p_application_name TEXT DEFAULT NULL
)
RETURNS TABLE(
    compliance_status TEXT,
    risk_score INTEGER,
    sensitive_data_accessed BOOLEAN,
    audit_notes TEXT
) AS $$
DECLARE
    v_query_type TEXT;
    v_tables_accessed TEXT[];
    v_sensitive_access BOOLEAN := FALSE;
    v_risk_score INTEGER := 1;
    v_compliance_status TEXT := 'PASSED';
    v_audit_notes TEXT := '';
    v_table_rec RECORD;
BEGIN
    -- Determine query type
    v_query_type := query_performance.get_query_type(p_query_text);
    
    -- Extract tables accessed
    v_tables_accessed := query_performance.extract_table_names(p_query_text);
    
    -- Check for sensitive data access
    FOR v_table_rec IN
        SELECT DISTINCT schema_name, table_name
        FROM unnest(v_tables_accessed) as table_name
        CROSS JOIN (SELECT schemaname FROM pg_tables WHERE tablename = table_name LIMIT 1) as schema_name
        JOIN query_performance.data_sensitivity_classification dsc 
            ON dsc.schema_name = schema_name.schemaname 
            AND dsc.table_name = table_name
        WHERE dsc.sensitivity_level IN ('CONFIDENTIAL', 'RESTRICTED')
    LOOP
        v_sensitive_access := TRUE;
        v_risk_score := v_risk_score + 3;
        v_audit_notes := v_audit_notes || format('Access to sensitive table: %s.%s; ', 
                                               v_table_rec.schema_name, v_table_rec.table_name);
    END LOOP;
    
    -- Risk scoring based on query type
    CASE v_query_type
        WHEN 'DELETE' THEN v_risk_score := v_risk_score + 2;
        WHEN 'UPDATE' THEN v_risk_score := v_risk_score + 1;
        WHEN 'DROP' THEN v_risk_score := v_risk_score + 5;
        WHEN 'CREATE' THEN v_risk_score := v_risk_score + 1;
        ELSE v_risk_score := v_risk_score + 0;
    END CASE;
    
    -- Check for potentially dangerous patterns
    IF p_query_text ~* '\b(delete|drop|truncate)\s+.*\b(all|where\s+1=1)\b' THEN
        v_risk_score := v_risk_score + 5;
        v_compliance_status := 'FAILED';
        v_audit_notes := v_audit_notes || 'Potentially dangerous query pattern detected; ';
    END IF;
    
    -- Cap risk score
    v_risk_score := LEAST(v_risk_score, 10);
    
    -- Log the audit
    INSERT INTO query_performance.security_audit_log (
        user_name, client_ip, query_text, query_type, accessed_tables,
        sensitive_data_accessed, risk_score, compliance_check_result,
        session_id, application_name, audit_notes
    ) VALUES (
        p_user_name, p_client_ip, p_query_text, v_query_type, v_tables_accessed,
        v_sensitive_access, v_risk_score, v_compliance_status,
        p_session_id, p_application_name, v_audit_notes
    );
    
    RETURN QUERY SELECT v_compliance_status, v_risk_score, v_sensitive_access, v_audit_notes;
END;
$$ LANGUAGE plpgsql;

-- Security compliance dashboard 
CREATE OR REPLACE VIEW query_performance.security_compliance_dashboard AS
SELECT 
    audit_date,
    total_queries,
    sensitive_access_count,
    failed_compliance_count,
    avg_risk_score,
    string_agg(DISTINCT table_name, ', ') as accessed_tables
FROM (
    SELECT 
        DATE_TRUNC('day', executed_at) as audit_date,
        COUNT(*) as total_queries,
        COUNT(CASE WHEN sensitive_data_accessed THEN 1 END) as sensitive_access_count,
        COUNT(CASE WHEN compliance_check_result = 'FAILED' THEN 1 END) as failed_compliance_count,
        AVG(risk_score) as avg_risk_score,
        unnest(accessed_tables) as table_name
    FROM query_performance.security_audit_log
    WHERE executed_at > NOW() - INTERVAL '7 days'
    GROUP BY DATE_TRUNC('day', executed_at), accessed_tables
) sub
GROUP BY audit_date, total_queries, sensitive_access_count, failed_compliance_count, avg_risk_score
ORDER BY audit_date DESC;


-- Security compliance dashboard  with LATERAL join
CREATE OR REPLACE VIEW query_performance.security_compliance_dashboard AS
SELECT 
    DATE_TRUNC('day', sal.executed_at) as audit_date,
    COUNT(*) as total_queries,
    COUNT(CASE WHEN sal.sensitive_data_accessed THEN 1 END) as sensitive_access_count,
    COUNT(CASE WHEN sal.compliance_check_result = 'FAILED' THEN 1 END) as failed_compliance_count,
    AVG(sal.risk_score) as avg_risk_score,
    string_agg(DISTINCT at.table_name, ', ') as accessed_tables
FROM query_performance.security_audit_log sal
LEFT JOIN LATERAL unnest(sal.accessed_tables) as at(table_name) ON TRUE
WHERE sal.executed_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', sal.executed_at)
ORDER BY audit_date DESC;



-- Security compliance dashboard simplified
CREATE OR REPLACE VIEW query_performance.security_compliance_dashboard_simplified AS
SELECT 
    DATE_TRUNC('day', executed_at) as audit_date,
    COUNT(*) as total_queries,
    COUNT(CASE WHEN sensitive_data_accessed THEN 1 END) as sensitive_access_count,
    COUNT(CASE WHEN compliance_check_result = 'FAILED' THEN 1 END) as failed_compliance_count,
    AVG(risk_score) as avg_risk_score
FROM query_performance.security_audit_log
WHERE executed_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', executed_at)
ORDER BY audit_date DESC;



-- Accessed tables summary view
CREATE OR REPLACE VIEW query_performance.accessed_tables_summary AS
SELECT 
    DATE_TRUNC('day', sal.executed_at) as audit_date,
    at.table_name,
    COUNT(*) as access_count
FROM query_performance.security_audit_log sal,
     unnest(sal.accessed_tables) as at(table_name)
WHERE sal.executed_at > NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', sal.executed_at), at.table_name
ORDER BY audit_date DESC, access_count DESC;

-- advanced backup and recovery performance monitoring 

-- Table for backup/recovery performance tracking
CREATE TABLE IF NOT EXISTS query_performance.backup_recovery_metrics (
    metric_id SERIAL PRIMARY KEY,
    operation_type TEXT NOT NULL, -- BACKUP, RESTORE, ARCHIVE, WAL
    database_name TEXT,
    backup_set_id TEXT,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds DECIMAL(12,3),
    data_size_bytes BIGINT,
    compressed_size_bytes BIGINT,
    compression_ratio DECIMAL(8,2),
    throughput_mb_per_sec DECIMAL(12,2),
    status TEXT, -- SUCCESS, FAILED, IN_PROGRESS
    error_message TEXT,
    backup_type TEXT, -- FULL, INCREMENTAL, DIFFERENTIAL
    retention_days INTEGER,
    storage_location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for backup schedule and SLA tracking
CREATE TABLE IF NOT EXISTS query_performance.backup_sla_tracking (
    sla_id SERIAL PRIMARY KEY,
    database_name TEXT NOT NULL,
    backup_type TEXT NOT NULL,
    expected_frequency INTERVAL NOT NULL,
    rto_hours INTEGER, -- Recovery Time Objective
    rpo_hours INTEGER, -- Recovery Point Objective
    last_backup_time TIMESTAMP WITH TIME ZONE,
    next_backup_due TIMESTAMP WITH TIME ZONE,
    sla_status TEXT, -- MET, AT_RISK, VIOLATED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to log backup performance
CREATE OR REPLACE FUNCTION query_performance.log_backup_performance(
    p_operation_type TEXT,
    p_database_name TEXT,
    p_backup_set_id TEXT,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_data_size_bytes BIGINT,
    p_compressed_size_bytes BIGINT DEFAULT NULL,
    p_status TEXT DEFAULT 'SUCCESS',
    p_error_message TEXT DEFAULT NULL,
    p_backup_type TEXT DEFAULT 'FULL',
    p_storage_location TEXT DEFAULT 'LOCAL'
)
RETURNS VOID AS $$
DECLARE
    v_duration DECIMAL(12,3);
    v_throughput DECIMAL(12,2);
    v_compression_ratio DECIMAL(8,2);
BEGIN
    v_duration := EXTRACT(EPOCH FROM (p_end_time - p_start_time));
    v_throughput := CASE 
        WHEN v_duration > 0 THEN (p_data_size_bytes / 1024.0 / 1024.0) / (v_duration / 60.0)
        ELSE 0 
    END;
    v_compression_ratio := CASE 
        WHEN p_compressed_size_bytes > 0 THEN p_data_size_bytes::DECIMAL / p_compressed_size_bytes
        ELSE 1.0 
    END;
    
    INSERT INTO query_performance.backup_recovery_metrics (
        operation_type, database_name, backup_set_id, start_time, end_time,
        duration_seconds, data_size_bytes, compressed_size_bytes,
        compression_ratio, throughput_mb_per_sec, status, error_message,
        backup_type, storage_location
    ) VALUES (
        p_operation_type, p_database_name, p_backup_set_id, p_start_time, p_end_time,
        v_duration, p_data_size_bytes, p_compressed_size_bytes,
        v_compression_ratio, v_throughput, p_status, p_error_message,
        p_backup_type, p_storage_location
    );
    
    -- Update SLA tracking
    UPDATE query_performance.backup_sla_tracking
    SET 
        last_backup_time = p_end_time,
        next_backup_due = p_end_time + expected_frequency,
        sla_status = CASE 
            WHEN p_status = 'SUCCESS' THEN 'MET'
            ELSE 'VIOLATED'
        END
    WHERE database_name = p_database_name AND backup_type = p_backup_type;
END;
$$ LANGUAGE plpgsql;

-- Backup performance dashboard
CREATE OR REPLACE VIEW query_performance.backup_performance_dashboard AS
SELECT 
    database_name,
    backup_type,
    COUNT(*) as backup_count,
    AVG(duration_seconds) as avg_duration_seconds,
    AVG(throughput_mb_per_sec) as avg_throughput_mb_per_sec,
    AVG(compression_ratio) as avg_compression_ratio,
    MAX(data_size_bytes) as max_backup_size_bytes,
    COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_backups,
    ROUND(COUNT(CASE WHEN status = 'FAILED' THEN 1 END) * 100.0 / COUNT(*), 2) as failure_rate_percent
FROM query_performance.backup_recovery_metrics
WHERE start_time > NOW() - INTERVAL '30 days'
GROUP BY database_name, backup_type
ORDER BY avg_duration_seconds DESC;


-- Cost optimization 

-- Table for resource cost tracking
CREATE TABLE IF NOT EXISTS query_performance.resource_costs (
    cost_id SERIAL PRIMARY KEY,
    resource_type TEXT NOT NULL, -- COMPUTE, STORAGE, NETWORK
    cost_category TEXT NOT NULL, -- QUERY_EXECUTION, STORAGE, BACKUP, etc.
    cost_amount DECIMAL(12,4),
    currency_code TEXT DEFAULT 'USD',
    billing_period DATE,
    allocated_to TEXT, -- User, Department, Project, Application
    tags JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table for query cost attribution
CREATE TABLE IF NOT EXISTS query_performance.query_cost_attribution (
    attribution_id SERIAL PRIMARY KEY,
    query_hash TEXT NOT NULL,
    user_name TEXT,
    application_name TEXT,
    department TEXT,
    project_code TEXT,
    compute_cost DECIMAL(12,4),
    storage_cost DECIMAL(12,4),
    network_cost DECIMAL(12,4),
    total_cost DECIMAL(12,4),
    execution_time_ms DECIMAL(12,3),
    rows_processed BIGINT,
    cost_per_row DECIMAL(12,6),
    cost_per_second DECIMAL(12,6),
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to calculate query costs
CREATE OR REPLACE FUNCTION query_performance.calculate_query_costs(
    p_query_hash TEXT,
    p_execution_time_ms DECIMAL(12,3),
    p_rows_processed BIGINT,
    p_user_name TEXT DEFAULT NULL,
    p_application_name TEXT DEFAULT NULL
)
RETURNS TABLE(
    compute_cost DECIMAL(12,4),
    storage_cost DECIMAL(12,4),
    network_cost DECIMAL(12,4),
    total_cost DECIMAL(12,4)
) AS $$
DECLARE
    v_compute_rate DECIMAL(12,6) := 0.0001; -- $0.0001 per millisecond
    v_storage_rate DECIMAL(12,6) := 0.0000001; -- $0.0000001 per row processed
    v_network_rate DECIMAL(12,6) := 0.000001; -- $0.000001 per row for network
    v_compute_cost DECIMAL(12,4);
    v_storage_cost DECIMAL(12,4);
    v_network_cost DECIMAL(12,4);
    v_total_cost DECIMAL(12,4);
BEGIN
    -- Calculate costs
    v_compute_cost := p_execution_time_ms * v_compute_rate;
    v_storage_cost := p_rows_processed * v_storage_rate;
    v_network_cost := p_rows_processed * v_network_rate;
    v_total_cost := v_compute_cost + v_storage_cost + v_network_cost;
    
    -- Store cost attribution
    INSERT INTO query_performance.query_cost_attribution (
        query_hash, user_name, application_name, compute_cost,
        storage_cost, network_cost, total_cost, execution_time_ms, rows_processed,
        cost_per_row, cost_per_second
    ) VALUES (
        p_query_hash, p_user_name, p_application_name, v_compute_cost,
        v_storage_cost, v_network_cost, v_total_cost, p_execution_time_ms, p_rows_processed,
        CASE WHEN p_rows_processed > 0 THEN v_total_cost / p_rows_processed ELSE 0 END,
        CASE WHEN p_execution_time_ms > 0 THEN v_total_cost / (p_execution_time_ms / 1000) ELSE 0 END
    );
    
    RETURN QUERY SELECT v_compute_cost, v_storage_cost, v_network_cost, v_total_cost;
END;
$$ LANGUAGE plpgsql;

-- Cost optimization recommendations
CREATE OR REPLACE VIEW query_performance.cost_optimization_recommendations AS
SELECT 
    user_name,
    application_name,
    COUNT(*) as query_count,
    SUM(total_cost) as total_cost,
    AVG(total_cost) as avg_cost_per_query,
    SUM(execution_time_ms) as total_execution_time_ms,
    SUM(rows_processed) as total_rows_processed,
    CASE 
        WHEN AVG(cost_per_row) > (SELECT AVG(cost_per_row) * 2 FROM query_performance.query_cost_attribution) 
        THEN 'HIGH_COST_PER_ROW'
        WHEN AVG(execution_time_ms) > (SELECT AVG(execution_time_ms) * 2 FROM query_performance.query_cost_attribution)
        THEN 'LONG_RUNNING_QUERIES'
        ELSE 'OPTIMAL'
    END as optimization_opportunity
FROM query_performance.query_cost_attribution
WHERE executed_at > NOW() - INTERVAL '30 days'
GROUP BY user_name, application_name
HAVING SUM(total_cost) > 10.00 -- Focus on significant costs
ORDER BY total_cost DESC;
