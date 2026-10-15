-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/spl-data.h:1472
-- Enum line: 217

local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MIASMA_BREATH",
    numeric_id = 153,
    status = "defined",
    name = "Miasma Breath",
    schools = {
        "conjuration",
    },
    flags = {
        "dir_or_target",
        "unclean",
        "monster",
        "needs_tracer",
        "cloud",
    },
    level = 6,
    power_cap = 0,
    min_range_expr = "5",
    max_range_expr = "5",
    noise = 6,
    effect_noise = 0,
    tile_id = "TILEG_MIASMA_BREATH",
}

register.definition(categories.SPELLS, definition)

return definition
