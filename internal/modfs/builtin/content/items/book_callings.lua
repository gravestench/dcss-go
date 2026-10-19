-- book of Callings (BOOK_CALLINGS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_CALLINGS",
    name = "book of Callings",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 18,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Callings has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Callings",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Callings enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_SMALL_MAMMAL,
            spells.SPELL_CALL_CANINE_FAMILIAR,
            spells.SPELL_SUMMON_GUARDIAN_GOLEM,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
