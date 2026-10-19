-- Blink Allies Away (SPELL_BLINK_ALLIES_AWAY) is a level 6 spell in
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_ALLIES_AWAY",
    numeric_id = 280,
    status = "defined",
    name = "Blink Allies Away",
    schools = {
        "translocation",
    },
    flags = {
        "area",
        "target",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
