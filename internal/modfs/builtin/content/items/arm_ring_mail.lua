-- ring mail (ARM_RING_MAIL) belongs to OBJ_ARMOUR and occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_RING_MAIL",
    name = "ring mail",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 2,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- ring mail has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "ring mail",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 5,
        ev = -70,
        price = 40,
        acquire_weight = 1000,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether ring mail enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
