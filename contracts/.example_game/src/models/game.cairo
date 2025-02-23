pub use grid_guru::models::index::{Game, GameStatus};
use starknet::ContractAddress;

pub mod errors {
    pub const GAME_NOT_IN_PROGRESS: felt252 = 'Game: not in progress';
    pub const GAME_NOT_PENDING: felt252 = 'Game: not pending';
    pub const CANNOT_PLAY_SELF: felt252 = 'Game: Cannot play self';
    pub const INVALID_PLAYER_ADDRESS: felt252 = 'Game: invalid player address';
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    #[inline]
    fn new(game_id: u128, player_one: ContractAddress) -> Game {
        assert(
            player_one != core::num::traits::Zero::<ContractAddress>::zero(),
            errors::INVALID_PLAYER_ADDRESS,
        );
        Game {
            game_id,
            player_one,
            player_two: core::num::traits::Zero::<ContractAddress>::zero(),
            current_player: player_one,
            move_count: 0,
            winner: core::num::traits::Zero::<ContractAddress>::zero(),
            status: GameStatus::Pending,
        }
    }

    #[inline]
    fn join(ref self: Game, player: ContractAddress) {
        assert(self.status == GameStatus::Pending, errors::GAME_NOT_PENDING);
        assert(player != self.player_one, errors::CANNOT_PLAY_SELF);
        assert(
            player != core::num::traits::Zero::<ContractAddress>::zero(),
            errors::INVALID_PLAYER_ADDRESS,
        );
        self.player_two = player;
        self.status = GameStatus::InProgress;
    }

    #[inline]
    fn handle_player_switch(ref self: Game) {
        assert(self.status == GameStatus::InProgress, errors::GAME_NOT_IN_PROGRESS);
        self
            .current_player =
                if self.current_player == self.player_one {
                    self.player_two
                } else {
                    self.player_one
                };
    }
}

#[generate_trait]
impl PlayerAssert of AssertTrait {}
