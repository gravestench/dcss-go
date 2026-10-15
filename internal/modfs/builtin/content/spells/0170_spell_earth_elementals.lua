-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1682
-- Enum line: 237

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_EARTH_ELEMENTALS",
    numeric_id = 169,
    status = "defined",
    name = "Summon Earth Elementals",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "mons_abjure",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_EARTH_ELEMENTALS",
}

register.definition(categories.SPELLS, definition)

return definition
