-- Anguish (SPELL_ANGUISH) is a level 4 spell in hexes, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANGUISH",
    numeric_id = 397,
    status = "defined",
    name = "Anguish",
    schools = {
        "hexes",
        "necromancy",
    },
    flags = {
        "area",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_ANGUISH",
}

register.definition(categories.SPELLS, definition)

return definition
