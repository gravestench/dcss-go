-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:584
-- Enum line: 76

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VAMPIRIC_DRAINING",
    numeric_id = 51,
    status = "defined",
    name = "Vampiric Draining",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "1",
    max_range_expr = "1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_VAMPIRIC_DRAINING",
}

register.definition(categories.SPELLS, definition)

return definition
