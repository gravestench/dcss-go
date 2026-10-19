-- Gell's Gravitas (SPELL_GRAVITAS) is a level 3 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GRAVITAS",
    numeric_id = 327,
    status = "defined",
    name = "Gell's Gravitas",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "not_self",
        "needs_tracer",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GRAVITAS",
}

register.definition(categories.SPELLS, definition)

return definition
