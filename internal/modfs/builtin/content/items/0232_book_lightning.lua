-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1001

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_LIGHTNING",
    name = "book of Lightning",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 10,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1001
    naming = {
        text = "book of Lightning",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_DISCHARGE,
            spells.SPELL_LIGHTNING_BOLT,
            spells.SPELL_MAXWELLS_COUPLING,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
