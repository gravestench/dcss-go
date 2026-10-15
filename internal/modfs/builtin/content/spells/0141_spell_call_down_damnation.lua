-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:425
-- Enum line: 200

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_DOWN_DAMNATION",
    numeric_id = 140,
    status = "defined",
    name = "Call Down Damnation",
    schools = {
        "conjuration",
    },
    flags = {
        "target",
        "area",
        "unholy",
        "needs_tracer",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 9,
    effect_noise = 0,
    tile_id = "TILEG_CALL_DOWN_DAMNATION",
}

register.definition(categories.SPELLS, definition)

return definition
