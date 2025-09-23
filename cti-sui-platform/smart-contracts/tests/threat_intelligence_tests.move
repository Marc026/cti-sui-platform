#[test_only]
module cti_platform::threat_intelligence_tests {
    use cti_platform::threat_intelligence;
    use std::string;
    use std::vector;
    use sui::coin;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, Scenario};
    use sui::clock;

    const ADMIN: address = @0x123;
    const USER1: address = @0x456;
    const USER2: address = @0x789;

    #[test]
    fun test_platform_initialization() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // Initialize platform
        {
            threat_intelligence::init_for_testing(test_scenario::ctx(scenario));
        };

        // Check platform was created
        test_scenario::next_tx(scenario, ADMIN);
        {
            assert!(test_scenario::has_most_recent_shared<threat_intelligence::CTIPlatform>(), 0);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_participant_registration() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // Initialize platform
        {
            threat_intelligence::init_for_testing(test_scenario::ctx(scenario));
        };

        // Register participant
        test_scenario::next_tx(scenario, USER1);
        {
            let platform = test_scenario::take_shared<threat_intelligence::CTIPlatform>(scenario);
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            
            threat_intelligence::register_participant(
                &mut platform,
                string::utf8(b"Test Organization"),
                &clock,
                test_scenario::ctx(scenario)
            );

            clock::destroy_for_testing(clock);
            test_scenario::return_shared(platform);
        };

        // Check participant profile was created
        test_scenario::next_tx(scenario, USER1);
        {
            assert!(test_scenario::has_most_recent_for_sender<threat_intelligence::ParticipantProfile>(scenario), 0);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_intelligence_submission() {
        let scenario_val = test_scenario::begin(ADMIN);
        let scenario = &mut scenario_val;

        // Initialize and register participant
        {
            threat_intelligence::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, USER1);
        {
            let platform = test_scenario::take_shared<threat_intelligence::CTIPlatform>(scenario);
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            
            threat_intelligence::register_participant(
                &mut platform,
                string::utf8(b"Test Organization"),
                &clock,
                test_scenario::ctx(scenario)
            );

            clock::destroy_for_testing(clock);
            test_scenario::return_shared(platform);
        };

        // Submit intelligence
        test_scenario::next_tx(scenario, USER1);
        {
            let platform = test_scenario::take_shared<threat_intelligence::CTIPlatform>(scenario);
            let profile = test_scenario::take_from_sender<threat_intelligence::ParticipantProfile>(scenario);
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            
            let fee_coin = coin::mint_for_testing<SUI>(1000000, test_scenario::ctx(scenario));
            
            threat_intelligence::submit_intelligence(
                &mut platform,
                &mut profile,
                vector::empty<u8>(),
                string::utf8(b"malware"),
                5,
                80,
                string::utf8(b"test_pattern"),
                vector::empty<string::String>(),
                24,
                fee_coin,
                &clock,
                test_scenario::ctx(scenario)
            );

            clock::destroy_for_testing(clock);
            test_scenario::return_to_sender(scenario, profile);
            test_scenario::return_shared(platform);
        };

        // Check intelligence was created
        test_scenario::next_tx(scenario, USER1);
        {
            assert!(test_scenario::has_most_recent_for_sender<threat_intelligence::ThreatIntelligence>(scenario), 0);
        };

        test_scenario::end(scenario_val);
    }
}