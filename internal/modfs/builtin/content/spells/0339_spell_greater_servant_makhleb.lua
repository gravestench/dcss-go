-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3042
-- Enum line: 470

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GREATER_SERVANT_MAKHLEB",
    numeric_id = 338,
    status = "defined",
    name = "Greater Servant of Makhleb",
    schools = {
        "summoning",
    },
    flags = {
        "unholy",
        "selfench",
        "mons_abjure",
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_ABILITY_MAKHLEB_GREATER_SERVANT",
}

register.definition(categories.SPELLS, definition)

return definition
