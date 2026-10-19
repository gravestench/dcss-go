-- Summon Dragon (SPELL_SUMMON_DRAGON) is a level 9 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_DRAGON",
    numeric_id = 114,
    status = "defined",
    name = "Summon Dragon",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_DRAGON",
}

register.definition(categories.SPELLS, definition)

return definition
