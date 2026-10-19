-- branch tomb (BRANCH_TOMB) has 3 levels and connects from BRANCH_CRYPT.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_TOMB",
    numeric_id = 14,
    parent_id = "BRANCH_CRYPT",
    min_depth = 3,
    max_depth = 3,
    depth = 3,
    absolute_depth = 21,
    flags = {
        "islanded",
        "dangerous_end",
        "no_shafts",
    },
    entry_feature = "DNGN_ENTER_TOMB",
    exit_feature = "DNGN_EXIT_TOMB",
    escape_feature = "NUM_FEATURES",
    short_name = "Tomb",
    long_name = "the Tomb of the Ancients",
    abbreviation = "Tomb",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "W",
    runes = {
        "RUNE_TOMB",
    },
    ambient_noise = "quiet",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
