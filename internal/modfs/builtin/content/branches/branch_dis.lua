-- branch dis (BRANCH_DIS) has 7 levels and connects from BRANCH_VESTIBULE.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_DIS",
    numeric_id = 16,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    -- The source ending is mandatory on the seventh floor.
    primary_vaults = {
        {
            depth = 7,
            family = families.DIS_END,
        },
    },
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_DIS",
    exit_feature = "DNGN_EXIT_DIS",
    escape_feature = "DNGN_EXIT_DIS",
    short_name = "Dis",
    long_name = "the Iron City of Dis",
    abbreviation = "Dis",
    entry_message = "An ancient malice corrodes your equipment.",
    floor_color = "CYAN",
    rock_color = "BROWN",
    travel_shortcut = "I",
    runes = {
        "RUNE_DIS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
    -- Source Dis monster requests can reach fourteen, past floor seven.
    ood_cap = 14,
}

register.definition(categories.BRANCHES, definition)

return definition
