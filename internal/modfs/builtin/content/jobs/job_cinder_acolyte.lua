-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_CINDER_ACOLYTE",
    abbreviation = "CA",
    name = "Cinder Acolyte",
    strength = 6,
    intelligence = 6,
    dexterity = 0,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_BASE_DRACONIAN",
        "SP_OGRE",
        "SP_DJINNI",
        "SP_GNOLL",
        "SP_METEORAN",
    },
    spells = {
        "SPELL_SCORCH",
    },
    equipment = {
        "robe",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
        {
            id = "SK_FIRE_MAGIC",
            level = 3,
        },
        {
            id = "SK_SPELLCASTING",
            level = 1,
        },
    },
    selectable = true,
}

register.definition(categories.JOBS, definition)

return definition
