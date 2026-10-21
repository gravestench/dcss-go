-- branch slime (BRANCH_SLIME) has 5 levels and connects from BRANCH_LAIR.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_SLIME",
    numeric_id = 10,
    parent_id = "BRANCH_LAIR",
    min_depth = 4,
    max_depth = 5,
    depth = 5,
    absolute_depth = 17,
    flags = {
        "no_items",
        "dangerous_end",
        "spotty",
    },
    entry_feature = "DNGN_ENTER_SLIME",
    exit_feature = "DNGN_EXIT_SLIME",
    escape_feature = "NUM_FEATURES",
    short_name = "Slime Pits",
    long_name = "the Pits of Slime",
    abbreviation = "Slime",
    floor_color = "GREEN",
    rock_color = "BROWN",
    travel_shortcut = "M",
    runes = {
        "RUNE_SLIME",
    },
    -- Slime:5 is the source whole-floor Slime Pit, never a generic cave.
    end_layout_required = true,
    ambient_noise = "quiet",
    mon_die_size_expr = "7",
}

register.definition(categories.BRANCHES, definition)

return definition
