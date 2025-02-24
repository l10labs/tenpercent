use grid_guru::elements::trophies::interface::{TrophyTrait, BushidoTask, Task, TaskTrait};

pub impl Navigator of TrophyTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        match level {
            0 => 'NAVIGATOR_I',
            1 => 'NAVIGATOR_II',
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
        'Navigator'
    }

    #[inline]
    fn icon(level: u8) -> felt252 {
        match level {
            0 => 'fa-compass',
            1 => 'fa-location-dot',
            _ => '',
        }
    }

    #[inline]
    fn title(level: u8) -> felt252 {
        match level {
            0 => 'Navigator I',
            1 => 'Navigator II',
            _ => '',
        }
    }

    #[inline]
    fn description(level: u8) -> ByteArray {
        match level {
            0 => "Every step forward is a new path charted, every move a destination mapped",
            1 => "The edge is not a boundary, but a gateway to unexplored territories",
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
        Task::Moving.tasks(level, total, total)
    }
}
