-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 279
-- Enum line: 51

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_BAILEY",
    numeric_id = 30,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 11,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_BAILEY",
    exit_feature = "DNGN_EXIT_BAILEY",
    escape_feature = "NUM_FEATURES",
    short_name = "Bailey",
    long_name = "a bailey",
    abbreviation = "Bailey",
    entry_message = "You enter a bailey!",
    floor_color = "WHITE",
    rock_color = "LIGHTRED",
    travel_shortcut = "5",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
