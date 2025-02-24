pub mod constants;
pub mod store;

pub mod models {
    pub mod game;
    pub mod index;
    pub mod player;
    pub mod tile;
}

pub mod components {
    pub mod playable;
}

pub mod elements {
    pub mod tasks {
        pub mod movement;
        pub mod territory;
        pub mod interface;
    }
    pub mod trophies {
        pub mod navigator;
        pub mod tactician;
        pub mod interface;
    }
}

pub mod systems {
    pub mod actions;
}

pub mod types {
    pub mod task;
    pub mod trophy;
}

pub mod helpers {}

#[cfg(test)]
pub mod tests {
    pub mod setup;
    pub mod test_actions;
}
