-- Death Rattle (SPELL_DEATH_RATTLE) is a level 7 spell in conjuration,
-- necromancy, air.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
