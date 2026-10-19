-- BRANCH_VOLCANO has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_VOLCANO",
    numeric_id = 32,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 14,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_VOLCANO",
    exit_feature = "DNGN_EXIT_VOLCANO",
    escape_feature = "NUM_FEATURES",
    short_name = "Volcano",
    long_name = "a volcano",
    abbreviation = "Volcano",
    entry_message = "You enter a volcano!",
    floor_color = "RED",
    rock_color = "RED",
    travel_shortcut = "7",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
