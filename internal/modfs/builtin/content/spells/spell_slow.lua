-- Slow (SPELL_SLOW) is a level 1 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SLOW",
    numeric_id = 15,
    status = "defined",
    name = "Slow",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SLOW",
}

register.definition(categories.SPELLS, definition)

return definition
