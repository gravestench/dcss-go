-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1919
-- Enum line: 280

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INJURY_MIRROR",
    numeric_id = 200,
    status = "defined",
    name = "Injury Mirror",
    schools = {
        "none",
    },
    flags = {
        "dir_or_target",
        "helpful",
        "selfench",
        "utility",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_INJURY_MIRROR",
}

register.definition(categories.SPELLS, definition)

return definition
