-- Summon Fire Elementals (SPELL_FIRE_ELEMENTALS) is a level 5 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FIRE_ELEMENTALS",
    numeric_id = 168,
    status = "defined",
    name = "Summon Fire Elementals",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "mons_abjure",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_FIRE_ELEMENTALS",
}

register.definition(categories.SPELLS, definition)

return definition
