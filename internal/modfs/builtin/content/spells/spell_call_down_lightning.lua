-- Call Down Lightning (SPELL_CALL_DOWN_LIGHTNING) is a level 4 spell in
-- conjuration, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_DOWN_LIGHTNING",
    numeric_id = 380,
    status = "defined",
    name = "Call Down Lightning",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "target",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
