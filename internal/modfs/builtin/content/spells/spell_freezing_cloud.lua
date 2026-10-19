-- Freezing Cloud (SPELL_FREEZING_CLOUD) is a level 5 spell in conjuration,
-- ice, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FREEZING_CLOUD",
    numeric_id = 23,
    status = "defined",
    name = "Freezing Cloud",
    schools = {
        "conjuration",
        "ice",
        "air",
    },
    flags = {
        "target",
        "area",
        "needs_tracer",
        "cloud",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 2,
    tile_id = "TILEG_FREEZING_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
