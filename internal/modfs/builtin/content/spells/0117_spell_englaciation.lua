-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1100
-- Enum line: 166

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ENGLACIATION",
    numeric_id = 116,
    status = "defined",
    name = "Metabolic Englaciation",
    schools = {
        "hexes",
        "ice",
    },
    flags = {
        "area",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_METABOLIC_ENGLACIATION",
}

register.definition(categories.SPELLS, definition)

return definition
