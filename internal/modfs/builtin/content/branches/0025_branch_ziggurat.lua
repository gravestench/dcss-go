-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 229
-- Enum line: 43

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ZIGGURAT",
    numeric_id = 24,
    parent_id = "BRANCH_DEPTHS",
    min_depth = 1,
    max_depth = 4,
    depth = 27,
    absolute_depth = 27,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_ZIGGURAT",
    exit_feature = "DNGN_EXIT_ZIGGURAT",
    escape_feature = "DNGN_FLOOR",
    short_name = "Ziggurat",
    long_name = "a ziggurat",
    abbreviation = "Zig",
    entry_message = "You land on top of a ziggurat so tall you cannot make out the ground.",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "Q",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
