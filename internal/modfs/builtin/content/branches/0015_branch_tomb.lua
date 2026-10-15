-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 134
-- Enum line: 26

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_TOMB",
    numeric_id = 14,
    parent_id = "BRANCH_CRYPT",
    min_depth = 3,
    max_depth = 3,
    depth = 3,
    absolute_depth = 21,
    flags = {
        "islanded",
        "dangerous_end",
        "no_shafts",
    },
    entry_feature = "DNGN_ENTER_TOMB",
    exit_feature = "DNGN_EXIT_TOMB",
    escape_feature = "NUM_FEATURES",
    short_name = "Tomb",
    long_name = "the Tomb of the Ancients",
    abbreviation = "Tomb",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "W",
    runes = {
        "RUNE_TOMB",
    },
    ambient_noise = "quiet",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
