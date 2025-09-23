-- Database initialization script
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables for API service
CREATE TABLE IF NOT EXISTS participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address VARCHAR(66) UNIQUE NOT NULL,
    organization VARCHAR(255) NOT NULL,
    reputation_score INTEGER DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS intelligence_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    object_id VARCHAR(66) UNIQUE NOT NULL,
    threat_type VARCHAR(100) NOT NULL,
    severity INTEGER NOT NULL,
    confidence_score INTEGER NOT NULL,
    submitter VARCHAR(66) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS validation_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    intelligence_id VARCHAR(66) NOT NULL,
    validator VARCHAR(66) NOT NULL,
    quality_score INTEGER NOT NULL,
    is_accurate BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_participants_address ON participants(address);
CREATE INDEX IF NOT EXISTS idx_intelligence_threat_type ON intelligence_cache(threat_type);
CREATE INDEX IF NOT EXISTS idx_intelligence_severity ON intelligence_cache(severity);
CREATE INDEX IF NOT EXISTS idx_intelligence_expires ON intelligence_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_validation_intelligence ON validation_cache(intelligence_id);

-- Insert initial data if needed
INSERT INTO participants (address, organization, reputation_score) 
VALUES ('0x0000000000000000000000000000000000000000000000000000000000000000', 'System Admin', 1000)
ON CONFLICT (address) DO NOTHING;