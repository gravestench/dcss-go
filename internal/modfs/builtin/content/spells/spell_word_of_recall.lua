-- Word of Recall (SPELL_WORD_OF_RECALL) is a level 3 spell in summoning,
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WORD_OF_RECALL",
    numeric_id = 237,
    status = "defined",
    name = "Word of Recall",
    schools = {
        "summoning",
        "translocation",
    },
    flags = {
        "utility",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_RECALL",
}

register.definition(categories.SPELLS, definition)

return definition
