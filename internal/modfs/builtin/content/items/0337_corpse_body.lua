-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1130

local categories = require("constants.catalog")

local definition = {
    id = "CORPSE_BODY",
    name = "corpse",
    glyph = 37,
    class = "OBJ_CORPSES",
    class_value = 12,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1130
    naming = {
        text = "corpse",
        kind = "corpse_monster",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
