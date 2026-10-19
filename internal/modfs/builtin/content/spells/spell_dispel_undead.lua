-- Dispel Undead (SPELL_DISPEL_UNDEAD) is a level 4 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISPEL_UNDEAD",
    numeric_id = 63,
    status = "defined",
    name = "Dispel Undead",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_DISPEL_UNDEAD",
}

register.definition(categories.SPELLS, definition)

return definition
