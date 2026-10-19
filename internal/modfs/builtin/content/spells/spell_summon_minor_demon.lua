-- Summon Minor Demon (SPELL_SUMMON_MINOR_DEMON) is a level 2 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_MINOR_DEMON",
    numeric_id = 225,
    status = "defined",
    name = "Summon Minor Demon",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "monster",
    },
    level = 2,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_MINOR_DEMON",
}

register.definition(categories.SPELLS, definition)

return definition
