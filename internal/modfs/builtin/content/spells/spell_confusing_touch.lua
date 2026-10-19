-- Confusing Touch (SPELL_CONFUSING_TOUCH) is a level 3 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONFUSING_TOUCH",
    numeric_id = 107,
    status = "defined",
    name = "Confusing Touch",
    schools = {
        "hexes",
    },
    flags = {
        "selfench",
        "WL_check",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_CONFUSING_TOUCH",
}

register.definition(categories.SPELLS, definition)

return definition
