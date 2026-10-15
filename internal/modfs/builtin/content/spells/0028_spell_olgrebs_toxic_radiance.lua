-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:289
-- Enum line: 46

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_OLGREBS_TOXIC_RADIANCE",
    numeric_id = 27,
    status = "defined",
    name = "Olgreb's Toxic Radiance",
    schools = {
        "poison",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_OLGREBS_TOXIC_RADIANCE",
}

register.definition(categories.SPELLS, definition)

return definition
