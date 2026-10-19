-- Summon Scarabs (SPELL_SUMMON_SCARABS) is a level 7 spell in summoning,
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SCARABS",
    numeric_id = 318,
    status = "defined",
    name = "Summon Scarabs",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
