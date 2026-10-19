-- Statue Form (SPELL_STATUE_FORM) is a level 6 spell in transmutation, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
