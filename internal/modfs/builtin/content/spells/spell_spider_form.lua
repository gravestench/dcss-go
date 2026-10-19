-- Spider Form (SPELL_SPIDER_FORM) is a level 3 spell in transmutation,
-- poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
