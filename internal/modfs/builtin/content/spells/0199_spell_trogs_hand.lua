-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1850
-- Enum line: 278

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_TROGS_HAND",
    numeric_id = 198,
    status = "defined",
    name = "Trog's Hand",
    schools = {
        "none",
    },
    flags = {
        "monster",
        "selfench",
    },
    level = 3,
    power_cap = 0,
    min_range_expr = "-1",
    max_range_expr = "-1",
    noise = 3,
    effect_noise = 0,
    tile_id = "TILEG_TROGS_HAND",
}

register.definition(categories.SPELLS, definition)

return definition
