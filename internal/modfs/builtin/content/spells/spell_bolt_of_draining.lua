-- Bolt of Draining (SPELL_BOLT_OF_DRAINING) is a level 5 spell in
-- conjuration, necromancy.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BOLT_OF_DRAINING",
    numeric_id = 37,
    status = "defined",
    name = "Bolt of Draining",
    schools = {
        "conjuration",
        "necromancy",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 5,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BOLT_OF_DRAINING",
}

register.definition(categories.SPELLS, definition)

return definition
