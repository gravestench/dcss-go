-- Inner Flame (SPELL_INNER_FLAME) is a level 3 spell in hexes, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INNER_FLAME",
    numeric_id = 218,
    status = "defined",
    name = "Inner Flame",
    schools = {
        "hexes",
        "fire",
    },
    flags = {
        "target",
        "not_self",
        "WL_check",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_INNER_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
