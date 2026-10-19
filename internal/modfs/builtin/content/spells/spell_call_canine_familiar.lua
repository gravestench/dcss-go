-- Call Canine Familiar (SPELL_CALL_CANINE_FAMILIAR) is a level 3 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_CANINE_FAMILIAR",
    numeric_id = 113,
    status = "defined",
    name = "Call Canine Familiar",
    schools = {
        "summoning",
    },
    flags = {
        "none",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_CALL_CANINE_FAMILIAR",
}

register.definition(categories.SPELLS, definition)

return definition
