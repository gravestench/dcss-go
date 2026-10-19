-- MST_MLIOGLOTL groups 3 DCSS monster spell slots, beginning with
-- SPELL_MIGHT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_MLIOGLOTL",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_MIGHT",
            frequency = 18,
            flags = {
                "MON_SPELL_NATURAL",
            },
        },

        {
            spell_id = "SPELL_CAUSE_FEAR",
            frequency = 18,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },

        {
            spell_id = "SPELL_CORRUPT_LOCALE",
            frequency = 36,
            flags = {
                "MON_SPELL_PRIEST",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
