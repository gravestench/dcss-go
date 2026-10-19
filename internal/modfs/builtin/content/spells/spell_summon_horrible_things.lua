-- Summon Horrible Things (SPELL_SUMMON_HORRIBLE_THINGS) is a level 8 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HORRIBLE_THINGS",
    numeric_id = 45,
    status = "defined",
    name = "Summon Horrible Things",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "chaotic",
        "mons_abjure",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_HORRIBLE_THINGS",
}

register.definition(categories.SPELLS, definition)

return definition
