-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 169
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 169

local categories = require("constants.catalog")

local definition = {
    id = "ARM_ICE_DRAGON_ARMOUR",
    name = "ice dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 22,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:169
    naming = {
        text = "ice dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 9,
        ev = -110,
        price = 600,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_COLD",
                level = 2,
            },
            {
                id = "ARMF_VUL_FIRE",
                level = -1,
            },
        },
    },
}

register.definition(categories.ITEMS, definition)

return definition
