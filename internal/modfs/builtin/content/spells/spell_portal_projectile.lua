-- Portal Projectile (SPELL_PORTAL_PROJECTILE) is a level 3 spell in
-- translocation, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
