-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3064
-- Enum line: 476

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_INFESTATION",
    numeric_id = 344,
    status = "defined",
    name = "Infestation",
    schools = {
        "necromancy",
    },
    flags = {
        "target",
        "unclean",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 8,
    effect_noise = 4,
    tile_id = "TILEG_INFESTATION",
}

register.definition(categories.SPELLS, definition)

return definition
