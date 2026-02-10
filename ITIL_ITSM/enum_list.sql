-- =============================================
-- PostgreSQL Schema for Human Resource Management System
-- Version: 2.0
-- Copyright 2025 All rights reserved β ORI Inc.
-- Created: 2025-05-29
-- Last Updated: 2025-06-15
--Author: Awase Khirni Syed
--=======================================

-- Enum: DATA_SUBJECT_REQUEST_TYPE
-- Description: Defines the types of data subject requests under privacy regulations
-- Business Case: Supports GDPR, CCPA, and other privacy compliance requirements by standardizing request categories
-- Feature Reference: 1.082
CREATE TYPE sec_audit.data_subject_request_type AS ENUM (
    'ACCESS',                        -- Right to access personal data
    'DELETE',                        -- Right to deletion/erasure
    'PORTABILITY',                   -- Right to data portability
    'OPT_OUT'                        -- Opt-out of processing
);
COMMENT ON TYPE sec_audit.data_subject_request_type IS 'Types of data subject requests under privacy regulations';

-- Enum: DATA_SUBJECT_REQUEST_STATUS
-- Description: Defines the lifecycle states of data subject requests
-- Business Case: Tracks completion status of privacy compliance requests through their processing lifecycle
-- Feature Reference: 1.082
CREATE TYPE sec_audit.data_subject_request_status AS ENUM (
    'RECEIVED',                      -- Request received
    'PROCESSING',                    -- Currently being processed
    'COMPLETED',                     -- Successfully completed
    'EXTENDED'                       -- Deadline extended
);
COMMENT ON TYPE sec_audit.data_subject_request_status IS 'Status of data subject requests throughout processing lifecycle';

-- Enum: PRIVILEGED_ACTION_TYPE
-- Description: Defines types of privileged actions requiring monitoring
-- Business Case: Enables comprehensive audit trail for security-sensitive operations to meet compliance requirements
-- Feature Reference: 1.081
CREATE TYPE sec_audit.privileged_action_type AS ENUM (
    'DELETE_USER',                   -- User deletion operation
    'DROP_TABLE',                    -- Table deletion operation
    'EXPORT_DATA',                   -- Data export operation
    'GRANT_PRIVILEGE',               -- Privilege granting operation
    'MODIFY_SCHEMA',                 -- Schema modification operation
    'RESET_PASSWORD',                -- Password reset operation
    'CONFIG_CHANGE',                 -- Configuration change operation
    'AUDIT_LOG_ACCESS',              -- Access to audit logs
    'SECURITY_POLICY_UPDATE',        -- Security policy update
    'USER_ROLE_ASSIGNMENT'           -- User role assignment
);
COMMENT ON TYPE sec_audit.privileged_action_type IS 'Types of privileged actions requiring enhanced monitoring';

-- Enum: ADVERSARIAL_ATTACK_TYPE
-- Description: Defines types of adversarial attacks on AI models
-- Business Case: Supports AI security and robustness monitoring by categorizing potential attack vectors
-- Feature Reference: 1.129
CREATE TYPE sec_audit.adversarial_attack_type AS ENUM (
    'DATA_POISONING',                -- Poisoning training data
    'EVASION',                       -- Evading model detection
    'MODEL_EXTRACTION',              -- Extracting model parameters
    'ADVERSARIAL_PATCH',             -- Physical adversarial patches
    'JAILBREAKING',                  -- Circumventing safety measures
    'PROMPT_INJECTION',              -- Malicious input injection
    'BACKDOOR_ATTACK',               -- Introducing hidden backdoors
    'POISONING_DURING_TRAINING'      -- Attacking during training phase
);
COMMENT ON TYPE sec_audit.adversarial_attack_type IS 'Types of adversarial attacks targeting AI models and systems';

-- Enum: TEST_SUITE_TYPE
-- Description: Defines types of automated test suites
-- Business Case: Organizes testing strategy for continuous integration and deployment pipelines
-- Feature Reference: 8.223
CREATE TYPE ai_core.test_suite_type AS ENUM (
    'UNIT',                          -- Unit tests for individual components
    'INTEGRATION',                   -- Integration tests for component interaction
    'E2E',                           -- End-to-end tests for complete workflows
    'PERFORMANCE',                   -- Performance and load tests
    'SECURITY',                      -- Security vulnerability tests
    'COMPATIBILITY',                 -- Compatibility tests across environments
    'REGRESSION',                    -- Regression tests for bug prevention
    'SMOKE'                          -- Basic functionality smoke tests
);
COMMENT ON TYPE ai_core.test_suite_type IS 'Types of automated test suites for continuous integration';

-- Enum: TRAINING_SESSION_TYPE
-- Description: Defines types of knowledge sharing sessions
-- Business Case: Facilitates organizational learning and expertise transfer through structured training
-- Feature Reference: 1.026
CREATE TYPE ai_core.training_session_type AS ENUM (
    'CODE_REVIEW',                   -- Peer code review sessions
    'BROWN_BAG',                     -- Informal lunch-and-learn sessions
    'HANDS_ON',                      -- Interactive practical sessions
    'MENTORING',                     -- One-on-one mentoring sessions
    'WORKSHOP',                      -- Structured learning workshops
    'SEMINAR',                       -- Formal presentation-based sessions
    'BOOTCAMP',                      -- Intensive training programs
    'PEER_LEARNING'                  -- Collaborative learning sessions
);
COMMENT ON TYPE ai_core.training_session_type IS 'Types of knowledge sharing and training sessions';

-- Enum: SWARM_RANK_LEVEL
-- Description: Defines reputation levels in expert swarming
-- Business Case: Gamifies expert participation and recognizes contributions to collaborative problem-solving
-- Feature Reference: 1.033
CREATE TYPE ai_core.swarm_rank_level AS ENUM (
    'NOVICE',                        -- Beginner level contributor
    'EXPERT',                        -- Intermediate level expert
    'MASTER',                        -- Advanced level master
    'GURU',                          -- Highest level guru
    'LEGEND'                         -- Legendary status
);
COMMENT ON TYPE ai_core.swarm_rank_level IS 'Rank levels in the swarm reputation system';

-- Enum: SIMULATION_CATEGORY
-- Description: Defines categories of simulation scenarios
-- Business Case: Categorizes failure scenarios for targeted testing and resilience building
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_category AS ENUM (
    'SECURITY',                      -- Security-related failure scenarios
    'OPERATIONAL',                   -- Operational failure scenarios
    'DISASTER',                      -- Disaster recovery scenarios
    'PERFORMANCE',                   -- Performance degradation scenarios
    'SCALABILITY',                   -- Scalability testing scenarios
    'NETWORK',                       -- Network failure scenarios
    'DATABASE',                      -- Database failure scenarios
    'APPLICATION'                    -- Application-level failure scenarios
);
COMMENT ON TYPE ai_core.simulation_category IS 'Categories for simulation scenarios';

-- Enum: SENTIMENT_SCOPE
-- Description: Defines scope of sentiment monitoring
-- Business Case: Targets sentiment analysis to specific organizational areas for focused insights
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_scope AS ENUM (
    'GLOBAL',                        -- Organization-wide monitoring
    'DEPARTMENT',                    -- Department-specific monitoring
    'SERVICE',                       -- Service-specific monitoring
    'TEAM',                          -- Team-specific monitoring
    'PROJECT',                       -- Project-specific monitoring
    'CUSTOMER',                      -- Customer-specific monitoring
    'VENDOR',                        -- Vendor-specific monitoring
    'REGION'                         -- Geographic region monitoring
);
COMMENT ON TYPE ai_core.sentiment_scope IS 'Scope of sentiment monitoring and alerts';

-- Enum: LIFECYCLE_STAGE
-- Description: Defines asset lifecycle stages in configuration management
-- Business Case: Tracks assets through their entire lifecycle from provisioning to disposal
-- Feature Reference: 1.063
CREATE TYPE config_mgmt.lifecycle_stage AS ENUM (
    'PROVISIONED',                   -- Asset provisioned but not deployed
    'DEPLOYED',                      -- Asset in active use
    'UPGRADED',                      -- Asset upgraded/replaced
    'RETIRED',                       -- Asset retired from service
    'DISPOSED',                      -- Asset properly disposed
    'MAINTENANCE',                   -- Asset in maintenance mode
    'STAGING',                       -- Asset in staging environment
    'TESTING'                        -- Asset in testing environment
);
COMMENT ON TYPE config_mgmt.lifecycle_stage IS 'Stages in the asset lifecycle management process';

-- Enum: DEPRECIATION_METHOD
-- Description: Defines methods for calculating asset depreciation
-- Business Case: Supports financial accounting and asset valuation for compliance and reporting
-- Feature Reference: 1.014
CREATE TYPE config_mgmt.depreciation_method AS ENUM (
    'STRAIGHT_LINE',                 -- Equal depreciation each period
    'DOUBLE_DECLINING',              -- Accelerated depreciation method
    'SUM_OF_YEARS_DIGITS',           -- Accelerated method based on remaining life
    'UNITS_OF_PRODUCTION',           -- Depreciation based on usage
    'MACRS',                         -- Modified Accelerated Cost Recovery System
    'WARRANTY_BASED'                 -- Depreciation tied to warranty periods
);
COMMENT ON TYPE config_mgmt.depreciation_method IS 'Methods for calculating asset depreciation';

-- Enum: RESOURCE_TYPE
-- Description: Defines types of system resources monitored
-- Business Case: Categorizes resource monitoring for capacity planning and performance optimization
-- Feature Reference: 1.055
CREATE TYPE ai_core.resource_type AS ENUM (
    'CPU',                           -- Central Processing Unit
    'MEMORY',                        -- Random Access Memory
    'DISK_IO',                       -- Disk Input/Output operations
    'NETWORK',                       -- Network bandwidth utilization
    'STORAGE',                       -- Storage space utilization
    'GPU',                           -- Graphics Processing Unit
    'CACHE',                         -- Cache memory utilization
    'DATABASE_CONNECTIONS'           -- Database connection pool usage
);
COMMENT ON TYPE ai_core.resource_type IS 'Types of system resources being monitored';

-- Enum: GENERATION_METHOD
-- Description: Defines methods for generating synthetic training data
-- Business Case: Supports AI model training with diverse datasets while maintaining privacy
-- Feature Reference: 1.112
CREATE TYPE ai_core.generation_method AS ENUM (
    'GAN',                           -- Generative Adversarial Network
    'VAE',                           -- Variational Autoencoder
    'SMOTE',                         -- Synthetic Minority Oversampling Technique
    'DIFFUSION',                     -- Diffusion model
    'FLOW_BASED',                    -- Normalizing flow based
    'RULE_BASED',                    -- Rule-based generation
    'STATISTICAL_SAMPLING',          -- Statistical sampling techniques
    'HYBRID_METHOD'                  -- Combination of multiple approaches
);
COMMENT ON TYPE ai_core.generation_method IS 'Methods for generating synthetic training data';

-- Enum: SWARM_ROLE
-- Description: Defines roles within expert swarming activities
-- Business Case: Organizes collaborative problem-solving efforts with clear role assignments
-- Feature Reference: 1.033
CREATE TYPE ai_core.swarm_role AS ENUM (
    'INITIATOR',                     -- Person who initiated the swarm
    'CONTRIBUTER',                   -- Active participant in swarm
    'OBSERVER',                      -- Passive observer of swarm
    'COORDINATOR',                   -- Swarm activity coordinator
    'MENTOR',                        -- Knowledge mentor in swarm
    'EXPERT',                        -- Subject matter expert
    'ANALYST',                       -- Data analyst in swarm
    'DECISION_MAKER'                 -- Final decision authority
);
COMMENT ON TYPE ai_core.swarm_role IS 'Roles within expert swarming activities';

-- Enum: PREDICTION_TYPE
-- Description: Defines types of predictions made by ML models
-- Business Case: Categorizes different prediction outputs for analytics and decision-making
-- Feature Reference: 1.013
CREATE TYPE ai_core.prediction_type AS ENUM (
    'CATEGORY',                      -- Classification into categories
    'PRIORITY',                      -- Priority level prediction
    'ROUTING',                       -- Routing destination prediction
    'TIME_ESTIMATE',                 -- Time duration prediction
    'PROBABILITY',                   -- Probability estimation
    'SCORE',                         -- Numerical score prediction
    'CLASSIFICATION',                -- Multi-class classification
    'CLUSTER'                        -- Clustering assignment
);
COMMENT ON TYPE ai_core.prediction_type IS 'Types of predictions generated by machine learning models';

-- Enum: CORRELATION_SCOPE
-- Description: Defines scope of correlation analysis
-- Business Case: Categorizes correlation relationships for analysis and action planning
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_scope AS ENUM (
    'SYSTEM_WIDE',                   -- Correlations across entire system
    'SERVICE_BOUNDARY',              -- Correlations within service boundaries
    'DEPARTMENTAL',                  -- Department-specific correlations
    'TEAM_BASED',                    -- Team-specific correlations
    'TEMPORAL',                      -- Time-based correlations
    'GEOSPATIAL',                    -- Location-based correlations
    'BUSINESS_CRITICAL',             -- Business-critical correlations
    'SECURITY_RELATED'               -- Security-related correlations
);
COMMENT ON TYPE ai_core.correlation_scope IS 'Scope of correlation analysis for metric relationships';

-- Enum: MODEL_EVALUATION_METRIC
-- Description: Defines metrics used for evaluating ML models
-- Business Case: Standardizes model performance measurement for comparison and selection
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_evaluation_metric AS ENUM (
    'ACCURACY',                      -- Overall prediction accuracy
    'PRECISION',                     -- Precision of positive predictions
    'RECALL',                        -- Recall/sensitivity
    'F1_SCORE',                      -- Harmonic mean of precision and recall
    'AUC_ROC',                       -- Area Under ROC Curve
    'RMSE',                          -- Root Mean Square Error
    'MAE',                           -- Mean Absolute Error
    'MAPE'                           -- Mean Absolute Percentage Error
);
COMMENT ON TYPE ai_core.model_evaluation_metric IS 'Metrics for evaluating machine learning model performance';

-- Enum: ANOMALY_SEVERITY
-- Description: Defines severity levels for anomaly detection events
-- Business Case: Prioritizes anomaly responses based on business impact and urgency
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_severity AS ENUM (
    'INFO',                          -- Informational only
    'WARNING',                       -- Warning level anomaly
    'ERROR',                         -- Error level anomaly
    'CRITICAL'                       -- Critical anomaly requiring immediate action
);
COMMENT ON TYPE ai_core.anomaly_severity IS 'Severity levels for detected anomalies';

-- Enum: HEALING_SCRIPT_STATUS
-- Description: Defines execution status of auto-healing scripts
-- Business Case: Tracks automated remediation effectiveness and execution progress
-- Feature Reference: 8.008
CREATE TYPE ai_core.healing_script_status AS ENUM (
    'READY',                         -- Script ready for execution
    'EXECUTING',                     -- Currently executing
    'SUCCESS',                       -- Execution completed successfully
    'FAILED',                        -- Execution failed
    'SKIPPED',                       -- Execution skipped
    'TIMEOUT',                       -- Execution timed out
    'CANCELLED',                     -- Execution cancelled
    'PENDING_APPROVAL'               -- Awaiting approval for execution
);
COMMENT ON TYPE ai_core.healing_script_status IS 'Execution status of auto-healing scripts';

-- Enum: FEEDBACK_TYPE
-- Description: Defines types of user feedback collected
-- Business Case: Categorizes feedback for targeted improvements and response strategies
-- Feature Reference: 8.007
CREATE TYPE it_incident.feedback_type AS ENUM (
    'SATISFACTION',                  -- Satisfaction rating
    'COMPLIMENT',                    -- Positive feedback
    'COMPLAINT',                     -- Negative feedback
    'SUGGESTION',                    -- Improvement suggestion
    'BUG_REPORT',                    -- Bug report
    'FEATURE_REQUEST',               -- New feature request
    'PRAISE',                        -- Recognition of good service
    'NEUTRAL'                        -- Neutral observation
);
COMMENT ON TYPE it_incident.feedback_type IS 'Types of user feedback collected for service improvement';

-- Enum: BLOCKCHAIN_TRANSACTION_TYPE
-- Description: Defines types of blockchain transactions for provenance
-- Business Case: Tracks different types of immutable audit records for compliance and security
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_type AS ENUM (
    'AUDIT_LOG',                     -- Audit log entry
    'ACCESS_RECORD',                 -- Access control record
    'CONFIG_CHANGE',                 -- Configuration change record
    'USER_ACTION',                   -- User action record
    'SECURITY_EVENT',                -- Security event record
    'COMPLIANCE_CHECK',              -- Compliance verification
    'DATA_MODIFICATION',             -- Data modification record
    'SYSTEM_STATE'                   -- System state snapshot
);
COMMENT ON TYPE sec_audit.blockchain_transaction_type IS 'Types of blockchain transactions for immutable audit trails';

-- Enum: PROVENANCE_VERIFICATION_STATUS
-- Description: Defines verification status of blockchain entries
-- Business Case: Tracks integrity and validation of audit records in blockchain network
-- Feature Reference: 8.005
CREATE TYPE sec_audit.provenance_verification_status AS ENUM (
    'PENDING',                       -- Verification pending
    'VERIFIED',                      -- Successfully verified
    'INVALID',                       -- Entry found to be invalid
    'CONFIRMED',                     -- Confirmed by consensus
    'DISPUTED',                      -- Disputed by network participants
    'EXPIRED',                       -- Verification window expired
    'REJECTED',                      -- Verification rejected
    'ARCHIVED'                       -- Archived after verification
);
COMMENT ON TYPE sec_audit.provenance_verification_status IS 'Verification status of blockchain provenance entries';

-- Enum: METERING_UNIT
-- Description: Defines units for metering data collection
-- Business Case: Standardizes unit measurements for analytics and reporting consistency
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_unit AS ENUM (
    'COUNT',                         -- Simple count
    'PERCENTAGE',                    -- Percentage value
    'BYTES',                         -- Data size in bytes
    'SECONDS',                       -- Time in seconds
    'MILLISECONDS',                  -- Time in milliseconds
    'KILOBYTES',                     -- Data size in kilobytes
    'MEGABYTES',                     -- Data size in megabytes
    'GIGABYTES',                     -- Data size in gigabytes
    'CORES',                         -- Number of CPU cores
    'GB',                            -- Gigabytes
    'MB',                            -- Megabytes
    'KB'                             -- Kilobytes
);
COMMENT ON TYPE it_incident.metering_unit IS 'Units for metering data collection and analysis';

-- Enum: METERING_SOURCE_TYPE
-- Description: Defines types of sources for metering data
-- Business Case: Categorizes data sources for proper attribution and monitoring strategy
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_source_type AS ENUM (
    'SERVER',                        -- Server-level metrics
    'DATABASE',                      -- Database metrics
    'APPLICATION',                   -- Application metrics
    'NETWORK',                       -- Network metrics
    'STORAGE',                       -- Storage metrics
    'VIRTUAL_MACHINE',               -- Virtual machine metrics
    'CONTAINER',                     -- Container metrics
    'MICROSERVICE',                  -- Microservice metrics
    'API_GATEWAY',                   -- API gateway metrics
    'LOAD_BALANCER',                 -- Load balancer metrics
    'MONITORING_AGENT',              -- Monitoring agent metrics
    'SENSOR'                         -- Hardware sensor metrics
);
COMMENT ON TYPE it_incident.metering_source_type IS 'Types of sources providing metering data';

-- Enum: AUDIT_LOG_ACTION_TYPE
-- Description: Defines types of actions logged in audit logs
-- Business Case: Categorizes audit events for security and compliance monitoring
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_action_type AS ENUM (
    'CREATE',                        -- Record creation
    'READ',                          -- Record access
    'UPDATE',                        -- Record modification
    'DELETE',                        -- Record deletion
    'LOGIN',                         -- User login attempt
    'LOGOUT',                        -- User logout
    'FAILED_LOGIN',                  -- Failed login attempt
    'PASSWORD_RESET',                -- Password reset request
    'PERMISSION_GRANTED',            -- Permission granted
    'PERMISSION_REVOKED',            -- Permission revoked
    'CONFIG_MODIFIED',               -- Configuration change
    'DATA_EXPORT',                   -- Data export operation
    'DATA_IMPORT',                   -- Data import operation
    'FILE_UPLOAD',                   -- File upload operation
    'FILE_DOWNLOAD',                 -- File download operation
    'SYSTEM_MAINTENANCE'             -- System maintenance operation
);
COMMENT ON TYPE it_incident.audit_log_action_type IS 'Types of actions recorded in audit logs';

-- Enum: CHATBOT_INTENT
-- Description: Defines recognized intents in chatbot conversations
-- Business Case: Enables intelligent conversation routing and resolution through intent recognition
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_intent AS ENUM (
    'INCIDENT_REPORT',               -- Reporting a new incident
    'STATUS_CHECK',                  -- Checking incident status
    'SOLUTION_REQUEST',              -- Requesting solution help
    'ACCOUNT_QUERY',                 -- Account-related query
    'BILLING_QUESTION',              -- Billing-related question
    'TECHNICAL_SUPPORT',             -- Technical support request
    'FEEDBACK_SUBMISSION',           -- Feedback submission
    'KNOWLEDGE_SEARCH',              -- Knowledge base search
    'PASSWORD_RESET',                -- Password reset request
    'ACCOUNT_LOCKOUT',               -- Account lockout issue
    'SOFTWARE_INSTALL',              -- Software installation request
    'HARDWARE_ISSUE',                -- Hardware-related issue
    'NETWORK_PROBLEM',               -- Network connectivity problem
    'SECURITY_CONCERN',              -- Security-related concern
    'TRAINING_REQUEST',              -- Training request
    'POLICY_QUESTION'                -- Policy-related question
);
COMMENT ON TYPE ai_core.chatbot_intent IS 'Intents recognized in chatbot conversations';

-- Enum: AR_CONTENT_TYPE
-- Description: Defines types of augmented reality content
-- Business Case: Categorizes AR content for appropriate rendering and contextual delivery
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_content_type AS ENUM (
    'INSTRUCTION',                   -- Step-by-step instructions
    'WARNING',                       -- Safety warnings
    'DIAGNOSTIC',                    -- Diagnostic information
    'REPAIR_GUIDE',                  -- Repair procedure guide
    'ASSEMBLY_GUIDE',                -- Assembly instruction guide
    'MAINTENANCE',                   -- Maintenance procedure
    'INSPECTION',                    -- Inspection checklist
    'SAFETY_PROCEDURE'               -- Safety procedure guide
);
COMMENT ON TYPE ai_core.ar_content_type IS 'Types of augmented reality content';

-- Enum: FEATURE_SCOPE
-- Description: Defines scope of machine learning features
-- Business Case: Categorizes features by their applicability domain for targeted development
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_scope AS ENUM (
    'USER',                          -- User-specific features
    'INCIDENT',                      -- Incident-specific features
    'SERVER',                        -- Server-specific features
    'SERVICE',                       -- Service-specific features
    'TEAM',                          -- Team-specific features
    'DEPARTMENT',                    -- Department-specific features
    'ORGANIZATION',                  -- Organization-wide features
    'CUSTOMER'                       -- Customer-specific features
);
COMMENT ON TYPE ai_core.feature_scope IS 'Scope of machine learning features';

-- Enum: MODEL_TRAINING_STATUS
-- Description: Defines status of ML model training process
-- Business Case: Tracks model development lifecycle from initiation to deployment
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_status AS ENUM (
    'QUEUED',                        -- Model training queued
    'TRAINING',                      -- Currently training
    'VALIDATING',                    -- Validation in progress
    'COMPLETED',                     -- Training completed successfully
    'FAILED',                        -- Training failed
    'CANCELLED',                     -- Training cancelled
    'PAUSED',                        -- Training temporarily paused
    'DEPLOYED'                       -- Model deployed to production
);
COMMENT ON TYPE ai_core.model_training_status IS 'Status of machine learning model training process';

-- Enum: AUTOMATION_SCORE_COMPONENT
-- Description: Defines components contributing to automation score
-- Business Case: Measures different aspects of automation maturity for continuous improvement
-- Feature Reference: 1.025
CREATE TYPE ai_core.automation_score_component AS ENUM (
    'API_COVERAGE',                  -- API endpoint coverage
    'TEST_COVERAGE',                 -- Test coverage percentage
    'DOCUMENTATION_SCORE',           -- Documentation completeness
    'MONITORING_COVERAGE',           -- Monitoring coverage
    'BACKUP_STRATEGY',               -- Backup automation coverage
    'DEPLOYMENT_AUTOMATION',         -- Deployment process automation
    'CONFIGURATION_MANAGEMENT',      -- Configuration management automation
    'SECURITY_AUTOMATION'            -- Security process automation
);
COMMENT ON TYPE ai_core.automation_score_component IS 'Components contributing to automation maturity score';

-- Enum: SKILL_PROFICIENCY_LEVEL
-- Description: Defines proficiency levels for skills
-- Business Case: Standardizes skill assessment across the organization for workforce planning
-- Feature Reference: 1.055
CREATE TYPE ai_core.skill_proficiency_level AS ENUM (
    'BEGINNER',                      -- Basic understanding
    'INTERMEDIATE',                  -- Working proficiency
    'ADVANCED',                      -- Strong proficiency
    'EXPERT',                        -- Expert level
    'MASTER',                        -- Master level
    'NOVICE',                        -- Very basic level
    'PROFICIENT',                    -- Proficient level
    'SPECIALIST'                     -- Specialist level
);
COMMENT ON TYPE ai_core.skill_proficiency_level IS 'Proficiency levels for skills assessment';

