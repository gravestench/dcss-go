-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 211
-- Enum line: 41

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ABYSS",
    numeric_id = 22,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 7,
    absolute_depth = 24,
    flags = {
        "no_x_level_travel",
        "no_map",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_ABYSS",
    exit_feature = "DNGN_EXIT_ABYSS",
    escape_feature = "DNGN_FLOOR",
    short_name = "Abyss",
    long_name = "the Abyss",
    abbreviation = "Abyss",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "J",
    runes = {
        "RUNE_ABYSSAL",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
