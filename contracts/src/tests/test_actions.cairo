pub mod test_actions {
    use crate::systems::actions::{IActionsDispatcherTrait};
    use crate::tests::setup::setup;
    use crate::store::{Store, StoreTrait};
    use starknet::testing::{set_contract_address};

    use crate::constants::{
        NUM_SQUARES, TOKENS_PER_CLAIM, MINIMUM_ENTRY_BALANCE, INITIAL_BOMB_COUNTER,
        PENALTY_PERCENTAGE,
    };


    const ACTIVE_PIT_ID: u32 = 0;

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
