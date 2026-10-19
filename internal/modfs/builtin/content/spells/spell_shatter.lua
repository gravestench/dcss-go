-- Shatter (SPELL_SHATTER) is a level 9 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHATTER",
    numeric_id = 122,
    status = "defined",
    name = "Shatter",
    schools = {
        "earth",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 30,
    tile_id = "TILEG_SHATTER",
}

register.definition(categories.SPELLS, definition)

return definition
