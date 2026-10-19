-- BRANCH_GAUNTLET has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_GAUNTLET",
    numeric_id = 36,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 15,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_GAUNTLET",
    exit_feature = "DNGN_EXIT_GAUNTLET",
    escape_feature = "DNGN_EXIT_THROUGH_ABYSS",
    short_name = "Gauntlet",
    long_name = "a Gauntlet",
    abbreviation = "Gauntlet",
    entry_message = "You enter a gauntlet!",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "!",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
