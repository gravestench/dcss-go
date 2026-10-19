-- branch depths (BRANCH_DEPTHS) has 4 levels and connects from
-- BRANCH_DUNGEON.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DEPTHS",
    numeric_id = 34,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 15,
    max_depth = 15,
    depth = 4,
    absolute_depth = 22,
    flags = {
        "none",
    },
    entry_feature = "DNGN_ENTER_DEPTHS",
    exit_feature = "DNGN_EXIT_DEPTHS",
    escape_feature = "NUM_FEATURES",
    short_name = "Depths",
    long_name = "the Depths",
    abbreviation = "Depths",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "U",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "10",
}

register.definition(categories.BRANCHES, definition)

return definition
