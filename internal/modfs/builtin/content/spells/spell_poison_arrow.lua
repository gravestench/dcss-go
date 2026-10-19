-- Poison Arrow (SPELL_POISON_ARROW) is a level 6 spell in conjuration,
-- poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POISON_ARROW",
    numeric_id = 65,
    status = "defined",
    name = "Poison Arrow",
    schools = {
        "conjuration",
        "poison",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_POISON_ARROW",
}

register.definition(categories.SPELLS, definition)

return definition
