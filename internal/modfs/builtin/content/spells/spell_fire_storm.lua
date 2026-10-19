-- Fire Storm (SPELL_FIRE_STORM) is a level 9 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FIRE_STORM",
    numeric_id = 41,
    status = "defined",
    name = "Fire Storm",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "target",
        "area",
        "needs_tracer",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 9,
    effect_noise = 0,
    tile_id = "TILEG_FIRE_STORM",
}

register.definition(categories.SPELLS, definition)

return definition
