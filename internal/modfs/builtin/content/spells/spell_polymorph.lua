-- Polymorph (SPELL_POLYMORPH) is a level 4 spell in transmutation, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POLYMORPH",
    numeric_id = 14,
    status = "defined",
    name = "Polymorph",
    schools = {
        "transmutation",
        "hexes",
    },
    flags = {
        "dir_or_target",
        "chaotic",
        "needs_tracer",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_POLYMORPH",
}

register.definition(categories.SPELLS, definition)

return definition
