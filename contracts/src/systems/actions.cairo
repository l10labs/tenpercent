// define the interface
#[starknet::interface]
trait IActions<TState> {
    fn join_pit(ref self: TState, pit_id: u32, token_amount: u128);
    fn move(ref self: TState, pit_id: u32, square_id: u8);
    fn buy_tokens(ref self: TState, pit_id: u32);
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

    fn dojo_init(ref self: ContractState) {
        let world = self.world_storage();
        self.bomb_game.create_pit(world);
    }


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn join_pit(ref self: ContractState, pit_id: u32, token_amount: u128) {
            let world = self.world_storage();
            self.bomb_game.join_game(world, pit_id, token_amount);
        }

        fn move(ref self: ContractState, pit_id: u32, square_id: u8) {
            let world = self.world_storage();
            self.bomb_game.move_to_square(world, pit_id, square_id);
            self.bomb_game.progress_round(world, pit_id);
        }

        fn buy_tokens(ref self: ContractState, pit_id: u32) {
            let world = self.world_storage();
            self.bomb_game.claim_mock_tokens(world, pit_id);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS())
        }
    }
}