-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1647
-- Enum line: 230

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CREATE_TENTACLES",
    numeric_id = 164,
    status = "defined",
    name = "Spawn Tentacles",
    schools = {
        "none",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 5,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_CREATE_TENTACLES",
}

register.definition(categories.SPELLS, definition)

return definition
