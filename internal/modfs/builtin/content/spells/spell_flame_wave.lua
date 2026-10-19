-- Flame Wave (SPELL_FLAME_WAVE) is a level 4 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLAME_WAVE",
    numeric_id = 393,
    status = "defined",
    name = "Flame Wave",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 0,
    effect_noise = 12,
    tile_id = "TILEG_FLAME_WAVE",
}

register.definition(categories.SPELLS, definition)

return definition
