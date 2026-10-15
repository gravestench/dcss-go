-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3274
-- Enum line: 501

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_NOXIOUS_BOG",
    numeric_id = 365,
    status = "defined",
    name = "Eringya's Noxious Bog",
    schools = {
        "poison",
        "transmutation",
    },
    flags = {
        "area",
        "no_ghost",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_NOXIOUS_BOG",
}

register.definition(categories.SPELLS, definition)

return definition
