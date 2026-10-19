-- Spawn Tentacles (SPELL_CREATE_TENTACLES) is a level 5 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CREATE_TENTACLES",
    numeric_id = 164,
    status = "defined",
    name = "Spawn Tentacles",
    schools = {
        "none",
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
    tile_id = "TILEG_CREATE_TENTACLES",
}

register.definition(categories.SPELLS, definition)

return definition
