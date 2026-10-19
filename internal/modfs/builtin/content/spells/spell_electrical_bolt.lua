-- Electrical Bolt (SPELL_ELECTRICAL_BOLT) is a level 5 spell in conjuration,
-- air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ELECTRICAL_BOLT",
    numeric_id = 302,
    status = "defined",
    name = "Electrical Bolt",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_LIGHTNING_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
