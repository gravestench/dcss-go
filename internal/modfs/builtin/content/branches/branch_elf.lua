-- branch elf (BRANCH_ELF) has 3 levels and connects from BRANCH_ORC.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")
local families = require("constants.vault_families")

local definition = {
    id = "BRANCH_ELF",
    numeric_id = 3,
    parent_id = "BRANCH_ORC",
    min_depth = 2,
    max_depth = 2,
    depth = 3,
    -- The source chooses one border check, Hall of Blades, and final hall.
    -- The Elf:1 dummy deliberately keeps an ordinary procedural floor.
    primary_vaults = {
        {
            depth = 1,
            family = families.ELF_ARRIVAL,
            allow_dummy = true,
        },
        {
            depth = 2,
            family = families.ELF_BLADES,
        },
        {
            depth = 3,
            family = families.ELF_END,
        },
    },
    absolute_depth = 15,
    flags = {
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_ELF",
    exit_feature = "DNGN_EXIT_ELF",
    escape_feature = "NUM_FEATURES",
    short_name = "Elven Halls",
    long_name = "the Elven Halls",
    abbreviation = "Elf",
    floor_color = "WHITE",
    rock_color = "ETC_ELVEN_BRICK",
    travel_shortcut = "E",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
    -- Source Elf monster requests can reach seven, past its three floors.
    ood_cap = 7,
}

register.definition(categories.BRANCHES, definition)

return definition
