-- Olgreb's Toxic Radiance (SPELL_OLGREBS_TOXIC_RADIANCE) is a level 4 spell
-- in poison.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_OLGREBS_TOXIC_RADIANCE",
    numeric_id = 27,
    status = "defined",
    name = "Olgreb's Toxic Radiance",
    schools = {
        "poison",
    },
    flags = {
        "area",
    },
    level = 4,
    power_cap = 100,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_OLGREBS_TOXIC_RADIANCE",
}

register.definition(categories.SPELLS, definition)

return definition
