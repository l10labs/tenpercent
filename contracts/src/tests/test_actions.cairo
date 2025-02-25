pub mod test_actions {
    use crate::systems::actions::{IActionsDispatcherTrait};
    use crate::tests::setup::setup;
    use crate::store::{Store, StoreTrait};
    use starknet::testing::{set_contract_address};
    use starknet::ContractAddress;

    use crate::constants::{TOKENS_PER_CLAIM, MINIMUM_ENTRY_BALANCE, PENALTY_PERCENTAGE};
    use crate::helpers::get_escrow_and_modulo;

    const ACTIVE_PIT_ID: u32 = 0;

    fn p1() -> ContractAddress {
        setup::OWNER()
    }

    fn p2() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER2'>()
    }

    fn p3() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER3'>()
    }

    fn p4() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER4'>()
    }

    fn p5() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER5'>()
    }

    fn p6() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER6'>()
    }


    #[test]
    #[available_gas(300000000)]
    fn test_buy_tokens() {
        // [Setup]
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);

        // Player Action
        systems.actions.buy_tokens(ACTIVE_PIT_ID);

        let player_tokens = store.get_token(setup::OWNER());
        assert(player_tokens.balance == TOKENS_PER_CLAIM, 'Wrong token balance');
        assert(player_tokens.has_claimed == true, 'Token not claimed');
        assert(player_tokens.moves_since_last_claim == 0, 'Moves not reset');
    }

    #[test]
    #[available_gas(300000000)]
    fn test_join_pit() {
        // [Setup]
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);

        // [Action]
        // First get tokens
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        let player_wager = MINIMUM_ENTRY_BALANCE;
        let expected_player_escrow = (player_wager * PENALTY_PERCENTAGE) / 100;
        let expected_player_pit_balance = player_wager - expected_player_escrow;
        let expected_player_token_balance = TOKENS_PER_CLAIM - player_wager;

        let player_tokens = store.get_token(setup::OWNER());
        assert(player_tokens.balance == TOKENS_PER_CLAIM, 'Wrong token balance');

        // Then join pit
        systems.actions.join_pit(ACTIVE_PIT_ID, player_wager);

        // [Verification]
        // Check player state
        let player = store.get_player(ACTIVE_PIT_ID, setup::OWNER());
        assert(player.square_id == 0, 'Invalid square id');
        assert(player.balance == expected_player_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == expected_player_escrow, 'Incorrect escrow');

        // Check square state
        let square = store.get_square(ACTIVE_PIT_ID, player.square_id);
        assert(square.total_balance == expected_player_pit_balance, 'Incorrect square balance');
        assert(square.total_escrow == expected_player_escrow, 'Incorrect square escrow');

        // Check token state
        let token = store.get_token(setup::OWNER());
        assert(token.balance == expected_player_token_balance, 'Wrong remaining balance');
    }

    #[test]
    #[available_gas(300000000)]
    fn test_6_players_join_pit() {
        // [Setup]
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);
        let common_wager = MINIMUM_ENTRY_BALANCE;
        let (common_escrow, common_modulo) = get_escrow_and_modulo(common_wager);
        let common_pit_balance = common_wager - common_escrow;

        let square_balance_for_a_and_b = common_pit_balance * 2;
        let square_escrow_for_a_and_b = common_escrow * 2;
        let square_balance_for_c_and_d = common_pit_balance;
        let square_escrow_for_c_and_d = common_escrow;

        let p1_square_id = 0;
        let p2_square_id = 1;
        let p3_square_id = 2;
        let p4_square_id = 3;
        let p5_square_id = 0;
        let p6_square_id = 1;

        // [Action]
        set_contract_address(p1());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        set_contract_address(p2());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        set_contract_address(p3());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        set_contract_address(p4());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        set_contract_address(p5());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        set_contract_address(p6());
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, common_wager);

        // [Verification]
        let player = store.get_player(ACTIVE_PIT_ID, p1());
        assert(player.square_id == p1_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p1_square_id);
        assert(square.total_balance == square_balance_for_a_and_b, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_a_and_b, 'Incorrect square escrow');

        let player = store.get_player(ACTIVE_PIT_ID, p2());
        assert(player.square_id == p2_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p2_square_id);
        assert(square.total_balance == square_balance_for_a_and_b, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_a_and_b, 'Incorrect square escrow');

        let player = store.get_player(ACTIVE_PIT_ID, p3());
        assert(player.square_id == p3_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p3_square_id);
        assert(square.total_balance == square_balance_for_c_and_d, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_c_and_d, 'Incorrect square escrow');

        let player = store.get_player(ACTIVE_PIT_ID, p4());
        assert(player.square_id == p4_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p4_square_id);
        assert(square.total_balance == square_balance_for_c_and_d, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_c_and_d, 'Incorrect square escrow');

        let player = store.get_player(ACTIVE_PIT_ID, p5());
        assert(player.square_id == p5_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p5_square_id);
        assert(square.total_balance == square_balance_for_a_and_b, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_a_and_b, 'Incorrect square escrow');

        let player = store.get_player(ACTIVE_PIT_ID, p6());
        assert(player.square_id == p6_square_id, 'Invalid square id');
        assert(player.balance == common_pit_balance, 'Incorrect pit balance');
        assert(player.escrow == common_escrow, 'Incorrect escrow');
        let square = store.get_square(ACTIVE_PIT_ID, p6_square_id);
        assert(square.total_balance == square_balance_for_a_and_b, 'Incorrect square balance');
        assert(square.total_escrow == square_escrow_for_a_and_b, 'Incorrect square escrow');
    }

    #[test]
    #[available_gas(300000000)]
    fn test_move() {
        // [Setup]
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);

        // Setup initial state
        systems.actions.buy_tokens(ACTIVE_PIT_ID);
        systems.actions.join_pit(ACTIVE_PIT_ID, MINIMUM_ENTRY_BALANCE);

        let expected_wager = MINIMUM_ENTRY_BALANCE;
        let expected_escrow = (expected_wager * PENALTY_PERCENTAGE) / 100;
        let expected_pit_balance = expected_wager - expected_escrow;
        let new_square_to_move_to_id = 1;

        systems.actions.move(ACTIVE_PIT_ID, new_square_to_move_to_id);

        let player = store.get_player(ACTIVE_PIT_ID, setup::OWNER());
        assert(player.square_id == new_square_to_move_to_id, 'Player did not move');
        assert(player.balance == expected_pit_balance, 'Player balance wrong');
        assert(player.escrow == expected_escrow, 'Player escrow wrong');

        let old_square_id = 0;

        let old_square = store.get_square(ACTIVE_PIT_ID, old_square_id);
        assert(old_square.total_balance == 0, 'Old square not empty');
        assert(old_square.total_escrow == 0, 'Old square escrow wrong');

        let square = store.get_square(ACTIVE_PIT_ID, new_square_to_move_to_id);
        assert(square.total_balance == expected_pit_balance, 'Square balance wrong');
        assert(square.total_escrow == expected_escrow, 'Square escrow wrong');
    }
}
