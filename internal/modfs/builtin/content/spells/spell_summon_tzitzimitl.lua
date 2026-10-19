-- Summon Tzitzimitl (SPELL_SUMMON_TZITZIMITL) is a level 8 spell in
-- summoning, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_TZITZIMITL",
    numeric_id = 375,
    status = "defined",
    name = "Summon Tzitzimitl",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "monster",
        "mons_abjure",
    },
    level = 8,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
