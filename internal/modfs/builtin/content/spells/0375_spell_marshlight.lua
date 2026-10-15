-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:3252
-- Enum line: 510

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MARSHLIGHT",
    numeric_id = 374,
    status = "defined",
    name = "Marshlight",
    schools = {
        "conjuration",
        "fire",
    },
    flags = {
        "selfench",
        "monster",
    },
    level = 4,
    power_cap = 200,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 1,
    effect_noise = 0,
    tile_id = "TILEG_FOXFIRE",
}

register.definition(categories.SPELLS, definition)

return definition
