-- Death Channel (SPELL_DEATH_CHANNEL) is a level 6 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEATH_CHANNEL",
    numeric_id = 100,
    status = "defined",
    name = "Death Channel",
    schools = {
        "necromancy",
    },
    flags = {
        "helpful",
        "utility",
        "selfench",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_DEATH_CHANNEL",
}

register.definition(categories.SPELLS, definition)

return definition
