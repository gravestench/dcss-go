-- MST_VAULT_SENTINEL groups 2 DCSS monster spell slots, beginning with
-- SPELL_WARNING_CRY.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_VAULT_SENTINEL",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_WARNING_CRY,
            frequency = 50,
            flags = {
                flags.VOCAL,
                flags.BREATH,
            },
        },

        {
            spell_id = spells.SPELL_SENTINEL_MARK,
            frequency = 58,
            flags = {
                flags.WIZARD,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
