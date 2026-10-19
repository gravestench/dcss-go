-- MST_IRON_GIANT groups 3 DCSS monster spell slots, beginning with
-- SPELL_IRON_SHOT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_IRON_GIANT",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_IRON_SHOT",
            frequency = 24,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_HARPOON_SHOT",
            frequency = 36,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },

        {
            spell_id = "SPELL_THROW_ALLY",
            frequency = 36,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
