module cti_platform::threat_intelligence {
    use std::string::{Self, String};
    use std::vector;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::transfer;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    
    // Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_ALREADY_REGISTERED: u64 = 2;
    const E_INVALID_THREAT_TYPE: u64 = 3;
    const E_INSUFFICIENT_REPUTATION: u64 = 4;
    const E_ALREADY_VALIDATED: u64 = 5;
    const E_EXPIRED_INTELLIGENCE: u64 = 6;
    const E_INSUFFICIENT_FEE: u64 = 7;
    
    // Platform constants
    const MIN_SUBMISSION_FEE: u64 = 1_000_000; // 0.001 SUI
    const MIN_VALIDATION_REP: u64 = 50;
    const MAX_SEVERITY: u8 = 10;
    const MIN_CONFIDENCE: u8 = 1;
    const MAX_CONFIDENCE: u8 = 100;
    
    // Main platform registry
    public struct CTIPlatform has key {
        id: UID,
        admin: address,
        total_submissions: u64,
        total_validations: u64,
        fee_pool: Balance<SUI>,
        participant_registry: Table<address, ID>,
    }
    
    // Threat intelligence object
    public struct ThreatIntelligence has key, store {
        id: UID,
        ioc_hash: vector<u8>,
        threat_type: String,
        severity: u8,
        confidence_score: u8,
        submitter: address,
        submission_time: u64,
        expiration_time: u64,
        validation_count: u64,
        validation_score: u64,
        is_verified: bool,
        stix_pattern: String,
        mitre_techniques: vector<String>,
    }
    
    // Participant profile
    public struct ParticipantProfile has key, store {
        id: UID,
        address: address,
        organization: String,
        reputation_score: u64,
        contributions: u64,
        successful_validations: u64,
        access_level: u8,
        join_date: u64,
    }
    
    // Validation record
    public struct ValidationRecord has key, store {
        id: UID,
        intelligence_id: ID,
        validator: address,
        quality_score: u8,
        is_accurate: bool,
        validation_time: u64,
        comments: String,
    }
    
    // Access capability
    public struct AccessCapability has key, store {
        id: UID,
        participant: address,
        intelligence_id: ID,
        access_level: u8,
        granted_time: u64,
        expiration_time: u64,
    }
    
    // Events
    public struct PlatformInitialized has copy, drop {
        platform_id: ID,
        admin: address,
    }
    
    public struct ParticipantRegistered has copy, drop {
        participant: address,
        organization: String,
        timestamp: u64,
    }
    
    public struct IntelligenceSubmitted has copy, drop {
        intelligence_id: ID,
        submitter: address,
        threat_type: String,
        severity: u8,
        confidence_score: u8,
        submission_time: u64,
    }
    
    public struct IntelligenceValidated has copy, drop {
        intelligence_id: ID,
        validator: address,
        quality_score: u8,
        is_accurate: bool,
        validation_time: u64,
    }
    
    // Initialize the platform
    fun init(ctx: &mut TxContext) {
        let platform = CTIPlatform {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            total_submissions: 0,
            total_validations: 0,
            fee_pool: balance::zero(),
            participant_registry: table::new(ctx),
        };
        
        event::emit(PlatformInitialized {
            platform_id: object::id(&platform),
            admin: tx_context::sender(ctx),
        });
        
        transfer::share_object(platform);
    }
    
    // Register a new participant
    public entry fun register_participant(
        platform: &mut CTIPlatform,
        organization: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(!table::contains(&platform.participant_registry, sender), E_ALREADY_REGISTERED);
        
        let profile = ParticipantProfile {
            id: object::new(ctx),
            address: sender,
            organization: string::utf8(organization),
            reputation_score: 10, // Initial reputation
            contributions: 0,
            successful_validations: 0,
            access_level: 1,
            join_date: clock::timestamp_ms(clock),
        };
        
        let profile_id = object::id(&profile);
        table::add(&mut platform.participant_registry, sender, profile_id);
        
        event::emit(ParticipantRegistered {
            participant: sender,
            organization: string::utf8(organization),
            timestamp: clock::timestamp_ms(clock),
        });
        
        transfer::public_transfer(profile, sender);
    }
    
