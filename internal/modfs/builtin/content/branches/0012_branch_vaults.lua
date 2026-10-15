-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 108
-- Enum line: 21

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_VAULTS",
    numeric_id = 11,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 13,
    max_depth = 14,
    depth = 5,
    absolute_depth = 19,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_VAULTS",
    exit_feature = "DNGN_EXIT_VAULTS",
    escape_feature = "NUM_FEATURES",
    short_name = "Vaults",
    long_name = "the Vaults",
    abbreviation = "Vaults",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "V",
    runes = {
        "RUNE_VAULTS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "9",
}

register.definition(categories.BRANCHES, definition)

return definition
