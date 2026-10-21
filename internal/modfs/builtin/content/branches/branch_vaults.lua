-- branch vaults (BRANCH_VAULTS) has 5 levels and connects from
-- BRANCH_DUNGEON.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_VAULTS",
    numeric_id = 11,
    parent_id = "BRANCH_DUNGEON",
    min_depth = 13,
    max_depth = 14,
    depth = 5,
    -- The last floor uses its authored PLACE map, not a V:1-4 layout.
    end_layout_required = true,
    -- Source monster generation caps Vaults out-of-depth draws at 12.
    ood_cap = 12,
    absolute_depth = 19,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_VAULTS",
    exit_feature = "DNGN_EXIT_VAULTS",
    escape_feature = "NUM_FEATURES",
    short_name = "Vaults",
    long_name = "the Vaults",
    abbreviation = "Vaults",
    floor_color = "LIGHTGREY",
    rock_color = "BROWN",
    travel_shortcut = "V",
    runes = {
        "RUNE_VAULTS",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "9",
}

register.definition(categories.BRANCHES, definition)

return definition
