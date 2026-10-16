-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1059

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BLOOD",
    name = "book of Blood",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 67,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1059
    naming = {
        text = "book of Blood",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUBLIMATION_OF_BLOOD,
            spells.SPELL_WEREBLOOD,
            spells.SPELL_SUMMON_HYDRA,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
