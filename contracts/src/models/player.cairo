pub use crate::models::index::Player;
use crate::constants::PENALTY_PERCENTAGE;
use starknet::ContractAddress;

pub mod errors {
    pub const INVALID_PLAYER: felt252 = 'Player: invalid player';
    pub const INSUFFICIENT_BALANCE: felt252 = 'Player: insufficient balance';
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    #[inline]
    fn new(pit_id: u32, player_id: ContractAddress) -> Player {
        Player {
            pit_id,
            player_id,
            square_id: 0,
            balance: 0,
            locked_balance: 0,
        }
    }

    fn get_escrow_and_modulo(self: @Player) -> (u128, u128) {
        let escrow = (*self.balance * PENALTY_PERCENTAGE) / 100;
        let modulo = (*self.balance * PENALTY_PERCENTAGE) % 100;
        (escrow, modulo)
    }

    #[inline]
    fn apply_penalty(ref self: Player) -> u128 {
        let penalty = (self.balance * PENALTY_PERCENTAGE) / 100;
        self.balance -= penalty;
        penalty
    }

    #[inline]
    fn add_reward(ref self: Player, reward: u128) {
        self.balance += reward;
    }
}

#[generate_trait]
impl PlayerAssert of AssertTrait {
    #[inline]
    fn assert_valid_balance(self: Player) {
        assert(self.balance > 0, errors::INSUFFICIENT_BALANCE);
    }
} 