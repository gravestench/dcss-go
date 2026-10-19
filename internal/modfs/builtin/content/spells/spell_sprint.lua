-- Sprint (SPELL_SPRINT) is a level 2 spell in hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPRINT",
    numeric_id = 337,
    status = "defined",
    name = "Sprint",
    schools = {
        "hexes",
    },
    flags = {
        "hasty",
        "selfench",
        "utility",
        "monster",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SPRINT",
}

register.definition(categories.SPELLS, definition)

return definition
