-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2010
-- Enum line: 311

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BEASTLY_APPENDAGE",
    numeric_id = 221,
    status = "defined",
    name = "Beastly Appendage",
    schools = {
        "transmutation",
    },
    flags = {
        "helpful",
        "chaotic",
    },
    level = 1,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_BEASTLY_APPENDAGE",
}

register.definition(categories.SPELLS, definition)

return definition
