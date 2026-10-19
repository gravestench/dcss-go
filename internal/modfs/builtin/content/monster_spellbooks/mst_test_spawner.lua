-- MST_TEST_SPAWNER groups 3 DCSS monster spell slots, beginning with
-- SPELL_SHADOW_CREATURES.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_TEST_SPAWNER",
    -- These 3 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_SHADOW_CREATURES,
            frequency = 100,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_PLANEREND,
            frequency = 67,
            flags = {
                flags.MAGICAL,
            },
        },

        {
            spell_id = spells.SPELL_PHANTOM_MIRROR,
            frequency = 33,
            flags = {
                flags.MAGICAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
