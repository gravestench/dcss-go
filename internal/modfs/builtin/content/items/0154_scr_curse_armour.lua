-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 722

local categories = require("constants.catalog")

local definition = {
    id = "SCR_CURSE_ARMOUR",
    name = "scroll of curse armour",
    glyph = 63,
    class = "OBJ_SCROLLS",
    class_value = 5,
    subtype_value = 11,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc:722
    naming = {
        text = "scroll of curse armour",
        kind = "static",
    },
    explicitly_removed = true,
}

register.definition(categories.ITEMS, definition)

return definition
