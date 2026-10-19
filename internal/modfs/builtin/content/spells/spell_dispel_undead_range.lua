-- Dispel Undead Range (SPELL_DISPEL_UNDEAD_RANGE) is a level 5 spell in
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISPEL_UNDEAD_RANGE",
    numeric_id = 367,
    status = "defined",
    name = "Dispel Undead Range",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_DISPEL_UNDEAD",
}

register.definition(categories.SPELLS, definition)

return definition
