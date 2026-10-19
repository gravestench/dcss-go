-- Conjure Living Spells (SPELL_CONJURE_LIVING_SPELLS) is a level 6 spell in
-- conjuration.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_CONJURE_LIVING_SPELLS",
    numeric_id = 394,
    status = "defined",
    name = "Conjure Living Spells",
    schools = {
        "conjuration",
    },
    flags = {
        "selfench",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
