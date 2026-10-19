-- staff of cold (STAFF_COLD) belongs to OBJ_STAVES and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_COLD",
    name = "staff of cold",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 3,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc
    staff = {
        school = schools.ICE,
        skill_id = "SK_ICE_MAGIC",
        resistance_id = resistances.COLD,
        message = "You freeze the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc
    -- staff of cold has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "staff of cold",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether staff of cold enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
