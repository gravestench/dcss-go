-- Wind Blast (SPELL_WIND_BLAST) is a level 3 spell in air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WIND_BLAST",
    numeric_id = 250,
    status = "defined",
    name = "Wind Blast",
    schools = {
        "air",
    },
    flags = {
        "area",
        "target",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
