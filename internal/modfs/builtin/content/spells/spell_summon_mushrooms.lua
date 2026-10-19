-- Summon Mushrooms (SPELL_SUMMON_MUSHROOMS) is a level 4 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_MUSHROOMS",
    numeric_id = 156,
    status = "defined",
    name = "Summon Mushrooms",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "selfench",
        "mons_abjure",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_MUSHROOMS",
}

register.definition(categories.SPELLS, definition)

return definition
