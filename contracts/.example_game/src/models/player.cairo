pub use grid_guru::models::index::Player;
use starknet::ContractAddress;

pub mod errors {}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    #[inline]
    fn new(game_id: u128, address: ContractAddress) -> Player {
        Player { game_id, address, score: 0 }
    }
}

#[generate_trait]
impl PlayerAssert of AssertTrait {}
