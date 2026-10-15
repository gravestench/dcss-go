-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")

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
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
    },
}

register.definition(categories.JOBS, definition)

return definition
