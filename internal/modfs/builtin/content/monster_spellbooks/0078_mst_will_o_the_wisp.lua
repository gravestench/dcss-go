-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 619

local categories = require("constants.catalog")

local definition = {
    id = "MST_WILL_O_THE_WISP",
    slots = {
        -- Source line: 621
        {
            spell_id = "SPELL_MARSHLIGHT",
            frequency = 50,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
        -- Source line: 622
        {
            spell_id = "SPELL_BLINK",
            frequency = 12,
            flags = {
                "MON_SPELL_MAGICAL",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
