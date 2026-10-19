-- crystal plate armour (ARM_CRYSTAL_PLATE_ARMOUR) belongs to OBJ_ARMOUR and
-- occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_CRYSTAL_PLATE_ARMOUR",
    name = "crystal plate armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 15,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- crystal plate armour has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "crystal plate armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 14,
        ev = -230,
        price = 800,
        acquire_weight = 500,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = false,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether crystal plate armour enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
