-- gold dragon scales (ARM_GOLD_DRAGON_ARMOUR) belongs to OBJ_ARMOUR and
-- occupies the body slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-prop.cc
-- Property Source: crawl-ref/source/item-prop.cc

local categories = require("constants.catalog")

local definition = {
    id = "ARM_GOLD_DRAGON_ARMOUR",
    name = "gold dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 30,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc
    -- gold dragon scales has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "gold dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 12,
        ev = -230,
        price = 800,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_COLD",
                level = 1,
            },
            {
                id = "ARMF_RES_FIRE",
                level = 1,
            },
            {
                id = "ARMF_RES_POISON",
                level = 1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether gold dragon scales enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
