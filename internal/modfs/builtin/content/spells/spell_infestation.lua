-- Infestation (SPELL_INFESTATION) is a level 8 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INFESTATION",
    numeric_id = 344,
    status = "defined",
    name = "Infestation",
    schools = {
        "necromancy",
    },
    flags = {
        "target",
        "unclean",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 8,
    effect_noise = 4,
    tile_id = "TILEG_INFESTATION",
}

register.definition(categories.SPELLS, definition)

return definition
