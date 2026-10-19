-- Aura of Brilliance (SPELL_AURA_OF_BRILLIANCE) is a level 5 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AURA_OF_BRILLIANCE",
    numeric_id = 334,
    status = "defined",
    name = "Aura of Brilliance",
    schools = {
        "conjuration",
    },
    flags = {
        "area",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
