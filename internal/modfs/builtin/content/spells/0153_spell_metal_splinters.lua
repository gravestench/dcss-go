-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1450
-- Enum line: 216

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_METAL_SPLINTERS",
    numeric_id = 152,
    status = "defined",
    name = "Metal Splinters",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_METAL_SPLINTERS",
}

register.definition(categories.SPELLS, definition)

return definition
