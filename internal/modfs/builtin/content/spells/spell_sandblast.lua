-- Sandblast (SPELL_SANDBLAST) is a level 1 spell in earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SANDBLAST",
    numeric_id = 129,
    status = "defined",
    name = "Sandblast",
    schools = {
        "earth",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_SANDBLAST",
}

register.definition(categories.SPELLS, definition)

return definition
