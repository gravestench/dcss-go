-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_NECROMANCER",
    abbreviation = "Ne",
    name = "Necromancer",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_DJINNI",
        "SP_HILL_ORC",
        "SP_DEMONSPAWN",
        "SP_MUMMY",
        "SP_VAMPIRE",
    },
    spells = {
        "SPELL_NECROTISE",
        "SPELL_VAMPIRIC_DRAINING",
        "SPELL_ANIMATE_DEAD",
        "SPELL_AGONY",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_NECROMANCY",
            level = 4,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 2,
        },
    },
    selectable = true,
}

register.definition(categories.JOBS, definition)

return definition
