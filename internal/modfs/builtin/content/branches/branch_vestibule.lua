-- BRANCH_VESTIBULE has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_VESTIBULE",
    numeric_id = 15,
    parent_id = "NUM_BRANCHES",
    min_depth = 27,
    max_depth = 27,
    depth = 1,
    absolute_depth = 27,
    flags = {
        "no_items",
    },
    entry_feature = "DNGN_ENTER_HELL",
    exit_feature = "DNGN_EXIT_HELL",
    escape_feature = "NUM_FEATURES",
    short_name = "Hell",
    long_name = "the Vestibule of Hell",
    abbreviation = "Hell",
    entry_message = "Welcome to Hell!\nPlease enjoy your stay.",
    floor_color = "LIGHTGREY",
    rock_color = "LIGHTRED",
    travel_shortcut = "H",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
