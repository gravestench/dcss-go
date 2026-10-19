-- Virulence (SPELL_VIRULENCE) is a level 4 spell in poison, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VIRULENCE",
    numeric_id = 263,
    status = "defined",
    name = "Virulence",
    schools = {
        "poison",
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
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
