-- gold piece (OBJ_GOLD) belongs to OBJ_GOLD.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "OBJ_GOLD",
    name = "gold piece",
    glyph = 36,
    class = "OBJ_GOLD",
    class_value = 13,
    subtype_value = 0,
    stackable = true,
    -- Source: crawl-ref/source/item-name.cc
    -- gold piece has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "gold piece",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether gold piece enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
    -- Source: vaults/arrival/giann_wishing_wells.des
    vault_aliases = {
        "gold",
    },
}

register.definition(categories.ITEMS, definition)

return definition
