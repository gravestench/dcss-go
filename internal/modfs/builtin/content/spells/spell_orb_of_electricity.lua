-- Orb of Electricity (SPELL_ORB_OF_ELECTRICITY) is a level 7 spell in
-- conjuration, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ORB_OF_ELECTRICITY",
    numeric_id = 265,
    status = "defined",
    name = "Orb of Electricity",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_ORB_OF_ELECTRICITY",
}

register.definition(categories.SPELLS, definition)

return definition
