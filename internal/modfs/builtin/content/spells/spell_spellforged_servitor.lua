-- Spellforged Servitor (SPELL_SPELLFORGED_SERVITOR) is a level 7 spell in
-- conjuration, summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SPELLFORGED_SERVITOR",
    numeric_id = 291,
    status = "defined",
    name = "Spellforged Servitor",
    schools = {
        "conjuration",
        "summoning",
    },
    flags = {
        "none",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_SPELLFORGED_SERVITOR",
}

register.definition(categories.SPELLS, definition)

return definition
