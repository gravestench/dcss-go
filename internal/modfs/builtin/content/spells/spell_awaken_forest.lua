-- Awaken Forest (SPELL_AWAKEN_FOREST) is a level 6 spell in hexes, summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_FOREST",
    numeric_id = 186,
    status = "defined",
    name = "Awaken Forest",
    schools = {
        "hexes",
        "summoning",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
