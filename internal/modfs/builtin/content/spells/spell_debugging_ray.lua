-- Debugging Ray (SPELL_DEBUGGING_RAY) is a level 7 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEBUGGING_RAY",
    numeric_id = 90,
    status = "defined",
    name = "Debugging Ray",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "testing",
    },
    level = 7,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
