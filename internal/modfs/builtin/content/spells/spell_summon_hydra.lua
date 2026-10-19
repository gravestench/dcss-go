-- Summon Hydra (SPELL_SUMMON_HYDRA) is a level 7 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HYDRA",
    numeric_id = 212,
    status = "defined",
    name = "Summon Hydra",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_HYDRA",
}

register.definition(categories.SPELLS, definition)

return definition
