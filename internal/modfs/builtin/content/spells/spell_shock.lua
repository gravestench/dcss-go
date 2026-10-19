-- Shock (SPELL_SHOCK) is a level 1 spell in conjuration, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHOCK",
    numeric_id = 83,
    status = "defined",
    name = "Shock",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_SHOCK",
}

register.definition(categories.SPELLS, definition)

return definition