-- Enum: SYNTHETIC_DATA_USAGE_CONTEXT
-- Description: Defines contexts for synthetic data usage
-- Business Case: Tracks appropriate use cases for synthetic data to maximize value and compliance
-- Feature Reference: 1.112
CREATE TYPE ai_core.synthetic_data_usage_context AS ENUM (
    'TRAINING',                      -- Training model development
    'TESTING',                       -- Testing and validation
    'PRIVACY_PROTECTION',            -- Privacy-preserving analytics
    'BALANCING',                     -- Dataset balancing
    'ANONYMIZATION',                 -- Data anonymization
    'GENERATION',                    -- Data generation research
    'ANALYSIS',                      -- Statistical analysis
    'SIMULATION'                     -- Simulation scenarios
);
COMMENT ON TYPE ai_core.synthetic_data_usage_context IS 'Contexts for synthetic data usage';

-- Enum: REPUTATION_CONTRIBUTION_TYPE
-- Description: Defines types of contributions to reputation scoring
-- Business Case: Recognizes different forms of expert participation in collaborative systems
-- Feature Reference: 1.033
CREATE TYPE ai_core.reputation_contribution_type AS ENUM (
    'ANSWER_PROVIDED',               -- Answer provided to query
    'SOLUTION_SHARED',               -- Solution shared with community
    'KNOWLEDGE_TRANSFER',            -- Knowledge transfer activity
    'MENTORING',                     -- Mentoring activity
    'PROBLEM_SOLVED',                -- Problem successfully solved
    'INNOVATION_SUGGESTED',          -- Innovation suggested
    'BEST_PRACTICE_SHARED',          -- Best practice shared
    'TRAINING_DELIVERED'             -- Training delivered
);
COMMENT ON TYPE ai_core.reputation_contribution_type IS 'Types of contributions to reputation scoring';

-- Enum: SENTIMENT_THRESHOLD_ALERT
-- Description: Defines alert types based on sentiment thresholds
-- Business Case: Triggers proactive interventions based on sentiment degradation trends
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_threshold_alert AS ENUM (
    'NEGATIVE_SPIKE',                -- Sudden increase in negative sentiment
    'POSITIVE_DECLINE',              -- Decline in positive sentiment
    'OVERALL_NEGATIVE',              -- Overall negative sentiment threshold
    'ENGAGEMENT_DROP',               -- Engagement level drop
    'RESPONSE_TIME_ISSUE',           -- Response time related sentiment
    'QUALITY_CONCERN',               -- Quality-related sentiment concern
    'COMMUNICATION_ISSUE',           -- Communication-related sentiment
    'SATISFACTION_FALL'              -- Satisfaction level fall
);
COMMENT ON TYPE ai_core.sentiment_threshold_alert IS 'Alert types based on sentiment threshold breaches';

-- Enum: CMDB_SYNC_STATUS
-- Description: Defines status of CMDB synchronization processes
-- Business Case: Tracks configuration management database synchronization for data consistency
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_status AS ENUM (
    'RUNNING',                       -- Synchronization in progress
    'SUCCESS',                       -- Synchronization completed successfully
    'FAILED',                        -- Synchronization failed
    'PARTIAL',                       -- Partial synchronization completed
    'QUEUED',                        -- Synchronization queued
    'CANCELLED',                     -- Synchronization cancelled
    'PAUSED',                        -- Synchronization paused
    'TIMED_OUT'                      -- Synchronization timed out
);
COMMENT ON TYPE config_mgmt.cmdb_sync_status IS 'Status of CMDB synchronization processes';

-- Enum: CONFIGURATION_ITEM_TYPE
-- Description: Defines types of configuration items in CMDB
-- Business Case: Categorizes managed configuration items for targeted management strategies
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_type AS ENUM (
    'SERVER',                        -- Physical or virtual server
    'DATABASE',                      -- Database instance
    'APPLICATION',                   -- Application instance
    'NETWORK_DEVICE',                -- Router, switch, firewall
    'STORAGE',                       -- Storage device
    'VIRTUAL_MACHINE',               -- Virtual machine instance
    'CONTAINER',                     -- Container instance
    'MICROSERVICE',                  -- Microservice component
    'API_GATEWAY',                   -- API gateway component
    'LOAD_BALANCER',                 -- Load balancer component
    'MONITORING_TOOL',               -- Monitoring tool instance
    'BACKUP_SYSTEM'                  -- Backup system component
);
COMMENT ON TYPE config_mgmt.configuration_item_type IS 'Types of configuration items in CMDB';

-- Enum: SCENARIO_SIMULATION_STATUS
-- Description: Defines status of simulation scenario execution
-- Business Case: Tracks execution of failure simulation scenarios for resilience testing
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_status AS ENUM (
    'DRAFT',                         -- Scenario in draft form
    'CONFIGURED',                    -- Scenario configured for execution
    'EXECUTING',                     -- Currently executing simulation
    'COMPLETED',                     -- Simulation completed successfully
    'FAILED',                        -- Simulation failed to execute
    'CANCELLED',                     -- Simulation cancelled
    'PAUSED',                        -- Simulation temporarily paused
    'ANALYZING_RESULTS'              -- Analyzing simulation results
);
COMMENT ON TYPE ai_core.scenario_simulation_status IS 'Status of simulation scenario execution';

-- Enum: SATISFACTION_INDEX_SCOPE
-- Description: Defines scope of satisfaction index measurement
-- Business Case: Measures satisfaction at different organizational levels for targeted improvement
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_scope AS ENUM (
    'GLOBAL',                        -- Organization-wide index
    'DEPARTMENT',                    -- Department-specific index
    'TEAM',                          -- Team-specific index
    'SERVICE',                       -- Service-specific index
    'CUSTOMER',                      -- Customer-specific index
    'REGION',                        -- Geographic region index
    'PRODUCT',                       -- Product-specific index
    'PROJECT'                        -- Project-specific index
);
COMMENT ON TYPE ai_core.satisfaction_index_scope IS 'Scope of satisfaction index measurement';

-- Enum: CORRELATION_RESULT_STATUS
-- Description: Defines status of correlation analysis results
-- Business Case: Tracks validity and reliability of correlation findings for decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_result_status AS ENUM (
    'VALID',                         -- Correlation result is valid
    'SUSPICIOUS',                    -- Correlation result appears suspicious
    'INSIGNIFICANT',                 -- Correlation is statistically insignificant
    'CONFIRMED',                     -- Correlation validated by domain experts
    'DISCARDED',                     -- Correlation result discarded
    'REQUIRES_REVIEW',               -- Correlation requires expert review
    'PRELIMINARY',                   -- Preliminary correlation finding
    'ARCHIVED'                       -- Correlation result archived
);
COMMENT ON TYPE ai_core.correlation_result_status IS 'Status of correlation analysis results';

-- Enum: MODEL_VERSION_STATUS
-- Description: Defines status of ML model versions
-- Business Case: Manages lifecycle of different model versions for deployment and rollback
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_version_status AS ENUM (
    'EXPERIMENTAL',                  -- Experimental model version
    'VALIDATION_READY',              -- Ready for validation
    'VALIDATION_IN_PROGRESS',        -- Validation in progress
    'VALIDATION_COMPLETE',           -- Validation completed
    'DEPLOYMENT_READY',              -- Ready for deployment
    'DEPLOYED',                      -- Deployed to production
    'OBSOLETE',                      -- Model version is obsolete
    'ROLLED_BACK'                    -- Model version rolled back
);
COMMENT ON TYPE ai_core.model_version_status IS 'Status of machine learning model versions';

-- Enum: ANOMALY_DETECTION_METHOD
-- Description: Defines methods used for anomaly detection
-- Business Case: Categorizes different anomaly detection approaches for optimal selection
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_method AS ENUM (
    'STATISTICAL',                   -- Statistical method
    'MACHINE_LEARNING',              -- ML-based method
    'RULE_BASED',                    -- Rule-based method
    'HYBRID',                        -- Hybrid approach
    'THRESHOLD_BASED',               -- Threshold-based method
    'BEHAVIORAL',                    -- Behavioral analysis
    'PATTERN_RECOGNITION',           -- Pattern recognition
    'DEEP_LEARNING'                  -- Deep learning approach
);
COMMENT ON TYPE ai_core.anomaly_detection_method IS 'Methods used for anomaly detection';

-- Enum: AUTO_HEALING_CATEGORY
-- Description: Defines categories of auto-healing scripts
-- Business Case: Categorizes automated remediation capabilities for targeted deployment
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_category AS ENUM (
    'INFRASTRUCTURE',                -- Infrastructure-level healing
    'APPLICATION',                   -- Application-level healing
    'NETWORK',                       -- Network-level healing
    'DATABASE',                      -- Database-level healing
    'SECURITY',                      -- Security-level healing
    'PERFORMANCE',                   -- Performance-level healing
    'AVAILABILITY',                  -- Availability-level healing
    'DATA_INTEGRITY'                 -- Data integrity healing
);
COMMENT ON TYPE ai_core.auto_healing_category IS 'Categories of auto-healing scripts';

-- Enum: USER_FEEDBACK_RATING
-- Description: Defines rating scales for user feedback
-- Business Case: Standardizes feedback collection and analysis for consistent measurement
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_rating AS ENUM (
    'VERY_UNSATISFIED',              -- 1-star rating
    'UNSATISFIED',                   -- 2-star rating
    'NEUTRAL',                       -- 3-star rating
    'SATISFIED',                     -- 4-star rating
    'VERY_SATISFIED',                -- 5-star rating
    'EXCELLENT',                     -- Exceptional rating
    'POOR',                          -- Poor rating
    'GOOD'                           -- Good rating
);
COMMENT ON TYPE it_incident.user_feedback_rating IS 'Rating scales for user feedback collection';

-- Enum: BLOCKCHAIN_CONSENSUS_TYPE
-- Description: Defines types of blockchain consensus mechanisms
-- Business Case: Supports different blockchain implementation strategies for various use cases
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_consensus_type AS ENUM (
    'PROOF_OF_WORK',                 -- Proof of Work consensus
    'PROOF_OF_STAKE',                -- Proof of Stake consensus
    'DELEGATED_PROOF',               -- Delegated Proof consensus
    'BYZANTINE_FAULT_TOLERANT',      -- Byzantine Fault Tolerant
    'PRACTICAL_BYZANTINE',           -- Practical Byzantine consensus
    'RAFT',                          -- Raft consensus algorithm
    'PBFT',                          -- Practical Byzantine Fault Tolerance
    'HYPERLEDGER_FABRIC'             -- Hyperledger Fabric consensus
);
COMMENT ON TYPE sec_audit.blockchain_consensus_type IS 'Types of blockchain consensus mechanisms';

-- Enum: METERING_COLLECTION_FREQUENCY
-- Description: Defines frequency of metering data collection
-- Business Case: Optimizes data collection for performance and storage efficiency
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_collection_frequency AS ENUM (
    'REAL_TIME',                     -- Real-time collection
    'SECONDLY',                      -- Every second
    'MINUTELY',                      -- Every minute
    'HOURLY',                        -- Every hour
    'DAILY',                         -- Daily collection
    'WEEKLY',                        -- Weekly collection
    'MONTHLY',                       -- Monthly collection
    'QUARTERLY'                      -- Quarterly collection
);
COMMENT ON TYPE it_incident.metering_collection_frequency IS 'Frequency of metering data collection';

-- Enum: AUDIT_LOG_SOURCE
-- Description: Defines sources of audit log entries
-- Business Case: Tracks origin of audit events for security analysis and investigation
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_source AS ENUM (
    'USER_INTERFACE',                -- User interface originated
    'API_CALL',                      -- API call originated
    'BACKGROUND_JOB',                -- Background job originated
    'SYSTEM_SERVICE',                -- System service originated
    'EXTERNAL_INTEGRATION',          -- External integration originated
    'SECURITY_MONITOR',              -- Security monitor originated
    'AUDIT_DAEMON',                  -- Audit daemon originated
    'MANUAL_ENTRY'                   -- Manual entry originated
);
COMMENT ON TYPE it_incident.audit_log_source IS 'Sources of audit log entries';

-- Enum: CHATBOT_TRAINING_QUALITY
-- Description: Defines quality levels of chatbot training corrections
-- Business Case: Assesses effectiveness of chatbot learning improvements for model refinement
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_quality AS ENUM (
    'HIGH',                          -- High quality correction
    'MEDIUM',                        -- Medium quality correction
    'LOW',                           -- Low quality correction
    'SPAM',                          -- Spam or invalid correction
    'DUPLICATE',                     -- Duplicate correction
    'IRRELEVANT',                    -- Irrelevant correction
    'HELPFUL',                       -- Helpful correction
    'UNHELPFUL'                      -- Unhelpful correction
);
COMMENT ON TYPE ai_core.chatbot_training_quality IS 'Quality levels of chatbot training corrections';

-- Enum: AR_SCENE_COMPLEXITY
-- Description: Defines complexity levels of AR scenes
-- Business Case: Optimizes AR rendering based on scene complexity for performance and user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_complexity AS ENUM (
    'SIMPLE',                        -- Simple scene with few elements
    'MODERATE',                      -- Moderate complexity scene
    'COMPLEX',                       -- Complex scene with many elements
    'VERY_COMPLEX',                  -- Very complex scene
    'ULTRA_COMPLEX',                 -- Ultra complex scene
    'LIGHTWEIGHT',                   -- Lightweight optimized scene
    'ENTERPRISE',                    -- Enterprise-level complexity
    'CUSTOM'                         -- Custom complexity level
);
COMMENT ON TYPE ai_core.ar_scene_complexity IS 'Complexity levels of augmented reality scenes';

-- Enum: FEATURE_IMPORTANCE_METHOD
-- Description: Defines methods for calculating feature importance
-- Business Case: Differentiates approaches to measuring feature impact for model interpretation
-- Feature Reference: 1.024
CREATE TYPE ai_core.feature_importance_method AS ENUM (
    'PERMUTATION',                   -- Permutation importance
    'SHAP_VALUES',                   -- SHAP (SHapley Additive exPlanations)
    'TREE_BASED',                    -- Tree-based feature importance
    'LINEAR_COEFFICIENTS',           -- Linear model coefficients
    'GRADIENT_BASED',                -- Gradient-based importance
    'VARIANCE_REDUCING',             -- Variance-reducing importance
    'LOFO_IMPORTANCE',               -- Leave-One-Feature-Out importance
    'CORRELATION_BASED'              -- Correlation-based importance
);
COMMENT ON TYPE ai_core.feature_importance_method IS 'Methods for calculating feature importance in models';

-- Enum: WORKFLOW_EXECUTION_STATUS
-- Description: Defines status of workflow execution instances
-- Business Case: Tracks progress of automated workflows for monitoring and troubleshooting
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_status AS ENUM (
    'QUEUED',                        -- Workflow queued for execution
    'RUNNING',                       -- Currently running
    'PAUSED',                        -- Execution temporarily paused
    'COMPLETED',                     -- Execution completed successfully
    'FAILED',                        -- Execution failed
    'CANCELLED',                     -- Execution cancelled
    'RETRYING',                      -- Retrying after failure
    'WAITING_DEPENDENCY'             -- Waiting for dependency
);
COMMENT ON TYPE ai_core.workflow_execution_status IS 'Status of workflow execution instances';

-- Enum: SIMULATION_EFFECTIVENESS
-- Description: Defines effectiveness levels of simulation scenarios
-- Business Case: Measures value of simulation exercises for resilience and readiness
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_effectiveness AS ENUM (
    'HIGHLY_EFFECTIVE',              -- Highly effective simulation
    'EFFECTIVE',                     -- Effective simulation
    'MODERATELY_EFFECTIVE',          -- Moderately effective
    'SLIGHTLY_EFFECTIVE',            -- Slightly effective
    'INEFFECTIVE',                   -- Ineffective simulation
    'COUNTER_PRODUCTIVE',            -- Counter-productive simulation
    'NOT_APPLICABLE',                -- Not applicable
    'UNCERTAIN'                      -- Uncertain effectiveness
);
COMMENT ON TYPE ai_core.simulation_effectiveness IS 'Effectiveness levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_CALCULATION_METHOD
-- Description: Defines methods for calculating satisfaction index
-- Business Case: Supports different approaches to satisfaction measurement for flexibility
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_calculation_method AS ENUM (
    'WEIGHTED_AVERAGE',              -- Weighted average calculation
    'GEOMETRIC_MEAN',                -- Geometric mean calculation
    'HARMONIC_MEAN',                 -- Harmonic mean calculation
    'MEDIAN_BASED',                  -- Median-based calculation
    'MODE_BASED',                    -- Mode-based calculation
    'COMPOSITE_INDEX',               -- Composite index calculation
    'FUZZY_LOGIC',                   -- Fuzzy logic calculation
    'NEURAL_NETWORK'                 -- Neural network calculation
);
COMMENT ON TYPE ai_core.satisfaction_index_calculation_method IS 'Methods for calculating satisfaction index';

-- Enum: CORRELATION_ANALYSIS_SCOPE
-- Description: Defines scope of correlation analysis
-- Business Case: Categorizes breadth of correlation studies for targeted analysis
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_analysis_scope AS ENUM (
    'BIVARIATE',                     -- Two-variable correlation
    'MULTIVARIATE',                  -- Multiple variable correlation
    'TEMPORAL',                      -- Time-series correlation
    'CROSS_SECTIONAL',               -- Cross-sectional correlation
    'LONGITUDINAL',                  -- Longitudinal correlation
    'NETWORK',                       -- Network-based correlation
    'CLUSTER_BASED',                 -- Cluster-based correlation
    'DOMAIN_SPECIFIC'                -- Domain-specific correlation
);
COMMENT ON TYPE ai_core.correlation_analysis_scope IS 'Scope of correlation analysis';

-- Enum: MODEL_ROLLBACK_REASON
-- Description: Defines reasons for rolling back ML model versions
-- Business Case: Tracks causes for model version rollbacks for continuous improvement
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_reason AS ENUM (
    'HIGH_ERROR_RATE',               -- High prediction error rate
    'DRIFT_DETECTED',                -- Model drift detected
    'PERFORMANCE_DEGRADATION',       -- Performance degradation
    'SECURITY_VULNERABILITY',        -- Security vulnerability found
    'COMPLIANCE_ISSUE',              -- Compliance issue discovered
    'BUSINESS_REQUIREMENT_CHANGE',   -- Business requirement changed
    'DATA_QUALITY_ISSUE',            -- Data quality issue
    'ACCURACY_DETERIORATION'         -- Prediction accuracy deterioration
);
COMMENT ON TYPE ai_core.model_rollback_reason IS 'Reasons for rolling back machine learning model versions';

-- Enum: TRAINING_DATA_QUALITY
-- Description: Defines quality levels of training data
-- Business Case: Assesses fitness of training data for model development and performance
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_quality AS ENUM (
    'EXCELLENT',                     -- Excellent quality data
    'GOOD',                          -- Good quality data
    'FAIR',                          -- Fair quality data
    'POOR',                          -- Poor quality data
    'INSUFFICIENT',                  -- Insufficient data volume
    'BIASED',                        -- Biased data distribution
    'INCOMPLETE',                    -- Incomplete data
    'CORRUPTED'                      -- Corrupted data
);
COMMENT ON TYPE ai_core.training_data_quality IS 'Quality levels of training data';

-- Enum: EXPERT_SWARM_EFFICIENCY
-- Description: Defines efficiency levels of expert swarms
-- Business Case: Measures collaborative problem-solving effectiveness for optimization
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_efficiency AS ENUM (
    'HIGHLY_EFFICIENT',              -- Highly efficient swarm
    'EFFICIENT',                     -- Efficient swarm
    'MODERATELY_EFFICIENT',          -- Moderately efficient
    'LESS_EFFICIENT',                -- Less efficient swarm
    'INEFFICIENT',                   -- Inefficient swarm
    'COUNTER_PRODUCTIVE',            -- Counter-productive swarm
    'OPTIMAL',                       -- Optimal efficiency
    'SUB_OPTIMAL'                    -- Sub-optimal efficiency
);
COMMENT ON TYPE ai_core.expert_swarm_efficiency IS 'Efficiency levels of expert swarms';

-- Enum: SENTIMENT_ANALYSIS_CONFIDENCE
-- Description: Defines confidence levels in sentiment analysis
-- Business Case: Indicates reliability of sentiment detection for appropriate action
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_confidence AS ENUM (
    'VERY_HIGH',                     -- Very high confidence
    'HIGH',                          -- High confidence
    'MODERATE',                      -- Moderate confidence
    'LOW',                           -- Low confidence
    'VERY_LOW',                      -- Very low confidence
    'UNDETERMINED',                  -- Undetermined confidence
    'UNCERTAIN',                     -- Uncertain sentiment
    'AMBIGUOUS'                      -- Ambiguous sentiment
);
COMMENT ON TYPE ai_core.sentiment_analysis_confidence IS 'Confidence levels in sentiment analysis';

-- Enum: CMDB_SYNC_CONFLICT_RESOLUTION
-- Description: Defines methods for resolving CMDB synchronization conflicts
-- Business Case: Handles data conflicts during synchronization to maintain data integrity
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_conflict_resolution AS ENUM (
    'LAST_WRITE_WINS',               -- Latest write takes precedence
    'SOURCE_PRIORITIZED',            -- Source system prioritized
    'MANUAL_RESOLUTION',             -- Manual conflict resolution
    'MERGE_CHANGES',                 -- Merge conflicting changes
    'IGNORE_CONFLICT',               -- Ignore the conflict
    'ROLLBACK_SYNC',                 -- Rollback the synchronization
    'CREATE_NEW_VERSION',            -- Create new version for conflict
    'PROMPT_USER'                    -- Prompt user for resolution
);
COMMENT ON TYPE config_mgmt.cmdb_sync_conflict_resolution IS 'Methods for resolving CMDB synchronization conflicts';

-- Enum: CONFIGURATION_ITEM_CRITICALITY
-- Description: Defines criticality levels of configuration items
-- Business Case: Prioritizes configuration item management based on business impact
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_criticality AS ENUM (
    'LOW',                           -- Low business impact
    'MEDIUM',                        -- Medium business impact
    'HIGH',                          -- High business impact
    'CRITICAL',                      -- Critical business impact
    'MISSION_CRITICAL',              -- Mission-critical impact
    'NON_CRITICAL',                  -- Non-critical impact
    'OPTIONAL',                      -- Optional component
    'DEPRECATED'                     -- Deprecated component
);
COMMENT ON TYPE config_mgmt.configuration_item_criticality IS 'Criticality levels of configuration items';

-- Enum: SCENARIO_SIMULATION_COMPLEXITY
-- Description: Defines complexity levels of simulation scenarios
-- Business Case: Categorizes simulation scenarios by complexity for resource allocation
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_complexity AS ENUM (
    'SIMPLE',                        -- Simple scenario
    'MODERATE',                      -- Moderate complexity scenario
    'COMPLEX',                       -- Complex scenario
    'VERY_COMPLEX',                  -- Very complex scenario
    'ENTERPRISE',                    -- Enterprise-level scenario
    'INDUSTRY_STANDARD',             -- Industry standard scenario
    'CUSTOM',                        -- Custom complexity scenario
    'EXPERIMENTAL'                   -- Experimental complexity scenario
);
COMMENT ON TYPE ai_core.scenario_simulation_complexity IS 'Complexity levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_TREND
-- Description: Defines trend directions for satisfaction indices
-- Business Case: Tracks satisfaction trend patterns for proactive management
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_trend AS ENUM (
    'SIGNIFICANTLY_IMPROVING',       -- Significantly improving trend
    'IMPROVING',                     -- Improving trend
    'STABLE',                        -- Stable trend
    'DECLINING',                     -- Declining trend
    'SIGNIFICANTLY_DECLINING',       -- Significantly declining trend
    'FLUCTUATING',                   -- Fluctuating trend
    'RECOVERING',                    -- Recovering trend
    'PEAKING'                        -- Peaking trend
);
COMMENT ON TYPE ai_core.satisfaction_index_trend IS 'Trend directions for satisfaction indices';

-- Enum: CORRELATION_SIGNIFICANCE_LEVEL
-- Description: Defines significance levels of correlations
-- Business Case: Indicates statistical significance of correlations for decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_significance_level AS ENUM (
    'HIGHLY_SIGNIFICANT',            -- p-value < 0.001
    'SIGNIFICANT',                   -- p-value < 0.01
    'MODERATELY_SIGNIFICANT',        -- p-value < 0.05
    'MARGINALLY_SIGNIFICANT',        -- p-value < 0.10
    'NOT_SIGNIFICANT',               -- p-value >= 0.10
    'STATISTICALLY_INSIGNIFICANT',   -- Clearly insignificant
    'PROBABLY_SIGNIFICANT',          -- Probably significant
    'QUESTIONABLY_SIGNIFICANT'       -- Questionably significant
);
COMMENT ON TYPE ai_core.correlation_significance_level IS 'Significance levels of statistical correlations';

