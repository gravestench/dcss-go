-- Might (SPELL_MIGHT) is a level 3 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
