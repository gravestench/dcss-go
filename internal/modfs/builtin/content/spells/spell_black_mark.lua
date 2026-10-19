-- Black Mark (SPELL_BLACK_MARK) is a level 7 spell in necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BLACK_MARK",
    numeric_id = 274,
    status = "defined",
    name = "Black Mark",
    schools = {
        "necromancy",
    },
    flags = {
        "monster",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
