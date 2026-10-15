-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 100
-- Enum line: 20

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SLIME",
    numeric_id = 10,
    parent_id = "BRANCH_LAIR",
    min_depth = 4,
    max_depth = 5,
    depth = 5,
    absolute_depth = 17,
    flags = {
        "no_items",
        "dangerous_end",
        "spotty",
    },
    entry_feature = "DNGN_ENTER_SLIME",
    exit_feature = "DNGN_EXIT_SLIME",
    escape_feature = "NUM_FEATURES",
    short_name = "Slime Pits",
    long_name = "the Pits of Slime",
    abbreviation = "Slime",
    floor_color = "GREEN",
    rock_color = "BROWN",
    travel_shortcut = "M",
    runes = {
        "RUNE_SLIME",
    },
    ambient_noise = "quiet",
    mon_die_size_expr = "7",
}

register.definition(categories.BRANCHES, definition)

return definition
