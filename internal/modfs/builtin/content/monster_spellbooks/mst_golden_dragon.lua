-- MST_GOLDEN_DRAGON groups 3 DCSS monster spell slots, beginning with
-- SPELL_BOLT_OF_FIRE.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_GOLDEN_DRAGON",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_BOLT_OF_FIRE",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_BOLT_OF_COLD",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_POISONOUS_CLOUD",
            frequency = 23,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
