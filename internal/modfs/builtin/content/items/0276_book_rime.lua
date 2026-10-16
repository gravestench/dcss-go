-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1047

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_RIME",
    name = "book of Rime",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 54,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1047
    naming = {
        text = "book of Rime",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_FROZEN_RAMPARTS,
            spells.SPELL_ICE_FORM,
            spells.SPELL_SUMMON_ICE_BEAST,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
