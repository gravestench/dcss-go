-- Marshlight (SPELL_MARSHLIGHT) is a level 4 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MARSHLIGHT",
    numeric_id = 374,
    status = "defined",
    name = "Marshlight",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "selfench",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FOXFIRE",
}

register.definition(categories.SPELLS, definition)

return definition
