-- Conjure Flame (SPELL_CONJURE_FLAME) is a level 3 spell in conjuration,
-- fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONJURE_FLAME",
    numeric_id = 8,
    status = "defined",
    name = "Conjure Flame",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "neutral",
        "no_ghost",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 2,
    tile_id = "TILEG_CONJURE_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
