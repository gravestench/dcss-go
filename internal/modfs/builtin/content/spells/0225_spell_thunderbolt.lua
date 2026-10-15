-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2032
-- Enum line: 316

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_THUNDERBOLT",
    numeric_id = 224,
    status = "defined",
    name = "Thunderbolt",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "dir_or_target",
        "not_self",
    },
    level = 2,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 15,
    effect_noise = 0,
    tile_id = "TILEG_THUNDERBOLT",
}

register.definition(categories.SPELLS, definition)

return definition
