-- branch gehenna (BRANCH_GEHENNA) has 7 levels and connects from
-- BRANCH_VESTIBULE.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_GEHENNA",
    numeric_id = 17,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    primary_vaults = {
        {
            depth = 7,
            family = families.GEH_END,
        },
    },
    -- The source lava maze is a whole-floor option on ordinary depths.
    encompass_vault_families = {
        families.GEH,
        families.GEH_LAVA_MAZE,
    },
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
    -- Source Gehenna monster requests can reach fourteen, past floor seven.
    ood_cap = 14,
}

register.definition(categories.BRANCHES, definition)

return definition
