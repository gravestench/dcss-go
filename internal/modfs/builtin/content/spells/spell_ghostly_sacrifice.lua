-- Ghostly Sacrifice (SPELL_GHOSTLY_SACRIFICE) is a level 7 spell in
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GHOSTLY_SACRIFICE",
    numeric_id = 347,
    status = "defined",
    name = "Ghostly Sacrifice",
    schools = {
        "necromancy",
    },
    flags = {
        "target",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
