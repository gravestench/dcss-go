-- box of beasts (MISC_BOX_OF_BEASTS) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_BOX_OF_BEASTS",
    name = "box of beasts",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 6,
    stackable = false,
    -- XP recharge is shared by every carried copy of this subtype.
    evoker = {
        charge_debt = 10,
        max_charges = 1,
        aimed = false,
    },
    -- Source: crawl-ref/source/item-name.cc
    -- box of beasts has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "box of beasts",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether box of beasts enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
