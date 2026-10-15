-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3131
-- Enum line: 482

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_UPHEAVAL",
    numeric_id = 350,
    status = "defined",
    name = "Upheaval",
    schools = {
        "conjuration",
    },
    flags = {
        "target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_ABILITY_QAZLAL_UPHEAVAL",
}

register.definition(categories.SPELLS, definition)

return definition
