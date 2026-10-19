-- Greater Servant of Makhleb (SPELL_GREATER_SERVANT_MAKHLEB) is a level 7
-- spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GREATER_SERVANT_MAKHLEB",
    numeric_id = 338,
    status = "defined",
    name = "Greater Servant of Makhleb",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_ABILITY_MAKHLEB_GREATER_SERVANT",
}

register.definition(categories.SPELLS, definition)

return definition
