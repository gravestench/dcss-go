-- Throw Ally (SPELL_THROW_ALLY) is a level 2 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THROW_ALLY",
    numeric_id = 324,
    status = "defined",
    name = "Throw Ally",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "monster",
        "not_self",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 5,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
