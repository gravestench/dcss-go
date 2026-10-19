-- Animate Armour (SPELL_ANIMATE_ARMOUR) is a level 4 spell in summoning,
-- earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANIMATE_ARMOUR",
    numeric_id = 377,
    status = "defined",
    name = "Animate Armour",
    schools = {
        "summoning",
        "earth",
    },
    flags = {
        "none",
    },
    level = 4,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_ANIMATE_ARMOUR",
}

register.definition(categories.SPELLS, definition)

return definition
