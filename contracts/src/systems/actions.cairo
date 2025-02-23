
// define the interface
#[starknet::interface]
trait IActions<T> {
    fn increment(ref self: T);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions};

    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;

    use crate::models::counter::Counter;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Incremented {
        #[key]
        pub id: felt252,
        pub count: u64,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn increment(ref self: ContractState) {
            // Get the default world.
            let mut world = self.world_default();

            let mut counter: Counter = world.read_model(0);
            counter.count += 1;
            world.write_model(@counter);

            world.emit_event(@Incremented { id: 0, count: counter.count });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}