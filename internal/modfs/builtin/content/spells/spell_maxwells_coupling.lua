-- Maxwell's Capacitive Coupling (SPELL_MAXWELLS_COUPLING) is a level 8 spell
-- in air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MAXWELLS_COUPLING",
    numeric_id = 369,
    status = "defined",
    name = "Maxwell's Capacitive Coupling",
    schools = {
        "air",
    },
    flags = {
        "no_ghost",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 7,
    effect_noise = 25,
    tile_id = "TILEG_MAXWELLS_COUPLING",
}

register.definition(categories.SPELLS, definition)

return definition
