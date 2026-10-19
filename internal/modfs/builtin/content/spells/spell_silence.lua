-- Silence (SPELL_SILENCE) is a level 5 spell in hexes, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SILENCE",
    numeric_id = 121,
    status = "defined",
    name = "Silence",
    schools = {
        "hexes",
        "air",
    },
    flags = {
        "area",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SILENCE",
}

register.definition(categories.SPELLS, definition)

return definition
