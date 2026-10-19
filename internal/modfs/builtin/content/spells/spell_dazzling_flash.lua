-- Dazzling Flash (SPELL_DAZZLING_FLASH) is a level 3 spell in conjuration,
-- hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DAZZLING_FLASH",
    numeric_id = 232,
    status = "defined",
    name = "Dazzling Flash",
    schools = {
        "conjuration",
        "hexes",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "2",
    max_range_expr = "3",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_DAZZLING_SPRAY",
}

register.definition(categories.SPELLS, definition)

return definition
