-- staff of death (STAFF_DEATH) belongs to OBJ_STAVES and occupies the weapon
-- slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")
local resistances = require("constants.resistance_ids")

local definition = {
    id = "STAFF_DEATH",
    name = "staff of death",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 6,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc
    staff = {
        school = schools.NECROMANCY,
        skill_id = "SK_NECROMANCY",
        resistance_id = resistances.NEGATIVE_ENERGY,
        negative_energy = true,
        message = "The %s writhes in agony!",
    },

    -- Source: crawl-ref/source/item-name.cc
    -- staff of death has its display text here so identification policy can choose
    -- known or unknown names consistently.
    naming = {
        text = "staff of death",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether staff of death enters random item
    -- pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
