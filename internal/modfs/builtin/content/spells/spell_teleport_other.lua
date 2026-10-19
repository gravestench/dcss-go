-- Teleport Other (SPELL_TELEPORT_OTHER) is a level 3 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_TELEPORT_OTHER",
    numeric_id = 28,
    status = "defined",
    name = "Teleport Other",
    schools = {
        "translocation",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "escape",
        "needs_tracer",
        "WL_check",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_TELEPORT_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
