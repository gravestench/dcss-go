-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3352
-- Enum line: 509

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_HURL_SLUDGE",
    numeric_id = 373,
    status = "defined",
    name = "Hurl Sludge",
    schools = {
        "poison",
        "conjuration",
        "transmutation",
    },
    flags = {
        "dir_or_target",
        "needs_tracer",
        "monster",
    },
    level = 6,
    power_cap = 200,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 3,
    effect_noise = 5,
    tile_id = "TILEG_GENERIC_MONSTER_SPELL",
}

register.definition(categories.SPELLS, definition)

return definition
