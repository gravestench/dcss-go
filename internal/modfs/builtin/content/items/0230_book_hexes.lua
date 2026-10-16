-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1000

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_HEXES",
    name = "book of Hexes",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 8,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1000
    naming = {
        text = "book of Hexes",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_INNER_FLAME,
            spells.SPELL_CAUSE_FEAR,
            spells.SPELL_DISCORD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
