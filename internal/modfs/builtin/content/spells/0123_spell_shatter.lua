-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1122
-- Enum line: 174

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHATTER",
    numeric_id = 122,
    status = "defined",
    name = "Shatter",
    schools = {
        "earth",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 30,
    tile_id = "TILEG_SHATTER",
}

register.definition(categories.SPELLS, definition)

return definition
