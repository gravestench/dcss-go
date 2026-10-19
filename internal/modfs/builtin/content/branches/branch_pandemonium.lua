-- BRANCH_PANDEMONIUM has 1 level(s) and no ordinary parent-depth range.
-- Its entry feature is metadata for special travel, not a fixed branch stair link.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_PANDEMONIUM",
    numeric_id = 23,
    parent_id = "NUM_BRANCHES",
    min_depth = -1,
    max_depth = -1,
    depth = 1,
    absolute_depth = 24,
    flags = {
        "no_x_level_travel",
    },
    entry_feature = "DNGN_ENTER_PANDEMONIUM",
    exit_feature = "DNGN_EXIT_PANDEMONIUM",
    escape_feature = "DNGN_TRANSIT_PANDEMONIUM",
    short_name = "Pandemonium",
    long_name = "Pandemonium",
    abbreviation = "Pan",
    entry_message = "You enter the halls of Pandemonium!\nTo return, you must find a gate leading back.",
    floor_color = "BLACK",
    rock_color = "BLACK",
    travel_shortcut = "R",
    runes = {
        "RUNE_DEMONIC",
        "RUNE_MNOLEG",
        "RUNE_LOM_LOBON",
        "RUNE_CEREBOV",
        "RUNE_GLOORX_VLOQ",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "8",
}

register.definition(categories.BRANCHES, definition)

return definition
