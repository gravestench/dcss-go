-- Pain (SPELL_PAIN) is a level 1 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PAIN",
    numeric_id = 48,
    status = "defined",
    name = "Pain",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_PAIN",
}

register.definition(categories.SPELLS, definition)

return definition
