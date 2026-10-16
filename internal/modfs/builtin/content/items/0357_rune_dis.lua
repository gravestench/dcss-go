-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 919

local categories = require("constants.catalog")

local definition = {
    id = "RUNE_DIS",
    name = "iron rune of Zot",
    glyph = 125,
    class = "OBJ_RUNES",
    class_value = 15,
    subtype_value = 7,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:919
    naming = {
        text = "iron rune of Zot",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
