-- BRANCH_WIZLAB has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_WIZLAB",
    numeric_id = 33,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 24,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_WIZLAB",
    exit_feature = "DNGN_EXIT_WIZLAB",
    escape_feature = "NUM_FEATURES",
    short_name = "Wizlab",
    long_name = "a wizard's laboratory",
    abbreviation = "WizLab",
    entry_message = "You enter a wizard's laboratory!",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "8",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
