module cti_platform::incentives {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::clock::{Self, Clock};

    // Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INSUFFICIENT_FUNDS: u64 = 2;
    const E_INVALID_REWARD_TYPE: u64 = 3;
    const E_ALREADY_CLAIMED: u64 = 4;

    // Reward types
    const SUBMISSION_REWARD: u8 = 1;
    const VALIDATION_REWARD: u8 = 2;
    const QUALITY_BONUS: u8 = 3;
    const PARTICIPATION_BONUS: u8 = 4;

    // Incentive pool
    public struct IncentivePool has key {
        id: UID,
        admin: address,
        total_pool: Balance<SUI>,
        reward_rates: Table<u8, u64>, // reward_type -> amount
        pending_rewards: Table<address, u64>,
        total_distributed: u64,
        distribution_history: Table<address, vector<RewardEntry>>,
    }

    public struct RewardEntry has store, copy, drop {
        timestamp: u64,
        amount: u64,
        reward_type: u8,
        intelligence_id: ID,
    }

    // Events
    public struct RewardEarned has copy, drop {
        participant: address,
        amount: u64,
        reward_type: u8,
        intelligence_id: ID,
    }

    public struct RewardClaimed has copy, drop {
        participant: address,
        amount: u64,
    }

    // Initialize incentive pool
    fun init(ctx: &mut TxContext) {
        let pool = IncentivePool {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            total_pool: balance::zero(),
            reward_rates: table::new(ctx),
            pending_rewards: table::new(ctx),
            total_distributed: 0,
            distribution_history: table::new(ctx),
        };

        transfer::share_object(pool);
    }

    // Add funds to incentive pool
    public entry fun add_funds(
        pool: &mut IncentivePool,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == pool.admin, E_NOT_AUTHORIZED);

        balance::join(&mut pool.total_pool, coin::into_balance(payment));
    }

    // Set reward rates
    public entry fun set_reward_rate(
        pool: &mut IncentivePool,
        reward_type: u8,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == pool.admin, E_NOT_AUTHORIZED);

        if (table::contains(&pool.reward_rates, reward_type)) {
            *table::borrow_mut(&mut pool.reward_rates, reward_type) = amount;
        } else {
            table::add(&mut pool.reward_rates, reward_type, amount);
        };
    }

    // Award reward to participant
    public fun award_reward(
        pool: &mut IncentivePool,
        participant: address,
        reward_type: u8,
        intelligence_id: ID,
        multiplier: u64, // For quality bonuses
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(
            table::contains(&pool.reward_rates, reward_type),
            E_INVALID_REWARD_TYPE
        );

        let base_reward = *table::borrow(&pool.reward_rates, reward_type);
        let total_reward = base_reward * multiplier;

        // Check if pool has sufficient funds
        assert!(
            balance::value(&pool.total_pool) >= total_reward,
            E_INSUFFICIENT_FUNDS
        );

        // Add to pending rewards
        if (table::contains(&pool.pending_rewards, participant)) {
            let current_pending = table::borrow_mut(&mut pool.pending_rewards, participant);
            *current_pending = *current_pending + total_reward;
        } else {
            table::add(&mut pool.pending_rewards, participant, total_reward);
        };

        // Record in history
        let entry = RewardEntry {
            timestamp: clock::timestamp_ms(clock),
            amount: total_reward,
            reward_type,
            intelligence_id,
        };

        if (table::contains(&pool.distribution_history, participant)) {
            vector::push_back(
                table::borrow_mut(&mut pool.distribution_history, participant),
                entry
            );
        } else {
            let history = vector::empty();
            vector::push_back(&mut history, entry);
            table::add(&mut pool.distribution_history, participant, history);
        };

        event::emit(RewardEarned {
            participant,
            amount: total_reward,
            reward_type,
            intelligence_id,
        });
    }

    // Claim pending rewards
    public entry fun claim_rewards(
        pool: &mut IncentivePool,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(
            table::contains(&pool.pending_rewards, sender),
            E_ALREADY_CLAIMED
        );

        let reward_amount = table::remove(&mut pool.pending_rewards, sender);
        assert!(reward_amount > 0, E_ALREADY_CLAIMED);

        let reward_balance = balance::split(&mut pool.total_pool, reward_amount);
        let reward_coin = coin::from_balance(reward_balance, ctx);

        pool.total_distributed = pool.total_distributed + reward_amount;

        event::emit(RewardClaimed {
            participant: sender,
            amount: reward_amount,
        });

        transfer::public_transfer(reward_coin, sender);
    }

    // Get pending rewards for participant
    public fun get_pending_rewards(
        pool: &IncentivePool,
        participant: address
    ): u64 {
        if (table::contains(&pool.pending_rewards, participant)) {
            *table::borrow(&pool.pending_rewards, participant)
        } else {
            0
        }
    }

    // Get pool statistics
    public fun get_pool_stats(pool: &IncentivePool): (u64, u64) {
        (balance::value(&pool.total_pool), pool.total_distributed)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}