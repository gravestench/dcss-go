-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:539
-- Enum line: 70

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANIMATE_DEAD",
    numeric_id = 47,
    status = "defined",
    name = "Animate Dead",
    schools = {
        "necromancy",
    },
    flags = {
        "helpful",
        "utility",
        "selfench",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_ANIMATE_DEAD",
}

register.definition(categories.SPELLS, definition)

return definition
