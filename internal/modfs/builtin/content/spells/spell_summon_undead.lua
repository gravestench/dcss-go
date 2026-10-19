-- Summon Undead (SPELL_SUMMON_UNDEAD) is a level 7 spell in summoning,
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_UNDEAD",
    numeric_id = 149,
    status = "defined",
    name = "Summon Undead",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "monster",
        "mons_abjure",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_UNDEAD",
}

register.definition(categories.SPELLS, definition)

return definition
