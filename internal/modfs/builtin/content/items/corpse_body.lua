-- corpse (CORPSE_BODY) belongs to OBJ_CORPSES.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")

local definition = {
    id = "CORPSE_BODY",
    name = "corpse",
    glyph = 37,
    class = "OBJ_CORPSES",
    class_value = 12,
    subtype_value = 0,
    stackable = false,
    -- Source: crawl-ref/source/item-name.cc
    -- corpse has its display text here so identification policy can choose known
    -- or unknown names consistently.
    naming = {
        text = "corpse",
        kind = "corpse_monster",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode forced controls whether corpse enters random item pools;
    -- held copies remain separate entities.
    generation = {
        mode = "forced",
    },
}

register.definition(categories.ITEMS, definition)

return definition
