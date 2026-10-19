-- Summon Scorpions (SPELL_SUMMON_SCORPIONS) is a level 4 spell in summoning,
-- poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SCORPIONS",
    numeric_id = 36,
    status = "defined",
    name = "Summon Scorpions",
    schools = {
        "summoning",
        "poison",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SCORPIONS",
}

register.definition(categories.SPELLS, definition)

return definition
