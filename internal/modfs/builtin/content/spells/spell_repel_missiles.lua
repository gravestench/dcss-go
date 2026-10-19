-- Repel Missiles (SPELL_REPEL_MISSILES) is a level 2 spell in air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_REPEL_MISSILES",
    numeric_id = 61,
    status = "defined",
    name = "Repel Missiles",
    schools = {
        "air",
    },
    flags = {
        "monster",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_REPEL_MISSILES",
}

register.definition(categories.SPELLS, definition)

return definition
