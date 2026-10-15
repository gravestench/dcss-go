-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:965
-- Enum line: 144

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEATH_CHANNEL",
    numeric_id = 100,
    status = "defined",
    name = "Death Channel",
    schools = {
        "necromancy",
    },
    flags = {
        "helpful",
        "utility",
        "selfench",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_DEATH_CHANNEL",
}

register.definition(categories.SPELLS, definition)

return definition