-- Enum: MODEL_PERFORMANCE_METRIC_TYPE
-- Description: Defines types of model performance metrics
-- Business Case: Categorizes different performance measurement approaches for evaluation
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_metric_type AS ENUM (
    'CLASSIFICATION',                -- Classification metrics
    'REGRESSION',                    -- Regression metrics
    'CLUSTERING',                    -- Clustering metrics
    'RANKING',                       -- Ranking metrics
    'ANOMALY_DETECTION',             -- Anomaly detection metrics
    'TIME_SERIES',                   -- Time series metrics
    'RECOMMENDATION',                -- Recommendation metrics
    'GENERATIVE'                     -- Generative model metrics
);
COMMENT ON TYPE ai_core.model_performance_metric_type IS 'Types of machine learning model performance metrics';

-- Enum: ANOMALY_RESPONSE_ACTION
-- Description: Defines actions taken in response to anomalies
-- Business Case: Standardizes response protocols for detected anomalies for consistency
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_response_action AS ENUM (
    'ALERT_ONLY',                    -- Alert without action
    'AUTO_HEALING_ATTEMPT',          -- Attempt auto-healing
    'ESCALATE_TO_HUMAN',             -- Escalate to human operator
    'ISOLATE_COMPONENT',             -- Isolate affected component
    'SHUTDOWN_COMPONENT',            -- Shutdown affected component
    'LOG_FOR_REVIEW',                -- Log for later review
    'IGNORE_TEMPORARILY',            -- Ignore temporarily
    'INCREASE_MONITORING'            -- Increase monitoring intensity
);
COMMENT ON TYPE ai_core.anomaly_response_action IS 'Actions taken in response to detected anomalies';

-- Enum: AUTO_HEALING_SUCCESS_RATE
-- Description: Defines success rate categories for auto-healing
-- Business Case: Measures effectiveness of automated remediation for optimization
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_success_rate AS ENUM (
    'EXCELLENT',                     -- >95% success rate
    'GOOD',                          -- 85-95% success rate
    'FAIR',                          -- 70-85% success rate
    'POOR',                          -- 50-70% success rate
    'VERY_POOR',                     -- <50% success rate
    'UNKNOWN',                       -- Success rate unknown
    'NOT_APPLICABLE',                -- Not applicable
    'PERFECT'                        -- 100% success rate
);
COMMENT ON TYPE ai_core.auto_healing_success_rate IS 'Success rate categories for auto-healing operations';

-- Enum: USER_FEEDBACK_SOURCE
-- Description: Defines sources of user feedback
-- Business Case: Tracks feedback origin channels for targeted response strategies
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_source AS ENUM (
    'WEB_PORTAL',                    -- Feedback from web portal
    'MOBILE_APP',                    -- Feedback from mobile app
    'EMAIL',                         -- Email feedback
    'PHONE_CALL',                    -- Phone call feedback
    'CHAT',                          -- Chat session feedback
    'SURVEY',                        -- Survey response
    'SOCIAL_MEDIA',                  -- Social media feedback
    'DIRECT_INTERACTION'             -- Direct interaction feedback
);
COMMENT ON TYPE it_incident.user_feedback_source IS 'Sources of user feedback collection';

-- Enum: BLOCKCHAIN_TRANSACTION_STATUS
-- Description: Defines status of blockchain transactions
-- Business Case: Tracks blockchain transaction lifecycle for monitoring and validation
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_status AS ENUM (
    'PENDING',                       -- Transaction pending confirmation
    'CONFIRMED',                     -- Transaction confirmed
    'REJECTED',                      -- Transaction rejected
    'FAILED',                        -- Transaction failed
    'DUPLICATE',                     -- Duplicate transaction
    'INSUFFICIENT_FUNDS',            -- Insufficient funds
    'CONTRACT_ERROR',                -- Smart contract error
    'TIMEOUT'                        -- Transaction timed out
);
COMMENT ON TYPE sec_audit.blockchain_transaction_status IS 'Status of blockchain transactions';

-- Enum: METERING_DATA_QUALITY
-- Description: Defines quality levels of metering data
-- Business Case: Assesses reliability of collected metrics for accurate analysis
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_quality AS ENUM (
    'EXCELLENT',                     -- Excellent data quality
    'GOOD',                          -- Good data quality
    'FAIR',                          -- Fair data quality
    'POOR',                          -- Poor data quality
    'MISSING',                       -- Missing data
    'INCONSISTENT',                  -- Inconsistent data
    'CORRUPTED',                     -- Corrupted data
    'OUTDATED'                       -- Outdated data
);
COMMENT ON TYPE it_incident.metering_data_quality IS 'Quality levels of metering data';

-- Enum: AUDIT_LOG_IMPORTANCE
-- Description: Defines importance levels of audit log entries
-- Business Case: Prioritizes audit log review and analysis for security and compliance
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_importance AS ENUM (
    'CRITICAL',                      -- Critical security event
    'HIGH',                          -- High importance event
    'MEDIUM',                        -- Medium importance event
    'LOW',                           -- Low importance event
    'INFORMATIONAL',                 -- Informational only
    'DEBUG',                         -- Debugging information
    'TRACE',                         -- Detailed tracing
    'VERBOSE'                        -- Verbose logging
);
COMMENT ON TYPE it_incident.audit_log_importance IS 'Importance levels of audit log entries';

-- Enum: CHATBOT_TRAINING_SOURCE
-- Description: Defines sources of chatbot training data
-- Business Case: Tracks origins of training improvements for quality assessment
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_source AS ENUM (
    'USER_CORRECTION',               -- User-provided correction
    'ADMIN_TRAINING',                -- Admin-provided training
    'KNOWLEDGE_BASE',                -- Knowledge base integration
    'EXTERNAL_API',                  -- External API integration
    'MANUAL_ENTRY',                  -- Manual entry by staff
    'AUTOMATED_FEED',                -- Automated feed integration
    'THIRD_PARTY',                   -- Third-party source
    'INTERNAL_KNOWLEDGE'             -- Internal knowledge source
);
COMMENT ON TYPE ai_core.chatbot_training_source IS 'Sources of chatbot training data';

-- Enum: AR_CONTENT_PRIORITY
-- Description: Defines priority levels for AR content
-- Business Case: Orders AR content display based on importance for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_content_priority AS ENUM (
    'CRITICAL',                      -- Critical safety content
    'HIGH',                          -- High priority content
    'MEDIUM',                        -- Medium priority content
    'LOW',                           -- Low priority content
    'OPTIONAL',                      -- Optional content
    'INFORMATIONAL',                 -- Informational content
    'REFERENCE',                     -- Reference content
    'BACKGROUND'                     -- Background information
);
COMMENT ON TYPE ai_core.ar_content_priority IS 'Priority levels for augmented reality content';

-- Enum: FEATURE_VALIDITY_STATUS
-- Description: Defines validity status of ML features
-- Business Case: Tracks feature reliability and applicability for model maintenance
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_validity_status AS ENUM (
    'VALID',                         -- Feature is valid
    'EXPIRED',                       -- Feature has expired
    'SUSPENDED',                     -- Feature temporarily suspended
    'DEPRECATED',                    -- Feature deprecated
    'INVALID',                       -- Feature is invalid
    'PENDING_VALIDATION',            -- Pending validation
    'REQUIRES_REFRESH',              -- Requires data refresh
    'ARCHIVED'                       -- Feature archived
);
COMMENT ON TYPE ai_core.feature_validity_status IS 'Validity status of machine learning features';

-- Enum: MODEL_TRAINING_DATA_SOURCE
-- Description: Defines sources of training data for ML models
-- Business Case: Tracks data provenance for model development and compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_data_source AS ENUM (
    'PRODUCTION_DATA',               -- Production system data
    'SYNTHETIC_DATA',                -- Artificially generated data
    'HISTORICAL_DATA',               -- Historical system data
    'EXTERNAL_API',                  -- External API data
    'USER_INPUT',                    -- User-provided data
    'SIMULATION_DATA',               -- Simulation-generated data
    'TEST_DATA',                     -- Test environment data
    'THIRD_PARTY'                    -- Third-party data source
);
COMMENT ON TYPE ai_core.model_training_data_source IS 'Sources of training data for machine learning models';

-- Enum: ANOMALY_PATTERN_TYPE
-- Description: Defines types of anomaly patterns detected
-- Business Case: Categorizes different anomaly detection patterns for targeted response
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_pattern_type AS ENUM (
    'POINT_ANOMALY',                 -- Single point anomaly
    'CONTEXTUAL_ANOMALY',            -- Contextual anomaly
    'COLLECTIVE_ANOMALY',            -- Collective anomaly pattern
    'TEMPORAL_ANOMALY',              -- Temporal anomaly pattern
    'SPATIAL_ANOMALY',               -- Spatial anomaly pattern
    'BEHAVIORAL_ANOMALY',            -- Behavioral anomaly pattern
    'STATISTICAL_ANOMALY',           -- Statistical anomaly pattern
    'DEVIATION_ANOMALY'              -- Deviation-based anomaly pattern
);
COMMENT ON TYPE ai_core.anomaly_pattern_type IS 'Types of anomaly patterns detected by systems';

-- Enum: AUTO_HEALING_STRATEGY
-- Description: Defines strategies for auto-healing operations
-- Business Case: Categorizes different remediation approaches for optimal selection
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_strategy AS ENUM (
    'RESTART_SERVICE',               -- Restart the affected service
    'SCALE_UP_RESOURCES',            -- Scale up computational resources
    'SWITCH_TO_BACKUP',              -- Switch to backup component
    'ROLLBACK_CONFIG',               -- Rollback to previous configuration
    'ISOLATE_PROBLEM',               -- Isolate problematic component
    'CLEAN_CACHE',                   -- Clean cache and temporary files
    'RECONFIGURE_SETTINGS',          -- Reconfigure system settings
    'EXECUTE_RECOVERY_SCRIPT'        -- Execute predefined recovery script
);
COMMENT ON TYPE ai_core.auto_healing_strategy IS 'Strategies for auto-healing operations';

-- Enum: USER_FEEDBACK_IMPACT
-- Description: Defines impact levels of user feedback
-- Business Case: Prioritizes feedback based on business impact for resource allocation
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_impact AS ENUM (
    'CRITICAL',                      -- Critical business impact
    'HIGH',                          -- High business impact
    'MEDIUM',                        -- Medium business impact
    'LOW',                           -- Low business impact
    'MINIMAL',                       -- Minimal business impact
    'NONE',                          -- No business impact
    'POSITIVE',                      -- Positive business impact
    'NEGATIVE'                       -- Negative business impact
);
COMMENT ON TYPE it_incident.user_feedback_impact IS 'Impact levels of user feedback on business operations';

-- Enum: BLOCKCHAIN_AUDIT_LEVEL
-- Description: Defines levels of blockchain audit detail
-- Business Case: Controls depth of audit trail inspection for compliance and security
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_audit_level AS ENUM (
    'DETAILED',                      -- Full detail audit trail
    'SUMMARY',                       -- Summary level audit
    'COMPLIANCE',                    -- Compliance-focused audit
    'SECURITY',                      -- Security-focused audit
    'TRANSACTION',                   -- Transaction-focused audit
    'ENTITY',                        -- Entity-focused audit
    'EVENT',                         -- Event-focused audit
    'PERFORMANCE'                    -- Performance-focused audit
);
COMMENT ON TYPE sec_audit.blockchain_audit_level IS 'Levels of blockchain audit detail';

-- Enum: METERING_DATA_AGGR_LEVEL
-- Description: Defines aggregation levels for metering data
-- Business Case: Optimizes data storage and retrieval for performance and cost
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_aggr_level AS ENUM (
    'RAW',                           -- Raw unaggregated data
    'MINUTE',                        -- Minute-level aggregation
    'HOUR',                          -- Hourly aggregation
    'DAY',                           -- Daily aggregation
    'WEEK',                          -- Weekly aggregation
    'MONTH',                         -- Monthly aggregation
    'QUARTER',                       -- Quarterly aggregation
    'YEAR'                           -- Yearly aggregation
);
COMMENT ON TYPE it_incident.metering_data_aggr_level IS 'Aggregation levels for metering data';

-- Enum: AUDIT_LOG_SENSITIVITY
-- Description: Defines sensitivity levels of audit log entries
-- Business Case: Controls access based on sensitivity for security and privacy
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_sensitivity AS ENUM (
    'PUBLIC',                        -- Public information
    'INTERNAL',                      -- Internal to organization
    'CONFIDENTIAL',                  -- Confidential information
    'RESTRICTED',                    -- Restricted access
    'SECRET',                        -- Secret information
    'TOP_SECRET',                    -- Top secret information
    'CLASSIFIED',                    -- Classified information
    'PERSONAL'                       -- Personal information
);
COMMENT ON TYPE it_incident.audit_log_sensitivity IS 'Sensitivity levels of audit log entries';

-- Enum: CHATBOT_TRAINING_EFFECTIVENESS
-- Description: Defines effectiveness of chatbot training updates
-- Business Case: Measures impact of training improvements for model optimization
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_effectiveness AS ENUM (
    'HIGHLY_EFFECTIVE',              -- Highly effective training
    'EFFECTIVE',                     -- Effective training
    'MODERATELY_EFFECTIVE',          -- Moderately effective
    'SLIGHTLY_EFFECTIVE',            -- Slightly effective
    'INEFFECTIVE',                   -- Ineffective training
    'COUNTER_PRODUCTIVE',            -- Counter-productive training
    'NEUTRAL',                       -- No effect on performance
    'UNKNOWN'                        -- Effectiveness unknown
);
COMMENT ON TYPE ai_core.chatbot_training_effectiveness IS 'Effectiveness of chatbot training updates';

-- Enum: AR_SCENE_RENDERING_QUALITY
-- Description: Defines quality levels for AR scene rendering
-- Business Case: Optimizes rendering based on quality requirements for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_rendering_quality AS ENUM (
    'ULTRA',                         -- Ultra high quality rendering
    'HIGH',                          -- High quality rendering
    'MEDIUM',                        -- Medium quality rendering
    'LOW',                           -- Low quality rendering
    'FAST',                          -- Fast rendering mode
    'BALANCED',                      -- Balanced quality and speed
    'POWER_SAVING',                  -- Power saving mode
    'ADAPTIVE'                       -- Adaptive quality mode
);
COMMENT ON TYPE ai_core.ar_scene_rendering_quality IS 'Quality levels for augmented reality scene rendering';

-- Enum: FEATURE_UPDATE_FREQUENCY
-- Description: Defines update frequency for ML features
-- Business Case: Optimizes feature refresh cycles for performance and relevance
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_update_frequency AS ENUM (
    'REAL_TIME',                     -- Updated in real-time
    'HOURLY',                        -- Updated hourly
    'DAILY',                         -- Updated daily
    'WEEKLY',                        -- Updated weekly
    'MONTHLY',                       -- Updated monthly
    'QUARTERLY',                     -- Updated quarterly
    'ANNUALLY',                      -- Updated annually
    'EVENT_DRIVEN'                   -- Updated on specific events
);
COMMENT ON TYPE ai_core.feature_update_frequency IS 'Update frequency for machine learning features';

-- Enum: MODEL_DEPLOYMENT_ENVIRONMENT
-- Description: Defines environments for ML model deployment
-- Business Case: Manages model lifecycle across environments for testing and production
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_deployment_environment AS ENUM (
    'DEVELOPMENT',                   -- Development environment
    'TESTING',                       -- Testing environment
    'STAGING',                       -- Staging environment
    'PRODUCTION',                    -- Production environment
    'QA',                            -- Quality assurance environment
    'SANDBOX',                       -- Sandbox environment
    'PREPRODUCTION',                 -- Pre-production environment
    'DR'                             -- Disaster recovery environment
);
COMMENT ON TYPE ai_core.model_deployment_environment IS 'Environments for machine learning model deployment';

-- Enum: ANOMALY_DETECTION_FREQUENCY
-- Description: Defines frequency of anomaly detection runs
-- Business Case: Balances detection sensitivity with system resources for optimization
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_frequency AS ENUM (
    'CONTINUOUS',                    -- Continuous monitoring
    'REAL_TIME',                     -- Real-time detection
    'MINUTELY',                      -- Minutely detection
    'HOURLY',                        -- Hourly detection
    'DAILY',                         -- Daily detection
    'WEEKLY',                        -- Weekly detection
    'EVENT_TRIGGERED',               -- Event-triggered detection
    'SCHEDULED'                      -- Scheduled detection
);
COMMENT ON TYPE ai_core.anomaly_detection_frequency IS 'Frequency of anomaly detection operations';

-- Enum: AUTO_HEALING_RECOVERY_MODE
-- Description: Defines recovery modes for auto-healing operations
-- Business Case: Categorizes different recovery approaches for optimal selection
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_recovery_mode AS ENUM (
    'GRACEFUL',                      -- Graceful service restart
    'FORCEFUL',                      -- Forceful restart if needed
    'GRADUAL',                       -- Gradual recovery approach
    'INSTANT',                       -- Instant recovery mode
    'STEP_BY_STEP',                  -- Step-by-step recovery
    'ROLLING',                       -- Rolling recovery approach
    'BLUE_GREEN',                    -- Blue-green deployment recovery
    'CANARY'                         -- Canary release recovery
);
COMMENT ON TYPE ai_core.auto_healing_recovery_mode IS 'Recovery modes for auto-healing operations';

-- Enum: USER_FEEDBACK_TIMELINESS
-- Description: Defines timeliness of user feedback provision
-- Business Case: Measures response time to service delivery for customer satisfaction
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_timeliness AS ENUM (
    'IMMEDIATE',                     -- Immediate feedback
    'SAME_DAY',                      -- Same day feedback
    'WITHIN_WEEK',                   -- Within week feedback
    'WITHIN_MONTH',                  -- Within month feedback
    'DELAYED',                       -- Delayed feedback
    'LATE',                          -- Late feedback
    'TYPICAL',                       -- Typical timing
    'ATYPICAL'                       -- Atypical timing
);
COMMENT ON TYPE it_incident.user_feedback_timeliness IS 'Timeliness of user feedback provision';

-- Enum: BLOCKCHAIN_NODE_TYPE
-- Description: Defines types of blockchain nodes in network
-- Business Case: Differentiates node responsibilities and capabilities for network management
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_node_type AS ENUM (
    'FULL_NODE',                     -- Full blockchain node
    'LIGHT_NODE',                    -- Light blockchain node
    'MINING_NODE',                   -- Mining node
    'VALIDATION_NODE',               -- Validation node
    'ARCHIVAL_NODE',                 -- Archival node
    'BOOTSTRAP_NODE',                -- Bootstrap node
    'PEER_NODE',                     -- Regular peer node
    'AUTHORITY_NODE'                 -- Authority node
);
COMMENT ON TYPE sec_audit.blockchain_node_type IS 'Types of blockchain nodes in the network';

-- Enum: METERING_DATA_RETENTION_POLICY
-- Description: Defines retention policies for metering data
-- Business Case: Optimizes storage costs while meeting compliance and analytical needs
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_retention_policy AS ENUM (
    'SHORT_TERM',                    -- Short-term retention (days-weeks)
    'MEDIUM_TERM',                   -- Medium-term retention (weeks-months)
    'LONG_TERM',                     -- Long-term retention (months-years)
    'COMPLIANCE',                    -- Compliance-mandated retention
    'LEGAL_HOLD',                    -- Legal hold retention
    'ARCHIVAL',                      -- Archival retention
    'ROTATING',                      -- Rotating retention policy
    'CUSTOM'                         -- Custom retention policy
);
COMMENT ON TYPE it_incident.metering_data_retention_policy IS 'Retention policies for metering data';

-- Enum: AUDIT_LOG_REVIEW_STATUS
-- Description: Defines review status of audit log entries
-- Business Case: Tracks audit log review progress for compliance and security
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_review_status AS ENUM (
    'PENDING_REVIEW',                -- Audit log awaiting review
    'UNDER_REVIEW',                  -- Currently under review
    'REVIEW_COMPLETED',              -- Review completed
    'ESCALATED',                     -- Escalated for further review
    'FLAGGED',                       -- Flagged for special attention
    'IGNORED',                       -- Ignored after review
    'ACTION_REQUIRED',               -- Action required from review
    'RESOLVED'                       -- Issue resolved from review
);
COMMENT ON TYPE it_incident.audit_log_review_status IS 'Review status of audit log entries';

-- Enum: CHATBOT_TRAINING_RELEVANCE
-- Description: Defines relevance of chatbot training examples
-- Business Case: Prioritizes training examples by relevance for model improvement
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_relevance AS ENUM (
    'HIGHLY_RELEVANT',               -- Highly relevant to current needs
    'RELEVANT',                      -- Relevant to current needs
    'MODERATELY_RELEVANT',           -- Moderately relevant
    'SLIGHTLY_RELEVANT',             -- Slightly relevant
    'IRRELEVANT',                    -- Not relevant
    'OBSOLETE',                      -- Obsolete training example
    'HISTORICAL',                    -- Historical but valuable
    'EDGE_CASE'                      -- Edge case example
);
COMMENT ON TYPE ai_core.chatbot_training_relevance IS 'Relevance of chatbot training examples';

-- Enum: AR_SCENE_OPTIMIZATION_LEVEL
-- Description: Defines optimization levels for AR scenes
-- Business Case: Balances performance with visual quality for optimal user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_optimization_level AS ENUM (
    'MAX_PERFORMANCE',               -- Maximum performance optimization
    'BALANCED',                      -- Balanced performance and quality
    'QUALITY_FOCUSED',               -- Quality-focused optimization
    'VISUAL_FIDELITY',               -- Visual fidelity focused
    'ENERGY_EFFICIENT',              -- Energy-efficient optimization
    'MOBILE_OPTIMIZED',              -- Mobile device optimized
    'ENTERPRISE_GRADE',              -- Enterprise-grade optimization
    'CUSTOM_OPTIMIZED'               -- Custom optimization level
);
COMMENT ON TYPE ai_core.ar_scene_optimization_level IS 'Optimization levels for augmented reality scenes';

-- Enum: FEATURE_IMPORTANCE_THRESHOLD
-- Description: Defines thresholds for feature importance
-- Business Case: Determines which features are significant for model interpretation
-- Feature Reference: 1.024
CREATE TYPE ai_core.feature_importance_threshold AS ENUM (
    'VERY_HIGH',                     -- Very high importance threshold
    'HIGH',                          -- High importance threshold
    'MODERATE',                      -- Moderate importance threshold
    'LOW',                           -- Low importance threshold
    'VERY_LOW',                      -- Very low importance threshold
    'INSIGNIFICANT',                 -- Insignificant importance
    'FILTERED_OUT',                  -- Filtered out due to low importance
    'CRITICAL'                       -- Critical importance threshold
);
COMMENT ON TYPE ai_core.feature_importance_threshold IS 'Thresholds for feature importance in models';

-- Enum: WORKFLOW_EXECUTION_PRIORITY
-- Description: Defines priority levels for workflow execution
-- Business Case: Orders workflow execution based on importance for resource allocation
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_priority AS ENUM (
    'CRITICAL',                      -- Critical priority execution
    'HIGH',                          -- High priority execution
    'NORMAL',                        -- Normal priority execution
    'LOW',                           -- Low priority execution
    'BACKGROUND',                    -- Background priority execution
    'DEFERRED',                      -- Deferred priority execution
    'URGENT',                        -- Urgent priority execution
    'IMMEDIATE'                      -- Immediate priority execution
);
COMMENT ON TYPE ai_core.workflow_execution_priority IS 'Priority levels for workflow execution';

-- Enum: SIMULATION_SCENARIO_COMPLEXITY
-- Description: Defines complexity levels of simulation scenarios
-- Business Case: Categorizes scenarios by implementation difficulty for resource planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_scenario_complexity AS ENUM (
    'TRIVIAL',                       -- Trivial scenario complexity
    'SIMPLE',                        -- Simple scenario complexity
    'MODERATE',                      -- Moderate complexity
    'COMPLEX',                       -- Complex scenario
    'VERY_COMPLEX',                  -- Very complex scenario
    'EXTREMELY_COMPLEX',             -- Extremely complex scenario
    'INDUSTRY_STANDARD',             -- Industry-standard complexity
    'CUSTOM_COMPLEXITY'              -- Custom complexity level
);
COMMENT ON TYPE ai_core.simulation_scenario_complexity IS 'Complexity levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_COMPONENT_WEIGHT
-- Description: Defines weight levels for satisfaction index components
-- Business Case: Adjusts importance of different satisfaction factors for accurate measurement
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_component_weight AS ENUM (
    'VERY_HIGH',                     -- Very high weight component
    'HIGH',                          -- High weight component
    'MODERATE',                      -- Moderate weight component
    'LOW',                           -- Low weight component
    'VERY_LOW',                      -- Very low weight component
    'NEGLIGIBLE',                    -- Negligible weight component
    'BALANCED',                      -- Balanced weight component
    'ADAPTIVE'                       -- Adaptive weight component
);
COMMENT ON TYPE ai_core.satisfaction_index_component_weight IS 'Weight levels for satisfaction index components';

-- Enum: CORRELATION_DECAY_RATE
-- Description: Defines decay rates for correlation coefficients
-- Business Case: Models temporal degradation of correlations for predictive analytics
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_decay_rate AS ENUM (
    'RAPID',                         -- Rapid decay rate
    'MODERATE',                      -- Moderate decay rate
    'SLOW',                          -- Slow decay rate
    'STABLE',                        -- Stable correlation
    'INCREASING',                    -- Increasing correlation
    'FLUCTUATING',                   -- Fluctuating correlation
    'CYCLICAL',                      -- Cyclically varying correlation
    'SEASONAL'                       -- Seasonally varying correlation
);
COMMENT ON TYPE ai_core.correlation_decay_rate IS 'Decay rates for correlation coefficients over time';

