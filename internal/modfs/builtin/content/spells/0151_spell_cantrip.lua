-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1428
-- Enum line: 214

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CANTRIP",
    numeric_id = 150,
    status = "defined",
    name = "Cantrip",
    schools = {
        "none",
    },
    flags = {
        "monster",
    },
    level = 1,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_CANTRIP",
}

register.definition(categories.SPELLS, definition)

return definition
