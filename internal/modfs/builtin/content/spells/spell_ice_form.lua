-- Ice Form (SPELL_ICE_FORM) is a level 4 spell in ice, transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ICE_FORM",
    numeric_id = 97,
    status = "defined",
    name = "Ice Form",
    schools = {
        "ice",
        "transmutation",
    },
    flags = {
        "helpful",
        "chaotic",
        "utility",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_ICE_FORM",
}

register.definition(categories.SPELLS, definition)

return definition
