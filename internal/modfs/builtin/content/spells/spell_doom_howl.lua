-- Doom Howl (SPELL_DOOM_HOWL) is a level 3 spell in translocation, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_DOOM_HOWL",
    numeric_id = 332,
    status = "defined",
    name = "Doom Howl",
    schools = {
        "translocation",
        "hexes",
    },
    flags = {
        "dir_or_target",
        "monster",
    },
    level = 3,
    power_cap = 200,
    min_range_expr = "LOS_RADIUS",
    max_range_expr = "LOS_RADIUS",
    noise = 15,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
