-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 68
-- Enum line: 16

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SWAMP",
    numeric_id = 6,
    parent_id = "BRANCH_LAIR",
    min_depth = 2,
    max_depth = 3,
    depth = 4,
    absolute_depth = 15,
    flags = {
        "dangerous_end",
        "spotty",
    },
    entry_feature = "DNGN_ENTER_SWAMP",
    exit_feature = "DNGN_EXIT_SWAMP",
    escape_feature = "NUM_FEATURES",
    short_name = "Swamp",
    long_name = "the Swamp",
    abbreviation = "Swamp",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "S",
    runes = {
        "RUNE_SWAMP",
    },
    ambient_noise = "loud",
    mon_die_size_expr = "8",
}

register.definition(categories.BRANCHES, definition)

return definition
