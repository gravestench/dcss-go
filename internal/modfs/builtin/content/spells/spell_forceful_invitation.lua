-- Forceful Invitation (SPELL_FORCEFUL_INVITATION) is a level 4 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_FORCEFUL_INVITATION",
    numeric_id = 270,
    status = "defined",
    name = "Forceful Invitation",
    schools = {
        "summoning",
    },
    flags = {
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