-- Enum: MODEL_ROLLBACK_STRATEGY
-- Description: Defines strategies for rolling back ML models
-- Business Case: Standardizes rollback procedures for consistency and reliability
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_strategy AS ENUM (
    'INSTANT_ROLLBACK',              -- Instant rollback to previous version
    'GRADUAL_ROLLBACK',              -- Gradual rollback approach
    'BLUE_GREEN_ROLLBACK',           -- Blue-green deployment rollback
    'CANARY_ROLLBACK',               -- Canary release rollback
    'PHASED_ROLLBACK',               -- Phased rollback approach
    'SAFE_ROLLBACK',                 -- Safe rollback with validation
    'IMMEDIATE_ROLLBACK',            -- Immediate rollback without delay
    'CONTROLLED_ROLLBACK'            -- Controlled rollback approach
);
COMMENT ON TYPE ai_core.model_rollback_strategy IS 'Strategies for rolling back machine learning models';

-- Enum: TRAINING_DATA_BALANCE_STATUS
-- Description: Defines balance status of training datasets
-- Business Case: Ensures fair representation in model training for unbiased results
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_balance_status AS ENUM (
    'PERFECTLY_BALANCED',            -- Perfectly balanced dataset
    'ALMOST_BALANCED',               -- Almost balanced dataset
    'MODERATELY_IMBALANCED',         -- Moderately imbalanced
    'HIGHLY_IMBALANCED',             -- Highly imbalanced dataset
    'SEVERELY_IMBALANCED',           -- Severely imbalanced dataset
    'UNKNOWN_BALANCE',               -- Balance status unknown
    'INTENTIONALLY_UNBALANCED',      -- Intentionally unbalanced for purpose
    'REQUIRES_BALANCING'             -- Requires balancing intervention
);
COMMENT ON TYPE ai_core.training_data_balance_status IS 'Balance status of training datasets';

-- Enum: EXPERT_SWARM_SIZE
-- Description: Defines sizes of expert swarms
-- Business Case: Optimizes collaboration effectiveness for problem-solving efficiency
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_size AS ENUM (
    'MINIMAL',                       -- Minimal swarm (2-3 members)
    'SMALL',                         -- Small swarm (4-6 members)
    'MEDIUM',                        -- Medium swarm (7-12 members)
    'LARGE',                         -- Large swarm (13-25 members)
    'XLARGE',                        -- Extra large swarm (26+ members)
    'OPTIMAL',                       -- Optimal size determined
    'EXPANDED',                      -- Expanded beyond optimal
    'REDUCED'                        -- Reduced from optimal
);
COMMENT ON TYPE ai_core.expert_swarm_size IS 'Sizes of expert swarms for collaborative problem-solving';

-- Enum: SENTIMENT_ANALYSIS_DEPTH
-- Description: Defines depth levels of sentiment analysis
-- Business Case: Controls granularity of sentiment processing for accurate insights
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_depth AS ENUM (
    'SHALLOW',                       -- Shallow sentiment analysis
    'MODERATE',                      -- Moderate depth analysis
    'DEEP',                          -- Deep sentiment analysis
    'COMPREHENSIVE',                 -- Comprehensive analysis
    'SURFACE_LEVEL',                 -- Surface-level analysis
    'NUANCED',                       -- Nuanced sentiment analysis
    'CONTEXTUAL',                    -- Contextual sentiment analysis
    'MULTI_LAYERED'                  -- Multi-layered analysis
);
COMMENT ON TYPE ai_core.sentiment_analysis_depth IS 'Depth levels of sentiment analysis processing';

-- Enum: CMDB_SYNC_INTEGRATION_TYPE
-- Description: Defines types of CMDB synchronization integrations
-- Business Case: Categorizes different integration approaches for optimal selection
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_integration_type AS ENUM (
    'API_BASED',                     -- API-based integration
    'FILE_BASED',                    -- File-based integration
    'DATABASE_SYNC',                 -- Database synchronization
    'REAL_TIME_STREAM',              -- Real-time streaming
    'BATCH_PROCESSING',              -- Batch processing
    'WEBHOOK_BASED',                 -- Webhook-based integration
    'MESSAGE_QUEUE',                 -- Message queue integration
    'CUSTOM_ADAPTER'                 -- Custom adapter integration
);
COMMENT ON TYPE config_mgmt.cmdb_sync_integration_type IS 'Types of CMDB synchronization integrations';

-- Enum: CONFIGURATION_ITEM_DISCOVERY_METHOD
-- Description: Defines methods for discovering configuration items
-- Business Case: Categorizes different discovery techniques for comprehensive coverage
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_discovery_method AS ENUM (
    'AGENT_BASED',                   -- Agent-based discovery
    'AGENTLESS',                     -- Agentless discovery
    'NETWORK_SCAN',                  -- Network scanning discovery
    'API_INTEGRATION',               -- API-based discovery
    'MANUAL_ENTRY',                  -- Manual entry discovery
    'IMPORT_FROM_FILE',              -- Import from file discovery
    'SNMP_BASED',                    -- SNMP-based discovery
    'WMI_BASED'                      -- WMI-based discovery
);
COMMENT ON TYPE config_mgmt.configuration_item_discovery_method IS 'Methods for discovering configuration items';

-- Enum: SCENARIO_SIMULATION_RISK_LEVEL
-- Description: Defines risk levels of simulation scenarios
-- Business Case: Assesses potential impact of simulations for safe testing
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_risk_level AS ENUM (
    'ZERO_RISK',                     -- Zero risk simulation
    'LOW_RISK',                      -- Low risk simulation
    'MODERATE_RISK',                 -- Moderate risk simulation
    'HIGH_RISK',                     -- High risk simulation
    'CRITICAL_RISK',                 -- Critical risk simulation
    'ACCEPTABLE_RISK',               -- Acceptable risk level
    'UNACCEPTABLE_RISK',             -- Unacceptable risk level
    'MITIGATED_RISK'                 -- Mitigated risk level
);
COMMENT ON TYPE ai_core.scenario_simulation_risk_level IS 'Risk levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_VOLATILITY
-- Description: Defines volatility levels of satisfaction indices
-- Business Case: Measures stability of satisfaction measurements for reliable metrics
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_volatility AS ENUM (
    'STABLE',                        -- Stable index values
    'SLIGHTLY_VOLATILE',             -- Slightly volatile index
    'MODERATELY_VOLATILE',           -- Moderately volatile index
    'HIGHLY_VOLATILE',               -- Highly volatile index
    'EXTREMELY_VOLATILE',            -- Extremely volatile index
    'CONSISTENT',                    -- Consistent index values
    'FLUCTUATING',                   -- Fluctuating index values
    'PREDICTABLE'                    -- Predictable volatility pattern
);
COMMENT ON TYPE ai_core.satisfaction_index_volatility IS 'Volatility levels of satisfaction indices';

-- Enum: CORRELATION_STABILITY_METRIC
-- Description: Defines metrics for measuring correlation stability
-- Business Case: Assesses reliability of correlation findings for decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_stability_metric AS ENUM (
    'CONSISTENT',                    -- Consistently stable correlation
    'FLUCTUATING',                   -- Fluctuating stability
    'DETERIORATING',                 -- Deteriorating stability
    'IMPROVING',                     -- Improving stability
    'UNPREDICTABLE',                 -- Unpredictable stability
    'SEASONAL',                      -- Seasonal stability pattern
    'CYCLICAL',                      -- Cyclical stability pattern
    'TRANSIENT'                      -- Transient correlation stability
);
COMMENT ON TYPE ai_core.correlation_stability_metric IS 'Metrics for measuring correlation stability over time';

-- Enum: MODEL_PERFORMANCE_DEGRADATION
-- Description: Defines levels of ML model performance degradation
-- Business Case: Identifies when models need retraining for continued effectiveness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_degradation AS ENUM (
    'NONE',                          -- No performance degradation
    'MINIMAL',                       -- Minimal performance degradation
    'MODERATE',                      -- Moderate performance degradation
    'SIGNIFICANT',                   -- Significant performance degradation
    'SEVERE',                        -- Severe performance degradation
    'CRITICAL',                      -- Critical performance degradation
    'FAILED',                        -- Model has failed
    'REQUIRES_RETRAINING'            -- Model requires retraining
);
COMMENT ON TYPE ai_core.model_performance_degradation IS 'Levels of machine learning model performance degradation';

-- Enum: ANOMALY_DETECTION_ACCURACY
-- Description: Defines accuracy levels of anomaly detection
-- Business Case: Measures effectiveness of detection algorithms for system reliability
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_accuracy AS ENUM (
    'VERY_HIGH',                     -- Very high detection accuracy
    'HIGH',                          -- High detection accuracy
    'MODERATE',                      -- Moderate detection accuracy
    'LOW',                           -- Low detection accuracy
    'VERY_LOW',                      -- Very low detection accuracy
    'UNKNOWN',                       -- Accuracy unknown
    'UNRELIABLE',                    -- Unreliable detection
    'IMPROVING'                      -- Accuracy improving over time
);
COMMENT ON TYPE ai_core.anomaly_detection_accuracy IS 'Accuracy levels of anomaly detection systems';

-- Enum: AUTO_HEALING_COST_IMPACT
-- Description: Defines cost impact levels of auto-healing operations
-- Business Case: Evaluates economic impact of automated remediation for optimization
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_cost_impact AS ENUM (
    'NEGATIVE',                      -- Negative cost impact (savings)
    'ZERO',                          -- Zero cost impact
    'LOW',                           -- Low cost impact
    'MODERATE',                      -- Moderate cost impact
    'HIGH',                          -- High cost impact
    'VERY_HIGH',                     -- Very high cost impact
    'PROHIBITIVE',                   -- Prohibitive cost impact
    'BENEFICIAL'                     -- Beneficial cost impact
);
COMMENT ON TYPE ai_core.auto_healing_cost_impact IS 'Cost impact levels of auto-healing operations';

-- Enum: USER_FEEDBACK_QUALITY
-- Description: Defines quality levels of user feedback
-- Business Case: Assesses value of received feedback for improvement initiatives
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_quality AS ENUM (
    'EXCELLENT',                     -- Excellent quality feedback
    'GOOD',                          -- Good quality feedback
    'FAIR',                          -- Fair quality feedback
    'POOR',                          -- Poor quality feedback
    'SPAM',                          -- Spam or junk feedback
    'VAGUE',                         -- Vague or unclear feedback
    'HELPFUL',                       -- Helpful feedback
    'UNHELPFUL'                      -- Unhelpful feedback
);
COMMENT ON TYPE it_incident.user_feedback_quality IS 'Quality levels of user feedback received';

-- Enum: BLOCKCHAIN_VERIFICATION_COMPLEXITY
-- Description: Defines complexity levels of blockchain verification
-- Business Case: Assesses computational requirements for verification processes
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_verification_complexity AS ENUM (
    'SIMPLE',                        -- Simple verification process
    'MODERATE',                      -- Moderate complexity verification
    'COMPLEX',                       -- Complex verification process
    'VERY_COMPLEX',                  -- Very complex verification
    'COMPUTE_INTENSIVE',             -- Compute-intensive verification
    'LIGHTWEIGHT',                   -- Lightweight verification
    'ENTERPRISE_GRADE',              -- Enterprise-grade verification
    'CUSTOM_COMPLEXITY'              -- Custom complexity level
);
COMMENT ON TYPE sec_audit.blockchain_verification_complexity IS 'Complexity levels of blockchain verification processes';

-- Enum: METERING_DATA_INTEGRITY_LEVEL
-- Description: Defines integrity levels of metering data
-- Business Case: Assesses trustworthiness of collected metrics for accurate analysis
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_integrity_level AS ENUM (
    'CERTIFIED',                     -- Certified data integrity
    'VERIFIED',                      -- Verified data integrity
    'TRUSTED',                       -- Trusted data integrity
    'RELIABLE',                      -- Reliable data integrity
    'QUESTIONABLE',                  -- Questionable data integrity
    'UNVERIFIED',                    -- Unverified data integrity
    'COMPROMISED',                   -- Compromised data integrity
    'UNCERTAIN'                      -- Uncertain data integrity
);
COMMENT ON TYPE it_incident.metering_data_integrity_level IS 'Integrity levels of metering data';

-- Enum: AUDIT_LOG_CORRELATION_LEVEL
-- Description: Defines correlation levels for audit log analysis
-- Business Case: Groups related audit events for analysis and investigation
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_correlation_level AS ENUM (
    'HIGH',                          -- High correlation level
    'MODERATE',                      -- Moderate correlation level
    'LOW',                           -- Low correlation level
    'NONE',                          -- No correlation
    'STRONG',                        -- Strong correlation
    'WEAK',                          -- Weak correlation
    'SIGNIFICANT',                   -- Significant correlation
    'INSIGNIFICANT'                  -- Insignificant correlation
);
COMMENT ON TYPE it_incident.audit_log_correlation_level IS 'Correlation levels for audit log analysis';

-- Enum: CHATBOT_TRAINING_COVERAGE
-- Description: Defines coverage levels of chatbot training
-- Business Case: Measures comprehensiveness of training data for model performance
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_coverage AS ENUM (
    'COMPREHENSIVE',                 -- Comprehensive training coverage
    'EXTENSIVE',                     -- Extensive training coverage
    'ADEQUATE',                      -- Adequate training coverage
    'LIMITED',                       -- Limited training coverage
    'INSUFFICIENT',                  -- Insufficient training coverage
    'GAPS_IDENTIFIED',               -- Coverage gaps identified
    'OPTIMAL',                       -- Optimal training coverage
    'OVERFITTING_RISK'               -- Risk of overfitting exists
);
COMMENT ON TYPE ai_core.chatbot_training_coverage IS 'Coverage levels of chatbot training data';

-- Enum: AR_SCENE_LOADING_STRATEGY
-- Description: Defines loading strategies for AR scenes
-- Business Case: Optimizes scene loading for different scenarios and device capabilities
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_loading_strategy AS ENUM (
    'PRELOAD_ALL',                   -- Preload all scene elements
    'LAZY_LOADING',                  -- Lazy loading approach
    'PROGRESSIVE_LOADING',           -- Progressive loading
    'STREAMING',                     -- Streaming approach
    'CACHED_LOADING',                -- Cached loading approach
    'ON_DEMAND',                     -- On-demand loading
    'PREFETCHING',                   -- Prefetching strategy
    'INCREMENTAL_LOADING'            -- Incremental loading approach
);
COMMENT ON TYPE ai_core.ar_scene_loading_strategy IS 'Loading strategies for augmented reality scenes';

-- Enum: FEATURE_DEPENDENCY_LEVEL
-- Description: Defines dependency levels of ML features
-- Business Case: Tracks interdependencies between features for model maintenance
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_dependency_level AS ENUM (
    'INDEPENDENT',                   -- Independent feature
    'WEAKLY_DEPENDENT',              -- Weakly dependent feature
    'MODERATELY_DEPENDENT',          -- Moderately dependent
    'STRONGLY_DEPENDENT',            -- Strongly dependent feature
    'CRITICALLY_DEPENDENT',          -- Critically dependent
    'OPTIONALLY_DEPENDENT',          -- Optionally dependent
    'CONDITIONALLY_DEPENDENT',       -- Conditionally dependent
    'REQUIRED_DEPENDENCY'            -- Required dependency
);
COMMENT ON TYPE ai_core.feature_dependency_level IS 'Dependency levels of machine learning features';

-- Enum: MODEL_TRAINING_EFFICIENCY
-- Description: Defines efficiency levels of model training
-- Business Case: Measures resource utilization during training for cost optimization
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_efficiency AS ENUM (
    'VERY_EFFICIENT',                -- Very efficient training
    'EFFICIENT',                     -- Efficient training
    'MODERATELY_EFFICIENT',          -- Moderately efficient
    'INEFFICIENT',                   -- Inefficient training
    'VERY_WASTEFUL',                 -- Very wasteful of resources
    'OPTIMAL',                       -- Optimal training efficiency
    'SUB_OPTIMAL',                   -- Sub-optimal efficiency
    'RESOURCE_HEAVY'                 -- Heavy resource consumption
);
COMMENT ON TYPE ai_core.model_training_efficiency IS 'Efficiency levels of machine learning model training';

-- Enum: ANOMALY_DETECTION_LATENCY
-- Description: Defines latency levels of anomaly detection
-- Business Case: Measures response time of detection systems for timely intervention
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_latency AS ENUM (
    'REAL_TIME',                     -- Real-time detection
    'NEAR_REAL_TIME',                -- Near real-time detection
    'LOW_LATENCY',                   -- Low latency detection
    'MEDIUM_LATENCY',                -- Medium latency detection
    'HIGH_LATENCY',                  -- High latency detection
    'DELAYED',                       -- Delayed detection
    'BATCH_PROCESSING',              -- Batch processing detection
    'ASYNC_PROCESSING'               -- Asynchronous processing
);
COMMENT ON TYPE ai_core.anomaly_detection_latency IS 'Latency levels of anomaly detection systems';

-- Enum: AUTO_HEALING_RESOURCE_UTILIZATION
-- Description: Defines resource utilization levels during healing
-- Business Case: Measures system overhead of auto-healing for performance optimization
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_resource_utilization AS ENUM (
    'MINIMAL',                       -- Minimal resource utilization
    'LOW',                           -- Low resource utilization
    'MODERATE',                      -- Moderate resource utilization
    'HIGH',                          -- High resource utilization
    'VERY_HIGH',                     -- Very high resource utilization
    'OPTIMAL',                       -- Optimal resource utilization
    'INEFFICIENT',                   -- Inefficient resource utilization
    'OVERWHELMING'                   -- Overwhelming resource utilization
);
COMMENT ON TYPE ai_core.auto_healing_resource_utilization IS 'Resource utilization levels during auto-healing operations';

-- Enum: USER_FEEDBACK_ACTIONABILITY
-- Description: Defines actionability levels of user feedback
-- Business Case: Prioritizes feedback based on implementability for effective response
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_actionability AS ENUM (
    'IMMEDIATELY_ACTIONABLE',        -- Can be acted upon immediately
    'HIGHLY_ACTIONABLE',             -- Highly actionable feedback
    'MODERATELY_ACTIONABLE',         -- Moderately actionable
    'SLIGHTLY_ACTIONABLE',           -- Slightly actionable
    'NOT_ACTIONABLE',                -- Not actionable currently
    'FUTURE_CONSIDERATION',          -- For future consideration
    'IMPLEMENTABLE',                 -- Implementable feedback
    'THEORETICAL'                    -- Theoretical feedback only
);
COMMENT ON TYPE it_incident.user_feedback_actionability IS 'Actionability levels of user feedback';

-- Enum: BLOCKCHAIN_TRANSPARENCY_LEVEL
-- Description: Defines transparency levels of blockchain operations
-- Business Case: Controls visibility of blockchain data for privacy and security
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transparency_level AS ENUM (
    'FULLY_PUBLIC',                  -- Fully public blockchain
    'PUBLIC_READ_PRIVATE_WRITE',     -- Public read, private write
    'PRIVATE_READ_PRIVATE_WRITE',    -- Private blockchain
    'CONSORTIUM',                    -- Consortium blockchain
    'HYBRID',                        -- Hybrid transparency model
    'SELECTIVE',                     -- Selective transparency
    'ROLE_BASED',                    -- Role-based transparency
    'CUSTOM_ACCESS'                  -- Custom access controls
);
COMMENT ON TYPE sec_audit.blockchain_transparency_level IS 'Transparency levels of blockchain operations';

-- Enum: METERING_DATA_SAMPLING_RATE
-- Description: Defines sampling rates for metering data collection
-- Business Case: Balances data granularity with storage costs for optimal monitoring
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_sampling_rate AS ENUM (
    'CONTINUOUS',                    -- Continuous sampling
    'HIGH_FREQUENCY',                -- High frequency sampling
    'MEDIUM_FREQUENCY',              -- Medium frequency sampling
    'LOW_FREQUENCY',                 -- Low frequency sampling
    'SCHEDULED_SAMPLING',            -- Scheduled sampling
    'EVENT_TRIGGERED',               -- Event-triggered sampling
    'ADAPTIVE_SAMPLING',             -- Adaptive sampling rate
    'REDUCED_SAMPLING'               -- Reduced sampling rate
);
COMMENT ON TYPE it_incident.metering_data_sampling_rate IS 'Sampling rates for metering data collection';

-- Enum: AUDIT_LOG_RETENTION_PERIOD
-- Description: Defines retention periods for audit logs
-- Business Case: Balances compliance needs with storage costs for regulatory requirements
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_retention_period AS ENUM (
    'SHORT_TERM',                    -- Short-term retention (days-weeks)
    'MEDIUM_TERM',                   -- Medium-term retention (weeks-months)
    'LONG_TERM',                     -- Long-term retention (months-years)
    'COMPLIANCE_MANDATED',           -- Compliance-mandated retention
    'LEGAL_RETENTION',               -- Legal retention period
    'ARCHIVAL_LONG_TERM',            -- Archival long-term retention
    'ROTATING_CYCLE',                -- Rotating retention cycle
    'CUSTOM_RETENTION'               -- Custom retention period
);
COMMENT ON TYPE it_incident.audit_log_retention_period IS 'Retention periods for audit logs';

-- Enum: CHATBOT_TRAINING_ADAPTIVENESS
-- Description: Defines adaptiveness levels of chatbot training
-- Business Case: Measures ability to adapt to changing needs for continuous improvement
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_adaptiveness AS ENUM (
    'HIGHLY_ADAPTIVE',               -- Highly adaptive to changes
    'ADAPTIVE',                      -- Adaptive to changes
    'MODERATELY_ADAPTIVE',           -- Moderately adaptive
    'SLOWLY_ADAPTIVE',               -- Slowly adaptive
    'RIGID',                         -- Rigid, non-adaptive
    'STATIC',                        -- Static training approach
    'DYNAMIC',                       -- Dynamic adaptation capability
    'EVOLVING'                       -- Continuously evolving approach
);
COMMENT ON TYPE ai_core.chatbot_training_adaptiveness IS 'Adaptiveness levels of chatbot training systems';

-- Enum: AR_SCENE_COMPLEXITY_OPTIMIZATION
-- Description: Defines optimization approaches for AR scene complexity
-- Business Case: Balances visual complexity with performance for optimal user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_complexity_optimization AS ENUM (
    'PERFORMANCE_FIRST',             -- Performance-first optimization
    'QUALITY_FIRST',                 -- Quality-first optimization
    'BALANCED_OPTIMIZATION',         -- Balanced approach
    'DEVICE_ADAPTIVE',               -- Device-adaptive optimization
    'USER_PREFERENCE',               -- User preference based
    'CONTEXT_AWARE',                 -- Context-aware optimization
    'ENERGY_EFFICIENT',              -- Energy-efficient optimization
    'CUSTOM_OPTIMIZATION'            -- Custom optimization approach
);
COMMENT ON TYPE ai_core.ar_scene_complexity_optimization IS 'Optimization approaches for AR scene complexity';

-- Enum: FEATURE_LIFESPAN_DURATION
-- Description: Defines expected lifespans of ML features
-- Business Case: Plans for feature obsolescence and updates for maintenance planning
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_lifespan_duration AS ENUM (
    'PERMANENT',                     -- Permanent feature
    'LONG_TERM',                     -- Long-term feature (>1 year)
    'MEDIUM_TERM',                   -- Medium-term feature (3-12 months)
    'SHORT_TERM',                    -- Short-term feature (<3 months)
    'TEMPORARY',                     -- Temporary feature
    'EXPERIMENTAL',                  -- Experimental feature
    'SEASONAL',                      -- Seasonal feature
    'CYCLICAL'                       -- Cyclically recurring feature
);
COMMENT ON TYPE ai_core.feature_lifespan_duration IS 'Expected lifespans of machine learning features';

-- Enum: WORKFLOW_EXECUTION_COMPLEXITY
-- Description: Defines complexity levels of workflow execution
-- Business Case: Categorizes workflows by implementation difficulty for resource planning
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_complexity AS ENUM (
    'TRIVIAL',                       -- Trivial execution complexity
    'SIMPLE',                        -- Simple execution complexity
    'MODERATE',                      -- Moderate complexity
    'COMPLEX',                       -- Complex execution
    'VERY_COMPLEX',                  -- Very complex execution
    'EXTREMELY_COMPLEX',             -- Extremely complex execution
    'INDUSTRY_STANDARD',             -- Industry-standard complexity
    'CUSTOM_COMPLEXITY'              -- Custom complexity level
);
COMMENT ON TYPE ai_core.workflow_execution_complexity IS 'Complexity levels of workflow execution';

-- Enum: SIMULATION_SCENARIO_IMPACT
-- Description: Defines impact levels of simulation scenarios
-- Business Case: Assesses potential effects of simulations for strategic planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_scenario_impact AS ENUM (
    'MINIMAL_IMPACT',                -- Minimal impact scenario
    'LOW_IMPACT',                    -- Low impact scenario
    'MODERATE_IMPACT',               -- Moderate impact scenario
    'HIGH_IMPACT',                   -- High impact scenario
    'CRITICAL_IMPACT',               -- Critical impact scenario
    'BENEFICIAL_IMPACT',             -- Beneficial impact scenario
    'RISKY_IMPACT',                  -- Risky impact scenario
    'TRANSFORMATIVE_IMPACT'          -- Transformative impact scenario
);
COMMENT ON TYPE ai_core.simulation_scenario_impact IS 'Impact levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_ACCURACY
-- Description: Defines accuracy levels of satisfaction indices
-- Business Case: Measures reliability of satisfaction measurements for trustworthiness
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_accuracy AS ENUM (
    'VERY_HIGH_ACCURACY',            -- Very high accuracy measurement
    'HIGH_ACCURACY',                 -- High accuracy measurement
    'MODERATE_ACCURACY',             -- Moderate accuracy measurement
    'LOW_ACCURACY',                  -- Low accuracy measurement
    'VERY_LOW_ACCURACY',             -- Very low accuracy measurement
    'ESTIMATED_ACCURACY',            -- Estimated accuracy level
    'CONFIDENCE_BASED',              -- Confidence-based accuracy
    'PROVISIONAL_ACCURACY'           -- Provisional accuracy assessment
);
COMMENT ON TYPE ai_core.satisfaction_index_accuracy IS 'Accuracy levels of satisfaction index measurements';

