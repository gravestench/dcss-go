-- Entropic Weave (SPELL_ENTROPIC_WEAVE) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ENTROPIC_WEAVE",
    numeric_id = 329,
    status = "defined",
    name = "Entropic Weave",
    schools = {
        "hexes",
    },
    flags = {
        "utility",
        "target",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
