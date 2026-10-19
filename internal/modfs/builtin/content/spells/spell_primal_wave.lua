-- Primal Wave (SPELL_PRIMAL_WAVE) is a level 6 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PRIMAL_WAVE",
    numeric_id = 180,
    status = "defined",
    name = "Primal Wave",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 6,
    effect_noise = 25,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
