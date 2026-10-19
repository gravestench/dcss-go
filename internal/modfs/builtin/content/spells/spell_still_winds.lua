-- Still Winds (SPELL_STILL_WINDS) is a level 6 spell in hexes, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STILL_WINDS",
    numeric_id = 345,
    status = "defined",
    name = "Still Winds",
    schools = {
        "hexes",
        "air",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
