-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 42
-- Enum line: 11

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_ELF",
    numeric_id = 3,
    parent_id = "BRANCH_ORC",
    min_depth = 2,
    max_depth = 2,
    depth = 3,
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
}

register.definition(categories.BRANCHES, definition)

return definition
