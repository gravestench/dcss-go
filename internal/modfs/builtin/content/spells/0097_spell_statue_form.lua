-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:910
-- Enum line: 137

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STATUE_FORM",
    numeric_id = 96,
    status = "defined",
    name = "Statue Form",
    schools = {
        "transmutation",
        "earth",
    },
    flags = {
        "helpful",
        "chaotic",
        "utility",
    },
    level = 6,
    power_cap = 150,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_STATUE_FORM",
}

register.definition(categories.SPELLS, definition)

return definition
