-- Roll (SPELL_ROLL) is a level 5 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ROLL",
    numeric_id = 370,
    status = "defined",
    name = "Roll",
    schools = {
        "earth",
    },
    flags = {
        "monster",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
