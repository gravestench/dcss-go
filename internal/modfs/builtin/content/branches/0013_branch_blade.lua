-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 117
-- Enum line: 23

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
