-- branch orc (BRANCH_ORC) has 2 levels and connects from BRANCH_DUNGEON.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_ORC",
    numeric_id = 2,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 9,
    max_depth = 12,
    depth = 2,
    absolute_depth = 10,
    flags = {
        "spotty",
    },
    entry_feature = "DNGN_ENTER_ORC",
    exit_feature = "DNGN_EXIT_ORC",
    escape_feature = "NUM_FEATURES",
    short_name = "Orcish Mines",
    long_name = "the Orcish Mines",
    abbreviation = "Orc",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "O",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
    -- Orc:2 is a required source ending, with shops instead of a rune.
    primary_vaults = {
        {
            depth = 2,
            family = families.ORC_END,
        },
    },
}

register.definition(categories.BRANCHES, definition)

return definition
