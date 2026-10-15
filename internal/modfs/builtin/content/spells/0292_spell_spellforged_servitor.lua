-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:2560
-- Enum line: 407

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
