-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2515
-- Enum line: 396

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHADOW_BOLT",
    numeric_id = 282,
    status = "defined",
    name = "Shadow Bolt",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
