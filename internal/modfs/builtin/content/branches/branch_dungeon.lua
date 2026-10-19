-- Dungeon is the root branch; NUM_BRANCHES is a source sentinel, not an entrance.
-- NUM_FEATURES means the root has no inbound staircase feature.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DUNGEON",
    numeric_id = 0,
    parent_id = "NUM_BRANCHES",
    min_depth = 0,
    max_depth = 0,
    depth = 15,
    absolute_depth = 0,
    flags = {
        "none",
    },
    entry_feature = "NUM_FEATURES",
    exit_feature = "DNGN_EXIT_DUNGEON",
    escape_feature = "NUM_FEATURES",
    short_name = "Dungeon",
    long_name = "the Dungeon",
    abbreviation = "D",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "D",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
