module cti_platform::access_control {
    use std::string::String;
    use sui::table::{Self, Table};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::clock::{Self, Clock};

    // Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INVALID_ACCESS_LEVEL: u64 = 2;
    const E_EXPIRED_CAPABILITY: u64 = 3;
    const E_INSUFFICIENT_REPUTATION: u64 = 4;

    // Access control registry
    public struct AccessControlRegistry has key {
        id: UID,
        admin: address,
        intelligence_permissions: Table<ID, IntelligencePermissions>,
        participant_capabilities: Table<address, vector<AccessCapability>>,
    }

    public struct IntelligencePermissions has store {
        owner: address,
        access_level_required: u8,
        is_public: bool,
        authorized_participants: vector<address>,
        restricted_until: u64,
    }

    public struct AccessCapability has key, store {
        id: UID,
        intelligence_id: ID,
        participant: address,
        access_level: u8,
        granted_by: address,
        granted_time: u64,
        expiration_time: u64,
        permissions: AccessPermissions,
    }

    public struct AccessPermissions has store, copy, drop {
        can_read: bool,
        can_validate: bool,
        can_share: bool,
        can_comment: bool,
    }

    // Events
    public struct AccessGranted has copy, drop {
        intelligence_id: ID,
        participant: address,
        granted_by: address,
        access_level: u8,
        expiration_time: u64,
    }

    public struct AccessRevoked has copy, drop {
        intelligence_id: ID,
        participant: address,
        revoked_by: address,
    }

    // Initialize access control registry
    fun init(ctx: &mut TxContext) {
        let registry = AccessControlRegistry {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            intelligence_permissions: table::new(ctx),
            participant_capabilities: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    // Set intelligence permissions
    public fun set_intelligence_permissions(
        registry: &mut AccessControlRegistry,
        intelligence_id: ID,
        owner: address,
        access_level_required: u8,
        is_public: bool,
        restriction_duration: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == owner, E_NOT_AUTHORIZED);

        let permissions = IntelligencePermissions {
            owner,
            access_level_required,
            is_public,
            authorized_participants: vector::empty(),
            restricted_until: clock::timestamp_ms(clock) + restriction_duration,
        };

        table::add(&mut registry.intelligence_permissions, intelligence_id, permissions);
    }

    // Grant access capability
    public entry fun grant_access_capability(
        registry: &mut AccessControlRegistry,
        intelligence_id: ID,
        participant: address,
        access_level: u8,
        duration_hours: u64,
        permissions: AccessPermissions,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Verify sender has permission to grant access
        assert!(
            table::contains(&registry.intelligence_permissions, intelligence_id),
            E_NOT_AUTHORIZED
        );
        
        let intel_permissions = table::borrow(&registry.intelligence_permissions, intelligence_id);
        assert!(sender == intel_permissions.owner, E_NOT_AUTHORIZED);

        let capability = AccessCapability {
            id: object::new(ctx),
            intelligence_id,
            participant,
            access_level,
            granted_by: sender,
            granted_time: current_time,
            expiration_time: current_time + (duration_hours * 3600 * 1000),
            permissions,
        };

        event::emit(AccessGranted {
            intelligence_id,
            participant,
            granted_by: sender,
            access_level,
            expiration_time: capability.expiration_time,
        });

        transfer::public_transfer(capability, participant);
    }

    // Check if participant has access
    public fun has_access(
        registry: &AccessControlRegistry,
        intelligence_id: ID,
        participant: address,
        required_permission: u8, // 1: read, 2: validate, 3: share, 4: comment
        clock: &Clock
    ): bool {
        // Check if intelligence is public
        if (table::contains(&registry.intelligence_permissions, intelligence_id)) {
            let intel_permissions = table::borrow(&registry.intelligence_permissions, intelligence_id);
            if (intel_permissions.is_public) {
                return true
            };
        };

        // Check participant capabilities (would need additional logic to check owned capabilities)
        false // Simplified for this example
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}