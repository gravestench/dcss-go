-- Summon Holies (SPELL_SUMMON_HOLIES) is a level 5 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_HOLIES",
    numeric_id = 193,
    status = "defined",
    name = "Summon Holies",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "mons_abjure",
        "holy",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
