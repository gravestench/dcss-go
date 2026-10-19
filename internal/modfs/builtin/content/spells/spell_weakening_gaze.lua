-- Weakening Gaze (SPELL_WEAKENING_GAZE) is a level 4 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WEAKENING_GAZE",
    numeric_id = 385,
    status = "defined",
    name = "Weakening Gaze",
    schools = {
        "hexes",
    },
    flags = {
        "target",
        "not_self",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
