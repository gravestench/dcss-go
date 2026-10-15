-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1200
-- Enum line: 188

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SIMULACRUM",
    numeric_id = 132,
    status = "defined",
    name = "Simulacrum",
    schools = {
        "ice",
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_SIMULACRUM",
}

register.definition(categories.SPELLS, definition)

return definition
