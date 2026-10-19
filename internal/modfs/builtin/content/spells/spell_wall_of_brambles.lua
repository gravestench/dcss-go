-- Wall of Brambles (SPELL_WALL_OF_BRAMBLES) is a level 5 spell in
-- conjuration, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WALL_OF_BRAMBLES",
    numeric_id = 247,
    status = "defined",
    name = "Wall of Brambles",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "area",
        "monster",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_WALL_OF_BRAMBLES",
}

register.definition(categories.SPELLS, definition)

return definition