-- Enum: CORRELATION_LONGEVITY
-- Description: Defines longevity of statistical correlations
-- Business Case: Assesses durability of correlation relationships over time
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_longevity AS ENUM (
    'PERMANENT',                     -- Permanent correlation
    'LONG_LASTING',                  -- Long-lasting correlation
    'MODERATE_DURATION',             -- Moderate duration correlation
    'SHORT_LIVED',                   -- Short-lived correlation
    'TEMPORARY',                     -- Temporary correlation
    'SEASONAL',                      -- Seasonal correlation
    'CYCLICAL',                      -- Cyclically occurring correlation
    'TRANSIENT'                      -- Transient correlation
);
COMMENT ON TYPE ai_core.correlation_longevity IS 'Longevity of statistical correlations over time';

-- Enum: MODEL_ROLLBACK_COMPLEXITY
-- Description: Defines complexity levels of model rollbacks
-- Business Case: Assesses difficulty of rollback procedures for operational planning
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_complexity AS ENUM (
    'TRIVIAL',                       -- Trivial rollback complexity
    'SIMPLE',                        -- Simple rollback complexity
    'MODERATE',                      -- Moderate complexity
    'COMPLEX',                       -- Complex rollback procedure
    'VERY_COMPLEX',                  -- Very complex rollback
    'EXTREMELY_COMPLEX',             -- Extremely complex rollback
    'INDUSTRY_STANDARD',             -- Industry-standard complexity
    'CUSTOM_COMPLEXITY'              -- Custom complexity level
);
COMMENT ON TYPE ai_core.model_rollback_complexity IS 'Complexity levels of machine learning model rollbacks';

-- Enum: TRAINING_DATA_DIVERSITY
-- Description: Defines diversity levels of training datasets
-- Business Case: Ensures comprehensive coverage of scenarios for robust model performance
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_diversity AS ENUM (
    'HIGHLY_DIVERSE',                -- Highly diverse dataset
    'DIVERSE',                       -- Diverse dataset
    'MODERATELY_DIVERSE',            -- Moderately diverse
    'LIMITED_DIVERSE',               -- Limited diversity
    'HOMOGENEOUS',                   -- Homogeneous dataset
    'SPECIALIZED',                   -- Specialized dataset
    'GENERALIZED',                   -- Generalized dataset
    'BIASED_TOWARD_DOMAIN'           -- Biased toward specific domain
);
COMMENT ON TYPE ai_core.training_data_diversity IS 'Diversity levels of training datasets';

-- Enum: EXPERT_SWARM_COLLABORATION_STYLE
-- Description: Defines collaboration styles in expert swarms
-- Business Case: Optimizes team dynamics for problem-solving effectiveness
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_collaboration_style AS ENUM (
    'CONSENSUS_DRIVEN',              -- Consensus-driven collaboration
    'LEADER_DRIVEN',                 -- Leader-driven collaboration
    'EQUAL_PARTICIPATION',           -- Equal participation style
    'SPECIALIST_FOCUSED',            -- Specialist-focused collaboration
    'AGILE_METHODOLOGY',             -- Agile methodology approach
    'TRADITIONAL_HIERARCHY',         -- Traditional hierarchy approach
    'PEER_TO_PEER',                  -- Peer-to-peer collaboration
    'HYBRID_APPROACH'                -- Hybrid collaboration approach
);
COMMENT ON TYPE ai_core.expert_swarm_collaboration_style IS 'Collaboration styles in expert swarms';

-- Enum: SENTIMENT_ANALYSIS_SCOPE_DEPTH
-- Description: Defines scope depth of sentiment analysis
-- Business Case: Controls breadth and depth of sentiment processing for insights
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_scope_depth AS ENUM (
    'SURFACE_LEVEL',                 -- Surface-level analysis
    'DEEP_SENTIMENT',                -- Deep sentiment analysis
    'COMPREHENSIVE',                 -- Comprehensive analysis
    'CONTEXTUAL',                    -- Contextual sentiment analysis
    'NUANCED',                       -- Nuanced sentiment analysis
    'MULTI_DIMENSIONAL',             -- Multi-dimensional analysis
    'GRANULAR',                      -- Granular sentiment analysis
    'HOLISTIC'                       -- Holistic sentiment analysis
);
COMMENT ON TYPE ai_core.sentiment_analysis_scope_depth IS 'Scope depth of sentiment analysis processing';

-- Enum: CMDB_SYNC_DATA_QUALITY
-- Description: Defines quality levels of CMDB synchronization data
-- Business Case: Assesses reliability of synchronized information for accuracy
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_data_quality AS ENUM (
    'EXCELLENT',                     -- Excellent data quality
    'GOOD',                          -- Good data quality
    'FAIR',                          -- Fair data quality
    'POOR',                          -- Poor data quality
    'INCONSISTENT',                  -- Inconsistent data quality
    'INCOMPLETE',                    -- Incomplete data quality
    'ACCURATE',                      -- Accurate data quality
    'RELIABLE'                       -- Reliable data quality
);
COMMENT ON TYPE config_mgmt.cmdb_sync_data_quality IS 'Quality levels of CMDB synchronization data';

-- Enum: CONFIGURATION_ITEM_CHANGE_IMPACT
-- Description: Defines impact levels of configuration item changes
-- Business Case: Assesses potential effects of configuration changes for risk management
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_change_impact AS ENUM (
    'MINIMAL_IMPACT',                -- Minimal change impact
    'LOW_IMPACT',                    -- Low change impact
    'MODERATE_IMPACT',               -- Moderate change impact
    'HIGH_IMPACT',                   -- High change impact
    'CRITICAL_IMPACT',               -- Critical change impact
    'BENEFICIAL_IMPACT',             -- Beneficial change impact
    'RISKY_IMPACT',                  -- Risky change impact
    'TRANSFORMATIVE_IMPACT'          -- Transformative change impact
);
COMMENT ON TYPE config_mgmt.configuration_item_change_impact IS 'Impact levels of configuration item changes';

-- Enum: SCENARIO_SIMULATION_PRECISION
-- Description: Defines precision levels of simulation scenarios
-- Business Case: Controls accuracy of simulation modeling for reliable results
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_precision AS ENUM (
    'HIGH_PRECISION',                -- High precision simulation
    'MODERATE_PRECISION',            -- Moderate precision simulation
    'LOW_PRECISION',                 -- Low precision simulation
    'APPROXIMATE',                   -- Approximate simulation
    'ROUGH_ESTIMATE',                -- Rough estimate simulation
    'DETAILED',                      -- Detailed simulation
    'ACCURATE',                      -- Accurate simulation
    'PRECISION_OPTIMIZED'            -- Precision-optimized simulation
);
COMMENT ON TYPE ai_core.scenario_simulation_precision IS 'Precision levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_SENSITIVITY
-- Description: Defines sensitivity levels of satisfaction indices
-- Business Case: Measures responsiveness to changes for accurate monitoring
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_sensitivity AS ENUM (
    'HIGHLY_SENSITIVE',              -- Highly sensitive to changes
    'SENSITIVE',                     -- Sensitive to changes
    'MODERATELY_SENSITIVE',          -- Moderately sensitive
    'SLIGHTLY_SENSITIVE',            -- Slightly sensitive
    'INSULATED',                     -- Insulated from changes
    'STABLE',                        -- Stable regardless of changes
    'ADAPTIVE_SENSITIVITY',          -- Adaptive sensitivity level
    'FIXED_SENSITIVITY'              -- Fixed sensitivity level
);
COMMENT ON TYPE ai_core.satisfaction_index_sensitivity IS 'Sensitivity levels of satisfaction indices';

-- Enum: CORRELATION_BUSINESS_RELEVANCE
-- Description: Defines business relevance of statistical correlations
-- Business Case: Assesses practical value of correlation findings for decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_business_relevance AS ENUM (
    'CRITICALLY_RELEVANT',           -- Critically relevant to business
    'HIGHLY_RELEVANT',               -- Highly relevant to business
    'MODERATELY_RELEVANT',           -- Moderately relevant
    'SLIGHTLY_RELEVANT',             -- Slightly relevant
    'NOT_RELEVANT',                  -- Not relevant to business
    'ACADEMICALLY_INTERESTING',      -- Academically interesting only
    'THEORETICALLY_USEFUL',          -- Theoretically useful
    'PRACTICALLY_VALUABLE'           -- Practically valuable correlation
);
COMMENT ON TYPE ai_core.correlation_business_relevance IS 'Business relevance of statistical correlations';

-- Enum: MODEL_PERFORMANCE_MONITORING_INTENSITY
-- Description: Defines intensity levels of model performance monitoring
-- Business Case: Controls frequency and depth of monitoring for optimal oversight
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_monitoring_intensity AS ENUM (
    'CONTINUOUS',                    -- Continuous monitoring
    'HIGH_INTENSITY',                -- High intensity monitoring
    'MODERATE_INTENSITY',            -- Moderate intensity monitoring
    'LOW_INTENSITY',                 -- Low intensity monitoring
    'PERIODIC',                      -- Periodic monitoring
    'EVENT_DRIVEN',                  -- Event-driven monitoring
    'PROACTIVE',                     -- Proactive monitoring
    'REACTIVE'                       -- Reactive monitoring
);
COMMENT ON TYPE ai_core.model_performance_monitoring_intensity IS 'Intensity levels of model performance monitoring';

-- Enum: ANOMALY_DETECTION_COVERAGE
-- Description: Defines coverage levels of anomaly detection systems
-- Business Case: Measures comprehensiveness of monitoring for system reliability
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_coverage AS ENUM (
    'COMPREHENSIVE',                 -- Comprehensive coverage
    'EXTENSIVE',                     -- Extensive coverage
    'ADEQUATE',                      -- Adequate coverage
    'LIMITED',                       -- Limited coverage
    'TARGETED',                      -- Targeted coverage
    'SELECTIVE',                     -- Selective coverage
    'BROAD',                         -- Broad coverage
    'SPECIFIC'                       -- Specific coverage focus
);
COMMENT ON TYPE ai_core.anomaly_detection_coverage IS 'Coverage levels of anomaly detection systems';

-- Enum: AUTO_HEALING_EFFECTIVENESS
-- Description: Defines effectiveness levels of auto-healing operations
-- Business Case: Measures success of automated remediation for operational efficiency
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_effectiveness AS ENUM (
    'HIGHLY_EFFECTIVE',              -- Highly effective healing
    'EFFECTIVE',                     -- Effective healing
    'MODERATELY_EFFECTIVE',          -- Moderately effective
    'SLIGHTLY_EFFECTIVE',            -- Slightly effective
    'INEFFECTIVE',                   -- Ineffective healing
    'COUNTER_PRODUCTIVE',            -- Counter-productive healing
    'SUCCESSFUL',                    -- Successful healing
    'UNSUCCESSFUL'                   -- Unsuccessful healing
);
COMMENT ON TYPE ai_core.auto_healing_effectiveness IS 'Effectiveness levels of auto-healing operations';

-- Enum: USER_FEEDBACK_INFLUENCE
-- Description: Defines influence levels of user feedback
-- Business Case: Measures impact of feedback on decisions for strategic planning
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_influence AS ENUM (
    'HIGH_INFLUENCE',                -- High influence on decisions
    'MODERATE_INFLUENCE',            -- Moderate influence on decisions
    'LOW_INFLUENCE',                 -- Low influence on decisions
    'NO_INFLUENCE',                  -- No influence on decisions
    'DECISION_DRIVING',              -- Decision-driving influence
    'INFORMATIVE',                   -- Informative influence only
    'STRATEGIC',                     -- Strategic influence
    'OPERATIONAL'                    -- Operational influence
);
COMMENT ON TYPE it_incident.user_feedback_influence IS 'Influence levels of user feedback on business decisions';

-- Enum: BLOCKCHAIN_TRANSACTION_COMPLEXITY
-- Description: Defines complexity levels of blockchain transactions
-- Business Case: Assesses processing requirements for transactions for performance
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_complexity AS ENUM (
    'SIMPLE',                        -- Simple transaction complexity
    'MODERATE',                      -- Moderate complexity transaction
    'COMPLEX',                       -- Complex transaction
    'VERY_COMPLEX',                  -- Very complex transaction
    'SMART_CONTRACT',                -- Smart contract complexity
    'MULTI_SIGNATURE',               -- Multi-signature complexity
    'CROSS_CHAIN',                   -- Cross-chain complexity
    'ENTERPRISE_GRADE'               -- Enterprise-grade complexity
);
COMMENT ON TYPE sec_audit.blockchain_transaction_complexity IS 'Complexity levels of blockchain transactions';

-- Enum: METERING_DATA_PROCESSING_INTENSITY
-- Description: Defines processing intensity levels for metering data
-- Business Case: Optimizes resource allocation for data processing efficiency
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_processing_intensity AS ENUM (
    'LIGHTWEIGHT',                   -- Lightweight processing
    'MODERATE',                      -- Moderate processing intensity
    'HEAVY',                         -- Heavy processing intensity
    'COMPUTE_INTENSIVE',             -- Compute-intensive processing
    'REAL_TIME',                     -- Real-time processing intensity
    'BATCH',                         -- Batch processing intensity
    'STREAMING',                     -- Streaming processing intensity
    'ANALYTICAL'                     -- Analytical processing intensity
);
COMMENT ON TYPE it_incident.metering_data_processing_intensity IS 'Processing intensity levels for metering data';

-- Enum: AUDIT_LOG_CRITICALITY
-- Description: Defines criticality levels of audit log entries
-- Business Case: Prioritizes audit log processing and review for security
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_criticality AS ENUM (
    'CRITICAL',                      -- Critical audit event
    'HIGH',                          -- High criticality event
    'MEDIUM',                        -- Medium criticality event
    'LOW',                           -- Low criticality event
    'INFORMATIONAL',                 -- Informational event
    'COMPLIANCE',                    -- Compliance-related event
    'SECURITY',                      -- Security-related event
    'OPERATIONAL'                    -- Operational event
);
COMMENT ON TYPE it_incident.audit_log_criticality IS 'Criticality levels of audit log entries';

-- Enum: CHATBOT_TRAINING_INNOVATION_LEVEL
-- Description: Defines innovation levels in chatbot training
-- Business Case: Measures advancement in training approaches for competitive advantage
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_innovation_level AS ENUM (
    'REVOLUTIONARY',                 -- Revolutionary training innovation
    'INNOVATIVE',                    -- Innovative training approach
    'IMPROVED',                      -- Improved training method
    'CONVENTIONAL',                  -- Conventional training approach
    'TRADITIONAL',                   -- Traditional training method
    'EXPERIMENTAL',                  -- Experimental training approach
    'ADVANCED',                      -- Advanced training technique
    'STATE_OF_THE_ART'               -- State-of-the-art training method
);
COMMENT ON TYPE ai_core.chatbot_training_innovation_level IS 'Innovation levels in chatbot training approaches';

-- Enum: AR_SCENE_VISUAL_COMPLEXITY
-- Description: Defines visual complexity levels of AR scenes
-- Business Case: Balances visual richness with performance for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_visual_complexity AS ENUM (
    'MINIMAL',                       -- Minimal visual complexity
    'LOW',                           -- Low visual complexity
    'MODERATE',                      -- Moderate visual complexity
    'HIGH',                          -- High visual complexity
    'VERY_HIGH',                     -- Very high visual complexity
    'ULTRA_HIGH',                    -- Ultra-high visual complexity
    'SIMPLIFIED',                    -- Simplified visual approach
    'ENHANCED_GRAPHICS'              -- Enhanced graphics complexity
);
COMMENT ON TYPE ai_core.ar_scene_visual_complexity IS 'Visual complexity levels of augmented reality scenes';

-- Enum: FEATURE_EVOLUTION_RATE
-- Description: Defines evolution rates of ML features
-- Business Case: Tracks how quickly features become outdated for maintenance planning
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_evolution_rate AS ENUM (
    'RAPIDLY_EVOLVING',              -- Rapidly evolving feature
    'MODERATELY_EVOLVING',           -- Moderately evolving feature
    'SLOWLY_EVOLVING',               -- Slowly evolving feature
    'STABLE',                        -- Stable feature
    'DEPRECATED',                    -- Deprecated feature
    'EMERGING',                      -- Emerging feature
    'MATURING',                      -- Maturing feature
    'STANDARDIZED'                   -- Standardized feature
);
COMMENT ON TYPE ai_core.feature_evolution_rate IS 'Evolution rates of machine learning features';

-- Enum: MODEL_TRAINING_CONVERGENCE_SPEED
-- Description: Defines convergence speeds of model training
-- Business Case: Measures efficiency of training algorithms for optimization
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_convergence_speed AS ENUM (
    'VERY_FAST',                     -- Very fast convergence
    'FAST',                          -- Fast convergence
    'MODERATE',                      -- Moderate convergence speed
    'SLOW',                          -- Slow convergence
    'VERY_SLOW',                     -- Very slow convergence
    'NO_CONVERGENCE',                -- No convergence achieved
    'INSTANT',                       -- Instant convergence
    'GRADUAL_CONVERGENCE'            -- Gradual convergence pattern
);
COMMENT ON TYPE ai_core.model_training_convergence_speed IS 'Convergence speeds of machine learning model training';

-- Enum: ANOMALY_DETECTION_SENSITIVITY
-- Description: Defines sensitivity levels of anomaly detection
-- Business Case: Balances false positive rate with detection accuracy for reliability
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_sensitivity AS ENUM (
    'VERY_HIGH_SENSITIVITY',         -- Very high sensitivity
    'HIGH_SENSITIVITY',              -- High sensitivity
    'MODERATE_SENSITIVITY',          -- Moderate sensitivity
    'LOW_SENSITIVITY',               -- Low sensitivity
    'VERY_LOW_SENSITIVITY',          -- Very low sensitivity
    'ADAPTIVE_SENSITIVITY',          -- Adaptive sensitivity level
    'OPTIMAL_SENSITIVITY',           -- Optimal sensitivity setting
    'CUSTOM_SENSITIVITY'             -- Custom sensitivity level
);
COMMENT ON TYPE ai_core.anomaly_detection_sensitivity IS 'Sensitivity levels of anomaly detection systems';

-- Enum: AUTO_HEALING_RELIABILITY
-- Description: Defines reliability levels of auto-healing operations
-- Business Case: Measures dependability of automated remediation for trustworthiness
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_reliability AS ENUM (
    'VERY_RELIABLE',                 -- Very reliable healing
    'RELIABLE',                      -- Reliable healing
    'MODERATELY_RELIABLE',           -- Moderately reliable
    'UNRELIABLE',                    -- Unreliable healing
    'VERY_UNRELIABLE',               -- Very unreliable healing
    'TESTING_PHASE',                 -- Testing phase reliability
    'PRODUCTION_READY',              -- Production-ready reliability
    'ENTERPRISE_GRADE'               -- Enterprise-grade reliability
);
COMMENT ON TYPE ai_core.auto_healing_reliability IS 'Reliability levels of auto-healing operations';

-- Enum: USER_FEEDBACK_QUALITY_SCORE
-- Description: Defines quality score levels for user feedback
-- Business Case: Quantifies value of received feedback for prioritization
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_quality_score AS ENUM (
    'EXCELLENT_SCORE',               -- Excellent quality score
    'GOOD_SCORE',                    -- Good quality score
    'FAIR_SCORE',                    -- Fair quality score
    'POOR_SCORE',                    -- Poor quality score
    'INVALID_SCORE',                 -- Invalid quality score
    'NOT_APPLICABLE',                -- Not applicable score
    'PENDING_ASSESSMENT',            -- Pending assessment score
    'HIGHEST_POSSIBLE'               -- Highest possible quality score
);
COMMENT ON TYPE it_incident.user_feedback_quality_score IS 'Quality score levels for user feedback';

-- Enum: BLOCKCHAIN_SCALABILITY_FACTOR
-- Description: Defines scalability factors of blockchain implementations
-- Business Case: Measures ability to handle increased load for growth planning
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_scalability_factor AS ENUM (
    'HIGHLY_SCALABLE',               -- Highly scalable implementation
    'SCALABLE',                      -- Scalable implementation
    'MODERATELY_SCALABLE',           -- Moderately scalable
    'LIMITED_SCALABILITY',           -- Limited scalability
    'NOT_SCALABLE',                  -- Not scalable implementation
    'VERTICALLY_SCALABLE',           -- Vertically scalable
    'HORIZONTALLY_SCALABLE',         -- Horizontally scalable
    'ELASTIC_SCALABILITY'            -- Elastic scalability factor
);
COMMENT ON TYPE sec_audit.blockchain_scalability_factor IS 'Scalability factors of blockchain implementations';

-- Enum: METERING_DATA_COMPRESSION_LEVEL
-- Description: Defines compression levels for metering data
-- Business Case: Optimizes storage and transmission costs for efficiency
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_compression_level AS ENUM (
    'NO_COMPRESSION',                -- No compression applied
    'LIGHT_COMPRESSION',             -- Light compression level
    'MODERATE_COMPRESSION',          -- Moderate compression
    'HIGH_COMPRESSION',              -- High compression level
    'MAXIMUM_COMPRESSION',           -- Maximum compression
    'LOSSLESS',                      -- Lossless compression
    'LOSSY',                         -- Lossy compression
    'ADAPTIVE_COMPRESSION'           -- Adaptive compression level
);
COMMENT ON TYPE it_incident.metering_data_compression_level IS 'Compression levels for metering data';

-- Enum: AUDIT_LOG_INTEGRITY_LEVEL
-- Description: Defines integrity levels of audit logs
-- Business Case: Ensures trustworthiness of audit records for compliance
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_integrity_level AS ENUM (
    'IMMUTABLE',                     -- Immutable audit logs
    'CRYPTOGRAPHICALLY_SECURE',      -- Cryptographically secure
    'VERIFIABLE',                    -- Verifiable audit logs
    'TRUSTED',                       -- Trusted audit logs
    'MODERATE_SECURITY',             -- Moderate security level
    'BASIC_SECURITY',                -- Basic security level
    'ENCRYPTED',                     -- Encrypted audit logs
    'BLOCKCHAIN_SECURED'             -- Blockchain-secured logs
);
COMMENT ON TYPE it_incident.audit_log_integrity_level IS 'Integrity levels of audit logs';

-- Enum: CHATBOT_TRAINING_COHERENCE
-- Description: Defines coherence levels of chatbot training
-- Business Case: Measures logical consistency of training data for quality
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_coherence AS ENUM (
    'HIGHLY_COHERENT',               -- Highly coherent training
    'COHERENT',                      -- Coherent training
    'MODERATELY_COHERENT',           -- Moderately coherent
    'INCOHERENT',                    -- Incoherent training
    'CONTRADICTORY',                 -- Contradictory training
    'CONSISTENT',                    -- Consistent training
    'LOGICAL',                       -- Logical training structure
    'RANDOM'                         -- Random training approach
);
COMMENT ON TYPE ai_core.chatbot_training_coherence IS 'Coherence levels of chatbot training data';

-- Enum: AR_SCENE_INTERACTION_COMPLEXITY
-- Description: Defines complexity levels of AR scene interactions
-- Business Case: Balances user experience with technical complexity for usability
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_interaction_complexity AS ENUM (
    'SIMPLE_INTERACTION',            -- Simple interaction complexity
    'MODERATE_INTERACTION',          -- Moderate interaction complexity
    'COMPLEX_INTERACTION',           -- Complex interaction
    'VERY_COMPLEX_INTERACTION',      -- Very complex interaction
    'INTUITIVE',                     -- Intuitive interaction design
    'ADVANCED',                      -- Advanced interaction complexity
    'USER_FRIENDLY',                 -- User-friendly interaction
    'EXPERT_LEVEL'                   -- Expert-level interaction
);
COMMENT ON TYPE ai_core.ar_scene_interaction_complexity IS 'Complexity levels of augmented reality scene interactions';

-- Enum: FEATURE_STABILITY_METRIC
-- Description: Defines stability metrics for ML features
-- Business Case: Measures consistency of feature behavior for reliability
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_stability_metric AS ENUM (
    'HIGHLY_STABLE',                 -- Highly stable feature
    'STABLE',                        -- Stable feature
    'MODERATELY_STABLE',             -- Moderately stable
    'UNSTABLE',                      -- Unstable feature
    'FLUCTUATING',                   -- Fluctuating feature behavior
    'CONSISTENT',                    -- Consistent feature behavior
    'PREDICTABLE',                   -- Predictable feature behavior
    'RELIABLE'                       -- Reliable feature behavior
);
COMMENT ON TYPE ai_core.feature_stability_metric IS 'Stability metrics for machine learning features';

