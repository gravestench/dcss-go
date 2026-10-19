-- MST_SPLINTER_BREATH groups 1 DCSS monster spell slots, beginning with
-- SPELL_METAL_SPLINTERS.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_SPLINTER_BREATH",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_METAL_SPLINTERS",
            frequency = 68,
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
