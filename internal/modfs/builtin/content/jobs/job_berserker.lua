-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")

local definition = {
    id = "JOB_BERSERKER",
    abbreviation = "Be",
    name = "Berserker",
    strength = 9,
    intelligence = -1,
    dexterity = 4,
    recommended_species = {
        "SP_HILL_ORC",
        "SP_OGRE",
        "SP_MERFOLK",
        "SP_MINOTAUR",
        "SP_GARGOYLE",
        "SP_PALENTONGA",
    },
    spells = mod.null,
    equipment = {
        "animal skin",
    },
    weapon_choice = "WCHOICE_PLAIN",
    skills = {
        {
            id = "SK_FIGHTING",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_WEAPON",
            level = 3,
        },
    },
    selectable = true,
    starting_grants = {
        {
            kind_id = item_ids.ARM_ANIMAL_SKIN,
            quantity = 1,
        },
    },
}

register.definition(categories.JOBS, definition)

return definition
