-- Airstrike (SPELL_AIRSTRIKE) is a level 4 spell in air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AIRSTRIKE",
    numeric_id = 105,
    status = "defined",
    name = "Airstrike",
    schools = {
        "air",
    },
    flags = {
        "target",
        "not_self",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 4,
    tile_id = "TILEG_AIRSTRIKE",
}

register.definition(categories.SPELLS, definition)

return definition
