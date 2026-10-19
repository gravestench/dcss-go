-- Tukima's Dance (SPELL_TUKIMAS_DANCE) is a level 3 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_TUKIMAS_DANCE",
    numeric_id = 72,
    status = "defined",
    name = "Tukima's Dance",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "not_self",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_TUKIMAS_DANCE",
}

register.definition(categories.SPELLS, definition)

return definition
