pub use crate::models::index::Player;
use starknet::ContractAddress;

pub mod errors {
    pub const INVALID_PLAYER: felt252 = 'Player: invalid player';
    pub const INSUFFICIENT_BALANCE: felt252 = 'Player: insufficient balance';
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    #[inline]
    fn new(pit_id: u32, player: ContractAddress) -> Player {
        Player {
            pit_id,
            player,
            balance: crate::constants::INITIAL_BALANCE,
            square_id: 0,
        }
    }

    #[inline]
    fn apply_penalty(ref self: Player) -> u128 {
        let penalty = (self.balance * crate::constants::PENALTY_PERCENTAGE) / 100;
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