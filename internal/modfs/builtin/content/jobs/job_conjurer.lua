-- Conjurer (JOB_CONJURER) is a character start with 2 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_CONJURER",
    abbreviation = "Cj",
    name = "Conjurer",
    strength = -1,
    intelligence = 10,
    dexterity = 3,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_NAGA",
        "SP_TENGU",
        "SP_BASE_DRACONIAN",
        "SP_DEMIGOD",
        "SP_DJINNI",
    },
    spells = {
        "SPELL_MAGIC_DART",
        "SPELL_SEARING_RAY",
        "SPELL_DAZZLING_FLASH",
        "SPELL_FULMINANT_PRISM",
        "SPELL_ISKENDERUNS_MYSTIC_BLAST",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Conjurer begins with these training levels before species aptitudes affect
    -- future training.
    skills = {
        {
            id = "SK_CONJURATIONS",
            level = 4,
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
    -- These 2 grants create actual starting inventory for Conjurer; weapon choice
    -- may add another item.
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
    description = "Conjurers confront problems with damaging spells.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 2,
}

register.definition(categories.JOBS, definition)

return definition
