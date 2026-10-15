-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2921
-- Enum line: 451

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CLEANSING_FLAME",
    numeric_id = 323,
    status = "defined",
    name = "Cleansing Flame",
    schools = {
        "none",
    },
    flags = {
        "area",
        "monster",
        "holy",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 20,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
