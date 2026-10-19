-- nonexistent spell (SPELL_NO_SPELL) is retained as a sentinel source spell ID.
-- Its historical fields do not register a cast effect or targeting action.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NO_SPELL",
    numeric_id = 0,
    status = "sentinel",
    name = "nonexistent spell",
    schools = {
        "none",
    },
    flags = {
        "testing",
    },
    level = 1,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_ERROR",
}

register.definition(categories.SPELLS, definition)

return definition
