-- Summon Mana Viper (SPELL_SUMMON_MANA_VIPER) is a level 5 spell in
-- summoning, hexes.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_SUMMON_MANA_VIPER",
    numeric_id = 293,
    status = "defined",
    name = "Summon Mana Viper",
    schools = {
        "summoning",
        "hexes",
    },
    flags = {
        "mons_abjure",
    },
    level = 5,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 4,
    effect_noise = 0,
    tile_id = "TILEG_SUMMON_MANA_VIPER",
}

register.definition(categories.SPELLS, definition)

return definition
