-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2627
-- Enum line: 471

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SERPENT_OF_HELL_GEH_BREATH",
    numeric_id = 339,
    status = "defined",
    name = "gehenna serpent of hell breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "noisy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
