-- Summon Spectral Orcs (SPELL_SUMMON_SPECTRAL_ORCS) is a level 4 spell in
-- necromancy, summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SPECTRAL_ORCS",
    numeric_id = 189,
    status = "defined",
    name = "Summon Spectral Orcs",
    schools = {
        "necromancy",
        "summoning",
    },
    flags = {
        "monster",
        "target",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SPECTRAL_ORCS",
}

register.definition(categories.SPELLS, definition)

return definition
