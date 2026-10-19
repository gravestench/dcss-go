-- Steam Ball (SPELL_STEAM_BALL) is a level 4 spell in conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_STEAM_BALL",
    numeric_id = 144,
    status = "defined",
    name = "Steam Ball",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "monster",
        "needs_tracer",
    },
    level = 4,
    power_cap = 0,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_STEAM_BALL",
}

register.definition(categories.SPELLS, definition)

return definition
