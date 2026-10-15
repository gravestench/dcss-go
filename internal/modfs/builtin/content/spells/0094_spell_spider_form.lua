-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:876
-- Enum line: 134

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPIDER_FORM",
    numeric_id = 93,
    status = "defined",
    name = "Spider Form",
    schools = {
        "transmutation",
        "poison",
    },
    flags = {
        "helpful",
        "chaotic",
        "utility",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SPIDER_FORM",
}

register.definition(categories.SPELLS, definition)

return definition
