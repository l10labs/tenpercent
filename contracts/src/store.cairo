use dojo::world::WorldStorage;
use dojo::model::ModelStorage;
use starknet::ContractAddress;

use crate::models::index::{Pit, Player, Square, RoundResult, PitQueue, Token};

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

    // Pit related functions
    #[inline]
    fn set_pit(ref self: Store, pit: Pit) {
        self.world.write_model(@pit)
    }

    #[inline]
    fn get_pit(self: Store, pit_id: u32) -> Pit {
        self.world.read_model(pit_id)
    }

    // PitQueue related functions
    #[inline]
    fn set_pit_queue(ref self: Store, pit_queue: PitQueue) {
        self.world.write_model(@pit_queue)
    }

    #[inline]
    fn get_pit_queue(self: Store, pit_id: u32) -> PitQueue {
        self.world.read_model(pit_id)
    }

    // Player related functions
    #[inline]
    fn set_player(ref self: Store, player: Player) {
        self.world.write_model(@player)
    }

    #[inline]
    fn get_player(self: Store, pit_id: u32, address: ContractAddress) -> Player {
        self.world.read_model((pit_id, address))
    }

    // Square related functions
    #[inline]
    fn set_square(ref self: Store, square: Square) {
        self.world.write_model(@square)
    }

    #[inline]
    fn get_square(self: Store, pit_id: u32, square_id: u8) -> Square {
        self.world.read_model((pit_id, square_id))
    }

    // RoundResult related functions
    #[inline]
    fn set_round_result(ref self: Store, result: RoundResult) {
        self.world.write_model(@result)
    }

    #[inline]
    fn get_round_result(self: Store, pit_id: u32, round: u32) -> RoundResult {
        self.world.read_model((pit_id, round))
    }

    // Token related functions
    #[inline]
    fn set_token(ref self: Store, token: Token) {
        self.world.write_model(@token)
    }

    #[inline]
    fn get_token(self: Store, address: ContractAddress) -> Token {
        self.world.read_model(address)
    }
}
