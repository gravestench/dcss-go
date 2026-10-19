-- Stoke Flames (SPELL_STOKE_FLAMES) is a level 8 spell in fire, conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STOKE_FLAMES",
    numeric_id = 390,
    status = "defined",
    name = "Stoke Flames",
    schools = {
        "fire",
        "conjuration",
    },
    flags = {
        "monster",
    },
    level = 8,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
