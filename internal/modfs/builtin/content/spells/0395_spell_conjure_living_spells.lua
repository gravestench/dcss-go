-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3463
-- Enum line: 532

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
