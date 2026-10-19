-- Stunning Burst (SPELL_STUNNING_BURST) is a level 4 spell in conjuration,
-- air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STUNNING_BURST",
    numeric_id = 387,
    status = "defined",
    name = "Stunning Burst",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 8,
    effect_noise = 8,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
