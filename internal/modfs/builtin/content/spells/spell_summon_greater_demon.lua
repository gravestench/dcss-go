-- Summon Greater Demon (SPELL_SUMMON_GREATER_DEMON) is a level 7 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_GREATER_DEMON",
    numeric_id = 76,
    status = "defined",
    name = "Summon Greater Demon",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_GREATER_DEMON",
}

register.definition(categories.SPELLS, definition)

return definition
