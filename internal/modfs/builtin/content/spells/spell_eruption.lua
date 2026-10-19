-- Eruption (SPELL_ERUPTION) is a level 5 spell in conjuration, fire, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ERUPTION",
    numeric_id = 383,
    status = "defined",
    name = "Eruption",
    schools = {
        "conjuration",
        "fire",
        "earth",
    },
    flags = {
        "target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
