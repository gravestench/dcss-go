-- book of the Sky (BOOK_SKY) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_SKY",
    name = "book of the Sky",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 21,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Sky has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of the Sky",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Sky enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_LIGHTNING_SPIRE,
            spells.SPELL_STORM_FORM,
            spells.SPELL_MAXWELLS_COUPLING,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
