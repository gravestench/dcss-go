-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:380
-- Enum line: 57

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LEHUDIBS_CRYSTAL_SPEAR",
    numeric_id = 38,
    status = "defined",
    name = "Lehudib's Crystal Spear",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "3",
    max_range_expr = "3",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_LEHUDIBS_CRYSTAL_SPEAR",
}

register.definition(categories.SPELLS, definition)

return definition
