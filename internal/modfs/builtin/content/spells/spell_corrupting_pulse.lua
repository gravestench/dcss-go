-- Corrupting Pulse (SPELL_CORRUPTING_PULSE) is a level 6 spell in hexes,
-- transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORRUPTING_PULSE",
    numeric_id = 311,
    status = "defined",
    name = "Corrupting Pulse",
    schools = {
        "hexes",
        "transmutation",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
