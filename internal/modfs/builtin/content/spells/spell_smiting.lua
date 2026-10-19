-- Smiting (SPELL_SMITING) is a level 4 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SMITING",
    numeric_id = 33,
    status = "defined",
    name = "Smiting",
    schools = {
        "none",
    },
    flags = {
        "target",
        "not_self",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SMITING",
}

register.definition(categories.SPELLS, definition)

return definition
