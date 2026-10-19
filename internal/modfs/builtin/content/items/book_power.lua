-- book of Power (BOOK_POWER) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_POWER",
    name = "book of Power",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 30,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Power has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Power",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Power enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_BATTLESPHERE,
            spells.SPELL_IRON_SHOT,
            spells.SPELL_SPELLFORGED_SERVITOR,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
