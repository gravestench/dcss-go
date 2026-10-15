-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1553
-- Enum line: 291

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STICKY_FLAME_RANGE",
    numeric_id = 209,
    status = "defined",
    name = "Sticky Flame Range",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "4",
    max_range_expr = "4",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STICKY_FLAME_RANGE",
}

register.definition(categories.SPELLS, definition)

return definition
