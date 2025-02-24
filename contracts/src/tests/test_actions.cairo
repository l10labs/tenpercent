pub mod test_actions {
    use crate::systems::actions::{IActionsDispatcherTrait};
    use crate::tests::setup::setup;
    use crate::store::{Store, StoreTrait};
    use starknet::testing::{set_contract_address};

    use crate::constants::{
        NUM_SQUARES, TOKENS_PER_CLAIM, MINIMUM_ENTRY_BALANCE, INITIAL_BOMB_COUNTER,
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
        let minimum_entry_balance = MINIMUM_ENTRY_BALANCE;

        // Check pit state
        let pit = store.get_pit(1);
        assert(pit.is_active == false, 'Pit should not be active');

        // Then join pit
        systems.actions.join_pit(ACTIVE_PIT_ID, minimum_entry_balance);

        // [Verification]
        // Check player state
        let player = store.get_player(ACTIVE_PIT_ID, setup::OWNER());
        assert(player.balance > 0, 'Player balance should be > 0');
        assert(player.square_id < NUM_SQUARES, 'Invalid square id');
        assert(player.locked_balance > 0, 'No locked balance');

        // Check pit state
        let pit = store.get_pit(ACTIVE_PIT_ID);
        assert(pit.is_active == true, 'Pit should be active');

        // Check square state
        let square = store.get_square(ACTIVE_PIT_ID, player.square_id);
        assert(square.total_balance > 0, 'Square balance should be > 0');

        // Check token state
        let token = store.get_token(setup::OWNER());
        assert(
            token.balance == TOKENS_PER_CLAIM - MINIMUM_ENTRY_BALANCE, 'Wrong remaining balance',
        );
    }
    // #[test]
// #[available_gas(300000000)]
// fn test_move() {
//     // [Setup]
//     let (world, systems) = spawn_game();
//     let mut store: Store = StoreTrait::new(world);

    //     // Setup initial state
//     systems.actions.buy_tokens(1);
//     systems.actions.join_pit(1, MINIMUM_ENTRY_BALANCE);

    //     // Get initial state
//     let initial_player = store.get_player(1, OWNER());
//     let initial_square_id = initial_player.square_id;
//     let initial_pit = store.get_pit(1);
//     let initial_bomb_counter = initial_pit.bomb_counter;

    //     // [Action]
//     let new_square_id = (initial_square_id + 1) % NUM_SQUARES;
//     systems.actions.move(1, new_square_id);

    //     // [Verification]
//     // Check player moved
//     let player = store.get_player(1, OWNER());
//     assert(player.square_id == new_square_id, 'Player did not move');

    //     // Check old square balance
//     let old_square = store.get_square(1, initial_square_id);
//     assert(old_square.total_balance == 0, 'Old square not empty');

    //     // Check new square balance
//     let new_square = store.get_square(1, new_square_id);
//     assert(new_square.total_balance > 0, 'New square balance wrong');

    //     // Check bomb counter decreased
//     let pit = store.get_pit(1);
//     assert(pit.bomb_counter == initial_bomb_counter - 1, 'Bomb counter not decreased');

    //     // Check moves incremented
//     let token = store.get_token(OWNER());
//     assert(token.moves_since_last_claim == 1, 'Moves not incremented');
// }

    // #[test]
// #[should_panic(expected: ('Game: already in square', ))]
// fn test_move_to_same_square() {
//     // [Setup]
//     let (world, systems) = spawn_game();

    //     // Setup initial state
//     systems.actions.buy_tokens(1);
//     systems.actions.join_pit(1, MINIMUM_ENTRY_BALANCE);

    //     // Get current square
//     let store: Store = StoreTrait::new(world);
//     let player = store.get_player(1, OWNER());
//     let current_square = player.square_id;

    //     // [Action]
//     // Try to move to same square
//     systems.actions.move(1, current_square);
// }

    // #[test]
// #[should_panic(expected: ('Game: not minimum entry balance', ))]
// fn test_join_pit_insufficient_balance() {
//     // [Setup]
//     let (world, systems) = spawn_game();

    //     // Get tokens
//     systems.actions.buy_tokens(1);

    //     // [Action]
//     // Try to join with less than minimum
//     systems.actions.join_pit(1, MINIMUM_ENTRY_BALANCE - 1);
// }
}
