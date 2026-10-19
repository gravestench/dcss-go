-- wand of flame (WAND_FLAME) belongs to OBJ_WANDS.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local spells = require("ids.spells")

local definition = {
    id = "WAND_FLAME",
    name = "wand of flame",
    glyph = 47,
    class = "OBJ_WANDS",
    class_value = 3,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/spl-book.cc
    wand_spell_id = spells.SPELL_THROW_FLAME,
    -- Source: crawl-ref/source/item-name.cc
    -- wand of flame has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "wand of flame",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether wand of flame enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
