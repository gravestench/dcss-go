-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3053
-- Enum line: 475

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BIND_SOULS",
    numeric_id = 343,
    status = "defined",
    name = "Bind Souls",
    schools = {
        "necromancy",
        "ice",
    },
    flags = {
        "area",
        "monster",
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
