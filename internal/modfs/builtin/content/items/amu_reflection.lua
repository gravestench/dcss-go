-- amulet of reflection (AMU_REFLECTION) belongs to OBJ_JEWELLERY.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local jewellery_kinds = require("constants.jewellery_kind")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")

local definition = {
    id = "AMU_REFLECTION",
    name = "amulet of reflection",
    glyph = 34,
    class = "OBJ_JEWELLERY",
    class_value = 6,
    subtype_value = 46,
    stackable = false,
    -- Source: crawl-ref/source/item-prop-enum.h
    jewellery = {
        kind = jewellery_kinds.AMULET,
        -- Source: crawl-ref/source/player-equip.cc
        effects = {
            [capabilities.REFLECTION] = 1,
        },
    },

    -- Source: crawl-ref/source/item-name.cc
    -- amulet of reflection has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "amulet of reflection",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether amulet of reflection enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
