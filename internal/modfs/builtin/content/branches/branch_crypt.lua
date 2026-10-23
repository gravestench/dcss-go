-- branch crypt (BRANCH_CRYPT) has 3 levels and connects from BRANCH_VAULTS.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_CRYPT",
    numeric_id = 13,
    parent_id = "BRANCH_VAULTS",
    min_depth = 2,
    max_depth = 3,
    depth = 3,
    primary_vaults = {
        {
            depth = 3,
            family = families.CRYPT_END,
        },
    },
    absolute_depth = 19,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_CRYPT",
    exit_feature = "DNGN_EXIT_CRYPT",
    escape_feature = "NUM_FEATURES",
    short_name = "Crypt",
    long_name = "the Crypt",
    abbreviation = "Crypt",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "C",
    runes = mod.null,
    ambient_noise = "quiet",
    mon_die_size_expr = "10",
    -- Source Crypt out-of-depth requests stop at five, not floor three.
    ood_cap = 5,
}

register.definition(categories.BRANCHES, definition)

return definition
