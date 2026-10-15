-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 176
-- Enum line: 33

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
