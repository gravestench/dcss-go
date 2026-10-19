-- Shadow Creatures (SPELL_SHADOW_CREATURES) is a level 6 spell in summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SHADOW_CREATURES",
    numeric_id = 106,
    status = "defined",
    name = "Shadow Creatures",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
        "monster",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_SHADOW_CREATURES",
}

register.definition(categories.SPELLS, definition)

return definition
