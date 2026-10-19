-- Porkalator (SPELL_PORKALATOR) is a level 5 spell in hexes, transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PORKALATOR",
    numeric_id = 163,
    status = "defined",
    name = "Porkalator",
    schools = {
        "hexes",
        "transmutation",
    },
    flags = {
        "dir_or_target",
        "chaotic",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_PORKALATOR",
}

register.definition(categories.SPELLS, definition)

return definition
