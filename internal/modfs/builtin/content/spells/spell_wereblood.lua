-- Wereblood (SPELL_WEREBLOOD) is a level 2 spell in transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_WEREBLOOD",
    numeric_id = 253,
    status = "defined",
    name = "Wereblood",
    schools = {
        "transmutation",
    },
    flags = {
        "utility",
        "chaotic",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 8,
    tile_id = "TILEG_WEREBLOOD",
}

register.definition(categories.SPELLS, definition)

return definition
