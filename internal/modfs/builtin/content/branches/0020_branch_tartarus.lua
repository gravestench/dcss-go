-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 184
-- Enum line: 34

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_TARTARUS",
    numeric_id = 19,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_TARTARUS",
    exit_feature = "DNGN_EXIT_TARTARUS",
    escape_feature = "DNGN_EXIT_TARTARUS",
    short_name = "Tartarus",
    long_name = "Tartarus",
    abbreviation = "Tar",
    entry_message = "This decaying realm drains your will.",
    floor_color = "MAGENTA",
    rock_color = "MAGENTA",
    travel_shortcut = "Y",
    runes = {
        "RUNE_TARTARUS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
