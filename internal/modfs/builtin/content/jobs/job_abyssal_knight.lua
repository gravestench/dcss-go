-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_ABYSSAL_KNIGHT",
    abbreviation = "AK",
    name = "Abyssal Knight",
    strength = 5,
    intelligence = 2,
    dexterity = 5,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_PALENTONGA",
        "SP_TROLL",
        "SP_MERFOLK",
        "SP_BASE_DRACONIAN",
        "SP_DEMONSPAWN",
        "SP_METEORAN",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_ARMOUR",
            level = 1,
        },
        {
            id = "SK_DODGING",
            level = 1,
        },
        {
            id = "SK_INVOCATIONS",
            level = 2,
        },
        {
            id = "SK_WEAPON",
            level = 2,
        },
    },
    selectable = true,
}

register.definition(categories.JOBS, definition)

return definition
