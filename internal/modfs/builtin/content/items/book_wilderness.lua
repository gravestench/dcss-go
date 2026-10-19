-- book of the Wilderness (BOOK_WILDERNESS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_WILDERNESS",
    name = "book of the Wilderness",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 4,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Wilderness has its display text here so identification policy
    -- can choose known or unknown names consistently.
    naming = {
        text = "book of the Wilderness",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Wilderness enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_SUMMON_FOREST,
            spells.SPELL_SUMMON_MANA_VIPER,
            spells.SPELL_SUMMON_CACTUS,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
