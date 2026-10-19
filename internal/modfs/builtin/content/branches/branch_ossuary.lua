-- BRANCH_OSSUARY has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_OSSUARY",
    numeric_id = 29,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 6,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_OSSUARY",
    exit_feature = "DNGN_EXIT_OSSUARY",
    escape_feature = "NUM_FEATURES",
    short_name = "Ossuary",
    long_name = "an ossuary",
    abbreviation = "Ossuary",
    entry_message = "You enter an ossuary!",
    floor_color = "WHITE",
    rock_color = "YELLOW",
    travel_shortcut = "4",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
