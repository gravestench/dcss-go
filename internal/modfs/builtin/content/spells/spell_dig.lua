-- Dig (SPELL_DIG) is a level 4 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DIG",
    numeric_id = 9,
    status = "defined",
    name = "Dig",
    schools = {
        "earth",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "neutral",
        "utility",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_DIG",
}

register.definition(categories.SPELLS, definition)

return definition