    // Submit threat intelligence
    public entry fun submit_intelligence(
        platform: &mut CTIPlatform,
        profile: &mut ParticipantProfile,
        ioc_hash: vector<u8>,
        threat_type: String,
        severity: u8,
        confidence_score: u8,
        stix_pattern: String,
        mitre_techniques: vector<String>,
        expiration_hours: u64,
        fee_payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(profile.address == sender, E_NOT_AUTHORIZED);
        assert!(severity <= MAX_SEVERITY, E_INVALID_THREAT_TYPE);
        assert!(confidence_score >= MIN_CONFIDENCE && confidence_score <= MAX_CONFIDENCE, E_INVALID_THREAT_TYPE);
        assert!(coin::value(&fee_payment) >= MIN_SUBMISSION_FEE, E_INSUFFICIENT_FEE);
        
        let current_time = clock::timestamp_ms(clock);
        let intelligence = ThreatIntelligence {
            id: object::new(ctx),
            ioc_hash,
            threat_type: string::utf8(threat_type),
            severity,
            confidence_score,
            submitter: sender,
            submission_time: current_time,
            expiration_time: current_time + (expiration_hours * 3600 * 1000),
            validation_count: 0,
            validation_score: 0,
            is_verified: false,
            stix_pattern: string::utf8(stix_pattern),
            mitre_techniques: mitre_techniques,
        };
        
        // Add fee to platform pool
        balance::join(&mut platform.fee_pool, coin::into_balance(fee_payment));
        
        // Update statistics
        platform.total_submissions = platform.total_submissions + 1;
        profile.contributions = profile.contributions + 1;
        
        event::emit(IntelligenceSubmitted {
            intelligence_id: object::id(&intelligence),
            submitter: sender,
            threat_type: string::utf8(threat_type),
            severity,
            confidence_score,
            submission_time: current_time,
        });
        
        transfer::public_transfer(intelligence, sender);
    }
    
    // Validate threat intelligence
    public entry fun validate_intelligence(
        platform: &mut CTIPlatform,
        validator_profile: &mut ParticipantProfile,
        intelligence: &mut ThreatIntelligence,
        quality_score: u8,
        is_accurate: bool,
        comments: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(validator_profile.address == sender, E_NOT_AUTHORIZED);
        assert!(validator_profile.reputation_score >= MIN_VALIDATION_REP, E_INSUFFICIENT_REPUTATION);
        assert!(intelligence.submitter != sender, E_NOT_AUTHORIZED); // Can't validate own submission
        assert!(clock::timestamp_ms(clock) < intelligence.expiration_time, E_EXPIRED_INTELLIGENCE);
        assert!(quality_score >= MIN_CONFIDENCE && quality_score <= MAX_CONFIDENCE, E_INVALID_THREAT_TYPE);
        
        let current_time = clock::timestamp_ms(clock);
        
        // Create validation record
        let validation = ValidationRecord {
            id: object::new(ctx),
            intelligence_id: object::id(intelligence),
            validator: sender,
            quality_score,
            is_accurate,
            validation_time: current_time,
            comments: string::utf8(comments),
        };
        
        // Update intelligence validation metrics
        intelligence.validation_count = intelligence.validation_count + 1;
        intelligence.validation_score = intelligence.validation_score + (quality_score as u64);
        
        // Mark as verified if threshold met
        if (intelligence.validation_count >= 3 && 
            (intelligence.validation_score / intelligence.validation_count) >= 70) {
            intelligence.is_verified = true;
        };
        
        // Update validator reputation
        if (is_accurate) {
            validator_profile.successful_validations = validator_profile.successful_validations + 1;
            validator_profile.reputation_score = validator_profile.reputation_score + 1;
        };
        
        platform.total_validations = platform.total_validations + 1;
        
        event::emit(IntelligenceValidated {
            intelligence_id: object::id(intelligence),
            validator: sender,
            quality_score,
            is_accurate,
            validation_time: current_time,
        });
        
        transfer::public_transfer(validation, sender);
    }
    
    // Grant access capability
    public entry fun grant_access(
        intelligence: &ThreatIntelligence,
        requestor_profile: &ParticipantProfile,
        access_duration_hours: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let grantor = tx_context::sender(ctx);
        assert!(grantor == intelligence.submitter, E_NOT_AUTHORIZED);
        
        // Determine required access level based on severity
        let required_level = if (intelligence.severity >= 8) { 
            3 
        } else if (intelligence.severity >= 5) { 
            2 
        } else { 
            1 
        };
        
        assert!(requestor_profile.access_level >= required_level, E_INSUFFICIENT_REPUTATION);
        
        let current_time = clock::timestamp_ms(clock);
        let access_cap = AccessCapability {
            id: object::new(ctx),
            participant: requestor_profile.address,
            intelligence_id: object::id(intelligence),
            access_level: requestor_profile.access_level,
            granted_time: current_time,
            expiration_time: current_time + (access_duration_hours * 3600 * 1000),
        };
        
        transfer::public_transfer(access_cap, requestor_profile.address);
    }
    
    // Get platform statistics
    public fun get_platform_stats(platform: &CTIPlatform): (u64, u64, u64) {
        (
            platform.total_submissions,
            platform.total_validations,
            balance::value(&platform.fee_pool)
        )
    }
    
    // Check if participant is registered
    public fun is_participant_registered(platform: &CTIPlatform, participant: address): bool {
        table::contains(&platform.participant_registry, participant)
    }
    
    // Get intelligence metadata
    public fun get_intelligence_metadata(intelligence: &ThreatIntelligence): (String, u8, u8, u64, bool) {
        (
            intelligence.threat_type,
            intelligence.severity,
            intelligence.confidence_score,
            intelligence.validation_count,
            intelligence.is_verified
        )
    }
    
    // Check access capability validity
    public fun is_access_valid(cap: &AccessCapability, current_time: u64): bool {
        current_time < cap.expiration_time
    }
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}