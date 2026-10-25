-- Venom Mage (JOB_VENOM_MAGE) is a character start with 2 fixed item grants
-- in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

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
    -- Venom Mage begins with these training levels before species aptitudes affect
    -- future training.
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
    -- These 2 grants create actual starting inventory for Venom Mage; weapon
    -- choice may add another item.
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
