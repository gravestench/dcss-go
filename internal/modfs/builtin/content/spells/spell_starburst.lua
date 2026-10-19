-- Starburst (SPELL_STARBURST) is a level 6 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STARBURST",
    numeric_id = 362,
    status = "defined",
    name = "Starburst",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "area",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_STARBURST",
}

register.definition(categories.SPELLS, definition)

return definition
