-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 126
-- Enum line: 25

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_CRYPT",
    numeric_id = 13,
    parent_id = "BRANCH_VAULTS",
    min_depth = 2,
    max_depth = 3,
    depth = 3,
    absolute_depth = 19,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_CRYPT",
    exit_feature = "DNGN_EXIT_CRYPT",
    escape_feature = "NUM_FEATURES",
    short_name = "Crypt",
    long_name = "the Crypt",
    abbreviation = "Crypt",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "C",
    runes = mod.null,
    ambient_noise = "quiet",
    mon_die_size_expr = "10",
}

register.definition(categories.BRANCHES, definition)

return definition
