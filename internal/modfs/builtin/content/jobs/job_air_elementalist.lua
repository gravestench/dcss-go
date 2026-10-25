-- Air Elementalist (JOB_AIR_ELEMENTALIST) is a character start with 2 fixed
-- item grants in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_AIR_ELEMENTALIST",
    abbreviation = "AE",
    name = "Air Elementalist",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_TENGU",
        "SP_BASE_DRACONIAN",
        "SP_NAGA",
        "SP_VINE_STALKER",
        "SP_DJINNI",
    },
    spells = {
        "SPELL_SHOCK",
        "SPELL_DISCHARGE",
        "SPELL_SWIFTNESS",
        "SPELL_AIRSTRIKE",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Air Elementalist begins with these training levels before species aptitudes
    -- affect future training.
    skills = {
        {
            id = "SK_CONJURATIONS",
            level = 1,
        },
        {
            id = "SK_AIR_MAGIC",
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
    -- These 2 grants create actual starting inventory for Air Elementalist; weapon
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
    description = "Air Elementalists have learned the Shock spell. Later on, " ..
        "their selection of\nAir Magic spells provides them with the " ..
        "flexibility to survive.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 7,
}

register.definition(categories.JOBS, definition)

return definition
