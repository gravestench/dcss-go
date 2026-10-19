-- sling bullet (MI_SLING_BULLET) belongs to OBJ_MISSILES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.
-- Copies may stack in inventory; the stack quantity is saved on the entity,
-- not this catalog entry.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "MI_SLING_BULLET",
    name = "sling bullet",
    glyph = 40,
    class = "OBJ_MISSILES",
    class_value = 1,
    subtype_value = 7,
    stackable = true,
    -- Source: crawl-ref/source/item-prop.cc
    -- sling bullet has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "sling bullet",
        kind = "static",
    },
    -- Retained source subtype; this flag records that ordinary item selection must exclude it.
    explicitly_removed = true,
    missile = {
        damage = 0,
        mulch_rate = 1,
        price = 5,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode none controls whether sling bullet enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "none",
    },
}

register.definition(categories.ITEMS, definition)

return definition
