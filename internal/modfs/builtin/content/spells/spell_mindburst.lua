-- Mindburst (SPELL_MINDBURST) is a level 6 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MINDBURST",
    numeric_id = 94,
    status = "defined",
    name = "Mindburst",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
