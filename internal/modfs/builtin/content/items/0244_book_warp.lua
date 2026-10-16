-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1015

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_WARP",
    name = "book of the Warp",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 22,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1015
    naming = {
        text = "book of the Warp",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_DISPERSAL,
            spells.SPELL_DISJUNCTION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
