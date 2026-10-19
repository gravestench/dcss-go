-- Frozen Ramparts (SPELL_FROZEN_RAMPARTS) is a level 3 spell in ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FROZEN_RAMPARTS",
    numeric_id = 368,
    status = "defined",
    name = "Frozen Ramparts",
    schools = {
        "ice",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "2",
    max_range_expr = "2",
    noise = 3,
    effect_noise = 8,
    tile_id = "TILEG_FROZEN_RAMPARTS",
}

register.definition(categories.SPELLS, definition)

return definition
