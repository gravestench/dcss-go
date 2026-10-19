-- Static Discharge (SPELL_DISCHARGE) is a level 2 spell in conjuration, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISCHARGE",
    numeric_id = 124,
    status = "defined",
    name = "Static Discharge",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "area",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_STATIC_DISCHARGE",
}

register.definition(categories.SPELLS, definition)

return definition
