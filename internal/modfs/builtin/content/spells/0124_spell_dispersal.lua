-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1133
-- Enum line: 175

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISPERSAL",
    numeric_id = 123,
    status = "defined",
    name = "Dispersal",
    schools = {
        "translocation",
    },
    flags = {
        "area",
        "escape",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "1",
    max_range_expr = "4",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_DISPERSAL",
}

register.definition(categories.SPELLS, definition)

return definition
