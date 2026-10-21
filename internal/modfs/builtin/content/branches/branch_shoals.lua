-- branch shoals (BRANCH_SHOALS) has 4 levels and connects from BRANCH_LAIR.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_SHOALS",
    numeric_id = 7,
    parent_id = "BRANCH_LAIR",
    min_depth = 2,
    max_depth = 3,
    depth = 4,
    -- Source branch_ood_cap defaults to this branch's four levels. DES
    -- out-of-depth monster requests must not sample an empty Shoals:12.
    ood_cap = 4,
    absolute_depth = 15,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_SHOALS",
    exit_feature = "DNGN_EXIT_SHOALS",
    escape_feature = "NUM_FEATURES",
    short_name = "Shoals",
    long_name = "the Shoals",
    abbreviation = "Shoals",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "A",
    runes = {
        "RUNE_SHOALS",
    },
    primary_vaults = {
        {
            depth = 4,
            family = families.SHOALS_END,
        },
    },
    ambient_noise = "loud",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
