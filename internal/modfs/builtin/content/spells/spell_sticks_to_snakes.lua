-- Sticks to Snakes (SPELL_STICKS_TO_SNAKES) is retained as a removed source spell ID.
-- Its historical fields do not register a cast effect or targeting action.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STICKS_TO_SNAKES",
    numeric_id = 112,
    status = "removed",
    name = "Sticks to Snakes",
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
