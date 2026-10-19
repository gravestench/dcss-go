-- Lightning Bolt (SPELL_LIGHTNING_BOLT) is a level 5 spell in conjuration,
-- air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LIGHTNING_BOLT",
    numeric_id = 12,
    status = "defined",
    name = "Lightning Bolt",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    -- Power scales the source 4..11 range, then the range policy clamps it to LOS.
    min_range_expr = "4",
    max_range_expr = "11",
    noise = 5,
    effect_noise = 25,
    tile_id = "TILEG_LIGHTNING_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
