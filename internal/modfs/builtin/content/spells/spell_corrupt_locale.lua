-- Corrupt (SPELL_CORRUPT_LOCALE) is a level 7 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CORRUPT_LOCALE",
    numeric_id = 388,
    status = "defined",
    name = "Corrupt",
    schools = {
        "translocation",
    },
    flags = {
        "monster",
        "area",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
