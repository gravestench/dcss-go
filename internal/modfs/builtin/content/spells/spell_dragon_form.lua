-- Dragon Form (SPELL_DRAGON_FORM) is a level 7 spell in transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DRAGON_FORM",
    numeric_id = 98,
    status = "defined",
    name = "Dragon Form",
    schools = {
        "transmutation",
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
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DRAGON_FORM",
}

register.definition(categories.SPELLS, definition)

return definition
