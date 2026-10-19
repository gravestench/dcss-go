-- Awaken Vines (SPELL_AWAKEN_VINES) is a level 6 spell in hexes, summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_VINES",
    numeric_id = 244,
    status = "defined",
    name = "Awaken Vines",
    schools = {
        "hexes",
        "summoning",
    },
    flags = {
        "area",
        "monster",
        "target",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_AWAKEN_VINES",
}

register.definition(categories.SPELLS, definition)

return definition
