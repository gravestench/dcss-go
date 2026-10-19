-- Blink Close (SPELL_BLINK_CLOSE) is a level 2 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_CLOSE",
    numeric_id = 173,
    status = "defined",
    name = "Blink Close",
    schools = {
        "translocation",
    },
    flags = {
        "monster",
        "target",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK",
}

register.definition(categories.SPELLS, definition)

return definition
