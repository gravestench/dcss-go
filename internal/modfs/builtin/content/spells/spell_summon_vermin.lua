-- Summon Vermin (SPELL_SUMMON_VERMIN) is a level 5 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_VERMIN",
    numeric_id = 256,
    status = "defined",
    name = "Summon Vermin",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "unholy",
        "selfench",
        "mons_abjure",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_VERMIN",
}

register.definition(categories.SPELLS, definition)

return definition
