-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1044
-- Enum line: 158

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PASSWALL",
    numeric_id = 110,
    status = "defined",
    name = "Passwall",
    schools = {
        "transmutation",
        "earth",
    },
    flags = {
        "target",
        "escape",
        "not_self",
        "utility",
    },
    level = 2,
    power_cap = 120,
    min_range_expr = "1",
    max_range_expr = "7",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_PASSWALL",
}

register.definition(categories.SPELLS, definition)

return definition
