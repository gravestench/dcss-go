-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 177
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 177

local categories = require("constants.catalog")

local definition = {
    id = "ARM_GOLD_DRAGON_HIDE",
    name = "removed gold dragon hide",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 29,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:177
    naming = {
        text = "removed gold dragon hide",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 0,
        ev = 0,
        price = 0,
        acquire_weight = 0,
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
}

register.definition(categories.ITEMS, definition)

return definition
