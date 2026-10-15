-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3108
-- Enum line: 480

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DREAM_DUST",
    numeric_id = 348,
    status = "defined",
    name = "Dream Dust",
    schools = {
        "hexes",
    },
    flags = {
        "target",
        "not_self",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 0,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
