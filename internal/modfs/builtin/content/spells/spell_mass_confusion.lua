-- Mass Confusion (SPELL_MASS_CONFUSION) is a level 6 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MASS_CONFUSION",
    numeric_id = 32,
    status = "defined",
    name = "Mass Confusion",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "WL_check",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_MASS_CONFUSION",
}

register.definition(categories.SPELLS, definition)

return definition
