-- Hunting Call (SPELL_HUNTING_CALL) is a level 6 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HUNTING_CALL",
    numeric_id = 401,
    status = "defined",
    name = "Hunting Call",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "monster",
        "selfench",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
