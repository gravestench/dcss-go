-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 297
-- Enum line: 55

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ICE_CAVE",
    numeric_id = 31,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 15,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_ICE_CAVE",
    exit_feature = "DNGN_EXIT_ICE_CAVE",
    escape_feature = "NUM_FEATURES",
    short_name = "Ice Cave",
    long_name = "an ice cave",
    abbreviation = "IceCv",
    entry_message = "You enter an ice cave!",
    floor_color = "BLUE",
    rock_color = "WHITE",
    travel_shortcut = "6",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
