-- Generated from the pinned DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/job-data.h
-- Starting grants: internal/content/generated/starting-gear.json

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
