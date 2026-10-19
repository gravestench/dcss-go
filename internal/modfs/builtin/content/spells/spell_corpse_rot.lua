-- Corpse Rot (SPELL_CORPSE_ROT) is a level 4 spell in necromancy, air,
-- poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORPSE_ROT",
    numeric_id = 77,
    status = "defined",
    name = "Corpse Rot",
    schools = {
        "necromancy",
        "air",
        "poison",
    },
    flags = {
        "helpful",
        "utility",
        "selfench",
        "unclean",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_CORPSE_ROT",
}

register.definition(categories.SPELLS, definition)

return definition
