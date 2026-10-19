-- Disjunction (SPELL_DISJUNCTION) is a level 8 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISJUNCTION",
    numeric_id = 226,
    status = "defined",
    name = "Disjunction",
    schools = {
        "translocation",
    },
    flags = {
        "escape",
        "utility",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DISJUNCTION",
}

register.definition(categories.SPELLS, definition)

return definition
