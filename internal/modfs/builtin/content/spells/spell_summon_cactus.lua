-- Summon Cactus Giant (SPELL_SUMMON_CACTUS) is a level 6 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_CACTUS",
    numeric_id = 389,
    status = "defined",
    name = "Summon Cactus Giant",
    schools = {
        "summoning",
    },
    flags = {
        "none",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_CACTUS_GIANT",
}

register.definition(categories.SPELLS, definition)

return definition
