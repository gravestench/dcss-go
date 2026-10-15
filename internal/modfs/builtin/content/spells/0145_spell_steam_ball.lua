-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1361
-- Enum line: 208

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STEAM_BALL",
    numeric_id = 144,
    status = "defined",
    name = "Steam Ball",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STEAM_BALL",
}

register.definition(categories.SPELLS, definition)

return definition
