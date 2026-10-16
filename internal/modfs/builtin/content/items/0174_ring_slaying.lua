-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Name Source: crawl-ref/source/item-name.cc
-- Name Line: 754

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_SLAYING",
    name = "ring of slaying",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h:200-266
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/item-prop.cc:2129-2135
        pluses = true,
        -- Source: crawl-ref/source/artefact.cc:346-379
        effects = {
            [capabilities.SLAYING] = magnitudes.ITEM_PLUS,
        },
    },

    -- Source: crawl-ref/source/item-name.cc:754
    naming = {
        text = "ring of slaying",
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
