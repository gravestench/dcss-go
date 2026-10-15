-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3219
-- Enum line: 497

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPORULATE",
    numeric_id = 361,
    status = "defined",
    name = "Sporulate",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SPORULATE",
}

register.definition(categories.SPELLS, definition)

return definition
