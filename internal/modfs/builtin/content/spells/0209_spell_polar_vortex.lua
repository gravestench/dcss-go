-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:391
-- Enum line: 290

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POLAR_VORTEX",
    numeric_id = 208,
    status = "defined",
    name = "Polar Vortex",
    schools = {
        "ice",
    },
    flags = {
        "area",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "POLAR_VORTEX_RADIUS",
    max_range_expr = "POLAR_VORTEX_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_POLAR_VORTEX",
}

register.definition(categories.SPELLS, definition)

return definition
