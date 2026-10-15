-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:820
-- Enum line: 119

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STONE_ARROW",
    numeric_id = 82,
    status = "defined",
    name = "Stone Arrow",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_STONE_ARROW",
}

register.definition(categories.SPELLS, definition)

return definition
