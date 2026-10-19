-- Brothers in Arms (SPELL_BROTHERS_IN_ARMS) is a level 6 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BROTHERS_IN_ARMS",
    numeric_id = 199,
    status = "defined",
    name = "Brothers in Arms",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_BROTHERS_IN_ARMS",
}

register.definition(categories.SPELLS, definition)

return definition
