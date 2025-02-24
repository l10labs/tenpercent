// define the interface
#[starknet::interface]
pub trait IActions<TState> {
    fn create_game(ref self: TState);
    fn join_game(ref self: TState, game_id: u128);
    fn claim_tile(ref self: TState, game_id: u128, x: u8, y: u8);
}

#[dojo::contract]
pub mod actions {
    use dojo::world::WorldStorage;
    use achievement::components::achievable::AchievableComponent;
    use grid_guru::components::playable::PlayableComponent;
    use grid_guru::types::trophy::{Trophy, TrophyTrait, TROPHY_COUNT};
    use grid_guru::constants::DEFAULT_NS;
    use super::{IActions};

    component!(path: PlayableComponent, storage: playable, event: PlayableEvent);
    impl PlayableInternalImpl = PlayableComponent::InternalImpl<ContractState>;
    component!(path: AchievableComponent, storage: achievable, event: AchievableEvent);
    impl AchievableInternalImpl = AchievableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub playable: PlayableComponent::Storage,
        #[substorage(v0)]
        achievable: AchievableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PlayableEvent: PlayableComponent::Event,
        #[flat]
        AchievableEvent: AchievableComponent::Event,
    }

    fn dojo_init(self: @ContractState) {
        // [Event] Emit all Trophy events
        let world = self.world(@DEFAULT_NS());
        let mut trophy_id: u8 = TROPHY_COUNT;
        while trophy_id > 0 {
            let trophy: Trophy = trophy_id.into();
            self
                .achievable
                .create(
                    world,
                    id: trophy.identifier(),
                    hidden: trophy.hidden(),
                    index: trophy.index(),
                    points: trophy.points(),
                    start: trophy.start(),
                    end: trophy.end(),
                    group: trophy.group(),
                    icon: trophy.icon(),
                    title: trophy.title(),
                    description: trophy.description(),
                    tasks: trophy.tasks(),
                    data: trophy.data(),
                );
            trophy_id -= 1;
        }
    }

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
