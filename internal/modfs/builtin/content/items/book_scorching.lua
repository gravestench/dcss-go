-- book of Scorching (BOOK_SCORCHING) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_SCORCHING",
    name = "book of Scorching",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 77,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Scorching has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Scorching",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of Scorching enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SCORCH,
            spells.SPELL_FLAME_WAVE,
            spells.SPELL_SUMMON_CACTUS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
