-- Confusion Gaze (SPELL_CONFUSION_GAZE) is a level 3 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONFUSION_GAZE",
    numeric_id = 315,
    status = "defined",
    name = "Confusion Gaze",
    schools = {
        "hexes",
    },
    flags = {
        "target",
        "not_self",
        "monster",
        "WL_check",
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
