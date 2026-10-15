-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1727
-- Enum line: 247

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FAKE_MARA_SUMMON",
    numeric_id = 177,
    status = "defined",
    name = "Mara Summon",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_FAKE_MARA_SUMMON",
}

register.definition(categories.SPELLS, definition)

return definition
