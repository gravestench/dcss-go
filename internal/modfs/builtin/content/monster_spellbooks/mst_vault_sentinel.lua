-- MST_VAULT_SENTINEL groups 2 DCSS monster spell slots, beginning with
-- SPELL_WARNING_CRY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_VAULT_SENTINEL",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_WARNING_CRY",
            frequency = 50,
            flags = {
                "MON_SPELL_VOCAL",
                "MON_SPELL_BREATH",
            },
        },

        {
            spell_id = "SPELL_SENTINEL_MARK",
            frequency = 58,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
