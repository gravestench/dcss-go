-- horn of Geryon (MISC_HORN_OF_GERYON) belongs to OBJ_MISCELLANY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "MISC_HORN_OF_GERYON",
    name = "horn of Geryon",
    glyph = 125,
    class = "OBJ_MISCELLANY",
    class_value = 11,
    subtype_value = 5,
    stackable = false,
    -- XP recharge is shared by every carried copy of this subtype.
    evoker = {
        charge_debt = 10,
        max_charges = 1,
        aimed = false,
    },
    -- Source: crawl-ref/source/item-name.cc
    -- horn of Geryon has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "horn of Geryon",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether horn of Geryon enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
