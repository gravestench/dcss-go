-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 84
-- Enum line: 18

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SNAKE",
    numeric_id = 8,
    parent_id = "BRANCH_LAIR",
    min_depth = 2,
    max_depth = 3,
    depth = 4,
    absolute_depth = 15,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_SNAKE",
    exit_feature = "DNGN_EXIT_SNAKE",
    escape_feature = "NUM_FEATURES",
    short_name = "Snake Pit",
    long_name = "the Snake Pit",
    abbreviation = "Snake",
    floor_color = "LIGHTGREEN",
    rock_color = "YELLOW",
    travel_shortcut = "P",
    runes = {
        "RUNE_SNAKE",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
