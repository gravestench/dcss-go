-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 337
-- Enum line: 59

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DEPTHS",
    numeric_id = 34,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 15,
    max_depth = 15,
    depth = 4,
    absolute_depth = 22,
    flags = {
        "none",
    },
    entry_feature = "DNGN_ENTER_DEPTHS",
    exit_feature = "DNGN_EXIT_DEPTHS",
    escape_feature = "NUM_FEATURES",
    short_name = "Depths",
    long_name = "the Depths",
    abbreviation = "Depths",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "U",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "10",
}

register.definition(categories.BRANCHES, definition)

return definition
