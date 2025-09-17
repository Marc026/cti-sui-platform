// Sui CTI Sharing Platform - Core Smart Contracts
// First implementation of Cyber Threat Intelligence sharing on Sui blockchain
// Author: Marc Lapira
// Date: August 2025

module cti_platform::threat_intelligence {
    use std::string::{Self, String};
    use std::vector;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::dynamic_field as df;
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};

    // ===== Error Codes =====
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INSUFFICIENT_REPUTATION: u64 = 2;
    const E_INVALID_CONFIDENCE_SCORE: u64 = 3;
    const E_EXPIRED_INTELLIGENCE: u64 = 4;
    const E_DUPLICATE_SUBMISSION: u64 = 5;
    const E_INSUFFICIENT_FUNDS: u64 = 6;

    // ===== Constants =====
    const MIN_CONFIDENCE_SCORE: u8 = 1;
    const MAX_CONFIDENCE_SCORE: u8 = 100;
    const MIN_REPUTATION_FOR_VALIDATION: u64 = 50;
    const SUBMISSION_FEE: u64 = 1000000; // 0.001 SUI
    const VALIDATION_REWARD: u64 = 500000; // 0.0005 SUI

    // ===== Core Data Structures =====

    /// Main platform registry that manages the CTI sharing ecosystem
    public struct CTIPlatform has key {
        id: UID,
        admin: address,
        total_submissions: u64,
        total_validations: u64,
        fee_pool: Balance<SUI>,
        participant_registry: Table<address, ID>, // address -> ParticipantProfile ID
    }

    /// Individual threat intelligence submission
    public struct ThreatIntelligence has key, store {
        id: UID,
        // Core Intelligence Data
        ioc_hash: vector<u8>,           // Hash of the indicator of compromise
        threat_type: String,            // Type of threat (malware, phishing, etc.)
        severity: u8,                   // Severity level 1-10
        confidence_score: u8,           // Confidence in intelligence (1-100)
        
        // Metadata
        submitter: address,
        submission_time: u64,
        expiration_time: u64,
        
        // Validation Status
        validation_count: u64,
        validation_score: u64,          // Weighted validation score
        is_verified: bool,
        
        // STIX Compatibility
        stix_pattern: String,           // STIX pattern for standardization
        mitre_techniques: vector<String>, // MITRE ATT&CK techniques
    }

    /// Participant profile with reputation and access control
    public struct ParticipantProfile has key, store {
        id: UID,
        address: address,
        organization: String,
        reputation_score: u64,
        contributions: u64,
        successful_validations: u64,
        access_level: u8,               // 1=Basic, 2=Advanced, 3=Premium
        join_date: u64,
    }

    /// Validation record for community-driven quality assurance
    public struct ValidationRecord has key, store {
        id: UID,
        intelligence_id: ID,
        validator: address,
        validation_time: u64,
        quality_score: u8,              // Quality assessment (1-100)
        is_accurate: bool,
        comments: String,
    }

    /// Access capability for intelligence consumption
    public struct AccessCapability has key, store {
        id: UID,
        participant: address,
        intelligence_id: ID,
        access_level: u8,
        granted_time: u64,
        expiration_time: u64,
    }

    // ===== Events =====

    public struct IntelligenceSubmitted has copy, drop {
        intelligence_id: ID,
        submitter: address,
        threat_type: String,
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

    public struct ReputationUpdated has copy, drop {
        participant: address,
        old_reputation: u64,
        new_reputation: u64,
        reason: String,
    }

    // ===== Initialization =====

    /// Initialize the CTI platform
    fun init(ctx: &mut TxContext) {
        let platform = CTIPlatform {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            total_submissions: 0,
            total_validations: 0,
            fee_pool: balance::zero(),
            participant_registry: table::new(ctx),
        };
        transfer::share_object(platform);
    }

    // ===== Participant Management =====

    /// Register a new participant in the CTI platform
    public entry fun register_participant(
        platform: &mut CTIPlatform,
        organization: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(!table::contains(&platform.participant_registry, sender), E_NOT_AUTHORIZED);

        let profile = ParticipantProfile {
            id: object::new(ctx),
            address: sender,
            organization,
            reputation_score: 10, // Starting reputation
            contributions: 0,
            successful_validations: 0,
            access_level: 1,      // Basic access level
            join_date: clock::timestamp_ms(clock),
        };

        let profile_id = object::id(&profile);
        table::add(&mut platform.participant_registry, sender, profile_id);
        transfer::public_transfer(profile, sender);
    }

    // ===== Intelligence Submission =====

    /// Submit new cyber threat intelligence
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
        assert!(confidence_score >= MIN_CONFIDENCE_SCORE && confidence_score <= MAX_CONFIDENCE_SCORE, E_INVALID_CONFIDENCE_SCORE);
        assert!(coin::value(&fee_payment) >= SUBMISSION_FEE, E_INSUFFICIENT_FUNDS);

        let current_time = clock::timestamp_ms(clock);
        let expiration_time = current_time + (expiration_hours * 3600 * 1000);

        // Create threat intelligence object
        let intelligence = ThreatIntelligence {
            id: object::new(ctx),
            ioc_hash,
            threat_type: threat_type,
            severity,
            confidence_score,
            submitter: sender,
            submission_time: current_time,
            expiration_time,
            validation_count: 0,
            validation_score: 0,
            is_verified: false,
            stix_pattern,
            mitre_techniques,
        };

        let intelligence_id = object::id(&intelligence);

        // Update platform statistics
        platform.total_submissions = platform.total_submissions + 1;
        
        // Add submission fee to platform pool
        balance::join(&mut platform.fee_pool, coin::into_balance(fee_payment));

        // Update participant reputation and stats
        profile.contributions = profile.contributions + 1;
        profile.reputation_score = profile.reputation_score + 5; // Reward for contribution

        // Emit event
        event::emit(IntelligenceSubmitted {
            intelligence_id,
            submitter: sender,
            threat_type: intelligence.threat_type,
            confidence_score,
            submission_time: current_time,
        });

        // Transfer intelligence to sender for management
        transfer::public_transfer(intelligence, sender);
    }

    // ===== Intelligence Validation =====

    /// Validate submitted threat intelligence
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
        let validator = tx_context::sender(ctx);
        assert!(validator_profile.address == validator, E_NOT_AUTHORIZED);
        assert!(validator_profile.reputation_score >= MIN_REPUTATION_FOR_VALIDATION, E_INSUFFICIENT_REPUTATION);
        assert!(validator != intelligence.submitter, E_NOT_AUTHORIZED); // Can't validate own submission
        assert!(quality_score >= MIN_CONFIDENCE_SCORE && quality_score <= MAX_CONFIDENCE_SCORE, E_INVALID_CONFIDENCE_SCORE);

        let current_time = clock::timestamp_ms(clock);
        assert!(current_time < intelligence.expiration_time, E_EXPIRED_INTELLIGENCE);

        // Create validation record
        let validation = ValidationRecord {
            id: object::new(ctx),
            intelligence_id: object::id(intelligence),
            validator,
            validation_time: current_time,
            quality_score,
            is_accurate,
            comments,
        };

        // Update intelligence validation metrics
        intelligence.validation_count = intelligence.validation_count + 1;
        
        // Weight validation score by validator reputation
        let weighted_score = (quality_score as u64) * validator_profile.reputation_score / 100;
        intelligence.validation_score = intelligence.validation_score + weighted_score;

        // Mark as verified if it meets criteria
        if (intelligence.validation_count >= 3 && intelligence.validation_score / intelligence.validation_count >= 70) {
            intelligence.is_verified = true;
        };

        // Update platform statistics
        platform.total_validations = platform.total_validations + 1;

        // Update validator reputation
        if (is_accurate) {
            validator_profile.successful_validations = validator_profile.successful_validations + 1;
            validator_profile.reputation_score = validator_profile.reputation_score + 3;
        };

        // Emit event
        event::emit(IntelligenceValidated {
            intelligence_id: object::id(intelligence),
            validator,
            quality_score,
            is_accurate,
            validation_time: current_time,
        });

        // Transfer validation record to validator
        transfer::public_transfer(validation, validator);
    }

    // ===== Access Control =====

    /// Grant access capability to threat intelligence
    public entry fun grant_access(
        intelligence: &ThreatIntelligence,
        requestor_profile: &ParticipantProfile,
        access_duration_hours: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let grantor = tx_context::sender(ctx);
        assert!(grantor == intelligence.submitter, E_NOT_AUTHORIZED);
        
        // Check if requestor has sufficient access level
        let required_level = if (intelligence.severity >= 8) { 3 } else if (intelligence.severity >= 5) { 2 } else { 1 };
        assert!(requestor_profile.access_level >= required_level, E_NOT_AUTHORIZED);

        let current_time = clock::timestamp_ms(clock);
        let expiration_time = current_time + (access_duration_hours * 3600 * 1000);

        let access_cap = AccessCapability {
            id: object::new(ctx),
            participant: requestor_profile.address,
            intelligence_id: object::id(intelligence),
            access_level: requestor_profile.access_level,
            granted_time: current_time,
            expiration_time,
        };

        transfer::public_transfer(access_cap, requestor_profile.address);
    }

    // ===== Incentive Distribution =====

    /// Distribute rewards to participants based on contribution quality
    public entry fun distribute_rewards(
        platform: &mut CTIPlatform,
        recipient_profile: &mut ParticipantProfile,
        reward_amount: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == platform.admin, E_NOT_AUTHORIZED);
        assert!(balance::value(&platform.fee_pool) >= reward_amount, E_INSUFFICIENT_FUNDS);

        // Extract reward from fee pool
        let reward_balance = balance::split(&mut platform.fee_pool, reward_amount);
        let reward_coin = coin::from_balance(reward_balance, ctx);

        // Update recipient reputation
        recipient_profile.reputation_score = recipient_profile.reputation_score + (reward_amount / 100000);

        // Transfer reward to recipient
        transfer::public_transfer(reward_coin, recipient_profile.address);
    }

    // ===== Query Functions =====

    /// Get platform statistics
    public fun get_platform_stats(platform: &CTIPlatform): (u64, u64, u64) {
        (platform.total_submissions, platform.total_validations, balance::value(&platform.fee_pool))
    }

    /// Get participant reputation
    public fun get_reputation(profile: &ParticipantProfile): u64 {
        profile.reputation_score
    }

    /// Check if intelligence is verified
    public fun is_intelligence_verified(intelligence: &ThreatIntelligence): bool {
        intelligence.is_verified
    }

    /// Get intelligence metadata
    public fun get_intelligence_metadata(intelligence: &ThreatIntelligence): (String, u8, u8, u64, bool) {
        (intelligence.threat_type, intelligence.severity, intelligence.confidence_score, intelligence.submission_time, intelligence.is_verified)
    }

    // ===== Utility Functions =====

    /// Check access capability validity
    public fun is_access_valid(access_cap: &AccessCapability, clock: &Clock): bool {
        clock::timestamp_ms(clock) < access_cap.expiration_time
    }

    /// Upgrade participant access level (admin only)
    public entry fun upgrade_access_level(
        platform: &CTIPlatform,
        profile: &mut ParticipantProfile,
        new_level: u8,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == platform.admin, E_NOT_AUTHORIZED);
        assert!(new_level >= 1 && new_level <= 3, E_NOT_AUTHORIZED);
        
        let old_reputation = profile.reputation_score;
        profile.access_level = new_level;
        profile.reputation_score = profile.reputation_score + 20; // Bonus for upgrade

        event::emit(ReputationUpdated {
            participant: profile.address,
            old_reputation,
            new_reputation: profile.reputation_score,
            reason: string::utf8(b"Access level upgrade"),
        });
    }

    // ===== Advanced Features =====

    /// Create a shared threat intelligence pool for consortium sharing
    public struct ThreatIntelligencePool has key {
        id: UID,
        consortium_members: vector<address>,
        shared_intelligence: Table<ID, bool>, // intelligence_id -> is_shared
        pool_reputation: u64,
    }

    /// Initialize consortium pool for advanced sharing
    public entry fun create_consortium_pool(
        platform: &CTIPlatform,
        initial_members: vector<address>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == platform.admin, E_NOT_AUTHORIZED);

        let pool = ThreatIntelligencePool {
            id: object::new(ctx),
            consortium_members: initial_members,
            shared_intelligence: table::new(ctx),
            pool_reputation: 100,
        };

        transfer::share_object(pool);
    }

    /// Share intelligence with consortium pool
    public entry fun share_with_consortium(
        pool: &mut ThreatIntelligencePool,
        intelligence: &ThreatIntelligence,
        submitter_profile: &ParticipantProfile,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(vector::contains(&pool.consortium_members, &sender), E_NOT_AUTHORIZED);
        assert!(submitter_profile.address == sender, E_NOT_AUTHORIZED);
        assert!(intelligence.is_verified, E_NOT_AUTHORIZED);

        let intelligence_id = object::id(intelligence);
        table::add(&mut pool.shared_intelligence, intelligence_id, true);
        
        // Boost pool reputation
        pool.pool_reputation = pool.pool_reputation + 10;
    }
}