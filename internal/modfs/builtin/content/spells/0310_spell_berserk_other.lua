-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2800
-- Enum line: 431

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BERSERK_OTHER",
    numeric_id = 309,
    status = "defined",
    name = "Berserk Other",
    schools = {
        "hexes",
    },
    flags = {
        "hasty",
        "monster",
        "not_self",
        "helpful",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
