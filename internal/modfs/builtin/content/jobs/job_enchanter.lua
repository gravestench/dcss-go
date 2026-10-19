-- Enchanter (JOB_ENCHANTER) is a character start with 3 fixed item grants in
-- this definition.
-- The start builder turns these grants and skills into player and inventory
-- components; the catalog stays unchanged.

-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_ENCHANTER",
    abbreviation = "En",
    name = "Enchanter",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_FELID",
        "SP_KOBOLD",
        "SP_SPRIGGAN",
        "SP_NAGA",
        "SP_VAMPIRE",
    },
    spells = {
        "SPELL_HIBERNATION",
        "SPELL_CONFUSING_TOUCH",
        "SPELL_TUKIMAS_DANCE",
        "SPELL_DAZZLING_FLASH",
    },
    equipment = {
        "dagger plus:1",
        "robe",
        "potion of invisibility q:2",
    },
    weapon_choice = "WCHOICE_NONE",
    -- Enchanter begins with these training levels before species aptitudes affect
    -- future training.
    skills = {
        {
            id = "SK_WEAPON",
            level = 1,
        },
        {
            id = "SK_HEXES",
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
            level = 3,
        },
    },
    selectable = true,
    -- These 3 grants create actual starting inventory for Enchanter; weapon choice
    -- may add another item.
    starting_grants = {
        {
            kind_id = item_ids.WPN_DAGGER,
            quantity = 1,
            plus = 1,
        },
        {
            kind_id = item_ids.ARM_ROBE,
            quantity = 1,
        },
        {
            kind_id = item_ids.POT_INVISIBILITY,
            quantity = 2,
        },
    },
    -- Source: crawl-ref/source/dat/descript/backgrounds.txt
    description = "Enchanters know a variety of Hexes that can incapacitate " ..
        "their foes, and are\nequipped with an enchanted dagger and " ..
        "potions of invisibility.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_WARRIOR_MAGE,
    menu_order = 4,
}

register.definition(categories.JOBS, definition)

return definition
