//! Store struct and component management methods.
use dojo::model::ModelStorage;
use dojo::world::WorldStorage;
use grid_guru::models::game::Game;

// Models imports
use grid_guru::models::player::Player;
use grid_guru::models::tile::Tile;
use starknet::ContractAddress;

// Structs
#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

// Implementations
#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn set_game(ref self: Store, game: Game) {
        self.world.write_model(@game)
    }

    #[inline]
    fn set_player(ref self: Store, player: Player) {
        self.world.write_model(@player);
    }

    #[inline]
    fn set_tile(ref self: Store, tile: Tile) {
        self.world.write_model(@tile);
    }

    #[inline]
    fn get_game(self: Store, game_id: u128) -> Game {
        self.world.read_model(game_id)
    }

    #[inline]
    fn get_player(self: Store, game_id: u128, address: ContractAddress) -> Player {
        self.world.read_model((game_id, address))
    }

    #[inline]
    fn get_tile(self: Store, game_id: u128, x: u8, y: u8) -> Tile {
        self.world.read_model((game_id, x, y))
    }
}
