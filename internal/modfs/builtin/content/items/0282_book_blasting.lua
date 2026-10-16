-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1052

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BLASTING",
    name = "book of Blasting",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 60,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1052
    naming = {
        text = "book of Blasting",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FULMINANT_PRISM,
            spells.SPELL_ISKENDERUNS_MYSTIC_BLAST,
            spells.SPELL_LRD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
