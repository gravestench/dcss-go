-- branch blade (BRANCH_BLADE) has 1 levels and connects from BRANCH_VAULTS.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_BLADE",
    numeric_id = 12,
    parent_id = "BRANCH_VAULTS",
    min_depth = 3,
    max_depth = 4,
    depth = 1,
    absolute_depth = 21,
    flags = {
        "no_items",
    },
    entry_feature = "DNGN_ENTER_BLADE",
    exit_feature = "DNGN_EXIT_BLADE",
    escape_feature = "NUM_FEATURES",
    short_name = "Hall of Blades",
    long_name = "the Hall of Blades",
    abbreviation = "Blade",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "B",
    runes = mod.null,
    ambient_noise = "quiet",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
