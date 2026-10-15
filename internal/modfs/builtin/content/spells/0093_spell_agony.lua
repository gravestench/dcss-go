-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:864
-- Enum line: 133

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_AGONY",
    numeric_id = 92,
    status = "defined",
    name = "Agony",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
        "WL_check",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_AGONY",
}

register.definition(categories.SPELLS, definition)

return definition
