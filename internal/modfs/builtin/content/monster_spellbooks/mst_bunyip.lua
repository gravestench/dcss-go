-- MST_BUNYIP groups 1 DCSS monster spell slots, beginning with
-- SPELL_WARNING_CRY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_BUNYIP",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 20,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
