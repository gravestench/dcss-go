-- Sleep (SPELL_SLEEP) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SLEEP",
    numeric_id = 171,
    status = "defined",
    name = "Sleep",
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
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SLEEP",
}

register.definition(categories.SPELLS, definition)

return definition
