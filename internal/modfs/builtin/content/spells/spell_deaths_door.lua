-- Death's Door (SPELL_DEATHS_DOOR) is a level 9 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEATHS_DOOR",
    numeric_id = 31,
    status = "defined",
    name = "Death's Door",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
        "no_ghost",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DEATHS_DOOR",
}

register.definition(categories.SPELLS, definition)

return definition
