-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2303
-- Enum line: 361

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DISCORD",
    numeric_id = 259,
    status = "defined",
    name = "Discord",
    schools = {
        "hexes",
    },
    flags = {
        "area",
        "hasty",
        "WL_check",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_DISCORD",
}

register.definition(categories.SPELLS, definition)

return definition
