-- Spit Poison (SPELL_SPIT_POISON) is a level 2 spell in poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPIT_POISON",
    numeric_id = 148,
    status = "defined",
    name = "Spit Poison",
    schools = {
        "poison",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SPIT_POISON",
}

register.definition(categories.SPELLS, definition)

return definition
