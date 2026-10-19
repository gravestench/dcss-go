-- Sublimation of Blood (SPELL_SUBLIMATION_OF_BLOOD) is a level 2 spell in
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUBLIMATION_OF_BLOOD",
    numeric_id = 71,
    status = "defined",
    name = "Sublimation of Blood",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUBLIMATION_OF_BLOOD",
}

register.definition(categories.SPELLS, definition)

return definition
