-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2932
-- Enum line: 457

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GRAVITAS",
    numeric_id = 327,
    status = "defined",
    name = "Gell's Gravitas",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "not_self",
        "needs_tracer",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GRAVITAS",
}

register.definition(categories.SPELLS, definition)

return definition
