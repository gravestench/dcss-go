-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2099
-- Enum line: 330

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SENTINEL_MARK",
    numeric_id = 236,
    status = "defined",
    name = "Sentinel's Mark",
    schools = {
        "hexes",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "WL_check",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SENTINEL_MARK",
}

register.definition(categories.SPELLS, definition)

return definition
