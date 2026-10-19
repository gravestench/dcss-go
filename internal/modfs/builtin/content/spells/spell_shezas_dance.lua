-- Sheza's Dance (SPELL_SHEZAS_DANCE) is a level 5 spell in summoning, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHEZAS_DANCE",
    numeric_id = 398,
    status = "defined",
    name = "Sheza's Dance",
    schools = {
        "summoning",
        "earth",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
