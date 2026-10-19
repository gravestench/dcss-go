-- There-And-Back Book (BOOK_THERE_AND_BACK) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_THERE_AND_BACK",
    name = "There-And-Back Book",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 68,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- There-And-Back Book has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "There-And-Back Book",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether There-And-Back Book enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_GRAVITAS,
            spells.SPELL_TELEPORT_OTHER,
            spells.SPELL_DISPERSAL,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
