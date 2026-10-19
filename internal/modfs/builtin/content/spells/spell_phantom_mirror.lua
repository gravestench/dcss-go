-- Phantom Mirror (SPELL_PHANTOM_MIRROR) is a level 5 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PHANTOM_MIRROR",
    numeric_id = 294,
    status = "defined",
    name = "Phantom Mirror",
    schools = {
        "hexes",
    },
    flags = {
        "helpful",
        "selfench",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_PHANTOM_MIRROR",
}

register.definition(categories.SPELLS, definition)

return definition
