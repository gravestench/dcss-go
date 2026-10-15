-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1988
-- Enum line: 307

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PETRIFYING_CLOUD",
    numeric_id = 219,
    status = "defined",
    name = "Petrifying Cloud",
    schools = {
        "conjuration",
        "earth",
        "air",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_PETRIFYING_CLOUD",
}

register.definition(categories.SPELLS, definition)

return definition
