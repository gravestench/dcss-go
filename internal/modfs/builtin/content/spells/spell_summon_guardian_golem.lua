-- Summon Guardian Golem (SPELL_SUMMON_GUARDIAN_GOLEM) is a level 3 spell in
-- summoning, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_GUARDIAN_GOLEM",
    numeric_id = 286,
    status = "defined",
    name = "Summon Guardian Golem",
    schools = {
        "summoning",
        "hexes",
    },
    flags = {
        "none",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_GUARDIAN_GOLEM",
}

register.definition(categories.SPELLS, definition)

return definition
