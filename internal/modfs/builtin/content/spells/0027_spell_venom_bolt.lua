-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:278
-- Enum line: 45

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_VENOM_BOLT",
    numeric_id = 26,
    status = "defined",
    name = "Venom Bolt",
    schools = {
        "conjuration",
        "poison",
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
    noise = 5,
    effect_noise = 0,
    tile_id = "TILEG_VENOM_BOLT",
}

register.definition(categories.SPELLS, definition)

return definition
