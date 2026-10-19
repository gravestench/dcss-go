-- Chain Lightning (SPELL_CHAIN_LIGHTNING) is a level 9 spell in air,
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHAIN_LIGHTNING",
    numeric_id = 134,
    status = "defined",
    name = "Chain Lightning",
    schools = {
        "air",
        "conjuration",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 25,
    effect_noise = 10,
    tile_id = "TILEG_CHAIN_LIGHTNING",
}

register.definition(categories.SPELLS, definition)

return definition
