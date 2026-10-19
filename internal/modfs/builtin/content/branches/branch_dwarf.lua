-- branch dwarf (BRANCH_DWARF) has 0 levels and connects from BRANCH_ELF.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_DWARF",
    numeric_id = 4,
    parent_id = "BRANCH_ELF",
    min_depth = -1,
    max_depth = -1,
    depth = 0,
    absolute_depth = 17,
    flags = {
        "none",
    },
    entry_feature = "DNGN_ENTER_DWARF",
    exit_feature = "DNGN_EXIT_DWARF",
    escape_feature = "NUM_FEATURES",
    short_name = "Dwarven Hall",
    long_name = "the Dwarven Hall",
    abbreviation = "Dwarf",
    floor_color = "BROWN",
    rock_color = "BROWN",
    travel_shortcut = "K",
    runes = mod.null,
    ambient_noise = "normal",
    mon_die_size_expr = "DEFAULT_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
