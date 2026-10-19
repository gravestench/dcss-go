-- Call Lost Soul (SPELL_CALL_LOST_SOUL) is a level 5 spell in summoning,
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_LOST_SOUL",
    numeric_id = 241,
    status = "defined",
    name = "Call Lost Soul",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "unholy",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
