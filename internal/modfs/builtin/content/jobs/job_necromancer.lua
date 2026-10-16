-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

local categories = require("constants.catalog")
local item_ids = require("ids.items")
local groups = require("constants.menu_groups")

local definition = {
    id = "JOB_NECROMANCER",
    abbreviation = "Ne",
    name = "Necromancer",
    strength = 0,
    intelligence = 7,
    dexterity = 5,
    recommended_species = {
        "SP_DEEP_ELF",
        "SP_DJINNI",
        "SP_HILL_ORC",
        "SP_DEMONSPAWN",
        "SP_MUMMY",
        "SP_VAMPIRE",
    },
    spells = {
        "SPELL_NECROTISE",
        "SPELL_VAMPIRIC_DRAINING",
        "SPELL_ANIMATE_DEAD",
        "SPELL_AGONY",
    },
    equipment = {
        "robe",
        "potion of magic",
    },
    weapon_choice = "WCHOICE_NONE",
    skills = {
        {
            id = "SK_SPELLCASTING",
            level = 2,
        },
        {
            id = "SK_NECROMANCY",
            level = 4,
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
    description = "Necromancers are wizards specializing in the practice of " ..
        "death magic. They\nstart out with the Necrotise spell.",
    -- Source: crawl-ref/source/newgame.cc
    menu_group = groups.JOB_MAGE,
    menu_order = 4,
}

register.definition(categories.JOBS, definition)

return definition
