-- animal skin (ARM_ANIMAL_SKIN) belongs to OBJ_ARMOUR and occupies the body
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ANIMAL_SKIN",
    name = "animal skin",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 16,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- animal skin has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "animal skin",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 2,
        ev = 0,
        price = 3,
        acquire_weight = 333,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether animal skin enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
