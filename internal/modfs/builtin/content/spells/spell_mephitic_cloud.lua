-- Mephitic Cloud (SPELL_MEPHITIC_CLOUD) is a level 3 spell in conjuration,
-- poison, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MEPHITIC_CLOUD",
    numeric_id = 24,
    status = "defined",
    name = "Mephitic Cloud",
    schools = {
        "conjuration",
        "poison",
        "air",
    },
    flags = {
        "dir_or_target",
        "area",
        "needs_tracer",
        "cloud",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_MEPHITIC_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
