-- Iskenderun's Battlesphere (SPELL_BATTLESPHERE) is a level 5 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BATTLESPHERE",
    numeric_id = 230,
    status = "defined",
    name = "Iskenderun's Battlesphere",
    schools = {
        "conjuration",
    },
    flags = {
        "utility",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_BATTLESPHERE",
}

register.definition(categories.SPELLS, definition)

return definition
