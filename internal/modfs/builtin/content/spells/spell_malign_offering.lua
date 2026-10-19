-- Malign Offering (SPELL_MALIGN_OFFERING) is a level 5 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MALIGN_OFFERING",
    numeric_id = 257,
    status = "defined",
    name = "Malign Offering",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 10,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
