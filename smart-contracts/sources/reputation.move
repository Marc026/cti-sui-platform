module cti_platform::reputation {
    use std::vector;
    use sui::table::{Self, Table};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;

    // Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INVALID_SCORE: u64 = 2;
    const E_REPUTATION_NOT_FOUND: u64 = 3;

    // Reputation tracking object
    public struct ReputationRegistry has key {
        id: UID,
        admin: address,
        participant_scores: Table<address, u64>,
        score_history: Table<address, vector<ReputationEntry>>,
        total_participants: u64,
    }

    public struct ReputationEntry has store, copy, drop {
        timestamp: u64,
        score_change: i64,
        reason: u8, // 1: submission, 2: validation, 3: penalty
        intelligence_id: ID,
    }

    // Events
    public struct ReputationUpdated has copy, drop {
        participant: address,
        old_score: u64,
        new_score: u64,
        change: i64,
        reason: u8,
    }

    // Initialize reputation registry
    fun init(ctx: &mut TxContext) {
        let registry = ReputationRegistry {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            participant_scores: table::new(ctx),
            score_history: table::new(ctx),
            total_participants: 0,
        };
        transfer::share_object(registry);
    }

    // Register new participant with initial reputation
    public fun register_participant(
        registry: &mut ReputationRegistry,
        participant: address,
        initial_score: u64,
        ctx: &mut TxContext
    ) {
        assert!(
            !table::contains(&registry.participant_scores, participant),
            E_REPUTATION_NOT_FOUND
        );

        table::add(&mut registry.participant_scores, participant, initial_score);
        table::add(&mut registry.score_history, participant, vector::empty());
        registry.total_participants = registry.total_participants + 1;
    }

    // Update reputation score
    public fun update_reputation(
        registry: &mut ReputationRegistry,
        participant: address,
        score_change: i64,
        reason: u8,
        intelligence_id: ID,
        timestamp: u64,
        ctx: &mut TxContext
    ) {
        assert!(
            table::contains(&registry.participant_scores, participant),
            E_REPUTATION_NOT_FOUND
        );

        let current_score = *table::borrow(&registry.participant_scores, participant);
        let new_score = if (score_change >= 0) {
            current_score + (score_change as u64)
        } else {
            let decrease = ((-score_change) as u64);
            if (current_score >= decrease) {
                current_score - decrease
            } else {
                0
            }
        };

        // Update score
        *table::borrow_mut(&mut registry.participant_scores, participant) = new_score;

        // Add to history
        let entry = ReputationEntry {
            timestamp,
            score_change,
            reason,
            intelligence_id,
        };
        vector::push_back(
            table::borrow_mut(&mut registry.score_history, participant),
            entry
        );

        event::emit(ReputationUpdated {
            participant,
            old_score: current_score,
            new_score,
            change: score_change,
            reason,
        });
    }

    // Get participant reputation score
    public fun get_reputation_score(
        registry: &ReputationRegistry,
        participant: address
    ): u64 {
        if (table::contains(&registry.participant_scores, participant)) {
            *table::borrow(&registry.participant_scores, participant)
        } else {
            0
        }
    }

    // Calculate reputation tier
    public fun get_reputation_tier(score: u64): u8 {
        if (score >= 1000) {
            5 // Expert
        } else if (score >= 500) {
            4 // Advanced
        } else if (score >= 100) {
            3 // Intermediate
        } else if (score >= 50) {
            2 // Novice
        } else {
            1 // Beginner
        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}