-- Enum: WORKFLOW_EXECUTION_RELIABILITY
-- Description: Defines reliability levels of workflow execution
-- Business Case: Measures dependability of automated workflows for operational trust
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_reliability AS ENUM (
    'VERY_RELIABLE',                 -- Very reliable execution
    'RELIABLE',                      -- Reliable execution
    'MODERATELY_RELIABLE',           -- Moderately reliable
    'UNRELIABLE',                    -- Unreliable execution
    'VERY_UNRELIABLE',               -- Very unreliable execution
    'TESTING_PHASE',                 -- Testing phase reliability
    'PRODUCTION_READY',              -- Production-ready reliability
    'ENTERPRISE_GRADE'               -- Enterprise-grade reliability
);
COMMENT ON TYPE ai_core.workflow_execution_reliability IS 'Reliability levels of workflow execution';

-- Enum: SIMULATION_SCENARIO_RELEVANCE
-- Description: Defines relevance levels of simulation scenarios
-- Business Case: Assesses practical applicability of scenarios for strategic value
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_scenario_relevance AS ENUM (
    'HIGHLY_RELEVANT',               -- Highly relevant scenario
    'RELEVANT',                      -- Relevant scenario
    'MODERATELY_RELEVANT',           -- Moderately relevant
    'SLIGHTLY_RELEVANT',             -- Slightly relevant
    'NOT_RELEVANT',                  -- Not relevant scenario
    'THEORETICAL',                   -- Theoretical relevance only
    'PRACTICAL',                     -- Practical relevance
    'INDUSTRY_STANDARD'              -- Industry-standard relevance
);
COMMENT ON TYPE ai_core.simulation_scenario_relevance IS 'Relevance levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_TRUSTWORTHINESS
-- Description: Defines trustworthiness levels of satisfaction indices
-- Business Case: Measures reliability of satisfaction measurements for decision-making
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_trustworthiness AS ENUM (
    'HIGHLY_TRUSTWORTHY',            -- Highly trustworthy index
    'TRUSTWORTHY',                   -- Trustworthy index
    'MODERATELY_TRUSTWORTHY',        -- Moderately trustworthy
    'UNTRUSTWORTHY',                 -- Untrustworthy index
    'QUESTIONABLE',                  -- Questionable trustworthiness
    'VERIFIED',                      -- Verified trustworthiness
    'ACCREDITED',                    -- Accredited measurement
    'PROVISIONAL'                     -- Provisional trustworthiness
);
COMMENT ON TYPE ai_core.satisfaction_index_trustworthiness IS 'Trustworthiness levels of satisfaction indices';

-- Enum: CORRELATION_BUSINESS_VALUE
-- Description: Defines business value of statistical correlations
-- Business Case: Assesses practical benefit of correlation findings for ROI
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_business_value AS ENUM (
    'TRANSFORMATIVE_VALUE',          -- Transformative business value
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'ACADEMIC_VALUE',                -- Academic value only
    'THEORETICALLY_USEFUL',          -- Theoretically useful only
    'PRACTICAL_VALUE'                -- Practical business value
);
COMMENT ON TYPE ai_core.correlation_business_value IS 'Business value of statistical correlations';

-- Enum: MODEL_ROLLBACK_IMPACT
-- Description: Defines impact levels of model rollbacks
-- Business Case: Assesses consequences of model version changes for planning
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_impact AS ENUM (
    'MINIMAL_IMPACT',                -- Minimal impact rollback
    'LOW_IMPACT',                    -- Low impact rollback
    'MODERATE_IMPACT',               -- Moderate impact rollback
    'HIGH_IMPACT',                   -- High impact rollback
    'CRITICAL_IMPACT',               -- Critical impact rollback
    'BENEFICIAL_IMPACT',             -- Beneficial impact rollback
    'RISKY_IMPACT',                  -- Risky impact rollback
    'NECESSARY_IMPACT'               -- Necessary impact rollback
);
COMMENT ON TYPE ai_core.model_rollback_impact IS 'Impact levels of machine learning model rollbacks';

-- Enum: TRAINING_DATA_REPRESENTATIVENESS
-- Description: Defines representativeness levels of training data
-- Business Case: Ensures fair representation across scenarios for unbiased models
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_representativeness AS ENUM (
    'HIGHLY_REPRESENTATIVE',         -- Highly representative data
    'REPRESENTATIVE',                -- Representative data
    'MODERATELY_REPRESENTATIVE',     -- Moderately representative
    'LIMITED_REPRESENTATIVENESS',    -- Limited representativeness
    'BIASED',                        -- Biased representation
    'UNREPRESENTATIVE',              -- Unrepresentative data
    'COMPREHENSIVE',                 -- Comprehensive representation
    'BALANCED'                       -- Balanced representation
);
COMMENT ON TYPE ai_core.training_data_representativeness IS 'Representativeness levels of training data';

-- Enum: EXPERT_SWARM_DYNAMICS
-- Description: Defines dynamic characteristics of expert swarms
-- Business Case: Optimizes swarm behavior and effectiveness for problem-solving
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_dynamics AS ENUM (
    'COLLABORATIVE',                 -- Collaborative swarm dynamics
    'COMPETITIVE',                   -- Competitive swarm dynamics
    'HIERARCHICAL',                  -- Hierarchical swarm dynamics
    'FLAT_STRUCTURE',                -- Flat structure dynamics
    'ADAPTIVE',                      -- Adaptive swarm dynamics
    'STATIC',                        -- Static swarm dynamics
    'FLEXIBLE',                      -- Flexible swarm dynamics
    'STRUCTURED'                     -- Structured swarm dynamics
);
COMMENT ON TYPE ai_core.expert_swarm_dynamics IS 'Dynamic characteristics of expert swarms';

-- Enum: SENTIMENT_ANALYSIS_RELIABILITY
-- Description: Defines reliability levels of sentiment analysis
-- Business Case: Measures trustworthiness of sentiment results for decision-making
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_reliability AS ENUM (
    'VERY_RELIABLE',                 -- Very reliable analysis
    'RELIABLE',                      -- Reliable analysis
    'MODERATELY_RELIABLE',           -- Moderately reliable
    'UNRELIABLE',                    -- Unreliable analysis
    'VERY_UNRELIABLE',               -- Very unreliable analysis
    'TESTING_PHASE',                 -- Testing phase reliability
    'PRODUCTION_READY',              -- Production-ready reliability
    'ENTERPRISE_GRADE'               -- Enterprise-grade reliability
);
COMMENT ON TYPE ai_core.sentiment_analysis_reliability IS 'Reliability levels of sentiment analysis';

-- Enum: CMDB_SYNC_PERFORMANCE_METRIC
-- Description: Defines performance metrics for CMDB synchronization
-- Business Case: Measures efficiency of synchronization processes for optimization
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_performance_metric AS ENUM (
    'HIGH_PERFORMANCE',              -- High performance sync
    'MODERATE_PERFORMANCE',          -- Moderate performance sync
    'LOW_PERFORMANCE',               -- Low performance sync
    'OPTIMIZED',                     -- Optimized performance
    'BOTTLENECKED',                  -- Bottlenecked performance
    'EFFICIENT',                     -- Efficient performance
    'SLOW_SYNC',                     -- Slow synchronization
    'INSTANT_SYNC'                   -- Instant synchronization
);
COMMENT ON TYPE config_mgmt.cmdb_sync_performance_metric IS 'Performance metrics for CMDB synchronization';

-- Enum: CONFIGURATION_ITEM_CHANGE_COMPLEXITY
-- Description: Defines complexity levels of configuration item changes
-- Business Case: Assesses difficulty of making configuration changes for planning
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_change_complexity AS ENUM (
    'SIMPLE_CHANGE',                 -- Simple configuration change
    'MODERATE_CHANGE',               -- Moderate change complexity
    'COMPLEX_CHANGE',                -- Complex change process
    'VERY_COMPLEX_CHANGE',           -- Very complex change
    'TRIVIAL_CHANGE',                -- Trivial change process
    'CRITICAL_CHANGE',               -- Critical change complexity
    'ROUTINE_CHANGE',                -- Routine change process
    'EXCEPTIONAL_CHANGE'             -- Exceptional change complexity
);
COMMENT ON TYPE config_mgmt.configuration_item_change_complexity IS 'Complexity levels of configuration item changes';

-- Enum: SCENARIO_SIMULATION_FIDELITY
-- Description: Defines fidelity levels of simulation scenarios
-- Business Case: Controls realism and accuracy of simulations for reliability
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_fidelity AS ENUM (
    'HIGH_FIDELITY',                 -- High fidelity simulation
    'MODERATE_FIDELITY',             -- Moderate fidelity simulation
    'LOW_FIDELITY',                  -- Low fidelity simulation
    'ABSTRACT',                      -- Abstract simulation
    'DETAILED',                      -- Detailed simulation
    'ACCURATE',                      -- Accurate simulation
    'REALISTIC',                     -- Realistic simulation
    'STYLIZED'                       -- Stylized simulation approach
);
COMMENT ON TYPE ai_core.scenario_simulation_fidelity IS 'Fidelity levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_STABILITY
-- Description: Defines stability levels of satisfaction indices
-- Business Case: Measures consistency of satisfaction measurements for trustworthiness
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_stability AS ENUM (
    'HIGHLY_STABLE',                 -- Highly stable index
    'STABLE',                        -- Stable index
    'MODERATELY_STABLE',             -- Moderately stable
    'UNSTABLE',                      -- Unstable index
    'FLUCTUATING',                   -- Fluctuating index
    'CONSISTENT',                    -- Consistent index
    'PREDICTABLE',                   -- Predictable index behavior
    'RELIABLE'                       -- Reliable index measurement
);
COMMENT ON TYPE ai_core.satisfaction_index_stability IS 'Stability levels of satisfaction indices';

-- Enum: CORRELATION_ANALYTICAL_DEPTH
-- Description: Defines analytical depth of correlation studies
-- Business Case: Controls sophistication of correlation analysis for insights
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_analytical_depth AS ENUM (
    'SURFACE_LEVEL',                 -- Surface-level analysis
    'DEEP_ANALYSIS',                 -- Deep analytical depth
    'COMPREHENSIVE',                 -- Comprehensive analysis
    'CONTEXTUAL',                    -- Contextual analysis depth
    'NUANCED',                       -- Nuanced analytical depth
    'MULTI_DIMENSIONAL',             -- Multi-dimensional analysis
    'GRANULAR',                      -- Granular analytical depth
    'HOLISTIC'                       -- Holistic analytical approach
);
COMMENT ON TYPE ai_core.correlation_analytical_depth IS 'Analytical depth of correlation studies';

-- Enum: MODEL_PERFORMANCE_METRIC_IMPORTANCE
-- Description: Defines importance levels of model performance metrics
-- Business Case: Prioritizes metrics based on business impact for focus
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_metric_importance AS ENUM (
    'CRITICAL',                      -- Critical performance metric
    'HIGH_IMPORTANCE',               -- High importance metric
    'MODERATE_IMPORTANCE',           -- Moderate importance
    'LOW_IMPORTANCE',                -- Low importance metric
    'MINIMAL_IMPORTANCE',            -- Minimal importance
    'OPTIONAL',                      -- Optional metric
    'PRIMARY',                       -- Primary performance metric
    'SECONDARY'                      -- Secondary performance metric
);
COMMENT ON TYPE ai_core.model_performance_metric_importance IS 'Importance levels of model performance metrics';

-- Enum: ANOMALY_DETECTION_CUSTOMIZABILITY
-- Description: Defines customizability levels of anomaly detection
-- Business Case: Controls adaptability to specific requirements for optimization
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_customizability AS ENUM (
    'HIGHLY_CUSTOMIZABLE',           -- Highly customizable system
    'CUSTOMIZABLE',                  -- Customizable system
    'MODERATELY_CUSTOMIZABLE',       -- Moderately customizable
    'LIMITED_CUSTOMIZABILITY',       -- Limited customization
    'FIXED_PARAMETERS',              -- Fixed parameter system
    'CONFIGURABLE',                  -- Configurable system
    'PRESET_OPTIONS',                -- Preset options only
    'FLEXIBLE_CUSTOMIZATION'         -- Flexible customization approach
);
COMMENT ON TYPE ai_core.anomaly_detection_customizability IS 'Customizability levels of anomaly detection systems';

-- Enum: AUTO_HEALING_AUTONOMY_LEVEL
-- Description: Defines autonomy levels of auto-healing operations
-- Business Case: Controls degree of human intervention required for operations
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_autonomy_level AS ENUM (
    'FULLY_AUTONOMOUS',              -- Fully autonomous healing
    'HIGH_AUTONOMY',                 -- High autonomy level
    'MODERATE_AUTONOMY',             -- Moderate autonomy level
    'LOW_AUTONOMY',                  -- Low autonomy level
    'HUMAN_CONTROLLED',              -- Human-controlled healing
    'SUPERVISED_AUTONOMY',           -- Supervised autonomy
    'SEMIAUTOMATED',                 -- Semi-automated healing
    'MANUAL_OPERATION'               -- Manual operation required
);
COMMENT ON TYPE ai_core.auto_healing_autonomy_level IS 'Autonomy levels of auto-healing operations';

-- Enum: USER_FEEDBACK_ENGAGEMENT_LEVEL
-- Description: Defines engagement levels of user feedback
-- Business Case: Measures depth of user involvement for quality assessment
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_engagement_level AS ENUM (
    'HIGHLY_ENGAGED',                -- Highly engaged feedback
    'ENGAGED',                       -- Engaged feedback
    'MODERATELY_ENGAGED',            -- Moderately engaged
    'LIGHTLY_ENGAGED',               -- Lightly engaged feedback
    'PASSIVE',                       -- Passive feedback
    'ACTIVE',                        -- Active feedback
    'DETAILED',                      -- Detailed feedback
    'BRIEF'                          -- Brief feedback
);
COMMENT ON TYPE it_incident.user_feedback_engagement_level IS 'Engagement levels of user feedback';

-- Enum: BLOCKCHAIN_GOVERNANCE_MODEL
-- Description: Defines governance models for blockchain implementations
-- Business Case: Establishes decision-making structures for blockchain networks
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_governance_model AS ENUM (
    'DEMOCRATIC',                    -- Democratic governance model
    'CENTRALIZED',                   -- Centralized governance model
    'DISTRIBUTED',                   -- Distributed governance model
    'CONSORTIUM',                    -- Consortium governance model
    'TOKEN_BASED',                   -- Token-based governance model
    'STAKEHOLDER_BASED',             -- Stakeholder-based governance
    'DELEGATED',                     -- Delegated governance model
    'HYBRID_MODEL'                   -- Hybrid governance model
);
COMMENT ON TYPE sec_audit.blockchain_governance_model IS 'Governance models for blockchain implementations';

-- Enum: METERING_DATA_STORAGE_EFFICIENCY
-- Description: Defines efficiency levels of metering data storage
-- Business Case: Optimizes storage resource utilization for cost-effectiveness
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_storage_efficiency AS ENUM (
    'VERY_EFFICIENT',                -- Very efficient storage
    'EFFICIENT',                     -- Efficient storage
    'MODERATELY_EFFICIENT',          -- Moderately efficient
    'INEFFICIENT',                   -- Inefficient storage
    'WASTEFUL',                      -- Wasteful storage usage
    'OPTIMAL',                       -- Optimal storage efficiency
    'SUB_OPTIMAL',                   -- Sub-optimal efficiency
    'SPACE_EFFICIENT'                -- Space-efficient storage
);
COMMENT ON TYPE it_incident.metering_data_storage_efficiency IS 'Efficiency levels of metering data storage';

-- Enum: AUDIT_LOG_PROCESSING_COMPLEXITY
-- Description: Defines complexity levels of audit log processing
-- Business Case: Assesses computational requirements for analysis efficiency
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_processing_complexity AS ENUM (
    'SIMPLE',                        -- Simple processing complexity
    'MODERATE',                      -- Moderate complexity processing
    'COMPLEX',                       -- Complex processing
    'VERY_COMPLEX',                  -- Very complex processing
    'COMPUTE_INTENSIVE',             -- Compute-intensive processing
    'LIGHTWEIGHT',                   -- Lightweight processing
    'ENTERPRISE_GRADE',              -- Enterprise-grade processing
    'CUSTOM_COMPLEXITY'              -- Custom complexity level
);
COMMENT ON TYPE it_incident.audit_log_processing_complexity IS 'Complexity levels of audit log processing';

-- Enum: CHATBOT_TRAINING_SCALABILITY
-- Description: Defines scalability levels of chatbot training
-- Business Case: Measures ability to scale training processes for growth
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_scalability AS ENUM (
    'HIGHLY_SCALABLE',               -- Highly scalable training
    'SCALABLE',                      -- Scalable training
    'MODERATELY_SCALABLE',           -- Moderately scalable
    'LIMITED_SCALABILITY',           -- Limited scalability
    'NOT_SCALABLE',                  -- Not scalable training
    'VERTICALLY_SCALABLE',           -- Vertically scalable
    'HORIZONTALLY_SCALABLE',         -- Horizontally scalable
    'ELASTIC_SCALABILITY'            -- Elastic scalability
);
COMMENT ON TYPE ai_core.chatbot_training_scalability IS 'Scalability levels of chatbot training processes';

-- Enum: AR_SCENE_VISUAL_FIDELITY
-- Description: Defines visual fidelity levels of AR scenes
-- Business Case: Controls visual quality and realism for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_visual_fidelity AS ENUM (
    'LOW_FIDELITY',                  -- Low visual fidelity
    'MODERATE_FIDELITY',             -- Moderate visual fidelity
    'HIGH_FIDELITY',                 -- High visual fidelity
    'ULTRA_HIGH_FIDELITY',           -- Ultra-high visual fidelity
    'PHOTO_REALISTIC',               -- Photo-realistic fidelity
    'CARTOON_STYLE',                 -- Cartoon-style fidelity
    'STYLIZED',                      -- Stylized visual approach
    'REALISTIC'                      -- Realistic visual fidelity
);
COMMENT ON TYPE ai_core.ar_scene_visual_fidelity IS 'Visual fidelity levels of augmented reality scenes';

-- Enum: FEATURE_BUSINESS_CRITICALITY
-- Description: Defines business criticality levels of ML features
-- Business Case: Prioritizes features based on business impact for resource allocation
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_business_criticality AS ENUM (
    'MISSION_CRITICAL',              -- Mission-critical feature
    'BUSINESS_CRITICAL',             -- Business-critical feature
    'IMPORTANT',                     -- Important feature
    'MODERATELY_IMPORTANT',          -- Moderately important
    'LOW_IMPORTANCE',                -- Low importance feature
    'OPTIONAL',                      -- Optional feature
    'BENEFICIAL',                    -- Beneficial feature
    'NECESSARY'                      -- Necessary feature
);
COMMENT ON TYPE ai_core.feature_business_criticality IS 'Business criticality levels of machine learning features';

-- Enum: MODEL_TRAINING_SCALABILITY
-- Description: Defines scalability levels of model training
-- Business Case: Measures ability to scale training resources for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_scalability AS ENUM (
    'HIGHLY_SCALABLE',               -- Highly scalable training
    'SCALABLE',                      -- Scalable training
    'MODERATELY_SCALABLE',           -- Moderately scalable
    'LIMITED_SCALABILITY',           -- Limited scalability
    'NOT_SCALABLE',                  -- Not scalable training
    'VERTICALLY_SCALABLE',           -- Vertically scalable
    'HORIZONTALLY_SCALABLE',         -- Horizontally scalable
    'ELASTIC_SCALABILITY'            -- Elastic scalability
);
COMMENT ON TYPE ai_core.model_training_scalability IS 'Scalability levels of machine learning model training';

-- Enum: ANOMALY_DETECTION_BUSINESS_IMPACT
-- Description: Defines business impact levels of anomaly detection
-- Business Case: Measures value of anomaly detection systems for ROI assessment
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_business_impact AS ENUM (
    'TRANSFORMATIVE_IMPACT',         -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'BENEFICIAL_IMPACT',             -- Beneficial impact
    'RISK_REDUCTION',                -- Risk reduction impact
    'COST_SAVINGS'                   -- Cost savings impact
);
COMMENT ON TYPE ai_core.anomaly_detection_business_impact IS 'Business impact levels of anomaly detection systems';

-- Enum: AUTO_HEALING_BUSINESS_VALUE
-- Description: Defines business value levels of auto-healing
-- Business Case: Assesses ROI of automated remediation for investment decisions
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_SAVING',                   -- Cost-saving value
    'RISK_REDUCTION',                -- Risk reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'PRODUCTIVITY_BOOST'             -- Productivity boost value
);
COMMENT ON TYPE ai_core.auto_healing_business_value IS 'Business value levels of auto-healing operations';

-- Enum: USER_FEEDBACK_BUSINESS_VALUE
-- Description: Defines business value levels of user feedback
-- Business Case: Measures ROI of feedback collection for strategic planning
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'INSIGHT_GENERATION',            -- Insight generation value
    'IMPROVEMENT_OPPORTUNITY',       -- Improvement opportunity value
    'CUSTOMER_RETENTION',            -- Customer retention value
    'QUALITY_ENHANCEMENT'            -- Quality enhancement value
);
COMMENT ON TYPE it_incident.user_feedback_business_value IS 'Business value levels of user feedback';

-- Enum: BLOCKCHAIN_TRANSACTION_BUSINESS_VALUE
-- Description: Defines business value levels of blockchain transactions
-- Business Case: Measures ROI of blockchain implementations for investment decisions
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'TRUST_ESTABLISHMENT',           -- Trust establishment value
    'COMPLIANCE_ASSURANCE',          -- Compliance assurance value
    'AUDIT_TRAIL',                   -- Audit trail value
    'TRANSPARENCY_ENHANCEMENT'       -- Transparency enhancement value
);
COMMENT ON TYPE sec_audit.blockchain_transaction_business_value IS 'Business value levels of blockchain transactions';

-- Enum: METERING_DATA_BUSINESS_VALUE
-- Description: Defines business value levels of metering data
-- Business Case: Measures ROI of data collection and analysis for optimization
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'OPERATIONAL_INSIGHT',           -- Operational insight value
    'PERFORMANCE_OPTIMIZATION',      -- Performance optimization value
    'CAPACITY_PLANNING',             -- Capacity planning value
    'COST_MANAGEMENT'                -- Cost management value
);
COMMENT ON TYPE it_incident.metering_data_business_value IS 'Business value levels of metering data';

-- Enum: AUDIT_LOG_BUSINESS_VALUE
-- Description: Defines business value levels of audit logs
-- Business Case: Measures ROI of audit and compliance systems for governance
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COMPLIANCE_ASSURANCE',          -- Compliance assurance value
    'SECURITY_INCIDENT_DETECTION',   -- Security incident detection value
    'FORENSIC_ANALYSIS',             -- Forensic analysis value
    'GOVERNANCE_SUPPORT'             -- Governance support value
);
COMMENT ON TYPE it_incident.audit_log_business_value IS 'Business value levels of audit logs';

-- Enum: CHATBOT_TRAINING_BUSINESS_VALUE
-- Description: Defines business value levels of chatbot training
-- Business Case: Measures ROI of AI training investments for optimization
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'CUSTOMER_EXPERIENCE',           -- Customer experience value
    'OPERATIONAL_EFFICIENCY',        -- Operational efficiency value
    'COST_REDUCTION',                -- Cost reduction value
    'SCALABILITY_ENHANCEMENT'        -- Scalability enhancement value
);
COMMENT ON TYPE ai_core.chatbot_training_business_value IS 'Business value levels of chatbot training';

-- Enum: AR_SCENE_BUSINESS_VALUE
-- Description: Defines business value levels of AR scenes
-- Business Case: Measures ROI of AR implementation for strategic investment
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'TRAINING_ENHANCEMENT',          -- Training enhancement value
    'PRODUCTIVITY_IMPROVEMENT',      -- Productivity improvement value
    'ERROR_REDUCTION',               -- Error reduction value
    'QUALITY_ENHANCEMENT'            -- Quality enhancement value
);
COMMENT ON TYPE ai_core.ar_scene_business_value IS 'Business value levels of augmented reality scenes';

-- Enum: FEATURE_BUSINESS_VALUE
-- Description: Defines business value levels of ML features
-- Business Case: Measures ROI of feature engineering efforts for optimization
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'PREDICTION_ACCURACY',           -- Prediction accuracy value
    'MODEL_PERFORMANCE',             -- Model performance value
    'INSIGHT_GENERATION',            -- Insight generation value
    'DECISION_SUPPORT'               -- Decision support value
);
COMMENT ON TYPE ai_core.feature_business_value IS 'Business value levels of machine learning features';

-- Enum: WORKFLOW_EXECUTION_BUSINESS_VALUE
-- Description: Defines business value levels of workflow execution
-- Business Case: Measures ROI of automation investments for strategic planning
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'PROCESS_AUTOMATION',            -- Process automation value
    'OPERATIONAL_EFFICIENCY',        -- Operational efficiency value
    'COST_REDUCTION',                -- Cost reduction value
    'SCALABILITY_ENHANCEMENT'        -- Scalability enhancement value
);
COMMENT ON TYPE ai_core.workflow_execution_business_value IS 'Business value levels of workflow execution';

