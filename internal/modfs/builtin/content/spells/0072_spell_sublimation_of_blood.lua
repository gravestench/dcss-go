-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:751
-- Enum line: 104

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUBLIMATION_OF_BLOOD",
    numeric_id = 71,
    status = "defined",
    name = "Sublimation of Blood",
    schools = {
        "necromancy",
    },
    flags = {
        "utility",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SUBLIMATION_OF_BLOOD",
}

register.definition(categories.SPELLS, definition)

return definition
