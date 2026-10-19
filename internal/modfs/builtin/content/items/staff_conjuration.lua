-- staff of conjuration (STAFF_CONJURATION) belongs to OBJ_STAVES and occupies
-- the weapon slot.
-- The definition supplies fixed item facts; quantity, position,
-- identification and enchantment belong to item entities.

-- Name Source: crawl-ref/source/item-name.cc

local categories = require("constants.catalog")
local schools = require("constants.spell_schools")

local definition = {
    id = "STAFF_CONJURATION",
    name = "staff of conjuration",
    glyph = 124,
    class = "OBJ_STAVES",
    slot = "weapon",
    class_value = 9,
    subtype_value = 7,
    stackable = false,
    -- Source: crawl-ref/source/melee-attack.cc
    staff = {
        school = schools.CONJURATION,
        skill_id = "SK_CONJURATIONS",
        ac_rolls = 1,
        message = "You blast the %s!",
    },

    -- Source: crawl-ref/source/item-name.cc
    -- staff of conjuration has its display text here so identification policy can
    -- choose known or unknown names consistently.
    naming = {
        text = "staff of conjuration",
        kind = "static",
    },
    explicitly_removed = false,
    -- Source: crawl-ref/source/makeitem.cc
    -- Generation mode random controls whether staff of conjuration enters random
    -- item pools; held copies remain separate entities.
    generation = {
        mode = "random",
    },
}

register.definition(categories.ITEMS, definition)

return definition
