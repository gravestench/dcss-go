-- Throw Frost (SPELL_THROW_FROST) is a level 2 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THROW_FROST",
    numeric_id = 21,
    status = "defined",
    name = "Throw Frost",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_THROW_FROST",
}

register.definition(categories.SPELLS, definition)

return definition
