-- MST_ORANGE_CRYSTAL_STATUE groups 4 DCSS monster spell slots, beginning with
-- SPELL_SHADOW_CREATURES.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_ORANGE_CRYSTAL_STATUE",
    -- These 4 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SHADOW_CREATURES",
            frequency = 40,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_BRAIN_FEED",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_DRAINING_GAZE",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },

        {
            spell_id = "SPELL_MASS_CONFUSION",
            frequency = 20,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
