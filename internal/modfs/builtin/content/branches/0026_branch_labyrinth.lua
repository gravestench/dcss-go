-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 238
-- Enum line: 45

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_LABYRINTH",
    numeric_id = 25,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 15,
    flags = {
        "no_x_level_travel",
        "no_items",
    },
    entry_feature = "DNGN_ENTER_LABYRINTH",
    exit_feature = "DNGN_EXIT_LABYRINTH",
    escape_feature = "DNGN_EXIT_THROUGH_ABYSS",
    short_name = "Labyrinth",
    long_name = "a Labyrinth",
    abbreviation = "Lab",
    entry_message = "You enter a labyrinth!",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "0",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
