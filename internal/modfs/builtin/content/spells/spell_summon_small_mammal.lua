-- Summon Small Mammal (SPELL_SUMMON_SMALL_MAMMAL) is a level 1 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_SMALL_MAMMAL",
    numeric_id = 34,
    status = "defined",
    name = "Summon Small Mammal",
    schools = {
        "summoning",
    },
    -- The `none` flag and -1 range leave placement to the summon effect;
    -- this record supplies cost and power metadata for that effect.
    flags = {
        "none",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SMALL_MAMMAL",
}

register.definition(categories.SPELLS, definition)

return definition
