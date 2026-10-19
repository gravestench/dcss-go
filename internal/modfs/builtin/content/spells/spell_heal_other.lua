-- Heal Other (SPELL_HEAL_OTHER) is a level 6 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HEAL_OTHER",
    numeric_id = 194,
    status = "defined",
    name = "Heal Other",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "needs_tracer",
        "utility",
        "not_evil",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HEAL_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
