-- ring of flight (RING_FLIGHT) belongs to OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "RING_FLIGHT",
    name = "ring of flight",
    glyph = 61,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 18,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h
    jewellery = {
        kind = jewellery_kinds.RING,
        -- Source: crawl-ref/source/artefact.cc
        effects = {
            [capabilities.PERMANENT_FLIGHT] = 1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc
    -- ring of flight has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "ring of flight",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether ring of flight enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
