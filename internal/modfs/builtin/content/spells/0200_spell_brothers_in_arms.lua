-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1839
-- Enum line: 279

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BROTHERS_IN_ARMS",
    numeric_id = 199,
    status = "defined",
    name = "Brothers in Arms",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_BROTHERS_IN_ARMS",
}

register.definition(categories.SPELLS, definition)

return definition
