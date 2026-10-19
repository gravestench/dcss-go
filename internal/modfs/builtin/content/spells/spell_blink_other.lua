-- Blink Other (SPELL_BLINK_OTHER) is a level 2 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_OTHER",
    numeric_id = 155,
    status = "defined",
    name = "Blink Other",
    schools = {
        "translocation",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "escape",
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
