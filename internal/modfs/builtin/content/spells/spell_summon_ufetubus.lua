-- Summon Ufetubus (SPELL_SUMMON_UFETUBUS) is a level 4 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_UFETUBUS",
    numeric_id = 145,
    status = "defined",
    name = "Summon Ufetubus",
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
    tile_id = "TILEG_SUMMON_UFETUBUS",
}

register.definition(categories.SPELLS, definition)

return definition
