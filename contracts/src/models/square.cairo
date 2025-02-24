pub use crate::models::index::Square;
use crate::constants::NUM_SQUARES;

pub mod errors {
    pub const INVALID_SQUARE_ID: felt252 = 'Square: invalid square id';
    pub const NEGATIVE_BALANCE: felt252 = 'Square: negative balance';
    pub const NEGATIVE_ESCROW: felt252 = 'Square: negative escrow';
}

#[generate_trait]
pub impl SquareImpl of SquareTrait {
    #[inline]
    fn new(pit_id: u32, square_id: u8) -> Square {
        assert(square_id < NUM_SQUARES, errors::INVALID_SQUARE_ID);
        Square { pit_id, square_id, total_balance: 0, total_escrow: 0 }
    }

    #[inline]
    fn add_balance(ref self: Square, amount: u128) {
        self.total_balance += amount;
    }

    #[inline]
    fn add_escrow(ref self: Square, amount: u128) {
        self.total_escrow += amount;
    }

    #[inline]
    fn remove_balance(ref self: Square, amount: u128) {
        assert(self.total_balance >= amount, errors::NEGATIVE_BALANCE);
        self.total_balance -= amount;
    }

    #[inline]
    fn remove_escrow(ref self: Square, amount: u128) {
        assert(self.total_escrow >= amount, errors::NEGATIVE_ESCROW);
        self.total_escrow -= amount;
    }
}

#[generate_trait]
pub impl SquareAssert of AssertTrait {
    #[inline]
    fn assert_valid_square_id(self: Square) {
        assert(self.square_id < NUM_SQUARES, errors::INVALID_SQUARE_ID);
    }
}
