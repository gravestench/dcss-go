-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 160
-- Enum line: 31

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DIS",
    numeric_id = 16,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_DIS",
    exit_feature = "DNGN_EXIT_DIS",
    escape_feature = "DNGN_EXIT_DIS",
    short_name = "Dis",
    long_name = "the Iron City of Dis",
    abbreviation = "Dis",
    entry_message = "An ancient malice corrodes your equipment.",
    floor_color = "CYAN",
    rock_color = "BROWN",
    travel_shortcut = "I",
    runes = {
        "RUNE_DIS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
