-- Symbol of Torment (SPELL_SYMBOL_OF_TORMENT) is a level 6 spell in
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SYMBOL_OF_TORMENT",
    numeric_id = 101,
    status = "defined",
    name = "Symbol of Torment",
    schools = {
        "necromancy",
    },
    flags = {
        "area",
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SYMBOL_OF_TORMENT",
}

register.definition(categories.SPELLS, definition)

return definition
