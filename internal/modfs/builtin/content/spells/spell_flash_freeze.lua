-- Flash Freeze (SPELL_FLASH_FREEZE) is a level 7 spell in conjuration, ice.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

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
