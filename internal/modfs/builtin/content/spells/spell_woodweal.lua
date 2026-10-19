-- Woodweal (SPELL_WOODWEAL) is a level 4 spell in necromancy, transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WOODWEAL",
    numeric_id = 372,
    status = "defined",
    name = "Woodweal",
    schools = {
        "necromancy",
        "transmutation",
    },
    flags = {
        "recovery",
        "helpful",
        "monster",
        "selfench",
        "utility",
        "not_evil",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
