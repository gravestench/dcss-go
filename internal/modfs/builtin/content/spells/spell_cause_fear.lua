-- Cause Fear (SPELL_CAUSE_FEAR) is a level 4 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CAUSE_FEAR",
    numeric_id = 2,
    status = "defined",
    name = "Cause Fear",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_CAUSE_FEAR",
}

register.definition(categories.SPELLS, definition)

return definition
