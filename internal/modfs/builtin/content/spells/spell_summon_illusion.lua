-- Summon Illusion (SPELL_SUMMON_ILLUSION) is a level 5 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_ILLUSION",
    numeric_id = 179,
    status = "defined",
    name = "Summon Illusion",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "target",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
