-- Foxfire (SPELL_FOXFIRE) is a level 1 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FOXFIRE",
    numeric_id = 363,
    status = "defined",
    name = "Foxfire",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "selfench",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FOXFIRE",
}

register.definition(categories.SPELLS, definition)

return definition
