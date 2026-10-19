-- Leda's Liquefaction (SPELL_LEDAS_LIQUEFACTION) is a level 4 spell in earth,
-- hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LEDAS_LIQUEFACTION",
    numeric_id = 210,
    status = "defined",
    name = "Leda's Liquefaction",
    schools = {
        "earth",
        "hexes",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_LEDAS_LIQUEFACTION",
}

register.definition(categories.SPELLS, definition)

return definition
