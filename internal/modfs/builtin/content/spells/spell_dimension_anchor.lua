-- Dimension Anchor (SPELL_DIMENSION_ANCHOR) is a level 4 spell in
-- translocation, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DIMENSION_ANCHOR",
    numeric_id = 242,
    status = "defined",
    name = "Dimension Anchor",
    schools = {
        "translocation",
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
