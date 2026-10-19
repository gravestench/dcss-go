-- Borgnjor's Revivification (SPELL_BORGNJORS_REVIVIFICATION) is a level 8
-- spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BORGNJORS_REVIVIFICATION",
    numeric_id = 53,
    status = "defined",
    name = "Borgnjor's Revivification",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_BORGNJORS_REVIVIFICATION",
}

register.definition(categories.SPELLS, definition)

return definition
