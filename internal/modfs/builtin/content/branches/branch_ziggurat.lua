-- branch ziggurat (BRANCH_ZIGGURAT) has 27 levels and connects from
-- BRANCH_DEPTHS.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

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
