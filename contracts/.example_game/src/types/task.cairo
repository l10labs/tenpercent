use achievement::types::task::{Task as ArcadeTask, TaskTrait as ArcadeTaskTrait};
use grid_guru::elements::tasks;

#[derive(Copy, Drop)]
pub enum Task {
    None,
    Moving,
    Territory,
}

#[generate_trait]
pub impl TaskImpl of TaskTrait {
    #[inline]
    fn identifier(self: Task, level: u8) -> felt252 {
        match self {
            Task::None => 0,
            Task::Moving => tasks::movement::Moving::identifier(level),
            Task::Territory => tasks::territory::Territory::identifier(level),
        }
    }

    #[inline]
    fn description(self: Task, count: u32) -> ByteArray {
        match self {
            Task::None => "",
            Task::Moving => tasks::movement::Moving::description(count),
            Task::Territory => tasks::territory::Territory::description(count),
        }
    }

    #[inline]
    fn tasks(self: Task, level: u8, count: u32, total: u32) -> Span<ArcadeTask> {
        let task_id: felt252 = self.identifier(level);
        let description: ByteArray = self.description(count);
        array![ArcadeTaskTrait::new(task_id, total, description)].span()
    }
}

impl IntoTaskU8 of core::traits::Into<Task, u8> {
    #[inline]
    fn into(self: Task) -> u8 {
        match self {
            Task::None => 0,
            Task::Moving => 1,
            Task::Territory => 2,
        }
    }
}

impl IntoU8Task of core::traits::Into<u8, Task> {
    #[inline]
    fn into(self: u8) -> Task {
        let card: felt252 = self.into();
        match card {
            0 => Task::None,
            1 => Task::Moving,
            2 => Task::Territory,
            _ => Task::None,
        }
    }
}
