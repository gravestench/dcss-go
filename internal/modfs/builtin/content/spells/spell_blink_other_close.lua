-- Blink Other Close (SPELL_BLINK_OTHER_CLOSE) is a level 2 spell in
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_OTHER_CLOSE",
    numeric_id = 172,
    status = "defined",
    name = "Blink Other Close",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "not_self",
        "monster",
        "needs_tracer",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
