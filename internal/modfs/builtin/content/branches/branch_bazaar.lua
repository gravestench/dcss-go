-- BRANCH_BAZAAR has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_BAZAAR",
    numeric_id = 26,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 18,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_BAZAAR",
    exit_feature = "DNGN_EXIT_BAZAAR",
    escape_feature = "NUM_FEATURES",
    short_name = "Bazaar",
    long_name = "a bazaar",
    abbreviation = "Bazaar",
    entry_message = "You enter an inter-dimensional bazaar!",
    floor_color = "BLUE",
    rock_color = "YELLOW",
    travel_shortcut = "1",
    runes = mod.null,
    ambient_noise = "normal",
}

register.definition(categories.BRANCHES, definition)

return definition
