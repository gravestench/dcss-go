-- branch tartarus (BRANCH_TARTARUS) has 7 levels and connects from
-- BRANCH_VESTIBULE.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_TARTARUS",
    numeric_id = 19,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    primary_vaults = {
        {
            depth = 7,
            family = families.TAR_END,
        },
    },
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_TARTARUS",
    exit_feature = "DNGN_EXIT_TARTARUS",
    escape_feature = "DNGN_EXIT_TARTARUS",
    short_name = "Tartarus",
    long_name = "Tartarus",
    abbreviation = "Tar",
    entry_message = "This decaying realm drains your will.",
    floor_color = "MAGENTA",
    rock_color = "MAGENTA",
    travel_shortcut = "Y",
    runes = {
        "RUNE_TARTARUS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
    -- Source Tartarus monster requests can reach fourteen, past floor seven.
    ood_cap = 14,
}

register.definition(categories.BRANCHES, definition)

return definition
