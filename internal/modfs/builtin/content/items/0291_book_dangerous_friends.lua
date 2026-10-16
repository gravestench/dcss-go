-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 1060

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_DANGEROUS_FRIENDS",
    name = "book of Dangerous Friends",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 69,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc:1060
    naming = {
        text = "book of Dangerous Friends",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_GUARDIAN_GOLEM,
            spells.SPELL_IOOD,
            spells.SPELL_SPELLFORGED_SERVITOR,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
