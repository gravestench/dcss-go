-- Conjure Ball Lightning (SPELL_CONJURE_BALL_LIGHTNING) is a level 6 spell in
-- air, conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONJURE_BALL_LIGHTNING",
    numeric_id = 133,
    status = "defined",
    name = "Conjure Ball Lightning",
    schools = {
        "air",
        "conjuration",
    },
    flags = {
        "selfench",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_CONJURE_BALL_LIGHTNING",
}

register.definition(categories.SPELLS, definition)

return definition
