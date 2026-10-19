-- MST_NAGA_SHARPSHOOTER groups 2 DCSS monster spell slots, beginning with
-- SPELL_SPIT_POISON.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_NAGA_SHARPSHOOTER",
    -- These 2 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_SPIT_POISON",
            frequency = 55,
            flags = {
                "MON_SPELL_NATURAL",
                "MON_SPELL_BREATH",
            },
        },

        {
            spell_id = "SPELL_PORTAL_PROJECTILE",
            frequency = 59,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
