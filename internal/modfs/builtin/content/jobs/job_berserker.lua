-- Berserker (JOB_BERSERKER) is a character start with 1 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

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
    -- Berserker begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 1 grants create actual starting inventory for Berserker; weapon choice
    -- may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_ANIMAL_SKIN,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Berserkers believe in Trog, the magic-hating god of frenzy. " ..
        "Not much can stop a\nraging berserker early on, apart from " ..
        "hubris.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_ZEALOT,
    menu_order = 1,
}

register.definition(categories.JOBS, definition)

return definition
