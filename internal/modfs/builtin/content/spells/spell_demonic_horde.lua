-- Demonic Horde (SPELL_DEMONIC_HORDE) is retained as a removed source spell ID.
-- Its historical fields do not register a cast effect or targeting action.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEMONIC_HORDE",
    numeric_id = 75,
    status = "removed",
    name = "Demonic Horde",
    schools = {
        "none",
    },
    flags = {
        "none",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_ERROR",
}

register.definition(categories.SPELLS, definition)

return definition
