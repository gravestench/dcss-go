-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")

local definition = {
    id = "JOB_HUNTER",
    abbreviation = "Hu",
    name = "Hunter",
    strength = 3,
    intelligence = 1,
    dexterity = 8,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_MINOTAUR",
        "SP_GNOLL",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
    },
    spells = mod.null,
    equipment = {
        "leather armour",
        "scroll of immolation",
        "shortbow",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 2,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 1,
        },
        {
            id = "SK_WEAPON",
            level = 4,
        },
    },
    selectable = true,
}

register.definition(categories.JOBS, definition)

return definition
