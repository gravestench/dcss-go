-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:175
-- Enum line: 31

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HASTE",
    numeric_id = 16,
    status = "defined",
    name = "Haste",
    schools = {
        "hexes",
    },
    flags = {
        "helpful",
        "hasty",
        "selfench",
        "utility",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HASTE",
}

register.definition(categories.SPELLS, definition)

return definition
