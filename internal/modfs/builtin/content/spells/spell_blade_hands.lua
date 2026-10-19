-- Blade Hands (SPELL_BLADE_HANDS) is a level 5 spell in transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLADE_HANDS",
    numeric_id = 95,
    status = "defined",
    name = "Blade Hands",
    schools = {
        "transmutation",
    },
    flags = {
        "helpful",
        "chaotic",
        "utility",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_BLADE_HANDS",
}

register.definition(categories.SPELLS, definition)

return definition
