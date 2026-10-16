-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 751

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_POISON_RESISTANCE",
    name = "ring of poison resistance",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 3,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/artefact.cc:346-379
        effects = {
            [capabilities.POISON_RESISTANCE] = 1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc:751
    naming = {
        text = "ring of poison resistance",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
