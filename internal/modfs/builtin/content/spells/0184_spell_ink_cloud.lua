-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1782
-- Enum line: 255

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
