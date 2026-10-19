-- branch cocytus (BRANCH_COCYTUS) has 7 levels and connects from
-- BRANCH_VESTIBULE.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_COCYTUS",
    numeric_id = 18,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_COCYTUS",
    exit_feature = "DNGN_EXIT_COCYTUS",
    escape_feature = "DNGN_EXIT_COCYTUS",
    short_name = "Cocytus",
    long_name = "Cocytus",
    abbreviation = "Coc",
    entry_message = "Your potions freeze solid in the terrible cold.",
    floor_color = "LIGHTBLUE",
    rock_color = "LIGHTCYAN",
    travel_shortcut = "X",
    runes = {
        "RUNE_COCYTUS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
