-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 168
-- Enum line: 32

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_GEHENNA",
    numeric_id = 17,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_GEHENNA",
    exit_feature = "DNGN_EXIT_GEHENNA",
    escape_feature = "DNGN_EXIT_GEHENNA",
    short_name = "Gehenna",
    long_name = "Gehenna",
    abbreviation = "Geh",
    entry_message = "Your scrolls appear blurry in the acrid smoke.",
    floor_color = "BROWN",
    rock_color = "RED",
    travel_shortcut = "G",
    runes = {
        "RUNE_GEHENNA",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
