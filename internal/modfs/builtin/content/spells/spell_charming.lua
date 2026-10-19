-- Charm (SPELL_CHARMING) is a level 4 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHARMING",
    numeric_id = 46,
    status = "defined",
    name = "Charm",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_CHARMING",
}

register.definition(categories.SPELLS, definition)

return definition
