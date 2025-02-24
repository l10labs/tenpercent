#[starknet::component]
pub mod PlayableComponent {
    use dojo::world::WorldStorage;
    use dojo::world::{IWorldDispatcherTrait};
    use starknet::{get_caller_address, get_block_timestamp};
    use achievement::store::{Store as ArcadeStore, StoreTrait as ArcadeStoreTrait};

    use grid_guru::models::game::{Game, GameTrait, GameStatus};
    use grid_guru::models::player::{Player, PlayerTrait};
    use grid_guru::models::tile::{Tile, TileAssert, TileTrait};
    use grid_guru::store::{Store, StoreTrait};
    use grid_guru::types::task::{Task, TaskTrait};

    pub mod errors {
        pub const GAME_NOT_IN_PROGRESS: felt252 = 'Game: not in progress';
    }

    #[storage]
    pub struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[generate_trait]
    pub impl InternalImpl<TState, +HasComponent<TState>> of InternalTrait<TState> {
        fn create_game(ref self: ComponentState<TState>, world: WorldStorage) {
            let mut store: Store = StoreTrait::new(world);
            let game_id: u128 = world.dispatcher.uuid().into() + 1;

            let mut player: Player = PlayerTrait::new(game_id, get_caller_address(), 0, 0);
            let mut game: Game = GameTrait::new(game_id, player.address);
            let mut tile: Tile = TileTrait::new(game_id, 0, 0, player.address);

            game.move_count += 1;

            store.set_player(player);
            store.set_game(game);
            store.set_tile(tile);
        }

        fn join_game(ref self: ComponentState<TState>, world: WorldStorage, game_id: u128) {
            let mut store: Store = StoreTrait::new(world);

            let mut player: Player = PlayerTrait::new(game_id, get_caller_address(), 7, 7);
            let mut game: Game = store.get_game(game_id);
            game.join(player.address);
            let mut tile: Tile = TileTrait::new(game_id, 7, 7, player.address);
            game.move_count += 1;

            store.set_game(game);
            store.set_player(player);
            store.set_tile(tile);
        }

        fn claim_tile(
            ref self: ComponentState<TState>, world: WorldStorage, game_id: u128, x: u8, y: u8,
        ) {
            let mut store: Store = StoreTrait::new(world);

            let mut game: Game = store.get_game(game_id);
            let player: Player = store.get_player(game_id, get_caller_address());
            assert(game.status == GameStatus::InProgress, errors::GAME_NOT_IN_PROGRESS);

            TileAssert::assert_is_valid_move(world, game_id, x, y, player.address);
            let mut tile: Tile = TileTrait::new(game_id, x, y, player.address);
            game.move_count += 1;

            game.handle_player_switch();

            let is_game_over = TileTrait::is_game_over(world, game_id);
            if is_game_over {
                game.status = GameStatus::Completed;
                game.winner = TileTrait::get_winner(world, game_id);
            }

            let arcade_store: ArcadeStore = ArcadeStoreTrait::new(world);
            let task_id = Task::Moving.identifier(0);
            let time = get_block_timestamp();
            arcade_store.progress(player.address.into(), task_id, 1, time);

            store.set_game(game);
            store.set_tile(tile);
        }
    }
}
