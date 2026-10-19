-- Might Other (SPELL_MIGHT_OTHER) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MIGHT_OTHER",
    numeric_id = 235,
    status = "defined",
    name = "Might Other",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "needs_tracer",
        "utility",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_MIGHT",
}

register.definition(categories.SPELLS, definition)

return definition
