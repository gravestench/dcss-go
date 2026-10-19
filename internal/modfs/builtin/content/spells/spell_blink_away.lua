-- Blink Away (SPELL_BLINK_AWAY) is a level 2 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLINK_AWAY",
    numeric_id = 175,
    status = "defined",
    name = "Blink Away",
    schools = {
        "translocation",
    },
    flags = {
        "escape",
        "monster",
        "selfench",
    },
    level = 2,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BLINK",
}

register.definition(categories.SPELLS, definition)

return definition
