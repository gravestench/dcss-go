-- Dream Dust (SPELL_DREAM_DUST) is a level 3 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DREAM_DUST",
    numeric_id = 348,
    status = "defined",
    name = "Dream Dust",
    schools = {
        "hexes",
    },
    flags = {
        "target",
        "not_self",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
