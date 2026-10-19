-- Storm Form (SPELL_STORM_FORM) is a level 7 spell in transmutation, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
