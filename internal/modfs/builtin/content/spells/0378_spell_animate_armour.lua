-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3385
-- Enum line: 513

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_ANIMATE_ARMOUR",
    numeric_id = 377,
    status = "defined",
    name = "Animate Armour",
    schools = {
        "summoning",
        "earth",
    },
    flags = {
        "none",
    },
    level = 4,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_ANIMATE_ARMOUR",
}

register.definition(categories.SPELLS, definition)

return definition
