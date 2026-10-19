-- Summon Lightning Spire (SPELL_SUMMON_LIGHTNING_SPIRE) is a level 4 spell in
-- summoning, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_LIGHTNING_SPIRE",
    numeric_id = 285,
    status = "defined",
    name = "Summon Lightning Spire",
    schools = {
        "summoning",
        "air",
    },
    flags = {
        "none",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_LIGHTNING_SPIRE",
}

register.definition(categories.SPELLS, definition)

return definition
