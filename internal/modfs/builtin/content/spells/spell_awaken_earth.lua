-- Awaken Earth (SPELL_AWAKEN_EARTH) is a level 7 spell in summoning, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_EARTH",
    numeric_id = 333,
    status = "defined",
    name = "Awaken Earth",
    schools = {
        "summoning",
        "earth",
    },
    flags = {
        "monster",
        "target",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
