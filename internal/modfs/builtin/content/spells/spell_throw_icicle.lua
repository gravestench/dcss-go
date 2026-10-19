-- Throw Icicle (SPELL_THROW_ICICLE) is a level 4 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THROW_ICICLE",
    numeric_id = 103,
    status = "defined",
    name = "Throw Icicle",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_THROW_ICICLE",
}

register.definition(categories.SPELLS, definition)

return definition
