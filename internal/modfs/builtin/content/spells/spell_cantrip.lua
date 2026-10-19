-- Cantrip (SPELL_CANTRIP) is a level 1 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CANTRIP",
    numeric_id = 150,
    status = "defined",
    name = "Cantrip",
    schools = {
        "none",
    },
    flags = {
        "monster",
    },
    level = 1,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_CANTRIP",
}

register.definition(categories.SPELLS, definition)

return definition
