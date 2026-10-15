-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 633

local categories = require("constants.catalog")

local definition = {
    id = "WAND_POLYMORPH",
    name = "wand of polymorph",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 15,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:633
    naming = {
        text = "wand of polymorph",
        kind = "static",
    },
    explicitly_removed = false,
}

register.definition(categories.ITEMS, definition)

return definition
