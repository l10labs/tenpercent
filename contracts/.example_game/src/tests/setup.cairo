pub mod setup {
    // Dojo imports
    use dojo::model::{ModelStorage, ModelStorageTest, ModelValueStorage};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use grid_guru::constants::DEFAULT_NS;

    // Internal imports
    use grid_guru::models::{index as models};
    use grid_guru::systems::actions::{
        IActions, IActionsDispatcher, IActionsDispatcherTrait, actions,
    };

    // Starknet imports
    use starknet::ContractAddress;
    use starknet::testing::{set_caller_address, set_contract_address};

    #[starknet::interface]
    trait IDojoInit<ContractState> {}

    #[derive(Drop)]
    pub struct Systems {
        pub actions: IActionsDispatcher,
    }

    pub fn OWNER() -> ContractAddress {
        starknet::contract_address_const::<'OWNER'>()
    }

    #[inline]
    fn setup_namespace() -> NamespaceDef {
        NamespaceDef {
            namespace: DEFAULT_NS(),
            resources: [
                TestResource::Model(models::m_Player::TEST_CLASS_HASH),
                TestResource::Model(models::m_Game::TEST_CLASS_HASH),
                TestResource::Model(models::m_Tile::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Event(achievement::events::index::e_TrophyCreation::TEST_CLASS_HASH),
                TestResource::Event(
                    achievement::events::index::e_TrophyProgression::TEST_CLASS_HASH,
                ),
            ]
                .span(),
        }
    }

    fn setup_contracts() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@DEFAULT_NS(), @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@DEFAULT_NS())].span()),
        ]
            .span()
    }

    #[inline(always)]
    pub fn spawn_game() -> (WorldStorage, Systems) {
        // [Setup] World
        set_contract_address(OWNER());
        let namespace_def = setup_namespace();
        let world = spawn_test_world([namespace_def].span());
        world.sync_perms_and_inits(setup_contracts());

        // [Setup] Systems
        let (actions_address, _) = world.dns(@"actions").unwrap();
        let systems = Systems { actions: IActionsDispatcher { contract_address: actions_address } };

        // [Return]
        (world, systems)
    }
}
