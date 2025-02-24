use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Pit {
    #[key]
    pub pit_id: u32,
    pub bomb_counter: u32,
    pub round_number: u32,
    pub is_active: bool,
    pub status: PitStatus,
    pub modulo_pool: u128,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum PitStatus {
    Active,
    Completed,
    Abandoned,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub pit_id: u32,
    #[key]
    pub player_id: ContractAddress,
    pub square_id: u8,
    pub balance: u128,
    pub locked_balance: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Square {
    #[key]
    pub pit_id: u32,
    #[key]
    pub square_id: u8,
    pub total_balance: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct RoundResult {
    #[key]
    pub pit_id: u32,
    #[key]
    pub round: u32,
    pub losing_square: u8,
    pub round_reward: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PitQueue {
    #[key]
    pub pit_id: u32,
    pub next_square: u8,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Token {
    #[key]
    pub player: ContractAddress,
    pub balance: u128,
    pub moves_since_last_claim: u32,
    pub has_claimed: bool,
} 