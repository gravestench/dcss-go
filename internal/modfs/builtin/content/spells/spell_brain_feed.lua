-- Brain Feed (SPELL_BRAIN_FEED) is a level 3 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BRAIN_FEED",
    numeric_id = 142,
    status = "defined",
    name = "Brain Feed",
    schools = {
        "necromancy",
    },
    flags = {
        "target",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_BRAIN_FEED",
}

register.definition(categories.SPELLS, definition)

return definition
