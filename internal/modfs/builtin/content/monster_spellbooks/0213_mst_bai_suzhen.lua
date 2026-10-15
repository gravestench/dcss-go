-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source line: 1639

local categories = require("constants.catalog")

local definition = {
    id = "MST_BAI_SUZHEN",
    slots = {
        -- Source line: 1641
        {
            spell_id = "SPELL_SUMMON_HYDRA",
            frequency = 40,
            flags = {
                "MON_SPELL_WIZARD",
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
