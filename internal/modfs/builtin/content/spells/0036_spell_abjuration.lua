-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:358
-- Enum line: 54

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ABJURATION",
    numeric_id = 35,
    status = "defined",
    name = "Abjuration",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_MASS_ABJURATION",
}

register.definition(categories.SPELLS, definition)

return definition
