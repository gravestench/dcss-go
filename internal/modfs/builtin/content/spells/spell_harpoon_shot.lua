-- Harpoon Shot (SPELL_HARPOON_SHOT) is a level 4 spell in conjuration, earth.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HARPOON_SHOT",
    numeric_id = 357,
    status = "defined",
    name = "Harpoon Shot",
    schools = {
        "conjuration",
        "earth",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
