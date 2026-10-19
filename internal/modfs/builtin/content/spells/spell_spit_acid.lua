-- Spit Acid (SPELL_SPIT_ACID) is a level 5 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPIT_ACID",
    numeric_id = 157,
    status = "defined",
    name = "Spit Acid",
    schools = {
        "conjuration",
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
    tile_id = "TILEG_SPIT_ACID",
}

register.definition(categories.SPELLS, definition)

return definition
