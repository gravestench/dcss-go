-- Sporulate (SPELL_SPORULATE) is a level 5 spell in conjuration, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPORULATE",
    numeric_id = 361,
    status = "defined",
    name = "Sporulate",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SPORULATE",
}

register.definition(categories.SPELLS, definition)

return definition
