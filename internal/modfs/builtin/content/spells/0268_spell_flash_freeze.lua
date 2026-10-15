-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2349
-- Enum line: 375

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FLASH_FREEZE",
    numeric_id = 267,
    status = "defined",
    name = "Flash Freeze",
    schools = {
        "conjuration",
        "ice",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 7,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
