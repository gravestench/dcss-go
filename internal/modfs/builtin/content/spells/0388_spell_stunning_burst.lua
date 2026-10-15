-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3441
-- Enum line: 525

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STUNNING_BURST",
    numeric_id = 387,
    status = "defined",
    name = "Stunning Burst",
    schools = {
        "conjuration",
        "air",
    },
    flags = {
        "target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 8,
    effect_noise = 8,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
