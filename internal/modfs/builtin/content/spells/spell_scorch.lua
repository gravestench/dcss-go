-- Scorch (SPELL_SCORCH) is a level 2 spell in fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SCORCH",
    numeric_id = 392,
    status = "defined",
    name = "Scorch",
    schools = {
        "fire",
    },
    flags = {
        "no_ghost",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 4,
    effect_noise = 8,
    tile_id = "TILEG_SCORCH",
}

register.definition(categories.SPELLS, definition)

return definition
