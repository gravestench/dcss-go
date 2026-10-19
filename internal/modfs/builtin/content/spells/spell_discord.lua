-- Discord (SPELL_DISCORD) is a level 8 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISCORD",
    numeric_id = 259,
    status = "defined",
    name = "Discord",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "hasty",
        "WL_check",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DISCORD",
}

register.definition(categories.SPELLS, definition)

return definition
