// define the interface
#[starknet::interface]
trait IActions<TState> {
    fn create_game(ref self: TState);
    fn join_game(ref self: TState, pit_id: u32);
    // fn move_to_square(ref self: TState, pit_id: u32, square_id: u8);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo::world::WorldStorage;

    use crate::components::bomb_game::BombGameComponent;
    use crate::constants::DEFAULT_NS;
    use super::IActions;

    component!(path: BombGameComponent, storage: bomb_game, event: BombGameEvent);
    impl BombGameInternalImpl = BombGameComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        bomb_game: BombGameComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        BombGameEvent: BombGameComponent::Event,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref self: ContractState) {
            let world = self.world_storage();
            self.bomb_game.create_game(world);
        }

        fn join_game(ref self: ContractState, pit_id: u32) {
            let world = self.world_storage();
            self.bomb_game.join_game(world, pit_id);
        }

        // fn move_to_square(ref self: ContractState, pit_id: u32, square_id: u8) {
        //     let world = self.world_storage();
        //     self.bomb_game.move_to_square(world, pit_id, square_id);
        // }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS())
        }
    }
}