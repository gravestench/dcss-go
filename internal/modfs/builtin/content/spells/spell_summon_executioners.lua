-- Summon Executioners (SPELL_SUMMON_EXECUTIONERS) is a level 9 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_EXECUTIONERS",
    numeric_id = 330,
    status = "defined",
    name = "Summon Executioners",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "mons_abjure",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
