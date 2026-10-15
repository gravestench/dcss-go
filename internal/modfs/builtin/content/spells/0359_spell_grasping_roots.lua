-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3197
-- Enum line: 494

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GRASPING_ROOTS",
    numeric_id = 358,
    status = "defined",
    name = "Grasping Roots",
    schools = {
        "earth",
    },
    flags = {
        "target",
        "not_self",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GRASPING_ROOTS",
}

register.definition(categories.SPELLS, definition)

return definition
