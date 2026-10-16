-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1194

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_AKASHIC_RECORD",
    name = "Akashic Record",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 33,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1194
    naming = {
        text = "Akashic Record",
        kind = "static",
    },
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_DISPERSAL,
            spells.SPELL_MALIGN_GATEWAY,
            spells.SPELL_DISJUNCTION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
