-- Chain of Chaos (SPELL_CHAIN_OF_CHAOS) is a level 8 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CHAIN_OF_CHAOS",
    numeric_id = 272,
    status = "defined",
    name = "Chain of Chaos",
    schools = {
        "conjuration",
    },
    flags = {
        "area",
        "monster",
        "chaotic",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
