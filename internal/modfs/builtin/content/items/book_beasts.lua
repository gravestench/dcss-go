-- book of Beasts (BOOK_BEASTS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

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
    -- Source: crawl-ref/source/item-name.cc
    -- book of Beasts has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Beasts",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Beasts enters random item
    -- pools; held copies remain separate entities.
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
