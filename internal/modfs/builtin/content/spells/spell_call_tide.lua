-- Call Tide (SPELL_CALL_TIDE) is a level 7 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_TIDE",
    numeric_id = 181,
    status = "defined",
    name = "Call Tide",
    schools = {
        "translocation",
    },
    flags = {
        "monster",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
