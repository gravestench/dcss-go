-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1255
-- Enum line: 197

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GOLUBRIAS_PASSAGE",
    numeric_id = 139,
    status = "defined",
    name = "Passage of Golubria",
    schools = {
        "translocation",
    },
    flags = {
        "target",
        "neutral",
        "escape",
        "selfench",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "2",
    max_range_expr = "LOS_RADIUS",
    noise = 3,
    effect_noise = 8,
    tile_id = "TILEG_PASSAGE_OF_GOLUBRIA",
}

register.definition(categories.SPELLS, definition)

return definition
