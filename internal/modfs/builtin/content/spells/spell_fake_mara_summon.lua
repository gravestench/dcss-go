-- Mara Summon (SPELL_FAKE_MARA_SUMMON) is a level 5 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FAKE_MARA_SUMMON",
    numeric_id = 177,
    status = "defined",
    name = "Mara Summon",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_FAKE_MARA_SUMMON",
}

register.definition(categories.SPELLS, definition)

return definition
