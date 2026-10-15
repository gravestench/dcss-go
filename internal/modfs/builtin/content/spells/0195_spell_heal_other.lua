-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1883
-- Enum line: 272

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HEAL_OTHER",
    numeric_id = 194,
    status = "defined",
    name = "Heal Other",
    schools = {
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "helpful",
        "needs_tracer",
        "utility",
        "not_evil",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_HEAL_OTHER",
}

register.definition(categories.SPELLS, definition)

return definition
