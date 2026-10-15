-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 92
-- Enum line: 19

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SPIDER",
    numeric_id = 9,
    parent_id = "BRANCH_LAIR",
    min_depth = 2,
    max_depth = 3,
    depth = 4,
    absolute_depth = 15,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_SPIDER",
    exit_feature = "DNGN_EXIT_SPIDER",
    escape_feature = "NUM_FEATURES",
    short_name = "Spider Nest",
    long_name = "the Spider Nest",
    abbreviation = "Spider",
    floor_color = "BROWN",
    rock_color = "YELLOW",
    travel_shortcut = "N",
    runes = {
        "RUNE_SPIDER",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
