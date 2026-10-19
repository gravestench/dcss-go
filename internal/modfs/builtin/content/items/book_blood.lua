-- book of Blood (BOOK_BLOOD) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

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
    -- Source: crawl-ref/source/item-name.cc
    -- book of Blood has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Blood",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Blood enters random item
    -- pools; held copies remain separate entities.
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
