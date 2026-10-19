-- Drain Magic (SPELL_DRAIN_MAGIC) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DRAIN_MAGIC",
    numeric_id = 295,
    status = "defined",
    name = "Drain Magic",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
        "WL_check",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
