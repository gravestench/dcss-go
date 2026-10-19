-- Sting (SPELL_STING) is a level 1 spell in transmutation, poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STING",
    numeric_id = 70,
    status = "defined",
    name = "Sting",
    schools = {
        "transmutation",
        "poison",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_STING",
}

register.definition(categories.SPELLS, definition)

return definition
