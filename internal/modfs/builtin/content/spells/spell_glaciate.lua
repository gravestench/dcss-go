-- Glaciate (SPELL_GLACIATE) is a level 9 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GLACIATE",
    numeric_id = 104,
    status = "defined",
    name = "Glaciate",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "area",
        "not_self",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 9,
    effect_noise = 25,
    tile_id = "TILEG_ICE_STORM",
}

register.definition(categories.SPELLS, definition)

return definition
