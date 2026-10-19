-- Invisibility (SPELL_INVISIBILITY) is a level 6 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INVISIBILITY",
    numeric_id = 19,
    status = "defined",
    name = "Invisibility",
    schools = {
        "hexes",
    },
    flags = {
        "helpful",
        "selfench",
        "escape",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_INVISIBILITY",
}

register.definition(categories.SPELLS, definition)

return definition
