-- Bolt of Magma (SPELL_BOLT_OF_MAGMA) is a level 5 spell in conjuration,
-- fire, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_MAGMA",
    numeric_id = 13,
    status = "defined",
    name = "Bolt of Magma",
    schools = {
        "conjuration",
        "fire",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_BOLT_OF_MAGMA",
}

register.definition(categories.SPELLS, definition)

return definition
