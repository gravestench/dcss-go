-- Searing Ray (SPELL_SEARING_RAY) is a level 2 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SEARING_RAY",
    numeric_id = 258,
    status = "defined",
    name = "Searing Ray",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SEARING_RAY",
}

register.definition(categories.SPELLS, definition)

return definition
