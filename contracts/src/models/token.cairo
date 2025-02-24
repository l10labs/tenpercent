pub use crate::models::index::Token;
use crate::constants::{MOVES_PER_CLAIM, TOKENS_PER_CLAIM};
use starknet::ContractAddress;

pub mod errors {
    pub const ALREADY_CLAIMED: felt252 = 'Token: already claimed';
    pub const INSUFFICIENT_MOVES: felt252 = 'Token: insufficient moves';
}

#[generate_trait]
pub impl TokenImpl of TokenTrait {
    #[inline]
    fn new(player: ContractAddress) -> Token {
        Token {
            player,
            balance: 0,
            moves_since_last_claim: 0,
            has_claimed: false,
        }
    }

    #[inline]
    fn can_claim(self: @Token) -> bool {
        !*self.has_claimed || *self.moves_since_last_claim >= MOVES_PER_CLAIM
    }

    #[inline]
    fn claim_tokens(ref self: Token) {
        assert(self.can_claim(), errors::INSUFFICIENT_MOVES);
        self.balance += TOKENS_PER_CLAIM;
        self.moves_since_last_claim = 0;
        self.has_claimed = true;
    }

    #[inline]
    fn increment_moves(ref self: Token) {
        self.moves_since_last_claim += 1;
    }
} 