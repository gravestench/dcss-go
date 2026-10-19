-- Eringya's Noxious Bog (SPELL_NOXIOUS_BOG) is a level 6 spell in poison,
-- transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NOXIOUS_BOG",
    numeric_id = 365,
    status = "defined",
    name = "Eringya's Noxious Bog",
    schools = {
        "poison",
        "transmutation",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_NOXIOUS_BOG",
}

register.definition(categories.SPELLS, definition)

return definition