-- Enum: SIMULATION_SCENARIO_BUSINESS_VALUE
-- Description: Defines business value levels of simulation scenarios
-- Business Case: Measures ROI of simulation investments for strategic planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.simulation_scenario_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'RISK_ASSESSMENT',               -- Risk assessment value
    'CONTINGENCY_PLANNING',          -- Contingency planning value
    'CAPACITY_PLANNING',             -- Capacity planning value
    'RESILIENCE_TESTING'             -- Resilience testing value
);
COMMENT ON TYPE ai_core.simulation_scenario_business_value IS 'Business value levels of simulation scenarios';

-- Enum: SATISFACTION_INDEX_BUSINESS_VALUE
-- Description: Defines business value levels of satisfaction indices
-- Business Case: Measures ROI of customer experience investments for optimization
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'CUSTOMER_RETENTION',            -- Customer retention value
    'QUALITY_IMPROVEMENT',           -- Quality improvement value
    'PERFORMANCE_MEASUREMENT',       -- Performance measurement value
    'STAKEHOLDER_COMMUNICATION'      -- Stakeholder communication value
);
COMMENT ON TYPE ai_core.satisfaction_index_business_value IS 'Business value levels of satisfaction indices';

-- Enum: CORRELATION_BUSINESS_VALUE
-- Description: Defines business value levels of correlations
-- Business Case: Measures ROI of analytical insights for strategic decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'INSIGHT_GENERATION',            -- Insight generation value
    'PREDICTION_IMPROVEMENT',        -- Prediction improvement value
    'OPERATIONAL_OPTIMIZATION',      -- Operational optimization value
    'STRATEGIC_PLANNING'             -- Strategic planning value
);
COMMENT ON TYPE ai_core.correlation_business_value IS 'Business value levels of statistical correlations';

-- Enum: MODEL_ROLLBACK_BUSINESS_VALUE
-- Description: Defines business value levels of model rollbacks
-- Business Case: Measures ROI of rollback capabilities for risk management
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'RISK_MITIGATION',               -- Risk mitigation value
    'STABILITY_MAINTENANCE',         -- Stability maintenance value
    'SERVICE_CONTINUITY',            -- Service continuity value
    'QUALITY_ASSURANCE'              -- Quality assurance value
);
COMMENT ON TYPE ai_core.model_rollback_business_value IS 'Business value levels of machine learning model rollbacks';

-- Enum: TRAINING_DATA_BUSINESS_VALUE
-- Description: Defines business value levels of training data
-- Business Case: Measures ROI of data investments for model optimization
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'MODEL_ACCURACY',                -- Model accuracy value
    'PREDICTION_QUALITY',            -- Prediction quality value
    'BUSINESS_INSIGHT',              -- Business insight value
    'DECISION_SUPPORT'               -- Decision support value
);
COMMENT ON TYPE ai_core.training_data_business_value IS 'Business value levels of training data';

-- Enum: EXPERT_SWARM_BUSINESS_VALUE
-- Description: Defines business value levels of expert swarms
-- Business Case: Measures ROI of collaborative problem-solving for efficiency
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'PROBLEM_SOLVING',               -- Problem solving value
    'KNOWLEDGE_SHARING',             -- Knowledge sharing value
    'EXPERTISE_UTILIZATION',         -- Expertise utilization value
    'COLLABORATION_ENHANCEMENT'      -- Collaboration enhancement value
);
COMMENT ON TYPE ai_core.expert_swarm_business_value IS 'Business value levels of expert swarms';

-- Enum: SENTIMENT_ANALYSIS_BUSINESS_VALUE
-- Description: Defines business value levels of sentiment analysis
-- Business Case: Measures ROI of emotional intelligence for customer experience
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'CUSTOMER_EXPERIENCE',           -- Customer experience value
    'MARKET_INTELLIGENCE',           -- Market intelligence value
    'RISK_DETECTION',                -- Risk detection value
    'OPPORTUNITY_IDENTIFICATION'     -- Opportunity identification value
);
COMMENT ON TYPE ai_core.sentiment_analysis_business_value IS 'Business value levels of sentiment analysis';

-- Enum: CMDB_SYNC_BUSINESS_VALUE
-- Description: Defines business value levels of CMDB synchronization
-- Business Case: Measures ROI of configuration management for operational efficiency
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'CONFIGURATION_ACCURACY',        -- Configuration accuracy value
    'CHANGE_MANAGEMENT',             -- Change management value
    'COMPLIANCE_ASSURANCE',          -- Compliance assurance value
    'INCIDENT_REDUCTION'             -- Incident reduction value
);
COMMENT ON TYPE config_mgmt.cmdb_sync_business_value IS 'Business value levels of CMDB synchronization';

-- Enum: CONFIGURATION_ITEM_BUSINESS_VALUE
-- Description: Defines business value levels of configuration items
-- Business Case: Measures ROI of IT asset management for optimization
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'ASSET_MANAGEMENT',              -- Asset management value
    'SERVICE_DELIVERY',              -- Service delivery value
    'COMPLIANCE_TRACKING',           -- Compliance tracking value
    'FINANCIAL_ACCOUNTING'           -- Financial accounting value
);
COMMENT ON TYPE config_mgmt.configuration_item_business_value IS 'Business value levels of configuration items';

-- Enum: SCENARIO_SIMULATION_BUSINESS_VALUE
-- Description: Defines business value levels of scenario simulations
-- Business Case: Measures ROI of predictive modeling for strategic planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'RISK_ASSESSMENT',               -- Risk assessment value
    'PLANNING_SUPPORT',              -- Planning support value
    'DECISION_SUPPORT',              -- Decision support value
    'STRATEGIC_PLANNING'             -- Strategic planning value
);
COMMENT ON TYPE ai_core.scenario_simulation_business_value IS 'Business value levels of scenario simulations';

-- Enum: SATISFACTION_INDEX_BUSINESS_IMPACT
-- Description: Defines business impact levels of satisfaction indices
-- Business Case: Measures impact on business outcomes for strategic alignment
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.satisfaction_index_business_impact IS 'Business impact levels of satisfaction indices';

-- Enum: CORRELATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of correlations
-- Business Case: Measures impact on business operations for strategic decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.correlation_business_impact IS 'Business impact levels of statistical correlations';

-- Enum: MODEL_ROLLBACK_BUSINESS_IMPACT
-- Description: Defines business impact levels of model rollbacks
-- Business Case: Measures consequences of version changes for operational planning
-- Feature Reference: 1.063
CREATE TYPE ai_core.model_rollback_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_rollback_business_impact IS 'Business impact levels of machine learning model rollbacks';

-- Enum: TRAINING_DATA_BUSINESS_IMPACT
-- Description: Defines business impact levels of training data
-- Business Case: Measures consequences of data quality for model performance
-- Feature Reference: 1.112
CREATE TYPE ai_core.training_data_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.training_data_business_impact IS 'Business impact levels of training data';

-- Enum: EXPERT_SWARM_BUSINESS_IMPACT
-- Description: Defines business impact levels of expert swarms
-- Business Case: Measures consequences of collaborative efforts for efficiency
-- Feature Reference: 1.033
CREATE TYPE ai_core.expert_swarm_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.expert_swarm_business_impact IS 'Business impact levels of expert swarms';

-- Enum: SENTIMENT_ANALYSIS_BUSINESS_IMPACT
-- Description: Defines business impact levels of sentiment analysis
-- Business Case: Measures consequences of emotional intelligence for customer experience
-- Feature Reference: 1.009
CREATE TYPE ai_core.sentiment_analysis_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.sentiment_analysis_business_impact IS 'Business impact levels of sentiment analysis';

-- Enum: CMDB_SYNC_BUSINESS_IMPACT
-- Description: Defines business impact levels of CMDB synchronization
-- Business Case: Measures consequences of configuration management for operations
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.cmdb_sync_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE config_mgmt.cmdb_sync_business_impact IS 'Business impact levels of CMDB synchronization';

-- Enum: CONFIGURATION_ITEM_BUSINESS_IMPACT
-- Description: Defines business impact levels of configuration items
-- Business Case: Measures consequences of IT asset management for optimization
-- Feature Reference: 1.097
CREATE TYPE config_mgmt.configuration_item_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE config_mgmt.configuration_item_business_impact IS 'Business impact levels of configuration items';

-- Enum: SCENARIO_SIMULATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of scenario simulations
-- Business Case: Measures consequences of predictive modeling for strategic planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.scenario_simulation_business_impact IS 'Business impact levels of scenario simulations';

-- Enum: WORKFLOW_EXECUTION_BUSINESS_IMPACT
-- Description: Defines business impact levels of workflow execution
-- Business Case: Measures consequences of automation for operational efficiency
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.workflow_execution_business_impact IS 'Business impact levels of workflow execution';

-- Enum: ANOMALY_DETECTION_BUSINESS_IMPACT
-- Description: Defines business impact levels of anomaly detection
-- Business Case: Measures consequences of monitoring systems for security
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.anomaly_detection_business_impact IS 'Business impact levels of anomaly detection systems';

-- Enum: AUTO_HEALING_BUSINESS_IMPACT
-- Description: Defines business impact levels of auto-healing
-- Business Case: Measures consequences of automated remediation for operations
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.auto_healing_business_impact IS 'Business impact levels of auto-healing operations';

-- Enum: USER_FEEDBACK_BUSINESS_IMPACT
-- Description: Defines business impact levels of user feedback
-- Business Case: Measures consequences of feedback collection for improvement
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE it_incident.user_feedback_business_impact IS 'Business impact levels of user feedback';

-- Enum: BLOCKCHAIN_TRANSACTION_BUSINESS_IMPACT
-- Description: Defines business impact levels of blockchain transactions
-- Business Case: Measures consequences of blockchain implementation for security
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE sec_audit.blockchain_transaction_business_impact IS 'Business impact levels of blockchain transactions';

-- Enum: METERING_DATA_BUSINESS_IMPACT
-- Description: Defines business impact levels of metering data
-- Business Case: Measures consequences of data collection for analytics
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE it_incident.metering_data_business_impact IS 'Business impact levels of metering data';

-- Enum: AUDIT_LOG_BUSINESS_IMPACT
-- Description: Defines business impact levels of audit logs
-- Business Case: Measures consequences of audit systems for compliance
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE it_incident.audit_log_business_impact IS 'Business impact levels of audit logs';

-- Enum: CHATBOT_TRAINING_BUSINESS_IMPACT
-- Description: Defines business impact levels of chatbot training
-- Business Case: Measures consequences of AI training for customer service
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.chatbot_training_business_impact IS 'Business impact levels of chatbot training';

-- Enum: AR_SCENE_BUSINESS_IMPACT
-- Description: Defines business impact levels of AR scenes
-- Business Case: Measures consequences of AR implementation for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.ar_scene_business_impact IS 'Business impact levels of augmented reality scenes';

-- Enum: FEATURE_BUSINESS_IMPACT
-- Description: Defines business impact levels of ML features
-- Business Case: Measures consequences of feature engineering for model performance
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.feature_business_impact IS 'Business impact levels of machine learning features';

-- Enum: MODEL_PERFORMANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model performance
-- Business Case: Measures consequences of AI model effectiveness for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_performance_business_impact IS 'Business impact levels of machine learning model performance';

-- Enum: MODEL_TRAINING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model training
-- Business Case: Measures consequences of model development for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_training_business_impact IS 'Business impact levels of machine learning model training';

-- Enum: MODEL_DEPLOYMENT_BUSINESS_IMPACT
-- Description: Defines business impact levels of model deployment
-- Business Case: Measures consequences of model implementation for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_deployment_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_deployment_business_impact IS 'Business impact levels of machine learning model deployment';

-- Enum: MODEL_MAINTENANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model maintenance
-- Business Case: Measures consequences of ongoing model care for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_maintenance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_maintenance_business_impact IS 'Business impact levels of machine learning model maintenance';

-- Enum: MODEL_MONITORING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model monitoring
-- Business Case: Measures consequences of model oversight for performance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_monitoring_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_monitoring_business_impact IS 'Business impact levels of machine learning model monitoring';

-- Enum: MODEL_EVALUATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model evaluation
-- Business Case: Measures consequences of model assessment for quality
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_evaluation_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_evaluation_business_impact IS 'Business impact levels of machine learning model evaluation';

-- Enum: MODEL_OPTIMIZATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model optimization
-- Business Case: Measures consequences of model improvement for performance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_optimization_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_optimization_business_impact IS 'Business impact levels of machine learning model optimization';

-- Enum: MODEL_RETRAINING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model retraining
-- Business Case: Measures consequences of model updating for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_retraining_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_retraining_business_impact IS 'Business impact levels of machine learning model retraining';

-- Enum: MODEL_VERSIONING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model versioning
-- Business Case: Measures consequences of model lifecycle management for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_versioning_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_versioning_business_impact IS 'Business impact levels of machine learning model versioning';

-- Enum: MODEL_SECURITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model security
-- Business Case: Measures consequences of AI security measures for protection
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_security_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_security_business_impact IS 'Business impact levels of machine learning model security';

-- Enum: MODEL_ETHICS_BUSINESS_IMPACT
-- Description: Defines business impact levels of model ethics
-- Business Case: Measures consequences of AI ethical considerations for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_ethics_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_ethics_business_impact IS 'Business impact levels of machine learning model ethics';

-- Enum: MODEL_GOVERNANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model governance
-- Business Case: Measures consequences of AI governance frameworks for oversight
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_governance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_governance_business_impact IS 'Business impact levels of machine learning model governance';

-- Enum: MODEL_COMPLIANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model compliance
-- Business Case: Measures consequences of AI regulatory compliance for risk management
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_compliance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_compliance_business_impact IS 'Business impact levels of machine learning model compliance';

-- Enum: MODEL_PRIVACY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model privacy
-- Business Case: Measures consequences of AI privacy protection for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_privacy_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_privacy_business_impact IS 'Business impact levels of machine learning model privacy';

-- Enum: MODEL_AUDITABILITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model auditability
-- Business Case: Measures consequences of AI audit capabilities for transparency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_audibility_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_audibility_business_impact IS 'Business impact levels of machine learning model auditability';

-- Enum: MODEL_EXPLAINABILITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model explainability
-- Business Case: Measures consequences of AI interpretability for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_explainability_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_explainability_business_impact IS 'Business impact levels of machine learning model explainability';

-- Enum: MODEL_FAIRNESS_BUSINESS_IMPACT
-- Description: Defines business impact levels of model fairness
-- Business Case: Measures consequences of AI bias mitigation for equity
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_fairness_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_fairness_business_impact IS 'Business impact levels of machine learning model fairness';

-- Enum: MODEL_ROBUSTNESS_BUSINESS_IMPACT
-- Description: Defines business impact levels of model robustness
-- Business Case: Measures consequences of AI resilience for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_robustness_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_robustness_business_impact IS 'Business impact levels of machine learning model robustness';

-- Enum: MODEL_ACCURACY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model accuracy
-- Business Case: Measures consequences of AI prediction quality for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_accuracy_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_accuracy_business_impact IS 'Business impact levels of machine learning model accuracy';

-- Enum: MODEL_PRECISION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model precision
-- Business Case: Measures consequences of AI positive prediction quality for decisions
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_precision_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_precision_business_impact IS 'Business impact levels of machine learning model precision';

-- Enum: MODEL_RECALL_BUSINESS_IMPACT
-- Description: Defines business impact levels of model recall
-- Business Case: Measures consequences of AI positive detection rate for completeness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_recall_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_recall_business_impact IS 'Business impact levels of machine learning model recall';

-- Enum: MODEL_F1_SCORE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model F1 score
-- Business Case: Measures consequences of AI balanced performance for optimization
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_f1_score_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_f1_score_business_impact IS 'Business impact levels of machine learning model F1 score';

-- Enum: MODEL_AUC_ROC_BUSINESS_IMPACT
-- Description: Defines business impact levels of model AUC-ROC
-- Business Case: Measures consequences of AI classification performance for evaluation
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_auc_roc_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_auc_roc_business_impact IS 'Business impact levels of machine learning model AUC-ROC';

-- Enum: MODEL_RMSE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model RMSE
-- Business Case: Measures consequences of AI regression accuracy for predictions
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_rmse_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_rmse_business_impact IS 'Business impact levels of machine learning model RMSE';

-- Enum: MODEL_MAE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model MAE
-- Business Case: Measures consequences of AI absolute error for precision
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_mae_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_mae_business_impact IS 'Business impact levels of machine learning model MAE';

-- Enum: MODEL_MAPE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model MAPE
-- Business Case: Measures consequences of AI percentage error for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_mape_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_mape_business_impact IS 'Business impact levels of machine learning model MAPE';

-- Enum: MODEL_COVERAGE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model coverage
-- Business Case: Measures consequences of AI prediction coverage for comprehensiveness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_coverage_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_coverage_business_impact IS 'Business impact levels of machine learning model coverage';

-- Enum: MODEL_STABILITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model stability
-- Business Case: Measures consequences of AI prediction consistency for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_stability_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_stability_business_impact IS 'Business impact levels of machine learning model stability';

-- Enum: MODEL_DRIFT_BUSINESS_IMPACT
-- Description: Defines business impact levels of model drift
-- Business Case: Measures consequences of AI concept drift for maintenance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_drift_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_drift_business_impact IS 'Business impact levels of machine learning model drift';

-- Enum: MODEL_BIAS_BUSINESS_IMPACT
-- Description: Defines business impact levels of model bias
-- Business Case: Measures consequences of AI systematic errors for fairness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_bias_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_bias_business_impact IS 'Business impact levels of machine learning model bias';

-- Enum: MODEL_VARIANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model variance
-- Business Case: Measures consequences of AI prediction variability for consistency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_variance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_variance_business_impact IS 'Business impact levels of machine learning model variance';

-- Enum: MODEL_OVERFITTING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model overfitting
-- Business Case: Measures consequences of AI generalization failure for performance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_overfitting_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_overfitting_business_impact IS 'Business impact levels of machine learning model overfitting';

-- Enum: MODEL_UNDERFITTING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model underfitting
-- Business Case: Measures consequences of AI insufficient learning for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_underfitting_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_underfitting_business_impact IS 'Business impact levels of machine learning model underfitting';

-- Enum: MODEL_COMPLEXITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model complexity
-- Business Case: Measures consequences of AI model sophistication for performance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_complexity_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_complexity_business_impact IS 'Business impact levels of machine learning model complexity';

-- Enum: MODEL_INTERPRETABILITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model interpretability
-- Business Case: Measures consequences of AI understanding for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_interpretability_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_interpretability_business_impact IS 'Business impact levels of machine learning model interpretability';

-- Enum: MODEL_TRANSPARENCY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model transparency
-- Business Case: Measures consequences of AI openness for accountability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_transparency_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_transparency_business_impact IS 'Business impact levels of machine learning model transparency';

-- Enum: MODEL_ACCOUNTABILITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model accountability
-- Business Case: Measures consequences of AI responsibility for governance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_accountability_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_accountability_business_impact IS 'Business impact levels of machine learning model accountability';

-- Enum: MODEL_CONSENT_BUSINESS_IMPACT
-- Description: Defines business impact levels of model consent
-- Business Case: Measures consequences of AI permission for privacy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_consent_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_consent_business_impact IS 'Business impact levels of machine learning model consent';

-- Enum: MODEL_DATA_PROVENANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data provenance
-- Business Case: Measures consequences of AI data lineage for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_provenance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_provenance_business_impact IS 'Business impact levels of machine learning model data provenance';

-- Enum: MODEL_DATA_QUALITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data quality
-- Business Case: Measures consequences of AI input quality for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_quality_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_quality_business_impact IS 'Business impact levels of machine learning model data quality';

-- Enum: MODEL_DATA_INTEGRITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data integrity
-- Business Case: Measures consequences of AI data trustworthiness for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_integrity_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_integrity_business_impact IS 'Business impact levels of machine learning model data integrity';

-- Enum: MODEL_DATA_SECURITY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data security
-- Business Case: Measures consequences of AI data protection for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_security_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_security_business_impact IS 'Business impact levels of machine learning model data security';

-- Enum: MODEL_DATA_PRIVACY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data privacy
-- Business Case: Measures consequences of AI data confidentiality for protection
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_privacy_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_privacy_business_impact IS 'Business impact levels of machine learning model data privacy';

-- Enum: MODEL_DATA_GOVERNANCE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data governance
-- Business Case: Measures consequences of AI data management for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_governance_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_governance_business_impact IS 'Business impact levels of machine learning model data governance';

-- Enum: MODEL_DATA_LIFECYCLE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data lifecycle
-- Business Case: Measures consequences of AI data management phases for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lifecycle_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_lifecycle_business_impact IS 'Business impact levels of machine learning model data lifecycle';

-- Enum: MODEL_DATA_LINEAGE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data lineage
-- Business Case: Measures consequences of AI data tracking for transparency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lineage_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_lineage_business_impact IS 'Business impact levels of machine learning model data lineage';

-- Enum: MODEL_DATA_CLASSIFICATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data classification
-- Business Case: Measures consequences of AI data categorization for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_classification_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_classification_business_impact IS 'Business impact levels of machine learning model data classification';

-- Enum: MODEL_DATA_ENCRYPTION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data encryption
-- Business Case: Measures consequences of AI data protection for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_encryption_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_encryption_business_impact IS 'Business impact levels of machine learning model data encryption';

-- Enum: MODEL_DATA_MASKING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data masking
-- Business Case: Measures consequences of AI data anonymization for privacy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_masking_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_masking_business_impact IS 'Business impact levels of machine learning model data masking';

-- Enum: MODEL_DATA_TOKENIZATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data tokenization
-- Business Case: Measures consequences of AI data substitution for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_tokenization_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_tokenization_business_impact IS 'Business impact levels of machine learning model data tokenization';

-- Enum: MODEL_DATA_DELETION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data deletion
-- Business Case: Measures consequences of AI data removal for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_deletion_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_deletion_business_impact IS 'Business impact levels of machine learning model data deletion';

-- Enum: MODEL_DATA_ARCHIVING_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data archiving
-- Business Case: Measures consequences of AI data preservation for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_archiving_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_archiving_business_impact IS 'Business impact levels of machine learning model data archiving';

-- Enum: MODEL_DATA_RECOVERY_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data recovery
-- Business Case: Measures consequences of AI data restoration for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_recovery_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_recovery_business_impact IS 'Business impact levels of machine learning model data recovery';

-- Enum: MODEL_DATA_BACKUP_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data backup
-- Business Case: Measures consequences of AI data protection for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_backup_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_backup_business_impact IS 'Business impact levels of machine learning model data backup';

-- Enum: MODEL_DATA_REPLICATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data replication
-- Business Case: Measures consequences of AI data duplication for availability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_replication_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_replication_business_impact IS 'Business impact levels of machine learning model data replication';

-- Enum: MODEL_DATA_SYNCHRONIZATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data synchronization
-- Business Case: Measures consequences of AI data consistency for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_synchronization_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_synchronization_business_impact IS 'Business impact levels of machine learning model data synchronization';

-- Enum: MODEL_DATA_INTEGRATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data integration
-- Business Case: Measures consequences of AI data combination for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_integration_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_integration_business_impact IS 'Business impact levels of machine learning model data integration';

-- Enum: MODEL_DATA_ETL_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data ETL
-- Business Case: Measures consequences of AI data extraction, transformation, and loading
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_etl_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_etl_business_impact IS 'Business impact levels of machine learning model data ETL';

-- Enum: MODEL_DATA_WAREHOUSE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data warehouse
-- Business Case: Measures consequences of AI data storage for analytics
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_warehouse_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_warehouse_business_impact IS 'Business impact levels of machine learning model data warehouse';

-- Enum: MODEL_DATA_LAKE_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data lake
-- Business Case: Measures consequences of AI raw data storage for analytics
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lake_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_lake_business_impact IS 'Business impact levels of machine learning model data lake';

-- Enum: MODEL_DATA_MESH_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data mesh
-- Business Case: Measures consequences of AI decentralized data architecture
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_mesh_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_mesh_business_impact IS 'Business impact levels of machine learning model data mesh';

-- Enum: MODEL_DATA_VIRTUALIZATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data virtualization
-- Business Case: Measures consequences of AI abstracted data access for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_virtualization_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_virtualization_business_impact IS 'Business impact levels of machine learning model data virtualization';

-- Enum: MODEL_DATA_FEDERATION_BUSINESS_IMPACT
-- Description: Defines business impact levels of model data federation
-- Business Case: Measures consequences of AI integrated data access for governance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_federation_business_impact AS ENUM (
    'TRANSFORMATIVE',                -- Transformative business impact
    'HIGH_IMPACT',                   -- High business impact
    'MODERATE_IMPACT',               -- Moderate business impact
    'LOW_IMPACT',                    -- Low business impact
    'MINIMAL_IMPACT',                -- Minimal business impact
    'POSITIVE_IMPACT',               -- Positive business impact
    'NEGATIVE_IMPACT',               -- Negative business impact
    'NEUTRAL_IMPACT'                 -- Neutral business impact
);
COMMENT ON TYPE ai_core.model_data_federation_business_impact IS 'Business impact levels of machine learning model data federation';

-- Enum: MODEL_DATA_VIRTUALIZATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data virtualization
-- Business Case: Measures ROI of AI abstracted data access for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_virtualization_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'INTEGRATION_VALUE'              -- Integration value
);
COMMENT ON TYPE ai_core.model_data_virtualization_business_value IS 'Business value levels of machine learning model data virtualization';

-- Enum: MODEL_DATA_FEDERATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data federation
-- Business Case: Measures ROI of AI integrated data access for governance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_federation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'INTEGRATION_VALUE'              -- Integration value
);
COMMENT ON TYPE ai_core.model_data_federation_business_value IS 'Business value levels of machine learning model data federation';

