#[starknet::component]
pub mod BombGameComponent {
    // Dojo imports
    use dojo::world::WorldStorage;
    use dojo::world::{IWorldDispatcherTrait};

    // Internal imports
    use crate::models::pit::{Pit, PitTrait};
    use crate::models::player::{Player, PlayerTrait};
    use crate::models::square::{Square, SquareTrait, SquareAssert};
    use crate::models::round_result::{RoundResult, RoundResultTrait};
    use crate::models::pit_order::{PitQueue, PitOrderTrait};
    use crate::store::{Store, StoreTrait};
    use crate::constants::NUM_SQUARES;

    // Starknet imports
    use starknet::{get_caller_address, ContractAddress};

    // Errors
    pub mod errors {
        pub const PIT_NOT_ACTIVE: felt252 = 'Pit: not active';
        pub const INVALID_SQUARE: felt252 = 'Game: invalid square';
        pub const SAME_SQUARE: felt252 = 'Game: already in square';
        pub const BOMB_EXPLODED: felt252 = 'Game: bomb has exploded';
    }

    // Storage
    #[storage]
    pub struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PitCreated: PitCreated,
        PlayerJoined: PlayerJoined,
        PlayerMoved: PlayerMoved,
        RoundCompleted: RoundCompleted,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PitCreated {
        pit_id: u32,
        creator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PlayerJoined {
        pit_id: u32,
        player: ContractAddress,
        square_id: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PlayerMoved {
        pit_id: u32,
        player: ContractAddress,
        from_square: u8,
        to_square: u8,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RoundCompleted {
        pit_id: u32,
        round: u32,
        losing_square: u8,
        round_reward: u128,
    }

    #[generate_trait]
    pub impl InternalImpl<T, +HasComponent<T>> of InternalTrait<T> {
        fn create_pit(ref self: ComponentState<T>, world: WorldStorage) {
            let mut store: Store = StoreTrait::new(world);
            let pit_id: u32 = world.dispatcher.uuid().into();
            let caller = get_caller_address();

            // Create pit
            let mut pit = PitTrait::new(pit_id);
            store.set_pit(pit);

            // Create squares
            for square_id in 0..NUM_SQUARES {
                let mut square = SquareTrait::new(pit_id, square_id);
                store.set_square(square);
            };

            // Initialize pit order
            let pit_order = PitOrderTrait::new(pit_id);
            store.set_pit_order(pit_order);

            self.emit(PitCreated { pit_id, creator: caller });
        }

        fn join_game(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();
            
            // use only the first pit_id = 0
            let mut pit = store.get_pit(pit_id);
            assert(pit.is_active, errors::PIT_NOT_ACTIVE);

            // Get and update pit order to determine starting square
            let mut pit_order = store.get_pit_order(pit_id);
            let starting_square = pit_order.get_and_increment_next_square();
            store.set_pit_order(pit_order);

            // Create new player in assigned square
            let mut player = PlayerTrait::new(pit_id, caller);
            player.square_id = starting_square;

            // Update assigned square balance
            let mut square = store.get_square(pit_id, starting_square);
            square.assert_valid_square_id();
            square.add_balance(player.balance);

            store.set_player(player);
            store.set_square(square);

            self.emit(PlayerJoined { pit_id, player: caller, square_id: starting_square });
        }

        fn move_to_square(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32, square_id: u8) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();

            let mut player = store.get_player(pit_id, caller);
            assert(player.square_id != square_id, errors::SAME_SQUARE);

            let mut square = store.get_square(pit_id, square_id);
            square.assert_valid_square_id();

            // Remove balance from old square
            let mut old_square = store.get_square(pit_id, player.square_id);
            old_square.remove_balance(player.balance);
            store.set_square(old_square);

            // Add balance to new square
            square.add_balance(player.balance);
            store.set_square(square);

            // Update player's square
            player.square_id = square_id;
            store.set_player(player);

            // Emit event
            self.emit(PlayerMoved { pit_id, player: caller, from_square: player.square_id, to_square: square_id });
        }

        fn progress_round(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32) {
            let mut store: Store = StoreTrait::new(world);
            let mut pit = store.get_pit(pit_id);
            assert(pit.is_active, errors::PIT_NOT_ACTIVE);

            if pit.bomb_counter > 0 {
                pit.decrement_bomb_counter();
                store.set_pit(pit);
            } else {
                // Start new round and update pit
                pit.start_new_round();
                store.set_pit(pit);
            }
        }
    }
}