-- Hedge Wizard (JOB_HEDGE_WIZARD) is a character start with 4 fixed item
-- grants in this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_HEDGE_WIZARD",
    abbreviation = "HW",
    name = "Hedge Wizard",
    strength = 2,
    intelligence = 6,
    dexterity = 4,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_NAGA",
        "SP_BASE_DRACONIAN",
        "SP_OCTOPODE",
        "SP_HUMAN",
        "SP_DJINNI",
        "SP_METEORAN",
    },
    spells = {
        "SPELL_MAGIC_DART",
        "SPELL_BLINK",
        "SPELL_CALL_IMP",
        "SPELL_SLOW",
        "SPELL_CONJURE_FLAME",
        "SPELL_MEPHITIC_CLOUD",
    },
    equipment = {
        "dagger",
        "robe",
        "hat",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Hedge Wizard begins with these training levels before species aptitudes
    -- affect future training.
    skills = {
        {
            id = "SK_DODGING",
            level = 2,
        },
        {
            id = "SK_STEALTH",
            level = 2,
        },
        {
            id = "SK_SPELLCASTING",
            level = 3,
        },
        {
            id = "SK_TRANSLOCATIONS",
            level = 1,
        },
        {
            id = "SK_CONJURATIONS",
            level = 1,
        },
        {
            id = "SK_SUMMONINGS",
            level = 1,
        },
    },
    selectable = true,
    -- These 4 grants create actual starting inventory for Hedge Wizard; weapon
    -- choice may add another item.
    starting_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.ARM_HAT,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_MAGIC,
            quantity = 1,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Hedge Wizards learn many minor magics, letting them backstab " ..
        "or escape their\nbewildered foes.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 1,
}

register.definition(categories.JOBS, definition)

return definition
