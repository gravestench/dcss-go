-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3031
-- Enum line: 469

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPRINT",
    numeric_id = 337,
    status = "defined",
    name = "Sprint",
    schools = {
        "hexes",
    },
    flags = {
        "hasty",
        "selfench",
        "utility",
        "monster",
    },
    level = 2,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_SPRINT",
}

register.definition(categories.SPELLS, definition)

return definition
