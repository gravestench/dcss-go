-- BRANCH_DESOLATION has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DESOLATION",
    numeric_id = 35,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 20,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_DESOLATION",
    exit_feature = "DNGN_EXIT_DESOLATION",
    escape_feature = "NUM_FEATURES",
    short_name = "Desolation",
    long_name = "the Desolation of Salt",
    abbreviation = "Desolation",
    entry_message = "You enter a great desolation of salt!",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "9",
    runes = mod.null,
    ambient_noise = "loud",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
