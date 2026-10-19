-- Metal Splinters (SPELL_METAL_SPLINTERS) is a level 5 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_METAL_SPLINTERS",
    numeric_id = 152,
    status = "defined",
    name = "Metal Splinters",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_METAL_SPLINTERS",
}

register.definition(categories.SPELLS, definition)

return definition
