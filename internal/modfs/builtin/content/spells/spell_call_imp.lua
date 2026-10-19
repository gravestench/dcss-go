-- Call Imp (SPELL_CALL_IMP) is a level 2 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_IMP",
    numeric_id = 60,
    status = "defined",
    name = "Call Imp",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_CALL_IMP",
}

register.definition(categories.SPELLS, definition)

return definition
