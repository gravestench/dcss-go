-- Summon Ice Beast (SPELL_SUMMON_ICE_BEAST) is a level 4 spell in ice,
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_ICE_BEAST",
    numeric_id = 58,
    status = "defined",
    name = "Summon Ice Beast",
    schools = {
        "ice",
        "summoning",
    },
    flags = {
        "none",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_ICE_BEAST",
}

register.definition(categories.SPELLS, definition)

return definition
