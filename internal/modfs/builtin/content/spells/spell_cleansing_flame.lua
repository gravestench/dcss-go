-- Cleansing Flame (SPELL_CLEANSING_FLAME) is a level 8 spell in none.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CLEANSING_FLAME",
    numeric_id = 323,
    status = "defined",
    name = "Cleansing Flame",
    schools = {
        "none",
    },
    flags = {
        "area",
        "monster",
        "holy",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 20,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
