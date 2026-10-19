-- MST_SERPENT_OF_HELL_DIS groups 2 DCSS monster spell slots, beginning with
-- SPELL_SERPENT_OF_HELL_DIS_BREATH.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SERPENT_OF_HELL_DIS",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SERPENT_OF_HELL_DIS_BREATH",
            frequency = 35,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
                "MON_SPELL_NOISY",
            },
        },

        {
            spell_id = "SPELL_SUMMON_DRAGON",
            frequency = 35,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
