-- Metabolic Englaciation (SPELL_ENGLACIATION) is a level 5 spell in hexes,
-- ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ENGLACIATION",
    numeric_id = 116,
    status = "defined",
    name = "Metabolic Englaciation",
    schools = {
        "hexes",
        "ice",
    },
    flags = {
        "area",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_METABOLIC_ENGLACIATION",
}

register.definition(categories.SPELLS, definition)

return definition