-- Enum: MODEL_DATA_MESH_BUSINESS_VALUE
-- Description: Defines business value levels of model data mesh
-- Business Case: Measures ROI of AI decentralized data architecture for agility
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_mesh_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'DECENTRALIZATION_VALUE'         -- Decentralization value
);
COMMENT ON TYPE ai_core.model_data_mesh_business_value IS 'Business value levels of machine learning model data mesh';

-- Enum: MODEL_DATA_LAKE_BUSINESS_VALUE
-- Description: Defines business value levels of model data lake
-- Business Case: Measures ROI of AI raw data storage for analytics
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lake_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ANALYTICS_VALUE'                -- Analytics value
);
COMMENT ON TYPE ai_core.model_data_lake_business_value IS 'Business value levels of machine learning model data lake';

-- Enum: MODEL_DATA_WAREHOUSE_BUSINESS_VALUE
-- Description: Defines business value levels of model data warehouse
-- Business Case: Measures ROI of AI data storage for reporting
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_warehouse_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'REPORTING_VALUE'                -- Reporting value
);
COMMENT ON TYPE ai_core.model_data_warehouse_business_value IS 'Business value levels of machine learning model data warehouse';

-- Enum: MODEL_DATA_ETL_BUSINESS_VALUE
-- Description: Defines business value levels of model data ETL
-- Business Case: Measures ROI of AI data extraction, transformation, and loading
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_etl_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'INTEGRATION_VALUE'              -- Integration value
);
COMMENT ON TYPE ai_core.model_data_etl_business_value IS 'Business value levels of machine learning model data ETL';

-- Enum: MODEL_DATA_SYNCHRONIZATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data synchronization
-- Business Case: Measures ROI of AI data consistency for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_synchronization_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'CONSISTENCY_VALUE'              -- Consistency value
);
COMMENT ON TYPE ai_core.model_data_synchronization_business_value IS 'Business value levels of machine learning model data synchronization';

-- Enum: MODEL_DATA_REPLICATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data replication
-- Business Case: Measures ROI of AI data duplication for availability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_replication_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RELIABILITY_VALUE'              -- Reliability value
);
COMMENT ON TYPE ai_core.model_data_replication_business_value IS 'Business value levels of machine learning model data replication';

-- Enum: MODEL_DATA_BACKUP_BUSINESS_VALUE
-- Description: Defines business value levels of model data backup
-- Business Case: Measures ROI of AI data protection for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_backup_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_data_backup_business_value IS 'Business value levels of machine learning model data backup';

-- Enum: MODEL_DATA_RECOVERY_BUSINESS_VALUE
-- Description: Defines business value levels of model data recovery
-- Business Case: Measures ROI of AI data restoration for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_recovery_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_data_recovery_business_value IS 'Business value levels of machine learning model data recovery';

-- Enum: MODEL_DATA_ARCHIVING_BUSINESS_VALUE
-- Description: Defines business value levels of model data archiving
-- Business Case: Measures ROI of AI data preservation for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_archiving_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_data_archiving_business_value IS 'Business value levels of machine learning model data archiving';

-- Enum: MODEL_DATA_DELETION_BUSINESS_VALUE
-- Description: Defines business value levels of model data deletion
-- Business Case: Measures ROI of AI data removal for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_deletion_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_data_deletion_business_value IS 'Business value levels of machine learning model data deletion';

-- Enum: MODEL_DATA_TOKENIZATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data tokenization
-- Business Case: Measures ROI of AI data substitution for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_tokenization_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PRIVACY_VALUE'                  -- Privacy value
);
COMMENT ON TYPE ai_core.model_data_tokenization_business_value IS 'Business value levels of machine learning model data tokenization';

-- Enum: MODEL_DATA_MASKING_BUSINESS_VALUE
-- Description: Defines business value levels of model data masking
-- Business Case: Measures ROI of AI data anonymization for privacy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_masking_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PRIVACY_VALUE'                  -- Privacy value
);
COMMENT ON TYPE ai_core.model_data_masking_business_value IS 'Business value levels of machine learning model data masking';

-- Enum: MODEL_DATA_ENCRYPTION_BUSINESS_VALUE
-- Description: Defines business value levels of model data encryption
-- Business Case: Measures ROI of AI data protection for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_encryption_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'SECURITY_VALUE'                 -- Security value
);
COMMENT ON TYPE ai_core.model_data_encryption_business_value IS 'Business value levels of machine learning model data encryption';

-- Enum: MODEL_DATA_CLASSIFICATION_BUSINESS_VALUE
-- Description: Defines business value levels of model data classification
-- Business Case: Measures ROI of AI data categorization for security
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_classification_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'GOVERNANCE_VALUE'               -- Governance value
);
COMMENT ON TYPE ai_core.model_data_classification_business_value IS 'Business value levels of machine learning model data classification';

-- Enum: MODEL_DATA_LINEAGE_BUSINESS_VALUE
-- Description: Defines business value levels of model data lineage
-- Business Case: Measures ROI of AI data tracking for transparency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lineage_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'AUDITABILITY_VALUE'             -- Auditability value
);
COMMENT ON TYPE ai_core.model_data_lineage_business_value IS 'Business value levels of machine learning model data lineage';

-- Enum: MODEL_DATA_LIFECYCLE_BUSINESS_VALUE
-- Description: Defines business value levels of model data lifecycle
-- Business Case: Measures ROI of AI data management phases for efficiency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_lifecycle_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'MANAGEMENT_VALUE'               -- Management value
);
COMMENT ON TYPE ai_core.model_data_lifecycle_business_value IS 'Business value levels of machine learning model data lifecycle';

-- Enum: MODEL_DATA_GOVERNANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model data governance
-- Business Case: Measures ROI of AI data management for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_governance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_data_governance_business_value IS 'Business value levels of machine learning model data governance';

-- Enum: MODEL_DATA_PRIVACY_BUSINESS_VALUE
-- Description: Defines business value levels of model data privacy
-- Business Case: Measures ROI of AI data confidentiality for protection
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_privacy_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_data_privacy_business_value IS 'Business value levels of machine learning model data privacy';

-- Enum: MODEL_DATA_SECURITY_BUSINESS_VALUE
-- Description: Defines business value levels of model data security
-- Business Case: Measures ROI of AI data protection for risk mitigation
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_security_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_data_security_business_value IS 'Business value levels of machine learning model data security';

-- Enum: MODEL_DATA_INTEGRITY_BUSINESS_VALUE
-- Description: Defines business value levels of model data integrity
-- Business Case: Measures ROI of AI data trustworthiness for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_integrity_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'TRUST_VALUE'                    -- Trust value
);
COMMENT ON TYPE ai_core.model_data_integrity_business_value IS 'Business value levels of machine learning model data integrity';

-- Enum: MODEL_DATA_QUALITY_BUSINESS_VALUE
-- Description: Defines business value levels of model data quality
-- Business Case: Measures ROI of AI input quality for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_quality_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_data_quality_business_value IS 'Business value levels of machine learning model data quality';

-- Enum: MODEL_DATA_PROVENANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model data provenance
-- Business Case: Measures ROI of AI data lineage for transparency
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_data_provenance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'AUDITABILITY_VALUE'             -- Auditability value
);
COMMENT ON TYPE ai_core.model_data_provenance_business_value IS 'Business value levels of machine learning model data provenance';

-- Enum: MODEL_CONSENT_BUSINESS_VALUE
-- Description: Defines business value levels of model consent
-- Business Case: Measures ROI of AI permission for privacy compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_consent_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_consent_business_value IS 'Business value levels of machine learning model consent';

-- Enum: MODEL_ACCOUNTABILITY_BUSINESS_VALUE
-- Description: Defines business value levels of model accountability
-- Business Case: Measures ROI of AI responsibility for governance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_accountability_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'GOVERNANCE_VALUE'               -- Governance value
);
COMMENT ON TYPE ai_core.model_accountability_business_value IS 'Business value levels of machine learning model accountability';

-- Enum: MODEL_TRANSPARENCY_BUSINESS_VALUE
-- Description: Defines business value levels of model transparency
-- Business Case: Measures ROI of AI openness for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_transparency_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'TRUST_VALUE'                    -- Trust value
);
COMMENT ON TYPE ai_core.model_transparency_business_value IS 'Business value levels of machine learning model transparency';

-- Enum: MODEL_INTERPRETABILITY_BUSINESS_VALUE
-- Description: Defines business value levels of model interpretability
-- Business Case: Measures ROI of AI understanding for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_interpretability_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'UNDERSTANDING_VALUE'            -- Understanding value
);
COMMENT ON TYPE ai_core.model_interpretability_business_value IS 'Business value levels of machine learning model interpretability';

-- Enum: MODEL_COMPLEXITY_BUSINESS_VALUE
-- Description: Defines business value levels of model complexity
-- Business Case: Measures ROI of AI model sophistication for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_complexity_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_complexity_business_value IS 'Business value levels of machine learning model complexity';

-- Enum: MODEL_UNDERFITTING_BUSINESS_VALUE
-- Description: Defines business value levels of model underfitting
-- Business Case: Measures ROI of AI insufficient learning for improvement
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_underfitting_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'IMPROVEMENT_VALUE'              -- Improvement value
);
COMMENT ON TYPE ai_core.model_underfitting_business_value IS 'Business value levels of machine learning model underfitting';

-- Enum: MODEL_OVERFITTING_BUSINESS_VALUE
-- Description: Defines business value levels of model overfitting
-- Business Case: Measures ROI of AI generalization failure for improvement
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_overfitting_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'IMPROVEMENT_VALUE'              -- Improvement value
);
COMMENT ON TYPE ai_core.model_overfitting_business_value IS 'Business value levels of machine learning model overfitting';

-- Enum: MODEL_VARIANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model variance
-- Business Case: Measures ROI of AI prediction variability for stability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_variance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'STABILITY_VALUE'                -- Stability value
);
COMMENT ON TYPE ai_core.model_variance_business_value IS 'Business value levels of machine learning model variance';

-- Enum: MODEL_BIAS_BUSINESS_VALUE
-- Description: Defines business value levels of model bias
-- Business Case: Measures ROI of AI systematic errors for fairness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_bias_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'FAIRNESS_VALUE'                 -- Fairness value
);
COMMENT ON TYPE ai_core.model_bias_business_value IS 'Business value levels of machine learning model bias';

-- Enum: MODEL_DRIFT_BUSINESS_VALUE
-- Description: Defines business value levels of model drift
-- Business Case: Measures ROI of AI concept drift for maintenance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_drift_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'STABILITY_VALUE'                -- Stability value
);
COMMENT ON TYPE ai_core.model_drift_business_value IS 'Business value levels of machine learning model drift';

-- Enum: MODEL_STABILITY_BUSINESS_VALUE
-- Description: Defines business value levels of model stability
-- Business Case: Measures ROI of AI prediction consistency for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_stability_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RELIABILITY_VALUE'              -- Reliability value
);
COMMENT ON TYPE ai_core.model_stability_business_value IS 'Business value levels of machine learning model stability';

-- Enum: MODEL_COVERAGE_BUSINESS_VALUE
-- Description: Defines business value levels of model coverage
-- Business Case: Measures ROI of AI prediction coverage for completeness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_coverage_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLETENESS_VALUE'             -- Completeness value
);
COMMENT ON TYPE ai_core.model_coverage_business_value IS 'Business value levels of machine learning model coverage';

-- Enum: MODEL_MAPE_BUSINESS_VALUE
-- Description: Defines business value levels of model MAPE
-- Business Case: Measures ROI of AI percentage error for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_mape_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_mape_business_value IS 'Business value levels of machine learning model MAPE';

-- Enum: MODEL_MAE_BUSINESS_VALUE
-- Description: Defines business value levels of model MAE
-- Business Case: Measures ROI of AI absolute error for precision
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_mae_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_mae_business_value IS 'Business value levels of machine learning model MAE';

-- Enum: MODEL_RMSE_BUSINESS_VALUE
-- Description: Defines business value levels of model RMSE
-- Business Case: Measures ROI of AI regression accuracy for predictions
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_rmse_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_rmse_business_value IS 'Business value levels of machine learning model RMSE';

-- Enum: MODEL_AUC_ROC_BUSINESS_VALUE
-- Description: Defines business value levels of model AUC-ROC
-- Business Case: Measures ROI of AI classification performance for evaluation
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_auc_roc_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PERFORMANCE_VALUE'              -- Performance value
);
COMMENT ON TYPE ai_core.model_auc_roc_business_value IS 'Business value levels of machine learning model AUC-ROC';

-- Enum: MODEL_F1_SCORE_BUSINESS_VALUE
-- Description: Defines business value levels of model F1 score
-- Business Case: Measures ROI of AI balanced performance for optimization
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_f1_score_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PERFORMANCE_VALUE'              -- Performance value
);
COMMENT ON TYPE ai_core.model_f1_score_business_value IS 'Business value levels of machine learning model F1 score';

-- Enum: MODEL_RECALL_BUSINESS_VALUE
-- Description: Defines business value levels of model recall
-- Business Case: Measures ROI of AI positive detection rate for completeness
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_recall_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_recall_business_value IS 'Business value levels of machine learning model recall';

-- Enum: MODEL_PRECISION_BUSINESS_VALUE
-- Description: Defines business value levels of model precision
-- Business Case: Measures ROI of AI positive prediction quality for decisions
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_precision_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_precision_business_value IS 'Business value levels of machine learning model precision';

-- Enum: MODEL_ACCURACY_BUSINESS_VALUE
-- Description: Defines business value levels of model accuracy
-- Business Case: Measures ROI of AI prediction quality for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_accuracy_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PERFORMANCE_VALUE'              -- Performance value
);
COMMENT ON TYPE ai_core.model_accuracy_business_value IS 'Business value levels of machine learning model accuracy';

-- Enum: MODEL_ROBUSTNESS_BUSINESS_VALUE
-- Description: Defines business value levels of model robustness
-- Business Case: Measures ROI of AI resilience for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_robustness_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RELIABILITY_VALUE'              -- Reliability value
);
COMMENT ON TYPE ai_core.model_robustness_business_value IS 'Business value levels of machine learning model robustness';

-- Enum: MODEL_FAIRNESS_BUSINESS_VALUE
-- Description: Defines business value levels of model fairness
-- Business Case: Measures ROI of AI bias mitigation for equity
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_fairness_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ETHICS_VALUE'                   -- Ethics value
);
COMMENT ON TYPE ai_core.model_fairness_business_value IS 'Business value levels of machine learning model fairness';

-- Enum: MODEL_EXPLAINABILITY_BUSINESS_VALUE
-- Description: Defines business value levels of model explainability
-- Business Case: Measures ROI of AI interpretability for trust
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_explainability_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'TRUST_VALUE'                    -- Trust value
);
COMMENT ON TYPE ai_core.model_explainability_business_value IS 'Business value levels of machine learning model explainability';

-- Enum: MODEL_AUDITABILITY_BUSINESS_VALUE
-- Description: Defines business value levels of model auditability
-- Business Case: Measures ROI of AI audit capabilities for governance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_audibility_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'GOVERNANCE_VALUE'               -- Governance value
);
COMMENT ON TYPE ai_core.model_audibility_business_value IS 'Business value levels of machine learning model auditability';

-- Enum: MODEL_PRIVACY_BUSINESS_VALUE
-- Description: Defines business value levels of model privacy
-- Business Case: Measures ROI of AI privacy protection for compliance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_privacy_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE ai_core.model_privacy_business_value IS 'Business value levels of machine learning model privacy';

-- Enum: MODEL_COMPLIANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model compliance
-- Business Case: Measures ROI of AI regulatory compliance for risk management
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_compliance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_compliance_business_value IS 'Business value levels of machine learning model compliance';

-- Enum: MODEL_GOVERNANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model governance
-- Business Case: Measures ROI of AI governance frameworks for oversight
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_governance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_governance_business_value IS 'Business value levels of machine learning model governance';

-- Enum: MODEL_ETHICS_BUSINESS_VALUE
-- Description: Defines business value levels of model ethics
-- Business Case: Measures ROI of AI ethical considerations for reputation
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_ethics_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'REPUTATION_VALUE'               -- Reputation value
);
COMMENT ON TYPE ai_core.model_ethics_business_value IS 'Business value levels of machine learning model ethics';

-- Enum: MODEL_SECURITY_BUSINESS_VALUE
-- Description: Defines business value levels of model security
-- Business Case: Measures ROI of AI security measures for protection
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_security_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_security_business_value IS 'Business value levels of machine learning model security';

-- Enum: MODEL_VERSIONING_BUSINESS_VALUE
-- Description: Defines business value levels of model versioning
-- Business Case: Measures ROI of AI lifecycle management for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_versioning_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'MANAGEMENT_VALUE'               -- Management value
);
COMMENT ON TYPE ai_core.model_versioning_business_value IS 'Business value levels of machine learning model versioning';

-- Enum: MODEL_RETRAINING_BUSINESS_VALUE
-- Description: Defines business value levels of model retraining
-- Business Case: Measures ROI of AI updating for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_retraining_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_retraining_business_value IS 'Business value levels of machine learning model retraining';

-- Enum: MODEL_OPTIMIZATION_BUSINESS_VALUE
-- Description: Defines business value levels of model optimization
-- Business Case: Measures ROI of AI improvement for performance
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_optimization_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PERFORMANCE_VALUE'              -- Performance value
);
COMMENT ON TYPE ai_core.model_optimization_business_value IS 'Business value levels of machine learning model optimization';

-- Enum: MODEL_EVALUATION_BUSINESS_VALUE
-- Description: Defines business value levels of model evaluation
-- Business Case: Measures ROI of AI assessment for quality
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_evaluation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'INSIGHT_VALUE'                  -- Insight value
);
COMMENT ON TYPE ai_core.model_evaluation_business_value IS 'Business value levels of machine learning model evaluation';

-- Enum: MODEL_MONITORING_BUSINESS_VALUE
-- Description: Defines business value levels of model monitoring
-- Business Case: Measures ROI of AI oversight for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_monitoring_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.model_monitoring_business_value IS 'Business value levels of machine learning model monitoring';

-- Enum: MODEL_MAINTENANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model maintenance
-- Business Case: Measures ROI of AI care for reliability
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_maintenance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RELIABILITY_VALUE'              -- Reliability value
);
COMMENT ON TYPE ai_core.model_maintenance_business_value IS 'Business value levels of machine learning model maintenance';

-- Enum: MODEL_DEPLOYMENT_BUSINESS_VALUE
-- Description: Defines business value levels of model deployment
-- Business Case: Measures ROI of AI implementation for impact
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_deployment_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'IMPACT_VALUE'                   -- Impact value
);
COMMENT ON TYPE ai_core.model_deployment_business_value IS 'Business value levels of machine learning model deployment';

-- Enum: MODEL_TRAINING_BUSINESS_VALUE
-- Description: Defines business value levels of model training
-- Business Case: Measures ROI of AI development for accuracy
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_training_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.model_training_business_value IS 'Business value levels of machine learning model training';

-- Enum: MODEL_PERFORMANCE_BUSINESS_VALUE
-- Description: Defines business value levels of model performance
-- Business Case: Measures ROI of AI effectiveness for operations
-- Feature Reference: 1.013
CREATE TYPE ai_core.model_performance_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'IMPACT_VALUE'                   -- Impact value
);
COMMENT ON TYPE ai_core.model_performance_business_value IS 'Business value levels of machine learning model performance';

-- Enum: FEATURE_BUSINESS_VALUE
-- Description: Defines business value levels of ML features
-- Business Case: Measures ROI of feature engineering efforts for model performance
-- Feature Reference: 1.002
CREATE TYPE ai_core.feature_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'ACCURACY_VALUE'                 -- Accuracy value
);
COMMENT ON TYPE ai_core.feature_business_value IS 'Business value levels of machine learning features';

-- Enum: AR_SCENE_BUSINESS_VALUE
-- Description: Defines business value levels of AR scenes
-- Business Case: Measures ROI of AR implementation for user experience
-- Feature Reference: 1.075
CREATE TYPE ai_core.ar_scene_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'PRODUCTIVITY_VALUE'             -- Productivity value
);
COMMENT ON TYPE ai_core.ar_scene_business_value IS 'Business value levels of augmented reality scenes';

-- Enum: CHATBOT_TRAINING_BUSINESS_VALUE
-- Description: Defines business value levels of chatbot training
-- Business Case: Measures ROI of AI training investments for customer service
-- Feature Reference: 1.072
CREATE TYPE ai_core.chatbot_training_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'CUSTOMER_SERVICE_VALUE'         -- Customer service value
);
COMMENT ON TYPE ai_core.chatbot_training_business_value IS 'Business value levels of chatbot training';

-- Enum: AUDIT_LOG_BUSINESS_VALUE
-- Description: Defines business value levels of audit logs
-- Business Case: Measures ROI of audit and compliance systems for governance
-- Feature Reference: 8.002
CREATE TYPE it_incident.audit_log_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'COMPLIANCE_VALUE'               -- Compliance value
);
COMMENT ON TYPE it_incident.audit_log_business_value IS 'Business value levels of audit logs';

-- Enum: METERING_DATA_BUSINESS_VALUE
-- Description: Defines business value levels of metering data
-- Business Case: Measures ROI of data collection and analysis for optimization
-- Feature Reference: 1.001
CREATE TYPE it_incident.metering_data_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'OPTIMIZATION_VALUE'             -- Optimization value
);
COMMENT ON TYPE it_incident.metering_data_business_value IS 'Business value levels of metering data';

-- Enum: BLOCKCHAIN_TRANSACTION_BUSINESS_VALUE
-- Description: Defines business value levels of blockchain transactions
-- Business Case: Measures ROI of blockchain implementations for security
-- Feature Reference: 8.005
CREATE TYPE sec_audit.blockchain_transaction_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'TRUST_VALUE'                    -- Trust value
);
COMMENT ON TYPE sec_audit.blockchain_transaction_business_value IS 'Business value levels of blockchain transactions';

-- Enum: USER_FEEDBACK_BUSINESS_VALUE
-- Description: Defines business value levels of user feedback
-- Business Case: Measures ROI of feedback collection for improvement
-- Feature Reference: 8.007
CREATE TYPE it_incident.user_feedback_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'IMPROVEMENT_VALUE'              -- Improvement value
);
COMMENT ON TYPE it_incident.user_feedback_business_value IS 'Business value levels of user feedback';

-- Enum: AUTO_HEALING_BUSINESS_VALUE
-- Description: Defines business value levels of auto-healing
-- Business Case: Measures ROI of automated remediation for operations
-- Feature Reference: 8.008
CREATE TYPE ai_core.auto_healing_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RELIABILITY_VALUE'              -- Reliability value
);
COMMENT ON TYPE ai_core.auto_healing_business_value IS 'Business value levels of auto-healing operations';

-- Enum: ANOMALY_DETECTION_BUSINESS_VALUE
-- Description: Defines business value levels of anomaly detection
-- Business Case: Measures ROI of monitoring systems for security
-- Feature Reference: 8.006
CREATE TYPE ai_core.anomaly_detection_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_MITIGATION_VALUE'          -- Risk mitigation value
);
COMMENT ON TYPE ai_core.anomaly_detection_business_value IS 'Business value levels of anomaly detection systems';

-- Enum: WORKFLOW_EXECUTION_BUSINESS_VALUE
-- Description: Defines business value levels of workflow execution
-- Business Case: Measures ROI of automation investments for efficiency
-- Feature Reference: 1.027
CREATE TYPE ai_core.workflow_execution_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'AUTOMATION_VALUE'               -- Automation value
);
COMMENT ON TYPE ai_core.workflow_execution_business_value IS 'Business value levels of workflow execution';

-- Enum: SCENARIO_SIMULATION_BUSINESS_VALUE
-- Description: Defines business value levels of scenario simulations
-- Business Case: Measures ROI of predictive modeling for strategic planning
-- Feature Reference: 1.114
CREATE TYPE ai_core.scenario_simulation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RISK_VALUE'                     -- Risk value
);
COMMENT ON TYPE ai_core.scenario_simulation_business_value IS 'Business value levels of scenario simulations';

-- Enum: SATISFACTION_INDEX_BUSINESS_VALUE
-- Description: Defines business value levels of satisfaction indices
-- Business Case: Measures ROI of customer experience investments for retention
-- Feature Reference: 1.027
CREATE TYPE ai_core.satisfaction_index_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'RETENTION_VALUE'                -- Retention value
);
COMMENT ON TYPE ai_core.satisfaction_index_business_value IS 'Business value levels of satisfaction indices';

-- Enum: CORRELATION_BUSINESS_VALUE
-- Description: Defines business value levels of correlations
-- Business Case: Measures ROI of analytical insights for decision-making
-- Feature Reference: 1.002
CREATE TYPE ai_core.correlation_business_value AS ENUM (
    'HIGH_VALUE',                    -- High business value
    'MODERATE_VALUE',                -- Moderate business value
    'LOW_VALUE',                     -- Low business value
    'NO_VALUE',                      -- No business value
    'COST_REDUCTION',                -- Cost reduction value
    'EFFICIENCY_GAIN',               -- Efficiency gain value
    'SCALABILITY_ENHANCEMENT',       -- Scalability enhancement value
    'INSIGHT_VALUE'                  -- Insight value
);
COMMENT ON TYPE ai_core.correlation_business_value IS 'Business value levels of statistical correlations';
