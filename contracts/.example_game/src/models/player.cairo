pub use grid_guru::models::index::Player;
use starknet::ContractAddress;

pub mod errors {}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    #[inline]
    fn new(game_id: u128, address: ContractAddress, x: u8, y: u8) -> Player {
        Player { game_id, address, score: 0, x, y }
    }
}

#[generate_trait]
impl PlayerAssert of AssertTrait {}
