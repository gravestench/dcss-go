-- Bolt of Fire (SPELL_BOLT_OF_FIRE) is a level 6 spell in conjuration, fire.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_FIRE",
    numeric_id = 10,
    status = "defined",
    name = "Bolt of Fire",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "6",
    max_range_expr = "6",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_BOLT_OF_FIRE",
}

register.definition(categories.SPELLS, definition)

return definition
