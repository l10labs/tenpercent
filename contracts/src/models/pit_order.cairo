pub use crate::models::index::PitOrder;
use crate::constants::NUM_SQUARES;

pub mod errors {
    pub const INVALID_NEXT_SQUARE: felt252 = 'PitOrder: invalid next square';
}

#[generate_trait]
pub impl PitOrderImpl of PitOrderTrait {
    #[inline]
    fn new(pit_id: u32) -> PitOrder {
        PitOrder {
            pit_id,
            next_square: 0,
        }
    }

    #[inline]
    fn get_and_increment_next_square(ref self: PitOrder) -> u8 {
        let current_square = self.next_square;
        // Increment and wrap around to 0 when reaching NUM_SQUARES
        self.next_square = (self.next_square + 1) % NUM_SQUARES;
        current_square
    }
}

#[generate_trait]
impl PitOrderAssert of AssertTrait {
    #[inline]
    fn assert_valid_next_square(self: @PitOrder) {
        assert(*self.next_square < NUM_SQUARES, errors::INVALID_NEXT_SQUARE);
    }
} 