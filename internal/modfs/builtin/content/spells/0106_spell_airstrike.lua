-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:999
-- Enum line: 151

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AIRSTRIKE",
    numeric_id = 105,
    status = "defined",
    name = "Airstrike",
    schools = {
        "air",
    },
    flags = {
        "target",
        "not_self",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 4,
    tile_id = "TILEG_AIRSTRIKE",
}

register.definition(categories.SPELLS, definition)

return definition
