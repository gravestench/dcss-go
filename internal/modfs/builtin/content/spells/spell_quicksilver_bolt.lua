-- Quicksilver Bolt (SPELL_QUICKSILVER_BOLT) is a level 5 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_QUICKSILVER_BOLT",
    numeric_id = 151,
    status = "defined",
    name = "Quicksilver Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_QUICKSILVER_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
