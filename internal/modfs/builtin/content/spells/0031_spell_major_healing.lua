-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1301
-- Enum line: 49

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MAJOR_HEALING",
    numeric_id = 30,
    status = "defined",
    name = "Major Healing",
    schools = {
        "necromancy",
    },
    flags = {
        "recovery",
        "helpful",
        "monster",
        "selfench",
        "utility",
        "not_evil",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_MAJOR_HEALING",
}

register.definition(categories.SPELLS, definition)

return definition
