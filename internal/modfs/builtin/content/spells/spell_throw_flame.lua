-- Throw Flame (SPELL_THROW_FLAME) is a level 2 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THROW_FLAME",
    numeric_id = 20,
    status = "defined",
    name = "Throw Flame",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_THROW_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
