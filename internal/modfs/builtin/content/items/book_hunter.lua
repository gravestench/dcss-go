-- book of the Hunter (BOOK_HUNTER) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_HUNTER",
    name = "book of the Hunter",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 76,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of the Hunter has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of the Hunter",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode random controls whether book of the Hunter enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
        spells = {
            spells.SPELL_CALL_CANINE_FAMILIAR,
            spells.SPELL_PORTAL_PROJECTILE,
            spells.SPELL_LEDAS_LIQUEFACTION,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
