-- book of Unlife (BOOK_UNLIFE) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_UNLIFE",
    name = "book of Unlife",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 24,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Unlife has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "book of Unlife",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Unlife enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_ANIMATE_DEAD,
            spells.SPELL_BORGNJORS_VILE_CLUTCH,
            spells.SPELL_DEATH_CHANNEL,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
