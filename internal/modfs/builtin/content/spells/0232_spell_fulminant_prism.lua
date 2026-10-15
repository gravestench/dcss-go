-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1266
-- Enum line: 325

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FULMINANT_PRISM",
    numeric_id = 231,
    status = "defined",
    name = "Fulminant Prism",
    schools = {
        "conjuration",
        "hexes",
    },
    flags = {
        "target",
        "area",
        "not_self",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_FULMINANT_PRISM",
}

register.definition(categories.SPELLS, definition)

return definition
