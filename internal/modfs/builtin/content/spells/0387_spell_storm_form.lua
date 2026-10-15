-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:932
-- Enum line: 524

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STORM_FORM",
    numeric_id = 386,
    status = "defined",
    name = "Storm Form",
    schools = {
        "transmutation",
        "air",
    },
    flags = {
        "helpful",
        "chaotic",
        "utility",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 15,
    effect_noise = 0,
    tile_id = "TILEG_STORM_FORM",
}

register.definition(categories.SPELLS, definition)

return definition
