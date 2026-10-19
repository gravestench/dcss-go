-- dis serpent of hell breath (SPELL_SERPENT_OF_HELL_DIS_BREATH) is a level 5
-- spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SERPENT_OF_HELL_DIS_BREATH",
    numeric_id = 342,
    status = "defined",
    name = "dis serpent of hell breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
