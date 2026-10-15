-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:831
-- Enum line: 120

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHOCK",
    numeric_id = 83,
    status = "defined",
    name = "Shock",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 1,
    power_cap = 25,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_SHOCK",
}

register.definition(categories.SPELLS, definition)

return definition
