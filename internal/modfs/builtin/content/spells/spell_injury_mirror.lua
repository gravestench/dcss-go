-- Injury Mirror (SPELL_INJURY_MIRROR) is a level 4 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INJURY_MIRROR",
    numeric_id = 200,
    status = "defined",
    name = "Injury Mirror",
    schools = {
        "none",
    },
    flags = {
        "dir_or_target",
        "helpful",
        "selfench",
        "utility",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_INJURY_MIRROR",
}

register.definition(categories.SPELLS, definition)

return definition
