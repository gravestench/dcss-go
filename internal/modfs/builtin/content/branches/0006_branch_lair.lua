-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 60
-- Enum line: 15

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_LAIR",
    numeric_id = 5,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 8,
    max_depth = 11,
    depth = 5,
    absolute_depth = 10,
    flags = {
        "none",
    },
    entry_feature = "DNGN_ENTER_LAIR",
    exit_feature = "DNGN_EXIT_LAIR",
    escape_feature = "NUM_FEATURES",
    short_name = "Lair",
    long_name = "the Lair of Beasts",
    abbreviation = "Lair",
    floor_color = "GREEN",
    rock_color = "BROWN",
    travel_shortcut = "L",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
