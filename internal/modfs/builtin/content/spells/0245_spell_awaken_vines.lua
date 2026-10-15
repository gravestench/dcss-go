-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2191
-- Enum line: 338

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AWAKEN_VINES",
    numeric_id = 244,
    status = "defined",
    name = "Awaken Vines",
    schools = {
        "hexes",
        "summoning",
    },
    flags = {
        "area",
        "monster",
        "target",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_AWAKEN_VINES",
}

register.definition(categories.SPELLS, definition)

return definition
