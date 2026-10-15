-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3142
-- Enum line: 484

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_POISONOUS_VAPOURS",
    numeric_id = 352,
    status = "defined",
    name = "Poisonous Vapours",
    schools = {
        "poison",
        "air",
    },
    flags = {
        "target",
        "not_self",
    },
    level = 2,
    power_cap = 50,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_POISONOUS_VAPOURS",
}

register.definition(categories.SPELLS, definition)

return definition
