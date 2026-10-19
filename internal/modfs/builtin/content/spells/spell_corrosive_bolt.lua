-- Corrosive Bolt (SPELL_CORROSIVE_BOLT) is a level 6 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORROSIVE_BOLT",
    numeric_id = 296,
    status = "defined",
    name = "Corrosive Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_CORROSIVE_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
