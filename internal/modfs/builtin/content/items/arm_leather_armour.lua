-- leather armour (ARM_LEATHER_ARMOUR) belongs to OBJ_ARMOUR and occupies the
-- body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_LEATHER_ARMOUR",
    name = "leather armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 1,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- leather armour has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "leather armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 3,
        ev = -40,
        price = 20,
        acquire_weight = 0,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether leather armour enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
