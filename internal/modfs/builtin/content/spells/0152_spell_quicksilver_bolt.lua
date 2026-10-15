-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1439
-- Enum line: 215

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_QUICKSILVER_BOLT",
    numeric_id = 151,
    status = "defined",
    name = "Quicksilver Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_QUICKSILVER_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
