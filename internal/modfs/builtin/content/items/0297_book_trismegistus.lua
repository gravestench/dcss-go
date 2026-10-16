-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1189

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_TRISMEGISTUS",
    name = "Trismegistus Codex",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 75,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1189
    naming = {
        text = "Trismegistus Codex",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_IGNITE_POISON,
            spells.SPELL_MEPHITIC_CLOUD,
            spells.SPELL_FREEZING_CLOUD,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
