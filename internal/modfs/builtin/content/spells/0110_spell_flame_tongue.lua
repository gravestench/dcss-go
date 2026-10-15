-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1032
-- Enum line: 157

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLAME_TONGUE",
    numeric_id = 109,
    status = "defined",
    name = "Flame Tongue",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "monster",
    },
    level = 1,
    power_cap = 40,
    min_range_expr = "2",
    max_range_expr = "5",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FLAME_TONGUE",
}

register.definition(categories.SPELLS, definition)

return definition
