-- BRANCH_SEWER has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SEWER",
    numeric_id = 28,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 4,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_SEWER",
    exit_feature = "DNGN_EXIT_SEWER",
    escape_feature = "NUM_FEATURES",
    short_name = "Sewer",
    long_name = "a sewer",
    abbreviation = "Sewer",
    entry_message = "You enter a sewer!",
    floor_color = "LIGHTGREY",
    rock_color = "BLUE",
    travel_shortcut = "3",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
