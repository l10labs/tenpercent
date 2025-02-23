use dojo::world::WorldStorage;
use dojo::model::ModelStorage;
use starknet::ContractAddress;

use crate::models::index::{Pit, Player, Square, RoundResult};

#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn set_pit(ref self: Store, pit: Pit) {
        self.world.write_model(@pit)
    }

    #[inline]
    fn set_player(ref self: Store, player: Player) {
        self.world.write_model(@player)
    }

    #[inline]
    fn set_square(ref self: Store, square: Square) {
        self.world.write_model(@square)
    }

    #[inline]
    fn set_round_result(ref self: Store, result: RoundResult) {
        self.world.write_model(@result)
    }

    #[inline]
    fn get_pit(self: Store, pit_id: u32) -> Pit {
        self.world.read_model(pit_id)
    }

    #[inline]
    fn get_player(self: Store, pit_id: u32, address: ContractAddress) -> Player {
        self.world.read_model((pit_id, address))
    }

    #[inline]
    fn get_square(self: Store, pit_id: u32, square_id: u8) -> Square {
        self.world.read_model((pit_id, square_id))
    }

    #[inline]
    fn get_round_result(self: Store, pit_id: u32, round: u32) -> RoundResult {
        self.world.read_model((pit_id, round))
    }
}
