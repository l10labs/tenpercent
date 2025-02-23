#[starknet::component]
pub mod BombGameComponent {
    // Dojo imports
    use dojo::world::WorldStorage;
    use dojo::world::{IWorldDispatcherTrait};

    // Internal imports
    use crate::models::pit::{Pit, PitTrait};
    use crate::models::player::{Player, PlayerTrait};
    use crate::models::square::{Square, SquareTrait};
    use crate::models::round_result::{RoundResult, RoundResultTrait};
    use crate::store::{Store, StoreTrait};

    // Starknet imports
    use starknet::{get_caller_address, ContractAddress};

    // Constants
    const INITIAL_BALANCE: u128 = 10;
    const INITIAL_BOMB_COUNTER: u32 = 5;
    const PENALTY_PERCENTAGE: u128 = 10; // 10%
    const NUM_SQUARES: u8 = 4;

    // Errors
    pub mod errors {
        pub const GAME_NOT_ACTIVE: felt252 = 'Game: not active';
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
        GameCreated: GameCreated,
        PlayerJoined: PlayerJoined,
        PlayerMoved: PlayerMoved,
        RoundCompleted: RoundCompleted,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GameCreated {
        pit_id: u32,
        creator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PlayerJoined {
        pit_id: u32,
        player: ContractAddress,
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
        penalty_amount: u128,
    }

    #[generate_trait]
    pub impl InternalImpl<TState, +HasComponent<TState>> of InternalTrait<TState> {
        fn create_game(ref self: ComponentState<TState>, world: WorldStorage) {
            let mut store: Store = StoreTrait::new(world);
            let pit_id: u32 = world.dispatcher.uuid().into();
            let caller = get_caller_address();

            // Create pit
            let mut pit = PitTrait::new(pit_id);

            // Create initial player in square 0
            let player = PlayerTrait::new(pit_id, caller); 

            // Initialize first square with player
            let square = SquareTrait::new(pit_id, 0);

            store.set_pit(pit);
            store.set_player(player);
            store.set_square(square);

            self.emit(GameCreated { pit_id, creator: caller });
        }

        fn join_game(ref self: ComponentState<TState>, world: WorldStorage, pit_id: u32) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();
            
            let mut pit = store.get_pit(pit_id);
            assert(pit.is_active, errors::GAME_NOT_ACTIVE);

            // Create new player in square 0
            let player = PlayerTrait::new(pit_id, caller);

            // Update square 0 balance
            let mut square = store.get_square(pit_id, 0);
            square.add_balance(INITIAL_BALANCE);

            store.set_player(player);
            store.set_square(square);

            self.emit(PlayerJoined { pit_id, player: caller });
        }

        // ... existing code ...
        // Additional functions would include:
        // - move_to_square
        // - check_bomb_result
        // - distribute_penalties
        // These would follow similar patterns to the JavaScript implementation
        // but adapted for Cairo's constraints and Dojo's model system
    }
}