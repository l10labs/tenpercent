use achievement::types::task::{Task as ArcadeTask};
use grid_guru::elements::trophies;

pub const TROPHY_COUNT: u8 = 4;

#[derive(Copy, Drop)]
pub enum Trophy {
    None,
    NAVIGATORI,
    NAVIGATORII,
    TACTICIANI,
    TACTICIANII,
}

#[generate_trait]
pub impl TrophyImpl of TrophyTrait {
    #[inline]
    fn level(self: Trophy) -> u8 {
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => 0,
            Trophy::NAVIGATORII => 1,
            Trophy::TACTICIANI => 0,
            Trophy::TACTICIANII => 1,
        }
    }

    #[inline]
    fn identifier(self: Trophy) -> felt252 {
        let level = self.level();
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::identifier(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::identifier(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::identifier(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::identifier(level),
        }
    }

    #[inline]
    fn hidden(self: Trophy) -> bool {
        let level = self.level();
        match self {
            Trophy::None => true,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::hidden(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::hidden(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::hidden(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::hidden(level),
        }
    }

    #[inline]
    fn index(self: Trophy) -> u8 {
        let level = self.level();
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::index(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::index(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::index(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::index(level),
        }
    }

    #[inline]
    fn points(self: Trophy) -> u16 {
        let level = self.level();
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::points(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::points(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::points(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::points(level),
        }
    }

    #[inline]
    fn start(self: Trophy) -> u64 {
        // TODO: Update start time if you want to create ephemeral trophies
        0
    }

    #[inline]
    fn end(self: Trophy) -> u64 {
        // TODO: Update end time if you want to create ephemeral trophies
        // Note: End time must be greater than start time
        0
    }

    #[inline]
    fn group(self: Trophy) -> felt252 {
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::group(),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::group(),
            Trophy::TACTICIANI => trophies::tactician::Tactician::group(),
            Trophy::TACTICIANII => trophies::tactician::Tactician::group(),
        }
    }

    #[inline]
    fn icon(self: Trophy) -> felt252 {
        let level = self.level();
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::icon(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::icon(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::icon(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::icon(level),
        }
    }

    #[inline]
    fn title(self: Trophy) -> felt252 {
        let level = self.level();
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::title(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::title(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::title(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::title(level),
        }
    }

    #[inline]
    fn description(self: Trophy) -> ByteArray {
        let level = self.level();
        match self {
            Trophy::None => "",
            Trophy::NAVIGATORI => trophies::navigator::Navigator::description(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::description(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::description(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::description(level),
        }
    }

    #[inline]
    fn count(self: Trophy, level: u8) -> u32 {
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => trophies::navigator::Navigator::count(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::count(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::count(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::count(level),
        }
    }

    #[inline]
    fn tasks(self: Trophy) -> Span<ArcadeTask> {
        let level = self.level();
        match self {
            Trophy::None => [].span(),
            Trophy::NAVIGATORI => trophies::navigator::Navigator::tasks(level),
            Trophy::NAVIGATORII => trophies::navigator::Navigator::tasks(level),
            Trophy::TACTICIANI => trophies::tactician::Tactician::tasks(level),
            Trophy::TACTICIANII => trophies::tactician::Tactician::tasks(level),
        }
    }

    #[inline]
    fn data(self: Trophy) -> ByteArray {
        ""
    }
}

impl IntoTrophyU8 of core::traits::Into<Trophy, u8> {
    #[inline]
    fn into(self: Trophy) -> u8 {
        match self {
            Trophy::None => 0,
            Trophy::NAVIGATORI => 1,
            Trophy::NAVIGATORII => 2,
            Trophy::TACTICIANI => 3,
            Trophy::TACTICIANII => 4,
        }
    }
}

impl IntoU8Trophy of core::traits::Into<u8, Trophy> {
    #[inline]
    fn into(self: u8) -> Trophy {
        let card: felt252 = self.into();
        match card {
            0 => Trophy::None,
            1 => Trophy::NAVIGATORI,
            2 => Trophy::NAVIGATORII,
            3 => Trophy::TACTICIANI,
            4 => Trophy::TACTICIANII,
            _ => Trophy::None,
        }
    }
}
