-- MST_MOON_TROLL groups 1 DCSS monster spell slots, beginning with
-- SPELL_CORROSIVE_BOLT.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")

local definition = {
    id = "MST_MOON_TROLL",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = "SPELL_CORROSIVE_BOLT",
            frequency = 50,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
