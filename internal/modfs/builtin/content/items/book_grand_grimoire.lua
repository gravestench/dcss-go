-- Grand Grimoire (BOOK_GRAND_GRIMOIRE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_GRAND_GRIMOIRE",
    name = "Grand Grimoire",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 41,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- Grand Grimoire has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "Grand Grimoire",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether Grand Grimoire enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_MALIGN_GATEWAY,
            spells.SPELL_SUMMON_HORRIBLE_THINGS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
