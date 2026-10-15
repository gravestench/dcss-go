-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1338
-- Enum line: 204

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BRAIN_FEED",
    numeric_id = 142,
    status = "defined",
    name = "Brain Feed",
    schools = {
        "necromancy",
    },
    flags = {
        "target",
        "monster",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_BRAIN_FEED",
}

register.definition(categories.SPELLS, definition)

return definition
