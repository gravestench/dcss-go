-- Summon Forest (SPELL_SUMMON_FOREST) is a level 5 spell in summoning,
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_FOREST",
    numeric_id = 284,
    status = "defined",
    name = "Summon Forest",
    schools = {
        "summoning",
        "translocation",
    },
    flags = {
        "none",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 10,
    tile_id = "TILEG_SUMMON_FOREST",
}

register.definition(categories.SPELLS, definition)

return definition
