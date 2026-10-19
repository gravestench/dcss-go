-- Corona (SPELL_CORONA) is a level 1 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORONA",
    numeric_id = 125,
    status = "defined",
    name = "Corona",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 1,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_CORONA",
}

register.definition(categories.SPELLS, definition)

return definition
