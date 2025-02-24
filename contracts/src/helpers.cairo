use crate::constants::PENALTY_PERCENTAGE;

pub fn get_escrow_and_modulo(balance: u128) -> (u128, u128) {
    let escrow = (balance * PENALTY_PERCENTAGE) / 100;
    let modulo = (balance * PENALTY_PERCENTAGE) % 100;
    (escrow, modulo)
}
