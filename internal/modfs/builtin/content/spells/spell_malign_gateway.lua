-- Malign Gateway (SPELL_MALIGN_GATEWAY) is a level 7 spell in summoning,
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MALIGN_GATEWAY",
    numeric_id = 206,
    status = "defined",
    name = "Malign Gateway",
    schools = {
        "summoning",
        "translocation",
    },
    flags = {
        "unholy",
        "chaotic",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_MALIGN_GATEWAY",
}

register.definition(categories.SPELLS, definition)

return definition
