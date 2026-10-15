-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 255
-- Enum line: 48

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_TROVE",
    numeric_id = 27,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 18,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_TROVE",
    exit_feature = "DNGN_EXIT_TROVE",
    escape_feature = "NUM_FEATURES",
    short_name = "Trove",
    long_name = "a treasure trove",
    abbreviation = "Trove",
    entry_message = "You enter a treasure trove!",
    floor_color = "DARKGREY",
    rock_color = "BLUE",
    travel_shortcut = "2",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
