-- Petrify (SPELL_PETRIFY) is a level 4 spell in transmutation, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PETRIFY",
    numeric_id = 138,
    status = "defined",
    name = "Petrify",
    schools = {
        "transmutation",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_PETRIFY",
}

register.definition(categories.SPELLS, definition)

return definition
