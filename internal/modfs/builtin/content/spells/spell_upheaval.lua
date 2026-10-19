-- Upheaval (SPELL_UPHEAVAL) is a level 5 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_UPHEAVAL",
    numeric_id = 350,
    status = "defined",
    name = "Upheaval",
    schools = {
        "conjuration",
    },
    flags = {
        "target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_ABILITY_QAZLAL_UPHEAVAL",
}

register.definition(categories.SPELLS, definition)

return definition
