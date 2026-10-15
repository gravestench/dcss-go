-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3319
-- Enum line: 505

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MAXWELLS_COUPLING",
    numeric_id = 369,
    status = "defined",
    name = "Maxwell's Capacitive Coupling",
    schools = {
        "air",
    },
    flags = {
        "no_ghost",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 7,
    effect_noise = 25,
    tile_id = "TILEG_MAXWELLS_COUPLING",
}

register.definition(categories.SPELLS, definition)

return definition
