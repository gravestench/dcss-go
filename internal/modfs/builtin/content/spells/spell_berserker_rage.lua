-- Berserker Rage (SPELL_BERSERKER_RAGE) is a level 3 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BERSERKER_RAGE",
    numeric_id = 62,
    status = "defined",
    name = "Berserker Rage",
    schools = {
        "earth",
    },
    flags = {
        "hasty",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_BERSERKER_RAGE",
}

register.definition(categories.SPELLS, definition)

return definition
