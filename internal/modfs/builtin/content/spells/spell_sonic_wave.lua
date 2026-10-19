-- Sonic wave (SPELL_SONIC_WAVE) is a level 7 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SONIC_WAVE",
    numeric_id = 359,
    status = "defined",
    name = "Sonic wave",
    schools = {
        "none",
    },
    flags = {
        "noisy",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_ERROR",
}

register.definition(categories.SPELLS, definition)

return definition
