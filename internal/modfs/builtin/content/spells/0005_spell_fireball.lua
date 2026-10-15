-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:51
-- Enum line: 17

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FIREBALL",
    numeric_id = 4,
    status = "defined",
    name = "Fireball",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_FIREBALL",
}

register.definition(categories.SPELLS, definition)

return definition
