-- Stone Arrow (SPELL_STONE_ARROW) is a level 3 spell in conjuration, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STONE_ARROW",
    numeric_id = 82,
    status = "defined",
    name = "Stone Arrow",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_STONE_ARROW",
}

register.definition(categories.SPELLS, definition)

return definition
