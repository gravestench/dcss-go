-- Swiftness (SPELL_SWIFTNESS) is a level 3 spell in air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SWIFTNESS",
    numeric_id = 84,
    status = "defined",
    name = "Swiftness",
    schools = {
        "air",
    },
    flags = {
        "hasty",
        "selfench",
        "utility",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SWIFTNESS",
}

register.definition(categories.SPELLS, definition)

return definition
