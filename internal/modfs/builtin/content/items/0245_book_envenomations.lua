-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1017

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_ENVENOMATIONS",
    name = "book of Envenomations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 23,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1017
    naming = {
        text = "book of Envenomations",
        kind = "static",
    },
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_SPIDER_FORM,
            spells.SPELL_OLGREBS_TOXIC_RADIANCE,
            spells.SPELL_INTOXICATE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
