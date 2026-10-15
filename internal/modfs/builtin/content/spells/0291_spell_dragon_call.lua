-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2549
-- Enum line: 406

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DRAGON_CALL",
    numeric_id = 290,
    status = "defined",
    name = "Dragon's Call",
    schools = {
        "summoning",
    },
    flags = {
        "none",
    },
    level = 9,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 7,
    effect_noise = 15,
    tile_id = "TILEG_SUMMON_DRAGON",
}

register.definition(categories.SPELLS, definition)

return definition
