-- Simulacrum (SPELL_SIMULACRUM) is a level 6 spell in ice, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SIMULACRUM",
    numeric_id = 132,
    status = "defined",
    name = "Simulacrum",
    schools = {
        "ice",
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SIMULACRUM",
}

register.definition(categories.SPELLS, definition)

return definition
