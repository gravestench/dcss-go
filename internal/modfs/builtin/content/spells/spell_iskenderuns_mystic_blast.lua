-- Iskenderun's Mystic Blast (SPELL_ISKENDERUNS_MYSTIC_BLAST) is a level 4
-- spell in conjuration, translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ISKENDERUNS_MYSTIC_BLAST",
    numeric_id = 43,
    status = "defined",
    name = "Iskenderun's Mystic Blast",
    schools = {
        "conjuration",
        "translocation",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "2",
    max_range_expr = "2",
    noise = 4,
    effect_noise = 10,
    tile_id = "TILEG_ISKENDERUNS_MYSTIC_BLAST",
}

register.definition(categories.SPELLS, definition)

return definition
