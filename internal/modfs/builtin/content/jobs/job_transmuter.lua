-- Transmuter (JOB_TRANSMUTER) is a character start with 2 fixed item grants
-- in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_TRANSMUTER",
    abbreviation = "Tm",
    name = "Transmuter",
    strength = 2,
    intelligence = 5,
    dexterity = 5,
    recommended_species = {
        "SP_NAGA",
        "SP_MERFOLK",
        "SP_BASE_DRACONIAN",
        "SP_DEMIGOD",
        "SP_DEMONSPAWN",
        "SP_TROLL",
        "SP_METEORAN",
    },
    spells = {
        "SPELL_BEASTLY_APPENDAGE",
        "SPELL_WEREBLOOD",
        "SPELL_SPIDER_FORM",
        "SPELL_ICE_FORM",
    },
    equipment = {
        "robe",
        "potion of lignification",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Transmuter begins with these training levels before species aptitudes affect
    -- future training.
    skills = {
        {
            id = "SK_FIGHTING",
            level = 1,
        },
        {
            id = "SK_UNARMED_COMBAT",
            level = 3,
        },
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_TRANSMUTATIONS",
            level = 2,
        },
    },
    selectable = true,
    -- These 2 grants create actual starting inventory for Transmuter; weapon
    -- choice may add another item.
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_LIGNIFY,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Transmuters learn spells to shift their form, making them " ..
        "powerful unarmed\nfighters.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR_MAGE,
    menu_order = 1,
}

register.definition(categories.JOBS, definition)

return definition
