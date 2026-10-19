-- Haste (SPELL_HASTE) is a level 6 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HASTE",
    numeric_id = 16,
    status = "defined",
    name = "Haste",
    schools = {
        "hexes",
    },
    flags = {
        "helpful",
        "hasty",
        "selfench",
        "utility",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HASTE",
}

register.definition(categories.SPELLS, definition)

return definition
