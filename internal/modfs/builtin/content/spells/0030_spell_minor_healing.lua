-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1289
-- Enum line: 48

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MINOR_HEALING",
    numeric_id = 29,
    status = "defined",
    name = "Minor Healing",
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
    level = 2,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_MINOR_HEALING",
}

register.definition(categories.SPELLS, definition)

return definition
