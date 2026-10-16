-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1037

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_BEASTS",
    name = "book of Beasts",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 39,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1037
    naming = {
        text = "book of Beasts",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_ICE_BEAST,
            spells.SPELL_SUMMON_MANA_VIPER,
            spells.SPELL_MONSTROUS_MENAGERIE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
