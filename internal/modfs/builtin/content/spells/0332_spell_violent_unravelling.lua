-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2943
-- Enum line: 463

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VIOLENT_UNRAVELLING",
    numeric_id = 331,
    status = "defined",
    name = "Yara's Violent Unravelling",
    schools = {
        "hexes",
        "transmutation",
    },
    flags = {
        "target",
        "no_ghost",
        "chaotic",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_VIOLENT_UNRAVELLING",
}

register.definition(categories.SPELLS, definition)

return definition
