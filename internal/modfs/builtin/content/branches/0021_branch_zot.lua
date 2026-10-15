-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 192
-- Enum line: 37

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ZOT",
    numeric_id = 20,
    parent_id = "BRANCH_DEPTHS",
    min_depth = 4,
    max_depth = 4,
    depth = 5,
    absolute_depth = 27,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_ZOT",
    exit_feature = "DNGN_EXIT_ZOT",
    escape_feature = "NUM_FEATURES",
    short_name = "Zot",
    long_name = "the Realm of Zot",
    abbreviation = "Zot",
    entry_message = "Welcome to the Realm of Zot!\nYou feel the power of the Orb interfering with translocations here.",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "Z",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
