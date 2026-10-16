-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1183

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_THERE_AND_BACK",
    name = "There-And-Back Book",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 68,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1183
    naming = {
        text = "There-And-Back Book",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_GRAVITAS,
            spells.SPELL_TELEPORT_OTHER,
            spells.SPELL_DISPERSAL,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
