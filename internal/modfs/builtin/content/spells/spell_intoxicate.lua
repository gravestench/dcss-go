-- Alistair's Intoxication (SPELL_INTOXICATE) is a level 5 spell in
-- transmutation, poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INTOXICATE",
    numeric_id = 126,
    status = "defined",
    name = "Alistair's Intoxication",
    schools = {
        "transmutation",
        "poison",
    },
    flags = {
        "none",
    },
    level = 5,
    power_cap = 150,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_ALISTAIRS_INTOXICATION",
}

register.definition(categories.SPELLS, definition)

return definition
