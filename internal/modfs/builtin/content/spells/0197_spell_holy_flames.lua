-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1896
-- Enum line: 276

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HOLY_FLAMES",
    numeric_id = 196,
    status = "defined",
    name = "Holy Flames",
    schools = {
        "none",
    },
    flags = {
        "target",
        "not_self",
        "holy",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
