-- Ignite Poison (SPELL_IGNITE_POISON) is a level 3 spell in fire,
-- transmutation, poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IGNITE_POISON",
    numeric_id = 111,
    status = "defined",
    name = "Ignite Poison",
    schools = {
        "fire",
        "transmutation",
        "poison",
    },
    flags = {
        "area",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_IGNITE_POISON",
}

register.definition(categories.SPELLS, definition)

return definition
