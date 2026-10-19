-- Abjuration (SPELL_ABJURATION) is a level 3 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ABJURATION",
    numeric_id = 35,
    status = "defined",
    name = "Abjuration",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_MASS_ABJURATION",
}

register.definition(categories.SPELLS, definition)

return definition
