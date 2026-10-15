-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:639
-- Enum line: 84

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STICKY_FLAME",
    numeric_id = 57,
    status = "defined",
    name = "Sticky Flame",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STICKY_FLAME",
}

register.definition(categories.SPELLS, definition)

return definition
