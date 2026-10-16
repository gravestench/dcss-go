-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 167
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 167

local categories = require("constants.catalog")

local definition = {
    id = "ARM_FIRE_DRAGON_ARMOUR",
    name = "fire dragon scales",
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 20,
    slot = "body",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:167
    naming = {
        text = "fire dragon scales",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 8,
        ev = -110,
        price = 600,
        acquire_weight = 25,
        slot_id = "EQ_BODY_ARMOUR",
        fit_min_id = "SIZE_LITTLE",
        fit_max_id = "SIZE_GIANT",
        mundane = false,
        flags = {
            {
                id = "ARMF_RES_FIRE",
                level = 2,
            },
            {
                id = "ARMF_VUL_COLD",
                level = -1,
            },
        },
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
