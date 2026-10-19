-- swamp dragon scales (ARM_SWAMP_DRAGON_ARMOUR) belongs to OBJ_ARMOUR and
-- occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_SWAMP_DRAGON_ARMOUR",
    name = "swamp dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 32,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- swamp dragon scales has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "swamp dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 7,
        ev = -70,
        price = 500,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_POISON",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether swamp dragon scales enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
