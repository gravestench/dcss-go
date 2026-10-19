-- Ink Cloud (SPELL_INK_CLOUD) is a level 7 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INK_CLOUD",
    numeric_id = 183,
    status = "defined",
    name = "Ink Cloud",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "monster",
        "escape",
        "utility",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_INK_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
