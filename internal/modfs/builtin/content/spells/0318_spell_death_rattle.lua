-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2888
-- Enum line: 441

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DEATH_RATTLE",
    numeric_id = 317,
    status = "defined",
    name = "Death Rattle",
    schools = {
        "conjuration",
        "necromancy",
        "air",
    },
    flags = {
        "dir_or_target",
        "monster",
    },
    level = 7,
    power_cap = 0,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
