-- Major Destruction (SPELL_MAJOR_DESTRUCTION) is a level 7 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MAJOR_DESTRUCTION",
    numeric_id = 279,
    status = "defined",
    name = "Major Destruction",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "chaotic",
        "needs_tracer",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_MAJOR_DESTRUCTION",
}

register.definition(categories.SPELLS, definition)

return definition
