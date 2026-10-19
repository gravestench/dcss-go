-- Mesmerise (SPELL_MESMERISE) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MESMERISE",
    numeric_id = 214,
    status = "defined",
    name = "Mesmerise",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "WL_check",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
