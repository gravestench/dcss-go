-- book of Envenomations (BOOK_ENVENOMATIONS) belongs to OBJ_BOOKS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "BOOK_ENVENOMATIONS",
    name = "book of Envenomations",
    glyph = 58,
    class = "OBJ_BOOKS",
    class_value = 8,
    subtype_value = 23,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- book of Envenomations has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "book of Envenomations",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    -- Source: crawl-ref/source/book-data.h
    -- Generation mode none controls whether book of Envenomations enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "none",
        spells = {
            spells.SPELL_SPIDER_FORM,
            spells.SPELL_OLGREBS_TOXIC_RADIANCE,
            spells.SPELL_INTOXICATE,
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
