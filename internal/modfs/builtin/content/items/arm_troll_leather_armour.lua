-- troll leather armour (ARM_TROLL_LEATHER_ARMOUR) belongs to OBJ_ARMOUR and
-- occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_TROLL_LEATHER_ARMOUR",
    name = "troll leather armour",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 18,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- troll leather armour has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "troll leather armour",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 4,
        ev = -40,
        price = 150,
        acquire_weight = 50,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_REGENERATION",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether troll leather armour enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
