-- Freeze (SPELL_FREEZE) is a level 1 spell in ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FREEZE",
    numeric_id = 54,
    status = "defined",
    name = "Freeze",
    schools = {
        "ice",
    },
    flags = {
        "dir_or_target",
        "not_self",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FREEZE",
}

register.definition(categories.SPELLS, definition)

return definition
