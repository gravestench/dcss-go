-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1966
-- Enum line: 298

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MESMERISE",
    numeric_id = 214,
    status = "defined",
    name = "Mesmerise",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "WL_check",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
