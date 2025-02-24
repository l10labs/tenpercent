pub use crate::models::index::{Pit, PitStatus};

use crate::constants::INITIAL_BOMB_COUNTER;

pub mod errors {
    pub const PIT_NOT_ACTIVE: felt252 = 'Pit: not active';
    pub const INVALID_PIT_ID: felt252 = 'Pit: invalid pit id';
    pub const BOMB_COUNTER_NOT_ZERO: felt252 = 'Pit: bomb counter not zero';
}

#[generate_trait]
pub impl PitImpl of PitTrait {
    #[inline]
    fn new(pit_id: u32) -> Pit {
        Pit {
            pit_id,
            bomb_counter: INITIAL_BOMB_COUNTER,
            round_number: 1,
            is_active: true,
            status: PitStatus::Active,
            modulo_pool: 0,
        }
    }

    #[inline]
    fn decrement_bomb_counter(ref self: Pit) {
        assert(self.is_active, errors::PIT_NOT_ACTIVE);
        if self.bomb_counter > 0 {
            self.bomb_counter -= 1;
        }
    }

    #[inline]
    fn start_new_round(ref self: Pit) {
        assert(self.is_active, errors::PIT_NOT_ACTIVE);
        assert(self.bomb_counter == 0, errors::BOMB_COUNTER_NOT_ZERO);
        self.bomb_counter = INITIAL_BOMB_COUNTER;
        self.round_number += 1;
    }
}

#[generate_trait]
impl PitAssert of AssertTrait {
    #[inline]
    fn assert_active(self: Pit) {
        assert(self.is_active, errors::PIT_NOT_ACTIVE);
    }
} 