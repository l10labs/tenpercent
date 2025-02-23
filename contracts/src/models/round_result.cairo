pub use crate::models::index::RoundResult;

#[generate_trait]
pub impl RoundResultImpl of RoundResultTrait {
    #[inline]
    fn new(pit_id: u32, round: u32, losing_square: u8, round_reward: u128) -> RoundResult {
        RoundResult {
            pit_id,
            round,
            losing_square,
            round_reward,
        }
    }
}

#[generate_trait]
impl RoundResultAssert of AssertTrait {} 