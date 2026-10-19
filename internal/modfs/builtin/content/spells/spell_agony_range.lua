-- Agony Range (SPELL_AGONY_RANGE) is a level 5 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AGONY_RANGE",
    numeric_id = 366,
    status = "defined",
    name = "Agony Range",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "monster",
        "WL_check",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_AGONY",
}

register.definition(categories.SPELLS, definition)

return definition
