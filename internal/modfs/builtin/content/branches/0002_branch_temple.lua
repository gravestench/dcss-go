-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 26
-- Enum line: 8

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_TEMPLE",
    numeric_id = 1,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 4,
    max_depth = 7,
    depth = 1,
    absolute_depth = 5,
    flags = {
        "no_items",
    },
    entry_feature = "DNGN_ENTER_TEMPLE",
    exit_feature = "DNGN_EXIT_TEMPLE",
    escape_feature = "NUM_FEATURES",
    short_name = "Temple",
    long_name = "the Ecumenical Temple",
    abbreviation = "Temple",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "T",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
