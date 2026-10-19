-- Summon Hell Beast (SPELL_SUMMON_HELL_BEAST) is a level 4 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HELL_BEAST",
    numeric_id = 146,
    status = "defined",
    name = "Summon Hell Beast",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "monster",
        "selfench",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_HELL_BEAST",
}

register.definition(categories.SPELLS, definition)

return definition
