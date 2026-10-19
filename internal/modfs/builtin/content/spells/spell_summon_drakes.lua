-- Summon Drakes (SPELL_SUMMON_DRAKES) is a level 6 spell in summoning,
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_DRAKES",
    numeric_id = 154,
    status = "defined",
    name = "Summon Drakes",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "unclean",
        "monster",
        "mons_abjure",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_DRAKES",
}

register.definition(categories.SPELLS, definition)

return definition
