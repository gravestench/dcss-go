-- Lee's Rapid Deconstruction (SPELL_LRD) is a level 5 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LRD",
    numeric_id = 128,
    status = "defined",
    name = "Lee's Rapid Deconstruction",
    schools = {
        "earth",
    },
    flags = {
        "target",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_LEES_RAPID_DECONSTRUCTION",
}

register.definition(categories.SPELLS, definition)

return definition
