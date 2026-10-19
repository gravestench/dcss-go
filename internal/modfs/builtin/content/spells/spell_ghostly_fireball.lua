-- Ghostly Fireball (SPELL_GHOSTLY_FIREBALL) is a level 5 spell in
-- conjuration, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_GHOSTLY_FIREBALL",
    numeric_id = 240,
    status = "defined",
    name = "Ghostly Fireball",
    schools = {
        "conjuration",
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "monster",
        "unholy",
        "needs_tracer",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_GHOSTLY_FIREBALL",
}

register.definition(categories.SPELLS, definition)

return definition
