-- Force Lance (SPELL_FORCE_LANCE) is a level 4 spell in conjuration,
-- translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FORCE_LANCE",
    numeric_id = 233,
    status = "defined",
    name = "Force Lance",
    schools = {
        "conjuration",
        "translocation",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_FORCE_LANCE",
}

register.definition(categories.SPELLS, definition)

return definition
