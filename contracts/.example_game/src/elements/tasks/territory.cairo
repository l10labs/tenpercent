use grid_guru::elements::tasks::interface::TaskTrait;

pub impl Territory of TaskTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        'TERRITORY'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        format!("Reach the board center first in {} games.", count)
    }
}
