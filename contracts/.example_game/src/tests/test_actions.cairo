pub mod test_actions {
    use grid_guru::systems::actions::{IActionsDispatcherTrait};
    use grid_guru::tests::setup::setup;
    use grid_guru::store::{Store, StoreTrait};
    use starknet::testing::{set_contract_address};

    #[test]
    #[available_gas(300000000000)]
    fn test_create_game() {
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);
        systems.actions.create_game();

        let game = store.get_game(1);
        assert(game.player_one == setup::OWNER(), 'player one not owner');

        let player = store.get_player(1, setup::OWNER());
        assert(player.score == 0, 'player one score not 0');

        let tile = store.get_tile(1, 0, 0);
        assert(tile.owner == setup::OWNER(), '0x0 not owned by player');
    }

    #[test]
    #[available_gas(300000000000)]
    fn test_join_game() {
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);
        systems.actions.create_game();
        let game_id = 1;

        // Change caller to second player
        let ANYONE = starknet::contract_address_const::<'ANYONE'>();
        set_contract_address(ANYONE);

        systems.actions.join_game(game_id);

        let game = store.get_game(game_id);
        assert(game.player_two == ANYONE, 'player two not ANYONE');

        let player = store.get_player(1, ANYONE);
        assert(player.score == 0, 'player one score not 0');

        let tile = store.get_tile(1, 7, 7);
        assert(tile.owner == ANYONE, '7x7 not owned by player');
    }

    #[test]
    #[available_gas(300000000000)]
    fn test_claim_tile() {
        let (world, systems) = setup::spawn_game();
        let mut store: Store = StoreTrait::new(world);
        systems.actions.create_game();
        let game_id = 1;

        // Change caller to second player
        let ANYONE = starknet::contract_address_const::<'ANYONE'>();
        set_contract_address(ANYONE);

        systems.actions.join_game(game_id);

        // Change caller to first player
        set_contract_address(setup::OWNER());

        systems.actions.claim_tile(game_id, 1, 0);

        let tile = store.get_tile(1, 1, 0);
        assert(tile.owner == setup::OWNER(), '1x0 not owned by player');

        let game = store.get_game(game_id);
        assert(game.current_player == ANYONE, 'player was not switched');
        
    }
}
