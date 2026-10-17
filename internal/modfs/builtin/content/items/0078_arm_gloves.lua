-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-prop.cc
-- Name Line: 119
-- Property Source: crawl-ref/source/item-prop.cc
-- Property Line: 119

local categories = require("constants.catalog")

local definition = {
    id = "ARM_GLOVES",
    name = "gloves",
    vault_aliases = {
        "pair of gloves",
    },
    glyph = 91,
    class = "OBJ_ARMOUR",
    class_value = 2,
    subtype_value = 10,
    slot = "gloves",
    stackable = false,
    -- Source: crawl-ref/source/item-prop.cc:119
    naming = {
        text = "gloves",
        kind = "static",
    },
    explicitly_removed = false,
    armour = {
        ac = 1,
        ev = 0,
        price = 45,
        acquire_weight = 0,
        slot_id = "EQ_GLOVES",
        fit_min_id = "SIZE_SMALL",
        fit_max_id = "SIZE_MEDIUM",
        mundane = true,
        flags = mod.null,
    },
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
