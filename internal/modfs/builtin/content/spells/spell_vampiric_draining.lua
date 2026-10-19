-- Vampiric Draining (SPELL_VAMPIRIC_DRAINING) is a level 3 spell in
-- necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VAMPIRIC_DRAINING",
    numeric_id = 51,
    status = "defined",
    name = "Vampiric Draining",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_VAMPIRIC_DRAINING",
}

register.definition(categories.SPELLS, definition)

return definition
