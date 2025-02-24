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
    use crate::models::pit_queue::{PitQueue, PitQueueTrait};
    use crate::store::{Store, StoreTrait};
    use crate::models::token::{Token, TokenTrait};
    use crate::constants::{NUM_SQUARES, MINIMUM_ENTRY_BALANCE};
    use crate::helpers::get_escrow_and_modulo;

    // Starknet imports
    use starknet::{get_caller_address, ContractAddress};

    // Errors
    pub mod errors {
        pub const PIT_NOT_ACTIVE: felt252 = 'Pit: not active';
        pub const INVALID_SQUARE: felt252 = 'Game: invalid square';
        pub const SAME_SQUARE: felt252 = 'Game: already in square';
        pub const BOMB_EXPLODED: felt252 = 'Game: bomb has exploded';
        pub const PLAYER_ALREADY_IN_PIT: felt252 = 'Game: player already in pit';
        pub const INSUFFICIENT_BALANCE: felt252 = 'Game: insufficient balance';
        pub const PLAYER_HAS_NO_TOKENS: felt252 = 'Game: player has no tokens';
        pub const DOES_NOT_MEET_MINIMUM_ENTRY_BALANCE: felt252 = 'Game: not minimum entry balance';
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
        MockTokensClaimed: MockTokensClaimed,
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
        wager: u128,
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

    #[derive(Drop, starknet::Event)]
    pub struct MockTokensClaimed {
        player: ContractAddress,
        amount: u128,
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

            // Initialize pit queue
            let pit_queue = PitQueueTrait::new(pit_id);
            store.set_pit_queue(pit_queue);

            self.emit(PitCreated { pit_id, creator: caller });
        }

        fn claim_mock_tokens(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();

            // Claim tokens if not claimed
            let mut token = store.get_token(caller);
            token.claim_tokens();
            store.set_token(token);

            // Emit event
            self.emit(MockTokensClaimed { player: caller, amount: token.balance });
        }

        fn join_game(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32, wager: u128) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();

            // Get all models
            let mut player_pit = store.get_player(pit_id, caller);
            let mut player_tokens = store.get_token(caller);
            let mut pit = store.get_pit(pit_id);
            let mut pit_queue = store.get_pit_queue(pit_id);
            let starting_square = pit_queue.get_and_increment_next_square();
            let mut square = store.get_square(pit_id, starting_square);

            // Assertions
            assert(player_pit.balance == 0, errors::PLAYER_ALREADY_IN_PIT);
            assert(player_tokens.balance >= wager, errors::INSUFFICIENT_BALANCE);
            assert(wager >= MINIMUM_ENTRY_BALANCE, errors::DOES_NOT_MEET_MINIMUM_ENTRY_BALANCE);
            assert(pit.is_active, errors::PIT_NOT_ACTIVE);
            square.assert_valid_square_id();

            // Calculate escrow and modulo
            let (escrow, modulo) = get_escrow_and_modulo(wager);
            let playable_balance = wager - escrow;

            // update balances
            player_tokens.balance -= wager;
            player_pit.balance += playable_balance;
            player_pit.escrow += escrow;
            pit.modulo_pool += modulo;

            square.add_balance(playable_balance);
            square.add_escrow(escrow);

            player_pit.square_id = starting_square;

            // Set all modified models
            store.set_player(player_pit);
            store.set_token(player_tokens);
            store.set_pit(pit);
            store.set_pit_queue(pit_queue);
            store.set_square(square);

            // Emit event
            self.emit(PlayerJoined { pit_id, player: caller, square_id: starting_square, wager });
        }

        fn move_to_square(
            ref self: ComponentState<T>, world: WorldStorage, pit_id: u32, square_id: u8,
        ) {
            let mut store: Store = StoreTrait::new(world);
            let caller = get_caller_address();

            // Get all models
            let mut player_in_pit = store.get_player(pit_id, caller);
            let mut pit = store.get_pit(pit_id);
            let mut old_square = store.get_square(pit_id, player_in_pit.square_id);
            let mut new_square = store.get_square(pit_id, square_id);
            let mut token = store.get_token(caller);

            // Assertions
            new_square.assert_valid_square_id();
            assert(player_in_pit.square_id != square_id, errors::SAME_SQUARE);
            assert(pit.is_active, errors::PIT_NOT_ACTIVE);

            // Modify values
            old_square.remove_balance(player_in_pit.balance);
            old_square.remove_escrow(player_in_pit.escrow);
            new_square.add_balance(player_in_pit.balance);
            new_square.add_escrow(player_in_pit.escrow);

            player_in_pit.square_id = square_id;
            token.increment_moves();

            // Set all modified models
            store.set_square(old_square);
            store.set_square(new_square);
            store.set_player(player_in_pit);
            store.set_token(token);

            // Emit event
            self
                .emit(
                    PlayerMoved {
                        pit_id,
                        player: caller,
                        from_square: player_in_pit.square_id,
                        to_square: square_id,
                    },
                );
        }

        // fn move_to_square(
        //     ref self: ComponentState<T>, world: WorldStorage, pit_id: u32, square_id: u8,
        // ) {
        //     let mut store: Store = StoreTrait::new(world);
        //     let caller = get_caller_address();

        //     // Get all models
        //     let mut player = store.get_player(pit_id, caller);
        //     let mut square = store.get_square(pit_id, square_id);
        //     let mut old_square = store.get_square(pit_id, player.square_id);
        //     let mut token = store.get_token(caller);

        //     // Assertions
        //     square.assert_valid_square_id();
        //     assert(player.square_id != square_id, errors::SAME_SQUARE);

        //     // Update models
        //     old_square.remove_balance(player.balance + player.locked_balance);
        //     square.add_balance(player.balance);
        //     player.square_id = square_id;
        //     token.increment_moves();

        //     // Set all modified models
        //     store.set_square(old_square);
        //     store.set_square(square);
        //     store.set_player(player);
        //     store.set_token(token);

        //     // Emit event
        //     self
        //         .emit(
        //             PlayerMoved {
        //                 pit_id, player: caller, from_square: player.square_id, to_square:
        //                 square_id,
        //             },
        //         );
        // }

        fn progress_round(ref self: ComponentState<T>, world: WorldStorage, pit_id: u32) {
            let mut store: Store = StoreTrait::new(world);

            // Get all models
            let mut pit = store.get_pit(pit_id);

            // Assertions
            assert(pit.is_active, errors::PIT_NOT_ACTIVE);

            // Update models
            if pit.bomb_counter > 0 {
                pit.decrement_bomb_counter();
            } else {
                pit.start_new_round();
            }

            // Set all modified models
            store.set_pit(pit);
        }
    }
}
