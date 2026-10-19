-- Ignition (SPELL_IGNITION) is a level 8 spell in fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IGNITION",
    numeric_id = 354,
    status = "defined",
    name = "Ignition",
    schools = {
        "fire",
    },
    flags = {
        "area",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_IGNITION",
}

register.definition(categories.SPELLS, definition)

return definition
