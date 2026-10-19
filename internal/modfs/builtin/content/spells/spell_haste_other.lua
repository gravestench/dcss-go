-- Haste Other (SPELL_HASTE_OTHER) is a level 6 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HASTE_OTHER",
    numeric_id = 167,
    status = "defined",
    name = "Haste Other",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "hasty",
        "needs_tracer",
        "utility",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HASTE_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
