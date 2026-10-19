-- Minor Healing (SPELL_MINOR_HEALING) is a level 2 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MINOR_HEALING",
    numeric_id = 29,
    status = "defined",
    name = "Minor Healing",
    schools = {
        "necromancy",
    },
    flags = {
        "recovery",
        "helpful",
        "monster",
        "selfench",
        "utility",
        "not_evil",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_MINOR_HEALING",
}

register.definition(categories.SPELLS, definition)

return definition
