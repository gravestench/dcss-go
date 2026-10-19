-- Seracfall (SPELL_SERACFALL) is a level 5 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SERACFALL",
    numeric_id = 391,
    status = "defined",
    name = "Seracfall",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_ICEBLAST",
}

register.definition(categories.SPELLS, definition)

return definition
