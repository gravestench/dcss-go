-- Animate Dead (SPELL_ANIMATE_DEAD) is a level 4 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANIMATE_DEAD",
    numeric_id = 47,
    status = "defined",
    name = "Animate Dead",
    schools = {
        "necromancy",
    },
    flags = {
        "helpful",
        "utility",
        "selfench",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_ANIMATE_DEAD",
}

register.definition(categories.SPELLS, definition)

return definition
