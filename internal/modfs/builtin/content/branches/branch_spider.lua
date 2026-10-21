-- branch spider (BRANCH_SPIDER) has 4 levels and connects from BRANCH_LAIR.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_SPIDER",
    numeric_id = 9,
    parent_id = "BRANCH_LAIR",
    min_depth = 2,
    max_depth = 3,
    depth = 4,
    primary_vaults = {
        {
            depth = 4,
            family = families.SPIDER_END,
        },
    },
    absolute_depth = 15,
    -- Source branch_ood_cap bounds depth requests from end-map MONS rules.
    ood_cap = 7,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_SPIDER",
    exit_feature = "DNGN_EXIT_SPIDER",
    escape_feature = "NUM_FEATURES",
    short_name = "Spider Nest",
    long_name = "the Spider Nest",
    abbreviation = "Spider",
    floor_color = "BROWN",
    rock_color = "YELLOW",
    travel_shortcut = "N",
    runes = {
        "RUNE_SPIDER",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
