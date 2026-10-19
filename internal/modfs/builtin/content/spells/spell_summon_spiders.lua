-- Summon Spiders (SPELL_SUMMON_SPIDERS) is a level 6 spell in summoning,
-- poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SPIDERS",
    numeric_id = 396,
    status = "defined",
    name = "Summon Spiders",
    schools = {
        "summoning",
        "poison",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
