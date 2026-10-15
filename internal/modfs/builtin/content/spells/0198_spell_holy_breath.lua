-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1907
-- Enum line: 277

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HOLY_BREATH",
    numeric_id = 197,
    status = "defined",
    name = "Holy Breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "area",
        "needs_tracer",
        "cloud",
        "holy",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 2,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
