#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Counter {
    #[key]
    pub id: felt252,
    pub count: u64,
}
