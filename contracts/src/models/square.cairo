pub use crate::models::index::Square;

pub mod errors {
    pub const INVALID_SQUARE_ID: felt252 = 'Square: invalid square id';
}

#[generate_trait]
pub impl SquareImpl of SquareTrait {
    #[inline]
    fn new(pit_id: u32, square_id: u8) -> Square {
        assert(square_id < crate::constants::NUM_SQUARES, errors::INVALID_SQUARE_ID);
        Square { 
            pit_id,
            square_id,
            total_balance: 0
        }
    }

    #[inline]
    fn add_balance(ref self: Square, amount: u128) {
        self.total_balance += amount;
    }

    #[inline]
    fn remove_balance(ref self: Square, amount: u128) {
        self.total_balance -= amount;
    }
}

#[generate_trait]
impl SquareAssert of AssertTrait {
    #[inline]
    fn assert_valid_square_id(square_id: u8) {
        assert(square_id < crate::constants::NUM_SQUARES, errors::INVALID_SQUARE_ID);
    }
} 