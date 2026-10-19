-- MST_SWAMP_DRAGON groups 1 DCSS monster spell slots, beginning with
-- SPELL_POISONOUS_CLOUD.
-- A monster with this book may offer its weighted slots to AI; eligibility is checked at decision time.
-- The table does not register or cast any spell effect.

local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_SWAMP_DRAGON",
    -- These 1 slots pair candidate spells with frequency and casting flags for the
    -- owning monster.
    slots = {
        {
            spell_id = spells.SPELL_POISONOUS_CLOUD,
            frequency = 59,
            flags = {
                flags.NATURAL,
                flags.BREATH,
                flags.NOISY,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
