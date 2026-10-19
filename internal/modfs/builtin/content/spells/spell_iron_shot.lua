-- Iron Shot (SPELL_IRON_SHOT) is a level 6 spell in conjuration, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IRON_SHOT",
    numeric_id = 81,
    status = "defined",
    name = "Iron Shot",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_IRON_SHOT",
}

register.definition(categories.SPELLS, definition)

return definition
