-- Yara's Violent Unravelling (SPELL_VIOLENT_UNRAVELLING) is a level 5 spell
-- in hexes, transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VIOLENT_UNRAVELLING",
    numeric_id = 331,
    status = "defined",
    name = "Yara's Violent Unravelling",
    schools = {
        "hexes",
        "transmutation",
    },
    flags = {
        "target",
        "no_ghost",
        "chaotic",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_VIOLENT_UNRAVELLING",
}

register.definition(categories.SPELLS, definition)

return definition
