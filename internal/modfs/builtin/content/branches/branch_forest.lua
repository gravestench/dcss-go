-- branch forest (BRANCH_FOREST) has 5 levels and connects from BRANCH_VAULTS.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_FOREST",
    numeric_id = 21,
    parent_id = "BRANCH_VAULTS",
    min_depth = 2,
    max_depth = 3,
    depth = 5,
    absolute_depth = 19,
    flags = {
        "spotty",
    },
    entry_feature = "DNGN_ENTER_FOREST",
    exit_feature = "DNGN_EXIT_FOREST",
    escape_feature = "NUM_FEATURES",
    short_name = "Forest",
    long_name = "the Enchanted Forest",
    abbreviation = "Forest",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "F",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
