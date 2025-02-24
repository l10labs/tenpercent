use grid_guru::elements::tasks::interface::TaskTrait;

pub impl Moving of TaskTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        'MOVING'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        format!("Move player {} position from edge", count)
    }
}
