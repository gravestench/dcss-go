-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1233
-- Enum line: 194

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_PORTAL_PROJECTILE",
    numeric_id = 136,
    status = "defined",
    name = "Portal Projectile",
    schools = {
        "translocation",
        "hexes",
    },
    flags = {
        "none",
    },
    level = 3,
    power_cap = 50,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_PORTAL_PROJECTILE",
}

register.definition(categories.SPELLS, definition)

return definition
