-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2537
-- Enum line: 150

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GLACIATE",
    numeric_id = 104,
    status = "defined",
    name = "Glaciate",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "area",
        "not_self",
        "monster",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 9,
    effect_noise = 25,
    tile_id = "TILEG_ICE_STORM",
}

register.definition(categories.SPELLS, definition)

return definition
