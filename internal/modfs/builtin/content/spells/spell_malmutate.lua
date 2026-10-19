-- Malmutate (SPELL_MALMUTATE) is a level 6 spell in transmutation, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MALMUTATE",
    numeric_id = 234,
    status = "defined",
    name = "Malmutate",
    schools = {
        "transmutation",
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "chaotic",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_MALMUTATE",
}

register.definition(categories.SPELLS, definition)

return definition
