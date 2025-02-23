pub use crate::models::index::{Pit, PitStatus};

pub mod errors {
    pub const PIT_NOT_ACTIVE: felt252 = 'Pit: not active';
    pub const INVALID_PIT_ID: felt252 = 'Pit: invalid pit id';
}

#[generate_trait]
pub impl PitImpl of PitTrait {
    #[inline]
    fn new(pit_id: u32) -> Pit {
        Pit {
            pit_id,
            bomb_counter: crate::constants::INITIAL_BOMB_COUNTER,
            round_number: 1,
            is_active: true,
            status: PitStatus::Active,
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
        self.bomb_counter = crate::constants::INITIAL_BOMB_COUNTER;
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