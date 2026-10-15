-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1793
-- Enum line: 256

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MIGHT",
    numeric_id = 184,
    status = "defined",
    name = "Might",
    schools = {
        "hexes",
    },
    flags = {
        "helpful",
        "selfench",
        "utility",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_MIGHT",
}

register.definition(categories.SPELLS, definition)

return definition
