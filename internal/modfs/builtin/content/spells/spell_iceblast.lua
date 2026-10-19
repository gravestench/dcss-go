-- Iceblast (SPELL_ICEBLAST) is a level 5 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ICEBLAST",
    numeric_id = 335,
    status = "defined",
    name = "Iceblast",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_ICEBLAST",
}

register.definition(categories.SPELLS, definition)

return definition
