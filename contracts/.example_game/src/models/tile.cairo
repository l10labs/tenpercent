use dojo::world::WorldStorage;
use grid_guru::models::game::Game;
pub use grid_guru::models::index::Tile;
use grid_guru::store::{Store, StoreTrait};
use starknet::ContractAddress;

pub mod errors {
    pub const TILE_ALREADY_CLAIMED: felt252 = 'Tile already claimed';
    pub const OUT_OF_BOUNDS: felt252 = 'Out of bounds';
    pub const NO_ADJACENT_TILE: felt252 = 'No adjacent tile owned';
    pub const NOT_PLAYER_TURN: felt252 = 'Not player turn';
}

#[generate_trait]
pub impl TileImpl of TileTrait {
    #[inline]
    fn new(game_id: u128, x: u8, y: u8, owner: ContractAddress) -> Tile {
        Tile { game_id, x, y, owner }
    }

    #[inline]
    fn is_game_over(world: WorldStorage, game_id: u128) -> bool {
        let store: Store = StoreTrait::new(world);
        let mut total_claimed = 0;

        let mut x = 0;
        loop {
            if x >= 8 {
                break;
            }
            let mut y = 0;
            loop {
                if y >= 8 {
                    break;
                }
                let tile = store.get_tile(game_id, x, y);
                if tile.owner != core::num::traits::Zero::<ContractAddress>::zero() {
                    total_claimed += 1;
                }
                y += 1;
            };
            x += 1;
        };

        total_claimed == 64
    }

    #[inline]
    fn get_adjacent_positions(ref self: Tile, x: u8, y: u8) -> Array<(u8, u8)> {
        let mut positions = ArrayTrait::new();

        if x > 0 {
            positions.append((x - 1, y));
        }

        if x < 7 {
            positions.append((x + 1, y));
        }

        if y > 0 {
            positions.append((x, y - 1));
        }

        if y < 7 {
            positions.append((x, y + 1));
        }

        positions
    }

    #[inline]
    fn get_winner(world: WorldStorage, game_id: u128) -> ContractAddress {
        let store: Store = StoreTrait::new(world);
        let mut player_one_count: u8 = 0;
        let mut player_two_count: u8 = 0;
        let game = store.get_game(game_id);

        let mut x = 0;
        loop {
            if x >= 8 {
                break;
            }
            let mut y = 0;
            loop {
                if y >= 8 {
                    break;
                }
                let tile = store.get_tile(game_id, x, y);
                if tile.owner == game.player_one {
                    player_one_count += 1;
                } else if tile.owner == game.player_two {
                    player_two_count += 1;
                }
                y += 1;
            };
            x += 1;
        };

        if player_one_count > player_two_count {
            game.player_one
        } else {
            game.player_two
        }
    }
}

#[generate_trait]
pub impl TileAssert of AssertTrait {
    #[inline]
    fn assert_is_valid_move(
        world: WorldStorage, game_id: u128, x: u8, y: u8, player: ContractAddress,
    ) {
        let store: Store = StoreTrait::new(world);
        let mut tile: Tile = store.get_tile(game_id, x, y);
        let game: Game = store.get_game(game_id);

        assert(
            tile.owner == core::num::traits::Zero::<ContractAddress>::zero(),
            errors::TILE_ALREADY_CLAIMED,
        );
        assert(x < 8 && y < 8, errors::OUT_OF_BOUNDS);
        assert(player == game.current_player, errors::NOT_PLAYER_TURN);

        if game.move_count >= 2 {
            let mut adjacents = tile.get_adjacent_positions(x, y);

            let mut has_adjacent = false;
            let mut i = 0;
            loop {
                if i >= adjacents.len() {
                    break;
                }
                let (adj_x, adj_y) = *adjacents[i];
                let adjacent_tile = store.get_tile(game_id, adj_x, adj_y);
                if adjacent_tile.owner == player {
                    has_adjacent = true;
                    break;
                }
                i += 1;
            };

            assert(has_adjacent, errors::NO_ADJACENT_TILE);
        }
    }
}
