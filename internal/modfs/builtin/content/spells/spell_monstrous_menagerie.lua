-- Monstrous Menagerie (SPELL_MONSTROUS_MENAGERIE) is a level 7 spell in
-- summoning.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MONSTROUS_MENAGERIE",
    numeric_id = 137,
    status = "defined",
    name = "Monstrous Menagerie",
    schools = {
        "summoning",
    },
    flags = {
        "mons_abjure",
    },
    level = 7,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_MONSTROUS_MENAGERIE",
}

register.definition(categories.SPELLS, definition)

return definition
