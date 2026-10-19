-- Noxious Cloud (SPELL_NOXIOUS_CLOUD) is a level 5 spell in conjuration,
-- poison, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NOXIOUS_CLOUD",
    numeric_id = 207,
    status = "defined",
    name = "Noxious Cloud",
    schools = {
        "conjuration",
        "poison",
        "air",
    },
    flags = {
        "target",
        "area",
        "monster",
        "needs_tracer",
        "cloud",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_NOXIOUS_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
