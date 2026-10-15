-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 369
-- Enum line: 65

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ARENA",
    numeric_id = 37,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 0,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_ARENA",
    exit_feature = "DNGN_EXIT_ARENA",
    escape_feature = "NUM_FEATURES",
    short_name = "Arena",
    long_name = "the Arena",
    abbreviation = "Arena",
    entry_message = "You enter Okawaru's Arena!",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "\"",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
