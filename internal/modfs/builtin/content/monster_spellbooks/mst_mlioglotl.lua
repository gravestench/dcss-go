-- MST_MLIOGLOTL groups 3 DCSS monster spell slots, beginning with
-- SPELL_MIGHT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MLIOGLOTL",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_MIGHT,
            frequency = 18,
            flags = {
                flags.NATURAL,
            },
        },

        {
            spell_id = spells.SPELL_CAUSE_FEAR,
            frequency = 18,
            flags = {
                flags.PRIEST,
            },
        },

        {
            spell_id = spells.SPELL_CORRUPT_LOCALE,
            frequency = 36,
            flags = {
                flags.PRIEST,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
