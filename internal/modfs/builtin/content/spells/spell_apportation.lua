-- Apportation (SPELL_APPORTATION) is a level 1 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_APPORTATION",
    numeric_id = 5,
    status = "defined",
    name = "Apportation",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "obj",
        "not_self",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_APPORTATION",
}

register.definition(categories.SPELLS, definition)

return definition
