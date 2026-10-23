-- branch tomb (BRANCH_TOMB) has 3 levels and connects from BRANCH_CRYPT.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")
local maps = require("ids.tomb_maps")

local definition = {
    id = "BRANCH_TOMB",
    numeric_id = 14,
    parent_id = "BRANCH_CRYPT",
    min_depth = 3,
    max_depth = 3,
    depth = 3,
    -- Source hatches name landings on other Tomb floors, so generation
    -- stages the complete route before accepting its first Crypt gate.
    bundle_generator = "policy.generation.tomb.level",
    bundle_maps = {
        {
            id = maps.FIRST,
            family = families.TOMB_1,
        },
        {
            id = maps.SECOND,
            family = families.TOMB_2,
        },
        {
            id = maps.THIRD,
            family = families.TOMB_3,
        },
    },
    absolute_depth = 21,
    flags = {
        "islanded",
        "dangerous_end",
        "no_shafts",
    },
    entry_feature = "DNGN_ENTER_TOMB",
    exit_feature = "DNGN_EXIT_TOMB",
    escape_feature = "NUM_FEATURES",
    short_name = "Tomb",
    long_name = "the Tomb of the Ancients",
    abbreviation = "Tomb",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "W",
    runes = {
        "RUNE_TOMB",
    },
    ambient_noise = "quiet",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
    -- Source Tomb out-of-depth requests stop at five, not floor three.
    ood_cap = 5,
}

register.definition(categories.BRANCHES, definition)

return definition
