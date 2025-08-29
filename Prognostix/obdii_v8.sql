-- PostgreSQL Schema for Enterprise Risk Management with 11 Modules
-- Version: 8.0
-- Copyright 2025 All rights reserved β ORI Inc.Canada
-- Created: 2025-01-29
-- Last Updated: 2025-08-14
--Author: Awase Khirni Syed
-- Description: Sycliq Prognostix - Vehicle Sensing Module OBD II Platform Diagnostics for End-to-End Analytics and Commerz - Toyota, Honda,
-- BlueDriver, Autel Diagnostics == DTC Codes from Alldata, Identifix, Mitchell 1
-- PostgreSQL Schema Conversion for OBD Diagnostic Tool
-- Ensure necessary extensions are enabled (run once by superuser)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS postgis; -- Needed for spatial indexes if used

-- Create schemas if they don't exist
CREATE SCHEMA IF NOT EXISTS enterprise;

-- Define custom ENUM types (PostgreSQL specific)
CREATE TYPE data_update_frequency_enum AS ENUM(
    'daily', 'weekly', 'monthly', 'quarterly'
);

CREATE TYPE vehicle_subsystem_category_enum AS ENUM(
    'powertrain', 'chassis', 'body', 'network', 'safety', 'ev'
);

CREATE TYPE criticality_enum AS ENUM(
    'critical', 'important', 'standard', 'optional'
);

CREATE TYPE vehicle_type_category_enum AS ENUM(
    'passenger', 'commercial', 'motorcycle', 'heavy_duty', 'other'
);

CREATE TYPE weight_class_enum AS ENUM(
    'light', 'medium', 'heavy'
);

CREATE TYPE drive_type_enum AS ENUM(
    'fwd', 'rwd', 'awd', '4wd'
);

CREATE TYPE transmission_type_enum AS ENUM(
    'manual', 'automatic', 'cvt', 'dsg', 'evt', 'other'
);

CREATE TYPE fuel_type_enum AS ENUM(
    'gasoline', 'diesel', 'hybrid', 'electric', 'lpg', 'cng', 'hydrogen', 'other'
);

CREATE TYPE identification_attribute_type_enum AS ENUM(
    'VIN_pattern', 'ECU_identifier', 'OBD_header', 'CAL_ID', 'CVN', 'VIN_derived'
);

CREATE TYPE identification_source_enum AS ENUM(
    'scan', 'manual', 'api', 'vin_decoder'
);

CREATE TYPE ecu_security_level_enum AS ENUM(
    'none', 'basic', 'high', 'secure'
);

CREATE TYPE diagnostic_tool_type_enum AS ENUM(
    'handheld', 'pc_based', 'mobile', 'cloud', 'mixed'
);

CREATE TYPE ignition_status_enum AS ENUM(
    'off', 'accessory', 'on', 'running'
);

CREATE TYPE diagnostic_session_type_enum AS ENUM(
    'diagnostic', 'programming', 'monitoring', 'configuration'
);

CREATE TYPE trouble_code_severity_level_enum AS ENUM(
    'info', 'warning', 'error', 'critical'
);

CREATE TYPE repair_priority_enum AS ENUM(
    'immediate', 'schedule', 'monitor', 'optional'
);

CREATE TYPE dtc_severity_enum AS ENUM(
    'info', 'low', 'medium', 'high', 'critical'
);

CREATE TYPE repair_complexity_enum AS ENUM(
    'simple', 'moderate', 'complex', 'specialized'
);

CREATE TYPE vehicle_dtc_status_enum AS ENUM(
    'active', 'pending', 'permanent', 'cleared', 'repaired'
);

CREATE TYPE procedure_difficulty_level_enum AS ENUM(
    'easy', 'medium', 'hard', 'expert'
);

CREATE TYPE parameter_data_type_enum AS ENUM(
    'int', 'float', 'boolean', 'string', 'bitmask'
);

CREATE TYPE trend_direction_enum AS ENUM(
    'up', 'down', 'stable', 'volatile'
);

CREATE TYPE pid_access_level_enum AS ENUM(
    'basic', 'advanced', 'dealer', 'engineering'
);

CREATE TYPE readiness_status_enum AS ENUM(
    'complete', 'incomplete', 'not_available', 'error'
);

CREATE TYPE readiness_result_enum AS ENUM(
    'passed', 'failed', 'not_ready', 'aborted'
);

CREATE TYPE diagnostic_test_category_enum AS ENUM(
    'functional', 'parameter', 'actuation', 'programming', 'security'
);

CREATE TYPE test_access_level_enum AS ENUM(
    'basic', 'advanced', 'dealer', 'engineering'
);

CREATE TYPE test_result_status_enum AS ENUM(
    'passed', 'failed', 'skipped', 'aborted', 'in_progress', 'pending'
);

CREATE TYPE maintenance_type_enum AS ENUM(
    'scheduled', 'unscheduled', 'recall', 'preventive', 'corrective'
);

CREATE TYPE maintenance_status_enum AS ENUM(
    'pending', 'in_progress', 'completed', 'cancelled', 'deferred'
);

CREATE TYPE user_status_enum AS ENUM(
    'active', 'inactive', 'pending_verification', 'locked', 'deleted'
);

CREATE TYPE user_role_type_enum AS ENUM(
    'admin', 'technician', 'manager', 'viewer', 'api_user'
);

CREATE TYPE standard_type_enum AS ENUM(
    'emissions', 'safety', 'communication', 'diagnostic', 'security'
);

CREATE TYPE translation_context_enum AS ENUM(
    'dtc_description', 'dtc_repair', 'pid_description', 'ui_label', 'report_section'
);

CREATE TYPE integration_type_enum AS ENUM(
    'parts_catalog', 'service_history', 'telematics', 'vin_decoder', 'payment_gateway'
);

CREATE TYPE integration_status_enum AS ENUM(
    'active', 'inactive', 'error', 'pending_config'
);

CREATE TYPE interface_type_enum AS ENUM(
    'obd2', 'j1939', 'can', 'kwp2000', 'uds', 'doip'
);

CREATE TYPE interface_medium_enum AS ENUM(
    'wired', 'bluetooth', 'wifi', 'cellular'
);

CREATE TYPE package_type_enum AS ENUM(
    'firmware', 'software', 'calibration', 'configuration'
);

CREATE TYPE package_status_enum AS ENUM(
    'development', 'testing', 'released', 'deprecated', 'archived'
);

CREATE TYPE history_event_type_enum AS ENUM(
    'installed', 'updated', 'removed', 'failed_update', 'rollback'
);

CREATE TYPE config_change_type_enum AS ENUM(
    'modified', 'added', 'removed', 'reset_default'
);

CREATE TYPE history_status_enum AS ENUM(
    'success', 'failed', 'pending', 'partial'
);

CREATE TYPE relationship_type_enum AS ENUM(
    'cause', 'symptom', 'component', 'system', 'correlated'
);

CREATE TYPE knowledge_type_enum AS ENUM(
    'fact', 'rule', 'heuristic', 'procedure', 'relationship'
);

CREATE TYPE alert_severity_enum AS ENUM(
    'info', 'warning', 'error', 'critical'
);

CREATE TYPE alert_status_enum AS ENUM(
    'new', 'acknowledged', 'in_progress', 'resolved', 'closed'
);

CREATE TYPE pattern_type_enum AS ENUM(
    'temporal', 'frequency', 'correlation', 'anomaly', 'sequence'
);

CREATE TYPE model_status_enum AS ENUM(
    'training', 'validating', 'active', 'inactive', 'error', 'retired'
);

CREATE TYPE prediction_type_enum AS ENUM(
    'classification', 'regression', 'clustering', 'anomaly_detection', 'recommendation'
);

CREATE TYPE custom_param_data_type_enum AS ENUM(
    'string', 'number', 'boolean', 'json', 'array'
);

CREATE TYPE bulletin_urgency_enum AS ENUM(
    'immediate', 'soon', 'next_service', 'monitor'
);

CREATE TYPE gateway_type_enum AS ENUM(
    'obd', 'can', 'ethernet', 'wireless', 'telematics'
);

CREATE TYPE network_type_enum AS ENUM(
    'can', 'lin', 'flexray', 'most', 'ethernet', 'lvds'
);

CREATE TYPE component_status_enum AS ENUM(
    'active', 'replaced', 'faulty', 'unknown', 'recalled'
);

CREATE TYPE firmware_install_method_enum AS ENUM(
    'dealer', 'ota', 'service', 'manufacturer'
);

CREATE TYPE can_frame_type_enum AS ENUM(
    'data', 'remote', 'error', 'overload'
);

CREATE TYPE can_frame_format_enum AS ENUM(
    'standard', 'extended'
);

CREATE TYPE cluster_severity_enum AS ENUM(
    'low', 'medium', 'high', 'critical'
);

CREATE TYPE engine_status_enum AS ENUM(
    'on', 'off', 'idle', 'cranking'
);

CREATE TYPE network_status_enum AS ENUM(
    'active', 'sleep', 'wake', 'error'
);

CREATE TYPE connectivity_status_enum AS ENUM(
    'online', 'offline', 'limited'
);

CREATE TYPE compliance_check_result_enum AS ENUM(
    'pass', 'fail', 'pending', 'exempt'
);

CREATE TYPE ui_translation_context_enum AS ENUM(
    'label', 'tooltip', 'error', 'menu', 'button', 'title'
);

CREATE TYPE ownership_type_enum AS ENUM(
    'private', 'fleet', 'lease', 'rental', 'dealer'
);

CREATE TYPE setting_data_type_enum AS ENUM(
    'string', 'number', 'boolean', 'json', 'array'
);

-- Table Definitions --

-- 1. Manufacturers Table
CREATE TABLE Manufacturers (
    manufacturer_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    headquarters_country VARCHAR(50),
    website VARCHAR(255),
    technical_contact_email VARCHAR(100),
    obd_compliance_date DATE,
    logo_url VARCHAR(255),
    data_update_frequency data_update_frequency_enum,
    api_integration_available BOOLEAN DEFAULT FALSE,
    api_documentation_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Manufacturers IS 'Stores information about vehicle manufacturers.';
COMMENT ON COLUMN Manufacturers.data_update_frequency IS 'How often the manufacturer updates their diagnostic data.';
COMMENT ON COLUMN Manufacturers.api_integration_available IS 'Indicates if the manufacturer provides an API for data integration.';
CREATE INDEX idx_manufacturers_name ON Manufacturers (name);

-- Trigger function to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply the trigger to Manufacturers table
CREATE TRIGGER update_manufacturers_modtime
BEFORE UPDATE ON Manufacturers
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 2. Vehicle Subsystems Table
CREATE TABLE VehicleSubsystems (
    subsystem_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    category vehicle_subsystem_category_enum NOT NULL,
    description TEXT,
    parent_subsystem_id INT NULL,
    icon_class VARCHAR(50),
    criticality criticality_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE VehicleSubsystems IS 'Categorizes different systems within a vehicle (e.g., Powertrain, Body).';
COMMENT ON COLUMN VehicleSubsystems.category IS 'Broad category of the subsystem.';
COMMENT ON COLUMN VehicleSubsystems.criticality IS 'Importance level of the subsystem for vehicle operation.';
CREATE INDEX idx_vehiclesubsystems_name_category ON VehicleSubsystems (name, category);
CREATE TRIGGER update_vehiclesubsystems_modtime
BEFORE UPDATE ON VehicleSubsystems
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 3. Vehicle Types Table
CREATE TABLE VehicleTypes (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    description TEXT,
    category vehicle_type_category_enum NOT NULL,
    icon_class VARCHAR(50),
    weight_class weight_class_enum,
    drive_type drive_type_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE VehicleTypes IS 'Classifies different types of vehicles (e.g., Sedan, SUV, Truck).';
COMMENT ON COLUMN VehicleTypes.weight_class IS 'Gross vehicle weight rating category.';
COMMENT ON COLUMN VehicleTypes.drive_type IS 'Vehicle drivetrain configuration (FWD, RWD, AWD, 4WD).';
CREATE INDEX idx_vehicletypes_type_name ON VehicleTypes (type_name);
CREATE TRIGGER update_vehicletypes_modtime
BEFORE UPDATE ON VehicleTypes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 4. Vehicles Table
CREATE TABLE Vehicles (
    vehicle_id VARCHAR(17) PRIMARY KEY, -- VIN
    manufacturer_id INT NOT NULL,
    type_id INT,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL CHECK (year BETWEEN 1886 AND EXTRACT(YEAR FROM CURRENT_DATE) + 2),
    generation VARCHAR(30),
    engine_code VARCHAR(30),
    engine_displacement_cc INT,
    transmission_type transmission_type_enum,
    fuel_type fuel_type_enum,
    firmware_version VARCHAR(50),
    ecu_software_version VARCHAR(50),
    country_of_origin VARCHAR(50),
    production_date DATE,
    gross_vehicle_weight_kg INT,
    number_of_axles SMALLINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id),
    FOREIGN KEY (type_id) REFERENCES VehicleTypes(type_id)
);
COMMENT ON TABLE Vehicles IS 'Stores details about specific vehicles, identified by VIN.';
COMMENT ON COLUMN Vehicles.vehicle_id IS 'VIN (Vehicle Identification Number)';
COMMENT ON COLUMN Vehicles.year IS 'Model year of the vehicle.';
CREATE INDEX idx_vehicles_model_year ON Vehicles (model, year);
CREATE INDEX idx_vehicles_manufacturer_id ON Vehicles (manufacturer_id);
CREATE INDEX idx_vehicles_production_date ON Vehicles (production_date);
CREATE TRIGGER update_vehicles_modtime
BEFORE UPDATE ON Vehicles
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 5. Vehicle Identification Attributes Table
CREATE TABLE VehicleIdentificationAttributes (
    attribute_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    attribute_type identification_attribute_type_enum NOT NULL,
    attribute_value VARCHAR(100) NOT NULL,
    confidence_score DECIMAL(5,2) DEFAULT 1.00,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    source identification_source_enum,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE VehicleIdentificationAttributes IS 'Stores various identifiers associated with a vehicle beyond the VIN.';
COMMENT ON COLUMN VehicleIdentificationAttributes.confidence_score IS 'Confidence level in the accuracy of the attribute.';
COMMENT ON COLUMN VehicleIdentificationAttributes.is_verified IS 'Indicates if the attribute has been manually or automatically verified.';
CREATE INDEX idx_vehicleidattr_type_value ON VehicleIdentificationAttributes (attribute_type, attribute_value);
CREATE INDEX idx_vehicleidattr_source ON VehicleIdentificationAttributes (source);
CREATE TRIGGER update_vehicleidentificationattributes_modtime
BEFORE UPDATE ON VehicleIdentificationAttributes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 6. Vehicle ECUs Table
CREATE TABLE VehicleECUs (
    ecu_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    subsystem_id INT,
    ecu_name VARCHAR(50) NOT NULL,
    ecu_address VARCHAR(10) NOT NULL, -- Hex address, e.g., 7E0
    hardware_version VARCHAR(30),
    software_version VARCHAR(30),
    programming_date DATE,
    is_gateway BOOLEAN DEFAULT FALSE,
    ecu_manufacturer VARCHAR(50),
    flash_size_kb INT,
    ram_size_kb INT,
    processor_type VARCHAR(50),
    security_level ecu_security_level_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id),
    UNIQUE (vehicle_id, ecu_address)
);
COMMENT ON TABLE VehicleECUs IS 'Details about Electronic Control Units (ECUs) within a vehicle.';
COMMENT ON COLUMN VehicleECUs.ecu_address IS 'Diagnostic address of the ECU (e.g., Hex address like 7E0).';
COMMENT ON COLUMN VehicleECUs.is_gateway IS 'Indicates if this ECU acts as a gateway between networks.';
COMMENT ON COLUMN VehicleECUs.security_level IS 'Security level implemented by the ECU.';
CREATE INDEX idx_vehicleecus_vehicle_name ON VehicleECUs (vehicle_id, ecu_name);
CREATE INDEX idx_vehicleecus_address ON VehicleECUs (ecu_address);
CREATE TRIGGER update_vehicleecus_modtime
BEFORE UPDATE ON VehicleECUs
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 7. OBD Protocols Table
CREATE TABLE ObdProtocols (
    protocol_id SERIAL PRIMARY KEY,
    protocol_code VARCHAR(20) UNIQUE NOT NULL, -- SAE/ISO standard code
    protocol_name VARCHAR(50) NOT NULL,
    description TEXT,
    data_rate_kbps INT,
    pin_configuration VARCHAR(100),
    is_legacy BOOLEAN DEFAULT FALSE,
    introduced_year INT,
    physical_layer VARCHAR(50),
    network_topology VARCHAR(50),
    maximum_nodes INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ObdProtocols IS 'Information about OBD communication protocols (e.g., ISO 15765-4 CAN).';
COMMENT ON COLUMN ObdProtocols.protocol_code IS 'Standardized code for the protocol (e.g., SAE J1850 PWM).';
COMMENT ON COLUMN ObdProtocols.network_topology IS 'Typical network layout (e.g., Bus, Star).';
CREATE INDEX idx_obdprotocols_code ON ObdProtocols (protocol_code);
CREATE INDEX idx_obdprotocols_introduced_year ON ObdProtocols (introduced_year);
CREATE TRIGGER update_obdprotocols_modtime
BEFORE UPDATE ON ObdProtocols
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 8. Diagnostic Tools Table
CREATE TABLE DiagnosticTools (
    tool_id SERIAL PRIMARY KEY,
    manufacturer VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    hardware_version VARCHAR(30),
    software_version VARCHAR(30),
    firmware_version VARCHAR(30),
    supported_protocols TEXT, -- Consider JSONB or separate mapping table
    release_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    tool_type diagnostic_tool_type_enum NOT NULL,
    connectivity_options JSONB, -- Store as JSONB for flexibility
    api_support BOOLEAN DEFAULT FALSE,
    last_software_update DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE DiagnosticTools IS 'Details about the diagnostic tools used.';
COMMENT ON COLUMN DiagnosticTools.supported_protocols IS 'List of OBD protocols supported by the tool.';
COMMENT ON COLUMN DiagnosticTools.connectivity_options IS 'Connectivity methods (e.g., {"bluetooth": true, "wifi": false, "usb": true}) stored as JSON';
-- Continuing PostgreSQL Schema Conversion for OBD Diagnostic Tool

-- 9. Diagnostic Sessions Table
CREATE TABLE DiagnosticSessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id VARCHAR(17) NOT NULL,
    protocol_id INT,
    tool_id INT,
    session_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP WITH TIME ZONE NULL,
    connection_success BOOLEAN NOT NULL,
    connection_duration_ms INT,
    voltage DECIMAL(5,2), -- Vehicle battery voltage during session
    ignition_status ignition_status_enum NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    altitude DECIMAL(10, 2),
    environment_temperature DECIMAL(5, 2),
    notes TEXT,
    mobile_device_id VARCHAR(100),
    session_type diagnostic_session_type_enum,
    security_level ecu_security_level_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (protocol_id) REFERENCES ObdProtocols(protocol_id),
    FOREIGN KEY (tool_id) REFERENCES DiagnosticTools(tool_id)
);
COMMENT ON TABLE DiagnosticSessions IS 'Records of diagnostic sessions performed on vehicles.';
COMMENT ON COLUMN DiagnosticSessions.voltage IS 'Vehicle battery voltage during session.';
COMMENT ON COLUMN DiagnosticSessions.session_type IS 'Type of diagnostic session performed.';
CREATE INDEX idx_diagnosticsessions_vehicle_start ON DiagnosticSessions (vehicle_id, session_start);
CREATE INDEX idx_diagnosticsessions_tool_id ON DiagnosticSessions (tool_id);
CREATE INDEX idx_diagnosticsessions_session_type ON DiagnosticSessions (session_type);
CREATE TRIGGER update_diagnosticsessions_modtime
BEFORE UPDATE ON DiagnosticSessions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 10. Trouble Code Categories Table
CREATE TABLE TroubleCodeCategories (
    category_id SERIAL PRIMARY KEY,
    code_prefix CHAR(1) NOT NULL, -- P, B, C, U
    category_name VARCHAR(50) NOT NULL,
    system_affected VARCHAR(100) NOT NULL,
    description TEXT,
    severity_level trouble_code_severity_level_enum NOT NULL DEFAULT 'warning',
    subsystem_id INT,
    repair_priority repair_priority_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE TroubleCodeCategories IS 'Categories of diagnostic trouble codes (P-Powertrain, B-Body, etc.).';
COMMENT ON COLUMN TroubleCodeCategories.code_prefix IS 'First letter of DTC code (P, B, C, U).';
COMMENT ON COLUMN TroubleCodeCategories.repair_priority IS 'Recommended priority for addressing issues in this category.';
CREATE INDEX idx_troublecodecategories_code_prefix ON TroubleCodeCategories (code_prefix);
CREATE INDEX idx_troublecodecategories_severity ON TroubleCodeCategories (severity_level);
CREATE TRIGGER update_troublecodecategories_modtime
BEFORE UPDATE ON TroubleCodeCategories
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 11. Trouble Codes Table
CREATE TABLE TroubleCodes (
    dtc_id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL, -- Format: [P/B/C/U]XXXX
    category_id INT,
    description TEXT NOT NULL,
    severity dtc_severity_enum NOT NULL,
    is_standard BOOLEAN DEFAULT TRUE,
    repair_complexity repair_complexity_enum NOT NULL DEFAULT 'moderate',
    common_causes TEXT,
    typical_repair_hours DECIMAL(4,2),
    standard_code VARCHAR(20),
    regulation_reference VARCHAR(50),
    affected_components JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES TroubleCodeCategories(category_id)
);
COMMENT ON TABLE TroubleCodes IS 'Diagnostic Trouble Codes (DTCs) definitions.';
COMMENT ON COLUMN TroubleCodes.code IS 'Format: [P/B/C/U]XXXX (e.g., P0300).';
COMMENT ON COLUMN TroubleCodes.is_standard IS 'Whether this is a standard OBD-II code or manufacturer-specific.';
COMMENT ON COLUMN TroubleCodes.affected_components IS 'JSON array of components typically affected by this code.';
CREATE INDEX idx_troublecodes_code ON TroubleCodes (code);
CREATE INDEX idx_troublecodes_category_id ON TroubleCodes (category_id);
CREATE INDEX idx_troublecodes_severity ON TroubleCodes (severity);
CREATE TRIGGER update_troublecodes_modtime
BEFORE UPDATE ON TroubleCodes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 12. Diagnostic Test Sequences Table
CREATE TABLE DiagnosticTestSequences (
    sequence_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    steps JSONB NOT NULL,
    expected_duration_min INT,
    required_tools JSONB,
    safety_instructions TEXT,
    prerequisite_dtcs JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE DiagnosticTestSequences IS 'Predefined sequences of diagnostic tests for troubleshooting.';
COMMENT ON COLUMN DiagnosticTestSequences.steps IS 'JSON array of test steps with instructions.';
COMMENT ON COLUMN DiagnosticTestSequences.prerequisite_dtcs IS 'DTCs that should be present before running this sequence.';
CREATE INDEX idx_diagnostictestsequences_name ON DiagnosticTestSequences (name);
CREATE TRIGGER update_diagnostictestsequences_modtime
BEFORE UPDATE ON DiagnosticTestSequences
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 13. Sequence to DTC Mapping Table
CREATE TABLE SequenceToDtcMapping (
    mapping_id SERIAL PRIMARY KEY,
    sequence_id INT NOT NULL,
    dtc_id INT NOT NULL,
    effectiveness_rating SMALLINT CHECK (effectiveness_rating BETWEEN 1 AND 5),
    is_primary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sequence_id) REFERENCES DiagnosticTestSequences(sequence_id),
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE SequenceToDtcMapping IS 'Maps diagnostic test sequences to the DTCs they help diagnose.';
COMMENT ON COLUMN SequenceToDtcMapping.effectiveness_rating IS 'Rating (1-5) of how effective this sequence is for this DTC.';
COMMENT ON COLUMN SequenceToDtcMapping.is_primary IS 'Whether this is the primary recommended sequence for this DTC.';
CREATE INDEX idx_sequencetodtcmapping_sequence_id ON SequenceToDtcMapping (sequence_id);
CREATE INDEX idx_sequencetodtcmapping_dtc_id ON SequenceToDtcMapping (dtc_id);
CREATE TRIGGER update_sequencetodtcmapping_modtime
BEFORE UPDATE ON SequenceToDtcMapping
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 14. Trouble Code Translations Table
CREATE TABLE TroubleCodeTranslations (
    translation_id SERIAL PRIMARY KEY,
    dtc_id INT NOT NULL,
    language_code CHAR(2) NOT NULL, -- ISO 639-1
    locale VARCHAR(5) NOT NULL, -- e.g., en-US, fr-CA
    translated_description TEXT NOT NULL,
    translated_repair_advice TEXT,
    translated_common_causes TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    translator_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE TroubleCodeTranslations IS 'Translations of trouble code descriptions and repair advice.';
COMMENT ON COLUMN TroubleCodeTranslations.language_code IS 'ISO 639-1 language code (e.g., en, fr, de).';
COMMENT ON COLUMN TroubleCodeTranslations.locale IS 'Language locale (e.g., en-US, fr-CA).';
CREATE INDEX idx_troublecodetranslations_dtc_locale ON TroubleCodeTranslations (dtc_id, language_code, locale);
CREATE TRIGGER update_troublecodetranslations_modtime
BEFORE UPDATE ON TroubleCodeTranslations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 15. Vehicle Trouble Codes Table
CREATE TABLE VehicleTroubleCodes (
    vehicle_dtc_id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    dtc_id INT NOT NULL,
    detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status vehicle_dtc_status_enum NOT NULL,
    cleared_by VARCHAR(100),
    cleared_on TIMESTAMP WITH TIME ZONE NULL,
    repair_description TEXT,
    repair_cost DECIMAL(10,2),
    freeze_frame_data JSONB,
    subsystem_id INT,
    recurrence_count INT DEFAULT 1,
    first_occurrence TIMESTAMP WITH TIME ZONE,
    last_occurrence TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id),
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id),
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE VehicleTroubleCodes IS 'Records of DTCs detected in specific vehicles.';
COMMENT ON COLUMN VehicleTroubleCodes.freeze_frame_data IS 'Snapshot of vehicle parameters when the DTC was set.';
COMMENT ON COLUMN VehicleTroubleCodes.recurrence_count IS 'Number of times this DTC has occurred in this vehicle.';
CREATE INDEX idx_vehicletroublecodes_session_dtc ON VehicleTroubleCodes (session_id, dtc_id);
CREATE INDEX idx_vehicletroublecodes_status ON VehicleTroubleCodes (status);
CREATE INDEX idx_vehicletroublecodes_detection ON VehicleTroubleCodes (detection_timestamp);
CREATE TRIGGER update_vehicletroublecodes_modtime
BEFORE UPDATE ON VehicleTroubleCodes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 16. Diagnostic Procedures Table
CREATE TABLE DiagnosticProcedures (
    procedure_id SERIAL PRIMARY KEY,
    dtc_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    procedure_steps JSONB NOT NULL,
    required_tools TEXT,
    estimated_time_min INT,
    difficulty_level procedure_difficulty_level_enum NOT NULL,
    safety_notes TEXT,
    verification_steps JSONB,
    typical_parts_needed JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE DiagnosticProcedures IS 'Step-by-step procedures for diagnosing and repairing DTCs.';
COMMENT ON COLUMN DiagnosticProcedures.procedure_steps IS 'JSON array of diagnostic steps.';
COMMENT ON COLUMN DiagnosticProcedures.verification_steps IS 'Steps to verify the repair was successful.';
CREATE INDEX idx_diagnosticprocedures_dtc_id ON DiagnosticProcedures (dtc_id);
CREATE INDEX idx_diagnosticprocedures_difficulty ON DiagnosticProcedures (difficulty_level);
CREATE TRIGGER update_diagnosticprocedures_modtime
BEFORE UPDATE ON DiagnosticProcedures
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 17. Parameter IDs Table
CREATE TABLE ParameterIds (
    pid_id SERIAL PRIMARY KEY,
    pid_hex VARCHAR(4) NOT NULL,
    description TEXT NOT NULL,
    unit VARCHAR(20),
    min_value DECIMAL(15, 5),
    max_value DECIMAL(15, 5),
    formula TEXT,
    data_type parameter_data_type_enum NOT NULL,
    byte_length SMALLINT NOT NULL,
    is_standard BOOLEAN DEFAULT TRUE,
    refresh_rate_hz DECIMAL(5,2), -- Typical update frequency
    subsystem_id INT,
    is_critical BOOLEAN DEFAULT FALSE,
    normal_range JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE ParameterIds IS 'OBD-II Parameter IDs (PIDs) for requesting live data.';
COMMENT ON COLUMN ParameterIds.pid_hex IS 'Hexadecimal code for the parameter (e.g., 0C for RPM).';
COMMENT ON COLUMN ParameterIds.formula IS 'Mathematical formula to convert raw data to actual value.';
COMMENT ON COLUMN ParameterIds.normal_range IS 'JSON object with min/max values for normal operation.';
CREATE INDEX idx_parameterids_pid_hex ON ParameterIds (pid_hex);
CREATE INDEX idx_parameterids_subsystem_id ON ParameterIds (subsystem_id);
CREATE TRIGGER update_parameterids_modtime
BEFORE UPDATE ON ParameterIds
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 18. Live Data Readings Table
CREATE TABLE LiveDataReadings (
    reading_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    pid_id INT NOT NULL,
    reading_value DECIMAL(20, 10) NOT NULL,
    reading_timestamp TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    signal_quality SMALLINT, -- 0-100 scale
    is_out_of_range BOOLEAN DEFAULT FALSE,
    is_anomaly BOOLEAN DEFAULT FALSE,
    anomaly_score DECIMAL(5,2),
    trend_direction trend_direction_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id),
    FOREIGN KEY (pid_id) REFERENCES ParameterIds(pid_id)
);
COMMENT ON TABLE LiveDataReadings IS 'Real-time parameter readings from vehicles.';
COMMENT ON COLUMN LiveDataReadings.signal_quality IS 'Quality of the signal on a scale of 0-100.';
COMMENT ON COLUMN LiveDataReadings.is_anomaly IS 'Flag indicating if this reading is anomalous.';
CREATE INDEX idx_livedatareadings_session_pid_time ON LiveDataReadings (session_id, pid_id, reading_timestamp);
CREATE INDEX idx_livedatareadings_anomaly ON LiveDataReadings (is_anomaly);
-- No update trigger needed as readings are immutable

-- 19. Manufacturer-Specific PIDs Table
CREATE TABLE ManufacturerPids (
    manufacturer_pid_id SERIAL PRIMARY KEY,
    manufacturer_id INT NOT NULL,
    pid_hex VARCHAR(10) NOT NULL,
    description TEXT,
    unit VARCHAR(20),
    decoding_instructions TEXT,
    applicable_models TEXT,
    introduced_year INT,
    discontinued_year INT,
    is_protected BOOLEAN DEFAULT FALSE,
    access_level pid_access_level_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id)
);
COMMENT ON TABLE ManufacturerPids IS 'Manufacturer-specific Parameter IDs not in the standard OBD-II set.';
COMMENT ON COLUMN ManufacturerPids.decoding_instructions IS 'Instructions for decoding the raw data.';
COMMENT ON COLUMN ManufacturerPids.is_protected IS 'Whether this PID requires security access.';
CREATE INDEX idx_manufacturerpids_manufacturer_pid ON ManufacturerPids (manufacturer_id, pid_hex);
CREATE INDEX idx_manufacturerpids_access_level ON ManufacturerPids (access_level);
CREATE TRIGGER update_manufacturerpids_modtime
BEFORE UPDATE ON ManufacturerPids
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 20. Readiness Tests Table
CREATE TABLE ReadinessTests (
    test_id SERIAL PRIMARY KEY,
    test_code VARCHAR(20) UNIQUE NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    description TEXT,
    system_affected VARCHAR(100) NOT NULL,
    is_continuous_monitor BOOLEAN NOT NULL,
    drive_cycle_required BOOLEAN DEFAULT FALSE,
    typical_completion_time_min INT,
    regulation_reference VARCHAR(50),
    subsystem_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE ReadinessTests IS 'OBD-II readiness monitors/tests.';
COMMENT ON COLUMN ReadinessTests.is_continuous_monitor IS 'Whether this is a continuous or non-continuous monitor.';
COMMENT ON COLUMN ReadinessTests.drive_cycle_required IS 'Whether a specific drive cycle is needed to complete this test.';
CREATE INDEX idx_readinesstests_test_code ON ReadinessTests (test_code);
CREATE INDEX idx_readinesstests_system_affected ON ReadinessTests (system_affected);
CREATE TRIGGER update_readinesstests_modtime
BEFORE UPDATE ON ReadinessTests
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 21. Vehicle Readiness Table
CREATE TABLE VehicleReadiness (
    readiness_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    test_id INT NOT NULL,
    status readiness_status_enum NOT NULL,
    result readiness_result_enum NULL,
    completion_percentage SMALLINT,
    test_duration_ms INT,
    conditions_met TEXT,
    extended_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id),
    FOREIGN KEY (test_id) REFERENCES ReadinessTests(test_id)
);
COMMENT ON TABLE VehicleReadiness IS 'Status of readiness monitors for specific vehicles.';
COMMENT ON COLUMN VehicleReadiness.completion_percentage IS 'Percentage of test completion (0-100).';
COMMENT ON COLUMN VehicleReadiness.extended_data IS 'Additional data about the test status.';
CREATE INDEX idx_vehiclereadiness_session_test ON VehicleReadiness (session_id, test_id);
CREATE INDEX idx_vehiclereadiness_result ON VehicleReadiness (result);
CREATE TRIGGER update_vehiclereadiness_modtime
BEFORE UPDATE ON VehicleReadiness
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 22. Diagnostic Tests Table
CREATE TABLE DiagnosticTests (
    test_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    test_commands JSONB NOT NULL, -- Sequence of OBD commands to execute
    expected_responses JSONB, -- Expected responses for validation
    is_destructive BOOLEAN DEFAULT FALSE,
    category diagnostic_test_category_enum NOT NULL,
    safety_warnings TEXT,
    required_access_level test_access_level_enum,
    typical_duration_sec INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE DiagnosticTests IS 'Predefined diagnostic tests that can be performed on vehicles.';
COMMENT ON COLUMN DiagnosticTests.test_commands IS 'JSON array of OBD commands to execute.';
COMMENT ON COLUMN DiagnosticTests.is_destructive IS 'Whether this test could potentially alter vehicle state.';
CREATE INDEX idx_diagnostictests_name ON DiagnosticTests (name);
CREATE INDEX idx_diagnostictests_category ON DiagnosticTests (category);
CREATE TRIGGER update_diagnostictests_modtime
BEFORE UPDATE ON DiagnosticTests
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 23. Performed Diagnostic Tests Table
CREATE TABLE PerformedDiagnosticTests (
    performed_test_id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    test_id INT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    status test_result_status_enum NOT NULL,
    result_data JSONB,
    notes TEXT,
    performed_by INT, -- User ID
    execution_log TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id),
    FOREIGN KEY (test_id) REFERENCES DiagnosticTests(test_id)
);
COMMENT ON TABLE PerformedDiagnosticTests IS 'Records of diagnostic tests performed during sessions.';
COMMENT ON COLUMN PerformedDiagnosticTests.result_data IS 'JSON data with test results.';
COMMENT ON COLUMN PerformedDiagnosticTests.execution_log IS 'Log of test execution steps and responses.';
CREATE INDEX idx_performeddiagnostictests_session ON PerformedDiagnosticTests (session_id);
CREATE INDEX idx_performeddiagnostictests_test ON PerformedDiagnosticTests (test_id);
CREATE INDEX idx_performeddiagnostictests_status ON PerformedDiagnosticTests (status);
CREATE TRIGGER update_performeddiagnostictests_modtime
BEFORE UPDATE ON PerformedDiagnosticTests
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 24. Diagnostic Session Notes Table
CREATE TABLE DiagnosticSessionNotes (
    note_id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    note_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INT, -- User ID
    note_type VARCHAR(50),
    is_private BOOLEAN DEFAULT FALSE,
    tags TEXT[],
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id)
);
COMMENT ON TABLE DiagnosticSessionNotes IS 'Notes added to diagnostic sessions.';
COMMENT ON COLUMN DiagnosticSessionNotes.note_type IS 'Type of note (e.g., observation, recommendation).';
COMMENT ON COLUMN DiagnosticSessionNotes.tags IS 'Array of tags for categorizing notes.';
CREATE INDEX idx_diagnosticsessionnotes_session ON DiagnosticSessionNotes (session_id);
CREATE INDEX idx_diagnosticsessionnotes_created_at ON DiagnosticSessionNotes (created_at);
-- No update trigger needed as notes are immutable

-- 25. Diagnostic Session Files Table
CREATE TABLE DiagnosticSessionFiles (
    file_id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(512) NOT NULL,
    file_type VARCHAR(50),
    file_size_bytes BIGINT,
    upload_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    uploaded_by INT, -- User ID
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    md5_hash VARCHAR(32),
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id)
);
COMMENT ON TABLE DiagnosticSessionFiles IS 'Files attached to diagnostic sessions (logs, screenshots, etc.).';
COMMENT ON COLUMN DiagnosticSessionFiles.file_type IS 'MIME type or file extension.';
COMMENT ON COLUMN DiagnosticSessionFiles.md5_hash IS 'MD5 hash of the file for integrity verification.';
CREATE INDEX idx_diagnosticsessionfiles_session ON DiagnosticSessionFiles (session_id);
CREATE INDEX idx_diagnosticsessionfiles_file_type ON DiagnosticSessionFiles (file_type);
-- No update trigger needed as files are immutable

-- 26. Vehicle Maintenance Records Table
CREATE TABLE VehicleMaintenanceRecords (
    record_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    service_date DATE NOT NULL,
    odometer_reading INT,
    maintenance_type maintenance_type_enum NOT NULL,
    description TEXT NOT NULL,
    performed_by VARCHAR(100),
    service_center_id INT,
    cost DECIMAL(10,2),
    invoice_number VARCHAR(50),
    parts_used TEXT,
    labor_hours DECIMAL(5,2),
    status maintenance_status_enum NOT NULL DEFAULT 'completed',
    next_service_date DATE,
    next_service_odometer INT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (service_center_id) REFERENCES ServiceCenters(service_center_id)
);
COMMENT ON TABLE VehicleMaintenanceRecords IS 'Records of maintenance performed on vehicles.';
COMMENT ON COLUMN VehicleMaintenanceRecords.maintenance_type IS 'Type of maintenance performed.';
COMMENT ON COLUMN VehicleMaintenanceRecords.next_service_date IS 'Recommended date for next service.';
CREATE INDEX idx_vehiclemaintenancerecords_vehicle ON VehicleMaintenanceRecords (vehicle_id);
CREATE INDEX idx_vehiclemaintenancerecords_service_date ON VehicleMaintenanceRecords (service_date);
CREATE INDEX idx_vehiclemaintenancerecords_status ON VehicleMaintenanceRecords (status);
CREATE TRIGGER update_vehiclemaintenancerecords_modtime
BEFORE UPDATE ON VehicleMaintenanceRecords
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 27. Service Centers Table
CREATE TABLE ServiceCenters (
    service_center_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(255),
    hours_of_operation TEXT,
    specialties TEXT,
    is_dealer BOOLEAN DEFAULT FALSE,
    manufacturer_id INT,
    rating DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id)
);
COMMENT ON TABLE ServiceCenters IS 'Information about service centers where maintenance is performed.';
COMMENT ON COLUMN ServiceCenters.is_dealer IS 'Whether this is an authorized dealer service center.';
COMMENT ON COLUMN ServiceCenters.specialties IS 'Areas of specialization (e.g., transmission, electrical).';
CREATE INDEX idx_servicecenters_name ON ServiceCenters (name);
CREATE INDEX idx_servicecenters_location ON ServiceCenters (country, state, city);
CREATE INDEX idx_servicecenters_manufacturer ON ServiceCenters (manufacturer_id);
CREATE TRIGGER update_servicecenters_modtime
BEFORE UPDATE ON ServiceCenters
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 28. Repair Orders Table
CREATE TABLE RepairOrders (
    order_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    service_center_id INT,
    order_date DATE NOT NULL,
    completion_date DATE,
    total_cost DECIMAL(10,2),
    labor_cost DECIMAL(10,2),
    parts_cost DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    customer_id INT,
    technician_id INT,
    status VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50),
    invoice_number VARCHAR(50),
    warranty_claim BOOLEAN DEFAULT FALSE,
    warranty_details TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (service_center_id) REFERENCES ServiceCenters(service_center_id)
);
COMMENT ON TABLE RepairOrders IS 'Repair orders for vehicle maintenance and repairs.';
COMMENT ON COLUMN RepairOrders.warranty_claim IS 'Whether this repair was covered under warranty.';
COMMENT ON COLUMN RepairOrders.status IS 'Status of the repair order (e.g., open, completed, cancelled).';
CREATE INDEX idx_repairorders_vehicle ON RepairOrders (vehicle_id);
CREATE INDEX idx_repairorders_order_date ON RepairOrders (order_date);
CREATE INDEX idx_repairorders_status ON RepairOrders (status);
CREATE TRIGGER update_repairorders_modtime
BEFORE UPDATE ON RepairOrders
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 29. Repair Order Items Table
CREATE TABLE RepairOrderItems (
    item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    description TEXT NOT NULL,
    procedure_id INT,
    dtc_id INT,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2),
    labor_hours DECIMAL(5,2),
    labor_rate DECIMAL(10,2),
    part_number VARCHAR(50),
    part_description TEXT,
    is_warranty_covered BOOLEAN DEFAULT FALSE,
    technician_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES RepairOrders(order_id),
    FOREIGN KEY (procedure_id) REFERENCES DiagnosticProcedures(procedure_id),
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE RepairOrderItems IS 'Line items within repair orders.';
COMMENT ON COLUMN RepairOrderItems.procedure_id IS 'Reference to the diagnostic procedure if applicable.';
COMMENT ON COLUMN RepairOrderItems.dtc_id IS 'Reference to the trouble code being addressed if applicable.';
CREATE INDEX idx_repairorderitems_order ON RepairOrderItems (order_id);
CREATE INDEX idx_repairorderitems_procedure ON RepairOrderItems (procedure_id);
CREATE INDEX idx_repairorderitems_dtc ON RepairOrderItems (dtc_id);
CREATE TRIGGER update_repairorderitems_modtime
BEFORE UPDATE ON RepairOrderItems
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 30. Users Table
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    status user_status_enum NOT NULL DEFAULT 'active',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INT DEFAULT 0,
    account_locked_until TIMESTAMP WITH TIME ZONE,
    password_reset_token VARCHAR(100),
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(100),
    profile_image_url VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language_preference VARCHAR(10) DEFAULT 'en-US'
);
COMMENT ON TABLE Users IS 'User accounts for the diagnostic system.';
COMMENT ON COLUMN Users.password_hash IS 'Securely hashed password.';
COMMENT ON COLUMN Users.status IS 'Current account status.';
CREATE INDEX idx_users_username ON Users (username);
CREATE INDEX idx_users_email ON Users (email);
CREATE INDEX idx_users_status ON Users (status);
CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON Users
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 31. User Roles Table
CREATE TABLE UserRoles (
    user_role_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    role_name user_role_type_enum NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (assigned_by) REFERENCES Users(user_id),
    UNIQUE (user_id, role_name)
);
COMMENT ON TABLE UserRoles IS 'Roles assigned to users.';
COMMENT ON COLUMN UserRoles.role_name IS 'Type of role assigned to the user.';
COMMENT ON COLUMN UserRoles.expires_at IS 'Expiration date for temporary roles.';
CREATE INDEX idx_userroles_user ON UserRoles (user_id);
CREATE INDEX idx_userroles_role ON UserRoles (role_name);
CREATE TRIGGER update_userroles_modtime
BEFORE UPDATE ON UserRoles
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 32. Roles Table
CREATE TABLE Roles (
    role_name user_role_type_enum PRIMARY KEY,
    description TEXT,
    permissions JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE Roles IS 'Defines available roles and their permissions.';
COMMENT ON COLUMN Roles.permissions IS 'JSON array of permissions granted to this role.';
CREATE TRIGGER update_roles_modtime
BEFORE UPDATE ON Roles
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 33. User Permissions Table
CREATE TABLE UserPermissions (
    permission_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    permission_key VARCHAR(100) NOT NULL,
    permission_value BOOLEAN DEFAULT TRUE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    granted_by INT,
    expires_at TIMESTAMP WITH TIME ZONE NULL,
    scope VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (granted_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE UserPermissions IS 'Individual permissions granted to users.';
COMMENT ON COLUMN UserPermissions.permission_key IS 'Unique identifier for the permission.';
COMMENT ON COLUMN UserPermissions.scope IS 'Optional scope limiting where the permission applies.';
CREATE INDEX idx_userpermissions_user ON UserPermissions (user_id);
CREATE INDEX idx_userpermissions_permission ON UserPermissions (permission_key);
CREATE TRIGGER update_userpermissions_modtime
BEFORE UPDATE ON UserPermissions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 34. User Activity Log Table
CREATE TABLE UserActivityLog (
    activity_id BIGSERIAL PRIMARY KEY,
    user_id INT,
    activity_type VARCHAR(50),
    description TEXT,
    activity_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_id VARCHAR(100),
    location_data JSONB,
    duration_sec INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (device_id) REFERENCES MobileDevices(device_id)
);
COMMENT ON TABLE UserActivityLog IS 'Log of user activities in the system.';
COMMENT ON COLUMN UserActivityLog.ip_address IS 'IP address from which the activity originated.';
COMMENT ON COLUMN UserActivityLog.location_data IS 'Geographic location data if available.';
CREATE INDEX idx_useractivitylog_user ON UserActivityLog (user_id);
CREATE INDEX idx_useractivitylog_timestamp ON UserActivityLog (activity_timestamp);
-- No update trigger needed as log entries are immutable

-- 35. Mobile Devices Table
CREATE TABLE MobileDevices (
    device_id VARCHAR(100) PRIMARY KEY,
    user_id INT,
    device_name VARCHAR(100),
    device_type VARCHAR(50),
    os_name VARCHAR(50),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    last_active TIMESTAMP WITH TIME ZONE,
    push_token VARCHAR(255),
    device_settings JSONB,
    is_authorized BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE MobileDevices IS 'Mobile devices used to access the system.';
COMMENT ON COLUMN MobileDevices.device_id IS 'Unique identifier for the device.';
COMMENT ON COLUMN MobileDevices.push_token IS 'Token for sending push notifications.';
CREATE INDEX idx_mobiledevices_user ON MobileDevices (user_id);
CREATE INDEX idx_mobiledevices_last_active ON MobileDevices (last_active);
CREATE TRIGGER update_mobiledevices_modtime
BEFORE UPDATE ON MobileDevices
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 36. Audit Log Table
CREATE TABLE AuditLog (
    log_id BIGSERIAL PRIMARY KEY,
    user_id INT,
    action_type VARCHAR(50) NOT NULL,
    table_affected VARCHAR(50),
    record_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'success',
    details TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE AuditLog IS 'Audit trail of system changes.';
COMMENT ON COLUMN AuditLog.action_type IS 'Type of action performed (e.g., insert, update, delete).';
COMMENT ON COLUMN AuditLog.old_values IS 'Previous values before change.';
COMMENT ON COLUMN AuditLog.new_values IS 'New values after change.';
CREATE INDEX idx_auditlog_user ON AuditLog (user_id);
CREATE INDEX idx_auditlog_action ON AuditLog (action_type);
CREATE INDEX idx_auditlog_timestamp ON AuditLog (timestamp);
-- No update trigger needed as log entries are immutable

-- 37. System Settings Table
CREATE TABLE SystemSettings (
    setting_id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INT,
    data_type setting_data_type_enum NOT NULL,
    min_value VARCHAR(50),
    max_value VARCHAR(50),
    options JSONB,
    category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE SystemSettings IS 'System-wide configuration settings.';
COMMENT ON COLUMN SystemSettings.setting_key IS 'Unique identifier for the setting.';
COMMENT ON COLUMN SystemSettings.is_public IS 'Whether this setting is visible to regular users.';
CREATE INDEX idx_systemsettings_category ON SystemSettings (category);
CREATE INDEX idx_systemsettings_is_public ON SystemSettings (is_public);
CREATE TRIGGER update_systemsettings_modtime
BEFORE UPDATE ON SystemSettings
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 38. Regional Standards Table
CREATE TABLE RegionalStandards (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(2),
    standard_type standard_type_enum NOT NULL,
    standard_name VARCHAR(100) NOT NULL,
    standard_version VARCHAR(50),
    effective_date DATE,
    expiration_date DATE,
    description TEXT,
    requirements TEXT,
    reference_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE RegionalStandards IS 'Regional regulatory standards for vehicles.';
COMMENT ON COLUMN RegionalStandards.country_code IS 'ISO 3166-1 alpha-2 country code.';
COMMENT ON COLUMN RegionalStandards.standard_type IS 'Type of standard (emissions, safety, etc.).';
CREATE INDEX idx_regionalstandards_region ON RegionalStandards (region_name);
CREATE INDEX idx_regionalstandards_standard_type ON RegionalStandards (standard_type);
CREATE INDEX idx_regionalstandards_effective_date ON RegionalStandards (effective_date);
CREATE TRIGGER update_regionalstandards_modtime
BEFORE UPDATE ON RegionalStandards
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 39. UI Translations Table
CREATE TABLE UiTranslations (
    translation_id SERIAL PRIMARY KEY,
    key_name VARCHAR(100) NOT NULL,
    language_code CHAR(2) NOT NULL,
    locale VARCHAR(5) NOT NULL,
    translated_text TEXT NOT NULL,
    context ui_translation_context_enum NOT NULL,
    screen_name VARCHAR(50),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by INT,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES Users(user_id),
    UNIQUE (key_name, language_code, locale, context)
);
COMMENT ON TABLE UiTranslations IS 'Translations for UI elements.';
COMMENT ON COLUMN UiTranslations.key_name IS 'Identifier for the UI element.';
COMMENT ON COLUMN UiTranslations.context IS 'Context where the translation is used.';
CREATE INDEX idx_uitranslations_language ON UiTranslations (language_code);
CREATE INDEX idx_uitranslations_context ON UiTranslations (context);
CREATE TRIGGER update_uitranslations_modtime
BEFORE UPDATE ON UiTranslations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 40. API Integrations Table
CREATE TABLE ApiIntegrations (
    integration_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    integration_type integration_type_enum NOT NULL,
    api_url VARCHAR(255),
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    auth_method VARCHAR(50),
    status integration_status_enum NOT NULL DEFAULT 'active',
    last_sync TIMESTAMP WITH TIME ZONE,
    sync_frequency_minutes INT,
    config_data JSONB,
    error_count INT DEFAULT 0,
    last_error TEXT,
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE ApiIntegrations IS 'External API integrations.';
COMMENT ON COLUMN ApiIntegrations.integration_type IS 'Type of integration (e.g., parts catalog, service history).';
COMMENT ON COLUMN ApiIntegrations.config_data IS 'Configuration data for the integration.';
CREATE INDEX idx_apiintegrations_name ON ApiIntegrations (name);
CREATE INDEX idx_apiintegrations_type ON ApiIntegrations (integration_type);
CREATE INDEX idx_apiintegrations_status ON ApiIntegrations (status);
CREATE TRIGGER update_apiintegrations_modtime
BEFORE UPDATE ON ApiIntegrations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();
-- Continuing PostgreSQL Schema Conversion for OBD Diagnostic Tool (Part 3)

-- 41. Vehicle Interfaces Table
CREATE TABLE VehicleInterfaces (
    interface_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    interface_type interface_type_enum NOT NULL,
    connector_type VARCHAR(50),
    pin_count INT,
    pin_layout TEXT,
    communication_medium interface_medium_enum,
    max_data_rate_kbps INT,
    voltage_levels VARCHAR(50),
    physical_dimensions VARCHAR(100),
    image_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE VehicleInterfaces IS 'Physical interfaces for connecting to vehicles.';
COMMENT ON COLUMN VehicleInterfaces.interface_type IS 'Type of interface (e.g., OBD2, J1939).';
COMMENT ON COLUMN VehicleInterfaces.pin_layout IS 'Description of pin layout and functions.';
CREATE INDEX idx_vehicleinterfaces_name ON VehicleInterfaces (name);
CREATE INDEX idx_vehicleinterfaces_type ON VehicleInterfaces (interface_type);
CREATE TRIGGER update_vehicleinterfaces_modtime
BEFORE UPDATE ON VehicleInterfaces
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 42. Vehicle Interface Mapping Table
CREATE TABLE VehicleInterfaceMapping (
    mapping_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    interface_id INT NOT NULL,
    connector_location VARCHAR(100),
    pin_mapping JSONB,
    notes TEXT,
    verified BOOLEAN DEFAULT FALSE,
    verified_by INT,
    verified_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (interface_id) REFERENCES VehicleInterfaces(interface_id),
    FOREIGN KEY (verified_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE VehicleInterfaceMapping IS 'Maps vehicles to their compatible interfaces.';
COMMENT ON COLUMN VehicleInterfaceMapping.connector_location IS 'Physical location of the connector in the vehicle.';
COMMENT ON COLUMN VehicleInterfaceMapping.pin_mapping IS 'JSON mapping of pins to functions for this vehicle.';
CREATE INDEX idx_vehicleinterfacemapping_vehicle ON VehicleInterfaceMapping (vehicle_id);
CREATE INDEX idx_vehicleinterfacemapping_interface ON VehicleInterfaceMapping (interface_id);
CREATE TRIGGER update_vehicleinterfacemapping_modtime
BEFORE UPDATE ON VehicleInterfaceMapping
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 43. Software Packages Table
CREATE TABLE SoftwarePackages (
    package_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(50) NOT NULL,
    package_type package_type_enum NOT NULL,
    description TEXT,
    release_date DATE,
    manufacturer_id INT,
    compatible_ecus TEXT,
    file_size_bytes BIGINT,
    checksum VARCHAR(64),
    download_url VARCHAR(255),
    installation_instructions TEXT,
    status package_status_enum DEFAULT 'released',
    release_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id)
);
COMMENT ON TABLE SoftwarePackages IS 'Software packages for vehicle ECUs.';
COMMENT ON COLUMN SoftwarePackages.package_type IS 'Type of software package.';
COMMENT ON COLUMN SoftwarePackages.compatible_ecus IS 'List of ECUs compatible with this package.';
CREATE INDEX idx_softwarepackages_name_version ON SoftwarePackages (name, version);
CREATE INDEX idx_softwarepackages_manufacturer ON SoftwarePackages (manufacturer_id);
CREATE INDEX idx_softwarepackages_status ON SoftwarePackages (status);
CREATE TRIGGER update_softwarepackages_modtime
BEFORE UPDATE ON SoftwarePackages
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 44. Vehicle Software History Table
CREATE TABLE VehicleSoftwareHistory (
    history_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    ecu_id INT NOT NULL,
    package_id INT,
    event_type history_event_type_enum NOT NULL,
    previous_version VARCHAR(50),
    new_version VARCHAR(50),
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    performed_by INT,
    status history_status_enum NOT NULL,
    notes TEXT,
    log_file_path VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id),
    FOREIGN KEY (package_id) REFERENCES SoftwarePackages(package_id),
    FOREIGN KEY (performed_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE VehicleSoftwareHistory IS 'History of software changes to vehicle ECUs.';
COMMENT ON COLUMN VehicleSoftwareHistory.event_type IS 'Type of software event.';
COMMENT ON COLUMN VehicleSoftwareHistory.log_file_path IS 'Path to detailed log file for this event.';
CREATE INDEX idx_vehiclesoftwarehistory_vehicle ON VehicleSoftwareHistory (vehicle_id);
CREATE INDEX idx_vehiclesoftwarehistory_ecu ON VehicleSoftwareHistory (ecu_id);
CREATE INDEX idx_vehiclesoftwarehistory_timestamp ON VehicleSoftwareHistory (event_timestamp);
-- No update trigger needed as history entries are immutable

-- 45. Vehicle Software Configurations Table
CREATE TABLE VehicleSoftwareConfigurations (
    config_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    ecu_id INT NOT NULL,
    config_name VARCHAR(100) NOT NULL,
    config_value TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_custom BOOLEAN DEFAULT FALSE,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(100),
    checksum VARCHAR(64),
    requires_restart BOOLEAN DEFAULT FALSE,
    valid_values JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id)
);
COMMENT ON TABLE VehicleSoftwareConfigurations IS 'Configuration settings for vehicle ECU software.';
COMMENT ON COLUMN VehicleSoftwareConfigurations.is_custom IS 'Whether this is a custom configuration or factory default.';
COMMENT ON COLUMN VehicleSoftwareConfigurations.valid_values IS 'JSON array of valid values for this configuration.';
CREATE INDEX idx_vehiclesoftwareconfigs_vehicle_ecu ON VehicleSoftwareConfigurations (vehicle_id, ecu_id);
CREATE INDEX idx_vehiclesoftwareconfigs_config_name ON VehicleSoftwareConfigurations (config_name);
CREATE TRIGGER update_vehiclesoftwareconfigs_modtime
BEFORE UPDATE ON VehicleSoftwareConfigurations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 46. Diagnostic Code History Table
CREATE TABLE DiagnosticCodeHistory (
    history_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    dtc_id INT NOT NULL,
    first_detected TIMESTAMP WITH TIME ZONE NOT NULL,
    last_detected TIMESTAMP WITH TIME ZONE NOT NULL,
    occurrence_count INT NOT NULL DEFAULT 1,
    average_interval_days DECIMAL(10,2),
    is_chronic BOOLEAN DEFAULT FALSE,
    chronic_score DECIMAL(5,2) DEFAULT 0.0,
    last_mileage INT,
    subsystem_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id),
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id),
    UNIQUE (vehicle_id, dtc_id)
);
COMMENT ON TABLE DiagnosticCodeHistory IS 'Historical record of DTCs for each vehicle.';
COMMENT ON COLUMN DiagnosticCodeHistory.occurrence_count IS 'Number of times this DTC has occurred in this vehicle.';
COMMENT ON COLUMN DiagnosticCodeHistory.is_chronic IS 'Whether this is a recurring issue.';
CREATE INDEX idx_diagnosticcodehistory_vehicle ON DiagnosticCodeHistory (vehicle_id);
CREATE INDEX idx_diagnosticcodehistory_dtc ON DiagnosticCodeHistory (dtc_id);
CREATE INDEX idx_diagnosticcodehistory_chronic ON DiagnosticCodeHistory (is_chronic);
CREATE TRIGGER update_diagnosticcodehistory_modtime
BEFORE UPDATE ON DiagnosticCodeHistory
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 47. Diagnostic Code Relationships Table
CREATE TABLE DiagnosticCodeRelationships (
    relationship_id SERIAL PRIMARY KEY,
    primary_dtc_id INT NOT NULL,
    related_dtc_id INT NOT NULL,
    relationship_type relationship_type_enum NOT NULL,
    confidence_score DECIMAL(5,2) DEFAULT 0.80,
    notes TEXT,
    evidence_source VARCHAR(100),
    occurrence_count INT DEFAULT 0,
    last_observed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (primary_dtc_id) REFERENCES TroubleCodes(dtc_id),
    FOREIGN KEY (related_dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE DiagnosticCodeRelationships IS 'Relationships between different DTCs.';
COMMENT ON COLUMN DiagnosticCodeRelationships.relationship_type IS 'Type of relationship between the DTCs.';
COMMENT ON COLUMN DiagnosticCodeRelationships.confidence_score IS 'Confidence level in this relationship (0-1).';
CREATE INDEX idx_diagnosticcoderelationships_primary ON DiagnosticCodeRelationships (primary_dtc_id);
CREATE INDEX idx_diagnosticcoderelationships_related ON DiagnosticCodeRelationships (related_dtc_id);
CREATE INDEX idx_diagnosticcoderelationships_type ON DiagnosticCodeRelationships (relationship_type);
CREATE TRIGGER update_diagnosticcoderelationships_modtime
BEFORE UPDATE ON DiagnosticCodeRelationships
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 48. Diagnostic Code Statistics Table
CREATE TABLE DiagnosticCodeStatistics (
    stat_id SERIAL PRIMARY KEY,
    dtc_id INT NOT NULL,
    occurrence_count INT DEFAULT 0,
    avg_repair_time_min INT,
    avg_repair_cost DECIMAL(10,2),
    most_common_vehicle VARCHAR(100),
    most_common_solution TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    failure_rate_per_100k DECIMAL(10,2),
    seasonal_variation JSONB,
    mileage_distribution JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dtc_id) REFERENCES TroubleCodes(dtc_id)
);
COMMENT ON TABLE DiagnosticCodeStatistics IS 'Statistical data about DTCs across all vehicles.';
COMMENT ON COLUMN DiagnosticCodeStatistics.occurrence_count IS 'Total number of occurrences across all vehicles.';
COMMENT ON COLUMN DiagnosticCodeStatistics.seasonal_variation IS 'JSON data showing seasonal patterns.';
CREATE INDEX idx_diagnosticcodestatistics_dtc ON DiagnosticCodeStatistics (dtc_id);
CREATE INDEX idx_diagnosticcodestatistics_occurrence ON DiagnosticCodeStatistics (occurrence_count);
CREATE TRIGGER update_diagnosticcodestatistics_modtime
BEFORE UPDATE ON DiagnosticCodeStatistics
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 49. Diagnostic Knowledge Graph Table
CREATE TABLE DiagnosticKnowledgeGraph (
    node_id SERIAL PRIMARY KEY,
    node_type knowledge_type_enum NOT NULL,
    title VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    related_dtcs INT[],
    related_subsystems INT[],
    related_nodes INT[],
    confidence_score DECIMAL(5,2) DEFAULT 1.00,
    source_reference TEXT,
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE DiagnosticKnowledgeGraph IS 'Knowledge graph for diagnostic information.';
COMMENT ON COLUMN DiagnosticKnowledgeGraph.node_type IS 'Type of knowledge node.';
COMMENT ON COLUMN DiagnosticKnowledgeGraph.related_dtcs IS 'Array of related DTC IDs.';
CREATE INDEX idx_diagnosticknowledgegraph_title ON DiagnosticKnowledgeGraph (title);
CREATE INDEX idx_diagnosticknowledgegraph_type ON DiagnosticKnowledgeGraph (node_type);
CREATE INDEX idx_diagnosticknowledgegraph_related_dtcs ON DiagnosticKnowledgeGraph USING GIN (related_dtcs);
CREATE TRIGGER update_diagnosticknowledgegraph_modtime
BEFORE UPDATE ON DiagnosticKnowledgeGraph
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 50. Predictive Maintenance Alerts Table
CREATE TABLE PredictiveMaintenanceAlerts (
    alert_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    subsystem_id INT,
    alert_type VARCHAR(50) NOT NULL,
    severity alert_severity_enum NOT NULL,
    description TEXT NOT NULL,
    predicted_failure_date DATE,
    confidence_score DECIMAL(5,2),
    recommended_action TEXT,
    data_points JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    status alert_status_enum DEFAULT 'new',
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id),
    FOREIGN KEY (acknowledged_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE PredictiveMaintenanceAlerts IS 'Predictive maintenance alerts for vehicles.';
COMMENT ON COLUMN PredictiveMaintenanceAlerts.alert_type IS 'Type of alert (e.g., component wear, fluid degradation).';
COMMENT ON COLUMN PredictiveMaintenanceAlerts.data_points IS 'JSON data supporting this prediction.';
CREATE INDEX idx_predictivemaintenancealerts_vehicle ON PredictiveMaintenanceAlerts (vehicle_id);
CREATE INDEX idx_predictivemaintenancealerts_severity ON PredictiveMaintenanceAlerts (severity);
CREATE INDEX idx_predictivemaintenancealerts_status ON PredictiveMaintenanceAlerts (status);
CREATE TRIGGER update_predictivemaintenancealerts_modtime
BEFORE UPDATE ON PredictiveMaintenanceAlerts
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 51. Vehicle Data Patterns Table
CREATE TABLE VehicleDataPatterns (
    pattern_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    pattern_type pattern_type_enum NOT NULL,
    pattern_name VARCHAR(100) NOT NULL,
    description TEXT,
    detection_algorithm VARCHAR(50),
    parameters JSONB,
    first_detected TIMESTAMP WITH TIME ZONE,
    last_detected TIMESTAMP WITH TIME ZONE,
    occurrence_count INT DEFAULT 1,
    significance_score DECIMAL(5,2),
    related_subsystem_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (related_subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE VehicleDataPatterns IS 'Patterns detected in vehicle data.';
COMMENT ON COLUMN VehicleDataPatterns.pattern_type IS 'Type of pattern detected.';
COMMENT ON COLUMN VehicleDataPatterns.parameters IS 'JSON parameters defining this pattern.';
CREATE INDEX idx_vehicledatapatterns_vehicle ON VehicleDataPatterns (vehicle_id);
CREATE INDEX idx_vehicledatapatterns_type ON VehicleDataPatterns (pattern_type);
CREATE INDEX idx_vehicledatapatterns_significance ON VehicleDataPatterns (significance_score);
CREATE TRIGGER update_vehicledatapatterns_modtime
BEFORE UPDATE ON VehicleDataPatterns
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 52. Machine Learning Models Table
CREATE TABLE MachineLearningModels (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL,
    description TEXT,
    version VARCHAR(20) NOT NULL,
    training_date TIMESTAMP WITH TIME ZONE,
    accuracy_score DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    training_data_size INT,
    features_used JSONB,
    hyperparameters JSONB,
    model_file_path VARCHAR(255),
    status model_status_enum DEFAULT 'training',
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE MachineLearningModels IS 'Machine learning models for vehicle diagnostics.';
COMMENT ON COLUMN MachineLearningModels.model_type IS 'Type of machine learning model.';
COMMENT ON COLUMN MachineLearningModels.features_used IS 'JSON array of features used by the model.';
CREATE INDEX idx_machinelearningmodels_name_version ON MachineLearningModels (model_name, version);
CREATE INDEX idx_machinelearningmodels_status ON MachineLearningModels (status);
CREATE TRIGGER update_machinelearningmodels_modtime
BEFORE UPDATE ON MachineLearningModels
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 53. Model Types Table
CREATE TABLE ModelTypes (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    description TEXT,
    typical_use_case TEXT,
    required_data_points TEXT,
    minimum_training_samples INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ModelTypes IS 'Types of machine learning models used in the system.';
COMMENT ON COLUMN ModelTypes.typical_use_case IS 'Typical application for this model type.';
COMMENT ON COLUMN ModelTypes.required_data_points IS 'Data points required for this model type.';
CREATE INDEX idx_modeltypes_type_name ON ModelTypes (type_name);
CREATE TRIGGER update_modeltypes_modtime
BEFORE UPDATE ON ModelTypes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 54. Model Predictions Table
CREATE TABLE ModelPredictions (
    prediction_id SERIAL PRIMARY KEY,
    model_id INT NOT NULL,
    vehicle_id VARCHAR(17) NOT NULL,
    prediction_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    prediction_type prediction_type_enum NOT NULL,
    prediction_value TEXT NOT NULL,
    confidence_score DECIMAL(5,4),
    input_features JSONB,
    actual_outcome TEXT,
    was_correct BOOLEAN,
    feedback_notes TEXT,
    explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES MachineLearningModels(model_id),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE ModelPredictions IS 'Predictions made by machine learning models.';
COMMENT ON COLUMN ModelPredictions.prediction_type IS 'Type of prediction made.';
COMMENT ON COLUMN ModelPredictions.input_features IS 'JSON data of input features used for this prediction.';
CREATE INDEX idx_modelpredictions_vehicle ON ModelPredictions (vehicle_id);
CREATE INDEX idx_modelpredictions_prediction_type ON ModelPredictions (prediction_type);
CREATE TRIGGER update_modelpredictions_modtime
BEFORE UPDATE ON ModelPredictions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 55. Vehicle Custom Parameters Table
CREATE TABLE VehicleCustomParameters (
    custom_param_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    param_name VARCHAR(100) NOT NULL,
    param_value TEXT,
    data_type custom_param_data_type_enum NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    is_protected BOOLEAN DEFAULT FALSE,
    validation_rules JSONB,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE VehicleCustomParameters IS 'Custom parameters for vehicles.';
COMMENT ON COLUMN VehicleCustomParameters.param_name IS 'Name of the custom parameter.';
COMMENT ON COLUMN VehicleCustomParameters.validation_rules IS 'JSON rules for validating parameter values.';
CREATE INDEX idx_vehiclecustomparameters_vehicle_param ON VehicleCustomParameters (vehicle_id, param_name);
CREATE INDEX idx_vehiclecustomparameters_data_type ON VehicleCustomParameters (data_type);
CREATE TRIGGER update_vehiclecustomparameters_modtime
BEFORE UPDATE ON VehicleCustomParameters
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 56. Diagnostic Service Bulletins Table
CREATE TABLE DiagnosticServiceBulletins (
    bulletin_id SERIAL PRIMARY KEY,
    manufacturer_id INT NOT NULL,
    bulletin_number VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    issue_date DATE NOT NULL,
    affected_models JSONB NOT NULL,
    affected_years VARCHAR(100),
    description TEXT NOT NULL,
    symptoms TEXT,
    diagnostic_procedures TEXT,
    repair_procedures TEXT,
    is_recall BOOLEAN DEFAULT FALSE,
    recall_number VARCHAR(50),
    urgency bulletin_urgency_enum,
    parts_affected JSONB,
    labor_time_estimate DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id)
);
COMMENT ON TABLE DiagnosticServiceBulletins IS 'Technical service bulletins from manufacturers.';
COMMENT ON COLUMN DiagnosticServiceBulletins.affected_models IS 'JSON array of affected model names.';
COMMENT ON COLUMN DiagnosticServiceBulletins.is_recall IS 'Whether this bulletin is a safety recall.';
CREATE INDEX idx_diagnosticservicebulletins_bulletin_number ON DiagnosticServiceBulletins (bulletin_number);
CREATE INDEX idx_diagnosticservicebulletins_manufacturer ON DiagnosticServiceBulletins (manufacturer_id);
CREATE INDEX idx_diagnosticservicebulletins_issue_date ON DiagnosticServiceBulletins (issue_date);
CREATE TRIGGER update_diagnosticservicebulletins_modtime
BEFORE UPDATE ON DiagnosticServiceBulletins
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 57. Vehicle Communication Gateways Table
CREATE TABLE VehicleCommunicationGateways (
    gateway_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    gateway_type gateway_type_enum NOT NULL,
    protocol_support JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    hw_version VARCHAR(50),
    sw_version VARCHAR(50),
    last_communication TIMESTAMP WITH TIME ZONE,
    security_level ecu_security_level_enum,
    data_rate_mbps DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE VehicleCommunicationGateways IS 'Communication gateways for vehicle diagnostics.';
COMMENT ON COLUMN VehicleCommunicationGateways.gateway_type IS 'Type of communication gateway.';
COMMENT ON COLUMN VehicleCommunicationGateways.protocol_support IS 'JSON array of supported protocols.';
CREATE INDEX idx_vehiclecommunicationgateways_vehicle ON VehicleCommunicationGateways (vehicle_id);
CREATE INDEX idx_vehiclecommunicationgateways_type ON VehicleCommunicationGateways (gateway_type);
CREATE TRIGGER update_vehiclecommunicationgateways_modtime
BEFORE UPDATE ON VehicleCommunicationGateways
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 58. Vehicle Network Topology Table
CREATE TABLE VehicleNetworkTopology (
    topology_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    ecu_id INT NOT NULL,
    network_type network_type_enum NOT NULL,
    bus_name VARCHAR(50) NOT NULL,
    bus_speed INT, -- Speed in kbps
    termination_resistor_present BOOLEAN DEFAULT FALSE,
    node_position INT, -- Position in the bus topology
    is_backbone BOOLEAN DEFAULT FALSE,
    is_redundant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id)
);
COMMENT ON TABLE VehicleNetworkTopology IS 'Network topology of vehicle ECUs.';
COMMENT ON COLUMN VehicleNetworkTopology.network_type IS 'Type of network (e.g., CAN, LIN).';
COMMENT ON COLUMN VehicleNetworkTopology.node_position IS 'Position of the ECU in the network topology.';
CREATE INDEX idx_vehiclenetworktopology_vehicle_network ON VehicleNetworkTopology (vehicle_id, network_type);
CREATE INDEX idx_vehiclenetworktopology_bus_name ON VehicleNetworkTopology (bus_name);
CREATE TRIGGER update_vehiclenetworktopology_modtime
BEFORE UPDATE ON VehicleNetworkTopology
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 59. Diagnostic Security Access Table
CREATE TABLE DiagnosticSecurityAccess (
    access_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    ecu_id INT NOT NULL,
    access_level VARCHAR(50) NOT NULL,
    algorithm_name VARCHAR(100),
    seed_length INT,
    key_length INT,
    security_supported BOOLEAN DEFAULT FALSE,
    documentation_url VARCHAR(255),
    known_vulnerabilities JSONB,
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id)
);
COMMENT ON TABLE DiagnosticSecurityAccess IS 'Security access information for vehicle ECUs.';
COMMENT ON COLUMN DiagnosticSecurityAccess.access_level IS 'Security access level (e.g., level 1, level 3).';
COMMENT ON COLUMN DiagnosticSecurityAccess.known_vulnerabilities IS 'JSON array of known security vulnerabilities.';
CREATE INDEX idx_diagnosticsecurityaccess_ecu ON DiagnosticSecurityAccess (ecu_id);
CREATE INDEX idx_diagnosticsecurityaccess_access_level ON DiagnosticSecurityAccess (access_level);
CREATE TRIGGER update_diagnosticsecurityaccess_modtime
BEFORE UPDATE ON DiagnosticSecurityAccess
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 60. Vehicle Customization Profiles Table
CREATE TABLE VehicleCustomizationProfiles (
    profile_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    profile_name VARCHAR(100) NOT NULL,
    description TEXT,
    configuration JSONB NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    is_protected BOOLEAN DEFAULT FALSE,
    version VARCHAR(20),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE VehicleCustomizationProfiles IS 'Customization profiles for vehicles.';
COMMENT ON COLUMN VehicleCustomizationProfiles.configuration IS 'JSON configuration data for this profile.';
COMMENT ON COLUMN VehicleCustomizationProfiles.is_active IS 'Whether this profile is currently active.';
CREATE INDEX idx_vehiclecustomizationprofiles_vehicle ON VehicleCustomizationProfiles (vehicle_id);
CREATE INDEX idx_vehiclecustomizationprofiles_is_active ON VehicleCustomizationProfiles (is_active);
CREATE TRIGGER update_vehiclecustomizationprofiles_modtime
BEFORE UPDATE ON VehicleCustomizationProfiles
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 61. Vehicle Communication Logs Table
CREATE TABLE VehicleCommunicationLogs (
    log_id BIGSERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    protocol VARCHAR(50) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    raw_data TEXT,
    decoded_data TEXT,
    timestamp TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE,
    response_time_ms INT,
    ecu_id INT,
    session_id UUID,
    signal_strength DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id),
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id)
);
COMMENT ON TABLE VehicleCommunicationLogs IS 'Logs of communication with vehicle ECUs.';
COMMENT ON COLUMN VehicleCommunicationLogs.direction IS 'Direction of communication (inbound/outbound).';
COMMENT ON COLUMN VehicleCommunicationLogs.raw_data IS 'Raw data sent or received.';
CREATE INDEX idx_vehiclecommunicationlogs_vehicle_timestamp ON VehicleCommunicationLogs (vehicle_id, timestamp);
CREATE INDEX idx_vehiclecommunicationlogs_protocol ON VehicleCommunicationLogs (protocol);
-- No update trigger needed as logs are immutable

-- 62. Vehicle Ownership History Table
CREATE TABLE VehicleOwnershipHistory (
    ownership_id BIGSERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    owner_name VARCHAR(100),
    owner_contact VARCHAR(100),
    ownership_start DATE,
    ownership_end DATE,
    ownership_type ownership_type_enum,
    registration_number VARCHAR(50),
    registration_state VARCHAR(50),
    odometer_at_transfer INT,
    transfer_reason VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE VehicleOwnershipHistory IS 'History of vehicle ownership.';
COMMENT ON COLUMN VehicleOwnershipHistory.ownership_type IS 'Type of ownership (e.g., private, fleet).';
COMMENT ON COLUMN VehicleOwnershipHistory.odometer_at_transfer IS 'Odometer reading at time of ownership transfer.';
CREATE INDEX idx_vehicleownershiphistory_vehicle ON VehicleOwnershipHistory (vehicle_id);
CREATE INDEX idx_vehicleownershiphistory_ownership_start ON VehicleOwnershipHistory (ownership_start);
CREATE TRIGGER update_vehicleownershiphistory_modtime
BEFORE UPDATE ON VehicleOwnershipHistory
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 63. Vehicle Components Table
CREATE TABLE VehicleComponents (
    component_id BIGSERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    component_type VARCHAR(100) NOT NULL,
    serial_number VARCHAR(100),
    installed_date DATE,
    replaced_date DATE,
    status component_status_enum DEFAULT 'active',
    expected_lifetime_months INT,
    maintenance_interval_months INT,
    last_maintenance_date DATE,
    subsystem_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (subsystem_id) REFERENCES VehicleSubsystems(subsystem_id)
);
COMMENT ON TABLE VehicleComponents IS 'Physical components installed in vehicles.';
COMMENT ON COLUMN VehicleComponents.component_type IS 'Type of component (e.g., alternator, water pump).';
COMMENT ON COLUMN VehicleComponents.status IS 'Current status of the component.';
CREATE INDEX idx_vehiclecomponents_vehicle ON VehicleComponents (vehicle_id);
CREATE INDEX idx_vehiclecomponents_component_type ON VehicleComponents (component_type);
CREATE TRIGGER update_vehiclecomponents_modtime
BEFORE UPDATE ON VehicleComponents
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 64. ECU Firmware History Table
CREATE TABLE EcuFirmwareHistory (
    history_id BIGSERIAL PRIMARY KEY,
    ecu_id INT NOT NULL,
    firmware_version VARCHAR(50),
    installed_on TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    installed_by INT,
    installation_method firmware_install_method_enum,
    checksum VARCHAR(64),
    file_size_kb INT,
    release_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id),
    FOREIGN KEY (installed_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE EcuFirmwareHistory IS 'History of ECU firmware updates.';
COMMENT ON COLUMN EcuFirmwareHistory.installation_method IS 'Method used to install the firmware.';
COMMENT ON COLUMN EcuFirmwareHistory.checksum IS 'Checksum of the firmware file for verification.';
CREATE INDEX idx_ecufirmwarehistory_ecu ON EcuFirmwareHistory (ecu_id);
CREATE INDEX idx_ecufirmwarehistory_installed_on ON EcuFirmwareHistory (installed_on);
-- No update trigger needed as history entries are immutable

-- 65. CAN Frame Logs Table
CREATE TABLE CanFrameLogs (
    frame_id BIGSERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17),
    session_id UUID,
    bus VARCHAR(50),
    arbitration_id VARCHAR(10),
    data_payload VARCHAR(50),
    timestamp TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    frame_type can_frame_type_enum,
    frame_format can_frame_format_enum,
    data_length INT,
    cycle_time_ms INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id)
);
COMMENT ON TABLE CanFrameLogs IS 'Logs of CAN bus frames.';
COMMENT ON COLUMN CanFrameLogs.arbitration_id IS 'CAN arbitration ID (message ID).';
COMMENT ON COLUMN CanFrameLogs.data_payload IS 'Hexadecimal data payload.';
CREATE INDEX idx_canframelogs_vehicle_timestamp ON CanFrameLogs (vehicle_id, timestamp);
CREATE INDEX idx_canframelogs_arbitration_id ON CanFrameLogs (arbitration_id);
-- No update trigger needed as logs are immutable

-- 66. DTC Clusters Table
CREATE TABLE DtcClusters (
    cluster_id SERIAL PRIMARY KEY,
    cluster_name VARCHAR(100),
    dtcs JSONB COMMENT 'Array of DTCs',
    typical_cause TEXT,
    recommended_action TEXT,
    severity cluster_severity_enum DEFAULT 'medium',
    occurrence_frequency VARCHAR(50),
    affected_subsystems JSONB,
    model_coverage JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE DtcClusters IS 'Clusters of related DTCs that often occur together.';
COMMENT ON COLUMN DtcClusters.dtcs IS 'JSON array of DTC IDs in this cluster.';
COMMENT ON COLUMN DtcClusters.model_coverage IS 'JSON data on vehicle models affected by this cluster.';
CREATE INDEX idx_dtcclusters_cluster_name ON DtcClusters (cluster_name);
CREATE INDEX idx_dtcclusters_severity ON DtcClusters (severity);
CREATE TRIGGER update_dtcclusters_modtime
BEFORE UPDATE ON DtcClusters
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 67. Driving Behavior Table
CREATE TABLE DrivingBehavior (
    behavior_id BIGSERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17),
    session_id UUID,
    acceleration_events INT,
    harsh_braking_events INT,
    average_speed DECIMAL(5,2),
    max_speed DECIMAL(5,2),
    distance_km DECIMAL(8,2),
    cornering_events INT,
    idling_time_min DECIMAL(6,2),
    eco_score INT,
    driving_duration_min INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id)
);
COMMENT ON TABLE DrivingBehavior IS 'Driving behavior metrics for vehicles.';
COMMENT ON COLUMN DrivingBehavior.acceleration_events IS 'Count of rapid acceleration events.';
COMMENT ON COLUMN DrivingBehavior.eco_score IS 'Score (0-100) rating eco-friendly driving.';
CREATE INDEX idx_drivingbehavior_vehicle ON DrivingBehavior (vehicle_id);
CREATE INDEX idx_drivingbehavior_eco_score ON DrivingBehavior (eco_score);
CREATE TRIGGER update_drivingbehavior_modtime
BEFORE UPDATE ON DrivingBehavior
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 68. Real-Time Vehicle Status Table
CREATE TABLE RealTimeVehicleStatus (
    vehicle_id VARCHAR(17) PRIMARY KEY,
    last_location_lat DECIMAL(10,8),
    last_location_long DECIMAL(11,8),
    battery_voltage DECIMAL(5,2),
    engine_status engine_status_enum,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    odometer_km INT,
    fuel_level_percent DECIMAL(5,2),
    network_status network_status_enum,
    connectivity_status connectivity_status_enum,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE RealTimeVehicleStatus IS 'Current real-time status of vehicles.';
COMMENT ON COLUMN RealTimeVehicleStatus.engine_status IS 'Current engine status.';
COMMENT ON COLUMN RealTimeVehicleStatus.network_status IS 'Status of the vehicle\'s internal network.';
CREATE INDEX idx_realtimevehiclestatus_engine_status ON RealTimeVehicleStatus (engine_status);
CREATE INDEX idx_realtimevehiclestatus_location ON RealTimeVehicleStatus USING GIST (
    ST_SetSRID(ST_MakePoint(last_location_long, last_location_lat), 4326)
) WHERE last_location_lat IS NOT NULL AND last_location_long IS NOT NULL;
CREATE TRIGGER update_realtimevehiclestatus_modtime
BEFORE UPDATE ON RealTimeVehicleStatus
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 69. Compliance Checks Table
CREATE TABLE ComplianceChecks (
    check_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17),
    region_id INT,
    check_type VARCHAR(100),
    check_result compliance_check_result_enum,
    check_date DATE,
    notes TEXT,
    regulation_reference VARCHAR(100),
    test_standard VARCHAR(100),
    valid_until DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (region_id) REFERENCES RegionalStandards(region_id)
);
COMMENT ON TABLE ComplianceChecks IS 'Regulatory compliance checks for vehicles.';
COMMENT ON COLUMN ComplianceChecks.check_type IS 'Type of compliance check (e.g., emissions, safety).';
COMMENT ON COLUMN ComplianceChecks.valid_until IS 'Date until which this compliance check is valid.';
CREATE INDEX idx_compliancechecks_vehicle ON ComplianceChecks (vehicle_id);
CREATE INDEX idx_compliancechecks_check_result ON ComplianceChecks (check_result);
CREATE TRIGGER update_compliancechecks_modtime
BEFORE UPDATE ON ComplianceChecks
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 70. Report Templates Table
CREATE TABLE ReportTemplates (
    template_id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    description TEXT,
    template_type VARCHAR(50) NOT NULL,
    template_content TEXT NOT NULL,
    variables JSONB,
    created_by INT,
    is_public BOOLEAN DEFAULT FALSE,
    version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE ReportTemplates IS 'Templates for generating reports.';
COMMENT ON COLUMN ReportTemplates.template_type IS 'Type of report template (e.g., diagnostic, maintenance).';
COMMENT ON COLUMN ReportTemplates.variables IS 'JSON array of variables used in the template.';
CREATE INDEX idx_reporttemplates_template_name ON ReportTemplates (template_name);
CREATE INDEX idx_reporttemplates_template_type ON ReportTemplates (template_type);
CREATE INDEX idx_reporttemplates_is_public ON ReportTemplates (is_public);
CREATE TRIGGER update_reporttemplates_modtime
BEFORE UPDATE ON ReportTemplates
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 71. Data Exports Table
CREATE TABLE DataExports (
    export_id SERIAL PRIMARY KEY,
    user_id INT,
    export_type VARCHAR(50) NOT NULL,
    file_format VARCHAR(20) NOT NULL,
    file_path VARCHAR(255),
    file_size_bytes BIGINT,
    record_count INT,
    query_parameters JSONB,
    status VARCHAR(20) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    expiry_date TIMESTAMP WITH TIME ZONE,
    download_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE DataExports IS 'Records of data exports from the system.';
COMMENT ON COLUMN DataExports.export_type IS 'Type of data being exported.';
COMMENT ON COLUMN DataExports.query_parameters IS 'JSON parameters used to generate the export.';
CREATE INDEX idx_dataexports_user ON DataExports (user_id);
CREATE INDEX idx_dataexports_status ON DataExports (status);
CREATE INDEX idx_dataexports_started_at ON DataExports (started_at);
CREATE TRIGGER update_dataexports_modtime
BEFORE UPDATE ON DataExports
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 72. Third-Party Data Cache Table
CREATE TABLE ThirdPartyDataCache (
    cache_id SERIAL PRIMARY KEY,
    data_source VARCHAR(100) NOT NULL,
    data_key VARCHAR(255) NOT NULL,
    data_value JSONB NOT NULL,
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_accessed TIMESTAMP WITH TIME ZONE,
    access_count INT DEFAULT 1,
    is_valid BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (data_source, data_key)
);
COMMENT ON TABLE ThirdPartyDataCache IS 'Cache for third-party API data.';
COMMENT ON COLUMN ThirdPartyDataCache.data_source IS 'Source of the cached data.';
COMMENT ON COLUMN ThirdPartyDataCache.data_key IS 'Key for retrieving the cached data.';
CREATE INDEX idx_thirdpartydatacache_source_key ON ThirdPartyDataCache (data_source, data_key);
CREATE INDEX idx_thirdpartydatacache_expires_at ON ThirdPartyDataCache (expires_at);
CREATE TRIGGER update_thirdpartydatacache_modtime
BEFORE UPDATE ON ThirdPartyDataCache
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 73. ECU Communication Settings Table
CREATE TABLE EcuCommunicationSettings (
    setting_id SERIAL PRIMARY KEY,
    ecu_id INT NOT NULL,
    baud_rate INT,
    parity VARCHAR(10),
    stop_bits DECIMAL(3,1),
    data_bits INT,
    flow_control VARCHAR(20),
    timeout_ms INT,
    retry_count INT,
    security_access_required BOOLEAN DEFAULT FALSE,
    custom_parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ecu_id) REFERENCES VehicleECUs(ecu_id),
    UNIQUE (ecu_id)
);
COMMENT ON TABLE EcuCommunicationSettings IS 'Communication settings for ECUs.';
COMMENT ON COLUMN EcuCommunicationSettings.baud_rate IS 'Communication baud rate in bps.';
COMMENT ON COLUMN EcuCommunicationSettings.custom_parameters IS 'JSON object with additional custom parameters.';
CREATE INDEX idx_ecucommunicationsettings_ecu ON EcuCommunicationSettings (ecu_id);
CREATE TRIGGER update_ecucommunicationsettings_modtime
BEFORE UPDATE ON EcuCommunicationSettings
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 74. Communication Logs Table
CREATE TABLE CommunicationLogs (
    log_id BIGSERIAL PRIMARY KEY,
    source_type VARCHAR(50) NOT NULL,
    source_id VARCHAR(100) NOT NULL,
    destination_type VARCHAR(50) NOT NULL,
    destination_id VARCHAR(100) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    message_content TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    response_time_ms INT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE CommunicationLogs IS 'Logs of communication between system components.';
COMMENT ON COLUMN CommunicationLogs.source_type IS 'Type of the source component.';
COMMENT ON COLUMN CommunicationLogs.destination_type IS 'Type of the destination component.';
CREATE INDEX idx_communicationlogs_source ON CommunicationLogs (source_type, source_id);
CREATE INDEX idx_communicationlogs_destination ON CommunicationLogs (destination_type, destination_id);
CREATE INDEX idx_communicationlogs_timestamp ON CommunicationLogs (timestamp);
-- No update trigger needed as logs are immutable

-- 75. EV Battery Systems Table
CREATE TABLE EVBatterySystems (
    battery_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    battery_type VARCHAR(50) NOT NULL,
    nominal_voltage DECIMAL(6,2),
    nominal_capacity_kwh DECIMAL(6,2),
    cell_count INT,
    module_count INT,
    manufacturer VARCHAR(100),
    model_number VARCHAR(50),
    production_date DATE,
    installation_date DATE,
    warranty_expiry_date DATE,
    thermal_management_type VARCHAR(50),
    chemistry VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    UNIQUE (vehicle_id)
);
COMMENT ON TABLE EVBatterySystems IS 'Information about EV battery systems.';
COMMENT ON COLUMN EVBatterySystems.battery_type IS 'Type of battery (e.g., Li-ion, LiFePO4).';
COMMENT ON COLUMN EVBatterySystems.thermal_management_type IS 'Type of thermal management system.';
CREATE INDEX idx_evbatterysystems_vehicle ON EVBatterySystems (vehicle_id);
CREATE INDEX idx_evbatterysystems_battery_type ON EVBatterySystems (battery_type);
CREATE TRIGGER update_evbatterysystems_modtime
BEFORE UPDATE ON EVBatterySystems
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 76. EV Battery Readings Table
CREATE TABLE EVBatteryReadings (
    reading_id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    battery_id INT NOT NULL,
    state_of_charge DECIMAL(5,2), -- Percentage
    state_of_health DECIMAL(5,2), -- Percentage
    pack_voltage DECIMAL(6,2),
    pack_current DECIMAL(6,2),
    pack_temperature DECIMAL(5,2),
    min_cell_voltage DECIMAL(5,3),
    max_cell_voltage DECIMAL(5,3),
    voltage_deviation DECIMAL(5,3),
    min_cell_temperature DECIMAL(5,2),
    max_cell_temperature DECIMAL(5,2),
    temperature_deviation DECIMAL(5,2),
    charge_cycles INT,
    reading_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES DiagnosticSessions(session_id),
    FOREIGN KEY (battery_id) REFERENCES EVBatterySystems(battery_id)
);
COMMENT ON TABLE EVBatteryReadings IS 'Readings from EV battery systems.';
COMMENT ON COLUMN EVBatteryReadings.state_of_charge IS 'Current battery charge level (0-100%).';
COMMENT ON COLUMN EVBatteryReadings.state_of_health IS 'Battery health relative to new condition (0-100%).';
CREATE INDEX idx_evbatteryreadings_session ON EVBatteryReadings (session_id);
CREATE INDEX idx_evbatteryreadings_battery ON EVBatteryReadings (battery_id);
CREATE INDEX idx_evbatteryreadings_timestamp ON EVBatteryReadings (reading_timestamp);
-- No update trigger needed as readings are immutable

-- 77. EV Charging History Table
CREATE TABLE EVChargingHistory (
    charging_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    start_soc DECIMAL(5,2),
    end_soc DECIMAL(5,2),
    energy_delivered_kwh DECIMAL(8,2),
    charging_power_kw DECIMAL(6,2),
    charging_location VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    charger_type VARCHAR(50),
    cost DECIMAL(10,2),
    currency VARCHAR(3),
    completed_normally BOOLEAN,
    termination_reason VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
);
COMMENT ON TABLE EVChargingHistory IS 'History of EV charging sessions.';
COMMENT ON COLUMN EVChargingHistory.start_soc IS 'State of charge at start of charging (%).';
COMMENT ON COLUMN EVChargingHistory.charger_type IS 'Type of charger used (e.g., Level 1, Level 2, DC Fast).';
CREATE INDEX idx_evcharginghistory_vehicle ON EVChargingHistory (vehicle_id);
CREATE INDEX idx_evcharginghistory_start_time ON EVChargingHistory (start_time);
CREATE INDEX idx_evcharginghistory_location ON EVChargingHistory USING GIST (
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE TRIGGER update_evcharginghistory_modtime
BEFORE UPDATE ON EVChargingHistory
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 78. Data Quality Rules Table
CREATE TABLE DataQualityRules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    description TEXT,
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    validation_expression TEXT,
    severity VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE DataQualityRules IS 'Rules for data quality validation.';
COMMENT ON COLUMN DataQualityRules.rule_type IS 'Type of data quality rule.';
COMMENT ON COLUMN DataQualityRules.validation_expression IS 'Expression used to validate data.';
CREATE INDEX idx_dataqualityrules_rule_name ON DataQualityRules (rule_name);
CREATE INDEX idx_dataqualityrules_table_column ON DataQualityRules (table_name, column_name);
CREATE TRIGGER update_dataqualityrules_modtime
BEFORE UPDATE ON DataQualityRules
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 79. API Keys Table
CREATE TABLE api_keys (
    key_id SERIAL PRIMARY KEY,
    api_key VARCHAR(64) NOT NULL,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    permissions JSONB,
    rate_limit INT,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    UNIQUE (api_key)
);
COMMENT ON TABLE api_keys IS 'API keys for accessing the system programmatically.';
COMMENT ON COLUMN api_keys.api_key IS 'Unique API key string.';
COMMENT ON COLUMN api_keys.permissions IS 'JSON array of permissions granted to this key.';
CREATE INDEX idx_api_keys_user ON api_keys (user_id);
CREATE INDEX idx_api_keys_is_active ON api_keys (is_active);
CREATE TRIGGER update_api_keys_modtime
BEFORE UPDATE ON api_keys
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 80. Audit Logs Table
CREATE TABLE audit_logs (
    log_id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    action VARCHAR(20) NOT NULL,
    user_id INT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE audit_logs IS 'Audit logs for tracking changes to entities.';
COMMENT ON COLUMN audit_logs.entity_type IS 'Type of entity being audited.';
COMMENT ON COLUMN audit_logs.action IS 'Action performed (e.g., create, update, delete).';
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_user ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs (timestamp);
-- No update trigger needed as logs are immutable
-- Continuing PostgreSQL Schema Conversion for OBD Diagnostic Tool (Part 4)

-- 81. Currencies Table
CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimal_places SMALLINT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE currencies IS 'Currency definitions for financial transactions.';
COMMENT ON COLUMN currencies.currency_code IS 'ISO 4217 currency code (e.g., USD, EUR).';
COMMENT ON COLUMN currencies.symbol IS 'Currency symbol (e.g., $, €).';
CREATE TRIGGER update_currencies_modtime
BEFORE UPDATE ON currencies
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 82. Data Classification Table
CREATE TABLE data_classification (
    classification_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    security_level INT NOT NULL,
    retention_period_days INT,
    requires_encryption BOOLEAN DEFAULT FALSE,
    requires_audit BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE data_classification IS 'Classification levels for data security and privacy.';
COMMENT ON COLUMN data_classification.security_level IS 'Numeric security level (higher = more sensitive).';
COMMENT ON COLUMN data_classification.retention_period_days IS 'Number of days to retain this class of data.';
CREATE INDEX idx_data_classification_name ON data_classification (name);
CREATE INDEX idx_data_classification_security_level ON data_classification (security_level);
CREATE TRIGGER update_data_classification_modtime
BEFORE UPDATE ON data_classification
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 83. Entity Attributes Table
CREATE TABLE entity_attributes (
    attribute_id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    data_type VARCHAR(20) NOT NULL,
    is_searchable BOOLEAN DEFAULT TRUE,
    is_indexed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE entity_attributes IS 'Flexible attributes for various entities.';
COMMENT ON COLUMN entity_attributes.entity_type IS 'Type of entity this attribute belongs to.';
COMMENT ON COLUMN entity_attributes.is_searchable IS 'Whether this attribute should be included in searches.';
CREATE INDEX idx_entity_attributes_entity ON entity_attributes (entity_type, entity_id);
CREATE INDEX idx_entity_attributes_name ON entity_attributes (attribute_name);
CREATE INDEX idx_entity_attributes_searchable ON entity_attributes (is_searchable) WHERE is_searchable = TRUE;
CREATE TRIGGER update_entity_attributes_modtime
BEFORE UPDATE ON entity_attributes
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 84. Exchange Rates Table
CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate DECIMAL(20,10) NOT NULL,
    effective_date DATE NOT NULL,
    source VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_currency) REFERENCES currencies(currency_code),
    FOREIGN KEY (to_currency) REFERENCES currencies(currency_code),
    UNIQUE (from_currency, to_currency, effective_date)
);
COMMENT ON TABLE exchange_rates IS 'Currency exchange rates for financial calculations.';
COMMENT ON COLUMN exchange_rates.rate IS 'Exchange rate from source to target currency.';
COMMENT ON COLUMN exchange_rates.source IS 'Source of the exchange rate data.';
CREATE INDEX idx_exchange_rates_currencies ON exchange_rates (from_currency, to_currency);
CREATE INDEX idx_exchange_rates_effective_date ON exchange_rates (effective_date);
CREATE TRIGGER update_exchange_rates_modtime
BEFORE UPDATE ON exchange_rates
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 85. Feature Flags Table
CREATE TABLE feature_flags (
    flag_id SERIAL PRIMARY KEY,
    flag_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_enabled BOOLEAN DEFAULT FALSE,
    percentage_rollout INT DEFAULT 100,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    user_criteria JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (flag_name)
);
COMMENT ON TABLE feature_flags IS 'Feature flags for controlling feature availability.';
COMMENT ON COLUMN feature_flags.percentage_rollout IS 'Percentage of users who should see this feature (0-100).';
COMMENT ON COLUMN feature_flags.user_criteria IS 'JSON criteria for targeting specific users.';
CREATE INDEX idx_feature_flags_name ON feature_flags (flag_name);
CREATE INDEX idx_feature_flags_enabled ON feature_flags (is_enabled);
CREATE TRIGGER update_feature_flags_modtime
BEFORE UPDATE ON feature_flags
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 86. Outbound Events Table
CREATE TABLE outbound_events (
    event_id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    destination VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT
);
COMMENT ON TABLE outbound_events IS 'Events to be sent to external systems.';
COMMENT ON COLUMN outbound_events.event_type IS 'Type of event being sent.';
COMMENT ON COLUMN outbound_events.payload IS 'JSON payload of the event.';
CREATE INDEX idx_outbound_events_status ON outbound_events (status);
CREATE INDEX idx_outbound_events_next_retry ON outbound_events (next_retry_at) WHERE status = 'pending';
CREATE TRIGGER update_outbound_events_modtime
BEFORE UPDATE ON outbound_events
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 87. Pipeline Jobs Table
CREATE TABLE pipeline_jobs (
    job_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    parameters JSONB,
    result_summary JSONB,
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE pipeline_jobs IS 'Data processing pipeline jobs.';
COMMENT ON COLUMN pipeline_jobs.status IS 'Current status of the job (e.g., pending, running, completed, failed).';
COMMENT ON COLUMN pipeline_jobs.parameters IS 'JSON parameters for the job.';
CREATE INDEX idx_pipeline_jobs_status ON pipeline_jobs (status);
CREATE INDEX idx_pipeline_jobs_job_name ON pipeline_jobs (job_name);
CREATE INDEX idx_pipeline_jobs_created_at ON pipeline_jobs (created_at);
CREATE TRIGGER update_pipeline_jobs_modtime
BEFORE UPDATE ON pipeline_jobs
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 88. Plans Table
CREATE TABLE plans (
    plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    billing_interval VARCHAR(20) NOT NULL,
    features JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    trial_days INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code)
);
COMMENT ON TABLE plans IS 'Subscription plans for the service.';
COMMENT ON COLUMN plans.billing_interval IS 'Billing interval (e.g., monthly, yearly).';
COMMENT ON COLUMN plans.features IS 'JSON array of features included in this plan.';
CREATE INDEX idx_plans_plan_name ON plans (plan_name);
CREATE INDEX idx_plans_is_active ON plans (is_active);
CREATE TRIGGER update_plans_modtime
BEFORE UPDATE ON plans
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 89. Product Recommendations Table
CREATE TABLE product_recommendations (
    recommendation_id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(17) NOT NULL,
    product_type VARCHAR(50) NOT NULL,
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    reason VARCHAR(100) NOT NULL,
    confidence_score DECIMAL(5,2),
    recommended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    dismissed_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id),
    FOREIGN KEY (dismissed_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE product_recommendations IS 'Product recommendations for vehicles.';
COMMENT ON COLUMN product_recommendations.product_type IS 'Type of product being recommended.';
COMMENT ON COLUMN product_recommendations.reason IS 'Reason for the recommendation.';
CREATE INDEX idx_product_recommendations_vehicle ON product_recommendations (vehicle_id);
CREATE INDEX idx_product_recommendations_product_type ON product_recommendations (product_type);
CREATE INDEX idx_product_recommendations_is_dismissed ON product_recommendations (is_dismissed);
CREATE TRIGGER update_product_recommendations_modtime
BEFORE UPDATE ON product_recommendations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 90. Product Translations Table
CREATE TABLE product_translations (
    translation_id SERIAL PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
    language_code CHAR(2) NOT NULL,
    locale VARCHAR(5) NOT NULL,
    translated_name VARCHAR(255) NOT NULL,
    translated_description TEXT,
    translated_features TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, language_code, locale)
);
COMMENT ON TABLE product_translations IS 'Translations for product information.';
COMMENT ON COLUMN product_translations.language_code IS 'ISO 639-1 language code.';
COMMENT ON COLUMN product_translations.locale IS 'Language locale (e.g., en-US, fr-CA).';
CREATE INDEX idx_product_translations_product ON product_translations (product_id);
CREATE INDEX idx_product_translations_language ON product_translations (language_code, locale);
CREATE TRIGGER update_product_translations_modtime
BEFORE UPDATE ON product_translations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 91. Rate Limits Table
CREATE TABLE rate_limits (
    limit_id SERIAL PRIMARY KEY,
    resource VARCHAR(100) NOT NULL,
    limit_type VARCHAR(50) NOT NULL,
    max_requests INT NOT NULL,
    time_window_seconds INT NOT NULL,
    user_type VARCHAR(50),
    applies_to_ip BOOLEAN DEFAULT TRUE,
    applies_to_user BOOLEAN DEFAULT TRUE,
    applies_to_api_key BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (resource, limit_type, user_type)
);
COMMENT ON TABLE rate_limits IS 'Rate limits for API and resource access.';
COMMENT ON COLUMN rate_limits.resource IS 'Resource being rate-limited.';
COMMENT ON COLUMN rate_limits.limit_type IS 'Type of rate limit (e.g., per-second, per-minute, per-hour).';
CREATE INDEX idx_rate_limits_resource ON rate_limits (resource);
CREATE TRIGGER update_rate_limits_modtime
BEFORE UPDATE ON rate_limits
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 92. Scheduled Jobs Table
CREATE TABLE scheduled_jobs (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL,
    job_type VARCHAR(50) NOT NULL,
    cron_expression VARCHAR(100),
    next_run_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_run_at TIMESTAMP WITH TIME ZONE,
    last_run_status VARCHAR(20),
    parameters JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE scheduled_jobs IS 'Scheduled background jobs.';
COMMENT ON COLUMN scheduled_jobs.cron_expression IS 'Cron expression for job scheduling.';
COMMENT ON COLUMN scheduled_jobs.parameters IS 'JSON parameters for the job.';
CREATE INDEX idx_scheduled_jobs_next_run ON scheduled_jobs (next_run_at) WHERE is_active = TRUE;
CREATE INDEX idx_scheduled_jobs_job_type ON scheduled_jobs (job_type);
CREATE TRIGGER update_scheduled_jobs_modtime
BEFORE UPDATE ON scheduled_jobs
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 93. Schema Migrations Table
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    script_name VARCHAR(255),
    checksum VARCHAR(64),
    execution_time_ms INT,
    applied_by VARCHAR(100),
    is_success BOOLEAN NOT NULL
);
COMMENT ON TABLE schema_migrations IS 'Database schema migration history.';
COMMENT ON COLUMN schema_migrations.version IS 'Version identifier for the migration.';
COMMENT ON COLUMN schema_migrations.checksum IS 'Checksum of the migration script for verification.';
CREATE INDEX idx_schema_migrations_applied_at ON schema_migrations (applied_at);

-- 94. Service Heartbeats Table
CREATE TABLE service_heartbeats (
    heartbeat_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    instance_id VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_heartbeat TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (service_name, instance_id)
);
COMMENT ON TABLE service_heartbeats IS 'Heartbeat monitoring for system services.';
COMMENT ON COLUMN service_heartbeats.service_name IS 'Name of the service.';
COMMENT ON COLUMN service_heartbeats.instance_id IS 'Unique identifier for the service instance.';
CREATE INDEX idx_service_heartbeats_last_heartbeat ON service_heartbeats (last_heartbeat);
CREATE TRIGGER update_service_heartbeats_modtime
BEFORE UPDATE ON service_heartbeats
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 95. Subscriptions Table
CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    billing_cycle_anchor TIMESTAMP WITH TIME ZONE,
    next_billing_date TIMESTAMP WITH TIME ZONE,
    payment_method_id VARCHAR(100),
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);
COMMENT ON TABLE subscriptions IS 'User subscriptions to service plans.';
COMMENT ON COLUMN subscriptions.status IS 'Current status of the subscription (e.g., active, canceled, past_due).';
COMMENT ON COLUMN subscriptions.billing_cycle_anchor IS 'Reference date for billing cycle calculations.';
CREATE INDEX idx_subscriptions_user ON subscriptions (user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions (status);
CREATE INDEX idx_subscriptions_next_billing ON subscriptions (next_billing_date);
CREATE TRIGGER update_subscriptions_modtime
BEFORE UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 96. User Events Table
CREATE TABLE user_events (
    event_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE user_events IS 'Events related to user activity.';
COMMENT ON COLUMN user_events.event_type IS 'Type of user event.';
COMMENT ON COLUMN user_events.event_data IS 'JSON data specific to the event.';
CREATE INDEX idx_user_events_user ON user_events (user_id);
CREATE INDEX idx_user_events_event_type ON user_events (event_type);
CREATE INDEX idx_user_events_occurred_at ON user_events (occurred_at);

-- 97. Workflow States Table
CREATE TABLE workflow_states (
    state_id SERIAL PRIMARY KEY,
    workflow_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    current_state VARCHAR(50) NOT NULL,
    previous_state VARCHAR(50),
    next_possible_states JSONB,
    assigned_to INT,
    transitioned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transitioned_by INT,
    due_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_to) REFERENCES Users(user_id),
    FOREIGN KEY (transitioned_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE workflow_states IS 'State tracking for workflow processes.';
COMMENT ON COLUMN workflow_states.workflow_type IS 'Type of workflow.';
COMMENT ON COLUMN workflow_states.current_state IS 'Current state in the workflow.';
COMMENT ON COLUMN workflow_states.next_possible_states IS 'JSON array of possible next states.';
CREATE INDEX idx_workflow_states_entity ON workflow_states (entity_type, entity_id);
CREATE INDEX idx_workflow_states_current_state ON workflow_states (current_state);
CREATE INDEX idx_workflow_states_assigned_to ON workflow_states (assigned_to);
CREATE TRIGGER update_workflow_states_modtime
BEFORE UPDATE ON workflow_states
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 98. AI Predictions Table
CREATE TABLE ai_predictions (
    prediction_id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    prediction_type VARCHAR(50) NOT NULL,
    prediction_value TEXT NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    features_used JSONB,
    model_version VARCHAR(50),
    explanation TEXT,
    feedback_correct BOOLEAN,
    feedback_notes TEXT,
    predicted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE ai_predictions IS 'Predictions made by AI models.';
COMMENT ON COLUMN ai_predictions.entity_type IS 'Type of entity being predicted for.';
COMMENT ON COLUMN ai_predictions.prediction_type IS 'Type of prediction being made.';
COMMENT ON COLUMN ai_predictions.features_used IS 'JSON array of features used in the prediction.';
CREATE INDEX idx_ai_predictions_entity ON ai_predictions (entity_type, entity_id);
CREATE INDEX idx_ai_predictions_prediction_type ON ai_predictions (prediction_type);
CREATE INDEX idx_ai_predictions_predicted_at ON ai_predictions (predicted_at);
CREATE TRIGGER update_ai_predictions_modtime
BEFORE UPDATE ON ai_predictions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 99. Shipments Table
CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(100),
    carrier VARCHAR(50),
    shipping_method VARCHAR(50),
    status VARCHAR(20) NOT NULL,
    shipped_at TIMESTAMP WITH TIME ZONE,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE,
    shipping_address JSONB,
    package_weight DECIMAL(10,2),
    package_dimensions JSONB,
    shipping_cost DECIMAL(10,2),
    currency_code CHAR(3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code)
);
COMMENT ON TABLE shipments IS 'Shipment tracking information.';
COMMENT ON COLUMN shipments.status IS 'Current status of the shipment.';
COMMENT ON COLUMN shipments.shipping_address IS 'JSON object with shipping address details.';
CREATE INDEX idx_shipments_order_id ON shipments (order_id);
CREATE INDEX idx_shipments_tracking_number ON shipments (tracking_number);
CREATE INDEX idx_shipments_status ON shipments (status);
CREATE TRIGGER update_shipments_modtime
BEFORE UPDATE ON shipments
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 100. Supply Chain Events Table
CREATE TABLE supply_chain_events (
    event_id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_data JSONB,
    previous_state JSONB,
    new_state JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE supply_chain_events IS 'Events in the supply chain process.';
COMMENT ON COLUMN supply_chain_events.event_type IS 'Type of supply chain event.';
COMMENT ON COLUMN supply_chain_events.entity_type IS 'Type of entity involved in the event.';
CREATE INDEX idx_supply_chain_events_entity ON supply_chain_events (entity_type, entity_id);
CREATE INDEX idx_supply_chain_events_event_type ON supply_chain_events (event_type);
CREATE INDEX idx_supply_chain_events_occurred_at ON supply_chain_events (occurred_at);
CREATE TRIGGER update_supply_chain_events_modtime
BEFORE UPDATE ON supply_chain_events
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 101. Notifications Table
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url VARCHAR(255),
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    importance VARCHAR(20) DEFAULT 'normal',
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE notifications IS 'User notifications.';
COMMENT ON COLUMN notifications.notification_type IS 'Type of notification.';
COMMENT ON COLUMN notifications.action_url IS 'URL to navigate to when the notification is clicked.';
CREATE INDEX idx_notifications_user ON notifications (user_id);
CREATE INDEX idx_notifications_is_read ON notifications (is_read);
CREATE INDEX idx_notifications_created_at ON notifications (created_at);

-- 102. User Preferences Table
CREATE TABLE user_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    UNIQUE (user_id, preference_key)
);
COMMENT ON TABLE user_preferences IS 'User preference settings.';
COMMENT ON COLUMN user_preferences.preference_key IS 'Key identifying the preference.';
COMMENT ON COLUMN user_preferences.preference_value IS 'Value of the preference.';
CREATE INDEX idx_user_preferences_user ON user_preferences (user_id);
CREATE TRIGGER update_user_preferences_modtime
BEFORE UPDATE ON user_preferences
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 103. Integration Logs Table
CREATE TABLE integration_logs (
    log_id SERIAL PRIMARY KEY,
    integration_id INT NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
    status VARCHAR(20) NOT NULL,
    request_data TEXT,
    response_data TEXT,
    error_message TEXT,
    duration_ms INT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (integration_id) REFERENCES ApiIntegrations(integration_id)
);
COMMENT ON TABLE integration_logs IS 'Logs of API integration activity.';
COMMENT ON COLUMN integration_logs.direction IS 'Direction of the integration call (inbound/outbound).';
COMMENT ON COLUMN integration_logs.duration_ms IS 'Duration of the integration call in milliseconds.';
CREATE INDEX idx_integration_logs_integration ON integration_logs (integration_id);
CREATE INDEX idx_integration_logs_status ON integration_logs (status);
CREATE INDEX idx_integration_logs_timestamp ON integration_logs (timestamp);


-- Create Enterprise Schema Tables

-- 105. Enterprise Vendors Table
CREATE TABLE enterprise.vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    contact_name VARCHAR(100),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    address TEXT,
    tax_id VARCHAR(50),
    payment_terms VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    onboarded_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE enterprise.vendors IS 'Vendor information for enterprise operations.';
COMMENT ON COLUMN enterprise.vendors.code IS 'Unique vendor code for internal reference.';
COMMENT ON COLUMN enterprise.vendors.payment_terms IS 'Payment terms agreed with this vendor.';
CREATE INDEX idx_enterprise_vendors_name ON enterprise.vendors (name);
CREATE INDEX idx_enterprise_vendors_status ON enterprise.vendors (status);
CREATE TRIGGER update_enterprise_vendors_modtime
BEFORE UPDATE ON enterprise.vendors
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 106. Enterprise Vendor Contracts Table
CREATE TABLE enterprise.vendor_contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL,
    contract_number VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    contract_type VARCHAR(50),
    contract_value DECIMAL(15,2),
    currency_code CHAR(3),
    sla_terms JSONB,
    renewal_terms TEXT,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code)
);
COMMENT ON TABLE enterprise.vendor_contracts IS 'Contracts with vendors.';
COMMENT ON COLUMN enterprise.vendor_contracts.sla_terms IS 'JSON object with SLA terms.';
COMMENT ON COLUMN enterprise.vendor_contracts.renewal_terms IS 'Terms for contract renewal.';
CREATE INDEX idx_enterprise_vendor_contracts_vendor ON enterprise.vendor_contracts (vendor_id);
CREATE INDEX idx_enterprise_vendor_contracts_dates ON enterprise.vendor_contracts (start_date, end_date);
CREATE TRIGGER update_enterprise_vendor_contracts_modtime
BEFORE UPDATE ON enterprise.vendor_contracts
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 107. Enterprise Vendor Products Table
CREATE TABLE enterprise.vendor_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL,
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    unit_price DECIMAL(15,2),
    currency_code CHAR(3),
    lead_time_days INT,
    minimum_order_quantity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code),
    UNIQUE (vendor_id, product_code)
);
COMMENT ON TABLE enterprise.vendor_products IS 'Products offered by vendors.';
COMMENT ON COLUMN enterprise.vendor_products.lead_time_days IS 'Typical lead time for delivery in days.';
COMMENT ON COLUMN enterprise.vendor_products.minimum_order_quantity IS 'Minimum quantity that can be ordered.';
CREATE INDEX idx_enterprise_vendor_products_vendor ON enterprise.vendor_products (vendor_id);
CREATE INDEX idx_enterprise_vendor_products_category ON enterprise.vendor_products (category);
CREATE TRIGGER update_enterprise_vendor_products_modtime
BEFORE UPDATE ON enterprise.vendor_products
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 108. Enterprise Vendor Performance Metrics Table
CREATE TABLE enterprise.vendor_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    target_value DECIMAL(10,2),
    unit VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id)
);
COMMENT ON TABLE enterprise.vendor_performance_metrics IS 'Performance metrics for vendors.';
COMMENT ON COLUMN enterprise.vendor_performance_metrics.metric_type IS 'Type of performance metric.';
COMMENT ON COLUMN enterprise.vendor_performance_metrics.metric_value IS 'Actual value of the metric.';
CREATE INDEX idx_enterprise_vendor_performance_metrics_vendor ON enterprise.vendor_performance_metrics (vendor_id);
CREATE INDEX idx_enterprise_vendor_performance_metrics_period ON enterprise.vendor_performance_metrics (period_start, period_end);
CREATE TRIGGER update_enterprise_vendor_performance_metrics_modtime
BEFORE UPDATE ON enterprise.vendor_performance_metrics
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 109. Enterprise KPI Definitions Table
CREATE TABLE enterprise.kpi_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    unit VARCHAR(20),
    calculation_method TEXT,
    data_source VARCHAR(100),
    frequency VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE enterprise.kpi_definitions IS 'Definitions of Key Performance Indicators.';
COMMENT ON COLUMN enterprise.kpi_definitions.calculation_method IS 'Method used to calculate this KPI.';
COMMENT ON COLUMN enterprise.kpi_definitions.frequency IS 'Frequency of KPI measurement (e.g., daily, weekly, monthly).';
CREATE INDEX idx_enterprise_kpi_definitions_name ON enterprise.kpi_definitions (name);
CREATE INDEX idx_enterprise_kpi_definitions_category ON enterprise.kpi_definitions (category);
CREATE TRIGGER update_enterprise_kpi_definitions_modtime
BEFORE UPDATE ON enterprise.kpi_definitions
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 110. Enterprise KPI Values Table
CREATE TABLE enterprise.kpi_values (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL,
    dimension_type VARCHAR(50),
    dimension_id UUID,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_value DECIMAL(15,4) NOT NULL,
    target_value DECIMAL(15,4),
    unit VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kpi_id) REFERENCES enterprise.kpi_definitions(id)
);
COMMENT ON TABLE enterprise.kpi_values IS 'Actual values for Key Performance Indicators.';
COMMENT ON COLUMN enterprise.kpi_values.dimension_type IS 'Type of dimension this KPI value applies to.';
COMMENT ON COLUMN enterprise.kpi_values.dimension_id IS 'ID of the dimension this KPI value applies to.';
CREATE INDEX idx_enterprise_kpi_values_kpi ON enterprise.kpi_values (kpi_id);
CREATE INDEX idx_enterprise_kpi_values_dimension ON enterprise.kpi_values (dimension_type, dimension_id);
CREATE INDEX idx_enterprise_kpi_values_period ON enterprise.kpi_values (period_start, period_end);
CREATE TRIGGER update_enterprise_kpi_values_modtime
BEFORE UPDATE ON enterprise.kpi_values
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 111. Enterprise KPI Targets Table
CREATE TABLE enterprise.kpi_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL,
    dimension_type VARCHAR(50),
    dimension_id UUID,
    target_value DECIMAL(15,4) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kpi_id) REFERENCES enterprise.kpi_definitions(id)
);
COMMENT ON TABLE enterprise.kpi_targets IS 'Target values for Key Performance Indicators.';
COMMENT ON COLUMN enterprise.kpi_targets.dimension_type IS 'Type of dimension this target applies to.';
COMMENT ON COLUMN enterprise.kpi_targets.dimension_id IS 'ID of the dimension this target applies to.';
CREATE INDEX idx_enterprise_kpi_targets_kpi ON enterprise.kpi_targets (kpi_id);
CREATE INDEX idx_enterprise_kpi_targets_dimension ON enterprise.kpi_targets (dimension_type, dimension_id);
CREATE INDEX idx_enterprise_kpi_targets_effective ON enterprise.kpi_targets (effective_from, effective_to);
CREATE TRIGGER update_enterprise_kpi_targets_modtime
BEFORE UPDATE ON enterprise.kpi_targets
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 112. Enterprise KPI Forecasts Table
CREATE TABLE enterprise.kpi_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL,
    dimension_type VARCHAR(50),
    dimension_id UUID,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    forecast_value DECIMAL(15,4) NOT NULL,
    confidence_level DECIMAL(5,2),
    model_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kpi_id) REFERENCES enterprise.kpi_definitions(id)
);
COMMENT ON TABLE enterprise.kpi_forecasts IS 'Forecasted values for Key Performance Indicators.';
COMMENT ON COLUMN enterprise.kpi_forecasts.confidence_level IS 'Confidence level of the forecast (0-1).';
COMMENT ON COLUMN enterprise.kpi_forecasts.model_version IS 'Version of the forecasting model used.';
CREATE INDEX idx_enterprise_kpi_forecasts_kpi ON enterprise.kpi_forecasts (kpi_id);
CREATE INDEX idx_enterprise_kpi_forecasts_dimension ON enterprise.kpi_forecasts (dimension_type, dimension_id);
CREATE INDEX idx_enterprise_kpi_forecasts_period ON enterprise.kpi_forecasts (period_start, period_end);
CREATE TRIGGER update_enterprise_kpi_forecasts_modtime
BEFORE UPDATE ON enterprise.kpi_forecasts
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 113. Enterprise KPI Alert Thresholds Table
CREATE TABLE enterprise.kpi_alert_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_id UUID NOT NULL,
    threshold_type VARCHAR(20) NOT NULL,
    threshold_value DECIMAL(15,4) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kpi_id) REFERENCES enterprise.kpi_definitions(id)
);
COMMENT ON TABLE enterprise.kpi_alert_thresholds IS 'Thresholds for KPI alerts.';
COMMENT ON COLUMN enterprise.kpi_alert_thresholds.threshold_type IS 'Type of threshold (e.g., above, below, percent_change).';
COMMENT ON COLUMN enterprise.kpi_alert_thresholds.severity IS 'Severity of the alert when threshold is crossed.';
CREATE INDEX idx_enterprise_kpi_alert_thresholds_kpi ON enterprise.kpi_alert_thresholds (kpi_id);
CREATE INDEX idx_enterprise_kpi_alert_thresholds_active ON enterprise.kpi_alert_thresholds (is_active);
CREATE TRIGGER update_enterprise_kpi_alert_thresholds_modtime
BEFORE UPDATE ON enterprise.kpi_alert_thresholds
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 114. Enterprise KPI Alert Log Table
CREATE TABLE enterprise.kpi_alert_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kpi_value_id UUID NOT NULL,
    threshold_id UUID NOT NULL,
    alert_message TEXT NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by INT,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kpi_value_id) REFERENCES enterprise.kpi_values(id),
    FOREIGN KEY (threshold_id) REFERENCES enterprise.kpi_alert_thresholds(id),
    FOREIGN KEY (acknowledged_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE enterprise.kpi_alert_log IS 'Log of KPI alerts triggered.';
COMMENT ON COLUMN enterprise.kpi_alert_log.alert_message IS 'Message describing the alert.';
COMMENT ON COLUMN enterprise.kpi_alert_log.acknowledged IS 'Whether the alert has been acknowledged.';
CREATE INDEX idx_enterprise_kpi_alert_log_kpi_value ON enterprise.kpi_alert_log (kpi_value_id);
CREATE INDEX idx_enterprise_kpi_alert_log_threshold ON enterprise.kpi_alert_log (threshold_id);
CREATE INDEX idx_enterprise_kpi_alert_log_acknowledged ON enterprise.kpi_alert_log (acknowledged);
CREATE TRIGGER update_enterprise_kpi_alert_log_modtime
BEFORE UPDATE ON enterprise.kpi_alert_log
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 115. Enterprise KPI Breach Assignments Table
CREATE TABLE enterprise.kpi_breach_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL,
    assigned_to_user_id INT,
    status VARCHAR(50) DEFAULT 'open',
    resolution_notes TEXT,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (alert_id) REFERENCES enterprise.kpi_alert_log(id),
    FOREIGN KEY (assigned_to_user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE enterprise.kpi_breach_assignments IS 'Assignments for handling KPI breaches.';
COMMENT ON COLUMN enterprise.kpi_breach_assignments.status IS 'Current status of the assignment.';
COMMENT ON COLUMN enterprise.kpi_breach_assignments.resolution_notes IS 'Notes on how the breach was resolved.';
CREATE INDEX idx_enterprise_kpi_breach_assignments_alert ON enterprise.kpi_breach_assignments (alert_id);
CREATE INDEX idx_enterprise_kpi_breach_assignments_user ON enterprise.kpi_breach_assignments (assigned_to_user_id);
CREATE INDEX idx_enterprise_kpi_breach_assignments_status ON enterprise.kpi_breach_assignments (status);
CREATE TRIGGER update_enterprise_kpi_breach_assignments_modtime
BEFORE UPDATE ON enterprise.kpi_breach_assignments
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 116. Enterprise KPI Stream Sources Table
CREATE TABLE enterprise.kpi_stream_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_name VARCHAR(100) NOT NULL,
    stream_type VARCHAR(50) NOT NULL,
    endpoint TEXT,
    active BOOLEAN DEFAULT TRUE,
    last_event_received TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE enterprise.kpi_stream_sources IS 'Sources of streaming KPI data.';
COMMENT ON COLUMN enterprise.kpi_stream_sources.stream_type IS 'Type of data stream (e.g., Kafka, Webhook).';
COMMENT ON COLUMN enterprise.kpi_stream_sources.endpoint IS 'Endpoint URL or connection string for the stream.';
CREATE INDEX idx_enterprise_kpi_stream_sources_name ON enterprise.kpi_stream_sources (source_name);
CREATE INDEX idx_enterprise_kpi_stream_sources_active ON enterprise.kpi_stream_sources (active);
CREATE TRIGGER update_enterprise_kpi_stream_sources_modtime
BEFORE UPDATE ON enterprise.kpi_stream_sources
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 117. Enterprise Marketplace Accounts Table
CREATE TABLE enterprise.marketplace_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL,
    marketplace_name VARCHAR(100) NOT NULL,
    account_identifier VARCHAR(100) NOT NULL,
    api_url VARCHAR(255),
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_frequency_minutes INT DEFAULT 1440,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id)
);
COMMENT ON TABLE enterprise.marketplace_accounts IS 'Marketplace accounts for vendors.';
COMMENT ON COLUMN enterprise.marketplace_accounts.marketplace_name IS 'Name of the marketplace.';
COMMENT ON COLUMN enterprise.marketplace_accounts.account_identifier IS 'Identifier for the account on the marketplace.';
CREATE INDEX idx_enterprise_marketplace_accounts_vendor ON enterprise.marketplace_accounts (vendor_id);
CREATE INDEX idx_enterprise_marketplace_accounts_marketplace ON enterprise.marketplace_accounts (marketplace_name);
CREATE TRIGGER update_enterprise_marketplace_accounts_modtime
BEFORE UPDATE ON enterprise.marketplace_accounts
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 118. Enterprise Marketplace Integrations Table
CREATE TABLE enterprise.marketplace_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL,
    integration_type VARCHAR(50) NOT NULL,
    configuration JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_run_at TIMESTAMP WITH TIME ZONE,
    last_run_status VARCHAR(20),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES enterprise.marketplace_accounts(id)
);
COMMENT ON TABLE enterprise.marketplace_integrations IS 'Integrations with marketplaces.';
COMMENT ON COLUMN enterprise.marketplace_integrations.integration_type IS 'Type of marketplace integration.';
COMMENT ON COLUMN enterprise.marketplace_integrations.configuration IS 'JSON configuration for the integration.';
CREATE INDEX idx_enterprise_marketplace_integrations_account ON enterprise.marketplace_integrations (account_id);
CREATE INDEX idx_enterprise_marketplace_integrations_type ON enterprise.marketplace_integrations (integration_type);
CREATE TRIGGER update_enterprise_marketplace_integrations_modtime
BEFORE UPDATE ON enterprise.marketplace_integrations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 119. Enterprise Marketplace Sync Logs Table
CREATE TABLE enterprise.marketplace_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL,
    sync_type VARCHAR(50) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL,
    records_processed INT DEFAULT 0,
    records_created INT DEFAULT 0,
    records_updated INT DEFAULT 0,
    records_failed INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES enterprise.marketplace_accounts(id)
);
COMMENT ON TABLE enterprise.marketplace_sync_logs IS 'Logs of marketplace synchronization operations.';
COMMENT ON COLUMN enterprise.marketplace_sync_logs.sync_type IS 'Type of synchronization operation.';
COMMENT ON COLUMN enterprise.marketplace_sync_logs.status IS 'Status of the synchronization operation.';
CREATE INDEX idx_enterprise_marketplace_sync_logs_account ON enterprise.marketplace_sync_logs (account_id);
CREATE INDEX idx_enterprise_marketplace_sync_logs_started_at ON enterprise.marketplace_sync_logs (started_at);
CREATE INDEX idx_enterprise_marketplace_sync_logs_status ON enterprise.marketplace_sync_logs (status);

-- 120. Enterprise Warehouses Table
CREATE TABLE enterprise.warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    manager_name VARCHAR(100),
    manager_email VARCHAR(100),
    manager_phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    total_capacity_sqm DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE enterprise.warehouses IS 'Warehouses for inventory storage.';
COMMENT ON COLUMN enterprise.warehouses.code IS 'Unique code for the warehouse.';
COMMENT ON COLUMN enterprise.warehouses.total_capacity_sqm IS 'Total capacity in square meters.';
CREATE INDEX idx_enterprise_warehouses_name ON enterprise.warehouses (name);
CREATE INDEX idx_enterprise_warehouses_status ON enterprise.warehouses (status);
CREATE TRIGGER update_enterprise_warehouses_modtime
BEFORE UPDATE ON enterprise.warehouses
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 121. Enterprise Warehouse Performance Metrics Table
CREATE TABLE enterprise.warehouse_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    target_value DECIMAL(10,2),
    unit VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES enterprise.warehouses(id)
);
COMMENT ON TABLE enterprise.warehouse_performance_metrics IS 'Performance metrics for warehouses.';
COMMENT ON COLUMN enterprise.warehouse_performance_metrics.metric_type IS 'Type of performance metric.';
COMMENT ON COLUMN enterprise.warehouse_performance_metrics.metric_value IS 'Actual value of the metric.';
CREATE INDEX idx_enterprise_warehouse_performance_metrics_warehouse ON enterprise.warehouse_performance_metrics (warehouse_id);
CREATE INDEX idx_enterprise_warehouse_performance_metrics_period ON enterprise.warehouse_performance_metrics (period_start, period_end);
CREATE TRIGGER update_enterprise_warehouse_performance_metrics_modtime
BEFORE UPDATE ON enterprise.warehouse_performance_metrics
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 122. Enterprise Distribution Centers Table
CREATE TABLE enterprise.distribution_centers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    manager_name VARCHAR(100),
    manager_email VARCHAR(100),
    manager_phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    service_area TEXT,
    type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE enterprise.distribution_centers IS 'Distribution centers for product distribution.';
COMMENT ON COLUMN enterprise.distribution_centers.code IS 'Unique code for the distribution center.';
COMMENT ON COLUMN enterprise.distribution_centers.service_area IS 'Geographic area served by this distribution center.';
CREATE INDEX idx_enterprise_distribution_centers_name ON enterprise.distribution_centers (name);
CREATE INDEX idx_enterprise_distribution_centers_status ON enterprise.distribution_centers (status);
CREATE TRIGGER update_enterprise_distribution_centers_modtime
BEFORE UPDATE ON enterprise.distribution_centers
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 123. Enterprise Inventory Locations Table
CREATE TABLE enterprise.inventory_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_id UUID NOT NULL,
    location_code VARCHAR(50) NOT NULL,
    location_type VARCHAR(50) NOT NULL,
    aisle VARCHAR(20),
    rack VARCHAR(20),
    shelf VARCHAR(20),
    bin VARCHAR(20),
    capacity DECIMAL(10,2),
    capacity_unit VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES enterprise.warehouses(id),
    UNIQUE (warehouse_id, location_code)
);
COMMENT ON TABLE enterprise.inventory_locations IS 'Specific locations within warehouses for inventory storage.';
COMMENT ON COLUMN enterprise.inventory_locations.location_code IS 'Code identifying the location within the warehouse.';
COMMENT ON COLUMN enterprise.inventory_locations.location_type IS 'Type of location (e.g., bulk, picking, staging).';
CREATE INDEX idx_enterprise_inventory_locations_warehouse ON enterprise.inventory_locations (warehouse_id);
CREATE INDEX idx_enterprise_inventory_locations_location_code ON enterprise.inventory_locations (location_code);
CREATE TRIGGER update_enterprise_inventory_locations_modtime
BEFORE UPDATE ON enterprise.inventory_locations
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 124. Enterprise Purchase Orders Table
CREATE TABLE enterprise.purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    po_number VARCHAR(50) UNIQUE NOT NULL,
    vendor_id UUID NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    status VARCHAR(20) DEFAULT 'draft',
    total_amount DECIMAL(15,2),
    currency_code CHAR(3),
    payment_terms VARCHAR(50),
    shipping_terms VARCHAR(50),
    notes TEXT,
    created_by INT,
    approved_by INT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code),
    FOREIGN KEY (created_by) REFERENCES Users(user_id),
    FOREIGN KEY (approved_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE enterprise.purchase_orders IS 'Purchase orders for vendors.';
COMMENT ON COLUMN enterprise.purchase_orders.po_number IS 'Unique purchase order number.';
COMMENT ON COLUMN enterprise.purchase_orders.status IS 'Current status of the purchase order.';
CREATE INDEX idx_enterprise_purchase_orders_po_number ON enterprise.purchase_orders (po_number);
CREATE INDEX idx_enterprise_purchase_orders_vendor ON enterprise.purchase_orders (vendor_id);
CREATE INDEX idx_enterprise_purchase_orders_status ON enterprise.purchase_orders (status);
CREATE TRIGGER update_enterprise_purchase_orders_modtime
BEFORE UPDATE ON enterprise.purchase_orders
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 125. Enterprise Purchase Order Items Table
CREATE TABLE enterprise.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    po_id UUID NOT NULL,
    product_id UUID,
    item_description TEXT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    unit_of_measure VARCHAR(20),
    line_total DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2),
    received_quantity DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id) REFERENCES enterprise.purchase_orders(id),
    FOREIGN KEY (product_id) REFERENCES enterprise.vendor_products(id)
);
COMMENT ON TABLE enterprise.purchase_order_items IS 'Line items within purchase orders.';
COMMENT ON COLUMN enterprise.purchase_order_items.quantity IS 'Quantity ordered.';
COMMENT ON COLUMN enterprise.purchase_order_items.received_quantity IS 'Quantity received so far.';
CREATE INDEX idx_enterprise_purchase_order_items_po ON enterprise.purchase_order_items (po_id);
CREATE INDEX idx_enterprise_purchase_order_items_product ON enterprise.purchase_order_items (product_id);
CREATE INDEX idx_enterprise_purchase_order_items_status ON enterprise.purchase_order_items (status);
CREATE TRIGGER update_enterprise_purchase_order_items_modtime
BEFORE UPDATE ON enterprise.purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 126. Enterprise Shipments Table
CREATE TABLE enterprise.shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_number VARCHAR(50) UNIQUE NOT NULL,
    po_id UUID,
    vendor_id UUID,
    warehouse_id UUID,
    shipment_date DATE,
    expected_arrival_date DATE,
    actual_arrival_date DATE,
    status VARCHAR(20) DEFAULT 'pending',
    carrier VARCHAR(100),
    tracking_number VARCHAR(100),
    shipping_cost DECIMAL(15,2),
    currency_code CHAR(3),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id) REFERENCES enterprise.purchase_orders(id),
    FOREIGN KEY (vendor_id) REFERENCES enterprise.vendors(id),
    FOREIGN KEY (warehouse_id) REFERENCES enterprise.warehouses(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(currency_code)
);
COMMENT ON TABLE enterprise.shipments IS 'Shipments of goods from vendors.';
COMMENT ON COLUMN enterprise.shipments.shipment_number IS 'Unique shipment number.';
COMMENT ON COLUMN enterprise.shipments.status IS 'Current status of the shipment.';
CREATE INDEX idx_enterprise_shipments_shipment_number ON enterprise.shipments (shipment_number);
CREATE INDEX idx_enterprise_shipments_po ON enterprise.shipments (po_id);
CREATE INDEX idx_enterprise_shipments_vendor ON enterprise.shipments (vendor_id);
CREATE INDEX idx_enterprise_shipments_warehouse ON enterprise.shipments (warehouse_id);
CREATE INDEX idx_enterprise_shipments_status ON enterprise.shipments (status);
CREATE TRIGGER update_enterprise_shipments_modtime
BEFORE UPDATE ON enterprise.shipments
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 127. Enterprise Supply Chain Events Table
CREATE TABLE enterprise.supply_chain_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    location_id UUID,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_data JSONB,
    created_by INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
COMMENT ON TABLE enterprise.supply_chain_events IS 'Events in the supply chain process.';
COMMENT ON COLUMN enterprise.supply_chain_events.event_type IS 'Type of supply chain event.';
COMMENT ON COLUMN enterprise.supply_chain_events.entity_type IS 'Type of entity involved in the event.';
CREATE INDEX idx_enterprise_supply_chain_events_entity ON enterprise.supply_chain_events (entity_type, entity_id);
CREATE INDEX idx_enterprise_supply_chain_events_event_type ON enterprise.supply_chain_events (event_type);
CREATE INDEX idx_enterprise_supply_chain_events_occurred_at ON enterprise.supply_chain_events (occurred_at);
CREATE TRIGGER update_enterprise_supply_chain_events_modtime
BEFORE UPDATE ON enterprise.supply_chain_events
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- 128. Enterprise Audit Logs Table
CREATE TABLE enterprise.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    operation_type VARCHAR(20) NOT NULL,
    user_id INT,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
COMMENT ON TABLE enterprise.audit_logs IS 'Audit logs for enterprise data changes.';
COMMENT ON COLUMN enterprise.audit_logs.operation_type IS 'Type of operation (INSERT, UPDATE, DELETE).';
COMMENT ON COLUMN enterprise.audit_logs.old_data IS 'Previous data before the change.';
CREATE INDEX idx_enterprise_audit_logs_table_record ON enterprise.audit_logs (table_name, record_id);
CREATE INDEX idx_enterprise_audit_logs_user ON enterprise.audit_logs (user_id);
CREATE INDEX idx_enterprise_audit_logs_changed_at ON enterprise.audit_logs (changed_at);



-- Create views for common queries

-- Vehicle Health Summary View
CREATE OR REPLACE VIEW vehicle_health_summary AS
SELECT
    v.vehicle_id,
    m.name AS make,
    v.model,
    v.year,
    COUNT(DISTINCT CASE WHEN vtc.status IN ('active', 'pending') THEN vtc.dtc_id END) AS current_issues,
    COUNT(DISTINCT dch.dtc_id) AS historical_issues,
    MAX(vr.completion_percentage) AS readiness_completion,
    MAX(vm.service_date) AS last_service_date,
    (SELECT COUNT(*) FROM PredictiveMaintenanceAlerts pma WHERE pma.vehicle_id = v.vehicle_id AND pma.acknowledged = FALSE) AS pending_alerts,
    (SELECT MAX(reading_timestamp) FROM LiveDataReadings ldr JOIN DiagnosticSessions ds ON ldr.session_id = ds.session_id WHERE ds.vehicle_id = v.vehicle_id) AS last_data_received,
    (SELECT param_value FROM VehicleCustomParameters vcp WHERE vcp.vehicle_id = v.vehicle_id AND vcp.param_name = 'health_score' ORDER BY updated_at DESC LIMIT 1) AS health_score,
    (SELECT MAX(charge_cycles) FROM EVBatteryReadings ebr JOIN DiagnosticSessions ds ON ebr.session_id = ds.session_id WHERE ds.vehicle_id = v.vehicle_id) AS battery_cycles,
    v.fuel_type
FROM Vehicles v
JOIN Manufacturers m ON v.manufacturer_id = m.manufacturer_id
LEFT JOIN VehicleTroubleCodes vtc ON vtc.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
LEFT JOIN DiagnosticCodeHistory dch ON v.vehicle_id = dch.vehicle_id
LEFT JOIN VehicleReadiness vr ON vr.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
LEFT JOIN VehicleMaintenanceRecords vm ON v.vehicle_id = vm.vehicle_id
GROUP BY v.vehicle_id, m.name, v.model, v.year, v.fuel_type;

-- Diagnostic Code Correlations View
CREATE OR REPLACE VIEW diagnostic_code_correlations AS
SELECT
    t1.code AS primary_code,
    t1.description AS primary_description,
    t2.code AS related_code,
    t2.description AS related_description,
    dcr.relationship_type,
    dcr.confidence_score,
    COUNT(DISTINCT vtc1.vehicle_dtc_id) AS co_occurrence_count,
    tcc1.category_name AS primary_category,
    tcc2.category_name AS related_category
FROM DiagnosticCodeRelationships dcr
JOIN TroubleCodes t1 ON dcr.primary_dtc_id = t1.dtc_id
JOIN TroubleCodes t2 ON dcr.related_dtc_id = t2.dtc_id
JOIN TroubleCodeCategories tcc1 ON t1.category_id = tcc1.category_id
JOIN TroubleCodeCategories tcc2 ON t2.category_id = tcc2.category_id
LEFT JOIN VehicleTroubleCodes vtc1 ON t1.dtc_id = vtc1.dtc_id
LEFT JOIN VehicleTroubleCodes vtc2 ON t2.dtc_id = vtc2.dtc_id AND vtc1.session_id = vtc2.session_id
GROUP BY dcr.relationship_id, t1.code, t1.description, t2.code, t2.description,
         dcr.relationship_type, dcr.confidence_score, tcc1.category_name, tcc2.category_name
ORDER BY co_occurrence_count DESC;

-- SLA Breach View
CREATE OR REPLACE VIEW enterprise.v_sla_breaches AS
SELECT
    kv.id AS kpi_value_id,
    vd.name AS vendor_name,
    kd.name AS kpi_name,
    kv.period_start,
    kv.actual_value,
    kt.target_value,
    kv.actual_value - kt.target_value AS deviation,
    kv.unit,
    vc.contract_number,
    vc.sla_terms,
    kv.created_at
FROM
    enterprise.kpi_values kv
JOIN enterprise.kpi_definitions kd ON kv.kpi_id = kd.id
JOIN enterprise.vendors vd ON kv.dimension_id = vd.id AND kv.dimension_type = 'vendor'
JOIN enterprise.kpi_targets kt ON kv.kpi_id = kt.kpi_id
    AND kv.dimension_id = kt.dimension_id
    AND kv.dimension_type = kt.dimension_type
    AND kv.period_start BETWEEN kt.effective_from AND COALESCE(kt.effective_to, 'infinity'::date)
JOIN enterprise.vendor_contracts vc ON vd.id = vc.vendor_id
WHERE
    kv.actual_value > kt.target_value;

-- Create functions for common operations

-- Function to calculate vehicle health score
CREATE OR REPLACE FUNCTION calculate_vehicle_health(p_vin VARCHAR(17))
RETURNS INTEGER AS $$
DECLARE
    v_health_score INTEGER;
    v_active_codes INTEGER;
    v_pending_codes INTEGER;
    v_historical_codes INTEGER;
    v_readiness_failed INTEGER;
    v_pending_alerts INTEGER;
    v_last_service_days INTEGER;
    v_odometer INTEGER;
    v_battery_soh DECIMAL(5,2);
    v_communication_errors INTEGER;
    v_communication_total INTEGER;
    v_base_score INTEGER := 100;
BEGIN
    -- Get active and pending DTCs
    SELECT
        COUNT(DISTINCT CASE WHEN status = 'active' THEN dtc_id END),
        COUNT(DISTINCT CASE WHEN status = 'pending' THEN dtc_id END)
    INTO v_active_codes, v_pending_codes
    FROM VehicleTroubleCodes vtc
    JOIN DiagnosticSessions ds ON vtc.session_id = ds.session_id
    WHERE ds.vehicle_id = p_vin;

    -- Get historical DTC count
    SELECT COUNT(DISTINCT dtc_id)
    INTO v_historical_codes
    FROM DiagnosticCodeHistory
    WHERE vehicle_id = p_vin;

    -- Get failed readiness tests
    SELECT COUNT(DISTINCT test_id)
    INTO v_readiness_failed
    FROM VehicleReadiness vr
    JOIN DiagnosticSessions ds ON vr.session_id = ds.session_id
    WHERE ds.vehicle_id = p_vin AND vr.result = 'failed';

    -- Get pending alerts
    SELECT COUNT(*)
    INTO v_pending_alerts
    FROM PredictiveMaintenanceAlerts
    WHERE vehicle_id = p_vin AND acknowledged = FALSE;

    -- Get days since last service
    SELECT EXTRACT(DAY FROM NOW() - MAX(service_date))::INTEGER
    INTO v_last_service_days
    FROM VehicleMaintenanceRecords
    WHERE vehicle_id = p_vin;

    -- Get current odometer
    SELECT odometer_km
    INTO v_odometer
    FROM RealTimeVehicleStatus
    WHERE vehicle_id = p_vin;

    -- Get battery state of health for EVs
    SELECT AVG(state_of_health)
    INTO v_battery_soh
    FROM EVBatteryReadings ebr
    JOIN DiagnosticSessions ds ON ebr.session_id = ds.session_id
    WHERE ds.vehicle_id = p_vin;

    -- Get communication error rate
    SELECT
        COUNT(CASE WHEN success = FALSE THEN 1 END),
        COUNT(*)
    INTO v_communication_errors, v_communication_total
    FROM VehicleCommunicationLogs
    WHERE vehicle_id = p_vin;

    -- Adjust base score for vehicle age
    IF v_odometer > 200000 THEN
        v_base_score := v_base_score - 10;
    ELSIF v_odometer > 100000 THEN
        v_base_score := v_base_score - 5;
    END IF;

    -- Calculate health score with all factors
    v_health_score := v_base_score -
        (COALESCE(v_active_codes, 0) * 10) -
        (COALESCE(v_pending_codes, 0) * 5) -
        (COALESCE(v_readiness_failed, 0) * 3) -
        (LEAST(COALESCE(v_historical_codes, 0), 10) * 1) -
        (COALESCE(v_pending_alerts, 0) * 2) -
        (CASE WHEN COALESCE(v_last_service_days, 0) > 365 THEN 5
              WHEN COALESCE(v_last_service_days, 0) > 180 THEN 2
              ELSE 0 END) -
        (CASE WHEN COALESCE(v_communication_errors, 0) > 0 AND COALESCE(v_communication_total, 0) > 0 AND
               (v_communication_errors::FLOAT / v_communication_total) > 0.1 THEN 5
              ELSE 0 END);

    -- Adjust for battery health if applicable
    IF v_battery_soh IS NOT NULL THEN
        IF v_battery_soh < 70 THEN
            v_health_score := v_health_score - 15;
        ELSIF v_battery_soh < 80 THEN
            v_health_score := v_health_score - 10;
        ELSIF v_battery_soh < 90 THEN
            v_health_score := v_health_score - 5;
        END IF;
    END IF;

    -- Ensure score is within bounds
    IF v_health_score < 0 THEN
        v_health_score := 0;
    ELSIF v_health_score > 100 THEN
        v_health_score := 100;
    END IF;

    -- Update vehicle custom parameters with the new score
    INSERT INTO VehicleCustomParameters (
        vehicle_id,
        param_name,
        param_value,
        data_type
    )
    VALUES (
        p_vin,
        'health_score',
        v_health_score::TEXT,
        'number'
    )
    ON CONFLICT (vehicle_id, param_name) DO UPDATE
    SET param_value = v_health_score::TEXT,
        updated_at = CURRENT_TIMESTAMP;

    RETURN v_health_score;
END;
$$ LANGUAGE plpgsql;

-- Function to export personal data (GDPR compliance)
CREATE OR REPLACE FUNCTION export_personal_data(p_email VARCHAR)
RETURNS TABLE (
    subject_id INTEGER,
    full_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE,
    last_login TIMESTAMP WITH TIME ZONE,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.user_id,
        u.first_name || ' ' || u.last_name,
        u.email,
        u.phone,
        u.created_at,
        u.last_login,
        u.status::TEXT
    FROM Users u
    WHERE u.email = p_email;
END;
$$ LANGUAGE plpgsql;

-- Function to erase personal data (GDPR Right to be Forgotten)
CREATE OR REPLACE FUNCTION erase_personal_data(p_email VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    SELECT user_id INTO v_user_id FROM Users WHERE email = p_email;

    IF v_user_id IS NOT NULL THEN
        -- Anonymize data in Users
        UPDATE Users
        SET first_name = '[REDACTED]',
            last_name = '[REDACTED]',
            email = 'deleted_' || v_user_id || '@example.com',
            phone = NULL,
            password_hash = 'DELETED',
            status = 'deleted'::user_status_enum,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = v_user_id;

        -- Insert audit log entry
        INSERT INTO AuditLog (
            user_id,
            action_type,
            table_affected,
            record_id,
            status
        ) VALUES (
            NULL,
            'gdpr_erasure',
            'Users',
            v_user_id::TEXT,
            'success'
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for data integrity

-- Trigger to update session end time on new DTC
CREATE OR REPLACE FUNCTION update_session_end_time()
RETURNS TRIGGER AS $$
DECLARE
    v_vehicle_id VARCHAR(17);
    v_dtc_count INTEGER;
BEGIN
    -- Update session end time
    UPDATE DiagnosticSessions
    SET session_end = CURRENT_TIMESTAMP
    WHERE session_id = NEW.session_id AND session_end IS NULL;

    -- Get vehicle ID
    SELECT vehicle_id INTO v_vehicle_id
    FROM DiagnosticSessions
    WHERE session_id = NEW.session_id;

    -- Update diagnostic code history
    INSERT INTO DiagnosticCodeHistory (
        vehicle_id,
        dtc_id,
        first_detected,
        last_detected,
        occurrence_count,
        last_mileage,
        subsystem_id
    )
    VALUES (
        v_vehicle_id,
        NEW.dtc_id,
        NEW.detection_timestamp,
        NEW.detection_timestamp,
        1,
        (SELECT odometer_km FROM RealTimeVehicleStatus WHERE vehicle_id = v_vehicle_id),
        NEW.subsystem_id
    )
    ON CONFLICT (vehicle_id, dtc_id) DO UPDATE
    SET last_detected = NEW.detection_timestamp,
        occurrence_count = DiagnosticCodeHistory.occurrence_count + 1,
        average_interval_days = COALESCE(
            EXTRACT(EPOCH FROM (NEW.detection_timestamp - DiagnosticCodeHistory.last_detected)) / 86400 / DiagnosticCodeHistory.occurrence_count,
            0
        ),
        last_mileage = (SELECT odometer_km FROM RealTimeVehicleStatus WHERE vehicle_id = v_vehicle_id),
        subsystem_id = COALESCE(NEW.subsystem_id, DiagnosticCodeHistory.subsystem_id);

    -- Check if this is a chronic issue (3+ occurrences)
    SELECT occurrence_count INTO v_dtc_count
    FROM DiagnosticCodeHistory
    WHERE vehicle_id = v_vehicle_id AND dtc_id = NEW.dtc_id;

    IF v_dtc_count >= 3 THEN
        UPDATE DiagnosticCodeHistory
        SET
            is_chronic = TRUE,
            chronic_score = LEAST(1.0, 0.3 + (v_dtc_count * 0.1))
        WHERE vehicle_id = v_vehicle_id AND dtc_id = NEW.dtc_id;
    END IF;

    -- Recalculate vehicle health score
    PERFORM calculate_vehicle_health(v_vehicle_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_session_end_time
AFTER INSERT ON VehicleTroubleCodes
FOR EACH ROW
EXECUTE FUNCTION update_session_end_time();

-- Trigger to validate live data readings
CREATE OR REPLACE FUNCTION validate_live_data_readings()
RETURNS TRIGGER AS $$
DECLARE
    v_min_value DECIMAL(15, 5);
    v_max_value DECIMAL(15, 5);
    v_normal_range JSONB;
BEGIN
    -- Get parameter validation rules
    SELECT
        min_value,
        max_value,
        normal_range
    INTO
        v_min_value,
        v_max_value,
        v_normal_range
    FROM ParameterIds
    WHERE pid_id = NEW.pid_id;

    -- Set out_of_range flag if value exceeds min/max
    IF v_min_value IS NOT NULL AND NEW.reading_value < v_min_value THEN
        NEW.is_out_of_range := TRUE;
    ELSIF v_max_value IS NOT NULL AND NEW.reading_value > v_max_value THEN
        NEW.is_out_of_range := TRUE;
    END IF;

    -- Check against normal operating range if available
    IF v_normal_range IS NOT NULL THEN
        IF (v_normal_range->>'min') IS NOT NULL
          AND NEW.reading_value < (v_normal_range->>'min')::DECIMAL THEN
            NEW.is_anomaly := TRUE;
            NEW.anomaly_score := GREATEST(0.7, COALESCE(NEW.anomaly_score, 0));
        ELSIF (v_normal_range->>'max') IS NOT NULL
             AND NEW.reading_value > (v_normal_range->>'max')::DECIMAL THEN
            NEW.is_anomaly := TRUE;
            NEW.anomaly_score := GREATEST(0.7, COALESCE(NEW.anomaly_score, 0));
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_live_data_readings
BEFORE INSERT ON LiveDataReadings
FOR EACH ROW
EXECUTE FUNCTION validate_live_data_readings();

-- Trigger to log firmware updates
CREATE OR REPLACE FUNCTION log_ecu_firmware_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.software_version IS DISTINCT FROM NEW.software_version THEN
        INSERT INTO EcuFirmwareHistory (
            ecu_id,
            firmware_version,
            installed_by
        )
        VALUES (
            NEW.ecu_id,
            NEW.software_version,
            (SELECT user_id FROM Users WHERE username = CURRENT_USER LIMIT 1)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_ecu_firmware_update
AFTER UPDATE ON VehicleECUs
FOR EACH ROW
EXECUTE FUNCTION log_ecu_firmware_update();

-- Create indexes for performance optimization
CREATE INDEX idx_vehicles_manufacturer_year ON Vehicles(manufacturer_id, year);
CREATE INDEX idx_dtc_codes_category ON TroubleCodes(code, category_id);
CREATE INDEX idx_livedata_session_pid ON LiveDataReadings(session_id, pid_id);
CREATE INDEX idx_commlogs_vehicle_timestamp ON VehicleCommunicationLogs(vehicle_id, timestamp);
CREATE INDEX idx_maintenance_vehicle_date ON VehicleMaintenanceRecords(vehicle_id, service_date);

-- Enable row-level security for multi-tenant isolation
ALTER TABLE Users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to only see their own data
CREATE POLICY user_isolation_policy ON Users
    USING (user_id = current_setting('app.current_user_id', TRUE)::INTEGER);

-- Create policy for admins to see all data
CREATE POLICY admin_access_policy ON Users
    USING (EXISTS (
        SELECT 1 FROM UserRoles
        WHERE user_id = current_setting('app.current_user_id', TRUE)::INTEGER
        AND role_name = 'admin'
    ));

-- Function to set current user context
CREATE OR REPLACE FUNCTION set_user_context(p_user_id INTEGER)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_user_id', p_user_id::TEXT, FALSE);
END;
$$ LANGUAGE plpgsql;


---views

-- PostgreSQL Views for OBD Diagnostic Tool Database

-- This file contains views designed to simplify querying and provide useful summaries
-- based on the tables defined in complete_postgresql_schema.sql.

-- Re-include views already created in the main schema file for completeness

-- Vehicle Health Summary View
CREATE OR REPLACE VIEW vehicle_health_summary AS
SELECT
    v.vehicle_id,
    m.name AS make,
    v.model,
    v.year,
    COUNT(DISTINCT CASE WHEN vtc.status IN (
        SELECT unnest(enum_range(NULL::dtc_status_enum))
        WHERE unnest::TEXT IN (
            CASE WHEN enum_exists(
                unnest(enum_range(NULL::dtc_status_enum))::TEXT,
                ARRAY[
                    (SELECT unnest(enum_range(NULL::dtc_status_enum)) WHERE unnest::TEXT = 'active')::TEXT,
                    (SELECT unnest(enum_range(NULL::dtc_status_enum)) WHERE unnest::TEXT = 'pending')::TEXT
                ]
            ) THEN unnest::TEXT ELSE NULL END
        )
    ) THEN vtc.dtc_id END) AS current_issues,
    COUNT(DISTINCT dch.dtc_id) AS historical_issues,
    MAX(vr.completion_percentage) AS readiness_completion,
    MAX(vm.service_date) AS last_service_date,
    (SELECT COUNT(*) FROM PredictiveMaintenanceAlerts pma WHERE pma.vehicle_id = v.vehicle_id AND pma.acknowledged = FALSE) AS pending_alerts,
    (SELECT MAX(reading_timestamp) FROM LiveDataReadings ldr JOIN DiagnosticSessions ds ON ldr.session_id = ds.session_id WHERE ds.vehicle_id = v.vehicle_id) AS last_data_received,
    (SELECT param_value FROM VehicleCustomParameters vcp WHERE vcp.vehicle_id = v.vehicle_id AND vcp.param_name = 'health_score' ORDER BY updated_at DESC LIMIT 1) AS health_score,
    (SELECT MAX(charge_cycles) FROM EVBatteryReadings ebr JOIN DiagnosticSessions ds ON ebr.session_id = ds.session_id WHERE ds.vehicle_id = v.vehicle_id) AS battery_cycles,
    v.fuel_type
FROM Vehicles v
JOIN Manufacturers m ON v.manufacturer_id = m.manufacturer_id
LEFT JOIN VehicleTroubleCodes vtc ON vtc.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
LEFT JOIN DiagnosticCodeHistory dch ON v.vehicle_id = dch.vehicle_id
LEFT JOIN VehicleReadiness vr ON vr.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
LEFT JOIN VehicleMaintenanceRecords vm ON v.vehicle_id = vm.vehicle_id
GROUP BY v.vehicle_id, m.name, v.model, v.year, v.fuel_type;
COMMENT ON VIEW vehicle_health_summary IS 'Provides a summary of vehicle health indicators, including current issues, historical problems, readiness status, maintenance, and alerts.';

-- Diagnostic Code Correlations View
CREATE OR REPLACE VIEW diagnostic_code_correlations AS
SELECT
    t1.code AS primary_code,
    t1.description AS primary_description,
    t2.code AS related_code,
    t2.description AS related_description,
    dcr.relationship_type,
    dcr.confidence_score,
    COUNT(DISTINCT vtc1.vehicle_dtc_id) AS co_occurrence_count,
    tcc1.category_name AS primary_category,
    tcc2.category_name AS related_category
FROM DiagnosticCodeRelationships dcr
JOIN TroubleCodes t1 ON dcr.primary_dtc_id = t1.dtc_id
JOIN TroubleCodes t2 ON dcr.related_dtc_id = t2.dtc_id
JOIN TroubleCodeCategories tcc1 ON t1.category_id = tcc1.category_id
JOIN TroubleCodeCategories tcc2 ON t2.category_id = tcc2.category_id
LEFT JOIN VehicleTroubleCodes vtc1 ON t1.dtc_id = vtc1.dtc_id
LEFT JOIN VehicleTroubleCodes vtc2 ON t2.dtc_id = vtc2.dtc_id AND vtc1.session_id = vtc2.session_id
GROUP BY dcr.relationship_id, t1.code, t1.description, t2.code, t2.description,
         dcr.relationship_type, dcr.confidence_score, tcc1.category_name, tcc2.category_name
ORDER BY co_occurrence_count DESC;
COMMENT ON VIEW diagnostic_code_correlations IS 'Shows relationships and co-occurrence counts between different Diagnostic Trouble Codes (DTCs).';

-- SLA Breach View (Enterprise Schema)
CREATE OR REPLACE VIEW enterprise.v_sla_breaches AS
SELECT
    kv.id AS kpi_value_id,
    vd.name AS vendor_name,
    kd.name AS kpi_name,
    kv.period_start,
    kv.actual_value,
    kt.target_value,
    kv.actual_value - kt.target_value AS deviation,
    kv.unit,
    vc.contract_number,
    vc.sla_terms,
    kv.created_at
FROM
    enterprise.kpi_values kv
JOIN enterprise.kpi_definitions kd ON kv.kpi_id = kd.id
JOIN enterprise.vendors vd ON kv.dimension_id = vd.id AND kv.dimension_type = 'vendor'
JOIN enterprise.kpi_targets kt ON kv.kpi_id = kt.kpi_id
    AND kv.dimension_id = kt.dimension_id
    AND kv.dimension_type = kt.dimension_type
    AND kv.period_start BETWEEN kt.effective_from AND COALESCE(kt.effective_to, 'infinity'::date)
JOIN enterprise.vendor_contracts vc ON vd.id = vc.vendor_id
WHERE
    kv.actual_value > kt.target_value;
COMMENT ON VIEW enterprise.v_sla_breaches IS 'Identifies instances where vendor Key Performance Indicators (KPIs) have breached their target values according to contracts.';

-- New Views --

-- Simplified Vehicle Details View
CREATE OR REPLACE VIEW v_vehicle_details AS
SELECT
    v.vehicle_id,
    v.vin,
    m.name AS manufacturer,
    v.model,
    v.year,
    vt.type_name AS vehicle_type,
    v.fuel_type,
    v.engine_displacement_cc,
    v.transmission_type,
    v.color,
    v.registration_number,
    v.registration_state,
    v.last_known_mileage,
    v.last_known_location_lat,
    v.last_known_location_long,
    v.created_at AS vehicle_added_date
FROM Vehicles v
JOIN Manufacturers m ON v.manufacturer_id = m.manufacturer_id
LEFT JOIN VehicleTypes vt ON v.vehicle_type_id = vt.type_id;
COMMENT ON VIEW v_vehicle_details IS 'Provides a simplified view of vehicle information, joining basic details with manufacturer and vehicle type.';

-- Active DTC Summary View
CREATE OR REPLACE VIEW v_active_dtc_summary AS
SELECT
    ds.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    tc.code AS dtc_code,
    tc.description AS dtc_description,
    tcc.category_name AS dtc_category,
    vtc.status AS dtc_status,
    vtc.detection_timestamp,
    ds.session_start AS session_start_time
FROM VehicleTroubleCodes vtc
JOIN TroubleCodes tc ON vtc.dtc_id = tc.dtc_id
JOIN TroubleCodeCategories tcc ON tc.category_id = tcc.category_id
JOIN DiagnosticSessions ds ON vtc.session_id = ds.session_id
JOIN Vehicles v ON ds.vehicle_id = v.vehicle_id
WHERE vtc.status IN (
    SELECT unnest(enum_range(NULL::dtc_status_enum))
    WHERE unnest::TEXT IN (
        CASE WHEN enum_exists(
            unnest(enum_range(NULL::dtc_status_enum))::TEXT,
            ARRAY[
                (SELECT unnest(enum_range(NULL::dtc_status_enum)) WHERE unnest::TEXT = 'active')::TEXT,
                (SELECT unnest(enum_range(NULL::dtc_status_enum)) WHERE unnest::TEXT = 'pending')::TEXT
            ]
        ) THEN unnest::TEXT ELSE NULL END
    )
);
COMMENT ON VIEW v_active_dtc_summary IS 'Lists currently active or pending Diagnostic Trouble Codes (DTCs) for all vehicles, including code descriptions and session details.';

-- User Roles and Permissions View
CREATE OR REPLACE VIEW v_user_roles_permissions AS
SELECT
    u.user_id,
    u.username,
    u.email,
    r.role_name,
    p.permission_name,
    p.description AS permission_description
FROM Users u
JOIN UserRoles ur ON u.user_id = ur.user_id
JOIN Roles r ON ur.role_id = r.role_id
LEFT JOIN UserPermissions up ON u.user_id = up.user_id
LEFT JOIN Permissions p ON up.permission_id = p.permission_id
WHERE u.status = 'active'::user_status_enum;
COMMENT ON VIEW v_user_roles_permissions IS 'Shows active users along with their assigned roles and specific permissions.';

-- Vehicle Maintenance Summary View
CREATE OR REPLACE VIEW v_maintenance_summary AS
SELECT
    vmr.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    vmr.service_date,
    vmr.service_type,
    vmr.description AS service_description,
    vmr.cost,
    vmr.currency,
    vmr.odometer_reading,
    sc.name AS service_center_name,
    sc.city AS service_center_city
FROM VehicleMaintenanceRecords vmr
JOIN Vehicles v ON vmr.vehicle_id = v.vehicle_id
LEFT JOIN ServiceCenters sc ON vmr.service_center_id = sc.center_id;
COMMENT ON VIEW v_maintenance_summary IS 'Summarizes vehicle maintenance history, including service details and service center information.';

-- ECU Details View
CREATE OR REPLACE VIEW v_ecu_details AS
SELECT
    ve.ecu_id,
    ve.vehicle_id,
    v.model AS vehicle_model,
    ve.ecu_name,
    ve.part_number,
    ve.serial_number,
    ve.hardware_version,
    ve.software_version,
    ve.location_in_vehicle,
    ve.communication_protocol,
    ve.security_level,
    ve.last_communication,
    ve.status AS ecu_status
FROM VehicleECUs ve
JOIN Vehicles v ON ve.vehicle_id = v.vehicle_id;
COMMENT ON VIEW v_ecu_details IS 'Provides detailed information about Electronic Control Units (ECUs) installed in vehicles.';

-- Diagnostic Session Summary View
CREATE OR REPLACE VIEW v_diagnostic_session_summary AS
SELECT
    ds.session_id,
    ds.vehicle_id,
    v.model AS vehicle_model,
    u.username AS technician_username,
    dt.tool_name AS diagnostic_tool,
    ds.session_start,
    ds.session_end,
    EXTRACT(EPOCH FROM (ds.session_end - ds.session_start)) / 60 AS duration_minutes,
    (SELECT COUNT(*) FROM VehicleTroubleCodes vtc WHERE vtc.session_id = ds.session_id) AS dtc_count,
    (SELECT COUNT(*) FROM LiveDataReadings ldr WHERE ldr.session_id = ds.session_id) AS live_data_points,
    ds.status AS session_status
FROM DiagnosticSessions ds
JOIN Vehicles v ON ds.vehicle_id = v.vehicle_id
LEFT JOIN Users u ON ds.user_id = u.user_id
LEFT JOIN DiagnosticTools dt ON ds.tool_id = dt.tool_id;
COMMENT ON VIEW v_diagnostic_session_summary IS 'Summarizes diagnostic sessions, including duration, technician, tool used, and counts of DTCs and live data points.';

-- EV Battery Status View
CREATE OR REPLACE VIEW v_ev_battery_status AS
WITH LatestBatteryReading AS (
    SELECT
        ebr.battery_id,
        ebr.state_of_charge,
        ebr.state_of_health,
        ebr.pack_voltage,
        ebr.pack_current,
        ebr.pack_temperature,
        ebr.charge_cycles,
        ebr.reading_timestamp,
        ROW_NUMBER() OVER(PARTITION BY ebr.battery_id ORDER BY ebr.reading_timestamp DESC) as rn
    FROM EVBatteryReadings ebr
)
SELECT
    evb.vehicle_id,
    v.model AS vehicle_model,
    evb.battery_type,
    evb.nominal_capacity_kwh,
    evb.manufacturer AS battery_manufacturer,
    lbr.state_of_charge AS latest_soc,
    lbr.state_of_health AS latest_soh,
    lbr.pack_temperature AS latest_temp,
    lbr.charge_cycles AS latest_charge_cycles,
    lbr.reading_timestamp AS last_reading_time
FROM EVBatterySystems evb
JOIN Vehicles v ON evb.vehicle_id = v.vehicle_id
LEFT JOIN LatestBatteryReading lbr ON evb.battery_id = lbr.battery_id AND lbr.rn = 1;
COMMENT ON VIEW v_ev_battery_status IS 'Shows the latest status of Electric Vehicle (EV) batteries, including state of charge (SoC), state of health (SoH), and other key metrics.';

-- Enterprise Vendor Overview View (Enterprise Schema)
CREATE OR REPLACE VIEW enterprise.v_vendor_overview AS
SELECT
    v.id AS vendor_id,
    v.name AS vendor_name,
    v.code AS vendor_code,
    v.status AS vendor_status,
    v.onboarded_date,
    COUNT(DISTINCT vc.id) AS active_contracts,
    COUNT(DISTINCT vp.id) AS product_count,
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'on_time_delivery_rate') AS avg_on_time_delivery_rate,
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'quality_rating') AS avg_quality_rating
FROM enterprise.vendors v
LEFT JOIN enterprise.vendor_contracts vc ON v.id = vc.vendor_id AND vc.status = 'active'
LEFT JOIN enterprise.vendor_products vp ON v.id = vp.vendor_id AND vp.is_active = TRUE
LEFT JOIN enterprise.vendor_performance_metrics vpm ON v.id = vpm.vendor_id
GROUP BY v.id, v.name, v.code, v.status, v.onboarded_date;
COMMENT ON VIEW enterprise.v_vendor_overview IS 'Provides an overview of vendors, including their status, number of active contracts, products, and key performance metrics.';

-- Recent User Activity View
CREATE OR REPLACE VIEW v_user_activity_recent AS
SELECT
    ual.log_id,
    u.username,
    ual.activity_type,
    ual.description,
    ual.ip_address,
    ual.timestamp AS activity_timestamp
FROM UserActivityLog ual
JOIN Users u ON ual.user_id = u.user_id
ORDER BY ual.timestamp DESC
LIMIT 1000; -- Limit to recent activity for performance
COMMENT ON VIEW v_user_activity_recent IS 'Shows the most recent user activities logged in the system.';

-- Secure User Information View (Security Example)
CREATE OR REPLACE VIEW v_secure_user_info AS
SELECT
    user_id,
    username,
    first_name,
    last_name,
    email, -- Consider masking or omitting email depending on security needs
    status,
    created_at,
    last_login
FROM Users
WHERE status = 'active'::user_status_enum;
COMMENT ON VIEW v_secure_user_info IS 'Provides a restricted view of user information, omitting sensitive fields like password hash and potentially phone number or full email.';

-- Add more views as needed for other tables and use cases...

-- Example: View for Live Data Parameters
CREATE OR REPLACE VIEW v_live_data_parameters AS
SELECT
    pid.pid_id,
    pid.parameter_name,
    pid.description AS parameter_description,
    pid.unit,
    pid.min_value,
    pid.max_value,
    pid.normal_range,
    op.protocol_name
FROM ParameterIds pid
LEFT JOIN ObdProtocols op ON pid.protocol_id = op.protocol_id;
COMMENT ON VIEW v_live_data_parameters IS 'Lists available live data parameters (PIDs) with their descriptions, units, and associated OBD protocols.';

-- Example: View for Repair Orders Summary
CREATE OR REPLACE VIEW v_repair_orders_summary AS
SELECT
    ro.order_id,
    ro.vehicle_id,
    v.model AS vehicle_model,
    ro.service_center_id,
    sc.name AS service_center_name,
    ro.order_date,
    ro.status AS order_status,
    ro.total_cost,
    ro.currency,
    COUNT(roi.item_id) AS item_count,
    SUM(roi.quantity * roi.unit_price) AS calculated_item_total
FROM RepairOrders ro
JOIN Vehicles v ON ro.vehicle_id = v.vehicle_id
LEFT JOIN ServiceCenters sc ON ro.service_center_id = sc.center_id
LEFT JOIN RepairOrderItems roi ON ro.order_id = roi.order_id
GROUP BY ro.order_id, v.model, sc.name;
COMMENT ON VIEW v_repair_orders_summary IS 'Summarizes repair orders, including vehicle, service center, status, costs, and item counts.';


-- PostgreSQL Views for OBD Diagnostic Tool Database (Part 2)

-- Vehicle Subsystem Health View
CREATE OR REPLACE VIEW v_vehicle_subsystem_health AS
SELECT
    vs.subsystem_id,
    vs.name AS subsystem_name,
    v.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    COUNT(DISTINCT vtc.dtc_id) FILTER (WHERE vtc.status = 'active'::dtc_status_enum) AS active_dtc_count,
    COUNT(DISTINCT vtc.dtc_id) FILTER (WHERE vtc.status = 'pending'::dtc_status_enum) AS pending_dtc_count,
    MAX(vr.result = 'passed'::readiness_result_enum) AS readiness_passed,
    (SELECT COUNT(*) FROM PredictiveMaintenanceAlerts pma
     WHERE pma.subsystem_id = vs.subsystem_id
     AND pma.vehicle_id = v.vehicle_id
     AND pma.acknowledged = FALSE) AS pending_alerts
FROM VehicleSubsystems vs
CROSS JOIN Vehicles v
LEFT JOIN VehicleTroubleCodes vtc ON vtc.subsystem_id = vs.subsystem_id
    AND vtc.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
LEFT JOIN VehicleReadiness vr ON vr.subsystem_id = vs.subsystem_id
    AND vr.session_id IN (SELECT session_id FROM DiagnosticSessions WHERE vehicle_id = v.vehicle_id)
GROUP BY vs.subsystem_id, vs.name, v.vehicle_id, v.model, v.year;
COMMENT ON VIEW v_vehicle_subsystem_health IS 'Provides health status of each vehicle subsystem, including active/pending DTCs, readiness status, and pending alerts.';

-- Diagnostic Tool Usage Statistics View
CREATE OR REPLACE VIEW v_diagnostic_tool_usage_stats AS
SELECT
    dt.tool_id,
    dt.tool_name,
    dt.manufacturer AS tool_manufacturer,
    dt.model AS tool_model,
    COUNT(DISTINCT ds.session_id) AS total_sessions,
    COUNT(DISTINCT ds.vehicle_id) AS unique_vehicles,
    COUNT(DISTINCT ds.user_id) AS unique_users,
    AVG(EXTRACT(EPOCH FROM (ds.session_end - ds.session_start)) / 60) AS avg_session_duration_minutes,
    MAX(ds.session_start) AS last_used_date
FROM DiagnosticTools dt
LEFT JOIN DiagnosticSessions ds ON dt.tool_id = ds.tool_id
GROUP BY dt.tool_id, dt.tool_name, dt.manufacturer, dt.model;
COMMENT ON VIEW v_diagnostic_tool_usage_stats IS 'Provides usage statistics for diagnostic tools, including session counts, unique vehicles, users, and average session duration.';

-- Vehicle Software Status View
CREATE OR REPLACE VIEW v_vehicle_software_status AS
SELECT
    v.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    ve.ecu_id,
    ve.ecu_name,
    ve.software_version AS current_version,
    sp.name AS latest_package_name,
    sp.version AS latest_package_version,
    CASE WHEN ve.software_version = sp.version THEN TRUE ELSE FALSE END AS is_up_to_date,
    vsh.event_timestamp AS last_update_date,
    u.username AS updated_by
FROM Vehicles v
JOIN VehicleECUs ve ON v.vehicle_id = ve.vehicle_id
LEFT JOIN (
    SELECT ecu_id, MAX(history_id) AS latest_history_id
    FROM VehicleSoftwareHistory
    GROUP BY ecu_id
) latest_hist ON ve.ecu_id = latest_hist.ecu_id
LEFT JOIN VehicleSoftwareHistory vsh ON latest_hist.latest_history_id = vsh.history_id
LEFT JOIN SoftwarePackages sp ON vsh.package_id = sp.package_id
LEFT JOIN Users u ON vsh.performed_by = u.user_id;
COMMENT ON VIEW v_vehicle_software_status IS 'Shows the current software status of vehicle ECUs, including whether they are up-to-date with the latest available packages.';

-- Predictive Maintenance Dashboard View
CREATE OR REPLACE VIEW v_predictive_maintenance_dashboard AS
SELECT
    v.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    pma.alert_id,
    pma.alert_type,
    pma.severity,
    pma.description AS alert_description,
    pma.predicted_failure_date,
    pma.confidence_score,
    pma.recommended_action,
    vs.name AS affected_subsystem,
    pma.acknowledged,
    u.username AS acknowledged_by,
    pma.acknowledged_at,
    pma.created_at AS alert_created_at
FROM PredictiveMaintenanceAlerts pma
JOIN Vehicles v ON pma.vehicle_id = v.vehicle_id
LEFT JOIN VehicleSubsystems vs ON pma.subsystem_id = vs.subsystem_id
LEFT JOIN Users u ON pma.acknowledged_by = u.user_id
WHERE pma.status != 'resolved'::alert_status_enum;
COMMENT ON VIEW v_predictive_maintenance_dashboard IS 'Provides a dashboard view of active predictive maintenance alerts, including severity, affected subsystems, and acknowledgment status.';

-- Machine Learning Model Performance View
CREATE OR REPLACE VIEW v_ml_model_performance AS
SELECT
    mlm.model_id,
    mlm.model_name,
    mlm.model_type,
    mlm.version,
    mlm.training_date,
    mlm.accuracy_score,
    mlm.precision_score,
    mlm.recall_score,
    mlm.f1_score,
    mlm.training_data_size,
    COUNT(mp.prediction_id) AS total_predictions,
    SUM(CASE WHEN mp.was_correct = TRUE THEN 1 ELSE 0 END) AS correct_predictions,
    CASE WHEN COUNT(mp.prediction_id) > 0
         THEN SUM(CASE WHEN mp.was_correct = TRUE THEN 1 ELSE 0 END)::FLOAT / COUNT(mp.prediction_id)
         ELSE NULL
    END AS real_world_accuracy,
    AVG(mp.confidence_score) AS avg_confidence_score
FROM MachineLearningModels mlm
LEFT JOIN ModelPredictions mp ON mlm.model_id = mp.model_id
GROUP BY mlm.model_id, mlm.model_name, mlm.model_type, mlm.version, mlm.training_date,
         mlm.accuracy_score, mlm.precision_score, mlm.recall_score, mlm.f1_score, mlm.training_data_size;
COMMENT ON VIEW v_ml_model_performance IS 'Evaluates the performance of machine learning models, comparing training metrics with real-world prediction accuracy.';

-- Vehicle Network Topology View
CREATE OR REPLACE VIEW v_vehicle_network_topology AS
SELECT
    v.vehicle_id,
    v.model AS vehicle_model,
    vnt.network_type,
    vnt.bus_name,
    vnt.bus_speed,
    COUNT(DISTINCT vnt.ecu_id) AS connected_ecu_count,
    STRING_AGG(ve.ecu_name, ', ' ORDER BY vnt.node_position) AS connected_ecus,
    MAX(vnt.is_backbone) AS has_backbone,
    SUM(CASE WHEN vnt.is_redundant THEN 1 ELSE 0 END) AS redundant_connections
FROM VehicleNetworkTopology vnt
JOIN Vehicles v ON vnt.vehicle_id = v.vehicle_id
JOIN VehicleECUs ve ON vnt.ecu_id = ve.ecu_id
GROUP BY v.vehicle_id, v.model, vnt.network_type, vnt.bus_name, vnt.bus_speed;
COMMENT ON VIEW v_vehicle_network_topology IS 'Provides a summary of vehicle network topology, including bus types, connected ECUs, and network characteristics.';

-- Diagnostic Code Frequency Analysis View
CREATE OR REPLACE VIEW v_diagnostic_code_frequency AS
SELECT
    tc.code AS dtc_code,
    tc.description AS dtc_description,
    tcc.category_name AS category,
    COUNT(DISTINCT vtc.vehicle_dtc_id) AS occurrence_count,
    COUNT(DISTINCT vtc.session_id) AS session_count,
    COUNT(DISTINCT ds.vehicle_id) AS affected_vehicle_count,
    ROUND(AVG(dcs.avg_repair_time_min)::NUMERIC, 2) AS avg_repair_time_minutes,
    ROUND(AVG(dcs.avg_repair_cost)::NUMERIC, 2) AS avg_repair_cost,
    dcs.most_common_solution
FROM TroubleCodes tc
JOIN TroubleCodeCategories tcc ON tc.category_id = tcc.category_id
LEFT JOIN VehicleTroubleCodes vtc ON tc.dtc_id = vtc.dtc_id
LEFT JOIN DiagnosticSessions ds ON vtc.session_id = ds.session_id
LEFT JOIN DiagnosticCodeStatistics dcs ON tc.dtc_id = dcs.dtc_id
GROUP BY tc.code, tc.description, tcc.category_name, dcs.most_common_solution
ORDER BY occurrence_count DESC;
COMMENT ON VIEW v_diagnostic_code_frequency IS 'Analyzes the frequency of diagnostic trouble codes, including occurrence counts, affected vehicles, and repair statistics.';

-- EV Charging Efficiency View
CREATE OR REPLACE VIEW v_ev_charging_efficiency AS
SELECT
    v.vehicle_id,
    v.model AS vehicle_model,
    ech.charging_id,
    ech.start_time,
    ech.end_time,
    EXTRACT(EPOCH FROM (ech.end_time - ech.start_time)) / 3600 AS charging_duration_hours,
    ech.start_soc,
    ech.end_soc,
    (ech.end_soc - ech.start_soc) AS soc_increase,
    ech.energy_delivered_kwh,
    CASE
        WHEN ech.energy_delivered_kwh > 0 AND (ech.end_soc - ech.start_soc) > 0
        THEN (ech.end_soc - ech.start_soc) / ech.energy_delivered_kwh
        ELSE NULL
    END AS efficiency_percent_per_kwh,
    ech.charging_power_kw,
    ech.charger_type,
    ech.charging_location
FROM EVChargingHistory ech
JOIN Vehicles v ON ech.vehicle_id = v.vehicle_id
WHERE ech.completed_normally = TRUE;
COMMENT ON VIEW v_ev_charging_efficiency IS 'Analyzes the efficiency of EV charging sessions, including duration, energy delivered, and state of charge increases.';

-- User Permission Matrix View
CREATE OR REPLACE VIEW v_user_permission_matrix AS
SELECT
    u.user_id,
    u.username,
    u.email,
    r.role_name,
    STRING_AGG(DISTINCT p.permission_name, ', ' ORDER BY p.permission_name) AS permissions
FROM Users u
JOIN UserRoles ur ON u.user_id = ur.user_id
JOIN Roles r ON ur.role_id = r.role_id
LEFT JOIN RolePermissions rp ON r.role_id = rp.role_id
LEFT JOIN Permissions p ON rp.permission_id = p.permission_id
WHERE u.status = 'active'::user_status_enum
GROUP BY u.user_id, u.username, u.email, r.role_name;
COMMENT ON VIEW v_user_permission_matrix IS 'Provides a matrix view of users, their roles, and aggregated permissions.';

-- Vehicle Ownership Timeline View
CREATE OR REPLACE VIEW v_vehicle_ownership_timeline AS
SELECT
    v.vehicle_id,
    v.model AS vehicle_model,
    v.year AS vehicle_year,
    voh.ownership_id,
    voh.owner_name,
    voh.ownership_start,
    voh.ownership_end,
    voh.ownership_type,
    voh.registration_number,
    voh.registration_state,
    voh.odometer_at_transfer,
    LEAD(voh.ownership_start) OVER (PARTITION BY v.vehicle_id ORDER BY voh.ownership_start) AS next_ownership_start,
    CASE
        WHEN voh.ownership_end IS NULL THEN 'current'
        ELSE 'previous'
    END AS ownership_status
FROM Vehicles v
LEFT JOIN VehicleOwnershipHistory voh ON v.vehicle_id = voh.vehicle_id
ORDER BY v.vehicle_id, voh.ownership_start;
COMMENT ON VIEW v_vehicle_ownership_timeline IS 'Provides a timeline of vehicle ownership changes, including registration details and odometer readings at transfer.';

-- Component Reliability Analysis View
CREATE OR REPLACE VIEW v_component_reliability_analysis AS
SELECT
    vc.component_type,
    vs.name AS subsystem_name,
    COUNT(vc.component_id) AS total_components,
    AVG(EXTRACT(EPOCH FROM (COALESCE(vc.replaced_date, CURRENT_DATE) - vc.installed_date)) / 86400 / 30) AS avg_lifetime_months,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (COALESCE(vc.replaced_date, CURRENT_DATE) - vc.installed_date)) / 86400 / 30) AS median_lifetime_months,
    COUNT(CASE WHEN vc.status = 'failed'::component_status_enum THEN 1 END) AS failure_count,
    ROUND((COUNT(CASE WHEN vc.status = 'failed'::component_status_enum THEN 1 END)::FLOAT / NULLIF(COUNT(vc.component_id), 0)) * 100, 2) AS failure_rate_percent
FROM VehicleComponents vc
LEFT JOIN VehicleSubsystems vs ON vc.subsystem_id = vs.subsystem_id
GROUP BY vc.component_type, vs.name
ORDER BY failure_rate_percent DESC NULLS LAST;
COMMENT ON VIEW v_component_reliability_analysis IS 'Analyzes the reliability of vehicle components, including average lifetime, failure rates, and subsystem correlations.';

-- Audit Trail View
CREATE OR REPLACE VIEW v_audit_trail AS
SELECT
    al.log_id,
    al.entity_type,
    al.entity_id,
    al.action,
    u.username AS performed_by,
    al.timestamp AS action_timestamp,
    al.ip_address,
    al.user_agent,
    al.old_values,
    al.new_values
FROM audit_logs al
LEFT JOIN Users u ON al.user_id = u.user_id
ORDER BY al.timestamp DESC;
COMMENT ON VIEW v_audit_trail IS 'Provides a comprehensive audit trail of all system changes, including who made the changes and what was modified.';

-- Enterprise KPI Dashboard View
CREATE OR REPLACE VIEW enterprise.v_kpi_dashboard AS
SELECT
    kd.id AS kpi_id,
    kd.name AS kpi_name,
    kd.category,
    kd.unit,
    kv.period_start,
    kv.period_end,
    kv.actual_value,
    kt.target_value,
    kv.actual_value - kt.target_value AS variance,
    CASE
        WHEN kt.target_value != 0 AND kt.target_value IS NOT NULL
        THEN ROUND(((kv.actual_value - kt.target_value) / ABS(kt.target_value)) * 100, 2)
        ELSE NULL
    END AS variance_percent,
    kf.forecast_value,
    kf.confidence_level AS forecast_confidence
FROM enterprise.kpi_definitions kd
LEFT JOIN enterprise.kpi_values kv ON kd.id = kv.kpi_id
    AND kv.period_end = (SELECT MAX(period_end) FROM enterprise.kpi_values WHERE kpi_id = kd.id)
LEFT JOIN enterprise.kpi_targets kt ON kd.id = kt.kpi_id
    AND kv.period_start BETWEEN kt.effective_from AND COALESCE(kt.effective_to, 'infinity'::date)
LEFT JOIN enterprise.kpi_forecasts kf ON kd.id = kf.kpi_id
    AND kf.period_start > CURRENT_DATE
    AND kf.period_start = (SELECT MIN(period_start) FROM enterprise.kpi_forecasts WHERE kpi_id = kd.id AND period_start > CURRENT_DATE)
WHERE kd.is_active = TRUE;
COMMENT ON VIEW enterprise.v_kpi_dashboard IS 'Provides a dashboard view of key performance indicators, including current values, targets, variances, and forecasts.';

-- Vendor Performance Scorecard View
CREATE OR REPLACE VIEW enterprise.v_vendor_performance_scorecard AS
SELECT
    v.id AS vendor_id,
    v.name AS vendor_name,
    v.code AS vendor_code,

    -- On-time delivery metrics
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'on_time_delivery_rate' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days') AS otd_90day,
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'on_time_delivery_rate' AND vpm.period_end >= CURRENT_DATE - INTERVAL '365 days') AS otd_annual,

    -- Quality metrics
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'quality_rating' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days') AS quality_90day,
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'quality_rating' AND vpm.period_end >= CURRENT_DATE - INTERVAL '365 days') AS quality_annual,

    -- Cost metrics
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'cost_variance_percent' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days') AS cost_variance_90day,

    -- Responsiveness metrics
    AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'response_time_hours' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days') AS response_time_90day,

    -- Overall score (weighted average of key metrics)
    (
        COALESCE(AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'on_time_delivery_rate' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days'), 0) * 0.3 +
        COALESCE(AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'quality_rating' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days'), 0) * 0.4 +
        (100 - COALESCE(ABS(AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'cost_variance_percent' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days')), 0)) * 0.2 +
        (100 - COALESCE(AVG(vpm.metric_value) FILTER (WHERE vpm.metric_type = 'response_time_hours' AND vpm.period_end >= CURRENT_DATE - INTERVAL '90 days'), 0) / 24 * 100, 0) * 0.1
    ) AS overall_score
FROM enterprise.vendors v
LEFT JOIN enterprise.vendor_performance_metrics vpm ON v.id = vpm.vendor_id
WHERE v.status = 'active'
GROUP BY v.id, v.name, v.code
ORDER BY overall_score DESC;
COMMENT ON VIEW enterprise.v_vendor_performance_scorecard IS 'Provides a comprehensive scorecard of vendor performance across multiple metrics, with an overall weighted score.';

-- Supply Chain Status View
CREATE OR REPLACE VIEW enterprise.v_supply_chain_status AS
WITH OpenOrders AS (
    SELECT
        po.vendor_id,
        COUNT(po.id) AS open_orders,
        SUM(po.total_amount) AS open_order_value,
        MIN(po.expected_delivery_date) AS next_expected_delivery
    FROM enterprise.purchase_orders po
    WHERE po.status IN ('draft', 'submitted', 'approved', 'in_progress')
    GROUP BY po.vendor_id
),
InTransit AS (
    SELECT
        s.vendor_id,
        COUNT(s.id) AS shipments_in_transit,
        MIN(s.expected_arrival_date) AS next_arrival_date
    FROM enterprise.shipments s
    WHERE s.status = 'in_transit'
    GROUP BY s.vendor_id
)
SELECT
    v.id AS vendor_id,
    v.name AS vendor_name,
    oo.open_orders,
    oo.open_order_value,
    oo.next_expected_delivery,
    it.shipments_in_transit,
    it.next_arrival_date,
    (SELECT COUNT(*) FROM enterprise.supply_chain_events sce
     WHERE sce.entity_type = 'vendor' AND sce.entity_id = v.id::TEXT
     AND sce.event_type = 'delay' AND sce.occurred_at >= CURRENT_DATE - INTERVAL '30 days') AS delay_events_30days
FROM enterprise.vendors v
LEFT JOIN OpenOrders oo ON v.id = oo.vendor_id
LEFT JOIN InTransit it ON v.id = it.vendor_id
WHERE v.status = 'active';
COMMENT ON VIEW enterprise.v_supply_chain_status IS 'Provides a real-time view of supply chain status, including open orders, in-transit shipments, and recent delay events.';

-- Warehouse Inventory Status View
CREATE OR REPLACE VIEW enterprise.v_warehouse_inventory_status AS
SELECT
    w.id AS warehouse_id,
    w.name AS warehouse_name,
    w.code AS warehouse_code,
    COUNT(DISTINCT il.id) AS total_locations,
    SUM(il.capacity) AS total_capacity,
    SUM(il.capacity) FILTER (WHERE il.is_active = TRUE) AS active_capacity,
    COUNT(DISTINCT il.id) FILTER (WHERE il.location_type = 'receiving') AS receiving_locations,
    COUNT(DISTINCT il.id) FILTER (WHERE il.location_type = 'shipping') AS shipping_locations,
    COUNT(DISTINCT il.id) FILTER (WHERE il.location_type = 'storage') AS storage_locations,
    COUNT(DISTINCT il.id) FILTER (WHERE il.location_type = 'picking') AS picking_locations
FROM enterprise.warehouses w
LEFT JOIN enterprise.inventory_locations il ON w.id = il.warehouse_id
WHERE w.status = 'active'
GROUP BY w.id, w.name, w.code;
COMMENT ON VIEW enterprise.v_warehouse_inventory_status IS 'Provides an overview of warehouse inventory status, including location counts by type and capacity metrics.';

-- Security Access Audit View
CREATE OR REPLACE VIEW v_security_access_audit AS
SELECT
    dsa.access_id,
    v.vehicle_id,
    v.model AS vehicle_model,
    ve.ecu_name,
    dsa.access_level,
    dsa.algorithm_name,
    dsa.security_supported,
    dsa.last_accessed,
    (SELECT COUNT(*) FROM VehicleCommunicationLogs vcl
     WHERE vcl.vehicle_id = v.vehicle_id
     AND vcl.ecu_id = ve.ecu_id
     AND vcl.message_type = 'security_access'
     AND vcl.timestamp >= CURRENT_DATE - INTERVAL '30 days') AS access_attempts_30days,
    dsa.known_vulnerabilities
FROM DiagnosticSecurityAccess dsa
JOIN Vehicles v ON dsa.vehicle_id = v.vehicle_id
JOIN VehicleECUs ve ON dsa.ecu_id = ve.ecu_id;
COMMENT ON VIEW v_security_access_audit IS 'Provides an audit view of security access configurations and recent access attempts for vehicle ECUs.';

-- Subscription Status View
CREATE OR REPLACE VIEW v_subscription_status AS
SELECT
    s.subscription_id,
    u.user_id,
    u.username,
    u.email,
    p.plan_name,
    p.price AS plan_price,
    p.currency_code,
    s.status AS subscription_status,
    s.start_date,
    s.end_date,
    s.next_billing_date,
    s.cancel_at_period_end,
    CASE
        WHEN s.end_date IS NOT NULL AND s.end_date < CURRENT_DATE THEN 'expired'
        WHEN s.next_billing_date < CURRENT_DATE + INTERVAL '7 days' THEN 'due_soon'
        ELSE 'active'
    END AS billing_status,
    p.features AS plan_features
FROM subscriptions s
JOIN Users u ON s.user_id = u.user_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE u.status = 'active'::user_status_enum;
COMMENT ON VIEW v_subscription_status IS 'Provides a view of user subscription status, including plan details, billing dates, and upcoming renewals.';

-- API Usage Analytics View
CREATE OR REPLACE VIEW v_api_usage_analytics AS
WITH DailyUsage AS (
    SELECT
        DATE_TRUNC('day', timestamp) AS usage_date,
        user_id,
        COUNT(*) AS request_count
    FROM user_events
    WHERE event_type = 'api_request'
    AND timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', timestamp), user_id
)
SELECT
    du.usage_date,
    u.username,
    ak.name AS api_key_name,
    du.request_count,
    ak.rate_limit,
    CASE WHEN du.request_count > ak.rate_limit THEN TRUE ELSE FALSE END AS limit_exceeded
FROM DailyUsage du
JOIN Users u ON du.user_id = u.user_id
JOIN api_keys ak ON u.user_id = ak.user_id
ORDER BY du.usage_date DESC, du.request_count DESC;
COMMENT ON VIEW v_api_usage_analytics IS 'Analyzes API usage patterns, including request counts, rate limit compliance, and usage trends over time.';

-- Feature Flag Status View
CREATE OR REPLACE VIEW v_feature_flag_status AS
SELECT
    ff.flag_id,
    ff.flag_name,
    ff.description,
    ff.is_enabled,
    ff.percentage_rollout,
    ff.start_date,
    ff.end_date,
    CASE
        WHEN ff.is_enabled = FALSE THEN 'disabled'
        WHEN ff.start_date > CURRENT_TIMESTAMP THEN 'scheduled'
        WHEN ff.end_date IS NOT NULL AND ff.end_date < CURRENT_TIMESTAMP THEN 'expired'
        WHEN ff.percentage_rollout < 100 THEN 'partial_rollout'
        ELSE 'fully_enabled'
    END AS status,
    ff.user_criteria
FROM feature_flags ff;
COMMENT ON VIEW v_feature_flag_status IS 'Provides the current status of feature flags, including rollout percentages, scheduling, and targeting criteria.';

-- System Health Dashboard View
CREATE OR REPLACE VIEW v_system_health_dashboard AS
SELECT
    sh.service_name,
    sh.instance_id,
    sh.status,
    sh.last_heartbeat,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - sh.last_heartbeat)) AS seconds_since_last_heartbeat,
    CASE
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - sh.last_heartbeat)) > 300 THEN 'critical'
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - sh.last_heartbeat)) > 60 THEN 'warning'
        ELSE 'healthy'
    END AS health_status,
    sh.metadata
FROM service_heartbeats sh
ORDER BY seconds_since_last_heartbeat DESC;
COMMENT ON VIEW v_system_health_dashboard IS 'Provides a dashboard view of system service health, based on heartbeat monitoring and status reporting.';

-- Notification Summary View
CREATE OR REPLACE VIEW v_notification_summary AS
SELECT
    u.user_id,
    u.username,
    u.email,
    COUNT(n.notification_id) AS total_notifications,
    COUNT(n.notification_id) FILTER (WHERE n.is_read = FALSE) AS unread_notifications,
    COUNT(n.notification_id) FILTER (WHERE n.importance = 'high') AS high_importance_notifications,
    COUNT(n.notification_id) FILTER (WHERE n.is_read = FALSE AND n.importance = 'high') AS unread_high_importance,
    MAX(n.created_at) FILTER (WHERE n.is_read = FALSE) AS latest_unread_notification_date
FROM Users u
LEFT JOIN notifications n ON u.user_id = n.user_id
WHERE u.status = 'active'::user_status_enum
GROUP BY u.user_id, u.username, u.email;
COMMENT ON VIEW v_notification_summary IS 'Summarizes notification status for users, including counts of unread and high-importance notifications.';

-- Integration Status Dashboard View
CREATE OR REPLACE VIEW v_integration_status_dashboard AS
WITH IntegrationStats AS (
    SELECT
        integration_id,
        COUNT(*) AS total_logs,
        COUNT(*) FILTER (WHERE status = 'success') AS successful_logs,
        COUNT(*) FILTER (WHERE status = 'error') AS error_logs,
        AVG(duration_ms) FILTER (WHERE status = 'success') AS avg_success_duration_ms,
        AVG(duration_ms) FILTER (WHERE status = 'error') AS avg_error_duration_ms,
        MAX(timestamp) AS last_activity
    FROM integration_logs
    WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY integration_id
)
SELECT
    ai.integration_id,
    ai.name AS integration_name,
    ai.integration_type,
    ai.status AS integration_status,
    is.total_logs,
    is.successful_logs,
    is.error_logs,
    CASE WHEN is.total_logs > 0 THEN ROUND((is.successful_logs::FLOAT / is.total_logs) * 100, 2) ELSE NULL END AS success_rate_percent,
    is.avg_success_duration_ms,
    is.avg_error_duration_ms,
    is.last_activity,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - is.last_activity)) / 3600 AS hours_since_last_activity
FROM ApiIntegrations ai
LEFT JOIN IntegrationStats is ON ai.integration_id = is.integration_id
ORDER BY ai.status, success_rate_percent;
COMMENT ON VIEW v_integration_status_dashboard IS 'Provides a dashboard view of API integration status, including success rates, error counts, and performance metrics.';

-- Data Quality Monitoring View
CREATE OR REPLACE VIEW v_data_quality_monitoring AS
WITH ValidationResults AS (
    SELECT
        dqr.rule_id,
        dqr.table_name,
        dqr.column_name,
        COUNT(*) AS total_validations,
        SUM(CASE WHEN al.action = 'data_quality_violation' THEN 1 ELSE 0 END) AS violations
    FROM DataQualityRules dqr
    LEFT JOIN audit_logs al ON al.entity_type = 'data_quality_rule' AND al.entity_id = dqr.rule_id::TEXT
    WHERE al.timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY dqr.rule_id, dqr.table_name, dqr.column_name
)
SELECT
    dqr.rule_id,
    dqr.rule_name,
    dqr.rule_type,
    dqr.table_name,
    dqr.column_name,
    dqr.validation_expression,
    dqr.severity,
    dqr.is_active,
    vr.total_validations,
    vr.violations,
    CASE WHEN vr.total_validations > 0 THEN ROUND((1 - (vr.violations::FLOAT / vr.total_validations)) * 100, 2) ELSE NULL END AS compliance_rate_percent
FROM DataQualityRules dqr
LEFT JOIN ValidationResults vr ON dqr.rule_id = vr.rule_id
ORDER BY dqr.severity, compliance_rate_percent;
COMMENT ON VIEW v_data_quality_monitoring IS 'Monitors data quality rule compliance, tracking validation results and violation rates across database tables.';


-- Comprehensive Audit Framework for PostgreSQL Schema
-- This implementation provides:
-- 1. Comprehensive coverage across all tables
-- 2. Detailed before/after value comparisons for all fields
-- 3. Tamper-proof audit mechanisms
-- 4. Audit policy management
-- 5. Compliance reporting capabilities

-- Step 1: Create Audit Schema
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema for audit framework tables, functions, and policies';

-- Step 2: Create Audit Tables

-- Main Audit Log Table with Cryptographic Verification
CREATE TABLE audit.audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_schema VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER,
    user_name VARCHAR(255) NOT NULL DEFAULT CURRENT_USER,
    application_name VARCHAR(255) NOT NULL DEFAULT current_setting('application_name'),
    client_addr INET NOT NULL DEFAULT inet_client_addr(),
    client_port INTEGER NOT NULL DEFAULT inet_client_port(),
    session_id VARCHAR(255) NOT NULL DEFAULT to_hex(txid_current()::bigint),
    transaction_id BIGINT NOT NULL DEFAULT txid_current(),
    statement_id BIGINT NOT NULL DEFAULT pg_current_xact_id_if_assigned(),
    query_id BIGINT,
    primary_key_column VARCHAR(255),
    primary_key_value TEXT,
    row_data JSONB,
    changed_fields JSONB,
    old_data JSONB,
    new_data JSONB,
    hash_value VARCHAR(128) NOT NULL,
    hash_verified BOOLEAN DEFAULT TRUE,
    CONSTRAINT audit_log_operation_check CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE'))
);

CREATE INDEX idx_audit_log_table ON audit.audit_log (table_schema, table_name);
CREATE INDEX idx_audit_log_timestamp ON audit.audit_log (timestamp);
CREATE INDEX idx_audit_log_user ON audit.audit_log (user_id);
CREATE INDEX idx_audit_log_operation ON audit.audit_log (operation);
CREATE INDEX idx_audit_log_primary_key ON audit.audit_log (table_schema, table_name, primary_key_value);
CREATE INDEX idx_audit_log_transaction ON audit.audit_log (transaction_id);
CREATE INDEX idx_audit_log_hash ON audit.audit_log (hash_value);
CREATE INDEX idx_audit_log_changed_fields ON audit.audit_log USING GIN (changed_fields);

COMMENT ON TABLE audit.audit_log IS 'Comprehensive audit log for all database changes with cryptographic verification';

-- Audit Policy Management Table
CREATE TABLE audit.audit_policies (
    policy_id SERIAL PRIMARY KEY,
    table_schema VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    audit_insert BOOLEAN DEFAULT TRUE,
    audit_update BOOLEAN DEFAULT TRUE,
    audit_delete BOOLEAN DEFAULT TRUE,
    audit_truncate BOOLEAN DEFAULT TRUE,
    excluded_columns TEXT[] DEFAULT NULL,
    included_columns TEXT[] DEFAULT NULL,
    retention_period INTERVAL DEFAULT '7 years'::INTERVAL,
    compliance_category VARCHAR(50),
    is_pii BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    updated_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT audit_policies_unique_table UNIQUE (table_schema, table_name)
);

CREATE INDEX idx_audit_policies_table ON audit.audit_policies (table_schema, table_name);
CREATE INDEX idx_audit_policies_active ON audit.audit_policies (is_active);
CREATE INDEX idx_audit_policies_pii ON audit.audit_policies (is_pii);

COMMENT ON TABLE audit.audit_policies IS 'Configuration for audit policies by table';

-- Audit Access Log Table (for audit trail access)
CREATE TABLE audit.audit_access_log (
    access_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER,
    user_name VARCHAR(255) NOT NULL DEFAULT CURRENT_USER,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(50) NOT NULL,
    query TEXT,
    client_addr INET NOT NULL DEFAULT inet_client_addr(),
    application_name VARCHAR(255) NOT NULL DEFAULT current_setting('application_name')
);

CREATE INDEX idx_audit_access_log_user ON audit.audit_access_log (user_id);
CREATE INDEX idx_audit_access_log_timestamp ON audit.audit_access_log (timestamp);
CREATE INDEX idx_audit_access_log_action ON audit.audit_access_log (action);

COMMENT ON TABLE audit.audit_access_log IS 'Logs access to audit data for security monitoring';

-- Audit Hash Verification Table
CREATE TABLE audit.hash_verification (
    verification_id BIGSERIAL PRIMARY KEY,
    audit_id BIGINT NOT NULL REFERENCES audit.audit_log(audit_id),
    verified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_by VARCHAR(255) NOT NULL DEFAULT CURRENT_USER,
    is_valid BOOLEAN NOT NULL,
    verification_method VARCHAR(50) NOT NULL,
    details TEXT
);

CREATE INDEX idx_hash_verification_audit_id ON audit.hash_verification (audit_id);
CREATE INDEX idx_hash_verification_valid ON audit.hash_verification (is_valid);

COMMENT ON TABLE audit.hash_verification IS 'Records verification attempts of audit log hash values';

-- Audit Configuration Table
CREATE TABLE audit.configuration (
    config_id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT FALSE,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(255) DEFAULT CURRENT_USER
);

COMMENT ON TABLE audit.configuration IS 'Configuration settings for the audit framework';

-- Insert default configuration
INSERT INTO audit.configuration (config_key, config_value, description)
VALUES
('hash_algorithm', 'sha256', 'Algorithm used for cryptographic hashing'),
('default_retention_period', '7 years', 'Default retention period for audit logs'),
('log_query_text', 'true', 'Whether to log the full query text'),
('compress_old_logs', 'true', 'Whether to compress audit logs older than 90 days'),
('enable_tamper_detection', 'true', 'Enable automatic tamper detection checks');

-- Step 3: Create Types and Functions

-- Function to calculate hash for audit records
CREATE OR REPLACE FUNCTION audit.calculate_hash(
    p_table_name TEXT,
    p_operation TEXT,
    p_timestamp TIMESTAMP WITH TIME ZONE,
    p_user_name TEXT,
    p_transaction_id BIGINT,
    p_row_data JSONB,
    p_old_data JSONB,
    p_new_data JSONB
) RETURNS TEXT AS $$
DECLARE
    v_text TEXT;
    v_hash TEXT;
    v_salt TEXT;
BEGIN
    -- Get salt from configuration (in a real implementation, this would be securely stored)
    SELECT config_value INTO v_salt FROM audit.configuration WHERE config_key = 'hash_salt';
    IF v_salt IS NULL THEN
        v_salt := 'default_salt_change_in_production';
    END IF;

    -- Concatenate values for hashing
    v_text := p_table_name || '|' ||
              p_operation || '|' ||
              p_timestamp::TEXT || '|' ||
              p_user_name || '|' ||
              p_transaction_id::TEXT || '|' ||
              v_salt || '|' ||
              COALESCE(p_row_data::TEXT, '') || '|' ||
              COALESCE(p_old_data::TEXT, '') || '|' ||
              COALESCE(p_new_data::TEXT, '');

    -- Calculate hash
    v_hash := encode(digest(v_text, 'sha256'), 'hex');

    RETURN v_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.calculate_hash IS 'Calculates a cryptographic hash for audit records to ensure tamper detection';

-- Function to verify audit record hash
CREATE OR REPLACE FUNCTION audit.verify_hash(p_audit_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE
    v_record audit.audit_log%ROWTYPE;
    v_calculated_hash TEXT;
    v_result BOOLEAN;
BEGIN
    -- Get the audit record
    SELECT * INTO v_record FROM audit.audit_log WHERE audit_id = p_audit_id;

    IF v_record IS NULL THEN
        RAISE EXCEPTION 'Audit record with ID % not found', p_audit_id;
    END IF;

    -- Calculate hash based on stored values
    v_calculated_hash := audit.calculate_hash(
        v_record.table_name,
        v_record.operation,
        v_record.timestamp,
        v_record.user_name,
        v_record.transaction_id,
        v_record.row_data,
        v_record.old_data,
        v_record.new_data
    );

    -- Compare calculated hash with stored hash
    v_result := (v_calculated_hash = v_record.hash_value);

    -- Log verification attempt
    INSERT INTO audit.hash_verification (
        audit_id,
        is_valid,
        verification_method,
        details
    ) VALUES (
        p_audit_id,
        v_result,
        'manual',
        CASE WHEN v_result THEN 'Hash verified successfully'
             ELSE 'Hash verification failed: ' || v_calculated_hash || ' != ' || v_record.hash_value
        END
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.verify_hash IS 'Verifies the cryptographic hash of an audit record to detect tampering';

-- Function to get primary key columns for a table
CREATE OR REPLACE FUNCTION audit.get_primary_key_columns(p_table_schema TEXT, p_table_name TEXT)
RETURNS TEXT[] AS $$
DECLARE
    v_columns TEXT[];
BEGIN
    SELECT array_agg(a.attname::TEXT ORDER BY a.attnum)
    INTO v_columns
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    JOIN pg_class c ON c.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE i.indisprimary
    AND n.nspname = p_table_schema
    AND c.relname = p_table_name;

    RETURN v_columns;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.get_primary_key_columns IS 'Returns an array of primary key column names for a given table';

-- Function to extract primary key value from a row
CREATE OR REPLACE FUNCTION audit.extract_primary_key_value(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_row_data JSONB
) RETURNS TEXT AS $$
DECLARE
    v_pk_columns TEXT[];
    v_pk_values TEXT[];
    v_i INTEGER;
BEGIN
    -- Get primary key columns
    v_pk_columns := audit.get_primary_key_columns(p_table_schema, p_table_name);

    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        RETURN NULL;
    END IF;

    -- Extract values for each PK column
    v_pk_values := array_fill(NULL::TEXT, ARRAY[array_length(v_pk_columns, 1)]);

    FOR v_i IN 1..array_length(v_pk_columns, 1) LOOP
        v_pk_values[v_i] := p_row_data->>v_pk_columns[v_i];
    END LOOP;

    -- Concatenate PK values with a delimiter
    RETURN array_to_string(v_pk_values, '|');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.extract_primary_key_value IS 'Extracts the primary key value from a row as a string';

-- Function to determine if a table should be audited
CREATE OR REPLACE FUNCTION audit.should_audit_table(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_operation TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_policy audit.audit_policies%ROWTYPE;
BEGIN
    -- Get audit policy for the table
    SELECT * INTO v_policy
    FROM audit.audit_policies
    WHERE table_schema = p_table_schema
    AND table_name = p_table_name;

    -- If no policy exists, use default (audit everything)
    IF v_policy IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if auditing is active for this table
    IF NOT v_policy.is_active THEN
        RETURN FALSE;
    END IF;

    -- Check if the specific operation should be audited
    CASE p_operation
        WHEN 'INSERT' THEN RETURN v_policy.audit_insert;
        WHEN 'UPDATE' THEN RETURN v_policy.audit_update;
        WHEN 'DELETE' THEN RETURN v_policy.audit_delete;
        WHEN 'TRUNCATE' THEN RETURN v_policy.audit_truncate;
        ELSE RETURN TRUE; -- Default to auditing unknown operations
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.should_audit_table IS 'Determines if a table should be audited based on configured policies';

-- Function to filter columns based on audit policy
CREATE OR REPLACE FUNCTION audit.filter_columns(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_policy audit.audit_policies%ROWTYPE;
    v_result JSONB := p_data;
    v_key TEXT;
BEGIN
    -- Get audit policy for the table
    SELECT * INTO v_policy
    FROM audit.audit_policies
    WHERE table_schema = p_table_schema
    AND table_name = p_table_name;

    -- If no policy exists or no column filtering is defined, return all data
    IF v_policy IS NULL OR
       (v_policy.excluded_columns IS NULL AND v_policy.included_columns IS NULL) THEN
        RETURN p_data;
    END IF;

    -- If included_columns is specified, keep only those columns
    IF v_policy.included_columns IS NOT NULL AND array_length(v_policy.included_columns, 1) > 0 THEN
        v_result := '{}'::JSONB;

        FOREACH v_key IN ARRAY v_policy.included_columns LOOP
            IF p_data ? v_key THEN
                v_result := v_result || jsonb_build_object(v_key, p_data->v_key);
            END IF;
        END LOOP;

        RETURN v_result;
    END IF;

    -- If excluded_columns is specified, remove those columns
    IF v_policy.excluded_columns IS NOT NULL AND array_length(v_policy.excluded_columns, 1) > 0 THEN
        v_result := p_data;

        FOREACH v_key IN ARRAY v_policy.excluded_columns LOOP
            v_result := v_result - v_key;
        END LOOP;

        RETURN v_result;
    END IF;

    RETURN p_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.filter_columns IS 'Filters columns based on audit policy inclusion/exclusion lists';

-- Function to compare old and new data and extract changed fields
CREATE OR REPLACE FUNCTION audit.extract_changed_fields(
    p_old_data JSONB,
    p_new_data JSONB
) RETURNS JSONB AS $$
DECLARE
    v_changed_fields JSONB := '{}'::JSONB;
    v_key TEXT;
BEGIN
    -- Iterate through all keys in new data
    FOR v_key IN SELECT jsonb_object_keys(p_new_data) LOOP
        -- If old data doesn't have this key or values are different
        IF (NOT p_old_data ? v_key) OR (p_old_data->v_key IS DISTINCT FROM p_new_data->v_key) THEN
            v_changed_fields := v_changed_fields || jsonb_build_object(
                v_key,
                jsonb_build_object(
                    'old', p_old_data->v_key,
                    'new', p_new_data->v_key
                )
            );
        END IF;
    END LOOP;

    -- Check for keys in old data that are not in new data (should be rare)
    FOR v_key IN SELECT jsonb_object_keys(p_old_data) LOOP
        IF NOT p_new_data ? v_key THEN
            v_changed_fields := v_changed_fields || jsonb_build_object(
                v_key,
                jsonb_build_object(
                    'old', p_old_data->v_key,
                    'new', NULL
                )
            );
        END IF;
    END LOOP;

    RETURN v_changed_fields;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION audit.extract_changed_fields IS 'Extracts and formats fields that changed between old and new data';

-- Function to log access to audit data
CREATE OR REPLACE FUNCTION audit.log_audit_access() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit.audit_access_log (
        user_id,
        action,
        query
    ) VALUES (
        (SELECT user_id FROM Users WHERE username = CURRENT_USER LIMIT 1),
        TG_OP,
        current_query()
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.log_audit_access IS 'Logs access to audit data for security monitoring';

-- Step 4: Create Main Audit Trigger Function

CREATE OR REPLACE FUNCTION audit.process_audit() RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_row_data JSONB := NULL;
    v_changed_fields JSONB := NULL;
    v_primary_key_column TEXT;
    v_primary_key_value TEXT;
    v_query_id BIGINT;
    v_user_id INTEGER;
    v_hash_value TEXT;
    v_excluded_columns TEXT[];
    v_table_schema TEXT;
BEGIN
    -- Get current user ID if possible
    BEGIN
        SELECT user_id INTO v_user_id FROM Users WHERE username = CURRENT_USER LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    -- Get query ID if available (PostgreSQL 14+)
    BEGIN
        v_query_id := pg_current_query_id();
    EXCEPTION WHEN OTHERS THEN
        v_query_id := NULL;
    END;

    -- Extract schema name
    v_table_schema := TG_TABLE_SCHEMA;

    -- Check if this table should be audited for this operation
    IF NOT audit.should_audit_table(v_table_schema, TG_TABLE_NAME, TG_OP) THEN
        RETURN NULL;
    END IF;

    -- Get primary key information
    v_primary_key_column := array_to_string(audit.get_primary_key_columns(v_table_schema, TG_TABLE_NAME), ',');

    -- Handle each operation type
    CASE TG_OP
        WHEN 'INSERT' THEN
            v_row_data := to_jsonb(NEW);
            v_new_data := audit.filter_columns(v_table_schema, TG_TABLE_NAME, v_row_data);
            v_primary_key_value := audit.extract_primary_key_value(v_table_schema, TG_TABLE_NAME, v_row_data);

        WHEN 'UPDATE' THEN
            v_row_data := to_jsonb(NEW);
            v_old_data := audit.filter_columns(v_table_schema, TG_TABLE_NAME, to_jsonb(OLD));
            v_new_data := audit.filter_columns(v_table_schema, TG_TABLE_NAME, v_row_data);
            v_changed_fields := audit.extract_changed_fields(v_old_data, v_new_data);
            v_primary_key_value := audit.extract_primary_key_value(v_table_schema, TG_TABLE_NAME, v_row_data);

            -- If nothing actually changed, don't audit
            IF v_changed_fields IS NULL OR jsonb_typeof(v_changed_fields) = 'null' OR
               jsonb_typeof(v_changed_fields) = 'object' AND jsonb_object_keys(v_changed_fields) IS NULL THEN
                RETURN NULL;
            END IF;

        WHEN 'DELETE' THEN
            v_old_data := audit.filter_columns(v_table_schema, TG_TABLE_NAME, to_jsonb(OLD));
            v_primary_key_value := audit.extract_primary_key_value(v_table_schema, TG_TABLE_NAME, v_old_data);

        WHEN 'TRUNCATE' THEN
            -- For truncate, we don't have row data
            v_row_data := NULL;
            v_primary_key_value := NULL;

        ELSE
            RAISE EXCEPTION 'Unhandled audit event: %', TG_OP;
    END CASE;

    -- Calculate hash for tamper detection
    v_hash_value := audit.calculate_hash(
        TG_TABLE_NAME,
        TG_OP,
        CURRENT_TIMESTAMP,
        CURRENT_USER,
        txid_current(),
        v_row_data,
        v_old_data,
        v_new_data
    );

    -- Insert audit record
    INSERT INTO audit.audit_log (
        table_schema,
        table_name,
        operation,
        user_id,
        query_id,
        primary_key_column,
        primary_key_value,
        row_data,
        changed_fields,
        old_data,
        new_data,
        hash_value
    ) VALUES (
        v_table_schema,
        TG_TABLE_NAME,
        TG_OP,
        v_user_id,
        v_query_id,
        v_primary_key_column,
        v_primary_key_value,
        CASE WHEN TG_OP = 'TRUNCATE' THEN NULL ELSE v_row_data END,
        v_changed_fields,
        v_old_data,
        v_new_data,
        v_hash_value
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.process_audit IS 'Main trigger function for comprehensive audit logging';

-- Step 5: Create Audit Management Functions

-- Function to enable auditing for a table
CREATE OR REPLACE FUNCTION audit.enable_table_audit(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_audit_insert BOOLEAN DEFAULT TRUE,
    p_audit_update BOOLEAN DEFAULT TRUE,
    p_audit_delete BOOLEAN DEFAULT TRUE,
    p_audit_truncate BOOLEAN DEFAULT TRUE,
    p_excluded_columns TEXT[] DEFAULT NULL,
    p_included_columns TEXT[] DEFAULT NULL,
    p_is_pii BOOLEAN DEFAULT FALSE
) RETURNS VOID AS $$
DECLARE
    v_trigger_exists BOOLEAN;
BEGIN
    -- Check if table exists
    PERFORM 1
    FROM information_schema.tables
    WHERE table_schema = p_table_schema
    AND table_name = p_table_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Table %.% does not exist', p_table_schema, p_table_name;
    END IF;

    -- Check if trigger already exists
    SELECT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = p_table_schema
        AND c.relname = p_table_name
        AND t.tgname = 'audit_trigger'
    ) INTO v_trigger_exists;

    -- Create or replace audit policy
    INSERT INTO audit.audit_policies (
        table_schema,
        table_name,
        audit_insert,
        audit_update,
        audit_delete,
        audit_truncate,
        excluded_columns,
        included_columns,
        is_pii
    ) VALUES (
        p_table_schema,
        p_table_name,
        p_audit_insert,
        p_audit_update,
        p_audit_delete,
        p_audit_truncate,
        p_excluded_columns,
        p_included_columns,
        p_is_pii
    )
    ON CONFLICT (table_schema, table_name) DO UPDATE SET
        audit_insert = p_audit_insert,
        audit_update = p_audit_update,
        audit_delete = p_audit_delete,
        audit_truncate = p_audit_truncate,
        excluded_columns = p_excluded_columns,
        included_columns = p_included_columns,
        is_pii = p_is_pii,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = CURRENT_USER,
        is_active = TRUE;

    -- Create trigger if it doesn't exist
    IF NOT v_trigger_exists THEN
        EXECUTE format(
            'CREATE TRIGGER audit_trigger
             AFTER INSERT OR UPDATE OR DELETE ON %I.%I
             FOR EACH ROW EXECUTE FUNCTION audit.process_audit()',
            p_table_schema, p_table_name
        );

        -- Add truncate trigger if supported
        BEGIN
            EXECUTE format(
                'CREATE TRIGGER audit_truncate_trigger
                 AFTER TRUNCATE ON %I.%I
                 FOR EACH STATEMENT EXECUTE FUNCTION audit.process_audit()',
                p_table_schema, p_table_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not create TRUNCATE trigger for %.%: %',
                p_table_schema, p_table_name, SQLERRM;
        END;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.enable_table_audit IS 'Enables auditing for a specific table with customizable options';

-- Function to disable auditing for a table
CREATE OR REPLACE FUNCTION audit.disable_table_audit(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_drop_triggers BOOLEAN DEFAULT FALSE
) RETURNS VOID AS $$
BEGIN
    -- Update audit policy to inactive
    UPDATE audit.audit_policies
    SET is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = CURRENT_USER
    WHERE table_schema = p_table_schema
    AND table_name = p_table_name;

    -- Optionally drop triggers
    IF p_drop_triggers THEN
        BEGIN
            EXECUTE format(
                'DROP TRIGGER IF EXISTS audit_trigger ON %I.%I',
                p_table_schema, p_table_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop audit trigger for %.%: %',
                p_table_schema, p_table_name, SQLERRM;
        END;

        BEGIN
            EXECUTE format(
                'DROP TRIGGER IF EXISTS audit_truncate_trigger ON %I.%I',
                p_table_schema, p_table_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop truncate audit trigger for %.%: %',
                p_table_schema, p_table_name, SQLERRM;
        END;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.disable_table_audit IS 'Disables auditing for a specific table';

-- Function to enable auditing for all tables in a schema
CREATE OR REPLACE FUNCTION audit.enable_schema_audit(
    p_schema TEXT,
    p_excluded_tables TEXT[] DEFAULT NULL,
    p_excluded_columns TEXT[] DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_table RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR v_table IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = p_schema
        AND table_type = 'BASE TABLE'
        AND table_name != ALL(COALESCE(p_excluded_tables, ARRAY[]::TEXT[]))
    LOOP
        BEGIN
            PERFORM audit.enable_table_audit(
                p_schema,
                v_table.table_name,
                TRUE, TRUE, TRUE, TRUE,
                p_excluded_columns
            );
            v_count := v_count + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not enable auditing for %.%: %',
                p_schema, v_table.table_name, SQLERRM;
        END;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.enable_schema_audit IS 'Enables auditing for all tables in a schema';

-- Function to purge audit logs based on retention policy
CREATE OR REPLACE FUNCTION audit.purge_audit_logs(
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS TABLE(table_schema TEXT, table_name TEXT, records_purged BIGINT) AS $$
DECLARE
    v_policy RECORD;
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
    v_records_purged BIGINT;
    v_result RECORD;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_purge_results (
        table_schema TEXT,
        table_name TEXT,
        records_purged BIGINT
    ) ON COMMIT DROP;

    -- Process each table's retention policy
    FOR v_policy IN
        SELECT * FROM audit.audit_policies
        WHERE is_active = TRUE
    LOOP
        v_cutoff_date := CURRENT_TIMESTAMP - v_policy.retention_period;

        IF p_dry_run THEN
            EXECUTE format(
                'SELECT COUNT(*) FROM audit.audit_log
                 WHERE table_schema = %L
                 AND table_name = %L
                 AND timestamp < %L',
                v_policy.table_schema, v_policy.table_name, v_cutoff_date
            ) INTO v_records_purged;
        ELSE
            EXECUTE format(
                'DELETE FROM audit.audit_log
                 WHERE table_schema = %L
                 AND table_name = %L
                 AND timestamp < %L',
                v_policy.table_schema, v_policy.table_name, v_cutoff_date
            );
            GET DIAGNOSTICS v_records_purged = ROW_COUNT;
        END IF;

        IF v_records_purged > 0 THEN
            INSERT INTO temp_purge_results VALUES (
                v_policy.table_schema, v_policy.table_name, v_records_purged
            );
        END IF;
    END LOOP;

    -- Return results
    FOR v_result IN SELECT * FROM temp_purge_results
    LOOP
        table_schema := v_result.table_schema;
        table_name := v_result.table_name;
        records_purged := v_result.records_purged;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.purge_audit_logs IS 'Purges audit logs based on retention policies';

-- Function to verify all audit log hashes
CREATE OR REPLACE FUNCTION audit.verify_all_hashes(
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_limit INTEGER DEFAULT 1000
) RETURNS TABLE(audit_id BIGINT, is_valid BOOLEAN, details TEXT) AS $$
DECLARE
    v_record RECORD;
    v_calculated_hash TEXT;
    v_is_valid BOOLEAN;
    v_details TEXT;
BEGIN
    FOR v_record IN
        SELECT *
        FROM audit.audit_log
        WHERE (p_start_date IS NULL OR timestamp >= p_start_date)
        AND (p_end_date IS NULL OR timestamp <= p_end_date)
        ORDER BY audit_id
        LIMIT p_limit
    LOOP
        -- Calculate hash based on stored values
        v_calculated_hash := audit.calculate_hash(
            v_record.table_name,
            v_record.operation,
            v_record.timestamp,
            v_record.user_name,
            v_record.transaction_id,
            v_record.row_data,
            v_record.old_data,
            v_record.new_data
        );

        -- Compare calculated hash with stored hash
        v_is_valid := (v_calculated_hash = v_record.hash_value);

        IF v_is_valid THEN
            v_details := 'Hash verified successfully';
        ELSE
            v_details := 'Hash verification failed: ' || v_calculated_hash || ' != ' || v_record.hash_value;
        END IF;

        -- Log verification attempt
        INSERT INTO audit.hash_verification (
            audit_id,
            is_valid,
            verification_method,
            details
        ) VALUES (
            v_record.audit_id,
            v_is_valid,
            'batch',
            v_details
        );

        -- Return result
        audit_id := v_record.audit_id;
        is_valid := v_is_valid;
        details := v_details;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.verify_all_hashes IS 'Verifies cryptographic hashes for multiple audit records';

-- Step 6: Create Compliance Reporting Views

-- View for PII data access
CREATE OR REPLACE VIEW audit.v_pii_data_access AS
SELECT
    al.audit_id,
    al.table_schema,
    al.table_name,
    al.operation,
    al.timestamp,
    al.user_name,
    al.client_addr,
    al.application_name,
    al.primary_key_value,
    al.changed_fields
FROM audit.audit_log al
JOIN audit.audit_policies ap ON al.table_schema = ap.table_schema AND al.table_name = ap.table_name
WHERE ap.is_pii = TRUE;

COMMENT ON VIEW audit.v_pii_data_access IS 'Shows all access to tables containing personally identifiable information';

-- View for data modification summary
CREATE OR REPLACE VIEW audit.v_data_modification_summary AS
SELECT
    table_schema,
    table_name,
    operation,
    date_trunc('day', timestamp) AS day,
    count(*) AS operation_count,
    count(DISTINCT user_id) AS unique_users,
    count(DISTINCT client_addr) AS unique_ip_addresses
FROM audit.audit_log
GROUP BY table_schema, table_name, operation, date_trunc('day', timestamp);

COMMENT ON VIEW audit.v_data_modification_summary IS 'Summarizes data modifications by table, operation, and day';

-- View for user activity
CREATE OR REPLACE VIEW audit.v_user_activity AS
SELECT
    u.user_id,
    u.username,
    al.operation,
    al.table_schema,
    al.table_name,
    count(*) AS operation_count,
    min(al.timestamp) AS first_operation,
    max(al.timestamp) AS last_operation,
    count(DISTINCT al.client_addr) AS unique_ip_addresses
FROM audit.audit_log al
JOIN Users u ON al.user_id = u.user_id
GROUP BY u.user_id, u.username, al.operation, al.table_schema, al.table_name;

COMMENT ON VIEW audit.v_user_activity IS 'Summarizes user activity across tables and operations';

-- View for suspicious activity detection
CREATE OR REPLACE VIEW audit.v_suspicious_activity AS
SELECT
    al.audit_id,
    al.timestamp,
    al.user_name,
    al.client_addr,
    al.table_schema,
    al.table_name,
    al.operation,
    al.primary_key_value,
    'Multiple operations in short time' AS reason
FROM audit.audit_log al
WHERE EXISTS (
    SELECT 1
    FROM audit.audit_log al2
    WHERE al2.user_id = al.user_id
    AND al2.timestamp BETWEEN al.timestamp - INTERVAL '1 minute' AND al.timestamp
    GROUP BY al2.user_id
    HAVING COUNT(*) > 100
)

UNION ALL

SELECT
    al.audit_id,
    al.timestamp,
    al.user_name,
    al.client_addr,
    al.table_schema,
    al.table_name,
    al.operation,
    al.primary_key_value,
    'Operation outside normal hours' AS reason
FROM audit.audit_log al
WHERE EXTRACT(HOUR FROM al.timestamp) BETWEEN 0 AND 5
AND al.operation IN ('DELETE', 'TRUNCATE')

UNION ALL

SELECT
    al.audit_id,
    al.timestamp,
    al.user_name,
    al.client_addr,
    al.table_schema,
    al.table_name,
    al.operation,
    al.primary_key_value,
    'Unusual client address' AS reason
FROM audit.audit_log al
WHERE al.client_addr NOT IN (
    SELECT DISTINCT client_addr
    FROM audit.audit_log
    WHERE timestamp < al.timestamp - INTERVAL '30 days'
);

COMMENT ON VIEW audit.v_suspicious_activity IS 'Identifies potentially suspicious database activity';

-- View for GDPR compliance reporting
CREATE OR REPLACE VIEW audit.v_gdpr_compliance AS
SELECT
    al.audit_id,
    al.timestamp,
    al.user_name,
    al.table_schema,
    al.table_name,
    al.operation,
    al.primary_key_value,
    CASE
        WHEN al.operation = 'INSERT' THEN 'Data Collection'
        WHEN al.operation = 'UPDATE' THEN 'Data Modification'
        WHEN al.operation = 'DELETE' THEN 'Data Deletion'
        WHEN al.operation = 'TRUNCATE' THEN 'Bulk Data Deletion'
    END AS gdpr_operation_type,
    al.old_data,
    al.new_data,
    ap.compliance_category
FROM audit.audit_log al
JOIN audit.audit_policies ap ON al.table_schema = ap.table_schema AND al.table_name = ap.table_name
WHERE ap.is_pii = TRUE;

COMMENT ON VIEW audit.v_gdpr_compliance IS 'Provides GDPR-focused view of personal data operations';

-- View for data retention compliance
CREATE OR REPLACE VIEW audit.v_data_retention_compliance AS
SELECT
    ap.table_schema,
    ap.table_name,
    ap.retention_period,
    min(al.timestamp) AS oldest_record,
    max(al.timestamp) AS newest_record,
    CURRENT_TIMESTAMP - min(al.timestamp) AS oldest_record_age,
    CASE
        WHEN CURRENT_TIMESTAMP - min(al.timestamp) > ap.retention_period THEN 'Non-compliant'
        ELSE 'Compliant'
    END AS compliance_status,
    count(*) AS total_records,
    count(*) FILTER (WHERE CURRENT_TIMESTAMP - al.timestamp > ap.retention_period) AS records_exceeding_retention
FROM audit.audit_policies ap
JOIN audit.audit_log al ON ap.table_schema = al.table_schema AND ap.table_name = al.table_name
GROUP BY ap.table_schema, ap.table_name, ap.retention_period;

COMMENT ON VIEW audit.v_data_retention_compliance IS 'Reports on compliance with data retention policies';

-- View for tamper detection
CREATE OR REPLACE VIEW audit.v_tamper_detection AS
SELECT
    hv.verification_id,
    hv.audit_id,
    al.table_schema,
    al.table_name,
    al.operation,
    al.timestamp AS audit_timestamp,
    hv.verified_at,
    hv.verified_by,
    hv.is_valid,
    hv.details
FROM audit.hash_verification hv
JOIN audit.audit_log al ON hv.audit_id = al.audit_id
WHERE hv.is_valid = FALSE;

COMMENT ON VIEW audit.v_tamper_detection IS 'Shows detected tampering attempts in the audit log';

-- View for audit coverage
CREATE OR REPLACE VIEW audit.v_audit_coverage AS
WITH all_tables AS (
    SELECT
        table_schema,
        table_name
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
    AND table_schema NOT IN ('pg_catalog', 'information_schema')
),
audited_tables AS (
    SELECT
        table_schema,
        table_name,
        audit_insert,
        audit_update,
        audit_delete,
        audit_truncate
    FROM audit.audit_policies
    WHERE is_active = TRUE
)
SELECT
    at.table_schema,
    at.table_name,
    CASE WHEN adt.table_name IS NULL THEN FALSE ELSE TRUE END AS is_audited,
    COALESCE(adt.audit_insert, FALSE) AS audit_insert,
    COALESCE(adt.audit_update, FALSE) AS audit_update,
    COALESCE(adt.audit_delete, FALSE) AS audit_delete,
    COALESCE(adt.audit_truncate, FALSE) AS audit_truncate,
    CASE
        WHEN adt.table_name IS NULL THEN 'Not Audited'
        WHEN adt.audit_insert AND adt.audit_update AND adt.audit_delete AND adt.audit_truncate THEN 'Full Coverage'
        ELSE 'Partial Coverage'
    END AS coverage_status
FROM all_tables at
LEFT JOIN audited_tables adt ON at.table_schema = adt.table_schema AND at.table_name = adt.table_name;

COMMENT ON VIEW audit.v_audit_coverage IS 'Shows audit coverage across all database tables';

-- View for audit policy management
CREATE OR REPLACE VIEW audit.v_audit_policies AS
SELECT
    ap.policy_id,
    ap.table_schema,
    ap.table_name,
    ap.audit_insert,
    ap.audit_update,
    ap.audit_delete,
    ap.audit_truncate,
    ap.excluded_columns,
    ap.included_columns,
    ap.retention_period,
    ap.compliance_category,
    ap.is_pii,
    ap.is_active,
    ap.created_at,
    ap.updated_at,
    ap.created_by,
    ap.updated_by,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = ap.table_schema
            AND c.relname = ap.table_name
            AND t.tgname = 'audit_trigger'
        ) THEN TRUE
        ELSE FALSE
    END AS trigger_exists,
    (SELECT COUNT(*) FROM audit.audit_log al WHERE al.table_schema = ap.table_schema AND al.table_name = ap.table_name) AS audit_record_count
FROM audit.audit_policies ap;

COMMENT ON VIEW audit.v_audit_policies IS 'Shows audit policy configuration and status';

-- Step 7: Create Audit Access Triggers

-- Create trigger to log access to audit log
CREATE TRIGGER log_audit_access
AFTER SELECT OR INSERT OR UPDATE OR DELETE ON audit.audit_log
FOR EACH STATEMENT EXECUTE FUNCTION audit.log_audit_access();

-- Create trigger to log access to audit policies
CREATE TRIGGER log_audit_policies_access
AFTER SELECT OR INSERT OR UPDATE OR DELETE ON audit.audit_policies
FOR EACH STATEMENT EXECUTE FUNCTION audit.log_audit_access();

-- Step 8: Create Scheduled Jobs for Audit Maintenance

-- Function to perform regular audit maintenance
CREATE OR REPLACE FUNCTION audit.perform_maintenance() RETURNS VOID AS $$
DECLARE
    v_config_value TEXT;
    v_verify_count INTEGER := 0;
BEGIN
    -- Check if tamper detection is enabled
    SELECT config_value INTO v_config_value
    FROM audit.configuration
    WHERE config_key = 'enable_tamper_detection';

    -- Verify a sample of recent audit logs
    IF v_config_value = 'true' THEN
        SELECT COUNT(*) INTO v_verify_count
        FROM audit.verify_all_hashes(
            CURRENT_TIMESTAMP - INTERVAL '1 day',
            NULL,
            100
        );
    END IF;

    -- Compress old audit logs if enabled
    SELECT config_value INTO v_config_value
    FROM audit.configuration
    WHERE config_key = 'compress_old_logs';

    IF v_config_value = 'true' THEN
        -- In a real implementation, this would compress old logs
        -- For PostgreSQL, this might involve table partitioning and compression
        NULL;
    END IF;

    -- Purge expired audit logs (dry run = false)
    PERFORM * FROM audit.purge_audit_logs(FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.perform_maintenance IS 'Performs regular maintenance on the audit framework';

-- Add scheduled job entry
INSERT INTO scheduled_jobs (
    job_name,
    job_type,
    cron_expression,
    next_run_at,
    parameters,
    is_active
) VALUES (
    'Audit Framework Maintenance',
    'function',
    '0 2 * * *',  -- Run at 2 AM daily
    CURRENT_TIMESTAMP + INTERVAL '1 day',
    '{"function": "audit.perform_maintenance"}',
    TRUE
);

-- Step 9: Apply Audit Framework to All Tables

-- Function to apply audit framework to all tables
CREATE OR REPLACE FUNCTION audit.apply_to_all_tables() RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
BEGIN
    -- Apply to public schema tables
    v_count := v_count + audit.enable_schema_audit(
        'public',
        ARRAY['schema_migrations']  -- Exclude some tables
    );

    -- Apply to enterprise schema tables
    v_count := v_count + audit.enable_schema_audit(
        'enterprise',
        NULL  -- No exclusions
    );

    -- Apply to audit schema tables (for meta-auditing)
    v_count := v_count + audit.enable_schema_audit(
        'audit',
        ARRAY['audit_log', 'audit_access_log', 'hash_verification']  -- Avoid recursive auditing
    );

    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.apply_to_all_tables IS 'Applies the audit framework to all tables in the database';

-- Step 10: Create Audit Dashboard Views

-- Audit activity overview
CREATE OR REPLACE VIEW audit.v_activity_dashboard AS
SELECT
    date_trunc('hour', timestamp) AS hour,
    count(*) AS total_operations,
    count(*) FILTER (WHERE operation = 'INSERT') AS inserts,
    count(*) FILTER (WHERE operation = 'UPDATE') AS updates,
    count(*) FILTER (WHERE operation = 'DELETE') AS deletes,
    count(*) FILTER (WHERE operation = 'TRUNCATE') AS truncates,
    count(DISTINCT user_id) AS unique_users,
    count(DISTINCT table_schema || '.' || table_name) AS tables_modified
FROM audit.audit_log
WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY date_trunc('hour', timestamp)
ORDER BY hour DESC;

COMMENT ON VIEW audit.v_activity_dashboard IS 'Provides an hourly overview of database activity';

-- Top users by activity
CREATE OR REPLACE VIEW audit.v_top_users AS
SELECT
    u.username,
    count(*) AS operation_count,
    count(*) FILTER (WHERE al.operation = 'INSERT') AS inserts,
    count(*) FILTER (WHERE al.operation = 'UPDATE') AS updates,
    count(*) FILTER (WHERE al.operation = 'DELETE') AS deletes,
    count(*) FILTER (WHERE al.operation = 'TRUNCATE') AS truncates,
    count(DISTINCT al.table_schema || '.' || al.table_name) AS tables_accessed,
    min(al.timestamp) AS first_operation,
    max(al.timestamp) AS last_operation
FROM audit.audit_log al
JOIN Users u ON al.user_id = u.user_id
WHERE al.timestamp > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY u.username
ORDER BY operation_count DESC;

COMMENT ON VIEW audit.v_top_users IS 'Shows the most active users in the database';

-- Top tables by activity
CREATE OR REPLACE VIEW audit.v_top_tables AS
SELECT
    table_schema,
    table_name,
    count(*) AS operation_count,
    count(*) FILTER (WHERE operation = 'INSERT') AS inserts,
    count(*) FILTER (WHERE operation = 'UPDATE') AS updates,
    count(*) FILTER (WHERE operation = 'DELETE') AS deletes,
    count(*) FILTER (WHERE operation = 'TRUNCATE') AS truncates,
    count(DISTINCT user_id) AS unique_users,
    min(timestamp) AS first_operation,
    max(timestamp) AS last_operation
FROM audit.audit_log
WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY table_schema, table_name
ORDER BY operation_count DESC;

COMMENT ON VIEW audit.v_top_tables IS 'Shows the most frequently modified tables';

-- Audit health status
CREATE OR REPLACE VIEW audit.v_audit_health AS
SELECT
    (SELECT COUNT(*) FROM audit.hash_verification WHERE is_valid = FALSE) AS failed_verifications,
    (SELECT COUNT(*) FROM audit.v_suspicious_activity) AS suspicious_activities,
    (SELECT COUNT(*) FROM audit.v_data_retention_compliance WHERE compliance_status = 'Non-compliant') AS retention_violations,
    (SELECT COUNT(*) FROM audit.v_audit_coverage WHERE coverage_status = 'Not Audited') AS unaudited_tables,
    (SELECT MAX(timestamp) FROM audit.audit_log) AS last_audit_record,
    (SELECT MAX(verified_at) FROM audit.hash_verification) AS last_verification,
    (SELECT COUNT(*) FROM audit.audit_log) AS total_audit_records,
    pg_size_pretty(pg_total_relation_size('audit.audit_log')) AS audit_log_size;

COMMENT ON VIEW audit.v_audit_health IS 'Provides an overview of audit framework health';

-- Step 11: Create Audit API Functions

-- Function to search audit logs
CREATE OR REPLACE FUNCTION audit.search_logs(
    p_table_schema TEXT DEFAULT NULL,
    p_table_name TEXT DEFAULT NULL,
    p_operation TEXT DEFAULT NULL,
    p_user_id INTEGER DEFAULT NULL,
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_primary_key_value TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE(
    audit_id BIGINT,
    table_schema TEXT,
    table_name TEXT,
    operation TEXT,
    timestamp TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    primary_key_value TEXT,
    changed_fields JSONB,
    old_data JSONB,
    new_data JSONB
) AS $$
BEGIN
    -- Log this search for security
    INSERT INTO audit.audit_access_log (
        user_id,
        action,
        query
    ) VALUES (
        (SELECT user_id FROM Users WHERE username = CURRENT_USER LIMIT 1),
        'SEARCH',
        format(
            'Search parameters: schema=%L, table=%L, operation=%L, user=%L, dates=%L to %L, pk=%L',
            p_table_schema, p_table_name, p_operation, p_user_id, p_start_date, p_end_date, p_primary_key_value
        )
    );

    -- Return search results
    RETURN QUERY
    SELECT
        al.audit_id,
        al.table_schema,
        al.table_name,
        al.operation,
        al.timestamp,
        al.user_name,
        al.primary_key_value,
        al.changed_fields,
        al.old_data,
        al.new_data
    FROM audit.audit_log al
    WHERE (p_table_schema IS NULL OR al.table_schema = p_table_schema)
    AND (p_table_name IS NULL OR al.table_name = p_table_name)
    AND (p_operation IS NULL OR al.operation = p_operation)
    AND (p_user_id IS NULL OR al.user_id = p_user_id)
    AND (p_start_date IS NULL OR al.timestamp >= p_start_date)
    AND (p_end_date IS NULL OR al.timestamp <= p_end_date)
    AND (p_primary_key_value IS NULL OR al.primary_key_value = p_primary_key_value)
    ORDER BY al.timestamp DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.search_logs IS 'Searches audit logs with various filters';

-- Function to get audit history for a specific record
CREATE OR REPLACE FUNCTION audit.get_record_history(
    p_table_schema TEXT,
    p_table_name TEXT,
    p_primary_key_value TEXT
) RETURNS TABLE(
    audit_id BIGINT,
    operation TEXT,
    timestamp TIMESTAMP WITH TIME ZONE,
    user_name TEXT,
    changed_fields JSONB,
    old_data JSONB,
    new_data JSONB
) AS $$
BEGIN
    -- Log this access for security
    INSERT INTO audit.audit_access_log (
        user_id,
        action,
        query
    ) VALUES (
        (SELECT user_id FROM Users WHERE username = CURRENT_USER LIMIT 1),
        'RECORD_HISTORY',
        format('Record history: schema=%L, table=%L, pk=%L', p_table_schema, p_table_name, p_primary_key_value)
    );

    -- Return record history
    RETURN QUERY
    SELECT
        al.audit_id,
        al.operation,
        al.timestamp,
        al.user_name,
        al.changed_fields,
        al.old_data,
        al.new_data
    FROM audit.audit_log al
    WHERE al.table_schema = p_table_schema
    AND al.table_name = p_table_name
    AND al.primary_key_value = p_primary_key_value
    ORDER BY al.timestamp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.get_record_history IS 'Gets the complete audit history for a specific record';

-- Function to generate compliance report
CREATE OR REPLACE FUNCTION audit.generate_compliance_report(
    p_report_type TEXT,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Log this report generation for security
    INSERT INTO audit.audit_access_log (
        user_id,
        action,
        query
    ) VALUES (
        (SELECT user_id FROM Users WHERE username = CURRENT_USER LIMIT 1),
        'COMPLIANCE_REPORT',
        format('Compliance report: type=%L, dates=%L to %L', p_report_type, p_start_date, p_end_date)
    );

    -- Generate different reports based on type
    CASE p_report_type
        WHEN 'gdpr' THEN
            SELECT jsonb_build_object(
                'report_type', 'GDPR Compliance',
                'generated_at', CURRENT_TIMESTAMP,
                'period', jsonb_build_object('start', p_start_date, 'end', p_end_date),
                'summary', jsonb_build_object(
                    'data_collection', (SELECT COUNT(*) FROM audit.v_gdpr_compliance
                                       WHERE gdpr_operation_type = 'Data Collection'
                                       AND timestamp BETWEEN p_start_date AND p_end_date),
                    'data_modification', (SELECT COUNT(*) FROM audit.v_gdpr_compliance
                                         WHERE gdpr_operation_type = 'Data Modification'
                                         AND timestamp BETWEEN p_start_date AND p_end_date),
                    'data_deletion', (SELECT COUNT(*) FROM audit.v_gdpr_compliance
                                     WHERE gdpr_operation_type IN ('Data Deletion', 'Bulk Data Deletion')
                                     AND timestamp BETWEEN p_start_date AND p_end_date)
                ),
                'pii_tables', (SELECT jsonb_agg(jsonb_build_object(
                                'schema', table_schema,
                                'table', table_name,
                                'operations', COUNT(*)
                              ))
                              FROM audit.v_gdpr_compliance
                              WHERE timestamp BETWEEN p_start_date AND p_end_date
                              GROUP BY table_schema, table_name),
                'user_access', (SELECT jsonb_agg(jsonb_build_object(
                                'user', user_name,
                                'operations', COUNT(*)
                              ))
                              FROM audit.v_gdpr_compliance
                              WHERE timestamp BETWEEN p_start_date AND p_end_date
                              GROUP BY user_name)
            ) INTO v_result;

        WHEN 'retention' THEN
            SELECT jsonb_build_object(
                'report_type', 'Data Retention Compliance',
                'generated_at', CURRENT_TIMESTAMP,
                'summary', jsonb_build_object(
                    'compliant_tables', (SELECT COUNT(*) FROM audit.v_data_retention_compliance
                                        WHERE compliance_status = 'Compliant'),
                    'non_compliant_tables', (SELECT COUNT(*) FROM audit.v_data_retention_compliance
                                           WHERE compliance_status = 'Non-compliant'),
                    'total_records_exceeding_retention', (SELECT SUM(records_exceeding_retention)
                                                        FROM audit.v_data_retention_compliance)
                ),
                'non_compliant_details', (SELECT jsonb_agg(jsonb_build_object(
                                         'schema', table_schema,
                                         'table', table_name,
                                         'retention_period', retention_period,
                                         'oldest_record', oldest_record,
                                         'records_exceeding', records_exceeding_retention
                                       ))
                                       FROM audit.v_data_retention_compliance
                                       WHERE compliance_status = 'Non-compliant')
            ) INTO v_result;

        WHEN 'security' THEN
            SELECT jsonb_build_object(
                'report_type', 'Security Audit',
                'generated_at', CURRENT_TIMESTAMP,
                'period', jsonb_build_object('start', p_start_date, 'end', p_end_date),
                'summary', jsonb_build_object(
                    'suspicious_activities', (SELECT COUNT(*) FROM audit.v_suspicious_activity
                                            WHERE timestamp BETWEEN p_start_date AND p_end_date),
                    'tamper_attempts', (SELECT COUNT(*) FROM audit.v_tamper_detection
                                      WHERE audit_timestamp BETWEEN p_start_date AND p_end_date),
                    'audit_access_events', (SELECT COUNT(*) FROM audit.audit_access_log
                                          WHERE timestamp BETWEEN p_start_date AND p_end_date)
                ),
                'suspicious_details', (SELECT jsonb_agg(jsonb_build_object(
                                      'timestamp', timestamp,
                                      'user', user_name,
                                      'ip_address', client_addr,
                                      'operation', operation,
                                      'table', table_schema || '.' || table_name,
                                      'reason', reason
                                    ))
                                    FROM audit.v_suspicious_activity
                                    WHERE timestamp BETWEEN p_start_date AND p_end_date
                                    LIMIT 100)
            ) INTO v_result;

        ELSE
            RAISE EXCEPTION 'Unknown report type: %', p_report_type;
    END CASE;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.generate_compliance_report IS 'Generates compliance reports for different regulatory frameworks';

-- Step 12: Create Audit Roles and Permissions

-- Create audit admin role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'audit_admin') THEN
        CREATE ROLE audit_admin;
    END IF;

    -- Grant permissions
    GRANT USAGE ON SCHEMA audit TO audit_admin;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO audit_admin;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO audit_admin;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA audit TO audit_admin;

    -- Allow audit admins to enable/disable auditing
    GRANT EXECUTE ON FUNCTION audit.enable_table_audit TO audit_admin;
    GRANT EXECUTE ON FUNCTION audit.disable_table_audit TO audit_admin;
    GRANT EXECUTE ON FUNCTION audit.enable_schema_audit TO audit_admin;
    GRANT EXECUTE ON FUNCTION audit.apply_to_all_tables TO audit_admin;
END$$;

-- Create audit viewer role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'audit_viewer') THEN
        CREATE ROLE audit_viewer;
    END IF;

    -- Grant read-only permissions
    GRANT USAGE ON SCHEMA audit TO audit_viewer;
    GRANT SELECT ON ALL TABLES IN SCHEMA audit TO audit_viewer;

    -- Grant execute on search functions
    GRANT EXECUTE ON FUNCTION audit.search_logs TO audit_viewer;
    GRANT EXECUTE ON FUNCTION audit.get_record_history TO audit_viewer;
    GRANT EXECUTE ON FUNCTION audit.generate_compliance_report TO audit_viewer;
END$$;

-- Create compliance officer role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'compliance_officer') THEN
        CREATE ROLE compliance_officer;
    END IF;

    -- Grant permissions for compliance views and functions
    GRANT USAGE ON SCHEMA audit TO compliance_officer;
    GRANT SELECT ON audit.v_gdpr_compliance TO compliance_officer;
    GRANT SELECT ON audit.v_data_retention_compliance TO compliance_officer;
    GRANT SELECT ON audit.v_audit_coverage TO compliance_officer;
    GRANT SELECT ON audit.v_suspicious_activity TO compliance_officer;
    GRANT SELECT ON audit.v_tamper_detection TO compliance_officer;

    -- Grant execute on compliance functions
    GRANT EXECUTE ON FUNCTION audit.generate_compliance_report TO compliance_officer;
    GRANT EXECUTE ON FUNCTION audit.verify_all_hashes TO compliance_officer;
END$$;

-- Step 13: Initialize the Audit Framework

-- Function to initialize the audit framework
CREATE OR REPLACE FUNCTION audit.initialize_framework(
    p_apply_to_all_tables BOOLEAN DEFAULT FALSE
) RETURNS TEXT AS $$
DECLARE
    v_tables_count INTEGER := 0;
BEGIN
    -- Create extension for cryptographic functions if not exists
    CREATE EXTENSION IF NOT EXISTS pgcrypto;

    -- Create extension for UUID generation if not exists
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    -- Apply to all tables if requested
    IF p_apply_to_all_tables THEN
        v_tables_count := audit.apply_to_all_tables();
    END IF;

    -- Return initialization status
    RETURN format('Audit framework initialized successfully. Applied to %s tables.',
                 CASE WHEN p_apply_to_all_tables THEN v_tables_count::TEXT ELSE 'no' END);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit.initialize_framework IS 'Initializes the audit framework and optionally applies it to all tables';

-- Step 14: Create Documentation

COMMENT ON SCHEMA audit IS 'Comprehensive audit framework for PostgreSQL with tamper-proof logging, policy management, and compliance reporting';

-- Add comments to all objects
DO $$
BEGIN
    EXECUTE 'COMMENT ON TABLE audit.audit_log IS ''Main audit log table with cryptographic verification for tamper detection''';
    EXECUTE 'COMMENT ON TABLE audit.audit_policies IS ''Configuration table for audit policies by table''';
    EXECUTE 'COMMENT ON TABLE audit.audit_access_log IS ''Security log of all access to audit data''';
    EXECUTE 'COMMENT ON TABLE audit.hash_verification IS ''Records of hash verification attempts for tamper detection''';
    EXECUTE 'COMMENT ON TABLE audit.configuration IS ''Configuration settings for the audit framework''';

    EXECUTE 'COMMENT ON VIEW audit.v_pii_data_access IS ''Shows all access to tables containing personally identifiable information''';
    EXECUTE 'COMMENT ON VIEW audit.v_data_modification_summary IS ''Summarizes data modifications by table, operation, and day''';
    EXECUTE 'COMMENT ON VIEW audit.v_user_activity IS ''Summarizes user activity across tables and operations''';
    EXECUTE 'COMMENT ON VIEW audit.v_suspicious_activity IS ''Identifies potentially suspicious database activity''';
    EXECUTE 'COMMENT ON VIEW audit.v_gdpr_compliance IS ''Provides GDPR-focused view of personal data operations''';
    EXECUTE 'COMMENT ON VIEW audit.v_data_retention_compliance IS ''Reports on compliance with data retention policies''';
    EXECUTE 'COMMENT ON VIEW audit.v_tamper_detection IS ''Shows detected tampering attempts in the audit log''';
    EXECUTE 'COMMENT ON VIEW audit.v_audit_coverage IS ''Shows audit coverage across all database tables''';
    EXECUTE 'COMMENT ON VIEW audit.v_audit_policies IS ''Shows audit policy configuration and status''';
    EXECUTE 'COMMENT ON VIEW audit.v_activity_dashboard IS ''Provides an hourly overview of database activity''';
    EXECUTE 'COMMENT ON VIEW audit.v_top_users IS ''Shows the most active users in the database''';
    EXECUTE 'COMMENT ON VIEW audit.v_top_tables IS ''Shows the most frequently modified tables''';
    EXECUTE 'COMMENT ON VIEW audit.v_audit_health IS ''Provides an overview of audit framework health''';
END$$;

-- Final initialization
SELECT audit.initialize_framework(TRUE);


-----
-- PostgreSQL GDPR and Privacy Features Enhancement
-- This implementation provides:
-- 1. Complete data classification system for personal/sensitive data
-- 2. Automated data retention policies
-- 3. Consent management tracking
-- 4. Cross-border data transfer tracking
-- 5. Data processing purpose documentation

-- Step 1: Create Privacy Schema
CREATE SCHEMA IF NOT EXISTS privacy;
COMMENT ON SCHEMA privacy IS 'Schema for GDPR and privacy management features';

-- Step 2: Create Data Classification System

-- Data Classification Categories Table
CREATE TABLE privacy.data_classification_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    sensitivity_level INTEGER NOT NULL CHECK (sensitivity_level BETWEEN 0 AND 10),
    requires_consent BOOLEAN DEFAULT FALSE,
    requires_special_handling BOOLEAN DEFAULT FALSE,
    default_retention_period INTERVAL,
    legal_basis_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_data_classification_categories_sensitivity ON privacy.data_classification_categories (sensitivity_level);

COMMENT ON TABLE privacy.data_classification_categories IS 'Categories for classifying data based on privacy sensitivity';

-- Insert standard classification categories
INSERT INTO privacy.data_classification_categories
(category_name, description, sensitivity_level, requires_consent, requires_special_handling, default_retention_period, legal_basis_required)
VALUES
('Public', 'Non-sensitive data that can be freely disclosed', 0, FALSE, FALSE, '7 years', FALSE),
('Internal', 'Data for internal use only, not particularly sensitive', 2, FALSE, FALSE, '7 years', FALSE),
('Confidential', 'Business confidential data with restricted access', 5, FALSE, TRUE, '7 years', FALSE),
('Personal Data', 'Personal data as defined by GDPR Article 4', 7, TRUE, TRUE, '2 years', TRUE),
('Special Category', 'Special category data as defined by GDPR Article 9', 9, TRUE, TRUE, '2 years', TRUE),
('Financial', 'Financial and payment data requiring PCI compliance', 8, TRUE, TRUE, '7 years', TRUE),
('Health Data', 'Health-related data subject to special protections', 10, TRUE, TRUE, '10 years', TRUE),
('Children''s Data', 'Data relating to children requiring special protection', 10, TRUE, TRUE, '1 year', TRUE),
('Biometric', 'Biometric data used for identification', 10, TRUE, TRUE, '2 years', TRUE),
('Location', 'Precise geolocation data', 8, TRUE, TRUE, '1 year', TRUE);

-- Data Classification for Database Objects
CREATE TABLE privacy.data_classifications (
    classification_id SERIAL PRIMARY KEY,
    object_type VARCHAR(50) NOT NULL CHECK (object_type IN ('table', 'column', 'view', 'function')),
    object_schema VARCHAR(255) NOT NULL,
    object_name VARCHAR(255) NOT NULL,
    column_name VARCHAR(255),
    category_id INTEGER NOT NULL REFERENCES privacy.data_classification_categories(category_id),
    justification TEXT,
    data_owner VARCHAR(255),
    reviewer VARCHAR(255),
    review_date TIMESTAMP WITH TIME ZONE,
    expiry_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_object_classification UNIQUE (object_type, object_schema, object_name, column_name)
);

CREATE INDEX idx_data_classifications_object ON privacy.data_classifications (object_type, object_schema, object_name);
CREATE INDEX idx_data_classifications_category ON privacy.data_classifications (category_id);

COMMENT ON TABLE privacy.data_classifications IS 'Classification of database objects according to data privacy categories';

-- Data Classification Audit Log
CREATE TABLE privacy.classification_audit_log (
    audit_id SERIAL PRIMARY KEY,
    classification_id INTEGER NOT NULL REFERENCES privacy.data_classifications(classification_id),
    action VARCHAR(50) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'REVIEW')),
    changed_by VARCHAR(255) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    notes TEXT
);

CREATE INDEX idx_classification_audit_log_classification ON privacy.classification_audit_log (classification_id);
CREATE INDEX idx_classification_audit_log_action ON privacy.classification_audit_log (action);

COMMENT ON TABLE privacy.classification_audit_log IS 'Audit trail for changes to data classifications';

-- Function to automatically classify columns based on name patterns
CREATE OR REPLACE FUNCTION privacy.auto_classify_columns() RETURNS INTEGER AS $$
DECLARE
    v_column RECORD;
    v_category_id INTEGER;
    v_count INTEGER := 0;
BEGIN
    -- Process each column in the database
    FOR v_column IN
        SELECT
            c.table_schema AS object_schema,
            c.table_name AS object_name,
            c.column_name
        FROM
            information_schema.columns c
        WHERE
            c.table_schema NOT IN ('pg_catalog', 'information_schema', 'audit', 'privacy')
        AND NOT EXISTS (
            SELECT 1 FROM privacy.data_classifications dc
            WHERE dc.object_type = 'column'
            AND dc.object_schema = c.table_schema
            AND dc.object_name = c.table_name
            AND dc.column_name = c.column_name
        )
    LOOP
        -- Determine category based on column name patterns
        v_category_id := CASE
            -- Personal Data
            WHEN v_column.column_name ~* '(^|_)(email|mail)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Personal Data')
            WHEN v_column.column_name ~* '(^|_)(name|first_name|last_name|full_name)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Personal Data')
            WHEN v_column.column_name ~* '(^|_)(phone|telephone|mobile)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Personal Data')
            WHEN v_column.column_name ~* '(^|_)(address|street|city|state|zip|postal)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Personal Data')
            WHEN v_column.column_name ~* '(^|_)(dob|birth_date|birthdate|date_of_birth)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Personal Data')
            WHEN v_column.column_name ~* '(^|_)(ssn|social_security|national_id)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Special Category')

            -- Financial Data
            WHEN v_column.column_name ~* '(^|_)(credit_card|card_number|cvv|ccv)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Financial')
            WHEN v_column.column_name ~* '(^|_)(bank_account|account_number|routing)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Financial')

            -- Health Data
            WHEN v_column.column_name ~* '(^|_)(health|medical|diagnosis|treatment)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Health Data')

            -- Biometric Data
            WHEN v_column.column_name ~* '(^|_)(biometric|fingerprint|face_id|retina)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Biometric')

            -- Location Data
            WHEN v_column.column_name ~* '(^|_)(lat|latitude|long|longitude|geo|location)($|_)' THEN
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Location')

            -- Default to Internal
            ELSE
                (SELECT category_id FROM privacy.data_classification_categories WHERE category_name = 'Internal')
        END;

        -- Insert classification
        INSERT INTO privacy.data_classifications (
            object_type,
            object_schema,
            object_name,
            column_name,
            category_id,
            justification
        ) VALUES (
            'column',
            v_column.object_schema,
            v_column.object_name,
            v_column.column_name,
            v_category_id,
            'Auto-classified based on column name pattern'
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION privacy.auto_classify_columns IS 'Automatically classifies database columns based on name patterns';

-- Function to get classification for a specific column
CREATE OR REPLACE FUNCTION privacy.get_column_classification(
    p_schema TEXT,
    p_table TEXT,
    p_column TEXT
) RETURNS TABLE (
    category_name TEXT,
    sensitivity_level INTEGER,
    requires_consent BOOLEAN,
    requires_special_handling BOOLEAN,
    default_retention_period INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dcc.category_name,
        dcc.sensitivity_level,
        dcc.requires_consent,
        dcc.requires_special_handling,
        dcc.default_retention_period
    FROM
        privacy.data_classifications dc
    JOIN
        privacy.data_classification_categories dcc ON dc.category_id = dcc.category_id
    WHERE
        dc.object_type = 'column'
        AND dc.object_schema = p_schema
        AND dc.object_name = p_table
        AND dc.column_name = p_column;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.get_column_classification IS 'Gets the privacy classification for a specific column';

-- Trigger function to log classification changes
CREATE OR REPLACE FUNCTION privacy.log_classification_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO privacy.classification_audit_log (
            classification_id,
            action,
            changed_by,
            new_values
        ) VALUES (
            NEW.classification_id,
            TG_OP,
            CURRENT_USER,
            to_jsonb(NEW)
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO privacy.classification_audit_log (
            classification_id,
            action,
            changed_by,
            old_values,
            new_values
        ) VALUES (
            NEW.classification_id,
            TG_OP,
            CURRENT_USER,
            to_jsonb(OLD),
            to_jsonb(NEW)
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO privacy.classification_audit_log (
            classification_id,
            action,
            changed_by,
            old_values
        ) VALUES (
            OLD.classification_id,
            TG_OP,
            CURRENT_USER,
            to_jsonb(OLD)
        );
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.log_classification_changes IS 'Trigger function to log changes to data classifications';

-- Create trigger on data_classifications table
CREATE TRIGGER trg_log_classification_changes
AFTER INSERT OR UPDATE OR DELETE ON privacy.data_classifications
FOR EACH ROW EXECUTE FUNCTION privacy.log_classification_changes();

-- Step 3: Create Automated Data Retention System

-- Data Retention Policies Table
CREATE TABLE privacy.retention_policies (
    policy_id SERIAL PRIMARY KEY,
    policy_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    retention_period INTERVAL NOT NULL,
    legal_basis TEXT,
    applies_to_classifications INTEGER[] REFERENCES privacy.data_classification_categories(category_id),
    archive_before_delete BOOLEAN DEFAULT FALSE,
    archive_location TEXT,
    requires_approval BOOLEAN DEFAULT FALSE,
    approver_role VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_retention_policies_active ON privacy.retention_policies (is_active);

COMMENT ON TABLE privacy.retention_policies IS 'Policies defining data retention periods and handling';

-- Insert default retention policies
INSERT INTO privacy.retention_policies
(policy_name, description, retention_period, legal_basis, archive_before_delete, requires_approval, is_active)
VALUES
('Standard Personal Data', 'Standard retention for personal data', '2 years', 'GDPR Article 5(1)(e) - Storage Limitation', TRUE, FALSE, TRUE),
('Extended Business Records', 'Extended retention for business records', '7 years', 'Business and tax requirements', TRUE, FALSE, TRUE),
('Short-term Marketing Data', 'Short retention for marketing preferences', '1 year', 'Legitimate interest', FALSE, FALSE, TRUE),
('Health Records', 'Extended retention for health-related data', '10 years', 'Medical record requirements', TRUE, TRUE, TRUE),
('Minimal Retention', 'Minimal retention for high-risk data', '90 days', 'Data minimization principle', FALSE, FALSE, TRUE);

-- Data Retention Execution Log
CREATE TABLE privacy.retention_execution_log (
    execution_id SERIAL PRIMARY KEY,
    policy_id INTEGER REFERENCES privacy.retention_policies(policy_id),
    execution_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    executed_by VARCHAR(255) NOT NULL,
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    records_processed INTEGER,
    records_deleted INTEGER,
    records_archived INTEGER,
    status VARCHAR(50) CHECK (status IN ('completed', 'failed', 'partial', 'approved', 'rejected')),
    error_message TEXT,
    execution_details JSONB
);

CREATE INDEX idx_retention_execution_log_policy ON privacy.retention_execution_log (policy_id);
CREATE INDEX idx_retention_execution_log_date ON privacy.retention_execution_log (execution_date);
CREATE INDEX idx_retention_execution_log_status ON privacy.retention_execution_log (status);

COMMENT ON TABLE privacy.retention_execution_log IS 'Log of data retention policy executions';

-- Data Retention Exemptions
CREATE TABLE privacy.retention_exemptions (
    exemption_id SERIAL PRIMARY KEY,
    exemption_type VARCHAR(50) CHECK (exemption_type IN ('legal_hold', 'regulatory', 'business_critical', 'user_request')),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    record_identifier JSONB,
    reason TEXT NOT NULL,
    requested_by VARCHAR(255) NOT NULL,
    approved_by VARCHAR(255),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_retention_exemptions_type ON privacy.retention_exemptions (exemption_type);
CREATE INDEX idx_retention_exemptions_target ON privacy.retention_exemptions (target_schema, target_table);
CREATE INDEX idx_retention_exemptions_dates ON privacy.retention_exemptions (start_date, end_date);
CREATE INDEX idx_retention_exemptions_active ON privacy.retention_exemptions (is_active);

COMMENT ON TABLE privacy.retention_exemptions IS 'Exemptions from automatic data retention policies';

-- Function to identify data for retention processing
CREATE OR REPLACE FUNCTION privacy.identify_data_for_retention(
    p_policy_id INTEGER,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    column_name TEXT,
    record_count BIGINT,
    oldest_record TIMESTAMP WITH TIME ZONE,
    sample_records JSONB
) AS $$
DECLARE
    v_policy privacy.retention_policies%ROWTYPE;
    v_sql TEXT;
    v_result RECORD;
BEGIN
    -- Get policy details
    SELECT * INTO v_policy FROM privacy.retention_policies WHERE policy_id = p_policy_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Retention policy with ID % not found', p_policy_id;
    END IF;

    -- Create temporary table for results
    CREATE TEMP TABLE IF NOT EXISTS temp_retention_results (
        schema_name TEXT,
        table_name TEXT,
        column_name TEXT,
        record_count BIGINT,
        oldest_record TIMESTAMP WITH TIME ZONE,
        sample_records JSONB
    ) ON COMMIT DROP;

    -- Find all classified columns that match this policy's criteria
    FOR v_result IN
        SELECT
            dc.object_schema,
            dc.object_name,
            dc.column_name,
            dcc.category_name,
            dcc.default_retention_period
        FROM
            privacy.data_classifications dc
        JOIN
            privacy.data_classification_categories dcc ON dc.category_id = dcc.category_id
        WHERE
            dc.object_type = 'column'
            AND (
                v_policy.applies_to_classifications IS NULL
                OR dc.category_id = ANY(v_policy.applies_to_classifications)
            )
    LOOP
        -- For each table with classified data, check for records older than retention period
        BEGIN
            v_sql := format(
                'INSERT INTO temp_retention_results
                 SELECT
                    %L AS schema_name,
                    %L AS table_name,
                    %L AS column_name,
                    COUNT(*) AS record_count,
                    MIN(created_at) AS oldest_record,
                    CASE WHEN COUNT(*) > 0 THEN
                        (SELECT jsonb_agg(t) FROM (SELECT * FROM %I.%I WHERE created_at < CURRENT_TIMESTAMP - %L::interval LIMIT 5) t)
                    ELSE NULL END AS sample_records
                 FROM %I.%I
                 WHERE created_at < CURRENT_TIMESTAMP - %L::interval
                    AND NOT EXISTS (
                        SELECT 1 FROM privacy.retention_exemptions re
                        WHERE re.target_schema = %L
                        AND re.target_table = %L
                        AND re.is_active = TRUE
                        AND (re.end_date IS NULL OR re.end_date > CURRENT_TIMESTAMP)
                    )',
                v_result.object_schema,
                v_result.object_name,
                v_result.column_name,
                v_result.object_schema,
                v_result.object_name,
                v_policy.retention_period,
                v_result.object_schema,
                v_result.object_name,
                v_policy.retention_period,
                v_result.object_schema,
                v_result.object_name
            );

            EXECUTE v_sql;
        EXCEPTION WHEN OTHERS THEN
            -- Skip tables that don't have created_at column or other issues
            RAISE NOTICE 'Could not process table %.%: %', v_result.object_schema, v_result.object_name, SQLERRM;
        END;
    END LOOP;

    -- Return results
    RETURN QUERY SELECT * FROM temp_retention_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION privacy.identify_data_for_retention IS 'Identifies data eligible for retention processing based on policy';

-- Function to execute data retention
CREATE OR REPLACE FUNCTION privacy.execute_retention_policy(
    p_policy_id INTEGER,
    p_execute BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    records_processed BIGINT,
    records_deleted BIGINT,
    records_archived BIGINT,
    status TEXT
) AS $$
DECLARE
    v_policy privacy.retention_policies%ROWTYPE;
    v_retention_data RECORD;
    v_sql TEXT;
    v_archive_sql TEXT;
    v_delete_sql TEXT;
    v_records_processed BIGINT;
    v_records_deleted BIGINT;
    v_records_archived BIGINT;
    v_execution_id INTEGER;
    v_status TEXT;
    v_error TEXT;
BEGIN
    -- Get policy details
    SELECT * INTO v_policy FROM privacy.retention_policies WHERE policy_id = p_policy_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Retention policy with ID % not found', p_policy_id;
    END IF;

    -- Create temporary table for results
    CREATE TEMP TABLE IF NOT EXISTS temp_execution_results (
        schema_name TEXT,
        table_name TEXT,
        records_processed BIGINT,
        records_deleted BIGINT,
        records_archived BIGINT,
        status TEXT
    ) ON COMMIT DROP;

    -- Create execution log entry
    INSERT INTO privacy.retention_execution_log (
        policy_id,
        executed_by,
        status,
        execution_details
    ) VALUES (
        p_policy_id,
        CURRENT_USER,
        CASE WHEN p_execute THEN 'completed' ELSE 'approved' END,
        jsonb_build_object('dry_run', NOT p_execute)
    ) RETURNING execution_id INTO v_execution_id;

    -- Process each table with data to retain
    FOR v_retention_data IN
        SELECT * FROM privacy.identify_data_for_retention(p_policy_id, NOT p_execute)
    LOOP
        v_records_processed := v_retention_data.record_count;
        v_records_deleted := 0;
        v_records_archived := 0;
        v_status := 'completed';
        v_error := NULL;

        -- Only execute if not in dry run mode
        IF p_execute THEN
            BEGIN
                -- Archive data if required
                IF v_policy.archive_before_delete THEN
                    -- In a real implementation, this would archive to a specified location
                    -- For this example, we'll just count the records
                    v_records_archived := v_records_processed;
                END IF;

                -- Delete data
                v_delete_sql := format(
                    'DELETE FROM %I.%I WHERE created_at < CURRENT_TIMESTAMP - %L::interval',
                    v_retention_data.schema_name,
                    v_retention_data.table_name,
                    v_policy.retention_period
                );

                EXECUTE v_delete_sql;
                GET DIAGNOSTICS v_records_deleted = ROW_COUNT;

            EXCEPTION WHEN OTHERS THEN
                v_status := 'failed';
                v_error := SQLERRM;
            END;
        ELSE
            -- In dry run mode, just report what would be deleted
            v_records_deleted := v_records_processed;
            v_status := 'approved';
        END IF;

        -- Update execution log with table details
        UPDATE privacy.retention_execution_log
        SET
            target_schema = v_retention_data.schema_name,
            target_table = v_retention_data.table_name,
            records_processed = v_records_processed,
            records_deleted = v_records_deleted,
            records_archived = v_records_archived,
            status = v_status,
            error_message = v_error,
            execution_details = jsonb_build_object(
                'dry_run', NOT p_execute,
                'oldest_record', v_retention_data.oldest_record,
                'sample_records', v_retention_data.sample_records
            )
        WHERE execution_id = v_execution_id;

        -- Add to results
        INSERT INTO temp_execution_results VALUES (
            v_retention_data.schema_name,
            v_retention_data.table_name,
            v_records_processed,
            v_records_deleted,
            v_records_archived,
            v_status
        );
    END LOOP;

    -- Return results
    RETURN QUERY SELECT * FROM temp_execution_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION privacy.execute_retention_policy IS 'Executes a data retention policy, optionally in dry-run mode';

-- Step 4: Create Consent Management System

-- Consent Types Table
CREATE TABLE privacy.consent_types (
    consent_type_id SERIAL PRIMARY KEY,
    consent_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_explicit BOOLEAN DEFAULT TRUE,
    requires_proof BOOLEAN DEFAULT TRUE,
    default_duration INTERVAL,
    legal_text TEXT,
    version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_consent_types_active ON privacy.consent_types (is_active);

COMMENT ON TABLE privacy.consent_types IS 'Types of consent that can be collected from data subjects';

-- Insert default consent types
INSERT INTO privacy.consent_types
(consent_name, description, is_explicit, requires_proof, default_duration, is_active)
VALUES
('Marketing Communications', 'Consent to receive marketing communications', TRUE, TRUE, '2 years', TRUE),
('Data Processing', 'General consent for processing personal data', TRUE, TRUE, '5 years', TRUE),
('Cookie Usage', 'Consent for using cookies on website', TRUE, FALSE, '1 year', TRUE),
('Third-party Sharing', 'Consent to share data with third parties', TRUE, TRUE, '1 year', TRUE),
('Profiling', 'Consent for automated profiling and decision making', TRUE, TRUE, '2 years', TRUE),
('Research', 'Consent to use data for research purposes', TRUE, TRUE, '5 years', TRUE),
('Location Tracking', 'Consent to track location data', TRUE, TRUE, '1 year', TRUE);

-- Consent Records Table
CREATE TABLE privacy.consent_records (
    consent_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    consent_type_id INTEGER NOT NULL REFERENCES privacy.consent_types(consent_type_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('granted', 'denied', 'withdrawn', 'expired')),
    collection_method VARCHAR(50) NOT NULL,
    collection_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    proof_data JSONB,
    expiry_date TIMESTAMP WITH TIME ZONE,
    withdrawal_timestamp TIMESTAMP WITH TIME ZONE,
    withdrawal_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE INDEX idx_consent_records_user ON privacy.consent_records (user_id);
CREATE INDEX idx_consent_records_type ON privacy.consent_records (consent_type_id);
CREATE INDEX idx_consent_records_status ON privacy.consent_records (status);
CREATE INDEX idx_consent_records_expiry ON privacy.consent_records (expiry_date);

COMMENT ON TABLE privacy.consent_records IS 'Records of user consent for various data processing purposes';

-- Consent Version History
CREATE TABLE privacy.consent_version_history (
    version_id SERIAL PRIMARY KEY,
    consent_type_id INTEGER NOT NULL REFERENCES privacy.consent_types(consent_type_id),
    version VARCHAR(20) NOT NULL,
    legal_text TEXT NOT NULL,
    effective_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE INDEX idx_consent_version_history_type ON privacy.consent_version_history (consent_type_id);
CREATE INDEX idx_consent_version_history_dates ON privacy.consent_version_history (effective_date, end_date);

COMMENT ON TABLE privacy.consent_version_history IS 'Historical versions of consent legal text and terms';

-- Consent Dependencies Table
CREATE TABLE privacy.consent_dependencies (
    dependency_id SERIAL PRIMARY KEY,
    parent_consent_type_id INTEGER NOT NULL REFERENCES privacy.consent_types(consent_type_id),
    child_consent_type_id INTEGER NOT NULL REFERENCES privacy.consent_types(consent_type_id),
    relationship_type VARCHAR(20) NOT NULL CHECK (relationship_type IN ('requires', 'invalidates', 'suggests')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_consent_dependency UNIQUE (parent_consent_type_id, child_consent_type_id)
);

CREATE INDEX idx_consent_dependencies_parent ON privacy.consent_dependencies (parent_consent_type_id);
CREATE INDEX idx_consent_dependencies_child ON privacy.consent_dependencies (child_consent_type_id);

COMMENT ON TABLE privacy.consent_dependencies IS 'Dependencies between different types of consent';

-- Function to check if user has valid consent
CREATE OR REPLACE FUNCTION privacy.has_valid_consent(
    p_user_id INTEGER,
    p_consent_type VARCHAR(100)
) RETURNS BOOLEAN AS $$
DECLARE
    v_consent_type_id INTEGER;
    v_has_consent BOOLEAN;
BEGIN
    -- Get consent type ID
    SELECT consent_type_id INTO v_consent_type_id
    FROM privacy.consent_types
    WHERE consent_name = p_consent_type AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Consent type "%" not found or not active', p_consent_type;
    END IF;

    -- Check if user has valid consent
    SELECT EXISTS (
        SELECT 1
        FROM privacy.consent_records
        WHERE user_id = p_user_id
        AND consent_type_id = v_consent_type_id
        AND status = 'granted'
        AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP)
    ) INTO v_has_consent;

    RETURN v_has_consent;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.has_valid_consent IS 'Checks if a user has valid consent for a specific purpose';

-- Function to record new consent
CREATE OR REPLACE FUNCTION privacy.record_consent(
    p_user_id INTEGER,
    p_consent_type VARCHAR(100),
    p_status VARCHAR(20),
    p_collection_method VARCHAR(50),
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_proof_data JSONB DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_consent_type_id INTEGER;
    v_default_duration INTERVAL;
    v_expiry_date TIMESTAMP WITH TIME ZONE;
    v_consent_id INTEGER;
BEGIN
    -- Get consent type ID and default duration
    SELECT
        consent_type_id,
        default_duration
    INTO
        v_consent_type_id,
        v_default_duration
    FROM privacy.consent_types
    WHERE consent_name = p_consent_type AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Consent type "%" not found or not active', p_consent_type;
    END IF;

    -- Calculate expiry date if applicable
    IF v_default_duration IS NOT NULL THEN
        v_expiry_date := CURRENT_TIMESTAMP + v_default_duration;
    END IF;

    -- Insert new consent record
    INSERT INTO privacy.consent_records (
        user_id,
        consent_type_id,
        status,
        collection_method,
        ip_address,
        user_agent,
        proof_data,
        expiry_date,
        notes
    ) VALUES (
        p_user_id,
        v_consent_type_id,
        p_status,
        p_collection_method,
        p_ip_address,
        p_user_agent,
        p_proof_data,
        v_expiry_date,
        p_notes
    ) RETURNING consent_id INTO v_consent_id;

    -- Handle consent dependencies
    IF p_status = 'granted' THEN
        -- Auto-grant dependent consents
        FOR v_consent_type_id IN
            SELECT child_consent_type_id
            FROM privacy.consent_dependencies
            WHERE parent_consent_type_id = v_consent_type_id
            AND relationship_type = 'requires'
        LOOP
            -- Check if dependent consent already exists
            IF NOT EXISTS (
                SELECT 1
                FROM privacy.consent_records
                WHERE user_id = p_user_id
                AND consent_type_id = v_consent_type_id
                AND status = 'granted'
                AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP)
            ) THEN
                -- Auto-grant the dependent consent
                PERFORM privacy.record_consent(
                    p_user_id,
                    (SELECT consent_name FROM privacy.consent_types WHERE consent_type_id = v_consent_type_id),
                    'granted',
                    'auto-dependency',
                    p_ip_address,
                    p_user_agent,
                    jsonb_build_object('parent_consent_id', v_consent_id),
                    'Auto-granted based on dependency'
                );
            END IF;
        END LOOP;
    ELSIF p_status = 'withdrawn' OR p_status = 'denied' THEN
        -- Auto-withdraw dependent consents
        FOR v_consent_type_id IN
            SELECT child_consent_type_id
            FROM privacy.consent_dependencies
            WHERE parent_consent_type_id = v_consent_type_id
            AND relationship_type = 'invalidates'
        LOOP
            -- Check if dependent consent exists and is granted
            IF EXISTS (
                SELECT 1
                FROM privacy.consent_records
                WHERE user_id = p_user_id
                AND consent_type_id = v_consent_type_id
                AND status = 'granted'
                AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP)
            ) THEN
                -- Auto-withdraw the dependent consent
                UPDATE privacy.consent_records
                SET
                    status = 'withdrawn',
                    withdrawal_timestamp = CURRENT_TIMESTAMP,
                    withdrawal_reason = 'Parent consent withdrawn',
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = p_user_id
                AND consent_type_id = v_consent_type_id
                AND status = 'granted'
                AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP);
            END IF;
        END LOOP;
    END IF;

    RETURN v_consent_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.record_consent IS 'Records a new consent decision for a user';

-- Function to withdraw consent
CREATE OR REPLACE FUNCTION privacy.withdraw_consent(
    p_user_id INTEGER,
    p_consent_type VARCHAR(100),
    p_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_consent_type_id INTEGER;
    v_updated BOOLEAN := FALSE;
BEGIN
    -- Get consent type ID
    SELECT consent_type_id INTO v_consent_type_id
    FROM privacy.consent_types
    WHERE consent_name = p_consent_type AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Consent type "%" not found or not active', p_consent_type;
    END IF;

    -- Update consent records
    UPDATE privacy.consent_records
    SET
        status = 'withdrawn',
        withdrawal_timestamp = CURRENT_TIMESTAMP,
        withdrawal_reason = p_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id
    AND consent_type_id = v_consent_type_id
    AND status = 'granted'
    AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    -- Handle consent dependencies
    IF v_updated > 0 THEN
        -- Auto-withdraw dependent consents
        FOR v_consent_type_id IN
            SELECT child_consent_type_id
            FROM privacy.consent_dependencies
            WHERE parent_consent_type_id = v_consent_type_id
            AND relationship_type = 'invalidates'
        LOOP
            -- Check if dependent consent exists and is granted
            IF EXISTS (
                SELECT 1
                FROM privacy.consent_records
                WHERE user_id = p_user_id
                AND consent_type_id = v_consent_type_id
                AND status = 'granted'
                AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP)
            ) THEN
                -- Auto-withdraw the dependent consent
                UPDATE privacy.consent_records
                SET
                    status = 'withdrawn',
                    withdrawal_timestamp = CURRENT_TIMESTAMP,
                    withdrawal_reason = 'Parent consent withdrawn: ' || p_consent_type,
                    updated_at = CURRENT_TIMESTAMP
                WHERE user_id = p_user_id
                AND consent_type_id = v_consent_type_id
                AND status = 'granted'
                AND (expiry_date IS NULL OR expiry_date > CURRENT_TIMESTAMP);
            END IF;
        END LOOP;
    END IF;

    RETURN v_updated > 0;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.withdraw_consent IS 'Withdraws a previously granted consent';

-- Step 5: Create Cross-Border Data Transfer Tracking

-- Countries Table with Data Protection Adequacy
CREATE TABLE privacy.countries (
    country_id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL UNIQUE,
    country_name VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    adequacy_status VARCHAR(50) CHECK (adequacy_status IN ('adequate', 'partial', 'inadequate', 'pending')),
    adequacy_details TEXT,
    requires_sccs BOOLEAN DEFAULT FALSE,
    requires_impact_assessment BOOLEAN DEFAULT FALSE,
    special_requirements TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE INDEX idx_countries_adequacy ON privacy.countries (adequacy_status);
CREATE INDEX idx_countries_region ON privacy.countries (region);

COMMENT ON TABLE privacy.countries IS 'Countries with their data protection adequacy status';

-- Insert sample countries with adequacy status
INSERT INTO privacy.countries
(country_code, country_name, region, adequacy_status, requires_sccs, requires_impact_assessment)
VALUES
('US', 'United States', 'North America', 'partial', TRUE, TRUE),
('CA', 'Canada', 'North America', 'adequate', FALSE, FALSE),
('GB', 'United Kingdom', 'Europe', 'adequate', FALSE, FALSE),
('DE', 'Germany', 'Europe', 'adequate', FALSE, FALSE),
('FR', 'France', 'Europe', 'adequate', FALSE, FALSE),
('JP', 'Japan', 'Asia', 'adequate', FALSE, FALSE),
('AU', 'Australia', 'Oceania', 'partial', TRUE, FALSE),
('BR', 'Brazil', 'South America', 'partial', TRUE, TRUE),
('IN', 'India', 'Asia', 'inadequate', TRUE, TRUE),
('RU', 'Russia', 'Europe/Asia', 'inadequate', TRUE, TRUE),
('CN', 'China', 'Asia', 'inadequate', TRUE, TRUE),
('ZA', 'South Africa', 'Africa', 'partial', TRUE, FALSE),
('SG', 'Singapore', 'Asia', 'partial', TRUE, FALSE),
('AE', 'United Arab Emirates', 'Middle East', 'inadequate', TRUE, TRUE),
('AR', 'Argentina', 'South America', 'adequate', FALSE, FALSE),
('CH', 'Switzerland', 'Europe', 'adequate', FALSE, FALSE),
('IL', 'Israel', 'Middle East', 'adequate', FALSE, FALSE),
('KR', 'South Korea', 'Asia', 'adequate', FALSE, FALSE),
('MX', 'Mexico', 'North America', 'partial', TRUE, FALSE),
('NZ', 'New Zealand', 'Oceania', 'adequate', FALSE, FALSE);

-- Data Transfer Mechanisms Table
CREATE TABLE privacy.transfer_mechanisms (
    mechanism_id SERIAL PRIMARY KEY,
    mechanism_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    legal_basis TEXT,
    documentation_required TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE privacy.transfer_mechanisms IS 'Legal mechanisms for cross-border data transfers';

-- Insert standard transfer mechanisms
INSERT INTO privacy.transfer_mechanisms
(mechanism_name, description, legal_basis, documentation_required, is_active)
VALUES
('Adequacy Decision', 'Transfer to country with EU adequacy decision', 'GDPR Article 45', 'None', TRUE),
('Standard Contractual Clauses', 'EU-approved standard contractual clauses', 'GDPR Article 46(2)(c)', 'Signed SCCs, Transfer Impact Assessment', TRUE),
('Binding Corporate Rules', 'Legally binding data protection rules', 'GDPR Article 46(2)(b)', 'Approved BCRs', TRUE),
('Explicit Consent', 'Explicit informed consent from data subject', 'GDPR Article 49(1)(a)', 'Consent records', TRUE),
('Contract Performance', 'Necessary for contract with data subject', 'GDPR Article 49(1)(b)', 'Contract documentation', TRUE),
('Important Public Interest', 'Necessary for important public interest', 'GDPR Article 49(1)(d)', 'Public interest documentation', TRUE),
('Legal Claims', 'Necessary for legal claims', 'GDPR Article 49(1)(e)', 'Legal documentation', TRUE),
('Vital Interests', 'Necessary to protect vital interests', 'GDPR Article 49(1)(f)', 'Documentation of circumstances', TRUE);

-- Data Transfers Table
CREATE TABLE privacy.data_transfers (
    transfer_id SERIAL PRIMARY KEY,
    transfer_name VARCHAR(100) NOT NULL,
    description TEXT,
    source_system VARCHAR(100) NOT NULL,
    destination_system VARCHAR(100) NOT NULL,
    destination_country_id INTEGER NOT NULL REFERENCES privacy.countries(country_id),
    destination_organization VARCHAR(100),
    transfer_mechanism_id INTEGER NOT NULL REFERENCES privacy.transfer_mechanisms(mechanism_id),
    data_categories TEXT[] NOT NULL,
    data_subject_categories TEXT[] NOT NULL,
    transfer_purpose TEXT NOT NULL,
    first_transfer_date TIMESTAMP WITH TIME ZONE,
    last_transfer_date TIMESTAMP WITH TIME ZONE,
    transfer_frequency VARCHAR(50),
    documentation_url TEXT,
    risk_assessment_completed BOOLEAN DEFAULT FALSE,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    mitigation_measures TEXT,
    responsible_person VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_data_transfers_destination ON privacy.data_transfers (destination_country_id);
CREATE INDEX idx_data_transfers_mechanism ON privacy.data_transfers (transfer_mechanism_id);
CREATE INDEX idx_data_transfers_active ON privacy.data_transfers (is_active);
CREATE INDEX idx_data_transfers_risk ON privacy.data_transfers (risk_level);

COMMENT ON TABLE privacy.data_transfers IS 'Registry of cross-border data transfers';

-- Data Transfer Logs Table
CREATE TABLE privacy.transfer_logs (
    log_id SERIAL PRIMARY KEY,
    transfer_id INTEGER NOT NULL REFERENCES privacy.data_transfers(transfer_id),
    transfer_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    data_volume INTEGER,
    volume_unit VARCHAR(20) DEFAULT 'records',
    transfer_status VARCHAR(20) CHECK (transfer_status IN ('completed', 'failed', 'partial')),
    affected_users INTEGER,
    error_details TEXT,
    transfer_method VARCHAR(50),
    encryption_used BOOLEAN DEFAULT TRUE,
    initiated_by VARCHAR(100),
    notes TEXT
);

CREATE INDEX idx_transfer_logs_transfer ON privacy.transfer_logs (transfer_id);
CREATE INDEX idx_transfer_logs_timestamp ON privacy.transfer_logs (transfer_timestamp);
CREATE INDEX idx_transfer_logs_status ON privacy.transfer_logs (transfer_status);

COMMENT ON TABLE privacy.transfer_logs IS 'Detailed logs of individual data transfer events';

-- Transfer Impact Assessments
CREATE TABLE privacy.transfer_impact_assessments (
    assessment_id SERIAL PRIMARY KEY,
    transfer_id INTEGER NOT NULL REFERENCES privacy.data_transfers(transfer_id),
    assessment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assessor VARCHAR(100) NOT NULL,
    legal_framework_analysis TEXT,
    recipient_country_laws TEXT,
    surveillance_risk_analysis TEXT,
    data_subject_rights_analysis TEXT,
    technical_measures TEXT,
    organizational_measures TEXT,
    contractual_measures TEXT,
    overall_risk_level VARCHAR(20) CHECK (overall_risk_level IN ('low', 'medium', 'high', 'critical')),
    conclusion TEXT,
    next_review_date TIMESTAMP WITH TIME ZONE,
    approval_status VARCHAR(20) CHECK (approval_status IN ('draft', 'pending', 'approved', 'rejected')),
    approved_by VARCHAR(100),
    approval_date TIMESTAMP WITH TIME ZONE,
    documentation_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transfer_impact_assessments_transfer ON privacy.transfer_impact_assessments (transfer_id);
CREATE INDEX idx_transfer_impact_assessments_risk ON privacy.transfer_impact_assessments (overall_risk_level);
CREATE INDEX idx_transfer_impact_assessments_status ON privacy.transfer_impact_assessments (approval_status);

COMMENT ON TABLE privacy.transfer_impact_assessments IS 'Impact assessments for high-risk data transfers';

-- Function to log a data transfer
CREATE OR REPLACE FUNCTION privacy.log_data_transfer(
    p_transfer_name VARCHAR(100),
    p_destination_country CHAR(2),
    p_destination_organization VARCHAR(100),
    p_transfer_mechanism VARCHAR(100),
    p_data_categories TEXT[],
    p_data_subject_categories TEXT[],
    p_transfer_purpose TEXT,
    p_data_volume INTEGER,
    p_affected_users INTEGER,
    p_transfer_method VARCHAR(50) DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_transfer_id INTEGER;
    v_country_id INTEGER;
    v_mechanism_id INTEGER;
    v_log_id INTEGER;
BEGIN
    -- Get country ID
    SELECT country_id INTO v_country_id
    FROM privacy.countries
    WHERE country_code = p_destination_country;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Country with code % not found', p_destination_country;
    END IF;

    -- Get mechanism ID
    SELECT mechanism_id INTO v_mechanism_id
    FROM privacy.transfer_mechanisms
    WHERE mechanism_name = p_transfer_mechanism AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transfer mechanism "%" not found or not active', p_transfer_mechanism;
    END IF;

    -- Check if transfer already exists
    SELECT transfer_id INTO v_transfer_id
    FROM privacy.data_transfers
    WHERE transfer_name = p_transfer_name
    AND destination_country_id = v_country_id
    AND destination_organization = p_destination_organization
    AND is_active = TRUE;

    -- Create new transfer if it doesn't exist
    IF NOT FOUND THEN
        INSERT INTO privacy.data_transfers (
            transfer_name,
            source_system,
            destination_system,
            destination_country_id,
            destination_organization,
            transfer_mechanism_id,
            data_categories,
            data_subject_categories,
            transfer_purpose,
            first_transfer_date,
            last_transfer_date,
            transfer_frequency,
            risk_assessment_completed,
            risk_level
        ) VALUES (
            p_transfer_name,
            'Internal System',
            'External System',
            v_country_id,
            p_destination_organization,
            v_mechanism_id,
            p_data_categories,
            p_data_subject_categories,
            p_transfer_purpose,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP,
            'As needed',
            FALSE,
            CASE
                WHEN (SELECT adequacy_status FROM privacy.countries WHERE country_id = v_country_id) = 'adequate' THEN 'low'
                WHEN (SELECT adequacy_status FROM privacy.countries WHERE country_id = v_country_id) = 'partial' THEN 'medium'
                ELSE 'high'
            END
        ) RETURNING transfer_id INTO v_transfer_id;
    ELSE
        -- Update existing transfer
        UPDATE privacy.data_transfers
        SET
            last_transfer_date = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE transfer_id = v_transfer_id;
    END IF;

    -- Log the transfer
    INSERT INTO privacy.transfer_logs (
        transfer_id,
        data_volume,
        affected_users,
        transfer_status,
        transfer_method,
        initiated_by,
        notes
    ) VALUES (
        v_transfer_id,
        p_data_volume,
        p_affected_users,
        'completed',
        p_transfer_method,
        CURRENT_USER,
        p_notes
    ) RETURNING log_id INTO v_log_id;

    -- Check if impact assessment is needed
    IF (SELECT requires_impact_assessment FROM privacy.countries WHERE country_id = v_country_id)
       AND NOT EXISTS (SELECT 1 FROM privacy.transfer_impact_assessments WHERE transfer_id = v_transfer_id) THEN

        -- Create draft impact assessment
        INSERT INTO privacy.transfer_impact_assessments (
            transfer_id,
            assessor,
            legal_framework_analysis,
            overall_risk_level,
            approval_status,
            next_review_date
        ) VALUES (
            v_transfer_id,
            CURRENT_USER,
            'Draft assessment needed for this transfer',
            CASE
                WHEN (SELECT adequacy_status FROM privacy.countries WHERE country_id = v_country_id) = 'adequate' THEN 'low'
                WHEN (SELECT adequacy_status FROM privacy.countries WHERE country_id = v_country_id) = 'partial' THEN 'medium'
                ELSE 'high'
            END,
            'draft',
            CURRENT_TIMESTAMP + INTERVAL '1 year'
        );
    END IF;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.log_data_transfer IS 'Logs a cross-border data transfer and creates necessary records';

-- Step 6: Create Data Processing Purpose Documentation

-- Data Processing Purposes Table
CREATE TABLE privacy.processing_purposes (
    purpose_id SERIAL PRIMARY KEY,
    purpose_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    legal_basis VARCHAR(50) NOT NULL CHECK (legal_basis IN (
        'consent', 'contract', 'legal_obligation', 'vital_interests',
        'public_interest', 'legitimate_interests', 'other'
    )),
    legal_basis_details TEXT,
    requires_consent BOOLEAN DEFAULT FALSE,
    requires_impact_assessment BOOLEAN DEFAULT FALSE,
    retention_period INTERVAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_processing_purposes_legal_basis ON privacy.processing_purposes (legal_basis);
CREATE INDEX idx_processing_purposes_active ON privacy.processing_purposes (is_active);

COMMENT ON TABLE privacy.processing_purposes IS 'Documented purposes for data processing activities';

-- Insert standard processing purposes
INSERT INTO privacy.processing_purposes
(purpose_name, description, legal_basis, requires_consent, requires_impact_assessment, retention_period, is_active)
VALUES
('User Account Management', 'Managing user accounts and authentication', 'contract', FALSE, FALSE, '7 years', TRUE),
('Order Processing', 'Processing and fulfilling customer orders', 'contract', FALSE, FALSE, '7 years', TRUE),
('Payment Processing', 'Processing payments for products and services', 'contract', FALSE, FALSE, '7 years', TRUE),
('Marketing Communications', 'Sending marketing emails and communications', 'consent', TRUE, FALSE, '2 years', TRUE),
('Website Analytics', 'Analyzing website usage and performance', 'legitimate_interests', TRUE, FALSE, '2 years', TRUE),
('Product Improvement', 'Using data to improve products and services', 'legitimate_interests', TRUE, FALSE, '3 years', TRUE),
('Legal Compliance', 'Compliance with legal and regulatory requirements', 'legal_obligation', FALSE, FALSE, '10 years', TRUE),
('Fraud Prevention', 'Detecting and preventing fraudulent activities', 'legitimate_interests', FALSE, TRUE, '5 years', TRUE),
('Customer Support', 'Providing customer support services', 'contract', FALSE, FALSE, '3 years', TRUE),
('Research and Development', 'Research for new products and features', 'legitimate_interests', TRUE, TRUE, '5 years', TRUE),
('Personalization', 'Personalizing user experience', 'consent', TRUE, FALSE, '2 years', TRUE),
('Security Monitoring', 'Monitoring for security threats', 'legitimate_interests', FALSE, FALSE, '1 year', TRUE);

-- Data Processing Activities Table
CREATE TABLE privacy.processing_activities (
    activity_id SERIAL PRIMARY KEY,
    activity_name VARCHAR(100) NOT NULL,
    description TEXT,
    purpose_id INTEGER NOT NULL REFERENCES privacy.processing_purposes(purpose_id),
    data_controller VARCHAR(100) NOT NULL,
    data_processor VARCHAR(100),
    processing_systems TEXT[],
    data_categories TEXT[] NOT NULL,
    data_subject_categories TEXT[] NOT NULL,
    recipients_categories TEXT[],
    involves_automated_decision BOOLEAN DEFAULT FALSE,
    involves_profiling BOOLEAN DEFAULT FALSE,
    involves_children_data BOOLEAN DEFAULT FALSE,
    involves_sensitive_data BOOLEAN DEFAULT FALSE,
    involves_systematic_monitoring BOOLEAN DEFAULT FALSE,
    involves_large_scale_processing BOOLEAN DEFAULT FALSE,
    dpia_conducted BOOLEAN DEFAULT FALSE,
    dpia_reference VARCHAR(100),
    technical_measures TEXT,
    organizational_measures TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_processing_activities_purpose ON privacy.processing_activities (purpose_id);
CREATE INDEX idx_processing_activities_active ON privacy.processing_activities (is_active);
CREATE INDEX idx_processing_activities_high_risk ON privacy.processing_activities (
    (involves_automated_decision OR involves_profiling OR involves_children_data OR
     involves_sensitive_data OR involves_systematic_monitoring OR involves_large_scale_processing)
);

COMMENT ON TABLE privacy.processing_activities IS 'Documented data processing activities';

-- Data Processing Impact Assessments
CREATE TABLE privacy.data_protection_impact_assessments (
    dpia_id SERIAL PRIMARY KEY,
    activity_id INTEGER NOT NULL REFERENCES privacy.processing_activities(activity_id),
    assessment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assessor VARCHAR(100) NOT NULL,
    systematic_description TEXT,
    necessity_proportionality TEXT,
    risks_to_rights TEXT,
    measures_to_address_risks TEXT,
    consultation_details TEXT,
    dpo_recommendation TEXT,
    dpo_name VARCHAR(100),
    overall_risk_level VARCHAR(20) CHECK (overall_risk_level IN ('low', 'medium', 'high', 'critical')),
    conclusion TEXT,
    next_review_date TIMESTAMP WITH TIME ZONE,
    approval_status VARCHAR(20) CHECK (approval_status IN ('draft', 'pending', 'approved', 'rejected')),
    approved_by VARCHAR(100),
    approval_date TIMESTAMP WITH TIME ZONE,
    documentation_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_data_protection_impact_assessments_activity ON privacy.data_protection_impact_assessments (activity_id);
CREATE INDEX idx_data_protection_impact_assessments_risk ON privacy.data_protection_impact_assessments (overall_risk_level);
CREATE INDEX idx_data_protection_impact_assessments_status ON privacy.data_protection_impact_assessments (approval_status);

COMMENT ON TABLE privacy.data_protection_impact_assessments IS 'Data Protection Impact Assessments for high-risk processing activities';

-- Table Mapping to Processing Purposes
CREATE TABLE privacy.table_purpose_mapping (
    mapping_id SERIAL PRIMARY KEY,
    table_schema VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    purpose_id INTEGER NOT NULL REFERENCES privacy.processing_purposes(purpose_id),
    justification TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_table_purpose UNIQUE (table_schema, table_name, purpose_id)
);

CREATE INDEX idx_table_purpose_mapping_table ON privacy.table_purpose_mapping (table_schema, table_name);
CREATE INDEX idx_table_purpose_mapping_purpose ON privacy.table_purpose_mapping (purpose_id);

COMMENT ON TABLE privacy.table_purpose_mapping IS 'Maps database tables to their processing purposes';

-- Function to document a processing activity
CREATE OR REPLACE FUNCTION privacy.document_processing_activity(
    p_activity_name VARCHAR(100),
    p_description TEXT,
    p_purpose_name VARCHAR(100),
    p_data_controller VARCHAR(100),
    p_data_processor VARCHAR(100),
    p_processing_systems TEXT[],
    p_data_categories TEXT[],
    p_data_subject_categories TEXT[],
    p_recipients_categories TEXT[] DEFAULT NULL,
    p_involves_automated_decision BOOLEAN DEFAULT FALSE,
    p_involves_profiling BOOLEAN DEFAULT FALSE,
    p_involves_children_data BOOLEAN DEFAULT FALSE,
    p_involves_sensitive_data BOOLEAN DEFAULT FALSE,
    p_involves_systematic_monitoring BOOLEAN DEFAULT FALSE,
    p_involves_large_scale_processing BOOLEAN DEFAULT FALSE,
    p_technical_measures TEXT DEFAULT NULL,
    p_organizational_measures TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_purpose_id INTEGER;
    v_activity_id INTEGER;
    v_requires_dpia BOOLEAN;
BEGIN
    -- Get purpose ID
    SELECT purpose_id INTO v_purpose_id
    FROM privacy.processing_purposes
    WHERE purpose_name = p_purpose_name AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Processing purpose "%" not found or not active', p_purpose_name;
    END IF;

    -- Check if activity already exists
    SELECT activity_id INTO v_activity_id
    FROM privacy.processing_activities
    WHERE activity_name = p_activity_name
    AND purpose_id = v_purpose_id
    AND is_active = TRUE;

    -- Determine if DPIA is required
    v_requires_dpia := (
        p_involves_automated_decision OR
        p_involves_profiling OR
        p_involves_children_data OR
        p_involves_sensitive_data OR
        p_involves_systematic_monitoring OR
        p_involves_large_scale_processing OR
        (SELECT requires_impact_assessment FROM privacy.processing_purposes WHERE purpose_id = v_purpose_id)
    );

    -- Create new activity if it doesn't exist
    IF NOT FOUND THEN
        INSERT INTO privacy.processing_activities (
            activity_name,
            description,
            purpose_id,
            data_controller,
            data_processor,
            processing_systems,
            data_categories,
            data_subject_categories,
            recipients_categories,
            involves_automated_decision,
            involves_profiling,
            involves_children_data,
            involves_sensitive_data,
            involves_systematic_monitoring,
            involves_large_scale_processing,
            dpia_conducted,
            technical_measures,
            organizational_measures
        ) VALUES (
            p_activity_name,
            p_description,
            v_purpose_id,
            p_data_controller,
            p_data_processor,
            p_processing_systems,
            p_data_categories,
            p_data_subject_categories,
            p_recipients_categories,
            p_involves_automated_decision,
            p_involves_profiling,
            p_involves_children_data,
            p_involves_sensitive_data,
            p_involves_systematic_monitoring,
            p_involves_large_scale_processing,
            FALSE,
            p_technical_measures,
            p_organizational_measures
        ) RETURNING activity_id INTO v_activity_id;
    ELSE
        -- Update existing activity
        UPDATE privacy.processing_activities
        SET
            description = p_description,
            data_controller = p_data_controller,
            data_processor = p_data_processor,
            processing_systems = p_processing_systems,
            data_categories = p_data_categories,
            data_subject_categories = p_data_subject_categories,
            recipients_categories = p_recipients_categories,
            involves_automated_decision = p_involves_automated_decision,
            involves_profiling = p_involves_profiling,
            involves_children_data = p_involves_children_data,
            involves_sensitive_data = p_involves_sensitive_data,
            involves_systematic_monitoring = p_involves_systematic_monitoring,
            involves_large_scale_processing = p_involves_large_scale_processing,
            technical_measures = p_technical_measures,
            organizational_measures = p_organizational_measures,
            updated_at = CURRENT_TIMESTAMP
        WHERE activity_id = v_activity_id;
    END IF;

    -- Create DPIA if required and doesn't exist
    IF v_requires_dpia AND NOT EXISTS (
        SELECT 1 FROM privacy.data_protection_impact_assessments WHERE activity_id = v_activity_id
    ) THEN
        INSERT INTO privacy.data_protection_impact_assessments (
            activity_id,
            assessor,
            systematic_description,
            overall_risk_level,
            approval_status,
            next_review_date
        ) VALUES (
            v_activity_id,
            CURRENT_USER,
            'Draft DPIA needed for this processing activity',
            'high',
            'draft',
            CURRENT_TIMESTAMP + INTERVAL '1 year'
        );
    END IF;

    RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.document_processing_activity IS 'Documents a data processing activity and creates necessary records';

-- Function to map tables to processing purposes
CREATE OR REPLACE FUNCTION privacy.map_table_to_purpose(
    p_table_schema VARCHAR(255),
    p_table_name VARCHAR(255),
    p_purpose_name VARCHAR(100),
    p_justification TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_purpose_id INTEGER;
    v_mapping_id INTEGER;
BEGIN
    -- Get purpose ID
    SELECT purpose_id INTO v_purpose_id
    FROM privacy.processing_purposes
    WHERE purpose_name = p_purpose_name AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Processing purpose "%" not found or not active', p_purpose_name;
    END IF;

    -- Check if table exists
    PERFORM 1
    FROM information_schema.tables
    WHERE table_schema = p_table_schema
    AND table_name = p_table_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Table %.% does not exist', p_table_schema, p_table_name;
    END IF;

    -- Insert or update mapping
    INSERT INTO privacy.table_purpose_mapping (
        table_schema,
        table_name,
        purpose_id,
        justification
    ) VALUES (
        p_table_schema,
        p_table_name,
        v_purpose_id,
        p_justification
    )
    ON CONFLICT (table_schema, table_name, purpose_id)
    DO UPDATE SET
        justification = p_justification,
        updated_at = CURRENT_TIMESTAMP
    RETURNING mapping_id INTO v_mapping_id;

    RETURN v_mapping_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION privacy.map_table_to_purpose IS 'Maps a database table to a processing purpose';

-- Step 7: Create Views for Reporting and Monitoring

-- View for Data Classification Overview
CREATE OR REPLACE VIEW privacy.v_data_classification_overview AS
SELECT
    dc.object_schema,
    dc.object_name,
    dc.column_name,
    dcc.category_name,
    dcc.sensitivity_level,
    dcc.requires_consent,
    dcc.requires_special_handling,
    dcc.default_retention_period,
    dc.data_owner,
    dc.reviewer,
    dc.review_date,
    dc.justification
FROM
    privacy.data_classifications dc
JOIN
    privacy.data_classification_categories dcc ON dc.category_id = dcc.category_id
ORDER BY
    dcc.sensitivity_level DESC,
    dc.object_schema,
    dc.object_name,
    dc.column_name;

COMMENT ON VIEW privacy.v_data_classification_overview IS 'Overview of data classifications across the database';

-- View for High-Risk Data Elements
CREATE OR REPLACE VIEW privacy.v_high_risk_data_elements AS
SELECT
    dc.object_schema,
    dc.object_name,
    dc.column_name,
    dcc.category_name,
    dcc.sensitivity_level,
    dcc.requires_consent,
    dcc.requires_special_handling,
    dc.data_owner,
    dc.reviewer,
    dc.review_date
FROM
    privacy.data_classifications dc
JOIN
    privacy.data_classification_categories dcc ON dc.category_id = dcc.category_id
WHERE
    dcc.sensitivity_level >= 7
ORDER BY
    dcc.sensitivity_level DESC,
    dc.object_schema,
    dc.object_name,
    dc.column_name;

COMMENT ON VIEW privacy.v_high_risk_data_elements IS 'High-risk data elements requiring special protection';

-- View for Consent Status by User
CREATE OR REPLACE VIEW privacy.v_user_consent_status AS
SELECT
    u.user_id,
    u.username,
    u.email,
    ct.consent_name,
    cr.status,
    cr.collection_timestamp,
    cr.expiry_date,
    CASE
        WHEN cr.status = 'granted' AND (cr.expiry_date IS NULL OR cr.expiry_date > CURRENT_TIMESTAMP) THEN TRUE
        ELSE FALSE
    END AS has_valid_consent,
    cr.collection_method,
    cr.withdrawal_timestamp,
    cr.withdrawal_reason
FROM
    Users u
CROSS JOIN
    privacy.consent_types ct
LEFT JOIN
    privacy.consent_records cr ON u.user_id = cr.user_id AND ct.consent_type_id = cr.consent_type_id
WHERE
    ct.is_active = TRUE
ORDER BY
    u.user_id,
    ct.consent_name;

COMMENT ON VIEW privacy.v_user_consent_status IS 'Current consent status for all users';

-- View for Data Retention Compliance
CREATE OR REPLACE VIEW privacy.v_data_retention_compliance AS
WITH classified_tables AS (
    SELECT DISTINCT
        dc.object_schema,
        dc.object_name,
        MAX(dcc.sensitivity_level) AS max_sensitivity
    FROM
        privacy.data_classifications dc
    JOIN
        privacy.data_classification_categories dcc ON dc.category_id = dcc.category_id
    WHERE
        dc.object_type = 'table'
    GROUP BY
        dc.object_schema,
        dc.object_name
)
SELECT
    ct.object_schema,
    ct.object_name,
    ct.max_sensitivity,
    COALESCE(
        (SELECT retention_period FROM privacy.retention_policies rp
         JOIN privacy.table_purpose_mapping tpm ON rp.policy_id = tpm.purpose_id
         WHERE tpm.table_schema = ct.object_schema AND tpm.table_name = ct.object_name
         LIMIT 1),
        CASE
            WHEN ct.max_sensitivity >= 7 THEN '2 years'::interval
            ELSE '7 years'::interval
        END
    ) AS applicable_retention_period,
    EXISTS (
        SELECT 1 FROM privacy.retention_execution_log rel
        WHERE rel.target_schema = ct.object_schema
        AND rel.target_table = ct.object_name
        AND rel.status = 'completed'
        AND rel.execution_date > CURRENT_TIMESTAMP - INTERVAL '1 month'
    ) AS recently_processed,
    (SELECT MAX(execution_date) FROM privacy.retention_execution_log rel
     WHERE rel.target_schema = ct.object_schema
     AND rel.target_table = ct.object_name) AS last_processed_date,
    EXISTS (
        SELECT 1 FROM privacy.retention_exemptions re
        WHERE re.target_schema = ct.object_schema
        AND re.target_table = ct.object_name
        AND re.is_active = TRUE
        AND (re.end_date IS NULL OR re.end_date > CURRENT_TIMESTAMP)
    ) AS has_exemptions
FROM
    classified_tables ct
ORDER BY
    ct.max_sensitivity DESC,
    ct.object_schema,
    ct.object_name;

COMMENT ON VIEW privacy.v_data_retention_compliance IS 'Overview of data retention compliance status';

-- View for Cross-Border Transfer Risk
CREATE OR REPLACE VIEW privacy.v_cross_border_transfer_risk AS
SELECT
    dt.transfer_id,
    dt.transfer_name,
    c.country_name AS destination_country,
    c.adequacy_status,
    tm.mechanism_name AS transfer_mechanism,
    dt.data_categories,
    dt.data_subject_categories,
    dt.risk_level,
    dt.risk_assessment_completed,
    CASE
        WHEN c.adequacy_status = 'adequate' THEN 'Low'
        WHEN c.adequacy_status = 'partial' AND tm.mechanism_name = 'Standard Contractual Clauses' THEN 'Medium'
        WHEN c.adequacy_status = 'inadequate' AND tm.mechanism_name = 'Standard Contractual Clauses' THEN 'High'
        WHEN tm.mechanism_name = 'Explicit Consent' THEN 'Medium'
        ELSE 'Critical'
    END AS calculated_risk,
    dt.first_transfer_date,
    dt.last_transfer_date,
    (SELECT COUNT(*) FROM privacy.transfer_logs tl WHERE tl.transfer_id = dt.transfer_id) AS transfer_count,
    (SELECT SUM(affected_users) FROM privacy.transfer_logs tl WHERE tl.transfer_id = dt.transfer_id) AS total_affected_users,
    EXISTS (
        SELECT 1 FROM privacy.transfer_impact_assessments tia
        WHERE tia.transfer_id = dt.transfer_id
        AND tia.approval_status = 'approved'
    ) AS has_approved_assessment
FROM
    privacy.data_transfers dt
JOIN
    privacy.countries c ON dt.destination_country_id = c.country_id
JOIN
    privacy.transfer_mechanisms tm ON dt.transfer_mechanism_id = tm.mechanism_id
WHERE
    dt.is_active = TRUE
ORDER BY
    CASE
        WHEN c.adequacy_status = 'adequate' THEN 1
        WHEN c.adequacy_status = 'partial' THEN 2
        ELSE 3
    END DESC,
    dt.risk_level DESC;

COMMENT ON VIEW privacy.v_cross_border_transfer_risk IS 'Risk assessment for cross-border data transfers';

-- View for Processing Activities Overview
CREATE OR REPLACE VIEW privacy.v_processing_activities_overview AS
SELECT
    pa.activity_id,
    pa.activity_name,
    pp.purpose_name,
    pp.legal_basis,
    pa.data_controller,
    pa.data_processor,
    pa.data_categories,
    pa.data_subject_categories,
    pa.involves_automated_decision,
    pa.involves_profiling,
    pa.involves_children_data,
    pa.involves_sensitive_data,
    pa.involves_systematic_monitoring,
    pa.involves_large_scale_processing,
    CASE
        WHEN pa.involves_automated_decision OR pa.involves_profiling OR pa.involves_children_data OR
             pa.involves_sensitive_data OR pa.involves_systematic_monitoring OR pa.involves_large_scale_processing
        THEN TRUE
        ELSE FALSE
    END AS requires_dpia,
    pa.dpia_conducted,
    EXISTS (
        SELECT 1 FROM privacy.data_protection_impact_assessments dpia
        WHERE dpia.activity_id = pa.activity_id
        AND dpia.approval_status = 'approved'
    ) AS has_approved_dpia,
    (SELECT STRING_AGG(table_name, ', ') FROM privacy.table_purpose_mapping tpm
     WHERE tpm.purpose_id = pp.purpose_id) AS related_tables
FROM
    privacy.processing_activities pa
JOIN
    privacy.processing_purposes pp ON pa.purpose_id = pp.purpose_id
WHERE
    pa.is_active = TRUE
ORDER BY
    CASE
        WHEN pa.involves_automated_decision OR pa.involves_profiling OR pa.involves_children_data OR
             pa.involves_sensitive_data OR pa.involves_systematic_monitoring OR pa.involves_large_scale_processing
        THEN 1
        ELSE 2
    END,
    pp.legal_basis,
    pa.activity_name;

COMMENT ON VIEW privacy.v_processing_activities_overview IS 'Overview of data processing activities and their compliance status';

-- View for GDPR Compliance Dashboard
CREATE OR REPLACE VIEW privacy.v_gdpr_compliance_dashboard AS
SELECT
    'Data Classification' AS compliance_area,
    (SELECT COUNT(*) FROM privacy.data_classifications) AS total_items,
    (SELECT COUNT(*) FROM privacy.data_classifications WHERE reviewer IS NOT NULL AND review_date IS NOT NULL) AS compliant_items,
    CASE
        WHEN (SELECT COUNT(*) FROM privacy.data_classifications) = 0 THEN 0
        ELSE ROUND(100.0 * (SELECT COUNT(*) FROM privacy.data_classifications WHERE reviewer IS NOT NULL AND review_date IS NOT NULL) /
                  (SELECT COUNT(*) FROM privacy.data_classifications))
    END AS compliance_percentage

UNION ALL

SELECT
    'Consent Management' AS compliance_area,
    (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) AS total_items,
    (SELECT COUNT(DISTINCT consent_type_id) FROM privacy.consent_records WHERE proof_data IS NOT NULL) AS compliant_items,
    CASE
        WHEN (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) = 0 THEN 0
        ELSE ROUND(100.0 * (SELECT COUNT(DISTINCT consent_type_id) FROM privacy.consent_records WHERE proof_data IS NOT NULL) /
                  (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE))
    END AS compliance_percentage

UNION ALL

SELECT
    'Data Retention' AS compliance_area,
    (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) AS total_items,
    (SELECT COUNT(*) FROM privacy.v_data_retention_compliance WHERE recently_processed = TRUE OR has_exemptions = TRUE) AS compliant_items,
    CASE
        WHEN (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) = 0 THEN 0
        ELSE ROUND(100.0 * (SELECT COUNT(*) FROM privacy.v_data_retention_compliance WHERE recently_processed = TRUE OR has_exemptions = TRUE) /
                  (SELECT COUNT(*) FROM privacy.v_data_retention_compliance))
    END AS compliance_percentage

UNION ALL

SELECT
    'Cross-Border Transfers' AS compliance_area,
    (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) AS total_items,
    (SELECT COUNT(*) FROM privacy.v_cross_border_transfer_risk WHERE has_approved_assessment = TRUE OR calculated_risk = 'Low') AS compliant_items,
    CASE
        WHEN (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) = 0 THEN 0
        ELSE ROUND(100.0 * (SELECT COUNT(*) FROM privacy.v_cross_border_transfer_risk WHERE has_approved_assessment = TRUE OR calculated_risk = 'Low') /
                  (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE))
    END AS compliance_percentage

UNION ALL

SELECT
    'Processing Activities' AS compliance_area,
    (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) AS total_items,
    (SELECT COUNT(*) FROM privacy.v_processing_activities_overview
     WHERE (requires_dpia = FALSE) OR (requires_dpia = TRUE AND has_approved_dpia = TRUE)) AS compliant_items,
    CASE
        WHEN (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) = 0 THEN 0
        ELSE ROUND(100.0 * (SELECT COUNT(*) FROM privacy.v_processing_activities_overview
                           WHERE (requires_dpia = FALSE) OR (requires_dpia = TRUE AND has_approved_dpia = TRUE)) /
                  (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE))
    END AS compliance_percentage

UNION ALL

SELECT
    'Overall GDPR Compliance' AS compliance_area,
    5 AS total_items, -- 5 compliance areas
    (
        SELECT COUNT(*) FROM (
            SELECT CASE
                WHEN (SELECT COUNT(*) FROM privacy.data_classifications) > 0 AND
                     (SELECT COUNT(*) FROM privacy.data_classifications WHERE reviewer IS NOT NULL AND review_date IS NOT NULL) /
                     (SELECT COUNT(*) FROM privacy.data_classifications) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) > 0 AND
                     (SELECT COUNT(DISTINCT consent_type_id) FROM privacy.consent_records WHERE proof_data IS NOT NULL) /
                     (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_data_retention_compliance WHERE recently_processed = TRUE OR has_exemptions = TRUE) /
                     (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_cross_border_transfer_risk WHERE has_approved_assessment = TRUE OR calculated_risk = 'Low') /
                     (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_processing_activities_overview
                      WHERE (requires_dpia = FALSE) OR (requires_dpia = TRUE AND has_approved_dpia = TRUE)) /
                     (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) >= 0.8
                THEN 1 ELSE 0 END AS compliant_areas
            FROM (SELECT 1) dummy
        ) subquery
    ) AS compliant_items,
    (
        SELECT ROUND(20.0 * COUNT(*)) FROM (
            SELECT CASE
                WHEN (SELECT COUNT(*) FROM privacy.data_classifications) > 0 AND
                     (SELECT COUNT(*) FROM privacy.data_classifications WHERE reviewer IS NOT NULL AND review_date IS NOT NULL) /
                     (SELECT COUNT(*) FROM privacy.data_classifications) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) > 0 AND
                     (SELECT COUNT(DISTINCT consent_type_id) FROM privacy.consent_records WHERE proof_data IS NOT NULL) /
                     (SELECT COUNT(*) FROM privacy.consent_types WHERE requires_proof = TRUE) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_data_retention_compliance WHERE recently_processed = TRUE OR has_exemptions = TRUE) /
                     (SELECT COUNT(*) FROM privacy.v_data_retention_compliance) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_cross_border_transfer_risk WHERE has_approved_assessment = TRUE OR calculated_risk = 'Low') /
                     (SELECT COUNT(*) FROM privacy.data_transfers WHERE is_active = TRUE) >= 0.8
                THEN 1 ELSE 0 END +

                CASE
                WHEN (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) > 0 AND
                     (SELECT COUNT(*) FROM privacy.v_processing_activities_overview
                      WHERE (requires_dpia = FALSE) OR (requires_dpia = TRUE AND has_approved_dpia = TRUE)) /
                     (SELECT COUNT(*) FROM privacy.processing_activities WHERE is_active = TRUE) >= 0.8
                THEN 1 ELSE 0 END AS compliant_areas
            FROM (SELECT 1) dummy
        ) subquery
    ) AS compliance_percentage;

COMMENT ON VIEW privacy.v_gdpr_compliance_dashboard IS 'Dashboard showing overall GDPR compliance status';

-- Step 8: Create Initialization Function

-- Function to initialize the privacy framework
CREATE OR REPLACE FUNCTION privacy.initialize_framework(
    p_auto_classify BOOLEAN DEFAULT TRUE
) RETURNS TEXT AS $$
DECLARE
    v_classified_count INTEGER := 0;
BEGIN
    -- Auto-classify columns if requested
    IF p_auto_classify THEN
        v_classified_count := privacy.auto_classify_columns();
    END IF;

    -- Map common tables to purposes
    PERFORM privacy.map_table_to_purpose('public', 'Users', 'User Account Management', 'Core user data for account management');
    PERFORM privacy.map_table_to_purpose('public', 'UserRoles', 'User Account Management', 'User role assignments for access control');
    PERFORM privacy.map_table_to_purpose('public', 'UserActivityLog', 'Security Monitoring', 'Audit trail of user activities');

    -- Document common processing activities
    PERFORM privacy.document_processing_activity(
        'User Registration and Authentication',
        'Processing of user data for account creation and authentication',
        'User Account Management',
        'Our Organization',
        'Our Organization',
        ARRAY['User Management System'],
        ARRAY['Personal Data', 'Authentication Data'],
        ARRAY['Customers', 'Employees'],
        ARRAY['Internal Staff'],
        FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
        'Encryption of passwords, secure authentication protocols',
        'Access controls, staff training'
    );

    -- Return initialization status
    RETURN format('Privacy framework initialized successfully. Auto-classified %s columns.', v_classified_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION privacy.initialize_framework IS 'Initializes the privacy framework with default settings';

-- Step 9: Create Documentation

COMMENT ON SCHEMA privacy IS 'Comprehensive GDPR and privacy management framework';

-- Add comments to all objects
DO $$
BEGIN
    EXECUTE 'COMMENT ON TABLE privacy.data_classification_categories IS ''Categories for classifying data based on privacy sensitivity''';
    EXECUTE 'COMMENT ON TABLE privacy.data_classifications IS ''Classification of database objects according to data privacy categories''';
    EXECUTE 'COMMENT ON TABLE privacy.classification_audit_log IS ''Audit trail for changes to data classifications''';

    EXECUTE 'COMMENT ON TABLE privacy.retention_policies IS ''Policies defining data retention periods and handling''';
    EXECUTE 'COMMENT ON TABLE privacy.retention_execution_log IS ''Log of data retention policy executions''';
    EXECUTE 'COMMENT ON TABLE privacy.retention_exemptions IS ''Exemptions from automatic data retention policies''';

    EXECUTE 'COMMENT ON TABLE privacy.consent_types IS ''Types of consent that can be collected from data subjects''';
    EXECUTE 'COMMENT ON TABLE privacy.consent_records IS ''Records of user consent for various data processing purposes''';
    EXECUTE 'COMMENT ON TABLE privacy.consent_version_history IS ''Historical versions of consent legal text and terms''';
    EXECUTE 'COMMENT ON TABLE privacy.consent_dependencies IS ''Dependencies between different types of consent''';

    EXECUTE 'COMMENT ON TABLE privacy.countries IS ''Countries with their data protection adequacy status''';
    EXECUTE 'COMMENT ON TABLE privacy.transfer_mechanisms IS ''Legal mechanisms for cross-border data transfers''';
    EXECUTE 'COMMENT ON TABLE privacy.data_transfers IS ''Registry of cross-border data transfers''';
    EXECUTE 'COMMENT ON TABLE privacy.transfer_logs IS ''Detailed logs of individual data transfer events''';
    EXECUTE 'COMMENT ON TABLE privacy.transfer_impact_assessments IS ''Impact assessments for high-risk data transfers''';

    EXECUTE 'COMMENT ON TABLE privacy.processing_purposes IS ''Documented purposes for data processing activities''';
    EXECUTE 'COMMENT ON TABLE privacy.processing_activities IS ''Documented data processing activities''';
    EXECUTE 'COMMENT ON TABLE privacy.data_protection_impact_assessments IS ''Data Protection Impact Assessments for high-risk processing activities''';
    EXECUTE 'COMMENT ON TABLE privacy.table_purpose_mapping IS ''Maps database tables to their processing purposes''';

    EXECUTE 'COMMENT ON VIEW privacy.v_data_classification_overview IS ''Overview of data classifications across the database''';
    EXECUTE 'COMMENT ON VIEW privacy.v_high_risk_data_elements IS ''High-risk data elements requiring special protection''';
    EXECUTE 'COMMENT ON VIEW privacy.v_user_consent_status IS ''Current consent status for all users''';
    EXECUTE 'COMMENT ON VIEW privacy.v_data_retention_compliance IS ''Overview of data retention compliance status''';
    EXECUTE 'COMMENT ON VIEW privacy.v_cross_border_transfer_risk IS ''Risk assessment for cross-border data transfers''';
    EXECUTE 'COMMENT ON VIEW privacy.v_processing_activities_overview IS ''Overview of data processing activities and their compliance status''';
    EXECUTE 'COMMENT ON VIEW privacy.v_gdpr_compliance_dashboard IS ''Dashboard showing overall GDPR compliance status''';
END$$;

-- Initialize the framework
SELECT privacy.initialize_framework(TRUE);

-- PostgreSQL Data Quality Management Framework - Part 1: Validation
-- This implementation provides:
-- 1. Comprehensive data validation frameworks

-- Step 1: Create Data Quality Schema
CREATE SCHEMA IF NOT EXISTS data_quality;
COMMENT ON SCHEMA data_quality IS 'Schema for data quality management features';

-- Step 2: Create Core Data Quality Tables

-- Validation Types Table
CREATE TABLE data_quality.dq_validation_types (
    validation_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    implementation_function VARCHAR(100) NOT NULL,
    required_parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality.dq_validation_types IS 'Defines the types of data quality validations available';

-- Insert standard validation types
INSERT INTO data_quality.dq_validation_types (type_name, description, implementation_function, required_parameters)
VALUES
('completeness', 'Checks for NULL or empty values', 'data_quality.validate_completeness', '{"check_empty_string": true}'),
('uniqueness', 'Checks for duplicate values in a column', 'data_quality.validate_uniqueness', '{}'),
('format', 'Checks if values match a specific format (e.g., regex)', 'data_quality.validate_format', '{"pattern": "regex_pattern"}'),
('range', 'Checks if numeric or date values fall within a specified range', 'data_quality.validate_range', '{"min_value": null, "max_value": null}'),
('lookup', 'Checks if values exist in a reference list or table', 'data_quality.validate_lookup', '{"lookup_table": "schema.table", "lookup_column": "column"}'),
('consistency', 'Checks consistency between related columns', 'data_quality.validate_consistency', '{"related_column": "column_name", "consistency_rule": "SQL expression"}'),
('timeliness', 'Checks if date values are recent or within expected timeframes', 'data_quality.validate_timeliness', '{"max_age_days": 30}'),
('length', 'Checks if string length is within specified limits', 'data_quality.validate_length', '{"min_length": 0, "max_length": 255}');

-- Data Quality Rules Table
CREATE TABLE data_quality.dq_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255) NOT NULL,
    validation_type_id INTEGER NOT NULL REFERENCES data_quality.dq_validation_types(validation_type_id),
    rule_parameters JSONB,
    severity_level VARCHAR(20) DEFAULT 'warning' CHECK (severity_level IN ('info', 'warning', 'error', 'critical')),
    error_message_template TEXT,
    remediation_suggestion TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    updated_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dq_rules_target ON data_quality.dq_rules (target_schema, target_table, target_column);
CREATE INDEX idx_dq_rules_type ON data_quality.dq_rules (validation_type_id);
CREATE INDEX idx_dq_rules_active ON data_quality.dq_rules (is_active);

COMMENT ON TABLE data_quality.dq_rules IS 'Defines specific data quality rules for database columns';

-- Data Quality Rule Sets Table
CREATE TABLE data_quality.dq_rule_sets (
    set_id SERIAL PRIMARY KEY,
    set_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    schedule_cron VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dq_rule_sets_active ON data_quality.dq_rule_sets (is_active);

COMMENT ON TABLE data_quality.dq_rule_sets IS 'Groups data quality rules for execution';

-- Rule Set Membership Table
CREATE TABLE data_quality.dq_rule_set_membership (
    membership_id SERIAL PRIMARY KEY,
    set_id INTEGER NOT NULL REFERENCES data_quality.dq_rule_sets(set_id),
    rule_id INTEGER NOT NULL REFERENCES data_quality.dq_rules(rule_id),
    execution_order INTEGER DEFAULT 0,
    CONSTRAINT unique_rule_set_membership UNIQUE (set_id, rule_id)
);

CREATE INDEX idx_dq_rule_set_membership_set ON data_quality.dq_rule_set_membership (set_id);
CREATE INDEX idx_dq_rule_set_membership_rule ON data_quality.dq_rule_set_membership (rule_id);

COMMENT ON TABLE data_quality.dq_rule_set_membership IS 'Maps rules to rule sets';

-- Data Quality Validation Log Table
CREATE TABLE data_quality.dq_validation_log (
    log_id BIGSERIAL PRIMARY KEY,
    execution_id UUID NOT NULL,
    rule_id INTEGER NOT NULL REFERENCES data_quality.dq_rules(rule_id),
    set_id INTEGER REFERENCES data_quality.dq_rule_sets(set_id),
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255) NOT NULL,
    validation_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('passed', 'failed', 'error', 'skipped')),
    total_rows_checked BIGINT,
    failed_rows_count BIGINT,
    failed_rows_percentage NUMERIC(5, 2),
    error_message TEXT,
    sample_failed_records JSONB,
    execution_duration INTERVAL,
    executed_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dq_validation_log_execution ON data_quality.dq_validation_log (execution_id);
CREATE INDEX idx_dq_validation_log_rule ON data_quality.dq_validation_log (rule_id);
CREATE INDEX idx_dq_validation_log_set ON data_quality.dq_validation_log (set_id);
CREATE INDEX idx_dq_validation_log_timestamp ON data_quality.dq_validation_log (execution_timestamp);
CREATE INDEX idx_dq_validation_log_status ON data_quality.dq_validation_log (status);
CREATE INDEX idx_dq_validation_log_target ON data_quality.dq_validation_log (target_schema, target_table, target_column);

COMMENT ON TABLE data_quality.dq_validation_log IS 'Logs the results of data quality validation executions';

-- Step 3: Create Core Functions for Validation Framework

-- Function to define a new data quality rule
CREATE OR REPLACE FUNCTION data_quality.define_dq_rule(
    p_rule_name VARCHAR(100),
    p_description TEXT,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_validation_type VARCHAR(50),
    p_rule_parameters JSONB DEFAULT '{}',
    p_severity_level VARCHAR(20) DEFAULT 'warning',
    p_error_message_template TEXT DEFAULT NULL,
    p_remediation_suggestion TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT TRUE
) RETURNS INTEGER AS $$
DECLARE
    v_validation_type_id INTEGER;
    v_rule_id INTEGER;
BEGIN
    -- Get validation type ID
    SELECT validation_type_id INTO v_validation_type_id
    FROM data_quality.dq_validation_types
    WHERE type_name = p_validation_type;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Validation type "%" not found.', p_validation_type;
    END IF;

    -- Insert the rule
    INSERT INTO data_quality.dq_rules (
        rule_name, description, target_schema, target_table, target_column,
        validation_type_id, rule_parameters, severity_level,
        error_message_template, remediation_suggestion, is_active
    ) VALUES (
        p_rule_name, p_description, p_target_schema, p_target_table, p_target_column,
        v_validation_type_id, p_rule_parameters, p_severity_level,
        p_error_message_template, p_remediation_suggestion, p_is_active
    )
    ON CONFLICT (rule_name) DO UPDATE SET
        description = p_description,
        target_schema = p_target_schema,
        target_table = p_target_table,
        target_column = p_target_column,
        validation_type_id = v_validation_type_id,
        rule_parameters = p_rule_parameters,
        severity_level = p_severity_level,
        error_message_template = p_error_message_template,
        remediation_suggestion = p_remediation_suggestion,
        is_active = p_is_active,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = CURRENT_USER
    RETURNING rule_id INTO v_rule_id;

    RETURN v_rule_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_quality.define_dq_rule IS 'Defines or updates a data quality rule';

-- Function to log validation results
CREATE OR REPLACE FUNCTION data_quality.log_dq_validation(
    p_execution_id UUID,
    p_rule_id INTEGER,
    p_set_id INTEGER,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_validation_type VARCHAR(50),
    p_status VARCHAR(20),
    p_total_rows_checked BIGINT,
    p_failed_rows_count BIGINT,
    p_error_message TEXT,
    p_sample_failed_records JSONB,
    p_execution_duration INTERVAL
) RETURNS BIGINT AS $$
DECLARE
    v_log_id BIGINT;
    v_failed_percentage NUMERIC(5, 2);
BEGIN
    -- Calculate failed percentage
    IF p_total_rows_checked > 0 THEN
        v_failed_percentage := ROUND((p_failed_rows_count::NUMERIC * 100.0) / p_total_rows_checked, 2);
    ELSE
        v_failed_percentage := 0.00;
    END IF;

    -- Insert log entry
    INSERT INTO data_quality.dq_validation_log (
        execution_id, rule_id, set_id, target_schema, target_table, target_column,
        validation_type, status, total_rows_checked, failed_rows_count,
        failed_rows_percentage, error_message, sample_failed_records, execution_duration
    ) VALUES (
        p_execution_id, p_rule_id, p_set_id, p_target_schema, p_target_table, p_target_column,
        p_validation_type, p_status, p_total_rows_checked, p_failed_rows_count,
        v_failed_percentage, p_error_message, p_sample_failed_records, p_execution_duration
    ) RETURNING log_id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.log_dq_validation IS 'Logs the result of a single data quality rule execution';

-- Placeholder functions for specific validation types (to be implemented later)
CREATE OR REPLACE FUNCTION data_quality.validate_completeness(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_uniqueness(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_format(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_range(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_lookup(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_consistency(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_timeliness(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION data_quality.validate_length(p_rule data_quality.dq_rules, p_execution_id UUID) RETURNS JSONB AS $$
BEGIN RETURN '{"status": "skipped", "message": "Implementation pending"}'; END;
$$ LANGUAGE plpgsql;

-- Main function to execute a single data quality rule
CREATE OR REPLACE FUNCTION data_quality.execute_dq_rule(
    p_rule_id INTEGER,
    p_execution_id UUID,
    p_set_id INTEGER DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    v_rule data_quality.dq_rules%ROWTYPE;
    v_validation_type data_quality.dq_validation_types%ROWTYPE;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration INTERVAL;
    v_result JSONB;
    v_status VARCHAR(20);
    v_total_rows BIGINT;
    v_failed_rows BIGINT;
    v_error_message TEXT;
    v_sample_failed JSONB;
    v_log_id BIGINT;
    v_sql TEXT;
BEGIN
    v_start_time := clock_timestamp();

    -- Get rule details
    SELECT * INTO v_rule FROM data_quality.dq_rules WHERE rule_id = p_rule_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE NOTICE 'Rule ID % not found or inactive, skipping.', p_rule_id;
        RETURN NULL;
    END IF;

    -- Get validation type details
    SELECT * INTO v_validation_type FROM data_quality.dq_validation_types WHERE validation_type_id = v_rule.validation_type_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Validation type ID % for rule % not found.', v_rule.validation_type_id, p_rule_id;
    END IF;

    -- Execute the specific validation function
    BEGIN
        v_sql := format('SELECT %I.%I($1, $2);', 'data_quality', v_validation_type.implementation_function);
        EXECUTE v_sql INTO v_result USING v_rule, p_execution_id;

        -- Parse result
        v_status := v_result->>'status';
        v_total_rows := (v_result->>'total_rows_checked')::BIGINT;
        v_failed_rows := (v_result->>'failed_rows_count')::BIGINT;
        v_error_message := v_result->>'error_message';
        v_sample_failed := v_result->'sample_failed_records';

    EXCEPTION WHEN OTHERS THEN
        v_status := 'error';
        v_total_rows := 0;
        v_failed_rows := 0;
        v_error_message := SQLERRM;
        v_sample_failed := NULL;
        RAISE WARNING 'Error executing rule % (%): %', p_rule_id, v_rule.rule_name, SQLERRM;
    END;

    v_end_time := clock_timestamp();
    v_duration := v_end_time - v_start_time;

    -- Log the result
    v_log_id := data_quality.log_dq_validation(
        p_execution_id,
        p_rule_id,
        p_set_id,
        v_rule.target_schema,
        v_rule.target_table,
        v_rule.target_column,
        v_validation_type.type_name,
        v_status,
        v_total_rows,
        v_failed_rows,
        v_error_message,
        v_sample_failed,
        v_duration
    );

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.execute_dq_rule IS 'Executes a single data quality rule and logs the result';

-- Function to execute a data quality rule set
CREATE OR REPLACE FUNCTION data_quality.execute_dq_rule_set(
    p_set_id INTEGER
) RETURNS UUID AS $$
DECLARE
    v_rule_membership RECORD;
    v_execution_id UUID := uuid_generate_v4();
    v_set_name TEXT;
BEGIN
    -- Get rule set name
    SELECT set_name INTO v_set_name FROM data_quality.dq_rule_sets WHERE set_id = p_set_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rule set ID % not found or inactive.', p_set_id;
    END IF;

    RAISE NOTICE 'Starting execution of rule set % (ID: %), Execution ID: %', v_set_name, p_set_id, v_execution_id;

    -- Execute each rule in the set
    FOR v_rule_membership IN
        SELECT rsm.rule_id
        FROM data_quality.dq_rule_set_membership rsm
        JOIN data_quality.dq_rules r ON rsm.rule_id = r.rule_id
        WHERE rsm.set_id = p_set_id AND r.is_active = TRUE
        ORDER BY rsm.execution_order
    LOOP
        PERFORM data_quality.execute_dq_rule(v_rule_membership.rule_id, v_execution_id, p_set_id);
    END LOOP;

    RAISE NOTICE 'Finished execution of rule set % (ID: %), Execution ID: %', v_set_name, p_set_id, v_execution_id;

    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.execute_dq_rule_set IS 'Executes all active rules within a specified rule set';

-- Step 4: Implement Specific Validation Functions (Example: Completeness)

CREATE OR REPLACE FUNCTION data_quality.validate_completeness(p_rule data_quality.dq_rules, p_execution_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_total_rows BIGINT;
    v_failed_rows BIGINT;
    v_sample_failed JSONB;
    v_pk_columns TEXT[];
    v_pk_select TEXT;
    v_check_empty_string BOOLEAN;
    v_status VARCHAR(20);
    v_error_message TEXT := NULL;
BEGIN
    -- Get primary key columns for sampling
    v_pk_columns := audit.get_primary_key_columns(p_rule.target_schema, p_rule.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        v_pk_select := 'NULL::TEXT AS pk'; -- No PK, cannot sample specific rows
    ELSE
        v_pk_select := format('array_to_string(ARRAY[%s], ''|'') AS pk', array_to_string(v_pk_columns, ','));
    END IF;

    -- Check parameters
    v_check_empty_string := COALESCE((p_rule.rule_parameters->>'check_empty_string')::BOOLEAN, TRUE);

    -- Build SQL to count total and failed rows
    v_sql := format(
        'WITH base AS (SELECT * FROM %I.%I),
         total AS (SELECT COUNT(*) AS cnt FROM base),
         failed AS (SELECT COUNT(*) AS cnt FROM base WHERE %I IS NULL %s)
         SELECT t.cnt AS total_rows, f.cnt AS failed_rows
         FROM total t, failed f;',
        p_rule.target_schema, p_rule.target_table,
        p_rule.target_column,
        CASE WHEN v_check_empty_string THEN format('OR %I::TEXT = ''''', p_rule.target_column) ELSE '' END
    );

    EXECUTE v_sql INTO v_total_rows, v_failed_rows;

    -- Get sample failed records if any
    IF v_failed_rows > 0 THEN
        v_sql := format(
            'SELECT jsonb_agg(t) FROM (
                SELECT %s, %I AS failed_value
                FROM %I.%I
                WHERE %I IS NULL %s
                LIMIT 5
            ) t;',
            v_pk_select,
            p_rule.target_column,
            p_rule.target_schema, p_rule.target_table,
            p_rule.target_column,
            CASE WHEN v_check_empty_string THEN format('OR %I::TEXT = ''''', p_rule.target_column) ELSE '' END
        );
        EXECUTE v_sql INTO v_sample_failed;
    ELSE
        v_sample_failed := '[]'::JSONB;
    END IF;

    -- Determine status
    IF v_failed_rows = 0 THEN
        v_status := 'passed';
    ELSE
        v_status := 'failed';
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'total_rows_checked', v_total_rows,
        'failed_rows_count', v_failed_rows,
        'error_message', v_error_message,
        'sample_failed_records', v_sample_failed
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'error',
        'error_message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.validate_completeness IS 'Implements the completeness validation check';

-- Step 5: Create Views for Reporting

-- View for Latest Validation Results
CREATE OR REPLACE VIEW data_quality.v_latest_validation_results AS
WITH ranked_logs AS (
    SELECT
        log_id,
        execution_id,
        rule_id,
        set_id,
        execution_timestamp,
        target_schema,
        target_table,
        target_column,
        validation_type,
        status,
        total_rows_checked,
        failed_rows_count,
        failed_rows_percentage,
        error_message,
        sample_failed_records,
        execution_duration,
        executed_by,
        ROW_NUMBER() OVER (PARTITION BY rule_id ORDER BY execution_timestamp DESC) as rn
    FROM data_quality.dq_validation_log
)
SELECT
    rl.log_id,
    rl.execution_id,
    rl.rule_id,
    r.rule_name,
    rl.set_id,
    rs.set_name,
    rl.execution_timestamp,
    rl.target_schema,
    rl.target_table,
    rl.target_column,
    rl.validation_type,
    rl.status,
    r.severity_level,
    rl.total_rows_checked,
    rl.failed_rows_count,
    rl.failed_rows_percentage,
    rl.error_message,
    rl.sample_failed_records,
    rl.execution_duration,
    rl.executed_by
FROM ranked_logs rl
JOIN data_quality.dq_rules r ON rl.rule_id = r.rule_id
LEFT JOIN data_quality.dq_rule_sets rs ON rl.set_id = rs.set_id
WHERE rl.rn = 1;

COMMENT ON VIEW data_quality.v_latest_validation_results IS 'Shows the latest result for each data quality rule';

-- View for Validation Summary by Table
CREATE OR REPLACE VIEW data_quality.v_validation_summary_by_table AS
SELECT
    target_schema,
    target_table,
    COUNT(*) AS total_rules,
    COUNT(*) FILTER (WHERE status = 'passed') AS passed_rules,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_rules,
    COUNT(*) FILTER (WHERE status = 'error') AS error_rules,
    MAX(execution_timestamp) AS last_validation_time,
    AVG(failed_rows_percentage) FILTER (WHERE status = 'failed') AS avg_failure_percentage,
    SUM(failed_rows_count) AS total_failed_rows
FROM data_quality.v_latest_validation_results
GROUP BY target_schema, target_table;

COMMENT ON VIEW data_quality.v_validation_summary_by_table IS 'Summarizes the latest validation results grouped by table';

-- View for Validation History
CREATE OR REPLACE VIEW data_quality.v_validation_history AS
SELECT
    l.log_id,
    l.execution_id,
    l.rule_id,
    r.rule_name,
    l.set_id,
    rs.set_name,
    l.execution_timestamp,
    l.target_schema,
    l.target_table,
    l.target_column,
    l.validation_type,
    l.status,
    l.failed_rows_count,
    l.failed_rows_percentage,
    l.execution_duration
FROM data_quality.dq_validation_log l
JOIN data_quality.dq_rules r ON l.rule_id = r.rule_id
LEFT JOIN data_quality.dq_rule_sets rs ON l.set_id = rs.set_id
ORDER BY l.execution_timestamp DESC;

COMMENT ON VIEW data_quality.v_validation_history IS 'Provides a historical view of all validation executions';

-- Step 6: Initialize Framework (Example Rules)

-- Example: Rule for Users table - email completeness
SELECT data_quality.define_dq_rule(
    'Users Email Completeness',
    'Ensure email address is not null or empty in Users table',
    'public',
    'Users',
    'email',
    'completeness',
    '{"check_empty_string": true}',
    'error',
    'User email cannot be empty.',
    'Investigate user record and populate email address.'
);

-- Example: Rule for Users table - username uniqueness
-- Note: Requires implementation of validate_uniqueness function
-- SELECT data_quality.define_dq_rule(
--     'Users Username Uniqueness',
--     'Ensure username is unique in Users table',
--     'public',
--     'Users',
--     'username',
--     'uniqueness',
--     '{}',
--     'critical',
--     'Username must be unique.',
--     'Identify duplicate usernames and resolve conflicts.'
-- );

-- Example: Rule for VehicleInfo table - VIN format
-- Note: Requires implementation of validate_format function
-- SELECT data_quality.define_dq_rule(
--     'VehicleInfo VIN Format',
--     'Ensure VIN follows standard format (17 alphanumeric chars)',
--     'public',
--     'VehicleInfo',
--     'vin',
--     'format',
--     '{"pattern": "^[A-HJ-NPR-Z0-9]{17}$"}',
--     'error',
--     'VIN format is invalid.',
--     'Correct the VIN based on vehicle documentation.'
-- );

-- Create an example rule set
INSERT INTO data_quality.dq_rule_sets (set_name, description)
VALUES ('Core User Data Quality', 'Basic quality checks for the Users table');

-- Add rules to the set
INSERT INTO data_quality.dq_rule_set_membership (set_id, rule_id)
SELECT
    (SELECT set_id FROM data_quality.dq_rule_sets WHERE set_name = 'Core User Data Quality'),
    rule_id
FROM data_quality.dq_rules
WHERE rule_name IN (
    'Users Email Completeness'
    -- 'Users Username Uniqueness' -- Add when implemented
);

-- Execute the example rule set
-- SELECT data_quality.execute_dq_rule_set((SELECT set_id FROM data_quality.dq_rule_sets WHERE set_name = 'Core User Data Quality'));

-- Add documentation comments
COMMENT ON SCHEMA data_quality IS 'Schema for comprehensive data quality management, including validation, scoring, cleansing, and monitoring';

-- PostgreSQL Data Quality Management Framework - Part 2: Scoring
-- This implementation provides:
-- 2. Data quality scoring mechanisms

-- Step 1: Create Data Quality Scoring Tables

-- Dimension Weights Table
CREATE TABLE data_quality.dq_dimensions (
    dimension_id SERIAL PRIMARY KEY,
    dimension_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    default_weight NUMERIC(5, 2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality.dq_dimensions IS 'Defines data quality dimensions and their weights for scoring';

-- Insert standard data quality dimensions
INSERT INTO data_quality.dq_dimensions (dimension_name, description, default_weight)
VALUES
('Completeness', 'Measure of the presence of data (non-null, non-empty values)', 1.0),
('Accuracy', 'Measure of how well data reflects the real-world entity', 1.0),
('Consistency', 'Measure of how well data agrees with itself across the database', 0.8),
('Timeliness', 'Measure of data currency and freshness', 0.7),
('Uniqueness', 'Measure of duplicate-free data', 0.9),
('Validity', 'Measure of data conforming to defined formats and ranges', 0.8),
('Integrity', 'Measure of data adhering to relational constraints', 0.9);

-- Mapping between validation types and dimensions
CREATE TABLE data_quality.dq_validation_dimension_map (
    map_id SERIAL PRIMARY KEY,
    validation_type_id INTEGER NOT NULL REFERENCES data_quality.dq_validation_types(validation_type_id),
    dimension_id INTEGER NOT NULL REFERENCES data_quality.dq_dimensions(dimension_id),
    weight_multiplier NUMERIC(5, 2) DEFAULT 1.0,
    CONSTRAINT unique_validation_dimension UNIQUE (validation_type_id, dimension_id)
);

COMMENT ON TABLE data_quality.dq_validation_dimension_map IS 'Maps validation types to quality dimensions for scoring';

-- Insert standard mappings
INSERT INTO data_quality.dq_validation_dimension_map (validation_type_id, dimension_id, weight_multiplier)
SELECT vt.validation_type_id, d.dimension_id, 1.0
FROM data_quality.dq_validation_types vt, data_quality.dq_dimensions d
WHERE
    (vt.type_name = 'completeness' AND d.dimension_name = 'Completeness') OR
    (vt.type_name = 'uniqueness' AND d.dimension_name = 'Uniqueness') OR
    (vt.type_name = 'format' AND d.dimension_name = 'Validity') OR
    (vt.type_name = 'range' AND d.dimension_name = 'Validity') OR
    (vt.type_name = 'lookup' AND d.dimension_name = 'Accuracy') OR
    (vt.type_name = 'consistency' AND d.dimension_name = 'Consistency') OR
    (vt.type_name = 'timeliness' AND d.dimension_name = 'Timeliness') OR
    (vt.type_name = 'length' AND d.dimension_name = 'Validity');

-- Table for custom dimension weights by table/column
CREATE TABLE data_quality.dq_custom_dimension_weights (
    weight_id SERIAL PRIMARY KEY,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255),
    dimension_id INTEGER NOT NULL REFERENCES data_quality.dq_dimensions(dimension_id),
    weight NUMERIC(5, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_custom_weight UNIQUE (target_schema, target_table, target_column, dimension_id)
);

CREATE INDEX idx_dq_custom_weights_target ON data_quality.dq_custom_dimension_weights (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_custom_weights_dimension ON data_quality.dq_custom_dimension_weights (dimension_id);

COMMENT ON TABLE data_quality.dq_custom_dimension_weights IS 'Custom weights for dimensions by table/column';

-- Quality Score Thresholds Table
CREATE TABLE data_quality.dq_score_thresholds (
    threshold_id SERIAL PRIMARY KEY,
    score_category VARCHAR(20) NOT NULL,
    min_score NUMERIC(5, 2) NOT NULL,
    max_score NUMERIC(5, 2) NOT NULL,
    color_code VARCHAR(7) NOT NULL,
    description TEXT,
    CONSTRAINT valid_score_range CHECK (min_score >= 0 AND max_score <= 100 AND min_score < max_score),
    CONSTRAINT unique_score_range UNIQUE (min_score, max_score)
);

COMMENT ON TABLE data_quality.dq_score_thresholds IS 'Defines thresholds for quality score categories';

-- Insert standard score thresholds
INSERT INTO data_quality.dq_score_thresholds (score_category, min_score, max_score, color_code, description)
VALUES
('Critical', 0, 60, '#FF0000', 'Critical data quality issues requiring immediate attention'),
('Poor', 60, 75, '#FFA500', 'Significant data quality issues needing remediation'),
('Fair', 75, 90, '#FFFF00', 'Some data quality issues that should be addressed'),
('Good', 90, 97, '#00FF00', 'Minor data quality issues'),
('Excellent', 97, 100, '#008000', 'Excellent data quality with minimal issues');

-- Quality Scores Table
CREATE TABLE data_quality.dq_quality_scores (
    score_id SERIAL PRIMARY KEY,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255),
    dimension_id INTEGER REFERENCES data_quality.dq_dimensions(dimension_id),
    score NUMERIC(5, 2) NOT NULL CHECK (score >= 0 AND score <= 100),
    score_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_id UUID,
    calculation_details JSONB,
    CONSTRAINT unique_current_score UNIQUE (target_schema, target_table, target_column, dimension_id)
);

CREATE INDEX idx_dq_quality_scores_target ON data_quality.dq_quality_scores (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_quality_scores_dimension ON data_quality.dq_quality_scores (dimension_id);
CREATE INDEX idx_dq_quality_scores_timestamp ON data_quality.dq_quality_scores (score_timestamp);
CREATE INDEX idx_dq_quality_scores_execution ON data_quality.dq_quality_scores (execution_id);

COMMENT ON TABLE data_quality.dq_quality_scores IS 'Current quality scores by table/column and dimension';

-- Quality Score History Table
CREATE TABLE data_quality.dq_quality_score_history (
    history_id SERIAL PRIMARY KEY,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255),
    dimension_id INTEGER REFERENCES data_quality.dq_dimensions(dimension_id),
    score NUMERIC(5, 2) NOT NULL CHECK (score >= 0 AND score <= 100),
    score_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_id UUID,
    calculation_details JSONB
);

CREATE INDEX idx_dq_quality_score_history_target ON data_quality.dq_quality_score_history (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_quality_score_history_dimension ON data_quality.dq_quality_score_history (dimension_id);
CREATE INDEX idx_dq_quality_score_history_timestamp ON data_quality.dq_quality_score_history (score_timestamp);

COMMENT ON TABLE data_quality.dq_quality_score_history IS 'Historical quality scores for trend analysis';

-- Step 2: Create Functions for Quality Scoring

-- Function to get dimension weight for a table/column
CREATE OR REPLACE FUNCTION data_quality.get_dimension_weight(
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_dimension_id INTEGER
) RETURNS NUMERIC(5, 2) AS $$
DECLARE
    v_weight NUMERIC(5, 2);
BEGIN
    -- Try to get column-specific weight
    SELECT weight INTO v_weight
    FROM data_quality.dq_custom_dimension_weights
    WHERE target_schema = p_target_schema
    AND target_table = p_target_table
    AND target_column = p_target_column
    AND dimension_id = p_dimension_id;

    IF FOUND THEN
        RETURN v_weight;
    END IF;

    -- Try to get table-level weight
    SELECT weight INTO v_weight
    FROM data_quality.dq_custom_dimension_weights
    WHERE target_schema = p_target_schema
    AND target_table = p_target_table
    AND target_column IS NULL
    AND dimension_id = p_dimension_id;

    IF FOUND THEN
        RETURN v_weight;
    END IF;

    -- Use default weight from dimensions table
    SELECT default_weight INTO v_weight
    FROM data_quality.dq_dimensions
    WHERE dimension_id = p_dimension_id;

    RETURN v_weight;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.get_dimension_weight IS 'Gets the appropriate weight for a dimension based on hierarchy of specificity';

-- Function to calculate quality score for a dimension based on validation results
CREATE OR REPLACE FUNCTION data_quality.calculate_dimension_score(
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_dimension_id INTEGER,
    p_execution_id UUID
) RETURNS NUMERIC(5, 2) AS $$
DECLARE
    v_score NUMERIC(5, 2);
    v_total_weight NUMERIC(5, 2) := 0;
    v_weighted_sum NUMERIC(5, 2) := 0;
    v_validation_record RECORD;
    v_rule_weight NUMERIC(5, 2);
    v_rule_score NUMERIC(5, 2);
    v_calculation_details JSONB := '[]'::JSONB;
BEGIN
    -- Get all validation results for this column and dimension
    FOR v_validation_record IN
        SELECT
            vl.rule_id,
            vl.status,
            vl.total_rows_checked,
            vl.failed_rows_count,
            vl.failed_rows_percentage,
            r.severity_level,
            vdm.weight_multiplier
        FROM data_quality.dq_validation_log vl
        JOIN data_quality.dq_rules r ON vl.rule_id = r.rule_id
        JOIN data_quality.dq_validation_types vt ON r.validation_type_id = vt.validation_type_id
        JOIN data_quality.dq_validation_dimension_map vdm ON vt.validation_type_id = vdm.validation_type_id
        WHERE vl.execution_id = p_execution_id
        AND vl.target_schema = p_target_schema
        AND vl.target_table = p_target_table
        AND vl.target_column = p_target_column
        AND vdm.dimension_id = p_dimension_id
    LOOP
        -- Calculate rule weight based on severity
        CASE v_validation_record.severity_level
            WHEN 'info' THEN v_rule_weight := 0.5;
            WHEN 'warning' THEN v_rule_weight := 1.0;
            WHEN 'error' THEN v_rule_weight := 2.0;
            WHEN 'critical' THEN v_rule_weight := 3.0;
            ELSE v_rule_weight := 1.0;
        END CASE;

        -- Apply dimension weight multiplier
        v_rule_weight := v_rule_weight * v_validation_record.weight_multiplier;

        -- Calculate rule score (100 - percentage of failed rows)
        IF v_validation_record.status = 'passed' THEN
            v_rule_score := 100.0;
        ELSIF v_validation_record.status = 'failed' THEN
            v_rule_score := 100.0 - v_validation_record.failed_rows_percentage;
        ELSE -- error or skipped
            v_rule_score := 0.0;
        END IF;

        -- Add to weighted sum
        v_weighted_sum := v_weighted_sum + (v_rule_score * v_rule_weight);
        v_total_weight := v_total_weight + v_rule_weight;

        -- Add to calculation details
        v_calculation_details := v_calculation_details || jsonb_build_object(
            'rule_id', v_validation_record.rule_id,
            'status', v_validation_record.status,
            'rule_weight', v_rule_weight,
            'rule_score', v_rule_score
        );
    END LOOP;

    -- Calculate final score
    IF v_total_weight > 0 THEN
        v_score := ROUND(v_weighted_sum / v_total_weight, 2);
    ELSE
        v_score := NULL; -- No applicable rules for this dimension
    END IF;

    -- Store the score
    IF v_score IS NOT NULL THEN
        -- First archive the current score
        INSERT INTO data_quality.dq_quality_score_history (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        )
        SELECT
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        FROM data_quality.dq_quality_scores
        WHERE target_schema = p_target_schema
        AND target_table = p_target_table
        AND target_column = p_target_column
        AND dimension_id = p_dimension_id;

        -- Then update or insert the new score
        INSERT INTO data_quality.dq_quality_scores (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        ) VALUES (
            p_target_schema,
            p_target_table,
            p_target_column,
            p_dimension_id,
            v_score,
            p_execution_id,
            jsonb_build_object(
                'total_weight', v_total_weight,
                'weighted_sum', v_weighted_sum,
                'rules', v_calculation_details
            )
        )
        ON CONFLICT (target_schema, target_table, target_column, dimension_id) DO UPDATE SET
            score = EXCLUDED.score,
            score_timestamp = CURRENT_TIMESTAMP,
            execution_id = EXCLUDED.execution_id,
            calculation_details = EXCLUDED.calculation_details;
    END IF;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.calculate_dimension_score IS 'Calculates a quality score for a specific dimension based on validation results';

-- Function to calculate overall quality score for a column
CREATE OR REPLACE FUNCTION data_quality.calculate_column_score(
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_execution_id UUID
) RETURNS NUMERIC(5, 2) AS $$
DECLARE
    v_dimension RECORD;
    v_dimension_score NUMERIC(5, 2);
    v_total_weight NUMERIC(5, 2) := 0;
    v_weighted_sum NUMERIC(5, 2) := 0;
    v_overall_score NUMERIC(5, 2);
    v_dimension_weight NUMERIC(5, 2);
BEGIN
    -- Calculate scores for each applicable dimension
    FOR v_dimension IN
        SELECT DISTINCT d.dimension_id, d.dimension_name
        FROM data_quality.dq_validation_log vl
        JOIN data_quality.dq_rules r ON vl.rule_id = r.rule_id
        JOIN data_quality.dq_validation_types vt ON r.validation_type_id = vt.validation_type_id
        JOIN data_quality.dq_validation_dimension_map vdm ON vt.validation_type_id = vdm.validation_type_id
        JOIN data_quality.dq_dimensions d ON vdm.dimension_id = d.dimension_id
        WHERE vl.execution_id = p_execution_id
        AND vl.target_schema = p_target_schema
        AND vl.target_table = p_target_table
        AND vl.target_column = p_target_column
    LOOP
        -- Calculate dimension score
        v_dimension_score := data_quality.calculate_dimension_score(
            p_target_schema,
            p_target_table,
            p_target_column,
            v_dimension.dimension_id,
            p_execution_id
        );

        IF v_dimension_score IS NOT NULL THEN
            -- Get dimension weight
            v_dimension_weight := data_quality.get_dimension_weight(
                p_target_schema,
                p_target_table,
                p_target_column,
                v_dimension.dimension_id
            );

            -- Add to weighted sum
            v_weighted_sum := v_weighted_sum + (v_dimension_score * v_dimension_weight);
            v_total_weight := v_total_weight + v_dimension_weight;
        END IF;
    END LOOP;

    -- Calculate overall score
    IF v_total_weight > 0 THEN
        v_overall_score := ROUND(v_weighted_sum / v_total_weight, 2);

        -- Store the overall score (dimension_id = NULL means overall score)
        INSERT INTO data_quality.dq_quality_scores (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        ) VALUES (
            p_target_schema,
            p_target_table,
            p_target_column,
            NULL,
            v_overall_score,
            p_execution_id,
            jsonb_build_object(
                'total_weight', v_total_weight,
                'weighted_sum', v_weighted_sum
            )
        )
        ON CONFLICT (target_schema, target_table, target_column, dimension_id) DO UPDATE SET
            score = EXCLUDED.score,
            score_timestamp = CURRENT_TIMESTAMP,
            execution_id = EXCLUDED.execution_id,
            calculation_details = EXCLUDED.calculation_details;

        -- Also store in history
        INSERT INTO data_quality.dq_quality_score_history (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        ) VALUES (
            p_target_schema,
            p_target_table,
            p_target_column,
            NULL,
            v_overall_score,
            p_execution_id,
            jsonb_build_object(
                'total_weight', v_total_weight,
                'weighted_sum', v_weighted_sum
            )
        );
    ELSE
        v_overall_score := NULL;
    END IF;

    RETURN v_overall_score;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.calculate_column_score IS 'Calculates an overall quality score for a column based on dimension scores';

-- Function to calculate table-level quality score
CREATE OR REPLACE FUNCTION data_quality.calculate_table_score(
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_execution_id UUID
) RETURNS NUMERIC(5, 2) AS $$
DECLARE
    v_column RECORD;
    v_column_score NUMERIC(5, 2);
    v_total_columns INTEGER := 0;
    v_score_sum NUMERIC(10, 2) := 0;
    v_overall_score NUMERIC(5, 2);
BEGIN
    -- Calculate scores for each column
    FOR v_column IN
        SELECT DISTINCT target_column
        FROM data_quality.dq_validation_log
        WHERE execution_id = p_execution_id
        AND target_schema = p_target_schema
        AND target_table = p_target_table
    LOOP
        -- Calculate column score
        v_column_score := data_quality.calculate_column_score(
            p_target_schema,
            p_target_table,
            v_column.target_column,
            p_execution_id
        );

        IF v_column_score IS NOT NULL THEN
            v_score_sum := v_score_sum + v_column_score;
            v_total_columns := v_total_columns + 1;
        END IF;
    END LOOP;

    -- Calculate overall table score
    IF v_total_columns > 0 THEN
        v_overall_score := ROUND(v_score_sum / v_total_columns, 2);

        -- Store the table score
        INSERT INTO data_quality.dq_quality_scores (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        ) VALUES (
            p_target_schema,
            p_target_table,
            NULL,
            NULL,
            v_overall_score,
            p_execution_id,
            jsonb_build_object(
                'total_columns', v_total_columns,
                'score_sum', v_score_sum
            )
        )
        ON CONFLICT (target_schema, target_table, target_column, dimension_id) DO UPDATE SET
            score = EXCLUDED.score,
            score_timestamp = CURRENT_TIMESTAMP,
            execution_id = EXCLUDED.execution_id,
            calculation_details = EXCLUDED.calculation_details;

        -- Also store in history
        INSERT INTO data_quality.dq_quality_score_history (
            target_schema,
            target_table,
            target_column,
            dimension_id,
            score,
            execution_id,
            calculation_details
        ) VALUES (
            p_target_schema,
            p_target_table,
            NULL,
            NULL,
            v_overall_score,
            p_execution_id,
            jsonb_build_object(
                'total_columns', v_total_columns,
                'score_sum', v_score_sum
            )
        );
    ELSE
        v_overall_score := NULL;
    END IF;

    RETURN v_overall_score;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.calculate_table_score IS 'Calculates an overall quality score for a table based on column scores';

-- Function to calculate all quality scores after a validation run
CREATE OR REPLACE FUNCTION data_quality.calculate_all_scores(
    p_execution_id UUID
) RETURNS TABLE (
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    table_score NUMERIC(5, 2)
) AS $$
DECLARE
    v_table RECORD;
    v_table_score NUMERIC(5, 2);
BEGIN
    -- Calculate scores for each table
    FOR v_table IN
        SELECT DISTINCT target_schema, target_table
        FROM data_quality.dq_validation_log
        WHERE execution_id = p_execution_id
    LOOP
        -- Calculate table score
        v_table_score := data_quality.calculate_table_score(
            v_table.target_schema,
            v_table.target_table,
            p_execution_id
        );

        -- Return result
        target_schema := v_table.target_schema;
        target_table := v_table.target_table;
        table_score := v_table_score;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.calculate_all_scores IS 'Calculates quality scores for all tables in a validation run';

-- Function to get score category for a given score
CREATE OR REPLACE FUNCTION data_quality.get_score_category(
    p_score NUMERIC(5, 2)
) RETURNS TABLE (
    score_category VARCHAR(20),
    color_code VARCHAR(7),
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        st.score_category,
        st.color_code,
        st.description
    FROM data_quality.dq_score_thresholds st
    WHERE p_score >= st.min_score AND p_score < st.max_score
    ORDER BY st.min_score DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.get_score_category IS 'Gets the category for a given quality score';

-- Step 3: Enhance Rule Execution to Calculate Scores

-- Modify the execute_dq_rule_set function to calculate scores after validation
CREATE OR REPLACE FUNCTION data_quality.execute_dq_rule_set_with_scoring(
    p_set_id INTEGER
) RETURNS TABLE (
    execution_id UUID,
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    table_score NUMERIC(5, 2),
    score_category VARCHAR(20),
    color_code VARCHAR(7)
) AS $$
DECLARE
    v_execution_id UUID;
    v_score_result RECORD;
    v_category_result RECORD;
BEGIN
    -- Execute the rule set
    v_execution_id := data_quality.execute_dq_rule_set(p_set_id);

    -- Calculate scores
    FOR v_score_result IN
        SELECT * FROM data_quality.calculate_all_scores(v_execution_id)
    LOOP
        -- Get score category
        SELECT * INTO v_category_result
        FROM data_quality.get_score_category(v_score_result.table_score);

        -- Return result
        execution_id := v_execution_id;
        target_schema := v_score_result.target_schema;
        target_table := v_score_result.target_table;
        table_score := v_score_result.table_score;
        score_category := v_category_result.score_category;
        color_code := v_category_result.color_code;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.execute_dq_rule_set_with_scoring IS 'Executes a rule set and calculates quality scores';

-- Step 4: Create Views for Quality Score Reporting

-- View for Current Quality Scores
CREATE OR REPLACE VIEW data_quality.v_current_quality_scores AS
SELECT
    qs.target_schema,
    qs.target_table,
    qs.target_column,
    d.dimension_name,
    qs.score,
    qs.score_timestamp,
    st.score_category,
    st.color_code,
    qs.calculation_details
FROM data_quality.dq_quality_scores qs
LEFT JOIN data_quality.dq_dimensions d ON qs.dimension_id = d.dimension_id
JOIN data_quality.dq_score_thresholds st ON
    qs.score >= st.min_score AND qs.score < st.max_score
ORDER BY
    qs.target_schema,
    qs.target_table,
    CASE WHEN qs.target_column IS NULL THEN 0 ELSE 1 END,
    qs.target_column,
    CASE WHEN qs.dimension_id IS NULL THEN 0 ELSE 1 END,
    d.dimension_name;

COMMENT ON VIEW data_quality.v_current_quality_scores IS 'Shows current quality scores with categories';

-- View for Quality Score Dashboard
CREATE OR REPLACE VIEW data_quality.v_quality_score_dashboard AS
SELECT
    qs.target_schema,
    qs.target_table,
    qs.score,
    st.score_category,
    st.color_code,
    qs.score_timestamp,
    (SELECT COUNT(*) FROM data_quality.dq_validation_log vl
     WHERE vl.target_schema = qs.target_schema
     AND vl.target_table = qs.target_table
     AND vl.execution_id = qs.execution_id) AS total_validations,
    (SELECT COUNT(*) FROM data_quality.dq_validation_log vl
     WHERE vl.target_schema = qs.target_schema
     AND vl.target_table = qs.target_table
     AND vl.execution_id = qs.execution_id
     AND vl.status = 'failed') AS failed_validations,
    (SELECT jsonb_agg(jsonb_build_object(
        'dimension', d.dimension_name,
        'score', dim_qs.score,
        'category', dim_st.score_category
     ))
     FROM data_quality.dq_quality_scores dim_qs
     JOIN data_quality.dq_dimensions d ON dim_qs.dimension_id = d.dimension_id
     JOIN data_quality.dq_score_thresholds dim_st ON
         dim_qs.score >= dim_st.min_score AND dim_qs.score < dim_st.max_score
     WHERE dim_qs.target_schema = qs.target_schema
     AND dim_qs.target_table = qs.target_table
     AND dim_qs.target_column IS NULL
     AND dim_qs.dimension_id IS NOT NULL) AS dimension_scores
FROM data_quality.dq_quality_scores qs
JOIN data_quality.dq_score_thresholds st ON
    qs.score >= st.min_score AND qs.score < st.max_score
WHERE qs.target_column IS NULL
AND qs.dimension_id IS NULL
ORDER BY qs.score ASC;

COMMENT ON VIEW data_quality.v_quality_score_dashboard IS 'Dashboard view of quality scores by table';

-- View for Quality Score Trends
CREATE OR REPLACE VIEW data_quality.v_quality_score_trends AS
WITH monthly_scores AS (
    SELECT
        target_schema,
        target_table,
        date_trunc('month', score_timestamp) AS month,
        AVG(score) AS avg_score
    FROM data_quality.dq_quality_score_history
    WHERE target_column IS NULL
    AND dimension_id IS NULL
    GROUP BY target_schema, target_table, date_trunc('month', score_timestamp)
)
SELECT
    ms.target_schema,
    ms.target_table,
    ms.month,
    ms.avg_score,
    LAG(ms.avg_score) OVER (PARTITION BY ms.target_schema, ms.target_table ORDER BY ms.month) AS prev_month_score,
    ms.avg_score - LAG(ms.avg_score) OVER (PARTITION BY ms.target_schema, ms.target_table ORDER BY ms.month) AS score_change,
    st.score_category,
    st.color_code
FROM monthly_scores ms
JOIN data_quality.dq_score_thresholds st ON
    ms.avg_score >= st.min_score AND ms.avg_score < st.max_score
ORDER BY ms.target_schema, ms.target_table, ms.month;

COMMENT ON VIEW data_quality.v_quality_score_trends IS 'Shows quality score trends over time';

-- View for Dimension Score Comparison
CREATE OR REPLACE VIEW data_quality.v_dimension_score_comparison AS
SELECT
    qs.target_schema,
    qs.target_table,
    d.dimension_name,
    qs.score,
    st.score_category,
    st.color_code,
    qs.score_timestamp
FROM data_quality.dq_quality_scores qs
JOIN data_quality.dq_dimensions d ON qs.dimension_id = d.dimension_id
JOIN data_quality.dq_score_thresholds st ON
    qs.score >= st.min_score AND qs.score < st.max_score
WHERE qs.target_column IS NULL
ORDER BY qs.target_schema, qs.target_table, qs.score ASC;

COMMENT ON VIEW data_quality.v_dimension_score_comparison IS 'Compares quality scores across dimensions';

-- Step 5: Initialize Scoring Framework (Example)

-- Set custom dimension weights for important tables
INSERT INTO data_quality.dq_custom_dimension_weights (
    target_schema, target_table, target_column, dimension_id, weight
)
VALUES
('public', 'Users', 'email',
 (SELECT dimension_id FROM data_quality.dq_dimensions WHERE dimension_name = 'Completeness'),
 2.0),
('public', 'Users', 'username',
 (SELECT dimension_id FROM data_quality.dq_dimensions WHERE dimension_name = 'Uniqueness'),
 2.0),
('public', 'VehicleInfo', NULL,
 (SELECT dimension_id FROM data_quality.dq_dimensions WHERE dimension_name = 'Accuracy'),
 1.5);

-- Add documentation comments
COMMENT ON SCHEMA data_quality IS 'Schema for comprehensive data quality management, including validation, scoring, cleansing, and monitoring';
-- PostgreSQL Data Quality Management Framework - Part 3: Cleansing
-- This implementation provides:
-- 3. Automated data cleansing procedures

-- Step 1: Create Data Cleansing Tables

-- Cleansing Methods Table
CREATE TABLE data_quality.dq_cleansing_methods (
    method_id SERIAL PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    implementation_function VARCHAR(100) NOT NULL,
    required_parameters JSONB,
    is_destructive BOOLEAN DEFAULT FALSE,
    requires_approval BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality.dq_cleansing_methods IS 'Defines available data cleansing methods';

-- Insert standard cleansing methods
INSERT INTO data_quality.dq_cleansing_methods (
    method_name, description, implementation_function, required_parameters, is_destructive, requires_approval
)
VALUES
('trim_whitespace', 'Removes leading and trailing whitespace', 'data_quality.cleanse_trim_whitespace', '{}', FALSE, FALSE),
('standardize_case', 'Converts text to specified case (upper, lower, title)', 'data_quality.cleanse_standardize_case', '{"case_type": "lower"}', FALSE, FALSE),
('replace_nulls', 'Replaces NULL values with a default value', 'data_quality.cleanse_replace_nulls', '{"default_value": ""}', FALSE, TRUE),
('replace_pattern', 'Replaces text matching a pattern with replacement text', 'data_quality.cleanse_replace_pattern', '{"pattern": "", "replacement": ""}', TRUE, TRUE),
('normalize_phone', 'Standardizes phone number formats', 'data_quality.cleanse_normalize_phone', '{"format": "+#-###-###-####"}', FALSE, TRUE),
('normalize_date', 'Standardizes date formats', 'data_quality.cleanse_normalize_date', '{"format": "YYYY-MM-DD"}', TRUE, TRUE),
('remove_duplicates', 'Removes duplicate records', 'data_quality.cleanse_remove_duplicates', '{"criteria_columns": []}', TRUE, TRUE),
('truncate_to_length', 'Truncates text to specified maximum length', 'data_quality.cleanse_truncate_to_length', '{"max_length": 255}', TRUE, TRUE),
('round_numeric', 'Rounds numeric values to specified precision', 'data_quality.cleanse_round_numeric', '{"precision": 2}', TRUE, TRUE),
('apply_regex_validation', 'Validates and corrects values using regex', 'data_quality.cleanse_apply_regex_validation', '{"pattern": "", "replacement_if_invalid": ""}', TRUE, TRUE);

-- Cleansing Rules Table
CREATE TABLE data_quality.dq_cleansing_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255) NOT NULL,
    method_id INTEGER NOT NULL REFERENCES data_quality.dq_cleansing_methods(method_id),
    rule_parameters JSONB,
    condition_sql TEXT,
    priority INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    updated_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dq_cleansing_rules_target ON data_quality.dq_cleansing_rules (target_schema, target_table, target_column);
CREATE INDEX idx_dq_cleansing_rules_method ON data_quality.dq_cleansing_rules (method_id);
CREATE INDEX idx_dq_cleansing_rules_active ON data_quality.dq_cleansing_rules (is_active);
CREATE INDEX idx_dq_cleansing_rules_priority ON data_quality.dq_cleansing_rules (priority);

COMMENT ON TABLE data_quality.dq_cleansing_rules IS 'Defines specific data cleansing rules for database columns';

-- Cleansing Rule Sets Table
CREATE TABLE data_quality.dq_cleansing_rule_sets (
    set_id SERIAL PRIMARY KEY,
    set_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    schedule_cron VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dq_cleansing_rule_sets_active ON data_quality.dq_cleansing_rule_sets (is_active);

COMMENT ON TABLE data_quality.dq_cleansing_rule_sets IS 'Groups data cleansing rules for execution';

-- Cleansing Rule Set Membership Table
CREATE TABLE data_quality.dq_cleansing_rule_set_membership (
    membership_id SERIAL PRIMARY KEY,
    set_id INTEGER NOT NULL REFERENCES data_quality.dq_cleansing_rule_sets(set_id),
    rule_id INTEGER NOT NULL REFERENCES data_quality.dq_cleansing_rules(rule_id),
    execution_order INTEGER DEFAULT 0,
    CONSTRAINT unique_cleansing_rule_set_membership UNIQUE (set_id, rule_id)
);

CREATE INDEX idx_dq_cleansing_rule_set_membership_set ON data_quality.dq_cleansing_rule_set_membership (set_id);
CREATE INDEX idx_dq_cleansing_rule_set_membership_rule ON data_quality.dq_cleansing_rule_set_membership (rule_id);

COMMENT ON TABLE data_quality.dq_cleansing_rule_set_membership IS 'Maps cleansing rules to rule sets';

-- Cleansing Execution Log Table
CREATE TABLE data_quality.dq_cleansing_log (
    log_id BIGSERIAL PRIMARY KEY,
    execution_id UUID NOT NULL,
    rule_id INTEGER NOT NULL REFERENCES data_quality.dq_cleansing_rules(rule_id),
    set_id INTEGER REFERENCES data_quality.dq_cleansing_rule_sets(set_id),
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255) NOT NULL,
    cleansing_method VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('completed', 'failed', 'skipped', 'approved', 'rejected')),
    total_rows_checked BIGINT,
    rows_modified BIGINT,
    rows_modified_percentage NUMERIC(5, 2),
    error_message TEXT,
    sample_modifications JSONB,
    execution_duration INTERVAL,
    executed_by VARCHAR(255) DEFAULT CURRENT_USER,
    approved_by VARCHAR(255),
    approval_timestamp TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_dq_cleansing_log_execution ON data_quality.dq_cleansing_log (execution_id);
CREATE INDEX idx_dq_cleansing_log_rule ON data_quality.dq_cleansing_log (rule_id);
CREATE INDEX idx_dq_cleansing_log_set ON data_quality.dq_cleansing_log (set_id);
CREATE INDEX idx_dq_cleansing_log_timestamp ON data_quality.dq_cleansing_log (execution_timestamp);
CREATE INDEX idx_dq_cleansing_log_status ON data_quality.dq_cleansing_log (status);
CREATE INDEX idx_dq_cleansing_log_target ON data_quality.dq_cleansing_log (target_schema, target_table, target_column);

COMMENT ON TABLE data_quality.dq_cleansing_log IS 'Logs the results of data cleansing executions';

-- Cleansing Approval Queue Table
CREATE TABLE data_quality.dq_cleansing_approval_queue (
    queue_id SERIAL PRIMARY KEY,
    log_id BIGINT NOT NULL REFERENCES data_quality.dq_cleansing_log(log_id),
    rule_id INTEGER NOT NULL REFERENCES data_quality.dq_cleansing_rules(rule_id),
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    target_column VARCHAR(255) NOT NULL,
    cleansing_method VARCHAR(100) NOT NULL,
    rule_parameters JSONB,
    condition_sql TEXT,
    sample_modifications JSONB,
    rows_to_modify BIGINT,
    requested_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    requested_by VARCHAR(255) DEFAULT CURRENT_USER,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by VARCHAR(255),
    approval_timestamp TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    execution_id UUID
);

CREATE INDEX idx_dq_cleansing_approval_queue_log ON data_quality.dq_cleansing_approval_queue (log_id);
CREATE INDEX idx_dq_cleansing_approval_queue_rule ON data_quality.dq_cleansing_approval_queue (rule_id);
CREATE INDEX idx_dq_cleansing_approval_queue_status ON data_quality.dq_cleansing_approval_queue (status);
CREATE INDEX idx_dq_cleansing_approval_queue_target ON data_quality.dq_cleansing_approval_queue (target_schema, target_table, target_column);

COMMENT ON TABLE data_quality.dq_cleansing_approval_queue IS 'Queue for approving data cleansing operations';

-- Data Backup Table
CREATE TABLE data_quality.dq_data_backups (
    backup_id SERIAL PRIMARY KEY,
    execution_id UUID NOT NULL,
    target_schema VARCHAR(255) NOT NULL,
    target_table VARCHAR(255) NOT NULL,
    backup_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    backup_data JSONB NOT NULL,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    is_restored BOOLEAN DEFAULT FALSE,
    restored_timestamp TIMESTAMP WITH TIME ZONE,
    restored_by VARCHAR(255)
);

CREATE INDEX idx_dq_data_backups_execution ON data_quality.dq_data_backups (execution_id);
CREATE INDEX idx_dq_data_backups_target ON data_quality.dq_data_backups (target_schema, target_table);
CREATE INDEX idx_dq_data_backups_timestamp ON data_quality.dq_data_backups (backup_timestamp);

COMMENT ON TABLE data_quality.dq_data_backups IS 'Stores backups of data before cleansing operations';

-- Step 2: Create Core Functions for Data Cleansing

-- Function to define a new data cleansing rule
CREATE OR REPLACE FUNCTION data_quality.define_cleansing_rule(
    p_rule_name VARCHAR(100),
    p_description TEXT,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_cleansing_method VARCHAR(100),
    p_rule_parameters JSONB DEFAULT '{}',
    p_condition_sql TEXT DEFAULT NULL,
    p_priority INTEGER DEFAULT 100,
    p_is_active BOOLEAN DEFAULT TRUE
) RETURNS INTEGER AS $$
DECLARE
    v_method_id INTEGER;
    v_rule_id INTEGER;
BEGIN
    -- Get method ID
    SELECT method_id INTO v_method_id
    FROM data_quality.dq_cleansing_methods
    WHERE method_name = p_cleansing_method;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cleansing method "%" not found.', p_cleansing_method;
    END IF;

    -- Insert the rule
    INSERT INTO data_quality.dq_cleansing_rules (
        rule_name, description, target_schema, target_table, target_column,
        method_id, rule_parameters, condition_sql, priority, is_active
    ) VALUES (
        p_rule_name, p_description, p_target_schema, p_target_table, p_target_column,
        v_method_id, p_rule_parameters, p_condition_sql, p_priority, p_is_active
    )
    ON CONFLICT (rule_name) DO UPDATE SET
        description = p_description,
        target_schema = p_target_schema,
        target_table = p_target_table,
        target_column = p_target_column,
        method_id = v_method_id,
        rule_parameters = p_rule_parameters,
        condition_sql = p_condition_sql,
        priority = p_priority,
        is_active = p_is_active,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = CURRENT_USER
    RETURNING rule_id INTO v_rule_id;

    RETURN v_rule_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_quality.define_cleansing_rule IS 'Defines or updates a data cleansing rule';

-- Function to log cleansing results
CREATE OR REPLACE FUNCTION data_quality.log_cleansing_operation(
    p_execution_id UUID,
    p_rule_id INTEGER,
    p_set_id INTEGER,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_cleansing_method VARCHAR(100),
    p_status VARCHAR(20),
    p_total_rows_checked BIGINT,
    p_rows_modified BIGINT,
    p_error_message TEXT,
    p_sample_modifications JSONB,
    p_execution_duration INTERVAL
) RETURNS BIGINT AS $$
DECLARE
    v_log_id BIGINT;
    v_modified_percentage NUMERIC(5, 2);
BEGIN
    -- Calculate modified percentage
    IF p_total_rows_checked > 0 THEN
        v_modified_percentage := ROUND((p_rows_modified::NUMERIC * 100.0) / p_total_rows_checked, 2);
    ELSE
        v_modified_percentage := 0.00;
    END IF;

    -- Insert log entry
    INSERT INTO data_quality.dq_cleansing_log (
        execution_id, rule_id, set_id, target_schema, target_table, target_column,
        cleansing_method, status, total_rows_checked, rows_modified,
        rows_modified_percentage, error_message, sample_modifications, execution_duration
    ) VALUES (
        p_execution_id, p_rule_id, p_set_id, p_target_schema, p_target_table, p_target_column,
        p_cleansing_method, p_status, p_total_rows_checked, p_rows_modified,
        v_modified_percentage, p_error_message, p_sample_modifications, p_execution_duration
    ) RETURNING log_id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.log_cleansing_operation IS 'Logs the result of a single data cleansing operation';

-- Function to backup data before cleansing
CREATE OR REPLACE FUNCTION data_quality.backup_data_before_cleansing(
    p_execution_id UUID,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_condition_sql TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_backup_id INTEGER;
    v_sql TEXT;
    v_backup_data JSONB;
BEGIN
    -- Build SQL to get data to backup
    IF p_condition_sql IS NULL OR p_condition_sql = '' THEN
        v_sql := format(
            'SELECT jsonb_agg(to_jsonb(t)) FROM %I.%I t',
            p_target_schema, p_target_table
        );
    ELSE
        v_sql := format(
            'SELECT jsonb_agg(to_jsonb(t)) FROM %I.%I t WHERE %s',
            p_target_schema, p_target_table, p_condition_sql
        );
    END IF;

    -- Execute SQL to get data
    EXECUTE v_sql INTO v_backup_data;

    -- If no data to backup, return NULL
    IF v_backup_data IS NULL OR jsonb_array_length(v_backup_data) = 0 THEN
        RETURN NULL;
    END IF;

    -- Insert backup
    INSERT INTO data_quality.dq_data_backups (
        execution_id, target_schema, target_table, backup_data
    ) VALUES (
        p_execution_id, p_target_schema, p_target_table, v_backup_data
    ) RETURNING backup_id INTO v_backup_id;

    RETURN v_backup_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.backup_data_before_cleansing IS 'Creates a backup of data before cleansing operations';

-- Function to restore data from backup
CREATE OR REPLACE FUNCTION data_quality.restore_from_backup(
    p_backup_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_backup data_quality.dq_data_backups%ROWTYPE;
    v_record JSONB;
    v_columns TEXT[];
    v_values TEXT[];
    v_sql TEXT;
    v_pk_columns TEXT[];
    v_pk_values TEXT[];
    v_pk_conditions TEXT[];
    v_success BOOLEAN := TRUE;
BEGIN
    -- Get backup record
    SELECT * INTO v_backup FROM data_quality.dq_data_backups WHERE backup_id = p_backup_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Backup with ID % not found.', p_backup_id;
    END IF;

    -- Check if already restored
    IF v_backup.is_restored THEN
        RAISE EXCEPTION 'Backup with ID % has already been restored.', p_backup_id;
    END IF;

    -- Get primary key columns
    v_pk_columns := audit.get_primary_key_columns(v_backup.target_schema, v_backup.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        RAISE EXCEPTION 'Cannot restore table %.% without primary key.', v_backup.target_schema, v_backup.target_table;
    END IF;

    -- Process each record in the backup
    FOR v_record IN SELECT * FROM jsonb_array_elements(v_backup.backup_data)
    LOOP
        -- Extract column names and values
        v_columns := ARRAY[]::TEXT[];
        v_values := ARRAY[]::TEXT[];

        FOR key, value IN SELECT * FROM jsonb_each(v_record)
        LOOP
            v_columns := v_columns || quote_ident(key);

            IF value IS NULL THEN
                v_values := v_values || 'NULL';
            ELSIF jsonb_typeof(value) = 'string' THEN
                v_values := v_values || quote_literal(value#>>'{}');
            ELSIF jsonb_typeof(value) = 'number' THEN
                v_values := v_values || (value#>>'{}');
            ELSIF jsonb_typeof(value) = 'boolean' THEN
                v_values := v_values || (value#>>'{}');
            ELSE
                v_values := v_values || quote_literal(value#>>'{}');
            END IF;
        END LOOP;

        -- Build primary key conditions
        v_pk_conditions := ARRAY[]::TEXT[];
        FOREACH key IN ARRAY v_pk_columns
        LOOP
            IF v_record ? key THEN
                IF v_record->key IS NULL THEN
                    v_pk_conditions := v_pk_conditions || format('%I IS NULL', key);
                ELSIF jsonb_typeof(v_record->key) = 'string' THEN
                    v_pk_conditions := v_pk_conditions || format('%I = %L', key, v_record->key#>>'{}');
                ELSIF jsonb_typeof(v_record->key) = 'number' THEN
                    v_pk_conditions := v_pk_conditions || format('%I = %s', key, v_record->key#>>'{}');
                ELSIF jsonb_typeof(v_record->key) = 'boolean' THEN
                    v_pk_conditions := v_pk_conditions || format('%I = %s', key, v_record->key#>>'{}');
                ELSE
                    v_pk_conditions := v_pk_conditions || format('%I = %L', key, v_record->key#>>'{}');
                END IF;
            END IF;
        END LOOP;

        -- Build and execute SQL to delete existing record
        v_sql := format(
            'DELETE FROM %I.%I WHERE %s',
            v_backup.target_schema, v_backup.target_table,
            array_to_string(v_pk_conditions, ' AND ')
        );

        BEGIN
            EXECUTE v_sql;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Error deleting record: %', SQLERRM;
            v_success := FALSE;
        END;

        -- Build and execute SQL to insert record
        v_sql := format(
            'INSERT INTO %I.%I (%s) VALUES (%s)',
            v_backup.target_schema, v_backup.target_table,
            array_to_string(v_columns, ', '),
            array_to_string(v_values, ', ')
        );

        BEGIN
            EXECUTE v_sql;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Error inserting record: %', SQLERRM;
            v_success := FALSE;
        END;
    END LOOP;

    -- Update backup record
    UPDATE data_quality.dq_data_backups
    SET
        is_restored = TRUE,
        restored_timestamp = CURRENT_TIMESTAMP,
        restored_by = CURRENT_USER
    WHERE backup_id = p_backup_id;

    RETURN v_success;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.restore_from_backup IS 'Restores data from a backup';

-- Step 3: Implement Specific Cleansing Methods

-- Function to trim whitespace
CREATE OR REPLACE FUNCTION data_quality.cleanse_trim_whitespace(
    p_rule data_quality.dq_cleansing_rules,
    p_execution_id UUID,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_condition TEXT;
    v_total_rows BIGINT;
    v_modified_rows BIGINT := 0;
    v_sample_modifications JSONB;
    v_pk_columns TEXT[];
    v_pk_select TEXT;
    v_status VARCHAR(20);
    v_error_message TEXT := NULL;
    v_backup_id INTEGER;
BEGIN
    -- Get primary key columns for sampling
    v_pk_columns := audit.get_primary_key_columns(p_rule.target_schema, p_rule.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        v_pk_select := 'NULL::TEXT AS pk'; -- No PK, cannot sample specific rows
    ELSE
        v_pk_select := format('array_to_string(ARRAY[%s], ''|'') AS pk',
                             array_to_string(array_agg(quote_ident(col) || '::TEXT'), ',')
                             FROM unnest(v_pk_columns) AS col);
    END IF;

    -- Build condition
    IF p_rule.condition_sql IS NOT NULL AND p_rule.condition_sql <> '' THEN
        v_condition := format('WHERE %s AND %I::TEXT IS NOT NULL AND %I::TEXT <> trim(%I::TEXT)',
                             p_rule.condition_sql, p_rule.target_column, p_rule.target_column, p_rule.target_column);
    ELSE
        v_condition := format('WHERE %I::TEXT IS NOT NULL AND %I::TEXT <> trim(%I::TEXT)',
                             p_rule.target_column, p_rule.target_column, p_rule.target_column);
    END IF;

    -- Count total rows that would be modified
    v_sql := format('SELECT COUNT(*) FROM %I.%I %s',
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_total_rows;

    -- Get sample of rows that would be modified
    v_sql := format('SELECT jsonb_agg(t) FROM (
                        SELECT %s, %I AS original_value, trim(%I::TEXT) AS new_value
                        FROM %I.%I %s
                        LIMIT 5
                    ) t',
                   v_pk_select, p_rule.target_column, p_rule.target_column,
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_sample_modifications;

    -- If not a dry run, perform the update
    IF NOT p_dry_run AND v_total_rows > 0 THEN
        -- Backup data before modification
        v_backup_id := data_quality.backup_data_before_cleansing(
            p_execution_id,
            p_rule.target_schema,
            p_rule.target_table,
            REPLACE(v_condition, 'WHERE ', '')
        );

        -- Perform the update
        v_sql := format('UPDATE %I.%I SET %I = trim(%I::TEXT) %s',
                       p_rule.target_schema, p_rule.target_table,
                       p_rule.target_column, p_rule.target_column, v_condition);
        EXECUTE v_sql;
        GET DIAGNOSTICS v_modified_rows = ROW_COUNT;

        v_status := 'completed';
    ELSE
        v_status := 'skipped';
        v_modified_rows := 0;
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'total_rows_checked', v_total_rows,
        'rows_modified', v_modified_rows,
        'error_message', v_error_message,
        'sample_modifications', v_sample_modifications,
        'backup_id', v_backup_id
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'failed',
        'error_message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.cleanse_trim_whitespace IS 'Implements the trim whitespace cleansing method';

-- Function to standardize case
CREATE OR REPLACE FUNCTION data_quality.cleanse_standardize_case(
    p_rule data_quality.dq_cleansing_rules,
    p_execution_id UUID,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_condition TEXT;
    v_total_rows BIGINT;
    v_modified_rows BIGINT := 0;
    v_sample_modifications JSONB;
    v_pk_columns TEXT[];
    v_pk_select TEXT;
    v_status VARCHAR(20);
    v_error_message TEXT := NULL;
    v_backup_id INTEGER;
    v_case_type TEXT;
    v_case_function TEXT;
BEGIN
    -- Get case type from parameters
    v_case_type := p_rule.rule_parameters->>'case_type';
    IF v_case_type IS NULL THEN
        v_case_type := 'lower';
    END IF;

    -- Determine case function
    CASE v_case_type
        WHEN 'upper' THEN v_case_function := 'upper';
        WHEN 'lower' THEN v_case_function := 'lower';
        WHEN 'title' THEN v_case_function := 'initcap';
        ELSE v_case_function := 'lower';
    END CASE;

    -- Get primary key columns for sampling
    v_pk_columns := audit.get_primary_key_columns(p_rule.target_schema, p_rule.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        v_pk_select := 'NULL::TEXT AS pk'; -- No PK, cannot sample specific rows
    ELSE
        v_pk_select := format('array_to_string(ARRAY[%s], ''|'') AS pk',
                             array_to_string(array_agg(quote_ident(col) || '::TEXT'), ',')
                             FROM unnest(v_pk_columns) AS col);
    END IF;

    -- Build condition
    IF p_rule.condition_sql IS NOT NULL AND p_rule.condition_sql <> '' THEN
        v_condition := format('WHERE %s AND %I::TEXT IS NOT NULL AND %I::TEXT <> %s(%I::TEXT)',
                             p_rule.condition_sql, p_rule.target_column,
                             p_rule.target_column, v_case_function, p_rule.target_column);
    ELSE
        v_condition := format('WHERE %I::TEXT IS NOT NULL AND %I::TEXT <> %s(%I::TEXT)',
                             p_rule.target_column, p_rule.target_column,
                             v_case_function, p_rule.target_column);
    END IF;

    -- Count total rows that would be modified
    v_sql := format('SELECT COUNT(*) FROM %I.%I %s',
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_total_rows;

    -- Get sample of rows that would be modified
    v_sql := format('SELECT jsonb_agg(t) FROM (
                        SELECT %s, %I AS original_value, %s(%I::TEXT) AS new_value
                        FROM %I.%I %s
                        LIMIT 5
                    ) t',
                   v_pk_select, p_rule.target_column, v_case_function, p_rule.target_column,
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_sample_modifications;

    -- If not a dry run, perform the update
    IF NOT p_dry_run AND v_total_rows > 0 THEN
        -- Backup data before modification
        v_backup_id := data_quality.backup_data_before_cleansing(
            p_execution_id,
            p_rule.target_schema,
            p_rule.target_table,
            REPLACE(v_condition, 'WHERE ', '')
        );

        -- Perform the update
        v_sql := format('UPDATE %I.%I SET %I = %s(%I::TEXT) %s',
                       p_rule.target_schema, p_rule.target_table,
                       p_rule.target_column, v_case_function, p_rule.target_column, v_condition);
        EXECUTE v_sql;
        GET DIAGNOSTICS v_modified_rows = ROW_COUNT;

        v_status := 'completed';
    ELSE
        v_status := 'skipped';
        v_modified_rows := 0;
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'total_rows_checked', v_total_rows,
        'rows_modified', v_modified_rows,
        'error_message', v_error_message,
        'sample_modifications', v_sample_modifications,
        'backup_id', v_backup_id
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'failed',
        'error_message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.cleanse_standardize_case IS 'Implements the standardize case cleansing method';

-- Function to replace nulls
CREATE OR REPLACE FUNCTION data_quality.cleanse_replace_nulls(
    p_rule data_quality.dq_cleansing_rules,
    p_execution_id UUID,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_condition TEXT;
    v_total_rows BIGINT;
    v_modified_rows BIGINT := 0;
    v_sample_modifications JSONB;
    v_pk_columns TEXT[];
    v_pk_select TEXT;
    v_status VARCHAR(20);
    v_error_message TEXT := NULL;
    v_backup_id INTEGER;
    v_default_value TEXT;
BEGIN
    -- Get default value from parameters
    v_default_value := p_rule.rule_parameters->>'default_value';
    IF v_default_value IS NULL THEN
        v_default_value := '';
    END IF;

    -- Get primary key columns for sampling
    v_pk_columns := audit.get_primary_key_columns(p_rule.target_schema, p_rule.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        v_pk_select := 'NULL::TEXT AS pk'; -- No PK, cannot sample specific rows
    ELSE
        v_pk_select := format('array_to_string(ARRAY[%s], ''|'') AS pk',
                             array_to_string(array_agg(quote_ident(col) || '::TEXT'), ',')
                             FROM unnest(v_pk_columns) AS col);
    END IF;

    -- Build condition
    IF p_rule.condition_sql IS NOT NULL AND p_rule.condition_sql <> '' THEN
        v_condition := format('WHERE %s AND %I IS NULL',
                             p_rule.condition_sql, p_rule.target_column);
    ELSE
        v_condition := format('WHERE %I IS NULL',
                             p_rule.target_column);
    END IF;

    -- Count total rows that would be modified
    v_sql := format('SELECT COUNT(*) FROM %I.%I %s',
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_total_rows;

    -- Get sample of rows that would be modified
    v_sql := format('SELECT jsonb_agg(t) FROM (
                        SELECT %s, NULL AS original_value, %L AS new_value
                        FROM %I.%I %s
                        LIMIT 5
                    ) t',
                   v_pk_select, v_default_value,
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_sample_modifications;

    -- If not a dry run, perform the update
    IF NOT p_dry_run AND v_total_rows > 0 THEN
        -- Backup data before modification
        v_backup_id := data_quality.backup_data_before_cleansing(
            p_execution_id,
            p_rule.target_schema,
            p_rule.target_table,
            REPLACE(v_condition, 'WHERE ', '')
        );

        -- Perform the update
        v_sql := format('UPDATE %I.%I SET %I = %L %s',
                       p_rule.target_schema, p_rule.target_table,
                       p_rule.target_column, v_default_value, v_condition);
        EXECUTE v_sql;
        GET DIAGNOSTICS v_modified_rows = ROW_COUNT;

        v_status := 'completed';
    ELSE
        v_status := 'skipped';
        v_modified_rows := 0;
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'total_rows_checked', v_total_rows,
        'rows_modified', v_modified_rows,
        'error_message', v_error_message,
        'sample_modifications', v_sample_modifications,
        'backup_id', v_backup_id
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'failed',
        'error_message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.cleanse_replace_nulls IS 'Implements the replace nulls cleansing method';

-- Function to replace pattern
CREATE OR REPLACE FUNCTION data_quality.cleanse_replace_pattern(
    p_rule data_quality.dq_cleansing_rules,
    p_execution_id UUID,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_sql TEXT;
    v_condition TEXT;
    v_total_rows BIGINT;
    v_modified_rows BIGINT := 0;
    v_sample_modifications JSONB;
    v_pk_columns TEXT[];
    v_pk_select TEXT;
    v_status VARCHAR(20);
    v_error_message TEXT := NULL;
    v_backup_id INTEGER;
    v_pattern TEXT;
    v_replacement TEXT;
BEGIN
    -- Get pattern and replacement from parameters
    v_pattern := p_rule.rule_parameters->>'pattern';
    v_replacement := p_rule.rule_parameters->>'replacement';

    IF v_pattern IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'failed',
            'error_message', 'Pattern parameter is required'
        );
    END IF;

    IF v_replacement IS NULL THEN
        v_replacement := '';
    END IF;

    -- Get primary key columns for sampling
    v_pk_columns := audit.get_primary_key_columns(p_rule.target_schema, p_rule.target_table);
    IF v_pk_columns IS NULL OR array_length(v_pk_columns, 1) IS NULL THEN
        v_pk_select := 'NULL::TEXT AS pk'; -- No PK, cannot sample specific rows
    ELSE
        v_pk_select := format('array_to_string(ARRAY[%s], ''|'') AS pk',
                             array_to_string(array_agg(quote_ident(col) || '::TEXT'), ',')
                             FROM unnest(v_pk_columns) AS col);
    END IF;

    -- Build condition
    IF p_rule.condition_sql IS NOT NULL AND p_rule.condition_sql <> '' THEN
        v_condition := format('WHERE %s AND %I::TEXT IS NOT NULL AND %I::TEXT ~ %L',
                             p_rule.condition_sql, p_rule.target_column,
                             p_rule.target_column, v_pattern);
    ELSE
        v_condition := format('WHERE %I::TEXT IS NOT NULL AND %I::TEXT ~ %L',
                             p_rule.target_column, p_rule.target_column, v_pattern);
    END IF;

    -- Count total rows that would be modified
    v_sql := format('SELECT COUNT(*) FROM %I.%I %s',
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_total_rows;

    -- Get sample of rows that would be modified
    v_sql := format('SELECT jsonb_agg(t) FROM (
                        SELECT %s, %I AS original_value,
                               regexp_replace(%I::TEXT, %L, %L) AS new_value
                        FROM %I.%I %s
                        LIMIT 5
                    ) t',
                   v_pk_select, p_rule.target_column,
                   p_rule.target_column, v_pattern, v_replacement,
                   p_rule.target_schema, p_rule.target_table, v_condition);
    EXECUTE v_sql INTO v_sample_modifications;

    -- If not a dry run, perform the update
    IF NOT p_dry_run AND v_total_rows > 0 THEN
        -- Backup data before modification
        v_backup_id := data_quality.backup_data_before_cleansing(
            p_execution_id,
            p_rule.target_schema,
            p_rule.target_table,
            REPLACE(v_condition, 'WHERE ', '')
        );

        -- Perform the update
        v_sql := format('UPDATE %I.%I SET %I = regexp_replace(%I::TEXT, %L, %L) %s',
                       p_rule.target_schema, p_rule.target_table,
                       p_rule.target_column, p_rule.target_column,
                       v_pattern, v_replacement, v_condition);
        EXECUTE v_sql;
        GET DIAGNOSTICS v_modified_rows = ROW_COUNT;

        v_status := 'completed';
    ELSE
        v_status := 'skipped';
        v_modified_rows := 0;
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'total_rows_checked', v_total_rows,
        'rows_modified', v_modified_rows,
        'error_message', v_error_message,
        'sample_modifications', v_sample_modifications,
        'backup_id', v_backup_id
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'status', 'failed',
        'error_message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.cleanse_replace_pattern IS 'Implements the replace pattern cleansing method';

-- Step 4: Create Functions for Cleansing Execution

-- Function to execute a single cleansing rule
CREATE OR REPLACE FUNCTION data_quality.execute_cleansing_rule(
    p_rule_id INTEGER,
    p_execution_id UUID,
    p_set_id INTEGER DEFAULT NULL,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS BIGINT AS $$
DECLARE
    v_rule data_quality.dq_cleansing_rules%ROWTYPE;
    v_method data_quality.dq_cleansing_methods%ROWTYPE;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration INTERVAL;
    v_result JSONB;
    v_status VARCHAR(20);
    v_total_rows BIGINT;
    v_modified_rows BIGINT;
    v_error_message TEXT;
    v_sample_modifications JSONB;
    v_log_id BIGINT;
    v_sql TEXT;
    v_requires_approval BOOLEAN;
BEGIN
    v_start_time := clock_timestamp();

    -- Get rule details
    SELECT * INTO v_rule FROM data_quality.dq_cleansing_rules WHERE rule_id = p_rule_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE NOTICE 'Cleansing rule ID % not found or inactive, skipping.', p_rule_id;
        RETURN NULL;
    END IF;

    -- Get method details
    SELECT * INTO v_method FROM data_quality.dq_cleansing_methods WHERE method_id = v_rule.method_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cleansing method ID % for rule % not found.', v_rule.method_id, p_rule_id;
    END IF;

    -- Check if method requires approval
    v_requires_approval := v_method.requires_approval;

    -- Execute the specific cleansing function
    BEGIN
        v_sql := format('SELECT %I.%I($1, $2, $3);', 'data_quality', v_method.implementation_function);
        EXECUTE v_sql INTO v_result USING v_rule, p_execution_id, p_dry_run;

        -- Parse result
        v_status := v_result->>'status';
        v_total_rows := (v_result->>'total_rows_checked')::BIGINT;
        v_modified_rows := (v_result->>'rows_modified')::BIGINT;
        v_error_message := v_result->>'error_message';
        v_sample_modifications := v_result->'sample_modifications';

    EXCEPTION WHEN OTHERS THEN
        v_status := 'failed';
        v_total_rows := 0;
        v_modified_rows := 0;
        v_error_message := SQLERRM;
        v_sample_modifications := NULL;
        RAISE WARNING 'Error executing cleansing rule % (%): %', p_rule_id, v_rule.rule_name, SQLERRM;
    END;

    v_end_time := clock_timestamp();
    v_duration := v_end_time - v_start_time;

    -- Log the result
    v_log_id := data_quality.log_cleansing_operation(
        p_execution_id,
        p_rule_id,
        p_set_id,
        v_rule.target_schema,
        v_rule.target_table,
        v_rule.target_column,
        v_method.method_name,
        v_status,
        v_total_rows,
        v_modified_rows,
        v_error_message,
        v_sample_modifications,
        v_duration
    );

    -- If requires approval and not a dry run, add to approval queue
    IF v_requires_approval AND NOT p_dry_run AND v_status = 'completed' AND v_total_rows > 0 THEN
        INSERT INTO data_quality.dq_cleansing_approval_queue (
            log_id,
            rule_id,
            target_schema,
            target_table,
            target_column,
            cleansing_method,
            rule_parameters,
            condition_sql,
            sample_modifications,
            rows_to_modify,
            execution_id
        ) VALUES (
            v_log_id,
            p_rule_id,
            v_rule.target_schema,
            v_rule.target_table,
            v_rule.target_column,
            v_method.method_name,
            v_rule.rule_parameters,
            v_rule.condition_sql,
            v_sample_modifications,
            v_total_rows,
            p_execution_id
        );

        -- Update log status to pending approval
        UPDATE data_quality.dq_cleansing_log
        SET status = 'pending'
        WHERE log_id = v_log_id;
    END IF;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.execute_cleansing_rule IS 'Executes a single data cleansing rule and logs the result';

-- Function to execute a cleansing rule set
CREATE OR REPLACE FUNCTION data_quality.execute_cleansing_rule_set(
    p_set_id INTEGER,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS UUID AS $$
DECLARE
    v_rule_membership RECORD;
    v_execution_id UUID := uuid_generate_v4();
    v_set_name TEXT;
BEGIN
    -- Get rule set name
    SELECT set_name INTO v_set_name FROM data_quality.dq_cleansing_rule_sets WHERE set_id = p_set_id AND is_active = TRUE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cleansing rule set ID % not found or inactive.', p_set_id;
    END IF;

    RAISE NOTICE 'Starting execution of cleansing rule set % (ID: %), Execution ID: %, Dry Run: %',
                v_set_name, p_set_id, v_execution_id, p_dry_run;

    -- Execute each rule in the set
    FOR v_rule_membership IN
        SELECT crsm.rule_id
        FROM data_quality.dq_cleansing_rule_set_membership crsm
        JOIN data_quality.dq_cleansing_rules cr ON crsm.rule_id = cr.rule_id
        WHERE crsm.set_id = p_set_id AND cr.is_active = TRUE
        ORDER BY crsm.execution_order, cr.priority
    LOOP
        PERFORM data_quality.execute_cleansing_rule(v_rule_membership.rule_id, v_execution_id, p_set_id, p_dry_run);
    END LOOP;

    RAISE NOTICE 'Finished execution of cleansing rule set % (ID: %), Execution ID: %, Dry Run: %',
                v_set_name, p_set_id, v_execution_id, p_dry_run;

    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.execute_cleansing_rule_set IS 'Executes all active rules within a specified cleansing rule set';

-- Function to approve a cleansing operation
CREATE OR REPLACE FUNCTION data_quality.approve_cleansing_operation(
    p_queue_id INTEGER,
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_queue data_quality.dq_cleansing_approval_queue%ROWTYPE;
    v_rule data_quality.dq_cleansing_rules%ROWTYPE;
    v_method data_quality.dq_cleansing_methods%ROWTYPE;
    v_result JSONB;
    v_sql TEXT;
BEGIN
    -- Get queue record
    SELECT * INTO v_queue FROM data_quality.dq_cleansing_approval_queue WHERE queue_id = p_queue_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Approval queue record with ID % not found.', p_queue_id;
    END IF;

    -- Check if already processed
    IF v_queue.status <> 'pending' THEN
        RAISE EXCEPTION 'Approval queue record with ID % has already been processed (status: %).',
                       p_queue_id, v_queue.status;
    END IF;

    -- Get rule details
    SELECT * INTO v_rule FROM data_quality.dq_cleansing_rules WHERE rule_id = v_queue.rule_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cleansing rule ID % not found.', v_queue.rule_id;
    END IF;

    -- Get method details
    SELECT * INTO v_method FROM data_quality.dq_cleansing_methods WHERE method_id = v_rule.method_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cleansing method ID % for rule % not found.', v_rule.method_id, v_queue.rule_id;
    END IF;

    -- Execute the cleansing operation (not dry run)
    BEGIN
        v_sql := format('SELECT %I.%I($1, $2, $3);', 'data_quality', v_method.implementation_function);
        EXECUTE v_sql INTO v_result USING v_rule, v_queue.execution_id, FALSE;
    EXCEPTION WHEN OTHERS THEN
        -- Update queue record
        UPDATE data_quality.dq_cleansing_approval_queue
        SET
            status = 'failed',
            approval_timestamp = CURRENT_TIMESTAMP,
            approved_by = CURRENT_USER,
            approval_notes = COALESCE(p_notes, '') || ' | Error: ' || SQLERRM
        WHERE queue_id = p_queue_id;

        -- Update log record
        UPDATE data_quality.dq_cleansing_log
        SET
            status = 'failed',
            error_message = SQLERRM
        WHERE log_id = v_queue.log_id;

        RETURN FALSE;
    END;

    -- Update queue record
    UPDATE data_quality.dq_cleansing_approval_queue
    SET
        status = 'approved',
        approval_timestamp = CURRENT_TIMESTAMP,
        approved_by = CURRENT_USER,
        approval_notes = p_notes
    WHERE queue_id = p_queue_id;

    -- Update log record
    UPDATE data_quality.dq_cleansing_log
    SET
        status = 'completed',
        approved_by = CURRENT_USER,
        approval_timestamp = CURRENT_TIMESTAMP,
        rows_modified = (v_result->>'rows_modified')::BIGINT,
        rows_modified_percentage = CASE
            WHEN (v_result->>'total_rows_checked')::BIGINT > 0
            THEN ROUND(((v_result->>'rows_modified')::BIGINT * 100.0) / (v_result->>'total_rows_checked')::BIGINT, 2)
            ELSE 0
        END
    WHERE log_id = v_queue.log_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.approve_cleansing_operation IS 'Approves and executes a pending cleansing operation';

-- Function to reject a cleansing operation
CREATE OR REPLACE FUNCTION data_quality.reject_cleansing_operation(
    p_queue_id INTEGER,
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_queue data_quality.dq_cleansing_approval_queue%ROWTYPE;
BEGIN
    -- Get queue record
    SELECT * INTO v_queue FROM data_quality.dq_cleansing_approval_queue WHERE queue_id = p_queue_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Approval queue record with ID % not found.', p_queue_id;
    END IF;

    -- Check if already processed
    IF v_queue.status <> 'pending' THEN
        RAISE EXCEPTION 'Approval queue record with ID % has already been processed (status: %).',
                       p_queue_id, v_queue.status;
    END IF;

    -- Update queue record
    UPDATE data_quality.dq_cleansing_approval_queue
    SET
        status = 'rejected',
        approval_timestamp = CURRENT_TIMESTAMP,
        approved_by = CURRENT_USER,
        approval_notes = p_notes
    WHERE queue_id = p_queue_id;

    -- Update log record
    UPDATE data_quality.dq_cleansing_log
    SET
        status = 'rejected',
        approved_by = CURRENT_USER,
        approval_timestamp = CURRENT_TIMESTAMP
    WHERE log_id = v_queue.log_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.reject_cleansing_operation IS 'Rejects a pending cleansing operation';

-- Step 5: Create Views for Cleansing Reporting

-- View for Cleansing Operations
CREATE OR REPLACE VIEW data_quality.v_cleansing_operations AS
SELECT
    cl.log_id,
    cl.execution_id,
    cl.rule_id,
    cr.rule_name,
    cl.set_id,
    crs.set_name,
    cl.execution_timestamp,
    cl.target_schema,
    cl.target_table,
    cl.target_column,
    cl.cleansing_method,
    cl.status,
    cl.total_rows_checked,
    cl.rows_modified,
    cl.rows_modified_percentage,
    cl.error_message,
    cl.sample_modifications,
    cl.execution_duration,
    cl.executed_by,
    cl.approved_by,
    cl.approval_timestamp
FROM data_quality.dq_cleansing_log cl
JOIN data_quality.dq_cleansing_rules cr ON cl.rule_id = cr.rule_id
LEFT JOIN data_quality.dq_cleansing_rule_sets crs ON cl.set_id = crs.set_id
ORDER BY cl.execution_timestamp DESC;

COMMENT ON VIEW data_quality.v_cleansing_operations IS 'Shows all data cleansing operations';

-- View for Pending Approvals
CREATE OR REPLACE VIEW data_quality.v_pending_cleansing_approvals AS
SELECT
    caq.queue_id,
    caq.log_id,
    caq.rule_id,
    cr.rule_name,
    caq.target_schema,
    caq.target_table,
    caq.target_column,
    caq.cleansing_method,
    caq.rule_parameters,
    caq.condition_sql,
    caq.sample_modifications,
    caq.rows_to_modify,
    caq.requested_timestamp,
    caq.requested_by,
    cm.is_destructive
FROM data_quality.dq_cleansing_approval_queue caq
JOIN data_quality.dq_cleansing_rules cr ON caq.rule_id = cr.rule_id
JOIN data_quality.dq_cleansing_methods cm ON cr.method_id = cm.method_id
WHERE caq.status = 'pending'
ORDER BY cm.is_destructive DESC, caq.requested_timestamp ASC;

COMMENT ON VIEW data_quality.v_pending_cleansing_approvals IS 'Shows pending cleansing operations requiring approval';

-- View for Cleansing Summary by Table
CREATE OR REPLACE VIEW data_quality.v_cleansing_summary_by_table AS
SELECT
    target_schema,
    target_table,
    COUNT(*) AS total_operations,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_operations,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_operations,
    COUNT(*) FILTER (WHERE status = 'pending') AS pending_operations,
    COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_operations,
    SUM(rows_modified) AS total_rows_modified,
    MAX(execution_timestamp) AS last_operation_time
FROM data_quality.dq_cleansing_log
GROUP BY target_schema, target_table;

COMMENT ON VIEW data_quality.v_cleansing_summary_by_table IS 'Summarizes cleansing operations by table';

-- View for Cleansing History
CREATE OR REPLACE VIEW data_quality.v_cleansing_history AS
SELECT
    cl.log_id,
    cl.execution_id,
    cl.rule_id,
    cr.rule_name,
    cl.set_id,
    crs.set_name,
    cl.execution_timestamp,
    cl.target_schema,
    cl.target_table,
    cl.target_column,
    cl.cleansing_method,
    cl.status,
    cl.rows_modified,
    cl.rows_modified_percentage,
    cl.execution_duration
FROM data_quality.dq_cleansing_log cl
JOIN data_quality.dq_cleansing_rules cr ON cl.rule_id = cr.rule_id
LEFT JOIN data_quality.dq_cleansing_rule_sets crs ON cl.set_id = crs.set_id
ORDER BY cl.execution_timestamp DESC;

COMMENT ON VIEW data_quality.v_cleansing_history IS 'Provides a historical view of all cleansing operations';

-- Step 6: Initialize Cleansing Framework (Example Rules)

-- Example: Rule for Users table - trim whitespace in email
SELECT data_quality.define_cleansing_rule(
    'Users Email Trim Whitespace',
    'Trim whitespace from email addresses in Users table',
    'public',
    'Users',
    'email',
    'trim_whitespace',
    '{}',
    NULL,
    100,
    TRUE
);

-- Example: Rule for Users table - standardize username case
SELECT data_quality.define_cleansing_rule(
    'Users Username Lowercase',
    'Convert usernames to lowercase in Users table',
    'public',
    'Users',
    'username',
    'standardize_case',
    '{"case_type": "lower"}',
    NULL,
    100,
    TRUE
);

-- Create an example cleansing rule set
INSERT INTO data_quality.dq_cleansing_rule_sets (set_name, description)
VALUES ('Core User Data Cleansing', 'Basic cleansing for the Users table');

-- Add rules to the set
INSERT INTO data_quality.dq_cleansing_rule_set_membership (set_id, rule_id)
SELECT
    (SELECT set_id FROM data_quality.dq_cleansing_rule_sets WHERE set_name = 'Core User Data Cleansing'),
    rule_id
FROM data_quality.dq_cleansing_rules
WHERE rule_name IN (
    'Users Email Trim Whitespace',
    'Users Username Lowercase'
);

-- Add documentation comments
COMMENT ON SCHEMA data_quality IS 'Schema for comprehensive data quality management, including validation, scoring, cleansing, and monitoring';
-- PostgreSQL Data Quality Management Framework - Part 4: Metric Tracking
-- This implementation provides:
-- 4. Quality metric tracking over time

-- Step 1: Create Quality Metric Tracking Tables

-- Quality Metrics Definition Table
CREATE TABLE data_quality.dq_metrics (
    metric_id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    metric_type VARCHAR(50) NOT NULL CHECK (metric_type IN ('validation', 'score', 'cleansing', 'custom')),
    calculation_sql TEXT,
    target_goal NUMERIC(10, 2),
    warning_threshold NUMERIC(10, 2),
    critical_threshold NUMERIC(10, 2),
    is_higher_better BOOLEAN DEFAULT TRUE,
    display_format VARCHAR(50) DEFAULT 'percentage',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dq_metrics_type ON data_quality.dq_metrics (metric_type);

COMMENT ON TABLE data_quality.dq_metrics IS 'Defines quality metrics to be tracked over time';

-- Quality Metric Values Table
CREATE TABLE data_quality.dq_metric_values (
    value_id BIGSERIAL PRIMARY KEY,
    metric_id INTEGER NOT NULL REFERENCES data_quality.dq_metrics(metric_id),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    metric_value NUMERIC(20, 6) NOT NULL,
    metric_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_id UUID,
    calculation_details JSONB,
    is_baseline BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_dq_metric_values_metric ON data_quality.dq_metric_values (metric_id);
CREATE INDEX idx_dq_metric_values_target ON data_quality.dq_metric_values (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_metric_values_timestamp ON data_quality.dq_metric_values (metric_timestamp);
CREATE INDEX idx_dq_metric_values_execution ON data_quality.dq_metric_values (execution_id);
CREATE INDEX idx_dq_metric_values_baseline ON data_quality.dq_metric_values (is_baseline);

COMMENT ON TABLE data_quality.dq_metric_values IS 'Stores metric values over time for trend analysis';

-- Metric Alerts Table
CREATE TABLE data_quality.dq_metric_alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    metric_id INTEGER NOT NULL REFERENCES data_quality.dq_metrics(metric_id),
    value_id BIGINT NOT NULL REFERENCES data_quality.dq_metric_values(value_id),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    alert_level VARCHAR(20) NOT NULL CHECK (alert_level IN ('warning', 'critical')),
    metric_value NUMERIC(20, 6) NOT NULL,
    threshold_value NUMERIC(20, 6) NOT NULL,
    alert_message TEXT,
    alert_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(255),
    acknowledgment_timestamp TIMESTAMP WITH TIME ZONE,
    acknowledgment_notes TEXT
);

CREATE INDEX idx_dq_metric_alerts_metric ON data_quality.dq_metric_alerts (metric_id);
CREATE INDEX idx_dq_metric_alerts_value ON data_quality.dq_metric_alerts (value_id);
CREATE INDEX idx_dq_metric_alerts_target ON data_quality.dq_metric_alerts (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_metric_alerts_timestamp ON data_quality.dq_metric_alerts (alert_timestamp);
CREATE INDEX idx_dq_metric_alerts_acknowledged ON data_quality.dq_metric_alerts (acknowledged);

COMMENT ON TABLE data_quality.dq_metric_alerts IS 'Stores alerts generated when metrics exceed thresholds';

-- Metric Subscriptions Table
CREATE TABLE data_quality.dq_metric_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    metric_id INTEGER REFERENCES data_quality.dq_metrics(metric_id),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    alert_level VARCHAR(20) CHECK (alert_level IN ('warning', 'critical', 'all')),
    subscriber_name VARCHAR(255) NOT NULL,
    subscriber_email VARCHAR(255) NOT NULL,
    notification_method VARCHAR(50) DEFAULT 'email' CHECK (notification_method IN ('email', 'slack', 'webhook')),
    notification_config JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dq_metric_subscriptions_metric ON data_quality.dq_metric_subscriptions (metric_id);
CREATE INDEX idx_dq_metric_subscriptions_target ON data_quality.dq_metric_subscriptions (target_schema, target_table, COALESCE(target_column, ''));
CREATE INDEX idx_dq_metric_subscriptions_subscriber ON data_quality.dq_metric_subscriptions (subscriber_name, subscriber_email);
CREATE INDEX idx_dq_metric_subscriptions_active ON data_quality.dq_metric_subscriptions (is_active);

COMMENT ON TABLE data_quality.dq_metric_subscriptions IS 'Defines who should be notified of metric alerts';

-- Metric Dashboards Table
CREATE TABLE data_quality.dq_metric_dashboards (
    dashboard_id SERIAL PRIMARY KEY,
    dashboard_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE data_quality.dq_metric_dashboards IS 'Defines dashboards for metric visualization';

-- Dashboard Metrics Table
CREATE TABLE data_quality.dq_dashboard_metrics (
    dashboard_metric_id SERIAL PRIMARY KEY,
    dashboard_id INTEGER NOT NULL REFERENCES data_quality.dq_metric_dashboards(dashboard_id),
    metric_id INTEGER NOT NULL REFERENCES data_quality.dq_metrics(metric_id),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    chart_type VARCHAR(50) DEFAULT 'line' CHECK (chart_type IN ('line', 'bar', 'gauge', 'table')),
    chart_config JSONB,
    CONSTRAINT unique_dashboard_metric UNIQUE (dashboard_id, metric_id, target_schema, target_table, COALESCE(target_column, ''))
);

CREATE INDEX idx_dq_dashboard_metrics_dashboard ON data_quality.dq_dashboard_metrics (dashboard_id);
CREATE INDEX idx_dq_dashboard_metrics_metric ON data_quality.dq_dashboard_metrics (metric_id);
CREATE INDEX idx_dq_dashboard_metrics_target ON data_quality.dq_dashboard_metrics (target_schema, target_table, COALESCE(target_column, ''));

COMMENT ON TABLE data_quality.dq_dashboard_metrics IS 'Maps metrics to dashboards with visualization settings';

-- Step 2: Create Core Functions for Metric Tracking

-- Function to define a new quality metric
CREATE OR REPLACE FUNCTION data_quality.define_metric(
    p_metric_name VARCHAR(100),
    p_description TEXT,
    p_metric_type VARCHAR(50),
    p_calculation_sql TEXT,
    p_target_goal NUMERIC(10, 2) DEFAULT NULL,
    p_warning_threshold NUMERIC(10, 2) DEFAULT NULL,
    p_critical_threshold NUMERIC(10, 2) DEFAULT NULL,
    p_is_higher_better BOOLEAN DEFAULT TRUE,
    p_display_format VARCHAR(50) DEFAULT 'percentage'
) RETURNS INTEGER AS $$
DECLARE
    v_metric_id INTEGER;
BEGIN
    -- Validate metric type
    IF p_metric_type NOT IN ('validation', 'score', 'cleansing', 'custom') THEN
        RAISE EXCEPTION 'Invalid metric type: %. Must be one of: validation, score, cleansing, custom', p_metric_type;
    END IF;

    -- Validate display format
    IF p_display_format NOT IN ('percentage', 'decimal', 'integer', 'currency', 'time') THEN
        RAISE EXCEPTION 'Invalid display format: %. Must be one of: percentage, decimal, integer, currency, time', p_display_format;
    END IF;

    -- Insert the metric
    INSERT INTO data_quality.dq_metrics (
        metric_name, description, metric_type, calculation_sql,
        target_goal, warning_threshold, critical_threshold,
        is_higher_better, display_format
    ) VALUES (
        p_metric_name, p_description, p_metric_type, p_calculation_sql,
        p_target_goal, p_warning_threshold, p_critical_threshold,
        p_is_higher_better, p_display_format
    )
    ON CONFLICT (metric_name) DO UPDATE SET
        description = p_description,
        metric_type = p_metric_type,
        calculation_sql = p_calculation_sql,
        target_goal = p_target_goal,
        warning_threshold = p_warning_threshold,
        critical_threshold = p_critical_threshold,
        is_higher_better = p_is_higher_better,
        display_format = p_display_format,
        updated_at = CURRENT_TIMESTAMP
    RETURNING metric_id INTO v_metric_id;

    RETURN v_metric_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_quality.define_metric IS 'Defines or updates a quality metric';

-- Function to record a metric value
CREATE OR REPLACE FUNCTION data_quality.record_metric_value(
    p_metric_id INTEGER,
    p_target_schema VARCHAR(255),
    p_target_table VARCHAR(255),
    p_target_column VARCHAR(255),
    p_metric_value NUMERIC(20, 6),
    p_execution_id UUID DEFAULT NULL,
    p_calculation_details JSONB DEFAULT NULL,
    p_is_baseline BOOLEAN DEFAULT FALSE
) RETURNS BIGINT AS $$
DECLARE
    v_value_id BIGINT;
    v_metric data_quality.dq_metrics%ROWTYPE;
    v_alert_level VARCHAR(20);
    v_threshold_value NUMERIC(20, 6);
    v_alert_message TEXT;
BEGIN
    -- Get metric details
    SELECT * INTO v_metric FROM data_quality.dq_metrics WHERE metric_id = p_metric_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Metric with ID % not found.', p_metric_id;
    END IF;

    -- Insert the metric value
    INSERT INTO data_quality.dq_metric_values (
        metric_id, target_schema, target_table, target_column,
        metric_value, execution_id, calculation_details, is_baseline
    ) VALUES (
        p_metric_id, p_target_schema, p_target_table, p_target_column,
        p_metric_value, p_execution_id, p_calculation_details, p_is_baseline
    ) RETURNING value_id INTO v_value_id;

    -- Check if alert should be generated
    IF v_metric.is_higher_better THEN
        -- For metrics where higher is better (e.g., completeness %)
        IF v_metric.critical_threshold IS NOT NULL AND p_metric_value <= v_metric.critical_threshold THEN
            v_alert_level := 'critical';
            v_threshold_value := v_metric.critical_threshold;
            v_alert_message := format('Critical: %s is %s, below critical threshold of %s',
                                     v_metric.metric_name, p_metric_value, v_metric.critical_threshold);
        ELSIF v_metric.warning_threshold IS NOT NULL AND p_metric_value <= v_metric.warning_threshold THEN
            v_alert_level := 'warning';
            v_threshold_value := v_metric.warning_threshold;
            v_alert_message := format('Warning: %s is %s, below warning threshold of %s',
                                     v_metric.metric_name, p_metric_value, v_metric.warning_threshold);
        END IF;
    ELSE
        -- For metrics where lower is better (e.g., error rate)
        IF v_metric.critical_threshold IS NOT NULL AND p_metric_value >= v_metric.critical_threshold THEN
            v_alert_level := 'critical';
            v_threshold_value := v_metric.critical_threshold;
            v_alert_message := format('Critical: %s is %s, above critical threshold of %s',
                                     v_metric.metric_name, p_metric_value, v_metric.critical_threshold);
        ELSIF v_metric.warning_threshold IS NOT NULL AND p_metric_value >= v_metric.warning_threshold THEN
            v_alert_level := 'warning';
            v_threshold_value := v_metric.warning_threshold;
            v_alert_message := format('Warning: %s is %s, above warning threshold of %s',
                                     v_metric.metric_name, p_metric_value, v_metric.warning_threshold);
        END IF;
    END IF;

    -- Generate alert if needed
    IF v_alert_level IS NOT NULL THEN
        INSERT INTO data_quality.dq_metric_alerts (
            metric_id, value_id, target_schema, target_table, target_column,
            alert_level, metric_value, threshold_value, alert_message
        ) VALUES (
            p_metric_id, v_value_id, p_target_schema, p_target_table, p_target_column,
            v_alert_level, p_metric_value, v_threshold_value, v_alert_message
        );

        -- Trigger notifications (placeholder for future implementation)
        -- PERFORM data_quality.send_alert_notifications(v_alert_id);
    END IF;

    RETURN v_value_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.record_metric_value IS 'Records a metric value and generates alerts if thresholds are exceeded';

-- Function to calculate and record standard metrics
CREATE OR REPLACE FUNCTION data_quality.calculate_standard_metrics(
    p_execution_id UUID
) RETURNS TABLE (
    metric_name VARCHAR(100),
    target_schema VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    metric_value NUMERIC(20, 6)
) AS $$
DECLARE
    v_metric_id INTEGER;
    v_value_id BIGINT;
    v_metric_value NUMERIC(20, 6);
    v_calculation_details JSONB;
BEGIN
    -- 1. Data Completeness Metrics
    -- Calculate completeness percentage for each column with validation results
    FOR target_schema, target_table, target_column, metric_value, calculation_details IN
        SELECT
            vl.target_schema,
            vl.target_table,
            vl.target_column,
            CASE
                WHEN vl.total_rows_checked > 0
                THEN 100.0 - vl.failed_rows_percentage
                ELSE 100.0
            END AS completeness_pct,
            jsonb_build_object(
                'total_rows', vl.total_rows_checked,
                'null_or_empty_rows', vl.failed_rows_count,
                'validation_rule', r.rule_name
            ) AS details
        FROM data_quality.dq_validation_log vl
        JOIN data_quality.dq_rules r ON vl.rule_id = r.rule_id
        JOIN data_quality.dq_validation_types vt ON r.validation_type_id = vt.validation_type_id
        WHERE vl.execution_id = p_execution_id
        AND vt.type_name = 'completeness'
    LOOP
        -- Get or create the metric
        SELECT metric_id INTO v_metric_id
        FROM data_quality.dq_metrics
        WHERE metric_name = 'Data Completeness';

        IF NOT FOUND THEN
            v_metric_id := data_quality.define_metric(
                'Data Completeness',
                'Percentage of non-null and non-empty values in a column',
                'validation',
                NULL, -- No SQL needed as this is calculated from validation results
                95.0, -- Target goal: 95% completeness
                90.0, -- Warning threshold: 90% completeness
                80.0, -- Critical threshold: 80% completeness
                TRUE, -- Higher is better
                'percentage'
            );
        END IF;

        -- Record the metric value
        v_value_id := data_quality.record_metric_value(
            v_metric_id,
            target_schema,
            target_table,
            target_column,
            metric_value,
            p_execution_id,
            calculation_details
        );

        -- Return the result
        metric_name := 'Data Completeness';
        RETURN NEXT;
    END LOOP;

    -- 2. Data Quality Score Metrics
    -- Record overall quality scores for tables
    FOR target_schema, target_table, metric_value, calculation_details IN
        SELECT
            qs.target_schema,
            qs.target_table,
            qs.score,
            jsonb_build_object(
                'execution_id', qs.execution_id,
                'score_timestamp', qs.score_timestamp,
                'calculation_details', qs.calculation_details
            ) AS details
        FROM data_quality.dq_quality_scores qs
        WHERE qs.execution_id = p_execution_id
        AND qs.target_column IS NULL
        AND qs.dimension_id IS NULL
    LOOP
        -- Get or create the metric
        SELECT metric_id INTO v_metric_id
        FROM data_quality.dq_metrics
        WHERE metric_name = 'Overall Data Quality Score';

        IF NOT FOUND THEN
            v_metric_id := data_quality.define_metric(
                'Overall Data Quality Score',
                'Composite score representing overall data quality',
                'score',
                NULL, -- No SQL needed as this is calculated from quality scores
                90.0, -- Target goal: 90 score
                80.0, -- Warning threshold: 80 score
                70.0, -- Critical threshold: 70 score
                TRUE, -- Higher is better
                'decimal'
            );
        END IF;

        -- Record the metric value
        v_value_id := data_quality.record_metric_value(
            v_metric_id,
            target_schema,
            target_table,
            NULL, -- No specific column
            metric_value,
            p_execution_id,
            calculation_details
        );

        -- Return the result
        metric_name := 'Overall Data Quality Score';
        target_column := NULL;
        RETURN NEXT;
    END LOOP;

    -- 3. Dimension-specific Quality Score Metrics
    -- Record dimension scores for tables
    FOR target_schema, target_table, dimension_name, metric_value, calculation_details IN
        SELECT
            qs.target_schema,
            qs.target_table,
            d.dimension_name,
            qs.score,
            jsonb_build_object(
                'execution_id', qs.execution_id,
                'score_timestamp', qs.score_timestamp,
                'calculation_details', qs.calculation_details
            ) AS details
        FROM data_quality.dq_quality_scores qs
        JOIN data_quality.dq_dimensions d ON qs.dimension_id = d.dimension_id
        WHERE qs.execution_id = p_execution_id
        AND qs.target_column IS NULL
        AND qs.dimension_id IS NOT NULL
    LOOP
        -- Get or create the metric
        SELECT metric_id INTO v_metric_id
        FROM data_quality.dq_metrics
        WHERE metric_name = 'Quality Score: ' || dimension_name;

        IF NOT FOUND THEN
            v_metric_id := data_quality.define_metric(
                'Quality Score: ' || dimension_name,
                'Quality score for the ' || dimension_name || ' dimension',
                'score',
                NULL, -- No SQL needed as this is calculated from quality scores
                90.0, -- Target goal: 90 score
                80.0, -- Warning threshold: 80 score
                70.0, -- Critical threshold: 70 score
                TRUE, -- Higher is better
                'decimal'
            );
        END IF;

        -- Record the metric value
        v_value_id := data_quality.record_metric_value(
            v_metric_id,
            target_schema,
            target_table,
            NULL, -- No specific column
            metric_value,
            p_execution_id,
            calculation_details
        );

        -- Return the result
        metric_name := 'Quality Score: ' || dimension_name;
        target_column := NULL;
        RETURN NEXT;
    END LOOP;

    -- 4. Data Cleansing Metrics
    -- Calculate cleansing effectiveness
    FOR target_schema, target_table, metric_value, calculation_details IN
        SELECT
            cl.target_schema,
            cl.target_table,
            CASE
                WHEN SUM(cl.total_rows_checked) > 0
                THEN (SUM(cl.rows_modified)::NUMERIC / SUM(cl.total_rows_checked)) * 100.0
                ELSE 0.0
            END AS cleansing_pct,
            jsonb_build_object(
                'total_rows_checked', SUM(cl.total_rows_checked),
                'rows_modified', SUM(cl.rows_modified),
                'cleansing_operations', COUNT(*)
            ) AS details
        FROM data_quality.dq_cleansing_log cl
        WHERE cl.execution_id = p_execution_id
        AND cl.status = 'completed'
        GROUP BY cl.target_schema, cl.target_table
    LOOP
        -- Get or create the metric
        SELECT metric_id INTO v_metric_id
        FROM data_quality.dq_metrics
        WHERE metric_name = 'Cleansing Effectiveness';

        IF NOT FOUND THEN
            v_metric_id := data_quality.define_metric(
                'Cleansing Effectiveness',
                'Percentage of rows that required cleansing',
                'cleansing',
                NULL, -- No SQL needed as this is calculated from cleansing logs
                NULL, -- No specific target
                10.0, -- Warning threshold: 10% of rows needed cleansing
                20.0, -- Critical threshold: 20% of rows needed cleansing
                FALSE, -- Lower is better (fewer rows needing cleansing)
                'percentage'
            );
        END IF;

        -- Record the metric value
        v_value_id := data_quality.record_metric_value(
            v_metric_id,
            target_schema,
            target_table,
            NULL, -- No specific column
            metric_value,
            p_execution_id,
            calculation_details
        );

        -- Return the result
        metric_name := 'Cleansing Effectiveness';
        target_column := NULL;
        RETURN NEXT;
    END LOOP;

    -- 5. Custom Metrics
    -- Execute and record custom metrics
    FOR v_metric_id, metric_name, target_schema, target_table, target_column, calculation_sql IN
        SELECT
            m.metric_id,
            m.metric_name,
            CASE WHEN m.calculation_sql LIKE '%:schema%' THEN split_part(split_part(m.calculation_sql, ':schema=''', 2), '''', 1) ELSE NULL END,
            CASE WHEN m.calculation_sql LIKE '%:table%' THEN split_part(split_part(m.calculation_sql, ':table=''', 2), '''', 1) ELSE NULL END,
            CASE WHEN m.calculation_sql LIKE '%:column%' THEN split_part(split_part(m.calculation_sql, ':column=''', 2), '''', 1) ELSE NULL END,
            m.calculation_sql
        FROM data_quality.dq_metrics m
        WHERE m.metric_type = 'custom'
        AND m.calculation_sql IS NOT NULL
    LOOP
        BEGIN
            -- Replace parameters in SQL
            v_calculation_details := jsonb_build_object('execution_id', p_execution_id);

            -- Execute the calculation SQL
            EXECUTE REPLACE(REPLACE(REPLACE(REPLACE(
                calculation_sql,
                ':execution_id', quote_literal(p_execution_id)),
                ':schema', quote_literal(target_schema)),
                ':table', quote_literal(target_table)),
                ':column', quote_literal(target_column))
            INTO v_metric_value;

            -- Record the metric value
            v_value_id := data_quality.record_metric_value(
                v_metric_id,
                target_schema,
                target_table,
                target_column,
                v_metric_value,
                p_execution_id,
                v_calculation_details
            );

            -- Return the result
            RETURN NEXT;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Error calculating custom metric %: %', metric_name, SQLERRM;
        END;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.calculate_standard_metrics IS 'Calculates and records standard metrics based on validation and cleansing results';

-- Function to acknowledge an alert
CREATE OR REPLACE FUNCTION data_quality.acknowledge_alert(
    p_alert_id BIGINT,
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_alert data_quality.dq_metric_alerts%ROWTYPE;
BEGIN
    -- Get alert record
    SELECT * INTO v_alert FROM data_quality.dq_metric_alerts WHERE alert_id = p_alert_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Alert with ID % not found.', p_alert_id;
    END IF;

    -- Check if already acknowledged
    IF v_alert.acknowledged THEN
        RAISE EXCEPTION 'Alert with ID % has already been acknowledged.', p_alert_id;
    END IF;

    -- Update alert record
    UPDATE data_quality.dq_metric_alerts
    SET
        acknowledged = TRUE,
        acknowledged_by = CURRENT_USER,
        acknowledgment_timestamp = CURRENT_TIMESTAMP,
        acknowledgment_notes = p_notes
    WHERE alert_id = p_alert_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.acknowledge_alert IS 'Acknowledges a metric alert';

-- Function to subscribe to metric alerts
CREATE OR REPLACE FUNCTION data_quality.subscribe_to_metric_alerts(
    p_metric_id INTEGER,
    p_subscriber_name VARCHAR(255),
    p_subscriber_email VARCHAR(255),
    p_target_schema VARCHAR(255) DEFAULT NULL,
    p_target_table VARCHAR(255) DEFAULT NULL,
    p_target_column VARCHAR(255) DEFAULT NULL,
    p_alert_level VARCHAR(20) DEFAULT 'all',
    p_notification_method VARCHAR(50) DEFAULT 'email',
    p_notification_config JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_subscription_id INTEGER;
BEGIN
    -- Validate metric exists
    IF NOT EXISTS (SELECT 1 FROM data_quality.dq_metrics WHERE metric_id = p_metric_id) THEN
        RAISE EXCEPTION 'Metric with ID % not found.', p_metric_id;
    END IF;

    -- Validate alert level
    IF p_alert_level NOT IN ('warning', 'critical', 'all') THEN
        RAISE EXCEPTION 'Invalid alert level: %. Must be one of: warning, critical, all', p_alert_level;
    END IF;

    -- Validate notification method
    IF p_notification_method NOT IN ('email', 'slack', 'webhook') THEN
        RAISE EXCEPTION 'Invalid notification method: %. Must be one of: email, slack, webhook', p_notification_method;
    END IF;

    -- Insert subscription
    INSERT INTO data_quality.dq_metric_subscriptions (
        metric_id, target_schema, target_table, target_column,
        alert_level, subscriber_name, subscriber_email,
        notification_method, notification_config
    ) VALUES (
        p_metric_id, p_target_schema, p_target_table, p_target_column,
        p_alert_level, p_subscriber_name, p_subscriber_email,
        p_notification_method, p_notification_config
    ) RETURNING subscription_id INTO v_subscription_id;

    RETURN v_subscription_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.subscribe_to_metric_alerts IS 'Subscribes a user to receive alerts for a specific metric';

-- Function to create a metric dashboard
CREATE OR REPLACE FUNCTION data_quality.create_metric_dashboard(
    p_dashboard_name VARCHAR(100),
    p_description TEXT DEFAULT NULL,
    p_is_public BOOLEAN DEFAULT FALSE
) RETURNS INTEGER AS $$
DECLARE
    v_dashboard_id INTEGER;
BEGIN
    -- Insert dashboard
    INSERT INTO data_quality.dq_metric_dashboards (
        dashboard_name, description, is_public
    ) VALUES (
        p_dashboard_name, p_description, p_is_public
    ) RETURNING dashboard_id INTO v_dashboard_id;

    RETURN v_dashboard_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.create_metric_dashboard IS 'Creates a new metric dashboard';

-- Function to add a metric to a dashboard
CREATE OR REPLACE FUNCTION data_quality.add_metric_to_dashboard(
    p_dashboard_id INTEGER,
    p_metric_id INTEGER,
    p_target_schema VARCHAR(255) DEFAULT NULL,
    p_target_table VARCHAR(255) DEFAULT NULL,
    p_target_column VARCHAR(255) DEFAULT NULL,
    p_display_order INTEGER DEFAULT 0,
    p_chart_type VARCHAR(50) DEFAULT 'line',
    p_chart_config JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_dashboard_metric_id INTEGER;
BEGIN
    -- Validate dashboard exists
    IF NOT EXISTS (SELECT 1 FROM data_quality.dq_metric_dashboards WHERE dashboard_id = p_dashboard_id) THEN
        RAISE EXCEPTION 'Dashboard with ID % not found.', p_dashboard_id;
    END IF;

    -- Validate metric exists
    IF NOT EXISTS (SELECT 1 FROM data_quality.dq_metrics WHERE metric_id = p_metric_id) THEN
        RAISE EXCEPTION 'Metric with ID % not found.', p_metric_id;
    END IF;

    -- Validate chart type
    IF p_chart_type NOT IN ('line', 'bar', 'gauge', 'table') THEN
        RAISE EXCEPTION 'Invalid chart type: %. Must be one of: line, bar, gauge, table', p_chart_type;
    END IF;

    -- Insert dashboard metric
    INSERT INTO data_quality.dq_dashboard_metrics (
        dashboard_id, metric_id, target_schema, target_table, target_column,
        display_order, chart_type, chart_config
    ) VALUES (
        p_dashboard_id, p_metric_id, p_target_schema, p_target_table, p_target_column,
        p_display_order, p_chart_type, p_chart_config
    )
    ON CONFLICT (dashboard_id, metric_id, target_schema, target_table, COALESCE(target_column, '')) DO UPDATE SET
        display_order = p_display_order,
        chart_type = p_chart_type,
        chart_config = p_chart_config
    RETURNING dashboard_metric_id INTO v_dashboard_metric_id;

    RETURN v_dashboard_metric_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_quality.add_metric_to_dashboard IS 'Adds a metric to a dashboard with visualization settings';

-- Step 3: Create Views for Metric Reporting

-- View for Current Metric Values
CREATE OR REPLACE VIEW data_quality.v_current_metric_values AS
WITH ranked_values AS (
    SELECT
        mv.*,
        m.metric_name,
        m.description,
        m.metric_type,
        m.target_goal,
        m.warning_threshold,
        m.critical_threshold,
        m.is_higher_better,
        m.display_format,
        ROW_NUMBER() OVER (PARTITION BY mv.metric_id, mv.target_schema, mv.target_table, mv.target_column ORDER BY mv.metric_timestamp DESC) as rn
    FROM data_quality.dq_metric_values mv
    JOIN data_quality.dq_metrics m ON mv.metric_id = m.metric_id
)
SELECT
    rv.value_id,
    rv.metric_id,
    rv.metric_name,
    rv.description,
    rv.metric_type,
    rv.target_schema,
    rv.target_table,
    rv.target_column,
    rv.metric_value,
    rv.metric_timestamp,
    rv.target_goal,
    rv.warning_threshold,
    rv.critical_threshold,
    rv.is_higher_better,
    rv.display_format,
    CASE
        WHEN rv.is_higher_better AND rv.metric_value < rv.critical_threshold THEN 'critical'
        WHEN rv.is_higher_better AND rv.metric_value < rv.warning_threshold THEN 'warning'
        WHEN NOT rv.is_higher_better AND rv.metric_value > rv.critical_threshold THEN 'critical'
        WHEN NOT rv.is_higher_better AND rv.metric_value > rv.warning_threshold THEN 'warning'
        WHEN rv.target_goal IS NOT NULL AND
             ((rv.is_higher_better AND rv.metric_value >= rv.target_goal) OR
              (NOT rv.is_higher_better AND rv.metric_value <= rv.target_goal)) THEN 'target_met'
        ELSE 'normal'
    END AS status,
    CASE
        WHEN rv.is_higher_better AND rv.target_goal IS NOT NULL
        THEN ROUND((rv.metric_value / rv.target_goal) * 100, 2)
        WHEN NOT rv.is_higher_better AND rv.target_goal IS NOT NULL AND rv.target_goal > 0
        THEN ROUND((2 - (rv.metric_value / rv.target_goal)) * 100, 2)
        ELSE NULL
    END AS goal_progress_pct,
    rv.calculation_details,
    rv.is_baseline
FROM ranked_values rv
WHERE rv.rn = 1;

COMMENT ON VIEW data_quality.v_current_metric_values IS 'Shows the latest value for each metric with status information';

-- View for Metric Trends
CREATE OR REPLACE VIEW data_quality.v_metric_trends AS
SELECT
    mv.metric_id,
    m.metric_name,
    mv.target_schema,
    mv.target_table,
    mv.target_column,
    date_trunc('day', mv.metric_timestamp) AS day,
    AVG(mv.metric_value) AS avg_value,
    MIN(mv.metric_value) AS min_value,
    MAX(mv.metric_value) AS max_value,
    COUNT(*) AS measurements_count
FROM data_quality.dq_metric_values mv
JOIN data_quality.dq_metrics m ON mv.metric_id = m.metric_id
GROUP BY
    mv.metric_id,
    m.metric_name,
    mv.target_schema,
    mv.target_table,
    mv.target_column,
    date_trunc('day', mv.metric_timestamp)
ORDER BY
    mv.metric_id,
    mv.target_schema,
    mv.target_table,
    mv.target_column,
    day;

COMMENT ON VIEW data_quality.v_metric_trends IS 'Shows daily trends for each metric';

-- View for Active Alerts
CREATE OR REPLACE VIEW data_quality.v_active_alerts AS
SELECT
    a.alert_id,
    a.metric_id,
    m.metric_name,
    a.target_schema,
    a.target_table,
    a.target_column,
    a.alert_level,
    a.metric_value,
    a.threshold_value,
    a.alert_message,
    a.alert_timestamp,
    a.acknowledged,
    a.acknowledged_by,
    a.acknowledgment_timestamp,
    a.acknowledgment_notes,
    m.is_higher_better,
    m.display_format,
    CASE
        WHEN m.is_higher_better THEN a.threshold_value - a.metric_value
        ELSE a.metric_value - a.threshold_value
    END AS threshold_deviation
FROM data_quality.dq_metric_alerts a
JOIN data_quality.dq_metrics m ON a.metric_id = m.metric_id
WHERE NOT a.acknowledged
ORDER BY a.alert_level DESC, a.alert_timestamp DESC;

COMMENT ON VIEW data_quality.v_active_alerts IS 'Shows active (unacknowledged) metric alerts';

-- View for Alert History
CREATE OR REPLACE VIEW data_quality.v_alert_history AS
SELECT
    a.alert_id,
    a.metric_id,
    m.metric_name,
    a.target_schema,
    a.target_table,
    a.target_column,
    a.alert_level,
    a.metric_value,
    a.threshold_value,
    a.alert_message,
    a.alert_timestamp,
    a.acknowledged,
    a.acknowledged_by,
    a.acknowledgment_timestamp,
    a.acknowledgment_notes,
    EXTRACT(EPOCH FROM (COALESCE(a.acknowledgment_timestamp, CURRENT_TIMESTAMP) - a.alert_timestamp)) / 3600 AS hours_to_acknowledge
FROM data_quality.dq_metric_alerts a
JOIN data_quality.dq_metrics m ON a.metric_id = m.metric_id
ORDER BY a.alert_timestamp DESC;

COMMENT ON VIEW data_quality.v_alert_history IS 'Shows historical metric alerts with acknowledgment information';

-- View for Dashboard Configuration
CREATE OR REPLACE VIEW data_quality.v_dashboard_configuration AS
SELECT
    d.dashboard_id,
    d.dashboard_name,
    d.description,
    d.is_public,
    d.created_by,
    d.created_at,
    d.updated_at,
    jsonb_agg(jsonb_build_object(
        'dashboard_metric_id', dm.dashboard_metric_id,
        'metric_id', dm.metric_id,
        'metric_name', m.metric_name,
        'target_schema', dm.target_schema,
        'target_table', dm.target_table,
        'target_column', dm.target_column,
        'display_order', dm.display_order,
        'chart_type', dm.chart_type,
        'chart_config', dm.chart_config,
        'metric_type', m.metric_type,
        'display_format', m.display_format
    ) ORDER BY dm.display_order) AS metrics
FROM data_quality.dq_metric_dashboards d
JOIN data_quality.dq_dashboard_metrics dm ON d.dashboard_id = dm.dashboard_id
JOIN data_quality.dq_metrics m ON dm.metric_id = m.metric_id
GROUP BY
    d.dashboard_id,
    d.dashboard_name,
    d.description,
    d.is_public,
    d.created_by,
    d.created_at,
    d.updated_at;

COMMENT ON VIEW data_quality.v_dashboard_configuration IS 'Shows dashboard configurations with metrics';

-- View for Data Quality Improvement Tracking
CREATE OR REPLACE VIEW data_quality.v_quality_improvement_tracking AS
WITH baseline AS (
    SELECT
        metric_id,
        target_schema,
        target_table,
        target_column,
        metric_value AS baseline_value,
        metric_timestamp AS baseline_timestamp
    FROM data_quality.dq_metric_values
    WHERE is_baseline = TRUE
),
current AS (
    SELECT
        mv.metric_id,
        mv.target_schema,
        mv.target_table,
        mv.target_column,
        mv.metric_value AS current_value,
        mv.metric_timestamp AS current_timestamp
    FROM data_quality.dq_metric_values mv
    JOIN (
        SELECT
            metric_id,
            target_schema,
            target_table,
            target_column,
            MAX(metric_timestamp) AS latest_timestamp
        FROM data_quality.dq_metric_values
        WHERE is_baseline = FALSE
        GROUP BY
            metric_id,
            target_schema,
            target_table,
            target_column
    ) latest ON
        mv.metric_id = latest.metric_id AND
        mv.target_schema = latest.target_schema AND
        mv.target_table = latest.target_table AND
        COALESCE(mv.target_column, '') = COALESCE(latest.target_column, '') AND
        mv.metric_timestamp = latest.latest_timestamp
)
SELECT
    m.metric_id,
    m.metric_name,
    c.target_schema,
    c.target_table,
    c.target_column,
    b.baseline_value,
    b.baseline_timestamp,
    c.current_value,
    c.current_timestamp,
    c.current_value - b.baseline_value AS absolute_change,
    CASE
        WHEN b.baseline_value <> 0
        THEN ROUND(((c.current_value - b.baseline_value) / ABS(b.baseline_value)) * 100, 2)
        ELSE NULL
    END AS percentage_change,
    CASE
        WHEN m.is_higher_better AND c.current_value > b.baseline_value THEN 'improved'
        WHEN m.is_higher_better AND c.current_value < b.baseline_value THEN 'degraded'
        WHEN NOT m.is_higher_better AND c.current_value < b.baseline_value THEN 'improved'
        WHEN NOT m.is_higher_better AND c.current_value > b.baseline_value THEN 'degraded'
        ELSE 'unchanged'
    END AS change_status,
    EXTRACT(EPOCH FROM (c.current_timestamp - b.baseline_timestamp)) / 86400 AS days_since_baseline
FROM current c
JOIN baseline b ON
    c.metric_id = b.metric_id AND
    c.target_schema = b.target_schema AND
    c.target_table = b.target_table AND
    COALESCE(c.target_column, '') = COALESCE(b.target_column, '')
JOIN data_quality.dq_metrics m ON c.metric_id = m.metric_id
ORDER BY
    CASE change_status
        WHEN 'degraded' THEN 1
        WHEN 'unchanged' THEN 2
        WHEN 'improved' THEN 3
    END,
    ABS(percentage_change) DESC;

COMMENT ON VIEW data_quality.v_quality_improvement_tracking IS 'Tracks improvement or degradation of metrics compared to baseline';

-- Step 4: Initialize Metric Tracking Framework

-- Define standard metrics
SELECT data_quality.define_metric(
    'Data Completeness',
    'Percentage of non-null and non-empty values in a column',
    'validation',
    NULL, -- No SQL needed as this is calculated from validation results
    95.0, -- Target goal: 95% completeness
    90.0, -- Warning threshold: 90% completeness
    80.0, -- Critical threshold: 80% completeness
    TRUE, -- Higher is better
    'percentage'
);

SELECT data_quality.define_metric(
    'Overall Data Quality Score',
    'Composite score representing overall data quality',
    'score',
    NULL, -- No SQL needed as this is calculated from quality scores
    90.0, -- Target goal: 90 score
    80.0, -- Warning threshold: 80 score
    70.0, -- Critical threshold: 70 score
    TRUE, -- Higher is better
    'decimal'
);

SELECT data_quality.define_metric(
    'Cleansing Effectiveness',
    'Percentage of rows that required cleansing',
    'cleansing',
    NULL, -- No SQL needed as this is calculated from cleansing logs
    NULL, -- No specific target
    10.0, -- Warning threshold: 10% of rows needed cleansing
    20.0, -- Critical threshold: 20% of rows needed cleansing
    FALSE, -- Lower is better (fewer rows needing cleansing)
    'percentage'
);

-- Example custom metric: Average number of trouble codes per vehicle
SELECT data_quality.define_metric(
    'Average Trouble Codes Per Vehicle',
    'Average number of trouble codes reported per vehicle',
    'custom',
    'SELECT AVG(code_count) FROM (
        SELECT vehicle_id, COUNT(*) as code_count
        FROM public.TroubleCodes
        GROUP BY vehicle_id
    ) t',
    NULL, -- No specific target
    5.0,  -- Warning threshold: 5 codes per vehicle
    10.0, -- Critical threshold: 10 codes per vehicle
    FALSE, -- Lower is better
    'decimal'
);

-- Create example dashboard
SELECT data_quality.create_metric_dashboard(
    'Data Quality Overview',
    'Overview of key data quality metrics',
    TRUE -- Public dashboard
);

-- Add metrics to dashboard
SELECT data_quality.add_metric_to_dashboard(
    1, -- Dashboard ID
    1, -- Metric ID (Data Completeness)
    'public',
    'Users',
    'email',
    1, -- Display order
    'line', -- Chart type
    '{"title": "Email Completeness Trend", "y_axis_label": "Completeness %"}'::JSONB
);

SELECT data_quality.add_metric_to_dashboard(
    1, -- Dashboard ID
    2, -- Metric ID (Overall Data Quality Score)
    'public',
    'Users',
    NULL,
    2, -- Display order
    'gauge', -- Chart type
    '{"title": "Users Table Quality Score", "min": 0, "max": 100, "thresholds": [70, 80, 90]}'::JSONB
);

-- Add documentation comments
COMMENT ON SCHEMA data_quality IS 'Schema for comprehensive data quality management, including validation, scoring, cleansing, and monitoring';

-- PostgreSQL Data Lineage Framework
-- This implementation provides:
-- 1. Comprehensive tracking of data origins and transformations
-- 2. Visualization and querying tools for data lineage

-- Step 1: Create Data Lineage Schema
CREATE SCHEMA IF NOT EXISTS data_lineage;
COMMENT ON SCHEMA data_lineage IS 'Schema for data lineage tracking and visualization';

-- Step 2: Create Core Data Lineage Tables

-- Data Sources Table
CREATE TABLE data_lineage.dl_sources (
    source_id SERIAL PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL UNIQUE,
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('database', 'file', 'api', 'manual', 'etl', 'application', 'other')),
    connection_details JSONB,
    description TEXT,
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dl_sources_type ON data_lineage.dl_sources (source_type);
CREATE INDEX idx_dl_sources_active ON data_lineage.dl_sources (is_active);

COMMENT ON TABLE data_lineage.dl_sources IS 'Defines data sources for lineage tracking';

-- Data Entities Table
CREATE TABLE data_lineage.dl_entities (
    entity_id SERIAL PRIMARY KEY,
    entity_name VARCHAR(255) NOT NULL,
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('table', 'view', 'column', 'file', 'dataset', 'report', 'api', 'other')),
    schema_name VARCHAR(255),
    table_name VARCHAR(255),
    column_name VARCHAR(255),
    entity_path TEXT,
    description TEXT,
    business_definition TEXT,
    sensitivity_level VARCHAR(20) CHECK (sensitivity_level IN ('public', 'internal', 'confidential', 'restricted', 'pii')),
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_entity UNIQUE (entity_type, schema_name, table_name, column_name)
);

CREATE INDEX idx_dl_entities_type ON data_lineage.dl_entities (entity_type);
CREATE INDEX idx_dl_entities_schema_table ON data_lineage.dl_entities (schema_name, table_name);
CREATE INDEX idx_dl_entities_active ON data_lineage.dl_entities (is_active);
CREATE INDEX idx_dl_entities_sensitivity ON data_lineage.dl_entities (sensitivity_level);

COMMENT ON TABLE data_lineage.dl_entities IS 'Defines data entities for lineage tracking';

-- Data Transformations Table
CREATE TABLE data_lineage.dl_transformations (
    transformation_id SERIAL PRIMARY KEY,
    transformation_name VARCHAR(100) NOT NULL,
    transformation_type VARCHAR(50) NOT NULL CHECK (transformation_type IN ('etl', 'query', 'procedure', 'function', 'trigger', 'application', 'manual', 'other')),
    description TEXT,
    transformation_logic TEXT,
    transformation_sql TEXT,
    parameters JSONB,
    owner VARCHAR(255),
    schedule_info JSONB,
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dl_transformations_type ON data_lineage.dl_transformations (transformation_type);
CREATE INDEX idx_dl_transformations_active ON data_lineage.dl_transformations (is_active);

COMMENT ON TABLE data_lineage.dl_transformations IS 'Defines data transformations for lineage tracking';

-- Lineage Relationships Table
CREATE TABLE data_lineage.dl_lineage (
    lineage_id SERIAL PRIMARY KEY,
    source_entity_id INTEGER NOT NULL REFERENCES data_lineage.dl_entities(entity_id),
    target_entity_id INTEGER NOT NULL REFERENCES data_lineage.dl_entities(entity_id),
    transformation_id INTEGER REFERENCES data_lineage.dl_transformations(transformation_id),
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN ('direct', 'derived', 'aggregated', 'filtered', 'joined', 'lookup', 'calculated', 'other')),
    confidence_score NUMERIC(5, 2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    impact_level VARCHAR(20) CHECK (impact_level IN ('none', 'low', 'medium', 'high', 'critical')),
    transformation_rule TEXT,
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    effective_to TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_lineage_relationship UNIQUE (source_entity_id, target_entity_id, transformation_id, relationship_type, COALESCE(effective_from, '1900-01-01'::TIMESTAMP WITH TIME ZONE))
);

CREATE INDEX idx_dl_lineage_source ON data_lineage.dl_lineage (source_entity_id);
CREATE INDEX idx_dl_lineage_target ON data_lineage.dl_lineage (target_entity_id);
CREATE INDEX idx_dl_lineage_transformation ON data_lineage.dl_lineage (transformation_id);
CREATE INDEX idx_dl_lineage_relationship ON data_lineage.dl_lineage (relationship_type);
CREATE INDEX idx_dl_lineage_active ON data_lineage.dl_lineage (is_active);
CREATE INDEX idx_dl_lineage_effective ON data_lineage.dl_lineage (effective_from, effective_to);

COMMENT ON TABLE data_lineage.dl_lineage IS 'Defines lineage relationships between data entities';

-- Lineage Execution Log Table
CREATE TABLE data_lineage.dl_execution_log (
    execution_id SERIAL PRIMARY KEY,
    transformation_id INTEGER REFERENCES data_lineage.dl_transformations(transformation_id),
    execution_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_status VARCHAR(20) NOT NULL CHECK (execution_status IN ('started', 'completed', 'failed', 'aborted')),
    execution_duration INTERVAL,
    rows_processed BIGINT,
    error_message TEXT,
    execution_details JSONB,
    executed_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dl_execution_log_transformation ON data_lineage.dl_execution_log (transformation_id);
CREATE INDEX idx_dl_execution_log_timestamp ON data_lineage.dl_execution_log (execution_timestamp);
CREATE INDEX idx_dl_execution_log_status ON data_lineage.dl_execution_log (execution_status);

COMMENT ON TABLE data_lineage.dl_execution_log IS 'Logs execution of data transformations for lineage tracking';

-- Data Quality Impact Table
CREATE TABLE data_lineage.dl_quality_impact (
    impact_id SERIAL PRIMARY KEY,
    lineage_id INTEGER NOT NULL REFERENCES data_lineage.dl_lineage(lineage_id),
    quality_dimension VARCHAR(50) NOT NULL CHECK (quality_dimension IN ('completeness', 'accuracy', 'consistency', 'timeliness', 'uniqueness', 'validity', 'integrity')),
    impact_type VARCHAR(20) NOT NULL CHECK (impact_type IN ('improves', 'degrades', 'maintains', 'unknown')),
    impact_score NUMERIC(5, 2) CHECK (impact_score >= -100 AND impact_score <= 100),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dl_quality_impact_lineage ON data_lineage.dl_quality_impact (lineage_id);
CREATE INDEX idx_dl_quality_impact_dimension ON data_lineage.dl_quality_impact (quality_dimension);
CREATE INDEX idx_dl_quality_impact_type ON data_lineage.dl_quality_impact (impact_type);

COMMENT ON TABLE data_lineage.dl_quality_impact IS 'Tracks impact of transformations on data quality dimensions';

-- Business Glossary Table
CREATE TABLE data_lineage.dl_business_glossary (
    term_id SERIAL PRIMARY KEY,
    term_name VARCHAR(100) NOT NULL UNIQUE,
    definition TEXT NOT NULL,
    abbreviation VARCHAR(50),
    domain VARCHAR(100),
    steward VARCHAR(255),
    status VARCHAR(20) CHECK (status IN ('draft', 'approved', 'deprecated', 'retired')),
    version VARCHAR(20),
    related_terms INTEGER[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    approved_by VARCHAR(255),
    approval_date TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_dl_business_glossary_domain ON data_lineage.dl_business_glossary (domain);
CREATE INDEX idx_dl_business_glossary_status ON data_lineage.dl_business_glossary (status);

COMMENT ON TABLE data_lineage.dl_business_glossary IS 'Business glossary for data lineage context';

-- Business Term to Entity Mapping Table
CREATE TABLE data_lineage.dl_term_entity_mapping (
    mapping_id SERIAL PRIMARY KEY,
    term_id INTEGER NOT NULL REFERENCES data_lineage.dl_business_glossary(term_id),
    entity_id INTEGER NOT NULL REFERENCES data_lineage.dl_entities(entity_id),
    relationship_type VARCHAR(50) DEFAULT 'associated' CHECK (relationship_type IN ('defines', 'associated', 'related', 'impacts')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_term_entity_mapping UNIQUE (term_id, entity_id)
);

CREATE INDEX idx_dl_term_entity_mapping_term ON data_lineage.dl_term_entity_mapping (term_id);
CREATE INDEX idx_dl_term_entity_mapping_entity ON data_lineage.dl_term_entity_mapping (entity_id);

COMMENT ON TABLE data_lineage.dl_term_entity_mapping IS 'Maps business terms to data entities';

-- Lineage Tags Table
CREATE TABLE data_lineage.dl_tags (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(100) NOT NULL UNIQUE,
    tag_category VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER
);

CREATE INDEX idx_dl_tags_category ON data_lineage.dl_tags (tag_category);

COMMENT ON TABLE data_lineage.dl_tags IS 'Tags for categorizing lineage entities';

-- Entity Tags Mapping Table
CREATE TABLE data_lineage.dl_entity_tags (
    entity_tag_id SERIAL PRIMARY KEY,
    entity_id INTEGER NOT NULL REFERENCES data_lineage.dl_entities(entity_id),
    tag_id INTEGER NOT NULL REFERENCES data_lineage.dl_tags(tag_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT CURRENT_USER,
    CONSTRAINT unique_entity_tag UNIQUE (entity_id, tag_id)
);

CREATE INDEX idx_dl_entity_tags_entity ON data_lineage.dl_entity_tags (entity_id);
CREATE INDEX idx_dl_entity_tags_tag ON data_lineage.dl_entity_tags (tag_id);

COMMENT ON TABLE data_lineage.dl_entity_tags IS 'Maps tags to data entities';

-- Lineage Visualization Settings Table
CREATE TABLE data_lineage.dl_visualization_settings (
    setting_id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    setting_name VARCHAR(100) NOT NULL,
    setting_type VARCHAR(50) NOT NULL CHECK (setting_type IN ('layout', 'color', 'filter', 'grouping', 'other')),
    setting_value JSONB NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_setting UNIQUE (user_id, setting_name)
);

CREATE INDEX idx_dl_visualization_settings_user ON data_lineage.dl_visualization_settings (user_id);
CREATE INDEX idx_dl_visualization_settings_type ON data_lineage.dl_visualization_settings (setting_type);
CREATE INDEX idx_dl_visualization_settings_default ON data_lineage.dl_visualization_settings (is_default);

COMMENT ON TABLE data_lineage.dl_visualization_settings IS 'User settings for lineage visualization';

-- Step 3: Create Core Functions for Data Lineage

-- Function to register a data source
CREATE OR REPLACE FUNCTION data_lineage.register_source(
    p_source_name VARCHAR(100),
    p_source_type VARCHAR(50),
    p_connection_details JSONB DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_source_id INTEGER;
BEGIN
    -- Validate source type
    IF p_source_type NOT IN ('database', 'file', 'api', 'manual', 'etl', 'application', 'other') THEN
        RAISE EXCEPTION 'Invalid source type: %. Must be one of: database, file, api, manual, etl, application, other', p_source_type;
    END IF;

    -- Insert the source
    INSERT INTO data_lineage.dl_sources (
        source_name, source_type, connection_details, description, metadata
    ) VALUES (
        p_source_name, p_source_type, p_connection_details, p_description, p_metadata
    )
    ON CONFLICT (source_name) DO UPDATE SET
        source_type = p_source_type,
        connection_details = p_connection_details,
        description = p_description,
        metadata = p_metadata,
        updated_at = CURRENT_TIMESTAMP
    RETURNING source_id INTO v_source_id;

    RETURN v_source_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_lineage.register_source IS 'Registers or updates a data source for lineage tracking';

-- Function to register a data entity
CREATE OR REPLACE FUNCTION data_lineage.register_entity(
    p_entity_name VARCHAR(255),
    p_entity_type VARCHAR(50),
    p_schema_name VARCHAR(255) DEFAULT NULL,
    p_table_name VARCHAR(255) DEFAULT NULL,
    p_column_name VARCHAR(255) DEFAULT NULL,
    p_entity_path TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_business_definition TEXT DEFAULT NULL,
    p_sensitivity_level VARCHAR(20) DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_entity_id INTEGER;
BEGIN
    -- Validate entity type
    IF p_entity_type NOT IN ('table', 'view', 'column', 'file', 'dataset', 'report', 'api', 'other') THEN
        RAISE EXCEPTION 'Invalid entity type: %. Must be one of: table, view, column, file, dataset, report, api, other', p_entity_type;
    END IF;

    -- Validate sensitivity level if provided
    IF p_sensitivity_level IS NOT NULL AND p_sensitivity_level NOT IN ('public', 'internal', 'confidential', 'restricted', 'pii') THEN
        RAISE EXCEPTION 'Invalid sensitivity level: %. Must be one of: public, internal, confidential, restricted, pii', p_sensitivity_level;
    END IF;

    -- Insert the entity
    INSERT INTO data_lineage.dl_entities (
        entity_name, entity_type, schema_name, table_name, column_name,
        entity_path, description, business_definition, sensitivity_level, metadata
    ) VALUES (
        p_entity_name, p_entity_type, p_schema_name, p_table_name, p_column_name,
        p_entity_path, p_description, p_business_definition, p_sensitivity_level, p_metadata
    )
    ON CONFLICT (entity_type, schema_name, table_name, column_name) DO UPDATE SET
        entity_name = p_entity_name,
        entity_path = p_entity_path,
        description = p_description,
        business_definition = p_business_definition,
        sensitivity_level = p_sensitivity_level,
        metadata = p_metadata,
        updated_at = CURRENT_TIMESTAMP
    RETURNING entity_id INTO v_entity_id;

    RETURN v_entity_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_lineage.register_entity IS 'Registers or updates a data entity for lineage tracking';

-- Function to register a data transformation
CREATE OR REPLACE FUNCTION data_lineage.register_transformation(
    p_transformation_name VARCHAR(100),
    p_transformation_type VARCHAR(50),
    p_description TEXT DEFAULT NULL,
    p_transformation_logic TEXT DEFAULT NULL,
    p_transformation_sql TEXT DEFAULT NULL,
    p_parameters JSONB DEFAULT NULL,
    p_owner VARCHAR(255) DEFAULT NULL,
    p_schedule_info JSONB DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_transformation_id INTEGER;
BEGIN
    -- Validate transformation type
    IF p_transformation_type NOT IN ('etl', 'query', 'procedure', 'function', 'trigger', 'application', 'manual', 'other') THEN
        RAISE EXCEPTION 'Invalid transformation type: %. Must be one of: etl, query, procedure, function, trigger, application, manual, other', p_transformation_type;
    END IF;

    -- Insert the transformation
    INSERT INTO data_lineage.dl_transformations (
        transformation_name, transformation_type, description, transformation_logic,
        transformation_sql, parameters, owner, schedule_info, metadata
    ) VALUES (
        p_transformation_name, p_transformation_type, p_description, p_transformation_logic,
        p_transformation_sql, p_parameters, p_owner, p_schedule_info, p_metadata
    )
    ON CONFLICT (transformation_name) DO UPDATE SET
        transformation_type = p_transformation_type,
        description = p_description,
        transformation_logic = p_transformation_logic,
        transformation_sql = p_transformation_sql,
        parameters = p_parameters,
        owner = p_owner,
        schedule_info = p_schedule_info,
        metadata = p_metadata,
        updated_at = CURRENT_TIMESTAMP
    RETURNING transformation_id INTO v_transformation_id;

    RETURN v_transformation_id;
EXCEPTION
    WHEN unique_violation THEN
        -- Handle the case where transformation_name is not unique
        UPDATE data_lineage.dl_transformations
        SET transformation_name = p_transformation_name || '_' || nextval('data_lineage.dl_transformations_transformation_id_seq'::regclass)::text
        WHERE transformation_id = (
            SELECT transformation_id
            FROM data_lineage.dl_transformations
            WHERE transformation_name = p_transformation_name
        );

        -- Try insert again
        INSERT INTO data_lineage.dl_transformations (
            transformation_name, transformation_type, description, transformation_logic,
            transformation_sql, parameters, owner, schedule_info, metadata
        ) VALUES (
            p_transformation_name, p_transformation_type, p_description, p_transformation_logic,
            p_transformation_sql, p_parameters, p_owner, p_schedule_info, p_metadata
        )
        RETURNING transformation_id INTO v_transformation_id;

        RETURN v_transformation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_lineage.register_transformation IS 'Registers or updates a data transformation for lineage tracking';

-- Function to register a lineage relationship
CREATE OR REPLACE FUNCTION data_lineage.register_lineage(
    p_source_entity_id INTEGER,
    p_target_entity_id INTEGER,
    p_transformation_id INTEGER DEFAULT NULL,
    p_relationship_type VARCHAR(50) DEFAULT 'direct',
    p_confidence_score NUMERIC(5, 2) DEFAULT 100.0,
    p_impact_level VARCHAR(20) DEFAULT NULL,
    p_transformation_rule TEXT DEFAULT NULL,
    p_effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    p_effective_to TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_lineage_id INTEGER;
BEGIN
    -- Validate relationship type
    IF p_relationship_type NOT IN ('direct', 'derived', 'aggregated', 'filtered', 'joined', 'lookup', 'calculated', 'other') THEN
        RAISE EXCEPTION 'Invalid relationship type: %. Must be one of: direct, derived, aggregated, filtered, joined, lookup, calculated, other', p_relationship_type;
    END IF;

    -- Validate impact level if provided
    IF p_impact_level IS NOT NULL AND p_impact_level NOT IN ('none', 'low', 'medium', 'high', 'critical') THEN
        RAISE EXCEPTION 'Invalid impact level: %. Must be one of: none, low, medium, high, critical', p_impact_level;
    END IF;

    -- Validate confidence score
    IF p_confidence_score < 0 OR p_confidence_score > 100 THEN
        RAISE EXCEPTION 'Invalid confidence score: %. Must be between 0 and 100', p_confidence_score;
    END IF;

    -- Insert the lineage relationship
    INSERT INTO data_lineage.dl_lineage (
        source_entity_id, target_entity_id, transformation_id, relationship_type,
        confidence_score, impact_level, transformation_rule, effective_from, effective_to, metadata
    ) VALUES (
        p_source_entity_id, p_target_entity_id, p_transformation_id, p_relationship_type,
        p_confidence_score, p_impact_level, p_transformation_rule, p_effective_from, p_effective_to, p_metadata
    )
    ON CONFLICT (source_entity_id, target_entity_id, transformation_id, relationship_type, COALESCE(effective_from, '1900-01-01'::TIMESTAMP WITH TIME ZONE)) DO UPDATE SET
        confidence_score = p_confidence_score,
        impact_level = p_impact_level,
        transformation_rule = p_transformation_rule,
        effective_to = p_effective_to,
        metadata = p_metadata,
        updated_at = CURRENT_TIMESTAMP
    RETURNING lineage_id INTO v_lineage_id;

    RETURN v_lineage_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION data_lineage.register_lineage IS 'Registers or updates a lineage relationship between data entities';

-- Function to log transformation execution
CREATE OR REPLACE FUNCTION data_lineage.log_transformation_execution(
    p_transformation_id INTEGER,
    p_execution_status VARCHAR(20),
    p_execution_duration INTERVAL DEFAULT NULL,
    p_rows_processed BIGINT DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL,
    p_execution_details JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_execution_id INTEGER;
BEGIN
    -- Validate execution status
    IF p_execution_status NOT IN ('started', 'completed', 'failed', 'aborted') THEN
        RAISE EXCEPTION 'Invalid execution status: %. Must be one of: started, completed, failed, aborted', p_execution_status;
    END IF;

    -- Insert the execution log
    INSERT INTO data_lineage.dl_execution_log (
        transformation_id, execution_status, execution_duration,
        rows_processed, error_message, execution_details
    ) VALUES (
        p_transformation_id, p_execution_status, p_execution_duration,
        p_rows_processed, p_error_message, p_execution_details
    )
    RETURNING execution_id INTO v_execution_id;

    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.log_transformation_execution IS 'Logs the execution of a data transformation';

-- Function to register quality impact
CREATE OR REPLACE FUNCTION data_lineage.register_quality_impact(
    p_lineage_id INTEGER,
    p_quality_dimension VARCHAR(50),
    p_impact_type VARCHAR(20),
    p_impact_score NUMERIC(5, 2) DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_impact_id INTEGER;
BEGIN
    -- Validate quality dimension
    IF p_quality_dimension NOT IN ('completeness', 'accuracy', 'consistency', 'timeliness', 'uniqueness', 'validity', 'integrity') THEN
        RAISE EXCEPTION 'Invalid quality dimension: %. Must be one of: completeness, accuracy, consistency, timeliness, uniqueness, validity, integrity', p_quality_dimension;
    END IF;

    -- Validate impact type
    IF p_impact_type NOT IN ('improves', 'degrades', 'maintains', 'unknown') THEN
        RAISE EXCEPTION 'Invalid impact type: %. Must be one of: improves, degrades, maintains, unknown', p_impact_type;
    END IF;

    -- Validate impact score if provided
    IF p_impact_score IS NOT NULL AND (p_impact_score < -100 OR p_impact_score > 100) THEN
        RAISE EXCEPTION 'Invalid impact score: %. Must be between -100 and 100', p_impact_score;
    END IF;

    -- Insert the quality impact
    INSERT INTO data_lineage.dl_quality_impact (
        lineage_id, quality_dimension, impact_type, impact_score, description
    ) VALUES (
        p_lineage_id, p_quality_dimension, p_impact_type, p_impact_score, p_description
    )
    RETURNING impact_id INTO v_impact_id;

    RETURN v_impact_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.register_quality_impact IS 'Registers the impact of a lineage relationship on data quality';

-- Function to add a business glossary term
CREATE OR REPLACE FUNCTION data_lineage.add_business_term(
    p_term_name VARCHAR(100),
    p_definition TEXT,
    p_abbreviation VARCHAR(50) DEFAULT NULL,
    p_domain VARCHAR(100) DEFAULT NULL,
    p_steward VARCHAR(255) DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT 'draft',
    p_version VARCHAR(20) DEFAULT '1.0',
    p_related_terms INTEGER[] DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_term_id INTEGER;
BEGIN
    -- Validate status
    IF p_status NOT IN ('draft', 'approved', 'deprecated', 'retired') THEN
        RAISE EXCEPTION 'Invalid status: %. Must be one of: draft, approved, deprecated, retired', p_status;
    END IF;

    -- Insert the business term
    INSERT INTO data_lineage.dl_business_glossary (
        term_name, definition, abbreviation, domain, steward, status, version, related_terms
    ) VALUES (
        p_term_name, p_definition, p_abbreviation, p_domain, p_steward, p_status, p_version, p_related_terms
    )
    ON CONFLICT (term_name) DO UPDATE SET
        definition = p_definition,
        abbreviation = p_abbreviation,
        domain = p_domain,
        steward = p_steward,
        status = p_status,
        version = p_version,
        related_terms = p_related_terms,
        updated_at = CURRENT_TIMESTAMP
    RETURNING term_id INTO v_term_id;

    RETURN v_term_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.add_business_term IS 'Adds or updates a business glossary term';

-- Function to map business term to entity
CREATE OR REPLACE FUNCTION data_lineage.map_term_to_entity(
    p_term_id INTEGER,
    p_entity_id INTEGER,
    p_relationship_type VARCHAR(50) DEFAULT 'associated'
) RETURNS INTEGER AS $$
DECLARE
    v_mapping_id INTEGER;
BEGIN
    -- Validate relationship type
    IF p_relationship_type NOT IN ('defines', 'associated', 'related', 'impacts') THEN
        RAISE EXCEPTION 'Invalid relationship type: %. Must be one of: defines, associated, related, impacts', p_relationship_type;
    END IF;

    -- Insert the mapping
    INSERT INTO data_lineage.dl_term_entity_mapping (
        term_id, entity_id, relationship_type
    ) VALUES (
        p_term_id, p_entity_id, p_relationship_type
    )
    ON CONFLICT (term_id, entity_id) DO UPDATE SET
        relationship_type = p_relationship_type
    RETURNING mapping_id INTO v_mapping_id;

    RETURN v_mapping_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.map_term_to_entity IS 'Maps a business glossary term to a data entity';

-- Function to add a tag
CREATE OR REPLACE FUNCTION data_lineage.add_tag(
    p_tag_name VARCHAR(100),
    p_tag_category VARCHAR(100) DEFAULT NULL,
    p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_tag_id INTEGER;
BEGIN
    -- Insert the tag
    INSERT INTO data_lineage.dl_tags (
        tag_name, tag_category, description
    ) VALUES (
        p_tag_name, p_tag_category, p_description
    )
    ON CONFLICT (tag_name) DO UPDATE SET
        tag_category = p_tag_category,
        description = p_description
    RETURNING tag_id INTO v_tag_id;

    RETURN v_tag_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.add_tag IS 'Adds or updates a tag for lineage categorization';

-- Function to tag an entity
CREATE OR REPLACE FUNCTION data_lineage.tag_entity(
    p_entity_id INTEGER,
    p_tag_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_entity_tag_id INTEGER;
BEGIN
    -- Insert the entity tag mapping
    INSERT INTO data_lineage.dl_entity_tags (
        entity_id, tag_id
    ) VALUES (
        p_entity_id, p_tag_id
    )
    ON CONFLICT (entity_id, tag_id) DO NOTHING
    RETURNING entity_tag_id INTO v_entity_tag_id;

    RETURN v_entity_tag_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.tag_entity IS 'Tags a data entity';

-- Function to save visualization settings
CREATE OR REPLACE FUNCTION data_lineage.save_visualization_settings(
    p_user_id VARCHAR(255),
    p_setting_name VARCHAR(100),
    p_setting_type VARCHAR(50),
    p_setting_value JSONB,
    p_is_default BOOLEAN DEFAULT FALSE
) RETURNS INTEGER AS $$
DECLARE
    v_setting_id INTEGER;
BEGIN
    -- Validate setting type
    IF p_setting_type NOT IN ('layout', 'color', 'filter', 'grouping', 'other') THEN
        RAISE EXCEPTION 'Invalid setting type: %. Must be one of: layout, color, filter, grouping, other', p_setting_type;
    END IF;

    -- Insert the visualization setting
    INSERT INTO data_lineage.dl_visualization_settings (
        user_id, setting_name, setting_type, setting_value, is_default
    ) VALUES (
        p_user_id, p_setting_name, p_setting_type, p_setting_value, p_is_default
    )
    ON CONFLICT (user_id, setting_name) DO UPDATE SET
        setting_type = p_setting_type,
        setting_value = p_setting_value,
        is_default = p_is_default,
        updated_at = CURRENT_TIMESTAMP
    RETURNING setting_id INTO v_setting_id;

    RETURN v_setting_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.save_visualization_settings IS 'Saves user settings for lineage visualization';

-- Step 4: Create Functions for Automatic Lineage Discovery

-- Function to discover table-level lineage from SQL
CREATE OR REPLACE FUNCTION data_lineage.discover_lineage_from_sql(
    p_sql TEXT,
    p_transformation_name VARCHAR(100),
    p_confidence_score NUMERIC(5, 2) DEFAULT 80.0
) RETURNS TABLE (
    lineage_id INTEGER,
    source_entity_name VARCHAR(255),
    target_entity_name VARCHAR(255),
    relationship_type VARCHAR(50)
) AS $$
DECLARE
    v_transformation_id INTEGER;
    v_source_tables TEXT[];
    v_target_tables TEXT[];
    v_source_entity_id INTEGER;
    v_target_entity_id INTEGER;
    v_lineage_id INTEGER;
    v_source_schema TEXT;
    v_source_table TEXT;
    v_target_schema TEXT;
    v_target_table TEXT;
    v_relationship_type VARCHAR(50);
BEGIN
    -- Register the transformation
    v_transformation_id := data_lineage.register_transformation(
        p_transformation_name,
        'query',
        'Automatically discovered from SQL',
        NULL,
        p_sql,
        NULL,
        CURRENT_USER,
        NULL,
        jsonb_build_object('discovery_method', 'automatic', 'discovery_timestamp', CURRENT_TIMESTAMP)
    );

    -- Extract source tables from SQL
    -- This is a simplified approach; a real implementation would use a SQL parser
    v_source_tables := ARRAY(
        SELECT DISTINCT table_name
        FROM regexp_matches(lower(p_sql), 'from\s+([a-z0-9_\.]+)', 'g') AS t(table_name)
        UNION
        SELECT DISTINCT table_name
        FROM regexp_matches(lower(p_sql), 'join\s+([a-z0-9_\.]+)', 'g') AS t(table_name)
    );

    -- Extract target tables from SQL (assuming INSERT INTO or CREATE TABLE AS)
    v_target_tables := ARRAY(
        SELECT DISTINCT table_name
        FROM regexp_matches(lower(p_sql), 'insert\s+into\s+([a-z0-9_\.]+)', 'g') AS t(table_name)
        UNION
        SELECT DISTINCT table_name
        FROM regexp_matches(lower(p_sql), 'create\s+table\s+([a-z0-9_\.]+)', 'g') AS t(table_name)
        UNION
        SELECT DISTINCT table_name
        FROM regexp_matches(lower(p_sql), 'update\s+([a-z0-9_\.]+)', 'g') AS t(table_name)
    );

    -- If no target tables found, assume it's a SELECT query for reporting
    IF array_length(v_target_tables, 1) IS NULL THEN
        v_target_tables := ARRAY['report.query_result'];
    END IF;

    -- Determine relationship type based on SQL
    IF p_sql ~* 'group by' THEN
        v_relationship_type := 'aggregated';
    ELSIF p_sql ~* 'join' THEN
        v_relationship_type := 'joined';
    ELSIF p_sql ~* 'where' THEN
        v_relationship_type := 'filtered';
    ELSE
        v_relationship_type := 'direct';
    END IF;

    -- Register lineage for each source-target pair
    FOREACH v_source_table IN ARRAY v_source_tables
    LOOP
        -- Parse schema and table
        IF v_source_table LIKE '%.%' THEN
            v_source_schema := split_part(v_source_table, '.', 1);
            v_source_table := split_part(v_source_table, '.', 2);
        ELSE
            v_source_schema := 'public';
        END IF;

        -- Register source entity
        v_source_entity_id := data_lineage.register_entity(
            v_source_table,
            'table',
            v_source_schema,
            v_source_table,
            NULL,
            v_source_schema || '.' || v_source_table,
            'Automatically discovered from SQL',
            NULL,
            NULL,
            jsonb_build_object('discovery_method', 'automatic', 'discovery_timestamp', CURRENT_TIMESTAMP)
        );

        FOREACH v_target_table IN ARRAY v_target_tables
        LOOP
            -- Parse schema and table
            IF v_target_table LIKE '%.%' THEN
                v_target_schema := split_part(v_target_table, '.', 1);
                v_target_table := split_part(v_target_table, '.', 2);
            ELSE
                v_target_schema := 'public';
            END IF;

            -- Register target entity
            v_target_entity_id := data_lineage.register_entity(
                v_target_table,
                'table',
                v_target_schema,
                v_target_table,
                NULL,
                v_target_schema || '.' || v_target_table,
                'Automatically discovered from SQL',
                NULL,
                NULL,
                jsonb_build_object('discovery_method', 'automatic', 'discovery_timestamp', CURRENT_TIMESTAMP)
            );

            -- Register lineage
            v_lineage_id := data_lineage.register_lineage(
                v_source_entity_id,
                v_target_entity_id,
                v_transformation_id,
                v_relationship_type,
                p_confidence_score,
                NULL,
                NULL,
                CURRENT_TIMESTAMP,
                NULL,
                jsonb_build_object('discovery_method', 'automatic', 'discovery_timestamp', CURRENT_TIMESTAMP)
            );

            -- Return the result
            lineage_id := v_lineage_id;
            source_entity_name := v_source_schema || '.' || v_source_table;
            target_entity_name := v_target_schema || '.' || v_target_table;
            relationship_type := v_relationship_type;
            RETURN NEXT;
        END LOOP;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.discover_lineage_from_sql IS 'Discovers lineage relationships from SQL statements';

-- Function to discover column-level lineage from SQL
CREATE OR REPLACE FUNCTION data_lineage.discover_column_lineage_from_sql(
    p_sql TEXT,
    p_transformation_name VARCHAR(100),
    p_confidence_score NUMERIC(5, 2) DEFAULT 70.0
) RETURNS TABLE (
    lineage_id INTEGER,
    source_entity_name VARCHAR(255),
    target_entity_name VARCHAR(255),
    relationship_type VARCHAR(50)
) AS $$
DECLARE
    v_transformation_id INTEGER;
    v_lineage_ids INTEGER[];
BEGIN
    -- This is a placeholder for a more complex implementation
    -- Column-level lineage discovery requires advanced SQL parsing

    -- Register the transformation
    v_transformation_id := data_lineage.register_transformation(
        p_transformation_name,
        'query',
        'Automatically discovered column-level lineage from SQL',
        NULL,
        p_sql,
        NULL,
        CURRENT_USER,
        NULL,
        jsonb_build_object('discovery_method', 'automatic', 'discovery_level', 'column', 'discovery_timestamp', CURRENT_TIMESTAMP)
    );

    -- For now, just call the table-level discovery
    RETURN QUERY
    SELECT * FROM data_lineage.discover_lineage_from_sql(p_sql, p_transformation_name, p_confidence_score);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.discover_column_lineage_from_sql IS 'Discovers column-level lineage relationships from SQL statements';

-- Function to discover lineage from database objects
CREATE OR REPLACE FUNCTION data_lineage.discover_lineage_from_db_objects(
    p_schema_pattern VARCHAR(255) DEFAULT '%',
    p_object_type VARCHAR(50) DEFAULT 'view'
) RETURNS TABLE (
    lineage_id INTEGER,
    source_entity_name VARCHAR(255),
    target_entity_name VARCHAR(255),
    relationship_type VARCHAR(50)
) AS $$
DECLARE
    v_object RECORD;
    v_definition TEXT;
    v_transformation_name VARCHAR(100);
BEGIN
    -- Loop through database objects
    FOR v_object IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS object_name,
            pg_get_viewdef(c.oid) AS object_definition
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname LIKE p_schema_pattern
        AND c.relkind = CASE
                          WHEN p_object_type = 'view' THEN 'v'::char
                          WHEN p_object_type = 'materialized_view' THEN 'm'::char
                          ELSE 'v'::char
                        END
    LOOP
        -- Create transformation name
        v_transformation_name := v_object.schema_name || '.' || v_object.object_name || ' definition';

        -- Discover lineage from the object definition
        RETURN QUERY
        SELECT * FROM data_lineage.discover_lineage_from_sql(
            v_object.object_definition,
            v_transformation_name,
            90.0 -- Higher confidence for database objects
        );
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.discover_lineage_from_db_objects IS 'Discovers lineage relationships from database objects like views';

-- Step 5: Create Views for Lineage Visualization and Querying

-- View for Direct Lineage Relationships
CREATE OR REPLACE VIEW data_lineage.v_direct_lineage AS
SELECT
    l.lineage_id,
    se.entity_id AS source_entity_id,
    se.entity_name AS source_entity_name,
    se.entity_type AS source_entity_type,
    se.schema_name AS source_schema,
    se.table_name AS source_table,
    se.column_name AS source_column,
    te.entity_id AS target_entity_id,
    te.entity_name AS target_entity_name,
    te.entity_type AS target_entity_type,
    te.schema_name AS target_schema,
    te.table_name AS target_table,
    te.column_name AS target_column,
    t.transformation_id,
    t.transformation_name,
    t.transformation_type,
    l.relationship_type,
    l.confidence_score,
    l.impact_level,
    l.transformation_rule,
    l.effective_from,
    l.effective_to,
    l.is_active
FROM data_lineage.dl_lineage l
JOIN data_lineage.dl_entities se ON l.source_entity_id = se.entity_id
JOIN data_lineage.dl_entities te ON l.target_entity_id = te.entity_id
LEFT JOIN data_lineage.dl_transformations t ON l.transformation_id = t.transformation_id
WHERE l.is_active = TRUE
AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP);

COMMENT ON VIEW data_lineage.v_direct_lineage IS 'Shows direct lineage relationships between entities';

-- View for Upstream Lineage (recursive)
CREATE OR REPLACE VIEW data_lineage.v_upstream_lineage AS
WITH RECURSIVE upstream_lineage AS (
    -- Base case: direct upstream relationships
    SELECT
        l.lineage_id,
        l.source_entity_id,
        l.target_entity_id,
        l.transformation_id,
        l.relationship_type,
        l.confidence_score,
        1 AS depth,
        ARRAY[l.target_entity_id, l.source_entity_id] AS path,
        l.source_entity_id::text AS path_key
    FROM data_lineage.dl_lineage l
    WHERE l.is_active = TRUE
    AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP)

    UNION ALL

    -- Recursive case: find upstream entities
    SELECT
        l.lineage_id,
        l.source_entity_id,
        ul.target_entity_id,
        l.transformation_id,
        l.relationship_type,
        l.confidence_score * ul.confidence_score / 100 AS confidence_score,
        ul.depth + 1 AS depth,
        ul.path || l.source_entity_id AS path,
        ul.path_key || '->' || l.source_entity_id::text AS path_key
    FROM data_lineage.dl_lineage l
    JOIN upstream_lineage ul ON l.target_entity_id = ul.source_entity_id
    WHERE l.is_active = TRUE
    AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP)
    AND NOT l.source_entity_id = ANY(ul.path) -- Prevent cycles
)
SELECT
    ul.lineage_id,
    se.entity_id AS source_entity_id,
    se.entity_name AS source_entity_name,
    se.entity_type AS source_entity_type,
    se.schema_name AS source_schema,
    se.table_name AS source_table,
    se.column_name AS source_column,
    te.entity_id AS target_entity_id,
    te.entity_name AS target_entity_name,
    te.entity_type AS target_entity_type,
    te.schema_name AS target_schema,
    te.table_name AS target_table,
    te.column_name AS target_column,
    t.transformation_id,
    t.transformation_name,
    t.transformation_type,
    ul.relationship_type,
    ul.confidence_score,
    ul.depth,
    ul.path,
    ul.path_key
FROM upstream_lineage ul
JOIN data_lineage.dl_entities se ON ul.source_entity_id = se.entity_id
JOIN data_lineage.dl_entities te ON ul.target_entity_id = te.entity_id
LEFT JOIN data_lineage.dl_transformations t ON ul.transformation_id = t.transformation_id;

COMMENT ON VIEW data_lineage.v_upstream_lineage IS 'Shows recursive upstream lineage relationships';

-- View for Downstream Lineage (recursive)
CREATE OR REPLACE VIEW data_lineage.v_downstream_lineage AS
WITH RECURSIVE downstream_lineage AS (
    -- Base case: direct downstream relationships
    SELECT
        l.lineage_id,
        l.source_entity_id,
        l.target_entity_id,
        l.transformation_id,
        l.relationship_type,
        l.confidence_score,
        1 AS depth,
        ARRAY[l.source_entity_id, l.target_entity_id] AS path,
        l.target_entity_id::text AS path_key
    FROM data_lineage.dl_lineage l
    WHERE l.is_active = TRUE
    AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP)

    UNION ALL

    -- Recursive case: find downstream entities
    SELECT
        l.lineage_id,
        dl.source_entity_id,
        l.target_entity_id,
        l.transformation_id,
        l.relationship_type,
        l.confidence_score * dl.confidence_score / 100 AS confidence_score,
        dl.depth + 1 AS depth,
        dl.path || l.target_entity_id AS path,
        dl.path_key || '->' || l.target_entity_id::text AS path_key
    FROM data_lineage.dl_lineage l
    JOIN downstream_lineage dl ON l.source_entity_id = dl.target_entity_id
    WHERE l.is_active = TRUE
    AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP)
    AND NOT l.target_entity_id = ANY(dl.path) -- Prevent cycles
)
SELECT
    dl.lineage_id,
    se.entity_id AS source_entity_id,
    se.entity_name AS source_entity_name,
    se.entity_type AS source_entity_type,
    se.schema_name AS source_schema,
    se.table_name AS source_table,
    se.column_name AS source_column,
    te.entity_id AS target_entity_id,
    te.entity_name AS target_entity_name,
    te.entity_type AS target_entity_type,
    te.schema_name AS target_schema,
    te.table_name AS target_table,
    te.column_name AS target_column,
    t.transformation_id,
    t.transformation_name,
    t.transformation_type,
    dl.relationship_type,
    dl.confidence_score,
    dl.depth,
    dl.path,
    dl.path_key
FROM downstream_lineage dl
JOIN data_lineage.dl_entities se ON dl.source_entity_id = se.entity_id
JOIN data_lineage.dl_entities te ON dl.target_entity_id = te.entity_id
LEFT JOIN data_lineage.dl_transformations t ON dl.transformation_id = t.transformation_id;

COMMENT ON VIEW data_lineage.v_downstream_lineage IS 'Shows recursive downstream lineage relationships';

-- View for Impact Analysis
CREATE OR REPLACE VIEW data_lineage.v_impact_analysis AS
SELECT
    e.entity_id,
    e.entity_name,
    e.entity_type,
    e.schema_name,
    e.table_name,
    e.column_name,
    COUNT(DISTINCT dl.target_entity_id) AS direct_downstream_count,
    COUNT(DISTINCT vdl.target_entity_id) AS total_downstream_count,
    MAX(vdl.depth) AS max_downstream_depth,
    jsonb_agg(DISTINCT jsonb_build_object(
        'entity_id', te.entity_id,
        'entity_name', te.entity_name,
        'entity_type', te.entity_type,
        'schema_name', te.schema_name,
        'table_name', te.table_name,
        'sensitivity_level', te.sensitivity_level
    )) FILTER (WHERE te.sensitivity_level IN ('confidential', 'restricted', 'pii')) AS sensitive_downstream_entities
FROM data_lineage.dl_entities e
LEFT JOIN data_lineage.dl_lineage dl ON e.entity_id = dl.source_entity_id
LEFT JOIN data_lineage.v_downstream_lineage vdl ON e.entity_id = vdl.source_entity_id
LEFT JOIN data_lineage.dl_entities te ON vdl.target_entity_id = te.entity_id
GROUP BY e.entity_id, e.entity_name, e.entity_type, e.schema_name, e.table_name, e.column_name;

COMMENT ON VIEW data_lineage.v_impact_analysis IS 'Shows impact analysis for entities';

-- View for Data Quality Impact
CREATE OR REPLACE VIEW data_lineage.v_quality_impact_analysis AS
SELECT
    e.entity_id,
    e.entity_name,
    e.entity_type,
    e.schema_name,
    e.table_name,
    e.column_name,
    qi.quality_dimension,
    COUNT(*) FILTER (WHERE qi.impact_type = 'improves') AS improves_count,
    COUNT(*) FILTER (WHERE qi.impact_type = 'degrades') AS degrades_count,
    COUNT(*) FILTER (WHERE qi.impact_type = 'maintains') AS maintains_count,
    AVG(qi.impact_score) FILTER (WHERE qi.impact_score IS NOT NULL) AS avg_impact_score,
    jsonb_agg(DISTINCT jsonb_build_object(
        'lineage_id', l.lineage_id,
        'source_entity', se.entity_name,
        'target_entity', te.entity_name,
        'impact_type', qi.impact_type,
        'impact_score', qi.impact_score,
        'description', qi.description
    )) AS impact_details
FROM data_lineage.dl_entities e
JOIN data_lineage.dl_lineage l ON e.entity_id = l.target_entity_id
JOIN data_lineage.dl_quality_impact qi ON l.lineage_id = qi.lineage_id
JOIN data_lineage.dl_entities se ON l.source_entity_id = se.entity_id
JOIN data_lineage.dl_entities te ON l.target_entity_id = te.entity_id
GROUP BY e.entity_id, e.entity_name, e.entity_type, e.schema_name, e.table_name, e.column_name, qi.quality_dimension;

COMMENT ON VIEW data_lineage.v_quality_impact_analysis IS 'Shows quality impact analysis for entities';

-- View for Business Term Context
CREATE OR REPLACE VIEW data_lineage.v_business_context AS
SELECT
    e.entity_id,
    e.entity_name,
    e.entity_type,
    e.schema_name,
    e.table_name,
    e.column_name,
    jsonb_agg(DISTINCT jsonb_build_object(
        'term_id', bg.term_id,
        'term_name', bg.term_name,
        'definition', bg.definition,
        'domain', bg.domain,
        'relationship_type', tem.relationship_type
    )) AS business_terms,
    jsonb_agg(DISTINCT t.tag_name) AS tags
FROM data_lineage.dl_entities e
LEFT JOIN data_lineage.dl_term_entity_mapping tem ON e.entity_id = tem.entity_id
LEFT JOIN data_lineage.dl_business_glossary bg ON tem.term_id = bg.term_id
LEFT JOIN data_lineage.dl_entity_tags et ON e.entity_id = et.entity_id
LEFT JOIN data_lineage.dl_tags t ON et.tag_id = t.tag_id
GROUP BY e.entity_id, e.entity_name, e.entity_type, e.schema_name, e.table_name, e.column_name;

COMMENT ON VIEW data_lineage.v_business_context IS 'Shows business context for entities';

-- View for Lineage Graph
CREATE OR REPLACE VIEW data_lineage.v_lineage_graph AS
SELECT
    l.lineage_id,
    l.source_entity_id AS source_id,
    se.entity_name AS source_name,
    se.entity_type AS source_type,
    se.schema_name || '.' || se.table_name || COALESCE('.' || se.column_name, '') AS source_path,
    l.target_entity_id AS target_id,
    te.entity_name AS target_name,
    te.entity_type AS target_type,
    te.schema_name || '.' || te.table_name || COALESCE('.' || te.column_name, '') AS target_path,
    l.transformation_id,
    t.transformation_name,
    t.transformation_type,
    l.relationship_type,
    l.confidence_score,
    l.impact_level,
    jsonb_build_object(
        'source', jsonb_build_object(
            'id', se.entity_id,
            'name', se.entity_name,
            'type', se.entity_type,
            'schema', se.schema_name,
            'table', se.table_name,
            'column', se.column_name,
            'sensitivity', se.sensitivity_level
        ),
        'target', jsonb_build_object(
            'id', te.entity_id,
            'name', te.entity_name,
            'type', te.entity_type,
            'schema', te.schema_name,
            'table', te.table_name,
            'column', te.column_name,
            'sensitivity', te.sensitivity_level
        ),
        'transformation', CASE WHEN t.transformation_id IS NOT NULL THEN jsonb_build_object(
            'id', t.transformation_id,
            'name', t.transformation_name,
            'type', t.transformation_type
        ) ELSE NULL END,
        'relationship', jsonb_build_object(
            'type', l.relationship_type,
            'confidence', l.confidence_score,
            'impact', l.impact_level
        )
    ) AS graph_data
FROM data_lineage.dl_lineage l
JOIN data_lineage.dl_entities se ON l.source_entity_id = se.entity_id
JOIN data_lineage.dl_entities te ON l.target_entity_id = te.entity_id
LEFT JOIN data_lineage.dl_transformations t ON l.transformation_id = t.transformation_id
WHERE l.is_active = TRUE
AND (l.effective_to IS NULL OR l.effective_to > CURRENT_TIMESTAMP);

COMMENT ON VIEW data_lineage.v_lineage_graph IS 'Provides data for lineage graph visualization';

-- View for Transformation Execution History
CREATE OR REPLACE VIEW data_lineage.v_transformation_history AS
SELECT
    el.execution_id,
    t.transformation_id,
    t.transformation_name,
    t.transformation_type,
    el.execution_timestamp,
    el.execution_status,
    el.execution_duration,
    el.rows_processed,
    el.error_message,
    el.executed_by,
    jsonb_agg(DISTINCT jsonb_build_object(
        'lineage_id', l.lineage_id,
        'source_entity', se.entity_name,
        'target_entity', te.entity_name,
        'relationship_type', l.relationship_type
    )) AS affected_lineage
FROM data_lineage.dl_execution_log el
JOIN data_lineage.dl_transformations t ON el.transformation_id = t.transformation_id
LEFT JOIN data_lineage.dl_lineage l ON t.transformation_id = l.transformation_id
LEFT JOIN data_lineage.dl_entities se ON l.source_entity_id = se.entity_id
LEFT JOIN data_lineage.dl_entities te ON l.target_entity_id = te.entity_id
GROUP BY el.execution_id, t.transformation_id, t.transformation_name, t.transformation_type,
         el.execution_timestamp, el.execution_status, el.execution_duration,
         el.rows_processed, el.error_message, el.executed_by
ORDER BY el.execution_timestamp DESC;

COMMENT ON VIEW data_lineage.v_transformation_history IS 'Shows transformation execution history';

-- Step 6: Create Functions for Lineage Visualization

-- Function to get upstream lineage for an entity
CREATE OR REPLACE FUNCTION data_lineage.get_upstream_lineage(
    p_entity_id INTEGER,
    p_max_depth INTEGER DEFAULT 10,
    p_min_confidence NUMERIC(5, 2) DEFAULT 0.0
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH upstream_data AS (
        SELECT *
        FROM data_lineage.v_upstream_lineage
        WHERE target_entity_id = p_entity_id
        AND depth <= p_max_depth
        AND confidence_score >= p_min_confidence
    ),
    nodes AS (
        -- Source entities
        SELECT DISTINCT
            source_entity_id AS id,
            source_entity_name AS name,
            source_entity_type AS type,
            source_schema || '.' || source_table || COALESCE('.' || source_column, '') AS path,
            jsonb_build_object(
                'id', source_entity_id,
                'name', source_entity_name,
                'type', source_entity_type,
                'schema', source_schema,
                'table', source_table,
                'column', source_column
            ) AS node_data
        FROM upstream_data

        UNION

        -- Target entity
        SELECT DISTINCT
            target_entity_id AS id,
            target_entity_name AS name,
            target_entity_type AS type,
            target_schema || '.' || target_table || COALESCE('.' || target_column, '') AS path,
            jsonb_build_object(
                'id', target_entity_id,
                'name', target_entity_name,
                'type', target_entity_type,
                'schema', target_schema,
                'table', target_table,
                'column', target_column
            ) AS node_data
        FROM upstream_data
    ),
    edges AS (
        SELECT
            lineage_id,
            source_entity_id AS source,
            target_entity_id AS target,
            relationship_type,
            confidence_score,
            depth,
            jsonb_build_object(
                'id', lineage_id,
                'source', source_entity_id,
                'target', target_entity_id,
                'type', relationship_type,
                'confidence', confidence_score,
                'depth', depth,
                'transformation', CASE WHEN transformation_id IS NOT NULL THEN jsonb_build_object(
                    'id', transformation_id,
                    'name', transformation_name,
                    'type', transformation_type
                ) ELSE NULL END
            ) AS edge_data
        FROM upstream_data
    )
    SELECT jsonb_build_object(
        'nodes', jsonb_agg(n.node_data),
        'edges', jsonb_agg(e.edge_data),
        'root_id', p_entity_id
    )
    INTO v_result
    FROM nodes n
    CROSS JOIN (SELECT jsonb_agg(e.edge_data) AS edges FROM edges e) e;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.get_upstream_lineage IS 'Gets upstream lineage data for visualization';

-- Function to get downstream lineage for an entity
CREATE OR REPLACE FUNCTION data_lineage.get_downstream_lineage(
    p_entity_id INTEGER,
    p_max_depth INTEGER DEFAULT 10,
    p_min_confidence NUMERIC(5, 2) DEFAULT 0.0
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH downstream_data AS (
        SELECT *
        FROM data_lineage.v_downstream_lineage
        WHERE source_entity_id = p_entity_id
        AND depth <= p_max_depth
        AND confidence_score >= p_min_confidence
    ),
    nodes AS (
        -- Target entities
        SELECT DISTINCT
            target_entity_id AS id,
            target_entity_name AS name,
            target_entity_type AS type,
            target_schema || '.' || target_table || COALESCE('.' || target_column, '') AS path,
            jsonb_build_object(
                'id', target_entity_id,
                'name', target_entity_name,
                'type', target_entity_type,
                'schema', target_schema,
                'table', target_table,
                'column', target_column
            ) AS node_data
        FROM downstream_data

        UNION

        -- Source entity
        SELECT DISTINCT
            source_entity_id AS id,
            source_entity_name AS name,
            source_entity_type AS type,
            source_schema || '.' || source_table || COALESCE('.' || source_column, '') AS path,
            jsonb_build_object(
                'id', source_entity_id,
                'name', source_entity_name,
                'type', source_entity_type,
                'schema', source_schema,
                'table', source_table,
                'column', source_column
            ) AS node_data
        FROM downstream_data
    ),
    edges AS (
        SELECT
            lineage_id,
            source_entity_id AS source,
            target_entity_id AS target,
            relationship_type,
            confidence_score,
            depth,
            jsonb_build_object(
                'id', lineage_id,
                'source', source_entity_id,
                'target', target_entity_id,
                'type', relationship_type,
                'confidence', confidence_score,
                'depth', depth,
                'transformation', CASE WHEN transformation_id IS NOT NULL THEN jsonb_build_object(
                    'id', transformation_id,
                    'name', transformation_name,
                    'type', transformation_type
                ) ELSE NULL END
            ) AS edge_data
        FROM downstream_data
    )
    SELECT jsonb_build_object(
        'nodes', jsonb_agg(n.node_data),
        'edges', jsonb_agg(e.edge_data),
        'root_id', p_entity_id
    )
    INTO v_result
    FROM nodes n
    CROSS JOIN (SELECT jsonb_agg(e.edge_data) AS edges FROM edges e) e;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.get_downstream_lineage IS 'Gets downstream lineage data for visualization';

-- Function to get full lineage for an entity
CREATE OR REPLACE FUNCTION data_lineage.get_full_lineage(
    p_entity_id INTEGER,
    p_upstream_depth INTEGER DEFAULT 3,
    p_downstream_depth INTEGER DEFAULT 3,
    p_min_confidence NUMERIC(5, 2) DEFAULT 0.0
) RETURNS JSONB AS $$
DECLARE
    v_upstream JSONB;
    v_downstream JSONB;
    v_result JSONB;
    v_nodes JSONB;
    v_edges JSONB;
BEGIN
    -- Get upstream lineage
    v_upstream := data_lineage.get_upstream_lineage(p_entity_id, p_upstream_depth, p_min_confidence);

    -- Get downstream lineage
    v_downstream := data_lineage.get_downstream_lineage(p_entity_id, p_downstream_depth, p_min_confidence);

    -- Merge nodes
    WITH upstream_nodes AS (
        SELECT jsonb_array_elements(v_upstream->'nodes') AS node
    ),
    downstream_nodes AS (
        SELECT jsonb_array_elements(v_downstream->'nodes') AS node
    ),
    all_nodes AS (
        SELECT node FROM upstream_nodes
        UNION
        SELECT node FROM downstream_nodes
    )
    SELECT jsonb_agg(node)
    INTO v_nodes
    FROM all_nodes;

    -- Merge edges
    WITH upstream_edges AS (
        SELECT jsonb_array_elements(v_upstream->'edges') AS edge
    ),
    downstream_edges AS (
        SELECT jsonb_array_elements(v_downstream->'edges') AS edge
    ),
    all_edges AS (
        SELECT edge FROM upstream_edges
        UNION
        SELECT edge FROM downstream_edges
    )
    SELECT jsonb_agg(edge)
    INTO v_edges
    FROM all_edges;

    -- Build result
    v_result := jsonb_build_object(
        'nodes', v_nodes,
        'edges', v_edges,
        'root_id', p_entity_id
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.get_full_lineage IS 'Gets full lineage data (upstream and downstream) for visualization';

-- Function to get impact analysis for an entity
CREATE OR REPLACE FUNCTION data_lineage.get_impact_analysis(
    p_entity_id INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'entity', jsonb_build_object(
            'id', e.entity_id,
            'name', e.entity_name,
            'type', e.entity_type,
            'schema', e.schema_name,
            'table', e.table_name,
            'column', e.column_name
        ),
        'impact', jsonb_build_object(
            'direct_downstream_count', ia.direct_downstream_count,
            'total_downstream_count', ia.total_downstream_count,
            'max_downstream_depth', ia.max_downstream_depth,
            'sensitive_downstream_entities', ia.sensitive_downstream_entities
        ),
        'quality_impact', (
            SELECT jsonb_agg(jsonb_build_object(
                'dimension', qia.quality_dimension,
                'improves_count', qia.improves_count,
                'degrades_count', qia.degrades_count,
                'maintains_count', qia.maintains_count,
                'avg_impact_score', qia.avg_impact_score,
                'details', qia.impact_details
            ))
            FROM data_lineage.v_quality_impact_analysis qia
            WHERE qia.entity_id = p_entity_id
        ),
        'business_context', (
            SELECT bc.business_terms
            FROM data_lineage.v_business_context bc
            WHERE bc.entity_id = p_entity_id
        )
    )
    INTO v_result
    FROM data_lineage.dl_entities e
    JOIN data_lineage.v_impact_analysis ia ON e.entity_id = ia.entity_id
    WHERE e.entity_id = p_entity_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION data_lineage.get_impact_analysis IS 'Gets impact analysis data for an entity';

-- Step 7: Initialize Data Lineage Framework with Example Data

-- Register example data sources
SELECT data_lineage.register_source(
    'PostgreSQL Database',
    'database',
    '{"host": "localhost", "port": 5432, "dbname": "diagnostic_tool"}'::jsonb,
    'Main PostgreSQL database for the diagnostic tool',
    '{"environment": "production"}'::jsonb
);

SELECT data_lineage.register_source(
    'ETL Process',
    'etl',
    NULL,
    'ETL processes for data integration',
    '{"tool": "custom_etl", "schedule": "daily"}'::jsonb
);

SELECT data_lineage.register_source(
    'Manual Data Entry',
    'manual',
    NULL,
    'Manual data entry by users',
    '{"validation": "ui_forms"}'::jsonb
);

-- Register example business terms
SELECT data_lineage.add_business_term(
    'Vehicle Identification Number',
    'A unique code including a serial number, used by the automotive industry to identify individual motor vehicles.',
    'VIN',
    'Vehicle',
    'Data Governance Team',
    'approved',
    '1.0',
    NULL
);

SELECT data_lineage.add_business_term(
    'Diagnostic Trouble Code',
    'Codes that are stored by the on-board computer diagnostic system in a vehicle when it detects a problem.',
    'DTC',
    'Diagnostics',
    'Technical Team',
    'approved',
    '1.0',
    NULL
);

SELECT data_lineage.add_business_term(
    'On-Board Diagnostics',
    'An automotive term referring to a vehicle''s self-diagnostic and reporting capability.',
    'OBD',
    'Diagnostics',
    'Technical Team',
    'approved',
    '1.0',
    NULL
);

-- Register example tags
SELECT data_lineage.add_tag(
    'Core Data',
    'Data Classification',
    'Essential data for the system'
);

SELECT data_lineage.add_tag(
    'Sensitive',
    'Data Classification',
    'Contains sensitive information'
);

SELECT data_lineage.add_tag(
    'Derived',
    'Data Processing',
    'Derived from other data sources'
);

-- Register example entities
SELECT data_lineage.register_entity(
    'VehicleInfo',
    'table',
    'public',
    'VehicleInfo',
    NULL,
    'public.VehicleInfo',
    'Stores basic vehicle information',
    'Contains core vehicle data including make, model, year, and VIN',
    'internal',
    '{"primary_key": "vehicle_id"}'::jsonb
);

SELECT data_lineage.register_entity(
    'VIN',
    'column',
    'public',
    'VehicleInfo',
    'vin',
    'public.VehicleInfo.vin',
    'Vehicle Identification Number',
    'Unique identifier for a vehicle',
    'confidential',
    '{"format": "17 characters", "validation": "required"}'::jsonb
);

SELECT data_lineage.register_entity(
    'TroubleCodes',
    'table',
    'public',
    'TroubleCodes',
    NULL,
    'public.TroubleCodes',
    'Stores diagnostic trouble codes',
    'Contains trouble codes reported by vehicles',
    'internal',
    '{"primary_key": "code_id"}'::jsonb
);

SELECT data_lineage.register_entity(
    'DiagnosticSessions',
    'table',
    'public',
    'DiagnosticSessions',
    NULL,
    'public.DiagnosticSessions',
    'Stores diagnostic session information',
    'Records of diagnostic sessions performed on vehicles',
    'internal',
    '{"primary_key": "session_id"}'::jsonb
);

SELECT data_lineage.register_entity(
    'VehicleDiagnosticSummary',
    'view',
    'public',
    'VehicleDiagnosticSummary',
    NULL,
    'public.VehicleDiagnosticSummary',
    'Summary view of vehicle diagnostics',
    'Aggregated view of diagnostic data by vehicle',
    'internal',
    '{"refresh": "on-demand"}'::jsonb
);

-- Register example transformations
SELECT data_lineage.register_transformation(
    'Create Diagnostic Summary',
    'query',
    'Creates the vehicle diagnostic summary view',
    'Aggregates diagnostic data by vehicle',
    'CREATE OR REPLACE VIEW public.VehicleDiagnosticSummary AS
     SELECT v.vehicle_id, v.vin, v.make, v.model, v.year,
            COUNT(DISTINCT ds.session_id) AS session_count,
            COUNT(DISTINCT tc.code_id) AS trouble_code_count,
            MAX(ds.session_date) AS last_session_date
     FROM public.VehicleInfo v
     LEFT JOIN public.DiagnosticSessions ds ON v.vehicle_id = ds.vehicle_id
     LEFT JOIN public.TroubleCodes tc ON ds.session_id = tc.session_id
     GROUP BY v.vehicle_id, v.vin, v.make, v.model, v.year',
    NULL,
    'Database Admin',
    NULL,
    '{"created_date": "2023-01-15"}'::jsonb
);

-- Register example lineage relationships
SELECT data_lineage.register_lineage(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleInfo' AND entity_type = 'table'),
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view'),
    (SELECT transformation_id FROM data_lineage.dl_transformations WHERE transformation_name = 'Create Diagnostic Summary'),
    'direct',
    100.0,
    'medium',
    'Direct inclusion of vehicle data',
    CURRENT_TIMESTAMP,
    NULL,
    NULL
);

SELECT data_lineage.register_lineage(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'DiagnosticSessions' AND entity_type = 'table'),
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view'),
    (SELECT transformation_id FROM data_lineage.dl_transformations WHERE transformation_name = 'Create Diagnostic Summary'),
    'aggregated',
    100.0,
    'medium',
    'Aggregation of session data',
    CURRENT_TIMESTAMP,
    NULL,
    NULL
);

SELECT data_lineage.register_lineage(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'TroubleCodes' AND entity_type = 'table'),
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view'),
    (SELECT transformation_id FROM data_lineage.dl_transformations WHERE transformation_name = 'Create Diagnostic Summary'),
    'aggregated',
    100.0,
    'medium',
    'Aggregation of trouble code data',
    CURRENT_TIMESTAMP,
    NULL,
    NULL
);

-- Map business terms to entities
SELECT data_lineage.map_term_to_entity(
    (SELECT term_id FROM data_lineage.dl_business_glossary WHERE term_name = 'Vehicle Identification Number'),
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VIN' AND entity_type = 'column'),
    'defines'
);

SELECT data_lineage.map_term_to_entity(
    (SELECT term_id FROM data_lineage.dl_business_glossary WHERE term_name = 'Diagnostic Trouble Code'),
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'TroubleCodes' AND entity_type = 'table'),
    'associated'
);

-- Tag entities
SELECT data_lineage.tag_entity(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleInfo' AND entity_type = 'table'),
    (SELECT tag_id FROM data_lineage.dl_tags WHERE tag_name = 'Core Data')
);

SELECT data_lineage.tag_entity(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VIN' AND entity_type = 'column'),
    (SELECT tag_id FROM data_lineage.dl_tags WHERE tag_name = 'Sensitive')
);

SELECT data_lineage.tag_entity(
    (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view'),
    (SELECT tag_id FROM data_lineage.dl_tags WHERE tag_name = 'Derived')
);

-- Register quality impact
SELECT data_lineage.register_quality_impact(
    (SELECT lineage_id FROM data_lineage.dl_lineage
     WHERE source_entity_id = (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleInfo' AND entity_type = 'table')
     AND target_entity_id = (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view')),
    'completeness',
    'maintains',
    0.0,
    'Vehicle information is passed through without modification'
);

SELECT data_lineage.register_quality_impact(
    (SELECT lineage_id FROM data_lineage.dl_lineage
     WHERE source_entity_id = (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'DiagnosticSessions' AND entity_type = 'table')
     AND target_entity_id = (SELECT entity_id FROM data_lineage.dl_entities WHERE entity_name = 'VehicleDiagnosticSummary' AND entity_type = 'view')),
    'accuracy',
    'improves',
    25.0,
    'Aggregation improves accuracy by removing outliers'
);

-- Log transformation execution
SELECT data_lineage.log_transformation_execution(
    (SELECT transformation_id FROM data_lineage.dl_transformations WHERE transformation_name = 'Create Diagnostic Summary'),
    'completed',
    '00:00:05'::interval,
    1250,
    NULL,
    '{"rows_before": 0, "rows_after": 1250}'::jsonb
);

-- Add documentation comments
COMMENT ON SCHEMA data_lineage IS 'Schema for comprehensive data lineage tracking, including origins, transformations, and visualization tools';
