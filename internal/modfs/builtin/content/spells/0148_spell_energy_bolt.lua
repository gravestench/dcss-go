-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1394
-- Enum line: 211

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ENERGY_BOLT",
    numeric_id = 147,
    status = "defined",
    name = "Energy Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_ENERGY_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
