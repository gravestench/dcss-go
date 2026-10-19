-- Irradiate (SPELL_IRRADIATE) is a level 5 spell in conjuration,
-- transmutation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_IRRADIATE",
    numeric_id = 300,
    status = "defined",
    name = "Irradiate",
    schools = {
        "conjuration",
        "transmutation",
    },
    flags = {
        "area",
        "chaotic",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_IRRADIATE",
}

register.definition(categories.SPELLS, definition)

return definition
