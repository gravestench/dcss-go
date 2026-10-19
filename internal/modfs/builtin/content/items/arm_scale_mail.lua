-- scale mail (ARM_SCALE_MAIL) belongs to OBJ_ARMOUR and occupies the body
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SCALE_MAIL",
    name = "scale mail",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 3,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- scale mail has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "scale mail",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 6,
        ev = -100,
        price = 40,
        acquire_weight = 1000,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether scale mail enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
