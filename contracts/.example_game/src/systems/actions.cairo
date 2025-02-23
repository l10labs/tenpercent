// define the interface
#[starknet::interface]
trait IActions<TState> {
    fn create_game(ref self: TState);
    fn join_game(ref self: TState, game_id: u128);
    fn claim_tile(ref self: TState, game_id: u128, x: u8, y: u8);
}

#[dojo::contract]
pub mod actions {
    use dojo::world::WorldStorage;

    use grid_guru::components::playable::PlayableComponent;
    use grid_guru::constants::DEFAULT_NS;
    use super::{IActions};

    component!(path: PlayableComponent, storage: playable, event: PlayableEvent);
    impl PlayableInternalImpl = PlayableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        playable: PlayableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PlayableEvent: PlayableComponent::Event,
    }

    fn dojo_init(self: @ContractState) {}

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref self: ContractState) {
            let world = self.world_storage();
            self.playable.create_game(world);
        }

        fn join_game(ref self: ContractState, game_id: u128) {
            let world = self.world_storage();
            self.playable.join_game(world, game_id);
        }

        fn claim_tile(ref self: ContractState, game_id: u128, x: u8, y: u8) {
            let world = self.world_storage();
            self.playable.claim_tile(world, game_id, x, y);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS())
        }
    }
}
