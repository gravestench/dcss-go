-- Summon Hell Sentinel (SPELL_SUMMON_HELL_SENTINEL) is a level 8 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HELL_SENTINEL",
    numeric_id = 376,
    status = "defined",
    name = "Summon Hell Sentinel",
    schools = {
        "summoning",
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
