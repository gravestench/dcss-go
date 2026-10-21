-- branch lair (BRANCH_LAIR) has 5 levels and connects from BRANCH_DUNGEON.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_LAIR",
    numeric_id = 5,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 8,
    max_depth = 11,
    depth = 5,
    absolute_depth = 10,
    flags = {
        "none",
    },
    entry_feature = "DNGN_ENTER_LAIR",
    exit_feature = "DNGN_EXIT_LAIR",
    escape_feature = "NUM_FEATURES",
    short_name = "Lair",
    long_name = "the Lair of Beasts",
    abbreviation = "Lair",
    floor_color = "GREEN",
    rock_color = "BROWN",
    travel_shortcut = "L",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
    -- Source Lair population extends to depth twelve for vault requests,
    -- beyond the five floors the player can visit.
    ood_cap = 12,
}

register.definition(categories.BRANCHES, definition)

return definition
