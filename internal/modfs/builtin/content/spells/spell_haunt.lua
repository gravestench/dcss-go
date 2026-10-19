-- Haunt (SPELL_HAUNT) is a level 7 spell in summoning, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HAUNT",
    numeric_id = 52,
    status = "defined",
    name = "Haunt",
    schools = {
        "summoning",
        "necromancy",
    },
    flags = {
        "target",
        "not_self",
        "mons_abjure",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_HAUNT",
}

register.definition(categories.SPELLS, definition)

return definition
