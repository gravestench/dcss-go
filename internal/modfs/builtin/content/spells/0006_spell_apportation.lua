-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:62
-- Enum line: 18

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_APPORTATION",
    numeric_id = 5,
    status = "defined",
    name = "Apportation",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "obj",
        "not_self",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_APPORTATION",
}

register.definition(categories.SPELLS, definition)

return definition
