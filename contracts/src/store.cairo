use dojo::world::WorldStorage;
use dojo::model::ModelStorage;

use crate::models::counter::Counter;

#[derive(Copy, Drop)]
struct Store {
    world: WorldStorage,
}

#[generate_trait]
impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn read_counter(self: @Store, id: felt252) -> Counter {
        self.world.read_model(id)
    }

    #[inline]
    fn write_counter(ref self: Store, counter: @Counter) {
        self.world.write_model(counter)
    }
}
