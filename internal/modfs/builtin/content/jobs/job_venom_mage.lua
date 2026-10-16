-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_VENOM_MAGE",
    abbreviation = "VM",
    name = "Venom Mage",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_SPRIGGAN",
        "SP_NAGA",
        "SP_MERFOLK",
        "SP_TENGU",
        "SP_DJINNI",
        "SP_DEMONSPAWN",
    },
    spells = {
        "SPELL_STING",
        "SPELL_POISONOUS_VAPOURS",
        "SPELL_MEPHITIC_CLOUD",
        "SPELL_OLGREBS_TOXIC_RADIANCE",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_TRANSMUTATIONS",
            level = 1,
        },
        {
            id = "SK_POISON_MAGIC",
            level = 3,
        },
        {
            id = "SK_SPELLCASTING",
            level = 2,
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
    starting_grants = {
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_MAGIC,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Venom Mages start with the Sting spell, and their poison " ..
        "magic is very\neffective against susceptible foes.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 9,
}

register.definition(categories.JOBS, definition)

return definition
