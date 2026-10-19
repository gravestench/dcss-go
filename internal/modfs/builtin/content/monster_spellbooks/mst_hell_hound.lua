-- MST_HELL_HOUND groups 1 DCSS monster spell slots, beginning with
-- SPELL_FIRE_BREATH.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_HELL_HOUND",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_FIRE_BREATH,
            frequency = 20,
            flags = {
                flags.NATURAL,
                flags.BREATH,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
