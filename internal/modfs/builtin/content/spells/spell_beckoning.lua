-- Lesser Beckoning (SPELL_BECKONING) is a level 3 spell in translocation.
-- Schools, ranges, and flags are metadata; a registered effect is still required to cast it.

-- Source: crawl-ref/source/spl-data.h

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_BECKONING",
    numeric_id = 349,
    status = "defined",
    name = "Lesser Beckoning",
    schools = {
        "translocation",
    },
    flags = {
        "dir_or_target",
        "not_self",
        "needs_tracer",
    },
    level = 3,
    power_cap = 100,
    min_range_expr = "2",
    max_range_expr = "5",
    noise = 2,
    effect_noise = 0,
    tile_id = "TILEG_BECKONING",
}

register.definition(categories.SPELLS, definition)

return definition
