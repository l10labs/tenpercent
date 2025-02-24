use starknet::ContractAddress;

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameStatus {
    Pending,
    InProgress,
    Completed,
    Draw,
    Abandoned,
    TimedOut,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u128,
    pub player_one: ContractAddress,
    pub player_two: ContractAddress,
    pub current_player: ContractAddress,
    pub winner: ContractAddress,
    pub move_count: u8,
    pub status: GameStatus,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub game_id: u128,
    #[key]
    pub address: ContractAddress,
    pub score: u8,
    pub x: u8,
    pub y: u8,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Tile {
    #[key]
    pub game_id: u128,
    #[key]
    pub x: u8,
    #[key]
    pub y: u8,
    pub owner: ContractAddress,
}
