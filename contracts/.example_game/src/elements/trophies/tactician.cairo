use grid_guru::elements::trophies::interface::{TrophyTrait, BushidoTask, Task, TaskTrait};

pub impl Tactician of TrophyTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        match level {
            0 => 'TACTICIAN_I',
            1 => 'TACTICIAN_II',
            _ => '',
        }
    }

    #[inline]
    fn hidden(level: u8) -> bool {
        false
    }

    #[inline]
    fn index(level: u8) -> u8 {
        level
    }

    #[inline]
    fn points(level: u8) -> u16 {
        match level {
            0 => 10,
            1 => 50,
            _ => 0,
        }
    }

    #[inline]
    fn group() -> felt252 {
        'Tactician'
    }

    #[inline]
    fn icon(level: u8) -> felt252 {
        match level {
            0 => 'fa-brain',
            1 => 'fa-chess',
            _ => '',
        }
    }

    #[inline]
    fn title(level: u8) -> felt252 {
        match level {
            0 => 'Tactician I',
            1 => 'Tactician II',
            _ => '',
        }
    }

    #[inline]
    fn description(level: u8) -> ByteArray {
        match level {
            0 => "The center holds power, but wisdom lies in knowing when to claim it",
            1 => "Victory belongs not to the swiftest, but to those who see the board as their realm",
            _ => "",
        }
    }

    #[inline]
    fn count(level: u8) -> u32 {
        match level {
            0 => 20,
            1 => 200,
            _ => 0,
        }
    }

    #[inline]
    fn tasks(level: u8) -> Span<BushidoTask> {
        let total: u32 = Self::count(level);
        Task::Territory.tasks(level, total, total)
    }
}
