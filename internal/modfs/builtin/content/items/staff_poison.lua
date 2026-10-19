-- staff of poison (STAFF_POISON) belongs to OBJ_STAVES and occupies the
-- weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_POISON",
    name = "staff of poison",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 4,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc
    staff = {
        school = schools.POISON,
        skill_id = "SK_POISON_MAGIC",
        resistance_id = resistances.POISON,
        poison_level = 2,
        message = "You envenom the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc
    -- staff of poison has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "staff of poison",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether staff of poison enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
