-- Legendary Destruction (SPELL_LEGENDARY_DESTRUCTION) is a level 8 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_LEGENDARY_DESTRUCTION",
    numeric_id = 268,
    status = "defined",
    name = "Legendary Destruction",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 8,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 8,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
