-- Hailstorm (SPELL_HAILSTORM) is a level 4 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HAILSTORM",
    numeric_id = 364,
    status = "defined",
    name = "Hailstorm",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_HAILSTORM",
}

register.definition(categories.SPELLS, definition)

return definition
