pub use crate::models::index::PitQueue;
use crate::constants::NUM_SQUARES;

pub mod errors {
    pub const INVALID_NEXT_SQUARE: felt252 = 'PitQueue: invalid next square';
}

#[generate_trait]
pub impl PitQueueImpl of PitQueueTrait {
    #[inline]
    fn new(pit_id: u32) -> PitQueue {
        PitQueue {
            pit_id,
            next_square: 0,
        }
    }

    #[inline]
    fn get_and_increment_next_square(ref self: PitQueue) -> u8 {
        let current_square = self.next_square;
        // Increment and wrap around to 0 when reaching NUM_SQUARES
        self.next_square = (self.next_square + 1) % NUM_SQUARES;
        current_square
    }
}

#[generate_trait]
impl PitQueueAssert of AssertTrait {
    #[inline]
    fn assert_valid_next_square(self: @PitQueue) {
        assert(*self.next_square < NUM_SQUARES, errors::INVALID_NEXT_SQUARE);
    }
} 