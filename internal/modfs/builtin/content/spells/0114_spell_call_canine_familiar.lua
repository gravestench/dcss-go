-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1066
-- Enum line: 163

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CALL_CANINE_FAMILIAR",
    numeric_id = 113,
    status = "defined",
    name = "Call Canine Familiar",
    schools = {
        "summoning",
    },
    flags = {
        "none",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_CALL_CANINE_FAMILIAR",
}

register.definition(categories.SPELLS, definition)

return definition
