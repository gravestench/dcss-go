-- Holy Flames (SPELL_HOLY_FLAMES) is a level 7 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HOLY_FLAMES",
    numeric_id = 196,
    status = "defined",
    name = "Holy Flames",
    schools = {
        "none",
    },
    flags = {
        "target",
        "not_self",
        "holy",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
